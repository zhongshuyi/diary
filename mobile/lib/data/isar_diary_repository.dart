export 'isar_diary_repository_native.dart'
    if (dart.library.html) 'isar_diary_repository_web.dart'
    if (dart.library.js_interop) 'isar_diary_repository_web.dart';
