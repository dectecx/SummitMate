class GearKeyRecord {
  final String key;
  final String title;
  final String visibility;
  final DateTime uploadedAt;

  GearKeyRecord({required this.key, required this.title, required this.visibility, required this.uploadedAt});

  String toStorageString() {
    return '$key|$title|$visibility|${uploadedAt.toIso8601String()}';
  }

  factory GearKeyRecord.fromStorageString(String str) {
    final parts = str.split('|');
    return GearKeyRecord(
      key: parts.isNotEmpty ? parts[0] : '',
      title: parts.length > 1 ? parts[1] : '',
      visibility: parts.length > 2 ? parts[2] : 'private',
      uploadedAt: parts.length > 3 ? DateTime.tryParse(parts[3]) ?? DateTime.now() : DateTime.now(),
    );
  }
}
