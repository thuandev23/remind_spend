import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show Value;
import '../db/app_db.dart';

class SetupEnvelopeSheet extends StatefulWidget {
  final AppDb db;
  final SavingsEnvelope? existingEnvelope;

  const SetupEnvelopeSheet({
    super.key,
    required this.db,
    this.existingEnvelope,
  });

  @override
  State<SetupEnvelopeSheet> createState() => _SetupEnvelopeSheetState();
}

class _SetupEnvelopeSheetState extends State<SetupEnvelopeSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  late TextEditingController _percentController;

  late String _selectedColorHex;
  late int _selectedIconCode;
  late bool _isActive;

  final List<String> _colors = [
    '#2ECC71', // Xanh lá pastel
    '#3498DB', // Xanh dương
    '#E74C3C', // Đỏ san hô
    '#F1C40F', // Vàng ấm
    '#9B59B6', // Tím oải hương
    '#1ABC9C', // Mint lam
    '#E67E22', // Cam đất
    '#FF7597', // Hồng ngọt ngào
  ];

  final List<Map<String, dynamic>> _icons = [
    {'code': 0xf0160, 'name': 'savings'}, // savings
    {'code': 0xe350, 'name': 'laptop'}, // laptop_rounded
    {'code': 0xe58b, 'name': 'security'}, // shield
    {'code': 0xf05e3, 'name': 'flight'}, // flight_takeoff_rounded
    {'code': 0xe318, 'name': 'home'}, // home
    {'code': 0xe1d7, 'name': 'car'}, // directions_car
    {'code': 0xe3b1, 'name': 'shopping'}, // shopping_cart
    {'code': 0xe3e3, 'name': 'health'}, // favorite_rounded
  ];

  @override
  void initState() {
    super.initState();
    final env = widget.existingEnvelope;
    _nameController = TextEditingController(text: env?.name ?? '');
    
    // Format tiền tệ ban đầu
    final targetVal = env?.targetAmountVnd ?? 0;
    _targetAmountController = TextEditingController(
      text: targetVal > 0 ? _formatNumber(targetVal.toString()) : '',
    );
    
    _percentController = TextEditingController(
      text: env != null ? env.autoAllocationPercent.toString() : '0',
    );

    _selectedColorHex = env?.colorHex ?? _colors[0];
    _selectedIconCode = env?.iconCode ?? _icons[0]['code'];
    _isActive = env?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  String _formatNumber(String s) {
    if (s.isEmpty) return '';
    final num = int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (num == 0) return '';
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return num.toString().replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  int _parseAmount(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingEnvelope != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thanh kéo
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tiêu đề
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? '✏️ Chỉnh sửa hũ tài chính' : '🐷 Tạo hũ tài chính mới',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C1C1E),
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    if (isEdit)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF3B30)),
                        onPressed: _confirmDelete,
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tên hũ
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên hũ tích luỹ',
                    hintText: 'Ví dụ: Mua Macbook Air M3, Quỹ khẩn cấp...',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                    floatingLabelStyle: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên hũ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mục tiêu (VND)
                TextFormField(
                  controller: _targetAmountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (val) {
                    final formatted = _formatNumber(val);
                    _targetAmountController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  },
                  decoration: InputDecoration(
                    labelText: 'Số tiền mục tiêu (đ)',
                    hintText: 'Để trống nếu là tích luỹ vô hạn (Không giới hạn)',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                    floatingLabelStyle: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Phần trăm tự động trích lập
                TextFormField(
                  controller: _percentController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Tỷ lệ tự động trích lập (%)',
                    hintText: 'Nhập % tiền trích từ mỗi giao dịch cộng (Credit)',
                    helperText: 'Tự động trừ từ dòng thu nhập được duyệt để bỏ vào hũ này.',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                    floatingLabelStyle: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập tỷ lệ %';
                    final val = int.tryParse(value) ?? 0;
                    if (val < 0 || val > 100) return 'Tỷ lệ phải từ 0% đến 100%';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Trạng thái hoạt động (Nếu sửa)
                if (isEdit) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kích hoạt hoạt động',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      Switch.adaptive(
                        value: _isActive,
                        activeColor: const Color(0xFF34C759),
                        onChanged: (val) {
                          setState(() {
                            _isActive = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Chọn màu sắc
                const Text(
                  'Chọn màu sắc hũ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colors.length,
                    itemBuilder: (context, index) {
                      final colorHex = _colors[index];
                      final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                      final isSelected = _selectedColorHex == colorHex;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedColorHex = colorHex),
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Chọn Icon đại diện
                const Text(
                  'Chọn biểu tượng hũ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _icons.length,
                  itemBuilder: (context, index) {
                    final item = _icons[index];
                    final code = item['code'];
                    final isSelected = _selectedIconCode == code;
                    final activeColor = Color(int.parse(_selectedColorHex.replaceFirst('#', '0xFF')));

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIconCode = code),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor.withOpacity(0.15) : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? activeColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          IconData(code, fontFamily: 'MaterialIcons'),
                          color: isSelected ? activeColor : const Color(0xFF8E8E93),
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Nút lưu
                ElevatedButton(
                  onPressed: _saveEnvelope,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isEdit ? 'Lưu thay đổi' : 'Tạo hũ tích luỹ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Xóa hũ tài chính?'),
        content: const Text(
          'Tất cả số tiền tích luỹ trong hũ này và lịch sử liên quan sẽ bị xoá khỏi thiết bị. Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF8E8E93))),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Xóa', style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx); // Đóng dialog
              await widget.db.deleteSavingsEnvelope(widget.existingEnvelope!.id);
              if (mounted) {
                Navigator.pop(context); // Đóng sheet
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveEnvelope() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final targetAmount = _parseAmount(_targetAmountController.text);
    final percent = int.tryParse(_percentController.text) ?? 0;

    // Validate tổng tỷ lệ % của các hũ khác
    final envelopes = await widget.db.getAllSavingsEnvelopes();
    int otherTotalPercent = 0;
    for (final e in envelopes) {
      if (e.isActive && e.id != widget.existingEnvelope?.id) {
        otherTotalPercent += e.autoAllocationPercent;
      }
    }

    if (_isActive && (otherTotalPercent + percent > 100)) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('❌ Vượt quá 100%'),
            content: Text(
              'Tổng tỷ lệ phần trăm tự động trích lập của tất cả các hũ đang kích hoạt không được vượt quá 100%.\n\n'
              'Hiện các hũ khác đã dùng: $otherTotalPercent%.\n'
              'Tỷ lệ tối đa bạn có thể đặt cho hũ này là: ${100 - otherTotalPercent}%.',
            ),
            actions: [
              TextButton(
                child: const Text('Đã hiểu', style: TextStyle(color: Color(0xFF007AFF))),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      }
      return;
    }

    final id = widget.existingEnvelope?.id ?? 'env_${DateTime.now().microsecondsSinceEpoch}';
    final createdAt = widget.existingEnvelope?.createdAt ?? DateTime.now().millisecondsSinceEpoch;
    final currentAmount = widget.existingEnvelope?.currentAmountVnd ?? 0;

    final companion = SavingsEnvelopesCompanion.insert(
      id: id,
      name: name,
      targetAmountVnd: Value(targetAmount),
      currentAmountVnd: Value(currentAmount),
      autoAllocationPercent: Value(percent),
      colorHex: _selectedColorHex,
      iconCode: _selectedIconCode,
      isActive: Value(_isActive),
      createdAt: createdAt,
    );

    await widget.db.upsertSavingsEnvelope(companion);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
