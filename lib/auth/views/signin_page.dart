import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/auth/auth.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

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

class _SigninPageContentState extends State<_SigninPageContent> {
  final _username = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
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
    final l10n = context.l10n;
    final t = context.tokens;
    final googleOn = getIt<FeatureFlags>().isEnabled(Feature.googleSignIn);

    // Canvas ១៣: light page, Google first, then the password form.
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
          child: MultiBlocListener(
            listeners: [
              BlocListener<SigninBloc, SigninState>(
                listener: (context, state) {
                  if (state is SigninSuccess) {
                    context.read<AuthBloc>().add(AuthSignedIn(state.user));
                  } else if (state is SigninFailure) {
                    showErrorSnackBar(
                      context,
                      state.error ?? l10n.googleSignInFailed,
                    );
                  }
                },
              ),
              BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is Authenticated) {
                    if (state.isSessionTrusted) {
                      showSuccessSnackBar(context, l10n.signinSuccessful);
                    }
                    context.goNamed(AppRoutes.home);
                  }
                },
              ),
            ],
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: t.textPrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.storefront_outlined,
                        size: 36,
                        color: t.surface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.signInWelcome,
                    textAlign: TextAlign.center,
                    style: AppTextTheme.headline.copyWith(
                      color: t.textPrimary,
                    ),
                  ),
                  Text(
                    l10n.signInSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTextTheme.label.copyWith(
                      color: t.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (googleOn) ...[
                    const GoogleSignInButton(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: Divider(color: t.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.signInOr,
                            style: AppTextTheme.hint.copyWith(
                              color: t.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: t.border)),
                      ],
                    ),
                    const SizedBox(height: 22),
                  ],
                  LabeledField(
                    label: l10n.signInUsernameOrEmail,
                    child: TextFormField(
                      controller: _username,
                      style: AppTextTheme.body,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: l10n.signInUsernameOrEmailHint,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? l10n.pleaseEnterYourName
                          : null,
                    ),
                  ),
                  const SizedBox(height: 22),
                  LabeledField(
                    label: l10n.password,
                    child: TextFormField(
                      controller: _passwordController,
                      style: AppTextTheme.body,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          onPressed: _togglePasswordVisibility,
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: t.textSecondary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterYourPassword;
                        }
                        if (value.length < 6) return l10n.passwordMinLength;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  BlocBuilder<SigninBloc, SigninState>(
                    builder: (context, state) => OutlinedButton(
                      onPressed: state is SigninLoading
                          ? null
                          : () => _handleLogin(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: t.surface,
                        foregroundColor: t.textPrimary,
                        minimumSize:
                            const Size.fromHeight(AppSizes.buttonHeight),
                        side: BorderSide(color: t.textPrimary),
                        shape: const StadiumBorder(),
                      ),
                      child: state is SigninLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              l10n.login,
                              style: AppTextTheme.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
