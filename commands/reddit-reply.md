---
description: Draft and, after approval, post either a top-level Reddit comment or a nested reply
argument-hint: [Reddit post/comment link or what you want to respond to]
---

Use the `postpal-reddit` skill to draft a reply for the user. Target/context: $ARGUMENTS

Steps:
1. Confirm the connection and that Reddit is linked (one-line status). Resolve the exact connected Reddit account that will publish. If more than one is connected and the user has not chosen one, ask which account.
2. Identify the exact target. If the user gave a link or post, fetch it and its comments so the reply fits what's already been said. If they were vague, ask which post or comment (or run a quick search and offer numbered options).
3. Write a from-scratch reply that answers the author's actual question, leads with the useful part, sounds human, and avoids links, CTAs, product mentions, and invented experience.
4. Show a clean preview — the Reddit account handle, subreddit, post title as a link, and verbatim reply text — and ask for an explicit yes (yes / edit / skip).
5. Only after an explicit yes, choose the operation by target:
   - Reply to the original post with `reddit_post_comment` using the post ID. This creates a top-level comment.
   - Reply to an existing comment with `reddit_comment_reply` using that parent comment's ID. This creates a nested reply.
   Both require the selected connected Reddit `account_id`, the exact approved `text`, and `confirmed: true`. Never omit `account_id` or allow a fallback to another account; do not use `body`. Then confirm in one line with the live comment link.

Never show raw JSON, curl, or Reddit IDs. Never treat "build karma" or "engage automatically" as approval — you need a yes on this exact reply to this exact thread.
