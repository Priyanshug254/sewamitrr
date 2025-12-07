import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/animations.dart';
import 'login_screen.dart'; // Import for AnimatedBackground

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedLanguage = 'en';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageService = context.read<LanguageService>();
      setState(() => _selectedLanguage = languageService.currentLanguage);
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Reuse Animated Background from LoginScreen
          const AnimatedBackground(),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header
                    FadeInSlide(
                      delay: 0.1,
                      child: Column(
                        children: [
                          Text(
                            languageService.translate('join_sewamitr'),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            languageService.translate('help_improve_your_community'),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Signup Form
                    FadeInSlide(
                      delay: 0.2,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: languageService.translate('full_name'),
                                prefixIcon: const Icon(Icons.person_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: languageService.translate('email'),
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            
                            TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: languageService.translate('password'),
                                prefixIcon: const Icon(Icons.lock_outlined),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
                            
                            TextField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: languageService.translate('confirm_password'),
                                prefixIcon: const Icon(Icons.lock_outlined),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              initialValue: _selectedLanguage,
                              decoration: InputDecoration(
                                labelText: languageService.translate('preferred_language'),
                                prefixIcon: const Icon(Icons.language),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'en', child: Text('English')),
                                DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedLanguage = value!);
                                languageService.changeLanguage(value!);
                              },
                            ),
                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              child: ScaleButton(
                                onPressed: _isLoading ? null : _signup,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _isLoading
                                      ? const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          languageService.translate('create_account'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Login Link
                    FadeInSlide(
                      delay: 0.3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            languageService.translate('already_have_account'),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              languageService.translate('login'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<LanguageService>().translate('please_fill_all_fields')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<LanguageService>().translate('passwords_do_not_match')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final error = await Provider.of<AuthService>(context, listen: false)
        .signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          _selectedLanguage,
        );
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<LanguageService>().translate('account_created_successfully')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }
}