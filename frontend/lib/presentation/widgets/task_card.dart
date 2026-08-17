import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/task_provider.dart';
import '../../data/models/task.dart';
import '../../presentation/screens/create_task_screen.dart';
import '../../presentation/screens/task_details_screen.dart';
import 'app_card.dart';

class TaskCard extends ConsumerWidget {
  final Task task;
  final String? subtitleOverride;

  const TaskCard({
    super.key,
    required this.task,
    this.subtitleOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDone = task.isCompleted;
    final subtitle = subtitleOverride ??
        (task.reminderTime?.format(context));

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _openDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Completion control
              GestureDetector(
                onTap: () => ref
                    .read(taskProvider.notifier)
                    .toggleTaskCompletion(task),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? scheme.primary : Colors.transparent,
                    border: Border.all(
                      color: isDone ? scheme.primary : scheme.onSurface.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: isDone
                      ? Icon(Icons.check, size: 15, color: scheme.onPrimary)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Text(task.icon ?? '📋', style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openDetail(context),
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        task.name,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: scheme.onSurface.withValues(alpha: 0.4),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Text('🔔', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _OverflowMenu(task: task),
            ],
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
    );
  }
}

class _OverflowMenu extends ConsumerWidget {
  final Task task;

  const _OverflowMenu({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateTaskScreen(editTask: task)),
          );
        } else if (value == 'detail') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
          );
        } else if (value == 'delete') {
          _confirmDelete(context, ref);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit Task')),
        PopupMenuItem(value: 'detail', child: Text('View Detail')),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Task?'),
        content: Text('This will remove "${task.name}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(taskProvider.notifier).deleteTask(task.id);
    }
  }
}
