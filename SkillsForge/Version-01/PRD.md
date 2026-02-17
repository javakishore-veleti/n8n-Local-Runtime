# Product Requirements Document (PRD)

# SkillForge — AI-Powered Skills-Based Test Validation Platform

**Version:** 1.0
**Date:** February 16, 2026
**Author:** Kishore / Product Team
**Status:** Draft

---

## 1. Executive Summary

SkillForge is an AI-powered test validation platform that enables QA engineers and business users to define, execute, and manage end-to-end integration tests across enterprise digital sales services using a natural language Skills-based approach.

The platform adopts Anthropic's SKILL.md paradigm — where a single markdown file serves as both human-readable documentation and machine-executable instruction set. Users author SKILL.md files that describe test scenarios in structured natural language, and the platform's AI execution engine interprets and orchestrates multi-system API test flows automatically.

The product eliminates the need for business users to understand API internals, authentication mechanisms, or test scripting, while giving QA engineers the flexibility to encode complex test logic into reusable, shareable skill definitions.

---

## 2. Problem Statement

### 2.1 Current Pain Points

Enterprise digital sales services involve deeply integrated business applications — TDI (Test Data Initialization), Digital Sales Services (DSS), Offers Microservice, Orders API, and others — that must work together seamlessly.

Currently, testing these integrations suffers from several critical challenges:

- **Manual, repetitive testing**: Business users rely on QA engineers to execute test scenarios manually using tools like Postman, custom scripts, or direct API calls.
- **Trillion combinations problem**: Different business users have different testing needs — one tests product eligibility, another tests pricing, another tests tax calculations, another tests channel-specific behavior. The number of unique test scenarios is effectively infinite.
- **Knowledge silos**: Understanding of API endpoints, authentication flows, data dependencies, and assertion logic lives in individual engineers' heads, not in reusable artifacts.
- **No self-service for business users**: Business users cannot independently validate scenarios without developer assistance.
- **Lack of standardization**: Each test scenario is approached differently, making it difficult to track coverage, reproduce failures, or build regression suites.

### 2.2 Target Users

**Skill Authors (QA Engineers / Technical Leads)**
- Understand the business domain and the underlying APIs
- Author SKILL.md files that encode test scenarios
- Optionally include supporting scripts (.sh, .py, .js) for complex logic
- Maintain and version skill definitions over time

**Skill Executors (Business Users / QA Analysts)**
- Need to validate specific business scenarios without coding
- Select pre-authored skills, provide input criteria, and run tests
- Interpret results in business language
- Run ad-hoc tests or scheduled regression suites

**Platform Administrators**
- Manage the Service Registry (API connections, credentials, Swagger specs)
- Monitor platform health, usage, and execution metrics
- Manage user access and permissions

---

## 3. Product Vision and Architecture

### 3.1 Core Concept

The platform operates on a three-layer architecture:

**Layer 1 — Service Registry (Platform-Managed)**

A centralized, admin-managed catalog of all enterprise APIs. Each registered service includes:

- Service name and description
- Base URL per environment (dev, staging, production)
- JWT Token Server URL
- Client ID and Client Secret (securely stored)
- Swagger/OpenAPI specification (ingested and indexed)
- Pre-defined callable operation references

The Service Registry is the platform's infrastructure layer. Business users never interact with it directly. When a SKILL.md references an API operation, the platform resolves it against the registry to obtain connection details, authentication credentials, and endpoint specifications.

**Layer 2 — Skills Layer (Author-Created, User-Executed)**

Skills are self-contained test scenario definitions packaged as a SKILL.md file with optional supporting files. A skill references registered services by name, defines input criteria, describes the execution workflow, and specifies validation assertions.

Skills are stored in a managed repository (local filesystem or AWS S3). They are versioned, searchable, and shareable across teams.

**Layer 3 — AI Execution Engine**

The AI engine reads a SKILL.md, collects user-provided input criteria, resolves service references against the registry, orchestrates API calls in the defined sequence, evaluates assertions, and presents results in business-friendly language.

### 3.2 Execution Model — Dual Path

The platform supports two execution paths for skills:

**AI-Interpreted Execution (Default — ~95% of scenarios)**

The AI reads the SKILL.md, interprets the workflow, and dynamically orchestrates API calls. This is the default path for all skills. It is fast to author, flexible, and sufficient for the vast majority of test scenarios. The AI handles variable passing between steps, fan-out logic (e.g., testing multiple channels), conditional assertions, and result interpretation.

**Hardened Workflow Execution (~5% of scenarios requiring 100% deterministic reliability)**

For mission-critical skills that require guaranteed, repeatable execution (e.g., release gates, compliance checks), a developer can implement the same SKILL.md as a Temporal workflow (or equivalent durable execution framework) in Java, Node.js, Go, or Python. The SKILL.md serves as the specification; the workflow is the deterministic implementation.

