import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.tenant;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AuthShell(
      title: 'Create account',
      subtitle: 'Join Rento as a tenant, owner, or both.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  label: 'Full name',
                  icon: Icons.person_outline,
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: _inputDecoration(
                  label: 'Email',
                  icon: Icons.email_outlined,
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: _inputDecoration(
                  label: 'Phone',
                  icon: Icons.phone_outlined,
                ),
                validator: _validatePhone,
              ),
              const SizedBox(height: 18),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(
                    value: UserRole.tenant,
                    icon: Icon(Icons.person_search_outlined),
                    label: Text('Tenant'),
                  ),
                  ButtonSegment(
                    value: UserRole.landowner,
                    icon: Icon(Icons.home_work_outlined),
                    label: Text('Owner'),
                  ),
                  ButtonSegment(
                    value: UserRole.both,
                    icon: Icon(Icons.handshake_outlined),
                    label: Text('Both'),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: authProvider.isLoading
                    ? null
                    : (selection) {
                        setState(() => _selectedRole = selection.first);
                      },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFFE0F2FE);
                    }
                    return const Color(0xFFF8FAFC);
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF075985);
                    }
                    return const Color(0xFF475467);
                  }),
                  side: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const BorderSide(color: Color(0xFF0EA5E9));
                    }
                    return const BorderSide(color: Color(0xFFE2E8F0));
                  }),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: _inputDecoration(
                  label: 'Password',
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                decoration: _inputDecoration(
                  label: 'Confirm password',
                  icon: Icons.lock_reset_outlined,
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirmPassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: _validateConfirmPassword,
                onFieldSubmitted: (_) => _signup(authProvider),
              ),
              if (authProvider.message != null) ...[
                const SizedBox(height: 16),
                AuthStatusMessage(message: authProvider.message!),
              ],
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Sign up',
                isLoading: authProvider.isLoading,
                onPressed: () => _signup(authProvider),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () {
                        authProvider.clearMessage();
                        context.go('/login');
                      },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6D28D9),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF667085)),
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.6),
      ),
    );
  }

  String? _validateName(String? value) {
    if ((value?.trim() ?? '').length < 2) return 'Enter your full name';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (email.isEmpty) return 'Enter your email address';
    if (!emailPattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.length < 8) return 'Enter a valid phone number';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 6) return 'Use at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _signup(AuthProvider authProvider) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final success = await authProvider.signup(
      _nameController.text,
      _emailController.text,
      _phoneController.text,
      _passwordController.text,
      _selectedRole,
    );

    if (!mounted || !success || authProvider.currentUser == null) return;
    _goToHome(authProvider.currentUser!.role);
  }

  void _goToHome(UserRole role) {
    if (role == UserRole.tenant) {
      context.go('/tenant_home');
    } else {
      context.go('/landowner_dashboard');
    }
  }
}
