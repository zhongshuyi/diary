import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/diary_lock_coordinator.dart';
import 'package:diary/application/settings_controller.dart';

class DiaryLockGate extends StatefulWidget {
  const DiaryLockGate({
    required this.controller,
    required this.coordinator,
    required this.child,
    super.key,
  });

  final SettingsController controller;
  final DiaryLockCoordinator coordinator;
  final Widget child;

  @override
  State<DiaryLockGate> createState() => _DiaryLockGateState();
}

class _DiaryLockGateState extends State<DiaryLockGate>
    with WidgetsBindingObserver {
  final _localAuth = LocalAuthentication();
  bool _locked = false;
  bool _authenticating = false;
  bool _authenticationAttempted = false;
  bool _closingApp = false;
  String? _errorMessage;
  late bool _lastLockEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = widget.controller.settings.biometricLock;
    _lastLockEnabled = _locked;
    widget.controller.addListener(_onSettingsChanged);
    widget.coordinator.addListener(_onCoordinatorChanged);
    if (_locked) _tryUnlock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onSettingsChanged);
    widget.coordinator.removeListener(_onCoordinatorChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final enabled = widget.controller.settings.biometricLock;
    if (!enabled) {
      _lastLockEnabled = false;
      if (_locked) setState(() => _locked = false);
      return;
    }
    final wasJustEnabled = !_lastLockEnabled;
    _lastLockEnabled = true;
    if (wasJustEnabled && !_locked) {
      _authenticationAttempted = false;
      setState(() => _locked = true);
      _tryUnlock();
    }
  }

  void _onCoordinatorChanged() {
    if (!mounted || widget.coordinator.isExternalActivityActive) return;
    if (_locked && widget.controller.settings.biometricLock) _tryUnlock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.controller.settings.biometricLock) return;
    if (_authenticating) return;
    if (widget.coordinator.isExternalActivityActive) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (mounted) {
        _authenticationAttempted = false;
        setState(() {
          _locked = true;
          _errorMessage = null;
        });
      }
    }
    if (state == AppLifecycleState.resumed && _locked) _tryUnlock();
  }

  Future<void> _tryUnlock() async {
    if (_authenticating ||
        _authenticationAttempted ||
        _closingApp ||
        !widget.controller.settings.biometricLock) {
      return;
    }
    _authenticationAttempted = true;
    if (mounted) setState(() => _errorMessage = null);
    _authenticating = true;
    try {
      final authenticated = await _localAuth.authenticate(
        authMessages: const [
          AndroidAuthMessages(
            biometricHint: '请触碰指纹传感器',
            biometricNotRecognized: '指纹不匹配，请重试',
            biometricSuccess: '验证成功',
            cancelButton: '取消',
            goToSettingsButton: '去设置',
            goToSettingsDescription: '请先在系统中开启指纹或设置设备锁屏密码',
            signInTitle: '扫描指纹以继续',
          ),
        ],
        localizedReason: '验证身份后打开你的私人日记',
        options: AuthenticationOptions(
          biometricOnly: defaultTargetPlatform != TargetPlatform.windows,
          useErrorDialogs: true,
          // A cancelled attempt must finish this lock session. The gate owns
          // the next attempt when the app is locked again.
          stickyAuth: false,
          sensitiveTransaction: true,
        ),
      );
      if (authenticated && mounted) {
        setState(() => _locked = false);
      } else {
        await _exitApp();
      }
    } on PlatformException catch (error) {
      debugPrint('Diary biometric authentication failed: ${error.code}');
      await _exitApp();
    } catch (_) {
      await _exitApp();
    } finally {
      _authenticating = false;
      if (mounted && !_closingApp) setState(() {});
    }
  }

  Future<void> _exitApp() async {
    if (_closingApp) return;
    _closingApp = true;
    await SystemNavigator.pop(animated: true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked || !widget.controller.settings.biometricLock) {
      return widget.child;
    }
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.ink,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.lock_outline, color: colors.onHero, size: 34),
              ),
              const SizedBox(height: 20),
              Text('日记已锁定', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 7),
              Text(
                '验证身份后继续阅读你的记录。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.terracotta),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _authenticating || _authenticationAttempted
                    ? null
                    : _tryUnlock,
                icon: const Icon(Icons.fingerprint),
                label: Text(_authenticating ? '等待验证…' : '解锁日记'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
