import '../core/constants.dart';

class CwaApiFactory {
  /// Determines the correct CWA Dataset ID based on the county name.
  /// Falls back to the global "All Townships" dataset if no specific county map is found.
  static String getTownshipForecastId(String countyName) {
    // 7-day forecast mapping
    if (CwaDataId.countyForecastIds.containsKey(countyName)) {
      return CwaDataId.countyForecastIds[countyName]!;
    }
    // Fallback to All Taiwan (F-D0047-093)
    return CwaDataId.townshipForecastAll;
  }

  /// Returns a list of possible JSON keys for a given weather element concept.
  /// This handles the variation between different CWA datasets (some use English keys, some Chinese).
  static List<String> getElementKeys(String concept) {
    switch (concept) {
      case 'Temperature':
        return ['T', '平均溫度'];
      case 'PoP':
        return ['PoP12h', '12小時降雨機率'];
      case 'Wx':
        return ['Wx', '天氣現象'];
      case 'MinT':
        return ['MinT', '最低溫度'];
      case 'MaxT':
        return ['MaxT', '最高溫度'];
      case 'RH':
        return ['RH', '平均相對濕度'];
      case 'WS':
        return ['WS', '風速'];
      case 'MaxAT':
        return ['MaxAT', '最高體感溫度'];
      case 'MinAT':
        return ['MinAT', '最低體感溫度'];
      default:
        return [concept];
    }
  }

  /// Returns the preferred key for extracting value from ElementValue map.
  static String getElementValueKey(String concept) {
    switch (concept) {
      case 'Temperature': return 'Temperature';
      case 'PoP': return 'ProbabilityOfPrecipitation';
      case 'Wx': return 'Weather';
      case 'MinT': return 'MinTemperature';
      case 'MaxT': return 'MaxTemperature';
      case 'RH': return 'RelativeHumidity';
      case 'WS': return 'WindSpeed';
      case 'MaxAT': return 'MaxApparentTemperature';
      case 'MinAT': return 'MinApparentTemperature';
      default: return 'value';
    }
  }
}
