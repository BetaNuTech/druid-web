# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BlueSky is a Rails 6.1 application for lead management and property leasing operations. It's a proprietary system owned by Bluecore Residential (formerly BlueStone Properties) that integrates with external lead sources, property management systems (Yardi Voyager), and communication platforms (Twilio, Mailgun, Cloudmailin).

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
- `npm test` - Run JavaScript (Jest) tests for app/javascript code

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
- **Lea AI** - AI-powered leasing assistant integration (see `doc/lea_ai_integration.md`)

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

### JavaScript Dependencies
- npm (package-lock.json) is the package manager; do NOT commit a yarn.lock —
  the heroku/nodejs buildpack rejects builds when multiple lockfiles exist
- Heroku's webpacker step (ruby buildpack) runs its own unpinned yarn install;
  this re-resolves dependencies fresh on each deploy and emits many warnings

## Deployment

- **Heroku** hosting with staging and production environments
- **Git remotes:** `heroku-staging`, `heroku-prod`
- **Deploy script:** `bin/deploy staging|prod` (tags the current HEAD, deploys, runs migrations)
- **Scheduled tasks** run via Heroku Scheduler for Yardi sync, lead processing, etc.

### Deploy flow

Work always lands on `master` first. The `staging` and `production` branches
track what is deployed to each environment and only ever fast-forward from
`master` — never commit directly on them.

1. Commit on `master` and `git push origin master`.
2. Fast-forward the deploy branch from `master`, push it, and deploy from it:
   - **Staging:** `git checkout staging && git merge --ff-only master && git push origin staging && bin/deploy staging`
   - **Production:** `git checkout production && git merge --ff-only master && git push origin production && bin/deploy prod`

   If `--ff-only` refuses, the branch has diverged from `master` — stop and
   sort that out rather than creating a merge commit.
3. Verify with `heroku releases -a druid-staging` / `heroku releases -a druid-prod`
   that the new release is the expected commit. `bin/deploy` has no error
   handling: a rejected push still runs migrations and moves the
   `staging-current` / `prod-current` tag to the undeployed commit.
4. **Always `git checkout master` when done.**

## Configuration

Development configuration uses `.env` file (copy from `env.example`). Key environment variables include Yardi credentials, Twilio settings, AWS keys, and database URLs.

## Google Sign-In

"Sign in with Google" is the primary sign-in; email/password stays permanently,
collapsed under a disclosure. Full design, decisions and rollout:
`doc/google_sign_in.md`. The points that are easy to break:

- **Switch:** `GOOGLE_SIGN_IN_ENABLED` + `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET`,
  read by `GoogleSignIn.enabled?` (`config/initializers/001_google_sign_in.rb`).
  Fails closed; checked at strategy registration, button render, and a callback
  `before_action`. Kill switch: `heroku config:set GOOGLE_SIGN_IN_ENABLED=false -a druid-prod`.
- **Never auto-provision.** The only membership gate is that the verified Google
  email matches an existing user. No `User.create` in the callback path. No `hd`
  check, on purpose (every account is admin-created).
- **`email_verified == true` strictly**, from `extra.raw_info` -- the gem's
  `verified_email` is truthy. Keep `skip_jwt` false (it checks `aud`).
- **`uid` is pinned on first use**, never re-bound; admin "Unlink Google" recovers.
- **Order in the callback is load-bearing:** system user refused first, then uid,
  deactivated, active property, then confirm (and clear the confirmation token),
  unlock, link, sync names against the `google_*_name` shadow columns.
- **`/privacy` must stay public** (Google's consent screen requires it) and
  must match what the code collects; update it in the same commit.

## Production Console Commands

- When running rails console on production, use heroku and rails runner and pass in commands
  - Production app: druid-prod
  - Staging app: druid-staging

## Claude Code Guidelines

- Git commit messages should not include Claude Code.

## Development Documentation

- All documentation should be placed in the /doc folder