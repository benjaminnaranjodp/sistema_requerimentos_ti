import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final Function(DateTime, DateTime) onDaySelected;

  const CalendarWidget({
    super.key,
    required this.selectedDay,
    required this.focusedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 4.0 : 8.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Mes',
          },
          calendarStyle: CalendarStyle(
            cellMargin: EdgeInsets.all(isMobile ? 2 : 4),
            todayDecoration: BoxDecoration(
              color: Colors.indigo.withAlpha(50),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            defaultTextStyle: TextStyle(fontSize: isMobile ? 12 : 14, color: Theme.of(context).textTheme.bodyMedium?.color),
            weekendTextStyle: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.red.shade300),
            todayTextStyle: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            selectedTextStyle: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontSize: isMobile ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150),
            ),
            weekendStyle: TextStyle(
              fontSize: isMobile ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade300,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: isMobile ? 14 : 17,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, size: isMobile ? 20 : 24),
            rightChevronIcon: Icon(Icons.chevron_right, size: isMobile ? 20 : 24),
            headerPadding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 8),
          ),
          rowHeight: isMobile ? 36 : 48,
          daysOfWeekHeight: isMobile ? 24 : 32,
        ),
      ),
    );
  }
}
