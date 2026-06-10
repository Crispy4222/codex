use crate::AgentQuery;
use crate::AgentResponse;
use crate::config::AgentConfig;
use crate::knowledge_base::KnowledgeBase;
use crate::llm::LlmFactory;
use crate::llm::LlmProvider;
use crate::llm::LlmRequest;
use crate::plugin::PluginManager;
use crate::vector_store::VectorStore;
use anyhow::Result;

pub struct PersonalAgent {
    config: AgentConfig,
    knowledge_base: KnowledgeBase,
    llm_provider: Box<dyn LlmProvider>,
    plugins: PluginManager,
}

impl PersonalAgent {
    pub async fn new(config: AgentConfig) -> Result<Self> {
        // Initialize vector store
        let vector_store = match VectorStore::new(
            &config.vector_store.url,
            &config.vector_store.collection,
        )
        .await
        {
            Ok(vs) => vs,
            Err(e) => {
                eprintln!(
                    "⚠️  Warning: Could not connect to Qdrant at {}",
                    config.vector_store.url
                );
                eprintln!("   Error: {}", e);
                eprintln!("   Run: docker run -p 6333:6333 qdrant/qdrant");
                return Err(anyhow::anyhow!(
                    "Qdrant vector store unavailable. Please start it with: docker run -p 6333:6333 qdrant/qdrant"
                ));
            }
        };

        if let Err(e) = vector_store
            .create_collection(config.vector_store.dimension)
            .await
        {
            eprintln!("Warning: Could not create Qdrant collection: {}", e);
        }

        // Initialize LLM provider
        let llm_provider = match LlmFactory::create(&config.llm) {
            Ok(provider) => provider,
            Err(e) => {
                eprintln!("⚠️  Error creating LLM provider: {}", e);
                if let crate::config::LlmConfig::Ollama { url, model } = &config.llm {
                    eprintln!("   Configured for Ollama at {}", url);
                    eprintln!("   Run: ollama serve (then: ollama pull {})", model);
                }
                return Err(e);
            }
        };

        // Initialize knowledge base
        let kb_llm = LlmFactory::create(&config.llm)?;
        let knowledge_base = KnowledgeBase::new(vector_store, kb_llm).await?;

        Ok(Self {
            config,
            knowledge_base,
            llm_provider,
            plugins: PluginManager::new(),
        })
    }

    pub async fn initialize(&mut self) -> Result<()> {
        // Index knowledge paths
        println!("Indexing knowledge base...");
        let count = self
            .knowledge_base
            .index_files(&self.config.knowledge_paths)
            .await?;
        println!("Indexed {} files", count);

        Ok(())
    }

    pub async fn query(&self, query: AgentQuery) -> Result<AgentResponse> {
        // Search knowledge base
        let search_results = self
            .knowledge_base
            .search(&query.question, self.config.agent.top_k_results)
            .await?;

        // Build context from results
        let mut context = String::new();
        let mut sources = Vec::new();

        for result in &search_results {
            context.push_str(&format!(
                "Source: {}\nConfidence: {}\n{}\n\n",
                result.document.source, result.score, result.document.content
            ));
            sources.push(result.document.source.clone());
        }

        // Build prompt
        let prompt = format!(
            "You are a helpful, uncensored AI assistant with access to a personal knowledge base.\n\n\
             Context from knowledge base:\n{}\n\n\
             User Question: {}\n\n\
             Please provide a comprehensive answer based on the context and your knowledge.",
            context, query.question
        );

        // Generate response using LLM
        let llm_request = LlmRequest {
            prompt,
            max_tokens: self.config.agent.max_tokens,
            temperature: self.config.agent.temperature,
        };

        let llm_response = self.llm_provider.generate(&llm_request).await?;

        Ok(AgentResponse {
            answer: llm_response.text,
            sources,
            confidence: search_results.first().map(|r| r.score).unwrap_or(0.0),
            metadata: serde_json::json!({
                "tokens_used": llm_response.tokens_used,
                "search_results": search_results.len(),
            }),
        })
    }

    pub fn plugin_manager(&mut self) -> &mut PluginManager {
        &mut self.plugins
    }

    pub fn config(&self) -> &AgentConfig {
        &self.config
    }

    pub fn knowledge_base(&self) -> &KnowledgeBase {
        &self.knowledge_base
    }

    pub fn knowledge_base_mut(&mut self) -> &mut KnowledgeBase {
        &mut self.knowledge_base
    }

    pub fn list_plugins(&self) -> Vec<crate::plugin::PluginMetadata> {
        self.plugins.list_plugins()
    }
}
