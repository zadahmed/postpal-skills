---
description: Generate social content in your brand voice, then schedule or publish it after you confirm
argument-hint: [topic and optionally platforms, e.g. "analytics launch on X and LinkedIn"]
---

Use the `postpal-content` skill to create and ship a social post for the user. Topic/context: $ARGUMENTS

Steps:
1. Confirm the connection (one-line status) and list which social accounts are actually linked.
2. Pick identity: if the user has more than one brand/pal, show them by name and let them choose; otherwise use the obvious one and say which.
3. Decide platforms — use any the user named (only if connected), otherwise ask. Then generate content in the brand voice, narrating that you're drafting.
4. Show the finished copy per platform, formatted the way it will appear, referenced by content (not IDs). Invite tweaks.
5. When they're happy, ask whether to **schedule** (collect a time, confirm the local→UTC conversion in words) or **publish now**. Show exactly what goes where and when, and get an explicit yes before any write.
6. After scheduling/publishing, confirm in one line per platform — with the live link if published.

Never show raw JSON, curl, endpoint paths, or internal IDs. Never publish or schedule without an explicit yes on the exact targets and timing.
