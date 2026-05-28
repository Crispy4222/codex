use crate::indexer::FileToIndex;
use crate::indexer::KnowledgeIndexer;
use crate::llm::LlmProvider;
use crate::vector_store::Document;
use crate::vector_store::SearchResult;
use crate::vector_store::VectorStore;
use anyhow::Result;
use std::path::PathBuf;
use std::sync::Mutex;
use uuid::Uuid;

pub struct KnowledgeBase {
    vector_store: Mutex<VectorStore>,
    llm_provider: Box<dyn LlmProvider>,
    indexer: KnowledgeIndexer,
}

impl KnowledgeBase {
    pub async fn new(
        vector_store: VectorStore,
        llm_provider: Box<dyn LlmProvider>,
    ) -> Result<Self> {
        Ok(Self {
            vector_store: Mutex::new(vector_store),
            llm_provider,
            indexer: KnowledgeIndexer::default(),
        })
    }

    pub async fn index_files(&self, paths: &[PathBuf]) -> Result<usize> {
        let mut count = 0;

        for path in paths {
            let files = self.indexer.index_directory(path)?;

            for file in files {
                if let Err(e) = self.index_file(&file).await {
                    eprintln!("Failed to index {}: {}", file.path.display(), e);
                    continue;
                }
                count += 1;
            }
        }

        Ok(count)
    }

    async fn index_file(&self, file: &FileToIndex) -> Result<()> {
        // Chunk the file into smaller pieces
        let chunks = self.chunk_content(&file.content, 512); // 512 token chunks

        for (idx, chunk) in chunks.iter().enumerate() {
            let embedding = self.llm_provider.embed_text(chunk).await?;

            let doc = Document {
                id: Uuid::new_v4().to_string(),
                content: chunk.clone(),
                source: file.path.to_string_lossy().to_string(),
                metadata: serde_json::json!({
                    "chunk_index": idx,
                    "file_type": file.path.extension().and_then(|e| e.to_str()).unwrap_or("unknown"),
                }),
            };

            let mut vs = self.vector_store.lock().unwrap();
            vs.store_document(&doc, embedding).await?;
        }

        Ok(())
    }

    pub async fn search(&self, query: &str, top_k: usize) -> Result<Vec<SearchResult>> {
        let query_embedding = self.llm_provider.embed_text(query).await?;
        let vs = self.vector_store.lock().unwrap();
        vs.search(query_embedding, top_k).await
    }

    fn chunk_content(&self, content: &str, chunk_size: usize) -> Vec<String> {
        let words: Vec<&str> = content.split_whitespace().collect();
        let mut chunks = Vec::new();

        for chunk in words.chunks(chunk_size) {
            chunks.push(chunk.join(" "));
        }

        chunks
    }
}
