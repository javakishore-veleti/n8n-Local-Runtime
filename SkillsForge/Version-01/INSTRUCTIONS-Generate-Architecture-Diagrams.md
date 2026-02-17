# Instructions for Claude Opus — Generate SkillForge Architecture Diagrams

## Context for Claude

You are helping build **SkillForge**, an AI-powered Skills-based Test Validation Platform for enterprise digital sales services. You need to generate a comprehensive set of architecture and business user view diagrams as a single interactive HTML file.

Read this entire document carefully before generating any code. This document contains the full product context, architecture decisions, and specific diagram requirements.

---

## Product Overview

SkillForge enables QA engineers and business users to define, execute, and manage end-to-end integration tests across enterprise digital sales services using Anthropic's SKILL.md paradigm — where a single markdown file serves as both human-readable documentation and machine-executable instruction set.

### The Problem
- Enterprise digital sales services involve deeply integrated applications (TDI, Digital Sales Services, Offers Microservice, Orders API, EventHub)
- Testing depends on QA engineers who understand APIs; business users can't self-serve
- Different business users have different needs (products, pricing, tax, channels) — "trillion combinations" of test scenarios
- Manual testing is slow, siloed, and doesn't scale

### The Solution
- Users author SKILL.md files describing test scenarios in structured natural language
- The platform's AI execution engine interprets and orchestrates multi-system API test flows automatically
- Business users select a skill, fill in criteria, click Run, and get results in plain English

---

## Architecture — Three Layers

### Layer 1: Service Registry (Platform-Managed)
- Centralized admin-managed catalog of all enterprise APIs
- Each service registered with: name, base URL per environment (dev/staging/prod), JWT Token Server URL, Client ID + Client Secret (encrypted), Swagger/OpenAPI spec
- Business users never see this layer
- Skills reference services by name — platform resolves to actual connection details

### Layer 2: Skills Layer (Author-Created, User-Executed)
- Self-contained test scenario definitions: SKILL.md + optional .sh/.py/.js scripts
- Stored in local filesystem or AWS S3, versioned, searchable
- SKILL.md contains:
  - **Metadata**: name, version, author, tags, execution_mode (ai/workflow)
  - **UICriteria**: defines input collection — HTML (dynamic form) or Excel (batch upload) or both. HTML fields have label, type (text/number/select/multi-select/checkbox/date), options, defaults, required flag
  - **WorkflowDefinition**: ordered Tasks, each with ID, name, service reference, operation, input mappings using `{TaskN.field}` notation, output captures, assertions, optional loop/conditional/wait
  - **OutputDefinition** (optional): desired report format in natural language
  - **Scripts** (optional): maps tasks to .sh/.py/.js files for complex logic

### Layer 3: AI Execution Engine
- Reads SKILL.md, collects user input, resolves services against registry, orchestrates API calls, evaluates assertions, generates business-language results
- Uses Anthropic Claude (Sonnet for speed, Opus for complex skills)
- Handles variable passing between tasks, fan-out (loops), conditional assertions, wait/poll

### Dual Execution Model
- **AI-Interpreted (~95%)**: Default. AI reads SKILL.md and orchestrates dynamically. Fast to author, flexible.
- **Hardened Workflow (~5%)**: Developer implements same SKILL.md as Temporal workflow (Java/Go/Python/Node.js). 100% deterministic for mission-critical skills (release gates, compliance).
- Same user experience for both paths — platform routes based on skill config.

---

## Domain-Specific Context: Digital Sales Services

The primary test pipeline flow:

1. **TDI Service** — Create test customer account + vehicle (inputs: model_year, make, model, country) → outputs: account_number, vin
2. **Digital Sales Services (DSS)** — Onboard customer/VIN for offer qualification → outputs: enrollment_status, trial_offers
3. **Offers Microservice** — Get qualified offers per sales channel (fan-out across MC_GMOC, MC_ONECRM, MC_WEB_APP, MC_ADVSR) → outputs: offers[], offer_ids[]
4. **Orders API — Create Quote** — Generate quote per offer (fan-out) → outputs: quote_id, quote_total, tax_details
5. **Orders API — Create Order** — Place order per quote (fan-out) → outputs: order_id, order_status
6. **Orders API — Get Orders** — Verify all orders created → assertions on count and status
7. **EventHub** (optional) — Listen for async order confirmation events

Authentication: Centralized JWT Token Server with Client ID + Client Secret per API.

---

## UI Navigation Structure

Left navigation bar:
- **Dashboard** (Phase 2)
- **Skills**
  - Definition — create, upload, edit, manage skill definitions
  - Execution — select skill, configure criteria, run
  - Favorites — quick-access bookmarked skills
  - Past Executions — search and review historical runs
