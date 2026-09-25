import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/app_lock_service.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/widgets/app_pin_pad.dart';

class AppLockSettings extends StatefulWidget {
  const AppLockSettings({
    required this.controller,
    this.lockService,
    super.key,
  });

  final SettingsController controller;
  final AppLockService? lockService;

  @override
  State<AppLockSettings> createState() => _AppLockSettingsState();
}

class _AppLockSettingsState extends State<AppLockSettings> {
  late final AppLockService _lock =
      widget.lockService ?? AppLockService.instance;
  bool _loading = true;
  bool _loadFailed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _lock.addListener(_refresh);
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      await _lock.load();
      _loadFailed = false;
    } catch (_) {
      _loadFailed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _lock.removeListener(_refresh);
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _pinSheet({required bool verify}) async {
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: DiaryThemeColors.of(context).paper,
          builder: (_) => _PinSheet(lock: _lock, verify: verify),
        ) ??
        false;
  }

  Future<void> _setPin() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (await _pinSheet(verify: false) && mounted) {
        _message('应用密码已设置');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _managePin() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.password_rounded),
              title: const Text('更改应用密码'),
              onTap: () => Navigator.pop(context, 'change'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_open_rounded),
              title: const Text('关闭应用锁'),
              subtitle: const Text('需要先输入当前密码'),
              onTap: () => Navigator.pop(context, 'disable'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (!await _pinSheet(verify: true) || !mounted) return;
    if (action == 'change') {
      await _setPin();
    } else {
      try {
        await _lock.removePin();
        await widget.controller.setBiometricLock(false);
        if (mounted) _message('应用锁已关闭');
      } catch (_) {
        if (mounted) _message('关闭失败，请重试');
      }
    }
  }

  Future<void> _setBiometric(bool enabled) async {
    if (_busy) return;
    if (enabled && !_lock.hasPin) {
      _message('请先设置应用密码');
      return;
    }
    setState(() => _busy = true);
    try {
      if (enabled) {
        final auth = LocalAuthentication();
        final available = defaultTargetPlatform == TargetPlatform.windows
            ? await auth.isDeviceSupported()
            : (await auth.getAvailableBiometrics()).isNotEmpty;
        if (!available) {
          if (mounted) _message('请先在系统中录入指纹或面容');
          return;
        }
      }
      await widget.controller.setBiometricLock(enabled);
    } catch (_) {
      if (mounted) _message('生物识别暂时不可用');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final biometric = widget.controller.settings.biometricLock;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          ListTile(
            key: const Key('settings-app-pin'),
            leading: Icon(Icons.lock_outline_rounded, color: colors.terracotta),
            title: Text(_lock.hasPin ? '应用密码' : '设置应用密码'),
            subtitle: Text(
              _loadFailed
                  ? '无法读取应用密码 · 点击重试'
                  : _loading
                  ? '正在检查应用锁…'
                  : _lock.hasPin
                  ? '已设置 6 位密码 · 点击更改或关闭'
                  : biometric
                  ? '设置密码后，指纹不可用时也能解锁'
                  : '用 6 位密码保护日记',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _loading || _busy
                ? null
                : _loadFailed
                ? _load
                : _lock.hasPin
                ? _managePin
                : _setPin,
          ),
          Divider(height: 1, indent: 56, color: colors.line),
          SwitchListTile(
            key: const Key('settings-biometric-lock'),
            secondary: Icon(
              Icons.fingerprint_rounded,
              color: colors.terracotta,
            ),
            title: const Text('生物识别快捷解锁'),
            subtitle: Text(
              _lock.hasPin
                  ? '打开应用时自动验证，也可输入应用密码'
                  : biometric
                  ? '原有生物识别锁仍可使用；建议设置应用密码'
                  : '设置应用密码后可开启',
            ),
            value: biometric,
            onChanged: _loading || _loadFailed || _busy ? null : _setBiometric,
          ),
        ],
      ),
    );
  }
}

class _PinSheet extends StatefulWidget {
  const _PinSheet({required this.lock, required this.verify});

  final AppLockService lock;
  final bool verify;

  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet> {
  String _entered = '';
  String? _first;
  String? _error;
  bool _busy = false;

  Future<void> _digit(String digit) async {
    if (_busy || _entered.length >= AppLockService.pinLength) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length != AppLockService.pinLength) return;
    final pin = _entered;
    if (widget.verify) {
      setState(() => _busy = true);
      try {
        if (await widget.lock.verifyPin(pin)) {
          if (mounted) Navigator.pop(context, true);
        } else if (mounted) {
          unawaited(HapticFeedback.mediumImpact());
          setState(() {
            _entered = '';
            _error = '密码不正确，请重试';
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _entered = '';
            _error = '验证失败，请重试';
          });
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    } else if (_first == null) {
      setState(() {
        _first = pin;
        _entered = '';
      });
    } else if (_first != pin) {
      unawaited(HapticFeedback.mediumImpact());
      setState(() {
        _first = null;
        _entered = '';
        _error = '两次密码不一致，请重新设置';
      });
    } else {
      setState(() => _busy = true);
      try {
        await widget.lock.setPin(pin);
        if (mounted) Navigator.pop(context, true);
      } catch (_) {
        if (mounted) {
          setState(() {
            _entered = '';
            _error = '保存失败，请重试';
          });
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.verify
                  ? '输入当前密码'
                  : _first == null
                  ? '设置 6 位应用密码'
                  : '再次输入密码',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.verify ? '验证后可更改或关闭应用锁' : '请妥善保管密码，遗忘后无法找回',
              style: TextStyle(color: colors.mutedInk),
            ),
            const SizedBox(height: 20),
            AppPinPad(
              length: _entered.length,
              error: _error != null,
              onDigit: _digit,
              onDelete: () {
                if (_entered.isNotEmpty) {
                  setState(
                    () => _entered = _entered.substring(0, _entered.length - 1),
                  );
                }
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: colors.terracotta)),
            ],
          ],
        ),
      ),
    );
  }
}