From the business user's perspective, both paths are identical — same skill selection, same criteria input, same results view. The platform routes to the appropriate execution engine based on the skill's configuration.

### 3.3 SKILL.md — The Core Contract

The SKILL.md file is the single source of truth for every test scenario. It serves as human-readable documentation, machine-executable instructions, and the contract between skill authors and the platform.

#### SKILL.md Structure

A SKILL.md file contains the following sections:

**Metadata Section**

```
---
name: Test US 2025 GMC Offers and Orders
version: 1.0
author: QA Team
tags: [offers, orders, GMC, US, e2e]
execution_mode: ai | workflow
description: End-to-end validation of vehicle creation, offer qualification, quoting, and order placement for US market GMC vehicles across all digital sales channels.
---
```

**UICriteria Section**

Defines how the platform collects input from the executor. Supports two modes: HTML (dynamic form rendered in the UI) and Excel (file upload for batch execution).

```xml
<UICriteria>
  <Type>HTML</Type>
  <!-- OR -->
  <Type>Excel</Type>
  <!-- OR -->
  <Type>HTML and Excel</Type>

  <HTMLCriteria>
    <Fields>
      {
        "model_year": { "label": "Model Year", "type": "select", "options": ["2024", "2025", "2026"], "default": "2025", "required": true },
        "make": { "label": "Make", "type": "select", "options": ["GMC", "Chevrolet", "Buick", "Cadillac"], "required": true },
        "model": { "label": "Model", "type": "text", "placeholder": "e.g., Sierra, Yukon", "required": true },
        "country": { "label": "Country", "type": "select", "options": ["US", "CA", "MX"], "default": "US", "required": true },
        "channels": { "label": "Sales Channels", "type": "multi-select", "options": ["MC_GMOC", "MC_ONECRM", "MC_WEB_APP", "MC_ADVSR"], "default": ["MC_GMOC", "MC_WEB_APP"], "required": true },
        "validate_tax": { "label": "Validate Tax Calculation", "type": "checkbox", "default": false },
        "validate_pricing": { "label": "Validate Pricing", "type": "checkbox", "default": false }
      }
    </Fields>
  </HTMLCriteria>

  <ExcelCriteria>
    <TemplateColumns>
      {
        "columns": ["model_year", "make", "model", "country", "channels", "expected_offer_count"],
        "description": "Each row represents one test scenario. Channels should be comma-separated."
      }
    </TemplateColumns>
  </ExcelCriteria>
</UICriteria>
```

**WorkflowDefinition Section**

Defines the ordered sequence of tasks to execute. Written in structured natural language with predefined conventions for service references, variable passing, looping, and assertions.

```xml
<WorkflowDefinition>
  <Tasks>

    <Task id="1" name="Generate Test Vehicle and Customer">
      Invoke TDI service to create a test customer account and vehicle.
      Service: TDI
      Operation: createVehicle
      Inputs: model_year={model_year}, make={make}, model={model}, country={country}
      Capture: account_number, vin, customer_id
      Assert: account_number is not null, vin is not null
    </Task>

    <Task id="2" name="Onboard Customer and Vehicle into Digital Sales Services">
      Register the customer and vehicle in Digital Sales Services for offer qualification.
      Service: DSS
      Operation: onboardCustomerVehicle
      Inputs: account_number={Task1.account_number}, vin={Task1.vin}
      Capture: enrollment_status, trial_offers
      Assert: enrollment_status equals "ACTIVE"
    </Task>

    <Task id="3" name="Retrieve Qualified Offers" loop="for each channel in {channels}">
      For each selected sales channel, retrieve qualified purchasable offers.
      Service: OffersAPI
      Operation: getQualifiedOffers
      Inputs: vin={Task1.vin}, account_number={Task1.account_number}, channel={current_channel}
      Capture: offers[], offer_ids[]
      Assert: offers is not empty for each channel
    </Task>

    <Task id="4" name="Generate Quote for Each Offer" loop="for each offer in {Task3.offers}">
      Create a quote for each qualified offer using the Orders API.
      Service: OrdersAPI
      Operation: createQuote
      Inputs: offer_id={current_offer.offer_id}, vin={Task1.vin}, account_number={Task1.account_number}, channel={current_offer.channel}
      Capture: quote_id, quote_total, tax_details
      Assert: quote_id is not null, quote_total > 0
      Assert if {validate_tax}: tax_details.total_tax > 0, tax_details.tax_rate is valid for {country}
      Assert if {validate_pricing}: quote_total matches expected pricing rules
    </Task>

    <Task id="5" name="Create Order from Quote" loop="for each quote in {Task4.quotes}">
      Place an order for each generated quote.
      Service: OrdersAPI
      Operation: createOrder
      Inputs: quote_id={current_quote.quote_id}
      Capture: order_id, order_status
      Assert: order_id is not null, order_status equals "CREATED"
    </Task>

    <Task id="6" name="Verify Orders Exist">
      Retrieve all orders for the account and verify they were created correctly.
      Service: OrdersAPI
      Operation: getOrders
      Inputs: account_number={Task1.account_number}
      Capture: orders[]
      Assert: orders count equals expected number of orders from Task 5
      Assert: each order status is "CREATED" or "CONFIRMED"
    </Task>

    <Task id="7" name="Verify EventHub Events" optional="true">
      Listen to EventHub for order confirmation events.
      Service: EventHub
      Operation: listenForEvents
      Inputs: filter_account={Task1.account_number}, timeout=300s, poll_interval=30s
      Capture: events[]
      Assert: order creation events received for each order in {Task5.order_ids}
    </Task>

  </Tasks>
</WorkflowDefinition>
```

