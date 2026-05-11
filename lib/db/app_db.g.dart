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
  const Transaction({
    required this.id,
    required this.bankId,
    required this.amountVnd,
    required this.sign,
    required this.timestampMs,
    required this.createdAt,
    this.syncedAt,
    this.rawContent,
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
  }) => Transaction(
    id: id ?? this.id,
    bankId: bankId ?? this.bankId,
    amountVnd: amountVnd ?? this.amountVnd,
    sign: sign ?? this.sign,
    timestampMs: timestampMs ?? this.timestampMs,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    rawContent: rawContent.present ? rawContent.value : this.rawContent,
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
          ..write('rawContent: $rawContent')
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
          other.rawContent == this.rawContent);
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

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $RegexConfigCacheTable regexConfigCache = $RegexConfigCacheTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactions,
    regexConfigCache,
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

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$RegexConfigCacheTableTableManager get regexConfigCache =>
      $$RegexConfigCacheTableTableManager(_db, _db.regexConfigCache);
}
