import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/find_hospital_place_info.dart';
import '../utils/find_hospital_webservice.dart';
import '../utils/hospital_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  // Default center; updated with the current location.
  LatLng _center = const LatLng(45.521563, -122.677433);
  Set<Marker> _markers = {};
  List<FindHospitalsPlaceInfo> _hospitals = [];
  String _sortBy = "distance"; // Default sort order is "distance"

  // Controller for the draggable bottom sheet.
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }
  
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }
  
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }
    
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    
    if (!mounted) return;
    setState(() {
      _center = LatLng(position.latitude, position.longitude);
    });
    debugPrint('Current location: ${position.latitude}, ${position.longitude}');
    
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _center, zoom: 14.0),
      ),
    );
    
    _fetchNearbyHospitals();
  }
  
  Future<void> _fetchNearbyHospitals() async {
    try {
      final String sessionToken = const Uuid().v4();
      debugPrint('Session Token: $sessionToken');
      debugPrint('Fetching hospitals near: $_center');
      
      List<FindHospitalsPlaceInfo> hospitals = await FindHospitalWebService.getNearestHospital(
          _center.latitude, _center.longitude, 5000.0);
      
      debugPrint('Number of hospitals fetched: ${hospitals.length}');
      // Filter out hospitals with rating <= 0.
      hospitals = hospitals.where((h) => (h.rating ?? 0.0) > 0.0).toList();
      
      setState(() {
        _hospitals = hospitals;
        _markers.clear();
        _markers.addAll(hospitals.map((hospital) => Marker(
          markerId: MarkerId(hospital.placeId),
          position: LatLng(hospital.lat, hospital.lng),
          infoWindow: InfoWindow(
            title: hospital.name,
            snippet: hospital.vicinity ?? '',
          ),
        )));
      });
      
      if (hospitals.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No nearby hospitals found.')),
        );
      }
    } catch (e) {
      debugPrint('Error in _fetchNearbyHospitals: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching hospitals: $e')),
      );
    }
  }
  
  Future<void> _launchNavigation(double lat, double lng) async {
    final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final Uri url = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch $googleMapsUrl');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch navigation URL.')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Sort hospitals by distance.
    List<FindHospitalsPlaceInfo> sortedHospitals = List.from(_hospitals);
    sortedHospitals.sort((a, b) {
      double distanceA = Geolocator.distanceBetween(_center.latitude, _center.longitude, a.lat, a.lng);
      double distanceB = Geolocator.distanceBetween(_center.latitude, _center.longitude, b.lat, b.lng);
      if (_sortBy == "rating") {
        double ratingA = a.rating ?? 0;
        double ratingB = b.rating ?? 0;
        if (ratingB.compareTo(ratingA) != 0) {
          return ratingB.compareTo(ratingA);
        } else {
          return distanceA.compareTo(distanceB);
        }
      } else if (_sortBy == "distance") {
        return distanceA.compareTo(distanceB);
      }
      return 0;
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Nearby'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          // Draggable bottom panel.
          DraggableScrollableSheet(
            controller: _draggableController,
            initialChildSize: 0.3, // 30% of screen height initially.
            minChildSize: 0.1,
            maxChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black, blurRadius: 8)],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // Draggable handle icon.
                    GestureDetector(
                      onPanUpdate: (details) {
                        // Calculate the new size based on the drag.
                        final newSize = _draggableController.size -
                            details.delta.dy / MediaQuery.of(context).size.height;
                        // Clamp the new size between minChildSize and maxChildSize.
                        _draggableController.jumpTo(newSize.clamp(0.1, 0.9));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.drag_handle, size: 30),
                      ),
                    ),
                    // Filter dropdown.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Text("Sort by: "),
                          DropdownButton<String>(
                            value: _sortBy,
                            items: const [
                              DropdownMenuItem(value: "distance", child: Text("Distance")),
                              DropdownMenuItem(value: "rating", child: Text("Rating")),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _sortBy = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: sortedHospitals.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: sortedHospitals.length,
                              itemBuilder: (context, index) {
                                final hospital = sortedHospitals[index];
                                double distance = Geolocator.distanceBetween(
                                    _center.latitude, _center.longitude, hospital.lat, hospital.lng);
                                return HospitalCard(
                                  hospital: hospital,
                                  distance: distance,
                                  onNavigate: (lat, lng) => _launchNavigation(lat, lng),
                                  // onTap focuses the map.
                                  onTap: () {
                                    mapController.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: LatLng(hospital.lat, hospital.lng),
                                          zoom: 16,
                                        ),
                                      ),
                                    );
                                  },
                                  // onInfoTap opens the detail page.
                                  onInfoTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HospitalDetailScreen(
                                          hospital: hospital,
                                          currentLat: _center.latitude,
                                          currentLng: _center.longitude,
                                          onNavigate: _launchNavigation,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A custom widget for each hospital in the list.
/// - Tapping the card (except for icons) focuses the map.
/// - Tapping the info icon opens the detail page.
/// - Tapping the navigation icon launches navigation.
class HospitalCard extends StatelessWidget {
  final FindHospitalsPlaceInfo hospital;
  final double distance; // in meters
  final void Function(double lat, double lng) onNavigate;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;
  
  const HospitalCard({
    super.key,
    required this.hospital,
    required this.distance,
    required this.onNavigate,
    required this.onTap,
    required this.onInfoTap,
  });
  
  // Truncate text to a maximum length.
  String _truncate(String text, [int maxLen = 15]) {
    if (text.length <= maxLen) return text;
    return text.substring(0, maxLen) + '...';
  }
  
  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    if (hospital.photos != null && hospital.photos!.isNotEmpty) {
      final photoRef = hospital.photos![0]['photo_reference'];
      if (photoRef is String && photoRef.isNotEmpty) {
        final apiKey = dotenv.env['GOOGLE_MAP_API_KEY'] ?? '';
        imageUrl = 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=$apiKey';
      }
    }
    
    String distanceStr = (distance / 1000).toStringAsFixed(2) + " km";
    String ratingStr = (hospital.rating != null) ? "Rating: ${hospital.rating!.toStringAsFixed(1)}" : "No rating";
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hospital image or placeholder.
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey,
                  child: const Icon(Icons.local_hospital, color: Colors.white),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _truncate(hospital.name),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(ratingStr, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Text(distanceStr, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              // Info icon.
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: onInfoTap,
              ),
              // Navigation icon.
              IconButton(
                icon: const Icon(Icons.navigation),
                onPressed: () => onNavigate(hospital.lat, hospital.lng),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
