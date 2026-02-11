import 'package:flutter/material.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

/// Reusable Log Viewer Modal Sheet
void showLogViewerSheet(BuildContext context) {
  final logs = LogService.getRecentLogs(count: 100);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Title Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('應用日誌 (${logs.length})', style: Theme.of(context).textTheme.titleLarge),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        ToastService.info('正在上傳...');
                        final (isSuccess, message) = await LogService.uploadToCloud();
                        if (isSuccess) {
                          ToastService.success(message);
                        } else {
                          ToastService.error(message);
                        }
                      },
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('上傳'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await LogService.clearAll();
                        if (context.mounted) Navigator.pop(context);
                        ToastService.info('日誌已清除');
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('清除'),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Log List
          Expanded(
            child: logs.isEmpty
                ? const Center(child: Text('暫無日誌'))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return ListTile(
                        dense: true,
                        leading: _getLogIcon(log.level),
                        title: Text(
                          log.message,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${log.formatted.substring(0, 8)} ${log.source ?? ''}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

Widget _getLogIcon(LogLevel level) {
  switch (level) {
    case LogLevel.debug:
      return const Icon(Icons.bug_report, size: 18, color: Colors.grey);
    case LogLevel.info:
      return const Icon(Icons.info_outline, size: 18, color: Colors.blue);
    case LogLevel.warning:
      return const Icon(Icons.warning_amber, size: 18, color: Colors.orange);
    case LogLevel.error:
      return const Icon(Icons.error_outline, size: 18, color: Colors.red);
  }
}
