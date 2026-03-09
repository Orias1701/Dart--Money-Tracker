import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/group.dart';
import '../providers/active_group_provider.dart';

class ManageGroupsScreen extends ConsumerStatefulWidget {
  const ManageGroupsScreen({super.key});

  @override
  ConsumerState<ManageGroupsScreen> createState() => _ManageGroupsScreenState();
}

class _ManageGroupsScreenState extends ConsumerState<ManageGroupsScreen> {
  final _createNameController = TextEditingController();
  final _joinIdController = TextEditingController();
  var _createLoading = false;
  var _joinLoading = false;
  String? _createError;
  String? _joinError;
  String? _joinSuccess;

  @override
  void dispose() {
    _createNameController.dispose();
    _joinIdController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _createNameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _createError = 'Nhập tên nhóm';
        _createLoading = false;
      });
      return;
    }
    setState(() {
      _createError = null;
      _createLoading = true;
    });
    final repo = ref.read(groupRepositoryProvider);
    final g = await repo.createGroup(name);
    if (!mounted) return;
    setState(() => _createLoading = false);
    if (g != null) {
      ref.read(activeGroupProvider.notifier).setActiveGroup(g);
      ref.invalidate(userGroupsListProvider);
      if (mounted) context.pop();
    } else {
      setState(() => _createError = 'Không tạo được nhóm');
    }
  }

  Future<void> _joinGroup() async {
    final id = _joinIdController.text.trim();
    if (id.isEmpty) {
      setState(() {
        _joinError = 'Nhập ID nhóm';
        _joinLoading = false;
      });
      return;
    }
    setState(() {
      _joinError = null;
      _joinSuccess = null;
      _joinLoading = true;
    });
    final repo = ref.read(groupRepositoryProvider);
    final err = await repo.joinGroupById(id);
    if (!mounted) return;
    setState(() => _joinLoading = false);
    if (err == null) {
      setState(() => _joinSuccess = 'Đã tham gia nhóm');
      ref.invalidate(userGroupsListProvider);
      final groups = await repo.getUserGroups();
      final joined = groups.where((g) => g.id == id).firstOrNull ?? (groups.isNotEmpty ? groups.first : null);
      if (joined != null) ref.read(activeGroupProvider.notifier).setActiveGroup(joined);
    } else {
      setState(() => _joinError = err);
    }
  }

  Future<void> _editGroup(AppGroup g) async {
    final nameController = TextEditingController(text: g.name);
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    final newName = nameController.text.trim();
    nameController.dispose();
    if (result != true || !mounted) return;
    if (newName.isEmpty) return;
    final repo = ref.read(groupRepositoryProvider);
    final updated = await repo.updateGroup(g.id, newName);
    if (!mounted) return;
    if (updated != null) {
      ref.invalidate(userGroupsListProvider);
      final active = ref.read(activeGroupProvider);
      if (active?.id == g.id) {
        ref.read(activeGroupProvider.notifier).setActiveGroup(updated);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật tên nhóm')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không sửa được. Kiểm tra quyền admin nhóm.'), backgroundColor: AppColors.expense),
        );
      }
    }
  }

  Future<void> _deleteGroup(AppGroup g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xóa nhóm'),
        content: Text(
          'Xóa nhóm "${g.name}"? Thành viên sẽ mất quyền truy cập. Không hoàn tác được.',
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
    final repo = ref.read(groupRepositoryProvider);
    final err = await repo.deleteGroup(g.id);
    if (!mounted) return;
    if (err == null) {
      ref.invalidate(userGroupsListProvider);
      final active = ref.read(activeGroupProvider);
      if (active?.id == g.id) {
        ref.read(activeGroupProvider.notifier).setActiveGroup(null);
        final list = await repo.getUserGroups();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.expense),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(userGroupsListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo & tham gia nhóm'),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nhóm của tôi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Chưa có nhóm. Tạo hoặc tham gia nhóm bên dưới.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: groups.map((g) {
                      return Card(
                        color: AppColors.surface,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            g.name,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                          ),
                          subtitle: g.isPersonal
                              ? const Text('Cá nhân', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
                                onPressed: () => _editGroup(g),
                                tooltip: 'Sửa tên',
                              ),
                              if (!g.isPersonal)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.expense, size: 22),
                                  onPressed: () => _deleteGroup(g),
                                  tooltip: 'Xóa nhóm',
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Center(child: SizedBox(height: 32, width: 32, child: CircularProgressIndicator(strokeWidth: 2))),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text('Không tải được danh sách nhóm.', style: TextStyle(color: AppColors.expense, fontSize: 14)),
              ),
            ),
            const Text(
              'Tạo nhóm mới',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _createNameController,
              decoration: const InputDecoration(
                labelText: 'Tên nhóm *',
                hintText: 'VD: Chi tiêu gia đình',
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              onSubmitted: (_) => _createGroup(),
            ),
            if (_createError != null) ...[
              const SizedBox(height: 8),
              Text(
                _createError!,
                style: const TextStyle(color: AppColors.expense, fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _createLoading ? null : _createGroup,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _createLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tạo nhóm'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tham gia nhóm bằng ID',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _joinIdController,
              decoration: const InputDecoration(
                labelText: 'ID nhóm *',
                hintText: 'Dán ID nhóm được chia sẻ',
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              onSubmitted: (_) => _joinGroup(),
            ),
            if (_joinError != null) ...[
              const SizedBox(height: 8),
              Text(
                _joinError!,
                style: const TextStyle(color: AppColors.expense, fontSize: 14),
              ),
            ],
            if (_joinSuccess != null) ...[
              const SizedBox(height: 8),
              Text(
                _joinSuccess!,
                style: const TextStyle(color: AppColors.income, fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _joinLoading ? null : _joinGroup,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _joinLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tham gia nhóm'),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
