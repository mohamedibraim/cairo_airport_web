import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import 'badges.dart';

/// Scrollable page container with breakpoint-aware padding and a 1560px cap.
class PageBody extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  const PageBody({
    super.key,
    required this.children,
    this.spacing = AppSpace.sectionGap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pad = AppSpace.pagePadding(w);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, AppSpace.space10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpace.maxPageWidth),
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

/// Page heading with description and actions. The page title lives here only;
/// the shell deliberately shows a quiet breadcrumb instead of repeating it.
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
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < AppBreakpoints.smallDesktop;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eyebrow != null) ...[
              Text(
                eyebrow!,
                style: AppTypography.label.copyWith(
                  color: AppColors.primaryStrong,
                ),
              ),
              const SizedBox(height: AppSpace.space2),
            ],
            Text(
              title,
              style: AppTypography.pageTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.space2),
            Text(
              subtitle,
              style: AppTypography.bodyPrimary.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
        if (narrow && actions.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              const SizedBox(height: AppSpace.space4),
              Wrap(
                spacing: AppSpace.space2,
                runSpacing: AppSpace.space2,
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
              const SizedBox(width: AppSpace.space6),
              Wrap(
                spacing: AppSpace.space2,
                runSpacing: AppSpace.space2,
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

/// A functional inline message for caveats, stale data and scope notes.
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
    final tone = AppTones.from(color);
    return Container(
      padding: const EdgeInsets.all(AppSpace.space4),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone.text),
          const SizedBox(width: AppSpace.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyEmphasis.copyWith(color: tone.text),
                ),
                const SizedBox(height: AppSpace.space1),
                Text(
                  message,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.space3),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Responsive card grid. Columns drop at the approved breakpoints instead of
/// relying on horizontal page scrolling.
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
    this.spacing = AppSpace.cardGap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= AppBreakpoints.smallDesktop
            ? desktop
            : (c.maxWidth >= AppBreakpoints.mobile ? tablet : mobile);
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
    this.sideWidth = 380,
    this.breakpoint = AppBreakpoints.tablet,
    this.gap = AppSpace.cardGap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [main, SizedBox(height: gap), side],
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
          selectedColor: AppColors.surfaceSelected,
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: o.$1 == selected ? AppColors.primaryBorder : AppColors.border,
          ),
          labelStyle: AppTypography.label.copyWith(
            color: o.$1 == selected
                ? AppColors.primaryStrong
                : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
    ];
    final content = Wrap(
      spacing: AppSpace.space2,
      runSpacing: AppSpace.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              end: AppSpace.metadataGap,
            ),
            child: Text(
              label!,
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ...chips,
      ],
    );
    if (!scrollable) return content;
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: content);
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
    this.width = 320,
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
    final mediaWidth = MediaQuery.sizeOf(context).width;
    return LayoutBuilder(
      builder: (context, c) {
        final available = c.maxWidth.isFinite ? c.maxWidth : widget.width;
        final width = mediaWidth < AppBreakpoints.mobile
            ? available
            : (widget.width > available ? available : widget.width);
        return SizedBox(
          width: width,
          child: TextField(
            controller: _controller,
            onChanged: (value) {
              setState(() {});
              widget.onChanged(value);
            },
            style: AppTypography.tableText,
            decoration: InputDecoration(
              hintText: widget.hint,
              isDense: false,
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: AppColors.textTertiary,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 44,
              ),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                        widget.onChanged('');
                      },
                    ),
            ),
          ),
        );
      },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.metadata.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpace.space1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LtrText(
              value,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.cardTitle.copyWith(
                color: color ?? AppColors.textPrimary,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: AppSpace.metadataGap),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  unit!,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: AppSpace.space1),
          Text(
            hint!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textTertiary,
            ),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpace.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: AppTypography.metadata.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.space3),
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
    final style = AppTypography.tableText.copyWith(
      color: color ?? AppColors.textPrimary,
    );
    if (!ltr) return Text(text, style: style);
    return LtrText(text, style: style);
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
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: AppSpace.space2),
        Expanded(
          child: Text(
            text,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textTertiary,
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
    return LtrText(
      text,
      textAlign: align,
      style: (style ?? AppTypography.metadata).merge(AppTypography.numeric),
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
