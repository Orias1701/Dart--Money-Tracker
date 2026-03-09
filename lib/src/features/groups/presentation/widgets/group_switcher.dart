import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/group.dart';
import '../providers/active_group_provider.dart';

/// Padding và font nhỏ cho dropdown nhóm (thu gọn ~40% chiều cao).
const _kCompactPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
const _kCompactFontSize = 12.0;
const _kCompactBorderRadius = 12.0;

class GroupSwitcher extends ConsumerWidget {
  const GroupSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGroup = ref.watch(activeGroupProvider);
    final groupsAsync = ref.watch(userGroupsListProvider);

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return InputDecorator(
            decoration: const InputDecoration(
              contentPadding: _kCompactPadding,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(_kCompactBorderRadius)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(_kCompactBorderRadius)),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            child: Text(
              activeGroup?.name ?? '—',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: _kCompactFontSize,
              ),
            ),
          );
        }
        AppGroup selected;
        try {
          selected = activeGroup != null &&
                  groups.any((g) => g.id == activeGroup.id)
              ? groups.firstWhere((g) => g.id == activeGroup.id)
              : groups.first;
        } catch (_) {
          selected = groups.first;
        }
        return DropdownButtonFormField<AppGroup>(
          initialValue: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            contentPadding: _kCompactPadding,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(_kCompactBorderRadius)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(_kCompactBorderRadius)),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          dropdownColor: AppColors.surface,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: _kCompactFontSize,
          ),
          items: groups
              .map(
                (g) => DropdownMenuItem<AppGroup>(
                  value: g,
                  child: Text(
                    g.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: _kCompactFontSize),
                  ),
                ),
              )
              .toList(),
          onChanged: (g) {
            if (g != null) {
              ref.read(activeGroupProvider.notifier).setActiveGroup(g);
            }
          },
        );
      },
      loading: () => InputDecorator(
        decoration: const InputDecoration(
          contentPadding: _kCompactPadding,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(_kCompactBorderRadius)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(_kCompactBorderRadius)),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        child: Text(
          activeGroup?.name ?? 'Đang tải...',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: _kCompactFontSize,
          ),
        ),
      ),
      error: (_, _) => InputDecorator(
        decoration: const InputDecoration(
          contentPadding: _kCompactPadding,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(_kCompactBorderRadius)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(_kCompactBorderRadius)),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        child: Text(
          activeGroup?.name ?? 'Lỗi',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: _kCompactFontSize),
        ),
      ),
    );
  }
}
