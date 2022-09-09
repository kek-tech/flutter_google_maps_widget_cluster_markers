import 'package:logger/logger.dart';

var logger = CallerLogger(
  ignoreCallers: {
    'syncTryCatchHandler',
    'asyncTryCatchHandler',
  },
  filter: TypeFilter(
    ignoreTypes: {},
    ignoreLevel: Level.warning,
  ),
  level: Level.verbose,
);
