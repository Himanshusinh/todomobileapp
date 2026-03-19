import 'dart:async';
import 'package:flutter/foundation.dart';

enum PomodoroState { focus, shortBreak, longBreak }

class PomodoroProvider extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  PomodoroState _currentState = PomodoroState.focus;
  int _completedSessions = 0;

  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  PomodoroState get currentState => _currentState;
  int get completedSessions => _completedSessions;

  String get timerString {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progress => 1 - (_remainingSeconds / _getInitialSeconds(_currentState));

  void toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
    notifyListeners();
  }

  void resetTimer() {
    _stopTimer();
    _remainingSeconds = _getInitialSeconds(_currentState);
    notifyListeners();
  }

  void _startTimer() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
  }

  void _stopTimer() {
    _isRunning = false;
    _timer?.cancel();
  }

  void _onTimerComplete() {
    _stopTimer();
    if (_currentState == PomodoroState.focus) {
      _completedSessions++;
      if (_completedSessions % 4 == 0) {
        _currentState = PomodoroState.longBreak;
      } else {
        _currentState = PomodoroState.shortBreak;
      }
    } else {
      _currentState = PomodoroState.focus;
    }
    _remainingSeconds = _getInitialSeconds(_currentState);
    notifyListeners();
  }

  int _getInitialSeconds(PomodoroState state) {
    switch (state) {
      case PomodoroState.focus:
        return 25 * 60;
      case PomodoroState.shortBreak:
        return 5 * 60;
      case PomodoroState.longBreak:
        return 15 * 60;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