- **Admin**
  - Service Registry
  - Users

---

## Target Users (Three Personas)

1. **Skill Authors** (QA Engineers / Technical Leads): Author SKILL.md files, optionally include scripts, maintain and version skills
2. **Skill Executors** (Business Users / QA Analysts): Select skills, fill criteria (form or Excel), run tests, read results in business language
3. **Platform Admins** (Engineering / DevOps): Manage Service Registry, configure credentials, monitor health

---

## Technical Stack

| Component | Technology |
|---|---|
| Frontend | React + TypeScript |
| Backend API | Java Spring Boot (primary) / Node.js / Python FastAPI |
| AI Engine | Anthropic Claude API (Sonnet/Opus) |
| Workflow Engine | Temporal (Java/Go/Python/TS SDK) |
| Skill Storage | Local filesystem (MVP) / AWS S3 |
| Credential Store | AWS Secrets Manager / HashiCorp Vault |
| Database | PostgreSQL |
| Message Queue | Apache Kafka / AWS SQS |
| Event Integration | Azure EventHub SDK |
| Script Runtime | Docker (sandboxed) |

---

## DIAGRAM REQUIREMENTS

Generate a **single HTML file** containing **9 diagrams**, each on its own full-height page section. Use a dark theme with a sticky top navigation bar to jump between diagrams. The aesthetic should be enterprise-grade, polished, dark-mode (background ~#0a0d14), with color-coded layers and clean iconography.

### Design Tokens

| Token | Value | Usage |
|---|---|---|
| Background | #0a0d14 | Page background |
| Surface | #111827 | Cards, diagram containers |
| Surface Alt | #1a2236 | Nested elements |
| Border | #1e2d45 | Borders, dividers |
| Text | #e2e8f0 | Primary text |
| Text Muted | #94a3b8 | Secondary text |
| Text Dim | #64748b | Tertiary text |
| Blue/Accent | #3b82f6 | Frontend, primary actions, users |
| Green | #10b981 | Service Registry, success, APIs |
| Purple | #8b5cf6 | AI Engine, execution |
| Yellow/Amber | #f59e0b | Admin, warnings, credentials |
| Pink | #ec4899 | Temporal, hardened path |
| Teal | #14b8a6 | Verification, EventHub |
| Red | #ef4444 | Failures |

Font: Inter (import from Google Fonts). Use monospace (SF Mono / Fira Code) for code/technical references.

### The 9 Diagrams

**Diagram 1: High-Level System Architecture**
- Full SVG diagram showing three columns: Users (left), SkillForge Platform (center), Enterprise APIs (right)
- Users column: Business Users, QA Engineers, Admins — with color-coded boxes and connecting arrows to platform
- Platform column: React Frontend → Backend API → Skills Storage + PostgreSQL → AI Execution Engine + Temporal → Service Registry
- Enterprise APIs column: TDI Service, Digital Sales Services, Offers Microservice, Orders API, EventHub, JWT Token Server
- Bottom section: Authentication & Security Flow showing Credentials Vault → Client ID/Secret → JWT Token Server → Authenticated API Calls
- Arrows with directional markers showing data flow

**Diagram 2: Three-Layer Architecture**
- Three horizontal layer cards stacked vertically (Layer 3 on top, Layer 1 on bottom)
- Layer 3 (purple): AI Execution Engine — chips: Claude Sonnet/Opus, NL Interpretation, Dynamic Orchestration, Result Summarization, Temporal Fallback
- Layer 2 (blue): Skills Layer — chips: SKILL.md, UICriteria, WorkflowDefinition, .sh/.py/.js Scripts, S3/Local Storage
- Layer 1 (green): Service Registry — chips: TDI, Digital Sales Services, Offers API, Orders API, EventHub, JWT Token Server
- Each layer has a number badge, title, description, and tag chips

**Diagram 3: SKILL.md Anatomy**
- 2-column grid layout showing each section of the SKILL.md file
- Metadata section (blue): name, version, author, tags, execution_mode, description
- UICriteria section (green): Type (HTML/Excel/Both), HTML field definitions, Excel column definitions
- WorkflowDefinition section (purple, full-width spanning both columns): 6 task boxes in a 3×2 grid showing the GMC test scenario — Task 1: Create Vehicle (TDI), Task 2: Onboard (DSS), Task 3: Get Offers (OffersAPI, loop by channel), Task 4: Create Quote (OrdersAPI, loop by offer), Task 5: Create Order (OrdersAPI, loop by quote), Task 6: Verify (OrdersAPI + EventHub)
- Each task shows: Service, Inputs with variable references, Capture fields, Assert conditions
- OutputDefinition section (pink): report format description
- Scripts section (amber): file mappings to tasks

**Diagram 4: Execution Flow**
- 6-step sequential flow diagram
- Top row (4 steps left-to-right with arrows): Step 1 Select Skill (blue) → Step 2 Fill Criteria (green) → Step 3 Click Run (amber) → Step 4 Queue Execution (purple)
- Middle: large dashed-border processing box labeled "AI Execution Engine — Processing" containing 4 internal steps: Parse SKILL.md → Resolve Services → Authenticate (JWT) → Execute Tasks, plus an Assertions evaluation sub-box
- Bottom row (2 steps): Step 5 Results & AI Summary (green) → Step 6 Store & Notify (blue)
- Arrows connecting all steps with directional flow

**Diagram 5: Dual Execution Model**
- Side-by-side comparison with a divider column in the middle showing "OR"
- Left card (purple): ~95% AI-Interpreted Execution — description, traits: fast to create, flexible, AI interprets assertions, cost is tokens, best for ad-hoc/new scenarios
- Right card (pink): ~5% Hardened Workflow Execution — description, traits: requires developer, deterministic, retry/timeout/recovery, Java/Go/Python/TS SDK, best for release gates/compliance
- Footer text: "Lifecycle: Start with AI execution → Identify critical skills → Harden to Temporal as needed"

**Diagram 6: Test Execution Pipeline**
- Horizontal pipeline showing the actual data flow through the digital sales services
- 7 nodes connected by arrows: TDI (🚗) → DSS (📋) → Offers API (🎯, fan-out label) → Quote (💰) → Order (📦) → Verify (✅)
- Each node shows: icon, service name, operation description, output fields
- Offers node specifically shows fan-out across 4 channels: MC_GMOC, MC_ONECRM, MC_WEB_APP, MC_ADVSR
- Bottom: Data threading bar showing how variables flow: account_number,vin → enrollment → offers[] → quote_ids[] → order_ids[] → verification
- Use emoji icons in the pipeline nodes

**Diagram 7: User Journeys**
- 3-column grid with one card per persona
- Each card has: colored top border, emoji icon, persona title, role subtitle, and 7 numbered steps
- Skill Author (blue, 🛠️): Identify scenario → Author SKILL.md → Add scripts → Upload zip → Review validation → Test-run → Iterate/version
- Skill Executor (green, ▶️): Open Execution/Favorites → Search/select skill → Fill criteria or upload Excel → Select environment + Run → Watch progress → Read AI summary → Drill into failures/export/re-run
- Platform Admin (amber, ⚙️): Register APIs → Configure JWT → Store credentials → Upload Swagger specs → Test connectivity → Rotate credentials → Monitor metrics

**Diagram 8: System Components**
- 4 component groups in a grid, each a bordered box with a label badge
- Frontend group (blue): React SPA, Dynamic Form Engine, SSE Client, State Management
- Backend group (green): REST API Server, Skills Manager, Execution Manager, Auth Service
- Execution Engines group (purple): Claude AI Engine, SKILL.md Parser, Temporal Workers, Script Sandbox
- Data & Infrastructure group (amber): PostgreSQL, AWS S3, Secrets Manager, Kafka/SQS
- Each component box shows name and technology

**Diagram 9: UI Layout Mockup**
- Realistic wireframe/mockup of the Skills Execution screen
- Browser chrome with traffic light dots and title bar
- Left sidebar with the full navigation: SkillForge logo, Dashboard, Skills (Definition, Execution [active/highlighted], Favorites, Past Executions), Admin (Service Registry, Users)
- Main content area showing:
  - "Execute Skill" title
  - Skill selector card with dropdown showing "⭐ Test US 2025 GMC Offers and Orders (v1.2)"
  - Input Criteria card with a 3-column form: Model Year (2025), Make (GMC), Model (Sierra), Country (US), Sales Channels (multi-select chips: MC_GMOC, MC_WEB_APP, MC_ADVSR)
  - Checkboxes: Validate Tax (checked), Validate Pricing (unchecked)
  - "▶ Run Skill" button (blue accent)
  - Environment badge in top bar showing "ENV: Staging"

---

## Implementation Notes

- All in a single HTML file with embedded CSS (no external dependencies except Google Fonts Inter)
- Use SVG for Diagrams 1 and 4 (complex arrow-based diagrams)
- Use CSS/HTML for Diagrams 2, 3, 5, 6, 7, 8, 9 (card/grid-based layouts)
- Sticky navigation bar at top with links to each diagram section
- Each diagram in a container with a subtle top glow border line
- Page labels showing "Diagram N of 9"
- Responsive-friendly but desktop-optimized
- Print-friendly: page breaks between diagrams

Generate the complete HTML file now.
