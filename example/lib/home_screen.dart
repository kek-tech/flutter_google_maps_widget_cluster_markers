import 'dart:math';

import 'package:example/my_place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/flutter_google_maps_widget_cluster_markers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    var temp = MyPlace(
      name: 'Tottenham Court Road',
      latLng: const LatLng(51.51630, -0.13000),
    );
    temp.location;
    return Scaffold(
      body: Center(
        child: GoogleMapWidgetClusterMarkers(
          clusterMarkerTextStyle: const TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          places: [
            MyPlace(
              name: 'Tottenham Court Road',
              latLng: const LatLng(51.51630, -0.13000),
            ),
            MyPlace(
              name: 'Chinatown',
              latLng: const LatLng(51.51090, -0.13160),
            ),
            MyPlace(
              name: 'Covent Garden',
              latLng: const LatLng(51.51170, -0.12400),
            ),
            MyPlace(
              name: 'Imperial College',
              latLng: const LatLng(51.4988, -0.1749),
            ),
          ],
          defaultPlaceMarker: Container(
            color: Colors.orange,
            height: 100,
            width: 100,
            child: const Icon(
              Icons.circle,
              size: 150,
            ),
          ),
          defaultClusterMarker: const Icon(
            Icons.hexagon,
            size: 150,
          ),
          clusterMarker: const Icon(
            Icons.hexagon,
            size: 150,
          ),
          placeMarkerBuilder: (latLngId) => Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.circle,
                size: 150,
              ),
              Text(
                '${Random().nextInt(9)}',
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
