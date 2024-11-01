import 'package:calendar_scheduler/firebase_options.dart';
import 'package:calendar_scheduler/screen/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tzycdzypylruydfzyoac.supabase.co',
    anonKey:'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6eWNkenlweWxydXlkZnp5b2FjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDM0OTQwNjUsImV4cCI6MjAxOTA3MDA2NX0.D5Jzu_ve7cdR8qssdFGhN3mgasE8Cq5meGp_mAzJZcQ',
  );

  await initializeDateFormatting();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthScreen(),
    ),
  );
}
