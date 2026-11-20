import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../providers/auth.dart';
import '../../widgets/common.dart';
import '../../widgets/branding.dart';

/// Contractor login / sign up ("Let's get building").
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.signup = false});
  final bool signup;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late int _tab = widget.signup ? 1 : 0;
  final _loginForm = GlobalKey<FormState>();
  final _signupForm = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _profession = 'Engineer';
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _company, _phone, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _tab == 0 ? _loginForm : _signupForm;
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final auth = ref.read(authProvider.notifier);
    try {
      if (_tab == 0) {
        await auth.login(_email.text, _password.text);
      } else {
        await auth.register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          phone: _phone.text,
          profession: _profession,
          company: _company.text,
        );
      }
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const Center(child: BuildoraLogo(size: 26)),
            const SizedBox(height: 28),
            PillTabs(tabs: const ['Log in', 'Sign up'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
            const SizedBox(height: 32),
            Text(_tab == 0 ? 'Good to see you again' : 'Buildora On-site', style: AppText.label),
            const SizedBox(height: 4),
            Text(_tab == 0 ? 'Welcome back' : "Let's get building", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500, letterSpacing: -0.6)),
            const SizedBox(height: 28),
            if (_tab == 0) _loginFields() else _signupFields(),
            const SizedBox(height: 36),
            AppButton(label: _tab == 0 ? 'Login' : 'Create account', loading: _busy, onPressed: _submit),
            const SizedBox(height: 12),
            AppButton(label: 'Login as Manager', style: AppButtonStyle.outline, onPressed: () => context.push('/labour-login')),
          ],
        ),
      ),
    );
  }

  Widget _loginFields() => Form(
        key: _loginForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, validator: Validators.email),
            const SizedBox(height: 20),
            AppTextField(label: 'Password', controller: _password, obscure: true, validator: (v) => Validators.required(v, 'Password')),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Forgot password?', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            ),
          ],
        ),
      );

  Widget _signupFields() => Form(
        key: _signupForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(label: 'Full name', controller: _name, keyboardType: TextInputType.name, textCapitalization: TextCapitalization.words, validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your full name' : null),
            const SizedBox(height: 20),
            const Text('Your role', style: AppText.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final r in const ['Engineer', 'Contractor', 'Builder'])
                  AppChip(label: r, selected: _profession == r, onTap: () => setState(() => _profession = r)),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(label: 'Company name (optional)', controller: _company, textCapitalization: TextCapitalization.words),
            const SizedBox(height: 20),
            AppTextField(label: 'Phone', controller: _phone, keyboardType: TextInputType.phone, validator: Validators.phone),
            const SizedBox(height: 20),
            AppTextField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress, validator: Validators.email),
            const SizedBox(height: 20),
            AppTextField(label: 'Password', controller: _password, obscure: true, validator: Validators.password),
          ],
        ),
      );
}

/// Site manager login with phone + 4-digit PIN given by the contractor.
class LabourLoginScreen extends ConsumerStatefulWidget {
  const LabourLoginScreen({super.key});
  @override
  ConsumerState<LabourLoginScreen> createState() => _LabourLoginScreenState();
}

class _LabourLoginScreenState extends ConsumerState<LabourLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).labourLogin(_phone.text, _pin.text);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              const Row(children: [BackCircle(), Spacer(), BuildoraLogo(size: 22), Spacer(), SizedBox(width: 40)]),
              const SizedBox(height: 32),
              const Text('Good to see you again', style: AppText.label),
              const SizedBox(height: 4),
              const Text('Manager login', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, letterSpacing: -0.6)),
              const SizedBox(height: 8),
              const Text('Use the phone number and PIN your contractor gave you.', style: AppText.muted),
              const SizedBox(height: 28),
              AppTextField(label: 'Phone', controller: _phone, keyboardType: TextInputType.phone, validator: Validators.phone),
              const SizedBox(height: 20),
              AppTextField(label: '4-digit PIN', controller: _pin, keyboardType: TextInputType.number, obscure: true, maxLength: 4, validator: Validators.pin),
              const SizedBox(height: 36),
              AppButton(label: 'Login', loading: _busy, onPressed: _login),
              const SizedBox(height: 12),
              AppButton(label: 'Contractor Login', style: AppButtonStyle.outline, onPressed: () => context.pop()),
            ],
          ),
        ),
      ),
    );
  }
}
