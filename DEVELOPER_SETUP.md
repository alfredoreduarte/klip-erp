# Developer Setup Guide

Welcome to the Klip ERP project! This guide will help you set up your development environment and understand the project structure.

## Prerequisites

Before you begin, ensure you have the following installed:

- [asdf](https://asdf-vm.com/) - Version manager for multiple runtimes
- [Docker](https://www.docker.com/) - Container platform
- [Docker Compose](https://docs.docker.com/compose/) - Multi-container Docker applications
- [Git](https://git-scm.com/) - Version control system

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd klip-erp
   ```

2. **Install dependencies:**
   ```bash
   make setup
   ```

3. **Start the development environment:**
   ```bash
   make up
   ```

4. **Access the application:**
   - Main application: http://localhost:3000
   - WAHA (WhatsApp): http://localhost:4000
   - Traefik dashboard: http://localhost:8080

## Project Structure

```
klip-erp/
├── services/
│   ├── store/          # Rails application
│   └── waha/           # Custom WAHA WhatsApp service
├── scripts/
│   └── backup/         # Database backup scripts
├── docker-compose.yml  # Development environment
├── docker-compose.prod.yml  # Production environment
├── deploy.sh           # Blue-green deployment script
├── Makefile           # Development commands
└── .tool-versions     # asdf version specifications
```

## Development Environment Setup

### 1. Install Required Tools

The project uses [asdf](https://asdf-vm.com/) for managing tool versions. Install the required plugins:

```bash
# Install asdf plugins
asdf plugin-add ruby
asdf plugin-add nodejs
asdf plugin-add postgres
asdf plugin-add yarn

# Install tool versions specified in .tool-versions
asdf install
```

### 2. Rails Application Setup

Navigate to the Rails application:

```bash
cd services/store
```

Install Ruby dependencies:

```bash
bundle install
```

Install JavaScript dependencies:

```bash
yarn install
```

### 3. Database Setup

The database runs in Docker, but you can set it up manually if needed:

```bash
cd services/store
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed
```

### 4. Environment Variables

Create a `.env` file in the project root:

```env
# Database
POSTGRES_PASSWORD=password
POSTGRES_USER=postgres
POSTGRES_DB=store_development

# WAHA (WhatsApp)
WAHA_BASE_URL=http://localhost:4000
WAHA_WEBHOOK_URL=http://store:3000/waha/webhooks

# Rails
SECRET_KEY_BASE=your_secret_key_here
RAILS_ENV=development
```

## Available Commands

### Makefile Commands

- `make setup` - Install dependencies and set up the project
- `make up` - Start all services with Docker Compose
- `make down` - Stop all services
- `make build` - Build Docker images
- `make test` - Run the test suite
- `make deploy` - Deploy using blue-green deployment

### Rails Commands

```bash
cd services/store

# Run the Rails server
bundle exec rails server

# Run tests
bundle exec rails test

# Generate migration
bundle exec rails generate migration AddFieldToModel

# Run migration
bundle exec rails db:migrate

# Access Rails console
bundle exec rails console
```

### WAHA (WhatsApp) Commands

```bash
# Start WAHA session and get QR code
cd services/store
bundle exec rake waha:pair

# Start specific session
bundle exec rake waha:pair[session_name]
```

## Testing

### Running Tests

```bash
# Run all tests
make test

# Run specific test file
cd services/store
bundle exec rails test test/models/chat_test.rb

# Run tests with coverage
cd services/store
bundle exec rails test
```

### Test Structure

- `test/models/` - Model tests
- `test/controllers/` - Controller tests
- `test/integration/` - Integration tests
- `test/lib/` - Library tests

## Database Management

### Migrations

```bash
cd services/store

# Create a new migration
bundle exec rails generate migration CreateProducts name:string price:decimal

# Run migrations
bundle exec rails db:migrate

# Rollback migration
bundle exec rails db:rollback

# Check migration status
bundle exec rails db:migrate:status
```

### Backup and Restore

```bash
# Create backup
./scripts/backup/backup.sh

# Restore from backup
./scripts/backup/restore.sh ./backup/store_production_20240101_120000.sql.gz

# Set up automated backups (add to crontab)
0 2 * * * /path/to/klip-erp/scripts/backup/cron-backup.sh
```

## Deployment

### Development Deployment

```bash
# Start development environment
make up

# Stop development environment
make down
```

### Production Deployment

```bash
# Deploy to production (blue-green)
make deploy

# Deploy specific version
./deploy.sh v1.0.0

# Deploy with custom compose file
COMPOSE_FILE=docker-compose.prod.yml ./deploy.sh
```

## Debugging

### Application Logs

```bash
# View Rails logs
docker compose logs -f store

# View WAHA logs
docker compose logs -f waha

# View all logs
docker compose logs -f
```

### Database Access

```bash
# Access Rails console
docker compose exec store bundle exec rails console

# Access PostgreSQL directly
docker compose exec postgres psql -U postgres -d store_development
```

### WAHA Debugging

```bash
# Check WAHA session status
curl http://localhost:4000/api/sessions

# Get QR code for session
curl http://localhost:4000/api/screenshot?session=default
```

## Troubleshooting

### Common Issues

1. **Port conflicts:**
   - Check if ports 3000, 4000, 5432, or 80 are in use
   - Stop conflicting services or change ports in docker-compose.yml

2. **Database connection issues:**
   - Ensure PostgreSQL container is running
   - Check database credentials in environment variables

3. **WAHA connection issues:**
   - Verify WAHA container is running
   - Check webhook URLs are correctly configured

4. **Asset compilation issues:**
   - Run `yarn install` in the Rails directory
   - Check if Node.js and Yarn are properly installed

### Getting Help

- Check the project documentation in the `docs/` directory
- Review the test files for usage examples
- Check the Rails logs for error messages
- Consult the WAHA documentation: https://github.com/devlikeapro/waha

## Development Workflow

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - Write tests first (TDD approach)
   - Implement the feature
   - Ensure all tests pass

3. **Run tests and linting:**
   ```bash
   make test
   cd services/store && bundle exec rubocop
   ```

4. **Commit and push:**
   ```bash
   git add .
   git commit -m "Add feature: description"
   git push origin feature/your-feature-name
   ```

5. **Create pull request:**
   - Open a pull request against the main branch
   - Ensure CI/CD pipeline passes
   - Request code review

## Architecture Overview

### Services

- **Store (Rails):** Main application handling orders, inventory, and customer management
- **WAHA:** WhatsApp HTTP API for messaging integration
- **PostgreSQL:** Primary database
- **Redis:** Caching and session storage
- **Traefik:** Reverse proxy and load balancer

### Key Features

- WhatsApp integration for customer communication
- Inventory management with FIFO costing
- Order processing and tracking
- Blue-green deployment for zero downtime
- Automated database backups

### API Endpoints

- `/api/health` - Health check
- `/waha/webhooks` - WhatsApp webhook receiver
- `/waha/sessions` - Session management
- `/chats` - Chat management
- `/messages` - Message handling

## Contributing

1. Follow the existing code style and conventions
2. Write tests for new features
3. Update documentation when necessary
4. Use semantic commit messages
5. Ensure CI/CD pipeline passes

## Security

- Keep dependencies updated
- Use environment variables for sensitive data
- Follow Rails security best practices
- Regularly review and update access controls

## Resources

- [Rails Guides](https://guides.rubyonrails.org/)
- [WAHA Documentation](https://github.com/devlikeapro/waha)
- [Docker Documentation](https://docs.docker.com/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)