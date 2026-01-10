import 'package:equatable/equatable.dart';
import '../../../data/models/itinerary_item.dart';

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

  const ItineraryLoaded({required this.items, this.selectedDay = 'D1', this.isEditMode = false});

  /// CopyWith method for updating state
  ItineraryLoaded copyWith({List<ItineraryItem>? items, String? selectedDay, bool? isEditMode}) {
    return ItineraryLoaded(
      items: items ?? this.items,
      selectedDay: selectedDay ?? this.selectedDay,
      isEditMode: isEditMode ?? this.isEditMode,
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
  List<Object?> get props => [items, selectedDay, isEditMode];
}

class ItineraryError extends ItineraryState {
  final String message;

  const ItineraryError(this.message);

  @override
  List<Object?> get props => [message];
}
