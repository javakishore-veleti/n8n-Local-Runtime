# Instructions for Claude Opus — Generate SkillForge PRD Document

## Context for Claude

You are helping build **SkillForge**, an AI-powered Skills-based Test Validation Platform for enterprise digital sales services. You need to generate two deliverables:

1. **PRD.md** — A comprehensive Product Requirements Document in Markdown
2. **PRD-SkillForge.docx** — A professionally formatted Word document version of the same PRD

Read this entire document carefully. It contains the complete product context, architecture decisions, feature requirements, and formatting specifications for both deliverables.

---

## Product Summary

SkillForge enables QA engineers and business users to define, execute, and manage end-to-end integration tests across enterprise digital sales services using Anthropic's SKILL.md paradigm — a single markdown file that serves as both human-readable documentation and machine-executable instruction set.

### The Problem

Enterprise digital sales services involve deeply integrated business applications — TDI (Test Data Initialization), Digital Sales Services (DSS), Offers Microservice, Orders API, EventHub — that must work together seamlessly.

Current pain points:
- **Manual testing**: Business users depend on QA engineers for every test scenario
- **Infinite combinations**: Different users test different things — products, pricing, tax, channels, markets. No fixed set of test cases can cover all needs
- **Knowledge silos**: API knowledge lives in engineers' heads, not reusable artifacts
- **No self-service**: Business users can't independently validate anything
- **No standardization**: Each test scenario handled differently; hard to track coverage or reproduce failures

### Target Users

1. **Skill Authors** (QA Engineers / Technical Leads) — Author SKILL.md files encoding test scenarios, optionally include supporting scripts (.sh, .py, .js), maintain and version skills
2. **Skill Executors** (Business Users / QA Analysts) — Select pre-authored skills, provide input criteria, run tests, read results in business language
3. **Platform Administrators** — Manage Service Registry (API connections, credentials, Swagger specs), monitor platform health

---

## Architecture

### Three-Layer Architecture

**Layer 1 — Service Registry (Platform-Managed)**
Centralized admin-managed catalog of all enterprise APIs. Each registered service includes: service name/description, base URL per environment (dev/staging/prod), JWT Token Server URL, Client ID and Client Secret (securely stored via Secrets Manager or Vault), Swagger/OpenAPI specification. Business users never interact with it. Skills reference services by name — the platform resolves to actual connection details at runtime.

**Layer 2 — Skills Layer (Author-Created, User-Executed)**
Self-contained test scenario definitions packaged as SKILL.md + optional scripts. Stored in local filesystem (MVP) or AWS S3 (production). Versioned, searchable, shareable.

The SKILL.md file is the core contract containing:
- **Metadata** (YAML front matter): name, version, author, tags, execution_mode (ai|workflow), description, timeout
- **UICriteria section** (XML-tagged): Defines input collection mode
  - Type: HTML (dynamic form), Excel (file upload for batch), or Both
  - HTMLCriteria: JSON field definitions — each field has label, type (text/number/select/multi-select/checkbox/date/textarea), options, default, required, placeholder, helpText
  - ExcelCriteria: expected column definitions for template generation
- **WorkflowDefinition section** (XML-tagged): Ordered Tasks
  - Each Task has: id, name, service reference, operation, input mappings using {TaskN.field_name} variable notation, capture fields, assert conditions (with optional conditional assertions "Assert if {field}:"), optional loop attribute ("for each channel in {channels}"), optional flag, depends_on
  - Supports: sequential execution, fan-out (loops), conditional tasks, wait/poll with timeout
- **OutputDefinition section** (optional): Natural language description of desired results report format
- **Scripts section** (optional): Maps task IDs to supporting script files with language attribute

**Layer 3 — AI Execution Engine**
Reads SKILL.md, collects user input, resolves services against registry, orchestrates API calls, evaluates assertions, generates business-language results. Uses Anthropic Claude (Sonnet for speed, Opus for complex skills).

### Dual Execution Model

