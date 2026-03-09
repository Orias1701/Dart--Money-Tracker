import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chỉ số nhánh trong shell: 0=Records, 1=Charts, 2=Add, 3=Reports, 4=Me.
class ShellAppBarTitleNotifier extends Notifier<Map<int, Widget>> {
  @override
  Map<int, Widget> build() => {};

  void setTitle(int branchIndex, Widget title) {
    if (state[branchIndex] == title) return;
    state = {...state, branchIndex: title};
  }
}

final shellAppBarTitleProvider =
    NotifierProvider<ShellAppBarTitleNotifier, Map<int, Widget>>(
  ShellAppBarTitleNotifier.new,
);
