# CloudKit Schema — Social Features

Record types live in the **public** database of `iCloud.co.brevinb.fridgecig`.

Schema is created automatically the first time a record saves in the
**Development** environment, but CloudKit does **not** index new fields
automatically. Every field a query filters or sorts on needs its index enabled in
the CloudKit Console, or the query fails at runtime (`invalidArguments` / "field
is not marked queryable"). Do that in Development, verify, then **Deploy Schema
Changes to Production**.

## `ActivityComment`

Replies on a feed post.

| Field | Type | Index |
| --- | --- | --- |
| `commentID` | String | Queryable |
| `activityID` | String | Queryable |
| `authorID` | String | Queryable |
| `authorName` | String | — |
| `authorPhotoID` | String | — |
| `authorEmoji` | String | — |
| `text` | String | — |
| `createdAt` | Date/Time | Queryable, Sortable |

Queries used:

- thread load — `activityID == %@`, sorted by `createdAt` ascending
- feed batch counts — `activityID IN %@`
- delete by ID — `commentID == %@`
- account deletion — `authorID == %@`

## `SocialNotification`

The social inbox, and the trigger for every social push. Written by the actor,
addressed to the recipient.

| Field | Type | Index |
| --- | --- | --- |
| `notificationID` | String | Queryable |
| `recipientID` | String | Queryable |
| `actorID` | String | Queryable |
| `actorName` | String | — |
| `actorPhotoID` | String | — |
| `actorEmoji` | String | — |
| `kind` | String | Queryable |
| `activityID` | String | — |
| `detail` | String | — |
| `bodyText` | String | — |
| `createdAt` | Date/Time | Queryable, Sortable |

Queries used:

- inbox — `recipientID == %@ AND createdAt > %@`, sorted by `createdAt` descending
- push subscription — `recipientID == %@` (`firesOnRecordCreation`)
- account deletion — `recipientID == %@`, then `actorID == %@`

`actorName` and `bodyText` are read by the push subscription's
`titleLocalizationArgs` / `alertLocalizationArgs`, which is how a notification
can say "Alex — commented: nice ratio" without a server. They must stay
populated on every record.

## `ActivityItem` — added fields

| Field | Type | Index |
| --- | --- | --- |
| `reactionTokens` | String (List) | — |
| `milestoneText` | String | — |

`reactionTokens` holds one `userID|emoji` entry per reaction. Keeping the whole
set in a single list field means a reaction is one record write instead of a new
record per person, and it merges cleanly on conflict (re-apply just the local
user's change on top of the server's set).

`cheersCount` and `cheersUserIDs` are still written as the aggregate view of
`reactionTokens` so clients on older builds keep showing a correct count.
Reading is symmetric: any `cheersUserIDs` entry without a matching token is
surfaced as a 👏, so reactions left before this change are preserved.

`milestoneText` is a pre-rendered push body ("earned the Centurion badge 🏆") for
the friend-milestone subscription, for the same reason as `bodyText` above.

## Retired subscriptions

These are deleted server-side on launch by `NotificationService`; they fired
generic alerts *and* triggered a second, app-generated local notification, so
users saw every social event twice.

- `friend-request-<userID>`
- `friend-accepted-<userID>`
- `cheers-received-<userID>`

Both survivors now render their alert entirely from record fields:

- `social-activity-<userID>` on `SocialNotification`
- `friend-milestones-<userID>` on `ActivityItem`
