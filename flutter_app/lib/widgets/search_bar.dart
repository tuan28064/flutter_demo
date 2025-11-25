import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_entry.dart';
import '../services/file_service.dart';

class FileSearchBar extends ConsumerStatefulWidget {
  const FileSearchBar({super.key});

  @override
  ConsumerState<FileSearchBar> createState() => _FileSearchBarState();
}

class _FileSearchBarState extends ConsumerState<FileSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchServiceProvider.notifier).search(value);
    });
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(searchServiceProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchServiceProvider);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: '搜索文件和文件夹...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: Theme.of(context).hintColor,
                  ),
                  suffixIcon: searchState.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _clearSearch,
                          padding: EdgeInsets.zero,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 高级搜索按钮
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            onPressed: () => _showAdvancedSearch(context),
            tooltip: '高级搜索',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  void _showAdvancedSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AdvancedSearchDialog(),
    );
  }
}

/// 高级搜索对话框
class AdvancedSearchDialog extends ConsumerStatefulWidget {
  const AdvancedSearchDialog({super.key});

  @override
  ConsumerState<AdvancedSearchDialog> createState() =>
      _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends ConsumerState<AdvancedSearchDialog> {
  final _queryController = TextEditingController();
  bool _recursive = true;
  bool _caseSensitive = false;
  bool _fuzzy = true;
  bool _includeHidden = false;
  final _extensionsController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    _extensionsController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final fileState = ref.read(fileServiceProvider);
    final extensions = _extensionsController.text.isEmpty
        ? null
        : _extensionsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    ref.read(searchServiceProvider.notifier).advancedSearch(
          SearchOptions(
            query: _queryController.text,
            rootPath: fileState.currentPath,
            recursive: _recursive,
            caseSensitive: _caseSensitive,
            fuzzy: _fuzzy,
            extensions: extensions,
            includeHidden: _includeHidden,
          ),
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('高级搜索'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _queryController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '搜索关键词',
                hintText: '输入文件名或关键词',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _extensionsController,
              decoration: const InputDecoration(
                labelText: '文件类型',
                hintText: 'pdf, doc, txt（用逗号分隔）',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // 选项
            CheckboxListTile(
              title: const Text('递归搜索子目录'),
              value: _recursive,
              onChanged: (v) => setState(() => _recursive = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),

            CheckboxListTile(
              title: const Text('区分大小写'),
              value: _caseSensitive,
              onChanged: (v) => setState(() => _caseSensitive = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),

            CheckboxListTile(
              title: const Text('模糊匹配'),
              value: _fuzzy,
              onChanged: (v) => setState(() => _fuzzy = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),

            CheckboxListTile(
              title: const Text('包含隐藏文件'),
              value: _includeHidden,
              onChanged: (v) => setState(() => _includeHidden = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _performSearch,
          child: const Text('搜索'),
        ),
      ],
    );
  }
}
