import 'package:flutter/material.dart';
import '../models/file_entry.dart';

class FileListView extends StatelessWidget {
  final List<FileEntry> entries;
  final void Function(FileEntry entry)? onTap;
  final void Function(FileEntry entry)? onDoubleTap;
  final void Function(FileEntry entry)? onSecondaryTap;

  const FileListView({
    super.key,
    required this.entries,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              '空文件夹',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 表头
        _buildHeader(context),

        // 文件列表
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _FileListItem(
                entry: entry,
                onTap: onTap != null ? () => onTap!(entry) : null,
                onDoubleTap:
                    onDoubleTap != null ? () => onDoubleTap!(entry) : null,
                onSecondaryTap:
                    onSecondaryTap != null ? () => onSecondaryTap!(entry) : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32), // 图标占位
          Expanded(flex: 4, child: Text('名称', style: style)),
          Expanded(flex: 2, child: Text('修改日期', style: style)),
          Expanded(flex: 1, child: Text('类型', style: style)),
          Expanded(
              flex: 1,
              child: Text('大小', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _FileListItem extends StatefulWidget {
  final FileEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onSecondaryTap;

  const _FileListItem({
    required this.entry,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTap,
  });

  @override
  State<_FileListItem> createState() => _FileListItemState();
}

class _FileListItemState extends State<_FileListItem> {
  bool _isHovered = false;
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onSecondaryTap: widget.onSecondaryTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : _isHovered
                    ? Theme.of(context).hoverColor
                    : null,
          ),
          child: Row(
            children: [
              // 图标
              SizedBox(
                width: 32,
                child: Icon(
                  _getIcon(),
                  size: 20,
                  color: _getIconColor(context),
                ),
              ),

              // 名称
              Expanded(
                flex: 4,
                child: Text(
                  widget.entry.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: widget.entry.isHidden
                            ? Theme.of(context).disabledColor
                            : null,
                      ),
                ),
              ),

              // 修改日期
              Expanded(
                flex: 2,
                child: Text(
                  widget.entry.formattedModified,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              // 类型
              Expanded(
                flex: 1,
                child: Text(
                  _getTypeLabel(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              // 大小
              Expanded(
                flex: 1,
                child: Text(
                  widget.entry.formattedSize,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    if (widget.entry.isDir) {
      return Icons.folder;
    }

    final ext = widget.entry.extension?.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
      case 'webp':
        return Icons.image;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
        return Icons.audio_file;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.video_file;
      case 'zip':
      case 'rar':
      case 'tar':
      case 'gz':
      case '7z':
        return Icons.archive;
      case 'dart':
      case 'rs':
      case 'py':
      case 'js':
      case 'ts':
      case 'java':
      case 'c':
      case 'cpp':
      case 'h':
      case 'go':
        return Icons.code;
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
      case 'toml':
        return Icons.data_object;
      case 'md':
      case 'txt':
        return Icons.article;
      case 'html':
      case 'css':
        return Icons.web;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getIconColor(BuildContext context) {
    if (widget.entry.isDir) {
      return Colors.amber;
    }

    final ext = widget.entry.extension?.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Colors.purple;
      case 'dart':
        return Colors.cyan;
      case 'rs':
        return Colors.deepOrange;
      case 'py':
        return Colors.yellow.shade700;
      case 'js':
      case 'ts':
        return Colors.amber.shade700;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _getTypeLabel() {
    if (widget.entry.isDir) {
      return '文件夹';
    }

    final ext = widget.entry.extension?.toLowerCase();
    if (ext == null || ext.isEmpty) {
      return '文件';
    }

    return ext.toUpperCase();
  }
}
