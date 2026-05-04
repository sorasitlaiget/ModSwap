import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/api_config.dart';
import 'providers/auth_provider.dart';
import 'screen/auth_gate.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (ApiConfig.useEmulator) {
    await FirebaseAuth.instance.useAuthEmulator(
      ApiConfig.emulatorHost,
      ApiConfig.authEmulatorPort,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(
      ApiConfig.emulatorHost,
      ApiConfig.firestoreEmulatorPort,
    );
  }

  // Create AuthState ONCE here (outside the widget tree)
  // This ensures it persists and there's exactly one instance
  final authState = AuthState.create();
  debugPrint('[main] AuthState created');

  runApp(ModSwapApp(authState: authState));
}

class ModSwapApp extends StatelessWidget {
  final AuthState authState;

  const ModSwapApp({super.key, required this.authState});

  @override
  Widget build(BuildContext context) {
    debugPrint('[ModSwapApp] building');

    return ChangeNotifierProvider<AuthState>.value(
      value: authState,
      child: MaterialApp(
        title: 'ModSwap',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.orange,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.orange,
            primary: AppColors.orange,
            secondary: AppColors.navy,
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
