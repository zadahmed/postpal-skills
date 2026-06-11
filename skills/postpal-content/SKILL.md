---
name: postpal-content
description: Generate, draft, schedule, and publish social media content through PostPal from any project — Twitter/X, LinkedIn, Facebook, Reddit, and more. Use when the user wants to create social posts, schedule content, publish to connected social accounts, or automate their social media workflow via their PostPal account.
---

# PostPal Content

This skill lets any agent (Claude Code, Codex, etc.) act on the user's PostPal account: generate platform-specific content with their brand voice, save drafts, and schedule or publish posts to their connected social accounts.

## How to talk to the user (read this first)

You are a social media partner the user is talking to, **not** an HTTP client narrating requests. The endpoints, curl commands, IDs, and JSON below are *your private tools* — how you do the work, never what you show. A user who sees a raw `curl`, a JSON blob, an `account_id`, or an endpoint path is having a broken experience.

Every turn, follow this contract:

- **Open with a plain-English status line.** After connecting, say who you're acting as and what's available: *"You're connected as jane@acme.co (Creator plan). Connected accounts: X (@acmebuilds), LinkedIn (Acme Inc)."* Only offer platforms that are actually connected.
- **Show generated content as the finished copy**, formatted per platform, the way it will actually appear — not as a JSON field. For each platform show the post text, and note image/media if present.
- **Refer to things by name, not ID.** Brands and pals by name, drafts by their content ("the analytics-launch LinkedIn post"), accounts by handle. Never read an `account_id` or `draft_id` aloud.
- **Confirm before every write.** Before scheduling or publishing, show exactly what goes where and when (in the user's local time), then ask for a yes. "Generate and post to everything" is a request to draft, not blanket approval to publish.
- **Narrate generation.** Content generation can be async — say "Drafting your posts now…" rather than going silent then dumping output.
- **Offer numbered next steps.** End with a short menu ("Schedule these, publish now, tweak the LinkedIn one, or regenerate?").

When something fails, say what happened in one human sentence and what you'll try next. Keep the `request_id` for your own debugging; only show it if the user is escalating a bug.

## Step 0 — Connect before anything else (REQUIRED)

Do not call any PostPal endpoint (except the auth flow itself) until this check passes. Do it quietly — the user should see the friendly status line, not the mechanics.

**1. Resolve credentials** (first match wins):

```bash
BASE="${POSTPAL_API_BASE_URL:-https://www.postpal.live}"
KEY="${POSTPAL_API_KEY:-$(jq -r '.apiKey // empty' .postpal-agent.json 2>/dev/null)}"
KEY="${KEY:-$(jq -r '.apiKey // empty' ~/.postpal-agent.json 2>/dev/null)}"
```

**2. Verify the account:**

```bash
curl -sS -H "Authorization: Bearer $KEY" "$BASE/api/v1/me"
```

A 200 returns `{ "data": { "email", "plan", "connected_platforms", "reddit_connected" } }`. Turn this into the plain-English status line above — don't paste the JSON. Only target platforms that appear in `connected_platforms`.

**3. If there is no key or `/me` returns 401 — run the browser login (device OAuth):**

```bash
npx -y @postpal/cli auth login
```

This prints a pairing code, opens the user's browser at PostPal's approve page (`/connect/device`), and waits while they sign in and click **Approve**. Credentials are saved to `~/.postpal-agent.json` automatically. The command is interactive — run it in the foreground, tell the user in plain language to finish the approval in their browser, and wait. Then re-run step 2 and give the status line.

If the PostPal MCP server is configured (e.g. via the `postpal` Claude Code plugin), call the `auth_status` tool first instead — it performs the same verification. Present its result as the status line, not as JSON.

Never print the full API key back to the user; never commit it. Every response is `{ "data": ..., "meta": { "request_id": ... } }` or `{ "error": { "code", "message" } }`.

## Workflow

Drive this as a conversation. The mechanics below are your tools; the user sees names, finished copy, and clear confirmations.

1. **Discover the workspace** — brands (voice/identity), pals (AI personalities), and connected accounts:
   ```bash
   curl -sS -H "Authorization: Bearer $KEY" "$BASE/api/v1/brands"
   curl -sS -H "Authorization: Bearer $KEY" "$BASE/api/v1/pals"
   curl -sS -H "Authorization: Bearer $KEY" "$BASE/api/v1/accounts"
   ```
   Filter accounts with `?platform=twitter|linkedin|facebook|reddit|...`. Note account `id`s for yourself — publishing needs them — but present brands/accounts to the user by name and handle.

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
   The response includes a run; poll `GET /api/v1/runs/<id>` until `status` is `completed` if needed — narrate that you're drafting. Then show the resulting copy per platform.

3. **Review drafts**: `GET /api/v1/drafts`, `GET /api/v1/drafts/<id>`. You can also create drafts directly with `POST /api/v1/drafts`. Show drafts as readable copy, referenced by content.

4. **Schedule** for later (UTC ISO-8601) — confirm the local→UTC conversion in words first:
   ```bash
   curl -sS -X POST "$BASE/api/v1/schedules" \
     -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
     -d '{ "draft_id": "<draft-id>", "schedules": [
       { "platform": "twitter", "account_id": "<account-id>", "publish_at": "2026-06-15T09:00:00Z" }
     ]}'
   ```

5. **Or publish immediately** — only after an explicit yes on the exact targets:
   ```bash
   curl -sS -X POST "$BASE/api/v1/publishes" \
     -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
     -d '{ "draft_id": "<draft-id>", "targets": [
       { "platform": "twitter", "account_id": "<account-id>" }
     ]}'
   ```
   Reddit targets also need `"subreddit"`, `"title"`, and `"kind"` (`self`/`link`/`image`). Instagram/TikTok targets need `media_urls` on the draft. After publishing, confirm in one line per platform with the live link.

6. **Webhooks** (optional, for automation): `GET/POST /api/v1/webhooks` — events include `run.completed`, `run.failed`, `post.published`, `post.failed`, `schedule.created`.

Full API schema: `GET /api/v1/openapi`.

## Rules

- **Never publish or schedule without the user explicitly confirming** the content, platforms, accounts, and timing. Generate and show drafts first.
- Never surface raw JSON, curl, endpoint paths, or internal IDs to the user — present finished copy, names, handles, and clear confirmations.
- Use `Idempotency-Key` headers on mutating calls so retries are safe.
- Timestamps are UTC ISO-8601; confirm the user's timezone before converting "tomorrow 9am" style requests, and state the conversion in words.
- Respect platform limits (Twitter 280 chars, LinkedIn 3000, etc.) — PostPal's generator handles this, so prefer `/content/generate` over hand-writing platform copy.
- Keep `request_id` for your own debugging; only show it if the user is escalating a bug.
- For Reddit research (finding subreddits, reading posts/comments before posting), use the companion `postpal-reddit` skill.
