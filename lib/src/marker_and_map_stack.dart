import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/flutter_google_maps_widget_cluster_markers.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/generators/default_repaint_boundary_generator.dart.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/generators/repaint_boundary_generator.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/map_and_clusters.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/init_map_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/map_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/refresh_map_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/injector.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/logger.dart';
import 'package:provider/provider.dart';

class MarkerAndMapStack extends StatelessWidget {
  const MarkerAndMapStack({
    required this.places,
    required this.defaultPlaceMarker,
    required this.defaultClusterMarker,
    required this.placeMarkerOnTap,
    required this.clusterMarkerOnTap,
    required this.clusterMarker,
    required this.placeMarkerBuilder,
    required this.controller,
    super.key,
  });

  final List<Place> places;

  final Widget defaultPlaceMarker;
  final Widget defaultClusterMarker;

  final Widget clusterMarker;
  final Widget Function(String latLngId) placeMarkerBuilder;

  final Future<void> Function(String latLngId)? placeMarkerOnTap;
  final Future<void> Function(String latLngId)? clusterMarkerOnTap;

  final GoogleMapWidgetClusterMarkersController? controller;

  @override
  Widget build(BuildContext context) {
    MapState mapState = Injector.map(context);
    InitMapBuildState initMapBuildState = Injector.initMapBuild(context);
    RefreshMapBuildState refreshMapBuildState =
        Injector.refreshMapBuild(context);

    if (controller != null) {
      // Init controller if not null
      controller!.init(context, mapState, refreshMapBuildState);
    }

    if (initMapBuildState.allowInitMapTripleBuildCycle) {
      initMapBuildState.startFirstBuild();
    }
    return Stack(
      children: [
        //! Default Markers (RepaintBoundary)
        /// Must be the first thing that builds in this stack, so that
        /// ClusterManager can use the default markers for the first build cycle
        /// of initMapTripleBuildCycle
        Align(
          alignment: Alignment.topLeft,
          child: DefaultRepaintBoundaryGenerator(
            defaultPlaceRepaintBoundaryKey:
                mapState.defaultPlaceRepaintBoundaryKey,
            defaultClusterRepaintBoundaryKey:
                mapState.defaultClusterRepaintBoundaryKey,
            defaultPlaceMarker: defaultPlaceMarker,
            defaultClusterMarker: defaultClusterMarker,
          ),
        ),

        //! Marker (RepaintBoundary) Generators
        /// For initMapTripleBuildCycle, should only be built in second build
        /// cycle after updateCachedPlacesAndClusters(). First build will return
        /// whitespace.
        ///
        /// For refreshMapDoubleBuildCycle, should only be rebuilt in second
        /// build after updateCachedPlacesAndClusters().
        Align(
          alignment: Alignment.bottomLeft,
          child: Selector<MapState, bool>(
            selector: (p0, p1) => p1.shouldRebuildRepaintBoundaryGenerator,
            builder: (context, value, child) {
              if (initMapBuildState.initMapTripleBuildCycle) {
                if (initMapBuildState.inFirstBuild) {
                  logger.v(
                      'RepaintBoundaryGenerator: initMapTripleBuildCycle: inFirstBuild, generating white space');
                  return const SizedBox();
                } else if (initMapBuildState.inSecondBuild) {
                  throw StateError(
                      'RepaintBoundaryGenerator: refreshMapDoubleBuildCycle: rebuildRepaintBoundaryGenerator was called in inSecondBuild');
                } else if (initMapBuildState.inThirdBuild) {
                  logger.v(
                      'RepaintBoundaryGenerator: initMapTripleBuildCycle: inThirdBuild, generating RepaintBoundaries');
                  return RepaintBoundaryGenerator(
                    clusterMarker: clusterMarker,
                    placeMarkerBuilder: placeMarkerBuilder,
                  );
                } else {
                  throw StateError(
                      'RepaintBoundaryGenerator: initMapTripleBuildCycle: inFirstBuild and inSecondBuild are both false');
                }
              } else if (refreshMapBuildState.refreshMapDoubleBuildCycle) {
                if (refreshMapBuildState.inFirstBuild) {
                  throw StateError(
                      'RepaintBoundaryGenerator: refreshMapDoubleBuildCycle: rebuildRepaintBoundaryGenerator was called in firstBuild');
                } else if (refreshMapBuildState.inSecondBuild) {
                  logger.v(
                      'RepaintBoundaryGenerator: refreshMapDoubleBuildCycle: inSecondBuild, generating RepaintBoundaries');
                  return RepaintBoundaryGenerator(
                    key:
                        GlobalKey(), // replace previous widget so that afterFirstLayout can be called again
                    clusterMarker: clusterMarker,
                    placeMarkerBuilder: placeMarkerBuilder,
                  );
                } else {
                  throw StateError(
                      'RepaintBoundaryGenerator: initMapTripleBuildCycle: inFirstBuild and inSecondBuild are both false');
                }
              } else {
                throw StateError(
                    'RepaintBoundaryGenerator: initMapTripleBuildCycle and refreshMapDoubleBuildCycle are both false');
              }
            },
          ),
        ),

        //! Google Map
        /// Only builds after the Default Marker Bitmaps are initialised
        Selector<MapState, bool>(
          selector: (p0, p1) => p1.defaultBitmapsInitialised,
          builder: (context, defaultBitmapsInitialised, child) {
            if (defaultBitmapsInitialised) {
              logger.w(
                  'Building map, this should only be called once when the widget is first built.');
              return Padding(
                padding: mapState.debugMode
                    ? const EdgeInsets.only(left: 100)
                    : EdgeInsets.zero,
                child: MapAndClusters(
                  places: places,
                  placeMarkerOnTap: placeMarkerOnTap,
                  clusterMarkerOnTap: clusterMarkerOnTap,
                ),
              );
            } else {
              logger.v(
                  'Waiting for default marker bitmaps to initialise before initialising map');
              return Container();
            }
          },
        ),
      ],
    );
  }
}
