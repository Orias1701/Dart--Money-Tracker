import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../groups/domain/group_invitation.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(myInvitationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: invitationsAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có thông báo nào.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myInvitationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final inv = list[index];
                return _InvitationTile(invitation: inv);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Lỗi: $e', style: const TextStyle(color: AppColors.expense)),
        ),
      ),
    );
  }
}

class _InvitationTile extends ConsumerStatefulWidget {
  const _InvitationTile({required this.invitation});

  final GroupInvitation invitation;

  @override
  ConsumerState<_InvitationTile> createState() => _InvitationTileState();
}

class _InvitationTileState extends ConsumerState<_InvitationTile> {
  bool _loading = false;

  Future<void> _accept() async {
    if (_loading) return;
    setState(() => _loading = true);
    final repo = ref.read(groupRepositoryProvider);
    final err = await repo.acceptInvitation(widget.invitation.id);
    if (!mounted) return;
    setState(() => _loading = false);
    ref.invalidate(myInvitationsProvider);
    ref.invalidate(userGroupsListProvider);
    final groups = await ref.read(userGroupsListProvider.future);
    if (!mounted) return;
    for (final g in groups) {
      if (g.id == widget.invitation.groupId) {
        ref.read(activeGroupProvider.notifier).setActiveGroup(g);
        break;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Đã tham gia nhóm ${widget.invitation.groupName}.'),
        backgroundColor: err == null ? AppColors.income : AppColors.expense,
      ),
    );
    if (err == null) {
      if (!mounted) return;
      context.pop();
    }
  }

  Future<void> _decline() async {
    if (_loading) return;
    setState(() => _loading = true);
    final repo = ref.read(groupRepositoryProvider);
    final err = await repo.declineInvitation(widget.invitation.id);
    if (!mounted) return;
    setState(() => _loading = false);
    ref.invalidate(myInvitationsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Đã từ chối lời mời.'),
        backgroundColor: err == null ? AppColors.textSecondary : AppColors.expense,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invitation;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        backgroundColor: AppColors.surface,
        child: const Icon(Icons.group_add, color: AppColors.primary),
      ),
      title: Text(
        '${inv.inviterName.isNotEmpty ? inv.inviterName : "Ai đó"} mời bạn vào nhóm',
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            inv.groupName,
            style: const TextStyle(color: AppColors.primary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: _loading ? null : _accept,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.income,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Đồng ý'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _loading ? null : _decline,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary),
                child: const Text('Từ chối'),
              ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}
