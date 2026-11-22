import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/events_api.dart';

final eventsApiProvider = Provider<EventsApi>((ref) => DioEventsApi(ref.watch(authedDioProvider)));
