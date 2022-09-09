import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/flutter_google_maps_widget_cluster_markers.dart';

class MyPlace extends Place {
  MyPlace({required this.name, required super.latLng});
  final String name;
  double? occupancy;
  Future<bool> getPlaceOccupancy() async {
    return await Future.delayed(const Duration(milliseconds: 100), () {
      occupancy = Random().nextDouble();
      debugPrint(
          'some API queried for latLngId: ${super.latLng}, with occupancy: $occupancy');
      return true;
    });
  }
}
