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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = widget.controller.settings.biometricLock;
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
    if (!widget.controller.settings.biometricLock) {
      if (_locked) setState(() => _locked = false);
      return;
    }
    if (!_locked) {
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
      if (mounted) setState(() => _locked = true);
    }
    if (state == AppLifecycleState.resumed && _locked) _tryUnlock();
  }

  Future<void> _tryUnlock() async {
    if (_authenticating || !widget.controller.settings.biometricLock) return;
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
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
      if (authenticated && mounted) {
        setState(() => _locked = false);
      } else if (mounted) {
        setState(() => _errorMessage = '验证未完成。请录入指纹，或先设置系统锁屏密码。');
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = '系统验证失败（${error.code}）。请先在系统设置中确认指纹和锁屏密码已启用。',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = '系统没有可用的生物识别验证，请先在系统设置中录入指纹或设置锁屏密码。');
      }
    } finally {
      _authenticating = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked || !widget.controller.settings.biometricLock) {
      return widget.child;
    }
    return Scaffold(
      backgroundColor: DiaryPalette.paper,
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
                  color: DiaryPalette.ink,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: DiaryPalette.butter,
                  size: 34,
                ),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DiaryPalette.terracotta,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _authenticating ? null : _tryUnlock,
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