**OutputDefinition Section (Optional)**

Defines what the execution results report should contain.

```xml
<OutputDefinition>
  <Summary>
    Show a summary table with: channel, number of offers qualified, quote generated (Y/N),
    order created (Y/N), order ID, and overall pass/fail per channel.
    If validate_tax was selected, include a tax details section.
    If validate_pricing was selected, include a pricing comparison section.
  </Summary>
</OutputDefinition>
```

**Supporting Scripts (Optional)**

When included in the skill package (zip/tar), the SKILL.md can reference scripts for specific tasks:

```
<Scripts>
  <Script task="7" file="eventhub_listener.py" language="python" />
  <Script task="4" file="tax_validator.sh" language="bash" />
</Scripts>
```

The AI execution engine delegates to these scripts when present, falling back to AI-interpreted execution for tasks without scripts.

---

## 4. Feature Requirements

### 4.1 Navigation and Layout

**Left Navigation Bar**

| Nav Item | Sub-Items | Description |
|----------|-----------|-------------|
| Dashboard | — | Platform overview, metrics, recent activity (Phase 2) |
| Skills | Definition | Create, upload, edit, manage skill definitions |
| Skills | Execution | Select a skill, configure criteria, execute |
| Skills | Favorites | Quick-access bookmarked skills |
| Skills | Past Executions | Search and review historical execution runs |

**Global Elements**

- Top bar: user profile, environment selector (dev/staging/prod), notifications
- Breadcrumb navigation within Skills sub-pages
- Responsive layout supporting desktop and tablet

---

### 4.2 Skills Definition (FR-DEF)

**FR-DEF-001: Skills Library View**

Display a searchable, filterable list of all skill definitions.

Each skill card/row shows: skill name, description (from metadata), author, version, tags, creation date, last modified date, execution count, favorite status (star icon).

Filters: by tag, by author, by date range.
Search: full-text search across skill name, description, and tags.

**FR-DEF-002: Skill Upload**

Users can upload a skill as a single SKILL.md file or as a zip/tar archive containing SKILL.md and optional supporting files (.sh, .py, .js, data files, Excel templates).

Upload methods: drag-and-drop zone, file browser, or reference to an S3 path.

Upon upload, the platform parses the SKILL.md and displays a preview showing: extracted metadata (name, version, author, tags), detected UICriteria type and fields, detected WorkflowDefinition tasks (count and names), detected supporting scripts, and any validation warnings or errors.

The author confirms and publishes the skill.

**FR-DEF-003: Skill Validation on Upload**

The platform performs automated validation when a skill is uploaded:

- SKILL.md is parseable and contains required sections (metadata, UICriteria, WorkflowDefinition)
- Service references in WorkflowDefinition match registered services in the Service Registry
- UICriteria field definitions are well-formed (valid types, required fields present)
- Referenced supporting scripts exist in the uploaded archive
- No hardcoded credentials or sensitive data in any file

Validation results are shown to the author with clear error/warning messages.

**FR-DEF-004: Skill Versioning**

Each upload of an existing skill (matched by name) creates a new version. Previous versions are retained and accessible. Executors always run the latest version by default but can select a specific version if needed.

**FR-DEF-005: Skill Edit**

Authors can re-upload a new version (replacing the archive) or use a lightweight in-browser editor for the SKILL.md file (Phase 2 — basic text/markdown editor with syntax awareness for UICriteria and WorkflowDefinition sections).

**FR-DEF-006: Skill Deletion and Archival**

Skills can be archived (hidden from Execution dropdown but retained for history) or permanently deleted (with confirmation). Past execution records referencing deleted skills retain their results.

---

### 4.3 Skills Execution (FR-EXE)

**FR-EXE-001: Skill Selection**

The Execution page features a search-enabled dropdown for selecting a skill to execute.

The dropdown displays: favorites first (visually grouped with star icon), followed by all available skill definitions. The search filters on skill name, description, and tags using typeahead matching. Each item in the dropdown shows: skill name, brief description, version, and author.

**FR-EXE-002: Dynamic Criteria Rendering**

When a skill is selected, the platform reads the UICriteria section from its SKILL.md and dynamically renders the appropriate input interface.

