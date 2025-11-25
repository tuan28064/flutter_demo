/// 文件条目模型（与 Rust 端对应）
class FileEntry {
  final String name;
  final String path;
  final bool isDir;
  final int size;
  final DateTime? modified;
  final DateTime? created;
  final String? extension;
  final String? mimeType;
  final bool isHidden;

  const FileEntry({
    required this.name,
    required this.path,
    required this.isDir,
    required this.size,
    this.modified,
    this.created,
    this.extension,
    this.mimeType,
    required this.isHidden,
  });

  /// 从 Rust FFI 数据创建
  factory FileEntry.fromRust(Map<String, dynamic> json) {
    return FileEntry(
      name: json['name'] as String,
      path: json['path'] as String,
      isDir: json['is_dir'] as bool,
      size: json['size'] as int,
      modified: json['modified'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['modified'] as int) * 1000)
          : null,
      created: json['created'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['created'] as int) * 1000)
          : null,
      extension: json['extension'] as String?,
      mimeType: json['mime_type'] as String?,
      isHidden: json['is_hidden'] as bool,
    );
  }

  /// 格式化文件大小
  String get formattedSize {
    if (isDir) return '--';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 格式化修改时间
  String get formattedModified {
    if (modified == null) return '--';
    return '${modified!.year}-${modified!.month.toString().padLeft(2, '0')}-${modified!.day.toString().padLeft(2, '0')} '
        '${modified!.hour.toString().padLeft(2, '0')}:${modified!.minute.toString().padLeft(2, '0')}';
  }
}

/// 搜索结果模型
class SearchResult {
  final List<FileEntry> entries;
  final int durationMs;
  final int totalMatches;

  const SearchResult({
    required this.entries,
    required this.durationMs,
    required this.totalMatches,
  });

  factory SearchResult.fromRust(Map<String, dynamic> json) {
    return SearchResult(
      entries: (json['entries'] as List)
          .map((e) => FileEntry.fromRust(e as Map<String, dynamic>))
          .toList(),
      durationMs: json['duration_ms'] as int,
      totalMatches: json['total_matches'] as int,
    );
  }
}

/// 目录统计信息
class DirectoryStats {
  final int fileCount;
  final int dirCount;
  final int totalSize;

  const DirectoryStats({
    required this.fileCount,
    required this.dirCount,
    required this.totalSize,
  });

  factory DirectoryStats.fromRust(Map<String, dynamic> json) {
    return DirectoryStats(
      fileCount: json['file_count'] as int,
      dirCount: json['dir_count'] as int,
      totalSize: json['total_size'] as int,
    );
  }
}

/// 搜索选项
class SearchOptions {
  final String query;
  final String rootPath;
  final bool recursive;
  final bool caseSensitive;
  final bool fuzzy;
  final List<String>? extensions;
  final int? maxResults;
  final bool includeHidden;

  const SearchOptions({
    required this.query,
    required this.rootPath,
    this.recursive = true,
    this.caseSensitive = false,
    this.fuzzy = true,
    this.extensions,
    this.maxResults = 1000,
    this.includeHidden = false,
  });

  Map<String, dynamic> toRust() {
    return {
      'query': query,
      'root_path': rootPath,
      'recursive': recursive,
      'case_sensitive': caseSensitive,
      'fuzzy': fuzzy,
      'extensions': extensions,
      'max_results': maxResults,
      'include_hidden': includeHidden,
    };
  }
}
