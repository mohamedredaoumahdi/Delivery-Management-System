import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:user_app/features/auth/presentation/bloc/auth_bloc.dart';


class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  // Password strength tracking
  double _passwordStrength = 0.0;
  List<String> _passwordRequirements = [];

  @override
  void initState() {
    super.initState();
    
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    
    // Listen for password changes to update strength indicator
    _newPasswordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _newPasswordController.text;
    
    // Calculate password strength
    int score = 0;
    final requirements = <String>[];
    
    // Length check
    if (password.length >= 8) {
      score += 2;
    } else {
      requirements.add('At least 8 characters');
    }
    
    // Uppercase check
    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 1;
    } else {
      requirements.add('One uppercase letter');
    }
    
    // Lowercase check
    if (password.contains(RegExp(r'[a-z]'))) {
      score += 1;
    } else {
      requirements.add('One lowercase letter');
    }
    
    // Number check
    if (password.contains(RegExp(r'[0-9]'))) {
      score += 1;
    } else {
      requirements.add('One number');
    }
    
    // Special character check
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 1;
    } else {
      requirements.add('One special character');
    }
    
    setState(() {
      _passwordStrength = score / 6; // Max score is 6
      _passwordRequirements = requirements;
    });
  }

  void _toggleCurrentPasswordVisibility() {
    setState(() {
      _obscureCurrentPassword = !_obscureCurrentPassword;
    });
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _obscureNewPassword = !_obscureNewPassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _changePassword() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    context.read<AuthBloc>().add(AuthChangePasswordEvent(
      currentPassword: currentPassword,
      newPassword: newPassword,
    ));
  }

  Color _getPasswordStrengthColor() {
    if (_passwordStrength < 0.3) {
      return Colors.red;
    } else if (_passwordStrength < 0.6) {
      return Colors.orange;
    } else if (_passwordStrength < 0.8) {
      return Colors.yellow.shade700;
    } else {
      return Colors.green;
    }
  }

  String _getPasswordStrengthText() {
    if (_passwordStrength < 0.3) {
      return 'Weak';
    } else if (_passwordStrength < 0.6) {
      return 'Fair';
    } else if (_passwordStrength < 0.8) {
      return 'Good';
    } else {
      return 'Strong';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordChanged) {
            // Password changed successfully
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Password changed successfully'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
            
            // Clear form
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
            
            // Transition back to authenticated state to keep user logged in
            context.read<AuthBloc>().add(AuthCheckStatusEvent());
            
            // Navigate back
            context.pop();
          } else if (state is AuthError) {
            // Show error message prominently
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 6),
                action: SnackBarAction(
                  label: 'DISMISS',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
            
            // Also show a dialog for critical errors
            if (state.message.toLowerCase().contains('current password is incorrect')) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  icon: Icon(Icons.error, color: Colors.red, size: 48),
                  title: Text('Incorrect Password'),
                  content: Text('The current password you entered is incorrect. Please enter your actual login password.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            }
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Security info card
                  _buildSecurityInfoCard(context),
                  const SizedBox(height: 24),
                  
                  // Current password field
                  AppInputField(
                    controller: _currentPasswordController,
                    labelText: 'Current Password',
                    hintText: 'Enter your current password',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _obscureCurrentPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    onSuffixIconPressed: _toggleCurrentPasswordVisibility,
                    obscureText: _obscureCurrentPassword,
                    required: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // New password field
                  AppInputField(
                    controller: _newPasswordController,
                    labelText: 'New Password',
                    hintText: 'Enter your new password',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _obscureNewPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    onSuffixIconPressed: _toggleNewPasswordVisibility,
                    obscureText: _obscureNewPassword,
                    required: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (value == _currentPasswordController.text) {
                        return 'New password must be different from current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password strength indicator
                  if (_newPasswordController.text.isNotEmpty)
                    _buildPasswordStrengthIndicator(context),
                  
                  const SizedBox(height: 20),
                  
                  // Confirm password field
                  AppInputField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm New Password',
                    hintText: 'Re-enter your new password',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    onSuffixIconPressed: _toggleConfirmPasswordVisibility,
                    obscureText: _obscureConfirmPassword,
                    required: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your new password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Change password button
                  AppButton(
                    text: 'Change Password',
                    onPressed: state is AuthLoading ? null : _changePassword,
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    isLoading: state is AuthLoading,
                    icon: Icons.security,
                  ),
                  const SizedBox(height: 24),
                  
                  // Password tips
                  _buildPasswordTips(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecurityInfoCard(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
      borderColor: theme.colorScheme.primary.withOpacity(0.3),
      borderWidth: 1,
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep Your Account Secure',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a strong password to protect your account and personal information.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final strengthColor = _getPasswordStrengthColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Password Strength: ',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              _getPasswordStrengthText(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: strengthColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Strength progress bar
        LinearProgressIndicator(
          value: _passwordStrength,
          backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
        ),
        
        // Requirements list
        if (_passwordRequirements.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Missing requirements:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          ...(_passwordRequirements.map((requirement) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      requirement,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ))),
        ],
      ],
    );
  }

  Widget _buildPasswordTips(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      title: 'Password Security Tips',
      leading: Icon(
        Icons.lightbulb_outline,
        color: theme.colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTipItem(
            context,
            'Use a mix of uppercase and lowercase letters',
            Icons.check_circle_outline,
          ),
          const SizedBox(height: 8),
          _buildTipItem(
            context,
            'Include numbers and special characters',
            Icons.check_circle_outline,
          ),
          const SizedBox(height: 8),
          _buildTipItem(
            context,
            'Make it at least 8 characters long',
            Icons.check_circle_outline,
          ),
          const SizedBox(height: 8),
          _buildTipItem(
            context,
            'Avoid using personal information',
            Icons.check_circle_outline,
          ),
          const SizedBox(height: 8),
          _buildTipItem(
            context,
            'Don\'t reuse passwords from other accounts',
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(
    BuildContext context,
    String text,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}