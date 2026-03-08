import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterState {
  const FilterState({
    required this.selectedTimeIndex, // 0=All/30d-default, 1=7d, 2=30d, 3=Custom
    this.startDate,
    this.endDate,
    this.selectedAccountIds = const [],
  });

  final int selectedTimeIndex;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> selectedAccountIds;

  FilterState copyWith({
    int? selectedTimeIndex,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? selectedAccountIds,
    bool clearDates = false,
  }) {
    return FilterState(
      selectedTimeIndex: selectedTimeIndex ?? this.selectedTimeIndex,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      selectedAccountIds: selectedAccountIds ?? this.selectedAccountIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterState &&
          selectedTimeIndex == other.selectedTimeIndex &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          listEquals(selectedAccountIds, other.selectedAccountIds);

  @override
  int get hashCode => Object.hash(
    selectedTimeIndex,
    startDate,
    endDate,
    Object.hashAll(selectedAccountIds),
  );
}

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() {
    // Default to "Last 30 days" equivalent, represented smoothly by index 2 or 0 depending on view.
    // Let's adopt 0 = "Tất cả" (Default for Records), 1 = "7 ngày qua", 2 = "30 ngày qua", 3 = "Tùy chọn".
    // For universal synergy, we'll start with 0 ("Tất cả") with null dates.
    // Records shows all. Charts might substitute null dates with 30 days locally if it wants, or we define 2 as default.
    // Let's stick to Records's original default: 0 ("Tất cả").
    return const FilterState(selectedTimeIndex: 0);
  }

  void updateFilter({
    required int selectedTimeIndex,
    DateTime? startDate,
    DateTime? endDate,
    required List<String> selectedAccountIds,
  }) {
    state = state.copyWith(
      selectedTimeIndex: selectedTimeIndex,
      startDate: startDate,
      endDate: endDate,
      selectedAccountIds: selectedAccountIds,
      clearDates: selectedTimeIndex == 0,
    );
  }

  void clearFilter() {
    state = const FilterState(selectedTimeIndex: 0);
  }
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(() {
  return FilterNotifier();
});
