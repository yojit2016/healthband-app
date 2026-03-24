import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';

/// A stat card showing a metric title, large value, unit, trend badge,
/// and a sparkline chart rendered with fl_chart.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
    required this.sparklineData,
    this.status,
    this.statusColor,
    this.minY,
    this.maxY,
  });

  /// Card header label, e.g. "Heart Rate"
  final String title;

  /// Main value displayed large, e.g. "77"
  final String value;

  /// Unit label shown small beneath the value, e.g. "bpm"
  final String unit;

  /// Icon shown in the badge top-right
  final IconData icon;

  /// Accent / neon colour used for icon, sparkline, and border glow
  final Color accentColor;

  /// Y-values for the sparkline (left = oldest, right = latest)
  final List<double> sparklineData;

  /// Optional status badge text, e.g. "Normal", "High"
  final String? status;

  /// Colour for the status badge background
  final Color? statusColor;

  /// Optional chart Y-axis bounds (auto-computed from data if null)
  final double? minY;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1623), Color(0xFF1A2235)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withAlpha(60),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(45),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // ── Glow accent blob (top-right) ──────────────────────────────
            Positioned(
              top: -30,
              right: -30,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withAlpha(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withAlpha(30),
                      blurRadius: 24,
                      spreadRadius: 12,
                    ),
                  ],
                ),
              ),
            ),

            // ── Card content ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: title + icon badge
                  _buildHeader(),
                  const SizedBox(height: 12),

                  // Value + unit
                  _buildValueRow(),
                  const SizedBox(height: 4),

                  // Status chip
                  if (status != null) _buildStatusChip(),

                  const Spacer(),

                  // Sparkline — occupies bottom portion of card
                  SizedBox(
                    height: 54,
                    child: _buildSparkline(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: accentColor.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accentColor, size: 16),
        ),
      ],
    );
  }

  Widget _buildValueRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.4),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
          child: Text(
            value,
            key: ValueKey<String>(value),
            style: TextStyle(
              color: accentColor,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1,
              shadows: [
                Shadow(
                  color: accentColor.withAlpha(80),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            unit,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    final chipColor = statusColor ?? AppColors.success;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withAlpha(80), width: 0.8),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          status!,
          key: ValueKey<String>(status!),
          style: TextStyle(
            color: chipColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildSparkline() {
    if (sparklineData.length < 2) {
      return const SizedBox.shrink();
    }

    final spots = sparklineData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    final dataMin = sparklineData.reduce((a, b) => a < b ? a : b);
    final dataMax = sparklineData.reduce((a, b) => a > b ? a : b);
    final padding  = (dataMax - dataMin) * 0.15;

    return LineChart(
      LineChartData(
        minY: minY ?? (dataMin - padding),
        maxY: maxY ?? (dataMax + padding),
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: accentColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accentColor.withAlpha(60),
                  accentColor.withAlpha(0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}
