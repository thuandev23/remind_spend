import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;

import '../db/app_db.dart';
import '../models/bank_rule.dart';
import '../repositories/transaction_repository.dart';
import '../services/regex_sync_service.dart';
import '../services/remote_config_service.dart';
import 'setup_regex_screen.dart';

class RegexRulesScreen extends StatefulWidget {
  final TransactionRepository repo;

  const RegexRulesScreen({super.key, required this.repo});

  @override
  State<RegexRulesScreen> createState() => _RegexRulesScreenState();
}

class _RegexRulesScreenState extends State<RegexRulesScreen> {
  List<CustomRegexRule> _customRules = [];
  List<BankRule> _systemRules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllRules();
  }

  Future<void> _loadAllRules() async {
    setState(() => _isLoading = true);
    try {
      final db = widget.repo.db;
      final custom = await db.getAllCustomRegexRules();
      
      final remoteService = RemoteConfigService(db);
      final system = await remoteService.resolve();
      
      if (mounted) {
        setState(() {
          _customRules = custom;
          _systemRules = system;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Bật/Tắt trạng thái hoạt động của custom rule
  Future<void> _toggleRuleActive(CustomRegexRule rule, bool isActive) async {
    final companion = CustomRegexRulesCompanion(
      id: drift.Value(rule.id),
      isActive: drift.Value(isActive),
    );
    await widget.repo.db.updateCustomRegexRule(rule.id, companion);
    
    // Đồng bộ lại xuống native tức thì!
    await RegexSyncService.syncAllRules(widget.repo.db, RemoteConfigService(widget.repo.db));
    
    _loadAllRules();
  }

  // Xoá custom rule
  Future<void> _deleteRule(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⚠️ Xác nhận xoá', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Bạn có chắc chắn muốn xoá cấu hình Regex cá nhân này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2D55),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xoá', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.repo.db.deleteCustomRegexRule(id);
      
      // Đồng bộ lại xuống native tức thì!
      await RegexSyncService.syncAllRules(widget.repo.db, RemoteConfigService(widget.repo.db));
      
      _loadAllRules();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '🤖 Quản lý Regex Rules',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAllRules,
              color: const Color(0xFF007AFF),
              child: ListView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 80),
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                children: [
                  // PHẦN 1: RULES CÁ NHÂN (CUSTOM RULES)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RULES CÁ NHÂN TỰ ĐỊNH NGHĨA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8E8E93),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Ưu tiên hàng đầu 🌟',
                          style: TextStyle(color: const Color(0xFF007AFF), fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_customRules.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.code_rounded, size: 36, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text(
                            'Chưa có Custom Regex nào.',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nhấn nút "+" ở dưới để tự tạo Regex cho ngân hàng của bạn!',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._customRules.map((rule) => _buildCustomRuleTile(rule)),

                  const SizedBox(height: 28),

                  // PHẦN 2: RULES HỆ THỐNG (SYSTEM RULES)
                  const Text(
                    'RULES MẶC ĐỊNH HỆ THỐNG (READ-ONLY)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8E8E93),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._systemRules.map((rule) => _buildSystemRuleTile(rule)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => SetupRegexScreen(repo: widget.repo),
            ),
          );
          if (res == true) _loadAllRules();
        },
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // WIDGET: Custom Rule Card
  Widget _buildCustomRuleTile(CustomRegexRule rule) {
    String pattern = '';
    try {
      final List list = jsonDecode(rule.patternsJson) as List;
      if (list.isNotEmpty) pattern = list.first as String;
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () async {
            final res = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => SetupRegexScreen(repo: widget.repo, existingRule: rule),
              ),
            );
            if (res == true) _loadAllRules();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon ngân hàng tròn xịn
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (rule.sign == 'debit' ? const Color(0xFFFF2D55) : const Color(0xFF34C759)).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    rule.sign == 'debit' ? Icons.arrow_outward_rounded : Icons.call_received_rounded,
                    size: 20,
                    color: rule.sign == 'debit' ? const Color(0xFFFF2D55) : const Color(0xFF34C759),
                  ),
                ),
                const SizedBox(width: 14),

                // Nội dung rule
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            rule.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rule.bankId,
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.grey[700]),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Regex: $pattern',
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF8E8E93)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Switch Bật/Tắt & Nút xoá
                Switch(
                  value: rule.isActive,
                  activeThumbColor: const Color(0xFF34C759),
                  onChanged: (val) => _toggleRuleActive(rule, val),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF2D55), size: 20),
                  onPressed: () => _deleteRule(rule.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET: System Rule Card
  Widget _buildSystemRuleTile(BankRule rule) {
    final pattern = rule.patterns.isNotEmpty ? rule.patterns.first : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              rule.sign == 'debit' ? Icons.arrow_outward_rounded : Icons.call_received_rounded,
              size: 16,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        rule.bankId.toUpperCase(),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          rule.sign.toUpperCase(),
                          style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Colors.grey[600]),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Regex: $pattern',
                    style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Hệ thống',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.grey[700]),
              ),
            )
          ],
        ),
      ),
    );
  }
}
