class DebugNeedsPaintException implements Exception {
  String cause =
      """Likely due to calling RenderObject.markNeedsPaint recursively 
      (e.g., from some animation). Problem should only occur in debug mode, if
      you see this error in release mode, please submit an issue.""";
  DebugNeedsPaintException();
}
