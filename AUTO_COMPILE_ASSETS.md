# Automatic Asset Compilation Setup

## Option 1: Using Procfile.dev (Recommended for Development)

The project already has a `Procfile.dev` configured for automatic asset compilation:

```bash
# Run in the store service directory
cd services/store

# Install foreman if not installed
gem install foreman

# Start all processes with auto-recompilation
foreman start -f Procfile.dev
```

This will start:
- **Rails server** on port 5000
- **JavaScript watcher** (esbuild with --watch)
- **CSS watcher** (Tailwind with --watch)

## Option 2: Docker Compose with Watchers

Add watch services to your `docker-compose.yml`:

```yaml
services:
  store-js-watcher:
    build: ./services/store
    working_dir: /rails
    command: yarn build --watch
    volumes:
      - ./services/store:/rails
    profiles: ["dev-watchers"]

  store-css-watcher:
    build: ./services/store
    working_dir: /rails
    command: yarn build:css --watch
    volumes:
      - ./services/store:/rails
    profiles: ["dev-watchers"]
```

Then run:
```bash
# Start watchers
docker-compose --profile dev-watchers up -d

# Your regular store service
docker-compose up -d store
```

## Option 3: Manual Watch Commands

Run these in separate terminals inside the Docker container:

```bash
# Terminal 1: JS Watcher
docker-compose exec store yarn build --watch

# Terminal 2: CSS Watcher  
docker-compose exec store yarn build:css --watch

# Terminal 3: Rails server (already running)
docker-compose up -d store
```

## Current Manual Process

For now, after making changes to views with JavaScript/CSS:

```bash
# Rebuild assets
docker-compose exec store yarn build
docker-compose exec store yarn build:css

# Restart container
docker-compose restart store
```

## Recommended Setup

For active development, use **Option 1** with foreman to get automatic asset recompilation on file changes.