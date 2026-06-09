import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;

import '../db/app_db.dart';
import '../repositories/transaction_repository.dart';
import '../services/regex_sync_service.dart';
import '../services/remote_config_service.dart';
import '../core/utils/formatter.dart';

class SetupRegexScreen extends StatefulWidget {
  final TransactionRepository repo;
  final CustomRegexRule? existingRule; // Null nếu là thêm mới

  const SetupRegexScreen({super.key, required this.repo, this.existingRule});

  @override
  State<SetupRegexScreen> createState() => _SetupRegexScreenState();
}

class _SetupRegexScreenState extends State<SetupRegexScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _bankIdController;
  late TextEditingController _packageNamesController;
  late TextEditingController _patternController;
  late TextEditingController _sampleMessageController;
  
  String _sign = 'debit';
  bool _isActive = true;
  
  // Trạng thái sandbox
  bool _sandboxMatched = false;
  int? _sandboxAmount;
  String? _sandboxError;

  // Danh sách các preset mẫu để gợi ý UX
  final List<Map<String, dynamic>> _presets = [
    {
      'name': 'Vietcombank (VCB)',
      'bankId': 'vcb',
      'packages': 'com.VCB',
      'pattern': r'GD: ?-([0-9,.]+) ?VND',
      'sign': 'debit',
      'sample': 'GD: -150,000 VND luc 12:30. SD: 5,000,000 VND.'
    },
    {
      'name': 'Techcombank (TCB)',
      'bankId': 'tcb',
      'packages': 'com.techcombank.mb.portal',
      'pattern': r'GD: ?-([0-9,.]+) ?VND',
      'sign': 'debit',
      'sample': 'GD: -500,000 VND tai Highlands Coffee. SD: 12,000,000 VND.'
    },
    {
      'name': 'ACB Custom',
      'bankId': 'acb',
      'packages': 'com.acb',
      'pattern': r'Tru tai khoan ([0-9,.]+) VND',
      'sign': 'debit',
      'sample': 'ACB: Tru tai khoan 120,000 VND tai Sieu thi WinMart.'
    },
    {
      'name': 'MoMo Transfer',
      'bankId': 'momo',
      'packages': 'com.mservice.momotransfer',
      'pattern': r'thanh toan ([0-9,.]+) ?đ',
      'sign': 'debit',
      'sample': 'Giao dich thanh toan 60.000 đ qua ZaloPay/MoMo hoan tat.'
    }
  ];

  @override
  void initState() {
    super.initState();
    
    final rule = widget.existingRule;
    _nameController = TextEditingController(text: rule?.name ?? '');
    _bankIdController = TextEditingController(text: rule?.bankId ?? '');
    
    String pkgs = '';
    if (rule != null) {
      try {
        final List list = jsonDecode(rule.packageNamesJson) as List;
        pkgs = list.join(', ');
      } catch (_) {}
    }
    _packageNamesController = TextEditingController(text: pkgs);
    
    String patt = '';
    if (rule != null) {
      try {
        final List list = jsonDecode(rule.patternsJson) as List;
        if (list.isNotEmpty) patt = list.first as String;
      } catch (_) {}
    }
    _patternController = TextEditingController(text: patt);
    _sign = rule?.sign ?? 'debit';
    _isActive = rule?.isActive ?? true;
    
    _sampleMessageController = TextEditingController(
      text: rule != null ? 'Gõ tin nhắn test ở đây...' : '',
    );

    // Lắng nghe thay đổi để chạy sandbox realtime
    _patternController.addListener(_runSandbox);
    _sampleMessageController.addListener(_runSandbox);
    _nameController.addListener(_autoGenBankId);
    
    if (rule != null) {
      // Khởi tạo sandbox nếu chỉnh sửa
      _runSandbox();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankIdController.dispose();
    _packageNamesController.dispose();
    _patternController.dispose();
    _sampleMessageController.dispose();
    super.dispose();
  }

  // Tự động sinh bankId từ Tên thân thiện
  void _autoGenBankId() {
    if (widget.existingRule != null) return; // Không tự sinh khi chỉnh sửa
    final text = _nameController.text.trim();
    if (text.isEmpty) {
      _bankIdController.text = '';
      return;
    }
    
    // Chuyển tiếng Việt có dấu thành không dấu và viết liền chữ thường
    var str = text.toLowerCase();
    const vietnamese = 'aáàảãạâấầẩẫậăắằẳẵặeéèẻẽẹêếềểễệiíìỉĩịoóòỏõọôốồổỗộơớờởỡợuúùủũụưứừửữựyýỳỷỹỵdđ';
    const latin = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiiioooooooooooooooooouuuuuuuuuuuuyyyyyydd';
    for (int i = 0; i < vietnamese.length; i++) {
      str = str.replaceAll(vietnamese[i], latin[i]);
    }
    // Loại bỏ ký tự đặc biệt, chỉ giữ lại chữ cái và số
    str = str.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    _bankIdController.text = str;
  }

  // Thuật toán chạy sandbox phân tích realtime
  void _runSandbox() {
    final smsText = _sampleMessageController.text.trim();
    final patternStr = _patternController.text.trim();
    
    if (smsText.isEmpty || patternStr.isEmpty) {
      setState(() {
        _sandboxMatched = false;
        _sandboxAmount = null;
        _sandboxError = null;
      });
      return;
    }

    try {
      final regex = RegExp(patternStr, caseSensitive: false);
      final match = regex.firstMatch(smsText);
      if (match != null) {
        if (match.groupCount >= 1) {
          final amountStr = match.group(1);
          if (amountStr != null) {
            // Làm sạch và parse tiền
            final cleanStr = amountStr.replaceAll(RegExp(r'[^0-9]'), '');
            final parsed = int.tryParse(cleanStr);
            if (parsed != null && parsed > 0) {
              setState(() {
                _sandboxMatched = true;
                _sandboxAmount = parsed;
                _sandboxError = null;
              });
              return;
            }
          }
        }
        setState(() {
          _sandboxMatched = false;
          _sandboxAmount = null;
          _sandboxError = 'Không trích xuất được số tiền từ Nhóm 1 (Group 1). Hãy đặt dấu ngoặc tròn () xung quanh phần regex khớp số tiền.';
        });
      } else {
        setState(() {
          _sandboxMatched = false;
          _sandboxAmount = null;
          _sandboxError = 'Không tìm thấy kết quả khớp trong chuỗi tin nhắn mẫu.';
        });
      }
    } catch (e) {
      setState(() {
        _sandboxMatched = false;
        _sandboxAmount = null;
        _sandboxError = 'Lỗi cú pháp Regex: ${e.toString()}';
      });
    }
  }

  // Áp dụng nhanh preset gợi ý
  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _nameController.text = preset['name'] as String;
      _bankIdController.text = preset['bankId'] as String;
      _packageNamesController.text = preset['packages'] as String;
      _patternController.text = preset['pattern'] as String;
      _sign = preset['sign'] as String;
      _sampleMessageController.text = preset['sample'] as String;
    });
    // Chạy lại sandbox ngay
    _runSandbox();
  }

  // Lưu dữ liệu xuống Drift DB và sync native
  Future<void> _saveRule() async {
    if (!_formKey.currentState!.validate()) return;
    
    final id = widget.existingRule?.id ?? '${UniqueKey()}_${DateTime.now().millisecondsSinceEpoch}';
    final name = _nameController.text.trim();
    final bankId = _bankIdController.text.trim();
    
    // Tách package names
    final pkgs = _packageNamesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
        
    final patts = [_patternController.text.trim()];

    final companion = CustomRegexRulesCompanion.insert(
      id: id,
      bankId: bankId,
      name: name,
      packageNamesJson: jsonEncode(pkgs),
      patternsJson: jsonEncode(patts),
      sign: _sign,
      isActive: drift.Value(_isActive),
      createdAt: widget.existingRule?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );

    // 1. Lưu vào SQLite
    await widget.repo.db.upsertCustomRegexRule(companion);
    
    // 2. Kích hoạt đồng bộ gộp rules xuống native ngay lập tức
    await RegexSyncService.syncAllRules(widget.repo.db, RemoteConfigService(widget.repo.db));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(widget.existingRule != null ? 'Đã cập nhật cấu hình!' : 'Đã thêm cấu hình Regex mới!'),
            ],
          ),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRule != null;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isEditing ? '🛠️ Sửa cấu hình Regex' : '✨ Thêm Custom Regex',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isEditing)
            Switch(
              value: _isActive,
              activeThumbColor: const Color(0xFF34C759),
              onChanged: (val) {
                setState(() => _isActive = val);
              },
            )

        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
            physics: const BouncingScrollPhysics(),
            children: [
              // Panel Gợi ý nhanh (UX)
              if (!isEditing) ...[
                const Text(
                  'GỢI Ý MẪU NHANH',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF8E8E93), letterSpacing: 0.8),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _presets.map((preset) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Icon(Icons.account_balance_wallet_rounded, size: 14, color: Colors.grey[700]),
                          label: Text(
                            preset['name'] as String,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey[300]!, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          onPressed: () => _applyPreset(preset),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text(
                'THÔNG TIN CẤU HÌNH GENERAL',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF8E8E93), letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              // Card điền thông tin config
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    // Tên cấu hình
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                      decoration: InputDecoration(
                        labelText: 'Tên hiển thị (Ví dụ: ACB Custom)',
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93)),
                        hintText: 'Tên gợi nhớ ngân hàng/ví...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tên cấu hình!' : null,
                    ),
                    const SizedBox(height: 16),

                    // Mã ID (Readonly nếu edit, auto gen nếu add)
                    TextFormField(
                      controller: _bankIdController,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey[700]),
                      enabled: !isEditing,
                      decoration: InputDecoration(
                        labelText: 'Mã định danh hệ thống (bank_id)',
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF2F2F7),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Mã bank_id không được trống!';
                        if (RegExp(r'[^a-z0-9_]').hasMatch(val)) return 'Mã chỉ được chứa chữ thường không dấu, số và dấu gạch dưới!';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Package Names
                    TextFormField(
                      controller: _packageNamesController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                      decoration: InputDecoration(
                        labelText: 'Package Names ứng dụng (cách nhau bởi dấu phẩy)',
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93)),
                        hintText: 'com.acb, com.mservice.momotransfer...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập ít nhất một package name!' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'CẤU HÌNH BIỂU THỨC CHÍNH QUY (REGEX)',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF8E8E93), letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              // Card Regex + Sign
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Segment control chọn Debit/Credit
                    const Text(
                      'LOẠI GIAO DỊCH:',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF8E8E93)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _sign = 'debit'),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _sign == 'debit' ? const Color(0xFFFF2D55).withValues(alpha: 0.1) : const Color(0xFFF2F2F7),
                                border: Border.all(
                                  color: _sign == 'debit' ? const Color(0xFFFF2D55) : Colors.transparent,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Debit (Trừ tiền 💸)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _sign == 'debit' ? const Color(0xFFFF2D55) : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _sign = 'credit'),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _sign == 'credit' ? const Color(0xFF34C759).withValues(alpha: 0.1) : const Color(0xFFF2F2F7),
                                border: Border.all(
                                  color: _sign == 'credit' ? const Color(0xFF34C759) : Colors.transparent,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Credit (Cộng tiền 💰)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _sign == 'credit' ? const Color(0xFF34C759) : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Regex Pattern Input
                    TextFormField(
                      controller: _patternController,
                      style: const TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                      decoration: InputDecoration(
                        labelText: 'Regex Pattern (Yêu cầu có dấu ngoặc () ở phần số tiền)',
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93)),
                        hintText: r'Tru tai khoan ([0-9,.]+) VND',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Regex pattern không được để trống!';
                        if (!val.contains('(') || !val.contains(')')) {
                          return 'Thiếu dấu ngoặc tròn (). Bắt buộc có () bọc quanh phần regex khớp số tiền!';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sandbox Card
              const Text(
                'HỘP CÁT KIỂM THỬ THỜI GIAN THỰC (REALTIME SANDBOX)',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF8E8E93), letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input sample message
                    TextFormField(
                      controller: _sampleMessageController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                      decoration: InputDecoration(
                        labelText: 'Dán hoặc gõ nội dung tin nhắn SMS mẫu vào đây:',
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93)),
                        hintText: 'ACB: Tru tai khoan 150,000 VND...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kết quả phân tích sandbox
                    const Divider(height: 1, color: Color(0xFFE5E5EA)),
                    const SizedBox(height: 16),
                    
                    const Text(
                      'KẾT QUẢ SO KHỚP SANDBOX:',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF8E8E93)),
                    ),
                    const SizedBox(height: 8),

                    if (_patternController.text.isEmpty || _sampleMessageController.text.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Hãy điền đủ Regex Pattern và Tin nhắn mẫu để chạy kiểm tra Sandbox.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600),
                        ),
                      )
                    else if (_sandboxMatched && _sandboxAmount != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF34C759).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF34C759), size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'KHỚP THÀNH CÔNG! 🎉',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF34C759)),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _sign == 'debit' ? const Color(0xFFFF2D55) : const Color(0xFF34C759),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _sign == 'debit' ? 'DEBIT' : 'CREDIT',
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Số tiền phân tích được: ${formatMoneyVnd(_sandboxAmount!)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF2D55).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFF2D55).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.cancel_rounded, color: Color(0xFFFF2D55), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'KHÔNG THỂ KHỚP TIN NHẮN ⚠️',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFFF2D55)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _sandboxError ?? 'Nội dung tin nhắn không khớp với biểu thức Regex.',
                                    style: TextStyle(fontSize: 11, color: Colors.red[800], fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Button Lưu & Kích hoạt
              ElevatedButton(
                onPressed: _sandboxMatched ? _saveRule : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E5EA),
                  disabledForegroundColor: const Color(0xFF8E8E93),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_sandboxMatched ? Icons.cloud_done_rounded : Icons.lock_outline_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      isEditing ? 'Cập nhật & Áp dụng' : 'Kích hoạt Custom Rule 🚀',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
