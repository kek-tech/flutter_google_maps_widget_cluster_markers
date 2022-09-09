import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/init_map_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/map_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/classes/place.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/refresh_map_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/injector.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/logger.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapAndClusters extends StatefulWidget {
  const MapAndClusters({
    required this.places,
    // required this.markerBuilder,
    super.key,
  });

  final List<Place> places;
  // final Future<Marker> Function(Cluster<Place>)? markerBuilder;
  @override
  State<MapAndClusters> createState() => _MapAndClustersState();
}

//! State
class _MapAndClustersState extends State<MapAndClusters> with AfterLayoutMixin {
  /// Markers to show in Google Map
  ///
  /// Initialised as empty, and set by [MapState._clusterManager] based on
  /// the places in view and zoom level via [_updateMarkersCallback]
  Set<Marker> markers = <Marker>{};

  //! Update Markers Callback
  /// Callback passed to [MapState._clusterManager] which is called everytime
  /// [MapState._clusterManager.updateMap()] is called
  ///
  /// The first time [_clusterManager] is init and calls [markerBuilder],
  /// it creates clusters and clusterMarkers from defaultClusterMarker
  /// it then calls _updateMarkers, and at this point, clusters have been init
  void _updateMarkersCallback(Set<Marker> markers) async {
    InitMapBuildState initMapBuildState = Injector.initMapBuild(context);
    RefreshMapBuildState refreshMapBuildState =
        Injector.refreshMapBuild(context);

    setState(() {
      /// Update this StatefulWidget.markers = _clusterManager.markers
      this.markers = markers;
      logger.v(
          '_updateMarkersCallback: setState: markers on screen: ${markers.length}');
    });

    if (initMapBuildState.initMapTripleBuildCycle) {
      if (initMapBuildState.inFirstBuild) {
        logger.v(
            '''initMapTripleBuildCycle: inFirstBuild: clusterManager finished initialising
''');
      } else if (initMapBuildState.inSecondBuild) {
        logger.v('''initMapTripleBuildCycle: inSecondBuild: end of secondBuild
        ''');
        initMapBuildState.startThirdBuild(context);
        refreshMapBuildState.allowRefreshMapDoubleBuildCycle = true;
      } else if (initMapBuildState.inThirdBuild) {
        logger.v(
            '''initMapTripleBuildCycle: inThirdBuild: end of thirdBuild and initMapTripleBuildCycle''');
        initMapBuildState.endThirdBuild();
      } else {
        throw UnimplementedError(
            '''Unimplemented Case: _updateMarkersCallback called when
            \ninitMapTripleBuildCycle: true
            \ninFirstBuild: false
            \ninSecondBuild: false''');
      }
    } else if (refreshMapBuildState.refreshMapDoubleBuildCycle) {
      if (refreshMapBuildState.inFirstBuild) {
        logger.v(
            '''refreshMapBuildState: inFirstBuild: Clusters refreshed, but previous Bitmaps are being used, starting second build cycle''');
        refreshMapBuildState.startSecondBuild(context);
      } else if (refreshMapBuildState.inSecondBuild) {
        logger.v(
            '''refreshMapBuildState: inSecondBuild: end of secondBuild and refreshMapDoubleBuildCycle''');
        refreshMapBuildState.endSecondBuild();
      } else {
        throw UnimplementedError(
            '''Unimplemented Case: _updateMarkersCallback called when
            \nrefreshMapDoubleBuildCycle: true
            \ninFirstBuild: false
            \ninSecondBuild: false''');
      }
    } else {
      throw UnimplementedError(
          '''Unimplemented Case: _updateMarkersCallback called with
            \ninitMapTripleBuildCycle: false
            \nrefreshMapDoubleBuildCycle: false.''');
    }
  }

  //! Marker Builder Callback

