import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/l10n/l10n.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignupBloc>(),
      child: const _SignupPageContent(),
    );
  }
}

class _SignupPageContent extends StatefulWidget {
  const _SignupPageContent();

  @override
  State<_SignupPageContent> createState() => _SignupPageContentState();
}

class _SignupPageContentState extends State<_SignupPageContent> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignup(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<SignupBloc>().add(
            SignupSubmitted(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
            ),
          );
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context); // Access translations

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: MultiBlocListener(
                  listeners: [
                    BlocListener<SignupBloc, SignupState>(
                      listener: (context, state) {
                        if (state is SignupSuccess) {
                          context.read<AuthBloc>().add(AuthSignedIn(state.user));
                        }
                      },
                    ),
                    BlocListener<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is Authenticated) {
                          showSuccessSnackBar(context, l10n.welcomeUser(state.user.name ?? 'No name'));
                          context.goNamed(AppRoutes.home);
                        }
                      },
                    ),
                  ],
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(),
                        const SizedBox(height: 40),
                        Text(
                          l10n.createAccount,
                          style: AppTextTheme.headline.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold, // Already w700, explicit for clarity
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.signUpToGetStarted,
                          style: AppTextTheme.body.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: .8),
                          ),
                        ),
                        const SizedBox(height: 40),
                        CustomTextFormField(
                          controller: _nameController,
                          hintText: l10n.enterYourName,
                          labelText: l10n.name,
                          prefixIcon: Icons.person_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterYourName;
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelStyle: AppTextTheme.body, // Apply to label
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          controller: _emailController,
                          hintText: l10n.enterYourEmail,
                          labelText: l10n.email,
                          prefixIcon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterYourEmail;
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return l10n.pleaseEnterAValidEmail;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelStyle: AppTextTheme.body, // Apply to label
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          controller: _passwordController,
                          hintText: l10n.enterYourPassword,
                          labelText: l10n.password,
                          prefixIcon: Icons.lock_rounded,
                          obscureText: _obscurePassword,
                          showVisibilityIcon: true,
                          onVisibilityToggle: _togglePasswordVisibility,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterYourPassword;
                            }
                            if (value.length < 6) {
                              return l10n.passwordMinLength;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelStyle: AppTextTheme.body, // Apply to label
                          ),
                        ),
                        const SizedBox(height: 30),
                        BlocBuilder<SignupBloc, SignupState>(
                          builder: (context, state) {
                            return ElevatedButton(
                              onPressed: state is SignupLoading ? null : () => _handleSignup(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: state is SignupLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      l10n.signUp,
                                      style: AppTextTheme.body.copyWith(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => context.pushNamed(AppRoutes.signin),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              child: Text(
                                l10n.signIn,
                                style: AppTextTheme.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
