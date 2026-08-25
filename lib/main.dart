import 'dart:async';

import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'app_controller.dart';
import 'background_tasks.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Workmanager().initialize(backgroundCallbackDispatcher);
  } catch (_) {
    // Background scheduling may be unavailable on a simulator.
  }
  final controller = AppController();
  runApp(SteamAuthenticatorApp(controller: controller));
  unawaited(controller.initialize());
}
