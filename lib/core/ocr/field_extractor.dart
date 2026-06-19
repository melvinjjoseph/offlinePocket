import '../../domain/entities/document_field.dart';

class ExtractedField {
  final String key;
  final String value;
  final FieldType type;
  final bool isSensitive;

  const ExtractedField({
    required this.key,
    required this.value,
    required this.type,
    this.isSensitive = false,
  });
}

class ExtractionResult {
  final List<ExtractedField> fields;
  final List<String> rawLines; // unmatched lines for manual copy

  const ExtractionResult({required this.fields, required this.rawLines});
}

class FieldExtractor {
  // 16-digit card number (with optional spaces/dashes)
  static final _cardNum =
      RegExp(r'(\d{4})[\s\-\.]?(\d{4})[\s\-\.]?(\d{4})[\s\-\.]?(\d{4})');

  // Expiry MM/YY or MM-YY (not a full date)
  static final _expiry =
      RegExp(r'\b(0[1-9]|1[0-2])[\/\-](\d{2})\b');

  // Passport / national ID: 1-2 letters followed by 6-9 digits
  static final _idNumber = RegExp(r'\b([A-Z]{1,2}\d{6,9})\b');

  // Generic date DD/MM/YYYY or DD-MM-YYYY
  static final _dateSlash =
      RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})\b');

  // ISO date YYYY-MM-DD (in MRZ or machine-readable zones)
  static final _dateISO = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b');

  // All-caps name: 2–4 words of 2+ letters (cardholder / passport name)
  static final _capsName =
      RegExp(r'(?:^|\s)([A-Z]{2,}(?:\s+[A-Z]{2,}){1,3})(?:\s|$)');

  // MRZ line: 30+ chars of uppercase letters, digits, or <
  static final _mrzLine = RegExp(r'^[A-Z0-9<]{30,}$');

  // Words that are never useful as extracted lines
  static const _skipWords = {
    'VISA', 'MASTERCARD', 'MAESTRO', 'AMEX', 'RUPAY', 'DISCOVER',
    'VALID', 'THRU', 'FROM', 'GOOD', 'THROUGH', 'EXPIRES', 'MEMBER',
    'SINCE', 'BANK', 'CREDIT', 'DEBIT', 'CARD', 'PLATINUM', 'GOLD',
    'CLASSIC', 'STANDARD', 'PREMIER', 'WORLD', 'ELITE', 'INFINITE',
    'SIGNATURE', 'CONTACTLESS', 'CHIP', 'PIN',
  };

  // Pure-digit-only lines (likely partial OCR noise)
  static final _pureDigits = RegExp(r'^\d+$');

  // Phone/customer-care numbers: 7+ consecutive digits (with optional separators)
  static final _phonePattern = RegExp(r'\d[\d\s\-]{6,}\d');

  static ExtractionResult extract(String text) {
    final fields = <ExtractedField>[];
    // Track character ranges already consumed to avoid double-labelling
    final used = <(int, int)>[];

    void consume(Match m) => used.add((m.start, m.end));
    bool isUsed(int start, int end) =>
        used.any((s) => start < s.$2 && end > s.$1);

    // ── Card number ──────────────────────────────────────────────────────
    final cardMatch = _cardNum.firstMatch(text);
    if (cardMatch != null) {
      final num =
          '${cardMatch.group(1)} ${cardMatch.group(2)} ${cardMatch.group(3)} ${cardMatch.group(4)}';
      fields.add(ExtractedField(
          key: 'Card Number', value: num, type: FieldType.masked, isSensitive: true));
      consume(cardMatch);
    }

    // ── Expiry (only when card number also found) ─────────────────────────
    if (cardMatch != null) {
      final em = _expiry.firstMatch(text);
      if (em != null && !isUsed(em.start, em.end)) {
        fields.add(ExtractedField(
            key: 'Expiry Date',
            value: '${em.group(1)}/${em.group(2)}',
            type: FieldType.date));
        consume(em);
      }
    }

    // ── Passport / ID number (only when no card number) ─────────────────
    if (cardMatch == null) {
      for (final m in _idNumber.allMatches(text)) {
        if (isUsed(m.start, m.end)) continue;
        fields.add(ExtractedField(
            key: 'ID Number',
            value: m.group(1)!,
            type: FieldType.masked,
            isSensitive: true));
        consume(m);
        break;
      }
    }

    // ── Generic dates (DOB, issue, expiry on IDs) ─────────────────────────
    final dateLabels = ['Date of Birth', 'Issue Date', 'Expiry Date'];
    var labelIdx = 0;
    for (final m in _dateSlash.allMatches(text)) {
      if (isUsed(m.start, m.end)) continue;
      if (labelIdx >= dateLabels.length) break;
      final d = m.group(1)!.padLeft(2, '0');
      final mo = m.group(2)!.padLeft(2, '0');
      final y = m.group(3)!;
      fields.add(ExtractedField(
          key: dateLabels[labelIdx],
          value: '$d/$mo/$y',
          type: FieldType.date));
      consume(m);
      labelIdx++;
    }
    for (final m in _dateISO.allMatches(text)) {
      if (isUsed(m.start, m.end)) continue;
      if (labelIdx >= dateLabels.length) break;
      fields.add(ExtractedField(
          key: dateLabels[labelIdx],
          value: '${m.group(3)}/${m.group(2)}/${m.group(1)}',
          type: FieldType.date));
      consume(m);
      labelIdx++;
    }

    // ── Cardholder / person name ─────────────────────────────────────────
    for (final m in _capsName.allMatches(text)) {
      if (isUsed(m.start, m.end)) continue;
      final name = m.group(1)!.trim();
      final words = name.split(RegExp(r'\s+'));
      // Skip if all words are brand/filler words
      if (words.every((w) => _skipWords.contains(w))) continue;
      if (words.any((w) => w.length < 2)) continue;
      final label = cardMatch != null ? 'Cardholder Name' : 'Full Name';
      fields.add(ExtractedField(key: label, value: name, type: FieldType.text));
      consume(m);
      break;
    }

    // ── Raw unmatched lines (max 3) ───────────────────────────────────────
    // Sweet spot: 5–25 chars. Below 5 = noise; above 25 = instructions /
    // customer-care numbers / addresses.
    final rawLines = <String>[];
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      // Length guard: skip noise and long instructions
      if (line.length < 5 || line.length > 25) continue;
      if (_mrzLine.hasMatch(line)) continue;
      if (_pureDigits.hasMatch(line)) continue;
      // Skip phone/care numbers embedded in the line
      if (_phonePattern.hasMatch(line)) continue;
      // Skip lines made entirely of brand/filler words
      final upper = line.toUpperCase();
      final words = upper.split(RegExp(r'\s+'));
      if (words.every((w) => _skipWords.contains(w))) continue;
      final idx = text.indexOf(line);
      if (idx >= 0 && isUsed(idx, idx + line.length)) continue;
      rawLines.add(line);
      if (rawLines.length == 3) break;
    }

    return ExtractionResult(fields: fields, rawLines: rawLines);
  }
}
