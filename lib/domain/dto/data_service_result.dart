import '../../data/models/itinerary_item.dart';
import '../../data/models/message.dart';

/// 資料服務回傳的聚合資料
class DataServiceResult {
  final List<ItineraryItem> itinerary;
  final List<Message> messages;

  const DataServiceResult({this.itinerary = const [], this.messages = const []});
}
