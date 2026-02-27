import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/sales/presentation/sales_list_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/sync/presentation/sync_queue_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _pages = [
    DashboardScreen(),
    SalesListScreen(),
    ProductsScreen(),
    CustomersScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(profileProvider);
    final syncStatus = ref.watch(syncCoordinatorProvider);

    final storeName = profile.whenOrNull(data: (p) => p.storeName);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        resizeToAvoidBottomInset: true,
        extendBody: false,
        appBar: _buildAppBar(context, l10n, storeName, syncStatus),
        body: SafeArea(
          top: false,
          bottom: false,
          child: _pages[_index],
        ),
        bottomNavigationBar: _buildNavBar(l10n),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    String? storeName,
    SyncStatusState syncStatus,
  ) {
    // Dashboard gets a special greeting header
    if (_index == 0) {
      return AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        bottom: _syncStatusBar(context, syncStatus),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (storeName != null && storeName.isNotEmpty)
              Text(
                storeName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const _SettingsPage(),
                ),
              ),
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  size: 18,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Other tabs — simple titled app bar
    return AppBar(
      title: Text(_title(l10n)),
      backgroundColor: AppColors.surface,
      bottom: _syncStatusBar(context, syncStatus),
    );
  }

  PreferredSizeWidget? _syncStatusBar(
    BuildContext context,
    SyncStatusState syncStatus,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final hasIssue =
        !syncStatus.online ||
        syncStatus.syncing ||
        syncStatus.pendingCount > 0 ||
        (syncStatus.lastError?.isNotEmpty ?? false);
    if (!hasIssue) return null;

    final isConflict = (syncStatus.lastError?.contains('Server has newer data') ?? false);
    final (Color bg, Color fg, IconData icon, String text) = switch (true) {
      _ when !syncStatus.online => (
          AppColors.warningBg,
          AppColors.warning,
          Icons.wifi_off_rounded,
          l10n.offlineMode,
        ),
      _ when syncStatus.syncing => (
          AppColors.surfaceAlt,
          AppColors.primary,
          Icons.sync_rounded,
          syncStatus.pendingCount > 0
              ? l10n.syncingChanges(syncStatus.pendingCount)
              : l10n.syncingShort,
        ),
      _ when (syncStatus.lastError?.isNotEmpty ?? false) => (
          isConflict ? AppColors.warningBg : AppColors.errorBg,
          isConflict ? AppColors.warning : AppColors.error,
          isConflict ? Icons.warning_amber_rounded : Icons.sync_problem_rounded,
          isConflict
              ? l10n.serverHasNewerDataPullRetry
              : l10n.syncFailedWillRetry,
        ),
      _ => (
          AppColors.warningBg,
          AppColors.warning,
          Icons.cloud_upload_outlined,
          l10n.pendingChangesCount(syncStatus.pendingCount),
        ),
    };

    return PreferredSize(
      preferredSize: Size.fromHeight(syncStatus.lastDurationMs != null ? 48 : 34),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
            bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                if (syncStatus.online &&
                    !syncStatus.syncing &&
                    (syncStatus.pendingCount > 0 ||
                        (syncStatus.lastError?.isNotEmpty ?? false)))
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: () => ref.read(syncCoordinatorProvider.notifier).triggerNow(),
                    onLongPress: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SyncQueueScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      child: Text(
                        isConflict
                            ? l10n.pullRetryShort
                            : l10n.syncNowLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (syncStatus.lastDurationMs != null &&
                (syncStatus.lastPushed > 0 ||
                    syncStatus.lastPulled > 0 ||
                    syncStatus.lastFailed > 0))
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 2),
                child: Text(
                  l10n.syncTelemetrySummary(
                    syncStatus.lastAcked,
                    syncStatus.lastFailed,
                    syncStatus.lastPulled,
                    syncStatus.lastDurationMs ?? 0,
                  ),
                  style: TextStyle(
                    fontSize: 10,
                    color: fg.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  NavigationBar _buildNavBar(AppLocalizations l10n) {
    return NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: l10n.dashboard,
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long_rounded),
          label: l10n.sales,
        ),
        NavigationDestination(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2_rounded),
          label: l10n.products,
        ),
        NavigationDestination(
          icon: const Icon(Icons.people_outline_rounded),
          selectedIcon: const Icon(Icons.people_rounded),
          label: l10n.customers,
        ),
        NavigationDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart_rounded),
          label: l10n.reports,
        ),
      ],
    );
  }

  String _title(AppLocalizations l10n) => switch (_index) {
        0 => l10n.dashboard,
        1 => l10n.sales,
        2 => l10n.products,
        3 => l10n.customers,
        4 => l10n.reports,
        _ => l10n.appName,
      };
}

// Wrapper scaffold for settings pushed from AppBar
class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        backgroundColor: AppColors.surface,
      ),
      body: const SettingsScreen(),
    );
  }
}
