import 'dart:async';

import 'package:flutter/material.dart';

import '../input/hands_free_controller.dart';
import '../input/hands_free_input.dart';

final handsFreeRouteObserver = RouteObserver<ModalRoute<dynamic>>();

/// Binds device input to the visible foreground route, including popup routes.
class HandsFreeInputHandler extends StatefulWidget {
  const HandsFreeInputHandler({
    super.key,
    required this.controller,
    required this.stage,
    required this.enabled,
    required this.onAction,
    required this.onError,
    required this.child,
    this.onGuidance,
    this.onVisibilityChanged,
  });

  final HandsFreeController controller;
  final HandsFreeStage stage;
  final bool enabled;
  final ValueChanged<HandsFreeAction> onAction;
  final ValueChanged<String> onError;
  final ValueChanged<String>? onGuidance;
  final ValueChanged<bool>? onVisibilityChanged;
  final Widget child;

  @override
  State<HandsFreeInputHandler> createState() => _HandsFreeInputHandlerState();
}

class _HandsFreeInputHandlerState extends State<HandsFreeInputHandler>
    with WidgetsBindingObserver, RouteAware {
  ModalRoute<dynamic>? _route;
  bool? _visible;
  bool _activated = false;
  bool _scheduled = false;
  HandsFreeStage? _stage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!identical(route, _route)) {
      handsFreeRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) handsFreeRouteObserver.subscribe(this, route);
    }
    _scheduleSync();
  }

  @override
  void didUpdateWidget(HandsFreeInputHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleSync();
  }

  void _scheduleSync() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _sync();
    });
  }

  bool get _isVisible =>
      _route?.isCurrent == true &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  void _sync() {
    final visible = _isVisible;
    if (_visible != visible) {
      _visible = visible;
      widget.onVisibilityChanged?.call(visible);
      if (!visible) unawaited(widget.controller.feedback.stop());
    }
    final active = visible && widget.enabled;
    if (active &&
        (!_activated ||
            _stage != widget.stage ||
            !widget.controller.isOwnedBy(this))) {
      _activated = true;
      _stage = widget.stage;
      widget.controller.activate(
        owner: this,
        stage: widget.stage,
        onAction: (action) {
          if (mounted && _isVisible && widget.enabled) widget.onAction(action);
        },
        onError: (message) {
          if (mounted) widget.onError(message);
        },
        onGuidance: (message) {
          if (mounted && _isVisible) widget.onGuidance?.call(message);
        },
      );
    } else if (!active && _activated) {
      _activated = false;
      widget.controller.deactivate(this);
    }
  }

  @override
  void didPush() => _scheduleSync();
  @override
  void didPopNext() => _scheduleSync();
  @override
  void didPushNext() => _sync();
  @override
  void didPop() => _sync();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _sync();

  @override
  void dispose() {
    handsFreeRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.deactivate(this);
    unawaited(widget.controller.feedback.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
