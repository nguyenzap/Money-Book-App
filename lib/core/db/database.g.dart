// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WalletsTable extends Wallets with TableInfo<$WalletsTable, Wallet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
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
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _initialBalanceMeta = const VerificationMeta(
    'initialBalance',
  );
  @override
  late final GeneratedColumn<int> initialBalance = GeneratedColumn<int>(
    'initial_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    initialBalance,
    iconKey,
    colorValue,
    note,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Wallet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
        _initialBalanceMeta,
        initialBalance.isAcceptableOrUnknown(
          data['initial_balance']!,
          _initialBalanceMeta,
        ),
      );
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Wallet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Wallet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      initialBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_balance'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      ),
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WalletsTable createAlias(String alias) {
    return $WalletsTable(attachedDatabase, alias);
  }
}

class Wallet extends DataClass implements Insertable<Wallet> {
  final int id;
  final String name;

  /// cash | bank | ewallet | credit | savings | other
  final String type;

  /// Số dư ban đầu, tính bằng ĐỒNG. Có thể âm (thẻ tín dụng).
  final int initialBalance;
  final String? iconKey;
  final int? colorValue;
  final String? note;

  /// Ví đã lưu trữ: ẩn khỏi các ô chọn nhưng vẫn giữ nguyên lịch sử.
  /// Dùng thay cho xoá, vì xoá ví có giao dịch sẽ làm thủng sổ sách.
  final bool isArchived;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    this.iconKey,
    this.colorValue,
    this.note,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['initial_balance'] = Variable<int>(initialBalance);
    if (!nullToAbsent || iconKey != null) {
      map['icon_key'] = Variable<String>(iconKey);
    }
    if (!nullToAbsent || colorValue != null) {
      map['color_value'] = Variable<int>(colorValue);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  WalletsCompanion toCompanion(bool nullToAbsent) {
    return WalletsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      initialBalance: Value(initialBalance),
      iconKey: iconKey == null && nullToAbsent
          ? const Value.absent()
          : Value(iconKey),
      colorValue: colorValue == null && nullToAbsent
          ? const Value.absent()
          : Value(colorValue),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isArchived: Value(isArchived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Wallet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Wallet(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      initialBalance: serializer.fromJson<int>(json['initialBalance']),
      iconKey: serializer.fromJson<String?>(json['iconKey']),
      colorValue: serializer.fromJson<int?>(json['colorValue']),
      note: serializer.fromJson<String?>(json['note']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'initialBalance': serializer.toJson<int>(initialBalance),
      'iconKey': serializer.toJson<String?>(iconKey),
      'colorValue': serializer.toJson<int?>(colorValue),
      'note': serializer.toJson<String?>(note),
      'isArchived': serializer.toJson<bool>(isArchived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Wallet copyWith({
    int? id,
    String? name,
    String? type,
    int? initialBalance,
    Value<String?> iconKey = const Value.absent(),
    Value<int?> colorValue = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? isArchived,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => Wallet(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    initialBalance: initialBalance ?? this.initialBalance,
    iconKey: iconKey.present ? iconKey.value : this.iconKey,
    colorValue: colorValue.present ? colorValue.value : this.colorValue,
    note: note.present ? note.value : this.note,
    isArchived: isArchived ?? this.isArchived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Wallet copyWithCompanion(WalletsCompanion data) {
    return Wallet(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      initialBalance: data.initialBalance.present
          ? data.initialBalance.value
          : this.initialBalance,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      note: data.note.present ? data.note.value : this.note,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Wallet(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorValue: $colorValue, ')
          ..write('note: $note, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    initialBalance,
    iconKey,
    colorValue,
    note,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Wallet &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.initialBalance == this.initialBalance &&
          other.iconKey == this.iconKey &&
          other.colorValue == this.colorValue &&
          other.note == this.note &&
          other.isArchived == this.isArchived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WalletsCompanion extends UpdateCompanion<Wallet> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<int> initialBalance;
  final Value<String?> iconKey;
  final Value<int?> colorValue;
  final Value<String?> note;
  final Value<bool> isArchived;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const WalletsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.note = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WalletsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.type = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.note = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Wallet> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? initialBalance,
    Expression<String>? iconKey,
    Expression<int>? colorValue,
    Expression<String>? note,
    Expression<bool>? isArchived,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorValue != null) 'color_value': colorValue,
      if (note != null) 'note': note,
      if (isArchived != null) 'is_archived': isArchived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WalletsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? type,
    Value<int>? initialBalance,
    Value<String?>? iconKey,
    Value<int?>? colorValue,
    Value<String?>? note,
    Value<bool>? isArchived,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return WalletsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      note: note ?? this.note,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (initialBalance.present) {
      map['initial_balance'] = Variable<int>(initialBalance.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorValue: $colorValue, ')
          ..write('note: $note, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flowMeta = const VerificationMeta('flow');
  @override
  late final GeneratedColumn<String> flow = GeneratedColumn<String>(
    'flow',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    flow,
    iconKey,
    colorValue,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('flow')) {
      context.handle(
        _flowMeta,
        flow.isAcceptableOrUnknown(data['flow']!, _flowMeta),
      );
    } else if (isInserting) {
      context.missing(_flowMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      flow: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flow'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      ),
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;

  /// 'expense' hoặc 'income' — một danh mục chỉ thuộc một chiều.
  final String flow;
  final String? iconKey;
  final int? colorValue;
  final bool isArchived;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const Category({
    required this.id,
    required this.name,
    required this.flow,
    this.iconKey,
    this.colorValue,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['flow'] = Variable<String>(flow);
    if (!nullToAbsent || iconKey != null) {
      map['icon_key'] = Variable<String>(iconKey);
    }
    if (!nullToAbsent || colorValue != null) {
      map['color_value'] = Variable<int>(colorValue);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      flow: Value(flow),
      iconKey: iconKey == null && nullToAbsent
          ? const Value.absent()
          : Value(iconKey),
      colorValue: colorValue == null && nullToAbsent
          ? const Value.absent()
          : Value(colorValue),
      isArchived: Value(isArchived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      flow: serializer.fromJson<String>(json['flow']),
      iconKey: serializer.fromJson<String?>(json['iconKey']),
      colorValue: serializer.fromJson<int?>(json['colorValue']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'flow': serializer.toJson<String>(flow),
      'iconKey': serializer.toJson<String?>(iconKey),
      'colorValue': serializer.toJson<int?>(colorValue),
      'isArchived': serializer.toJson<bool>(isArchived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? flow,
    Value<String?> iconKey = const Value.absent(),
    Value<int?> colorValue = const Value.absent(),
    bool? isArchived,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    flow: flow ?? this.flow,
    iconKey: iconKey.present ? iconKey.value : this.iconKey,
    colorValue: colorValue.present ? colorValue.value : this.colorValue,
    isArchived: isArchived ?? this.isArchived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      flow: data.flow.present ? data.flow.value : this.flow,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('flow: $flow, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorValue: $colorValue, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    flow,
    iconKey,
    colorValue,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.flow == this.flow &&
          other.iconKey == this.iconKey &&
          other.colorValue == this.colorValue &&
          other.isArchived == this.isArchived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> flow;
  final Value<String?> iconKey;
  final Value<int?> colorValue;
  final Value<bool> isArchived;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.flow = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String flow,
    this.iconKey = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : name = Value(name),
       flow = Value(flow),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? flow,
    Expression<String>? iconKey,
    Expression<int>? colorValue,
    Expression<bool>? isArchived,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (flow != null) 'flow': flow,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorValue != null) 'color_value': colorValue,
      if (isArchived != null) 'is_archived': isArchived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? flow,
    Value<String?>? iconKey,
    Value<int?>? colorValue,
    Value<bool>? isArchived,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      flow: flow ?? this.flow,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (flow.present) {
      map['flow'] = Variable<String>(flow.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('flow: $flow, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorValue: $colorValue, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PeopleTable extends People with TableInfo<$PeopleTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarColorMeta = const VerificationMeta(
    'avatarColor',
  );
  @override
  late final GeneratedColumn<int> avatarColor = GeneratedColumn<int>(
    'avatar_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    phone,
    note,
    avatarColor,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('avatar_color')) {
      context.handle(
        _avatarColorMeta,
        avatarColor.isAcceptableOrUnknown(
          data['avatar_color']!,
          _avatarColorMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      avatarColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar_color'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final int id;
  final String name;
  final String? phone;
  final String? note;
  final int? avatarColor;
  final bool isArchived;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const Person({
    required this.id,
    required this.name,
    this.phone,
    this.note,
    this.avatarColor,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || avatarColor != null) {
      map['avatar_color'] = Variable<int>(avatarColor);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(id),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      avatarColor: avatarColor == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarColor),
      isArchived: Value(isArchived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      note: serializer.fromJson<String?>(json['note']),
      avatarColor: serializer.fromJson<int?>(json['avatarColor']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'note': serializer.toJson<String?>(note),
      'avatarColor': serializer.toJson<int?>(avatarColor),
      'isArchived': serializer.toJson<bool>(isArchived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Person copyWith({
    int? id,
    String? name,
    Value<String?> phone = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<int?> avatarColor = const Value.absent(),
    bool? isArchived,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => Person(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    note: note.present ? note.value : this.note,
    avatarColor: avatarColor.present ? avatarColor.value : this.avatarColor,
    isArchived: isArchived ?? this.isArchived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Person copyWithCompanion(PeopleCompanion data) {
    return Person(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      note: data.note.present ? data.note.value : this.note,
      avatarColor: data.avatarColor.present
          ? data.avatarColor.value
          : this.avatarColor,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    phone,
    note,
    avatarColor,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.note == this.note &&
          other.avatarColor == this.avatarColor &&
          other.isArchived == this.isArchived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PeopleCompanion extends UpdateCompanion<Person> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> note;
  final Value<int?> avatarColor;
  final Value<bool> isArchived;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PeopleCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Person> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? note,
    Expression<int>? avatarColor,
    Expression<bool>? isArchived,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (note != null) 'note': note,
      if (avatarColor != null) 'avatar_color': avatarColor,
      if (isArchived != null) 'is_archived': isArchived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PeopleCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? phone,
    Value<String?>? note,
    Value<int?>? avatarColor,
    Value<bool>? isArchived,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return PeopleCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      avatarColor: avatarColor ?? this.avatarColor,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (avatarColor.present) {
      map['avatar_color'] = Variable<int>(avatarColor.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RecurringTemplatesTable extends RecurringTemplates
    with TableInfo<$RecurringTemplatesTable, RecurringTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TxKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TxKind>($RecurringTemplatesTable.$converterkind);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walletFromIdMeta = const VerificationMeta(
    'walletFromId',
  );
  @override
  late final GeneratedColumn<int> walletFromId = GeneratedColumn<int>(
    'wallet_from_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _walletToIdMeta = const VerificationMeta(
    'walletToId',
  );
  @override
  late final GeneratedColumn<int> walletToId = GeneratedColumn<int>(
    'wallet_to_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _freqMeta = const VerificationMeta('freq');
  @override
  late final GeneratedColumn<String> freq = GeneratedColumn<String>(
    'freq',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthly'),
  );
  static const VerificationMeta _intervalNMeta = const VerificationMeta(
    'intervalN',
  );
  @override
  late final GeneratedColumn<int> intervalN = GeneratedColumn<int>(
    'interval_n',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _dayOfMonthMeta = const VerificationMeta(
    'dayOfMonth',
  );
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
    'day_of_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextDueAtMeta = const VerificationMeta(
    'nextDueAt',
  );
  @override
  late final GeneratedColumn<int> nextDueAt = GeneratedColumn<int>(
    'next_due_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastRunAtMeta = const VerificationMeta(
    'lastRunAt',
  );
  @override
  late final GeneratedColumn<int> lastRunAt = GeneratedColumn<int>(
    'last_run_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    kind,
    amount,
    walletFromId,
    walletToId,
    categoryId,
    personId,
    note,
    freq,
    intervalN,
    dayOfMonth,
    weekday,
    nextDueAt,
    lastRunAt,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('wallet_from_id')) {
      context.handle(
        _walletFromIdMeta,
        walletFromId.isAcceptableOrUnknown(
          data['wallet_from_id']!,
          _walletFromIdMeta,
        ),
      );
    }
    if (data.containsKey('wallet_to_id')) {
      context.handle(
        _walletToIdMeta,
        walletToId.isAcceptableOrUnknown(
          data['wallet_to_id']!,
          _walletToIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('freq')) {
      context.handle(
        _freqMeta,
        freq.isAcceptableOrUnknown(data['freq']!, _freqMeta),
      );
    }
    if (data.containsKey('interval_n')) {
      context.handle(
        _intervalNMeta,
        intervalN.isAcceptableOrUnknown(data['interval_n']!, _intervalNMeta),
      );
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
        _dayOfMonthMeta,
        dayOfMonth.isAcceptableOrUnknown(
          data['day_of_month']!,
          _dayOfMonthMeta,
        ),
      );
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    }
    if (data.containsKey('next_due_at')) {
      context.handle(
        _nextDueAtMeta,
        nextDueAt.isAcceptableOrUnknown(data['next_due_at']!, _nextDueAtMeta),
      );
    }
    if (data.containsKey('last_run_at')) {
      context.handle(
        _lastRunAtMeta,
        lastRunAt.isAcceptableOrUnknown(data['last_run_at']!, _lastRunAtMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      kind: $RecurringTemplatesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      walletFromId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wallet_from_id'],
      ),
      walletToId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wallet_to_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      freq: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}freq'],
      )!,
      intervalN: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_n'],
      )!,
      dayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_month'],
      ),
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      ),
      nextDueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_due_at'],
      ),
      lastRunAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_run_at'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RecurringTemplatesTable createAlias(String alias) {
    return $RecurringTemplatesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TxKind, String, String> $converterkind =
      const EnumNameConverter<TxKind>(TxKind.values);
}

class RecurringTemplate extends DataClass
    implements Insertable<RecurringTemplate> {
  final int id;
  final String title;
  final TxKind kind;
  final int amount;
  final int? walletFromId;
  final int? walletToId;
  final int? categoryId;
  final int? personId;
  final String? note;

  /// none | daily | weekly | monthly | yearly
  final String freq;
  final int intervalN;

  /// 1..31 cho chu kỳ tháng. Ngày 31 ở tháng thiếu sẽ tự lùi về ngày cuối.
  final int? dayOfMonth;

  /// 1..7 theo DateTime.weekday, cho chu kỳ tuần.
  final int? weekday;
  final int? nextDueAt;
  final int? lastRunAt;
  final bool isActive;
  final int createdAt;
  final int updatedAt;
  const RecurringTemplate({
    required this.id,
    required this.title,
    required this.kind,
    required this.amount,
    this.walletFromId,
    this.walletToId,
    this.categoryId,
    this.personId,
    this.note,
    required this.freq,
    required this.intervalN,
    this.dayOfMonth,
    this.weekday,
    this.nextDueAt,
    this.lastRunAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    {
      map['kind'] = Variable<String>(
        $RecurringTemplatesTable.$converterkind.toSql(kind),
      );
    }
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || walletFromId != null) {
      map['wallet_from_id'] = Variable<int>(walletFromId);
    }
    if (!nullToAbsent || walletToId != null) {
      map['wallet_to_id'] = Variable<int>(walletToId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<int>(personId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['freq'] = Variable<String>(freq);
    map['interval_n'] = Variable<int>(intervalN);
    if (!nullToAbsent || dayOfMonth != null) {
      map['day_of_month'] = Variable<int>(dayOfMonth);
    }
    if (!nullToAbsent || weekday != null) {
      map['weekday'] = Variable<int>(weekday);
    }
    if (!nullToAbsent || nextDueAt != null) {
      map['next_due_at'] = Variable<int>(nextDueAt);
    }
    if (!nullToAbsent || lastRunAt != null) {
      map['last_run_at'] = Variable<int>(lastRunAt);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  RecurringTemplatesCompanion toCompanion(bool nullToAbsent) {
    return RecurringTemplatesCompanion(
      id: Value(id),
      title: Value(title),
      kind: Value(kind),
      amount: Value(amount),
      walletFromId: walletFromId == null && nullToAbsent
          ? const Value.absent()
          : Value(walletFromId),
      walletToId: walletToId == null && nullToAbsent
          ? const Value.absent()
          : Value(walletToId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      freq: Value(freq),
      intervalN: Value(intervalN),
      dayOfMonth: dayOfMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfMonth),
      weekday: weekday == null && nullToAbsent
          ? const Value.absent()
          : Value(weekday),
      nextDueAt: nextDueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDueAt),
      lastRunAt: lastRunAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRunAt),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RecurringTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringTemplate(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      kind: $RecurringTemplatesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      amount: serializer.fromJson<int>(json['amount']),
      walletFromId: serializer.fromJson<int?>(json['walletFromId']),
      walletToId: serializer.fromJson<int?>(json['walletToId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      personId: serializer.fromJson<int?>(json['personId']),
      note: serializer.fromJson<String?>(json['note']),
      freq: serializer.fromJson<String>(json['freq']),
      intervalN: serializer.fromJson<int>(json['intervalN']),
      dayOfMonth: serializer.fromJson<int?>(json['dayOfMonth']),
      weekday: serializer.fromJson<int?>(json['weekday']),
      nextDueAt: serializer.fromJson<int?>(json['nextDueAt']),
      lastRunAt: serializer.fromJson<int?>(json['lastRunAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'kind': serializer.toJson<String>(
        $RecurringTemplatesTable.$converterkind.toJson(kind),
      ),
      'amount': serializer.toJson<int>(amount),
      'walletFromId': serializer.toJson<int?>(walletFromId),
      'walletToId': serializer.toJson<int?>(walletToId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'personId': serializer.toJson<int?>(personId),
      'note': serializer.toJson<String?>(note),
      'freq': serializer.toJson<String>(freq),
      'intervalN': serializer.toJson<int>(intervalN),
      'dayOfMonth': serializer.toJson<int?>(dayOfMonth),
      'weekday': serializer.toJson<int?>(weekday),
      'nextDueAt': serializer.toJson<int?>(nextDueAt),
      'lastRunAt': serializer.toJson<int?>(lastRunAt),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  RecurringTemplate copyWith({
    int? id,
    String? title,
    TxKind? kind,
    int? amount,
    Value<int?> walletFromId = const Value.absent(),
    Value<int?> walletToId = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
    Value<int?> personId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? freq,
    int? intervalN,
    Value<int?> dayOfMonth = const Value.absent(),
    Value<int?> weekday = const Value.absent(),
    Value<int?> nextDueAt = const Value.absent(),
    Value<int?> lastRunAt = const Value.absent(),
    bool? isActive,
    int? createdAt,
    int? updatedAt,
  }) => RecurringTemplate(
    id: id ?? this.id,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    walletFromId: walletFromId.present ? walletFromId.value : this.walletFromId,
    walletToId: walletToId.present ? walletToId.value : this.walletToId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    personId: personId.present ? personId.value : this.personId,
    note: note.present ? note.value : this.note,
    freq: freq ?? this.freq,
    intervalN: intervalN ?? this.intervalN,
    dayOfMonth: dayOfMonth.present ? dayOfMonth.value : this.dayOfMonth,
    weekday: weekday.present ? weekday.value : this.weekday,
    nextDueAt: nextDueAt.present ? nextDueAt.value : this.nextDueAt,
    lastRunAt: lastRunAt.present ? lastRunAt.value : this.lastRunAt,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RecurringTemplate copyWithCompanion(RecurringTemplatesCompanion data) {
    return RecurringTemplate(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      walletFromId: data.walletFromId.present
          ? data.walletFromId.value
          : this.walletFromId,
      walletToId: data.walletToId.present
          ? data.walletToId.value
          : this.walletToId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      personId: data.personId.present ? data.personId.value : this.personId,
      note: data.note.present ? data.note.value : this.note,
      freq: data.freq.present ? data.freq.value : this.freq,
      intervalN: data.intervalN.present ? data.intervalN.value : this.intervalN,
      dayOfMonth: data.dayOfMonth.present
          ? data.dayOfMonth.value
          : this.dayOfMonth,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      nextDueAt: data.nextDueAt.present ? data.nextDueAt.value : this.nextDueAt,
      lastRunAt: data.lastRunAt.present ? data.lastRunAt.value : this.lastRunAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTemplate(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('walletFromId: $walletFromId, ')
          ..write('walletToId: $walletToId, ')
          ..write('categoryId: $categoryId, ')
          ..write('personId: $personId, ')
          ..write('note: $note, ')
          ..write('freq: $freq, ')
          ..write('intervalN: $intervalN, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('weekday: $weekday, ')
          ..write('nextDueAt: $nextDueAt, ')
          ..write('lastRunAt: $lastRunAt, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    kind,
    amount,
    walletFromId,
    walletToId,
    categoryId,
    personId,
    note,
    freq,
    intervalN,
    dayOfMonth,
    weekday,
    nextDueAt,
    lastRunAt,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringTemplate &&
          other.id == this.id &&
          other.title == this.title &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.walletFromId == this.walletFromId &&
          other.walletToId == this.walletToId &&
          other.categoryId == this.categoryId &&
          other.personId == this.personId &&
          other.note == this.note &&
          other.freq == this.freq &&
          other.intervalN == this.intervalN &&
          other.dayOfMonth == this.dayOfMonth &&
          other.weekday == this.weekday &&
          other.nextDueAt == this.nextDueAt &&
          other.lastRunAt == this.lastRunAt &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecurringTemplatesCompanion extends UpdateCompanion<RecurringTemplate> {
  final Value<int> id;
  final Value<String> title;
  final Value<TxKind> kind;
  final Value<int> amount;
  final Value<int?> walletFromId;
  final Value<int?> walletToId;
  final Value<int?> categoryId;
  final Value<int?> personId;
  final Value<String?> note;
  final Value<String> freq;
  final Value<int> intervalN;
  final Value<int?> dayOfMonth;
  final Value<int?> weekday;
  final Value<int?> nextDueAt;
  final Value<int?> lastRunAt;
  final Value<bool> isActive;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const RecurringTemplatesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.walletFromId = const Value.absent(),
    this.walletToId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.personId = const Value.absent(),
    this.note = const Value.absent(),
    this.freq = const Value.absent(),
    this.intervalN = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.weekday = const Value.absent(),
    this.nextDueAt = const Value.absent(),
    this.lastRunAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RecurringTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required TxKind kind,
    required int amount,
    this.walletFromId = const Value.absent(),
    this.walletToId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.personId = const Value.absent(),
    this.note = const Value.absent(),
    this.freq = const Value.absent(),
    this.intervalN = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.weekday = const Value.absent(),
    this.nextDueAt = const Value.absent(),
    this.lastRunAt = const Value.absent(),
    this.isActive = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : title = Value(title),
       kind = Value(kind),
       amount = Value(amount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<RecurringTemplate> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<int>? walletFromId,
    Expression<int>? walletToId,
    Expression<int>? categoryId,
    Expression<int>? personId,
    Expression<String>? note,
    Expression<String>? freq,
    Expression<int>? intervalN,
    Expression<int>? dayOfMonth,
    Expression<int>? weekday,
    Expression<int>? nextDueAt,
    Expression<int>? lastRunAt,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (walletFromId != null) 'wallet_from_id': walletFromId,
      if (walletToId != null) 'wallet_to_id': walletToId,
      if (categoryId != null) 'category_id': categoryId,
      if (personId != null) 'person_id': personId,
      if (note != null) 'note': note,
      if (freq != null) 'freq': freq,
      if (intervalN != null) 'interval_n': intervalN,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (weekday != null) 'weekday': weekday,
      if (nextDueAt != null) 'next_due_at': nextDueAt,
      if (lastRunAt != null) 'last_run_at': lastRunAt,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RecurringTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<TxKind>? kind,
    Value<int>? amount,
    Value<int?>? walletFromId,
    Value<int?>? walletToId,
    Value<int?>? categoryId,
    Value<int?>? personId,
    Value<String?>? note,
    Value<String>? freq,
    Value<int>? intervalN,
    Value<int?>? dayOfMonth,
    Value<int?>? weekday,
    Value<int?>? nextDueAt,
    Value<int?>? lastRunAt,
    Value<bool>? isActive,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return RecurringTemplatesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      walletFromId: walletFromId ?? this.walletFromId,
      walletToId: walletToId ?? this.walletToId,
      categoryId: categoryId ?? this.categoryId,
      personId: personId ?? this.personId,
      note: note ?? this.note,
      freq: freq ?? this.freq,
      intervalN: intervalN ?? this.intervalN,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weekday: weekday ?? this.weekday,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $RecurringTemplatesTable.$converterkind.toSql(kind.value),
      );
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (walletFromId.present) {
      map['wallet_from_id'] = Variable<int>(walletFromId.value);
    }
    if (walletToId.present) {
      map['wallet_to_id'] = Variable<int>(walletToId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (freq.present) {
      map['freq'] = Variable<String>(freq.value);
    }
    if (intervalN.present) {
      map['interval_n'] = Variable<int>(intervalN.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (nextDueAt.present) {
      map['next_due_at'] = Variable<int>(nextDueAt.value);
    }
    if (lastRunAt.present) {
      map['last_run_at'] = Variable<int>(lastRunAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('walletFromId: $walletFromId, ')
          ..write('walletToId: $walletToId, ')
          ..write('categoryId: $categoryId, ')
          ..write('personId: $personId, ')
          ..write('note: $note, ')
          ..write('freq: $freq, ')
          ..write('intervalN: $intervalN, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('weekday: $weekday, ')
          ..write('nextDueAt: $nextDueAt, ')
          ..write('lastRunAt: $lastRunAt, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FundsTable extends Funds with TableInfo<$FundsTable, Fund> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walletIdMeta = const VerificationMeta(
    'walletId',
  );
  @override
  late final GeneratedColumn<int> walletId = GeneratedColumn<int>(
    'wallet_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wallets (id)',
    ),
  );
  static const VerificationMeta _targetAmountMeta = const VerificationMeta(
    'targetAmount',
  );
  @override
  late final GeneratedColumn<int> targetAmount = GeneratedColumn<int>(
    'target_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDayKeyMeta = const VerificationMeta(
    'dueDayKey',
  );
  @override
  late final GeneratedColumn<int> dueDayKey = GeneratedColumn<int>(
    'due_day_key',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    walletId,
    targetAmount,
    dueDayKey,
    note,
    iconKey,
    colorValue,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'funds';
  @override
  VerificationContext validateIntegrity(
    Insertable<Fund> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_walletIdMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
        _targetAmountMeta,
        targetAmount.isAcceptableOrUnknown(
          data['target_amount']!,
          _targetAmountMeta,
        ),
      );
    }
    if (data.containsKey('due_day_key')) {
      context.handle(
        _dueDayKeyMeta,
        dueDayKey.isAcceptableOrUnknown(data['due_day_key']!, _dueDayKeyMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Fund map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Fund(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wallet_id'],
      )!,
      targetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_amount'],
      ),
      dueDayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day_key'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      ),
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FundsTable createAlias(String alias) {
    return $FundsTable(attachedDatabase, alias);
  }
}

class Fund extends DataClass implements Insertable<Fund> {
  final int id;
  final String name;

  /// Ví đang giữ tiền của quỹ này. Xoá ví thì quỹ mất chỗ neo nên chặn lại.
  final int walletId;

  /// Số tiền mục tiêu, hoặc null nếu chỉ để dành mà không có đích cụ thể.
  final int? targetAmount;

  /// Hạn cần dùng tới, dạng yyyymmdd. Dùng để nhắc và để sắp xếp.
  final int? dueDayKey;
  final String? note;
  final String? iconKey;
  final int? colorValue;

  /// Quỹ đã dùng xong nhưng giữ lại để xem lịch sử.
  final bool isArchived;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const Fund({
    required this.id,
    required this.name,
    required this.walletId,
    this.targetAmount,
    this.dueDayKey,
    this.note,
    this.iconKey,
    this.colorValue,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['wallet_id'] = Variable<int>(walletId);
    if (!nullToAbsent || targetAmount != null) {
      map['target_amount'] = Variable<int>(targetAmount);
    }
    if (!nullToAbsent || dueDayKey != null) {
      map['due_day_key'] = Variable<int>(dueDayKey);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || iconKey != null) {
      map['icon_key'] = Variable<String>(iconKey);
    }
    if (!nullToAbsent || colorValue != null) {
      map['color_value'] = Variable<int>(colorValue);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  FundsCompanion toCompanion(bool nullToAbsent) {
    return FundsCompanion(
      id: Value(id),
      name: Value(name),
      walletId: Value(walletId),
      targetAmount: targetAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(targetAmount),
      dueDayKey: dueDayKey == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDayKey),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      iconKey: iconKey == null && nullToAbsent
          ? const Value.absent()
          : Value(iconKey),
      colorValue: colorValue == null && nullToAbsent
          ? const Value.absent()
          : Value(colorValue),
      isArchived: Value(isArchived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Fund.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Fund(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      walletId: serializer.fromJson<int>(json['walletId']),
      targetAmount: serializer.fromJson<int?>(json['targetAmount']),
      dueDayKey: serializer.fromJson<int?>(json['dueDayKey']),
      note: serializer.fromJson<String?>(json['note']),
      iconKey: serializer.fromJson<String?>(json['iconKey']),
      colorValue: serializer.fromJson<int?>(json['colorValue']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'walletId': serializer.toJson<int>(walletId),
      'targetAmount': serializer.toJson<int?>(targetAmount),
      'dueDayKey': serializer.toJson<int?>(dueDayKey),
      'note': serializer.toJson<String?>(note),
      'iconKey': serializer.toJson<String?>(iconKey),
      'colorValue': serializer.toJson<int?>(colorValue),
      'isArchived': serializer.toJson<bool>(isArchived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Fund copyWith({
    int? id,
    String? name,
    int? walletId,
    Value<int?> targetAmount = const Value.absent(),
    Value<int?> dueDayKey = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> iconKey = const Value.absent(),
    Value<int?> colorValue = const Value.absent(),
    bool? isArchived,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => Fund(
    id: id ?? this.id,
    name: name ?? this.name,
    walletId: walletId ?? this.walletId,
    targetAmount: targetAmount.present ? targetAmount.value : this.targetAmount,
    dueDayKey: dueDayKey.present ? dueDayKey.value : this.dueDayKey,
    note: note.present ? note.value : this.note,
    iconKey: iconKey.present ? iconKey.value : this.iconKey,
    colorValue: colorValue.present ? colorValue.value : this.colorValue,
    isArchived: isArchived ?? this.isArchived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Fund copyWithCompanion(FundsCompanion data) {
    return Fund(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      dueDayKey: data.dueDayKey.present ? data.dueDayKey.value : this.dueDayKey,
      note: data.note.present ? data.note.value : this.note,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Fund(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('walletId: $walletId, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('dueDayKey: $dueDayKey, ')
          ..write('note: $note, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorValue: $colorValue, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    walletId,
    targetAmount,
    dueDayKey,
    note,
    iconKey,
    colorValue,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Fund &&
          other.id == this.id &&
          other.name == this.name &&
          other.walletId == this.walletId &&
          other.targetAmount == this.targetAmount &&
          other.dueDayKey == this.dueDayKey &&
          other.note == this.note &&
          other.iconKey == this.iconKey &&
          other.colorValue == this.colorValue &&
          other.isArchived == this.isArchived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FundsCompanion extends UpdateCompanion<Fund> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> walletId;
  final Value<int?> targetAmount;
  final Value<int?> dueDayKey;
  final Value<String?> note;
  final Value<String?> iconKey;
  final Value<int?> colorValue;
  final Value<bool> isArchived;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const FundsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.walletId = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.dueDayKey = const Value.absent(),
    this.note = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FundsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int walletId,
    this.targetAmount = const Value.absent(),
    this.dueDayKey = const Value.absent(),
    this.note = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : name = Value(name),
       walletId = Value(walletId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Fund> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? walletId,
    Expression<int>? targetAmount,
    Expression<int>? dueDayKey,
    Expression<String>? note,
    Expression<String>? iconKey,
    Expression<int>? colorValue,
    Expression<bool>? isArchived,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (walletId != null) 'wallet_id': walletId,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (dueDayKey != null) 'due_day_key': dueDayKey,
      if (note != null) 'note': note,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorValue != null) 'color_value': colorValue,
      if (isArchived != null) 'is_archived': isArchived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FundsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? walletId,
    Value<int?>? targetAmount,
    Value<int?>? dueDayKey,
    Value<String?>? note,
    Value<String?>? iconKey,
    Value<int?>? colorValue,
    Value<bool>? isArchived,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return FundsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      walletId: walletId ?? this.walletId,
      targetAmount: targetAmount ?? this.targetAmount,
      dueDayKey: dueDayKey ?? this.dueDayKey,
      note: note ?? this.note,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<int>(walletId.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<int>(targetAmount.value);
    }
    if (dueDayKey.present) {
      map['due_day_key'] = Variable<int>(dueDayKey.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FundsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('walletId: $walletId, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('dueDayKey: $dueDayKey, ')
          ..write('note: $note, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorValue: $colorValue, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TxKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TxKind>($TransactionsTable.$converterkind);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<int> dayKey = GeneratedColumn<int>(
    'day_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthKeyMeta = const VerificationMeta(
    'monthKey',
  );
  @override
  late final GeneratedColumn<int> monthKey = GeneratedColumn<int>(
    'month_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walletFromIdMeta = const VerificationMeta(
    'walletFromId',
  );
  @override
  late final GeneratedColumn<int> walletFromId = GeneratedColumn<int>(
    'wallet_from_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wallets (id)',
    ),
  );
  static const VerificationMeta _walletToIdMeta = const VerificationMeta(
    'walletToId',
  );
  @override
  late final GeneratedColumn<int> walletToId = GeneratedColumn<int>(
    'wallet_to_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wallets (id)',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  static const VerificationMeta _debtDeltaMeta = const VerificationMeta(
    'debtDelta',
  );
  @override
  late final GeneratedColumn<int> debtDelta = GeneratedColumn<int>(
    'debt_delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurringIdMeta = const VerificationMeta(
    'recurringId',
  );
  @override
  late final GeneratedColumn<int> recurringId = GeneratedColumn<int>(
    'recurring_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recurring_templates (id)',
    ),
  );
  static const VerificationMeta _fundIdMeta = const VerificationMeta('fundId');
  @override
  late final GeneratedColumn<int> fundId = GeneratedColumn<int>(
    'fund_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES funds (id)',
    ),
  );
  static const VerificationMeta _isWriteoffMeta = const VerificationMeta(
    'isWriteoff',
  );
  @override
  late final GeneratedColumn<bool> isWriteoff = GeneratedColumn<bool>(
    'is_writeoff',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_writeoff" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    amount,
    occurredAt,
    dayKey,
    monthKey,
    walletFromId,
    walletToId,
    categoryId,
    personId,
    debtDelta,
    note,
    groupId,
    recurringId,
    fundId,
    isWriteoff,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(
        _monthKeyMeta,
        monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('wallet_from_id')) {
      context.handle(
        _walletFromIdMeta,
        walletFromId.isAcceptableOrUnknown(
          data['wallet_from_id']!,
          _walletFromIdMeta,
        ),
      );
    }
    if (data.containsKey('wallet_to_id')) {
      context.handle(
        _walletToIdMeta,
        walletToId.isAcceptableOrUnknown(
          data['wallet_to_id']!,
          _walletToIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('debt_delta')) {
      context.handle(
        _debtDeltaMeta,
        debtDelta.isAcceptableOrUnknown(data['debt_delta']!, _debtDeltaMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('recurring_id')) {
      context.handle(
        _recurringIdMeta,
        recurringId.isAcceptableOrUnknown(
          data['recurring_id']!,
          _recurringIdMeta,
        ),
      );
    }
    if (data.containsKey('fund_id')) {
      context.handle(
        _fundIdMeta,
        fundId.isAcceptableOrUnknown(data['fund_id']!, _fundIdMeta),
      );
    }
    if (data.containsKey('is_writeoff')) {
      context.handle(
        _isWriteoffMeta,
        isWriteoff.isAcceptableOrUnknown(data['is_writeoff']!, _isWriteoffMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: $TransactionsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_key'],
      )!,
      monthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_key'],
      )!,
      walletFromId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wallet_from_id'],
      ),
      walletToId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wallet_to_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      ),
      debtDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}debt_delta'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      recurringId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurring_id'],
      ),
      fundId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fund_id'],
      ),
      isWriteoff: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_writeoff'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TxKind, String, String> $converterkind =
      const EnumNameConverter<TxKind>(TxKind.values);
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;
  final TxKind kind;

  /// LUÔN là số dương. Dấu suy ra từ [kind], không bao giờ lưu vào đây.
  final int amount;

  /// Thời điểm giao dịch, epoch millis.
  final int occurredAt;

  /// yyyymmdd theo giờ ĐỊA PHƯƠNG, ví dụ 20260906.
  ///
  /// Tính sẵn ở Dart thay vì dùng strftime của SQLite, vì SQLite quy về UTC —
  /// một giao dịch lúc 23h30 ngày cuối tháng sẽ bị xếp nhầm sang tháng sau.
  final int dayKey;

  /// yyyymm theo giờ địa phương, ví dụ 202609.
  final int monthKey;
  final int? walletFromId;
  final int? walletToId;
  final int? categoryId;
  final int? personId;

  /// Thay đổi công nợ. Xem [TxKindX.debtDelta].
  final int debtDelta;
  final String? note;

  /// Gom nhiều giao dịch sinh ra cùng lúc thành một nhóm (trả dùm tạo ra một
  /// khoản chi cho phần mình ăn và một khoản cho mượn cho phần bạn bè).
  final String? groupId;
  final int? recurringId;

  /// Quỹ mà giao dịch này nạp vào hoặc lấy ra.
  ///
  /// Không phải một loại giao dịch riêng: nạp quỹ là một [TxKind.transfer] có
  /// gắn quỹ, chi từ quỹ là một [TxKind.expense] có gắn quỹ. Nhờ vậy công thức
  /// tính số dư ví không phải rẽ nhánh thêm lần nào nữa.
  ///
  /// Chiều tiền của quỹ suy ra từ chân ví giống hệt cách làm với số dư: giao
  /// dịch đưa tiền vào ví giữ quỹ thì quỹ tăng, lấy tiền ra thì quỹ giảm.
  final int? fundId;

  /// Tất toán không có dòng tiền (xoá nợ, cho luôn). Khi đó không ví nào bị
  /// đụng tới, nhưng công nợ vẫn về 0.
  final bool isWriteoff;
  final int createdAt;
  final int updatedAt;

  /// Xoá mềm, để còn hoàn tác được. Mọi truy vấn đều phải lọc
  /// `deletedAt IS NULL`.
  final int? deletedAt;
  const Transaction({
    required this.id,
    required this.kind,
    required this.amount,
    required this.occurredAt,
    required this.dayKey,
    required this.monthKey,
    this.walletFromId,
    this.walletToId,
    this.categoryId,
    this.personId,
    required this.debtDelta,
    this.note,
    this.groupId,
    this.recurringId,
    this.fundId,
    required this.isWriteoff,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] = Variable<String>(
        $TransactionsTable.$converterkind.toSql(kind),
      );
    }
    map['amount'] = Variable<int>(amount);
    map['occurred_at'] = Variable<int>(occurredAt);
    map['day_key'] = Variable<int>(dayKey);
    map['month_key'] = Variable<int>(monthKey);
    if (!nullToAbsent || walletFromId != null) {
      map['wallet_from_id'] = Variable<int>(walletFromId);
    }
    if (!nullToAbsent || walletToId != null) {
      map['wallet_to_id'] = Variable<int>(walletToId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<int>(personId);
    }
    map['debt_delta'] = Variable<int>(debtDelta);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || recurringId != null) {
      map['recurring_id'] = Variable<int>(recurringId);
    }
    if (!nullToAbsent || fundId != null) {
      map['fund_id'] = Variable<int>(fundId);
    }
    map['is_writeoff'] = Variable<bool>(isWriteoff);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      kind: Value(kind),
      amount: Value(amount),
      occurredAt: Value(occurredAt),
      dayKey: Value(dayKey),
      monthKey: Value(monthKey),
      walletFromId: walletFromId == null && nullToAbsent
          ? const Value.absent()
          : Value(walletFromId),
      walletToId: walletToId == null && nullToAbsent
          ? const Value.absent()
          : Value(walletToId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      debtDelta: Value(debtDelta),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      recurringId: recurringId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringId),
      fundId: fundId == null && nullToAbsent
          ? const Value.absent()
          : Value(fundId),
      isWriteoff: Value(isWriteoff),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      kind: $TransactionsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      amount: serializer.fromJson<int>(json['amount']),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
      dayKey: serializer.fromJson<int>(json['dayKey']),
      monthKey: serializer.fromJson<int>(json['monthKey']),
      walletFromId: serializer.fromJson<int?>(json['walletFromId']),
      walletToId: serializer.fromJson<int?>(json['walletToId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      personId: serializer.fromJson<int?>(json['personId']),
      debtDelta: serializer.fromJson<int>(json['debtDelta']),
      note: serializer.fromJson<String?>(json['note']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      recurringId: serializer.fromJson<int?>(json['recurringId']),
      fundId: serializer.fromJson<int?>(json['fundId']),
      isWriteoff: serializer.fromJson<bool>(json['isWriteoff']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(
        $TransactionsTable.$converterkind.toJson(kind),
      ),
      'amount': serializer.toJson<int>(amount),
      'occurredAt': serializer.toJson<int>(occurredAt),
      'dayKey': serializer.toJson<int>(dayKey),
      'monthKey': serializer.toJson<int>(monthKey),
      'walletFromId': serializer.toJson<int?>(walletFromId),
      'walletToId': serializer.toJson<int?>(walletToId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'personId': serializer.toJson<int?>(personId),
      'debtDelta': serializer.toJson<int>(debtDelta),
      'note': serializer.toJson<String?>(note),
      'groupId': serializer.toJson<String?>(groupId),
      'recurringId': serializer.toJson<int?>(recurringId),
      'fundId': serializer.toJson<int?>(fundId),
      'isWriteoff': serializer.toJson<bool>(isWriteoff),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Transaction copyWith({
    int? id,
    TxKind? kind,
    int? amount,
    int? occurredAt,
    int? dayKey,
    int? monthKey,
    Value<int?> walletFromId = const Value.absent(),
    Value<int?> walletToId = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
    Value<int?> personId = const Value.absent(),
    int? debtDelta,
    Value<String?> note = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
    Value<int?> recurringId = const Value.absent(),
    Value<int?> fundId = const Value.absent(),
    bool? isWriteoff,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => Transaction(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    occurredAt: occurredAt ?? this.occurredAt,
    dayKey: dayKey ?? this.dayKey,
    monthKey: monthKey ?? this.monthKey,
    walletFromId: walletFromId.present ? walletFromId.value : this.walletFromId,
    walletToId: walletToId.present ? walletToId.value : this.walletToId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    personId: personId.present ? personId.value : this.personId,
    debtDelta: debtDelta ?? this.debtDelta,
    note: note.present ? note.value : this.note,
    groupId: groupId.present ? groupId.value : this.groupId,
    recurringId: recurringId.present ? recurringId.value : this.recurringId,
    fundId: fundId.present ? fundId.value : this.fundId,
    isWriteoff: isWriteoff ?? this.isWriteoff,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      walletFromId: data.walletFromId.present
          ? data.walletFromId.value
          : this.walletFromId,
      walletToId: data.walletToId.present
          ? data.walletToId.value
          : this.walletToId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      personId: data.personId.present ? data.personId.value : this.personId,
      debtDelta: data.debtDelta.present ? data.debtDelta.value : this.debtDelta,
      note: data.note.present ? data.note.value : this.note,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      recurringId: data.recurringId.present
          ? data.recurringId.value
          : this.recurringId,
      fundId: data.fundId.present ? data.fundId.value : this.fundId,
      isWriteoff: data.isWriteoff.present
          ? data.isWriteoff.value
          : this.isWriteoff,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('dayKey: $dayKey, ')
          ..write('monthKey: $monthKey, ')
          ..write('walletFromId: $walletFromId, ')
          ..write('walletToId: $walletToId, ')
          ..write('categoryId: $categoryId, ')
          ..write('personId: $personId, ')
          ..write('debtDelta: $debtDelta, ')
          ..write('note: $note, ')
          ..write('groupId: $groupId, ')
          ..write('recurringId: $recurringId, ')
          ..write('fundId: $fundId, ')
          ..write('isWriteoff: $isWriteoff, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    amount,
    occurredAt,
    dayKey,
    monthKey,
    walletFromId,
    walletToId,
    categoryId,
    personId,
    debtDelta,
    note,
    groupId,
    recurringId,
    fundId,
    isWriteoff,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.occurredAt == this.occurredAt &&
          other.dayKey == this.dayKey &&
          other.monthKey == this.monthKey &&
          other.walletFromId == this.walletFromId &&
          other.walletToId == this.walletToId &&
          other.categoryId == this.categoryId &&
          other.personId == this.personId &&
          other.debtDelta == this.debtDelta &&
          other.note == this.note &&
          other.groupId == this.groupId &&
          other.recurringId == this.recurringId &&
          other.fundId == this.fundId &&
          other.isWriteoff == this.isWriteoff &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<TxKind> kind;
  final Value<int> amount;
  final Value<int> occurredAt;
  final Value<int> dayKey;
  final Value<int> monthKey;
  final Value<int?> walletFromId;
  final Value<int?> walletToId;
  final Value<int?> categoryId;
  final Value<int?> personId;
  final Value<int> debtDelta;
  final Value<String?> note;
  final Value<String?> groupId;
  final Value<int?> recurringId;
  final Value<int?> fundId;
  final Value<bool> isWriteoff;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.walletFromId = const Value.absent(),
    this.walletToId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.personId = const Value.absent(),
    this.debtDelta = const Value.absent(),
    this.note = const Value.absent(),
    this.groupId = const Value.absent(),
    this.recurringId = const Value.absent(),
    this.fundId = const Value.absent(),
    this.isWriteoff = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required TxKind kind,
    required int amount,
    required int occurredAt,
    required int dayKey,
    required int monthKey,
    this.walletFromId = const Value.absent(),
    this.walletToId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.personId = const Value.absent(),
    this.debtDelta = const Value.absent(),
    this.note = const Value.absent(),
    this.groupId = const Value.absent(),
    this.recurringId = const Value.absent(),
    this.fundId = const Value.absent(),
    this.isWriteoff = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
  }) : kind = Value(kind),
       amount = Value(amount),
       occurredAt = Value(occurredAt),
       dayKey = Value(dayKey),
       monthKey = Value(monthKey),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<int>? occurredAt,
    Expression<int>? dayKey,
    Expression<int>? monthKey,
    Expression<int>? walletFromId,
    Expression<int>? walletToId,
    Expression<int>? categoryId,
    Expression<int>? personId,
    Expression<int>? debtDelta,
    Expression<String>? note,
    Expression<String>? groupId,
    Expression<int>? recurringId,
    Expression<int>? fundId,
    Expression<bool>? isWriteoff,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (dayKey != null) 'day_key': dayKey,
      if (monthKey != null) 'month_key': monthKey,
      if (walletFromId != null) 'wallet_from_id': walletFromId,
      if (walletToId != null) 'wallet_to_id': walletToId,
      if (categoryId != null) 'category_id': categoryId,
      if (personId != null) 'person_id': personId,
      if (debtDelta != null) 'debt_delta': debtDelta,
      if (note != null) 'note': note,
      if (groupId != null) 'group_id': groupId,
      if (recurringId != null) 'recurring_id': recurringId,
      if (fundId != null) 'fund_id': fundId,
      if (isWriteoff != null) 'is_writeoff': isWriteoff,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<TxKind>? kind,
    Value<int>? amount,
    Value<int>? occurredAt,
    Value<int>? dayKey,
    Value<int>? monthKey,
    Value<int?>? walletFromId,
    Value<int?>? walletToId,
    Value<int?>? categoryId,
    Value<int?>? personId,
    Value<int>? debtDelta,
    Value<String?>? note,
    Value<String?>? groupId,
    Value<int?>? recurringId,
    Value<int?>? fundId,
    Value<bool>? isWriteoff,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      occurredAt: occurredAt ?? this.occurredAt,
      dayKey: dayKey ?? this.dayKey,
      monthKey: monthKey ?? this.monthKey,
      walletFromId: walletFromId ?? this.walletFromId,
      walletToId: walletToId ?? this.walletToId,
      categoryId: categoryId ?? this.categoryId,
      personId: personId ?? this.personId,
      debtDelta: debtDelta ?? this.debtDelta,
      note: note ?? this.note,
      groupId: groupId ?? this.groupId,
      recurringId: recurringId ?? this.recurringId,
      fundId: fundId ?? this.fundId,
      isWriteoff: isWriteoff ?? this.isWriteoff,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $TransactionsTable.$converterkind.toSql(kind.value),
      );
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<int>(dayKey.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<int>(monthKey.value);
    }
    if (walletFromId.present) {
      map['wallet_from_id'] = Variable<int>(walletFromId.value);
    }
    if (walletToId.present) {
      map['wallet_to_id'] = Variable<int>(walletToId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (debtDelta.present) {
      map['debt_delta'] = Variable<int>(debtDelta.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (recurringId.present) {
      map['recurring_id'] = Variable<int>(recurringId.value);
    }
    if (fundId.present) {
      map['fund_id'] = Variable<int>(fundId.value);
    }
    if (isWriteoff.present) {
      map['is_writeoff'] = Variable<bool>(isWriteoff.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('dayKey: $dayKey, ')
          ..write('monthKey: $monthKey, ')
          ..write('walletFromId: $walletFromId, ')
          ..write('walletToId: $walletToId, ')
          ..write('categoryId: $categoryId, ')
          ..write('personId: $personId, ')
          ..write('debtDelta: $debtDelta, ')
          ..write('note: $note, ')
          ..write('groupId: $groupId, ')
          ..write('recurringId: $recurringId, ')
          ..write('fundId: $fundId, ')
          ..write('isWriteoff: $isWriteoff, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _monthKeyMeta = const VerificationMeta(
    'monthKey',
  );
  @override
  late final GeneratedColumn<int> monthKey = GeneratedColumn<int>(
    'month_key',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _limitAmountMeta = const VerificationMeta(
    'limitAmount',
  );
  @override
  late final GeneratedColumn<int> limitAmount = GeneratedColumn<int>(
    'limit_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    monthKey,
    limitAmount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(
        _monthKeyMeta,
        monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta),
      );
    }
    if (data.containsKey('limit_amount')) {
      context.handle(
        _limitAmountMeta,
        limitAmount.isAcceptableOrUnknown(
          data['limit_amount']!,
          _limitAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_limitAmountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      monthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_key'],
      ),
      limitAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_amount'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final int id;
  final int categoryId;

  /// yyyymm, hoặc null nghĩa là áp dụng cho mọi tháng.
  final int? monthKey;
  final int limitAmount;
  final int createdAt;
  final int updatedAt;
  const Budget({
    required this.id,
    required this.categoryId,
    this.monthKey,
    required this.limitAmount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || monthKey != null) {
      map['month_key'] = Variable<int>(monthKey);
    }
    map['limit_amount'] = Variable<int>(limitAmount);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      monthKey: monthKey == null && nullToAbsent
          ? const Value.absent()
          : Value(monthKey),
      limitAmount: Value(limitAmount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      monthKey: serializer.fromJson<int?>(json['monthKey']),
      limitAmount: serializer.fromJson<int>(json['limitAmount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int>(categoryId),
      'monthKey': serializer.toJson<int?>(monthKey),
      'limitAmount': serializer.toJson<int>(limitAmount),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Budget copyWith({
    int? id,
    int? categoryId,
    Value<int?> monthKey = const Value.absent(),
    int? limitAmount,
    int? createdAt,
    int? updatedAt,
  }) => Budget(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    monthKey: monthKey.present ? monthKey.value : this.monthKey,
    limitAmount: limitAmount ?? this.limitAmount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      limitAmount: data.limitAmount.present
          ? data.limitAmount.value
          : this.limitAmount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('monthKey: $monthKey, ')
          ..write('limitAmount: $limitAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, categoryId, monthKey, limitAmount, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.monthKey == this.monthKey &&
          other.limitAmount == this.limitAmount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<int> id;
  final Value<int> categoryId;
  final Value<int?> monthKey;
  final Value<int> limitAmount;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.limitAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BudgetsCompanion.insert({
    this.id = const Value.absent(),
    required int categoryId,
    this.monthKey = const Value.absent(),
    required int limitAmount,
    required int createdAt,
    required int updatedAt,
  }) : categoryId = Value(categoryId),
       limitAmount = Value(limitAmount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Budget> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<int>? monthKey,
    Expression<int>? limitAmount,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (monthKey != null) 'month_key': monthKey,
      if (limitAmount != null) 'limit_amount': limitAmount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BudgetsCompanion copyWith({
    Value<int>? id,
    Value<int>? categoryId,
    Value<int?>? monthKey,
    Value<int>? limitAmount,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      monthKey: monthKey ?? this.monthKey,
      limitAmount: limitAmount ?? this.limitAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<int>(monthKey.value);
    }
    if (limitAmount.present) {
      map['limit_amount'] = Variable<int>(limitAmount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('monthKey: $monthKey, ')
          ..write('limitAmount: $limitAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ExpenseTemplatesTable extends ExpenseTemplates
    with TableInfo<$ExpenseTemplatesTable, ExpenseTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _walletIdMeta = const VerificationMeta(
    'walletId',
  );
  @override
  late final GeneratedColumn<int> walletId = GeneratedColumn<int>(
    'wallet_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wallets (id)',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    note,
    amount,
    walletId,
    categoryId,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      ),
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wallet_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ExpenseTemplatesTable createAlias(String alias) {
    return $ExpenseTemplatesTable(attachedDatabase, alias);
  }
}

class ExpenseTemplate extends DataClass implements Insertable<ExpenseTemplate> {
  final int id;

  /// Cũng là nhãn của mẫu. Để trống thì mẫu mang tên danh mục.
  final String? note;

  /// Số đồng, luôn dương. Null nghĩa là mỗi lần một khác, hỏi lúc ghi.
  final int? amount;
  final int? walletId;
  final int? categoryId;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const ExpenseTemplate({
    required this.id,
    this.note,
    this.amount,
    this.walletId,
    this.categoryId,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<int>(amount);
    }
    if (!nullToAbsent || walletId != null) {
      map['wallet_id'] = Variable<int>(walletId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ExpenseTemplatesCompanion toCompanion(bool nullToAbsent) {
    return ExpenseTemplatesCompanion(
      id: Value(id),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      walletId: walletId == null && nullToAbsent
          ? const Value.absent()
          : Value(walletId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExpenseTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseTemplate(
      id: serializer.fromJson<int>(json['id']),
      note: serializer.fromJson<String?>(json['note']),
      amount: serializer.fromJson<int?>(json['amount']),
      walletId: serializer.fromJson<int?>(json['walletId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'note': serializer.toJson<String?>(note),
      'amount': serializer.toJson<int?>(amount),
      'walletId': serializer.toJson<int?>(walletId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ExpenseTemplate copyWith({
    int? id,
    Value<String?> note = const Value.absent(),
    Value<int?> amount = const Value.absent(),
    Value<int?> walletId = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => ExpenseTemplate(
    id: id ?? this.id,
    note: note.present ? note.value : this.note,
    amount: amount.present ? amount.value : this.amount,
    walletId: walletId.present ? walletId.value : this.walletId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExpenseTemplate copyWithCompanion(ExpenseTemplatesCompanion data) {
    return ExpenseTemplate(
      id: data.id.present ? data.id.value : this.id,
      note: data.note.present ? data.note.value : this.note,
      amount: data.amount.present ? data.amount.value : this.amount,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseTemplate(')
          ..write('id: $id, ')
          ..write('note: $note, ')
          ..write('amount: $amount, ')
          ..write('walletId: $walletId, ')
          ..write('categoryId: $categoryId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    note,
    amount,
    walletId,
    categoryId,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseTemplate &&
          other.id == this.id &&
          other.note == this.note &&
          other.amount == this.amount &&
          other.walletId == this.walletId &&
          other.categoryId == this.categoryId &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExpenseTemplatesCompanion extends UpdateCompanion<ExpenseTemplate> {
  final Value<int> id;
  final Value<String?> note;
  final Value<int?> amount;
  final Value<int?> walletId;
  final Value<int?> categoryId;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ExpenseTemplatesCompanion({
    this.id = const Value.absent(),
    this.note = const Value.absent(),
    this.amount = const Value.absent(),
    this.walletId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ExpenseTemplatesCompanion.insert({
    this.id = const Value.absent(),
    this.note = const Value.absent(),
    this.amount = const Value.absent(),
    this.walletId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExpenseTemplate> custom({
    Expression<int>? id,
    Expression<String>? note,
    Expression<int>? amount,
    Expression<int>? walletId,
    Expression<int>? categoryId,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (note != null) 'note': note,
      if (amount != null) 'amount': amount,
      if (walletId != null) 'wallet_id': walletId,
      if (categoryId != null) 'category_id': categoryId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ExpenseTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String?>? note,
    Value<int?>? amount,
    Value<int?>? walletId,
    Value<int?>? categoryId,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ExpenseTemplatesCompanion(
      id: id ?? this.id,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<int>(walletId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('note: $note, ')
          ..write('amount: $amount, ')
          ..write('walletId: $walletId, ')
          ..write('categoryId: $categoryId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsKvTable extends SettingsKv
    with TableInfo<$SettingsKvTable, SettingsKvData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsKvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsKvData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsKvData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsKvData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsKvTable createAlias(String alias) {
    return $SettingsKvTable(attachedDatabase, alias);
  }
}

class SettingsKvData extends DataClass implements Insertable<SettingsKvData> {
  final String key;
  final String value;
  const SettingsKvData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsKvCompanion toCompanion(bool nullToAbsent) {
    return SettingsKvCompanion(key: Value(key), value: Value(value));
  }

  factory SettingsKvData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsKvData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsKvData copyWith({String? key, String? value}) =>
      SettingsKvData(key: key ?? this.key, value: value ?? this.value);
  SettingsKvData copyWithCompanion(SettingsKvCompanion data) {
    return SettingsKvData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsKvData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsKvData &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsKvCompanion extends UpdateCompanion<SettingsKvData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsKvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsKvCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingsKvData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsKvCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsKvCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsKvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WalletsTable wallets = $WalletsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $RecurringTemplatesTable recurringTemplates =
      $RecurringTemplatesTable(this);
  late final $FundsTable funds = $FundsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $ExpenseTemplatesTable expenseTemplates = $ExpenseTemplatesTable(
    this,
  );
  late final $SettingsKvTable settingsKv = $SettingsKvTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    wallets,
    categories,
    people,
    recurringTemplates,
    funds,
    transactions,
    budgets,
    expenseTemplates,
    settingsKv,
  ];
}

typedef $$WalletsTableCreateCompanionBuilder =
    WalletsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> type,
      Value<int> initialBalance,
      Value<String?> iconKey,
      Value<int?> colorValue,
      Value<String?> note,
      Value<bool> isArchived,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
    });
typedef $$WalletsTableUpdateCompanionBuilder =
    WalletsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> type,
      Value<int> initialBalance,
      Value<String?> iconKey,
      Value<int?> colorValue,
      Value<String?> note,
      Value<bool> isArchived,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$WalletsTableReferences
    extends BaseReferences<_$AppDatabase, $WalletsTable, Wallet> {
  $$WalletsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FundsTable, List<Fund>> _fundsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.funds,
    aliasName: $_aliasNameGenerator(db.wallets.id, db.funds.walletId),
  );

  $$FundsTableProcessedTableManager get fundsRefs {
    final manager = $$FundsTableTableManager(
      $_db,
      $_db.funds,
    ).filter((f) => f.walletId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_fundsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _outgoingTransactionsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(
      db.wallets.id,
      db.transactions.walletFromId,
    ),
  );

  $$TransactionsTableProcessedTableManager get outgoingTransactions {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.walletFromId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _outgoingTransactionsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _incomingTransactionsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(db.wallets.id, db.transactions.walletToId),
  );

  $$TransactionsTableProcessedTableManager get incomingTransactions {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.walletToId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _incomingTransactionsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpenseTemplatesTable, List<ExpenseTemplate>>
  _expenseTemplatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expenseTemplates,
    aliasName: $_aliasNameGenerator(
      db.wallets.id,
      db.expenseTemplates.walletId,
    ),
  );

  $$ExpenseTemplatesTableProcessedTableManager get expenseTemplatesRefs {
    final manager = $$ExpenseTemplatesTableTableManager(
      $_db,
      $_db.expenseTemplates,
    ).filter((f) => f.walletId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _expenseTemplatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WalletsTableFilterComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> fundsRefs(
    Expression<bool> Function($$FundsTableFilterComposer f) f,
  ) {
    final $$FundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FundsTableFilterComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> outgoingTransactions(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.walletFromId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> incomingTransactions(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.walletToId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseTemplatesRefs(
    Expression<bool> Function($$ExpenseTemplatesTableFilterComposer f) f,
  ) {
    final $$ExpenseTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseTemplates,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.expenseTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WalletsTableOrderingComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WalletsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> fundsRefs<T extends Object>(
    Expression<T> Function($$FundsTableAnnotationComposer a) f,
  ) {
    final $$FundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FundsTableAnnotationComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> outgoingTransactions<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.walletFromId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> incomingTransactions<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.walletToId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseTemplatesRefs<T extends Object>(
    Expression<T> Function($$ExpenseTemplatesTableAnnotationComposer a) f,
  ) {
    final $$ExpenseTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseTemplates,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenseTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WalletsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WalletsTable,
          Wallet,
          $$WalletsTableFilterComposer,
          $$WalletsTableOrderingComposer,
          $$WalletsTableAnnotationComposer,
          $$WalletsTableCreateCompanionBuilder,
          $$WalletsTableUpdateCompanionBuilder,
          (Wallet, $$WalletsTableReferences),
          Wallet,
          PrefetchHooks Function({
            bool fundsRefs,
            bool outgoingTransactions,
            bool incomingTransactions,
            bool expenseTemplatesRefs,
          })
        > {
  $$WalletsTableTableManager(_$AppDatabase db, $WalletsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> initialBalance = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => WalletsCompanion(
                id: id,
                name: name,
                type: type,
                initialBalance: initialBalance,
                iconKey: iconKey,
                colorValue: colorValue,
                note: note,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> type = const Value.absent(),
                Value<int> initialBalance = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => WalletsCompanion.insert(
                id: id,
                name: name,
                type: type,
                initialBalance: initialBalance,
                iconKey: iconKey,
                colorValue: colorValue,
                note: note,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WalletsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                fundsRefs = false,
                outgoingTransactions = false,
                incomingTransactions = false,
                expenseTemplatesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (fundsRefs) db.funds,
                    if (outgoingTransactions) db.transactions,
                    if (incomingTransactions) db.transactions,
                    if (expenseTemplatesRefs) db.expenseTemplates,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (fundsRefs)
                        await $_getPrefetchedData<Wallet, $WalletsTable, Fund>(
                          currentTable: table,
                          referencedTable: $$WalletsTableReferences
                              ._fundsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalletsTableReferences(db, table, p0).fundsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.walletId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (outgoingTransactions)
                        await $_getPrefetchedData<
                          Wallet,
                          $WalletsTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$WalletsTableReferences
                              ._outgoingTransactionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalletsTableReferences(
                                db,
                                table,
                                p0,
                              ).outgoingTransactions,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.walletFromId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (incomingTransactions)
                        await $_getPrefetchedData<
                          Wallet,
                          $WalletsTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$WalletsTableReferences
                              ._incomingTransactionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalletsTableReferences(
                                db,
                                table,
                                p0,
                              ).incomingTransactions,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.walletToId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (expenseTemplatesRefs)
                        await $_getPrefetchedData<
                          Wallet,
                          $WalletsTable,
                          ExpenseTemplate
                        >(
                          currentTable: table,
                          referencedTable: $$WalletsTableReferences
                              ._expenseTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WalletsTableReferences(
                                db,
                                table,
                                p0,
                              ).expenseTemplatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.walletId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WalletsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WalletsTable,
      Wallet,
      $$WalletsTableFilterComposer,
      $$WalletsTableOrderingComposer,
      $$WalletsTableAnnotationComposer,
      $$WalletsTableCreateCompanionBuilder,
      $$WalletsTableUpdateCompanionBuilder,
      (Wallet, $$WalletsTableReferences),
      Wallet,
      PrefetchHooks Function({
        bool fundsRefs,
        bool outgoingTransactions,
        bool incomingTransactions,
        bool expenseTemplatesRefs,
      })
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required String name,
      required String flow,
      Value<String?> iconKey,
      Value<int?> colorValue,
      Value<bool> isArchived,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> flow,
      Value<String?> iconKey,
      Value<int?> colorValue,
      Value<bool> isArchived,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(
      db.categories.id,
      db.transactions.categoryId,
    ),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.budgets,
    aliasName: $_aliasNameGenerator(db.categories.id, db.budgets.categoryId),
  );

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpenseTemplatesTable, List<ExpenseTemplate>>
  _expenseTemplatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expenseTemplates,
    aliasName: $_aliasNameGenerator(
      db.categories.id,
      db.expenseTemplates.categoryId,
    ),
  );

  $$ExpenseTemplatesTableProcessedTableManager get expenseTemplatesRefs {
    final manager = $$ExpenseTemplatesTableTableManager(
      $_db,
      $_db.expenseTemplates,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _expenseTemplatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flow => $composableBuilder(
    column: $table.flow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetsRefs(
    Expression<bool> Function($$BudgetsTableFilterComposer f) f,
  ) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseTemplatesRefs(
    Expression<bool> Function($$ExpenseTemplatesTableFilterComposer f) f,
  ) {
    final $$ExpenseTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseTemplates,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.expenseTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flow => $composableBuilder(
    column: $table.flow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get flow =>
      $composableBuilder(column: $table.flow, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
    Expression<T> Function($$BudgetsTableAnnotationComposer a) f,
  ) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseTemplatesRefs<T extends Object>(
    Expression<T> Function($$ExpenseTemplatesTableAnnotationComposer a) f,
  ) {
    final $$ExpenseTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseTemplates,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenseTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({
            bool transactionsRefs,
            bool budgetsRefs,
            bool expenseTemplatesRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> flow = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                flow: flow,
                iconKey: iconKey,
                colorValue: colorValue,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String flow,
                Value<String?> iconKey = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                flow: flow,
                iconKey: iconKey,
                colorValue: colorValue,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                transactionsRefs = false,
                budgetsRefs = false,
                expenseTemplatesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                    if (budgetsRefs) db.budgets,
                    if (expenseTemplatesRefs) db.expenseTemplates,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (budgetsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Budget
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._budgetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (expenseTemplatesRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          ExpenseTemplate
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._expenseTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).expenseTemplatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({
        bool transactionsRefs,
        bool budgetsRefs,
        bool expenseTemplatesRefs,
      })
    >;
typedef $$PeopleTableCreateCompanionBuilder =
    PeopleCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> phone,
      Value<String?> note,
      Value<int?> avatarColor,
      Value<bool> isArchived,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
    });
typedef $$PeopleTableUpdateCompanionBuilder =
    PeopleCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> phone,
      Value<String?> note,
      Value<int?> avatarColor,
      Value<bool> isArchived,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$PeopleTableReferences
    extends BaseReferences<_$AppDatabase, $PeopleTable, Person> {
  $$PeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(db.people.id, db.transactions.personId),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PeopleTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleTable,
          Person,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (Person, $$PeopleTableReferences),
          Person,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$PeopleTableTableManager(_$AppDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> avatarColor = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => PeopleCompanion(
                id: id,
                name: name,
                phone: phone,
                note: note,
                avatarColor: avatarColor,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> avatarColor = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => PeopleCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                note: note,
                avatarColor: avatarColor,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PeopleTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<
                      Person,
                      $PeopleTable,
                      Transaction
                    >(
                      currentTable: table,
                      referencedTable: $$PeopleTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$PeopleTableReferences(
                        db,
                        table,
                        p0,
                      ).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.personId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleTable,
      Person,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (Person, $$PeopleTableReferences),
      Person,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$RecurringTemplatesTableCreateCompanionBuilder =
    RecurringTemplatesCompanion Function({
      Value<int> id,
      required String title,
      required TxKind kind,
      required int amount,
      Value<int?> walletFromId,
      Value<int?> walletToId,
      Value<int?> categoryId,
      Value<int?> personId,
      Value<String?> note,
      Value<String> freq,
      Value<int> intervalN,
      Value<int?> dayOfMonth,
      Value<int?> weekday,
      Value<int?> nextDueAt,
      Value<int?> lastRunAt,
      Value<bool> isActive,
      required int createdAt,
      required int updatedAt,
    });
typedef $$RecurringTemplatesTableUpdateCompanionBuilder =
    RecurringTemplatesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<TxKind> kind,
      Value<int> amount,
      Value<int?> walletFromId,
      Value<int?> walletToId,
      Value<int?> categoryId,
      Value<int?> personId,
      Value<String?> note,
      Value<String> freq,
      Value<int> intervalN,
      Value<int?> dayOfMonth,
      Value<int?> weekday,
      Value<int?> nextDueAt,
      Value<int?> lastRunAt,
      Value<bool> isActive,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$RecurringTemplatesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RecurringTemplatesTable,
          RecurringTemplate
        > {
  $$RecurringTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(
      db.recurringTemplates.id,
      db.transactions.recurringId,
    ),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.recurringId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecurringTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringTemplatesTable> {
  $$RecurringTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TxKind, TxKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get walletFromId => $composableBuilder(
    column: $table.walletFromId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get walletToId => $composableBuilder(
    column: $table.walletToId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get freq => $composableBuilder(
    column: $table.freq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalN => $composableBuilder(
    column: $table.intervalN,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextDueAt => $composableBuilder(
    column: $table.nextDueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastRunAt => $composableBuilder(
    column: $table.lastRunAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.recurringId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurringTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringTemplatesTable> {
  $$RecurringTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get walletFromId => $composableBuilder(
    column: $table.walletFromId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get walletToId => $composableBuilder(
    column: $table.walletToId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get freq => $composableBuilder(
    column: $table.freq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalN => $composableBuilder(
    column: $table.intervalN,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextDueAt => $composableBuilder(
    column: $table.nextDueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastRunAt => $composableBuilder(
    column: $table.lastRunAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurringTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringTemplatesTable> {
  $$RecurringTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TxKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get walletFromId => $composableBuilder(
    column: $table.walletFromId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get walletToId => $composableBuilder(
    column: $table.walletToId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get freq =>
      $composableBuilder(column: $table.freq, builder: (column) => column);

  GeneratedColumn<int> get intervalN =>
      $composableBuilder(column: $table.intervalN, builder: (column) => column);

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get nextDueAt =>
      $composableBuilder(column: $table.nextDueAt, builder: (column) => column);

  GeneratedColumn<int> get lastRunAt =>
      $composableBuilder(column: $table.lastRunAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.recurringId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurringTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringTemplatesTable,
          RecurringTemplate,
          $$RecurringTemplatesTableFilterComposer,
          $$RecurringTemplatesTableOrderingComposer,
          $$RecurringTemplatesTableAnnotationComposer,
          $$RecurringTemplatesTableCreateCompanionBuilder,
          $$RecurringTemplatesTableUpdateCompanionBuilder,
          (RecurringTemplate, $$RecurringTemplatesTableReferences),
          RecurringTemplate,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$RecurringTemplatesTableTableManager(
    _$AppDatabase db,
    $RecurringTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<TxKind> kind = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int?> walletFromId = const Value.absent(),
                Value<int?> walletToId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> freq = const Value.absent(),
                Value<int> intervalN = const Value.absent(),
                Value<int?> dayOfMonth = const Value.absent(),
                Value<int?> weekday = const Value.absent(),
                Value<int?> nextDueAt = const Value.absent(),
                Value<int?> lastRunAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => RecurringTemplatesCompanion(
                id: id,
                title: title,
                kind: kind,
                amount: amount,
                walletFromId: walletFromId,
                walletToId: walletToId,
                categoryId: categoryId,
                personId: personId,
                note: note,
                freq: freq,
                intervalN: intervalN,
                dayOfMonth: dayOfMonth,
                weekday: weekday,
                nextDueAt: nextDueAt,
                lastRunAt: lastRunAt,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required TxKind kind,
                required int amount,
                Value<int?> walletFromId = const Value.absent(),
                Value<int?> walletToId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> freq = const Value.absent(),
                Value<int> intervalN = const Value.absent(),
                Value<int?> dayOfMonth = const Value.absent(),
                Value<int?> weekday = const Value.absent(),
                Value<int?> nextDueAt = const Value.absent(),
                Value<int?> lastRunAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => RecurringTemplatesCompanion.insert(
                id: id,
                title: title,
                kind: kind,
                amount: amount,
                walletFromId: walletFromId,
                walletToId: walletToId,
                categoryId: categoryId,
                personId: personId,
                note: note,
                freq: freq,
                intervalN: intervalN,
                dayOfMonth: dayOfMonth,
                weekday: weekday,
                nextDueAt: nextDueAt,
                lastRunAt: lastRunAt,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RecurringTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<
                      RecurringTemplate,
                      $RecurringTemplatesTable,
                      Transaction
                    >(
                      currentTable: table,
                      referencedTable: $$RecurringTemplatesTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RecurringTemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.recurringId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RecurringTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringTemplatesTable,
      RecurringTemplate,
      $$RecurringTemplatesTableFilterComposer,
      $$RecurringTemplatesTableOrderingComposer,
      $$RecurringTemplatesTableAnnotationComposer,
      $$RecurringTemplatesTableCreateCompanionBuilder,
      $$RecurringTemplatesTableUpdateCompanionBuilder,
      (RecurringTemplate, $$RecurringTemplatesTableReferences),
      RecurringTemplate,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$FundsTableCreateCompanionBuilder =
    FundsCompanion Function({
      Value<int> id,
      required String name,
      required int walletId,
      Value<int?> targetAmount,
      Value<int?> dueDayKey,
      Value<String?> note,
      Value<String?> iconKey,
      Value<int?> colorValue,
      Value<bool> isArchived,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
    });
typedef $$FundsTableUpdateCompanionBuilder =
    FundsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> walletId,
      Value<int?> targetAmount,
      Value<int?> dueDayKey,
      Value<String?> note,
      Value<String?> iconKey,
      Value<int?> colorValue,
      Value<bool> isArchived,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$FundsTableReferences
    extends BaseReferences<_$AppDatabase, $FundsTable, Fund> {
  $$FundsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WalletsTable _walletIdTable(_$AppDatabase db) => db.wallets
      .createAlias($_aliasNameGenerator(db.funds.walletId, db.wallets.id));

  $$WalletsTableProcessedTableManager get walletId {
    final $_column = $_itemColumn<int>('wallet_id')!;

    final manager = $$WalletsTableTableManager(
      $_db,
      $_db.wallets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(db.funds.id, db.transactions.fundId),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.fundId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FundsTableFilterComposer extends Composer<_$AppDatabase, $FundsTable> {
  $$FundsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDayKey => $composableBuilder(
    column: $table.dueDayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableFilterComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.fundId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FundsTableOrderingComposer
    extends Composer<_$AppDatabase, $FundsTable> {
  $$FundsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDayKey => $composableBuilder(
    column: $table.dueDayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableOrderingComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FundsTable> {
  $$FundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDayKey =>
      $composableBuilder(column: $table.dueDayKey, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableAnnotationComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.fundId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FundsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FundsTable,
          Fund,
          $$FundsTableFilterComposer,
          $$FundsTableOrderingComposer,
          $$FundsTableAnnotationComposer,
          $$FundsTableCreateCompanionBuilder,
          $$FundsTableUpdateCompanionBuilder,
          (Fund, $$FundsTableReferences),
          Fund,
          PrefetchHooks Function({bool walletId, bool transactionsRefs})
        > {
  $$FundsTableTableManager(_$AppDatabase db, $FundsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> walletId = const Value.absent(),
                Value<int?> targetAmount = const Value.absent(),
                Value<int?> dueDayKey = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => FundsCompanion(
                id: id,
                name: name,
                walletId: walletId,
                targetAmount: targetAmount,
                dueDayKey: dueDayKey,
                note: note,
                iconKey: iconKey,
                colorValue: colorValue,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int walletId,
                Value<int?> targetAmount = const Value.absent(),
                Value<int?> dueDayKey = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => FundsCompanion.insert(
                id: id,
                name: name,
                walletId: walletId,
                targetAmount: targetAmount,
                dueDayKey: dueDayKey,
                note: note,
                iconKey: iconKey,
                colorValue: colorValue,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$FundsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({walletId = false, transactionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (walletId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.walletId,
                                    referencedTable: $$FundsTableReferences
                                        ._walletIdTable(db),
                                    referencedColumn: $$FundsTableReferences
                                        ._walletIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          Fund,
                          $FundsTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$FundsTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FundsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fundId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FundsTable,
      Fund,
      $$FundsTableFilterComposer,
      $$FundsTableOrderingComposer,
      $$FundsTableAnnotationComposer,
      $$FundsTableCreateCompanionBuilder,
      $$FundsTableUpdateCompanionBuilder,
      (Fund, $$FundsTableReferences),
      Fund,
      PrefetchHooks Function({bool walletId, bool transactionsRefs})
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required TxKind kind,
      required int amount,
      required int occurredAt,
      required int dayKey,
      required int monthKey,
      Value<int?> walletFromId,
      Value<int?> walletToId,
      Value<int?> categoryId,
      Value<int?> personId,
      Value<int> debtDelta,
      Value<String?> note,
      Value<String?> groupId,
      Value<int?> recurringId,
      Value<int?> fundId,
      Value<bool> isWriteoff,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<TxKind> kind,
      Value<int> amount,
      Value<int> occurredAt,
      Value<int> dayKey,
      Value<int> monthKey,
      Value<int?> walletFromId,
      Value<int?> walletToId,
      Value<int?> categoryId,
      Value<int?> personId,
      Value<int> debtDelta,
      Value<String?> note,
      Value<String?> groupId,
      Value<int?> recurringId,
      Value<int?> fundId,
      Value<bool> isWriteoff,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WalletsTable _walletFromIdTable(_$AppDatabase db) =>
      db.wallets.createAlias(
        $_aliasNameGenerator(db.transactions.walletFromId, db.wallets.id),
      );

  $$WalletsTableProcessedTableManager? get walletFromId {
    final $_column = $_itemColumn<int>('wallet_from_id');
    if ($_column == null) return null;
    final manager = $$WalletsTableTableManager(
      $_db,
      $_db.wallets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletFromIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WalletsTable _walletToIdTable(_$AppDatabase db) =>
      db.wallets.createAlias(
        $_aliasNameGenerator(db.transactions.walletToId, db.wallets.id),
      );

  $$WalletsTableProcessedTableManager? get walletToId {
    final $_column = $_itemColumn<int>('wallet_to_id');
    if ($_column == null) return null;
    final manager = $$WalletsTableTableManager(
      $_db,
      $_db.wallets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletToIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.transactions.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PeopleTable _personIdTable(_$AppDatabase db) => db.people.createAlias(
    $_aliasNameGenerator(db.transactions.personId, db.people.id),
  );

  $$PeopleTableProcessedTableManager? get personId {
    final $_column = $_itemColumn<int>('person_id');
    if ($_column == null) return null;
    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RecurringTemplatesTable _recurringIdTable(_$AppDatabase db) =>
      db.recurringTemplates.createAlias(
        $_aliasNameGenerator(
          db.transactions.recurringId,
          db.recurringTemplates.id,
        ),
      );

  $$RecurringTemplatesTableProcessedTableManager? get recurringId {
    final $_column = $_itemColumn<int>('recurring_id');
    if ($_column == null) return null;
    final manager = $$RecurringTemplatesTableTableManager(
      $_db,
      $_db.recurringTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recurringIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FundsTable _fundIdTable(_$AppDatabase db) => db.funds.createAlias(
    $_aliasNameGenerator(db.transactions.fundId, db.funds.id),
  );

  $$FundsTableProcessedTableManager? get fundId {
    final $_column = $_itemColumn<int>('fund_id');
    if ($_column == null) return null;
    final manager = $$FundsTableTableManager(
      $_db,
      $_db.funds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TxKind, TxKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get debtDelta => $composableBuilder(
    column: $table.debtDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWriteoff => $composableBuilder(
    column: $table.isWriteoff,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WalletsTableFilterComposer get walletFromId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletFromId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableFilterComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WalletsTableFilterComposer get walletToId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletToId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableFilterComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringTemplatesTableFilterComposer get recurringId {
    final $$RecurringTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringId,
      referencedTable: $db.recurringTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.recurringTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FundsTableFilterComposer get fundId {
    final $$FundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FundsTableFilterComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get debtDelta => $composableBuilder(
    column: $table.debtDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWriteoff => $composableBuilder(
    column: $table.isWriteoff,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WalletsTableOrderingComposer get walletFromId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletFromId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableOrderingComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WalletsTableOrderingComposer get walletToId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletToId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableOrderingComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringTemplatesTableOrderingComposer get recurringId {
    final $$RecurringTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringId,
      referencedTable: $db.recurringTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.recurringTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FundsTableOrderingComposer get fundId {
    final $$FundsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FundsTableOrderingComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TxKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<int> get debtDelta =>
      $composableBuilder(column: $table.debtDelta, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<bool> get isWriteoff => $composableBuilder(
    column: $table.isWriteoff,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$WalletsTableAnnotationComposer get walletFromId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletFromId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableAnnotationComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WalletsTableAnnotationComposer get walletToId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletToId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableAnnotationComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringTemplatesTableAnnotationComposer get recurringId {
    final $$RecurringTemplatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.recurringId,
          referencedTable: $db.recurringTemplates,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecurringTemplatesTableAnnotationComposer(
                $db: $db,
                $table: $db.recurringTemplates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$FundsTableAnnotationComposer get fundId {
    final $$FundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FundsTableAnnotationComposer(
            $db: $db,
            $table: $db.funds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (Transaction, $$TransactionsTableReferences),
          Transaction,
          PrefetchHooks Function({
            bool walletFromId,
            bool walletToId,
            bool categoryId,
            bool personId,
            bool recurringId,
            bool fundId,
          })
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<TxKind> kind = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> occurredAt = const Value.absent(),
                Value<int> dayKey = const Value.absent(),
                Value<int> monthKey = const Value.absent(),
                Value<int?> walletFromId = const Value.absent(),
                Value<int?> walletToId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<int> debtDelta = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int?> recurringId = const Value.absent(),
                Value<int?> fundId = const Value.absent(),
                Value<bool> isWriteoff = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                kind: kind,
                amount: amount,
                occurredAt: occurredAt,
                dayKey: dayKey,
                monthKey: monthKey,
                walletFromId: walletFromId,
                walletToId: walletToId,
                categoryId: categoryId,
                personId: personId,
                debtDelta: debtDelta,
                note: note,
                groupId: groupId,
                recurringId: recurringId,
                fundId: fundId,
                isWriteoff: isWriteoff,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required TxKind kind,
                required int amount,
                required int occurredAt,
                required int dayKey,
                required int monthKey,
                Value<int?> walletFromId = const Value.absent(),
                Value<int?> walletToId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<int> debtDelta = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int?> recurringId = const Value.absent(),
                Value<int?> fundId = const Value.absent(),
                Value<bool> isWriteoff = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                kind: kind,
                amount: amount,
                occurredAt: occurredAt,
                dayKey: dayKey,
                monthKey: monthKey,
                walletFromId: walletFromId,
                walletToId: walletToId,
                categoryId: categoryId,
                personId: personId,
                debtDelta: debtDelta,
                note: note,
                groupId: groupId,
                recurringId: recurringId,
                fundId: fundId,
                isWriteoff: isWriteoff,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                walletFromId = false,
                walletToId = false,
                categoryId = false,
                personId = false,
                recurringId = false,
                fundId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (walletFromId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.walletFromId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._walletFromIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._walletFromIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (walletToId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.walletToId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._walletToIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._walletToIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._categoryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (personId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.personId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._personIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._personIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (recurringId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.recurringId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._recurringIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._recurringIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (fundId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.fundId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._fundIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._fundIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Transaction, $$TransactionsTableReferences),
      Transaction,
      PrefetchHooks Function({
        bool walletFromId,
        bool walletToId,
        bool categoryId,
        bool personId,
        bool recurringId,
        bool fundId,
      })
    >;
typedef $$BudgetsTableCreateCompanionBuilder =
    BudgetsCompanion Function({
      Value<int> id,
      required int categoryId,
      Value<int?> monthKey,
      required int limitAmount,
      required int createdAt,
      required int updatedAt,
    });
typedef $$BudgetsTableUpdateCompanionBuilder =
    BudgetsCompanion Function({
      Value<int> id,
      Value<int> categoryId,
      Value<int?> monthKey,
      Value<int> limitAmount,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.budgets.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitAmount => $composableBuilder(
    column: $table.limitAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitAmount => $composableBuilder(
    column: $table.limitAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<int> get limitAmount => $composableBuilder(
    column: $table.limitAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, $$BudgetsTableReferences),
          Budget,
          PrefetchHooks Function({bool categoryId})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int?> monthKey = const Value.absent(),
                Value<int> limitAmount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                categoryId: categoryId,
                monthKey: monthKey,
                limitAmount: limitAmount,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int categoryId,
                Value<int?> monthKey = const Value.absent(),
                required int limitAmount,
                required int createdAt,
                required int updatedAt,
              }) => BudgetsCompanion.insert(
                id: id,
                categoryId: categoryId,
                monthKey: monthKey,
                limitAmount: limitAmount,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BudgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable: $$BudgetsTableReferences
                                    ._categoryIdTable(db),
                                referencedColumn: $$BudgetsTableReferences
                                    ._categoryIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, $$BudgetsTableReferences),
      Budget,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$ExpenseTemplatesTableCreateCompanionBuilder =
    ExpenseTemplatesCompanion Function({
      Value<int> id,
      Value<String?> note,
      Value<int?> amount,
      Value<int?> walletId,
      Value<int?> categoryId,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
    });
typedef $$ExpenseTemplatesTableUpdateCompanionBuilder =
    ExpenseTemplatesCompanion Function({
      Value<int> id,
      Value<String?> note,
      Value<int?> amount,
      Value<int?> walletId,
      Value<int?> categoryId,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$ExpenseTemplatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ExpenseTemplatesTable, ExpenseTemplate> {
  $$ExpenseTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WalletsTable _walletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias(
        $_aliasNameGenerator(db.expenseTemplates.walletId, db.wallets.id),
      );

  $$WalletsTableProcessedTableManager? get walletId {
    final $_column = $_itemColumn<int>('wallet_id');
    if ($_column == null) return null;
    final manager = $$WalletsTableTableManager(
      $_db,
      $_db.wallets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.expenseTemplates.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExpenseTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseTemplatesTable> {
  $$ExpenseTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableFilterComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseTemplatesTable> {
  $$ExpenseTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableOrderingComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseTemplatesTable> {
  $$ExpenseTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableAnnotationComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpenseTemplatesTable,
          ExpenseTemplate,
          $$ExpenseTemplatesTableFilterComposer,
          $$ExpenseTemplatesTableOrderingComposer,
          $$ExpenseTemplatesTableAnnotationComposer,
          $$ExpenseTemplatesTableCreateCompanionBuilder,
          $$ExpenseTemplatesTableUpdateCompanionBuilder,
          (ExpenseTemplate, $$ExpenseTemplatesTableReferences),
          ExpenseTemplate,
          PrefetchHooks Function({bool walletId, bool categoryId})
        > {
  $$ExpenseTemplatesTableTableManager(
    _$AppDatabase db,
    $ExpenseTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> amount = const Value.absent(),
                Value<int?> walletId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ExpenseTemplatesCompanion(
                id: id,
                note: note,
                amount: amount,
                walletId: walletId,
                categoryId: categoryId,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> amount = const Value.absent(),
                Value<int?> walletId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ExpenseTemplatesCompanion.insert(
                id: id,
                note: note,
                amount: amount,
                walletId: walletId,
                categoryId: categoryId,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExpenseTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({walletId = false, categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (walletId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.walletId,
                                referencedTable:
                                    $$ExpenseTemplatesTableReferences
                                        ._walletIdTable(db),
                                referencedColumn:
                                    $$ExpenseTemplatesTableReferences
                                        ._walletIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable:
                                    $$ExpenseTemplatesTableReferences
                                        ._categoryIdTable(db),
                                referencedColumn:
                                    $$ExpenseTemplatesTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExpenseTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpenseTemplatesTable,
      ExpenseTemplate,
      $$ExpenseTemplatesTableFilterComposer,
      $$ExpenseTemplatesTableOrderingComposer,
      $$ExpenseTemplatesTableAnnotationComposer,
      $$ExpenseTemplatesTableCreateCompanionBuilder,
      $$ExpenseTemplatesTableUpdateCompanionBuilder,
      (ExpenseTemplate, $$ExpenseTemplatesTableReferences),
      ExpenseTemplate,
      PrefetchHooks Function({bool walletId, bool categoryId})
    >;
typedef $$SettingsKvTableCreateCompanionBuilder =
    SettingsKvCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsKvTableUpdateCompanionBuilder =
    SettingsKvCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsKvTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsKvTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsKvTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsKvTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsKvTable,
          SettingsKvData,
          $$SettingsKvTableFilterComposer,
          $$SettingsKvTableOrderingComposer,
          $$SettingsKvTableAnnotationComposer,
          $$SettingsKvTableCreateCompanionBuilder,
          $$SettingsKvTableUpdateCompanionBuilder,
          (
            SettingsKvData,
            BaseReferences<_$AppDatabase, $SettingsKvTable, SettingsKvData>,
          ),
          SettingsKvData,
          PrefetchHooks Function()
        > {
  $$SettingsKvTableTableManager(_$AppDatabase db, $SettingsKvTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsKvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsKvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsKvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsKvCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsKvCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsKvTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsKvTable,
      SettingsKvData,
      $$SettingsKvTableFilterComposer,
      $$SettingsKvTableOrderingComposer,
      $$SettingsKvTableAnnotationComposer,
      $$SettingsKvTableCreateCompanionBuilder,
      $$SettingsKvTableUpdateCompanionBuilder,
      (
        SettingsKvData,
        BaseReferences<_$AppDatabase, $SettingsKvTable, SettingsKvData>,
      ),
      SettingsKvData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db, _db.wallets);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$RecurringTemplatesTableTableManager get recurringTemplates =>
      $$RecurringTemplatesTableTableManager(_db, _db.recurringTemplates);
  $$FundsTableTableManager get funds =>
      $$FundsTableTableManager(_db, _db.funds);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$ExpenseTemplatesTableTableManager get expenseTemplates =>
      $$ExpenseTemplatesTableTableManager(_db, _db.expenseTemplates);
  $$SettingsKvTableTableManager get settingsKv =>
      $$SettingsKvTableTableManager(_db, _db.settingsKv);
}
