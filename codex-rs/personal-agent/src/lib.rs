//! Personal AI Agent - Your unlimited, uncensored, independently-owned coding agent
//!
//! Features:
//! - Vector-based knowledge indexing from your personal files
//! - Modular plugin architecture for extensibility
//! - Local and remote LLM support
//! - Self-growing knowledge base
//! - Complete data ownership

pub mod agent;
pub mod config;
pub mod indexer;
pub mod knowledge_base;
pub mod llm;
pub mod plugin;
pub mod vector_store;

pub use agent::PersonalAgent;
pub use config::AgentConfig;
pub use knowledge_base::KnowledgeBase;

#[derive(Debug, Clone)]
pub struct AgentQuery {
    pub question: String,
    pub context_limit: usize,
    pub include_files: bool,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct AgentResponse {
    pub answer: String,
    pub sources: Vec<String>,
    pub confidence: f32,
    pub metadata: serde_json::Value,
}
