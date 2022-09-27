import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/flutter_google_maps_widget_cluster_markers.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/map_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/injector.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/logger.dart';

class UpdatePlacesBuildState extends ChangeNotifier {
  //! Build Members
  /// Build cycle flag used when the Google Map is created for the first time
  ///
  bool allowUpdatePlacesDoubleBuildCycle = false;

  /// Build cycle flag
  bool updatePlacesDoubleBuildCycle = false;

  /// Build flag
  bool inFirstBuild = false;

  /// Build flag
  bool inSecondBuild = false;

  Future<void> startFirstBuild(
      BuildContext context, List<Place> newPlaces) async {
    logger.w('==========UPDATE MARKERS DOUBLE BUILD START==========');
    logger.w('==========startFirstBuild==========');
    if (!allowUpdatePlacesDoubleBuildCycle) {
      throw StateError(
          'Tried to call updatePlacesDoubleBuildCycle.startFirstBuild() when allowUpdatePlacesDoubleBuildCycle is false.');
    } else {
      updatePlacesDoubleBuildCycle = true;
      Injector.refreshMapBuild(context).allowRefreshMapDoubleBuildCycle = false;
      if (inFirstBuild) {
        throw StateError(
            'Tried to call startFirstBuild() when inFirstBuild is already true');
      }
      inFirstBuild = true;
      Injector.map(context)
          .callMarkerBuilderAndUpdateMarkersCallbackWithNewPlaces(newPlaces);
      // Injector.map(context).callMarkerBuilderAndUpdateMarkersCallback();
    }
  }

  Future<void> startSecondBuild(BuildContext context) async {
    logger.w('==========startSecondBuild==========');
    if (!updatePlacesDoubleBuildCycle) {
      throw StateError(
          '''Tried to call startSecondBuild() when updatePlacesDoubleBuildCycle is false.
            \nCheck to see if startFirstBuild() was called.''');
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

  void endSecondBuild(BuildContext context) {
    updatePlacesDoubleBuildCycle = false;
    inSecondBuild = false;
    Injector.refreshMapBuild(context).allowRefreshMapDoubleBuildCycle = true;

    logger.w('==========UPDATE MARKERS DOUBLE BUILD END==========');
  }
}
