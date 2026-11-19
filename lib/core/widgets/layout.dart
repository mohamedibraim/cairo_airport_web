import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';

/// Scrollable page container with consistent padding and max width.
class PageBody extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  const PageBody({
    super.key,
    required this.children,
    this.spacing = AppSpace.lg,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pad = w < 640 ? AppSpace.md : AppSpace.xl;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, AppSpace.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i != 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Page heading with description and actions.
class PageIntro extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? eyebrow;
  final List<Widget> actions;
  const PageIntro({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 720;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eyebrow != null) ...[
              Text(
                eyebrow!.toUpperCase(),
                style: t.labelSmall?.copyWith(
                  color: AppColors.action,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(title, style: t.displaySmall),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: t.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        );
        if (narrow && actions.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: actions,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: heading),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: AppSpace.lg),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                alignment: WrapAlignment.end,
                children: actions,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A soft inline message used for caveats, stale data, conflicts and scope
/// notes. Never used for decoration.
class InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Widget? trailing;
  const InfoBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = AppColors.info,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.nested),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleSmall?.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(message, style: t.bodySmall?.copyWith(height: 1.5)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Responsive card grid. Columns drop automatically for tablet and mobile
/// browser widths instead of relying on horizontal scrolling.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int desktop;
  final int tablet;
  final int mobile;
  final double spacing;
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.desktop = 4,
    this.tablet = 2,
    this.mobile = 1,
    this.spacing = AppSpace.md,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1180
            ? desktop
            : (c.maxWidth >= 680 ? tablet : mobile);
        final width = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// Two-column layout that stacks below [breakpoint].
class SplitPane extends StatelessWidget {
  final Widget main;
  final Widget side;
  final double sideWidth;
  final double breakpoint;
  final double gap;
  const SplitPane({
    super.key,
    required this.main,
    required this.side,
    this.sideWidth = 360,
    this.breakpoint = 980,
    this.gap = AppSpace.lg,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              main,
              SizedBox(height: gap),
              side,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: main),
            SizedBox(width: gap),
            SizedBox(width: sideWidth, child: side),
          ],
        );
      },
    );
  }
}

class ChoiceChips<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String? label;
  final bool scrollable;
  const ChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.label,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final o in options)
        ChoiceChip(
          label: Text(o.$2),
          selected: o.$1 == selected,
          onSelected: (_) => onChanged(o.$1),
          showCheckmark: false,
          selectedColor: AppColors.action,
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: o.$1 == selected ? AppColors.action : AppColors.border,
          ),
          labelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: o.$1 == selected ? Colors.white : AppColors.text,
          ),
          visualDensity: VisualDensity.compact,
        ),
    ];
    final content = Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
        ...chips,
      ],
    );
    if (!scrollable) return content;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: content,
    );
  }
}

class SearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final double width;
  final String initial;
  const SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.width = 260,
    this.initial = '',
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: widget.hint,
          isDense: true,
          prefixIcon: const Icon(
            Icons.search,
            size: 17,
            color: AppColors.muted,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 32,
          ),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 15),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

class MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? color;
  final String? hint;
  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.color,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: t.titleLarge?.copyWith(color: color ?? AppColors.navy),
            ),
            if (unit != null) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit!, style: t.bodySmall),
              ),
            ],
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 1),
          Text(
            hint!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.labelSmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

/// Simple label/value row used inside detail panels.
class DetailRow extends StatelessWidget {
  final String label;
  final Widget value;
  const DetailRow({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 8),
          Expanded(child: value),
        ],
      ),
    );
  }
}

class DetailValue extends StatelessWidget {
  final String text;
  final bool ltr;
  final Color? color;
  const DetailValue(this.text, {super.key, this.ltr = false, this.color});
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: color ?? AppColors.text);
    if (!ltr) return Text(text, style: style);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(text, style: style, textAlign: TextAlign.start),
    );
  }
}

/// Small status note used at the bottom of cards.
class CardNote extends StatelessWidget {
  final String text;
  final IconData icon;
  const CardNote(this.text, {super.key, this.icon = Icons.info_outline});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Keeps IDs, times and codes left-to-right inside Arabic text.
class Mono extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? align;
  const Mono(this.text, {super.key, this.style, this.align});
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        text,
        textAlign: align ?? TextAlign.start,
        style: (style ?? const TextStyle()).copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

String asOfLabel(AppStrings s, DateTime utc) {
  String two(int n) => n.toString().padLeft(2, '0');
  final local = utc.add(const Duration(hours: 2));
  return '${s.tr('as of', 'اعتبارًا من')} ${two(local.hour)}:${two(local.minute)}';
}

String shortClock(DateTime utc) {
  String two(int n) => n.toString().padLeft(2, '0');
  final local = utc.add(const Duration(hours: 2));
  return '${two(local.hour)}:${two(local.minute)}';
}
