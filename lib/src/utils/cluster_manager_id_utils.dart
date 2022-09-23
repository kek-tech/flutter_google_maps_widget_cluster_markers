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
}
