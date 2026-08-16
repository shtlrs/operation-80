# Operation 80

Personal 8-week fitness tracker. Single-page web app hosted on Cloudflare Pages, with state persisted to Cloudflare KV so progress syncs across devices.

## What it does

- Tracks daily checklists (morning routine, nutrition, activity)
- Shows today's workout from a weekly rotation (Mon–Sun schedule)
- Suggests meals for breakfast, lunch, snack, and dinner — shuffleable, with tuna-limit guard
- Displays estimated macro totals (protein, fiber, calories) vs. daily targets
- Weekly shopping list that resets every Monday
- Daily state resets at midnight; weekly review card appears on Sundays
- All state auto-syncs to KV on a 600 ms debounce after any interaction

## Architecture

### Cloudflare Pages

Pages is Cloudflare's static site hosting — files are served from the edge (200+ locations worldwide), no server to manage. `pages_build_output_dir = "."` in `wrangler.toml` tells Wrangler to serve the repo root, so `index.html` becomes the site.

### Pages Functions

Any file under `functions/` is automatically a serverless API endpoint based on its path:

```
functions/api/state.js  →  /api/state
```

No routing config needed. The file exports named handlers per HTTP method (`onRequestGet`, `onRequestPost`, `onRequestOptions`). Cloudflare routes the request to the right export and injects an `env` object containing all bound resources (KV, secrets, etc.).

### KV (Key-Value store)

KV is Cloudflare's distributed key→value store. This app uses a single key (`tracker`) whose value is a JSON blob holding all state for all days:

```json
{
  "op80-2026-08-16":        { "m1": true, "ex0": true, "meals": { "breakfast": 2 } },
  "op80-shop-2026-08-11":   { "sp1": true, "sc3": false }
}
```

Daily entries are keyed by date; shopping entries by the Monday of the current week. One blob, one key, one read on load, one write per debounce burst — regardless of how many boxes the user checks in that window.

### How the binding works

`wrangler.toml` declares the binding, giving the KV namespace a name the function uses at runtime:

```toml
[[kv_namespaces]]
binding = "STATE"      # accessed as env.STATE inside the function
id = "862cd0c9..."     # which KV namespace on Cloudflare's infra
```

Cloudflare injects the namespace into `env` at deploy time. The function never touches the ID directly — it just calls `env.STATE.get(...)` and `env.STATE.put(...)`.

### Request lifecycle

**Page load**
1. Browser fetches `index.html` from the Pages edge
2. JS fires `GET /api/state` → Pages Function reads the `tracker` key from KV → returns the full blob
3. JS hydrates all checkboxes, meal selections, and shopping list from the blob

**User interaction (e.g. checking a box)**
1. JS updates the in-memory `CACHE` object and starts a 600 ms debounce timer (resets on each new action)
2. After 600 ms of inactivity, JS fires `POST /api/state` with the entire `CACHE` as the body
3. Pages Function writes it to the `tracker` KV key
4. Sync dot flashes yellow (saving) → green (saved)

Multiple actions within 600 ms collapse into a single KV write.

### File layout

```
/
├── index.html              Static frontend — served directly by Pages
├── wrangler.toml           Project config: name, build dir, KV binding
└── functions/
    └── api/
        └── state.js        Edge function — auto-mounted at /api/state
```

## Deploy

### Prerequisites

- [Node.js](https://nodejs.org) 18+
- A Cloudflare account
- Wrangler v4+

```bash
npm install -D wrangler@latest
```

### Steps

**1. Authenticate**

```bash
npx wrangler login
```

**2. Create the KV namespace**

```bash
npx wrangler kv namespace create STATE
```

Copy the `id` from the output and update `wrangler.toml`:

```toml
[[kv_namespaces]]
binding = "STATE"
id = "<paste-your-id-here>"
```

**3. Create the Pages project (first deploy only)**

```bash
npx wrangler pages project create operation-80
```

**4. Deploy**

```bash
npx wrangler pages deploy .
```

Wrangler prints the deployment URL. On subsequent deploys, skip step 3.

### Local development

```bash
npx wrangler pages dev . --kv STATE
```

State writes go to a local `.wrangler/state` directory and do not touch the production KV namespace.