For HTML criteria type: render a form with the appropriate controls based on field definitions — text inputs, number inputs, select dropdowns, multi-select, checkboxes, date pickers. Apply default values where specified. Mark required fields. Show placeholder text and help descriptions.

For Excel criteria type: show a file upload dropzone. Provide a "Download Template" button that generates a blank Excel file with the expected column headers (derived from ExcelCriteria.TemplateColumns). Upon upload, display a preview of the first 5 rows so the user can verify the data before execution.

For combined (HTML and Excel) type: show the form for primary parameters and a file upload for the batch data.

**FR-EXE-003: Environment Selection**

Before execution, the user selects the target environment (dev, staging, production). This determines which Service Registry configuration (URLs, credentials) is used for all API calls during execution.

**FR-EXE-004: Execute Skill**

User clicks "Run" to initiate execution. The platform:

1. Generates a unique Execution ID
2. Validates all required criteria are provided
3. Sets execution status to "Queued"
4. Submits the execution job to the AI execution engine (or Temporal workflow engine for hardened skills)
5. Transitions status to "Running" once execution begins

**FR-EXE-005: Real-Time Execution Progress**

While execution is in progress, the UI displays:

- Overall execution status and progress bar (tasks completed / total tasks)
- Per-task status: Pending, Running, Passed, Failed, Skipped
- Live log streaming showing current activity
- Elapsed time per task and overall

Users can navigate away and return — progress state is preserved.

**FR-EXE-006: Asynchronous Execution Support**

Executions may take significant time (minutes to hours for batch runs, EventHub listeners, or complex multi-step flows). The platform handles this gracefully:

- Execution runs asynchronously — the user does not need to keep the page open
- A notification (in-app) is sent when execution completes
- The execution is immediately visible in Past Executions upon initiation
- Long-running tasks (e.g., EventHub listeners with timeouts) show periodic status updates

**FR-EXE-007: Execution Results**

Upon completion, the Execution page (or the Past Executions detail view) displays:

- Overall pass/fail status
- AI-generated business-language summary of results (e.g., "4 of 4 channels qualified offers successfully. 3 orders created. 1 order for MC_ADVSR channel failed — no offers qualified for this vehicle configuration.")
- Per-task detail: task name, status, duration, inputs used, outputs captured, assertion results
- For failed tasks: error details, response payload excerpts, suggested investigation steps
- If OutputDefinition is specified in the SKILL.md: formatted summary table/report as defined

---

### 4.4 Skills Favorites (FR-FAV)

**FR-FAV-001: Favorite / Unfavorite a Skill**

Users can toggle a star/favorite icon on any skill from: the Skills Definition library view, the Execution skill selection dropdown, or the Favorites page itself.

Favorites are per-user and persist across sessions.

**FR-FAV-002: Favorites Page**

Displays the user's favorited skills as cards with: skill name, description, last executed date and result, and a prominent "Run" button that navigates to Execution with the skill pre-selected.

This page is designed for daily-use workflows where a business user runs the same 3-5 skills regularly.

---

### 4.5 Past Executions (FR-HIST)

**FR-HIST-001: Execution History List**

Display a searchable, filterable table of all past execution runs.

Columns: Execution ID, Skill Name, Executed By, Environment, Start Time, End Time, Duration, Status (Passed/Failed/Running/Queued), Summary.

**FR-HIST-002: Search and Filters**

Filters available:

- Date range: start date and end date pickers
- Skill definition: dropdown/typeahead search
- Status: Passed, Failed, Running, Queued, All
- Executed by: user selector (for team visibility)
- Environment: dev, staging, production
- Execution ID: exact match search

Filters are combinable (AND logic). Results are paginated and sortable by any column.

**FR-HIST-003: Execution Detail View**

Clicking on an execution row opens the full detail view showing: all information from FR-EXE-007 (results, per-task details, AI summary), the input criteria used for this run, the SKILL.md version that was executed, and option to re-run with same criteria or modified criteria.

**FR-HIST-004: Export Results**

Users can export execution results as: JSON (for programmatic consumption), PDF report (for sharing/archival), or Excel (for batch run results with one row per test scenario).

---

### 4.6 Service Registry — Admin (FR-REG)

**FR-REG-001: Service Registration**

Administrators can register a new service with: service name and description, base URL per environment, JWT Token Server URL, Client ID and Client Secret (encrypted at rest), and Swagger/OpenAPI specification (file upload or URL).

**FR-REG-002: Service Management**

View, edit, and deactivate registered services. Test connectivity to a service (health check). View which skills reference a given service.

**FR-REG-003: Credential Management**

Credentials are stored securely (encrypted at rest, never displayed in full in UI). Support for credential rotation without affecting skill definitions. Audit log of credential access.

---

## 5. AI Execution Engine

### 5.1 Execution Flow

