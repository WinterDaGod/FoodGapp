import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'api_exceptions.dart';

class UsdaService {
  static const _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  final _apiKey = ApiConfig.usdaApiKey;
  final http.Client _client;

  UsdaService({http.Client? client}) : _client = client ?? http.Client();

  /// Searches for foods in the USDA database.
  Future<List<Map<String, dynamic>>> searchFoods(String query) async {
    final uri = Uri.parse('$_baseUrl/foods/search').replace(queryParameters: {
      'api_key': _apiKey,
      'query': query,
      'pageSize': '15',
      'dataType': 'Foundation,SR Legacy,Branded',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw ApiUnavailableException('USDA API returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['foods'] ?? []);
  }

  /// Fetches detailed nutrition for a specific food by its FDC ID.
  Future<Map<String, dynamic>> getFoodDetails(int fdcId) async {
    final uri = Uri.parse('$_baseUrl/food/$fdcId').replace(queryParameters: {
      'api_key': _apiKey,
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw ApiUnavailableException('USDA API detail fetch failed');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void dispose() => _client.close();
}
