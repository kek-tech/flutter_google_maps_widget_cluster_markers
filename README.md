<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# flutter_google_maps_widget_cluster_markers

![Alt Text](https://github.com/Kek-Tech/flutter_google_maps_widget_cluster_markers/blob/main/example.gif)

This widget implements a very specific adaptation of google_maps_cluster_manager, allowing different ,markers to be shown depending on whether it is a Cluster or a Place (Cluster of size 1). Different markers can also be shown depending on its location (allows the marker to wait for information from external APIs).


# 1. Getting started
## 1.1. Dependencies
Add the following dependencies to your pubspec.yaml
- google_maps_cluster_manager: https://pub.dev/packages/google_maps_cluster_manager
- google_maps_flutter: https://pub.dev/packages/google_maps_flutter

## 1.2. Setup
Follow setup on 
- google_maps_flutter to enable Google Maps

# 2. Usage

Just call the `GoogleMapWidgetClusterMarkers` constructor to instantiate the widget.

A controller can be supplied to expose more package functions, e.g. to refresh the map or update places.

```dart
GoogleMapWidgetClusterMarkersController controller = GoogleMapWidgetClusterMarkersController()


GoogleMapWidgetClusterMarkers(
          controller: controller,
          clusterMarkerTextStyle: const TextStyle(
            fontSize: 100,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          places: [
            MyPlace(
              name: 'Tottenham Court Road',
              latLng: const LatLng(51.51630, -0.13000),
            ),
            MyPlace(
              name: 'Chinatown',
              latLng: const LatLng(51.51090, -0.13160),
            ),
            MyPlace(
              name: 'Covent Garden',
              latLng: const LatLng(51.51170, -0.12400),
            ),
            MyPlace(
              name: 'Imperial College',
              latLng: const LatLng(51.4988, -0.1749),
            ),
          ],
          defaultPlaceMarker: Container(
            color: Colors.orange,
            height: 100,
            width: 100,
            child: const Icon(
              Icons.circle,
              size: 150,
            ),
          ),
          defaultClusterMarker: const Icon(
            Icons.hexagon,
            size: 150,
          ),
          clusterMarker: const Icon(
            Icons.hexagon,
            size: 150,
          ),
          placeMarkerBuilder: (latLngId) => Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.circle,
                size: 150,
              ),
              Text(
                /// This can return data from some API query.
                '${Random().nextInt(9)}',
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
```

# 3. Additional information

## 3.1. How it works
There are three types of build cycles, used to implement the package

### 3.1.1. An initMapTripleBuildCycle, which occurs the first time GoogleMap is built

FIRST BUILD

1. DefaultRepaintBoundaryGenerator builds
2. DefaultRenderRepaintBoundaries converted to DefaultBitmaps
3. GoogleMap built
4. ClusterManager initialised (with Places, GoogleMapController.id) but
no clusters in view (because map has not rendered)
5. GoogleMap renders and calls onCameraIdle

SECOND BUILD

6. MapState.refreshMarkerBuilderAndUpdateMarkerCallback() to get clusters in view
and use DefaultBitmaps

THIRD BUILD

7. MapState.updateCachedPlacesAndClusters() splits clusterManager.clusters
into a List<CachedCluster> and List<CachedPlace> in state (so that there is
a cached reference when updateMap is called).
CachedCluster and CachedPlace contain a repaintBoundaryKey and
clusterManagerId (so that markerBuilder knows which one to use).
Additionally, CachedCluster contains clusterSize to display on the Marker,
and CachedPlace contains the latLngId so that API requests can be made to
furnish the Marker with information (e.g., occupancy).
8. ClusterBoundaryGenerator and PlaceBoundaryGenerator then builds a
RepaintBoundary for each CachedCluster and CachedPlace, using both the
repaintBoundaryKey and other info (clusterSize, latLngId)
9. MapState.storeBitmapsInCache() then converts each CachedPlace and
CachedCluster repaintBoundaryKey into a bitmap and stores it
10. ClusterManager.updateMap is then called, and markerBuilderCallback uses
the newly generated bitmaps

### 3.1.2. A refreshMapDoubleBuildCycle, which occurs whenever the GoogleMap is refreshed

FIRST BUILD

1. MapState.refreshMarkerBuilderAndUpdateMarkerCallback() to get clusters in view
and use DefaultBitmaps

SECOND BUILD

2. MapState.updateCachedPlacesAndClusters() splits clusterManager.clusters
into a List<CachedCluster> and List<CachedPlace> in state (so that there is
a cached reference when updateMap is called).
CachedCluster and CachedPlace contain a repaintBoundaryKey and
clusterManagerId (so that markerBuilder knows which one to use).
Additionally, CachedCluster contains clusterSize to display on the Marker,
and CachedPlace contains the latLngId so that API requests can be made to
furnish the Marker with information (e.g., occupancy).
3. ClusterBoundaryGenerator and PlaceBoundaryGenerator then builds a
RepaintBoundary for each CachedCluster and CachedPlace, using both the
repaintBoundaryKey and other info (clusterSize, latLngId)
4. MapState.storeBitmapsInCache() then converts each CachedPlace and
CachedCluster repaintBoundaryKey into a bitmap and stores it
5. ClusterManager.updateMap is then called, and markerBuilderCallback uses
the newly generated bitmaps

### 3.1.3. An updatePlacesDoubleBuildCycle, which occurs occurs whenever the places in clusterManager is updated. This cycle uses the second and third build of initMapTripleBuildCycle

FIRST BUILD

1. MapState.refreshMarkerBuilderAndUpdateMarkerCallback() to get clusters in view
and use DefaultBitmaps

SECOND BUILD

2. MapState.updateCachedPlacesAndClusters() splits clusterManager.clusters
into a List<CachedCluster> and List<CachedPlace> in state (so that there is
a cached reference when updateMap is called).
CachedCluster and CachedPlace contain a repaintBoundaryKey and
clusterManagerId (so that markerBuilder knows which one to use).
Additionally, CachedCluster contains clusterSize to display on the Marker,
and CachedPlace contains the latLngId so that API requests can be made to
furnish the Marker with information (e.g., occupancy).
3. ClusterBoundaryGenerator and PlaceBoundaryGenerator then builds a
RepaintBoundary for each CachedCluster and CachedPlace, using both the
repaintBoundaryKey and other info (clusterSize, latLngId)
4. MapState.storeBitmapsInCache() then converts each CachedPlace and
CachedCluster repaintBoundaryKey into a bitmap and stores it
5. ClusterManager.updateMap is then called, and markerBuilderCallback uses
the newly generated bitmaps

## 3.2. Note:
* clusterManagerId == ClusterManager.cluster.getId(), has format lat_lng_clusterSize
* latLngId has format lat_lng
* RepaintBoundary is converted into Bitmap via: RepaintBoundary > RenderRepaintBoundary > Image > ByteDate > BitmapDescriptor


TODO: Tell users more about the package: how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
