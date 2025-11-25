import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_service.dart';
import '../services/rust_bridge.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeDir = RustBridge.getHomeDirectory() ?? '/';

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.folder_special,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'File Explorer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 快捷位置
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '快捷访问',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          _SidebarItem(
            icon: Icons.home,
            label: '主目录',
            path: homeDir,
            onTap: () =>
                ref.read(fileServiceProvider.notifier).navigateTo(homeDir),
          ),

          _SidebarItem(
            icon: Icons.desktop_mac,
            label: '桌面',
            path: '$homeDir/Desktop',
            onTap: () => ref
                .read(fileServiceProvider.notifier)
                .navigateTo('$homeDir/Desktop'),
          ),

          _SidebarItem(
            icon: Icons.download,
            label: '下载',
            path: '$homeDir/Downloads',
            onTap: () => ref
                .read(fileServiceProvider.notifier)
                .navigateTo('$homeDir/Downloads'),
          ),

          _SidebarItem(
            icon: Icons.description,
            label: '文档',
            path: '$homeDir/Documents',
            onTap: () => ref
                .read(fileServiceProvider.notifier)
                .navigateTo('$homeDir/Documents'),
          ),

          _SidebarItem(
            icon: Icons.image,
            label: '图片',
            path: '$homeDir/Pictures',
            onTap: () => ref
                .read(fileServiceProvider.notifier)
                .navigateTo('$homeDir/Pictures'),
          ),

          _SidebarItem(
            icon: Icons.music_note,
            label: '音乐',
            path: '$homeDir/Music',
            onTap: () => ref
                .read(fileServiceProvider.notifier)
                .navigateTo('$homeDir/Music'),
          ),

          _SidebarItem(
            icon: Icons.movie,
            label: '视频',
            path: '$homeDir/Movies',
            onTap: () => ref
                .read(fileServiceProvider.notifier)
                .navigateTo('$homeDir/Movies'),
          ),

          const Divider(height: 1),

          // 设备/磁盘
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '设备',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          _SidebarItem(
            icon: Icons.computer,
            label: _getComputerName(),
            path: '/',
            onTap: () =>
                ref.read(fileServiceProvider.notifier).navigateTo('/'),
          ),

          const Spacer(),

          // 设置按钮
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.settings, size: 20),
              title: const Text('设置'),
              onTap: () {
                // TODO: 打开设置
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getComputerName() {
    if (Platform.isMacOS) return 'Macintosh HD';
    if (Platform.isWindows) return '本地磁盘 (C:)';
    return '根目录';
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String path;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _isHovered ? Theme.of(context).hoverColor : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
