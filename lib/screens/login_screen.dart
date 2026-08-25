import 'package:flutter/material.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _server = TextEditingController(text: ApiService.instance.server);
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidePass = true;
  bool _editingServer = false;

  @override
  void dispose() {
    _server.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    await ApiService.instance.setServer(_server.text);
    final r = await ApiService.instance.login(_username.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ?? 'Login failed'),
        backgroundColor: AppTheme.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.brand, AppTheme.brandLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Icon(Icons.inventory_2, size: 72, color: Colors.white),
                const SizedBox(height: 10),
                const Text('AT Sol',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(AppConfig.appTagline,
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15)),
                const SizedBox(height: 30),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _form,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(
                          children: [
                            Expanded(
                              child: !_editingServer
                                  ? TextButton.icon(
                                      onPressed: () => setState(() => _editingServer = true),
                                      icon: const Icon(Icons.dns, size: 18),
                                      label: Text(
                                        ApiService.instance.server,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                                      ),
                                    )
                                  : TextFormField(
                                      controller: _server,
                                      keyboardType: TextInputType.url,
                                      decoration: const InputDecoration(
                                        labelText: 'Server URL',
                                        prefixIcon: Icon(Icons.dns),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty) ? 'Enter server URL' : null,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _username,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter username' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _hidePass,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_hidePass ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _hidePass = !_hidePass),
                            ),
                          ),
                          onFieldSubmitted: (_) => _login(),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
                        ),
                        const SizedBox(height: 20),
                        _busy
                            ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
                            : FilledButton.icon(
                                onPressed: _login,
                                icon: const Icon(Icons.login),
                                label: const Text('Sign In'),
                              ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Software by Raheem Soft',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
