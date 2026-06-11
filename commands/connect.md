---
description: Connect to PostPal and show which account, plan, and social platforms are linked
---

Connect this session to the user's PostPal account using the `postpal-content` skill's Step 0 (or the `auth_status` MCP tool if the PostPal MCP server is configured).

Then report the result as a single friendly, plain-English status line — for example:

> ✅ Connected as jane@acme.co (Creator plan). Linked accounts: X (@acmebuilds), LinkedIn (Acme Inc), Reddit (u/acmebuilds).

Rules:
- If no key is found or the key is rejected, walk the user through `npx -y @postpal/cli auth login`, tell them to approve in their browser, wait for it, then re-check and report the status line.
- If PostPal is connected but a platform they care about isn't linked, point them to PostPal → Settings → Social Accounts.
- Never print the API key, raw JSON, or curl commands. Just the status line and clear next steps.
- Finish by offering a short numbered menu of what they can do next (research Reddit, draft a post, schedule content).
