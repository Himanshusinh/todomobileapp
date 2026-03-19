import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/screens/focus_mode_screen.dart';

class PlanningWizardScreen extends StatefulWidget {
  const PlanningWizardScreen({super.key});

  @override
  State<PlanningWizardScreen> createState() => _PlanningWizardScreenState();
}

class _PlanningWizardScreenState extends State<PlanningWizardScreen> {
  int _currentStep = 0;
  final Set<String> _selectedTodayIds = {};

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final overdue = taskProvider.getSuggestedTasks().where((t) => !t.isCompleted).toList();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Planning Wizard')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            Navigator.pop(context);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.pop(context);
          }
        },
        steps: [
          Step(
            title: const Text('Review Overdue & Critical'),
            subtitle: const Text('Check these tasks first'),
            content: Column(
              children: overdue.map((t) => CheckboxListTile(
                title: Text(t.title),
                value: _selectedTodayIds.contains(t.id),
                onChanged: (val) {
                  setState(() => val! ? _selectedTodayIds.add(t.id) : _selectedTodayIds.remove(t.id));
                },
              )).toList(),
            ),
          ),
          Step(
            title: const Text('Pick Your "Big" 3'),
            subtitle: const Text('Focus on 3 main tasks today'),
            content: Column(
              children: [
                const Text('Choose 3 tasks to focus on for maximum productivity'),
                ...taskProvider.tasks.where((t) => !t.isCompleted && !_selectedTodayIds.contains(t.id)).take(5).map((t) => CheckboxListTile(
                  title: Text(t.title),
                  value: _selectedTodayIds.contains(t.id),
                  onChanged: (val) {
                    setState(() => val! ? _selectedTodayIds.add(t.id) : _selectedTodayIds.remove(t.id));
                  },
                )),
              ],
            ),
          ),
          Step(
            title: const Text('Ready to Focus?'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your focus list for today:'),
                const SizedBox(height: 10),
                ..._selectedTodayIds.map((id) {
                  final t = taskProvider.tasks.firstWhere((t) => t.id == id);
                  return ListTile(
                    title: Text(t.title),
                    leading: const Icon(Icons.star, color: Colors.blue),
                    trailing: IconButton(
                      icon: const Icon(Icons.center_focus_strong),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FocusModeScreen(task: t))),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
