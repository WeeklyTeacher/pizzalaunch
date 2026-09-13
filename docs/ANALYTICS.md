# Journey analytics

JourneyAnalytics accepts a fixed event vocabulary and exactly three bounded custom fields: initial mount cohort (unmounted/direct/blocked), activity, and outcome. Player IDs, names, destinations, scores, run IDs, timestamps and raw errors are not dimensions. Counters and a 24-event diagnostic window are server-owned. Individual streams and total per-player traffic are rate limited; repeat events cannot duplicate first-action milestones.

GameService owns authoritative hooks for join, mount, mode, accepted shot, successful delivery, first round, earned upgrade, occupied interaction, queue transitions, takeout start/completion/replay, Record Run start/completion/cancellation/replay, personal best and profile failures. Record completion uses the immutable completed submission. Initial blocked players remain a separate cohort even after mounting; later occupancy does not reclassify an immediately mounted player.

Only routeStarted and launcherReached can arrive from UI. The server requires the current character, cleanup epoch, walking state, living unanchored root and proximity to its own spawn/launcher coordinates. The client cannot supply event names or analytics fields. These validated UI events indicate a route cue interaction/proximity, not proven human attention.

The default SDK adapter uses server-only LogCustomEvent in a published non-Studio server. It defers calls, allows at most 64 outstanding sends, catches SDK failures and drops excess telemetry without blocking gameplay. Studio/unpublished environments keep local diagnostics and make no AnalyticsService calls. Events are not a durable audit ledger; overload/network loss can drop them.

Primary API references: [custom events](https://create.roblox.com/docs/production/analytics/custom-events) and [custom fields](https://create.roblox.com/docs/production/analytics/custom-fields). Custom events are available from published server scripts, not Studio. No dashboard configuration or production verification was performed during this run.

Analysis should compare players who mounted immediately against players blocked on first approach: eventual mount, queue abandonment, runner uptake/replay and session end. A queue does not increase station capacity. Measure human abandonment before approving an independent practice lane; source tests cannot answer that design question.
