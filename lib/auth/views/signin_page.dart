import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/l10n/l10n.dart';

class SigninPage extends StatelessWidget {
  const SigninPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SigninBloc>(),
      child: const _SigninPageContent(),
    );
  }
}

class _SigninPageContent extends StatefulWidget {
  const _SigninPageContent();

  @override
  State<_SigninPageContent> createState() => _SigninPageContentState();
}

class _SigninPageContentState extends State<_SigninPageContent> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _username = TextEditingController();
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
    _username.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();
      context.read<SigninBloc>().add(
            SigninSubmitted(
              username: _username.text,
              password: _passwordController.text,
            ),
          );
    }
  }

  void _togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      extendBodyBehindAppBar: true,
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
                    BlocListener<SigninBloc, SigninState>(
                      listener: (context, state) {
                        if (state is SigninSuccess) {
                          context.read<AuthBloc>().add(AuthSignedIn(state.user));
                        }
                      },
                    ),
                    BlocListener<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is Authenticated) {
                          showSuccessSnackBar(context, l10n.signinSuccessful);
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
                          l10n.welcomeBack,
                          style: AppTextTheme.headline.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold, // Already w700, explicit for clarity
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.signInToContinue,
                          style: AppTextTheme.body.copyWith(
                            color: colorScheme.onPrimary.withOpacity(.8),
                          ),
                        ),
                        const SizedBox(height: 40),
                        CustomTextFormField(
                          controller: _username,
                          hintText: l10n.nameRequired(l10n.name),
                          labelText: l10n.name,
                          prefixIcon: Icons.person,
                          action: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterYourName;
                            }

                            return null;
                          },
                          keyboardType: TextInputType.name,
                          decoration: const InputDecoration(
                            labelStyle: AppTextTheme.body,
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          controller: _passwordController,
                          hintText: l10n.enterYourPassword,
                          labelText: l10n.password,
                          prefixIcon: Icons.lock_rounded,
                          obscureText: _obscurePassword,
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
                          decoration: const InputDecoration(
                            labelStyle: AppTextTheme.body, // Apply to label
                          ),
                        ),
                        const SizedBox(height: 30),
                        BlocBuilder<SigninBloc, SigninState>(
                          builder: (context, state) {
                            return ElevatedButton(
                              onPressed: state is SigninLoading ? null : () => _handleLogin(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: state is SigninLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      l10n.login,
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
                              onPressed: () => context.pushNamed(AppRoutes.signup),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              child: Text(
                                l10n.signUp,
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
