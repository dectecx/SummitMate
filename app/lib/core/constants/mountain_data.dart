import 'package:summitmate/domain/domain.dart';

/// 山岳資料
class MountainData {
  static const MountainLocation jiamingLake = MountainLocation(
    id: 'jiaming_lake',
    name: '三叉山 (嘉明湖)',
    altitude: 3496,
    region: MountainRegion.south,
    category: MountainCategory.baiyue,
    introduction:
        '三叉山位於臺灣臺東縣海端鄉利稻村、花蓮縣卓溪鄉古風村與高雄市桃源區梅山里之間，為台灣知名山峰，也是台灣百岳之一，排名第27。三叉山3,496公尺，屬於中央山脈。三叉山南方有向陽山，北邊連接雲峰。三叉山具特色為山頂平緩，全是淺竹，視野良好。',
    features: '嘉明湖位於三叉山東南側，海拔約3310公尺，是台灣第二高的高山湖泊。湖面呈橢圓形，湖水為湛藍色，有「天使的眼淚」之稱。三叉山山頂展望廣闊，可眺望玉山、秀姑巒山等名山。',
    trailheads: ['向陽登山口'],
    mapRef: '上河文化 M22 丹大‧東郡橫斷',
    jurisdiction: '林務局臺東林區管理處',
    isBeginnerFriendly: false,
    cwaPid: 'D055',
    windyParams: '23.293/121.034?23.284,121.034,14',
    links: [
      MountainLink(type: LinkType.permit, title: '申請入山證', url: 'https://hike.taiwan.gov.tw/'),
      MountainLink(type: LinkType.cabin, title: '山屋預約申請', url: 'https://jmlnt.forest.gov.tw/room/'),
      MountainLink(
        type: LinkType.trail,
        title: '台灣山林悠遊網 (官網)',
        url: 'https://recreation.forest.gov.tw/Trail/RT?tr_id=139',
      ),
      MountainLink(
        type: LinkType.gpx,
        title: 'GPX 軌跡檔下載 (健行筆記)',
        url: 'https://hiking.biji.co/index.php?q=trail&act=gpx_list&city=全部&keyword=嘉明湖國家步道',
      ),
      MountainLink(
        type: LinkType.gearPdf,
        title: '官方建議裝備清單',
        url:
            'https://recreation.forest.gov.tw/Files/RT/UploadFiles/Package/139_%E5%98%89%E6%98%8E%E6%B9%96%E5%9C%8B%E5%AE%B6%E6%AD%A5%E9%81%93_%E5%A4%9A%E6%97%A5%E7%99%BB%E5%B1%B1%E5%9E%8B%E6%AD%A5%E9%81%93%E5%BB%BA%E8%AD%B0%E8%A3%9D%E5%82%99%E6%B8%85%E5%96%AE.pdf',
      ),
      MountainLink(
        type: LinkType.accommodation,
        title: '鋤禾日好-站前館 (住宿)',
        url: 'https://www.booking.com/hotel/tw/farming-hostel.zh-tw.html',
      ),
    ],
  );

  static const MountainLocation jadeMountain = MountainLocation(
    id: 'jade_mountain',
    name: '玉山主峰',
    altitude: 3952,
    region: MountainRegion.central,
    category: MountainCategory.baiyue,
    introduction: '玉山主峰海拔3952公尺，為台灣第一高峰，也是東北亞最高峰。玉山山容氣勢磅礡，四季景致變化萬千，是台灣登山客心目中的聖山。',
    features: '玉山群峰氣勢磅礡，主峰視野遼闊，可俯瞰全台。冬季雪景壯麗，有「玉山積雪」之稱。生態資源豐富，植被隨海拔變化明顯。',
    trailheads: ['塔塔加登山口'],
    mapRef: '上河文化 M19 玉山群峰',
    jurisdiction: '玉山國家公園',
    isBeginnerFriendly: true,
    cwaPid: 'D033', // 玉山
    windyParams: '23.470/120.957?23.470,120.957,14',
    links: [
      MountainLink(type: LinkType.permit, title: '入園入山申請', url: 'https://npm.cpami.gov.tw/'),
      MountainLink(type: LinkType.cabin, title: '排雲山莊抽籤', url: 'https://npm.cpami.gov.tw/bed_1.aspx'),
    ],
  );

  static const MountainLocation snowMountain = MountainLocation(
    id: 'snow_mountain',
    name: '雪山主峰',
    altitude: 3886,
    region: MountainRegion.central,
    category: MountainCategory.baiyue,
    introduction: '雪山主峰海拔3886公尺，為台灣第二高峰。雪山圈谷為台灣目前發現最完整的冰斗地形，景色壯麗。雪山主東峰路線是熱門的百岳路線。',
    features: '雪山圈谷冰河地形完整，景色壯觀。黑森林冷杉純林蒼鬱挺拔。高山杜鵑花季美不勝收。',
    trailheads: ['雪山登山口 (武陵農場)'],
    mapRef: '上河文化 M06 雪山聖稜線',
    jurisdiction: '雪霸國家公園',
    isBeginnerFriendly: true,
    cwaPid: 'D003', // 雪山
    windyParams: '24.383/121.234?24.383,121.234,14',
    links: [
      MountainLink(type: LinkType.permit, title: '入園申請', url: 'https://npm.cpami.gov.tw/'),
      MountainLink(type: LinkType.cabin, title: '三六九山莊/七卡山莊', url: 'https://npm.cpami.gov.tw/bed_1.aspx'),
    ],
  );

  static const List<MountainLocation> all = [jiamingLake, jadeMountain, snowMountain];
}
