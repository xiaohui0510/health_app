import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/find_hospital_place_info.dart';

class FindHospitalWebService {
  static final Dio dio = Dio();

  // Nearby Search API endpoint.
  static const String nearbySearchEndpoint =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  // Place Details API endpoint.
  static const String placeDetailsEndpoint =
      'https://maps.googleapis.com/maps/api/place/details/json';

  /// Retrieves nearby hospitals using the Places Nearby Search API.
  static Future<List<FindHospitalsPlaceInfo>> getNearestHospital(
      double latitude, double longitude, double? radius) async {
    List<FindHospitalsPlaceInfo> hospitals = [];
    log('Calling getNearestHospital with lat: $latitude, lng: $longitude, radius: $radius');

    final String apiKey = dotenv.env['GOOGLE_MAP_API_KEY'] ?? '';
    log('Using API Key: $apiKey');
    
    try {
      log('Sending request to $nearbySearchEndpoint with query parameters: { location: "$latitude,$longitude", radius: "${radius?.toString() ?? '5000'}", type: ["hospital", "emergency_hospital", "surgery_hospital"], key: "$apiKey" }');
      
      final response = await dio.get(
        nearbySearchEndpoint,
        queryParameters: {
          'location': '$latitude,$longitude',
          'radius': radius?.toString() ?? '5000',
          // You can send multiple types by joining them with a comma if needed.
          'type': 'hospital',
          'key': apiKey,
        },
      );
      log('Response status code: ${response.statusCode}');
      log('Response data: ${response.data}');

      if (response.data == null || response.data['results'] == null) {
        log('Response data is null or missing the results key.');
        return hospitals;
      }

      final List<dynamic> results = response.data['results'];
      log('Found ${results.length} results');

      for (var item in results) {
        hospitals.add(FindHospitalsPlaceInfo.fromJson(item));
      }
    } catch (err) {
      log('Error in getNearestHospital: $err');
      return hospitals;
    }

    return hospitals;
  }

  /// Retrieves detailed information about a place using the Place Details API.
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final String apiKey = dotenv.env['GOOGLE_MAP_API_KEY'] ?? '';
    try {
      final response = await dio.get(
        placeDetailsEndpoint,
        queryParameters: {
          'place_id': placeId,
          'fields': 'name,formatted_phone_number,international_phone_number,website,opening_hours,formatted_address,adr_address,review,rating,user_ratings_total',
          'key': apiKey,
        },
      );
      log('Place details response: ${response.data}');
      if (response.data == null || response.data['result'] == null) {
        return null;
      }
      return response.data['result'];
    } catch (e) {
      log('Error in getPlaceDetails: $e');
      return null;
    }
  }
}
