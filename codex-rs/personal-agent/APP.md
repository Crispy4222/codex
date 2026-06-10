# Crispy Agent

Crispy Agent is a local desktop chat app backed by Ollama. It does not require
an API key, Qdrant, or a cloud token balance.

It discovers existing local workspaces instead of creating duplicate projects:
C4 Construct, Roughdraft City, the game garage, C4 Racing & Repair, the bike
repair lane, and the C4 model mesh. Selecting a workspace gives the model its
name, purpose, and path; **Open folder** opens the existing project directly.

## Launch

Install the application-menu entry once:

```bash
./install-app.sh
```

Then open **Crispy Agent** from the application menu, or run:

```bash
./launch-app
```

## Token Controls

- **Max response tokens** caps the next model response.
- **Session output budget** caps generated tokens across the current chat session.
- **New session** clears chat context and resets the session counter.

Ollama's `eval_count` supplies the generated-token count shown in the footer.
Local tokens are compute limits, not billable API credits.

Settings are stored at `~/.config/crispy-agent/settings.json`.

## Requirements

- Python 3 with Tkinter
- Ollama listening on `127.0.0.1:11434`
- At least one locally installed Ollama model

Run the focused tests with:

```bash
python3 -m unittest discover -s tests -p 'test_*.py'
```
