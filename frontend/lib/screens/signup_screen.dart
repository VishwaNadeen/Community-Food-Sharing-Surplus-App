import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_row.dart';
import '../services/auth_service.dart';

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ==================== BACK BUTTON ====================

                      Container(
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

                      const SizedBox(height: 24),

                      // ==================== HEADER ICON ====================

                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppTheme.lightGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: AppTheme.primaryGreenDark,
                          size: 30,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================== TITLE ====================

                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Sign up to start sharing surplus food nearby',
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              value: _selectedRole,
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

                      const SizedBox(height: 24),

                      // ==================== SOCIAL LOGIN ====================

                      const SocialRow(),

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