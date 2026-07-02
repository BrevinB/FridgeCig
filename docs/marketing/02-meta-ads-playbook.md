# FridgeCig Meta Ads Playbook (<$100/month edition)

## Read this first: what $100/month can and can't do

At this budget, Meta ads are **not** an acquisition engine — they're an amplifier. The play is:

1. Let organic content run for a few weeks.
2. Take the **one Reel that clearly outperformed** (views, shares, saves).
3. Put $3–5/day behind it for 2 weeks to a tightly targeted DC audience.
4. Judge by App Store results, keep or kill.

Never run ads on untested creative at this budget — you'd spend the whole month learning what a free organic post would have told you.

**Measurement reality:** the app has no Meta SDK/pixel, so Meta cannot see installs and will report clicks only. That's fine. Your source of truth is App Store Connect: create a **custom product page** used *only* in ads (call it `meta-ads`) and use its link as the ad destination. Downloads attributed to that page ≈ downloads from ads. Don't add the Meta SDK for a $100 budget — not worth the privacy-label and maintenance cost.

## Setup (one-time, ~30 min)

1. Instagram → professional account (free), connect to a Meta Business Suite / Ads Manager account.
2. App Store Connect → create custom product page `meta-ads` (screenshots: streak home screen first, badges second, share card third).
3. In Ads Manager, create the campaign below. Skip "Advantage+ App Campaigns" (needs the SDK); use a **Traffic** or **Engagement (video views)** objective pointed at the custom product page URL.
4. Turn OFF Advantage+ audience expansion and placements you don't want (Audience Network, in particular).

## Campaign structure (one at a time, ever)

```
Campaign: FridgeCig — Organic Winner Boost
└── Ad set: DC Superfans US
    ├── Budget: $5/day, 14 days ($70)
    ├── Placements: Instagram Reels + Facebook Reels only
    ├── Location: United States
    ├── Age: 18–45
    ├── Interests (narrow, stacked with OR):
    │     Diet Coke · Coca-Cola · Diet soda ·
    │     Duolingo (streak-psychology proxy) · Apple Watch
    └── Ad: your top organic Reel, unchanged, + CTA button "Download"
          → custom product page URL (meta-ads)
```

Rules:
- **One ad set, one ad, one test at a time.** Multiple ad sets at $5/day just starves them all.
- Use the actual organic post ("use existing post") so the ad keeps its likes/comments — social proof rides along free.
- Don't touch it for the first 7 days (learning phase); judge at day 14.

## Written ad variants

Use these as the primary text if you run a dark post instead of boosting an existing Reel, or as caption swaps for tests. Headline field: keep to ≤5 words.

**Variant 1 — The Identity Hook**
- **Hook (first 2s of video):** "If you've ever called it a fridge cigarette, this is your app."
- **Primary text:** Streaks, badges, and a leaderboard — for Diet Coke. Log every can in 3 seconds, keep your streak alive, and prove you're the most committed sipper you know. We don't judge. We just track. 🥤
- **Headline:** The Diet Coke tracker
- **CTA:** Download

**Variant 2 — The Absurd Flex**
- **Hook:** "I have a 47-day Diet Coke streak and 37 badges."
- **Primary text:** There's an app that tracks your Diet Coke habit. With badges. And an Apple Watch app. And a leaderboard your friends can't hide from. You're welcome.
- **Headline:** Badges for drinking DC
- **CTA:** Download

**Variant 3 — The Collector**
- **Hook:** "I'm collecting a Diet Coke from all 50 states."
- **Primary text:** FridgeCig turns your Diet Coke habit into a game — daily streaks, rare badges, State Cans from every state, and shareable stat cards. Pokémon for people who love aspartame.
- **Headline:** Catch every State Can
- **CTA:** Download

**Creative brief (if re-editing the winner for ads):** hook in the first 2 seconds, app screen visible by second 3, captions burned in (most watch muted), under 20 seconds, end on the streak counter or share card — not a logo.

## Decision rules

After the 14-day, ~$70 test:

| Result | Read | Action |
|--------|------|--------|
| CPC > $1.50 and near-zero product-page downloads | Creative or audience miss | Kill. Back to organic; test a different winner next month |
| CPC < $0.75, downloads on `meta-ads` page clearly up | It works | Keep at $5/day; raise to $7–8/day only if week 3 holds |
| Lots of cheap video views, no downloads | Entertaining, not converting | Kill the boost; the post still earned free reach — repost the format organically |

**Cost sanity check:** if a download is costing >$3 via ads while your organic posts drive them free, ads lose. At <$100/month, ads must beat "post it again" to deserve the money.

## The Apple Search Ads alternative (often the better $100)

Apple Search Ads **Basic** frequently beats Meta at tiny budgets because intent is higher and installs are directly attributed (no SDK needed — Apple owns the whole funnel).

- Set a $50–100/month cap, target cost-per-install ~$2.
- Let it run on relevant search terms: *diet coke*, *soda tracker*, *caffeine tracker*, *drink tracker*, *habit tracker*.
- ASA Basic reports true installs per dollar — cleaner data than Meta clicks.

**Recommended split for month 3 of the [90-day plan](00-master-strategy.md#6-90-day-calendar):** run ASA Basic at $50/mo continuously (it's set-and-forget), and save Meta boosts for months where an organic Reel genuinely pops. If forced to choose one: choose ASA.
