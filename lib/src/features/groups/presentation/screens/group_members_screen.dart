import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/group_member.dart';
import '../providers/active_group_provider.dart';

class GroupMembersScreen extends ConsumerStatefulWidget {
  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.isPersonal = true,
  });

  final String groupId;
  final String groupName;
  final bool isPersonal;

  @override
  ConsumerState<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends ConsumerState<GroupMembersScreen> {
  String? _actionError;
  bool _kicking = false;
  late String _groupName;

  @override
  void initState() {
    super.initState();
    _groupName = widget.groupName;
  }

  String _memberInitial(GroupMember m) {
    final name = m.user?.fullName ?? m.user?.username ?? '';
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  Future<void> _leaveGroup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Rời nhóm'),
        content: Text('Bạn có chắc muốn rời nhóm "$_groupName"?'),
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
    setState(() => _actionError = null);
    final err = await ref.read(groupRepositoryProvider).leaveGroup(widget.groupId);
    if (!mounted) return;
    if (err != null) {
      setState(() => _actionError = err);
      return;
    }
    ref.invalidate(userGroupsListProvider);
    ref.invalidate(groupMembersProvider(widget.groupId));
    final active = ref.read(activeGroupProvider);
    if (active?.id == widget.groupId) {
      ref.read(activeGroupProvider.notifier).setActiveGroup(null);
      final groups = await ref.read(groupRepositoryProvider).getUserGroups();
      final personal = groups.where((g) => g.isPersonal).firstOrNull;
      if (personal != null) {
        ref.read(activeGroupProvider.notifier).setActiveGroup(personal);
      }
    }
    if (mounted) context.pop();
  }

  Future<void> _kickMember(GroupMember member) async {
    final name = member.user?.fullName ?? member.user?.username ?? 'Thành viên';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xóa khỏi nhóm'),
        content: Text('Bạn có chắc muốn xóa "$name" khỏi nhóm "$_groupName"?'),
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
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _actionError = null;
      _kicking = true;
    });
    final err = await ref.read(groupRepositoryProvider).kickMember(widget.groupId, member.userId);
    if (!mounted) return;
    setState(() => _kicking = false);
    if (err != null) {
      setState(() => _actionError = err);
      return;
    }
    ref.invalidate(groupMembersProvider(widget.groupId));
    ref.invalidate(userGroupsListProvider);
  }

  Future<void> _editGroup() async {
    final nameController = TextEditingController(text: _groupName);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sửa tên nhóm'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Tên nhóm *',
            hintText: 'VD: Chi tiêu gia đình',
          ),
          style: const TextStyle(color: AppColors.textPrimary),
          autofocus: true,
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
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
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    final newName = nameController.text.trim();
    nameController.dispose();
    if (result != true || !mounted || newName.isEmpty) return;
    setState(() => _actionError = null);
    final updated = await ref.read(groupRepositoryProvider).updateGroup(widget.groupId, newName);
    if (!mounted) return;
    if (updated != null) {
      setState(() => _groupName = updated.name);
      ref.invalidate(userGroupsListProvider);
      final active = ref.read(activeGroupProvider);
      if (active?.id == widget.groupId) {
        ref.read(activeGroupProvider.notifier).setActiveGroup(updated);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật tên nhóm')),
        );
      }
    } else {
      setState(() => _actionError = 'Không sửa được. Kiểm tra quyền admin nhóm.');
    }
  }

  Future<void> _deleteGroup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xóa nhóm'),
        content: Text(
          'Xóa nhóm "$_groupName"? Thành viên sẽ mất quyền truy cập. Không hoàn tác được.',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _actionError = null);
    final err = await ref.read(groupRepositoryProvider).deleteGroup(widget.groupId);
    if (!mounted) return;
    if (err == null) {
      ref.invalidate(userGroupsListProvider);
      final active = ref.read(activeGroupProvider);
      if (active?.id == widget.groupId) {
        ref.read(activeGroupProvider.notifier).setActiveGroup(null);
        final list = await ref.read(groupRepositoryProvider).getUserGroups();
        final personal = list.where((x) => x.isPersonal).firstOrNull;
        if (personal != null) {
          ref.read(activeGroupProvider.notifier).setActiveGroup(personal);
        } else if (list.isNotEmpty) {
          ref.read(activeGroupProvider.notifier).setActiveGroup(list.first);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa nhóm')),
        );
        context.pop();
      }
    } else {
      setState(() => _actionError = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    GroupMember? myMembership;
    var isAdmin = false;
    if (membersAsync.hasValue && currentUserId != null) {
      myMembership = membersAsync.value!.where((m) => m.userId == currentUserId).firstOrNull;
      isAdmin = myMembership?.isAdmin ?? false;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_groupName),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: _editGroup,
              tooltip: 'Sửa tên nhóm',
            ),
            if (!widget.isPersonal)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                onPressed: _deleteGroup,
                tooltip: 'Xóa nhóm',
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_actionError != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _actionError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return const Center(child: Text('Chưa có thành viên'));
                }
                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final m = members[index];
                    final isMe = m.userId == currentUserId;
                    final canKick = isAdmin && !isMe;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                        child: Text(
                          _memberInitial(m),
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                      title: Text(
                        m.user?.fullName ?? m.user?.username ?? 'Thành viên',
                        style: TextStyle(
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          color: isMe ? AppColors.income : null,
                        ),
                      ),
                      subtitle: Text(m.role == 'admin' ? 'Admin' : 'Thành viên'),
                      trailing: canKick
                          ? TextButton(
                              onPressed: _kicking
                                  ? null
                                  : () => _kickMember(m),
                              child: const Text('Xóa khỏi nhóm'),
                            )
                          : null,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
            ),
          ),
          if (!widget.isPersonal && myMembership != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _leaveGroup,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Rời nhóm'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
