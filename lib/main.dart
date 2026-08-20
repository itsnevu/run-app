import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'state/penyedia.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pref = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [prefProvider.overrideWithValue(pref)],
      child: const AplikasiRukun(),
    ),
  );
}
