import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:diary/app/app_theme.dart';

/// Opens an in-app album grid, then hands temporary source paths to the caller.
/// The caller must import the files before storing them in an entry or draft.
Future<List<String>> pickDiaryPhotos(
  BuildContext context, {
  int maxAssets = 9,
}) async {
  final selected = await AssetPicker.pickAssets(
    context,
    pickerConfig: AssetPickerConfig(
      requestType: RequestType.image,
      maxAssets: maxAssets,
      themeColor: DiaryThemeColors.of(context).terracotta,
      pathNameBuilder: (path) => path.isAll ? '最近照片' : path.name,
    ),
  );
  if (selected == null || selected.isEmpty) return const [];

  final paths = <String>[];
  for (final asset in selected) {
    final file = await asset.file;
    if (file == null) {
      throw StateError('无法读取选中的照片');
    }
    paths.add(file.path);
  }
  return paths;
}