1. **Load**: Read the SKILL.md from the skill's stored package
2. **Parse**: Extract metadata, UICriteria, WorkflowDefinition, OutputDefinition, and script references
3. **Resolve**: Map service references in WorkflowDefinition to Service Registry entries; load connection details and credentials
4. **Contextualize**: Merge user-provided input criteria with the workflow; resolve variable placeholders
5. **Authenticate**: Obtain JWT tokens for each referenced service via the token server using registered client credentials
6. **Execute**: Process tasks in sequence:
   - For each task, construct the API request based on the service operation, input mappings, and captured variables from prior tasks
   - Handle loop constructs (fan-out): iterate over collections as defined (e.g., for each channel, for each offer)
   - Handle optional tasks: skip if the condition is not met
   - Handle wait/poll constructs: implement retry with timeout for async operations
   - If a supporting script is referenced for the task, delegate execution to the script in a sandboxed container
7. **Assert**: Evaluate each task's assertions against the actual API responses
8. **Report**: Generate per-task results and an overall AI-interpreted business summary
9. **Store**: Persist execution record (inputs, outputs, assertions, status, timestamps) for history

### 5.2 AI Context Strategy

When invoking the AI execution engine, the following context is provided:

- The full SKILL.md content
- The resolved service details (endpoint URLs, operation specifications from Swagger) — summarized, not full Swagger files
- The user's input criteria
- The execution state (results from completed tasks, variables captured)

For large service registries, the platform uses a two-pass approach:
1. First pass: AI identifies which services are referenced in the SKILL.md
2. Second pass: only the relevant service details are loaded into context

### 5.3 Variable Resolution

Variables flow between tasks using a context object maintained throughout execution.

Naming convention: `{TaskN.field_name}` or `{task_name.field_name}`.

The context object accumulates outputs from each completed task, making them available to all subsequent tasks.

### 5.4 Error Handling

- **API errors**: Captured with full response details; task marked as failed; subsequent dependent tasks are skipped; independent tasks continue
- **Authentication errors**: Retry token acquisition once; if failed, halt execution with clear error
- **Timeout errors**: For wait/poll tasks, report timeout with last polled state
- **Script errors**: Capture stderr and exit code; task marked as failed
- **AI interpretation errors**: If the AI cannot interpret a workflow step, flag the task as "Unresolvable" with details for the skill author

### 5.5 Sandboxed Script Execution

When a skill includes supporting scripts (.sh, .py, .js), the platform executes them in a sandboxed environment:

- Docker container per execution (isolated filesystem, network access to registered services only)
- Skill files mounted read-only
- Input criteria passed via environment variables or a mounted config.json
- Script outputs captured from stdout (structured JSON expected) and result files
- Execution timeout enforced (configurable per task, default 5 minutes)
- Container torn down after execution

---

## 6. Technical Architecture

### 6.1 System Components

| Component | Technology Options | Purpose |
|---|---|---|
| Frontend | React + TypeScript | SPA for all user-facing screens |
| Backend API | Java Spring Boot / Node.js / Python FastAPI | REST API serving the frontend; manages skills, executions, registry |
| AI Engine | Anthropic Claude API (Opus/Sonnet) / Claude Code CLI | Reads SKILL.md, orchestrates execution |
| Workflow Engine | Temporal (Java/Go/Python/TypeScript SDK) | Hardened execution path for deterministic skills |
| Skill Storage | Local filesystem (MVP) / AWS S3 (production) | Stores skill packages (SKILL.md + supporting files) |
| Credential Store | AWS Secrets Manager / HashiCorp Vault / Encrypted DB | Securely stores JWT client credentials |
| Database | PostgreSQL | Stores service registry, skill metadata, execution records, user preferences |
| Message Queue | Apache Kafka / AWS SQS | Async execution job queue |
| Event Integration | Azure EventHub SDK | For skills that require event listening |
| Script Runtime | Docker | Sandboxed execution of skill scripts |
| Monitoring | Prometheus + Grafana / CloudWatch | Platform and execution monitoring |

### 6.2 Deployment Architecture

**MVP / Phase 1**: Single-server deployment with local filesystem storage, embedded database, and direct AI API calls. Suitable for team-scale usage (10-50 users).

**Production / Phase 2**: Cloud-native deployment on AWS/Azure with S3 storage, RDS PostgreSQL, ECS/EKS for script execution containers, Secrets Manager for credentials, and auto-scaling for concurrent executions.

### 6.3 API Design

The backend exposes RESTful APIs consumed by the frontend:

**Skills APIs**

- `POST /api/skills` — Upload a new skill (multipart: zip/tar file)
- `GET /api/skills` — List all skills (with search, filter, pagination)
- `GET /api/skills/{id}` — Get skill details and metadata
- `GET /api/skills/{id}/versions` — List versions of a skill
- `PUT /api/skills/{id}` — Update skill (upload new version)
- `DELETE /api/skills/{id}` — Archive or delete a skill
- `POST /api/skills/{id}/favorite` — Toggle favorite status
- `GET /api/skills/favorites` — Get user's favorited skills

**Execution APIs**

