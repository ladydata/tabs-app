import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tabs/config/firebase_options.dart';
import 'package:tabs/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // Note: This will throw until you run `flutterfire configure`
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase not configured yet. Run: flutterfire configure');
  }

  runApp(
    const ProviderScope(
      child: TabsApp(),
    ),
  );
}
