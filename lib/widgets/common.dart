import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';

// ------------------------------------------------------------------ Buttons

enum AppButtonStyle { primary, outline, orange, danger, whatsapp }

/// Pill button used everywhere ("Login", "Next >", "Post Update").
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.trailingArrow = false,
    this.orangeArrow = false,
    this.icon,
    this.loading = false,
    this.height = 56,
    this.expand = true,
    this.alignStart = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool trailingArrow; // chevron at the end
  final bool orangeArrow; // orange circle with chevron (design accent)
  final IconData? icon;
  final bool loading;
  final double height;
  final bool expand;
  final bool alignStart; // label left-aligned, as in "View all updates   >"

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (style) {
      AppButtonStyle.primary => (AppColors.black, AppColors.white, AppColors.black),
      AppButtonStyle.outline => (AppColors.white, AppColors.text, AppColors.border),
      AppButtonStyle.orange => (AppColors.orange, AppColors.white, AppColors.orange),
      AppButtonStyle.danger => (AppColors.white, AppColors.red, AppColors.red.withValues(alpha: 0.4)),
      AppButtonStyle.whatsapp => (AppColors.white, AppColors.green, AppColors.green),
    };
    final disabled = onPressed == null || loading;
    final content = loading
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: (trailingArrow || orangeArrow || alignStart) ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 8)],
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg)),
              ),
              if (orangeArrow || trailingArrow) const SizedBox(width: 12),
              if (orangeArrow)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                  child: const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                )
              else if (trailingArrow)
                Icon(Icons.chevron_right, color: fg),
            ],
          );
    return Opacity(
      opacity: disabled && !loading ? 0.45 : 1,
      child: SizedBox(
        height: height,
        width: expand ? double.infinity : null,
        child: Material(
          color: bg,
          shape: StadiumBorder(side: BorderSide(color: border, width: style == AppButtonStyle.outline ? 1.2 : 1.4)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: disabled ? null : onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: (trailingArrow || orangeArrow || alignStart) ? 22 : 20),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round grey icon button (back arrows, close, more).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, this.onTap, this.size = 40, this.dark = false, this.tooltip});
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool dark;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: dark ? AppColors.black : AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.5, color: onTap == null ? AppColors.textFaint : (dark ? Colors.white : AppColors.text)),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

class BackCircle extends StatelessWidget {
  const BackCircle({super.key, this.onTap, this.arrow = false});
  final VoidCallback? onTap;
  final bool arrow;
  @override
  Widget build(BuildContext context) => CircleIconButton(
        icon: arrow ? Icons.arrow_back : Icons.chevron_left,
        tooltip: 'Back',
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
      );
}

/// Centered title header with back button: "<   Project   ...".
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.trailing, this.onBack, this.showBack = true});
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showBack) Align(alignment: Alignment.centerLeft, child: BackCircle(onTap: onBack)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            ),
            if (trailing != null) Align(alignment: Alignment.centerRight, child: trailing),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ Inputs

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.validator,
    this.textInputAction,
    this.onChanged,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.showCounter = false,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final bool showCounter;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppText.label),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          autofocus: widget.autofocus,
          textCapitalization: widget.textCapitalization,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppColors.textFaint),
            filled: true,
            fillColor: AppColors.surface,
            counterText: widget.showCounter ? null : '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            border: border,
            enabledBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.black, width: 1.2)),
            errorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.red)),
            focusedErrorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.red, width: 1.2)),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Show' : 'Hide',
                    icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.text),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : widget.suffix,
          ),
        ),
      ],
    );
  }
}

class Validators {
  static String? required(String? v, [String field = 'This field']) => (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? null : 'Enter a valid email';
  }

  static String? password(String? v) => (v == null || v.length < 6) ? 'At least 6 characters' : null;

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone is required';
    return RegExp(r'^[+\d][\d\s-]{6,}$').hasMatch(v.trim()) ? null : 'Enter a valid phone number';
  }

  static String? pin(String? v) => RegExp(r'^\d{4}$').hasMatch(v ?? '') ? null : 'PIN must be 4 digits';
}

// ------------------------------------------------------------------ Tabs & chips

/// Segmented control: [Log in | Sign up], [Updates | Requests | Info].
class PillTabs extends StatelessWidget {
  const PillTabs({super.key, required this.tabs, required this.index, required this.onChanged, this.height = 52});
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(height)),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(height),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                      color: i == index ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small selectable pill chip ("All", "In progress", work types...).
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, this.selected = false, this.onTap, this.trailing, this.dense = false});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.black : AppColors.surface,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dense ? 14 : 18, vertical: dense ? 8 : 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: dense ? 13 : 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.text.withValues(alpha: 0.75),
                  )),
              if (trailing != null) ...[const SizedBox(width: 4), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrolling row of single-select chips.
class ChipFilterBar extends StatelessWidget {
  const ChipFilterBar({super.key, required this.options, required this.selected, required this.onSelected, this.padding = const EdgeInsets.symmetric(horizontal: 20)});
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelected;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => AppChip(label: options[i], selected: i == selected, onTap: () => onSelected(i)),
      ),
    );
  }
}

