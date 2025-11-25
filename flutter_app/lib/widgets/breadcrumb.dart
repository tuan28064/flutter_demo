import 'dart:io';
import 'package:flutter/material.dart';

class Breadcrumb extends StatelessWidget {
  final String path;
  final void Function(String path)? onNavigate;

  const Breadcrumb({
    super.key,
    required this.path,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final parts = _getPathParts();

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < parts.length; i++) ...[
              if (i > 0)
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Theme.of(context).disabledColor,
                ),
              _BreadcrumbItem(
                label: parts[i].label,
                path: parts[i].path,
                isLast: i == parts.length - 1,
                onTap: onNavigate != null
                    ? () => onNavigate!(parts[i].path)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_PathPart> _getPathParts() {
    final parts = <_PathPart>[];
    final separator = Platform.pathSeparator;

    if (Platform.isWindows) {
      // Windows: C:\Users\Name\...
      final segments = path.split(separator);
      String currentPath = '';
      for (final segment in segments) {
        if (segment.isEmpty) continue;
        currentPath += segment + separator;
        parts.add(_PathPart(
          label: segment,
          path: currentPath.endsWith(separator)
              ? currentPath.substring(0, currentPath.length - 1)
              : currentPath,
        ));
      }
    } else {
      // Unix: /Users/Name/...
      if (path == '/') {
        parts.add(_PathPart(label: '/', path: '/'));
      } else {
        parts.add(_PathPart(label: '/', path: '/'));
        final segments = path.split('/').where((s) => s.isNotEmpty).toList();
        String currentPath = '';
        for (final segment in segments) {
          currentPath += '/$segment';
          parts.add(_PathPart(label: segment, path: currentPath));
        }
      }
    }

    return parts;
  }
}

class _PathPart {
  final String label;
  final String path;

  _PathPart({required this.label, required this.path});
}

class _BreadcrumbItem extends StatefulWidget {
  final String label;
  final String path;
  final bool isLast;
  final VoidCallback? onTap;

  const _BreadcrumbItem({
    required this.label,
    required this.path,
    required this.isLast,
    this.onTap,
  });

  @override
  State<_BreadcrumbItem> createState() => _BreadcrumbItemState();
}

class _BreadcrumbItemState extends State<_BreadcrumbItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isLast ? null : widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: _isHovered && !widget.isLast
                ? Theme.of(context).hoverColor
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: widget.isLast
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: widget.isLast ? FontWeight.bold : null,
                ),
          ),
        ),
      ),
    );
  }
}
