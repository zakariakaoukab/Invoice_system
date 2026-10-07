import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'firebase_options.dart';
import 'features/invoice/pdf_invoice_generator.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enforce local session persistence if supported by platform
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (_) {}

  // Disable Firestore local persistence on Windows desktop to prevent
  // abort() crashes in the Firebase C++ SDK during debug builds.
  if (!kIsWeb && Platform.isWindows) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  // Preload heavy PDF assets in the background to ensure instantaneous print speeds
  PdfInvoiceGenerator.preloadAssets().ignore();

  runApp(
    const ProviderScope(
      child: DarBelAmriApp(),
    ),
  );
}
