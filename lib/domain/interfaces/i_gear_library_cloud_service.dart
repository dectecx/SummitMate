import '../../data/models/gear_library_item.dart';

/// 裝備庫雲端操作結果
class GearLibraryCloudResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  const GearLibraryCloudResult._({required this.isSuccess, this.data, this.errorMessage});

  factory GearLibraryCloudResult.success(T data) => GearLibraryCloudResult._(isSuccess: true, data: data);
  factory GearLibraryCloudResult.failure(String message) =>
      GearLibraryCloudResult._(isSuccess: false, errorMessage: message);
}

/// 個人裝備庫雲端服務介面
/// 負責使用者個人裝備庫的雲端同步
abstract interface class IGearLibraryCloudService {
  /// 同步個人裝備庫 (上傳全部)
  Future<GearLibraryCloudResult<int>> syncLibrary(List<GearLibraryItem> items);

  /// 取得雲端個人裝備庫
  Future<GearLibraryCloudResult<List<GearLibraryItem>>> getLibrary();
}
