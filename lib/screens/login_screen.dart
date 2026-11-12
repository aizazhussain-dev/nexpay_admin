import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import 'main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isBusy = false;
  String? _errorMsg;

  Future<void> _handleLogin() async {
    setState(() {
      _isBusy = true;
      _errorMsg = null;
    });

    final success = await context.read<AuthProvider>().login(
      _userController.text,
      _passController.text,
    );

    if (mounted) {
      setState(() => _isBusy = false);
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainAdminLayout()),
        );
      } else {
        setState(() {
          _errorMsg = "Invalid Operator Credentials!";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppConstants.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppConstants.accentGreen, AppConstants.accentBlue],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield, color: Color(0xFF021A13)),
                    ),
                    const SizedBox(width: 12),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                        children: [
                          TextSpan(text: "Nex"),
                          TextSpan(text: "Pay", style: TextStyle(color: AppConstants.accentGreen)),
                          TextSpan(text: " Core", style: TextStyle(fontSize: 18, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Central Executive Terminal Gateway",
                  style: TextStyle(color: AppConstants.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                if (_errorMsg != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.dangerRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.dangerRed.withValues(alpha: 0.3)),
                    ),
                    child: Text(_errorMsg!, style: const TextStyle(color: AppConstants.dangerRed, fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ),
                const Text("OPERATOR USERNAME", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                TextField(
                  controller: _userController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "admin",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: AppConstants.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("MASTER PASSWORD", style: TextStyle(color: AppConstants.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "••••••••••••",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: AppConstants.surfaceCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentGreen,
                      foregroundColor: const Color(0xFF022C22),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isBusy ? null : _handleLogin,
                    child: _isBusy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                        : const Text("Authorize Terminal", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}