import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_service.dart';
import '../widgets/file_list_view.dart';
import '../widgets/search_bar.dart';
import '../widgets/sidebar.dart';
import '../widgets/breadcrumb.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileServiceProvider);
    final searchState = ref.watch(searchServiceProvider);
    final isSearching = searchState.query.isNotEmpty;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleKeyEvent(event, ref),
      child: Scaffold(
        body: Row(
          children: [
            // 侧边栏
            const Sidebar(),

            // 主内容区
            Expanded(
              child: Column(
                children: [
                  // 工具栏
                  _buildToolbar(context, ref, fileState),

                  // 面包屑导航
                  Breadcrumb(
                    path: fileState.currentPath,
                    onNavigate: (path) {
                      ref.read(fileServiceProvider.notifier).navigateTo(path);
                    },
                  ),

                  // 搜索栏
                  const FileSearchBar(),

                  // 文件列表
                  Expanded(
                    child: fileState.isLoading || searchState.isSearching
                        ? const Center(child: CircularProgressIndicator())
                        : fileState.error != null
                            ? _buildError(context, fileState.error!)
                            : isSearching
                                ? _buildSearchResults(context, ref, searchState)
                                : FileListView(
                                    entries: fileState.entries,
                                    onTap: (entry) {
                                      if (entry.isDir) {
                                        ref
                                            .read(fileServiceProvider.notifier)
                                            .enterDirectory(entry);
                                      } else {
                                        _openFile(entry.path);
                                      }
                                    },
                                  ),
                  ),

                  // 状态栏
                  _buildStatusBar(context, fileState, searchState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(
      BuildContext context, WidgetRef ref, FileServiceState state) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // 导航按钮
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: state.canGoBack
                ? () => ref.read(fileServiceProvider.notifier).goBack()
                : null,
            tooltip: '后退',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: state.canGoForward
                ? () => ref.read(fileServiceProvider.notifier).goForward()
                : null,
            tooltip: '前进',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: () =>
                ref.read(fileServiceProvider.notifier).goToParent(),
            tooltip: '上级目录',
          ),

          const VerticalDivider(),

          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(fileServiceProvider.notifier).refresh(),
            tooltip: '刷新',
          ),

          const Spacer(),

          // 视图切换
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () {
              // TODO: 切换视图模式
            },
            tooltip: '列表视图',
          ),
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () {
              // TODO: 切换视图模式
            },
            tooltip: '网格视图',
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(fileServiceProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
      BuildContext context, WidgetRef ref, SearchState state) {
    if (state.result == null) {
      return const Center(child: Text('无搜索结果'));
    }

    return Column(
      children: [
        // 搜索结果统计
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Row(
            children: [
              Text(
                '找到 ${state.result!.totalMatches} 个结果',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Text(
                '耗时 ${state.result!.durationMs} ms',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    ref.read(searchServiceProvider.notifier).clearSearch(),
                child: const Text('清除搜索'),
              ),
            ],
          ),
        ),

        // 结果列表
        Expanded(
          child: FileListView(
            entries: state.result!.entries,
            onTap: (entry) {
              if (entry.isDir) {
                ref.read(searchServiceProvider.notifier).clearSearch();
                ref.read(fileServiceProvider.notifier).navigateTo(entry.path);
              } else {
                _openFile(entry.path);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(
    BuildContext context,
    FileServiceState fileState,
    SearchState searchState,
  ) {
    final itemCount = searchState.query.isNotEmpty
        ? searchState.result?.entries.length ?? 0
        : fileState.entries.length;

    final dirCount = (searchState.query.isNotEmpty
            ? searchState.result?.entries
            : fileState.entries)
        ?.where((e) => e.isDir)
        .length ?? 0;

    final fileCount = itemCount - dirCount;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$itemCount 项 ($dirCount 文件夹, $fileCount 文件)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            fileState.currentPath,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event, WidgetRef ref) {
    if (event is! KeyDownEvent) return;

    final isCmd = HardwareKeyboard.instance.isMetaPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    if ((isCmd || isCtrl) && event.logicalKey == LogicalKeyboardKey.keyR) {
      ref.read(fileServiceProvider.notifier).refresh();
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (ref.read(fileServiceProvider).canGoBack) {
        ref.read(fileServiceProvider.notifier).goBack();
      }
    }
  }

  void _openFile(String path) {
    // TODO: 调用系统默认程序打开文件
    debugPrint('Opening file: $path');
  }
}