- `POST /api/executions` — Initiate a skill execution (body: skill ID, criteria, environment)
- `GET /api/executions` — List executions (with search, filter, pagination)
- `GET /api/executions/{id}` — Get execution details and results
- `GET /api/executions/{id}/stream` — SSE endpoint for real-time execution progress
- `POST /api/executions/{id}/cancel` — Cancel a running execution
- `POST /api/executions/{id}/rerun` — Re-run with same or modified criteria

**Service Registry APIs (Admin)**

- `POST /api/services` — Register a new service
- `GET /api/services` — List all registered services
- `GET /api/services/{id}` — Get service details
- `PUT /api/services/{id}` — Update service configuration
- `DELETE /api/services/{id}` — Deactivate a service
- `POST /api/services/{id}/health` — Test service connectivity

**Authentication/User APIs**

- Standard OAuth2/OIDC integration for user authentication
- `GET /api/users/me` — Current user profile and preferences

### 6.4 Data Model (Core Entities)

**Skill**

| Field | Type | Description |
|---|---|---|
| id | UUID | Primary key |
| name | String | Skill name from metadata |
| description | String | Skill description from metadata |
| version | String | Semantic version |
| author | String | Author name |
| tags | String[] | Searchable tags |
| execution_mode | Enum | AI or WORKFLOW |
| storage_path | String | S3 path or local path to skill package |
| ui_criteria_type | Enum | HTML, EXCEL, BOTH |
| ui_criteria_fields | JSON | Parsed field definitions from UICriteria |
| task_count | Integer | Number of tasks in WorkflowDefinition |
| created_at | Timestamp | Upload timestamp |
| updated_at | Timestamp | Last update timestamp |
| status | Enum | ACTIVE, ARCHIVED, DELETED |

**Execution**

| Field | Type | Description |
|---|---|---|
| id | UUID | Execution ID |
| skill_id | UUID | FK to Skill |
| skill_version | String | Version executed |
| executed_by | UUID | FK to User |
| environment | Enum | DEV, STAGING, PRODUCTION |
| input_criteria | JSON | User-provided criteria |
| status | Enum | QUEUED, RUNNING, COMPLETED, FAILED, CANCELLED |
| start_time | Timestamp | Execution start |
| end_time | Timestamp | Execution end |
| result_summary | Text | AI-generated business summary |
| task_results | JSON | Per-task results array |
| overall_pass | Boolean | Overall pass/fail |

**Service**

| Field | Type | Description |
|---|---|---|
| id | UUID | Primary key |
| name | String | Service name (referenced in SKILL.md) |
| description | String | Service description |
| environments | JSON | Map of env → { base_url, token_url, client_id_ref, client_secret_ref } |
| swagger_spec | JSON | Parsed OpenAPI spec |
| status | Enum | ACTIVE, INACTIVE |

**Favorite**

| Field | Type | Description |
|---|---|---|
| user_id | UUID | FK to User |
| skill_id | UUID | FK to Skill |
| created_at | Timestamp | When favorited |

---

## 7. SKILL.md Specification Reference

### 7.1 File Format

The SKILL.md file uses a combination of YAML front matter (for metadata) and XML-tagged sections (for machine-parseable content: UICriteria, WorkflowDefinition, OutputDefinition, Scripts). Narrative content between sections is treated as documentation and provided to the AI as context.

### 7.2 Metadata (YAML Front Matter)

Required fields: name, version, description.
Optional fields: author, tags, execution_mode (default: ai), timeout (default: 30m).

### 7.3 UICriteria Section

Required. Defines input collection mode and field definitions.

Supported field types: text, number, select, multi-select, checkbox, date, textarea.

Field properties: label (display name), type, options (for select/multi-select), default, required (boolean), placeholder, helpText, validation (optional regex or min/max).

### 7.4 WorkflowDefinition Section

Required. Contains one or more Task elements.

Task attributes: id (unique integer), name (human-readable), loop (optional — iteration expression), optional (boolean — skip if condition not met), depends_on (optional — explicit dependency if not sequential).

Task body: free-form structured natural language including Service reference, Operation name, Inputs mapping, Capture fields, Assert conditions (with optional conditional assertions using "Assert if {field}:").

### 7.5 OutputDefinition Section

Optional. Describes the desired format and content of the execution results report. Written in natural language for the AI to interpret when generating the results summary.

### 7.6 Scripts Section

Optional. Maps tasks to supporting script files included in the skill package. Script attributes: task (task ID), file (filename), language (python/bash/node).

---

## 8. User Interface Specifications

### 8.1 Design Principles

- **Enterprise SaaS aesthetic**: Clean, professional, information-dense but not cluttered
- **Progressive disclosure**: Show essential information first, details on demand
- **Real-time feedback**: Execution progress visible at all times
- **Accessibility**: WCAG 2.1 AA compliance
- **Responsive**: Desktop-first with tablet support

### 8.2 Color and Theme

