import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_row.dart';
import '../providers/auth_provider.dart';

import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;

  // Official multicolor Google "G" logo.
  static const String _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(
        context,
        listen: false,
      );

      await auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Navigate based on role.
      final role = auth.roleCode;

      if (role == 'R') {
        if (!auth.profileCompleted) {
          Navigator.pushReplacementNamed(
            context,
            '/recipient-profile',
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/recipient-home',
          );
        }
      } else if (role == 'D') {
        if (!auth.profileCompleted) {
          Navigator.pushReplacementNamed(
            context,
            '/donor-profile',
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/donor-home',
          );
        }
      } else if (role == 'N') {
        Navigator.pushReplacementNamed(
          context,
          '/ngo-dashboard',
        );
      } else if (role == 'V') {
        if (!auth.profileCompleted) {
          Navigator.pushReplacementNamed(
            context,
            '/volunteer-profile-setup',
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/volunteer-home',
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to identify your account role.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _socialLoginButton({
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE0E5E7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }

  Widget _orDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.grey.shade300, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.grey.shade300, thickness: 1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),

                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: AppTheme.fieldFill,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 18,
                            ),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Logo with soft outer ring
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.lightGreen.withOpacity(0.45),
                        ),
                        child: Center(
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppTheme.lightGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGreenDark
                                      .withOpacity(0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              color: AppTheme.primaryGreenDark,
                              size: 36,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Welcome Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppTheme.darkText,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Sign in to continue where you left off',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 32),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              controller: _emailController,
                              hint: 'Email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter your email';
                                }

                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(v.trim())) {
                                  return 'Enter a valid email';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            CustomTextField(
                              controller: _passwordController,
                              hint: 'Password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              obscureText: _obscure,
                              onToggle: () {
                                setState(() {
                                  _obscure = !_obscure;
                                });
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter password';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 4),

                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: AppTheme.primaryGreenDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            PrimaryButton(
                              text: 'Sign In',
                              isLoading: _isLoading,
                              onPressed: _login,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      _orDivider(),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          // Google
                          _socialLoginButton(
                            icon: SvgPicture.string(
                              _googleSvg,
                              width: 24,
                              height: 24,
                            ),
                            onTap: () {
                              // Google Sign-In
                            },
                          ),
                          const SizedBox(width: 14),

                          // Facebook
                          _socialLoginButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.facebook,
                              size: 26,
                              color: Color(0xFF1877F2),
                            ),
                            onTap: () {
                              // Facebook Login
                            },
                          ),
                          const SizedBox(width: 14),

                          // Apple
                          _socialLoginButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.apple,
                              size: 28,
                              color: Colors.black,
                            ),
                            onTap: () {
                              // Apple Sign-In
                            },
                          ),
                        ],
                      ),

                      const Spacer(),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignupScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: AppTheme.primaryGreenDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}