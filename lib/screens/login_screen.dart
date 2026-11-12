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
  bool _obscurePassword = true;
  String? _errorMsg;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final user = _userController.text.trim();
    final pass = _passController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = 'Please enter both Operator ID and Master Password.');
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMsg = null;
    });

    final success = await context.read<AuthProvider>().login(user, pass);

    if (mounted) {
      setState(() => _isBusy = false);
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainAdminLayout()),
        );
      } else {
        setState(() {
          _errorMsg = 'Authentication failed. Invalid Operator ID or Master Password.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: Row(
        children: [
          // Left Executive Institutional Panel (Desktop)
          if (isWide)
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(48),
                decoration: const BoxDecoration(
                  color: AppConstants.bgDark,
                  border: Border(right: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Identity
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'N',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NexPay Core',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'INSTITUTIONAL FINTECH CONSOLE',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      'Centralized Treasury,\nCompliance & Settlement\nCommand Center.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        height: 1.22,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Real-time operational control across customer wallets, biometric KYC verification, bank settlements, 24K bullion dispatch, US equities, and ROSCA pools.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildFeatureRow(
                      Icons.verified_user_outlined,
                      'End-to-End Encrypted Ledger',
                      'Direct TLS connection to smartvest.tech core banking API',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureRow(
                      Icons.account_balance_outlined,
                      '33 Integrated Operational Desks',
                      'Full custody, KYC audit, reversal, and gateway controls',
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 9, color: Color(0xFF10B981)),
                          SizedBox(width: 10),
                          Text(
                            'Node: smartvest.tech  •  256-Bit SSL Active',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Right Authentication Form
          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: AppConstants.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppConstants.borderColor),
                    boxShadow: AppConstants.cardShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppConstants.accentGreenLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'AUTHORIZED PERSONNEL ONLY',
                          style: TextStyle(
                            color: AppConstants.accentGreen,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sign in to Command Console',
                        style: TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter your executive credentials to unlock live treasury operations.',
                        style: TextStyle(
                          color: AppConstants.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 26),
                      if (_errorMsg != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppConstants.dangerRedLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppConstants.dangerRed.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppConstants.dangerRed, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMsg!,
                                  style: const TextStyle(
                                    color: AppConstants.dangerRed,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Text(
                        'Operator Username',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _userController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter operator ID',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 19, color: AppConstants.textMuted),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Master Security Password',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _passController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                        style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter master password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19, color: AppConstants.textMuted),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 19,
                              color: AppConstants.textMuted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.accentGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isBusy ? null : _handleLogin,
                          icon: _isBusy
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                              : const Icon(Icons.shield_outlined, size: 19),
                          label: Text(
                            _isBusy ? 'Authenticating Session...' : 'Authorize & Launch Console',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'All administrative actions are logged with forensic timestamps.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppConstants.textMuted, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF34D399)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}