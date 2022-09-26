import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/map_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/refresh_map_build_state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Controller for flutter_google_maps_widget_cluster_markers package which is
/// initialised when instantiating GoogleMapWidgetClusterMarkers

class GoogleMapWidgetClusterMarkersController extends ChangeNotifier {
  /// Context to use for package so that methods which depend on the package's
  /// subtree context can be called from anywhere when the package is used.
  BuildContext? _context;

  //! Refresh Map
  void Function(BuildContext context)? _refreshMap;

  /// Refreshes the map using the refreshMapDoubleBuildCycle.
  ///
  ///
  void refreshMap() {
    if (_refreshMap == null && _context == null) {
      throw StateError(
          'Tried to call refreshMap without passing a controller to GoogleMapWidgetClusterMarkers');
    }
    _refreshMap!.call(_context!);
  }

  //! Zoom to Marker
  Future<void> Function({required LatLng position, required bool cluster})?
      _zoomToMarker;

  /// Zooms to the marker indicated by [position].
  /// If [cluster] is true, the CameraPosition is centered on the provided [position].

  Future<void> zoomToMarker(
      {required LatLng position, required bool cluster}) async {
    if (_zoomToMarker == null) {
      throw StateError(
          'Tried to call zoomToMarker without passing a controller to GoogleMapWidgetClusterMarkers');
    }
    await _zoomToMarker!.call(position: position, cluster: cluster);
  }

  void init(BuildContext context, MapState mapState,
      RefreshMapBuildState refreshMapBuildState) {
    _context = context;
    _zoomToMarker = mapState.zoomToMarker;
    _refreshMap = refreshMapBuildState.startFirstBuild;
  }
}
