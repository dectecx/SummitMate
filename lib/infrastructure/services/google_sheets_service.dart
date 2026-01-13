import 'package:dio/dio.dart';
import '../clients/network_aware_client.dart';
import '../clients/gas_api_client.dart';
import '../../core/constants.dart';
import '../../core/di.dart';
import '../../core/error/result.dart';
import '../../data/models/itinerary_item.dart';
import '../../domain/dto/data_service_result.dart';
import '../../data/models/message.dart';
import '../../data/models/trip.dart';
import '../tools/log_service.dart';
import '../../domain/interfaces/i_data_service.dart';

/// Google Sheets API 服務
/// 透過 Google Apps Script 作為 API Gateway
class GoogleSheetsService implements IDataService {
  final NetworkAwareClient _apiClient;

  /// 建構子
  GoogleSheetsService({NetworkAwareClient? apiClient}) : _apiClient = apiClient ?? getIt<NetworkAwareClient>();

  /// 取得所有資料 (行程 + 留言)
  @override
  Future<Result<DataServiceResult, Exception>> getAll({String? tripId}) async {
    try {
      LogService.info('API 請求: FetchAll${tripId != null ? " (tripId: $tripId)" : ""}', source: 'API');

      final queryParams = <String, String>{'action': ApiConfig.actionTripGetFull};
      if (tripId != null) {
        queryParams['trip_id'] = tripId;
      }

      final response = await _apiClient.get(queryParams: queryParams);
      LogService.debug('API 回應: ${response.statusCode}', source: 'API');

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

        if (!gasResponse.isSuccess) {
          return Failure(GeneralException(gasResponse.message));
        }

        final itineraryList =
            (gasResponse.data['itinerary'] as List<dynamic>?)
                ?.map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        final messagesList =
            (gasResponse.data['messages'] as List<dynamic>?)
                ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        LogService.debug('解析成功: 行程=${itineraryList.length}, 留言=${messagesList.length}', source: 'API');

        return Success(DataServiceResult(itinerary: itineraryList, messages: messagesList));
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}: ${response.statusMessage}'));
      }
    } catch (e) {
      LogService.error('API 異常: $e', source: 'API');
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 僅取得行程資料
  ///
  /// [tripId] 行程 ID (可選，若無則取得所有行程)
  @override
  Future<Result<List<ItineraryItem>, Exception>> getItinerary({String? tripId}) async {
    try {
      LogService.info('API 請求: FetchItinerary${tripId != null ? " (tripId: $tripId)" : ""}', source: 'API');

      final queryParams = <String, String>{'action': ApiConfig.actionItineraryList};
      if (tripId != null) {
        queryParams['trip_id'] = tripId;
      }

      final response = await _apiClient.get(queryParams: queryParams);

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

        if (!gasResponse.isSuccess) {
          return Failure(GeneralException(gasResponse.message));
        }

        final itineraryList =
            (gasResponse.data['itinerary'] as List<dynamic>?)
                ?.map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return Success(itineraryList);
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 僅取得留言資料
  ///
  /// [tripId] 行程 ID (可選)
  @override
  Future<Result<List<Message>, Exception>> getMessages({String? tripId}) async {
    try {
      LogService.info('API 請求: FetchMessages${tripId != null ? " (tripId: $tripId)" : ""}', source: 'API');

      final queryParams = <String, String>{'action': ApiConfig.actionMessageList};
      if (tripId != null) {
        queryParams['trip_id'] = tripId;
      }

      final response = await _apiClient.get(queryParams: queryParams);

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);

        if (!gasResponse.isSuccess) {
          return Failure(GeneralException(gasResponse.message));
        }

        final messagesList =
            (gasResponse.data['messages'] as List<dynamic>?)
                ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return Success(messagesList);
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 新增留言
  ///
  /// [message] 留言物件
  @override
  Future<Result<void, Exception>> addMessage(Message message) async {
    try {
      final response = await _apiClient.post({'action': ApiConfig.actionMessageCreate, 'data': message.toJson()});
      return _handleResponse(response);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 刪除留言
  ///
  /// [uuid] 留言 UUID
  @override
  Future<Result<void, Exception>> deleteMessage(String id) async {
    try {
      final response = await _apiClient.post({'action': ApiConfig.actionMessageDelete, 'id': id});
      return _handleResponse(response);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 批次新增留言
  ///
  /// [messages] 留言列表
  @override
  Future<Result<void, Exception>> batchAddMessages(List<Message> messages) async {
    try {
      final response = await _apiClient.post({
        'action': ApiConfig.actionMessageCreateBatch,
        'data': messages.map((m) => m.toJson()).toList(),
      });
      return _handleResponse(response);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 更新行程 (覆寫雲端)
  ///
  /// [items] 行程列表
  @override
  Future<Result<void, Exception>> updateItinerary(List<ItineraryItem> items) async {
    try {
      final response = await _apiClient.post({
        'action': ApiConfig.actionItineraryUpdate,
        'data': items.map((e) {
          final json = e.toJson();
          // Force est_time to be string in Google Sheets by prepending '
          if (e.estTime.isNotEmpty) {
            json['est_time'] = "'${e.estTime}";
          }
          return json;
        }).toList(),
      });
      return _handleResponse(response);
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 取得雲端行程列表
  @override
  Future<Result<List<Trip>, Exception>> getTrips() async {
    try {
      LogService.info('API 請求: FetchTrips', source: 'API');
      final response = await _apiClient.get(queryParams: {'action': ApiConfig.actionTripList});

      if (response.statusCode == 200) {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
        if (!gasResponse.isSuccess) {
          return Failure(GeneralException(gasResponse.message));
        }

        final trips =
            (gasResponse.data['trips'] as List<dynamic>?)
                ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        return Success(trips);
      } else {
        return Failure(GeneralException('HTTP ${response.statusCode}'));
      }
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 上傳日誌
  ///
  /// [logs] 日誌列表
  /// [deviceName] 裝置名稱 (可選)
  @override
  Future<Result<String, Exception>> uploadLogs(List<LogEntry> logs, {String? deviceName}) async {
    try {
      final response = await _apiClient.post({
        'action': ApiConfig.actionLogUpload,
        'logs': logs.map((e) => e.toJson()).toList(),
        'device_info': {
          'device_id': DateTime.now().millisecondsSinceEpoch.toString(),
          'device_name': deviceName ?? 'SummitMate App',
        },
      });

      // 解析 GAS 回傳的計數
      if (response.statusCode == 200) {
        try {
          final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
          if (gasResponse.isSuccess) {
            final countMsg = gasResponse.data['count'] != null
                ? '已上傳 ${gasResponse.data['count']} 條日誌'
                : gasResponse.message;
            return Success(countMsg);
          } else {
            return Failure(GeneralException(gasResponse.message));
          }
        } catch (_) {
          // If parsing fails but status 200, assume success? Or fallback
        }
      }
      final result = _handleResponse(response);
      return switch (result) {
        Success() => const Success('上傳成功'),
        Failure(exception: final e) => Failure(e),
      };
    } catch (e) {
      return Failure(e is Exception ? e : GeneralException(e.toString()));
    }
  }

  /// 統一處理回應
  Result<void, Exception> _handleResponse(Response response) {
    if (response.statusCode == 200) {
      try {
        final gasResponse = GasApiResponse.fromJson(response.data as Map<String, dynamic>);
        if (gasResponse.isSuccess) {
          return const Success(null);
        } else {
          return Failure(GeneralException(gasResponse.message));
        }
      } catch (_) {
        return const Success(null);
      }
    } else {
      return Failure(GeneralException('HTTP ${response.statusCode}: ${response.statusMessage}'));
    }
  }
}
