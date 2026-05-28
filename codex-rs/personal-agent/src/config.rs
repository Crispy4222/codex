use serde::Deserialize;
use serde::Serialize;
use std::path::Path;
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentConfig {
    /// Knowledge base directories to index
    pub knowledge_paths: Vec<PathBuf>,

    /// Vector store configuration
    pub vector_store: VectorStoreConfig,

    /// LLM configuration
    pub llm: LlmConfig,

    /// Agent behavior
    pub agent: AgentBehavior,

    /// Data directory for agent state
    pub data_dir: PathBuf,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VectorStoreConfig {
    /// Qdrant server URL
    pub url: String,

    /// Collection name
    pub collection: String,

    /// Vector dimension
    pub dimension: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum LlmConfig {
    /// Local model via Ollama
    Ollama { url: String, model: String },
    /// Remote model via API
    Remote {
        endpoint: String,
        api_key: String,
        model: String,
    },
    /// Custom LLM implementation
    Custom { plugin_path: PathBuf },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentBehavior {
    /// Maximum tokens for responses
    pub max_tokens: usize,

    /// Temperature for LLM (0.0 - 2.0)
    pub temperature: f32,

    /// Top-k results from knowledge base
    pub top_k_results: usize,

    /// Auto-index new files
    pub auto_index: bool,
}

impl Default for AgentConfig {
    fn default() -> Self {
        let data_dir = dirs::data_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("personal-agent");

        Self {
            knowledge_paths: vec![dirs::home_dir().unwrap_or_default().join("Documents")],
            vector_store: VectorStoreConfig {
                url: "http://localhost:6333".to_string(),
                collection: "personal-knowledge".to_string(),
                dimension: 768,
            },
            llm: LlmConfig::Ollama {
                url: "http://localhost:11434".to_string(),
                model: "llama2".to_string(),
            },
            agent: AgentBehavior {
                max_tokens: 2048,
                temperature: 0.7,
                top_k_results: 5,
                auto_index: true,
            },
            data_dir,
        }
    }
}

impl AgentConfig {
    pub fn load_from_file<P: AsRef<Path>>(path: P) -> anyhow::Result<Self> {
        let contents = std::fs::read_to_string(path)?;
        Ok(serde_json::from_str(&contents)?)
    }

    pub fn save_to_file<P: AsRef<Path>>(&self, path: P) -> anyhow::Result<()> {
        let contents = serde_json::to_string_pretty(self)?;
        std::fs::write(path, contents)?;
        Ok(())
    }
}
