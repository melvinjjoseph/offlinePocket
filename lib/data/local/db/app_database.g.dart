// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CardEntriesTableTable extends CardEntriesTable
    with TableInfo<$CardEntriesTableTable, CardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frontImagePathMeta = const VerificationMeta(
    'frontImagePath',
  );
  @override
  late final GeneratedColumn<String> frontImagePath = GeneratedColumn<String>(
    'front_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backImagePathMeta = const VerificationMeta(
    'backImagePath',
  );
  @override
  late final GeneratedColumn<String> backImagePath = GeneratedColumn<String>(
    'back_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    label,
    createdAt,
    frontImagePath,
    backImagePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('front_image_path')) {
      context.handle(
        _frontImagePathMeta,
        frontImagePath.isAcceptableOrUnknown(
          data['front_image_path']!,
          _frontImagePathMeta,
        ),
      );
    }
    if (data.containsKey('back_image_path')) {
      context.handle(
        _backImagePathMeta,
        backImagePath.isAcceptableOrUnknown(
          data['back_image_path']!,
          _backImagePathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      frontImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front_image_path'],
      ),
      backImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back_image_path'],
      ),
    );
  }

  @override
  $CardEntriesTableTable createAlias(String alias) {
    return $CardEntriesTableTable(attachedDatabase, alias);
  }
}

class CardRow extends DataClass implements Insertable<CardRow> {
  final String id;
  final String category;
  final String label;
  final int createdAt;
  final String? frontImagePath;
  final String? backImagePath;
  const CardRow({
    required this.id,
    required this.category,
    required this.label,
    required this.createdAt,
    this.frontImagePath,
    this.backImagePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    map['label'] = Variable<String>(label);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || frontImagePath != null) {
      map['front_image_path'] = Variable<String>(frontImagePath);
    }
    if (!nullToAbsent || backImagePath != null) {
      map['back_image_path'] = Variable<String>(backImagePath);
    }
    return map;
  }

  CardEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return CardEntriesTableCompanion(
      id: Value(id),
      category: Value(category),
      label: Value(label),
      createdAt: Value(createdAt),
      frontImagePath: frontImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(frontImagePath),
      backImagePath: backImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(backImagePath),
    );
  }

  factory CardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardRow(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      label: serializer.fromJson<String>(json['label']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      frontImagePath: serializer.fromJson<String?>(json['frontImagePath']),
      backImagePath: serializer.fromJson<String?>(json['backImagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'label': serializer.toJson<String>(label),
      'createdAt': serializer.toJson<int>(createdAt),
      'frontImagePath': serializer.toJson<String?>(frontImagePath),
      'backImagePath': serializer.toJson<String?>(backImagePath),
    };
  }

  CardRow copyWith({
    String? id,
    String? category,
    String? label,
    int? createdAt,
    Value<String?> frontImagePath = const Value.absent(),
    Value<String?> backImagePath = const Value.absent(),
  }) => CardRow(
    id: id ?? this.id,
    category: category ?? this.category,
    label: label ?? this.label,
    createdAt: createdAt ?? this.createdAt,
    frontImagePath: frontImagePath.present
        ? frontImagePath.value
        : this.frontImagePath,
    backImagePath: backImagePath.present
        ? backImagePath.value
        : this.backImagePath,
  );
  CardRow copyWithCompanion(CardEntriesTableCompanion data) {
    return CardRow(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      label: data.label.present ? data.label.value : this.label,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      frontImagePath: data.frontImagePath.present
          ? data.frontImagePath.value
          : this.frontImagePath,
      backImagePath: data.backImagePath.present
          ? data.backImagePath.value
          : this.backImagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardRow(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('frontImagePath: $frontImagePath, ')
          ..write('backImagePath: $backImagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    label,
    createdAt,
    frontImagePath,
    backImagePath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardRow &&
          other.id == this.id &&
          other.category == this.category &&
          other.label == this.label &&
          other.createdAt == this.createdAt &&
          other.frontImagePath == this.frontImagePath &&
          other.backImagePath == this.backImagePath);
}

class CardEntriesTableCompanion extends UpdateCompanion<CardRow> {
  final Value<String> id;
  final Value<String> category;
  final Value<String> label;
  final Value<int> createdAt;
  final Value<String?> frontImagePath;
  final Value<String?> backImagePath;
  final Value<int> rowid;
  const CardEntriesTableCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.frontImagePath = const Value.absent(),
    this.backImagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardEntriesTableCompanion.insert({
    required String id,
    required String category,
    required String label,
    required int createdAt,
    this.frontImagePath = const Value.absent(),
    this.backImagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       label = Value(label),
       createdAt = Value(createdAt);
  static Insertable<CardRow> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<String>? label,
    Expression<int>? createdAt,
    Expression<String>? frontImagePath,
    Expression<String>? backImagePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
      if (frontImagePath != null) 'front_image_path': frontImagePath,
      if (backImagePath != null) 'back_image_path': backImagePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardEntriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? category,
    Value<String>? label,
    Value<int>? createdAt,
    Value<String?>? frontImagePath,
    Value<String?>? backImagePath,
    Value<int>? rowid,
  }) {
    return CardEntriesTableCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      backImagePath: backImagePath ?? this.backImagePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (frontImagePath.present) {
      map['front_image_path'] = Variable<String>(frontImagePath.value);
    }
    if (backImagePath.present) {
      map['back_image_path'] = Variable<String>(backImagePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('frontImagePath: $frontImagePath, ')
          ..write('backImagePath: $backImagePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentFieldsTableTable extends DocumentFieldsTable
    with TableInfo<$DocumentFieldsTableTable, FieldRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentFieldsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyNameMeta = const VerificationMeta(
    'keyName',
  );
  @override
  late final GeneratedColumn<String> keyName = GeneratedColumn<String>(
    'key_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedValueMeta = const VerificationMeta(
    'encryptedValue',
  );
  @override
  late final GeneratedColumn<Uint8List> encryptedValue =
      GeneratedColumn<Uint8List>(
        'encrypted_value',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fieldTypeMeta = const VerificationMeta(
    'fieldType',
  );
  @override
  late final GeneratedColumn<String> fieldType = GeneratedColumn<String>(
    'field_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSensitiveMeta = const VerificationMeta(
    'isSensitive',
  );
  @override
  late final GeneratedColumn<bool> isSensitive = GeneratedColumn<bool>(
    'is_sensitive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_sensitive" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    keyName,
    encryptedValue,
    fieldType,
    isSensitive,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<FieldRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('key_name')) {
      context.handle(
        _keyNameMeta,
        keyName.isAcceptableOrUnknown(data['key_name']!, _keyNameMeta),
      );
    } else if (isInserting) {
      context.missing(_keyNameMeta);
    }
    if (data.containsKey('encrypted_value')) {
      context.handle(
        _encryptedValueMeta,
        encryptedValue.isAcceptableOrUnknown(
          data['encrypted_value']!,
          _encryptedValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedValueMeta);
    }
    if (data.containsKey('field_type')) {
      context.handle(
        _fieldTypeMeta,
        fieldType.isAcceptableOrUnknown(data['field_type']!, _fieldTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldTypeMeta);
    }
    if (data.containsKey('is_sensitive')) {
      context.handle(
        _isSensitiveMeta,
        isSensitive.isAcceptableOrUnknown(
          data['is_sensitive']!,
          _isSensitiveMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isSensitiveMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FieldRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FieldRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      keyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_name'],
      )!,
      encryptedValue: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_value'],
      )!,
      fieldType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_type'],
      )!,
      isSensitive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_sensitive'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $DocumentFieldsTableTable createAlias(String alias) {
    return $DocumentFieldsTableTable(attachedDatabase, alias);
  }
}

class FieldRow extends DataClass implements Insertable<FieldRow> {
  final String id;
  final String cardId;
  final String keyName;
  final Uint8List encryptedValue;
  final String fieldType;
  final bool isSensitive;
  final int sortOrder;
  const FieldRow({
    required this.id,
    required this.cardId,
    required this.keyName,
    required this.encryptedValue,
    required this.fieldType,
    required this.isSensitive,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['card_id'] = Variable<String>(cardId);
    map['key_name'] = Variable<String>(keyName);
    map['encrypted_value'] = Variable<Uint8List>(encryptedValue);
    map['field_type'] = Variable<String>(fieldType);
    map['is_sensitive'] = Variable<bool>(isSensitive);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  DocumentFieldsTableCompanion toCompanion(bool nullToAbsent) {
    return DocumentFieldsTableCompanion(
      id: Value(id),
      cardId: Value(cardId),
      keyName: Value(keyName),
      encryptedValue: Value(encryptedValue),
      fieldType: Value(fieldType),
      isSensitive: Value(isSensitive),
      sortOrder: Value(sortOrder),
    );
  }

  factory FieldRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FieldRow(
      id: serializer.fromJson<String>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      keyName: serializer.fromJson<String>(json['keyName']),
      encryptedValue: serializer.fromJson<Uint8List>(json['encryptedValue']),
      fieldType: serializer.fromJson<String>(json['fieldType']),
      isSensitive: serializer.fromJson<bool>(json['isSensitive']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cardId': serializer.toJson<String>(cardId),
      'keyName': serializer.toJson<String>(keyName),
      'encryptedValue': serializer.toJson<Uint8List>(encryptedValue),
      'fieldType': serializer.toJson<String>(fieldType),
      'isSensitive': serializer.toJson<bool>(isSensitive),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  FieldRow copyWith({
    String? id,
    String? cardId,
    String? keyName,
    Uint8List? encryptedValue,
    String? fieldType,
    bool? isSensitive,
    int? sortOrder,
  }) => FieldRow(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    keyName: keyName ?? this.keyName,
    encryptedValue: encryptedValue ?? this.encryptedValue,
    fieldType: fieldType ?? this.fieldType,
    isSensitive: isSensitive ?? this.isSensitive,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  FieldRow copyWithCompanion(DocumentFieldsTableCompanion data) {
    return FieldRow(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      keyName: data.keyName.present ? data.keyName.value : this.keyName,
      encryptedValue: data.encryptedValue.present
          ? data.encryptedValue.value
          : this.encryptedValue,
      fieldType: data.fieldType.present ? data.fieldType.value : this.fieldType,
      isSensitive: data.isSensitive.present
          ? data.isSensitive.value
          : this.isSensitive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FieldRow(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('keyName: $keyName, ')
          ..write('encryptedValue: $encryptedValue, ')
          ..write('fieldType: $fieldType, ')
          ..write('isSensitive: $isSensitive, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    keyName,
    $driftBlobEquality.hash(encryptedValue),
    fieldType,
    isSensitive,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FieldRow &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.keyName == this.keyName &&
          $driftBlobEquality.equals(
            other.encryptedValue,
            this.encryptedValue,
          ) &&
          other.fieldType == this.fieldType &&
          other.isSensitive == this.isSensitive &&
          other.sortOrder == this.sortOrder);
}

class DocumentFieldsTableCompanion extends UpdateCompanion<FieldRow> {
  final Value<String> id;
  final Value<String> cardId;
  final Value<String> keyName;
  final Value<Uint8List> encryptedValue;
  final Value<String> fieldType;
  final Value<bool> isSensitive;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const DocumentFieldsTableCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.keyName = const Value.absent(),
    this.encryptedValue = const Value.absent(),
    this.fieldType = const Value.absent(),
    this.isSensitive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentFieldsTableCompanion.insert({
    required String id,
    required String cardId,
    required String keyName,
    required Uint8List encryptedValue,
    required String fieldType,
    required bool isSensitive,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cardId = Value(cardId),
       keyName = Value(keyName),
       encryptedValue = Value(encryptedValue),
       fieldType = Value(fieldType),
       isSensitive = Value(isSensitive),
       sortOrder = Value(sortOrder);
  static Insertable<FieldRow> custom({
    Expression<String>? id,
    Expression<String>? cardId,
    Expression<String>? keyName,
    Expression<Uint8List>? encryptedValue,
    Expression<String>? fieldType,
    Expression<bool>? isSensitive,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (keyName != null) 'key_name': keyName,
      if (encryptedValue != null) 'encrypted_value': encryptedValue,
      if (fieldType != null) 'field_type': fieldType,
      if (isSensitive != null) 'is_sensitive': isSensitive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentFieldsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? cardId,
    Value<String>? keyName,
    Value<Uint8List>? encryptedValue,
    Value<String>? fieldType,
    Value<bool>? isSensitive,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return DocumentFieldsTableCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      keyName: keyName ?? this.keyName,
      encryptedValue: encryptedValue ?? this.encryptedValue,
      fieldType: fieldType ?? this.fieldType,
      isSensitive: isSensitive ?? this.isSensitive,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (keyName.present) {
      map['key_name'] = Variable<String>(keyName.value);
    }
    if (encryptedValue.present) {
      map['encrypted_value'] = Variable<Uint8List>(encryptedValue.value);
    }
    if (fieldType.present) {
      map['field_type'] = Variable<String>(fieldType.value);
    }
    if (isSensitive.present) {
      map['is_sensitive'] = Variable<bool>(isSensitive.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentFieldsTableCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('keyName: $keyName, ')
          ..write('encryptedValue: $encryptedValue, ')
          ..write('fieldType: $fieldType, ')
          ..write('isSensitive: $isSensitive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivityEventsTableTable extends ActivityEventsTable
    with TableInfo<$ActivityEventsTableTable, ActivityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityEventsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sensitiveMeta = const VerificationMeta(
    'sensitive',
  );
  @override
  late final GeneratedColumn<bool> sensitive = GeneratedColumn<bool>(
    'sensitive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sensitive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<String> target = GeneratedColumn<String>(
    'target',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    timestamp,
    cardId,
    sensitive,
    target,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    }
    if (data.containsKey('sensitive')) {
      context.handle(
        _sensitiveMeta,
        sensitive.isAcceptableOrUnknown(data['sensitive']!, _sensitiveMeta),
      );
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      ),
      sensitive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sensitive'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target'],
      ),
    );
  }

  @override
  $ActivityEventsTableTable createAlias(String alias) {
    return $ActivityEventsTableTable(attachedDatabase, alias);
  }
}

class ActivityRow extends DataClass implements Insertable<ActivityRow> {
  final String id;
  final String type;
  final int timestamp;

  /// Reference to the card involved, if any. Deliberately not the label —
  /// the label is resolved at render time so deleted cards degrade gracefully.
  final String? cardId;

  /// True when the event moved sensitive values outside the app.
  final bool sensitive;

  /// Best-effort share destination (e.g. package name). Null when unknown.
  final String? target;
  const ActivityRow({
    required this.id,
    required this.type,
    required this.timestamp,
    this.cardId,
    required this.sensitive,
    this.target,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || cardId != null) {
      map['card_id'] = Variable<String>(cardId);
    }
    map['sensitive'] = Variable<bool>(sensitive);
    if (!nullToAbsent || target != null) {
      map['target'] = Variable<String>(target);
    }
    return map;
  }

  ActivityEventsTableCompanion toCompanion(bool nullToAbsent) {
    return ActivityEventsTableCompanion(
      id: Value(id),
      type: Value(type),
      timestamp: Value(timestamp),
      cardId: cardId == null && nullToAbsent
          ? const Value.absent()
          : Value(cardId),
      sensitive: Value(sensitive),
      target: target == null && nullToAbsent
          ? const Value.absent()
          : Value(target),
    );
  }

  factory ActivityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      cardId: serializer.fromJson<String?>(json['cardId']),
      sensitive: serializer.fromJson<bool>(json['sensitive']),
      target: serializer.fromJson<String?>(json['target']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'timestamp': serializer.toJson<int>(timestamp),
      'cardId': serializer.toJson<String?>(cardId),
      'sensitive': serializer.toJson<bool>(sensitive),
      'target': serializer.toJson<String?>(target),
    };
  }

  ActivityRow copyWith({
    String? id,
    String? type,
    int? timestamp,
    Value<String?> cardId = const Value.absent(),
    bool? sensitive,
    Value<String?> target = const Value.absent(),
  }) => ActivityRow(
    id: id ?? this.id,
    type: type ?? this.type,
    timestamp: timestamp ?? this.timestamp,
    cardId: cardId.present ? cardId.value : this.cardId,
    sensitive: sensitive ?? this.sensitive,
    target: target.present ? target.value : this.target,
  );
  ActivityRow copyWithCompanion(ActivityEventsTableCompanion data) {
    return ActivityRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      sensitive: data.sensitive.present ? data.sensitive.value : this.sensitive,
      target: data.target.present ? data.target.value : this.target,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('timestamp: $timestamp, ')
          ..write('cardId: $cardId, ')
          ..write('sensitive: $sensitive, ')
          ..write('target: $target')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, timestamp, cardId, sensitive, target);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.timestamp == this.timestamp &&
          other.cardId == this.cardId &&
          other.sensitive == this.sensitive &&
          other.target == this.target);
}

class ActivityEventsTableCompanion extends UpdateCompanion<ActivityRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<int> timestamp;
  final Value<String?> cardId;
  final Value<bool> sensitive;
  final Value<String?> target;
  final Value<int> rowid;
  const ActivityEventsTableCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.cardId = const Value.absent(),
    this.sensitive = const Value.absent(),
    this.target = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityEventsTableCompanion.insert({
    required String id,
    required String type,
    required int timestamp,
    this.cardId = const Value.absent(),
    this.sensitive = const Value.absent(),
    this.target = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       timestamp = Value(timestamp);
  static Insertable<ActivityRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<int>? timestamp,
    Expression<String>? cardId,
    Expression<bool>? sensitive,
    Expression<String>? target,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (timestamp != null) 'timestamp': timestamp,
      if (cardId != null) 'card_id': cardId,
      if (sensitive != null) 'sensitive': sensitive,
      if (target != null) 'target': target,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityEventsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<int>? timestamp,
    Value<String?>? cardId,
    Value<bool>? sensitive,
    Value<String?>? target,
    Value<int>? rowid,
  }) {
    return ActivityEventsTableCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      cardId: cardId ?? this.cardId,
      sensitive: sensitive ?? this.sensitive,
      target: target ?? this.target,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (sensitive.present) {
      map['sensitive'] = Variable<bool>(sensitive.value);
    }
    if (target.present) {
      map['target'] = Variable<String>(target.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityEventsTableCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('timestamp: $timestamp, ')
          ..write('cardId: $cardId, ')
          ..write('sensitive: $sensitive, ')
          ..write('target: $target, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CardEntriesTableTable cardEntriesTable = $CardEntriesTableTable(
    this,
  );
  late final $DocumentFieldsTableTable documentFieldsTable =
      $DocumentFieldsTableTable(this);
  late final $ActivityEventsTableTable activityEventsTable =
      $ActivityEventsTableTable(this);
  late final CardsDao cardsDao = CardsDao(this as AppDatabase);
  late final ActivityDao activityDao = ActivityDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cardEntriesTable,
    documentFieldsTable,
    activityEventsTable,
  ];
}

typedef $$CardEntriesTableTableCreateCompanionBuilder =
    CardEntriesTableCompanion Function({
      required String id,
      required String category,
      required String label,
      required int createdAt,
      Value<String?> frontImagePath,
      Value<String?> backImagePath,
      Value<int> rowid,
    });
typedef $$CardEntriesTableTableUpdateCompanionBuilder =
    CardEntriesTableCompanion Function({
      Value<String> id,
      Value<String> category,
      Value<String> label,
      Value<int> createdAt,
      Value<String?> frontImagePath,
      Value<String?> backImagePath,
      Value<int> rowid,
    });

class $$CardEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CardEntriesTableTable> {
  $$CardEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frontImagePath => $composableBuilder(
    column: $table.frontImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backImagePath => $composableBuilder(
    column: $table.backImagePath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CardEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CardEntriesTableTable> {
  $$CardEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frontImagePath => $composableBuilder(
    column: $table.frontImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backImagePath => $composableBuilder(
    column: $table.backImagePath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardEntriesTableTable> {
  $$CardEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get frontImagePath => $composableBuilder(
    column: $table.frontImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backImagePath => $composableBuilder(
    column: $table.backImagePath,
    builder: (column) => column,
  );
}

class $$CardEntriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardEntriesTableTable,
          CardRow,
          $$CardEntriesTableTableFilterComposer,
          $$CardEntriesTableTableOrderingComposer,
          $$CardEntriesTableTableAnnotationComposer,
          $$CardEntriesTableTableCreateCompanionBuilder,
          $$CardEntriesTableTableUpdateCompanionBuilder,
          (
            CardRow,
            BaseReferences<_$AppDatabase, $CardEntriesTableTable, CardRow>,
          ),
          CardRow,
          PrefetchHooks Function()
        > {
  $$CardEntriesTableTableTableManager(
    _$AppDatabase db,
    $CardEntriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardEntriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardEntriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardEntriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String?> frontImagePath = const Value.absent(),
                Value<String?> backImagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardEntriesTableCompanion(
                id: id,
                category: category,
                label: label,
                createdAt: createdAt,
                frontImagePath: frontImagePath,
                backImagePath: backImagePath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String category,
                required String label,
                required int createdAt,
                Value<String?> frontImagePath = const Value.absent(),
                Value<String?> backImagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardEntriesTableCompanion.insert(
                id: id,
                category: category,
                label: label,
                createdAt: createdAt,
                frontImagePath: frontImagePath,
                backImagePath: backImagePath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CardEntriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardEntriesTableTable,
      CardRow,
      $$CardEntriesTableTableFilterComposer,
      $$CardEntriesTableTableOrderingComposer,
      $$CardEntriesTableTableAnnotationComposer,
      $$CardEntriesTableTableCreateCompanionBuilder,
      $$CardEntriesTableTableUpdateCompanionBuilder,
      (CardRow, BaseReferences<_$AppDatabase, $CardEntriesTableTable, CardRow>),
      CardRow,
      PrefetchHooks Function()
    >;
typedef $$DocumentFieldsTableTableCreateCompanionBuilder =
    DocumentFieldsTableCompanion Function({
      required String id,
      required String cardId,
      required String keyName,
      required Uint8List encryptedValue,
      required String fieldType,
      required bool isSensitive,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$DocumentFieldsTableTableUpdateCompanionBuilder =
    DocumentFieldsTableCompanion Function({
      Value<String> id,
      Value<String> cardId,
      Value<String> keyName,
      Value<Uint8List> encryptedValue,
      Value<String> fieldType,
      Value<bool> isSensitive,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$DocumentFieldsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentFieldsTableTable> {
  $$DocumentFieldsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyName => $composableBuilder(
    column: $table.keyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedValue => $composableBuilder(
    column: $table.encryptedValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSensitive => $composableBuilder(
    column: $table.isSensitive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocumentFieldsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentFieldsTableTable> {
  $$DocumentFieldsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyName => $composableBuilder(
    column: $table.keyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedValue => $composableBuilder(
    column: $table.encryptedValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSensitive => $composableBuilder(
    column: $table.isSensitive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentFieldsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentFieldsTableTable> {
  $$DocumentFieldsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get keyName =>
      $composableBuilder(column: $table.keyName, builder: (column) => column);

  GeneratedColumn<Uint8List> get encryptedValue => $composableBuilder(
    column: $table.encryptedValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldType =>
      $composableBuilder(column: $table.fieldType, builder: (column) => column);

  GeneratedColumn<bool> get isSensitive => $composableBuilder(
    column: $table.isSensitive,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$DocumentFieldsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentFieldsTableTable,
          FieldRow,
          $$DocumentFieldsTableTableFilterComposer,
          $$DocumentFieldsTableTableOrderingComposer,
          $$DocumentFieldsTableTableAnnotationComposer,
          $$DocumentFieldsTableTableCreateCompanionBuilder,
          $$DocumentFieldsTableTableUpdateCompanionBuilder,
          (
            FieldRow,
            BaseReferences<_$AppDatabase, $DocumentFieldsTableTable, FieldRow>,
          ),
          FieldRow,
          PrefetchHooks Function()
        > {
  $$DocumentFieldsTableTableTableManager(
    _$AppDatabase db,
    $DocumentFieldsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentFieldsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentFieldsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DocumentFieldsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<String> keyName = const Value.absent(),
                Value<Uint8List> encryptedValue = const Value.absent(),
                Value<String> fieldType = const Value.absent(),
                Value<bool> isSensitive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentFieldsTableCompanion(
                id: id,
                cardId: cardId,
                keyName: keyName,
                encryptedValue: encryptedValue,
                fieldType: fieldType,
                isSensitive: isSensitive,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cardId,
                required String keyName,
                required Uint8List encryptedValue,
                required String fieldType,
                required bool isSensitive,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => DocumentFieldsTableCompanion.insert(
                id: id,
                cardId: cardId,
                keyName: keyName,
                encryptedValue: encryptedValue,
                fieldType: fieldType,
                isSensitive: isSensitive,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocumentFieldsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentFieldsTableTable,
      FieldRow,
      $$DocumentFieldsTableTableFilterComposer,
      $$DocumentFieldsTableTableOrderingComposer,
      $$DocumentFieldsTableTableAnnotationComposer,
      $$DocumentFieldsTableTableCreateCompanionBuilder,
      $$DocumentFieldsTableTableUpdateCompanionBuilder,
      (
        FieldRow,
        BaseReferences<_$AppDatabase, $DocumentFieldsTableTable, FieldRow>,
      ),
      FieldRow,
      PrefetchHooks Function()
    >;
typedef $$ActivityEventsTableTableCreateCompanionBuilder =
    ActivityEventsTableCompanion Function({
      required String id,
      required String type,
      required int timestamp,
      Value<String?> cardId,
      Value<bool> sensitive,
      Value<String?> target,
      Value<int> rowid,
    });
typedef $$ActivityEventsTableTableUpdateCompanionBuilder =
    ActivityEventsTableCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<int> timestamp,
      Value<String?> cardId,
      Value<bool> sensitive,
      Value<String?> target,
      Value<int> rowid,
    });

class $$ActivityEventsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityEventsTableTable> {
  $$ActivityEventsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sensitive => $composableBuilder(
    column: $table.sensitive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivityEventsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityEventsTableTable> {
  $$ActivityEventsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sensitive => $composableBuilder(
    column: $table.sensitive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivityEventsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityEventsTableTable> {
  $$ActivityEventsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<bool> get sensitive =>
      $composableBuilder(column: $table.sensitive, builder: (column) => column);

  GeneratedColumn<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);
}

class $$ActivityEventsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivityEventsTableTable,
          ActivityRow,
          $$ActivityEventsTableTableFilterComposer,
          $$ActivityEventsTableTableOrderingComposer,
          $$ActivityEventsTableTableAnnotationComposer,
          $$ActivityEventsTableTableCreateCompanionBuilder,
          $$ActivityEventsTableTableUpdateCompanionBuilder,
          (
            ActivityRow,
            BaseReferences<
              _$AppDatabase,
              $ActivityEventsTableTable,
              ActivityRow
            >,
          ),
          ActivityRow,
          PrefetchHooks Function()
        > {
  $$ActivityEventsTableTableTableManager(
    _$AppDatabase db,
    $ActivityEventsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityEventsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityEventsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ActivityEventsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<String?> cardId = const Value.absent(),
                Value<bool> sensitive = const Value.absent(),
                Value<String?> target = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivityEventsTableCompanion(
                id: id,
                type: type,
                timestamp: timestamp,
                cardId: cardId,
                sensitive: sensitive,
                target: target,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required int timestamp,
                Value<String?> cardId = const Value.absent(),
                Value<bool> sensitive = const Value.absent(),
                Value<String?> target = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivityEventsTableCompanion.insert(
                id: id,
                type: type,
                timestamp: timestamp,
                cardId: cardId,
                sensitive: sensitive,
                target: target,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivityEventsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivityEventsTableTable,
      ActivityRow,
      $$ActivityEventsTableTableFilterComposer,
      $$ActivityEventsTableTableOrderingComposer,
      $$ActivityEventsTableTableAnnotationComposer,
      $$ActivityEventsTableTableCreateCompanionBuilder,
      $$ActivityEventsTableTableUpdateCompanionBuilder,
      (
        ActivityRow,
        BaseReferences<_$AppDatabase, $ActivityEventsTableTable, ActivityRow>,
      ),
      ActivityRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CardEntriesTableTableTableManager get cardEntriesTable =>
      $$CardEntriesTableTableTableManager(_db, _db.cardEntriesTable);
  $$DocumentFieldsTableTableTableManager get documentFieldsTable =>
      $$DocumentFieldsTableTableTableManager(_db, _db.documentFieldsTable);
  $$ActivityEventsTableTableTableManager get activityEventsTable =>
      $$ActivityEventsTableTableTableManager(_db, _db.activityEventsTable);
}
