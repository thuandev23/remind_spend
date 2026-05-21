import 'dart:ui';
import 'package:flutter/material.dart';

import '../repositories/transaction_repository.dart';
import '../services/pull_service.dart';
import 'dashboard_screen.dart';
import 'transaction_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final TransactionRepository repo;
  final PullService pullService;

  const MainNavigationScreen({
    super.key,
    required this.repo,
    required this.pullService,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TransactionListScreen(
        repo: widget.repo,
        pullService: widget.pullService,
      ),
      DashboardScreen(
        repo: widget.repo,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Layout dạng Stack để thanh Bottom Bar thực sự bay lơ lửng phía trên nội dung
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Nền sáng xám nhẹ siêu sạch
      body: Stack(
        children: [
          // IndexedStack giữ lại trạng thái cuộn & dữ liệu khi chuyển tab
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          
          // Custom Floating Bottom Navigation Bar bay lơ lửng phía trên
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.paddingOf(context).bottom > 0
                ? MediaQuery.paddingOf(context).bottom + 4
                : 16,
            child: _buildFloatingBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75), // Trắng sữa đục mờ
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3), // Viền phản chiếu sáng nhẹ
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08), // Đổ bóng mượt mà, siêu nhẹ
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), // Kính mờ cao cấp
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.receipt_long_rounded,
                  label: 'Giao dịch',
                  activeColor: const Color(0xFF1A1A1A), // Đen huyền bí
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.analytics_rounded,
                  label: 'Thống kê',
                  activeColor: const Color(0xFF007AFF), // Xanh dương iOS thời thượng
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _currentIndex == index;
    
    return InkWell(
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.08) // Nền chuyển màu nhạt khi chọn
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeColor : const Color(0xFF8E8E93),
            ),
            const SizedBox(width: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF8E8E93),
                fontFamily: 'SF Pro Display',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
