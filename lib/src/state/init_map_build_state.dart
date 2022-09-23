import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/map_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/injector.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/logger.dart';

class InitMapBuildState extends ChangeNotifier {
  //! Build Members
  /// Double build cycle flag used when the Google Map is created for the first time
  ///
  /// Is false after the first double build cycle to prevent user from reinitialising
  bool allowInitMapTripleBuildCycle = true;

  /// Build cycle flag
  bool initMapTripleBuildCycle = false;

  /// Build flag
  bool inFirstBuild = false;

  /// Build flag
  bool inSecondBuild = false;

  /// Build flag
  bool inThirdBuild = false;

  void startFirstBuild() {
    logger.w('==========INIT MAP TRIPLE BUILD START==========');
    logger.w('==========startFirstBuild==========');
    if (!allowInitMapTripleBuildCycle) {
      throw StateError(
          'startFirstBuild() should only be called once, but it has been called before.');
    } else {
      allowInitMapTripleBuildCycle = false;
      initMapTripleBuildCycle = true;

      if (inFirstBuild) {
        throw StateError(
            'Tried to call startFirstBuild() when inFirstBuild is already true');
      }
      inFirstBuild = true;
    }
  }

  Future<void> startSecondBuild(BuildContext context) async {
    logger.w('==========startSecondBuild==========');
    if (!initMapTripleBuildCycle) {
      throw StateError(
          '''Tried to call startSecondBuild() when initMapTripleBuildCycle is false.
            \nCheck to see if startInitMapFirstBuild() was called.''');
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
      Injector.map(context).callMarkerBuilderAndUpdateMarkersCallback();
    }
  }

  Future<void> startThirdBuild(BuildContext context) async {
    logger.w('==========startThirdBuild==========');
    if (!initMapTripleBuildCycle) {
      throw StateError(
          '''Tried to call startThirdBuild() when initMapTripleBuildCycle is false.
            \nCheck to see if startInitMapFirstBuild() was called.''');
    } else {
      if (!inSecondBuild) {
        throw StateError(
            'Tried to call startThirdBuild() when inSecondBuild is already false.');
      } else if (inThirdBuild) {
        throw StateError(
            'Tried to call startThirdBuild() when inThirdBuild is already true.');
      }
      inSecondBuild = false;
      inThirdBuild = true;
      MapState mapState = Injector.map(context);
      await mapState.updateCachedPlacesAndClusters();
      mapState.rebuildRepaintBoundaryGenerator();
    }
  }

  void endThirdBuild() {
    initMapTripleBuildCycle = false;
    inThirdBuild = false;
    allowInitMapTripleBuildCycle = false;
    logger.w('==========INIT MAP TRIPLE BUILD END==========');
  }
}
