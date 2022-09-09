import 'package:flutter/material.dart';
import 'package:flutter_dev_utils/flutter_dev_utils.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/map_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/boundary_key_to_bitmap.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/injector.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/logger.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  }

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
}
