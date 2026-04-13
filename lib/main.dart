import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'data/hive_adapters.dart';
import 'data/json_loader.dart';
import 'services/save_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    registerHiveAdapters();
    await SaveService.instance.init();
    await JsonLoader.instance.loadAll();
  } catch (e, stack) {
    debugPrint('Init error: $e');
    debugPrint('$stack');
  }

  runApp(
    const ProviderScope(
      child: OnuncuDalApp(),
    ),
  );
}
