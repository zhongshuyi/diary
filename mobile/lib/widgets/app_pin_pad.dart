import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/app_lock_service.dart';

class AppPinPad extends StatelessWidget {
  const AppPinPad({
    required this.length,
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
    this.biometricBusy = false,
    this.error = false,
    super.key,
  });

  final int length;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;
  final bool biometricBusy;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(AppLockService.pinLength, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: error
                    ? colors.terracotta
                    : index < length
                    ? colors.ink
                    : colors.line,
              ),
            );
          }),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 288),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              for (final digit in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                _digit(context, digit, colors),
              if (onBiometric == null)
                const SizedBox.shrink()
              else
                IconButton(
                  tooltip: '使用指纹解锁',
                  onPressed: biometricBusy ? null : onBiometric,
                  icon: const Icon(Icons.fingerprint_rounded, size: 30),
                ),
              _digit(context, '0', colors),
              IconButton(
                tooltip: '删除一位',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onDelete();
                },
                icon: const Icon(Icons.backspace_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _digit(BuildContext context, String digit, DiaryThemeColors colors) {
    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        key: Key('pin-digit-$digit'),
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onDigit(digit);
        },
        child: Center(
          child: Text(digit, style: Theme.of(context).textTheme.headlineSmall),
        ),
      ),
    );
  }
}
