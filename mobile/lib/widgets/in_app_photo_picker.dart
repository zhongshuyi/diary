import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:diary/app/app_theme.dart';

enum DiaryPhotoSource { gallery, camera }

/// Uses the same choices wherever the app needs a single image: the in-app
/// album grid for existing photos and the platform camera for a fresh one.
Future<DiaryPhotoSource?> chooseDiaryPhotoSource(
  BuildContext context, {
  String title = '添加图片',
}) {
  return showModalBottomSheet<DiaryPhotoSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text(title)),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('从相册选择'),
            onTap: () => Navigator.pop(sheetContext, DiaryPhotoSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('拍照'),
            onTap: () => Navigator.pop(sheetContext, DiaryPhotoSource.camera),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<List<String>> pickDiaryPhotoSource(
  BuildContext context, {
  required DiaryPhotoSource source,
  int maxAssets = 9,
}) async {
  if (source == DiaryPhotoSource.gallery) {
    return pickDiaryPhotos(context, maxAssets: maxAssets);
  }
  final photo = await ImagePicker().pickImage(
    source: ImageSource.camera,
    imageQuality: 92,
  );
  return photo == null ? const [] : [photo.path];
}

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
