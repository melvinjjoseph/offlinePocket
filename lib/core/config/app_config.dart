import 'package:flutter/material.dart';
import '../../domain/entities/document_field.dart';

class FieldConfig {
  final String name;
  final FieldType type;
  final bool sensitive;
  final String? regex;

  const FieldConfig({
    required this.name,
    this.type = FieldType.text,
    this.sensitive = false,
    this.regex,
  });

  factory FieldConfig.fromJson(Map<String, dynamic> json) => FieldConfig(
        name: json['name'] as String,
        type: FieldType.values.firstWhere(
          (t) => t.name == (json['type'] as String? ?? 'text'),
          orElse: () => FieldType.text,
        ),
        sensitive: json['sensitive'] as bool? ?? false,
        regex: json['regex'] as String?,
      );
}

class CategoryConfig {
  final String id;
  final String label;
  final String icon;
  final List<FieldConfig> fields;

  const CategoryConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.fields,
  });

  factory CategoryConfig.fromJson(Map<String, dynamic> json) => CategoryConfig(
        id: json['id'] as String,
        label: json['label'] as String,
        icon: json['icon'] as String? ?? 'card_membership_outlined',
        fields: (json['fields'] as List<dynamic>? ?? [])
            .map((f) => FieldConfig.fromJson(f as Map<String, dynamic>))
            .toList(),
      );

  IconData get iconData => switch (icon) {
        'credit_card'            => Icons.credit_card,
        'credit_card_outlined'   => Icons.credit_card_outlined,
        'card_giftcard_outlined' => Icons.card_giftcard_outlined,
        'book_outlined'          => Icons.book_outlined,
        'drive_eta_outlined'     => Icons.drive_eta_outlined,
        'badge_outlined'         => Icons.badge_outlined,
        _                        => Icons.card_membership_outlined,
      };
}

class AppConfig {
  final int securityIdleTimeoutSeconds;
  final int clipboardClearTimeoutSeconds;
  final double ocrConfidenceThreshold;
  final int maxCustomFieldsPerCard;
  final List<CategoryConfig> categories;

  const AppConfig({
    required this.securityIdleTimeoutSeconds,
    required this.clipboardClearTimeoutSeconds,
    required this.ocrConfidenceThreshold,
    required this.maxCustomFieldsPerCard,
    required this.categories,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        securityIdleTimeoutSeconds:
            json['security_idle_timeout_seconds'] as int? ?? 300,
        clipboardClearTimeoutSeconds:
            json['clipboard_clear_timeout_seconds'] as int? ?? 45,
        ocrConfidenceThreshold:
            (json['ocr_confidence_threshold'] as num?)?.toDouble() ?? 0.75,
        maxCustomFieldsPerCard: json['max_custom_fields_per_card'] as int? ?? 20,
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((c) => CategoryConfig.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  CategoryConfig? categoryById(String id) =>
      categories.where((c) => c.id == id).firstOrNull;

  static const AppConfig fallback = AppConfig(
    securityIdleTimeoutSeconds: 300,
    clipboardClearTimeoutSeconds: 45,
    ocrConfidenceThreshold: 0.75,
    maxCustomFieldsPerCard: 20,
    categories: _defaultCategories,
  );
}

// Shared payment fields for credit / debit / prepaid
const _paymentFields = <FieldConfig>[
  FieldConfig(
    name: 'Card Number',
    type: FieldType.masked,
    sensitive: true,
    regex: r'^[0-9]{4}[\s\-]?[0-9]{4}[\s\-]?[0-9]{4}[\s\-]?[0-9]{4}$',
  ),
  FieldConfig(name: 'Cardholder Name'),
  FieldConfig(
    name: 'Expiry Date',
    type: FieldType.date,
    regex: r'^(0[1-9]|1[0-2])\/[0-9]{2}$',
  ),
  FieldConfig(
    name: 'CVV',
    type: FieldType.masked,
    sensitive: true,
    regex: r'^[0-9]{3,4}$',
  ),
];

const _defaultCategories = <CategoryConfig>[
  CategoryConfig(
    id: 'creditCard',
    label: 'Credit Card',
    icon: 'credit_card',
    fields: _paymentFields,
  ),
  CategoryConfig(
    id: 'debitCard',
    label: 'Debit Card',
    icon: 'credit_card_outlined',
    fields: _paymentFields,
  ),
  CategoryConfig(
    id: 'prepaidCard',
    label: 'Prepaid Card',
    icon: 'card_giftcard_outlined',
    fields: _paymentFields,
  ),
  CategoryConfig(
    id: 'passport',
    label: 'Passport',
    icon: 'book_outlined',
    fields: <FieldConfig>[
      FieldConfig(
        name: 'Passport Number',
        type: FieldType.masked,
        sensitive: true,
        regex: r'^[A-Z][0-9]{7,8}$',
      ),
      FieldConfig(name: 'Full Name'),
      FieldConfig(name: 'Nationality', regex: r'^[A-Za-z ]{2,50}$'),
      FieldConfig(
        name: 'Date of Birth',
        type: FieldType.date,
        regex: r'^[0-9]{2}\/[0-9]{2}\/[0-9]{4}$',
      ),
      FieldConfig(
        name: 'Issue Date',
        type: FieldType.date,
        regex: r'^[0-9]{2}\/[0-9]{2}\/[0-9]{4}$',
      ),
      FieldConfig(
        name: 'Expiry Date',
        type: FieldType.date,
        regex: r'^[0-9]{2}\/[0-9]{2}\/[0-9]{4}$',
      ),
    ],
  ),
  CategoryConfig(
    id: 'driverLicense',
    label: 'Driver License',
    icon: 'drive_eta_outlined',
    fields: <FieldConfig>[
      FieldConfig(
        name: 'License Number',
        type: FieldType.masked,
        sensitive: true,
        regex: r'^[A-Z0-9]{5,20}$',
      ),
      FieldConfig(name: 'Full Name'),
      FieldConfig(
        name: 'Date of Birth',
        type: FieldType.date,
        regex: r'^[0-9]{2}\/[0-9]{2}\/[0-9]{4}$',
      ),
      FieldConfig(
        name: 'Expiry Date',
        type: FieldType.date,
        regex: r'^[0-9]{2}\/[0-9]{2}\/[0-9]{4}$',
      ),
    ],
  ),
  CategoryConfig(
    id: 'nationalId',
    label: 'National ID',
    icon: 'badge_outlined',
    fields: <FieldConfig>[
      FieldConfig(
        name: 'ID Number',
        type: FieldType.masked,
        sensitive: true,
        regex: r'^[A-Z0-9]{4,20}$',
      ),
      FieldConfig(name: 'Full Name'),
      FieldConfig(
        name: 'Date of Birth',
        type: FieldType.date,
        regex: r'^[0-9]{2}\/[0-9]{2}\/[0-9]{4}$',
      ),
      FieldConfig(
        name: 'Expiry Date',
        type: FieldType.date,
        regex: r'^[0-9]{2}\/[0-9]{2}\/[0-9]{4}$',
      ),
    ],
  ),
  CategoryConfig(
    id: 'genericId',
    label: 'Generic ID',
    icon: 'card_membership_outlined',
    fields: <FieldConfig>[
      FieldConfig(name: 'ID Number', sensitive: true),
      FieldConfig(name: 'Full Name'),
    ],
  ),
];
