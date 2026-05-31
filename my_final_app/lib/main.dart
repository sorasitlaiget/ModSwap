import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'config/api_config.dart';
import 'presentation/providers/theme_notifier.dart';
import 'router/app_router.dart';
import 'services/remote_config_service.dart';
import 'theme/app_colors.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await RemoteConfigService().initialize();

  if (ApiConfig.useEmulator) {
    await FirebaseAuth.instance.useAuthEmulator(
      ApiConfig.emulatorHost,
      ApiConfig.authEmulatorPort,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(
      ApiConfig.emulatorHost,
      ApiConfig.firestoreEmulatorPort,
    );
    FirebaseStorage.instance.useStorageEmulator(ApiConfig.emulatorHost, 9199);
  }

  AppLogger.d('[main] Starting ModSwap');

  runZonedGuarded(
    () => runApp(const ProviderScope(child: ModSwapApp())),
    (error, stack) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

class ModSwapApp extends ConsumerWidget {
  const ModSwapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.d('[ModSwapApp] building');

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      title: 'ModSwap',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.orange,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.orange,
          primary: AppColors.orange,
          secondary: AppColors.navy,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.orange,
        scaffoldBackgroundColor: const Color(0xFF121212),
        canvasColor: const Color(0xFF1E1E1E),
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: const Color(0xFF2A2A2A),
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E1E1E)),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.orange,
          primary: AppColors.orange,
          secondary: AppColors.navy,
          surface: const Color(0xFF1E1E1E),
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        useMaterial3: true,
      ),
      themeMode: themeMode,
    );
  }
}
