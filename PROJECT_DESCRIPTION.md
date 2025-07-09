# Retail Store Suite – Project Overview

Use this document to track high-level progress across all modules. Checkboxes represent completion status for each area; feel free to break items down further inside each section as the project evolves.

---

## 1. ERP Core

- [ ] Product & Variant Catalog
- [ ] FIFO Inventory Engine
- [ ] Supplier & Purchase Order Management
- [ ] Warehouse Locations & Stock Transfers
- [ ] Pricing Rules & Promotions
- [ ] Tax Configuration & Compliance
- [ ] Packaging Materials Inventory & Optional Special Packaging (included in COGS)

## 2. Sourcing & Procurement

- [ ] Automated Re-order Rules (min/max, sales velocity)
- [ ] Purchase Order Lifecycle (draft → approved → received → invoiced)
- [ ] Vendor Performance KPIs (delivery time, defect rate)
- [ ] Landed-Cost Allocation (shipping, duties, fees)
- [ ] Additional Cost Components (marketplace fees, multi-leg shipping, customs, last-mile)

## 3. Sales & Cart Workflow

- [ ] WhatsApp-Driven Cart Creation for Sales Reps
- [ ] Multi-Channel Order Intake (Phone, Web, POS)
- [ ] Quote → Order Conversion
- [ ] Discount & Coupon Handling
- [ ] Order Status Tracking (new → packed → shipped → delivered)
- [ ] Retail Store Cash Register Management (operation categories, open/close sessions, cash-at-hand tracking)
- [ ] Order Tracking Short-Link Generation & Customer Portal
- [ ] Legacy Manual Order Form Enhancements (address paste, Google-Maps link, gift wrap, delivery windows)
- [ ] Multi-Payment Entry Per Order (method, amount, reference, currency)

## 4. WhatsApp Integration

- [ ] Adopt WAHA (https://github.com/devlikeapro/waha) as Core WhatsApp HTTP API Engine
- [ ] Multi-Session / Multi-Number Support
- [ ] Message Templates & Quick Replies
- [ ] Contact & Chat Sync to CRM
- [ ] Webhook Events for Incoming Messages & Media

## 5. Separate WhatsApp-Web UI (Sales Console)

- [ ] Clone Official WhatsApp-Web Layout
- [ ] Custom Sidebar: Cart Builder & Shipping Panel
- [ ] Real-Time Sync with ERP Orders
- [ ] Lead Enrichment (auto-fill customer profile: shipping GPS location, phone number, name, etc)
- [ ] Desktop Notifications & Shortcuts

## 6. Marketing & Meta Ads Tracking

- [ ] Meta Ads API Integration (FB / IG)
- [ ] Campaign ↔ Product Mapping
- [ ] Real-Time Ad Spend Ingestion
- [ ] Attribution Rules (last-click, weighted)
- [ ] Cost-Per-Sale & ROAS Reports

## 7. Financials & Reporting

- [ ] Automatic COGS Calculation (FIFO, landed cost)
- [ ] Profit & Loss Statement
- [ ] Cash Flow Forecasting
- [ ] Custom KPI Builder
- [ ] Scheduled Reports (email, Slack)
- [ ] Payment Method Ledger per Account (cash, Tigo, Itau, cards, online, etc.)
- [ ] Account Consolidation & Transfers Workflow (agent payout → bank deposit)
- [ ] Payment Reconciliation & Pending-Cash Alerts

## 8. Logistics & Delivery Management

- [ ] Route Optimization via Google Maps API
- [ ] Courier Pool (motorcycle drivers)
- [ ] Batch Packing & Label Printing
- [ ] Real-Time Driver Tracking & POD
- [ ] Delivery Cost Allocation per Order

## 9. Admin Dashboards & KPIs

- [ ] Advertising Spend Allocation Tool
- [ ] Inventory Health Metrics (ageing, turnover)
- [ ] Sales Funnel & Conversion Rates
- [ ] Team Performance Leaderboards
- [ ] Alerting & Anomaly Detection
- [ ] Store Operator Dashboard (open carts, confirmed orders, packed, en route, pending payments, walk-in order form)

## 10. Security & Compliance

- [ ] Role-Based Access Control
- [ ] Audit Logs & Data Lineage
- [ ] GDPR / Data-Retention Policies
- [ ] Backups & Disaster Recovery

## 11. Infrastructure & DevOps

- [ ] CI/CD Pipelines
- [ ] Microservices Deployment (Containers / Kubernetes)
- [ ] Observability (logs, metrics, tracing)
- [ ] Auto-Scaling & Cost Monitoring
- [ ] Secrets Management

## 12. Infrastructure Setup (Rails 7.2 & Blue-Green Docker Compose)

- [x] Initialize Rails 7.2 application skeleton
- [x] Establish Monorepo Structure (`/services/rails`, `/services/waha`, etc.)
- [ ] Write Dockerfiles for Rails & WAHA (Rails done, WAHA TBD)
- [x] Create `docker-compose.yml` with Postgres, Redis, Rails, WAHA, Traefik
- [ ] Add Traefik configuration for blue-green stacks (`app_v1`, `app_v2`) & health probes
- [x] Implement `Makefile` targets (`setup`, `up`, `test`, `deploy`)
- [x] GitHub Actions CI: test, lint, build & push versioned images
- [x] Deployment Script (`deploy.sh`) for zero-downtime blue-green swap
- [ ] CI/CD step: SSH into VPS & run `deploy.sh`
- [ ] Automated database backup & restore plan
- [ ] Developer onboarding docs (`README` + `.devcontainer` optional)
- [x] Provide `.tool-versions` file and asdf tooling guidelines for Ruby, Node, Postgres, etc.

## 13. Domain Data Modeling
- [ ] Product & Variant entities (SKU, barcode, attributes)
- [ ] Packaging Material entity (units, cost)
- [ ] Inventory Lots with FIFO cost tracking
- [ ] Order entity with states & short-link token
- [ ] Cart entity (draft orders via WhatsApp/UI)
- [ ] Payment entity with multi-method split & ledger posting
- [ ] Cash Register Session entity (open/close, cash-at-hand)
- [ ] Shipping entity (courier, cost, tracking)
- [ ] Sourcing Order entity with cost breakdown (fees, customs, shipping)
- [ ] Marketing Campaign attribution entities (Meta Ads → order)

---

**Legend**

- [ ] Pending / Not Started
- [▪] In Progress (replace with `▪` when actively being worked on)
- [x] Completed

> _Next steps_: refine each module's scope, define architecture, and create detailed task issues in the tracker.
