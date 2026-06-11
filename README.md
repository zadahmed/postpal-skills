# PostPal Skills & Plugin

A Claude Code plugin and portable agent skills that connect [PostPal](https://postpal.live) — the AI social media content platform — to your coding agents. Install once and any project's agent (Claude Code, Codex, Cursor) can use your PostPal account to:

- 🔎 **Research Reddit** — find subreddits, browse and search posts, read comment threads through your connected Reddit account
- ✍️ **Generate content** — platform-specific posts in your brand voice (Twitter/X, LinkedIn, Facebook, Reddit, and more)
- 📅 **Schedule & publish** — save drafts, schedule for later, or publish immediately to your connected social accounts

## Skills

| Skill | What it does |
|---|---|
| [`postpal-reddit`](skills/postpal-reddit/SKILL.md) | Reddit research (subreddits, posts, comments) + Reddit post scheduling/publishing via your connected Reddit account |
| [`postpal-content`](skills/postpal-content/SKILL.md) | Full content workflow: generate → draft → schedule/publish across all connected platforms |

## Prerequisites

1. A [PostPal](https://postpal.live) account — API access is included on **every plan, including free**
2. An API key: PostPal dashboard → **Settings → API Keys** (keys look like `ppk_live_...`)
3. For Reddit features: connect Reddit in **Settings → Social Accounts**

## Install

| Tool | Recommended install |
|---|---|
| **Claude Code** | Plugin (below) — includes both skills **plus** the PostPal MCP server |
| **Codex** | `install.sh` — copies skills to `~/.codex/skills` |
| **Cursor** | `install.sh --project <dir>` — converts skills to `.cursor/rules/*.mdc` |

### Claude Code (plugin — recommended)

```
/plugin marketplace add zadahmed/postpal-skills
/plugin install postpal@postpal-skills
```

The plugin bundles the `postpal-reddit` and `postpal-content` skills and registers the PostPal MCP server (`npx @postpal/cli mcp serve`), giving the agent first-class tools — `reddit_search_subreddits`, `reddit_browse_posts`, `reddit_post_comments`, `content_generate`, `schedules_create`, `publishes_create`, and more. Set `POSTPAL_API_KEY` in your environment before starting Claude Code.

### Codex / Cursor (skills)

```bash
# One-liner (user-level: ~/.claude/skills + ~/.codex/skills)
curl -fsSL https://raw.githubusercontent.com/zadahmed/postpal-skills/main/install.sh | bash

# From a clone
git clone https://github.com/zadahmed/postpal-skills.git
cd postpal-skills
./install.sh                          # user-level: ~/.claude/skills + ~/.codex/skills
./install.sh --project ~/code/my-app  # also project-level, including Cursor rules
./install.sh --skill postpal-reddit   # just one skill
```

### Manual

- **Claude Code**: prefer the plugin; or copy `skills/<name>/` into `~/.claude/skills/<name>/`
- **Codex**: copy `skills/<name>/` into `~/.codex/skills/<name>/` or `<project>/.codex/skills/<name>/`
- **Cursor**: add the SKILL.md body as a rule in `<project>/.cursor/rules/<name>.mdc` (the installer does this conversion for you)

## Connect your account

**Easiest: browser login (device OAuth).** Run this once — it opens PostPal in your browser, you click Approve, and credentials are saved to `~/.postpal-agent.json`:

```bash
npx -y @postpal/cli auth login
```

You can also just ask your agent to "connect to my PostPal account" — the skills know how to start this flow and will wait while you approve in the browser. Check the connection any time with `npx -y @postpal/cli auth status`.

**Alternative: manual API key.** Create a key in the PostPal dashboard (Settings → API Keys) and either export it where the agent runs:

```bash
export POSTPAL_API_KEY=ppk_live_...
# optional, defaults to https://www.postpal.live
export POSTPAL_API_BASE_URL=https://www.postpal.live
```

or put it in `.postpal-agent.json` in the project root (add it to `.gitignore`):

```json
{ "apiKey": "ppk_live_...", "apiBaseUrl": "https://www.postpal.live" }
```

Either way, the skills always verify the connection (`GET /api/v1/me`) before doing any work, and the Reddit skill additionally requires your Reddit account to be connected in PostPal (Settings → Social Accounts) before it will touch any Reddit endpoint.

## Commands (Claude Code)

The plugin adds guided slash commands so you don't have to remember anything — each one runs a conversational flow that shows readable results and asks before it posts:

| Command | What it does |
|---|---|
| `/postpal:connect` | Connect and show which account, plan, and platforms are linked |
| `/postpal:reddit-research [topic]` | Find relevant Reddit threads worth joining, as a ranked list with draft replies |
| `/postpal:reddit-reply [link or context]` | Draft a reply to a specific thread, preview it, and post after you approve |
| `/postpal:post [topic]` | Generate content in your brand voice, then schedule or publish after you confirm |

## Try it

Or just talk to your agent:

> research r/SaaS and r/indiehackers for pain points around social scheduling tools, then draft a Reddit post introducing our product and schedule it for Friday 9am

The skills handle discovery (`/api/v1/accounts`, `/api/v1/brands`), research (`/api/v1/reddit/*`), and the publish flow (`/api/v1/content/generate` → `/api/v1/schedules` or `/api/v1/publishes`) — and they will always show you the draft and ask before anything is posted.

## How it works

The skills are plain Markdown instructions — no binaries, no dependencies beyond `curl`/`jq`. They teach your agent PostPal's [v1 API](https://www.postpal.live/api/v1/openapi): Bearer-key auth, the research endpoints, and the content lifecycle. Your Reddit OAuth tokens stay in PostPal; agents only ever hold the PostPal API key, which you can revoke any time from the dashboard.

The Claude Code plugin additionally registers PostPal's MCP server ([`@postpal/cli`](https://www.npmjs.com/package/@postpal/cli)) so the same capabilities are exposed as structured tools rather than curl recipes — the skills then guide the workflow while the MCP tools do the calls.

## Safety

- Skills instruct agents to **never publish or schedule without your explicit confirmation**
- API keys are never echoed or committed; revoke keys in the dashboard at any time
- Research endpoints are read-only

## License

MIT