| Element | Color | Usage |
|---|---|---|
| Background | #0B0E14 | Main background |
| Surface | #111620 | Cards, panels |
| Border | #1E2738 | Dividers, card borders |
| Text Primary | #E2E8F0 | Headings, body text |
| Text Muted | #64748B | Secondary text, labels |
| Accent/Primary | #3B82F6 | Buttons, links, active states |
| Success | #10B981 | Passed status, positive indicators |
| Failure | #EF4444 | Failed status, errors |
| Warning | #F59E0B | Pending, warnings |
| Running | #8B5CF6 | In-progress indicators |

### 8.3 Screen Specifications

**Skills Definition — Library View**

- Header: "Skills Library" with search bar and "Upload Skill" button
- Body: Grid or list view (toggleable) of skill cards
- Each card: name, description snippet, tags as chips, version badge, author, favorite star, last run status indicator
- Click card → detail panel or detail page

**Skills Definition — Upload Flow**

- Step 1: Drag-and-drop or file browser to upload SKILL.md or zip/tar
- Step 2: Platform parses and shows preview (metadata, criteria fields, workflow tasks, scripts detected, validation results)
- Step 3: Author confirms and publishes
- Error state: validation errors displayed inline with guidance on how to fix

**Skills Execution — Main View**

- Top: Skill selector (searchable dropdown with favorites grouped at top)
- Middle: Dynamic criteria form (rendered from UICriteria) or Excel upload zone
- Middle: Environment selector (dev/staging/prod toggle)
- Bottom: "Run Skill" button (prominent, primary color)
- Post-execution: inline progress view with per-task status indicators, live log, and completion summary

**Skills Execution — Progress View**

- Vertical task pipeline visualization (Task 1 → Task 2 → Task 3 → ...)
- Each task node shows: name, status icon (pending/running/passed/failed), duration, and expandable detail
- Fan-out tasks (loops) shown as branching sub-nodes
- Live log panel (collapsible) showing raw execution output

**Favorites Page**

- Grid of favorited skill cards with prominent "Run" action button
- Last execution result badge on each card (green check, red X, or "Never run")
- "Run" button navigates to Execution with skill pre-selected

**Past Executions — List View**

- Filter bar: date range, skill selector, status, user, environment, execution ID
- Results table with sortable columns: Execution ID, Skill Name, User, Environment, Start Time, Duration, Status
- Status shown as colored badge (Passed=green, Failed=red, Running=purple, Queued=yellow)
- Click row → detail view

**Past Executions — Detail View**

- Header: Skill name, execution ID, status badge, duration, user, environment
- AI Summary section: business-language interpretation of results
- Task breakdown: expandable accordion for each task showing inputs, outputs, assertions (with pass/fail per assertion), error details if failed
- Input criteria used: collapsible section showing what the user provided
- Actions: "Re-run" (opens Execution with pre-filled criteria), "Export" (JSON/PDF/Excel)

---

## 9. Non-Functional Requirements

### 9.1 Performance

- Skill upload and parsing: < 5 seconds for packages up to 50MB
- Dynamic criteria rendering: < 1 second after skill selection
- Execution initiation: < 2 seconds from "Run" click to queued status
- Past Executions search: < 3 seconds for filtered queries across 100K+ records
- Concurrent executions: support 20+ simultaneous skill executions (Phase 1), 100+ (Phase 2)

### 9.2 Security

- All API credentials encrypted at rest (AES-256) and in transit (TLS 1.3)
- No credentials stored in SKILL.md files (validation enforced on upload)
- Role-based access control: Admin (full access), Author (create/edit skills), Executor (run skills, view results), Viewer (view results only)
- Script execution sandboxed in isolated containers with no access to platform internals
- Audit logging for all credential access, skill modifications, and execution initiations

### 9.3 Reliability

- Execution state persisted at each task boundary — resumable after platform restart
- Failed task does not halt entire execution unless explicitly dependent
- Automatic retry for transient API failures (configurable: max retries, backoff)
- Execution timeout enforced at task level and overall skill level

### 9.4 Scalability

- Skill storage: S3 (virtually unlimited)
- Execution records: partitioned by date in PostgreSQL
- Script execution: containerized, horizontally scalable via ECS/K8s
- AI API calls: rate-limited with queuing to handle burst execution requests

---

## 10. Phase Plan

### Phase 1 — MVP (8-12 weeks)

**Goal**: Demonstrate the core value proposition end-to-end.

Scope:
- Left nav with Skills Definition, Execution, Favorites, Past Executions
- Skill upload (SKILL.md + zip) with validation and preview
- Skill library with search
- Skill execution with dynamic HTML criteria form
- AI-interpreted execution using Anthropic Claude API
- Real-time execution progress view
- Execution results with AI-generated summary
- Past Executions with search and filters
- Favorites toggle and favorites page
- Service Registry admin UI (basic CRUD)
- Single environment support (one set of credentials)

