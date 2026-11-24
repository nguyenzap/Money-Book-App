import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets.dart';
import '../../core/domain/autotrack/text_fold.dart';
import 'autotrack_platform.dart';
import 'autotrack_providers.dart';

/// Chọn một app trên máy. Trả về [LaunchableApp] đã chọn, hoặc null.
class AppPickerScreen extends ConsumerStatefulWidget {
  const AppPickerScreen({super.key, required this.title});

  final String title;

  @override
  ConsumerState<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<AppPickerScreen> {
  late final Future<List<LaunchableApp>> _apps = ref
      .read(autoTrackPlatformProvider)
      .listLaunchableApps();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              autofocus: false,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm app',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = foldVi(v)),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LaunchableApp>>(
              future: _apps,
              builder: (context, snap) {
                if (snap.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: 'Không lấy được danh sách app',
                    message: '${snap.error}',
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final apps = snap.data!
                    .where(
                      (a) =>
                          _query.isEmpty ||
                          foldVi(a.label).contains(_query) ||
                          a.packageName.toLowerCase().contains(_query),
                    )
                    .toList();
                if (apps.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'Không có app nào khớp',
                  );
                }
                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, i) {
                    final app = apps[i];
                    return ListTile(
                      leading: app.icon == null
                          ? const Icon(Icons.apps, size: 40)
                          : Image.memory(app.icon!, width: 40, height: 40),
                      title: Text(app.label),
                      subtitle: Text(
                        app.packageName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () => Navigator.pop(context, app),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
