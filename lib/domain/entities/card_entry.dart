import 'document_field.dart';

class CardEntry {
  final String id;
  final String category; // matches CategoryConfig.id
  final String label;
  final List<DocumentField> fields;
  final DateTime createdAt;
  final String? frontImagePath;
  final String? backImagePath;

  const CardEntry({
    required this.id,
    required this.category,
    required this.label,
    required this.fields,
    required this.createdAt,
    this.frontImagePath,
    this.backImagePath,
  });
}
