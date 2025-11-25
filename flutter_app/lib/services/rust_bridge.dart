import 'dart:io';
import '../models/file_entry.dart';

// 注意：这个文件需要在运行 flutter_rust_bridge_codegen 后更新
// 当前为模拟实现，展示 API 结构

/// Rust 桥接服务
///
/// 封装所有与 Rust 后端的通信
class RustBridge {
  static bool _initialized = false;

  /// 初始化 Rust 库
  static Future<void> init() async {
    if (_initialized) return;

    // TODO: 初始化 flutter_rust_bridge
    // 加载动态库等
    _initialized = true;
  }

  /// 列出目录内容
  static Future<List<FileEntry>> listDirectory(
    String path, {
    bool includeHidden = false,
  }) async {
    // TODO: 调用 Rust API
    // return await api.listDirectory(path: path, includeHidden: includeHidden);

    // 临时实现：使用 Dart 原生 API
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw Exception('目录不存在: $path');
    }

    final entries = <FileEntry>[];
    await for (final entity in dir.list()) {
      final stat = await entity.stat();
      final name = entity.path.split(Platform.pathSeparator).last;

      if (!includeHidden && name.startsWith('.')) continue;

      entries.add(FileEntry(
        name: name,
        path: entity.path,
        isDir: entity is Directory,
        size: stat.size,
        modified: stat.modified,
        created: stat.changed,
        extension: entity is File ? name.split('.').last : null,
        mimeType: null,
        isHidden: name.startsWith('.'),
      ));
    }

    // 目录优先，然后按名称排序
    entries.sort((a, b) {
      if (a.isDir && !b.isDir) return -1;
      if (!a.isDir && b.isDir) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entries;
  }

  /// 搜索文件
  static Future<SearchResult> searchFiles(SearchOptions options) async {
    // TODO: 调用 Rust API
    // return await api.searchFiles(options: options);

    final stopwatch = Stopwatch()..start();
    final results = <FileEntry>[];

    await _searchRecursive(
      Directory(options.rootPath),
      options,
      results,
    );

    stopwatch.stop();

    return SearchResult(
      entries: results.take(options.maxResults ?? 1000).toList(),
      durationMs: stopwatch.elapsedMilliseconds,
      totalMatches: results.length,
    );
  }

  static Future<void> _searchRecursive(
    Directory dir,
    SearchOptions options,
    List<FileEntry> results,
  ) async {
    try {
      await for (final entity in dir.list()) {
        final name = entity.path.split(Platform.pathSeparator).last;

        if (!options.includeHidden && name.startsWith('.')) continue;

        final matches = options.caseSensitive
            ? name.contains(options.query)
            : name.toLowerCase().contains(options.query.toLowerCase());

        if (matches) {
          final stat = await entity.stat();
          results.add(FileEntry(
            name: name,
            path: entity.path,
            isDir: entity is Directory,
            size: stat.size,
            modified: stat.modified,
            created: stat.changed,
            extension: entity is File ? name.split('.').last : null,
            mimeType: null,
            isHidden: name.startsWith('.'),
          ));
        }

        if (options.recursive && entity is Directory) {
          await _searchRecursive(entity, options, results);
        }
      }
    } catch (_) {
      // 忽略无权访问的目录
    }
  }

  /// 快速搜索
  static Future<SearchResult> quickSearch(String query, String rootPath) async {
    return searchFiles(SearchOptions(
      query: query,
      rootPath: rootPath,
    ));
  }

  /// 获取目录统计信息
  static Future<DirectoryStats> getDirectoryStats(String path) async {
    // TODO: 调用 Rust API
    int fileCount = 0;
    int dirCount = 0;
    int totalSize = 0;

    await _countRecursive(Directory(path), (files, dirs, size) {
      fileCount += files;
      dirCount += dirs;
      totalSize += size;
    });

    return DirectoryStats(
      fileCount: fileCount,
      dirCount: dirCount,
      totalSize: totalSize,
    );
  }

  static Future<void> _countRecursive(
    Directory dir,
    void Function(int files, int dirs, int size) callback,
  ) async {
    try {
      int files = 0;
      int dirs = 0;
      int size = 0;

      await for (final entity in dir.list()) {
        if (entity is File) {
          files++;
          size += await entity.length();
        } else if (entity is Directory) {
          dirs++;
          await _countRecursive(entity, callback);
        }
      }

      callback(files, dirs, size);
    } catch (_) {}
  }

  /// 获取用户主目录
  static String? getHomeDirectory() {
    return Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  }

  /// 检查路径是否存在
  static Future<bool> pathExists(String path) async {
    return await FileSystemEntity.isDirectory(path) ||
        await FileSystemEntity.isFile(path);
  }

  /// 检查是否为目录
  static Future<bool> isDirectory(String path) async {
    return await FileSystemEntity.isDirectory(path);
  }
}
