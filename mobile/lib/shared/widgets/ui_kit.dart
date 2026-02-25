import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sme_digital/l10n/app_localizations.dart';

import '../../core/theme/app_theme.dart';

export '../../core/theme/app_theme.dart' show AppColors, AppSpacing, AppRadius;

// ─── AppCard ──────────────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color = AppColors.surface,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: padding,
      child: child,
    );

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

// ─── SectionHeader ────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.muted,
                      letterSpacing: 0.4,
                    )),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(action!,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}

// ─── EmptyState ───────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.label),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 180,
                child: FilledButton(
                  onPressed: onAction,
                  child: Text(action!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── ErrorRetry ───────────────────────────────────────────────────────────────

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.onRetry, this.message});
  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 40, color: AppColors.muted),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ?? l10n.somethingWentWrong,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 140,
              child: OutlinedButton(
                onPressed: onRetry,
                child: Text(l10n.retry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── InlineBanner (success / error / info) ────────────────────────────────────

enum BannerType { success, error, warning, info }

class InlineBanner extends StatelessWidget {
  const InlineBanner({
    super.key,
    required this.message,
    this.type = BannerType.error,
  });

  final String message;
  final BannerType type;

  @override
  Widget build(BuildContext context) {
    final (bg, bd, fg, ic) = switch (type) {
      BannerType.success => (
          AppColors.successBg,
          AppColors.success.withAlpha(80),
          AppColors.success,
          Icons.check_circle_outline_rounded,
        ),
      BannerType.warning => (
          AppColors.warningBg,
          AppColors.warning.withAlpha(80),
          AppColors.warning,
          Icons.warning_amber_rounded,
        ),
      BannerType.info => (
          AppColors.surfaceAlt,
          AppColors.border,
          AppColors.muted,
          Icons.info_outline_rounded,
        ),
      BannerType.error => (
          AppColors.errorBg,
          AppColors.errorBorder,
          AppColors.error,
          Icons.error_outline_rounded,
        ),
    };

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: bd),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(ic, size: 16, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 13, color: fg)),
          ),
        ],
      ),
    );
  }
}

// ─── ConfirmDialog ────────────────────────────────────────────────────────────

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String? confirmLabel,
  bool destructive = true,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(title),
      content: Text(body,
          style: const TextStyle(color: AppColors.muted, fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? AppColors.error : AppColors.primary,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          ),
          child: Text(confirmLabel ?? l10n.deleteLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ─── AppListTile ─────────────────────────────────────────────────────────────

class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: leading,
          title: Text(title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.label,
                  )),
          subtitle: subtitle != null
              ? Text(subtitle!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.muted))
              : null,
          trailing: trailing ??
              (onTap != null
                  ? const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.muted)
                  : null),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
      ],
    );
  }
}

// ─── InitialsAvatar ───────────────────────────────────────────────────────────

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.color,
  });

  final String name;
  final double size;
  final Color? color;

  static const _palette = [
    Color(0xFF1565C0),
    Color(0xFF00695C),
    Color(0xFF6A1B9A),
    Color(0xFFAD1457),
    Color(0xFF00838F),
    Color(0xFFE65100),
    Color(0xFF558B2F),
    Color(0xFF4527A0),
  ];

  Color _colorFor(String name) {
    final index = name.isEmpty ? 0 : name.codeUnitAt(0) % _palette.length;
    return _palette[index];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = color ?? _colorFor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: bg,
          ),
        ),
      ),
    );
  }
}

// ─── CategoryBadge ────────────────────────────────────────────────────────────

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

// ─── SkeletonBox ──────────────────────────────────────────────────────────────

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E5E4),
      highlightColor: const Color(0xFFF5F7F6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          SkeletonBox(width: 40, height: 40, radius: AppRadius.pill),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, width: 140),
                const SizedBox(height: AppSpacing.xs),
                SkeletonBox(height: 11, width: 90),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SkeletonBox(width: 60, height: 14),
        ],
      ),
    );
  }
}

// ─── StatusChip ───────────────────────────────────────────────────────────────

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── AddBottomSheet helper ────────────────────────────────────────────────────

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: child,
    ),
  );
}

// ─── BottomSheetHeader ────────────────────────────────────────────────────────

class BottomSheetHeader extends StatelessWidget {
  const BottomSheetHeader(this.title, {super.key, this.onClose});
  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl, 0, AppSpacing.md, AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                onPressed: onClose ?? () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded,
                    size: 20, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}
