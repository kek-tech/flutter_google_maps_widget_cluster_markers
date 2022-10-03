//! Utils
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dev_utils/flutter_dev_utils.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/debug_needs_paint_exception.dart';
import 'package:flutter_google_maps_widget_cluster_markers/src/utils/logger.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;

/// Converts render repaint boundary to bitmap
///
/// boundary.toImage throws Failed assertion: '!debugNeedsPaint': is not true when in debugMode
/// Likely due to calling RenderObject.markNeedsPaint recursively
/// (e.g., from some animation),
/// so conversion needs to wait until debugNeedsPaint is false again else
/// error is thrown from assert(!debugNeedsPaint) in toImage()
///
/// Problem should not occur in release mode
/// If need solution for debugMode: https://stackoverflow.com/questions/57645037/unable-to-take-screenshot-in-flutter
Future<BitmapDescriptor> boundaryToBitmap(
    RenderRepaintBoundary boundary, double devicePixelRatio) async {
  return await asyncTryHandler(
    tryFunction: () async {
      logger.v('Converting RenderRepaintBoundary to Image');
      // boundary to image
      ui.Image image = await boundary.toImage(pixelRatio: devicePixelRatio);
      logger.v('Converting Image to ByteData');
      // image to byte data
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png) as ByteData;
      logger.v('Converting ByteData to Uint8List');
      // byte data to uint8list
      var pngBytes = byteData.buffer.asUint8List();

      logger.v('Converting Uint8List to BitmapDescriptor');
      return BitmapDescriptor.fromBytes(pngBytes);
    },
    catchKnownExceptions: {
      AssertionError(): (e) async {
        if ((e as AssertionError)
            .message
            .toString()
            .contains("'!debugNeedsPaint': is not true.")) {
          throw DebugNeedsPaintException();
        }
      },
    },
  );
}

/// Convenience wrapper for getting RenderRepaintBoundary from key before
/// calling [boundaryToBitmap]
Future<BitmapDescriptor> boundaryKeyToBitmap(
    GlobalKey boundaryKey, double devicePixelRatio) async {
  return await asyncTryHandler(
    tryFunction: () async {
      if (boundaryKey.currentContext == null) {
        final error =
            'Could not find the build context in which the widget with this key builds. boundaryKey: ${boundaryKey.toString()}';
        logger.e(error);
        throw StateError(error);
      }
      RenderRepaintBoundary boundary = boundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      logger.v(
          'Found RenderRepaintBoundary with boundaryKey: ${boundaryKey.toString()}, converting to bitmap.');
      return boundaryToBitmap(boundary, devicePixelRatio);
    },
  );
}
