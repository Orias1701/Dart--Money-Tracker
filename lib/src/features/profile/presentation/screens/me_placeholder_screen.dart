import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shell/shell_app_bar_provider.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';

class MePlaceholderScreen extends ConsumerStatefulWidget {
  const MePlaceholderScreen({super.key});

  @override
  ConsumerState<MePlaceholderScreen> createState() => _MePlaceholderScreenState();
}

class _MePlaceholderScreenState extends ConsumerState<MePlaceholderScreen> {
  var _groupsExpanded = false;

  Future<void> _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentFullName,
  ) async {
    final controller = TextEditingController(text: currentFullName ?? '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Chỉnh sửa hồ sơ'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Họ tên',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final result = await ref.read(authRepositoryProvider).updateProfile(
                    fullName: controller.text.trim().isEmpty ? null : controller.text.trim(),
                  );
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (result is AuthSuccess) {
                ref.invalidate(currentUserProvider);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final activeGroup = ref.watch(activeGroupProvider);
    final groupsAsync = ref.watch(userGroupsListProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellAppBarTitleProvider.notifier).setTitle(
            4,
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Me',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
    });
    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
              data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.surface,
                    child: Text(
                      user?.fullName?.isNotEmpty == true
                          ? user!.fullName![0].toUpperCase()
                          : (user?.username?.isNotEmpty == true ? user!.username![0].toUpperCase() : '?'),
                      style: const TextStyle(
                        fontSize: 28,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName?.trim().isNotEmpty == true
                              ? user!.fullName!
                              : (user?.username ?? 'User'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user?.username != null)
                          Text(
                            '@${user!.username}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        Text(
                          'ID: ${user?.id ?? '—'}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.textSecondary),
                title: const Text('Chỉnh sửa hồ sơ'),
                subtitle: const Text('Đổi họ tên hiển thị'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditProfileDialog(context, ref, user?.fullName),
              ),
              ListTile(
                leading: Icon(
                  _groupsExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                ),
                title: const Text('Quản lý nhóm'),
                subtitle: Text(
                  activeGroup?.name ?? 'Chọn nhóm',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() => _groupsExpanded = !_groupsExpanded);
                },
              ),
              if (_groupsExpanded) ...[
                groupsAsync.when(
                  data: (groups) {
                    final indent = MediaQuery.of(context).size.width * 0.1;
                    return Padding(
                      padding: EdgeInsets.only(left: indent),
                      child: Column(
                        children: [
                          ...groups.map((g) {
                          final isActive = activeGroup?.id == g.id;
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              g.isPersonal ? Icons.person : Icons.group,
                              color: isActive ? AppColors.primary : AppColors.textSecondary,
                              size: 22,
                            ),
                            title: Text(
                              g.name,
                              style: TextStyle(
                                color: isActive ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isActive)
                                  const Icon(Icons.check, color: AppColors.primary, size: 20),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (value) async {
                                    if (value == 'members') {
                                      setState(() => _groupsExpanded = false);
                                      context.push('/me/group-members', extra: {
                                        'groupId': g.id,
                                        'groupName': g.name,
                                        'isPersonal': g.isPersonal,
                                      });
                                    } else if (value == 'leave') {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: AppColors.surface,
                                          title: const Text('Rời nhóm'),
                                          content: Text(
                                            'Bạn có chắc muốn rời nhóm "${g.name}"?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(false),
                                              child: const Text('Hủy'),
                                            ),
                                            FilledButton(
                                              onPressed: () => Navigator.of(ctx).pop(true),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                                foregroundColor: Colors.black,
                                              ),
                                              child: const Text('Rời nhóm'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok != true || !mounted) return;
                                      final err = await ref
                                          .read(groupRepositoryProvider)
                                          .leaveGroup(g.id);
                                      if (!mounted) return;
                                      if (err != null) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(err)),
                                          );
                                        }
                                        return;
                                      }
                                      ref.invalidate(userGroupsListProvider);
                                      ref.invalidate(groupMembersProvider(g.id));
                                      if (activeGroup?.id == g.id) {
                                        ref.read(activeGroupProvider.notifier).setActiveGroup(null);
                                        final repo = ref.read(groupRepositoryProvider);
                                        final list = await repo.getUserGroups();
                                        final personal =
                                            list.where((x) => x.isPersonal).firstOrNull;
                                        if (personal != null) {
                                          ref
                                              .read(activeGroupProvider.notifier)
                                              .setActiveGroup(personal);
                                        }
                                      }
                                      setState(() {});
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'members',
                                      child: Text('Xem thành viên'),
                                    ),
                                    if (!g.isPersonal)
                                      const PopupMenuItem(
                                        value: 'leave',
                                        child: Text('Rời nhóm'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              ref.read(activeGroupProvider.notifier).setActiveGroup(g);
                              setState(() {});
                            },
                          );
                        }),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                          title: const Text(
                            'Thêm nhóm',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            setState(() => _groupsExpanded = false);
                            context.push('/me/manage-groups');
                          },
                        ),
                      ],
                    ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
              ListTile(
                leading: const Icon(
                  Icons.workspace_premium,
                  color: AppColors.primary,
                ),
                title: const Text('Mua Premium'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(
                  Icons.settings,
                  color: AppColors.textSecondary,
                ),
                title: const Text('Cài đặt'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: AppColors.textSecondary,
                ),
                title: const Text('Đăng xuất'),
                onTap: () async {
                  ref.invalidate(activeGroupProvider);
                  ref.invalidate(userGroupsListProvider);
                  ref.invalidate(currentUserProvider);
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}
