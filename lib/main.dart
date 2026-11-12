import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NexPayAdminApp());
}

class DesktopScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class NexPayAdminApp extends StatelessWidget {
  const NexPayAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => AdminProvider()..fetchAllData()),
      ],
      child: MaterialApp(
        title: 'NexPay Core — Institutional Admin Console',
        debugShowCheckedModeBanner: false,
        scrollBehavior: DesktopScrollBehavior(),
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: AppConstants.background,
          primaryColor: AppConstants.accentGreen,
          fontFamily: 'Segoe UI',
          colorScheme: const ColorScheme.light(
            primary: AppConstants.accentGreen,
            onPrimary: Colors.white,
            secondary: AppConstants.accentBlue,
            onSecondary: Colors.white,
            surface: AppConstants.surface,
            onSurface: AppConstants.textPrimary,
            error: AppConstants.dangerRed,
          ),
          scrollbarTheme: ScrollbarThemeData(
            thumbVisibility: WidgetStateProperty.all(true),
            trackVisibility: WidgetStateProperty.all(true),
            interactive: true,
            thickness: WidgetStateProperty.all(8),
            radius: const Radius.circular(6),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered) || states.contains(WidgetState.dragged)) {
                return AppConstants.textMuted;
              }
              return AppConstants.borderStrong;
            }),
            trackColor: WidgetStateProperty.all(AppConstants.surfaceCard),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppConstants.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: AppConstants.textPrimary, size: 20),
            titleTextStyle: TextStyle(
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          cardTheme: CardThemeData(
            color: AppConstants.surface,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppConstants.borderColor, width: 1),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.textPrimary,
              backgroundColor: AppConstants.surface,
              side: const BorderSide(color: AppConstants.borderStrong, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppConstants.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            labelStyle: const TextStyle(
              color: AppConstants.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: const TextStyle(
              color: AppConstants.textLight,
              fontSize: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppConstants.borderStrong),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppConstants.borderStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppConstants.accentGreen, width: 1.5),
            ),
          ),
          dataTableTheme: DataTableThemeData(
            headingRowColor: WidgetStateProperty.all(AppConstants.surfaceCard),
            dataRowColor: WidgetStateProperty.all(AppConstants.surface),
            dividerThickness: 1,
            headingTextStyle: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
            dataTextStyle: const TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppConstants.surface,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppConstants.borderColor),
            ),
            titleTextStyle: const TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: AppConstants.borderColor,
            thickness: 1,
            space: 1,
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: AppConstants.accentGreen),
                ),
              );
            }
            if (auth.isAuthenticated) {
              return const MainAdminLayout();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}