- **AI-Interpreted Execution (Default, ~95%)**: AI reads SKILL.md and dynamically orchestrates. Fast to author, flexible, sufficient for most scenarios. Cost: AI tokens per execution.
- **Hardened Workflow Execution (~5%)**: For mission-critical skills needing 100% deterministic reliability, a developer implements the same SKILL.md as a Temporal workflow (Java/Go/Python/Node.js). Same SKILL.md serves as the spec. Same user experience — platform routes based on skill's execution_mode config.
- Lifecycle: Skills start as AI-executed → critical ones get hardened to Temporal as needed.

---

## Domain Context: Digital Sales Services

The primary test pipeline:

1. **TDI Service** — Create test customer/account/vehicle. Inputs: model_year, make, model, country (US/CA/MX). Outputs: account_number, vin, customer_id
2. **Digital Sales Services (DSS)** — Onboard customer/VIN into DSS for offer qualification. Inputs: account_number, vin. Outputs: enrollment_status, trial_offers
3. **Offers Microservice** — Get qualified purchasable offers. **Fans out by channel**: MC_GMOC, MC_ONECRM, MC_WEB_APP, MC_ADVSR. Inputs: vin, account_number, channel. Outputs: offers[], offer_ids[]
4. **Orders API — Create Quote** — Generate quote for each qualified offer. Fans out per offer. Inputs: offer_id, vin, account_number, channel. Outputs: quote_id, quote_total, tax_details
5. **Orders API — Create Order** — Place order per quote. Fans out per quote. Inputs: quote_id. Outputs: order_id, order_status
6. **Orders API — Get Orders** — Verify all orders exist and are correct. Inputs: account_number. Assertions: order count matches, each status is CREATED or CONFIRMED
7. **EventHub** (optional) — Listen for async order confirmation events. Configurable timeout (e.g., 300s) and poll interval (e.g., 30s)

Authentication: Centralized JWT Token Server. Each API has its own Client ID and Client Secret. Platform obtains JWT tokens before each API call.

---

## UI Navigation

Left Navigation Bar:
- **Dashboard** — Platform overview, metrics, recent activity (Phase 2)
- **Skills → Definition** — Create, upload, edit, manage skill definitions
- **Skills → Execution** — Select a skill, configure criteria, execute
- **Skills → Favorites** — Quick-access bookmarked skills
- **Skills → Past Executions** — Search and review historical execution runs

---

## Feature Requirements

### Skills Definition (FR-DEF)
- **FR-DEF-001 Skills Library View**: Searchable, filterable list of all skills. Each shows: name, description, author, version, tags, dates, execution count, favorite star. Filters: tag, author, date range. Full-text search.
- **FR-DEF-002 Skill Upload**: Upload SKILL.md or zip/tar archive (SKILL.md + scripts). Drag-and-drop, file browser, or S3 path. Platform parses and shows preview: metadata, criteria fields, workflow tasks, scripts, validation results. Author confirms and publishes.
- **FR-DEF-003 Skill Validation**: Automated checks on upload — parseable SKILL.md with required sections, service references match registry, well-formed UICriteria, referenced scripts exist, no hardcoded credentials.
- **FR-DEF-004 Skill Versioning**: Each upload of existing skill creates new version. Previous versions retained. Executors run latest by default, can select specific version.
- **FR-DEF-005 Skill Edit**: Re-upload new version or in-browser SKILL.md editor (Phase 2).
- **FR-DEF-006 Deletion/Archival**: Archive (hidden but retained) or permanent delete (with confirmation). Past execution records preserved.

### Skills Execution (FR-EXE)
- **FR-EXE-001 Skill Selection**: Search-enabled dropdown. Favorites grouped at top with star icon. Typeahead on name, description, tags. Shows: name, description, version, author.
- **FR-EXE-002 Dynamic Criteria Rendering**: Reads UICriteria from SKILL.md. HTML type: renders form controls per field definitions. Excel type: file upload zone + "Download Template" button + upload preview. Combined: form + file upload.
- **FR-EXE-003 Environment Selection**: Choose dev/staging/production. Determines Service Registry config used.
- **FR-EXE-004 Execute**: Click Run → generate unique Execution ID → validate criteria → set status Queued → submit to engine → transition to Running.
- **FR-EXE-005 Real-Time Progress**: Overall status + progress bar, per-task status (Pending/Running/Passed/Failed/Skipped), live log streaming, elapsed time. Preserved if user navigates away.
- **FR-EXE-006 Async Support**: Runs asynchronously. In-app notification on completion. Immediately visible in Past Executions. Long-running tasks show periodic updates.
- **FR-EXE-007 Results**: Overall pass/fail. AI-generated business summary. Per-task: inputs, outputs, assertions (pass/fail each), duration. Failed tasks: error details, response excerpts, investigation suggestions. Formatted report per OutputDefinition if present.

