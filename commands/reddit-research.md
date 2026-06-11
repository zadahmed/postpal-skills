---
description: Find relevant Reddit conversations worth joining, as a ranked list of opportunities
argument-hint: [topic or product to research]
---

Use the `postpal-reddit` skill to research Reddit for the user. Topic/context: $ARGUMENTS

Run the skill's full research flow: confirm the connection (and that Reddit is linked) with a one-line status, then search subreddits, browse/search posts in the best matches, and pull comments on the most promising threads before recommending anything.

Present the result the way the skill's presentation contract requires:
- A short ranked list of comment opportunities, each as a readable card: the post title as a link, the subreddit, how old it is in human terms, a one-line read of the thread, why this account is qualified to help, and what's missing from the existing replies.
- For the top candidates, include a from-scratch draft reply written for that thread.
- End with a numbered menu (reply to #1, see more from a subreddit, refine the search).

Never show raw JSON, curl, endpoint paths, or Reddit IDs. If nothing is genuinely worth a reply, say so plainly rather than padding the list. Do not post anything — this command only researches and drafts.
