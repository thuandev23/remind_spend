import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/app_db.dart';
import '../services/savings_service.dart';
import 'setup_envelope_sheet.dart';

class SavingsScreen extends StatefulWidget {
  final AppDb db;

  const SavingsScreen({super.key, required this.db});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // GlobalKey cho từng hũ để bắn đồng xu vàng
  final Map<String, GlobalKey> _envelopeKeys = {};

  // Lưu trữ ID của hũ vừa được gõ (tapped) để tạo hiệu ứng dạt sóng vật lý
  String? _tappedEnvelopeId;
  double _waveIntensityMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Helper format tiền tệ VND
  String _formatVnd(num amount) {
    final cleanAmount = amount.abs().toInt();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final match = cleanAmount.toString().replaceAllMapped(reg, (Match m) => '${m[1]},');
    final suffix = amount < 0 ? '-' : '';
    return '$suffix$match đ';
  }

  // Lấy Huy chương tương ứng với tiến độ mục tiêu
  Map<String, dynamic> _getMilestoneBadge(double progress) {
    if (progress >= 1.0) {
      return {'emoji': '🏆', 'title': 'Nhà Vô Địch', 'color': const Color(0xFFFFD700)}; // Vàng
    } else if (progress >= 0.8) {
      return {'emoji': '🔥', 'title': 'Sắp Cán Đích', 'color': const Color(0xFFFF5722)}; // Cam đỏ
    } else if (progress >= 0.5) {
      return {'emoji': '🪵', 'title': 'Vững Chãi', 'color': const Color(0xFF5856D6)}; // Tím
    } else if (progress >= 0.2) {
      return {'emoji': '🌱', 'title': 'Khởi Sắc', 'color': const Color(0xFF34C759)}; // Xanh lá
    } else {
      return {'emoji': '🥚', 'title': 'Hạt Mầm', 'color': const Color(0xFF8E8E93)}; // Xám
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Nền sáng lam nhạt tinh khiết
      appBar: AppBar(
        title: const Text(
          '🔮 Hũ tích lũy Kakeibo',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1C1C1E),
            fontFamily: 'SF Pro Display',
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFFF4F6F9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF007AFF), size: 28), // Xanh dương đậm sang trọng
            onPressed: () => _openSetupSheet(null),
          ),
        ],
      ),
      body: StreamBuilder<List<SavingsEnvelope>>(
        stream: widget.db.watchAllSavingsEnvelopes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final envelopes = snapshot.data ?? [];
          final activeEnvelopes = envelopes.where((e) => e.isActive).toList();

          // Tính tổng số tiền đang tích luỹ
          int totalSavings = 0;
          for (final env in activeEnvelopes) {
            totalSavings += env.currentAmountVnd;
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            physics: const BouncingScrollPhysics(),
            children: [
              // Thẻ tổng quan số dư tích luỹ Glassmorphism Neon Gradient
              _buildSavingsOverviewCard(totalSavings, activeEnvelopes.length),
              const SizedBox(height: 24),

              // Thước đo so sánh tiến độ các Hũ (Kakeibo Milestones Panel) MỚI 🌟
              if (activeEnvelopes.isNotEmpty) ...[
                _buildMilestonesProgressPanel(activeEnvelopes),
                const SizedBox(height: 24),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DANH SÁCH HŨ TÍCH LUỸ (CHẠM ĐỂ TƯƠNG TÁC)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (envelopes.length > activeEnvelopes.length)
                    Text(
                      'Ẩn ${envelopes.length - activeEnvelopes.length} hũ tạm dừng',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (activeEnvelopes.isEmpty)
                _buildEmptyState()
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.70, // Thon dài hơn một chút để tăng chiều cao an toàn chống tràn chữ
                  ),
                  itemCount: activeEnvelopes.length,
                  itemBuilder: (context, index) {
                    final env = activeEnvelopes[index];
                    return _buildEnvelopeCard(env);
                  },
                ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // WIDGET: Tổng quan số tiền tích luỹ Glassmorphism Neon
  Widget _buildSavingsOverviewCard(int totalSavings, int activeCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Nền trắng tinh khiết
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tài sản tích luỹ',
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha:0.08), // Xanh dương nhạt
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFF007AFF).withValues(alpha:0.12)),
                ),
                child: Text(
                  '$activeCount hũ hoạt động',
                  style: const TextStyle(
                    color: Color(0xFF007AFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatVnd(totalSavings),
            style: const TextStyle(
              color: Color(0xFF1C1C1E), // Đen sẫm Apple
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: 'SF Pro Display',
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          // Đường chia Neon mảnh
          Container(height: 1, color: const Color(0xFFE5E5EA)),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF8E8E93), size: 14),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Phân bổ mục tiêu ảo trên sổ sách, hoàn toàn không giữ tiền thật',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET: Bản đồ Hành trình Milestones Kakeibo Game hóa (Kakeibo Quest Board) 🌟
  Widget _buildMilestonesProgressPanel(List<SavingsEnvelope> envelopes) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Nền trắng tinh khiết
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'BẢN ĐỒ HÀNH TRÌNH TÍCH LUỸ KAKEIBO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8E8E93),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha:0.08), // Xanh dương đậm nhạt
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.gamepad_rounded, color: Color(0xFF007AFF), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'HÀNH TRÌNH',
                      style: TextStyle(color: Color(0xFF007AFF), fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 18),
          
          // Quest Board Canvas
          SizedBox(
            height: 75,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 75),
                  painter: KakeiboQuestPainter(
                    envelopes: envelopes,
                    animationValue: _controller.value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Empty State
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white, // Nền trắng tinh khiết
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1.0),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.savings_rounded,
            size: 64,
            color: Color(0xFFC7C7CC),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có hũ tích luỹ nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tạo ngay hũ tích luỹ Kakeibo để phân chia thu nhập ảo trên sổ sách và nuôi heo đất cực kỳ sinh động!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8E8E93),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openSetupSheet(null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tạo hũ đầu tiên', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF), // Xanh dương đậm sang trọng
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        ],
      ),
    );
  }

  // WIDGET: Thẻ hũ Glassmorphism Premium Neon với Liquid Wave Tương tác & Bọt bong bóng
  Widget _buildEnvelopeCard(SavingsEnvelope env) {
    final activeColor = Color(int.parse(env.colorHex.replaceFirst('#', '0xFF')));
    final cardKey = _envelopeKeys.putIfAbsent(env.id, () => GlobalKey());
    
    // Tính tiến độ đạt mục tiêu
    double progress = 0.5; // mặc định 50% cho hũ vô hạn
    if (env.targetAmountVnd > 0) {
      progress = env.currentAmountVnd / env.targetAmountVnd;
    }
    final displayProgress = progress;

    final badge = _getMilestoneBadge(progress);
    final isCurrentlyTapped = _tappedEnvelopeId == env.id;

    return GestureDetector(
      key: cardKey,
      onTapDown: (_) {
        // Tăng biên độ sóng dội lên dồn dập khi tapped (hiệu ứng vật lý nước)
        setState(() {
          _tappedEnvelopeId = env.id;
          _waveIntensityMultiplier = 3.5; // Tăng biên độ sóng gấp 3.5 lần!
        });
        HapticFeedback.lightImpact(); // Rung phản hồi xúc giác nhẹ (Premium!)
      },
      onTapUp: (_) {
        // Trả biên độ sóng về bình thường sau 1.5 giây
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && _tappedEnvelopeId == env.id) {
            setState(() {
              _tappedEnvelopeId = null;
              _waveIntensityMultiplier = 1.0;
            });
          }
        });
        _showEnvelopeDetailSheet(env);
      },
      onLongPress: () => _openSetupSheet(env),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.65), // Kính trắng sữa bóng bẩy
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.02),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha:0.015), // Viền đổ bóng siêu mịn ngoài cùng
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias, // Bo tròn cả các phần tử bên trong card
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Cấu trúc phân tách: Hũ ở trên (Expanded), Chữ thông tin ở dưới
            Positioned.fill(
              child: Column(
                children: [
                  // 1. Khu vực Hũ thủy tinh elip 3D chiếm trọn phần trên thoáng đãng
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14, left: 10, right: 10),
                      child: LiquidWaveWidget(
                        progress: displayProgress,
                        color: activeColor,
                        size: 220,
                        iconCode: env.iconCode,
                        name: env.name,
                        waveIntensityMultiplier: isCurrentlyTapped ? _waveIntensityMultiplier : 1.0,
                        enableBubbles: true, // Kích hoạt bọt khí sủi tăm cao cấp!
                      ),
                    ),
                  ),

                  // 2. Khối thông tin chữ ở chân hũ siêu sạch sẽ trên dải gradient trắng mờ mượt mà (Tự co giãn chiều cao)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6, top: 2), // Giảm nhẹ padding dọc để tối ưu diện tích Column
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha:0.0),
                          Colors.white.withValues(alpha:0.5),
                          Colors.white.withValues(alpha:0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Tối ưu kích thước theo chiều dọc
                      children: [
                        // Tên hũ màu đen sẫm (1 dòng an toàn)
                        Text(
                          env.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C1C1E),
                            fontFamily: 'SF Pro Display',
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 1.0),

                        // Số dư đen đậm và phần trăm (1 dòng an toàn tuyệt đối)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _formatVnd(env.currentAmountVnd),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1C1C1E),
                                  fontFamily: 'SF Pro Display',
                                ),
                              ),
                            ),
                            if (env.targetAmountVnd > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: activeColor,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Trích lập tự động / Lũy kế mục tiêu (1 dòng an toàn tuyệt đối)
                        const SizedBox(height: 0.5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (env.autoAllocationPercent > 0)
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.flash_on_rounded, color: Color(0xFF24B273), size: 10), // Xanh ngọc bích đậm
                                    const SizedBox(width: 1),
                                    Expanded(
                                      child: Text(
                                        'Trích lập: +${env.autoAllocationPercent}%',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF24B273),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (env.targetAmountVnd > 0)
                              Expanded(
                                child: Text(
                                  'Mục tiêu: ${_formatVnd(env.targetAmountVnd)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF8E8E93),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              const Expanded(
                                child: Text(
                                  'Tích luỹ vô hạn 🔄',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: Colors.black26,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Badge Huy chương tiến độ nhỏ gọn lơ lửng ở góc trên bên trái
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: (badge['color'] as Color).withValues(alpha:0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (badge['color'] as Color).withValues(alpha:0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(badge['emoji'] as String, style: const TextStyle(fontSize: 9)),
                    const SizedBox(width: 3),
                    Text(
                      badge['title'] as String,
                      style: TextStyle(
                        color: badge['color'] as Color,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mở Bottom Sheet Setup Hũ
  void _openSetupSheet(SavingsEnvelope? env) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SetupEnvelopeSheet(
        db: widget.db,
        existingEnvelope: env,
      ),
    );
  }

  // Mở Bottom Sheet Chi tiết Hũ (Nạp/Rút & Lịch sử)
  void _showEnvelopeDetailSheet(SavingsEnvelope env) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EnvelopeDetailBottomSheet(
        db: widget.db,
        envelope: env,
        formatVnd: _formatVnd,
        onDepositSuccess: (envId, color) {
          _triggerGoldenCoinDrop(envId, color);
        },
      ),
    );
  }

  void _triggerGoldenCoinDrop(String envId, Color color) {
    // 1. Tìm GlobalKey tương ứng với hũ
    final cardKey = _envelopeKeys[envId];
    if (cardKey == null || cardKey.currentContext == null) return;

    // 2. Lấy tọa độ của Card hũ trên màn hình
    final RenderBox renderBox = cardKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Tọa độ đích rơi của đồng xu (khoảng giữa hũ thủy tinh)
    final double targetX = position.dx + size.width / 2;
    final double targetY = position.dy + size.height * 0.45;

    // 3. Tạo OverlayEntry vẽ đồng xu vàng rơi tự do và nổ splash nước!
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _GoldenCoinDropOverlay(
        startX: targetX,
        startY: 0.0, // Rơi từ đỉnh màn hình xuống!
        targetX: targetX,
        targetY: targetY,
        splashColor: color,
        onComplete: () {
          overlayEntry.remove(); // Gỡ overlay khi hoàn thành
          
          // Kích hoạt dội sóng dữ dội cho hũ đó và rung phản hồi success!
          if (mounted) {
            setState(() {
              _tappedEnvelopeId = envId;
              _waveIntensityMultiplier = 5.0; // Dội sóng cực mạnh khi đồng xu vàng rơi trúng đáy hũ!
            });
            HapticFeedback.vibrate(); // Rung success pattern cực sướng tay!
            
            // Trả biên độ sóng về bình thường sau 2 giây
            Future.delayed(const Duration(milliseconds: 2000), () {
              if (mounted && _tappedEnvelopeId == envId) {
                setState(() {
                  _tappedEnvelopeId = null;
                  _waveIntensityMultiplier = 1.0;
                });
              }
            });
          }
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }
}

// ── LIQUID WAVE ANIMATION WITH GLASSMOPHISM 3D JAR & BUBBLES ─────────────────────

class LiquidWaveWidget extends StatefulWidget {
  final double progress; // 0.0 -> 1.0
  final Color color;
  final double size;
  final double waveIntensityMultiplier; // Cường độ dạt sóng khi tapped
  final bool enableBubbles; // Bật tắt sủi bọt khí
  final int iconCode; // Mã icon đại diện để vẽ lên nhãn treo
  final String name; // Tên hũ để vẽ lên nhãn treo (hoặc hiển thị)

  const LiquidWaveWidget({
    super.key,
    required this.progress,
    required this.color,
    required this.size,
    required this.iconCode,
    required this.name,
    this.waveIntensityMultiplier = 1.0,
    this.enableBubbles = true,
  });

  @override
  State<LiquidWaveWidget> createState() => _LiquidWaveWidgetState();
}

class _LiquidWaveWidgetState extends State<LiquidWaveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Map<String, double>> _bubbles = [];
  final List<Map<String, double>> _sparkles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    // Sinh bọt bong bóng ngẫu nhiên
    if (widget.enableBubbles) {
      final random = Random();
      // Bọt khí wobble
      for (int i = 0; i < 18; i++) {
        _bubbles.add({
          'x': random.nextDouble(), // % chiều rộng [0, 1]
          'y': random.nextDouble(), // % chiều cao ban đầu [0, 1]
          'radius': 1.0 + random.nextDouble() * 2.8, // Bán kính bọt khí
          'speed': 0.12 + random.nextDouble() * 0.16, // Tốc độ bay lên
          'opacity': 0.15 + random.nextDouble() * 0.40, // Độ mờ
          'wobbleSpeed': 1.0 + random.nextDouble() * 2.0, // Tốc độ lắc ngang
          'wobbleAmount': 2.0 + random.nextDouble() * 4.0, // Độ lệch lắc
        });
      }
      // Hạt ánh sáng sparkles lấp lánh li ti
      for (int i = 0; i < 10; i++) {
        _sparkles.add({
          'x': random.nextDouble(),
          'y': random.nextDouble(),
          'size': 2.2 + random.nextDouble() * 2.5,
          'speed': 0.15 + random.nextDouble() * 0.18,
          'opacity': 0.20 + random.nextDouble() * 0.45,
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: LiquidWavePainter(
            progress: widget.progress,
            animationValue: _controller.value,
            color: widget.color,
            waveIntensityMultiplier: widget.waveIntensityMultiplier,
            bubbles: _bubbles,
            sparkles: _sparkles,
            iconCode: widget.iconCode,
            name: widget.name,
          ),
        );
      },
    );
  }
}

class LiquidWavePainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final Color color;
  final double waveIntensityMultiplier;
  final List<Map<String, double>> bubbles;
  final List<Map<String, double>> sparkles;
  final int iconCode;
  final String name;

  LiquidWavePainter({
    required this.progress,
    required this.animationValue,
    required this.color,
    required this.waveIntensityMultiplier,
    required this.bubbles,
    required this.sparkles,
    required this.iconCode,
    required this.name,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final double left = size.width * 0.16;
    final double right = size.width * 0.84;
    final double top = size.height * 0.16;
    final double bottom = size.height * 0.81;
    final double neckWidth = size.width * 0.28;
    final double neckY = size.height * 0.23;

    // 1. Vẽ Bục Thạch Anh Bóng Kính Phát Hào Quang Dịu Nhẹ (Frosted Quartz Pedestal) lơ lửng ở đáy hũ
    final double pedestalWidth = size.width * 0.72;
    final double pedestalHeight = size.height * 0.08;
    final Offset pedestalCenter = Offset(centerX, bottom + 2);
    final Rect pedestalRect = Rect.fromCenter(center: pedestalCenter, width: pedestalWidth, height: pedestalHeight);
    
    // Bóng phát quang neon dịu nhẹ hệ nền sáng
    final hologramGlowPaint = Paint()
      ..color = color.withValues(alpha:0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(pedestalRect, hologramGlowPaint);
    
    // Viền elip thạch anh mờ tinh xảo
    final hologramOutlinePaint = Paint()
      ..color = color.withValues(alpha:0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(pedestalRect, hologramOutlinePaint);
    
    // Tâm bục thạch anh mờ bóng kính
    final hologramCorePaint = Paint()
      ..color = Colors.white.withValues(alpha:0.45)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: pedestalCenter, width: pedestalWidth * 0.7, height: pedestalHeight * 0.7), hologramCorePaint);

    // 2. Định nghĩa Path cho Hũ Thủy Tinh elip Bezier tuyệt mỹ (3D Ellipse Glass Flask)
    final glassPath = Path();
    glassPath.moveTo(centerX - neckWidth / 2, top);
    glassPath.lineTo(centerX + neckWidth / 2, top);
    glassPath.quadraticBezierTo(centerX + neckWidth / 2, neckY, right - 2, neckY + 12);
    glassPath.quadraticBezierTo(right + 3, size.height * 0.53, right - 2, bottom - 12);
    glassPath.quadraticBezierTo(centerX, bottom + 8, left + 2, bottom - 12);
    glassPath.quadraticBezierTo(left - 3, size.height * 0.53, left + 2, neckY + 12);
    glassPath.quadraticBezierTo(centerX - neckWidth / 2, neckY, centerX - neckWidth / 2, top);
    glassPath.close();

    // Lưu trạng thái canvas để clip sóng chất lỏng nằm trọn vẹn trong hũ
    canvas.save();
    canvas.clipPath(glassPath);

    // Vẽ nền hũ kính mờ Glassmorphism trắng sữa trong suốt nổi bật trên nền sáng
    final glassBgPaint = Paint()
      ..color = Colors.white.withValues(alpha:0.24)
      ..style = PaintingStyle.fill;
    canvas.drawPath(glassPath, glassBgPaint);

    // 3. Vẽ Icon Khắc Axit Mờ Chìm Trên Kính (Frosted Glass Engraved Icon) ở tâm hũ
    canvas.save();
    final Offset laserCenter = Offset(centerX, size.height * 0.52);
    final iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(iconCode),
      style: TextStyle(
        fontSize: 32,
        fontFamily: 'MaterialIcons',
        color: color.withValues(alpha:0.35), // Màu trong suốt dịu nhẹ
        shadows: [
          Shadow(
            color: Colors.white, // Bóng đổ trắng nổi khối 3D trên kính
            blurRadius: 4.0,
            offset: const Offset(1.0, 1.0),
          ),
          Shadow(
            color: color.withValues(alpha:0.2),
            blurRadius: 2.0,
            offset: const Offset(-0.5, -0.5),
          ),
        ],
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(laserCenter.dx - iconPainter.width / 2, laserCenter.dy - iconPainter.height / 2),
    );
    canvas.restore();

    // 4. Vẽ sóng chất lỏng 3 lớp cuộn trào pastel mượt mà thanh lịch!
    final clampedProgress = progress.clamp(0.04, 0.96);
    final waterY = bottom - (bottom - top) * clampedProgress * 0.85;

    final wavePath1 = Path();
    final wavePath2 = Path();
    final wavePath3 = Path();

    wavePath1.moveTo(left - 20, size.height + 20);
    wavePath2.moveTo(left - 20, size.height + 20);
    wavePath3.moveTo(left - 20, size.height + 20);

    final amp1 = 4.5 * waveIntensityMultiplier;
    final amp2 = 3.6 * waveIntensityMultiplier;
    final amp3 = 2.7 * waveIntensityMultiplier;

    for (double x = left - 20; x <= right + 20; x += 2.0) {
      final relativeX = (x - left) / (right - left);
      // Sóng 1
      final y1 = waterY + amp1 * sin((relativeX * 2 * pi) + (animationValue * 2 * pi));
      wavePath1.lineTo(x, y1);
      
      // Sóng 2 (lệch pha)
      final y2 = waterY + amp2 * cos((relativeX * 2 * pi) - (animationValue * 2 * pi * 1.2) + pi / 3);
      wavePath2.lineTo(x, y2);
      
      // Sóng 3 (lệch pha)
      final y3 = waterY + amp3 * sin((relativeX * 2 * pi * 1.5) + (animationValue * 2 * pi * 0.8) + pi);
      wavePath3.lineTo(x, y3);
    }

    wavePath1.lineTo(right + 20, size.height + 20);
    wavePath1.close();

    wavePath2.lineTo(right + 20, size.height + 20);
    wavePath2.close();

    wavePath3.lineTo(right + 20, size.height + 20);
    wavePath3.close();

    // Vẽ 3 lớp nước pastel mượt mà nhẹ dịu (tối ưu hóa thẩm mỹ trên nền sáng Scaffold)
    canvas.drawPath(wavePath1, Paint()..color = color.withValues(alpha:0.10)..style = PaintingStyle.fill);
    canvas.drawPath(wavePath2, Paint()..color = color.withValues(alpha:0.24)..style = PaintingStyle.fill);
    canvas.drawPath(wavePath3, Paint()..color = color.withValues(alpha:0.50)..style = PaintingStyle.fill);

    // 5. Vẽ bọt khí sủi tăm sủi tăm wobble sine ngang
    for (final bubble in bubbles) {
      final speed = bubble['speed']!;
      final radius = bubble['radius']!;
      final opacity = bubble['opacity']!;
      final startX = left + bubble['x']! * (right - left);
      final wobbleSpeed = bubble['wobbleSpeed']!;
      final wobbleAmount = bubble['wobbleAmount']!;
      
      final rawY = bottom - ((bottom - top) * bubble['y']! + animationValue * 95 * speed) % (bottom - top);
      final wobbleX = startX + sin(rawY * 0.04 + animationValue * 2 * pi * wobbleSpeed) * wobbleAmount;
      
      if (rawY > waterY + 4) {
        final bubblePaint = Paint()
          ..color = Colors.white.withValues(alpha:opacity * 1.1)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(wobbleX, rawY), radius, bubblePaint);
      }
    }

    // 6. Vẽ hạt ánh sáng sparkles lấp lánh li ti cho hũ Premium
    for (final sparkle in sparkles) {
      final speed = sparkle['speed']!;
      final sizeVal = sparkle['size']!;
      final opacity = sparkle['opacity']!;
      final startX = left + sparkle['x']! * (right - left);
      
      final rawY = bottom - ((bottom - top) * sparkle['y']! + animationValue * 75 * speed) % (bottom - top);
      
      if (rawY > waterY + 4) {
        final sparklePaint = Paint()
          ..color = Colors.white.withValues(alpha:opacity * (sin(animationValue * 2 * pi * 2) * 0.35 + 0.65))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        
        canvas.drawLine(Offset(startX - sizeVal, rawY), Offset(startX + sizeVal, rawY), sparklePaint);
        canvas.drawLine(Offset(startX, rawY - sizeVal), Offset(startX, rawY + sizeVal), sparklePaint);
      }
    }

    // Khôi phục canvas thoát clip hũ
    canvas.restore();

    // 7. Vẽ viền Hũ thủy tinh phát sáng và Specular Highlights phản quang kính
    final glassOutlinePaint = Paint()
      ..color = color.withValues(alpha:0.28) // Viền kính trong suốt thanh lịch
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    
    // Đổ bóng mờ dịu nhẹ quanh viền hũ
    final glassGlowPaint = Paint()
      ..color = color.withValues(alpha:0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(glassPath, glassGlowPaint);
    canvas.drawPath(glassPath, glassOutlinePaint);

    // Specular Highlights: Vết kính phản quang mạn trái hũ (Glass Reflection Highlight)
    final glassReflectionPaint = Paint()
      ..color = Colors.white.withValues(alpha:0.45) // Nổi bật vết phản quang trên nền sáng
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final reflectionPath = Path();
    reflectionPath.moveTo(left + 6, neckY + 16);
    reflectionPath.quadraticBezierTo(left, size.height * 0.54, left + 6, bottom - 16);
    canvas.drawPath(reflectionPath, glassReflectionPaint);

    // Specular spot: Chấm phản quang nhỏ mạn phải trên cổ hũ
    final spotPaint = Paint()
      ..color = Colors.white.withValues(alpha:0.55)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(right - 14, neckY + 22), width: 4.0, height: 10.0),
      spotPaint,
    );

    // 8. Vẽ Nắp Kim Loại Mạ Crom (Chrome Metal Cap) sáng loáng thời thượng
    final capPath = Path();
    final double capLeft = centerX - neckWidth / 2 - 3;
    final double capRight = centerX + neckWidth / 2 + 3;
    final double capTop = top - 11;
    final double capBottom = top + 1;
    
    capPath.moveTo(capLeft + 4, capTop);
    capPath.lineTo(capRight - 4, capTop);
    capPath.quadraticBezierTo(capRight, capTop, capRight, capTop + 4);
    capPath.lineTo(capRight, capBottom);
    capPath.lineTo(capLeft, capBottom);
    capPath.lineTo(capLeft, capTop + 4);
    capPath.quadraticBezierTo(capLeft, capTop, capLeft + 4, capTop);
    capPath.close();

    final capPaint = Paint()
      ..shader = LinearGradient(
        colors: const [
          Color(0xFF8E8E93),
          Color(0xFFE5E5EA),
          Colors.white,
          Color(0xFFAEAEB2),
          Color(0xFF636366),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTRB(capLeft, capTop, capRight, capBottom))
      ..style = PaintingStyle.fill;
    canvas.drawPath(capPath, capPaint);

    final capBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha:0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(capPath, capBorderPaint);
  }

  @override
  bool shouldRepaint(covariant LiquidWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.waveIntensityMultiplier != waveIntensityMultiplier;
  }
}

// ── ENVELOPE DETAIL & TRANSACTION SHEET ───────────────────────────────────────

class _EnvelopeDetailBottomSheet extends StatefulWidget {
  final AppDb db;
  final SavingsEnvelope envelope;
  final String Function(num) formatVnd;
  final Function(String, Color) onDepositSuccess;

  const _EnvelopeDetailBottomSheet({
    required this.db,
    required this.envelope,
    required this.formatVnd,
    required this.onDepositSuccess,
  });

  @override
  State<_EnvelopeDetailBottomSheet> createState() => _EnvelopeDetailBottomSheetState();
}

class _EnvelopeDetailBottomSheetState extends State<_EnvelopeDetailBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  final List<int> _quickAmounts = [50000, 100000, 200000, 500000, 1000000, 2000000];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descController.dispose();
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
    final env = widget.envelope;
    final activeColor = Color(int.parse(env.colorHex.replaceFirst('#', '0xFF')));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh kéo
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(2.25),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Thông tin hũ
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha:0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconData(env.iconCode, fontFamily: 'MaterialIcons'),
                      color: activeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          env.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1C1C1E),
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Số dư: ${widget.formatVnd(env.currentAmountVnd)}${env.targetAmountVnd > 0 ? ' / Mục tiêu: ${widget.formatVnd(env.targetAmountVnd)}' : ' (Tích luỹ vô hạn)'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8E93),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // TabBar phân tách Bỏ ống heo và Lịch sử
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  labelColor: const Color(0xFF1C1C1E),
                  unselectedLabelColor: const Color(0xFF8E8E93),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'SF Pro Display'),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'SF Pro Display'),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: '⚡ Bỏ ống heo nhanh'),
                    Tab(text: '📜 Lịch sử biến động'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // TabView content
              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Tab 1: Bỏ ống heo nhanh (Tích luỹ/Sử dụng)
                    _buildTransactionTab(env, activeColor),

                    // Tab 2: Lịch sử biến động
                    _buildHistoryTab(env),
                  ],
                ),
              ),
              
              // Helper note mỏng ở đáy Bottom Sheet giải thích cơ chế ảo 💡
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '💡 Phân bổ ảo trên sổ sách, hoàn toàn không giữ tiền thật của bạn.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: const Color(0xFF8E8E93),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET: Tab Bỏ ống heo nhanh
  Widget _buildTransactionTab(SavingsEnvelope env, Color themeColor) {
    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ô nhập số tiền
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (val) {
                final formatted = _formatNumber(val);
                _amountController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              },
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: themeColor,
                fontFamily: 'SF Pro Display',
              ),
              decoration: const InputDecoration(
                hintText: '0 đ',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            const SizedBox(height: 12),

            // Chips gợi ý tiền nhanh
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _quickAmounts.length,
                itemBuilder: (context, index) {
                  final amount = _quickAmounts[index];
                  return GestureDetector(
                    onTap: () {
                      setInnerState(() {
                        _amountController.text = _formatNumber(amount.toString());
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        widget.formatVnd(amount).replaceAll(' đ', ''),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Ghi chú giao dịch
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Ghi chú (Tùy chọn)',
                hintText: 'Ví dụ: Bỏ ống heo ảo, Chi tiêu từ quỹ...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const Spacer(),

            // Hai nút bấm Sử dụng quỹ & Bỏ ống heo
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _submitTransaction(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF3B30),
                      side: const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Sử dụng quỹ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _submitTransaction(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34C759),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Bỏ ống heo', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // WIDGET: Tab Lịch sử biến động
  Widget _buildHistoryTab(SavingsEnvelope env) {
    return StreamBuilder<List<SavingsLog>>(
      stream: widget.db.watchEnvelopeLogs(env.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 48, color: Color(0xFFC7C7CC)),
                SizedBox(height: 12),
                Text(
                  'Chưa có biến động số dư',
                  style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500),
                )
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: logs.length,
          separatorBuilder: (context, index) => const Divider(color: Color(0xFFE5E5EA), height: 1),
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final log = logs[index];
            final date = DateTime.fromMillisecondsSinceEpoch(log.timestampMs);
            final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - '
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
            
            final isDeposit = log.amountVnd > 0;
            final amountColor = isDeposit ? const Color(0xFF34C759) : const Color(0xFFFF3B30);
            final amountPrefix = isDeposit ? '+' : '';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  // Icon chỉ hướng nạp/rút
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDeposit ? const Color(0xFF34C759).withValues(alpha:0.12) : const Color(0xFFFF3B30).withValues(alpha:0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDeposit ? Icons.add_rounded : Icons.remove_rounded,
                      color: amountColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nội dung log
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Số tiền
                  Text(
                    '$amountPrefix${widget.formatVnd(log.amountVnd)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Xử lý nạp/rút
  Future<void> _submitTransaction(bool isDeposit) async {
    final amount = _parseAmount(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    final desc = _descController.text.trim();

    if (isDeposit) {
      await SavingsService.depositToEnvelope(widget.db, widget.envelope.id, amount, desc);
    } else {
      // Validate rút không được vượt quá số dư hiện có
      if (amount > widget.envelope.currentAmountVnd) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('❌ Số dư không đủ'),
            content: Text(
              'Số tiền sử dụng (${widget.formatVnd(amount)}) vượt quá số dư hiện tại trong hũ này (${widget.formatVnd(widget.envelope.currentAmountVnd)}).',
            ),
            actions: [
              TextButton(
                child: const Text('Đã hiểu', style: TextStyle(color: Color(0xFF007AFF))),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
        return;
      }
      await SavingsService.withdrawFromEnvelope(widget.db, widget.envelope.id, amount, desc);
    }

    if (mounted) {
      Navigator.pop(context); // Đóng bottom sheet
      
      // Kích hoạt hiệu ứng đồng xu rơi khi bỏ ống heo thành công!
      if (isDeposit) {
        final activeColor = Color(int.parse(widget.envelope.colorHex.replaceFirst('#', '0xFF')));
        widget.onDepositSuccess(widget.envelope.id, activeColor);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDeposit
                ? 'Đã bỏ ${widget.formatVnd(amount)} vào ống heo ảo thành công!'
                : 'Đã sử dụng ${widget.formatVnd(amount)} từ quỹ ảo thành công!',
          ),
          backgroundColor: isDeposit ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
        ),
      );
    }
  }
}

// ── KAKEIBO QUEST TIMELINE PAINTER ──────────────────────────────────────────

class KakeiboQuestPainter extends CustomPainter {
  final List<SavingsEnvelope> envelopes;
  final double animationValue;

  KakeiboQuestPainter({required this.envelopes, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double startX = 25;
    final double endX = size.width - 25;
    final double y = 32;
    final double trailLength = endX - startX;

    // 1. Vẽ đường dẫn làm nền (xanh dương phát sáng nhẹ)
    final trailPaint = Paint()
      ..color = const Color(0xFFE5E5EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(startX, y), Offset(endX, y), trailPaint);

    final neonTrailPaint = Paint()
      ..color = const Color(0xFF007AFF).withValues(alpha:0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawLine(Offset(startX, y), Offset(endX, y), neonTrailPaint);

    // 2. Định nghĩa 5 mốc Milestone
    final List<Map<String, dynamic>> milestones = [
      {'t': 0.0, 'emoji': '🥚', 'title': 'Hạt mầm'},
      {'t': 0.2, 'emoji': '🌱', 'title': 'Khởi sắc'},
      {'t': 0.5, 'emoji': '🪵', 'title': 'Vững chãi'},
      {'t': 0.8, 'emoji': '🔥', 'title': 'Cán đích'},
      {'t': 1.0, 'emoji': '🏆', 'title': 'Vô địch'},
    ];

    // Vẽ các nút Milestone phát sáng
    for (final ms in milestones) {
      final double msX = startX + trailLength * (ms['t'] as double);
      
      // Bóng phát sáng nhẹ cho nút mốc
      final msGlowPaint = Paint()
        ..color = const Color(0xFF007AFF).withValues(alpha:0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset(msX, y), 14, msGlowPaint);

      // Nút nền trắng tròn tinh khiết
      final msBasePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(msX, y), 12, msBasePaint);

      final msBorderPaint = Paint()
        ..color = const Color(0xFFE5E5EA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(msX, y), 12, msBorderPaint);

      // Vẽ Emoji
      final emojiPainter = TextPainter(textDirection: TextDirection.ltr);
      emojiPainter.text = TextSpan(
        text: ms['emoji'] as String,
        style: const TextStyle(fontSize: 12),
      );
      emojiPainter.layout();
      emojiPainter.paint(canvas, Offset(msX - emojiPainter.width / 2, y - emojiPainter.height / 2));

      // Vẽ nhãn chữ Milestone màu xám đậm thanh lịch
      final titlePainter = TextPainter(textDirection: TextDirection.ltr);
      titlePainter.text = TextSpan(
        text: ms['title'] as String,
        style: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF8E8E93),
          fontFamily: 'SF Pro Display',
        ),
      );
      titlePainter.layout();
      titlePainter.paint(canvas, Offset(msX - titlePainter.width / 2, y + 18));
    }

    // 3. Vẽ vị trí các Hũ đang chạy trên con đường
    for (final env in envelopes) {
      double progress = 0.5;
      if (env.targetAmountVnd > 0) {
        progress = (env.currentAmountVnd / env.targetAmountVnd).clamp(0.0, 1.0);
      }
      
      final activeColor = Color(int.parse(env.colorHex.replaceFirst('#', '0xFF')));
      final double envX = startX + trailLength * progress;
      
      // Hiệu ứng "đang thở/nhảy múa" nhẹ: nhấp nhô tọa độ Y theo thời gian
      final double envY = y + sin(animationValue * 2 * pi + env.id.hashCode) * 3.5 - 2;

      // Bóng neon phát sáng màu của hũ
      final envGlowPaint = Paint()
        ..color = activeColor.withValues(alpha:0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(envX, envY), 10, envGlowPaint);

      // Vòng tròn đại diện của hũ
      final envPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(envX, envY), 8, envPaint);

      final envInnerPaint = Paint()
        ..color = Colors.white // Nền trắng ngọc bích tinh khiết phù hợp nền sáng
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(envX, envY), 6, envInnerPaint);

      // Vẽ Icon siêu nhỏ của hũ ở tâm chấm tròn
      final iconPainter = TextPainter(textDirection: TextDirection.ltr);
      iconPainter.text = TextSpan(
        text: String.fromCharCode(env.iconCode),
        style: TextStyle(
          fontSize: 8,
          fontFamily: 'MaterialIcons',
          color: activeColor,
        ),
      );
      iconPainter.layout();
      iconPainter.paint(canvas, Offset(envX - iconPainter.width / 2, envY - iconPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant KakeiboQuestPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.envelopes != envelopes;
  }
}

// ── GOLDEN COIN DROP EFFECT OVERLAY ─────────────────────────────────────────

class _GoldenCoinDropOverlay extends StatefulWidget {
  final double startX;
  final double startY;
  final double targetX;
  final double targetY;
  final Color splashColor;
  final VoidCallback onComplete;

  const _GoldenCoinDropOverlay({
    required this.startX,
    required this.startY,
    required this.targetX,
    required this.targetY,
    required this.splashColor,
    required this.onComplete,
  });

  @override
  State<_GoldenCoinDropOverlay> createState() => _GoldenCoinDropOverlayState();
}

class _GoldenCoinDropOverlayState extends State<_GoldenCoinDropOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<Map<String, dynamic>> _particles = [];
  bool _hasHitWater = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _animController.addListener(() {
      final double progress = _animController.value;
      
      // Chạm nước ở mức progress = 0.60
      if (progress >= 0.60 && !_hasHitWater) {
        _hasHitWater = true;
        // Kích hoạt rung xúc giác chạm nước và sinh hạt splash bắn tung tóe!
        HapticFeedback.mediumImpact();
        widget.onComplete(); // Kích hoạt dội sóng hũ cha sớm khi đồng xu vừa chạm nước!
        _generateSplashParticles();
      }
    });

    _animController.forward();
  }

  void _generateSplashParticles() {
    final random = Random();
    // Sinh 16 hạt nước bắn tung tóe parabol
    for (int i = 0; i < 16; i++) {
      final angle = -pi / 6 - random.nextDouble() * (2 * pi / 3); // Góc bắn hướng lên trên
      final speed = 3.0 + random.nextDouble() * 5.0; // Tốc độ bắn
      _particles.add({
        'vx': cos(angle) * speed,
        'vy': sin(angle) * speed,
        'x': widget.targetX,
        'y': widget.targetY,
        'size': 2.0 + random.nextDouble() * 3.5,
        'opacity': 1.0,
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer( // Bỏ qua tương tác chạm để không block UI!
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _CoinDropPainter(
              startX: widget.startX,
              startY: widget.startY,
              targetX: widget.targetX,
              targetY: widget.targetY,
              progress: _animController.value,
              splashColor: widget.splashColor,
              particles: _particles,
              hasHitWater: _hasHitWater,
            ),
          );
        },
      ),
    );
  }
}

class _CoinDropPainter extends CustomPainter {
  final double startX;
  final double startY;
  final double targetX;
  final double targetY;
  final double progress;
  final Color splashColor;
  final List<Map<String, dynamic>> particles;
  final bool hasHitWater;

  _CoinDropPainter({
    required this.startX,
    required this.startY,
    required this.targetX,
    required this.targetY,
    required this.progress,
    required this.splashColor,
    required this.particles,
    required this.hasHitWater,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Vẽ đồng xu vàng rơi
    if (progress < 0.85) {
      double coinX = startX;
      double coinY = startY;
      
      if (!hasHitWater) {
        // Rơi tự do có gia tốc từ đỉnh
        final double t = progress / 0.60;
        final double easeInT = t * t;
        coinY = startY + (targetY - startY) * easeInT;
      } else {
        // Chìm từ từ sau chạm nước
        final double t = (progress - 0.60) / 0.25;
        coinY = targetY + 30 * t;
      }

      // Xoay 3D quanh trục Y
      final double coinRotation = progress * 6 * pi;
      final double widthMultiplier = cos(coinRotation).abs().clamp(0.1, 1.0);
      
      final double coinRadius = 13.0;
      final coinPaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.fill;

      // Bóng neon
      final coinGlowPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha:0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      
      final coinCenter = Offset(coinX, coinY);
      
      canvas.drawOval(
        Rect.fromCenter(center: coinCenter, width: coinRadius * 2 * widthMultiplier + 6, height: coinRadius * 2 + 6),
        coinGlowPaint,
      );

      canvas.drawOval(
        Rect.fromCenter(center: coinCenter, width: coinRadius * 2 * widthMultiplier, height: coinRadius * 2),
        coinPaint,
      );

      final coinBorderPaint = Paint()
        ..color = const Color(0xFFB8860B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawOval(
        Rect.fromCenter(center: coinCenter, width: coinRadius * 2 * widthMultiplier, height: coinRadius * 2),
        coinBorderPaint,
      );

      final dollarPainter = TextPainter(textDirection: TextDirection.ltr);
      dollarPainter.text = const TextSpan(
        text: 'đ',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Color(0xFFB8860B),
          fontFamily: 'SF Pro Display',
        ),
      );
      dollarPainter.layout();
      dollarPainter.paint(
        canvas,
        Offset(coinX - dollarPainter.width / 2, coinY - dollarPainter.height / 2),
      );
    }

    // 2. Vẽ bọt splash nước sau chạm
    if (hasHitWater) {
      final double t = (progress - 0.60) / 0.40;
      final double gravity = 0.35;

      for (final p in particles) {
        p['vx'] = p['vx'] as double;
        p['vy'] = (p['vy'] as double) + gravity;
        p['x'] = (p['x'] as double) + (p['vx'] as double);
        p['y'] = (p['y'] as double) + (p['vy'] as double);
        p['opacity'] = (1.0 - t).clamp(0.0, 1.0);

        final particlePaint = Paint()
          ..color = splashColor.withValues(alpha:p['opacity'] as double)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(p['x'] as double, p['y'] as double), p['size'] as double, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CoinDropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
