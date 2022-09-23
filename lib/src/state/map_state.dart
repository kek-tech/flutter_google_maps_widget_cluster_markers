import 'package:flutter/material.dart';
import 'package:flutter_dev_utils/flutter_dev_utils.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/classes/place.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/classes/cached_places_clusters.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/refresh_map_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/boundary_key_to_bitmap.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/cluster_manager_id_utils.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/injector.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/logger.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum DebugBuildStage {
  // sequential build stages
  initMapFirstBuild,
  initMapSecondBuild,
  refreshMapFirstBuild,
  refreshMapSecondBuild,
}

class MapState extends ChangeNotifier {
  MapState({
    required this.debugMode,
    required this.devicePixelRatio,
    required this.initialCameraPosition,
    required this.debugBuildStage,
  });
  //! Misc
  final bool debugMode;
  final DebugBuildStage debugBuildStage;
  final double devicePixelRatio;

  //! Default Markers
  /// Keys to use when generating and finding RepaintBoundary for default place marker
  GlobalKey defaultPlaceRepaintBoundaryKey =
      GlobalKey(debugLabel: 'defaultPlaceRepaintBoundaryKey');

  /// Keys to use when generating and finding RepaintBoundary for default cluster markers
  GlobalKey defaultClusterRepaintBoundaryKey =
      GlobalKey(debugLabel: 'defaultClusterRepaintBoundaryKey');

  /// This will be marked as initialised once bitmaps for the default markers are generated
  bool get defaultBitmapsInitialised =>
      defaultPlaceMarkerBitmap != null && defaultClusterMarkerBitmap != null;

  BitmapDescriptor? defaultPlaceMarkerBitmap;
  BitmapDescriptor? defaultClusterMarkerBitmap;

  /// Converts the default markers to bitmaps
  ///
  /// Should only be called once after first layout of default markers
  Future<void> initDefaultBitmaps(BuildContext context) async {
    logger.v('initDefaultBitmaps: running');
    await asyncTryCatchHandler(
      tryFunction: () async {
        final devicePixelRatio = Injector.map(context).devicePixelRatio;
        // convert to bitmap
        defaultPlaceMarkerBitmap = await boundaryKeyToBitmap(
            defaultPlaceRepaintBoundaryKey, devicePixelRatio);
        defaultClusterMarkerBitmap = await boundaryKeyToBitmap(
            defaultClusterRepaintBoundaryKey, devicePixelRatio);
        notifyListeners(); // defaultBitmapsInitialised => true
      },
    );
  }

  //! Generated Markers
  List<CachedCluster> _cachedClusters = [];
  List<CachedCluster> get cachedClusters => _cachedClusters;

  List<CachedPlace> _cachedPlaces = [];
  List<CachedPlace> get cachedPlaces => _cachedPlaces;

  /// For initMapTripleBuildCycle, should be called after clusters are
  /// initialised in clusterManager
  ///
  /// For refreshMapDoubleBuildcycle, should be called after clusters are
  /// refreshed in clusterManager
  Future<void> updateCachedPlacesAndClusters() async {
    logger.v('updating _cachedClusters and _cachedPlaces');
    _assertClusterManagerInitialised();
    final clusterManagerClusters = await _clusterManager!.getMarkers();
    if (clusterManagerClusters.isEmpty) {
      throw StateError(
          'updateCachedPlacesAndClusters called and there are no clusters in the cluster manager');
    }
    // clear previous cache
    _cachedClusters = [];
    _cachedPlaces = [];
    // add new ones
    for (final cluster in clusterManagerClusters) {
      if (cluster.isMultiple) {
        _cachedClusters.add(
          CachedCluster(
            clusterSize: cluster.count,
            clusterManagerId: cluster.getId(),
            repaintBoundaryKey: GlobalKey(debugLabel: cluster.getId()),
          ),
        );
      } else {
        _cachedPlaces.add(
          CachedPlace(
            clusterManagerId: cluster.getId(),
            repaintBoundaryKey: GlobalKey(debugLabel: cluster.getId()),
          ),
        );
      }
    }
  }

  /// A change in the value of this flag triggers the rebuild of
  /// RepaintBoundaryGenerator
  ///
  /// The value is trivial; the value change triggers the Selector of this flag
  /// to rebuild.
  bool _shouldRebuildRepaintBoundaryGenerator = false;
  bool get shouldRebuildRepaintBoundaryGenerator =>
      _shouldRebuildRepaintBoundaryGenerator;
  void rebuildRepaintBoundaryGenerator() {
    _shouldRebuildRepaintBoundaryGenerator =
        !_shouldRebuildRepaintBoundaryGenerator;
    notifyListeners();
  }

  /// Generates bitmaps for all CachedClusters and CachedPlaces
  ///
  /// Should only be called after RepaintBoundaries are built
  Future<void> convertCachedRepaintBoundariesToBitmaps() async {
    if (_cachedClusters.isEmpty && _cachedPlaces.isEmpty) {
      throw StateError(
          'convertCachedRepaintBoundariesToBitmaps called when _cachedClusters and _cachedPlaces are both empty');
    }
    for (var element in _cachedClusters) {
      element.bitmap = await boundaryKeyToBitmap(
          element.repaintBoundaryKey, devicePixelRatio);
    }
    for (var element in _cachedPlaces) {
      element.bitmap = await boundaryKeyToBitmap(
          element.repaintBoundaryKey, devicePixelRatio);
    }
  }

