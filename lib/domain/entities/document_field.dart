enum FieldType { text, number, date, masked }

class DocumentField {
  final String key;
  final String value;
  final FieldType type;
  final bool isSensitive;

  const DocumentField({
    required this.key,
    required this.value,
    required this.type,
    this.isSensitive = false,
  });
}
