import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hmbczhzpbpqqddsfappc.supabase.co',
    anonKey: 'sb_publishable_P8Or7ov09hF3aV4KFFLA8w_I7H_jwuP',
  );

  await Supabase.instance.client.auth.signOut();

  runApp(const MainApp());
}
