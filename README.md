# rails-8-template

For your AppDev Projects!

## Deploying

The app is pre-configured for Render's free tier with an external Neon Postgres
database; the walkthrough is the [Deploying a Rails App to Render](https://learn.firstdraft.com/lessons/215-rails-on-render)
lesson, and the reasons behind each setting are in
[Configuring Rails for Render's Free Tier](https://learn.firstdraft.com/lessons/875-configuring-rails-for-render-free-tier).

Environment variables in production:

| Key | Who sets it | What it does |
|---|---|---|
| `DATABASE_URL` | you, once, when Render creates the Blueprint | Your Neon **direct** connection string (no `-pooler` in the hostname) |
| `SECRET_KEY_BASE` | Render generates it | Signs cookies and sessions; no `config/master.key` is needed |
| `ROLLBAR_ACCESS_TOKEN` | you, optional | Turns on error reporting to [Rollbar](https://rollbar.com); without it Rollbar stays silent |
| `WEB_CONCURRENCY`, `RAILS_MAX_THREADS`, `DB_POOL`, `SOLID_QUEUE_IN_PUMA` | `render.yaml` | The single-process, 512 MB memory profile (see `config/puma.rb`) |
| `SOLID_QUEUE_POLL_INTERVAL`, `SOLID_QUEUE_DISPATCH_INTERVAL`, `SOLID_CABLE_POLL_INTERVAL` | optional | Seconds between database polls in production (default 5, 5, 1); lower them only if you can afford the bandwidth |
| `SOLID_CACHE_MAX_SIZE_MB` | optional | Cache budget inside the shared database (default 64) |
| `RACK_ATTACK_LIMIT` | optional | Requests allowed per IP per five minutes (default 300) |

Add `healthCheckPath: /up` under the web service in `render.yaml` so Render waits for
Rails to boot before sending visitors; the `/up` route is already in `config/routes.rb`.

All files are covered by the MIT license, see [LICENSE.txt](LICENSE.txt).
