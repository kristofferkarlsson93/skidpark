import 'dart:async';

import 'hands_free_input.dart';

/// One device source shared by routes. Ownership changes immediately; native
/// stop/start operations are serialized so an old route cannot stop a new one.
class HandsFreeController {
  HandsFreeController({required this.input, required this.feedback}) {
    _actions = input.actions.listen((action) {
      if (_readyGeneration == _generation) _onAction?.call(action);
    });
    _guidance = input.guidance.listen((message) => _onGuidance?.call(message));
    _errors = input.errors.listen((message) {
      if (_readyGeneration != _generation) return;
      final onError = _onError;
      final owner = _owner;
      if (owner != null) deactivate(owner);
      onError?.call(message);
    });
  }

  final HandsFreeInput input;
  final HandsFreeFeedback feedback;
  late final StreamSubscription<HandsFreeAction> _actions;
  late final StreamSubscription<String> _guidance;
  late final StreamSubscription<String> _errors;
  Object? _owner;
  void Function(HandsFreeAction)? _onAction;
  void Function(String)? _onGuidance;
  void Function(String)? _onError;
  Future<void> _operation = Future.value();
  int _generation = 0;
  int? _readyGeneration;

  HandsFreeConfiguration get configuration => input.configuration;
  HandsFreeInstructions get instructions => input.instructions;

  bool isOwnedBy(Object owner) => identical(_owner, owner);

  void activate({
    required Object owner,
    required HandsFreeStage stage,
    required void Function(HandsFreeAction) onAction,
    required void Function(String) onError,
    void Function(String)? onGuidance,
  }) {
    if (_owner != null) {
      _operation = _operation.then((_) => input.stop());
    }
    final generation = ++_generation;
    _owner = owner;
    _onAction = onAction;
    _onGuidance = onGuidance;
    _onError = onError;
    _operation = _operation.then((_) {
      if (generation != _generation) return;
      input.setStage(stage);
      _readyGeneration = generation;
      input.start();
    });
  }

  void deactivate(Object owner) {
    if (!identical(owner, _owner)) return;
    _generation++;
    _owner = null;
    _onAction = null;
    _onGuidance = null;
    _onError = null;
    _operation = _operation.then((_) => input.stop());
  }

  Future<void> pause() async {
    final owner = _owner;
    if (owner != null) deactivate(owner);
    await _operation;
  }

  Future<void> dispose() async {
    _generation++;
    _onAction = null;
    _onGuidance = null;
    _onError = null;
    await _actions.cancel();
    await _guidance.cancel();
    await _errors.cancel();
    await _operation;
    await input.dispose();
    await feedback.stop();
  }
}
