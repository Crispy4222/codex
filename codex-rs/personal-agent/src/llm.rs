use crate::config::LlmConfig;
use anyhow::Result;
use anyhow::anyhow;
use serde::Deserialize;
use serde::Serialize;
use async_trait::async_trait;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LlmRequest {
    pub prompt: String,
    pub max_tokens: usize,
    pub temperature: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LlmResponse {
    pub text: String,
    pub tokens_used: usize,
}

#[async_trait]
pub trait LlmProvider: Send + Sync {
    async fn generate(&self, request: &LlmRequest) -> Result<LlmResponse>;
    async fn embed_text(&self, text: &str) -> Result<Vec<f32>>;
}

pub struct OllamaProvider {
    url: String,
    model: String,
}

impl OllamaProvider {
    pub fn new(url: String, model: String) -> Self {
        Self { url, model }
    }
}

#[derive(Debug, Serialize)]
struct OllamaGenerateRequest {
    model: String,
    prompt: String,
    stream: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    options: Option<OllamaOptions>,
}

#[derive(Debug, Serialize)]
struct OllamaOptions {
    temperature: f32,
    num_predict: usize,
}

#[derive(Debug, Deserialize)]
struct OllamaGenerateResponse {
    response: String,
}

#[derive(Debug, Serialize)]
struct OllamaEmbedRequest {
    model: String,
    input: String,
}

#[derive(Debug, Deserialize)]
struct OllamaEmbedResponse {
    embedding: Vec<f32>,
}

#[async_trait]
impl LlmProvider for OllamaProvider {
    async fn generate(&self, request: &LlmRequest) -> Result<LlmResponse> {
        let client = reqwest::Client::new();

        let req = OllamaGenerateRequest {
            model: self.model.clone(),
            prompt: request.prompt.clone(),
            stream: false,
            options: Some(OllamaOptions {
                temperature: request.temperature,
                num_predict: request.max_tokens,
            }),
        };

        let response = client
            .post(format!("{}/api/generate", self.url))
            .json(&req)
            .send()
            .await?;

        let body: OllamaGenerateResponse = response.json().await?;

        Ok(LlmResponse {
            text: body.response,
            tokens_used: 0, // Ollama doesn't return token count
        })
    }

    async fn embed_text(&self, text: &str) -> Result<Vec<f32>> {
        let client = reqwest::Client::new();

        let req = OllamaEmbedRequest {
            model: self.model.clone(),
            input: text.to_string(),
        };

        let response = client
            .post(format!("{}/api/embeddings", self.url))
            .json(&req)
            .send()
            .await?;

        let body: OllamaEmbedResponse = response.json().await?;
        Ok(body.embedding)
    }
}

pub struct RemoteProvider {
    endpoint: String,
    api_key: String,
    model: String,
}

impl RemoteProvider {
    pub fn new(endpoint: String, api_key: String, model: String) -> Self {
        Self {
            endpoint,
            api_key,
            model,
        }
    }
}

#[async_trait]
impl LlmProvider for RemoteProvider {
    async fn generate(&self, _request: &LlmRequest) -> Result<LlmResponse> {
        // Implementation for custom remote LLM
        todo!("Implement custom remote LLM provider")
    }

    async fn embed_text(&self, _text: &str) -> Result<Vec<f32>> {
        // Implementation for embeddings
        todo!("Implement remote embeddings")
    }
}

pub struct LlmFactory;

impl LlmFactory {
    pub fn create(config: &LlmConfig) -> Result<Box<dyn LlmProvider>> {
        match config {
            LlmConfig::Ollama { url, model } => {
                Ok(Box::new(OllamaProvider::new(url.clone(), model.clone())))
            }
            LlmConfig::Remote {
                endpoint,
                api_key,
                model,
            } => Ok(Box::new(RemoteProvider::new(
                endpoint.clone(),
                api_key.clone(),
                model.clone(),
            ))),
            LlmConfig::Custom { plugin_path: _ } => Err(anyhow!("Custom plugins not yet implemented")),
        }
    }
}
