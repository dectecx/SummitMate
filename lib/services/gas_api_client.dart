import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'log_service.dart';

/// Client related to Google Apps Script API calls
/// Handles common logic like Redirects (302), Web compatibility, etc.
class GasApiClient {
  static const String _source = 'GasApiClient';

  final http.Client _client;
  final String _baseUrl;

  GasApiClient({http.Client? client, required String baseUrl}) : _client = client ?? http.Client(), _baseUrl = baseUrl;

  /// GET request
  Future<http.Response> get({Map<String, String>? queryParams}) async {
    try {
      Uri uri = Uri.parse(_baseUrl);
      if (queryParams != null && queryParams.isNotEmpty) {
        // Merge existing params with new ones
        final newParams = Map<String, String>.from(uri.queryParameters);
        newParams.addAll(queryParams);
        uri = uri.replace(queryParameters: newParams);
      }

      LogService.debug('GET $uri', source: _source);
      final response = await _client.get(uri);
      return response;
    } catch (e) {
      LogService.error('GET error: $e', source: _source);
      rethrow;
    }
  }

  /// POST request with automated redirect handling
  Future<http.Response> post(Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse(_baseUrl);
      // [Web Compatibility]
      // Web: Use text/plain to avoid CORS Preflight (OPTIONS) which GAS doesn't support.
      // GAS parses e.postData.contents regardless of Content-Type.
      final headers = {'Content-Type': kIsWeb ? 'text/plain' : 'application/json'};

      // Log simple info to avoid leaking too much data, or debug full body
      LogService.debug('POST $_baseUrl action=${body['action']}', source: _source);

      final response = await _client.post(uri, headers: headers, body: jsonEncode(body));

      // [Web Compatibility]
      // Web: Browser follows redirects automatically.
      if (kIsWeb) {
        return response;
      }

      // [Mobile Compatibility]
      // 1. Standard 302 Redirect
      if (response.statusCode == 302) {
        final location = response.headers['location'];
        if (location != null && location.isNotEmpty) {
          LogService.debug('Following 302 redirect: $location', source: _source);
          return await _client.get(Uri.parse(location));
        }
      }

      // 2. HTML Body Redirect (Common in GAS)
      // Sometimes GAS returns 200 OK (or other) but with HTML body containing redirect
      if (response.body.contains('<HTML>') && (response.body.contains('HREF=') || response.body.contains('href='))) {
        // Using case-insensitive regex for robustness
        final hrefMatch = RegExp(r'HREF="([^"]+)"', caseSensitive: false).firstMatch(response.body);
        if (hrefMatch != null) {
          final redirectUrl = hrefMatch.group(1)!.replaceAll('&amp;', '&');
          LogService.debug('Following HTML redirect: $redirectUrl', source: _source);
          return await _client.get(Uri.parse(redirectUrl));
        }
      }

      return response;
    } catch (e) {
      LogService.error('POST error: $e', source: _source);
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
