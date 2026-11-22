/// Metadata of one remote Rudy Map file, taken from a HEAD response.
class RudyRemoteFile {
  const RudyRemoteFile({
    required this.name,
    required this.resolvedUrl,
    this.contentLength,
    this.lastModified,
    this.acceptsRanges = false,
  });

  final String name;

  /// Final mirror URL after redirects (use it directly when resuming).
  final Uri resolvedUrl;
  final int? contentLength;
  final String? lastModified;
  final bool acceptsRanges;

  /// ETags differ between mirrors, so use Last-Modified + length + host.
  String get fingerprint => '${lastModified ?? ''}|${contentLength ?? ''}|${resolvedUrl.host}';
}

enum RudyAvailability { available, notAvailable, unreachable }

class RudyProbe {
  const RudyProbe(this.availability, [this.file]);

  final RudyAvailability availability;

  /// Non-null only when [availability] is [RudyAvailability.available].
  final RudyRemoteFile? file;
}
