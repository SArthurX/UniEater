import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'restaurant_info.dart';
import 'add.dart';
import 'dart:async';

class Page1 extends StatefulWidget {
  const Page1({super.key});
  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> {
  late GoogleMapController mapController;
  LocationData? currentLocation;
  final Location location = Location();
  bool _isGettingLocation = false;
  Set<Marker> _markers = {};
  StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>>?
      _streamSubscription;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final permissionStatus = await location.hasPermission();
    if (permissionStatus == PermissionStatus.granted) {
      _getLocation();
    } else {
      final requestPermissionStatus = await location.requestPermission();
      if (requestPermissionStatus == PermissionStatus.granted) {
        _getLocation();
      } else {
        print('Location permission denied');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddLocationPage()),
              );
            },
          ),
        ],
      ),
      body: _isGettingLocation
          ? const Center(child: CircularProgressIndicator())
          : currentLocation == null
              ? const Center(child: Text('无法获取当前位置'))
              : GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(currentLocation!.latitude!,
                        currentLocation!.longitude!),
                    zoom: 14.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  onCameraIdle: () async {
                    LatLngBounds bounds =
                        await mapController.getVisibleRegion();
                    LatLng center = LatLng(
                      (bounds.northeast.latitude + bounds.southwest.latitude) /
                          2,
                      (bounds.northeast.longitude +
                              bounds.southwest.longitude) /
                          2,
                    );

                    _setCenterMarker(center);

                    _createMarkers(center, 1);
                  },
                  markers: _markers,
                ),
    );
  }

  Future<void> _getLocation() async {
    setState(() {
      _isGettingLocation = true;
    });
    final locationResult = await location.getLocation();
    setState(() {
      currentLocation = locationResult;
      _isGettingLocation = false;
    });
  }

  void _setCenterMarker(LatLng center) {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('center_marker'),
          position: center,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: '中心'),
        ),
      );
    });
  }

  // 打开导航到 Google Maps
  Future<void> _launchMaps(String address) async {
    final Uri googleMapsUrl = Uri.parse('comgooglemaps://?daddr=$address');
    final Uri webUrl = Uri.parse('https://www.google.com/maps/dir//$address');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl);
    } else {
      throw Exception('無法開啟 $googleMapsUrl/$webUrl');
    }
  }

  void _showBottomSheet(
    BuildContext context,
    String title,
    String timings,
    String address,
    String restaurantId,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 50, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  restaurant_info(restaurantId: restaurantId)),
                        );
                      },
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      timings,
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      address,
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                const Color.fromARGB(255, 84, 182, 217),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 100),
                            elevation: 5,
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            shadowColor: Colors.grey,
                          ),
                          onPressed: () {},
                          child: const Text("店家菜單"),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              side: const BorderSide(
                                  color: Color.fromARGB(255, 84, 182, 217),
                                  width: 2),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25),
                            ),
                            onPressed: () => _launchMaps(address),
                            child: const Icon(
                              Icons.near_me,
                              color: Colors.blue,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _createMarkers(LatLng center, double radiusInKm) {
    final CollectionReference<Map<String, dynamic>> collectionReference =
        FirebaseFirestore.instance.collection('university');

    GeoFirePoint centerPoint = GeoFirePoint(
      GeoPoint(center.latitude, center.longitude),
    );

    print(
        'Querying with center: ${center.latitude}, ${center.longitude}, radius: $radiusInKm km');

    Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream =
        GeoCollectionReference<Map<String, dynamic>>(collectionReference)
            .subscribeWithin(
      center: centerPoint,
      radiusInKm: radiusInKm,
      field: 'geo',
      geopointFrom: (data) {
        if (data['geo'] is Map<String, dynamic> &&
            data['geo']['geopoint'] is GeoPoint) {
          return data['geo']['geopoint'] as GeoPoint;
        }
        print('Warning: Unexpected geo data structure for document');
        return GeoPoint(0, 0);
      },
      strictMode: true,
    );

    _streamSubscription?.cancel();

    _streamSubscription = stream.listen((documentList) {
      print('Received ${documentList.length} documents');
      Set<Marker> markers = {};

      for (var doc in documentList) {
        final storeData = doc.data();
        if (storeData == null) continue;

        print('Document found: ${doc.id}, Data: $storeData');

        if (storeData['geo'] != null && storeData['name'] != null) {
          final geoData = storeData['geo'] as Map<String, dynamic>;
          final geoPoint = geoData['geopoint'] as GeoPoint;
          markers.add(
            Marker(
              markerId: MarkerId(storeData['name']),
              position: LatLng(geoPoint.latitude, geoPoint.longitude),
              infoWindow: InfoWindow(
                title: storeData['name'],
                snippet: storeData['description'] ?? '',
              ),
              onTap: () {
                _showBottomSheet(
                    context,
                    storeData['name'],
                    storeData['hours']["${DateTime.now().weekday}"] ??
                        'Hours not available',
                    storeData['address'] ?? 'Address not available',
                    doc.id);
              },
            ),
          );
          print('Added marker for ${storeData['name']}');
        } else {
          print('Error: Missing required data fields for document ${doc.id}');
        }
      }

      setState(() {
        _markers = {
          ..._markers
              .where((marker) => marker.markerId == MarkerId('center_marker')),
          ...markers,
        };
      });
      print('Updated markers with ${markers.length} markers');
    });
  }
}
