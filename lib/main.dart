import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NexPayAdminApp());
}

class NexPayAdminApp extends StatelessWidget {
  const NexPayAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()..fetchAllData()),
      ],
      child: MaterialApp(
        title: 'NexPay Executive Console',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: AppConstants.background,
          primaryColor: AppConstants.accentGreen,
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppConstants.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: AppConstants.textPrimary),
            titleTextStyle: TextStyle(color: AppConstants.textPrimary, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          cardTheme: CardThemeData(
            color: AppConstants.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppConstants.borderColor),
            ),
          ),
          colorScheme: const ColorScheme.light(
            primary: AppConstants.accentGreen,
            surface: AppConstants.surface,
            onSurface: AppConstants.textPrimary,
          ),
        ),
        home: const MainAdminLayout(),
      ),
    );
  }
}