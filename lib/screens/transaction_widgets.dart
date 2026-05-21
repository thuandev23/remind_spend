import 'package:flutter/material.dart';
import '../core/utils/bank_helper.dart';
import '../core/utils/formatter.dart';
import '../db/app_db.dart';
import '../models/category.dart';

// ─── Number Ticker / Animated Counter ────────────────────────────────────────

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle style;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutQuart,
      builder: (context, val, child) {
        final formatted = formatMoneyVnd(val.toInt());
        return Text(
          formatted,
          style: style,
        );
      },
    );
  }
}

// ─── Shimmer Skeleton Loader ──────────────────────────────────────────────────

class ShimmerLoadingTile extends StatefulWidget {
  const ShimmerLoadingTile({super.key});

  @override
  State<ShimmerLoadingTile> createState() => _ShimmerLoadingTileState();
}

class _ShimmerLoadingTileState extends State<ShimmerLoadingTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEAEA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 110,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 180,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 70,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEAEA),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Pulse Draft Badge ────────────────────────────────────────────────────────

class PulseBadge extends StatefulWidget {
  const PulseBadge({super.key});

  @override
  State<PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<PulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_filled, size: 8, color: Color(0xFFE53935)),
                SizedBox(width: 3),
                Text(
                  'CẦN DUYỆT',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── New-item slide-in animation ──────────────────────────────────────────────

class AnimatedNewItem extends StatelessWidget {
  final bool animate;
  final Widget child;
  const AnimatedNewItem({super.key, required this.animate, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      child: child,
      builder: (_, value, inner) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, -16 * (1 - value)),
          child: inner,
        ),
      ),
    );
  }
}

// ─── Confirmed Transaction Tile ───────────────────────────────────────────────

class ConfirmedTransactionTile extends StatelessWidget {
  final Transaction tx;
  final VoidCallback? onTapCategory;

  const ConfirmedTransactionTile({
    super.key,
    required this.tx,
    this.onTapCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit = tx.sign == 'debit';
    final amountColor = isDebit ? const Color(0xFFE53935) : const Color(0xFF43A047);
    final amountPrefix = isDebit ? '-' : '+';
    final formattedAmount = formatAmountAbbr(tx.amountVnd);
    final time = DateTime.fromMillisecondsSinceEpoch(tx.timestampMs);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    // Kiểm tra xem đây có phải là giao dịch tự động không (có rawContent)
    final isAutomated = tx.rawContent != null;

    final category = AppCategory.fromId(tx.categoryId, sign: tx.sign);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDebit ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isDebit ? Icons.arrow_upward : Icons.arrow_downward,
          size: 18,
          color: amountColor,
        ),
      ),
      title: Row(
        children: [
          Text(
            getBankDisplayName(tx.bankId),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          if (isAutomated) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt,
                size: 10,
                color: Colors.amber,
              ),
            ),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Text(
            timeStr,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
          ),
          const SizedBox(width: 8),
          CategoryBadge(
            category: category,
            onTap: onTapCategory,
            isAiPending: tx.categoryId == 'others',
          ),
        ],
      ),
      trailing: Text(
        '$amountPrefix$formattedAmount',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: amountColor,
        ),
      ),
    );
  }
}

// ─── Category Badge Widget ───────────────────────────────────────────────────

class CategoryBadge extends StatefulWidget {
  final AppCategory category;
  final VoidCallback? onTap;
  final bool isAiPending;

  const CategoryBadge({
    super.key,
    required this.category,
    this.onTap,
    this.isAiPending = false,
  });

  @override
  State<CategoryBadge> createState() => _CategoryBadgeState();
}

class _CategoryBadgeState extends State<CategoryBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAiPending) {
      return InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: widget.category.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.category.color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.category.icon,
                size: 11,
                color: widget.category.color,
              ),
              const SizedBox(width: 4),
              Text(
                widget.category.nameVi,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: widget.category.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF1E3C72).withValues(alpha: 0.2),
              width: 1,
            ),
            gradient: LinearGradient(
              colors: const [
                Color(0xFFF2F2F7),
                Color(0xFFE5E5EA),
                Color(0xFFF2F2F7),
              ],
              stops: [
                (_animation.value - 0.5).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.5).clamp(0.0, 1.0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_rounded,
                size: 11,
                color: Color(0xFF1E3C72),
              ),
              SizedBox(width: 4),
              Text(
                'AI Phân loại...',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3C72),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
