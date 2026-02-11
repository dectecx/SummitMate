/// CWA 開放資料平台相關常數
/// Data IDs and API configurations
class CwaConstants {
  /// 鄉鎮天氣預報-全臺灣各鄉鎮市區預報資料
  static const String townshipForecastAll = 'F-D0047-093';

  // 宜蘭縣
  static const String townshipForecastYilan3Day = 'F-D0047-001';
  static const String townshipForecastYilan7Day = 'F-D0047-003';

  // 桃園市
  static const String townshipForecastTaoyuan3Day = 'F-D0047-005';
  static const String townshipForecastTaoyuan7Day = 'F-D0047-007';

  // 新竹縣
  static const String townshipForecastHsinchuCounty3Day = 'F-D0047-009';
  static const String townshipForecastHsinchuCounty7Day = 'F-D0047-011';

  // 苗栗縣
  static const String townshipForecastMiaoli3Day = 'F-D0047-013';
  static const String townshipForecastMiaoli7Day = 'F-D0047-015';

  // 彰化縣
  static const String townshipForecastChanghua3Day = 'F-D0047-017';
  static const String townshipForecastChanghua7Day = 'F-D0047-019';

  // 南投縣
  static const String townshipForecastNantou3Day = 'F-D0047-021';
  static const String townshipForecastNantou7Day = 'F-D0047-023';

  // 雲林縣
  static const String townshipForecastYunlin3Day = 'F-D0047-025';
  static const String townshipForecastYunlin7Day = 'F-D0047-027';

  // 嘉義縣
  static const String townshipForecastChiayiCounty3Day = 'F-D0047-029';
  static const String townshipForecastChiayiCounty7Day = 'F-D0047-031';

  // 屏東縣
  static const String townshipForecastPingtung3Day = 'F-D0047-033';
  static const String townshipForecastPingtung7Day = 'F-D0047-035';

  // 臺東縣
  static const String townshipForecastTaitung3Day = 'F-D0047-037';
  static const String townshipForecastTaitung7Day = 'F-D0047-039';

  // 花蓮縣
  static const String townshipForecastHualien3Day = 'F-D0047-041';
  static const String townshipForecastHualien7Day = 'F-D0047-043';

  // 澎湖縣
  static const String townshipForecastPenghu3Day = 'F-D0047-045';
  static const String townshipForecastPenghu7Day = 'F-D0047-047';

  // 基隆市
  static const String townshipForecastKeelung3Day = 'F-D0047-049';
  static const String townshipForecastKeelung7Day = 'F-D0047-051';

  // 新竹市
  static const String townshipForecastHsinchuCity3Day = 'F-D0047-053';
  static const String townshipForecastHsinchuCity7Day = 'F-D0047-055';

  // 嘉義市
  static const String townshipForecastChiayiCity3Day = 'F-D0047-057';
  static const String townshipForecastChiayiCity7Day = 'F-D0047-059';

  // 臺北市
  static const String townshipForecastTaipei3Day = 'F-D0047-061';
  static const String townshipForecastTaipei7Day = 'F-D0047-063';

  // 高雄市
  static const String townshipForecastKaohsiung3Day = 'F-D0047-065';
  static const String townshipForecastKaohsiung7Day = 'F-D0047-067';

  // 新北市
  static const String townshipForecastNewTaipei3Day = 'F-D0047-069';
  static const String townshipForecastNewTaipei7Day = 'F-D0047-071';

  // 臺中市
  static const String townshipForecastTaichung3Day = 'F-D0047-073';
  static const String townshipForecastTaichung7Day = 'F-D0047-075';

  // 臺南市
  static const String townshipForecastTainan3Day = 'F-D0047-077';
  static const String townshipForecastTainan7Day = 'F-D0047-079';

  // 連江縣
  static const String townshipForecastLienchiang3Day = 'F-D0047-081';
  static const String townshipForecastLienchiang7Day = 'F-D0047-083';

  // 金門縣
  static const String townshipForecastKinmen3Day = 'F-D0047-085';
  static const String townshipForecastKinmen7Day = 'F-D0047-087';

  // 臺灣 (Global)
  static const String townshipForecastTaiwan3Day = 'F-D0047-089';
  static const String townshipForecastTaiwan7Day = 'F-D0047-091';

  /// 育樂天氣預報資料-登山一週日夜天氣預報
  static const String hikingForecast = 'F-B0053-031';

  /// 縣市鄉鎮預報 ID 對照表 (1週預報)
  static const Map<String, String> countyForecastIds = {
    '宜蘭縣': townshipForecastYilan7Day,
    '桃園市': townshipForecastTaoyuan7Day,
    '新竹縣': townshipForecastHsinchuCounty7Day,
    '苗栗縣': townshipForecastMiaoli7Day,
    '彰化縣': townshipForecastChanghua7Day,
    '南投縣': townshipForecastNantou7Day,
    '雲林縣': townshipForecastYunlin7Day,
    '嘉義縣': townshipForecastChiayiCounty7Day,
    '屏東縣': townshipForecastPingtung7Day,
    '臺東縣': townshipForecastTaitung7Day,
    '花蓮縣': townshipForecastHualien7Day,
    '澎湖縣': townshipForecastPenghu7Day,
    '基隆市': townshipForecastKeelung7Day,
    '新竹市': townshipForecastHsinchuCity7Day,
    '嘉義市': townshipForecastChiayiCity7Day,
    '臺北市': townshipForecastTaipei7Day,
    '高雄市': townshipForecastKaohsiung7Day,
    '新北市': townshipForecastNewTaipei7Day,
    '臺中市': townshipForecastTaichung7Day,
    '臺南市': townshipForecastTainan7Day,
    '連江縣': townshipForecastLienchiang7Day,
    '金門縣': townshipForecastKinmen7Day,
  };
}
