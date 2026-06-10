import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


MODULE_PATH = Path(__file__).resolve().parents[1] / "crispy_agent.py"
SPEC = importlib.util.spec_from_file_location("crispy_agent", MODULE_PATH)
crispy_agent = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(crispy_agent)


class BudgetStateTests(unittest.TestCase):
    def test_caps_request_to_remaining_session_budget(self):
        budget = crispy_agent.BudgetState(session_limit=1000, response_limit=600)

        budget.record(550)

        self.assertEqual(budget.remaining, 450)
        self.assertEqual(budget.next_request_limit, 450)

    def test_never_allows_a_zero_token_request(self):
        budget = crispy_agent.BudgetState(session_limit=10, response_limit=5)
        budget.record(10)

        self.assertTrue(budget.exhausted)
        self.assertEqual(budget.next_request_limit, 0)


class SettingsTests(unittest.TestCase):
    def test_round_trips_settings(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "settings.json"
            settings = crispy_agent.Settings(
                model="mistral:latest",
                response_tokens=700,
                session_tokens=5000,
            )

            crispy_agent.save_settings(path, settings)

            self.assertEqual(crispy_agent.load_settings(path), settings)
            self.assertEqual(json.loads(path.read_text())["session_tokens"], 5000)


class OllamaPayloadTests(unittest.TestCase):
    def test_payload_uses_selected_model_and_token_limit(self):
        payload = crispy_agent.build_generate_payload(
            model="qwen2.5-coder:7b",
            prompt="Build the thing",
            token_limit=321,
        )

        self.assertEqual(payload["model"], "qwen2.5-coder:7b")
        self.assertEqual(payload["options"]["num_predict"], 321)
        self.assertFalse(payload["stream"])


class WorkspaceTests(unittest.TestCase):
    def test_discovers_only_existing_workspaces(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            existing = Path(temp_dir) / "existing"
            existing.mkdir()
            candidates = (
                crispy_agent.Workspace("Existing", existing, "ready"),
                crispy_agent.Workspace("Missing", Path(temp_dir) / "missing", "not ready"),
            )

            workspaces = crispy_agent.discover_workspaces(candidates)

            self.assertEqual([workspace.name for workspace in workspaces], ["Existing"])

    def test_prompt_identifies_selected_workspace(self):
        workspace = crispy_agent.Workspace("C4 Construct", Path("/tmp/c4"), "pipeline")

        prompt = crispy_agent.build_chat_prompt([], "What is next?", workspace)

        self.assertIn("C4 Construct", prompt)
        self.assertIn("/tmp/c4", prompt)
        self.assertIn("What is next?", prompt)


if __name__ == "__main__":
    unittest.main()
