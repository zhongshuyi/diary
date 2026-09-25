class DiaryPlace {
  const DiaryPlace({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.thumbnailPath,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? thumbnailPath;

  bool get isValid =>
      name.trim().isNotEmpty &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}