### Skills Favorites (FR-FAV)
- **FR-FAV-001**: Toggle star icon from Definition, Execution dropdown, or Favorites page. Per-user, persisted.
- **FR-FAV-002 Favorites Page**: Grid of favorited skills with name, description, last execution result, prominent "Run" button → opens Execution pre-selected.

### Past Executions (FR-HIST)
- **FR-HIST-001 History List**: Table with Execution ID, Skill Name, Executed By, Environment, Start Time, End Time, Duration, Status, Summary.
- **FR-HIST-002 Filters**: Date range, skill definition, status (Passed/Failed/Running/Queued), executed by, environment, execution ID. Combinable (AND). Paginated, sortable.
- **FR-HIST-003 Detail View**: Full results, input criteria used, SKILL.md version executed, re-run option.
- **FR-HIST-004 Export**: JSON, PDF, Excel.

### Service Registry — Admin (FR-REG)
- **FR-REG-001**: Register service with name, description, base URL per environment, JWT Token Server URL, Client ID, Client Secret (encrypted), Swagger spec.
- **FR-REG-002**: View, edit, deactivate services. Health check. View which skills reference a service.
- **FR-REG-003**: Credentials encrypted at rest, never displayed in full. Rotation without affecting skills. Audit log.

---

## AI Execution Engine Flow

1. Load SKILL.md from storage
2. Parse: extract Metadata, UICriteria, WorkflowDefinition, OutputDefinition, Scripts
3. Resolve: map service references to Service Registry entries
4. Contextualize: merge user input criteria with workflow; resolve variable placeholders
5. Authenticate: obtain JWT tokens for each service
6. Execute: process tasks sequentially; handle loops (fan-out), optional tasks, wait/poll; delegate to scripts when referenced
7. Assert: evaluate assertions per task against API responses
8. Report: generate per-task results + AI business summary
9. Store: persist execution record for history

Error handling: API errors captured/task failed/dependent tasks skipped; auth retry once; timeout reported; script stderr captured; AI interpretation failures flagged as "Unresolvable."

Sandboxed script execution: Docker container per execution, skill files mounted read-only, inputs via env vars or config.json, outputs from stdout (JSON expected), timeout enforced, container torn down.

---

## Technical Stack

| Component | Technology | Purpose |
|---|---|---|
| Frontend | React + TypeScript | SPA for all screens |
| Backend API | Java Spring Boot / Node.js / Python FastAPI | REST API, skill management, execution management |
| AI Engine | Anthropic Claude API (Opus/Sonnet) | SKILL.md interpretation and orchestration |
| Workflow Engine | Temporal (Java/Go/Python/TS SDK) | Hardened execution path |
| Skill Storage | Local filesystem (MVP) / AWS S3 | Skill packages |
| Credential Store | AWS Secrets Manager / HashiCorp Vault | JWT client credentials |
| Database | PostgreSQL | Skills, executions, users, registry |
| Message Queue | Apache Kafka / AWS SQS | Async job queue |
| Event Integration | Azure EventHub SDK | Event listening |
| Script Runtime | Docker | Sandboxed execution |

---

## API Endpoints

### Skills APIs
- POST /api/skills — Upload new skill
- GET /api/skills — List (search, filter, paginate)
- GET /api/skills/{id} — Details
- GET /api/skills/{id}/versions — Version history
- PUT /api/skills/{id} — Update (new version)
- DELETE /api/skills/{id} — Archive/delete
- POST /api/skills/{id}/favorite — Toggle favorite
- GET /api/skills/favorites — User's favorites

### Execution APIs
- POST /api/executions — Initiate execution
- GET /api/executions — List (search, filter, paginate)
- GET /api/executions/{id} — Details and results
- GET /api/executions/{id}/stream — SSE real-time progress
- POST /api/executions/{id}/cancel — Cancel
- POST /api/executions/{id}/rerun — Re-run

