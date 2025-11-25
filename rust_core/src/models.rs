use serde::{Deserialize, Serialize};

/// 文件条目信息
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileEntry {
    /// 文件名
    pub name: String,
    /// 完整路径
    pub path: String,
    /// 是否为目录
    pub is_dir: bool,
    /// 文件大小（字节）
    pub size: u64,
    /// 修改时间
    pub modified: Option<i64>,
    /// 创建时间
    pub created: Option<i64>,
    /// 文件扩展名
    pub extension: Option<String>,
    /// MIME 类型
    pub mime_type: Option<String>,
    /// 是否隐藏文件
    pub is_hidden: bool,
}

/// 搜索结果
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchResult {
    /// 匹配的文件列表
    pub entries: Vec<FileEntry>,
    /// 搜索耗时（毫秒）
    pub duration_ms: u64,
    /// 总匹配数
    pub total_matches: usize,
}

/// 目录统计信息
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DirectoryStats {
    /// 文件数量
    pub file_count: usize,
    /// 目录数量
    pub dir_count: usize,
    /// 总大小
    pub total_size: u64,
}

/// 搜索选项
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchOptions {
    /// 搜索关键词
    pub query: String,
    /// 搜索根目录
    pub root_path: String,
    /// 是否递归搜索
    pub recursive: bool,
    /// 是否区分大小写
    pub case_sensitive: bool,
    /// 是否使用模糊匹配
    pub fuzzy: bool,
    /// 文件类型过滤（扩展名列表）
    pub extensions: Option<Vec<String>>,
    /// 最大结果数
    pub max_results: Option<usize>,
    /// 是否包含隐藏文件
    pub include_hidden: bool,
}

impl Default for SearchOptions {
    fn default() -> Self {
        Self {
            query: String::new(),
            root_path: String::new(),
            recursive: true,
            case_sensitive: false,
            fuzzy: true,
            extensions: None,
            max_results: Some(1000),
            include_hidden: false,
        }
    }
}
