import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/flutter_google_maps_widget_cluster_markers.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/init_map_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/map_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/refresh_map_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/update_places_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/cluster_manager_id_utils.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/injector.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/logger.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapAndClusters extends StatefulWidget {
  const MapAndClusters({
    required this.places,
    required this.placeMarkerOnTap,
    required this.clusterMarkerOnTap,
    required this.controller,
    super.key,
  });

  final List<Place> places;
  final Future<void> Function(String latLngId)? placeMarkerOnTap;
  final Future<void> Function(String latLngId)? clusterMarkerOnTap;
  final GoogleMapWidgetClusterMarkersController? controller;

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
    UpdatePlacesBuildState updatePlacesBuildState =
        Injector.updatePlacesBuild(context);

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
      } else if (initMapBuildState.inThirdBuild) {
        logger.v(
            '''initMapTripleBuildCycle: inThirdBuild: end of thirdBuild and initMapTripleBuildCycle''');
        initMapBuildState.endThirdBuild();
        refreshMapBuildState.allowRefreshMapDoubleBuildCycle = true;
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
    } else if (updatePlacesBuildState.updatePlacesDoubleBuildCycle) {
      if (updatePlacesBuildState.inFirstBuild) {
        logger
            .v('''updatePlacesDoubleBuildCycle: inFirstBuild: end of firstBuild
        ''');
        updatePlacesBuildState.startSecondBuild(context);
        refreshMapBuildState.allowRefreshMapDoubleBuildCycle = true;
      } else if (updatePlacesBuildState.inSecondBuild) {
        logger.v(
            '''updatePlacesDoubleBuildCycle: inSecondBuild: end of secondBuild and updatePlacesDoubleBuildCycle''');
        updatePlacesBuildState.endSecondBuild();
      } else {
        throw UnimplementedError(
            '''Unimplemented Case: _updateMarkersCallback called when
            \nupdatePlacesDoubleBuildCycle: true
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
        UpdatePlacesBuildState updatePlacesBuildState =
            Injector.updatePlacesBuild(context);
        String clusterManagerId = cluster.getId();
        String latLngId =
            ClusterManagerIdUtils.clusterManagerIdToLatLngId(clusterManagerId);
        return Marker(
          markerId: MarkerId(clusterManagerId),
          position: cluster.location,
          //! Marker onTap
          onTap: () async {
            logger.v('Marker: onTap: ${cluster.getId()}');

            // zoom in to marker
            await (cluster.isMultiple
                ? mapState.zoomToMarker(
                    position: cluster.location, cluster: true)
                : mapState.zoomToMarker(
                    position: cluster.location, cluster: false));

            // call onTaps
            await (cluster.isMultiple
                ? widget.clusterMarkerOnTap?.call(latLngId)
                : widget.placeMarkerOnTap?.call(latLngId));
          },
          //! Marker Icon/Bitmap
          icon: (() {
            if (!mapState.defaultBitmapsInitialised) {
              throw StateError(
                  '_markerBuilderCallback called when mapState.defaultClusterMarkerBitmap or mapState.defaultPlaceMarkerBitmap are still null');
            }
            if (initMapBuildState.initMapTripleBuildCycle) {
              if (initMapBuildState.inFirstBuild) {
                logger.v(
                    '''initMapTripleBuildCycle: inFirstBuild: GoogleMap not rendered yet, so no Clusters in ClusterManager, using defaultMarkerBitmaps (trivial)''');
                if (cluster.isMultiple) {
                  return mapState.defaultClusterMarkerBitmap!;
                } else {
                  return mapState.defaultPlaceMarkerBitmap!;
                }
              } else if (initMapBuildState.inSecondBuild) {
                logger.v(
                    '''initMapTripleBuildCycle: inSecondBuild: Clusters just initialised in ClusterManager, using defaultMarkerBitmaps.''');
                if (cluster.isMultiple) {
                  return mapState.defaultClusterMarkerBitmap!;
                } else {
                  return mapState.defaultPlaceMarkerBitmap!;
                }
              } else if (initMapBuildState.inThirdBuild) {
                logger.v('''initMapTripleBuildCycle: inThirdBuild: ''');
                return mapState.getBitmapFromClusterManagerId(
                    context, cluster.getId());
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
                    '''refreshMapBuildState: inFirstBuild: New clusters in view not initialised in ClusterManager,
        Using markers from previous double build cycle.''');
                return mapState.getBitmapFromClusterManagerId(
                    context, cluster.getId());
              } else if (refreshMapBuildState.inSecondBuild) {
                logger.v(
                    '''refreshMapBuildState: inSecondBuild: Clusters just refreshed in ClusterManager, 
        replacing markers from previous double build cycle with current ones in cache.''');
                return mapState.getBitmapFromClusterManagerId(
                    context, cluster.getId());
              } else {
                throw UnimplementedError(
                    '''Unimplemented Case: _markerBuilderCallback called when
                \nrefreshMapDoubleBuildCycle: true
                \ninFirstBuild: false
                \ninSecondBuild: false''');
              }
            } else if (updatePlacesBuildState.updatePlacesDoubleBuildCycle) {
              if (updatePlacesBuildState.inFirstBuild) {
                logger.v(
                    '''updatePlacesDoubleBuildCycle: inFirstBuild: Clusters just updated in ClusterManager, using defaultMarkerBitmaps.''');
                if (cluster.isMultiple) {
                  return mapState.defaultClusterMarkerBitmap!;
                } else {
                  return mapState.defaultPlaceMarkerBitmap!;
                }
              } else if (updatePlacesBuildState.inSecondBuild) {
                logger.v('''updatePlacesDoubleBuildCycle: inSecondBuild: ''');
                return mapState.getBitmapFromClusterManagerId(
                    context, cluster.getId());
              } else {
                throw UnimplementedError(
                    '''Unimplemented Case: _markerBuilderCallback called when
                \nupdatePlacesDoubleBuildCycle: true
                \ninFirstBuild: false
                // \ninSecondBuild: false''');
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
    UpdatePlacesBuildState updatePlacesBuildState =
        Injector.updatePlacesBuild(context);

    if (!mapState.clusterManagerInitialised) {
      mapState.initClusterManager(
        places: widget.places,
        updateMarkers: _updateMarkersCallback,
        markerBuilder: _markerBuilderCallback,
      );
    }

    if (widget.controller != null) {
      // Init controller if not null
      widget.controller!.init(
          context, mapState, refreshMapBuildState, updatePlacesBuildState);
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
