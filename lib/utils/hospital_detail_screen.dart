import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/find_hospital_place_info.dart';
import '../utils/find_hospital_webservice.dart';

class HospitalDetailScreen extends StatelessWidget {
  final FindHospitalsPlaceInfo hospital;
  final double currentLat;
  final double currentLng;
  final void Function(double lat, double lng) onNavigate;

  const HospitalDetailScreen({
    Key? key,
    required this.hospital,
    required this.currentLat,
    required this.currentLng,
    required this.onNavigate,
  }) : super(key: key);

  /// Computes the distance from the current location to the hospital in kilometers.
  String _computeDistance() {
    double distance = Geolocator.distanceBetween(currentLat, currentLng, hospital.lat, hospital.lng);
    return (distance / 1000).toStringAsFixed(2) + " km";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(hospital.name),
        actions: [
          TextButton(
            onPressed: () => onNavigate(hospital.lat, hospital.lng),
            child: const Text(
              "GO",
              style: TextStyle(color: Colors.green, fontSize: 16),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: FindHospitalWebService.getPlaceDetails(hospital.placeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching details: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No details available.'));
          } else {
            final details = snapshot.data!;
            String distanceStr = _computeDistance();
            String ratingStr = (details['rating'] != null)
                ? "Rating: ${details['rating'].toStringAsFixed(1)} (${details['user_ratings_total'] ?? 0} reviews)"
                : "No rating";
            
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hospital image.
                    Builder(builder: (context) {
                      String? imageUrl;
                      if (hospital.photos != null && hospital.photos!.isNotEmpty) {
                        final photoRef = hospital.photos![0]['photo_reference'];
                        if (photoRef is String && photoRef.isNotEmpty) {
                          final apiKey = dotenv.env['GOOGLE_MAP_API_KEY'] ?? '';
                          imageUrl =
                              'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=$apiKey';
                        }
                      }
                      if (imageUrl != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        );
                      } else {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey,
                          child: const Icon(Icons.local_hospital, color: Colors.white, size: 100),
                        );
                      }
                    }),
                    const SizedBox(height: 16),
                    Text(
                      details['name'] ?? hospital.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(ratingStr, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 16),
                        Text("Distance: $distanceStr", style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Address.
                    const Text(
                      "Address:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      details['formatted_address'] ?? hospital.vicinity ?? "Not available",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    // Phone number.
                    const Text(
                      "Phone:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      details['formatted_phone_number'] ?? "Not available",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    // Website.
                    const Text(
                      "Website:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      details['website'] ?? "Not available",
                      style: const TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                    const SizedBox(height: 16),
                    // Opening Hours.
                    const Text(
                      "Opening Hours:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Builder(builder: (context) {
                      if (details['opening_hours'] != null &&
                          details['opening_hours']['weekday_text'] != null) {
                        List<dynamic> weekdayText = details['opening_hours']['weekday_text'];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: weekdayText
                              .map<Widget>((day) => Text(day, style: const TextStyle(fontSize: 16)))
                              .toList(),
                        );
                      } else {
                        return const Text("Not available", style: TextStyle(fontSize: 16));
                      }
                    }),
                    // Additional fields (e.g., reviews) can be added here.
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
