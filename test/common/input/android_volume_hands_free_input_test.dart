import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:skidpark/common/input/android/android_volume_hands_free_input.dart';
import 'package:skidpark/common/input/hands_free_input.dart';
import 'package:skidpark/common/services/volume_press_handler.dart';

void main() {
  test(
    'Android maps existing short/long presses to the shared intentions',
    () async {
      final volume = _VolumeInput();
      final input = AndroidVolumeHandsFreeInput(volume);
      final actions = <HandsFreeAction>[];
      final subscription = input.actions.listen(actions.add);
      input.start();
      volume.short.add(VolumeButton.down);
      volume.long.add(VolumeButton.up);
      volume.long.add(VolumeButton.down);
      expect(actions, [HandsFreeAction.confirm]);

      input.setStage(HandsFreeStage.skiSelection);
      volume.short.add(VolumeButton.up);
      volume.short.add(VolumeButton.down);
      volume.long.add(VolumeButton.down);
      expect(actions, [
        HandsFreeAction.confirm,
        HandsFreeAction.previous,
        HandsFreeAction.next,
        HandsFreeAction.confirm,
      ]);

      input.setStage(HandsFreeStage.recording);
      volume.short.add(VolumeButton.up);
      volume.long.add(VolumeButton.down);
      volume.short.add(VolumeButton.down);
      expect(actions.last, HandsFreeAction.stopAndSave);

      await input.stop();
      volume.long.add(VolumeButton.down);
      expect(actions, hasLength(5));
      await input.dispose();
      expect(volume.disposed, isFalse);
      await subscription.cancel();
      volume.dispose();
    },
  );
}

class _VolumeInput implements VolumeButtonInput {
  final short = StreamController<VolumeButton>.broadcast(sync: true);
  final long = StreamController<VolumeButton>.broadcast(sync: true);
  bool disposed = false;
  @override
  bool get supportsVolumeInput => true;
  @override
  Stream<VolumeButton> get shortPressStream => short.stream;
  @override
  Stream<VolumeButton> get longPressStream => long.stream;
  @override
  void dispose() {
    disposed = true;
    unawaited(short.close());
    unawaited(long.close());
  }
}
