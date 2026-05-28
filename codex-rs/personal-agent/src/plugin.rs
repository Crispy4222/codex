//! Plugin system for extending the personal agent
//!
//! Plugins can be loaded dynamically to add new capabilities

use anyhow::Result;
use serde::Deserialize;
use serde::Serialize;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginMetadata {
    pub name: String,
    pub version: String,
    pub author: String,
    pub description: String,
}

/// Plugin trait for implementing custom agent capabilities
pub trait AgentPlugin: Send + Sync {
    /// Plugin metadata
    fn metadata(&self) -> &PluginMetadata;

    /// Initialize the plugin
    fn initialize(&mut self) -> Result<()>;

    /// Process a query with custom logic
    fn process_query(&self, query: &str) -> Result<String>;

    /// Shutdown the plugin
    fn shutdown(&mut self) -> Result<()>;
}

pub struct PluginManager {
    plugins: Vec<Box<dyn AgentPlugin>>,
}

impl PluginManager {
    pub fn new() -> Self {
        Self {
            plugins: Vec::new(),
        }
    }

    pub fn register_plugin(&mut self, plugin: Box<dyn AgentPlugin>) -> Result<()> {
        self.plugins.push(plugin);
        Ok(())
    }

    pub fn get_plugin(&self, name: &str) -> Option<&dyn AgentPlugin> {
        self.plugins
            .iter()
            .find(|p| p.metadata().name == name)
            .map(|p| p.as_ref())
    }

    pub fn list_plugins(&self) -> Vec<PluginMetadata> {
        self.plugins.iter().map(|p| p.metadata().clone()).collect()
    }
}

impl Default for PluginManager {
    fn default() -> Self {
        Self::new()
    }
}
