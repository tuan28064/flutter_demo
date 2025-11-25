import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_entry.dart';
import 'rust_bridge.dart';

/// 文件服务状态
class FileServiceState {
  final String currentPath;
  final List<FileEntry> entries;
  final bool isLoading;
  final String? error;
  final List<String> pathHistory;
  final int historyIndex;

  const FileServiceState({
    required this.currentPath,
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.pathHistory = const [],
    this.historyIndex = -1,
  });

  FileServiceState copyWith({
    String? currentPath,
    List<FileEntry>? entries,
    bool? isLoading,
    String? error,
    List<String>? pathHistory,
    int? historyIndex,
  }) {
    return FileServiceState(
      currentPath: currentPath ?? this.currentPath,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pathHistory: pathHistory ?? this.pathHistory,
      historyIndex: historyIndex ?? this.historyIndex,
    );
  }

  bool get canGoBack => historyIndex > 0;
  bool get canGoForward => historyIndex < pathHistory.length - 1;
}

/// 文件服务 Provider
class FileServiceNotifier extends StateNotifier<FileServiceState> {
  FileServiceNotifier()
      : super(FileServiceState(
          currentPath: RustBridge.getHomeDirectory() ?? '/',
        )) {
    // 初始化时加载主目录
    _loadDirectory(state.currentPath);
  }

  /// 导航到指定目录
  Future<void> navigateTo(String path) async {
    if (path == state.currentPath) return;

    final newHistory = [
      ...state.pathHistory.sublist(0, state.historyIndex + 1),
      path,
    ];

    state = state.copyWith(
      pathHistory: newHistory,
      historyIndex: newHistory.length - 1,
    );

    await _loadDirectory(path);
  }

  /// 后退
  Future<void> goBack() async {
    if (!state.canGoBack) return;

    final newIndex = state.historyIndex - 1;
    state = state.copyWith(historyIndex: newIndex);
    await _loadDirectory(state.pathHistory[newIndex]);
  }

  /// 前进
  Future<void> goForward() async {
    if (!state.canGoForward) return;

    final newIndex = state.historyIndex + 1;
    state = state.copyWith(historyIndex: newIndex);
    await _loadDirectory(state.pathHistory[newIndex]);
  }

  /// 进入子目录
  Future<void> enterDirectory(FileEntry entry) async {
    if (!entry.isDir) return;
    await navigateTo(entry.path);
  }

  /// 返回上级目录
  Future<void> goToParent() async {
    final parts = state.currentPath.split('/');
    if (parts.length <= 1) return;

    parts.removeLast();
    final parentPath = parts.isEmpty ? '/' : parts.join('/');
    await navigateTo(parentPath);
  }

  /// 刷新当前目录
  Future<void> refresh() async {
    await _loadDirectory(state.currentPath);
  }

  /// 加载目录内容
  Future<void> _loadDirectory(String path) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entries = await RustBridge.listDirectory(path);
      state = state.copyWith(
        currentPath: path,
        entries: entries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// 文件服务 Provider
final fileServiceProvider =
    StateNotifierProvider<FileServiceNotifier, FileServiceState>((ref) {
  return FileServiceNotifier();
});

/// 搜索状态
class SearchState {
  final String query;
  final SearchResult? result;
  final bool isSearching;
  final String? error;

  const SearchState({
    this.query = '',
    this.result,
    this.isSearching = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    SearchResult? result,
    bool? isSearching,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      result: result ?? this.result,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}

/// 搜索服务
class SearchServiceNotifier extends StateNotifier<SearchState> {
  final Ref ref;

  SearchServiceNotifier(this.ref) : super(const SearchState());

  /// 执行搜索
  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(query: query, isSearching: true, error: null);

    try {
      final fileState = ref.read(fileServiceProvider);
      final result = await RustBridge.quickSearch(query, fileState.currentPath);
      state = state.copyWith(result: result, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  /// 高级搜索
  Future<void> advancedSearch(SearchOptions options) async {
    state = state.copyWith(
      query: options.query,
      isSearching: true,
      error: null,
    );

    try {
      final result = await RustBridge.searchFiles(options);
      state = state.copyWith(result: result, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  /// 清除搜索
  void clearSearch() {
    state = const SearchState();
  }
}

/// 搜索服务 Provider
final searchServiceProvider =
    StateNotifierProvider<SearchServiceNotifier, SearchState>((ref) {
  return SearchServiceNotifier(ref);
});
