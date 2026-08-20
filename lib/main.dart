import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/konfigurasi.dart';
import 'state/penyedia.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final pref = await SharedPreferences.getInstance();

  // Tanpa kredensial, aplikasi berjalan sepenuhnya lokal dengan tetangga
  // tersimulasi. Semua mekanik tetap bisa dijalankan dan diuji.
  SupabaseClient? klien;
  if (Konfigurasi.pakaiSupabase) {
    await Supabase.initialize(
      url: Konfigurasi.supabaseUrl,
      publishableKey: Konfigurasi.supabaseKunciPublik,
    );
    klien = Supabase.instance.client;
  }

  runApp(
    ProviderScope(
      overrides: [
        prefProvider.overrideWithValue(pref),
        supabaseProvider.overrideWithValue(klien),
      ],
      child: const AplikasiRukun(),
    ),
  );
}
