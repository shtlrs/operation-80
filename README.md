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

## How things are connected

```
Browser
  └── index.html          Single-page frontend (vanilla JS, no framework)
        │
        ├── GET  /api/state   Load full state blob on page init
        └── POST /api/state   Save full state blob on every change

Cloudflare Pages
  └── functions/api/state.js  Pages Function (runs at the edge)
        │
        └── env.STATE         KV namespace binding
              └── key: "tracker"   One JSON blob holds all daily + weekly state
```

**State layout inside the `tracker` KV key:**

```json
{
  "op80-YYYY-MM-DD": { "m1": true, "ex0": true, "meals": { ... } },
  "op80-shop-YYYY-MM-DD": { "sp1": true, "sc2": false }
}
```

Daily entries are keyed by date; shopping entries are keyed by the Monday of the current week.

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

Wrangler will print the deployment URL. On subsequent deploys, step 3 is skipped.

### Local development

```bash
npx wrangler pages dev . --kv STATE
```

State writes go to a local `.wrangler/state` directory and do not touch the production KV namespace.
