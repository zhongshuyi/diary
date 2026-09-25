import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/app_lock_service.dart';
import 'package:diary/application/diary_lock_coordinator.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/widgets/app_pin_pad.dart';

class DiaryLockGate extends StatefulWidget {
  const DiaryLockGate({
    required this.controller,
    required this.coordinator,
    required this.child,
    this.authenticate,
    this.lockService,
    super.key,
  });

  final SettingsController controller;
  final DiaryLockCoordinator coordinator;
  final Widget child;
  final Future<bool> Function()? authenticate;
  final AppLockService? lockService;

  @override
  State<DiaryLockGate> createState() => _DiaryLockGateState();
}

class _DiaryLockGateState extends State<DiaryLockGate>
    with WidgetsBindingObserver {
  final _localAuth = LocalAuthentication();
  late final AppLockService _pin =
      widget.lockService ?? AppLockService.instance;
  bool _locked = false;
  bool _pinReady = false;
  bool _pinLoadFailed = false;
  bool _startupResolved = false;
  bool _authenticating = false;
  bool _authenticationAttempted = false;
  bool _backgroundPending = false;
  String? _errorMessage;
  String _enteredPin = '';
  bool _checkingPin = false;
  int _failedPins = 0;
  DateTime? _retryAfter;
  late bool _lastBiometricEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = widget.controller.settings.biometricLock;
    _lastBiometricEnabled = widget.controller.settings.biometricLock;
    widget.controller.addListener(_onSettingsChanged);
    widget.coordinator.addListener(_onCoordinatorChanged);
    _pin.addListener(_onPinChanged);
    _loadPin();
  }

  Future<void> _loadPin() async {
    try {
      await _pin.load();
      if (!mounted) return;
      setState(() {
        _pinReady = true;
        _pinLoadFailed = false;
        _locked = _locked || _pin.hasPin;
        _errorMessage = null;
      });
      if (widget.controller.settings.biometricLock) _tryUnlock();
    } catch (error) {
      debugPrint('Unable to read app PIN: $error');
      if (mounted) {
        setState(() {
          _pinReady = true;
          _pinLoadFailed = true;
          _locked = true;
          _errorMessage = '无法读取应用密码，请重试';
        });
      }
    }
  }

  void _onPinChanged() {
    if (!mounted) return;
    if (!_pin.hasPin && !widget.controller.settings.biometricLock) {
      setState(() => _locked = false);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onSettingsChanged);
    widget.coordinator.removeListener(_onCoordinatorChanged);
    _pin.removeListener(_onPinChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final biometricEnabled = widget.controller.settings.biometricLock;
    final changed = biometricEnabled != _lastBiometricEnabled;
    _lastBiometricEnabled = biometricEnabled;
    if (!_startupResolved && !widget.controller.isLoading) {
      _startupResolved = true;
      if (biometricEnabled || _pin.hasPin) {
        setState(() => _locked = true);
        if (_pinReady && biometricEnabled) _tryUnlock();
        return;
      }
    }
    if (!changed) return;
    if (!biometricEnabled && !_pin.hasPin && _locked) {
      setState(() => _locked = false);
    }
  }

  void _onCoordinatorChanged() {
    if (!mounted || widget.coordinator.isExternalActivityActive) return;
    if (_locked && widget.controller.settings.biometricLock) _tryUnlock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.controller.settings.biometricLock && !_pin.hasPin) return;
    if (widget.coordinator.isExternalActivityActive) return;
    if (state == AppLifecycleState.inactive && !_authenticating) {
      _backgroundPending = true;
    }
    if ((state == AppLifecycleState.paused && _backgroundPending) ||
        state == AppLifecycleState.detached) {
      if (_authenticating) return;
      _backgroundPending = false;
      if (mounted && !_locked) {
        _authenticationAttempted = false;
        setState(() {
          _locked = true;
          _errorMessage = null;
        });
      }
    }
    if (state == AppLifecycleState.resumed) {
      _backgroundPending = false;
      if (_locked && widget.controller.settings.biometricLock) _tryUnlock();
    }
  }

  Future<void> _enterDigit(String digit) async {
    if (_checkingPin || _enteredPin.length >= AppLockService.pinLength) return;
    final retryAfter = _retryAfter;
    if (retryAfter != null && DateTime.now().isBefore(retryAfter)) {
      setState(() => _errorMessage = '尝试过多，请稍后再试');
      return;
    }
    if (retryAfter != null) _retryAfter = null;
    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });
    if (_enteredPin.length != AppLockService.pinLength) return;
    _checkingPin = true;
    try {
      if (await _pin.verifyPin(_enteredPin)) {
        _failedPins = 0;
        _retryAfter = null;
        if (mounted) {
          setState(() {
            _locked = false;
            _enteredPin = '';
            _errorMessage = null;
          });
        }
      } else if (mounted) {
        unawaited(HapticFeedback.mediumImpact());
        _failedPins += 1;
        if (_failedPins >= 5) {
          _retryAfter = DateTime.now().add(const Duration(seconds: 30));
          _failedPins = 0;
        }
        setState(() {
          _enteredPin = '';
          _errorMessage = _retryAfter == null ? '密码不正确，请重试' : '尝试过多，请 30 秒后再试';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '密码验证失败，请重试');
    } finally {
      _checkingPin = false;
    }
  }

  Future<void> _tryUnlock({bool manual = false}) async {
    if (_authenticating ||
        (_authenticationAttempted && !manual) ||
        !widget.controller.settings.biometricLock) {
      return;
    }
    _authenticationAttempted = true;
    if (mounted) setState(() => _errorMessage = null);
    _authenticating = true;
    try {
      final authenticated = widget.authenticate != null
          ? await widget.authenticate!()
          : await _localAuth.authenticate(
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
                biometricOnly:
                    _pin.hasPin &&
                    defaultTargetPlatform != TargetPlatform.windows,
                useErrorDialogs: true,
                stickyAuth: false,
                sensitiveTransaction: true,
              ),
            );
      if (!mounted) return;
      if (authenticated) {
        setState(() {
          _locked = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = _pin.hasPin ? null : '验证未完成，请点击按钮重试';
        });
      }
    } on Object catch (error) {
      debugPrint('Diary biometric authentication failed: $error');
      if (mounted) {
        setState(() {
          _errorMessage = '暂时无法验证，请点击按钮重试';
        });
      }
    } finally {
      _authenticating = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_pinReady || widget.controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_pinLoadFailed) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('无法读取应用锁'),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadPin, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (!_locked ||
        (!widget.controller.settings.biometricLock && !_pin.hasPin)) {
      return widget.child;
    }
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                    child: Icon(
                      Icons.lock_outline,
                      color: colors.onHero,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '日记已锁定',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _pin.hasPin ? '输入 6 位密码，或使用指纹解锁' : '验证身份后继续阅读你的记录。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.terracotta,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_pin.hasPin)
                    AppPinPad(
                      length: _enteredPin.length,
                      error: _errorMessage != null,
                      onDigit: _enterDigit,
                      onDelete: () {
                        if (_enteredPin.isNotEmpty) {
                          setState(
                            () => _enteredPin = _enteredPin.substring(
                              0,
                              _enteredPin.length - 1,
                            ),
                          );
                        }
                      },
                      onBiometric: widget.controller.settings.biometricLock
                          ? () => _tryUnlock(manual: true)
                          : null,
                      biometricBusy: _authenticating,
                    )
                  else
                    FilledButton.icon(
                      onPressed: _authenticating
                          ? null
                          : () => _tryUnlock(manual: true),
                      icon: const Icon(Icons.fingerprint),
                      label: Text(_authenticating ? '等待验证…' : '解锁日记'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
