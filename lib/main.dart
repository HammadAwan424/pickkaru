import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/root_router.dart';
import 'firebase_options.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/mock/mock_user_overlay.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/mock/mock_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

// Pass your access token to MapboxOptions so you can load a map
  String ACCESS_TOKEN = const String.fromEnvironment("ACCESS_TOKEN");
  print("ACCESS TOKEN: $ACCESS_TOKEN");
  MapboxOptions.setAccessToken(ACCESS_TOKEN);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final container = ProviderContainer();
  const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  
  if (appEnv != 'production') {
    String emulatorHost = 'localhost';
    if (!kIsWeb && Platform.isAndroid) {
      emulatorHost = '10.0.2.2';
    }
    
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    
    await seedMockData(container, emulatorHost);
  }

  runApp(UncontrolledProviderScope(
    container: container,
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Pickkaru',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: RootRouter(),
      builder: (context, child) {
        const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
        if (appEnv == 'production') return child!;
        
        return Stack(
          children: [
            child!,
            const Positioned(
              bottom: 20,
              left: 20,
              child: MockUserOverlay(),
            ),
          ],
        );
      },
    );
  }
}
