import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:skidpark/common/input/hands_free_controller.dart';
import 'package:skidpark/common/input/hands_free_input.dart';

void main() {
  test('route handover waits for stop and a hidden old route cannot stop the new owner', () async {
    final input = _Input();
    final controller = HandsFreeController(input: input, feedback: _Feedback());
    final overview = Object();
    final selection = Object();
    final overviewActions = <HandsFreeAction>[];
    final selectionActions = <HandsFreeAction>[];
    controller.activate(
      owner: overview,
      stage: HandsFreeStage.overview,
      onAction: overviewActions.add,
      onError: fail,
    );
    await Future<void>.delayed(Duration.zero);
    input.emit(HandsFreeAction.confirm);
    expect(overviewActions, [HandsFreeAction.confirm]);

    input.pendingStop = Completer<void>();
    controller.deactivate(overview);
    controller.activate(
      owner: selection,
      stage: HandsFreeStage.skiSelection,
      onAction: selectionActions.add,
      onError: fail,
    );
    input.emit(HandsFreeAction.confirm);
    expect(selectionActions, isEmpty);
    controller.deactivate(overview);
    input.pendingStop!.complete();
    await Future<void>.delayed(Duration.zero);
    input.emit(HandsFreeAction.next);
    expect(selectionActions, [HandsFreeAction.next]);
    expect(input.starts, 2);
    await controller.dispose();
  });
}

class _Input implements HandsFreeInput {
  final _actions = StreamController<HandsFreeAction>.broadcast(sync: true);
  Completer<void>? pendingStop;
  int starts = 0;
  void emit(HandsFreeAction action) => _actions.add(action);
  @override
  final configuration = const HandsFreeConfiguration(
    startDelay: Duration(seconds: 2),
  );
  @override
  final instructions = const HandsFreeInstructions(
    openRun: '',
    selectSki: '',
    confirmSki: '',
  );
  @override
  Stream<HandsFreeAction> get actions => _actions.stream;
  @override
  Stream<String> get errors => const Stream.empty();
  @override
  Stream<String> get guidance => const Stream.empty();
  @override
  void setStage(HandsFreeStage stage) {}
  @override
  void start() => starts++;
  @override
  Future<void> stop() async => pendingStop?.future;
  @override
  Future<void> dispose() async => _actions.close();
}

class _Feedback implements HandsFreeFeedback {
  @override
  Future<void> announce(String message) async {}
  @override
  Future<void> stop() async {}
}
