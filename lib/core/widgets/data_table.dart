import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class AppTableColumn {
  final String label;
  final int flex;
  final bool numeric;
  final AlignmentGeometry alignment;
  const AppTableColumn(
    this.label, {
    this.flex = 1,
    this.numeric = false,
    this.alignment = AlignmentDirectional.centerStart,
  });
}

class AppTableRow {
  final List<Widget> cells;
  final VoidCallback? onTap;
  final bool selected;
  final bool emphasized;
  const AppTableRow({
    required this.cells,
    this.onTap,
    this.selected = false,
    this.emphasized = false,
  });
}

/// Operational data table: 44px header, 52px+ rows, dividers only, horizontal
/// scrolling on narrow screens and no vertical gridlines.
class AppTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final double minWidth;
  final String? emptyMessage;
  final EdgeInsetsGeometry padding;
  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 720,
    this.emptyMessage,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpace.space1),
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.space6),
        child: Center(
          child: Text(
            emptyMessage ?? '—',
            style: AppTypography.metadata.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth < minWidth ? minWidth : c.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const Divider(height: 1, color: AppColors.divider),
                for (var i = 0; i < rows.length; i++) ...[
                  _row(context, rows[i]),
                  if (i != rows.length - 1)
                    const Divider(height: 1, color: AppColors.divider),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    return Container(
      height: 44,
      color: AppColors.surfaceSoft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.space4),
      child: Row(
        children: [
          for (final col in columns)
            Expanded(
              flex: col.flex,
              child: Align(
                alignment: col.alignment,
                child: Text(
                  col.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AppTableRow row) {
    final background = row.selected
        ? AppColors.surfaceSelected
        : (row.emphasized ? AppColors.surfaceSoft : AppColors.surface);
    final resolvedPadding = padding.resolve(Directionality.of(context));
    final decorated = Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(color: background)),
        ),
        if (row.selected)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(width: 3, color: AppColors.primaryStrong),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpace.space4,
              right: AppSpace.space4,
              top: resolvedPadding.top,
              bottom: resolvedPadding.bottom,
            ),
            child: Row(
              children: [
                for (var i = 0; i < columns.length; i++)
                  Expanded(
                    flex: columns[i].flex,
                    child: Align(
                      alignment: columns[i].alignment,
                      child: i < row.cells.length
                          ? row.cells[i]
                          : const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
    if (row.onTap == null) return decorated;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: row.onTap,
        hoverColor: AppColors.surfaceHover,
        focusColor: AppColors.primarySoft,
        child: decorated,
      ),
    );
  }
}

/// Small caption strip used above tables to explain provenance and scope.
class TableCaption extends StatelessWidget {
  final String text;
  const TableCaption(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.space2),
      child: Text(
        text,
        style: AppTypography.metadata.copyWith(color: AppColors.textTertiary),
      ),
    );
  }
}
