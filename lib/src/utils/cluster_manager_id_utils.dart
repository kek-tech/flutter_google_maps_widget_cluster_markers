abstract class ClusterManagerIdUtils {
  // clusterManagerId == ClusterManager.cluster.getId(), has format lat_lng_clusterSize
  static bool isCluster(String clusterManagerId) {
    int clusterSizeString = int.parse((clusterManagerId.split('_')[2]));
    if (clusterSizeString == 1) {
      return false;
    } else {
      return true;
    }
  }

  /// Takes lat_lng_clusterSize and returns lat_lng
  static String clusterManagerIdToLatLngId(String clusterManagerId) {
    final temp = clusterManagerId.split('_');
    return '${temp[0]}_${temp[1]}';
  }
}
