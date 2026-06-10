use anyhow::Result;
use clap::Parser;
use clap::Subcommand;
use codex_personal_agent::AgentConfig;
use codex_personal_agent::AgentQuery;
use codex_personal_agent::PersonalAgent;
use std::path::PathBuf;
use tracing_subscriber;

#[derive(Parser)]
#[command(name = "personal-agent")]
#[command(about = "Your unlimited, uncensored, independently-owned AI coding agent")]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    #[arg(global = true, short, long)]
    config: Option<PathBuf>,
}

#[derive(Subcommand)]
enum Commands {
    /// Initialize the agent with configuration
    Init {
        #[arg(help = "Configuration file path")]
        config_path: Option<PathBuf>,
    },

    /// Setup: Start required services (Qdrant, Ollama)
    Setup,

    /// Check system requirements and diagnose issues
    Doctor,

    /// Index knowledge files
    Index {
        #[arg(help = "Paths to index")]
        paths: Vec<PathBuf>,
    },

    /// Query the agent
    Query {
        #[arg(help = "Your question")]
        question: String,

        #[arg(short, long, default_value = "5")]
        top_k: usize,
    },

    /// Interactive mode
    Repl,

    /// Manage plugins
    Plugin {
        #[command(subcommand)]
        action: PluginAction,
    },
}

#[derive(Subcommand)]
enum PluginAction {
    /// List available plugins
    List,

    /// Load a plugin
    Load {
        #[arg(help = "Plugin path")]
        path: PathBuf,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();

    let cli = Cli::parse();

    // Load config
    let config = if let Some(config_path) = cli.config {
        match AgentConfig::load_from_file(config_path) {
            Ok(cfg) => cfg,
            Err(e) => {
                eprintln!("Error loading config: {}", e);
                eprintln!("Using default configuration");
                AgentConfig::default()
            }
        }
    } else {
        AgentConfig::default()
    };

    match cli.command {
        Commands::Init { config_path } => {
            let path = config_path.unwrap_or_else(|| PathBuf::from("agent-config.json"));
            config.save_to_file(&path)?;
            println!("✓ Configuration saved to {}", path.display());
        }

        Commands::Setup => {
            println!("🔧 Setting up Personal Agent...\n");
            println!("To get started, run:");
            println!("  1. docker run -d -p 6333:6333 qdrant/qdrant  # Start Qdrant");
            println!(
                "  2. ollama serve                              # Start Ollama (separate terminal)"
            );
            println!("  3. ollama pull mistral                       # Download model");
            println!("  4. personal-agent index ~/GARAGE/logs        # Index your files");
            println!("  5. personal-agent repl                       # Start interactive mode\n");
            println!("Configuration: {:?}", config.data_dir);
            println!("Knowledge paths: {:?}", config.knowledge_paths);
            println!("Vector store: {}", config.vector_store.url);
            println!("LLM model: {:?}", config.llm);
        }

        Commands::Doctor => {
            println!("🏥 Diagnosing system...\n");

            // Check Qdrant
            print!("Checking Qdrant at {}... ", config.vector_store.url);
            match reqwest::Client::new()
                .get(&format!("{}/health", config.vector_store.url))
                .send()
                .await
            {
                Ok(_) => println!("✓ Running"),
                Err(_) => println!("✗ Not responding"),
            }

            // Check LLM
            if let codex_personal_agent::config::LlmConfig::Ollama { url, model } = &config.llm {
                print!("Checking Ollama at {}... ", url);
                match reqwest::Client::new()
                    .get(&format!("{}/api/tags", url))
                    .send()
                    .await
                {
                    Ok(resp) => {
                        if resp.status().is_success() {
                            println!("✓ Running");
                            println!("  Model: {}", model);
                        } else {
                            println!("✗ Not responding");
                        }
                    }
                    Err(_) => println!("✗ Not responding"),
                }
            }

            // Check knowledge paths
            println!("\nKnowledge paths:");
            for path in &config.knowledge_paths {
                if path.exists() {
                    println!("  ✓ {}", path.display());
                } else {
                    println!("  ✗ {} (not found)", path.display());
                }
            }

            println!("\n📝 Configuration directory: {:?}", config.data_dir);
        }

        Commands::Index { paths } => {
            let mut agent = PersonalAgent::new(config).await?;
            agent.initialize().await?;

            for path in paths {
                println!("Indexing: {}", path.display());
                let count = agent.knowledge_base_mut().index_files(&[path]).await?;
                println!("  Indexed {} files", count);
            }
        }

        Commands::Query { question, top_k: _ } => {
            let agent = PersonalAgent::new(config).await?;

            let query = AgentQuery {
                question,
                context_limit: 4096,
                include_files: true,
            };

            let response = agent.query(query).await?;

            println!("\n📌 Answer:\n");
            println!("{}", response.answer);
            println!("\n📚 Sources:");
            for source in &response.sources {
                println!("  - {}", source);
            }
            println!("\nConfidence: {:.2}%", response.confidence * 100.0);
        }

        Commands::Repl => {
            let mut agent = PersonalAgent::new(config).await?;
            agent.initialize().await?;

            println!("🤖 Personal Agent REPL");
            println!("Type your questions or /help for commands\n");

            let stdin = std::io::stdin();
            let mut line = String::new();

            loop {
                print!("> ");
                use std::io::Write;
                std::io::stdout().flush()?;

                line.clear();
                stdin.read_line(&mut line)?;

                let trimmed = line.trim();

                if trimmed.is_empty() {
                    continue;
                }

                match trimmed {
                    "/exit" | "/quit" => break,
                    "/help" => {
                        println!("Commands:");
                        println!("  /exit, /quit - Exit the REPL");
                        println!("  /help - Show this help");
                        println!("  Anything else - Query the agent");
                    }
                    _ => {
                        match agent
                            .query(AgentQuery {
                                question: trimmed.to_string(),
                                context_limit: 4096,
                                include_files: true,
                            })
                            .await
                        {
                            Ok(response) => {
                                println!("\n{}\n", response.answer);
                            }
                            Err(e) => {
                                eprintln!("Error: {}", e);
                            }
                        }
                    }
                }
            }

            println!("\nGoodbye!");
        }

        Commands::Plugin { action } => {
            match action {
                PluginAction::List => {
                    let agent = PersonalAgent::new(config).await?;
                    let plugins = agent.list_plugins();

                    if plugins.is_empty() {
                        println!("No plugins loaded");
                    } else {
                        println!("Loaded plugins:");
                        for plugin in plugins {
                            println!("  - {} (v{})", plugin.name, plugin.version);
                            println!("    {}", plugin.description);
                        }
                    }
                }

                PluginAction::Load { path } => {
                    println!("Loading plugin from: {}", path.display());
                    // Plugin loading implementation
                    println!("Plugin loading not yet implemented");
                }
            }
        }
    }

    Ok(())
}
