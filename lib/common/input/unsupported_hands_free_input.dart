import 'hands_free_input.dart';

class UnsupportedHandsFreeInput implements HandsFreeInput {
  static const inputConfiguration = HandsFreeConfiguration(
    startDelay: Duration.zero,
  );
  static const inputInstructions = HandsFreeInstructions(
    openRun: '',
    selectSki: '',
    confirmSki: '',
  );
  @override
  HandsFreeConfiguration get configuration => inputConfiguration;
  @override
  HandsFreeInstructions get instructions => inputInstructions;
  @override
  Stream<HandsFreeAction> get actions => const Stream.empty();
  @override
  Stream<String> get errors => const Stream.empty();
  @override
  Stream<String> get guidance => const Stream.empty();
  @override
  void setStage(HandsFreeStage stage) {}
  @override
  void start() {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}
