import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place with ClusterItem {
  Place({
    required this.latLng,
  });

  final LatLng latLng;

  /// ClusterItem needs location getter to function
  @override
  LatLng get location => latLng;

  String getLatLngId() {
    return "${location.latitude}_${location.longitude}";
  }
}
