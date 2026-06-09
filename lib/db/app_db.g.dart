// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankIdMeta = const VerificationMeta('bankId');
  @override
  late final GeneratedColumn<String> bankId = GeneratedColumn<String>(
    'bank_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountVndMeta = const VerificationMeta(
    'amountVnd',
  );
  @override
  late final GeneratedColumn<int> amountVnd = GeneratedColumn<int>(
    'amount_vnd',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signMeta = const VerificationMeta('sign');
  @override
  late final GeneratedColumn<String> sign = GeneratedColumn<String>(
    'sign',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMsMeta = const VerificationMeta(
    'timestampMs',
  );
  @override
  late final GeneratedColumn<int> timestampMs = GeneratedColumn<int>(
    'timestamp_ms',
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
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawContentMeta = const VerificationMeta(
    'rawContent',
  );
  @override
  late final GeneratedColumn<String> rawContent = GeneratedColumn<String>(
    'raw_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDraftMeta = const VerificationMeta(
    'isDraft',
  );
  @override
  late final GeneratedColumn<bool> isDraft = GeneratedColumn<bool>(
    'is_draft',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_draft" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bankId,
    amountVnd,
    sign,
    timestampMs,
    createdAt,
    syncedAt,
    rawContent,
    isDraft,
    categoryId,
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
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bank_id')) {
      context.handle(
        _bankIdMeta,
        bankId.isAcceptableOrUnknown(data['bank_id']!, _bankIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bankIdMeta);
    }
    if (data.containsKey('amount_vnd')) {
      context.handle(
        _amountVndMeta,
        amountVnd.isAcceptableOrUnknown(data['amount_vnd']!, _amountVndMeta),
      );
    } else if (isInserting) {
      context.missing(_amountVndMeta);
    }
    if (data.containsKey('sign')) {
      context.handle(
        _signMeta,
        sign.isAcceptableOrUnknown(data['sign']!, _signMeta),
      );
    } else if (isInserting) {
      context.missing(_signMeta);
    }
    if (data.containsKey('timestamp_ms')) {
      context.handle(
        _timestampMsMeta,
        timestampMs.isAcceptableOrUnknown(
          data['timestamp_ms']!,
          _timestampMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampMsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('raw_content')) {
      context.handle(
        _rawContentMeta,
        rawContent.isAcceptableOrUnknown(data['raw_content']!, _rawContentMeta),
      );
    }
    if (data.containsKey('is_draft')) {
      context.handle(
        _isDraftMeta,
        isDraft.isAcceptableOrUnknown(data['is_draft']!, _isDraftMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
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
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bankId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_id'],
      )!,
      amountVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_vnd'],
      )!,
      sign: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sign'],
      )!,
      timestampMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_ms'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at'],
      ),
      rawContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_content'],
      ),
      isDraft: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_draft'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String bankId;
  final int amountVnd;
  final String sign;
  final int timestampMs;
  final int createdAt;
  final int? syncedAt;
  final String? rawContent;
  final bool isDraft;
  final String? categoryId;
  const Transaction({
    required this.id,
    required this.bankId,
    required this.amountVnd,
    required this.sign,
    required this.timestampMs,
    required this.createdAt,
    this.syncedAt,
    this.rawContent,
    required this.isDraft,
    this.categoryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bank_id'] = Variable<String>(bankId);
    map['amount_vnd'] = Variable<int>(amountVnd);
    map['sign'] = Variable<String>(sign);
    map['timestamp_ms'] = Variable<int>(timestampMs);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<int>(syncedAt);
    }
    if (!nullToAbsent || rawContent != null) {
      map['raw_content'] = Variable<String>(rawContent);
    }
    map['is_draft'] = Variable<bool>(isDraft);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      bankId: Value(bankId),
      amountVnd: Value(amountVnd),
      sign: Value(sign),
      timestampMs: Value(timestampMs),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      rawContent: rawContent == null && nullToAbsent
          ? const Value.absent()
          : Value(rawContent),
      isDraft: Value(isDraft),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      bankId: serializer.fromJson<String>(json['bankId']),
      amountVnd: serializer.fromJson<int>(json['amountVnd']),
      sign: serializer.fromJson<String>(json['sign']),
      timestampMs: serializer.fromJson<int>(json['timestampMs']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      syncedAt: serializer.fromJson<int?>(json['syncedAt']),
      rawContent: serializer.fromJson<String?>(json['rawContent']),
      isDraft: serializer.fromJson<bool>(json['isDraft']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bankId': serializer.toJson<String>(bankId),
      'amountVnd': serializer.toJson<int>(amountVnd),
      'sign': serializer.toJson<String>(sign),
      'timestampMs': serializer.toJson<int>(timestampMs),
      'createdAt': serializer.toJson<int>(createdAt),
      'syncedAt': serializer.toJson<int?>(syncedAt),
      'rawContent': serializer.toJson<String?>(rawContent),
      'isDraft': serializer.toJson<bool>(isDraft),
      'categoryId': serializer.toJson<String?>(categoryId),
    };
  }

  Transaction copyWith({
    String? id,
    String? bankId,
    int? amountVnd,
    String? sign,
    int? timestampMs,
    int? createdAt,
    Value<int?> syncedAt = const Value.absent(),
    Value<String?> rawContent = const Value.absent(),
    bool? isDraft,
    Value<String?> categoryId = const Value.absent(),
  }) => Transaction(
    id: id ?? this.id,
    bankId: bankId ?? this.bankId,
    amountVnd: amountVnd ?? this.amountVnd,
    sign: sign ?? this.sign,
    timestampMs: timestampMs ?? this.timestampMs,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    rawContent: rawContent.present ? rawContent.value : this.rawContent,
    isDraft: isDraft ?? this.isDraft,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      bankId: data.bankId.present ? data.bankId.value : this.bankId,
      amountVnd: data.amountVnd.present ? data.amountVnd.value : this.amountVnd,
      sign: data.sign.present ? data.sign.value : this.sign,
      timestampMs: data.timestampMs.present
          ? data.timestampMs.value
          : this.timestampMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      rawContent: data.rawContent.present
          ? data.rawContent.value
          : this.rawContent,
      isDraft: data.isDraft.present ? data.isDraft.value : this.isDraft,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('amountVnd: $amountVnd, ')
          ..write('sign: $sign, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rawContent: $rawContent, ')
          ..write('isDraft: $isDraft, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bankId,
    amountVnd,
    sign,
    timestampMs,
    createdAt,
    syncedAt,
    rawContent,
    isDraft,
    categoryId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.bankId == this.bankId &&
          other.amountVnd == this.amountVnd &&
          other.sign == this.sign &&
          other.timestampMs == this.timestampMs &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt &&
          other.rawContent == this.rawContent &&
          other.isDraft == this.isDraft &&
          other.categoryId == this.categoryId);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> bankId;
  final Value<int> amountVnd;
  final Value<String> sign;
  final Value<int> timestampMs;
  final Value<int> createdAt;
  final Value<int?> syncedAt;
  final Value<String?> rawContent;
  final Value<bool> isDraft;
  final Value<String?> categoryId;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.bankId = const Value.absent(),
    this.amountVnd = const Value.absent(),
    this.sign = const Value.absent(),
    this.timestampMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rawContent = const Value.absent(),
    this.isDraft = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String bankId,
    required int amountVnd,
    required String sign,
    required int timestampMs,
    required int createdAt,
    this.syncedAt = const Value.absent(),
    this.rawContent = const Value.absent(),
    this.isDraft = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bankId = Value(bankId),
       amountVnd = Value(amountVnd),
       sign = Value(sign),
       timestampMs = Value(timestampMs),
       createdAt = Value(createdAt);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? bankId,
    Expression<int>? amountVnd,
    Expression<String>? sign,
    Expression<int>? timestampMs,
    Expression<int>? createdAt,
    Expression<int>? syncedAt,
    Expression<String>? rawContent,
    Expression<bool>? isDraft,
    Expression<String>? categoryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bankId != null) 'bank_id': bankId,
      if (amountVnd != null) 'amount_vnd': amountVnd,
      if (sign != null) 'sign': sign,
      if (timestampMs != null) 'timestamp_ms': timestampMs,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rawContent != null) 'raw_content': rawContent,
      if (isDraft != null) 'is_draft': isDraft,
      if (categoryId != null) 'category_id': categoryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? bankId,
    Value<int>? amountVnd,
    Value<String>? sign,
    Value<int>? timestampMs,
    Value<int>? createdAt,
    Value<int?>? syncedAt,
    Value<String?>? rawContent,
    Value<bool>? isDraft,
    Value<String?>? categoryId,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      bankId: bankId ?? this.bankId,
      amountVnd: amountVnd ?? this.amountVnd,
      sign: sign ?? this.sign,
      timestampMs: timestampMs ?? this.timestampMs,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rawContent: rawContent ?? this.rawContent,
      isDraft: isDraft ?? this.isDraft,
      categoryId: categoryId ?? this.categoryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bankId.present) {
      map['bank_id'] = Variable<String>(bankId.value);
    }
    if (amountVnd.present) {
      map['amount_vnd'] = Variable<int>(amountVnd.value);
    }
    if (sign.present) {
      map['sign'] = Variable<String>(sign.value);
    }
    if (timestampMs.present) {
      map['timestamp_ms'] = Variable<int>(timestampMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    if (rawContent.present) {
      map['raw_content'] = Variable<String>(rawContent.value);
    }
    if (isDraft.present) {
      map['is_draft'] = Variable<bool>(isDraft.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('amountVnd: $amountVnd, ')
          ..write('sign: $sign, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rawContent: $rawContent, ')
          ..write('isDraft: $isDraft, ')
          ..write('categoryId: $categoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RegexConfigCacheTable extends RegexConfigCache
    with TableInfo<$RegexConfigCacheTable, RegexConfigCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RegexConfigCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bankIdMeta = const VerificationMeta('bankId');
  @override
  late final GeneratedColumn<String> bankId = GeneratedColumn<String>(
    'bank_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNamesJsonMeta = const VerificationMeta(
    'packageNamesJson',
  );
  @override
  late final GeneratedColumn<String> packageNamesJson = GeneratedColumn<String>(
    'package_names_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patternsJsonMeta = const VerificationMeta(
    'patternsJson',
  );
  @override
  late final GeneratedColumn<String> patternsJson = GeneratedColumn<String>(
    'patterns_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountGroupMeta = const VerificationMeta(
    'amountGroup',
  );
  @override
  late final GeneratedColumn<int> amountGroup = GeneratedColumn<int>(
    'amount_group',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _signMeta = const VerificationMeta('sign');
  @override
  late final GeneratedColumn<String> sign = GeneratedColumn<String>(
    'sign',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bankId,
    packageNamesJson,
    patternsJson,
    amountGroup,
    sign,
    version,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'regex_config_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<RegexConfigCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bank_id')) {
      context.handle(
        _bankIdMeta,
        bankId.isAcceptableOrUnknown(data['bank_id']!, _bankIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bankIdMeta);
    }
    if (data.containsKey('package_names_json')) {
      context.handle(
        _packageNamesJsonMeta,
        packageNamesJson.isAcceptableOrUnknown(
          data['package_names_json']!,
          _packageNamesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNamesJsonMeta);
    }
    if (data.containsKey('patterns_json')) {
      context.handle(
        _patternsJsonMeta,
        patternsJson.isAcceptableOrUnknown(
          data['patterns_json']!,
          _patternsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_patternsJsonMeta);
    }
    if (data.containsKey('amount_group')) {
      context.handle(
        _amountGroupMeta,
        amountGroup.isAcceptableOrUnknown(
          data['amount_group']!,
          _amountGroupMeta,
        ),
      );
    }
    if (data.containsKey('sign')) {
      context.handle(
        _signMeta,
        sign.isAcceptableOrUnknown(data['sign']!, _signMeta),
      );
    } else if (isInserting) {
      context.missing(_signMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bankId};
  @override
  RegexConfigCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RegexConfigCacheData(
      bankId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_id'],
      )!,
      packageNamesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_names_json'],
      )!,
      patternsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patterns_json'],
      )!,
      amountGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_group'],
      )!,
      sign: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sign'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $RegexConfigCacheTable createAlias(String alias) {
    return $RegexConfigCacheTable(attachedDatabase, alias);
  }
}

class RegexConfigCacheData extends DataClass
    implements Insertable<RegexConfigCacheData> {
  final String bankId;
  final String packageNamesJson;
  final String patternsJson;
  final int amountGroup;
  final String sign;
  final int version;
  final int fetchedAt;
  const RegexConfigCacheData({
    required this.bankId,
    required this.packageNamesJson,
    required this.patternsJson,
    required this.amountGroup,
    required this.sign,
    required this.version,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bank_id'] = Variable<String>(bankId);
    map['package_names_json'] = Variable<String>(packageNamesJson);
    map['patterns_json'] = Variable<String>(patternsJson);
    map['amount_group'] = Variable<int>(amountGroup);
    map['sign'] = Variable<String>(sign);
    map['version'] = Variable<int>(version);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  RegexConfigCacheCompanion toCompanion(bool nullToAbsent) {
    return RegexConfigCacheCompanion(
      bankId: Value(bankId),
      packageNamesJson: Value(packageNamesJson),
      patternsJson: Value(patternsJson),
      amountGroup: Value(amountGroup),
      sign: Value(sign),
      version: Value(version),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory RegexConfigCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RegexConfigCacheData(
      bankId: serializer.fromJson<String>(json['bankId']),
      packageNamesJson: serializer.fromJson<String>(json['packageNamesJson']),
      patternsJson: serializer.fromJson<String>(json['patternsJson']),
      amountGroup: serializer.fromJson<int>(json['amountGroup']),
      sign: serializer.fromJson<String>(json['sign']),
      version: serializer.fromJson<int>(json['version']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bankId': serializer.toJson<String>(bankId),
      'packageNamesJson': serializer.toJson<String>(packageNamesJson),
      'patternsJson': serializer.toJson<String>(patternsJson),
      'amountGroup': serializer.toJson<int>(amountGroup),
      'sign': serializer.toJson<String>(sign),
      'version': serializer.toJson<int>(version),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  RegexConfigCacheData copyWith({
    String? bankId,
    String? packageNamesJson,
    String? patternsJson,
    int? amountGroup,
    String? sign,
    int? version,
    int? fetchedAt,
  }) => RegexConfigCacheData(
    bankId: bankId ?? this.bankId,
    packageNamesJson: packageNamesJson ?? this.packageNamesJson,
    patternsJson: patternsJson ?? this.patternsJson,
    amountGroup: amountGroup ?? this.amountGroup,
    sign: sign ?? this.sign,
    version: version ?? this.version,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  RegexConfigCacheData copyWithCompanion(RegexConfigCacheCompanion data) {
    return RegexConfigCacheData(
      bankId: data.bankId.present ? data.bankId.value : this.bankId,
      packageNamesJson: data.packageNamesJson.present
          ? data.packageNamesJson.value
          : this.packageNamesJson,
      patternsJson: data.patternsJson.present
          ? data.patternsJson.value
          : this.patternsJson,
      amountGroup: data.amountGroup.present
          ? data.amountGroup.value
          : this.amountGroup,
      sign: data.sign.present ? data.sign.value : this.sign,
      version: data.version.present ? data.version.value : this.version,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RegexConfigCacheData(')
          ..write('bankId: $bankId, ')
          ..write('packageNamesJson: $packageNamesJson, ')
          ..write('patternsJson: $patternsJson, ')
          ..write('amountGroup: $amountGroup, ')
          ..write('sign: $sign, ')
          ..write('version: $version, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bankId,
    packageNamesJson,
    patternsJson,
    amountGroup,
    sign,
    version,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RegexConfigCacheData &&
          other.bankId == this.bankId &&
          other.packageNamesJson == this.packageNamesJson &&
          other.patternsJson == this.patternsJson &&
          other.amountGroup == this.amountGroup &&
          other.sign == this.sign &&
          other.version == this.version &&
          other.fetchedAt == this.fetchedAt);
}

class RegexConfigCacheCompanion extends UpdateCompanion<RegexConfigCacheData> {
  final Value<String> bankId;
  final Value<String> packageNamesJson;
  final Value<String> patternsJson;
  final Value<int> amountGroup;
  final Value<String> sign;
  final Value<int> version;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const RegexConfigCacheCompanion({
    this.bankId = const Value.absent(),
    this.packageNamesJson = const Value.absent(),
    this.patternsJson = const Value.absent(),
    this.amountGroup = const Value.absent(),
    this.sign = const Value.absent(),
    this.version = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RegexConfigCacheCompanion.insert({
    required String bankId,
    required String packageNamesJson,
    required String patternsJson,
    this.amountGroup = const Value.absent(),
    required String sign,
    required int version,
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : bankId = Value(bankId),
       packageNamesJson = Value(packageNamesJson),
       patternsJson = Value(patternsJson),
       sign = Value(sign),
       version = Value(version),
       fetchedAt = Value(fetchedAt);
  static Insertable<RegexConfigCacheData> custom({
    Expression<String>? bankId,
    Expression<String>? packageNamesJson,
    Expression<String>? patternsJson,
    Expression<int>? amountGroup,
    Expression<String>? sign,
    Expression<int>? version,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bankId != null) 'bank_id': bankId,
      if (packageNamesJson != null) 'package_names_json': packageNamesJson,
      if (patternsJson != null) 'patterns_json': patternsJson,
      if (amountGroup != null) 'amount_group': amountGroup,
      if (sign != null) 'sign': sign,
      if (version != null) 'version': version,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RegexConfigCacheCompanion copyWith({
    Value<String>? bankId,
    Value<String>? packageNamesJson,
    Value<String>? patternsJson,
    Value<int>? amountGroup,
    Value<String>? sign,
    Value<int>? version,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return RegexConfigCacheCompanion(
      bankId: bankId ?? this.bankId,
      packageNamesJson: packageNamesJson ?? this.packageNamesJson,
      patternsJson: patternsJson ?? this.patternsJson,
      amountGroup: amountGroup ?? this.amountGroup,
      sign: sign ?? this.sign,
      version: version ?? this.version,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bankId.present) {
      map['bank_id'] = Variable<String>(bankId.value);
    }
    if (packageNamesJson.present) {
      map['package_names_json'] = Variable<String>(packageNamesJson.value);
    }
    if (patternsJson.present) {
      map['patterns_json'] = Variable<String>(patternsJson.value);
    }
    if (amountGroup.present) {
      map['amount_group'] = Variable<int>(amountGroup.value);
    }
    if (sign.present) {
      map['sign'] = Variable<String>(sign.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RegexConfigCacheCompanion(')
          ..write('bankId: $bankId, ')
          ..write('packageNamesJson: $packageNamesJson, ')
          ..write('patternsJson: $patternsJson, ')
          ..write('amountGroup: $amountGroup, ')
          ..write('sign: $sign, ')
          ..write('version: $version, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomRegexRulesTable extends CustomRegexRules
    with TableInfo<$CustomRegexRulesTable, CustomRegexRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomRegexRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankIdMeta = const VerificationMeta('bankId');
  @override
  late final GeneratedColumn<String> bankId = GeneratedColumn<String>(
    'bank_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNamesJsonMeta = const VerificationMeta(
    'packageNamesJson',
  );
  @override
  late final GeneratedColumn<String> packageNamesJson = GeneratedColumn<String>(
    'package_names_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patternsJsonMeta = const VerificationMeta(
    'patternsJson',
  );
  @override
  late final GeneratedColumn<String> patternsJson = GeneratedColumn<String>(
    'patterns_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signMeta = const VerificationMeta('sign');
  @override
  late final GeneratedColumn<String> sign = GeneratedColumn<String>(
    'sign',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bankId,
    name,
    packageNamesJson,
    patternsJson,
    sign,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_regex_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomRegexRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bank_id')) {
      context.handle(
        _bankIdMeta,
        bankId.isAcceptableOrUnknown(data['bank_id']!, _bankIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bankIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('package_names_json')) {
      context.handle(
        _packageNamesJsonMeta,
        packageNamesJson.isAcceptableOrUnknown(
          data['package_names_json']!,
          _packageNamesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNamesJsonMeta);
    }
    if (data.containsKey('patterns_json')) {
      context.handle(
        _patternsJsonMeta,
        patternsJson.isAcceptableOrUnknown(
          data['patterns_json']!,
          _patternsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_patternsJsonMeta);
    }
    if (data.containsKey('sign')) {
      context.handle(
        _signMeta,
        sign.isAcceptableOrUnknown(data['sign']!, _signMeta),
      );
    } else if (isInserting) {
      context.missing(_signMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomRegexRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomRegexRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bankId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      packageNamesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_names_json'],
      )!,
      patternsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patterns_json'],
      )!,
      sign: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sign'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CustomRegexRulesTable createAlias(String alias) {
    return $CustomRegexRulesTable(attachedDatabase, alias);
  }
}

class CustomRegexRule extends DataClass implements Insertable<CustomRegexRule> {
  final String id;
  final String bankId;
  final String name;
  final String packageNamesJson;
  final String patternsJson;
  final String sign;
  final bool isActive;
  final int createdAt;
  const CustomRegexRule({
    required this.id,
    required this.bankId,
    required this.name,
    required this.packageNamesJson,
    required this.patternsJson,
    required this.sign,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bank_id'] = Variable<String>(bankId);
    map['name'] = Variable<String>(name);
    map['package_names_json'] = Variable<String>(packageNamesJson);
    map['patterns_json'] = Variable<String>(patternsJson);
    map['sign'] = Variable<String>(sign);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CustomRegexRulesCompanion toCompanion(bool nullToAbsent) {
    return CustomRegexRulesCompanion(
      id: Value(id),
      bankId: Value(bankId),
      name: Value(name),
      packageNamesJson: Value(packageNamesJson),
      patternsJson: Value(patternsJson),
      sign: Value(sign),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory CustomRegexRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomRegexRule(
      id: serializer.fromJson<String>(json['id']),
      bankId: serializer.fromJson<String>(json['bankId']),
      name: serializer.fromJson<String>(json['name']),
      packageNamesJson: serializer.fromJson<String>(json['packageNamesJson']),
      patternsJson: serializer.fromJson<String>(json['patternsJson']),
      sign: serializer.fromJson<String>(json['sign']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bankId': serializer.toJson<String>(bankId),
      'name': serializer.toJson<String>(name),
      'packageNamesJson': serializer.toJson<String>(packageNamesJson),
      'patternsJson': serializer.toJson<String>(patternsJson),
      'sign': serializer.toJson<String>(sign),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CustomRegexRule copyWith({
    String? id,
    String? bankId,
    String? name,
    String? packageNamesJson,
    String? patternsJson,
    String? sign,
    bool? isActive,
    int? createdAt,
  }) => CustomRegexRule(
    id: id ?? this.id,
    bankId: bankId ?? this.bankId,
    name: name ?? this.name,
    packageNamesJson: packageNamesJson ?? this.packageNamesJson,
    patternsJson: patternsJson ?? this.patternsJson,
    sign: sign ?? this.sign,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  CustomRegexRule copyWithCompanion(CustomRegexRulesCompanion data) {
    return CustomRegexRule(
      id: data.id.present ? data.id.value : this.id,
      bankId: data.bankId.present ? data.bankId.value : this.bankId,
      name: data.name.present ? data.name.value : this.name,
      packageNamesJson: data.packageNamesJson.present
          ? data.packageNamesJson.value
          : this.packageNamesJson,
      patternsJson: data.patternsJson.present
          ? data.patternsJson.value
          : this.patternsJson,
      sign: data.sign.present ? data.sign.value : this.sign,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomRegexRule(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('name: $name, ')
          ..write('packageNamesJson: $packageNamesJson, ')
          ..write('patternsJson: $patternsJson, ')
          ..write('sign: $sign, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bankId,
    name,
    packageNamesJson,
    patternsJson,
    sign,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomRegexRule &&
          other.id == this.id &&
          other.bankId == this.bankId &&
          other.name == this.name &&
          other.packageNamesJson == this.packageNamesJson &&
          other.patternsJson == this.patternsJson &&
          other.sign == this.sign &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class CustomRegexRulesCompanion extends UpdateCompanion<CustomRegexRule> {
  final Value<String> id;
  final Value<String> bankId;
  final Value<String> name;
  final Value<String> packageNamesJson;
  final Value<String> patternsJson;
  final Value<String> sign;
  final Value<bool> isActive;
  final Value<int> createdAt;
  final Value<int> rowid;
  const CustomRegexRulesCompanion({
    this.id = const Value.absent(),
    this.bankId = const Value.absent(),
    this.name = const Value.absent(),
    this.packageNamesJson = const Value.absent(),
    this.patternsJson = const Value.absent(),
    this.sign = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomRegexRulesCompanion.insert({
    required String id,
    required String bankId,
    required String name,
    required String packageNamesJson,
    required String patternsJson,
    required String sign,
    this.isActive = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bankId = Value(bankId),
       name = Value(name),
       packageNamesJson = Value(packageNamesJson),
       patternsJson = Value(patternsJson),
       sign = Value(sign),
       createdAt = Value(createdAt);
  static Insertable<CustomRegexRule> custom({
    Expression<String>? id,
    Expression<String>? bankId,
    Expression<String>? name,
    Expression<String>? packageNamesJson,
    Expression<String>? patternsJson,
    Expression<String>? sign,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bankId != null) 'bank_id': bankId,
      if (name != null) 'name': name,
      if (packageNamesJson != null) 'package_names_json': packageNamesJson,
      if (patternsJson != null) 'patterns_json': patternsJson,
      if (sign != null) 'sign': sign,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomRegexRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? bankId,
    Value<String>? name,
    Value<String>? packageNamesJson,
    Value<String>? patternsJson,
    Value<String>? sign,
    Value<bool>? isActive,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return CustomRegexRulesCompanion(
      id: id ?? this.id,
      bankId: bankId ?? this.bankId,
      name: name ?? this.name,
      packageNamesJson: packageNamesJson ?? this.packageNamesJson,
      patternsJson: patternsJson ?? this.patternsJson,
      sign: sign ?? this.sign,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bankId.present) {
      map['bank_id'] = Variable<String>(bankId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (packageNamesJson.present) {
      map['package_names_json'] = Variable<String>(packageNamesJson.value);
    }
    if (patternsJson.present) {
      map['patterns_json'] = Variable<String>(patternsJson.value);
    }
    if (sign.present) {
      map['sign'] = Variable<String>(sign.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomRegexRulesCompanion(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('name: $name, ')
          ..write('packageNamesJson: $packageNamesJson, ')
          ..write('patternsJson: $patternsJson, ')
          ..write('sign: $sign, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingsEnvelopesTable extends SavingsEnvelopes
    with TableInfo<$SavingsEnvelopesTable, SavingsEnvelope> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsEnvelopesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetAmountVndMeta = const VerificationMeta(
    'targetAmountVnd',
  );
  @override
  late final GeneratedColumn<int> targetAmountVnd = GeneratedColumn<int>(
    'target_amount_vnd',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentAmountVndMeta = const VerificationMeta(
    'currentAmountVnd',
  );
  @override
  late final GeneratedColumn<int> currentAmountVnd = GeneratedColumn<int>(
    'current_amount_vnd',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _autoAllocationPercentMeta =
      const VerificationMeta('autoAllocationPercent');
  @override
  late final GeneratedColumn<int> autoAllocationPercent = GeneratedColumn<int>(
    'auto_allocation_percent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconCodeMeta = const VerificationMeta(
    'iconCode',
  );
  @override
  late final GeneratedColumn<int> iconCode = GeneratedColumn<int>(
    'icon_code',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    targetAmountVnd,
    currentAmountVnd,
    autoAllocationPercent,
    colorHex,
    iconCode,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_envelopes';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsEnvelope> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_amount_vnd')) {
      context.handle(
        _targetAmountVndMeta,
        targetAmountVnd.isAcceptableOrUnknown(
          data['target_amount_vnd']!,
          _targetAmountVndMeta,
        ),
      );
    }
    if (data.containsKey('current_amount_vnd')) {
      context.handle(
        _currentAmountVndMeta,
        currentAmountVnd.isAcceptableOrUnknown(
          data['current_amount_vnd']!,
          _currentAmountVndMeta,
        ),
      );
    }
    if (data.containsKey('auto_allocation_percent')) {
      context.handle(
        _autoAllocationPercentMeta,
        autoAllocationPercent.isAcceptableOrUnknown(
          data['auto_allocation_percent']!,
          _autoAllocationPercentMeta,
        ),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('icon_code')) {
      context.handle(
        _iconCodeMeta,
        iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_iconCodeMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsEnvelope map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsEnvelope(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      targetAmountVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_amount_vnd'],
      )!,
      currentAmountVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_amount_vnd'],
      )!,
      autoAllocationPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auto_allocation_percent'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      iconCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SavingsEnvelopesTable createAlias(String alias) {
    return $SavingsEnvelopesTable(attachedDatabase, alias);
  }
}

class SavingsEnvelope extends DataClass implements Insertable<SavingsEnvelope> {
  final String id;
  final String name;
  final int targetAmountVnd;
  final int currentAmountVnd;
  final int autoAllocationPercent;
  final String colorHex;
  final int iconCode;
  final bool isActive;
  final int createdAt;
  const SavingsEnvelope({
    required this.id,
    required this.name,
    required this.targetAmountVnd,
    required this.currentAmountVnd,
    required this.autoAllocationPercent,
    required this.colorHex,
    required this.iconCode,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['target_amount_vnd'] = Variable<int>(targetAmountVnd);
    map['current_amount_vnd'] = Variable<int>(currentAmountVnd);
    map['auto_allocation_percent'] = Variable<int>(autoAllocationPercent);
    map['color_hex'] = Variable<String>(colorHex);
    map['icon_code'] = Variable<int>(iconCode);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SavingsEnvelopesCompanion toCompanion(bool nullToAbsent) {
    return SavingsEnvelopesCompanion(
      id: Value(id),
      name: Value(name),
      targetAmountVnd: Value(targetAmountVnd),
      currentAmountVnd: Value(currentAmountVnd),
      autoAllocationPercent: Value(autoAllocationPercent),
      colorHex: Value(colorHex),
      iconCode: Value(iconCode),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory SavingsEnvelope.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsEnvelope(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetAmountVnd: serializer.fromJson<int>(json['targetAmountVnd']),
      currentAmountVnd: serializer.fromJson<int>(json['currentAmountVnd']),
      autoAllocationPercent: serializer.fromJson<int>(
        json['autoAllocationPercent'],
      ),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      iconCode: serializer.fromJson<int>(json['iconCode']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'targetAmountVnd': serializer.toJson<int>(targetAmountVnd),
      'currentAmountVnd': serializer.toJson<int>(currentAmountVnd),
      'autoAllocationPercent': serializer.toJson<int>(autoAllocationPercent),
      'colorHex': serializer.toJson<String>(colorHex),
      'iconCode': serializer.toJson<int>(iconCode),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SavingsEnvelope copyWith({
    String? id,
    String? name,
    int? targetAmountVnd,
    int? currentAmountVnd,
    int? autoAllocationPercent,
    String? colorHex,
    int? iconCode,
    bool? isActive,
    int? createdAt,
  }) => SavingsEnvelope(
    id: id ?? this.id,
    name: name ?? this.name,
    targetAmountVnd: targetAmountVnd ?? this.targetAmountVnd,
    currentAmountVnd: currentAmountVnd ?? this.currentAmountVnd,
    autoAllocationPercent: autoAllocationPercent ?? this.autoAllocationPercent,
    colorHex: colorHex ?? this.colorHex,
    iconCode: iconCode ?? this.iconCode,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  SavingsEnvelope copyWithCompanion(SavingsEnvelopesCompanion data) {
    return SavingsEnvelope(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetAmountVnd: data.targetAmountVnd.present
          ? data.targetAmountVnd.value
          : this.targetAmountVnd,
      currentAmountVnd: data.currentAmountVnd.present
          ? data.currentAmountVnd.value
          : this.currentAmountVnd,
      autoAllocationPercent: data.autoAllocationPercent.present
          ? data.autoAllocationPercent.value
          : this.autoAllocationPercent,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsEnvelope(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmountVnd: $targetAmountVnd, ')
          ..write('currentAmountVnd: $currentAmountVnd, ')
          ..write('autoAllocationPercent: $autoAllocationPercent, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconCode: $iconCode, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    targetAmountVnd,
    currentAmountVnd,
    autoAllocationPercent,
    colorHex,
    iconCode,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsEnvelope &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetAmountVnd == this.targetAmountVnd &&
          other.currentAmountVnd == this.currentAmountVnd &&
          other.autoAllocationPercent == this.autoAllocationPercent &&
          other.colorHex == this.colorHex &&
          other.iconCode == this.iconCode &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class SavingsEnvelopesCompanion extends UpdateCompanion<SavingsEnvelope> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> targetAmountVnd;
  final Value<int> currentAmountVnd;
  final Value<int> autoAllocationPercent;
  final Value<String> colorHex;
  final Value<int> iconCode;
  final Value<bool> isActive;
  final Value<int> createdAt;
  final Value<int> rowid;
  const SavingsEnvelopesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetAmountVnd = const Value.absent(),
    this.currentAmountVnd = const Value.absent(),
    this.autoAllocationPercent = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsEnvelopesCompanion.insert({
    required String id,
    required String name,
    this.targetAmountVnd = const Value.absent(),
    this.currentAmountVnd = const Value.absent(),
    this.autoAllocationPercent = const Value.absent(),
    required String colorHex,
    required int iconCode,
    this.isActive = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       colorHex = Value(colorHex),
       iconCode = Value(iconCode),
       createdAt = Value(createdAt);
  static Insertable<SavingsEnvelope> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? targetAmountVnd,
    Expression<int>? currentAmountVnd,
    Expression<int>? autoAllocationPercent,
    Expression<String>? colorHex,
    Expression<int>? iconCode,
    Expression<bool>? isActive,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetAmountVnd != null) 'target_amount_vnd': targetAmountVnd,
      if (currentAmountVnd != null) 'current_amount_vnd': currentAmountVnd,
      if (autoAllocationPercent != null)
        'auto_allocation_percent': autoAllocationPercent,
      if (colorHex != null) 'color_hex': colorHex,
      if (iconCode != null) 'icon_code': iconCode,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsEnvelopesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? targetAmountVnd,
    Value<int>? currentAmountVnd,
    Value<int>? autoAllocationPercent,
    Value<String>? colorHex,
    Value<int>? iconCode,
    Value<bool>? isActive,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return SavingsEnvelopesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmountVnd: targetAmountVnd ?? this.targetAmountVnd,
      currentAmountVnd: currentAmountVnd ?? this.currentAmountVnd,
      autoAllocationPercent:
          autoAllocationPercent ?? this.autoAllocationPercent,
      colorHex: colorHex ?? this.colorHex,
      iconCode: iconCode ?? this.iconCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetAmountVnd.present) {
      map['target_amount_vnd'] = Variable<int>(targetAmountVnd.value);
    }
    if (currentAmountVnd.present) {
      map['current_amount_vnd'] = Variable<int>(currentAmountVnd.value);
    }
    if (autoAllocationPercent.present) {
      map['auto_allocation_percent'] = Variable<int>(
        autoAllocationPercent.value,
      );
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<int>(iconCode.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsEnvelopesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmountVnd: $targetAmountVnd, ')
          ..write('currentAmountVnd: $currentAmountVnd, ')
          ..write('autoAllocationPercent: $autoAllocationPercent, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconCode: $iconCode, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingsLogsTable extends SavingsLogs
    with TableInfo<$SavingsLogsTable, SavingsLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _envelopeIdMeta = const VerificationMeta(
    'envelopeId',
  );
  @override
  late final GeneratedColumn<String> envelopeId = GeneratedColumn<String>(
    'envelope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountVndMeta = const VerificationMeta(
    'amountVnd',
  );
  @override
  late final GeneratedColumn<int> amountVnd = GeneratedColumn<int>(
    'amount_vnd',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMsMeta = const VerificationMeta(
    'timestampMs',
  );
  @override
  late final GeneratedColumn<int> timestampMs = GeneratedColumn<int>(
    'timestamp_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    envelopeId,
    amountVnd,
    description,
    timestampMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('envelope_id')) {
      context.handle(
        _envelopeIdMeta,
        envelopeId.isAcceptableOrUnknown(data['envelope_id']!, _envelopeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_envelopeIdMeta);
    }
    if (data.containsKey('amount_vnd')) {
      context.handle(
        _amountVndMeta,
        amountVnd.isAcceptableOrUnknown(data['amount_vnd']!, _amountVndMeta),
      );
    } else if (isInserting) {
      context.missing(_amountVndMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('timestamp_ms')) {
      context.handle(
        _timestampMsMeta,
        timestampMs.isAcceptableOrUnknown(
          data['timestamp_ms']!,
          _timestampMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      envelopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}envelope_id'],
      )!,
      amountVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_vnd'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      timestampMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_ms'],
      )!,
    );
  }

  @override
  $SavingsLogsTable createAlias(String alias) {
    return $SavingsLogsTable(attachedDatabase, alias);
  }
}

class SavingsLog extends DataClass implements Insertable<SavingsLog> {
  final String id;
  final String envelopeId;
  final int amountVnd;
  final String description;
  final int timestampMs;
  const SavingsLog({
    required this.id,
    required this.envelopeId,
    required this.amountVnd,
    required this.description,
    required this.timestampMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['envelope_id'] = Variable<String>(envelopeId);
    map['amount_vnd'] = Variable<int>(amountVnd);
    map['description'] = Variable<String>(description);
    map['timestamp_ms'] = Variable<int>(timestampMs);
    return map;
  }

  SavingsLogsCompanion toCompanion(bool nullToAbsent) {
    return SavingsLogsCompanion(
      id: Value(id),
      envelopeId: Value(envelopeId),
      amountVnd: Value(amountVnd),
      description: Value(description),
      timestampMs: Value(timestampMs),
    );
  }

  factory SavingsLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsLog(
      id: serializer.fromJson<String>(json['id']),
      envelopeId: serializer.fromJson<String>(json['envelopeId']),
      amountVnd: serializer.fromJson<int>(json['amountVnd']),
      description: serializer.fromJson<String>(json['description']),
      timestampMs: serializer.fromJson<int>(json['timestampMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'envelopeId': serializer.toJson<String>(envelopeId),
      'amountVnd': serializer.toJson<int>(amountVnd),
      'description': serializer.toJson<String>(description),
      'timestampMs': serializer.toJson<int>(timestampMs),
    };
  }

  SavingsLog copyWith({
    String? id,
    String? envelopeId,
    int? amountVnd,
    String? description,
    int? timestampMs,
  }) => SavingsLog(
    id: id ?? this.id,
    envelopeId: envelopeId ?? this.envelopeId,
    amountVnd: amountVnd ?? this.amountVnd,
    description: description ?? this.description,
    timestampMs: timestampMs ?? this.timestampMs,
  );
  SavingsLog copyWithCompanion(SavingsLogsCompanion data) {
    return SavingsLog(
      id: data.id.present ? data.id.value : this.id,
      envelopeId: data.envelopeId.present
          ? data.envelopeId.value
          : this.envelopeId,
      amountVnd: data.amountVnd.present ? data.amountVnd.value : this.amountVnd,
      description: data.description.present
          ? data.description.value
          : this.description,
      timestampMs: data.timestampMs.present
          ? data.timestampMs.value
          : this.timestampMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsLog(')
          ..write('id: $id, ')
          ..write('envelopeId: $envelopeId, ')
          ..write('amountVnd: $amountVnd, ')
          ..write('description: $description, ')
          ..write('timestampMs: $timestampMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, envelopeId, amountVnd, description, timestampMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsLog &&
          other.id == this.id &&
          other.envelopeId == this.envelopeId &&
          other.amountVnd == this.amountVnd &&
          other.description == this.description &&
          other.timestampMs == this.timestampMs);
}

class SavingsLogsCompanion extends UpdateCompanion<SavingsLog> {
  final Value<String> id;
  final Value<String> envelopeId;
  final Value<int> amountVnd;
  final Value<String> description;
  final Value<int> timestampMs;
  final Value<int> rowid;
  const SavingsLogsCompanion({
    this.id = const Value.absent(),
    this.envelopeId = const Value.absent(),
    this.amountVnd = const Value.absent(),
    this.description = const Value.absent(),
    this.timestampMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsLogsCompanion.insert({
    required String id,
    required String envelopeId,
    required int amountVnd,
    required String description,
    required int timestampMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       envelopeId = Value(envelopeId),
       amountVnd = Value(amountVnd),
       description = Value(description),
       timestampMs = Value(timestampMs);
  static Insertable<SavingsLog> custom({
    Expression<String>? id,
    Expression<String>? envelopeId,
    Expression<int>? amountVnd,
    Expression<String>? description,
    Expression<int>? timestampMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (envelopeId != null) 'envelope_id': envelopeId,
      if (amountVnd != null) 'amount_vnd': amountVnd,
      if (description != null) 'description': description,
      if (timestampMs != null) 'timestamp_ms': timestampMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? envelopeId,
    Value<int>? amountVnd,
    Value<String>? description,
    Value<int>? timestampMs,
    Value<int>? rowid,
  }) {
    return SavingsLogsCompanion(
      id: id ?? this.id,
      envelopeId: envelopeId ?? this.envelopeId,
      amountVnd: amountVnd ?? this.amountVnd,
      description: description ?? this.description,
      timestampMs: timestampMs ?? this.timestampMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (envelopeId.present) {
      map['envelope_id'] = Variable<String>(envelopeId.value);
    }
    if (amountVnd.present) {
      map['amount_vnd'] = Variable<int>(amountVnd.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (timestampMs.present) {
      map['timestamp_ms'] = Variable<int>(timestampMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsLogsCompanion(')
          ..write('id: $id, ')
          ..write('envelopeId: $envelopeId, ')
          ..write('amountVnd: $amountVnd, ')
          ..write('description: $description, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $RegexConfigCacheTable regexConfigCache = $RegexConfigCacheTable(
    this,
  );
  late final $CustomRegexRulesTable customRegexRules = $CustomRegexRulesTable(
    this,
  );
  late final $SavingsEnvelopesTable savingsEnvelopes = $SavingsEnvelopesTable(
    this,
  );
  late final $SavingsLogsTable savingsLogs = $SavingsLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactions,
    regexConfigCache,
    customRegexRules,
    savingsEnvelopes,
    savingsLogs,
  ];
}

typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String bankId,
      required int amountVnd,
      required String sign,
      required int timestampMs,
      required int createdAt,
      Value<int?> syncedAt,
      Value<String?> rawContent,
      Value<bool> isDraft,
      Value<String?> categoryId,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> bankId,
      Value<int> amountVnd,
      Value<String> sign,
      Value<int> timestampMs,
      Value<int> createdAt,
      Value<int?> syncedAt,
      Value<String?> rawContent,
      Value<bool> isDraft,
      Value<String?> categoryId,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDb, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
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

  ColumnFilters<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountVnd => $composableBuilder(
    column: $table.amountVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sign => $composableBuilder(
    column: $table.sign,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawContent => $composableBuilder(
    column: $table.rawContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDraft => $composableBuilder(
    column: $table.isDraft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDb, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
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

  ColumnOrderings<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountVnd => $composableBuilder(
    column: $table.amountVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sign => $composableBuilder(
    column: $table.sign,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawContent => $composableBuilder(
    column: $table.rawContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDraft => $composableBuilder(
    column: $table.isDraft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDb, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bankId =>
      $composableBuilder(column: $table.bankId, builder: (column) => column);

  GeneratedColumn<int> get amountVnd =>
      $composableBuilder(column: $table.amountVnd, builder: (column) => column);

  GeneratedColumn<String> get sign =>
      $composableBuilder(column: $table.sign, builder: (column) => column);

  GeneratedColumn<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<String> get rawContent => $composableBuilder(
    column: $table.rawContent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDraft =>
      $composableBuilder(column: $table.isDraft, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<_$AppDb, $TransactionsTable, Transaction>,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDb db, $TransactionsTable table)
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
                Value<String> id = const Value.absent(),
                Value<String> bankId = const Value.absent(),
                Value<int> amountVnd = const Value.absent(),
                Value<String> sign = const Value.absent(),
                Value<int> timestampMs = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> syncedAt = const Value.absent(),
                Value<String?> rawContent = const Value.absent(),
                Value<bool> isDraft = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                bankId: bankId,
                amountVnd: amountVnd,
                sign: sign,
                timestampMs: timestampMs,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rawContent: rawContent,
                isDraft: isDraft,
                categoryId: categoryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bankId,
                required int amountVnd,
                required String sign,
                required int timestampMs,
                required int createdAt,
                Value<int?> syncedAt = const Value.absent(),
                Value<String?> rawContent = const Value.absent(),
                Value<bool> isDraft = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                bankId: bankId,
                amountVnd: amountVnd,
                sign: sign,
                timestampMs: timestampMs,
                createdAt: createdAt,
                syncedAt: syncedAt,
                rawContent: rawContent,
                isDraft: isDraft,
                categoryId: categoryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Transaction, BaseReferences<_$AppDb, $TransactionsTable, Transaction>),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$RegexConfigCacheTableCreateCompanionBuilder =
    RegexConfigCacheCompanion Function({
      required String bankId,
      required String packageNamesJson,
      required String patternsJson,
      Value<int> amountGroup,
      required String sign,
      required int version,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$RegexConfigCacheTableUpdateCompanionBuilder =
    RegexConfigCacheCompanion Function({
      Value<String> bankId,
      Value<String> packageNamesJson,
      Value<String> patternsJson,
      Value<int> amountGroup,
      Value<String> sign,
      Value<int> version,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$RegexConfigCacheTableFilterComposer
    extends Composer<_$AppDb, $RegexConfigCacheTable> {
  $$RegexConfigCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageNamesJson => $composableBuilder(
    column: $table.packageNamesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patternsJson => $composableBuilder(
    column: $table.patternsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountGroup => $composableBuilder(
    column: $table.amountGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sign => $composableBuilder(
    column: $table.sign,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RegexConfigCacheTableOrderingComposer
    extends Composer<_$AppDb, $RegexConfigCacheTable> {
  $$RegexConfigCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageNamesJson => $composableBuilder(
    column: $table.packageNamesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patternsJson => $composableBuilder(
    column: $table.patternsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountGroup => $composableBuilder(
    column: $table.amountGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sign => $composableBuilder(
    column: $table.sign,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RegexConfigCacheTableAnnotationComposer
    extends Composer<_$AppDb, $RegexConfigCacheTable> {
  $$RegexConfigCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bankId =>
      $composableBuilder(column: $table.bankId, builder: (column) => column);

  GeneratedColumn<String> get packageNamesJson => $composableBuilder(
    column: $table.packageNamesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patternsJson => $composableBuilder(
    column: $table.patternsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountGroup => $composableBuilder(
    column: $table.amountGroup,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sign =>
      $composableBuilder(column: $table.sign, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$RegexConfigCacheTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $RegexConfigCacheTable,
          RegexConfigCacheData,
          $$RegexConfigCacheTableFilterComposer,
          $$RegexConfigCacheTableOrderingComposer,
          $$RegexConfigCacheTableAnnotationComposer,
          $$RegexConfigCacheTableCreateCompanionBuilder,
          $$RegexConfigCacheTableUpdateCompanionBuilder,
          (
            RegexConfigCacheData,
            BaseReferences<
              _$AppDb,
              $RegexConfigCacheTable,
              RegexConfigCacheData
            >,
          ),
          RegexConfigCacheData,
          PrefetchHooks Function()
        > {
  $$RegexConfigCacheTableTableManager(_$AppDb db, $RegexConfigCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RegexConfigCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RegexConfigCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RegexConfigCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bankId = const Value.absent(),
                Value<String> packageNamesJson = const Value.absent(),
                Value<String> patternsJson = const Value.absent(),
                Value<int> amountGroup = const Value.absent(),
                Value<String> sign = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RegexConfigCacheCompanion(
                bankId: bankId,
                packageNamesJson: packageNamesJson,
                patternsJson: patternsJson,
                amountGroup: amountGroup,
                sign: sign,
                version: version,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bankId,
                required String packageNamesJson,
                required String patternsJson,
                Value<int> amountGroup = const Value.absent(),
                required String sign,
                required int version,
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => RegexConfigCacheCompanion.insert(
                bankId: bankId,
                packageNamesJson: packageNamesJson,
                patternsJson: patternsJson,
                amountGroup: amountGroup,
                sign: sign,
                version: version,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RegexConfigCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $RegexConfigCacheTable,
      RegexConfigCacheData,
      $$RegexConfigCacheTableFilterComposer,
      $$RegexConfigCacheTableOrderingComposer,
      $$RegexConfigCacheTableAnnotationComposer,
      $$RegexConfigCacheTableCreateCompanionBuilder,
      $$RegexConfigCacheTableUpdateCompanionBuilder,
      (
        RegexConfigCacheData,
        BaseReferences<_$AppDb, $RegexConfigCacheTable, RegexConfigCacheData>,
      ),
      RegexConfigCacheData,
      PrefetchHooks Function()
    >;
typedef $$CustomRegexRulesTableCreateCompanionBuilder =
    CustomRegexRulesCompanion Function({
      required String id,
      required String bankId,
      required String name,
      required String packageNamesJson,
      required String patternsJson,
      required String sign,
      Value<bool> isActive,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$CustomRegexRulesTableUpdateCompanionBuilder =
    CustomRegexRulesCompanion Function({
      Value<String> id,
      Value<String> bankId,
      Value<String> name,
      Value<String> packageNamesJson,
      Value<String> patternsJson,
      Value<String> sign,
      Value<bool> isActive,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$CustomRegexRulesTableFilterComposer
    extends Composer<_$AppDb, $CustomRegexRulesTable> {
  $$CustomRegexRulesTableFilterComposer({
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

  ColumnFilters<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageNamesJson => $composableBuilder(
    column: $table.packageNamesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patternsJson => $composableBuilder(
    column: $table.patternsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sign => $composableBuilder(
    column: $table.sign,
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
}

class $$CustomRegexRulesTableOrderingComposer
    extends Composer<_$AppDb, $CustomRegexRulesTable> {
  $$CustomRegexRulesTableOrderingComposer({
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

  ColumnOrderings<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageNamesJson => $composableBuilder(
    column: $table.packageNamesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patternsJson => $composableBuilder(
    column: $table.patternsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sign => $composableBuilder(
    column: $table.sign,
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
}

class $$CustomRegexRulesTableAnnotationComposer
    extends Composer<_$AppDb, $CustomRegexRulesTable> {
  $$CustomRegexRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bankId =>
      $composableBuilder(column: $table.bankId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get packageNamesJson => $composableBuilder(
    column: $table.packageNamesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patternsJson => $composableBuilder(
    column: $table.patternsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sign =>
      $composableBuilder(column: $table.sign, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CustomRegexRulesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $CustomRegexRulesTable,
          CustomRegexRule,
          $$CustomRegexRulesTableFilterComposer,
          $$CustomRegexRulesTableOrderingComposer,
          $$CustomRegexRulesTableAnnotationComposer,
          $$CustomRegexRulesTableCreateCompanionBuilder,
          $$CustomRegexRulesTableUpdateCompanionBuilder,
          (
            CustomRegexRule,
            BaseReferences<_$AppDb, $CustomRegexRulesTable, CustomRegexRule>,
          ),
          CustomRegexRule,
          PrefetchHooks Function()
        > {
  $$CustomRegexRulesTableTableManager(_$AppDb db, $CustomRegexRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomRegexRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomRegexRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomRegexRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bankId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> packageNamesJson = const Value.absent(),
                Value<String> patternsJson = const Value.absent(),
                Value<String> sign = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomRegexRulesCompanion(
                id: id,
                bankId: bankId,
                name: name,
                packageNamesJson: packageNamesJson,
                patternsJson: patternsJson,
                sign: sign,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bankId,
                required String name,
                required String packageNamesJson,
                required String patternsJson,
                required String sign,
                Value<bool> isActive = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CustomRegexRulesCompanion.insert(
                id: id,
                bankId: bankId,
                name: name,
                packageNamesJson: packageNamesJson,
                patternsJson: patternsJson,
                sign: sign,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomRegexRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $CustomRegexRulesTable,
      CustomRegexRule,
      $$CustomRegexRulesTableFilterComposer,
      $$CustomRegexRulesTableOrderingComposer,
      $$CustomRegexRulesTableAnnotationComposer,
      $$CustomRegexRulesTableCreateCompanionBuilder,
      $$CustomRegexRulesTableUpdateCompanionBuilder,
      (
        CustomRegexRule,
        BaseReferences<_$AppDb, $CustomRegexRulesTable, CustomRegexRule>,
      ),
      CustomRegexRule,
      PrefetchHooks Function()
    >;
typedef $$SavingsEnvelopesTableCreateCompanionBuilder =
    SavingsEnvelopesCompanion Function({
      required String id,
      required String name,
      Value<int> targetAmountVnd,
      Value<int> currentAmountVnd,
      Value<int> autoAllocationPercent,
      required String colorHex,
      required int iconCode,
      Value<bool> isActive,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$SavingsEnvelopesTableUpdateCompanionBuilder =
    SavingsEnvelopesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> targetAmountVnd,
      Value<int> currentAmountVnd,
      Value<int> autoAllocationPercent,
      Value<String> colorHex,
      Value<int> iconCode,
      Value<bool> isActive,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$SavingsEnvelopesTableFilterComposer
    extends Composer<_$AppDb, $SavingsEnvelopesTable> {
  $$SavingsEnvelopesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetAmountVnd => $composableBuilder(
    column: $table.targetAmountVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentAmountVnd => $composableBuilder(
    column: $table.currentAmountVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get autoAllocationPercent => $composableBuilder(
    column: $table.autoAllocationPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconCode => $composableBuilder(
    column: $table.iconCode,
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
}

class $$SavingsEnvelopesTableOrderingComposer
    extends Composer<_$AppDb, $SavingsEnvelopesTable> {
  $$SavingsEnvelopesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetAmountVnd => $composableBuilder(
    column: $table.targetAmountVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentAmountVnd => $composableBuilder(
    column: $table.currentAmountVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get autoAllocationPercent => $composableBuilder(
    column: $table.autoAllocationPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCode => $composableBuilder(
    column: $table.iconCode,
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
}

class $$SavingsEnvelopesTableAnnotationComposer
    extends Composer<_$AppDb, $SavingsEnvelopesTable> {
  $$SavingsEnvelopesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get targetAmountVnd => $composableBuilder(
    column: $table.targetAmountVnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentAmountVnd => $composableBuilder(
    column: $table.currentAmountVnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get autoAllocationPercent => $composableBuilder(
    column: $table.autoAllocationPercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<int> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SavingsEnvelopesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $SavingsEnvelopesTable,
          SavingsEnvelope,
          $$SavingsEnvelopesTableFilterComposer,
          $$SavingsEnvelopesTableOrderingComposer,
          $$SavingsEnvelopesTableAnnotationComposer,
          $$SavingsEnvelopesTableCreateCompanionBuilder,
          $$SavingsEnvelopesTableUpdateCompanionBuilder,
          (
            SavingsEnvelope,
            BaseReferences<_$AppDb, $SavingsEnvelopesTable, SavingsEnvelope>,
          ),
          SavingsEnvelope,
          PrefetchHooks Function()
        > {
  $$SavingsEnvelopesTableTableManager(_$AppDb db, $SavingsEnvelopesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsEnvelopesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsEnvelopesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsEnvelopesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> targetAmountVnd = const Value.absent(),
                Value<int> currentAmountVnd = const Value.absent(),
                Value<int> autoAllocationPercent = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<int> iconCode = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsEnvelopesCompanion(
                id: id,
                name: name,
                targetAmountVnd: targetAmountVnd,
                currentAmountVnd: currentAmountVnd,
                autoAllocationPercent: autoAllocationPercent,
                colorHex: colorHex,
                iconCode: iconCode,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> targetAmountVnd = const Value.absent(),
                Value<int> currentAmountVnd = const Value.absent(),
                Value<int> autoAllocationPercent = const Value.absent(),
                required String colorHex,
                required int iconCode,
                Value<bool> isActive = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SavingsEnvelopesCompanion.insert(
                id: id,
                name: name,
                targetAmountVnd: targetAmountVnd,
                currentAmountVnd: currentAmountVnd,
                autoAllocationPercent: autoAllocationPercent,
                colorHex: colorHex,
                iconCode: iconCode,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavingsEnvelopesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $SavingsEnvelopesTable,
      SavingsEnvelope,
      $$SavingsEnvelopesTableFilterComposer,
      $$SavingsEnvelopesTableOrderingComposer,
      $$SavingsEnvelopesTableAnnotationComposer,
      $$SavingsEnvelopesTableCreateCompanionBuilder,
      $$SavingsEnvelopesTableUpdateCompanionBuilder,
      (
        SavingsEnvelope,
        BaseReferences<_$AppDb, $SavingsEnvelopesTable, SavingsEnvelope>,
      ),
      SavingsEnvelope,
      PrefetchHooks Function()
    >;
typedef $$SavingsLogsTableCreateCompanionBuilder =
    SavingsLogsCompanion Function({
      required String id,
      required String envelopeId,
      required int amountVnd,
      required String description,
      required int timestampMs,
      Value<int> rowid,
    });
typedef $$SavingsLogsTableUpdateCompanionBuilder =
    SavingsLogsCompanion Function({
      Value<String> id,
      Value<String> envelopeId,
      Value<int> amountVnd,
      Value<String> description,
      Value<int> timestampMs,
      Value<int> rowid,
    });

class $$SavingsLogsTableFilterComposer
    extends Composer<_$AppDb, $SavingsLogsTable> {
  $$SavingsLogsTableFilterComposer({
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

  ColumnFilters<String> get envelopeId => $composableBuilder(
    column: $table.envelopeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountVnd => $composableBuilder(
    column: $table.amountVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavingsLogsTableOrderingComposer
    extends Composer<_$AppDb, $SavingsLogsTable> {
  $$SavingsLogsTableOrderingComposer({
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

  ColumnOrderings<String> get envelopeId => $composableBuilder(
    column: $table.envelopeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountVnd => $composableBuilder(
    column: $table.amountVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavingsLogsTableAnnotationComposer
    extends Composer<_$AppDb, $SavingsLogsTable> {
  $$SavingsLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get envelopeId => $composableBuilder(
    column: $table.envelopeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountVnd =>
      $composableBuilder(column: $table.amountVnd, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => column,
  );
}

class $$SavingsLogsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $SavingsLogsTable,
          SavingsLog,
          $$SavingsLogsTableFilterComposer,
          $$SavingsLogsTableOrderingComposer,
          $$SavingsLogsTableAnnotationComposer,
          $$SavingsLogsTableCreateCompanionBuilder,
          $$SavingsLogsTableUpdateCompanionBuilder,
          (SavingsLog, BaseReferences<_$AppDb, $SavingsLogsTable, SavingsLog>),
          SavingsLog,
          PrefetchHooks Function()
        > {
  $$SavingsLogsTableTableManager(_$AppDb db, $SavingsLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> envelopeId = const Value.absent(),
                Value<int> amountVnd = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> timestampMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsLogsCompanion(
                id: id,
                envelopeId: envelopeId,
                amountVnd: amountVnd,
                description: description,
                timestampMs: timestampMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String envelopeId,
                required int amountVnd,
                required String description,
                required int timestampMs,
                Value<int> rowid = const Value.absent(),
              }) => SavingsLogsCompanion.insert(
                id: id,
                envelopeId: envelopeId,
                amountVnd: amountVnd,
                description: description,
                timestampMs: timestampMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavingsLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $SavingsLogsTable,
      SavingsLog,
      $$SavingsLogsTableFilterComposer,
      $$SavingsLogsTableOrderingComposer,
      $$SavingsLogsTableAnnotationComposer,
      $$SavingsLogsTableCreateCompanionBuilder,
      $$SavingsLogsTableUpdateCompanionBuilder,
      (SavingsLog, BaseReferences<_$AppDb, $SavingsLogsTable, SavingsLog>),
      SavingsLog,
      PrefetchHooks Function()
    >;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$RegexConfigCacheTableTableManager get regexConfigCache =>
      $$RegexConfigCacheTableTableManager(_db, _db.regexConfigCache);
  $$CustomRegexRulesTableTableManager get customRegexRules =>
      $$CustomRegexRulesTableTableManager(_db, _db.customRegexRules);
  $$SavingsEnvelopesTableTableManager get savingsEnvelopes =>
      $$SavingsEnvelopesTableTableManager(_db, _db.savingsEnvelopes);
  $$SavingsLogsTableTableManager get savingsLogs =>
      $$SavingsLogsTableTableManager(_db, _db.savingsLogs);
}