// ------------------------------------------------------------------ Status & progress

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.small = false});
  final String status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'completed' || 'done' => (AppColors.greenSoft, AppColors.green),
      'on_hold' => (AppColors.surfaceDark, AppColors.textMuted),
      'urgent' => (AppColors.redSoft, AppColors.red),
      _ => (AppColors.orangeSoft, AppColors.orange),
    };
    final label = status == 'urgent' ? 'Urgent' : Fmt.statusLabel(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 10 : 14, vertical: small ? 4 : 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: small ? 11 : 13, fontWeight: FontWeight.w600)),
    );
  }
}

class ProgressRow extends StatelessWidget {
  const ProgressRow({super.key, required this.progress, this.label = 'Progress'});
  final int progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label, style: AppText.muted), Text('$progress%', style: AppText.muted)],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 100) / 100,
            minHeight: 6,
            backgroundColor: AppColors.surfaceDark,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Containers & rows

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color = AppColors.surface, this.radius = 20});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Label / value row used in project info lists.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.divider = true});
  final String label;
  final String value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(border: divider ? const Border(bottom: BorderSide(color: AppColors.border)) : null),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.text))),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: AppColors.text))),
        ],
      ),
    );
  }
}

/// Settings-like tile: icon, label, chevron (Edit name, Change password, Logout...).
class ActionTile extends StatelessWidget {
  const ActionTile({super.key, required this.icon, required this.label, this.onTap, this.trailing, this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.red : AppColors.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        color: danger ? AppColors.redSoft : AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 16, color: color))),
            trailing ?? (danger ? const SizedBox.shrink() : const Icon(Icons.chevron_right, color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.boxed = false});
  final String value;
  final String label;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(label, style: AppText.muted, maxLines: 2),
      ],
    );
    if (!boxed) return content;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: content,
    );
  }
}

/// Row of stats separated by vertical dividers: "01 Active projects | 13 Total updates".
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.items});
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: AppColors.border))),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const VerticalDivider(color: AppColors.border, width: 24),
              Expanded(child: StatTile(value: items[i].$1, label: items[i].$2)),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(0, 24, 0, 12)});
  final String text;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2))),
          ?trailing,
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.size = 40, this.square = false});
  final String name;
  final double size;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(size * 0.25) : null,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        Fmt.initials(name),
        style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w600, color: size > 60 ? AppColors.textFaint : AppColors.text.withValues(alpha: 0.7)),
      ),
    );
  }
}

/// Brand mark from the design (three stacked bars, top one orange).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, Color c) => Container(
          width: w,
          height: size * 0.16,
          margin: EdgeInsets.only(bottom: size * 0.08),
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [bar(size * 0.45, AppColors.orange), bar(size * 0.75, AppColors.black), bar(size, AppColors.black)],
    );
  }
}

// ------------------------------------------------------------------ Bottom nav

class NavItem {
  const NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating black pill navigation from the design.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.items, required this.index, required this.onTap, this.badges = const {}});
  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Badge(
                        isLabelVisible: (badges[i] ?? 0) > 0,
                        label: Text('${badges[i]}'),
                        backgroundColor: AppColors.orange,
                        child: Icon(i == index ? items[i].activeIcon : items[i].icon, color: i == index ? AppColors.orange : Colors.white, size: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(items[i].label, style: TextStyle(fontSize: 12, color: i == index ? AppColors.orange : Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ States

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2.5)));
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: AppText.h3),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!, textAlign: TextAlign.center, style: AppText.muted),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'Could not load',
      message: error is ApiException ? (error as ApiException).message : error.toString(),
      action: onRetry == null ? null : AppButton(label: 'Try again', expand: false, style: AppButtonStyle.outline, height: 46, onPressed: onRetry),
    );
  }
}

/// Renders an [AsyncValue] with consistent loading / error states.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.data, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: data,
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: onRetry),
    );
  }
}

// ------------------------------------------------------------------ Feedback helpers

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.red : AppColors.black,
    ));
}

String errorText(Object e) => e is ApiException ? e.message : e.toString();

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title, style: AppText.h3),
      content: Text(message, style: AppText.body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.text))),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel, style: TextStyle(color: destructive ? AppColors.red : AppColors.black, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Standard rounded bottom sheet with title and close button.
Future<T?> showAppSheet<T>(BuildContext context, {required String title, required Widget Function(BuildContext) builder, bool scrollable = true}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
                  CircleIconButton(icon: Icons.close, tooltip: 'Close', onTap: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Flexible(
              child: scrollable
                  ? SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), child: builder(ctx))
                  : Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), child: builder(ctx)),
            ),
          ],
        ),
      ),
    ),
  );
}
