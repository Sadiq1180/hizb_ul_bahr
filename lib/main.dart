import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve the native splash screen so it stays visible
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize pdfrx
  await pdfrxFlutterInitialize();

  // Keep the splash visible for 2 more seconds
  await Future.delayed(const Duration(seconds: 1));

  // Remove the native splash and show the app
  FlutterNativeSplash.remove();

  runApp(const HizbUlBahrApp());
}
