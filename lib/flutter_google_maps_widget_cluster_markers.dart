library flutter_google_maps_widget_cluster_markers;

export 'src/classes/controller.dart';
export 'src/classes/place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/classes/controller.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/init_map_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/map_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/marker_and_map_stack.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/classes/place.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/refresh_map_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/update_places_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/logger.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

/// This widget implements a very specific adaptation of google_maps_cluster_manager.
///
/// The original google_maps_cluster_manager package implements the following process:
/// 1. First allowing the GoogleMap widget to be built with an empty Set<Marker>,
/// 2. Determining the LatLng bounds of the GoogleMap view and the current zoom level,
/// 3. Calculating how many Places there are in each Cluster based on info from
/// the previous step, and storing it in List<Cluster>
/// 4. Building a widget to show the number of Places in each Cluster and
/// converting it to a Bitmap
/// 5. Calling setState on the Set<Marker> with the converted Bitmaps
///
/// This package takes the approach a step further, allowing different
/// Markers to be shown depending on whether it is a Cluster or a Place (Cluster of size 1),
/// and also allows the Marker to wait for information from external APIs.
///
/// A double build cycle is used to implement this, wherein the first build cycle
/// allows the ClusterManager to perform its initial process, and the second
/// build cycle builds Markers based on the Clusters from the first build cycle,
/// converts them into bitmaps, then updates the map markers
///
/// The second build cycle goes through the following process:
/// 6. MapState.updateCachedPlacesAndClusters() splits clusterManager.clusters
/// into a List<CachedCluster> and List<CachedPlace> in state (so that there is
/// a cached reference when updateMap is called).
/// CachedCluster and CachedPlace contain a repaintBoundaryKey and
/// clusterManagerId (so that markerBuilder knows which one to use).
/// Additionally, CachedCluster contains clusterSize to display on the Marker,
/// and CachedPlace contains the latLngId so that API requests can be made to
/// furnish the Marker with information (e.g., occupancy).
/// 7. ClusterBoundaryGenerator and PlaceBoundaryGenerator then builds a
/// RepaintBoundary for each CachedCluster and CachedPlace, using both the
/// repaintBoundaryKey and other info (clusterSize, latLngId)
/// 8. MapState.storeBitmapsInCache() then converts each CachedPlace and
/// CachedCluster repaintBoundaryKey into a bitmap and stores it
/// 9. ClusterManager.updateMap is then called, and markerBuilderCallback uses
/// the newly generated bitmaps
///
/// There are three types of build cycles,
///
/// - An initMapTripleBuildCycle, which occurs the first time GoogleMap is built
/// FIRST BUILD
/// 1. DefaultRepaintBoundaryGenerator builds
/// 2. DefaultRenderRepaintBoundaries converted to DefaultBitmaps
/// 3. GoogleMap built
/// 4. ClusterManager initialised (with Places, GoogleMapController.id) but
/// no clusters in view (because map has not rendered)
/// 5. GoogleMap renders and calls onCameraIdle
/// SECOND BUILD
/// 6. MapState.refreshMarkerBuilderAndUpdateMarkerCallback() to get clusters in view
/// and use DefaultBitmaps
/// THIRD BUILD
/// 7. MapState.updateCachedPlacesAndClusters() splits clusterManager.clusters
/// into a List<CachedCluster> and List<CachedPlace> in state (so that there is
/// a cached reference when updateMap is called).
/// CachedCluster and CachedPlace contain a repaintBoundaryKey and
/// clusterManagerId (so that markerBuilder knows which one to use).
/// Additionally, CachedCluster contains clusterSize to display on the Marker,
/// and CachedPlace contains the latLngId so that API requests can be made to
/// furnish the Marker with information (e.g., occupancy).
/// 8. ClusterBoundaryGenerator and PlaceBoundaryGenerator then builds a
/// RepaintBoundary for each CachedCluster and CachedPlace, using both the
/// repaintBoundaryKey and other info (clusterSize, latLngId)
/// 9. MapState.storeBitmapsInCache() then converts each CachedPlace and
/// CachedCluster repaintBoundaryKey into a bitmap and stores it
/// 10. ClusterManager.updateMap is then called, and markerBuilderCallback uses
/// the newly generated bitmaps
///
/// - A refreshMapDoubleBuildCycle, which occurs whenever the GoogleMap is refreshed
/// FIRST BUILD
/// 1. MapState.refreshMarkerBuilderAndUpdateMarkerCallback() to get clusters in view
/// and use DefaultBitmaps
/// SECOND BUILD
/// 2. MapState.updateCachedPlacesAndClusters() splits clusterManager.clusters
/// into a List<CachedCluster> and List<CachedPlace> in state (so that there is
/// a cached reference when updateMap is called).
/// CachedCluster and CachedPlace contain a repaintBoundaryKey and
/// clusterManagerId (so that markerBuilder knows which one to use).
/// Additionally, CachedCluster contains clusterSize to display on the Marker,
/// and CachedPlace contains the latLngId so that API requests can be made to
/// furnish the Marker with information (e.g., occupancy).
/// 3. ClusterBoundaryGenerator and PlaceBoundaryGenerator then builds a
/// RepaintBoundary for each CachedCluster and CachedPlace, using both the
/// repaintBoundaryKey and other info (clusterSize, latLngId)
/// 4. MapState.storeBitmapsInCache() then converts each CachedPlace and
/// CachedCluster repaintBoundaryKey into a bitmap and stores it
/// 5. ClusterManager.updateMap is then called, and markerBuilderCallback uses
/// the newly generated bitmaps
///
/// - An updatePlacesDoubleBuildCycle, which occurs occurs whenever the places in
/// clusterManager is updated. This cycle uses the second and third build of
/// initMapTripleBuildCycle
/// FIRST
/// 1. MapState.refreshMarkerBuilderAndUpdateMarkerCallback() to get clusters in view
/// and use DefaultBitmaps
/// THIRD BUILD
/// 2. MapState.updateCachedPlacesAndClusters() splits clusterManager.clusters
/// into a List<CachedCluster> and List<CachedPlace> in state (so that there is
/// a cached reference when updateMap is called).
/// CachedCluster and CachedPlace contain a repaintBoundaryKey and
/// clusterManagerId (so that markerBuilder knows which one to use).
/// Additionally, CachedCluster contains clusterSize to display on the Marker,
/// and CachedPlace contains the latLngId so that API requests can be made to
/// furnish the Marker with information (e.g., occupancy).
/// 3. ClusterBoundaryGenerator and PlaceBoundaryGenerator then builds a
/// RepaintBoundary for each CachedCluster and CachedPlace, using both the
/// repaintBoundaryKey and other info (clusterSize, latLngId)
/// 4. MapState.storeBitmapsInCache() then converts each CachedPlace and
/// CachedCluster repaintBoundaryKey into a bitmap and stores it
/// 5. ClusterManager.updateMap is then called, and markerBuilderCallback uses
/// the newly generated bitmaps
/// SECOND
///
/// Note:
/// * clusterManagerId == ClusterManager.cluster.getId(), has format lat_lng_clusterSize
/// * latLngId has format lat_lng
/// * RepaintBoundary is converted into Bitmap via: RepaintBoundary > RenderRepaintBoundary > Image > ByteDate > BitmapDescriptor
class GoogleMapWidgetClusterMarkers extends StatelessWidget {
  const GoogleMapWidgetClusterMarkers({
    required this.places,
    required this.defaultPlaceMarker,
    required this.defaultClusterMarker,
    required this.clusterMarker,
    required this.placeMarkerBuilder,
    this.clusterMarkerOnTap,
    this.placeMarkerOnTap,
    this.showLogs = false,
    this.clusterMarkerTextStyle,
    this.clusterTextPadding = EdgeInsets.zero,
    this.debugMode = false,
    this.devicePixelRatio = 1,
    this.initialCameraPosition = const CameraPosition(
      target: LatLng(51.5136, -0.1365), // SOHO
      zoom: 14,
    ),
    this.debugBuildStage = DebugBuildStage.refreshMapSecondBuild,
    this.controller,
    this.afterInitMapCallback,
    super.key,
  });
  final List<Place> places;
  final Widget defaultPlaceMarker;
  final Widget defaultClusterMarker;

