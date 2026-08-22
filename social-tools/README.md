# social-tools

Batch-produce on-brand Instagram/TikTok post images from the idea bank in
[`docs/social-media-content-strategy.md`](../docs/social-media-content-strategy.md).
Outreach lives in [`docs/social-outreach-playbook.md`](../docs/social-outreach-playbook.md).

## Produce a week of posts

```sh
python3 generate.py batches/week1.json
```

Outputs `output/week1/*.png` plus `output/week1/captions.md` with the matching
captions + hashtags to copy-paste at post time. AirDrop the folder to your
phone and schedule the posts (Meta Business Suite for IG, TikTok web uploader).

## Add a new batch

Copy `batches/week1.json`, swap the content, rerun. Each post is:

```json
{
  "slug": "output filename",
  "template": "meme-card | stat-card | list-card",
  "size": "feed (1080x1350) | square (1080x1080) | story (1080x1920)",
  "fields": { "TITLE": "...", "...": "..." },
  "caption": "post caption",
  "hashtags": "#FridgeCig ..."
}
```

Templates are plain HTML in `templates/` (brand red `#E3172B`, deep red
`#B80F1F`, charcoal `#1C1C1E`) — tweak the CSS once and every future batch
inherits it. Rendering uses your installed Chrome in headless mode.
