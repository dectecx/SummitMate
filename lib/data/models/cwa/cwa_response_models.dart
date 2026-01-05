import 'dart:convert';

/// Root Response
class CwaApiResponse {
  final String success;
  final CwaRecords records;

  CwaApiResponse({required this.success, required this.records});

  factory CwaApiResponse.fromJson(Map<String, dynamic> json) {
    return CwaApiResponse(
      success: json['success'] ?? 'false',
      records: CwaRecords.fromJson(json['records'] ?? {}),
    );
  }
}

/// Records Wrapper
class CwaRecords {
  final List<CwaLocations> locationsList;

  CwaRecords({required this.locationsList});

  factory CwaRecords.fromJson(Map<String, dynamic> json) {
    // Handle "Locations" vs "locations"
    final list = json['Locations'] ?? json['locations'] ?? [];
    return CwaRecords(
      locationsList: (list as List).map((e) => CwaLocations.fromJson(e)).toList(),
    );
  }
}

/// Locations Group (Usually contains DatasetDescription + List of Location)
class CwaLocations {
  final String datasetDescription;
  final String locationsName;
  final List<CwaLocation> location;

  CwaLocations({
    required this.datasetDescription,
    required this.locationsName,
    required this.location,
  });

  factory CwaLocations.fromJson(Map<String, dynamic> json) {
    // Handle "Location" vs "location"
    final locList = json['Location'] ?? json['location'] ?? [];
    return CwaLocations(
      datasetDescription: json['DatasetDescription'] ?? '',
      locationsName: json['LocationsName'] ?? '',
      location: (locList as List).map((e) => CwaLocation.fromJson(e)).toList(),
    );
  }
}

/// Individual Location (e.g. "Xinyi District")
class CwaLocation {
  final String locationName;
  final List<CwaWeatherElement> weatherElement;

  CwaLocation({required this.locationName, required this.weatherElement});

  factory CwaLocation.fromJson(Map<String, dynamic> json) {
    // Handle "LocationName" vs "locationName"
    final name = json['LocationName'] ?? json['locationName'] ?? '';
    // Handle "WeatherElement" vs "weatherElement"
    final elements = json['WeatherElement'] ?? json['weatherElement'] ?? [];
    return CwaLocation(
      locationName: name,
      weatherElement: (elements as List).map((e) => CwaWeatherElement.fromJson(e)).toList(),
    );
  }
}

/// Weather Element (e.g. Temperature series)
class CwaWeatherElement {
  final String elementName;
  final List<CwaTime> time;

  CwaWeatherElement({required this.elementName, required this.time});

  factory CwaWeatherElement.fromJson(Map<String, dynamic> json) {
    // Handle "ElementName" vs "elementName"
    final name = json['ElementName'] ?? json['elementName'] ?? '';
    // Handle "Time" vs "time"
    final t = json['Time'] ?? json['time'] ?? [];
    return CwaWeatherElement(
      elementName: name,
      time: (t as List).map((e) => CwaTime.fromJson(e)).toList(),
    );
  }
}

/// Time Entry (Start, End, Value)
class CwaTime {
  final DateTime startTime;
  final DateTime? endTime;
  final List<Map<String, dynamic>> elementValue;

  CwaTime({required this.startTime, this.endTime, required this.elementValue});

  factory CwaTime.fromJson(Map<String, dynamic> json) {
    final start = json['StartTime'] ?? json['startTime'];
    final end = json['EndTime'] ?? json['endTime'];
    final vals = json['ElementValue'] ?? json['elementValue'] ?? [];

    return CwaTime(
      startTime: DateTime.parse(start),
      endTime: end != null ? DateTime.parse(end) : null,
      elementValue: List<Map<String, dynamic>>.from(vals),
    );
  }

  /// Helper to get the value string for a specific key preference
  /// e.g. getValue(['Temperature', 'value'])
  String getValue(List<String> keyPreferences) {
    if (elementValue.isEmpty) return '';
    final first = elementValue[0];
    
    for (final key in keyPreferences) {
      if (first.containsKey(key)) {
        return first[key].toString();
      }
    }
    // Fallback: return first value if keys don't match (for simple 'value' case)
    if (first.isNotEmpty) {
       // but maybe it's not what we want. Safer to return empty if not found?
       // Let's stick to key preference.
       // Check if 'value' exists as implicit fallback
       if (first.containsKey('value')) return first['value'].toString();
    }
    return '';
  }
}
