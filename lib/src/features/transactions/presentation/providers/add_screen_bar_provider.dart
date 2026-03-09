import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';

/// State cho thanh shell khi đang ở màn Add (Hủy + Save cùng hàng Friend/Notif).
class AddScreenBarState {
  const AddScreenBarState({
    this.onCancel,
    this.onSave,
    this.isLoading = false,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final bool isLoading;
}

class AddScreenBarNotifier extends Notifier<AddScreenBarState> {
  @override
  AddScreenBarState build() => const AddScreenBarState();

  void update({
    VoidCallback? onCancel,
    VoidCallback? onSave,
    bool? isLoading,
  }) {
    state = AddScreenBarState(
      onCancel: onCancel ?? state.onCancel,
      onSave: onSave ?? state.onSave,
      isLoading: isLoading ?? state.isLoading,
    );
  }
}

final addScreenBarProvider =
    NotifierProvider<AddScreenBarNotifier, AddScreenBarState>(
  AddScreenBarNotifier.new,
);

/// Nội dung thanh Add cho shell: Hủy bên trái, Save giữa, cùng hàng với Friend/Notif.
class AddScreenBarContent extends ConsumerWidget {
  const AddScreenBarContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bar = ref.watch(addScreenBarProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: bar.onCancel,
          icon: const Icon(Icons.close),
          tooltip: 'Hủy',
        ),
        Expanded(
          child: Center(
            child: TextButton(
              onPressed: bar.isLoading ? null : bar.onSave,
              child: bar.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Lưu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
