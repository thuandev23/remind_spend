import 'dart:convert';

/// Mirrors Android BankRule data class and iOS BankRegexParser.Rule.
/// Serialised as JSON for remote config and for sending to native via bridge.
class BankRule {
  final String bankId;
  final List<String> packageNames; // Android only
  final List<String> patterns;
  final int amountGroup;
  final String sign; // "debit" | "credit"

  const BankRule({
    required this.bankId,
    required this.packageNames,
    required this.patterns,
    this.amountGroup = 1,
    required this.sign,
  });

  factory BankRule.fromJson(Map<String, dynamic> json) => BankRule(
        bankId: json['bank_id'] as String,
        packageNames:
            (json['package_names'] as List<dynamic>? ?? []).cast<String>(),
        patterns: (json['patterns'] as List<dynamic>).cast<String>(),
        amountGroup: json['amount_group'] as int? ?? 1,
        sign: json['sign'] as String,
      );

  Map<String, dynamic> toJson() => {
        'bank_id': bankId,
        'package_names': packageNames,
        'patterns': patterns,
        'amount_group': amountGroup,
        'sign': sign,
      };

  static List<BankRule> listFromJson(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rules = decoded['rules'] as List<dynamic>;
    return rules.map((r) => BankRule.fromJson(r as Map<String, dynamic>)).toList();
  }

  @override
  bool operator ==(Object other) =>
      other is BankRule && other.bankId == bankId && other.sign == sign;

  @override
  int get hashCode => Object.hash(bankId, sign);
}
