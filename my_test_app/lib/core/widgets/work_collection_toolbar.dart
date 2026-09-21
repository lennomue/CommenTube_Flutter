import 'package:flutter/material.dart';

import '../models/quiz_filter.dart';
import '../../features/home/presentation/home_filter_bar.dart';

enum WorkOrder { views, newest, oldest }

class WorkCollectionToolbar extends StatelessWidget {
  const WorkCollectionToolbar({
    super.key,
    required this.filter,
    required this.order,
    required this.onFilterChanged,
    required this.onOrderChanged,
    required this.onBulkAdd,
  });

  final QuizFilter filter;
  final WorkOrder order;
  final ValueChanged<QuizFilter> onFilterChanged;
  final ValueChanged<WorkOrder> onOrderChanged;
  final VoidCallback? onBulkAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 6),
      child: Row(
        children: [
          OutlinedButton.icon(
            key: const ValueKey('work-collection-filter'),
            onPressed: () => showDetailedQuizFilters(
              context,
              filter,
              onChanged: onFilterChanged,
            ),
            icon: const Icon(Icons.manage_search_rounded),
            label: Text(
              filter.isEmpty ? '絞り込み' : '絞り込み ${filter.activeConditionCount}',
            ),
          ),
          const Spacer(),
          DropdownButton<WorkOrder>(
            key: const ValueKey('work-collection-order'),
            value: order,
            underline: const SizedBox.shrink(),
            onChanged: (value) {
              if (value != null) {
                onOrderChanged(value);
              }
            },
            items: const [
              DropdownMenuItem(value: WorkOrder.views, child: Text('再生順')),
              DropdownMenuItem(value: WorkOrder.newest, child: Text('新しい順')),
              DropdownMenuItem(value: WorkOrder.oldest, child: Text('古い順')),
            ],
          ),
          PopupMenuButton<String>(
            key: const ValueKey('work-collection-menu'),
            tooltip: '作品の操作',
            icon: const Icon(Icons.more_horiz_rounded),
            enabled: onBulkAdd != null,
            onSelected: (_) => onBulkAdd?.call(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'bulk-add', child: Text('まとめて再生リストに追加する')),
            ],
          ),
        ],
      ),
    );
  }
}
