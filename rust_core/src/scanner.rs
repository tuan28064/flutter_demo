use crate::models::{DirectoryStats, FileEntry};
use anyhow::{Context, Result};
use std::fs;
use std::path::Path;
use std::time::SystemTime;

/// 文件扫描器
pub struct FileScanner;

impl FileScanner {
    /// 扫描目录，返回文件列表
    pub fn scan_directory(path: &str, recursive: bool, include_hidden: bool) -> Result<Vec<FileEntry>> {
        let path = Path::new(path);
        if !path.exists() {
            anyhow::bail!("路径不存在: {}", path.display());
        }
        if !path.is_dir() {
            anyhow::bail!("不是目录: {}", path.display());
        }

        let mut entries = Vec::new();
        Self::scan_dir_internal(path, recursive, include_hidden, &mut entries)?;
        Ok(entries)
    }

    fn scan_dir_internal(
        dir: &Path,
        recursive: bool,
        include_hidden: bool,
        entries: &mut Vec<FileEntry>,
    ) -> Result<()> {
        let read_dir = fs::read_dir(dir)
            .with_context(|| format!("无法读取目录: {}", dir.display()))?;

        for entry in read_dir.flatten() {
            let path = entry.path();
            let file_name = entry.file_name().to_string_lossy().to_string();

            // 检查是否为隐藏文件
            let is_hidden = file_name.starts_with('.');
            if is_hidden && !include_hidden {
                continue;
            }

            if let Ok(metadata) = entry.metadata() {
                let is_dir = metadata.is_dir();

                let file_entry = FileEntry {
                    name: file_name,
                    path: path.to_string_lossy().to_string(),
                    is_dir,
                    size: if is_dir { 0 } else { metadata.len() },
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
                    extension: path
                        .extension()
                        .map(|e| e.to_string_lossy().to_string()),
                    mime_type: Self::detect_mime_type(&path),
                    is_hidden,
                };

                entries.push(file_entry);

                if is_dir && recursive {
                    let _ = Self::scan_dir_internal(&path, recursive, include_hidden, entries);
                }
            }
        }

        Ok(())
    }

    /// 获取目录统计信息
    pub fn get_directory_stats(path: &str, include_hidden: bool) -> Result<DirectoryStats> {
        let entries = Self::scan_directory(path, true, include_hidden)?;

        let file_count = entries.iter().filter(|e| !e.is_dir).count();
        let dir_count = entries.iter().filter(|e| e.is_dir).count();
        let total_size: u64 = entries.iter().map(|e| e.size).sum();

        Ok(DirectoryStats {
            file_count,
            dir_count,
            total_size,
        })
    }

    /// 检测文件 MIME 类型
    fn detect_mime_type(path: &Path) -> Option<String> {
        if path.is_dir() {
            return Some("inode/directory".to_string());
        }

        // 尝试通过文件内容检测
        if let Ok(buf) = fs::read(path) {
            if let Some(kind) = infer::get(&buf) {
                return Some(kind.mime_type().to_string());
            }
        }

        // 通过扩展名猜测
        path.extension()
            .and_then(|ext| Self::mime_from_extension(&ext.to_string_lossy()))
    }

    fn mime_from_extension(ext: &str) -> Option<String> {
        let mime = match ext.to_lowercase().as_str() {
            "txt" => "text/plain",
            "md" => "text/markdown",
            "rs" => "text/x-rust",
            "dart" => "text/x-dart",
            "py" => "text/x-python",
            "js" => "text/javascript",
            "ts" => "text/typescript",
            "json" => "application/json",
            "xml" => "application/xml",
            "html" | "htm" => "text/html",
            "css" => "text/css",
            "pdf" => "application/pdf",
            "doc" | "docx" => "application/msword",
            "xls" | "xlsx" => "application/vnd.ms-excel",
            "png" => "image/png",
            "jpg" | "jpeg" => "image/jpeg",
            "gif" => "image/gif",
            "svg" => "image/svg+xml",
            "mp3" => "audio/mpeg",
            "mp4" => "video/mp4",
            "zip" => "application/zip",
            "tar" => "application/x-tar",
            "gz" => "application/gzip",
            _ => return None,
        };
        Some(mime.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_scan_current_dir() {
        let result = FileScanner::scan_directory(".", false, false);
        assert!(result.is_ok());
    }
}
