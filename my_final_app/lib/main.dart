import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/api_config.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'screen/auth_gate.dart';
import 'services/remote_config_service.dart';
import 'theme/app_colors.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics — disabled on web (not supported)
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Remote Config feature flags
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
    FirebaseStorage.instance.useStorageEmulator(
      ApiConfig.emulatorHost,
      9199, // พอร์ตตรงตามไฟล์ firebase.json ของคุณเป๊ะๆ
    );
  }

  // Create AuthState ONCE here (outside the widget tree)
  // This ensures it persists and there's exactly one instance
  final authState = AuthState.create();
  AppLogger.d('[main] AuthState created');

  runApp(ModSwapApp(authState: authState));
}

class ModSwapApp extends StatelessWidget {
  final AuthState authState;

  const ModSwapApp({super.key, required this.authState});

  @override
  Widget build(BuildContext context) {
    AppLogger.d('[ModSwapApp] building');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>.value(value: authState),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'ModSwap',
            debugShowCheckedModeBanner: false,
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
              dialogTheme: const DialogThemeData(
                backgroundColor: Color(0xFF1E1E1E),
              ),
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
            themeMode: themeProvider.mode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
