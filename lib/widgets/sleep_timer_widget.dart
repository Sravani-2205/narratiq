import 'dart:async';
import 'package:flutter/material.dart';

/// Sleep timer widget — stops playback after a set duration.
class SleepTimerWidget extends StatefulWidget {
  final VoidCallback onTimerEnd;

  const SleepTimerWidget({super.key, required this.onTimerEnd});

  @override
  State<SleepTimerWidget> createState() => _SleepTimerWidgetState();
}

class _SleepTimerWidgetState extends State<SleepTimerWidget> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isActive = false;

  static const _options = [15, 30, 45, 60];

  void _startTimer(int minutes) {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = minutes * 60;
      _isActive = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        t.cancel();
        setState(() => _isActive = false);
        widget.onTimerEnd();
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() { _isActive = false; _remainingSeconds = 0; });
  }

  String get _timeDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Sleep Timer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
        ),
        if (_isActive) ...[
          Text(_timeDisplay,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4EFF))),
          const SizedBox(height: 8),
          TextButton(onPressed: _cancelTimer, child: const Text('Cancel Timer')),
        ] else ...[
          Wrap(
            spacing: 8,
            children: _options.map((mins) => ElevatedButton(
              onPressed: () { _startTimer(mins); Navigator.pop(context); },
              child: Text('$mins min'),
            )).toList(),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
