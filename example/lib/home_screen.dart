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
        key: GlobalKey(),
        debugMode: true,
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
        ],
        defaultPlaceMarker: Container(
          color: Colors.orange,
          height: 50,
          width: 50,
          child: const Icon(Icons.circle),
        ),
        defaultClusterMarker: Container(
          color: Colors.orange,
          height: 50,
          width: 50,
          child: const Icon(Icons.hexagon),
        ),
        clusterMarker: Container(
          color: Colors.orange,
          height: 50,
          width: 50,
          child: const Icon(Icons.square),
        ),
        placeMarkerBuilder: (latLngId) => const Icon(Icons.shield),
      )),
    );
  }
}
