import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/pomodoro_provider.dart';
import 'package:todoapp/providers/task_provider.dart';

class FocusModeScreen extends StatelessWidget {
  final TaskItem task;

  const FocusModeScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final pomodoro = Provider.of<PomodoroProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black, // Immersive dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Focus Mode', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Task Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                task.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (task.description.isNotEmpty)
              Text(
                task.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 60),

            // Pomodoro Timer Circular Progress
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: pomodoro.progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pomodoro.currentState == PomodoroState.focus
                          ? Colors.blue
                          : Colors.green,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pomodoro.timerString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w200,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      pomodoro.currentState == PomodoroState.focus
                          ? 'FOCUS'
                          : 'BREAK',
                      style: TextStyle(
                        color: pomodoro.currentState == PomodoroState.focus
                            ? Colors.blue
                            : Colors.green,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  onPressed: () => pomodoro.resetTimer(),
                ),
                const SizedBox(width: 40),
                GestureDetector(
                  onTap: () => pomodoro.toggleTimer(),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      pomodoro.isRunning ? Icons.pause : Icons.play_arrow,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
                IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.done_all, color: Colors.greenAccent),
                  onPressed: () {
                    taskProvider.updateTimeSpent(task.id, 25); // Log session
                    Navigator.pop(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),
            Text(
              'Session ${pomodoro.completedSessions + 1} • Est: ${task.estimatedMinutes ?? '--'}m',
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}