  Future<Marker> Function(Cluster) get _markerBuilderCallback =>
      (cluster) async {
        MapState mapState = Injector.map(context);
        InitMapBuildState initMapBuildState = Injector.initMapBuild(context);
        RefreshMapBuildState refreshMapBuildState =
            Injector.refreshMapBuild(context);
        return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          //! Marker onTap
          onTap: () async {
            logger.v('Marker: onTap: $cluster');

            // zoom in to marker
            cluster.isMultiple
                ? mapState.zoomToMarker(
                    position: cluster.location, cluster: true)
                : mapState.zoomToMarker(
                    position: cluster.location, cluster: false);
          },
          //! Marker Icon/Bitmap
          icon: (() {
            if (!initMapBuildState.defaultBitmapsInitialised) {
              throw StateError(
                  '_markerBuilderCallback called when mapState.defaultClusterMarkerBitmap or mapState.defaultPlaceMarkerBitmap are still null');
            }
            if (initMapBuildState.initMapTripleBuildCycle) {
              if (initMapBuildState.inFirstBuild) {
                logger.v(
                    '''initMapTripleBuildCycle: inFirstBuild: GoogleMap not rendered yet, so no Clusters in ClusterManager, using defaultMarkerBitmaps (trivial)''');
                if (cluster.isMultiple) {
                  return initMapBuildState.defaultClusterMarkerBitmap!;
                } else {
                  return initMapBuildState.defaultPlaceMarkerBitmap!;
                }
              } else if (initMapBuildState.inSecondBuild) {
                logger.v(
                    '''initMapTripleBuildCycle: inSecondBuild: Clusters just initialised in ClusterManager, using defaultMarkerBitmaps.''');
                if (cluster.isMultiple) {
                  return initMapBuildState.defaultClusterMarkerBitmap!;
                } else {
                  return initMapBuildState.defaultPlaceMarkerBitmap!;
                }
              } else if (initMapBuildState.inThirdBuild) {
                logger.v('''initMapTripleBuildCycle: inThirdBuild: ''');
                return mapState.getBitmapFromClusterManagerId(cluster.getId());
              } else {
                throw UnimplementedError(
                    '''Unimplemented Case: _markerBuilderCallback called when
                \ninitMapTripleBuildCycle: true
                \ninFirstBuild: false
                // \ninSecondBuild: false''');
              }
            } else if (refreshMapBuildState.refreshMapDoubleBuildCycle) {
              if (refreshMapBuildState.inFirstBuild) {
                logger.v(
                    '''refreshMapBuildState: inFirstBuild: Clusters not initialised in ClusterManager,
        Using markers from previous double build cycle.''');
                return mapState.getBitmapFromClusterManagerId(cluster.getId());
              } else if (refreshMapBuildState.inSecondBuild) {
                logger.v(
                    '''refreshMapBuildState: inSecondBuild: Clusters just refreshed in ClusterManager, 
        replacing markers from previous double build cycle with current ones in cache.''');
                return mapState.getBitmapFromClusterManagerId(cluster.getId());
              } else {
                throw UnimplementedError(
                    '''Unimplemented Case: _markerBuilderCallback called when
                \nrefreshMapDoubleBuildCycle: true
                \ninFirstBuild: false
                \ninSecondBuild: false''');
              }
            } else {
              throw UnimplementedError(
                  '''Unimplemented Case: _markerBuilderCallback called with
              \ninitMapTripleBuildCycle: false
              \nrefreshMapDoubleBuildCycle: false.''');
            }
          }()),
        );
      };

  //! Build
  @override
  Widget build(BuildContext context) {
    MapState mapState = Injector.map(context);
    InitMapBuildState initMapBuildState = Injector.initMapBuild(context);
    RefreshMapBuildState refreshMapBuildState =
        Injector.refreshMapBuild(context);

    if (!mapState.clusterManagerInitialised) {
      mapState.initClusterManager(
        places: widget.places,
        updateMarkers: _updateMarkersCallback,
        markerBuilder: _markerBuilderCallback,
      );
    }

    return GoogleMap(
      markers: markers,
      initialCameraPosition: mapState.initialCameraPosition,
      onMapCreated: (GoogleMapController controller) {
        mapState.onMapCreated(controller);
      },
      onCameraMove:
          mapState.onCameraMove, // does not update render, only zoom value
      onCameraIdle: () async {
        logger.v('onCameraIdle');

        if (initMapBuildState.initMapTripleBuildCycle &&
            initMapBuildState.inFirstBuild) {
          logger.v(
              '''GoogleMap has just rendered. End of initMapTripleBuildCycle.firstBuild''');
          // mapState.callMarkerBuilderAndUpdateMarkersCallback();
          initMapBuildState.startSecondBuild(context);
        } else if (refreshMapBuildState.allowRefreshMapDoubleBuildCycle) {
          refreshMapBuildState.startFirstBuild(context);
        } else {
          throw UnimplementedError('Unimplemented case in onCamerIdle');
        }
      },
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {
    logger.w('GoogleMap just built, this should not be called again');
    // MapState mapState = Injector.map(context)(context);
    // mapState.callMarkerBuilderAndUpdateMarkersCallback();
  }
}
