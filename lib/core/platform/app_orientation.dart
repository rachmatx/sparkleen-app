import 'package:flutter/services.dart';

/// Apply before runApp so the first Flutter frame is portrait, too.
Future<void> lockAppOrientation() =>
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
