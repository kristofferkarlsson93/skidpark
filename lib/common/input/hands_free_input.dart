import 'dart:async';

enum HandsFreeAction { previous, next, confirm, stopAndSave }

enum HandsFreeStage { overview, skiSelection, recording }

class HandsFreeConfiguration {
  const HandsFreeConfiguration({
    required this.startDelay,
    this.selectFirstSki = false,
    this.canStopRecording = false,
  });

  final Duration startDelay;
  final bool selectFirstSki;
  final bool canStopRecording;
}

class HandsFreeInstructions {
  final String openRun;
  final String selectSki;
  final String confirmSki;
  final String? selectionLabel;
  final String? confirmationLabel;
  final String? stopLabel;

  const HandsFreeInstructions({
    required this.openRun,
    required this.selectSki,
    required this.confirmSki,
    this.selectionLabel,
    this.confirmationLabel,
    this.stopLabel,
  });
}

/// Route-owned input. Adapters translate device events into user intentions.
abstract interface class HandsFreeInput {
  HandsFreeConfiguration get configuration;
  HandsFreeInstructions get instructions;
  Stream<HandsFreeAction> get actions;
  Stream<String> get errors;
  Stream<String> get guidance;

  void setStage(HandsFreeStage stage);
  void start();
  Future<void> stop();
  Future<void> dispose();
}

abstract interface class HandsFreeFeedback {
  Future<void> announce(String message);
  Future<void> stop();
}
