import 'dart:async';

import 'package:flutter/material.dart';
import 'package:river_player/src/core/better_player_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Netflix-style vertical swipe overlay. In fullscreen, a vertical drag on the
/// left half of the player adjusts device screen brightness and a vertical drag
/// on the right half adjusts the media volume. The gesture zones are translucent
/// so taps still fall through to the controls layer below.
///
/// This widget is intentionally placed above the controls in the player stack so
/// its drag recognizers win the vertical-drag gesture, while taps (which it does
/// not handle) are delegated to the controls. When not in fullscreen — or when
/// the matching config flag is disabled — it renders nothing and does not
/// interfere with tap handling or page scrolling for inline players.
class BetterPlayerVerticalDragControls extends StatefulWidget {
  final BetterPlayerController controller;

  const BetterPlayerVerticalDragControls({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<BetterPlayerVerticalDragControls> createState() =>
      _BetterPlayerVerticalDragControlsState();
}

enum _DragMode { brightness, volume }

class _BetterPlayerVerticalDragControlsState
    extends State<BetterPlayerVerticalDragControls> {
  static const double _dragSensitivity = 1.0;

  bool _brightnessTouched = false;
  double _brightnessValue = 1.0;
  double _volumeValue = 1.0;

  _DragMode? _activeMode;
  double _dragStartValue = 0.0;
  bool _indicatorVisible = false;
  Timer? _hideIndicatorTimer;

  BetterPlayerController get _controller => widget.controller;

  @override
  void dispose() {
    _hideIndicatorTimer?.cancel();
    // Release the app-forced brightness so leaving the player restores the
    // system brightness the user had before.
    if (_brightnessTouched) {
      ScreenBrightness().resetApplicationScreenBrightness();
    }
    super.dispose();
  }

  bool get _enableBrightness =>
      _controller.betterPlayerControlsConfiguration.enableBrightnessControl;

  bool get _enableVolume =>
      _controller.betterPlayerControlsConfiguration.enableVolumeControl;

  Future<void> _onDragStart(_DragMode mode) async {
    _hideIndicatorTimer?.cancel();
    _activeMode = mode;
    if (mode == _DragMode.brightness) {
      try {
        _brightnessValue = await ScreenBrightness().application;
      } catch (_) {
        _brightnessValue = 1.0;
      }
      _dragStartValue = _brightnessValue;
    } else {
      _volumeValue =
          _controller.videoPlayerController?.value.volume ?? _volumeValue;
      _dragStartValue = _volumeValue;
    }
    if (mounted) {
      setState(() => _indicatorVisible = true);
    }
  }

  void _onDragUpdate(double primaryDelta, double height) {
    if (_activeMode == null || height <= 0) {
      return;
    }
    // Dragging up increases the value, dragging down decreases it.
    _dragStartValue =
        (_dragStartValue - (primaryDelta / height) * _dragSensitivity)
            .clamp(0.0, 1.0);

    if (_activeMode == _DragMode.brightness) {
      _brightnessTouched = true;
      _brightnessValue = _dragStartValue;
      ScreenBrightness().setApplicationScreenBrightness(_brightnessValue);
    } else {
      _volumeValue = _dragStartValue;
      _controller.setVolume(_volumeValue);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onDragEnd() {
    _activeMode = null;
    _hideIndicatorTimer?.cancel();
    _hideIndicatorTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _indicatorVisible = false);
      }
    });
  }

  Widget _buildDragZone(_DragMode mode) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (_) => _onDragStart(mode),
      onVerticalDragUpdate: (details) {
        final height = context.size?.height ?? 1.0;
        _onDragUpdate(details.primaryDelta ?? 0.0, height);
      },
      onVerticalDragEnd: (_) => _onDragEnd(),
      onVerticalDragCancel: _onDragEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isFullScreen) {
      return const SizedBox.shrink();
    }
    if (!_enableBrightness && !_enableVolume) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Row(
          children: [
            Expanded(
              child: _enableBrightness
                  ? _buildDragZone(_DragMode.brightness)
                  : const SizedBox.expand(),
            ),
            Expanded(
              child: _enableVolume
                  ? _buildDragZone(_DragMode.volume)
                  : const SizedBox.expand(),
            ),
          ],
        ),
        if (_indicatorVisible && _activeMode != null)
          Align(
            alignment: _activeMode == _DragMode.brightness
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: _buildIndicator(),
          ),
      ],
    );
  }

  Widget _buildIndicator() {
    final bool isBrightness = _activeMode == _DragMode.brightness;
    final double value = isBrightness ? _brightnessValue : _volumeValue;
    final IconData icon = isBrightness
        ? (value <= 0.02
            ? Icons.brightness_low
            : value >= 0.98
                ? Icons.brightness_high
                : Icons.brightness_6)
        : (value <= 0.0
            ? Icons.volume_off
            : value < 0.5
                ? Icons.volume_down
                : Icons.volume_up);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                width: 4,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(value * 100).round()}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
