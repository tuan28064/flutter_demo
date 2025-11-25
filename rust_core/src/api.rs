//! Flutter-Rust 桥接 API
//!
//! 这个模块定义了暴露给 Flutter 的所有公共 API。
//! flutter_rust_bridge 会自动生成 Dart 绑定代码。

use crate::models::{DirectoryStats, FileEntry, SearchOptions, SearchResult};
use crate::scanner::FileScanner;
use crate::search::SearchEngine;

/// 列出目录内容
///
/// # 参数
/// * `path` - 目录路径
/// * `include_hidden` - 是否包含隐藏文件
///
/// # 返回
/// 文件条目列表
#[flutter_rust_bridge::frb(sync)]
pub fn list_directory(path: String, include_hidden: bool) -> Result<Vec<FileEntry>, String> {
    FileScanner::scan_directory(&path, false, include_hidden)
        .map_err(|e| e.to_string())
}

/// 递归扫描目录
///
/// # 参数
/// * `path` - 目录路径
/// * `include_hidden` - 是否包含隐藏文件
///
/// # 返回
/// 所有文件条目列表
pub fn scan_directory_recursive(path: String, include_hidden: bool) -> Result<Vec<FileEntry>, String> {
    FileScanner::scan_directory(&path, true, include_hidden)
        .map_err(|e| e.to_string())
}

/// 搜索文件
///
/// # 参数
/// * `options` - 搜索选项
///
/// # 返回
/// 搜索结果
pub fn search_files(options: SearchOptions) -> Result<SearchResult, String> {
    SearchEngine::search(options).map_err(|e| e.to_string())
}

/// 快速搜索（简化版）
///
/// # 参数
/// * `query` - 搜索关键词
/// * `root_path` - 搜索根目录
///
/// # 返回
/// 搜索结果
pub fn quick_search(query: String, root_path: String) -> Result<SearchResult, String> {
    let options = SearchOptions {
        query,
        root_path,
        ..Default::default()
    };
    SearchEngine::search(options).map_err(|e| e.to_string())
}

/// 按扩展名搜索
///
/// # 参数
/// * `root_path` - 搜索根目录
/// * `extension` - 文件扩展名
///
/// # 返回
/// 匹配的文件列表
pub fn search_by_extension(root_path: String, extension: String) -> Result<Vec<FileEntry>, String> {
    SearchEngine::search_by_extension(&root_path, &extension, true)
        .map_err(|e| e.to_string())
}

/// 按文件大小搜索
///
/// # 参数
/// * `root_path` - 搜索根目录
/// * `min_size` - 最小大小（字节）
/// * `max_size` - 最大大小（字节）
///
/// # 返回
/// 匹配的文件列表
pub fn search_by_size(
    root_path: String,
    min_size: Option<u64>,
    max_size: Option<u64>,
) -> Result<Vec<FileEntry>, String> {
    SearchEngine::search_by_size(&root_path, min_size, max_size, true)
        .map_err(|e| e.to_string())
}

/// 获取目录统计信息
///
/// # 参数
/// * `path` - 目录路径
///
/// # 返回
/// 目录统计信息
pub fn get_directory_stats(path: String) -> Result<DirectoryStats, String> {
    FileScanner::get_directory_stats(&path, false).map_err(|e| e.to_string())
}

/// 获取单个文件信息
///
/// # 参数
/// * `path` - 文件路径
///
/// # 返回
/// 文件信息
#[flutter_rust_bridge::frb(sync)]
pub fn get_file_info(path: String) -> Result<FileEntry, String> {
    use std::fs;
    use std::path::Path;
    use std::time::SystemTime;

    let path_obj = Path::new(&path);
    if !path_obj.exists() {
        return Err(format!("文件不存在: {}", path));
    }

    let metadata = fs::metadata(&path).map_err(|e| e.to_string())?;
    let file_name = path_obj
        .file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_default();
    let extension = path_obj
        .extension()
        .map(|e| e.to_string_lossy().to_string());
    let is_hidden = file_name.starts_with('.');

    Ok(FileEntry {
        name: file_name,
        path,
        is_dir: metadata.is_dir(),
        size: if metadata.is_dir() { 0 } else { metadata.len() },
        modified: metadata
            .modified()
            .ok()
            .and_then(|t| t.duration_since(SystemTime::UNIX_EPOCH).ok())
            .map(|d| d.as_secs() as i64),
        created: metadata
            .created()
            .ok()
            .and_then(|t| t.duration_since(SystemTime::UNIX_EPOCH).ok())
            .map(|d| d.as_secs() as i64),
        extension,
        mime_type: None,
        is_hidden,
    })
}

/// 检查路径是否存在
#[flutter_rust_bridge::frb(sync)]
pub fn path_exists(path: String) -> bool {
    std::path::Path::new(&path).exists()
}

/// 检查是否为目录
#[flutter_rust_bridge::frb(sync)]
pub fn is_directory(path: String) -> bool {
    std::path::Path::new(&path).is_dir()
}

/// 获取用户主目录
#[flutter_rust_bridge::frb(sync)]
pub fn get_home_directory() -> Option<String> {
    dirs::home_dir().map(|p| p.to_string_lossy().to_string())
}

// 需要添加 dirs 依赖
