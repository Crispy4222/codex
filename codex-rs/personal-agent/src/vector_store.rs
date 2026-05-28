use anyhow::Result;
use serde::Deserialize;
use serde::Serialize;
use serde_json::Value;
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Document {
    pub id: String,
    pub content: String,
    pub source: String,
    pub metadata: Value,
}

#[derive(Debug, Clone)]
pub struct SearchResult {
    pub document: Document,
    pub score: f32,
}

// In-memory vector store for now
// TODO: Replace with actual Qdrant backend when API is stabilized
pub struct VectorStore {
    documents: HashMap<String, (Document, Vec<f32>)>,
    collection: String,
}

impl VectorStore {
    pub async fn new(_url: &str, collection: &str) -> Result<Self> {
        Ok(Self {
            documents: HashMap::new(),
            collection: collection.to_string(),
        })
    }

    pub async fn create_collection(&self, _dimension: u64) -> Result<()> {
        Ok(())
    }

    pub async fn store_document(&mut self, doc: &Document, embedding: Vec<f32>) -> Result<String> {
        let doc_id = doc.id.clone();
        self.documents.insert(doc_id.clone(), (doc.clone(), embedding));
        Ok(doc_id)
    }

    pub async fn search(&self, embedding: Vec<f32>, limit: usize) -> Result<Vec<SearchResult>> {
        let mut results = Vec::new();

        for (_, (doc, stored_embedding)) in &self.documents {
            let score = cosine_similarity(&embedding, stored_embedding);
            results.push(SearchResult {
                document: doc.clone(),
                score,
            });
        }

        // Sort by score descending and limit
        results.sort_by(|a, b| b.score.partial_cmp(&a.score).unwrap_or(std::cmp::Ordering::Equal));
        results.truncate(limit);

        Ok(results)
    }

    pub async fn delete_document(&mut self, doc_id: &str) -> Result<()> {
        self.documents.remove(doc_id);
        Ok(())
    }

    pub async fn clear_collection(&mut self) -> Result<()> {
        self.documents.clear();
        Ok(())
    }
}

fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    if a.is_empty() || b.is_empty() || a.len() != b.len() {
        return 0.0;
    }

    let mut dot_product = 0.0;
    let mut mag_a = 0.0;
    let mut mag_b = 0.0;

    for i in 0..a.len() {
        dot_product += a[i] * b[i];
        mag_a += a[i] * a[i];
        mag_b += b[i] * b[i];
    }

    let magnitude = (mag_a * mag_b).sqrt();
    if magnitude == 0.0 {
        0.0
    } else {
        dot_product / magnitude
    }
}
