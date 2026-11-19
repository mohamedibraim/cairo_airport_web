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

/// A compact, theme-consistent data table with an optional minimum width so it
/// scrolls horizontally on mobile browsers instead of clipping values.
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
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
        child: Center(
          child: Text(
            emptyMessage ?? '—',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpace.sm,
                    horizontal: AppSpace.sm,
                  ),
                  child: Row(
                    children: [
                      for (final col in columns)
                        Expanded(
                          flex: col.flex,
                          child: Align(
                            alignment: col.alignment,
                            child: Text(
                              col.label,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                for (var i = 0; i < rows.length; i++) ...[
                  _row(context, rows[i], i),
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

  Widget _row(BuildContext context, AppTableRow row, int index) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpace.md,
        horizontal: AppSpace.sm,
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
    );
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: row.selected
            ? AppColors.tealSoft
            : (row.emphasized ? AppColors.soft : Colors.transparent),
      ),
      child: content,
    );
    if (row.onTap == null) return decorated;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: row.onTap, child: decorated),
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
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.muted,
          height: 1.4,
        ),
      ),
    );
  }
}
