import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/app_user.dart';
import '../../../groups/domain/group.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';

class MeFriendTab extends ConsumerStatefulWidget {
  const MeFriendTab({super.key});

  @override
  ConsumerState<MeFriendTab> createState() => _MeFriendTabState();
}

class _MeFriendTabState extends ConsumerState<MeFriendTab> {
  final _searchController = TextEditingController();
  String _query = '';
  List<AppUser> _results = [];
  bool _loading = false;
  String? _invitingUserId;
  AppGroup? _inviteTargetGroup;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.length < 2) {
      setState(() {
        _query = q;
        _results = [];
      });
      return;
    }
    setState(() {
      _query = q;
      _loading = true;
      _results = [];
    });
    try {
      final repo = ref.read(groupRepositoryProvider);
      final list = await repo.searchUsers(q);
      if (mounted) {
        setState(() {
          _results = list;
          _loading = false;
        });
      }
    } catch (e, st) {
      if (mounted) {
        setState(() => _loading = false);
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tìm kiếm lỗi: $msg'),
            backgroundColor: AppColors.expense,
            duration: const Duration(seconds: 5),
          ),
        );
        debugPrint('searchUsers error: $e\n$st');
      }
    }
  }

  Future<void> _inviteToGroup(AppUser user, AppGroup group) async {
    setState(() => _invitingUserId = user.id);
    final repo = ref.read(groupRepositoryProvider);
    final err = await repo.inviteUserToGroup(group.id, user.id);
    if (mounted) {
      setState(() => _invitingUserId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Đã mời ${user.fullName ?? user.username ?? 'thành viên'} vào nhóm.'),
          backgroundColor: err == null ? AppColors.income : AppColors.expense,
        ),
      );
      if (err == null) ref.invalidate(groupMembersProvider(group.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(userGroupsListProvider);
    final sharedGroups = groupsAsync.valueOrNull?.where((g) => !g.isPersonal).toList() ?? [];
    final canInvite = _inviteTargetGroup != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tìm bạn',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Username hoặc họ tên (tối thiểu 2 ký tự)',
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _loading ? null : _search,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 22),
                label: const Text('Tìm'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Chọn nhóm để mời vào',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          groupsAsync.when(
            data: (_) {
              if (sharedGroups.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Chưa có nhóm chung. Vào Quản lý nhóm → Thêm nhóm → Tạo nhóm mới.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                );
              }
              if (_inviteTargetGroup == null && sharedGroups.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _inviteTargetGroup == null) {
                    setState(() => _inviteTargetGroup = sharedGroups.first);
                  }
                });
              }
              final selectedGroup = _inviteTargetGroup != null &&
                      sharedGroups.any((g) => g.id == _inviteTargetGroup!.id)
                  ? sharedGroups.firstWhere((g) => g.id == _inviteTargetGroup!.id)
                  : sharedGroups.first;
              return DropdownButtonHideUnderline(
                child: DropdownButton<AppGroup>(
                  value: selectedGroup,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  hint: const Text('Chọn nhóm'),
                  items: sharedGroups
                      .map((g) => DropdownMenuItem<AppGroup>(
                            value: g,
                            child: Text(
                              g.name,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (g) => setState(() => _inviteTargetGroup = g),
                ),
              );
            },
            loading: () => const SizedBox(height: 48),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mời bạn vào nhóm',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_query.isEmpty || (_query.length < 2 && _results.isEmpty))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nhập từ khóa và bấm Tìm để tìm bạn.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Không tìm thấy ai phù hợp.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _results[index];
                final inviting = _invitingUserId == user.id;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    child: Text(
                      (user.fullName?.isNotEmpty == true
                              ? user.fullName![0]
                              : user.username?.isNotEmpty == true
                                  ? user.username![0]
                                  : '?')
                          .toUpperCase(),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  title: Text(
                    user.fullName?.trim().isNotEmpty == true
                        ? user.fullName!
                        : (user.username ?? 'Thành viên'),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: user.username != null
                      ? Text('@${user.username}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
                      : null,
                  trailing: canInvite && _inviteTargetGroup != null
                      ? TextButton.icon(
                          onPressed: inviting
                              ? null
                              : () => _inviteToGroup(user, _inviteTargetGroup!),
                          icon: inviting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.person_add, size: 20),
                          label: Text(inviting ? 'Đang mời...' : 'Mời vào ${_inviteTargetGroup!.name}'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        )
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }
}
