import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../core/l10n/context_i18n.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/sales/presentation/sales_list_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

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
        appBar: _buildAppBar(context, l10n, storeName, syncStatus),
        body: _pages[_index],
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
              'SME Digital',
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
    final hasIssue =
        !syncStatus.online ||
        syncStatus.syncing ||
        syncStatus.pendingCount > 0 ||
        (syncStatus.lastError?.isNotEmpty ?? false);
    if (!hasIssue) return null;

    final (Color bg, Color fg, IconData icon, String text) = switch (true) {
      _ when !syncStatus.online => (
          AppColors.warningBg,
          AppColors.warning,
          Icons.wifi_off_rounded,
          context.tr('Offline mode', 'अफलाइन मोड'),
        ),
      _ when syncStatus.syncing => (
          AppColors.surfaceAlt,
          AppColors.primary,
          Icons.sync_rounded,
          syncStatus.pendingCount > 0
              ? context.tr(
                'Syncing ${syncStatus.pendingCount} changes…',
                '${syncStatus.pendingCount} परिवर्तन सिंक हुँदै…',
              )
              : context.tr('Syncing…', 'सिंक हुँदै…'),
        ),
      _ when (syncStatus.lastError?.isNotEmpty ?? false) => (
          AppColors.errorBg,
          AppColors.error,
          Icons.sync_problem_rounded,
          context.tr('Sync failed. Will retry.', 'सिंक असफल भयो। फेरि प्रयास हुनेछ।'),
        ),
      _ => (
          AppColors.warningBg,
          AppColors.warning,
          Icons.cloud_upload_outlined,
          context.tr(
            '${syncStatus.pendingCount} pending changes',
            '${syncStatus.pendingCount} परिवर्तन बाँकी',
          ),
        ),
    };

    return PreferredSize(
      preferredSize: const Size.fromHeight(34),
      child: Container(
        width: double.infinity,
        color: bg,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  child: Text(
                    context.tr('Sync now', 'अहिले सिंक'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
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
          label: 'Reports',
        ),
      ],
    );
  }

  String _title(AppLocalizations l10n) => switch (_index) {
        0 => l10n.dashboard,
        1 => l10n.sales,
        2 => l10n.products,
        3 => l10n.customers,
        4 => 'Reports',
        _ => 'SME Digital',
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
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
      ),
      body: const SettingsScreen(),
    );
  }
}
