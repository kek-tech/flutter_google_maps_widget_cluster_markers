import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/init_map_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/map_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/refresh_map_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/injector.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/logger.dart';

/// Generates RepaintBoundary for each CachedCluster and CachedPlace
///
/// After the first render, converts the RenderRepaintBoundary belonging to each
/// RepaintBoundary into a Bitmap
class RepaintBoundaryGenerator extends StatefulWidget {
  const RepaintBoundaryGenerator({
    required this.clusterMarker,
    required this.placeMarkerBuilder,
    Key? key,
  }) : super(key: key);

  final Widget clusterMarker;
  final Widget Function(String latLngId) placeMarkerBuilder;

  @override
  State<RepaintBoundaryGenerator> createState() =>
      _RepaintBoundaryGeneratorState();
}

class _RepaintBoundaryGeneratorState extends State<RepaintBoundaryGenerator>
    with AfterLayoutMixin<RepaintBoundaryGenerator> {
  late List<GlobalKey> keyList;
  //! 1.
  List<RepaintBoundary> generateRepaintBoundaries(BuildContext context) {
    MapState mapState = Injector.map(context);
    List<RepaintBoundary> repaintBoundaries = [];

    //! Generate RepaintBoundaries for CachedClusters
    for (var element in mapState.cachedClusters) {
      repaintBoundaries.add(
        RepaintBoundary(
            key: element.repaintBoundaryKey,
            child: Stack(
              alignment: Alignment.center,
              children: [
                widget.clusterMarker,
                Text('${element.clusterSize}'),
              ],
            )),
      );
    }
    //! Generate RepaintBoundaries for CachedPlaces
    for (var element in mapState.cachedPlaces) {
      repaintBoundaries.add(
        RepaintBoundary(
          key: element.repaintBoundaryKey,
          child: widget.placeMarkerBuilder(element.latLngId),
        ),
      );
    }
    return repaintBoundaries;
  }

  //! 2. Build
  @override
  Widget build(BuildContext context) {
    logger.v('RepaintBoundaryGenerator: REBUILDING');
    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RepaintBoundaryGenerator'),
          const SizedBox(height: 50),
          ...generateRepaintBoundaries(context),
        ],
      ),
    );
  }

  //! 3.
  @override
  void afterFirstLayout(BuildContext context) async {
    logger.v('');
    MapState mapState = Injector.map(context);
    InitMapBuildState initMapBuildState = Injector.initMapBuild(context);
    RefreshMapBuildState refreshMapBuildState =
        Injector.refreshMapBuild(context);
    if (initMapBuildState.initMapTripleBuildCycle) {
      if (initMapBuildState.inFirstBuild) {
        throw StateError(
            'RepaintBoundaryGenerator called in initMapBuildState.inFirstBuild, where ClusterManager is not initialised yet');
      } else if (initMapBuildState.inSecondBuild) {
        throw StateError(
            'RepaintBoundaryGenerator called in initMapBuildState.inSecondBuild, where there are no clusters yet');
      } else if (initMapBuildState.inThirdBuild) {
        logger.v('''initMapTripleBuildCycle: inThirdBuild:''');
        await mapState.convertCachedRepaintBoundariesToBitmaps();
        mapState.callMarkerBuilderAndUpdateMarkersCallback();
      } else {
        throw UnimplementedError(
            '''Unimplemented Case: _updateMarkersCallback called when
            \ninitMapTripleBuildCycle: true
            \ninFirstBuild: false
            \ninSecondBuild: false''');
      }
    } else if (refreshMapBuildState.refreshMapDoubleBuildCycle) {
      if (refreshMapBuildState.inFirstBuild) {
        throw StateError(
            'RepaintBoundaryGenerator called in refreshMapBuildState.inFirstBuild, where the clusters are not refreshed yet');
      } else if (refreshMapBuildState.inSecondBuild) {
        logger.v('''refreshMapBuildState: inSecondBuild: ''');
        await mapState.convertCachedRepaintBoundariesToBitmaps();
        mapState.callMarkerBuilderAndUpdateMarkersCallback();
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
}
