import 'package:flutter/material.dart';
import '../../config.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// User management — admin only. Uses the session cookie captured at login.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> users = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final r = await ApiService.instance.get(AppConfig.epUsers);
    if (!mounted) return;
    if (r.ok && r.data is List) {
      users = r.data as List;
    } else {
      error = r.message ?? 'Could not load users';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _openAdd() async {
    final username = TextEditingController();
    final fullName = TextEditingController();
    final password = TextEditingController();
    String role = 'operator';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const Text('Add New User', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextFormField(controller: username, decoration: const InputDecoration(labelText: 'Username *')),
              const SizedBox(height: 10),
              TextFormField(controller: fullName, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 10),
              TextFormField(controller: password, obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password *')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin — full access')),
                  DropdownMenuItem(value: 'operator', child: Text('Operator — create & edit')),
                  DropdownMenuItem(value: 'viewer', child: Text('Viewer — read only')),
                ],
                onChanged: (v) => setSheet(() => role = v ?? role),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Create User'),
                onPressed: () async {
                  if (username.text.trim().isEmpty || password.text.isEmpty) {
                    showSnack(ctx, 'Username and password required', error: true);
                    return;
                  }
                  final r = await ApiService.instance.post(AppConfig.epUsers, {
                    'username': username.text.trim(),
                    'full_name': fullName.text.trim(),
                    'password': password.text,
                    'role': role,
                  });
                  if (ctx.mounted) {
                    showSnack(ctx, r.ok ? 'User created' : (r.message ?? 'Failed'), error: !r.ok);
                    if (r.ok) Navigator.pop(ctx, true);
                  }
                },
              ),
            ]),
          ),
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _toggleActive(Map<String, dynamic> u) async {
    final r = await ApiService.instance.put(AppConfig.epUsers, {
      'id': u['id'],
      'full_name': u['full_name'],
      'role': u['role'],
      'is_active': '${u['is_active'] ?? 1}' == '1' ? 0 : 1,
    });
    if (mounted) {
      showSnack(context, r.ok ? 'User updated' : (r.message ?? 'Update failed'), error: !r.ok);
      if (r.ok) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add User'),
        onPressed: _openAdd,
      ),
      body: RefreshIndicator(
        color: AppTheme.brand,
        onRefresh: _load,
        child: loading
            ? ListView(children: const [SizedBox(height: 120), LoadingView()])
            : error != null
                ? ListView(children: [ErrorRetry(message: error!, onRetry: _load)])
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (c, i) {
                      final u = (users[i] as Map).cast<String, dynamic>();
                      final active = '${u['is_active'] ?? 1}' == '1';
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                (u['role'] == 'admin' ? AppTheme.danger : AppTheme.brand).withOpacity(0.12),
                            child: Icon(
                              u['role'] == 'admin' ? Icons.admin_panel_settings : Icons.person,
                              color: u['role'] == 'admin' ? AppTheme.danger : AppTheme.brand,
                              size: 20,
                            ),
                          ),
                          title: Text('${u['full_name'] ?? u['username']}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${u['username']} • ${u['role']}${active ? '' : ' • DISABLED'}'),
                          trailing: Switch(
                            value: active,
                            onChanged: (_) => _toggleActive(u),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

/// Change own password.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool busy = false;

  Future<void> _change() async {
    if (_new.text.length < 6) {
      showSnack(context, 'New password must be at least 6 characters', error: true);
      return;
    }
    if (_new.text != _confirm.text) {
      showSnack(context, 'Passwords do not match', error: true);
      return;
    }
    setState(() => busy = true);
    final r = await ApiService.instance.post(AppConfig.epChangePassword, {
      'current_password': _old.text,
      'new_password': _new.text,
    });
    if (!mounted) return;
    setState(() => busy = false);
    showSnack(context, r.ok ? 'Password changed successfully' : (r.message ?? 'Change failed'), error: !r.ok);
    if (r.ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Icon(Icons.lock_reset, size: 60, color: AppTheme.brand),
          const SizedBox(height: 20),
          TextFormField(
            controller: _old,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _new,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock)),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.lock)),
          ),
          const SizedBox(height: 22),
          busy
              ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
              : FilledButton.icon(onPressed: _change, icon: const Icon(Icons.check), label: const Text('Update Password')),
        ],
      ),
    );
  }
}
