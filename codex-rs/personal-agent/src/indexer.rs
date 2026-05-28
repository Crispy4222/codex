use anyhow::Result;
use std::path::Path;
use std::path::PathBuf;
use walkdir::WalkDir;

#[derive(Debug, Clone)]
pub struct FileToIndex {
    pub path: PathBuf,
    pub content: String,
}

pub struct KnowledgeIndexer {
    /// File extensions to index
    pub extensions: Vec<String>,

    /// Directories to exclude
    pub exclude_dirs: Vec<String>,

    /// Max file size in bytes
    pub max_file_size: u64,
}

impl Default for KnowledgeIndexer {
    fn default() -> Self {
        Self {
            extensions: vec![
                "rs".to_string(),
                "ts".to_string(),
                "js".to_string(),
                "py".to_string(),
                "md".to_string(),
                "txt".to_string(),
                "toml".to_string(),
                "yaml".to_string(),
                "json".to_string(),
                "go".to_string(),
                "c".to_string(),
                "cpp".to_string(),
                "h".to_string(),
            ],
            exclude_dirs: vec![
                "node_modules".to_string(),
                ".git".to_string(),
                "target".to_string(),
                ".venv".to_string(),
                "__pycache__".to_string(),
                "dist".to_string(),
                "build".to_string(),
            ],
            max_file_size: 10 * 1024 * 1024, // 10MB
        }
    }
}

impl KnowledgeIndexer {
    pub fn index_directory<P: AsRef<Path>>(&self, path: P) -> Result<Vec<FileToIndex>> {
        let mut files = Vec::new();

        for entry in WalkDir::new(path)
            .into_iter()
            .filter_map(|e| e.ok())
            .filter(|e| e.path().is_file())
        {
            let path = entry.path();

            // Skip excluded directories
            if self.should_exclude_path(path) {
                continue;
            }

            // Check extension
            if !self.should_index_file(path) {
                continue;
            }

            // Check file size
            if let Ok(metadata) = std::fs::metadata(path) {
                if metadata.len() > self.max_file_size {
                    continue;
                }
            }

            // Read file
            match std::fs::read_to_string(path) {
                Ok(content) => {
                    files.push(FileToIndex {
                        path: path.to_path_buf(),
                        content,
                    });
                }
                Err(_) => continue, // Skip unreadable files
            }
        }

        Ok(files)
    }

    fn should_exclude_path(&self, path: &Path) -> bool {
        path.components().any(|comp| {
            if let std::path::Component::Normal(name) = comp {
                if let Some(name_str) = name.to_str() {
                    return self.exclude_dirs.contains(&name_str.to_string());
                }
            }
            false
        })
    }

    fn should_index_file(&self, path: &Path) -> bool {
        if let Some(ext) = path.extension() {
            if let Some(ext_str) = ext.to_str() {
                return self.extensions.contains(&ext_str.to_string());
            }
        }
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use tempfile::TempDir;

    #[test]
    fn test_indexer_finds_files() {
        let temp_dir = TempDir::new().unwrap();
        let rs_file = temp_dir.path().join("test.rs");
        fs::write(&rs_file, "fn main() {}").unwrap();

        let indexer = KnowledgeIndexer::default();
        let files = indexer.index_directory(temp_dir.path()).unwrap();

        assert_eq!(files.len(), 1);
        assert_eq!(files[0].path, rs_file);
    }
}
