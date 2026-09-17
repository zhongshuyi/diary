import 'mobile_attachment_store.dart';

Future<List<String>> importQuickPhotos(List<String> paths) async {
  final store = MobileAttachmentStore();
  final imported = <String>[];
  for (final path in paths) {
    final attachment = await store.importFile(path);
    imported.add(attachment.localPath!);
  }
  return imported;
}
