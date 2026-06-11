---
name: postpal-reddit
description: Use PostPal's Reddit integration from any project — authenticate with a PostPal API key, research subreddits/posts/comments via the user's connected Reddit account, generate content, and schedule or publish Reddit posts. Use when the user wants Reddit research, audience/community discovery, or to draft, schedule, or publish Reddit posts through PostPal.
---

# PostPal Reddit

This skill lets any agent (Claude Code, Codex, etc.) act on the user's PostPal account: research Reddit through their connected Reddit account, then draft, schedule, or publish posts.

## Step 0 — Connect before anything else (REQUIRED)

Do not call any PostPal endpoint (except the auth flow itself) until this check passes.

**1. Resolve credentials** (first match wins):

```bash
BASE="${POSTPAL_API_BASE_URL:-https://postpal.live}"
KEY="${POSTPAL_API_KEY:-$(jq -r '.apiKey // empty' .postpal-agent.json 2>/dev/null)}"
KEY="${KEY:-$(jq -r '.apiKey // empty' ~/.postpal-agent.json 2>/dev/null)}"
```

**2. Verify the account:**

```bash
curl -sS -H "Authorization: Bearer $KEY" "$BASE/api/v1/me"
```

A 200 returns `{ "data": { "email", "plan", "connected_platforms", "reddit_connected" } }`. Tell the user which account you're connected as before doing anything else.

**3. If there is no key or `/me` returns 401 — run the browser login (device OAuth):**

```bash
npx -y @postpal/cli auth login
```

This prints a pairing code, opens the user's browser at PostPal's approve page (`/connect/device`), and waits while they sign in and click **Approve**. Credentials are then saved to `~/.postpal-agent.json` automatically. The command is interactive — run it in the foreground, tell the user to complete the approval in the browser, and wait for it to finish. Then re-run step 2.

**4. Require a Reddit connection** — this skill must not call any `/api/v1/reddit/*` endpoint unless `reddit_connected` is `true` in `/me`. If it's `false`, tell the user: *"Connect Reddit in PostPal → Settings → Social Accounts, then ask me again"* — and stop.

When publishing you'll also need the Reddit `account_id`:

```bash
curl -sS -H "Authorization: Bearer $KEY" "$BASE/api/v1/accounts?platform=reddit"
```

Never print the full API key back to the user; never commit it. Every response is `{ "data": ..., "meta": { "request_id": ... } }` or `{ "error": { "code", "message" } }`. A `reddit_not_connected` (409) error at any point means step 4 was skipped — go back to it.

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

If the PostPal MCP server is configured (e.g. via the `postpal` Claude Code plugin, or `postpal mcp serve` / `npx -y @postpal/cli mcp serve`), the same capabilities exist as tools — call `auth_status` first (it performs Step 0's verification, including `reddit_connected`), then use `reddit_search_subreddits`, `reddit_subreddit_info`, `reddit_browse_posts`, `reddit_search_posts`, `reddit_post_comments`, plus the content/draft/schedule/publish tools. Prefer MCP tools when configured; otherwise use curl as above.

## Rules

- Research freely, but **never publish or schedule without the user explicitly confirming** the subreddit, title, body, and timing.
- Validate the subreddit exists (`GET /api/v1/reddit/subreddits/<name>`) before scheduling/publishing to it.
- Respect community norms: when researching, check the subreddit's description and pinned conventions before recommending a post; flag if the target subreddit looks hostile to promotional content.
- Quote `request_id` from error responses when reporting failures to the user.
- Timestamps for scheduling are ISO-8601 UTC; confirm the user's timezone before converting "tomorrow 9am" style requests.
