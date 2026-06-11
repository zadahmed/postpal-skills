---
name: postpal-content
description: Generate, draft, schedule, and publish social media content through PostPal from any project — Twitter/X, LinkedIn, Facebook, Reddit, and more. Use when the user wants to create social posts, schedule content, publish to connected social accounts, or automate their social media workflow via their PostPal account.
---

# PostPal Content

This skill lets any agent (Claude Code, Codex, etc.) act on the user's PostPal account: generate platform-specific content with their brand voice, save drafts, and schedule or publish posts to their connected social accounts.

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

A 200 returns `{ "data": { "email", "plan", "connected_platforms", "reddit_connected" } }`. Tell the user which account you're connected as, and only target platforms that appear in `connected_platforms`.

**3. If there is no key or `/me` returns 401 — run the browser login (device OAuth):**

```bash
npx -y @postpal/cli auth login
```

This prints a pairing code, opens the user's browser at PostPal's approve page (`/connect/device`), and waits while they sign in and click **Approve**. Credentials are then saved to `~/.postpal-agent.json` automatically. The command is interactive — run it in the foreground, tell the user to complete the approval in the browser, and wait for it to finish. Then re-run step 2.

If the PostPal MCP server is configured (e.g. via the `postpal` Claude Code plugin), call the `auth_status` tool first instead — it performs the same verification.

Never print the full API key back to the user; never commit it. Every response is `{ "data": ..., "meta": { "request_id": ... } }` or `{ "error": { "code", "message" } }`.

## Workflow

1. **Discover the workspace** — brands (voice/identity), pals (AI personalities), and connected accounts:
   ```bash
   curl -sS -H "Authorization: Bearer $KEY" "$BASE/api/v1/brands"
   curl -sS -H "Authorization: Bearer $KEY" "$BASE/api/v1/pals"
   curl -sS -H "Authorization: Bearer $KEY" "$BASE/api/v1/accounts"
   ```
   Filter accounts with `?platform=twitter|linkedin|facebook|reddit|...`. Note account `id`s — publishing needs them.

2. **Generate content** (uses the brand's voice; one post per platform):
   ```bash
   curl -sS -X POST "$BASE/api/v1/content/generate" \
     -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
     -H "Idempotency-Key: $(uuidgen)" \
     -d '{
       "topic": "Launch of our new analytics dashboard",
       "brand_id": "<brand-id>",
       "platforms": ["twitter", "linkedin"],
       "platform_settings": { "twitter": "short", "linkedin": "medium" },
       "persist_drafts": true
     }'
   ```
   The response includes a run; poll `GET /api/v1/runs/<id>` until `status` is `completed` if needed.

3. **Review drafts**: `GET /api/v1/drafts`, `GET /api/v1/drafts/<id>`. You can also create drafts directly with `POST /api/v1/drafts`.

4. **Schedule** for later (UTC ISO-8601):
   ```bash
   curl -sS -X POST "$BASE/api/v1/schedules" \
     -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
     -d '{ "draft_id": "<draft-id>", "schedules": [
       { "platform": "twitter", "account_id": "<account-id>", "publish_at": "2026-06-15T09:00:00Z" }
     ]}'
   ```

5. **Or publish immediately**:
   ```bash
   curl -sS -X POST "$BASE/api/v1/publishes" \
     -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
     -d '{ "draft_id": "<draft-id>", "targets": [
       { "platform": "twitter", "account_id": "<account-id>" }
     ]}'
   ```
   Reddit targets also need `"subreddit"`, `"title"`, and `"kind"` (`self`/`link`/`image`). Instagram/TikTok targets need `media_urls` on the draft.

6. **Webhooks** (optional, for automation): `GET/POST /api/v1/webhooks` — events include `run.completed`, `run.failed`, `post.published`, `post.failed`, `schedule.created`.

Full API schema: `GET /api/v1/openapi`.

## Rules

- **Never publish or schedule without the user explicitly confirming** the content, platforms, accounts, and timing. Generate and show drafts first.
- Use `Idempotency-Key` headers on mutating calls so retries are safe.
- Timestamps are UTC ISO-8601; confirm the user's timezone before converting "tomorrow 9am" style requests.
- Respect platform limits (Twitter 280 chars, LinkedIn 3000, etc.) — PostPal's generator handles this, so prefer `/content/generate` over hand-writing platform copy.
- Quote `request_id` from error responses when reporting failures.
- For Reddit research (finding subreddits, reading posts/comments before posting), use the companion `postpal-reddit` skill.
