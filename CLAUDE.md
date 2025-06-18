# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BlueSky is a Rails 6.1 application for lead management and property leasing operations. It's a proprietary system owned by BlueStone Properties that integrates with external lead sources, property management systems (Yardi Voyager), and communication platforms (Twilio, Mailgun, Cloudmailin).

## Common Development Commands

### Development Setup
- `bin/setup` - Bootstrap the application (copies config files, installs dependencies)
- `bin/server` - Development server (runs bundler, security audit, starts foreman with Procfile.dev)

### Running the Application
- `bin/server` - Preferred development server (includes security checks and foreman)
- `bundle exec foreman start -f Procfile.dev` - Direct foreman start
- `bundle exec rails server` - Basic Rails server only

### Testing
- `bundle exec guard` - Recommended for development (auto-runs tests, updates tags)
- `bundle exec rspec` - Run full test suite with coverage report
- `NO_TEST_COVERAGE=true rspec <spec_file>` - Run specific test without coverage

### Code Quality
- `bundle exec rubocop` - Linter/Formatter 
- `bundle exec annotate` - Update model annotations with schema information
- `bundle exec bundle audit check --update` - Security vulnerability check
- Use RuboCop to keep code clean

### Database & Data
- `bundle exec rails db:migrate`
- `bundle exec rails db:seed`
- `bundle exec rails console` - Rails console with Pry

## Application Architecture

### Core Domain Models
- **Lead** - Central entity with state machine, messaging, duplicates, exports, referrals
  - Located at `app/models/lead.rb:43` 
  - Extensive concerns in `app/models/concerns/leads/`
  - State machine for lead lifecycle management
- **Property** - Properties with team assignments, users, phone numbers, working hours
  - Located at `app/models/property.rb:38`
  - Concerns in `app/models/concerns/properties/`
- **User** - Devise-based authentication with roles (Administrator, Corporate, Manager, Agent)
- **Message** - Communication system supporting SMS/email via Twilio/Mailgun
- **ScheduledAction** - Task management system with lead engagement policies

### Service Layer Architecture
Located in `lib/` directory with clear separation by domain:

**Lead Management:**
- `Leads::Creator` - Lead processing and creation
- `Leads::AgentAssigner` - Lead assignment logic  
- `Leads::Adapters` - External lead source integrations (Zillow, CloudMailin, Yardi, etc.)

**Communication:**
- `Messages::Sender/Receiver` - Message processing
- `Messages::DeliveryAdapters` - Twilio, CloudMailin, ActionMailer integrations

**External Integrations:**
- `Yardi::Voyager` - Property management system integration
- Various CloudMailin parsers for different lead sources

### Frontend Technology
- Rails 6.1 with Webpacker 5.4
- React 18.2 components for Lead search functionality
- Bootstrap 3.4.1 for styling
- D3.js for charts
- jQuery and jQuery UI

### Key Integrations
- **Yardi Voyager** - Property management system (guest cards, units, residents)
- **Twilio** - SMS messaging
- **Cloudmailin** - Incoming email processing for leads and messages
- **Mailgun** - Outbound email delivery
- **AWS S3** - File storage via ActiveStorage

## Testing Strategy

- **RSpec** with **FactoryBot** for model/controller tests
- **Guard** for continuous testing during development  
- **SimpleCov** for coverage reporting (generated in `coverage/index.html`)
- **Capybara** for integration tests

## Key Business Logic Patterns

### Lead Processing Pipeline
1. External lead data comes via API (`api/v1/leads`) or email (Cloudmailin webhooks)
2. `Leads::Creator` parses, validates, and assigns to properties
3. `Leads::AgentAssigner` assigns to appropriate agents
4. State machine manages lead lifecycle
5. Engagement policies create scheduled actions/tasks

### Message Flow
1. Outbound: `Messages::Sender` → delivery adapters → external services
2. Inbound: Webhooks → `Messages::Receiver` → parsing → lead association

### State Management
- Leads use AASM state machine with states: new, contacted, scheduled, qualified, etc.
- Transitions tracked in `lead_transitions` table
- Integration with engagement policies for automated actions

## Development Conventions

### Code Organization
- Service objects in `lib/` directory organized by domain
- Model concerns in `app/models/concerns/`
- Controllers are RESTful with minimal business logic
- Use Pundit for authorization policies

### Testing
- Create FactoryBot factories for all models
- Test business logic in service objects, not controllers
- Use shared examples and contexts in `spec/support/`

### Database
- UUID primary keys
- PostgreSQL with JSONB for flexible data storage
- Audited gem for model change tracking
- Foreign key constraints via Immigrant gem

## Deployment

- **Heroku** hosting with staging and production environments
- **Git remotes:** `heroku-staging`, `heroku-prod`
- **Deploy script:** `bin/deploy staging|prod` (tags, deploys, runs migrations)
- **Scheduled tasks** run via Heroku Scheduler for Yardi sync, lead processing, etc.

## Configuration

Development configuration uses `.env` file (copy from `env.example`). Key environment variables include Yardi credentials, Twilio settings, AWS keys, and database URLs.

## Production Console Commands

- When running rails console on production, use heroku and rails runner and pass in commands
  - Production app: druid-prod
  - Staging app: druid-staging

## Claude Code Guidelines

- Git commit messages should not include Claude Code.