  /// Returns bitmap for a CachedCluster or CachedPlace.
  ///
  /// Should only be called after convertCachedRenderKeysToBitmaps is done
  BitmapDescriptor getBitmapFromClusterManagerId(
      BuildContext context, String clusterManagerId) {
    if (_cachedClusters.isEmpty && _cachedPlaces.isEmpty) {
      throw StateError(
          'getBitmapFromClusterManagerId called when _cachedClusters and _cachedPlaces are both empty');
    }
    logger.v(
        'Looking for clusterManagerId: $clusterManagerId in _cachedClusters and _cachedPlaces');
    for (var element in _cachedClusters) {
      logger.v('_cachedCluster: ${element.clusterManagerId}');
      if (element.clusterManagerId == clusterManagerId) {
        if (element.bitmap == null) {
          throw StateError(
              'CachedCluster with matching clusterManagerId found, but bitmap is null');
        } else {
          return element.bitmap!;
        }
      }
    }
    for (var element in _cachedPlaces) {
      logger.v('_cachedPlace: ${element.clusterManagerId}');

      if (element.clusterManagerId == clusterManagerId) {
        if (element.bitmap == null) {
          throw StateError(
              'CachedPlace with matching clusterManagerId found, but bitmap is null');
        } else {
          return element.bitmap!;
        }
      }
    }

    /// At this stage, no matching clusterManagerId was found in _cachedClusters or _cachedPlaces.
    /// If this method is called from RefreshMapDoubleBuildCycle.firstBuild,
    /// then it might be because there is a new Place in the map view which was not present in the previous build cycle.
    /// In this case, return default cluster or place marker
    RefreshMapBuildState refreshMapBuildState =
        Injector.refreshMapBuild(context);
    if (refreshMapBuildState.refreshMapDoubleBuildCycle &&
        refreshMapBuildState.inFirstBuild) {
      if (!defaultBitmapsInitialised) {
        throw StateError(
            'Tried to return defaultBitmap when it is not initialised yet');
      }
      // check to see if the clusterManagerId is for a place or cluster
      if (ClusterManagerIdUtils.isCluster(clusterManagerId)) {
        return defaultClusterMarkerBitmap!;
      } else {
        return defaultPlaceMarkerBitmap!;
      }
    }

    throw StateError(
        'No matching clusterManagerId found in _cachedClusters or _cachedPlaces');
  }

  //! Google Map
  GoogleMapController? _mapController;

  final CameraPosition initialCameraPosition;

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    _assertClusterManagerInitialised();
    _clusterManager!.setMapId(controller.mapId);
  }

  void onCameraMove(CameraPosition cameraPosition) {
    _assertClusterManagerInitialised();
    _clusterManager!.onCameraMove(cameraPosition);
  }

  /// Pans and zooms CameraPosition of GoogleMap to desired [position].
  ///
  /// If [cluster] is true, the CameraPosition is centered on the provided [position].
  Future<void> zoomToMarker(
      {required LatLng position, required bool cluster}) async {
    if (_mapController == null) {
      throw StateError('zoomToMarker called when _mapController is null');
    }
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          bearing: 0,
          target: (() {
            if (cluster) {
              return position;
            } else {
              LatLng offsetPosition = LatLng(
                  position.latitude -
                      0.0035, // minus offset to show marker above SiteCard
                  // position.latitude - 0.0035 + _googleLogoPaddingCorrection,
                  position.longitude);
              return offsetPosition;
            }
          }()),
          tilt: 0,
          zoom: cluster ? 14 : 16,
        ),
      ),
    );
  }

  //! Cluster Manager
  bool get clusterManagerInitialised => _clusterManager != null;

  /// Do not access this directly, only to be used as setter.
  ClusterManager? _clusterManager;

  // change this back to getter
  void _assertClusterManagerInitialised() {
    if (_clusterManager == null) {
      throw StateError(
          '_clusterManager should be initialised before Google Map is created');
    }
  }

  /// Should be called before map is created
  void initClusterManager(
      {required List<Place> places,
      required Function(Set<Marker>) updateMarkers,
      required Future<Marker> Function(Cluster<Place>)? markerBuilder}) {
    logger.v('initClusterManager: $places');

    _clusterManager = ClusterManager<Place>(
      places, updateMarkers,
      markerBuilder: markerBuilder,
      stopClusteringZoom: 13.0, //  zoom level above which clustering stops
    );
  }

  /// Function to rebuilds the markers, does not start the entire double build cycle.
  ///
  /// Calls clusterManager.updateMap()
  /// Named as such to avoid confusion with [startRefreshMapDoubleBuildCycle]
  ///
  /// For initMapTripleBuildCycle, clusterManager.updateMap is automatically
  /// called on init of clusterManager, so it should only be called after
  /// [convertCachedRepaintBoundariesToBitmaps]
  ///
  /// For refreshMapDoubleBuildCycle, should be called at start and
  /// after [convertCachedRepaintBoundariesToBitmaps]
  void callMarkerBuilderAndUpdateMarkersCallback() {
    logger.i('rebuildMarkers');
    _assertClusterManagerInitialised();
    _clusterManager!.updateMap();
  }
}
