import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/init_map_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/map_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/injector.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/logger.dart';

class RefreshMapBuildState extends ChangeNotifier {
  //! Build Members
  bool allowRefreshMapDoubleBuildCycle = false;
  // Double build cycle flag used when the Google Map exists and [refreshMarkers()] is called
  bool refreshMapDoubleBuildCycle = false;

  bool inFirstBuild = false;

  bool inSecondBuild = false;

  /// Master function to start refreshMapDoubleBuildCycle
  void startFirstBuild(BuildContext context) {
    logger.w('==========REFRESH MAP DOUBLE BUILD START==========');
    logger.w('==========startFirstBuild==========');

    InitMapBuildState initMapBuildState = Injector.initMapBuild(context);
    if (initMapBuildState.initMapTripleBuildCycle) {
      throw StateError(
          'Tried to call refreshMapBuildCycle.startFirstBuild() when initMapTripleBuildCycle is true.');
    } else {
      refreshMapDoubleBuildCycle = true;

      if (inFirstBuild) {
        throw StateError(
            'Tried to call startFirstBuild() when inFirstBuild is already true');
      }
      inFirstBuild = true;
      Injector.map(context).callMarkerBuilderAndUpdateMarkersCallback();
    }
  }

  Future<void> startSecondBuild(BuildContext context) async {
    logger.w('==========startSecondBuild==========');
    if (!refreshMapDoubleBuildCycle) {
      throw StateError(
          '''Tried to call startSecondBuild() when refreshMapDoubleBuildCycle is false.
            \nCheck to see if refreshMapBuild.startFirstBuild() was called.''');
    } else {
      if (!inFirstBuild) {
        throw StateError(
            'Tried to call startSecondBuild() when inFirstBuild is already false.');
      } else if (inSecondBuild) {
        throw StateError(
            'Tried to call startSecondBuild() when inSecondBuild is already true.');
      }
      inFirstBuild = false;
      inSecondBuild = true;
      MapState mapState = Injector.map(context);
      await mapState.updateCachedPlacesAndClusters();
      mapState.rebuildRepaintBoundaryGenerator();
    }
  }

  void endSecondBuild() {
    refreshMapDoubleBuildCycle = false;
    inSecondBuild = false;
    allowRefreshMapDoubleBuildCycle = true;
    logger.w('==========REFRESH MAP DOUBLE BUILD END==========');
  }
}
