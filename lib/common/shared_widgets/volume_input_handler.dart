import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/volume_press_handler.dart';

class VolumeInputHandler extends StatefulWidget {
  final Widget child;
  final Function(VolumeButton)? onShortPress;
  final Function(VolumeButton)? onLongPress;
  final bool shouldPublishEvents;

  const VolumeInputHandler({
    super.key,
    required this.child,
    required this.shouldPublishEvents,
    this.onShortPress,
    this.onLongPress,
  });

  @override
  State<VolumeInputHandler> createState() => _VolumeInputHandlerState();
}

class _VolumeInputHandlerState extends State<VolumeInputHandler> {
  late final VolumePressHandler _volumePressHandler;
  StreamSubscription<VolumeButton>? _shortPressSubscription;
  StreamSubscription<VolumeButton>? _longPressSubscription;

  @override
  void initState() {
    super.initState();
    _volumePressHandler = context.read<VolumePressHandler>();
    if (widget.shouldPublishEvents) {
      _setupListeners();
    }
  }

  @override
  void didUpdateWidget(covariant VolumeInputHandler oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shouldPublishEvents != oldWidget.shouldPublishEvents) {
      if (widget.shouldPublishEvents) {
        log("VolumeInputHandler: starting listeners");
        _setupListeners();
      } else {
        log("VolumeInputHandler: cancelling listeners");
        _cancelListeners();
      }
    }
  }

  void _setupListeners() {
    if (widget.onShortPress != null) {
      _shortPressSubscription = _volumePressHandler.shortPressStream.listen(
        widget.onShortPress!,
      );
    }

    if (widget.onLongPress != null) {
      _longPressSubscription = _volumePressHandler.longPressStream.listen(
        widget.onLongPress!,
      );
    }
  }

  void _cancelListeners() {
    _shortPressSubscription?.cancel();
    _longPressSubscription?.cancel();
    _shortPressSubscription = null;
    _longPressSubscription = null;
  }

  @override
  void dispose() {
    _cancelListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
