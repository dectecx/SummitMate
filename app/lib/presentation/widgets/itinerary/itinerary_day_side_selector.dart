import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/itinerary/itinerary_cubit.dart';
import '../day_management_dialog.dart';

/// 側邊天數選擇器 (桌面版專用)
class ItineraryDaySideSelector extends StatelessWidget {
  final List<String> dayNames;
  final String selectedDay;

  const ItineraryDaySideSelector({super.key, required this.dayNames, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('天數', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.edit_calendar, size: 20),
                onPressed: () => showDialog(context: context, builder: (_) => const DayManagementDialog()),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: dayNames.length,
            itemBuilder: (context, index) {
              final dayName = dayNames[index];
              final isSelected = dayName == selectedDay;
              return ListTile(
                title: Text(dayName),
                selected: isSelected,
                selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                onTap: () => context.read<ItineraryCubit>().selectDay(dayName),
              );
            },
          ),
        ),
      ],
    );
  }
}
