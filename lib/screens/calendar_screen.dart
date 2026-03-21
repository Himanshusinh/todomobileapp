import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/widgets/task_tile.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<TaskItem> _getEventsForDay(DateTime day, TaskProvider provider) {
    return provider.getTasksForDay(day);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);

    final appBarBg =
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: appBarBg,
          elevation: 0,
          child: SafeArea(
            bottom: false,
            child: AppBar(
              title: const Text('Calendar'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.today),
                  onPressed: () => setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = _focusedDay;
                  }),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
          TableCalendar<TaskItem>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: (day) => _getEventsForDay(day, taskProvider),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildTaskList(taskProvider),
          ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(TaskProvider provider) {
    final tasks = _getEventsForDay(_selectedDay ?? _focusedDay, provider);
    
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks for this day'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskTile(
          key: ValueKey(task.id),
          task: task,
          isSelectionMode: false,
          isSelected: false,
          onTap: () {}, // Navigate to edit if needed
          onLongPress: () {},
        );
      },
    );
  }
}