  final Future<void> Function(String latLngId)? placeMarkerOnTap;
  final Future<void> Function(String latLngId)? clusterMarkerOnTap;

  final Widget clusterMarker;
  final Widget Function(String latLngId) placeMarkerBuilder;

  final bool debugMode;
  final double devicePixelRatio;

  final CameraPosition initialCameraPosition;
  final DebugBuildStage debugBuildStage;

  final TextStyle? clusterMarkerTextStyle;
  final EdgeInsets clusterTextPadding;

  /// Set to true to see all logs, false to just show error logs
  final bool showLogs;

  final GoogleMapWidgetClusterMarkersController? controller;

  final Future<void> Function()? afterInitMapCallback;

  @override
  Widget build(BuildContext context) {
    logger = CallerLogger(
      ignoreCallers: {
        'syncTryCatchHandler',
        'asyncTryCatchHandler',
      },
      filter: TypeFilter(
        ignoreTypes: {},
        ignoreLevel: Level.error,
      ),
      level: showLogs ? Level.verbose : Level.error,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MapState(
            debugMode: debugMode,
            devicePixelRatio: devicePixelRatio,
            initialCameraPosition: initialCameraPosition,
            debugBuildStage: debugBuildStage,
            clusterMarkerTextStyle: clusterMarkerTextStyle,
            clusterTextPadding: clusterTextPadding,
          ),
        ),
        ChangeNotifierProvider(
            create: (context) => InitMapBuildState(
                  afterInitMapCallback: afterInitMapCallback,
                )),
        ChangeNotifierProvider(create: (context) => RefreshMapBuildState()),
        ChangeNotifierProvider(create: (context) => UpdatePlacesBuildState()),
        if (controller != null)
          ChangeNotifierProvider(create: (context) => controller),
      ],
      child: MarkerAndMapStack(
        places: places,
        defaultPlaceMarker: defaultPlaceMarker,
        defaultClusterMarker: defaultClusterMarker,
        clusterMarker: clusterMarker,
        placeMarkerBuilder: placeMarkerBuilder,
        placeMarkerOnTap: placeMarkerOnTap,
        clusterMarkerOnTap: clusterMarkerOnTap,
        controller: controller,
      ),
    );
  }
}
