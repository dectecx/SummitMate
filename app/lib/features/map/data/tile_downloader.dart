import '../domain/offline_regions.dart';

/// Progress of one region download.
class DownloadUpdate {
  const DownloadUpdate({required this.done, required this.total, required this.bytes});
  final int done;
  final int total;
  final double bytes;
}

/// Downloads the tiles of a region into the tile cache. Separated from the manager so the queue and
/// state logic can be tested without the native tile cache.
abstract interface class TileDownloader {
  /// Emits progress and completes when every tile was handled. Emits an error when the download fails
  /// as a whole. Cancelling (see [cancel]) just ends the stream.
  Stream<DownloadUpdate> download(OfflineRegionDef region);

  /// Stops a running download. The tiles already stored stay until [deleteTiles].
  Future<void> cancel(String regionId);

  /// Removes the tiles that belong only to this region (tiles shared with another region stay).
  Future<void> deleteTiles(String regionId);
}
