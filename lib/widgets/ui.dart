import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

/// Shared UI building blocks used across all screens.

String fmtMoney(dynamic v) {
  final n = double.tryParse('$v'.replaceAll(',', '')) ?? 0;
  final f = NumberFormat('#,##0.##');
  return f.format(n);
}

String fmtDate(String? d) {
  if (d == null || d.isEmpty) return '-';
  final dt = DateTime.tryParse(d);
  if (dt == null) return d;
  return DateFormat('dd-MMM-yyyy').format(dt);
}

Future<void> showSnack(BuildContext context, String msg, {bool error = false}) async {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? AppTheme.danger : Colors.green.shade700,
  ));
}

Future<bool> confirmDelete(BuildContext context, String what) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm Delete'),
      content: Text('Are you sure you want to delete this $what? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppTheme.danger, minimumSize: const Size(80, 40)),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return res == true;
}

class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: AppTheme.brand),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ]),
      );
}

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ]),
        ),
      );
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyView({super.key, this.message = 'Nothing here yet', this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ]),
      );
}

/// Simple searchable list scaffold with pull-to-refresh.
class SearchListScaffold extends StatefulWidget {
  final String title;
  final Future<List<dynamic>> Function() loader;
  final Widget Function(BuildContext, Map<String, dynamic>) itemBuilder;
  final Widget? fab;
  const SearchListScaffold({
    super.key,
    required this.title,
    required this.loader,
    required this.itemBuilder,
    this.fab,
  });

  @override
  State<SearchListScaffold> createState() => _SearchListScaffoldState();
}

class _SearchListScaffoldState extends State<SearchListScaffold> {
  List<dynamic> _all = [];
  List<dynamic> _shown = [];
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.loader();
      _all = data;
      _applyFilter();
    } catch (e) {
      setState(() => _error = 'Could not load data.\n$e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _applyFilter() {
    final q = _search.text.trim().toLowerCase();
    Iterable<dynamic> it = _all;
    if (q.isNotEmpty) {
      it = it.where((row) =>
          row is Map<String, dynamic> &&
          row.values.any((v) => '$v'.toLowerCase().contains(q)));
    }
    setState(() => _shown = it.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: widget.fab,
      body: RefreshIndicator(
        color: AppTheme.brand,
        onRefresh: _load,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _search,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'Search…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _search.clear();
                        _applyFilter();
                      }),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorRetry(message: _error!, onRetry: _load)
                    : _shown.isEmpty
                        ? const EmptyView()
                        : RefreshIndicator(
                            color: AppTheme.brand,
                            onRefresh: _load,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _shown.length,
                              itemBuilder: (c, i) =>
                                  widget.itemBuilder(c, (_shown[i] as Map).cast<String, dynamic>()),
                            ),
                          ),
          ),
        ]),
      ),
    );
  }
}

/// Reusable key-value detail row.
Widget kvRow(String key, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(key, style: TextStyle(color: Colors.grey.shade600))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
    );

/// Section header chip.
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.8)),
        ),
      );
}
