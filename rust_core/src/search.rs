use crate::models::{FileEntry, SearchOptions, SearchResult};
use crate::scanner::FileScanner;
use anyhow::Result;
use fuzzy_matcher::skim::SkimMatcherV2;
use fuzzy_matcher::FuzzyMatcher;
use rayon::prelude::*;
use std::time::Instant;

/// 文件搜索引擎
pub struct SearchEngine;

impl SearchEngine {
    /// 执行文件搜索
    pub fn search(options: SearchOptions) -> Result<SearchResult> {
        let start = Instant::now();

        // 扫描目录
        let entries = FileScanner::scan_directory(
            &options.root_path,
            options.recursive,
            options.include_hidden,
        )?;

        // 执行搜索
        let matched_entries: Vec<FileEntry> = if options.fuzzy {
            Self::fuzzy_search(&entries, &options)
        } else {
            Self::exact_search(&entries, &options)
        };

        // 限制结果数量
        let total_matches = matched_entries.len();
        let entries = if let Some(max) = options.max_results {
            matched_entries.into_iter().take(max).collect()
        } else {
            matched_entries
        };

        let duration_ms = start.elapsed().as_millis() as u64;

        Ok(SearchResult {
            entries,
            duration_ms,
            total_matches,
        })
    }

    /// 模糊搜索
    fn fuzzy_search(entries: &[FileEntry], options: &SearchOptions) -> Vec<FileEntry> {
        let matcher = SkimMatcherV2::default();
        let query = if options.case_sensitive {
            options.query.clone()
        } else {
            options.query.to_lowercase()
        };

        let mut scored: Vec<(i64, FileEntry)> = entries
            .par_iter()
            .filter_map(|entry| {
                // 扩展名过滤
                if let Some(ref exts) = options.extensions {
                    if let Some(ref ext) = entry.extension {
                        if !exts.iter().any(|e| e.eq_ignore_ascii_case(ext)) {
                            return None;
                        }
                    } else if !entry.is_dir {
                        return None;
                    }
                }

                let name = if options.case_sensitive {
                    entry.name.clone()
                } else {
                    entry.name.to_lowercase()
                };

                matcher
                    .fuzzy_match(&name, &query)
                    .map(|score| (score, entry.clone()))
            })
            .collect();

        // 按分数降序排序
        scored.sort_by(|a, b| b.0.cmp(&a.0));
        scored.into_iter().map(|(_, entry)| entry).collect()
    }

    /// 精确搜索（包含匹配）
    fn exact_search(entries: &[FileEntry], options: &SearchOptions) -> Vec<FileEntry> {
        let query = if options.case_sensitive {
            options.query.clone()
        } else {
            options.query.to_lowercase()
        };

        entries
            .par_iter()
            .filter(|entry| {
                // 扩展名过滤
                if let Some(ref exts) = options.extensions {
                    if let Some(ref ext) = entry.extension {
                        if !exts.iter().any(|e| e.eq_ignore_ascii_case(ext)) {
                            return false;
                        }
                    } else if !entry.is_dir {
                        return false;
                    }
                }

                let name = if options.case_sensitive {
                    entry.name.clone()
                } else {
                    entry.name.to_lowercase()
                };

                name.contains(&query)
            })
            .cloned()
            .collect()
    }

    /// 按扩展名搜索
    pub fn search_by_extension(root_path: &str, extension: &str, recursive: bool) -> Result<Vec<FileEntry>> {
        let entries = FileScanner::scan_directory(root_path, recursive, false)?;

        Ok(entries
            .into_iter()
            .filter(|e| {
                e.extension
                    .as_ref()
                    .map(|ext| ext.eq_ignore_ascii_case(extension))
                    .unwrap_or(false)
            })
            .collect())
    }

    /// 按大小范围搜索
    pub fn search_by_size(
        root_path: &str,
        min_size: Option<u64>,
        max_size: Option<u64>,
        recursive: bool,
    ) -> Result<Vec<FileEntry>> {
        let entries = FileScanner::scan_directory(root_path, recursive, false)?;

        Ok(entries
            .into_iter()
            .filter(|e| {
                if e.is_dir {
                    return false;
                }
                let size = e.size;
                let above_min = min_size.map(|m| size >= m).unwrap_or(true);
                let below_max = max_size.map(|m| size <= m).unwrap_or(true);
                above_min && below_max
            })
            .collect())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_fuzzy_search() {
        let options = SearchOptions {
            query: "lib".to_string(),
            root_path: ".".to_string(),
            recursive: true,
            ..Default::default()
        };

        let result = SearchEngine::search(options);
        assert!(result.is_ok());
    }
}
