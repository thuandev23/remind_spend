import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class GeminiSettingsDialog extends StatefulWidget {
  final String initialApiKey;
  final bool initialEnabled;

  const GeminiSettingsDialog({
    super.key,
    required this.initialApiKey,
    required this.initialEnabled,
  });

  @override
  State<GeminiSettingsDialog> createState() => _GeminiSettingsDialogState();
}

class _GeminiSettingsDialogState extends State<GeminiSettingsDialog> {
  late final TextEditingController _keyCont;
  late bool _enabled;
  bool _obscureText = true;
  bool _testing = false;
  String? _testResult; // 'success', 'fail' hoặc null

  @override
  void initState() {
    super.initState();
    _keyCont = TextEditingController(text: widget.initialApiKey);
    _enabled = widget.initialEnabled;
  }

  @override
  void dispose() {
    _keyCont.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final key = _keyCont.text.trim();
    if (key.isEmpty) {
      setState(() {
        _testResult = 'fail';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập API Key trước khi kiểm tra!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _testing = true;
      _testResult = null;
    });

    final ok = await GeminiService.testConnection(key);

    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = ok ? 'success' : 'fail';
      });
    }
  }

  Future<void> _save() async {
    final key = _keyCont.text.trim();
    
    if (_enabled && key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Vui lòng nhập API Key để kích hoạt AI Auto-Categorization!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await GeminiService.setAiEnabled(_enabled);
    if (key.isNotEmpty) {
      await GeminiService.saveApiKey(key);
    } else {
      await GeminiService.deleteApiKey();
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã lưu cấu hình AI thành công!'),
          backgroundColor: Color(0xFF43A047),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 10,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3C72).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Color(0xFF1E3C72),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'AI Auto-Categorization',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Sử dụng sức mạnh của Gemini AI để tự động gán chính xác các danh mục chi tiêu (Ăn uống, Di chuyển, Mua sắm...) cho những tin nhắn biến động số dư phức tạp.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFEEEEEE)),
              
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Kích hoạt AI Auto-Categorization',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                subtitle: const Text(
                  'Tự động phân tích khi tin nhắn không khớp từ khóa cục bộ',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                ),
                // ignore: deprecated_member_use
                activeColor: const Color(0xFF1E3C72),
                value: _enabled,
                onChanged: (val) {
                  setState(() {
                    _enabled = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              
              Text(
                'Gemini API Key',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _enabled ? const Color(0xFF1A1A1A) : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _keyCont,
                enabled: _enabled,
                obscureText: _obscureText,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Sử dụng API Key mặc định của hệ thống',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: _enabled ? const Color(0xFFF8F9FA) : const Color(0xFFEEEEEE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3C72), width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: _enabled ? const Color(0xFF8A8A8A) : Colors.grey[400],
                      size: 20,
                    ),
                    onPressed: _enabled
                        ? () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          }
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (_enabled) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _testing ? null : _testConnection,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        foregroundColor: const Color(0xFF1E3C72),
                      ),
                      icon: _testing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Color(0xFF1E3C72),
                              ),
                            )
                          : const Icon(Icons.wifi_tethering, size: 16),
                      label: Text(
                        _testing ? 'Đang kết nối...' : 'Kiểm tra kết nối',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_testResult == 'success')
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF43A047), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Kết nối tốt!',
                            style: TextStyle(
                              color: Color(0xFF43A047),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    else if (_testResult == 'fail')
                      const Row(
                        children: [
                          Icon(Icons.error, color: Color(0xFFE53935), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Lỗi kết nối!',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              const Divider(color: Color(0xFFEEEEEE)),
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8A8A8A),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3C72),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Lưu cấu hình',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