### Service Registry APIs (Admin)
- POST /api/services — Register
- GET /api/services — List
- PUT /api/services/{id} — Update
- DELETE /api/services/{id} — Deactivate
- POST /api/services/{id}/health — Test connectivity

---

## Data Model

### Skill Entity
id (UUID), name (String), description (String), version (String), author (String), tags (String[]), execution_mode (Enum: AI/WORKFLOW), storage_path (String), ui_criteria_type (Enum: HTML/EXCEL/BOTH), ui_criteria_fields (JSON), task_count (Integer), created_at (Timestamp), updated_at (Timestamp), status (Enum: ACTIVE/ARCHIVED/DELETED)

### Execution Entity
id (UUID), skill_id (UUID FK), skill_version (String), executed_by (UUID FK), environment (Enum: DEV/STAGING/PRODUCTION), input_criteria (JSON), status (Enum: QUEUED/RUNNING/COMPLETED/FAILED/CANCELLED), start_time (Timestamp), end_time (Timestamp), result_summary (Text), task_results (JSON), overall_pass (Boolean)

### Service Entity
id (UUID), name (String), description (String), environments (JSON: map of env → {base_url, token_url, client_id_ref, client_secret_ref}), swagger_spec (JSON), status (Enum: ACTIVE/INACTIVE)

### Favorite Entity
user_id (UUID FK), skill_id (UUID FK), created_at (Timestamp)

---

## Non-Functional Requirements

### Performance
- Skill upload/parse: <5s for packages up to 50MB
- Dynamic criteria rendering: <1s after selection
- Execution initiation: <2s to queued
- Past Executions search: <3s across 100K+ records
- Concurrent executions: 20+ (Phase 1), 100+ (Phase 2)

### Security
- Credentials encrypted at rest (AES-256) and in transit (TLS 1.3)
- No credentials in SKILL.md files (enforced on upload)
- RBAC: Admin, Author, Executor, Viewer
- Sandboxed script execution in isolated containers
- Audit logging

### Reliability
- Execution state persisted at task boundaries — resumable
- Failed tasks don't halt execution unless dependent
- Auto retry for transient failures (configurable)
- Timeouts at task and skill level

---

## Phase Plan

### Phase 1 — MVP (8–12 weeks)
Left nav, skill upload/validation/preview, skill library, execution with dynamic HTML criteria, AI execution via Claude API, real-time progress, results with AI summary, past executions with search, favorites, service registry admin. Single environment. Tech: React + Java Spring Boot + PostgreSQL + Local filesystem + Claude API.

### Phase 2 — Production Hardening (6–8 weeks)
Excel criteria, multi-environment, Temporal integration, Docker script sandbox, export (JSON/PDF/Excel), skill versioning UI, in-browser SKILL.md editor, S3 storage, Secrets Manager.

### Phase 3 — Scale & Intelligence (6–8 weeks)
Dashboard with metrics/trends, AI-assisted skill authoring, recommendations, scheduled execution (cron), team workspaces/RBAC, notifications (email/Slack/Teams), CI/CD API (Jenkins/GitHub Actions), EventHub module.

### Phase 4 — Enterprise (Ongoing)
Multi-tenancy, SSO/SAML, compliance/audit reporting, custom branding, SLA monitoring, skill marketplace.

---

## Success Metrics (6 months post-launch)

| Metric | Target |
|---|---|
| Skills authored | 50+ |
| Monthly executions | 1,000+ |
| Business user adoption | 80%+ of runs by non-QA |
| AI execution reliability | 95%+ |
| Time to create a skill | <30 minutes |
| Time to execute | <2 minutes typical |
| NPS | 40+ |

---

## Open Questions

| # | Question | Options | Recommendation |
|---|---|---|---|
| 1 | Backend language | Java Spring Boot vs Node.js vs Python | Java (enterprise context) |
| 2 | AI model | Claude Opus 4.6 vs Sonnet 4.5 | Sonnet default; Opus for complex |
| 3 | Storage MVP | Local vs S3 | Local for MVP; S3 in Phase 2 |
| 4 | AI skill authoring | Phase 1 or 3 | Phase 3 |
| 5 | CI/CD integration | Phase 2 or 3 | Phase 3 |
| 6 | Conditional UI fields | Phase 1 or 2 | Phase 2 |

