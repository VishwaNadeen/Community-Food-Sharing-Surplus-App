import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';
import 'verify_email_screen.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // UI states
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Selected role
  String? _selectedRole;

  // Roles accepted by the backend
  final List<Map<String, String>> _roles = [
    {
      'value': 'recipient',
      'label': 'Recipient',
    },
    {
      'value': 'donor',
      'label': 'Food Donor',
    },
    {
      'value': 'volunteer delivery partner',
      'label': 'Volunteer Delivery Partner',
    },
    {
      'value': 'ngo coordinator',
      'label': 'NGO Coordinator',
    },
  ];

  // Official multicolor Google "G" logo.
  static const String _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

  // ==================== SIGN UP ====================

  Future<void> _signup() async {
    // Validate all form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Make sure a role has been selected
    if (_selectedRole == null || _selectedRole!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Start loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Send signup request to backend
      //
      // Backend receives:
      // email
      // password
      // confirmPassword
      // role
      final result = await AuthService.signup(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmController.text,
        role: _selectedRole!,
      );

      if (!mounted) return;

      // Get returned user
      final user = result['user'];

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created! Verification code sent to ${user['email']}',
          ),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );

      // TODO:
      // Navigate to email verification screen.
      //
      // Example:
      //
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => VerifyEmailScreen(
      //       email: _emailController.text.trim(),
      //     ),
      //   ),
      // );
      // Navigate to email verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            email: _emailController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Remove "Exception: " from the error message
      final errorMessage = e
          .toString()
          .replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==================== DISPOSE ====================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ==================== SOCIAL BUTTON ====================

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

  // ==================== BUILD ====================

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

                      // ==================== BACK BUTTON ====================

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
                            onPressed: () {
                              Navigator.maybePop(context);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================== HEADER ICON ====================

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
                              Icons.person_add_alt_1_rounded,
                              color: AppTheme.primaryGreenDark,
                              size: 34,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================== TITLE ====================

                      const Text(
                        'Create Account',
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
                        'Sign up to start sharing surplus food nearby',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ==================== FORM ====================

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ==================== EMAIL ====================

                            CustomTextField(
                              controller: _emailController,
                              hint: 'Email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType:
                                  TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }

                                final email = value.trim();

                                final emailRegex = RegExp(
                                  r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
                                );

                                if (!emailRegex.hasMatch(email)) {
                                  return 'Enter a valid email';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // ==================== ROLE ====================

                            DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'Select Role',
                                prefixIcon: const Icon(
                                  Icons.people_outline,
                                ),
                                filled: true,
                                fillColor: AppTheme.fieldFill,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color:
                                        AppTheme.primaryGreenDark,
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                focusedErrorBorder:
                                    OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              items: _roles.map((role) {
                                return DropdownMenuItem<String>(
                                  value: role['value'],
                                  child: Text(
                                    role['label']!,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value;
                                });
                              },
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please select your role';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // ==================== PASSWORD ====================

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
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter a password';
                                }

                                if (value.length < 6) {
                                  return 'At least 6 characters';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // ==================== CONFIRM PASSWORD ====================

                            CustomTextField(
                              controller: _confirmController,
                              hint: 'Confirm Password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              obscureText: _obscureConfirm,
                              onToggle: () {
                                setState(() {
                                  _obscureConfirm =
                                      !_obscureConfirm;
                                });
                              },
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please confirm your password';
                                }

                                if (value !=
                                    _passwordController.text) {
                                  return 'Passwords do not match';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // ==================== CREATE ACCOUNT ====================

                            PrimaryButton(
                              text: 'Create Account',
                              isLoading: _isLoading,
                              onPressed: _signup,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ==================== SOCIAL DIVIDER ====================

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            child: Text(
                              'or continue with',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ==================== SOCIAL LOGIN ====================

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

                      const SizedBox(height: 24),

                      // ==================== SIGN IN ====================

                      Center(
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.maybePop(context);
                              },
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color:
                                      AppTheme.primaryGreenDark,
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