/// 開發者工具服務介面
///
/// 封裝 Debug 工具所需的本地資料維護操作（清除資料、資料表檢視），
/// 讓 Presentation 層不需直接依賴 infrastructure 的 AppDatabase 或 drift 套件。
abstract interface class IDevToolsService {
  /// 選擇性清除本地資料
  ///
  /// 各參數對應一組資料表，為 true 時清除該組資料。
  Future<void> clearSelectedData({
    bool trips = false,
    bool messages = false,
    bool gear = false,
    bool gearLibrary = false,
    bool polls = false,
    bool groupEvents = false,
    bool favorites = false,
    bool logs = false,
    bool settings = false,
    bool weather = false,
  });

  /// 取得所有本地資料表名稱
  Future<List<String>> getTableNames();

  /// 取得指定資料表的內容
  ///
  /// [tableName] 資料表名稱（必須是 [getTableNames] 回傳的有效名稱）
  /// [limit] 最多回傳的列數
  Future<List<Map<String, dynamic>>> getTableData(String tableName, {int limit = 100});
}
