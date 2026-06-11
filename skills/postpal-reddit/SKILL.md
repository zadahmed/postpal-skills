---
name: postpal-reddit
description: Use PostPal's Reddit integration from any project — authenticate with a PostPal API key, research subreddits/posts/comments via the user's connected Reddit account, generate content, and schedule or publish Reddit posts. Use when the user wants Reddit research, audience/community discovery, or to draft, schedule, or publish Reddit posts through PostPal.
---

# PostPal Reddit

This skill lets any agent (Claude Code, Codex, etc.) act on the user's PostPal account: research Reddit through their connected Reddit account, then draft, schedule, or publish posts.

## Authentication

All requests go to the PostPal v1 API with a Bearer API key:

- Base URL: `$POSTPAL_API_BASE_URL` if set, otherwise `https://postpal.live`
- API key: `$POSTPAL_API_KEY`, or the `apiKey` field of `.postpal-agent.json` in the project root

```bash
BASE="${POSTPAL_API_BASE_URL:-https://postpal.live}"
KEY="${POSTPAL_API_KEY:-$(jq -r '.apiKey // empty' .postpal-agent.json 2>/dev/null)}"
curl -sS -H "Authorization: Bearer $KEY" "$BASE/api/v1/health"
```

If no key is found, ask the user for one. They can create a key in the PostPal dashboard (Settings → API Keys) — keys look like `ppk_live_...`. Never print the full key back to the user; never commit it.

Every response is `{ "data": ..., "meta": { "request_id": ... } }` or `{ "error": { "code", "message" } }`. If you get `reddit_not_connected` (409), tell the user to connect Reddit in the PostPal dashboard (Settings → Social Accounts) and stop.

## Verify the connection first

Before any Reddit work, confirm a Reddit account is connected:

```bash
curl -sS -H "Authorization: Bearer $KEY" "$BASE/api/v1/accounts?platform=reddit"
```

Note the `id` of the Reddit account — it is required for publishing (`account_id`).

## Research endpoints (read-only, safe to use freely)

| Endpoint | Purpose |
|---|---|
| `GET /api/v1/reddit/subreddits/search?q=<query>&limit=10` | Find subreddits by topic |
| `GET /api/v1/reddit/subreddits/<name>` | Subreddit info (subscribers, description) |
| `GET /api/v1/reddit/subreddits/<name>/posts?sort=hot&t=day&limit=25` | Browse posts (`sort`: hot/new/top/rising/controversial; `t`: hour/day/week/month/year/all) |
| `GET /api/v1/reddit/posts/search?q=<query>&subreddit=<name>&sort=relevance&t=month&limit=25` | Keyword search, global or per-subreddit |
| `GET /api/v1/reddit/posts/<post_id>/comments?limit=50` | A post plus flattened comment tree |

Typical research flow: search subreddits → browse/search posts in the best matches → pull comments on the most relevant posts → summarize themes, pain points, language, and posting norms for the user.

## Content: generate, draft, schedule, publish

1. **List brands/pals** to pick identity: `GET /api/v1/brands`, `GET /api/v1/pals`
2. **Generate content**: `POST /api/v1/content/generate` with e.g.
   ```json
   { "brand_id": "...", "platforms": ["reddit"], "topic": "...", "persist_drafts": true }
   ```
   This returns a run; poll `GET /api/v1/runs/<id>` until completed if async.
3. **Or create a draft directly**: `POST /api/v1/drafts`
4. **Schedule**: `POST /api/v1/schedules` with
   ```json
   { "draft_id": "...", "schedules": [{ "platform": "reddit", "account_id": "...", "publish_at": "2026-06-12T09:00:00Z" }] }
   ```
5. **Publish now**: `POST /api/v1/publishes` with
   ```json
   { "draft_id": "...", "targets": [{ "platform": "reddit", "account_id": "...", "subreddit": "r/example", "title": "Post title", "kind": "self" }] }
   ```
   `kind` is `self` (text), `link` (requires `url`), or `image` (requires `image_url`).

Full API schema: `GET /api/v1/openapi`.

## MCP alternative

If the project has the PostPal CLI available (PostPal repo, or `postpal` on PATH), the same capabilities exist as MCP tools via `postpal mcp serve` — including `reddit_search_subreddits`, `reddit_subreddit_info`, `reddit_browse_posts`, `reddit_search_posts`, `reddit_post_comments`, plus the content/draft/schedule/publish tools. Prefer MCP tools when configured; otherwise use curl as above.

## Rules

- Research freely, but **never publish or schedule without the user explicitly confirming** the subreddit, title, body, and timing.
- Validate the subreddit exists (`GET /api/v1/reddit/subreddits/<name>`) before scheduling/publishing to it.
- Respect community norms: when researching, check the subreddit's description and pinned conventions before recommending a post; flag if the target subreddit looks hostile to promotional content.
- Quote `request_id` from error responses when reporting failures to the user.
- Timestamps for scheduling are ISO-8601 UTC; confirm the user's timezone before converting "tomorrow 9am" style requests.
