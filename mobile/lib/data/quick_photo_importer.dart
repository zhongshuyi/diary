import 'quick_photo_importer_stub.dart'
    if (dart.library.io) 'quick_photo_importer_io.dart'
    as platform;

Future<List<String>> importQuickPhotos(List<String> paths) =>
    platform.importQuickPhotos(paths);
