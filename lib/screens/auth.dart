import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegister = false;
  bool _loading = false;
  String? _error;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final email = _email.text.trim();
    final pass = _pass.text;
    String? err;
    if (!email.contains('@') || email.length < 5) {
      err = 'Email tidak valid';
    } else if (pass.length < 6) {
      err = 'Password minimal 6 karakter';
    } else if (_isRegister && _name.text.trim().isEmpty) {
      err = 'Nama wajib diisi';
    }
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
      return;
    }

    if (_isRegister) {
      final e = await AppState.instance.register(
        name: _name.text,
        email: email,
        password: pass,
      );
      if (e != null) {
        setState(() {
          _loading = false;
          _error = e;
        });
        return;
      }
    } else {
      final ok = await AppState.instance.login(email: email, password: pass);
      if (!ok) {
        setState(() {
          _loading = false;
          _error = 'Email/password salah';
        });
        return;
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.account_balance_wallet, size: 34, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'FinTrack',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Text(
                'Pelacak keuangan pribadi',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Masuk')),
                  ButtonSegment(value: true, label: Text('Daftar')),
                ],
                selected: {_isRegister},
                onSelectionChanged: (s) => setState(() => _isRegister = s.first),
              ),
              const SizedBox(height: 20),
              if (_isRegister) ...[
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.expense, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isRegister ? 'Daftar' : 'Masuk'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Data tersimpan di perangkat ini',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}