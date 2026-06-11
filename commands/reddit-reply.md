---
description: Draft and (after you approve) post a helpful reply to a specific Reddit thread
argument-hint: [reddit post link or what you want to respond to]
---

Use the `postpal-reddit` skill to draft a reply for the user. Target/context: $ARGUMENTS

Steps:
1. Confirm the connection and that Reddit is linked (one-line status).
2. Identify the target thread. If the user gave a link or post, fetch it and its comments so the reply fits what's already been said. If they were vague, ask which thread (or run a quick search and offer numbered options).
3. Write a from-scratch reply that answers the author's actual question, leads with the useful part, sounds human, and avoids links, CTAs, product mentions, and invented experience.
4. Show a clean preview — the subreddit, the post title as a link, and the verbatim reply text — and ask for an explicit yes (yes / edit / skip).
5. Only after an explicit yes, post it via the skill (`confirmed: true`). Then confirm in one line with the live comment link.

Never show raw JSON, curl, or Reddit IDs. Never treat "build karma" or "engage automatically" as approval — you need a yes on this exact reply to this exact thread.
