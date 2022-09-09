import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/init_map_build_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/map_state.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/state/refresh_map_build_state.dart';
import 'package:provider/provider.dart';

///  State Injector

class Injector {
  static MapState map(BuildContext context) =>
      Provider.of<MapState>(context, listen: false);
  static InitMapBuildState initMapBuild(BuildContext context) =>
      Provider.of<InitMapBuildState>(context, listen: false);
  static RefreshMapBuildState refreshMapBuild(BuildContext context) =>
      Provider.of<RefreshMapBuildState>(context, listen: false);
}
