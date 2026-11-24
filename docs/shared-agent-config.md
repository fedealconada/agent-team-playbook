# Sharing configuration across coding agent CLIs

Goal: run multiple coding agent CLIs (for example Claude Code, Codex and Antigravity) on the same machine and repositories without duplicating rules, skills or server definitions.

## One canonical rules file

Maintaining separate instruction files per tool causes silent drift. Pick one canonical file at each scope and point every other CLI at it.

### Repository scope

Keep `AGENTS.md` as the source of truth inside each repository. Codex and Antigravity discover `AGENTS.md` automatically as they walk up from the working directory to the repository root. For Claude Code, add a one line `CLAUDE.md` in the same folder that imports it:

```markdown
@AGENTS.md
```

### Global scope

Keep one personal rules file on the workstation and link the other agent locations to it. For example, if `~/.claude/CLAUDE.md` is the canonical file:

```bash
ln -s ../.claude/CLAUDE.md ~/.codex/AGENTS.md
ln -s ../../.claude/CLAUDE.md ~/.gemini/config/AGENTS.md
```

Editing the single file updates every CLI on its next session.

## Sharing skills without copying

Standard skills use a directory containing `SKILL.md` with YAML frontmatter (`name` and `description`). Do not copy skill folders into multiple config roots.

- **Per repository:** If a repository stores shared playbooks outside the default discovery folder, register them with `.agents/skills.json` at the repository root using a relative path entry.
- **Global:** Use `~/.gemini/config/skills.json` to point at existing skill folders with `entries`, `include_only` and `exclude`.
- **Prefer generic skill bundles:** When a tool ships both a client specific skill tree (with tool specific frontmatter) and a generic `.agents/skills` tree, register the generic tree for other CLIs and filter the remaining skills explicitly so nothing loads twice.

Example `~/.gemini/config/skills.json`:

```json
{
  "entries": [
    {
      "path": "~/.claude/skills/shared-pack/.agents/skills"
    },
    {
      "path": "~/.claude/skills",
      "include_only": [
        "cloud-.*"
      ]
    }
  ]
}
```

## Syncing MCP servers

Each CLI keeps its own MCP configuration file (`~/.claude.json`, `~/.codex/config.toml` and `~/.gemini/config/mcp_config.json`).

1. **Skip servers already provided by an installed plugin.** Check enabled plugins before adding a global entry so the same MCP server is not started twice.
2. **Match each client's schema.** For Antigravity, use `command`, `args` and optional `env` for stdio servers, and `url` with optional `headers` for Streamable HTTP servers. Drop client specific fields such as `"type": "http"`.
3. **Protect credential files.** Set `chmod 600` on any MCP config file that holds tokens or headers. When scripting a sync, never print secret values to stdout or logs.

## Keep headless worker guards off interactive sessions

Autonomous workers that run without interactive permission prompts need strict `PreToolUse` guards. Those guards block actions such as modifying guard scripts, running orchestrator admin commands or writing outside an assigned worktree.

Do not attach those worker guards to the human operator's interactive CLI configuration. When a person runs an agent directly, blocking guard edits or orchestrator maintenance breaks normal repo upkeep. Keep full seatbelts wired to headless worker invocations, and use lighter boundaries (such as blocking reads of `.env` files) for interactive sessions if needed.

## Verify and reload

Global rules, skill manifests and MCP configs load when a new session starts. After changing them:

1. Verify that every symlink resolves to an existing file.
2. Validate every JSON manifest and confirm that expected skill folders contain `SKILL.md`.
3. Confirm `0600` permissions on any config file that stores credentials.
4. Start a fresh CLI session so the updated configuration takes effect.
