import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/auth/auth.dart';
import 'package:jabhouy/profile/profile.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// Where a User without a Username (one who joined with Google) picks one
/// before reaching Home. Needs a [ProfileBloc] above it.
class ChooseUsernamePage extends StatefulWidget {
  const ChooseUsernamePage({super.key});

  @override
  State<ChooseUsernamePage> createState() => _ChooseUsernamePageState();
}

class _ChooseUsernamePageState extends State<ChooseUsernamePage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  late final User? _user;
  late final Future<List<String>> _suggestions;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _user = authState is Authenticated ? authState.user : null;
    _suggestions = _user == null ? Future.value([]) : getIt<AuthService>().usernameSuggestions(_user);
  }

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  String get _chosen => _username.text.trim().toLowerCase();

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    // Name and image go along so the update keeps them.
    context.read<ProfileBloc>().add(
          UpdateProfile(name: _user?.name, image: _user?.image, username: _chosen),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MultiBlocListener(
      listeners: [
        // A taken name never gets here: ApiService shows the server's error.
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileStateData && state.isSuccess && _user != null) {
              context.read<AuthBloc>().add(AuthSignedIn(_user.copyWith(username: _chosen)));
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authenticated && state.user.hasUsername) {
              context.goNamed(AppRoutes.home);
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.chooseUsername), automaticallyImplyLeading: false),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.chooseUsernameSubtitle, style: AppTextTheme.body),
                  const SizedBox(height: 16),
                  FutureBuilder<List<String>>(
                    future: _suggestions,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const LinearProgressIndicator();
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final name in snapshot.data ?? const <String>[])
                            ActionChip(
                              label: Text(name),
                              onPressed: () => _username.text = name,
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _username,
                    hintText: l10n.usernameRules,
                    labelText: l10n.username,
                    prefixIcon: Icons.alternate_email,
                    action: TextInputAction.done,
                    validator: (value) =>
                        AuthService.isValidUsername((value ?? '').trim()) ? null : l10n.usernameRules,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: _save, child: Text(l10n.save)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
