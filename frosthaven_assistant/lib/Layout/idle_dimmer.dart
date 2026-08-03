import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../Resource/enums.dart';
import '../Resource/settings.dart';
import '../Resource/ui_utils.dart';
import '../services/service_locator.dart';

/// How long the app sits without input before dimming.
const Duration kIdleDimDelay = Duration(seconds: 15);

/// Opacity of the black scrim once dimmed. Deliberately short of opaque so the
/// board stays legible from across a table — initiative order and monster
/// health are still readable without touching anything.
const double kIdleDimScrimOpacity = 0.65;

/// Display brightness while dimmed, as a fraction of the hardware maximum.
///
/// Floored well above zero on purpose: this writes the real system brightness,
/// so if the process dies while dimmed and the plugin's auto-reset never runs,
/// the user is left with a dim screen rather than a black one they cannot see
/// to fix.
const double kIdleDimBrightness = 0.4;

const Duration _kFadeDuration = Duration(milliseconds: 1200);

/// Identifies the dim scrim so tests can assert on it specifically — Material
/// paints plenty of other ColoredBoxes.
const Key kIdleDimScrimKey = Key('idle-dim-scrim');

/// Dims the app after [kIdleDimDelay] without input, when the user has selected
/// [PowerMode.dimWhenIdle].
///
/// Unlike [PowerMode.reducePower] this keeps the wakelock held: the device never
/// locks, so waking is a single tap with no passcode and no lost place. On OLED
/// panels the black scrim genuinely powers pixels down, and the brightness drop
/// helps on every panel type.
class IdleDimmer extends StatefulWidget {
  const IdleDimmer({super.key, required this.child});

  final Widget child;

  @override
  State<IdleDimmer> createState() => _IdleDimmerState();
}

class _IdleDimmerState extends State<IdleDimmer> with WidgetsBindingObserver {
  Timer? _timer;
  bool _dimmed = false;
  late final Settings _settings;

  /// The brightness plugin ships for Android, iOS, macOS and Windows. This app
  /// also targets Linux and Web, where the calls would throw.
  static bool get _brightnessSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows;
  }

  @override
  void initState() {
    super.initState();
    _settings = getIt<Settings>();
    WidgetsBinding.instance.addObserver(this);
    _settings.powerMode.addListener(_onPowerModeChanged);
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _settings.powerMode.removeListener(_onPowerModeChanged);
    WidgetsBinding.instance.removeObserver(this);
    // Never leave the device dimmed because this widget went away.
    if (_dimmed) {
      _restoreBrightness();
      isDimmed.value = false;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _wake();
    } else {
      // Backgrounding counts as waking: the plugin restores brightness on
      // resign-active anyway, and coming back should never land on a dim screen.
      _cancelDim();
    }
  }

  void _onPowerModeChanged() {
    if (!dimWhenIdleEnabled(settings: _settings)) {
      _wake();
      _timer?.cancel();
      return;
    }
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!dimWhenIdleEnabled(settings: _settings)) return;
    _timer = Timer(kIdleDimDelay, _dim);
  }

  Future<void> _applyBrightness(double value) async {
    if (!_brightnessSupported) return;
    try {
      // `setApplicationScreenBrightness` is scoped to this app and is restored
      // by the plugin on resign-active. `setSystemScreenBrightness` would record
      // a new user preference, which is not ours to change.
      await ScreenBrightness.instance.setApplicationScreenBrightness(value);
    } catch (_) {
      // Brightness control is a bonus on top of the scrim; never let it break
      // the app if the platform refuses.
    }
  }

  Future<void> _restoreBrightness() async {
    if (!_brightnessSupported) return;
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (_) {
      // As above.
    }
  }

  void _dim() {
    if (!mounted || _dimmed) return;
    if (!dimWhenIdleEnabled(settings: _settings)) return;
    setState(() => _dimmed = true);
    isDimmed.value = true;
    unawaited(_applyBrightness(kIdleDimBrightness));
  }

  /// Undims and restarts the idle countdown.
  void _wake() {
    _cancelDim();
    _restartTimer();
  }

  void _cancelDim() {
    _timer?.cancel();
    if (!_dimmed) return;
    if (mounted) {
      setState(() => _dimmed = false);
    } else {
      _dimmed = false;
    }
    isDimmed.value = false;
    unawaited(_restoreBrightness());
  }

  void _onUserActivity([Object? _]) {
    if (_dimmed) {
      _wake();
      return;
    }
    _restartTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Translucent so normal input still reaches the board underneath while
      // the app is awake; the scrim below is what blocks input once dimmed.
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onUserActivity,
      onPointerSignal: _onUserActivity,
      child: Focus(
        onKeyEvent: (node, event) {
          _onUserActivity();
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            widget.child,
            if (_dimmed)
              Positioned.fill(
                child: GestureDetector(
                  key: kIdleDimScrimKey,
                  // Opaque: the tap that wakes the screen must not also land on
                  // the board and, say, change a monster's health.
                  behavior: HitTestBehavior.opaque,
                  onTap: _wake,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: kIdleDimScrimOpacity),
                    duration: _kFadeDuration,
                    curve: Curves.easeOut,
                    builder: (context, value, _) => ColoredBox(
                      color: Colors.black.withValues(alpha: value),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