Technology: React + Java Spring Boot + PostgreSQL + Local filesystem + Anthropic Claude API.

### Phase 2 — Production Hardening (6-8 weeks)

Scope:
- Excel criteria support (upload, template download, batch execution)
- Multi-environment support (dev/staging/prod)
- Temporal workflow integration for hardened execution path
- Sandboxed script execution (Docker containers)
- Export results (JSON, PDF, Excel)
- Skill versioning with version history UI
- In-browser SKILL.md editor
- Enhanced error handling and retry configuration
- AWS S3 skill storage
- AWS Secrets Manager integration

### Phase 3 — Scale and Intelligence (6-8 weeks)

Scope:
- Dashboard with execution metrics, trends, pass rates
- AI-assisted skill authoring (conversational skill creation)
- Skill recommendations (based on usage patterns)
- Scheduled execution (cron-based regression runs)
- Team workspaces and RBAC
- Notification integrations (email, Slack, Teams)
- API for external CI/CD integration (trigger skills from Jenkins/GitHub Actions)
- EventHub integration module

### Phase 4 — Enterprise (Ongoing)

Scope:
- Multi-tenancy
- SSO/SAML integration
- Compliance and audit reporting
- Custom branding
- SLA monitoring and alerting
- Skill marketplace (share skills across teams/organizations)

---

## 11. Success Metrics

| Metric | Target (6 months post-launch) |
|---|---|
| Skills authored | 50+ unique skill definitions |
| Monthly executions | 1,000+ skill runs per month |
| Business user adoption | 80%+ of test executions initiated by non-QA users |
| AI execution reliability | 95%+ successful interpretation rate |
| Mean time to create a skill | < 30 minutes for a standard e2e scenario |
| Mean time to execute | < 2 minutes for a typical 5-7 task skill |
| User satisfaction (NPS) | 40+ |

---

## 12. Open Questions and Decisions

| # | Question | Options | Decision |
|---|---|---|---|
| 1 | Primary backend language | Java Spring Boot (team familiarity) vs Node.js (frontend alignment) vs Python (AI ecosystem) | TBD — recommend Java Spring Boot given enterprise context |
| 2 | AI model for execution | Claude Opus 4.6 (highest accuracy) vs Claude Sonnet 4.5 (faster, cheaper) | Start with Sonnet for speed; escalate to Opus for complex skills |
| 3 | Skill storage for MVP | Local filesystem vs S3 from day one | Local filesystem for MVP; migrate to S3 in Phase 2 |
| 4 | SKILL.md authoring assistance | Build AI-assisted authoring in Phase 1 or defer to Phase 3 | Phase 3 — focus MVP on execution |
| 5 | CI/CD integration | Build trigger API in Phase 2 or Phase 3 | Phase 3 |
| 6 | Dependent field logic in UICriteria | Support conditional fields (e.g., state/province based on country) in Phase 1 or Phase 2 | Phase 2 — flat independent fields for MVP |

---

## 13. Glossary

| Term | Definition |
|---|---|
| SKILL.md | A markdown file following the Anthropic Skills paradigm that serves as both documentation and executable instruction set for a test scenario |
| Skill Definition | A packaged skill consisting of SKILL.md and optional supporting files (.sh, .py, .js) |
| Skill Execution | A single run of a skill definition with specific input criteria against a target environment |
| Service Registry | Platform-managed catalog of all enterprise APIs with connection details and credentials |
| UICriteria | Section of SKILL.md that defines how input criteria are collected from the executor |
| WorkflowDefinition | Section of SKILL.md that defines the ordered sequence of API operations to execute |
| Task | A single step in a WorkflowDefinition representing one API operation or script execution |
| Fan-out | When a task iterates over a collection (e.g., testing each channel), producing multiple parallel sub-executions |
| Hardened Execution | A skill implemented as a Temporal workflow for 100% deterministic reliability |
| TDI | Test Data Initialization — service that generates test customer accounts and vehicles |
| DSS | Digital Sales Services — service that onboards customers/vehicles for offer qualification |

---

## 14. Appendix

### A. Example SKILL.md — Complete Reference

See Section 3.3 for the fully worked example of "Test US 2025 GMC Offers and Orders" skill definition.

### B. Service Registry — Initial Services

| Service | Operations | Auth |
|---|---|---|
| TDI | createVehicle, createCustomer, createAccount | JWT (client credentials) |
| DSS | onboardCustomerVehicle, getEnrollmentStatus | JWT (client credentials) |
| Offers API | getQualifiedOffers, getOfferDetails | JWT (client credentials) |
| Orders API | createQuote, createOrder, getOrders, getOrderDetails | JWT (client credentials) |
| EventHub | listenForEvents, publishEvent | Connection string + SAS |

### C. Related References

- Anthropic SKILL.md paradigm: https://docs.anthropic.com
- Temporal workflow framework: https://temporal.io
- OpenAPI Specification: https://swagger.io/specification/

---

**End of Document**
