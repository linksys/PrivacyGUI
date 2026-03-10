import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shimmer/skeleton placeholder for the USP Dashboard while data is loading.
///
/// Mirrors the actual dashboard card layout so users see the page structure
/// immediately, with animated skeleton placeholders instead of real content.
class UspDashboardSkeleton extends StatelessWidget {
  const UspDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppResponsiveLayout(
      mobile: (_) => _buildMobileLayout(),
      desktop: (_) => _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SkeletonStatsPanel(),
        AppGap.xl(),
        const _SkeletonInfoCard(rows: 5), // Device Info
        AppGap.xl(),
        const _SkeletonInfoCard(rows: 4), // Network Status
        AppGap.xl(),
        const _SkeletonInfoCard(rows: 3), // System Status
        AppGap.xl(),
        const _SkeletonInfoCard(rows: 4), // LAN Info
        AppGap.xl(),
        const _SkeletonInfoCard(rows: 4), // Ethernet Ports
        AppGap.xl(),
        const _SkeletonListCard(rows: 3), // Connected Devices
        AppGap.xl(),
        const _SkeletonListCard(rows: 2), // WiFi Status
        AppGap.xl(),
        const _SkeletonTopologyCard(),
        AppGap.xl(),
        const _SkeletonInfoCard(rows: 3), // Time Settings
        AppGap.xl(),
        const _SkeletonConnectionStatus(),
        AppGap.xl(),
        const _SkeletonListCard(rows: 2), // DHCP Reservations
        AppGap.xl(),
        const _SkeletonListCard(rows: 2), // Port Forwarding
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Panel (full width)
        const _SkeletonStatsPanel(),

        // Device Info | Network Status
        _skeletonRow(
          const _SkeletonInfoCard(rows: 5),
          const _SkeletonInfoCard(rows: 4),
        ),

        // System Status | LAN Info
        _skeletonRow(
          const _SkeletonInfoCard(rows: 3),
          const _SkeletonInfoCard(rows: 4),
        ),

        // Ethernet Ports | Connected Devices
        _skeletonRow(
          const _SkeletonInfoCard(rows: 4),
          const _SkeletonListCard(rows: 3),
        ),

        // WiFi Status | Topology
        _skeletonRow(
          const _SkeletonListCard(rows: 2),
          const _SkeletonTopologyCard(),
        ),

        // Time Settings | Connection Status
        _skeletonRow(
          const _SkeletonInfoCard(rows: 3),
          const _SkeletonConnectionStatus(),
        ),

        // DHCP Reservations | Port Forwarding
        _skeletonRow(
          const _SkeletonListCard(rows: 2),
          const _SkeletonListCard(rows: 2),
        ),
        AppGap.xl(),
      ],
    );
  }

  static Widget _skeletonRow(Widget left, Widget right) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          AppGap.gutter(),
          Expanded(child: right),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats panel — 4 tiles in a row
// ---------------------------------------------------------------------------

class _SkeletonStatsPanel extends StatelessWidget {
  const _SkeletonStatsPanel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : AppSpacing.md),
            child: AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(
                        width: 24,
                        height: 24,
                        borderRadius: BorderRadius.circular(4)),
                    AppGap.sm(),
                    AppSkeleton.text(width: 48, height: 24),
                    AppGap.xs(),
                    AppSkeleton.text(width: 56),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Connection status — single-row card
// ---------------------------------------------------------------------------

class _SkeletonConnectionStatus extends StatelessWidget {
  const _SkeletonConnectionStatus();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            AppSkeleton.circular(size: 12),
            AppGap.md(),
            AppSkeleton.text(width: 160),
            const Spacer(),
            AppSkeleton.text(width: 60),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Topology card — title + large placeholder
// ---------------------------------------------------------------------------

class _SkeletonTopologyCard extends StatelessWidget {
  const _SkeletonTopologyCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppSkeleton.text(width: 140, height: 20),
                AppGap.md(),
                AppSkeleton.capsule(width: 32, height: 20),
              ],
            ),
            AppGap.xl(),
            AppSkeleton(
              width: double.infinity,
              height: 320,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info card — title + configurable number of label-value rows
// ---------------------------------------------------------------------------

class _SkeletonInfoCard extends StatelessWidget {
  final int rows;

  const _SkeletonInfoCard({required this.rows});

  // Vary value widths so it looks natural
  static const _valueWidths = [180.0, 140.0, 200.0, 120.0, 160.0];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeleton.text(width: 120, height: 20),
            AppGap.xl(),
            for (int i = 0; i < rows; i++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    AppSkeleton.text(width: 100),
                    AppGap.xl(),
                    AppSkeleton.text(
                      width: _valueWidths[i % _valueWidths.length],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List card — title + action buttons + configurable item rows
// ---------------------------------------------------------------------------

class _SkeletonListCard extends StatelessWidget {
  final int rows;

  const _SkeletonListCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title + action button placeholders
            Row(
              children: [
                AppSkeleton.text(width: 140, height: 20),
                AppGap.md(),
                AppSkeleton.capsule(width: 28, height: 20),
                const Spacer(),
                AppSkeleton(
                    width: 28,
                    height: 28,
                    borderRadius: BorderRadius.circular(6)),
              ],
            ),
            AppGap.xl(),
            for (int i = 0; i < rows; i++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    AppSkeleton.capsule(width: 36, height: 20),
                    AppGap.md(),
                    Expanded(child: AppSkeleton.text(width: double.infinity)),
                    AppGap.md(),
                    AppSkeleton.text(width: 80),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