---

## Glossary

| Term | Definition |
|---|---|
| SKILL.md | Markdown file following Anthropic Skills paradigm; documentation + executable instructions |
| Skill Definition | Packaged skill: SKILL.md + optional .sh/.py/.js scripts |
| Skill Execution | Single run of a skill with specific criteria against a target environment |
| Service Registry | Platform-managed API catalog with connection details and credentials |
| UICriteria | SKILL.md section defining input collection from executor |
| WorkflowDefinition | SKILL.md section defining ordered API operation sequence |
| Task | Single step in workflow: one API operation or script execution |
| Fan-out | Task iterating over collection (e.g., per channel), producing parallel sub-executions |
| Hardened Execution | Skill implemented as Temporal workflow for deterministic reliability |
| TDI | Test Data Initialization service |
| DSS | Digital Sales Services |

---

## GENERATION INSTRUCTIONS

### Deliverable 1: PRD.md

Generate a comprehensive Markdown file with the full PRD content organized into these sections:

1. Executive Summary
2. Problem Statement (2.1 Pain Points, 2.2 Target Users)
3. Product Vision and Architecture (3.1 Three-Layer Architecture, 3.2 Dual Execution Model, 3.3 SKILL.md specification with FULL example for the GMC scenario including UICriteria XML and WorkflowDefinition XML with all 7 tasks)
4. Feature Requirements (4.1 Navigation, 4.2 Skills Definition FR-DEF-001 through 006, 4.3 Skills Execution FR-EXE-001 through 007, 4.4 Favorites FR-FAV-001-002, 4.5 Past Executions FR-HIST-001 through 004, 4.6 Service Registry FR-REG-001 through 003)
5. AI Execution Engine (5.1 Flow, 5.2 Context Strategy, 5.3 Variable Resolution, 5.4 Error Handling, 5.5 Sandboxed Scripts)
6. Technical Architecture (6.1 Components table, 6.2 Deployment, 6.3 API Design with all endpoints, 6.4 Data Model with all entities)
7. SKILL.md Specification Reference (7.1-7.6 covering format, metadata, UICriteria, WorkflowDefinition, OutputDefinition, Scripts)
8. UI Specifications (8.1 Design Principles, 8.2 Color Theme table, 8.3 Screen Specs for each page)
9. Non-Functional Requirements (Performance, Security, Reliability, Scalability)
10. Phase Plan (Phase 1-4 with scope and timeline)
11. Success Metrics table
12. Open Questions table
13. Glossary table
14. Appendix (Example SKILL.md, Initial Services list)

### Deliverable 2: PRD-SkillForge.docx

Generate a professionally formatted Word document with:

- **Cover page**: Product title "SkillForge", subtitle "AI-Powered Skills-Based Test Validation Platform", "Product Requirements Document", version, date, status (Draft), "Confidential"
- **Table of Contents**: Auto-generated from heading styles
- **Headers**: "SkillForge PRD" left-aligned, "v1.0 — Confidential" right-aligned, with bottom border line
- **Footers**: Centered page numbers
- **Heading styles**: H1 dark navy (#1A3764), H2 medium blue (#2E5090), H3 lighter blue (#3B6DB5), all Arial font
- **Body text**: Arial 11pt, good spacing
- **Tables**: Blue header rows (#2E5090) with white text, alternating row shading (#F0F4FA), light gray borders
- **Bullet lists**: Proper numbering config (not unicode bullets)
- **Page breaks**: Between major sections
- **US Letter page size** (12240 × 15840 DXA)

If using Node.js with the `docx` npm package, use `Packer.toBuffer()` and proper heading styles with `outlineLevel` for TOC compatibility. Set explicit page size to US Letter. Use `WidthType.DXA` for all table widths (never percentage). Use `ShadingType.CLEAR` (never SOLID). Use `LevelFormat.BULLET` for bullet lists (never unicode bullet characters).

Generate both files now.
