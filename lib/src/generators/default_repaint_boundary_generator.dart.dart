import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/injector.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/logger.dart';

class DefaultRepaintBoundaryGenerator extends StatefulWidget {
  const DefaultRepaintBoundaryGenerator({
    required this.defaultPlaceRepaintBoundaryKey,
    required this.defaultClusterRepaintBoundaryKey,
    required this.defaultPlaceMarker,
    required this.defaultClusterMarker,
    Key? key,
  }) : super(key: key);

  final GlobalKey defaultPlaceRepaintBoundaryKey;
  final GlobalKey defaultClusterRepaintBoundaryKey;

  final Widget defaultPlaceMarker;
  final Widget defaultClusterMarker;

  @override
  State<DefaultRepaintBoundaryGenerator> createState() =>
      _DefaultRepaintBoundaryGeneratorState();
}

class _DefaultRepaintBoundaryGeneratorState
    extends State<DefaultRepaintBoundaryGenerator> with AfterLayoutMixin {
  @override
  void afterFirstLayout(BuildContext context) {
    logger.v('afterFirstLayout');
    Injector.map(context).initDefaultBitmaps(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DefaultRepaintBoundaryGenerator'),
          RepaintBoundary(
            key: widget.defaultPlaceRepaintBoundaryKey,
            child: widget.defaultPlaceMarker,
          ),
          RepaintBoundary(
            key: widget.defaultClusterRepaintBoundaryKey,
            child: widget.defaultClusterMarker,
          ),
        ],
      ),
    );
  }
}
