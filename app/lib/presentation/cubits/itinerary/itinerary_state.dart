import 'package:equatable/equatable.dart';
import '../../../domain/entities/itinerary_item.dart';

abstract class ItineraryState extends Equatable {
  const ItineraryState();

  @override
  List<Object?> get props => [];
}

class ItineraryInitial extends ItineraryState {
  const ItineraryInitial();
}

class ItineraryLoading extends ItineraryState {
  const ItineraryLoading();
}

class ItineraryLoaded extends ItineraryState {
  final List<ItineraryItem> items;
  final String selectedDay;
  final bool isEditMode;
  final List<String> dayNames;
  final bool isMockMode;

  /// 建構子
  ///
  /// [items] 行程節點列表
  /// [selectedDay] 目前選擇的天數 (預設 'D1')
  /// [isEditMode] 是否處於編輯模式
  /// [dayNames] 天數名稱列表 (預設空)
  /// [isMockMode] 是否為教學展示模式
  const ItineraryLoaded({
    required this.items,
    this.selectedDay = 'D1',
    this.isEditMode = false,
    this.dayNames = const [],
    this.isMockMode = false,
  });

  /// CopyWith method for updating state
  ItineraryLoaded copyWith({
    List<ItineraryItem>? items,
    String? selectedDay,
    bool? isEditMode,
    List<String>? dayNames,
    bool? isMockMode,
  }) {
    return ItineraryLoaded(
      items: items ?? this.items,
      selectedDay: selectedDay ?? this.selectedDay,
      isEditMode: isEditMode ?? this.isEditMode,
      dayNames: dayNames ?? this.dayNames,
      isMockMode: isMockMode ?? this.isMockMode,
    );
  }

  /// Get items for the selected day, sorted by start time
  List<ItineraryItem> get currentDayItems {
    final dayItems = items.where((item) => item.day == selectedDay).toList();
    dayItems.sort((a, b) => a.estTime.compareTo(b.estTime));
    return dayItems;
  }

  /// Progress (checked / total count)
  double get progress {
    if (items.isEmpty) return 0;
    final checked = items.where((item) => item.isCheckedIn).length;
    return checked / items.length;
  }

  @override
  List<Object?> get props => [items, selectedDay, isEditMode, dayNames, isMockMode];
}

class ItineraryError extends ItineraryState {
  final String message;

  const ItineraryError(this.message);

  @override
  List<Object?> get props => [message];
}

class ItineraryDayRemovalWarning extends ItineraryState {
  final String dayName;
  final String mealPlanDayId;

  const ItineraryDayRemovalWarning({required this.dayName, required this.mealPlanDayId});

  @override
  List<Object?> get props => [dayName, mealPlanDayId];
}
