import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/recipe.dart';

class CookingModePage extends StatefulWidget {
  const CookingModePage({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<CookingModePage> createState() => _CookingModePageState();
}

class _CookingModePageState extends State<CookingModePage> {
  int _step = 0;
  int _remainingSeconds = 0;
  Timer? _timer;

  RecipeStep get current => widget.recipe.steps[_step];

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();
    _remainingSeconds = current.durationMinutes * 60;
  }

  void _move(int delta) {
    setState(() {
      _step = (_step + delta).clamp(0, widget.recipe.steps.length - 1);
      _resetTimer();
    });
  }

  void _toggleTimer() {
    if (_timer?.isActive == true) {
      _timer?.cancel();
      setState(() {});
      return;
    }
    if (_remainingSeconds <= 0) {
      _remainingSeconds = current.durationMinutes * 60;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = (_step + 1) / widget.recipe.steps.length;
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: Text('${_step + 1} / ${widget.recipe.steps.length}'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: progress, minHeight: 5),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: [
                        Text(
                          'STEP ${_step + 1}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.8,
                              ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          current.instruction,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontFamily: 'Georgia',
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                        ),
                        if (current.tip.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Text(
                                'Kitchen note — ${current.tip}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                        if (current.durationMinutes > 0) ...[
                          const SizedBox(height: 34),
                          Text(
                            '$minutes:$seconds',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _toggleTimer,
                            icon: Icon(
                              _timer?.isActive == true
                                  ? Icons.pause
                                  : Icons.timer_outlined,
                            ),
                            label: Text(
                              _timer?.isActive == true
                                  ? 'Pause timer'
                                  : 'Start timer',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _step > 0 ? () => _move(-1) : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _step < widget.recipe.steps.length - 1
                          ? () => _move(1)
                          : () => Navigator.of(context).pop(),
                      icon: Icon(
                        _step < widget.recipe.steps.length - 1
                            ? Icons.arrow_forward
                            : Icons.check,
                      ),
                      label: Text(
                        _step < widget.recipe.steps.length - 1
                            ? 'Next'
                            : 'Finish',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
