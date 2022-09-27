import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/cluster_manager_id_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// CachedCluster does not have a latLngId because the Cluster latLng changes
/// depending on the Places it is grouping together, therefore having a latLngId
/// is trivial.
class CachedCluster {
  CachedCluster(
      {required this.clusterSize,
      required this.clusterManagerId,
      required this.repaintBoundaryKey});

  final int clusterSize;

  /// Used to match with cluster.getId(), has format lat_lng_clusterSize
  final String clusterManagerId;
  final GlobalKey repaintBoundaryKey;
  BitmapDescriptor? bitmap;
}

class CachedPlace {
  CachedPlace._(
      {required this.latLngId,
      required this.clusterManagerId,
      required this.repaintBoundaryKey});

  factory CachedPlace(
      {required String clusterManagerId,
      required GlobalKey repaintBoundaryKey}) {
    return CachedPlace._(
        latLngId:
            ClusterManagerIdUtils.clusterManagerIdToLatLngId(clusterManagerId),
        clusterManagerId: clusterManagerId,
        repaintBoundaryKey: repaintBoundaryKey);
  }

  /// Used to make API requests and get info to display on bitmap marker, has
  /// format lat_lng
  String latLngId;

  /// Used to match with cluster.getId(), has format lat_lng_clusterSize
  ///
  /// For CachedPlace, clusterSize will always be 1
  final String clusterManagerId;
  final GlobalKey repaintBoundaryKey;
  BitmapDescriptor? bitmap;
}
