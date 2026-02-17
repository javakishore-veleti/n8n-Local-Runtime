# SSIUV — Sales Services Intelligent Unified Validations

## Complete Product & Architecture Specification

**Purpose of this document:** This is the single source of truth for SSIUV. Use it to generate architecture diagrams, code, presentations, or any deliverable. It captures every design decision, domain detail, API signature, tech stack choice, and execution model discussed during product design.

---

## 1. WHAT IS SSIUV

SSIUV is an AI-powered test validation platform for GM's digital sales services. Instead of writing traditional test scripts, QA engineers and business users write human-readable SKILL.md files that describe what to test. The AI reads the skill, calls real APIs in sequence, accumulates responses as context (RAG pattern), generates assertions, and produces human-readable test reports.

### The Problem It Solves

- GM's digital sales pipeline (TDI → DSS Catalog → Offers → Orders → EventHub) has dozens of APIs across multiple microservices
- Traditional test automation requires developers to write and maintain brittle scripts for every scenario
- When APIs change, scripts break silently — tests pass but don't actually validate the right things
- QA teams spend weeks writing test harnesses instead of thinking about what to test

### The SSIUV Solution

- **SKILL.md files** describe test scenarios in structured natural language — what to call, in what order, what to assert
- **AI Execution Engine** reads the skill, calls APIs via Service Registry or MCP servers, accumulates real responses as context
- **GuardRails** (optional) — a second-pass AI validation that re-checks all assertions against raw API responses
- **Temporal Workflows** (5% of cases) — for mission-critical deterministic execution with exactly-once guarantees

---

## 2. DOMAIN — GM DIGITAL SALES SERVICES

### Service Pipeline (order of execution)

```
TDI (Test Data Injection) → DSS Catalog → Offers → Orders → EventHub
```

1. **TDI** — Creates test vehicles and customer accounts. Entry point for all test data.
2. **DSS Catalog (sales-catalog-retail)** — Product catalog. Returns vehicles, features, packages, pricing for a given country/locale.
3. **Offers (sales-offer-retail)** — Returns available offers (incentives, rebates, financing) for a specific VIN + account + channel.
4. **Orders (sales-order)** — Creates quotes, converts to orders, tracks fulfillment status.
5. **EventHub** — Async event bus. Publishes events when orders change state. Skills can listen for specific events.

### Domain Values (real, use these exactly)

**Countries:** `US` | `CA` | `MX`

**Locales:** `en_US` | `es_MX` | `fr_CA`

**Sales Channels:** `MC_GMOC` | `MC_ADVSR` | `MC_ONECRM` | `MC_BATCH` | `MC_OLE` | `MC_REWARDS` | `MC_GUARDIAN`

**Sales Segments:** `FIRST_PURCHASE` | `SALES`

**Vehicle Makes:** Chevrolet, GMC, Buick, Cadillac

### API Signatures (real method signatures from the Spring Boot microservices)

**sales-catalog-retail:**
```
@Tool getProducts(country, locale, includeFeatures, includeProductsWithCategories) → List<Product>
  country: US | CA | MX
  locale: en_US | es_MX | fr_CA
```

**sales-offer-retail:**
```
@Tool getOffers(account, vin, channel, salesSegment) → List<Offer>
  channel: MC_GMOC | MC_ADVSR | MC_ONECRM | MC_BATCH | MC_OLE | MC_REWARDS | MC_GUARDIAN
  salesSegment: FIRST_PURCHASE | SALES
```

**sales-order:**
```
@Tool getOrders(vin, account, channel, country) → List<Order>
@Tool createQuote(offerId, vin, accountNumber) → Quote
@Tool createOrder(quoteId) → Order
@Tool getOrderDetails(orderId) → OrderDetail
```

**TDI:**
```
@Tool createVehicle(year, make, model, country) → VehicleRecord
@Tool createCustomerAccount(vehicleId) → Account
  country: US | CA | MX
```

---

## 3. ARCHITECTURE — THREE LAYERS

### Layer 1: Presentation (React Frontend)
- React 18+ SPA with TypeScript
- Skill selection dropdown, dynamic input criteria form, execution controls
- GuardRails toggle checkbox (optional, adds ~15s)
- Real-time execution progress via WebSocket
- Past executions history, favorites

### Layer 2: Orchestration (Spring Boot Backend)
- Java Spring Boot 3.x, JDK 17
- REST API + WebSocket for real-time updates
- Service Registry — stores API endpoints, client credentials, Swagger specs
- AI Execution Engine (see Section 5 for two-phase approach)
- Temporal client for workflow dispatch (5% of executions)
- PostgreSQL for skill metadata, execution history, user data
- S3 for SKILL.md file storage

### Layer 3: Enterprise APIs
- Existing GM microservices (TDI, DSS Catalog, Offers, Orders, EventHub)
- Each protected by OAuth2 — Client ID + Client Secret → JWT → Bearer token
- Can be called directly via REST (current) or via MCP servers (future)

---

## 4. SKILL.MD FORMAT

A SKILL.md is a structured markdown file that the AI reads as instructions. It is NOT code — it is structured natural language.

### Example SKILL.md Structure

```xml
<SkillDefinition>
  name: Test US 2025 GMC Offers and Orders
  version: 1.2
  execution_mode: ai          <!-- ai | temporal | hybrid -->
  model: claude-sonnet-4-5
  estimated_duration: 45s
</SkillDefinition>

<UICriteria>
  <Fields>
    "modelYear":    { "type": "text",         "required": true,  "default": "2025" }
    "make":         { "type": "text",         "required": true  }
    "model":        { "type": "text",         "required": true  }
    "country":      { "type": "select",       "options": ["US","CA","MX"] }
    "salesSegment": { "type": "select",       "options": ["FIRST_PURCHASE","SALES"] }
    "locale":       { "type": "select",       "options": ["en_US","es_MX","fr_CA"] }
    "channels":     { "type": "multi-select", "options": ["MC_GMOC","MC_ONECRM","MC_WEB_APP","MC_ADVSR"] }
  </Fields>
</UICriteria>

<Activities>
  <Activity id="1" name="createVehicle">
    service: TDI
    method: POST /api/vehicles
    body: { year: {modelYear}, make: {make}, model: {model}, country: {country} }
    save: { vin → $vin, accountNumber → $account }
  </Activity>

  <Activity id="2" name="getProducts">
    service: CatalogAPI
    method: GET /api/products?country={country}&locale={locale}
    assert: response.products.length > 0
    assert: response.products[0].make == {make}
  </Activity>

  <Activity id="3" name="getOffers" loop="for each channel in {channels}">
    service: OffersAPI
    method: GET /api/offers?account=$account&vin=$vin&channel={channel}&salesSegment={salesSegment}
    assert: response.offers is not empty
    assert: each offer has validFrom and validTo dates
  </Activity>

  <Activity id="4" name="getOrders">
    service: OrdersAPI
    method: GET /api/orders?vin=$vin&account=$account
    assert: order count matches expected
    optional: EventHub listen for ORDER_CREATED event
  </Activity>
</Activities>

<OutputDefinition>
  Generate summary table: VIN, account, offer count per channel, order status
  Flag any channel with zero offers as WARNING
  Include response times for each API call
</OutputDefinition>
```

### Key SKILL.md Concepts

- **UICriteria** — Defines the dynamic form fields shown in the UI. The React frontend reads this and renders the input form automatically.
- **Activities** — Ordered list of API calls. Each can reference outputs from previous activities using `$variable` syntax.
- **Assertions** — Natural language or structured assertions that the AI evaluates against real responses.
- **execution_mode** — Determines routing: `ai` (95%) goes to AI engine, `temporal` (5%) goes to Temporal workflows.
- **loop** — An activity can iterate over multi-select values (e.g., test each channel separately).

---

## 5. AI EXECUTION ENGINE — TWO-PHASE APPROACH

### Short-Term: CLI Subprocess (Day 1 — No SDK License Needed)

Spring Boot spawns `claude` CLI or `copilot` CLI as a subprocess via `ProcessBuilder`. The CLI is pointed at the SKILLS folder as its working directory and reads SKILL.md files as context.

```java
// Spring Boot — SkillExecutionService.java
ProcessBuilder pb = new ProcessBuilder(
    "claude", "--print",
    "--model", "sonnet",
    "--mcp-config", "/opt/ssiuv/mcp.json"
);
pb.directory(new File("/opt/ssiuv/skills/"));
pb.environment().put("ANTHROPIC_API_KEY", apiKey);

Process proc = pb.start();
proc.getOutputStream().write(prompt.getBytes());
String result = new String(proc.getInputStream().readAllBytes());
```

- Multiple CLI processes run in parallel — one per skill execution
- Thread pool manages lifecycle (~10-20 concurrent sessions)
- MCP servers configured in CLI config — AI calls APIs through MCP tools
- Read stdout line by line for streaming progress
- License: Uses existing GitHub Copilot Enterprise or Claude CLI (free/Max plan)

### Long-Term: Anthropic Java SDK (Requires Enterprise License)

Direct API integration via Anthropic Java SDK or Spring AI Anthropic starter.

```java
// Spring Boot — SkillExecutionService.java
var response = anthropicClient.messages()
    .create(MessageCreateParams.builder()
        .model("claude-sonnet-4-5-20250929")
        .system(skillMdContent)
        .addUserMessage(userCriteria)
        .tools(mcpToolDefinitions)
        .maxTokens(8192)
        .build());
```

- Native async — CompletableFuture / WebFlux concurrency
- Streaming responses — real-time SSE to the UI
- Full control: system prompts, tool definitions, temperature, structured JSON output
- Hundreds of concurrent requests (vs ~20 for CLI approach)

### Migration Path

Both approaches use the same `SkillExecutionService` interface. When IT approves the Anthropic SDK license, swap the CLI implementation for the SDK implementation. Zero changes to SKILL.md files, UI, Service Registry, or any other component.

### Comparison

| Aspect               | CLI Subprocess (Short-term)              | Anthropic SDK (Long-term)                |
|-----------------------|------------------------------------------|------------------------------------------|
| License needed        | None — existing Copilot Enterprise       | Anthropic API Enterprise license         |
| Concurrency           | Thread pool ~10-20 concurrent            | Async HTTP — hundreds concurrent         |
| Streaming             | Read stdout line by line                 | Native SSE streaming to UI               |
| Tool calling          | Via MCP config on CLI                    | Native function/tool calling API         |
| SKILLS folder         | CLI working directory = skills path      | SKILL.md loaded as system prompt         |
| Migration effort      | Start building immediately               | Swap ProcessBuilder → SDK client         |

---

## 6. RAG PATTERN — REAL API RESPONSES AS CONTEXT

During execution, every API response is stored and fed back into the AI's context window. The AI accumulates real data from live systems — making decisions based on actual responses, not assumptions.

### Flow

```
1. Load SKILL.md → Send as system prompt + user criteria
2. Call API (Task 1) → TDI: createVehicle → gets vin, account
3. Response → Context → Full response added to AI context (RAG)
4. Call API (Task 2) → Uses real vin from Task 1 → getOffers
5. Accumulate → Context grows with every real response
```

Traditional tools use fixed variable passing. SSIUV's AI sees full context of all prior responses — adapts to unexpected formats, makes intelligent decisions about edge cases, generates human-readable summaries because it understands actual data.

---

## 7. GUARDRAILS — SECOND-PASS VALIDATION (OPTIONAL)

After all tasks complete, a separate AI call re-validates every assertion against raw API responses. This is a "second opinion" that catches hallucinations.

### How It Works

1. Execution completes normally (all tasks done, assertions generated)
2. GuardRails collects every raw API response from the execution
3. Makes a separate Claude API call with: all raw responses + SKILL.md assertions
4. AI re-evaluates every assertion independently against ground truth
5. If disagrees → result flagged for human review

### How Users Enable It

- Checkbox on execution form next to Run button: `☑ GuardRails Enabled`
- When checked, adds ~15 seconds for second AI validation pass
- When to use: High-stakes validations, first run of new skill, batch runs, regulatory checks
- When to skip: Routine re-runs, time-sensitive, simple single-step skills

### Flow

```
Execution Completes → ⛨ GuardRails Pass → ✅ Validated (agrees)
                                         → ⚠️ Flagged (disagrees → human review)
```

---

## 8. TEMPORAL WORKFLOWS (5% OF EXECUTIONS)

For mission-critical flows that need deterministic execution, exactly-once guarantees, and durable state.

### When to Use Temporal vs AI

| Use Temporal When...                    | Use AI When...                          |
|-----------------------------------------|-----------------------------------------|
| Financial transactions                  | Exploratory testing                     |
| Regulatory compliance                   | Ad-hoc validations                      |
| Exact retry/compensation needed         | Cross-service discovery                 |
| Audit trail required                    | Dynamic assertions                      |
| Same flow runs thousands of times       | New or changing scenarios               |

### Development Flow

1. Write a workflow-specific SKILL.md with typed Activities section
2. Open IntelliJ → Copilot Chat → select Claude Opus 4.6
3. Paste the SKILL.md → ask Claude to generate Temporal Java workflow
4. Claude generates: Workflow interface, Activity interface, Workflow implementation, Activity implementations
5. Developer reviews, tests, deploys to Temporal workers

### Workflow SKILL.md Template (different from AI SKILL.md)

```yaml
SkillDefinition:
  name: Hardened US Offer Validation
  execution_mode: temporal
  temporal:
    taskQueue: ssiuv-offer-validation
    workflowId_prefix: offer-val
    timeout: PT5M
    retryPolicy:
      maxAttempts: 3
      backoffCoefficient: 2.0

Activities:
  - name: createVehicle
    service: TDI
    method: POST /api/vehicles
    input: { year, make, model, country }
    output: { vin: String, accountNumber: String }
    retryPolicy: { maxAttempts: 3, initialInterval: PT1S }

  - name: getOffers
    service: OffersAPI
    method: GET /api/offers
    input: { account: $createVehicle.accountNumber, vin: $createVehicle.vin, channel, salesSegment }
    output: { offers: List<Offer> }
    retryPolicy: { maxAttempts: 5, initialInterval: PT2S }

  - name: validateOffers
    type: assertion
    input: { offers: $getOffers.offers }
    rules:
      - offers.size() > 0
      - each offer.validFrom < today < offer.validTo
      - no duplicate offer IDs

Compensation:
  - on: createVehicle.failure → log and alert
  - on: getOffers.timeout → retry with exponential backoff, then skip channel
```

---

## 9. MCP SERVERS — SPRING BOOT → SPRING AI

### What Are MCP Servers

Model Context Protocol (MCP) servers expose existing API methods as typed tools that AI can call directly. Instead of the AI reading Swagger specs and constructing HTTP requests, it sees typed functions like `getOffers(account, vin, channel, salesSegment)`.

### How to Convert (minimal code change)

**Before (existing Spring Boot service):**
```java
@RestController
public class OfferController {
    @GetMapping("/api/offers")
    public List<Offer> getOffers(
        @RequestParam String account, @RequestParam String vin,
        @RequestParam String channel, @RequestParam String salesSegment) {
        return offerRepository.getOffers(account, vin, channel, salesSegment);
    }
}
```

**After (add Spring AI MCP annotation):**
```java
@RestController
public class OfferController {
    @GetMapping("/api/offers")
    @Tool(description = "Get retail offers for a vehicle by account, VIN, sales channel, and segment")
    public List<Offer> getOffers(
        @RequestParam String account, @RequestParam String vin,
        @RequestParam String channel, @RequestParam String salesSegment) {
        return offerRepository.getOffers(account, vin, channel, salesSegment);
    }
}
```

The `@Tool` annotation exposes the method as an MCP tool. Spring AI auto-generates the tool schema from the method signature. The existing REST API continues to work alongside MCP. No changes to business logic.

### MCP Server List

| MCP Server           | Service              | Key Tools                                  |
|----------------------|----------------------|--------------------------------------------|
| sales-catalog-retail | DSS Catalog          | getProducts(country, locale, ...)          |
| sales-offer-retail   | Offers               | getOffers(account, vin, channel, segment)  |
| sales-order          | Orders               | getOrders, createQuote, createOrder        |
| tdi-service          | TDI                  | createVehicle, createCustomerAccount       |

---

## 10. MCP IN PRACTICE — CREDENTIALS & PERSONAS

### Prerequisites: Environment Variables on Each Machine

Before anyone uses MCP servers, each host machine needs service credentials as environment variables. One-time setup per machine per environment.

```bash
# ~/.bashrc or ~/.zshrc or system env vars
# Sales Services — Staging Environment
export SALES_CATALOG_CLIENT_ID="svc-catalog-staging-xxxxx"
export SALES_CATALOG_CLIENT_SECRET="••••••••••••"
export SALES_OFFERS_CLIENT_ID="svc-offers-staging-xxxxx"
export SALES_OFFERS_CLIENT_SECRET="••••••••••••"
export SALES_ORDERS_CLIENT_ID="svc-orders-staging-xxxxx"
export SALES_ORDERS_CLIENT_SECRET="••••••••••••"
export TDI_CLIENT_ID="svc-tdi-staging-xxxxx"
export TDI_CLIENT_SECRET="••••••••••••"
export JWT_TOKEN_URL="https://auth.gm.com/oauth2/token"
export SALES_API_BASE_URL="https://staging-api.sales.gm.com"
```

Where they go: Developer Laptop (onboarding script) | CI/CD Runner (Vault/Secrets Manager) | SSIUV Server (Service Registry)

Each MCP server reads its CLIENT_ID and CLIENT_SECRET from the environment, requests a JWT at startup (auto-refreshes), attaches bearer token to every downstream call. Users never handle tokens directly.

### Three Personas — Three Tools — Same MCP Servers

#### Java Developer — IntelliJ + Copilot Chat

**MCP Setup:**
```
// IntelliJ: Settings → Tools → GitHub Copilot → MCP Servers → Add Server
Name:  sales-offers
URL:   http://localhost:8082/mcp
Auth:  None (server handles JWT)
// Repeat for each MCP server
// Model dropdown → Claude Opus 4.6
```

**Workflow:** Open Copilot Chat → Claude Opus 4.6 → "What offers exist for VIN 1GTEK19T on MC_GMOC?" → Copilot calls sales-offer-retail MCP → MCP authenticates with $SALES_OFFERS_CLIENT_ID → JWT → real API → structured response in chat panel.

**Use cases:** Debug APIs while coding, generate Temporal workflows from live data, verify responses before writing assertions, replace Postman.

#### QA Engineer — VS Code + Copilot

**MCP Setup:**
```json
// .vscode/settings.json
{
  "github.copilot.chat.mcpServers": {
    "sales-catalog": {
      "url": "http://localhost:8081/mcp"
    },
    "sales-offers": {
      "url": "http://localhost:8082/mcp"
    },
    "sales-orders": {
      "url": "http://localhost:8083/mcp"
    }
  }
}
```

**Workflow:** Open Copilot Chat sidebar → "What fields does getProducts return for country=US?" → Copilot calls sales-catalog-retail MCP → live API → QA sees real field names → writes accurate SKILL.md → "Generate OutputDefinition for this" → done.

**Use cases:** Discover API response shapes, generate assertions from live data, validate test data before execution, compare staging vs prod.

#### Business User / Support — Copilot CLI (Terminal)

**MCP Setup:**
```json
// ~/.config/github-copilot/mcp.json
{
  "servers": [
    { "name": "sales-catalog", "url": "http://localhost:8081/mcp" },
    { "name": "sales-offers",  "url": "http://localhost:8082/mcp" },
    { "name": "sales-orders",  "url": "http://localhost:8083/mcp" }
  ]
}
```

**Workflow:** Open terminal → "Check order status for account 12345 in US" → CLI routes to sales-order MCP → $SALES_ORDERS_CLIENT_ID → JWT → getOrders API → "Account 12345 has 3 active orders — 2 CONFIRMED, 1 PENDING" → "Show fulfillment for the PENDING one" → drills in.

**Use cases:** Quick lookups without portals, support investigations, batch status checks, on-call triage.

### End-to-End Flow

```
User Asks (natural language) → GitHub Copilot (selects MCP tool) → MCP Server (env vars → JWT → API) → Enterprise API (processes request) → AI Responds (formats result)
```

The user never constructs HTTP requests, manages JWT tokens, reads Swagger docs, or opens Postman. They ask in English → get answers from live data.

### MCP Deployment Options

| Option             | Description                                                  | Best For              |
|--------------------|--------------------------------------------------------------|-----------------------|
| Local (dev)        | Run on localhost alongside microservice                      | Development, debugging|
| Shared staging     | Deployed as shared service, all devs/QA point to same URLs   | Team consistency      |
| SSIUV embedded     | Run alongside SSIUV backend, AI calls directly — no hop      | Production execution  |

---

## 11. DEVELOPMENT TOOLS

### Enterprise GitHub Copilot — Three Surfaces

**VS Code + Copilot (Everyone):**
- SKILL.md authoring with inline suggestions
- React frontend (TypeScript)
- Python skill scripts
- YAML/JSON config editing
- Quick prototyping & debugging

**IntelliJ + Copilot Chat (Java Developers):**
- Java Spring Boot backend code
- Temporal workflows from SKILL.md
- Chat window → select Claude Opus 4.6 → generate Java
- Spring AI MCP server annotations
- DB migrations & JPA entities

**Copilot CLI (All Developers via Terminal):**
- Git operations & complex commands
- Docker / Kubernetes commands
- Quick database queries
- Shell scripts for CI/CD pipelines

All three run under company's GitHub Copilot Enterprise license. Code stays within company boundaries.

---

## 12. RECOMMENDED TECH STACK

Based on team skills: strong in Java/Spring Boot + PostgreSQL, some Python, some TypeScript/Node.js.

### Backend — Java Spring Boot (Team Strength)
- Spring Boot 3.x: REST, WebSocket, Security
- JDK 17 (LTS): Records, sealed classes
- Spring AI: Claude API integration + MCP server exposure
- Temporal Java SDK: Hardened workflow engine

### Database — PostgreSQL (Team Strength)
- PostgreSQL 15+: JSONB for skill metadata
- Spring Data JPA: ORM + Flyway migrations
- AWS S3: SKILL.md + script storage
- Redis (optional): Execution status cache

### Frontend — React + TypeScript
- React 18+: SPA with React Router
- TypeScript: Type-safe forms & APIs
- Tailwind CSS: Utility-first styling
- Vite: Fast build + HMR

### AI & Scripting
- Anthropic Claude API: Runtime execution (via CLI short-term, SDK long-term)
- Python 3.11+ (optional): Complex skill scripts
- Node.js (optional): JS scripts, EventHub listeners
- Spring AI MCP: Expose APIs as AI tools

**Why this stack:** Plays to team strengths (Java + PostgreSQL, no ramp-up). Spring AI unifies Claude integration and MCP server exposure in same ecosystem. Python/Node are optional — AI handles most logic.

---

## 13. SERVICE REGISTRY

The Service Registry is a database table that stores connection info for every API the platform can call.

### Fields per Service Entry

| Field          | Example                                        |
|----------------|------------------------------------------------|
| service_name   | sales-offer-retail                             |
| base_url       | https://staging-api.sales.gm.com/offers        |
| auth_type      | oauth2_client_credentials                      |
| client_id_ref  | vault:sales-offers-client-id                   |
| client_secret_ref | vault:sales-offers-client-secret            |
| token_url      | https://auth.gm.com/oauth2/token               |
| swagger_url    | https://staging-api.sales.gm.com/offers/v3/api-docs |
| mcp_endpoint   | http://localhost:8082/mcp (if MCP enabled)     |

The AI Execution Engine reads the registry to know where to call, how to authenticate, and what the API shape looks like. When MCP servers are enabled, the AI uses MCP tools instead of constructing REST calls from Swagger.

---

## 14. EXECUTION FLOW — ROUTING DECISION

```
User clicks "Run Skill"
    ↓
Backend reads SKILL.md metadata → checks execution_mode field
    ↓
┌─────────────────────────────┐
│ execution_mode = "ai" (95%) │ → AI Execution Engine (CLI subprocess or SDK)
│                             │   → Reads SKILL.md as system prompt
│                             │   → Calls APIs via MCP or REST
│                             │   → RAG: accumulates responses
│                             │   → Generates assertions + report
│                             │   → Optional: GuardRails second pass
└─────────────────────────────┘
┌─────────────────────────────────┐
│ execution_mode = "temporal" (5%)│ → Temporal Workflow Engine
│                                 │   → Dispatches to task queue
│                                 │   → Typed activities execute APIs
│                                 │   → Deterministic + exactly-once
│                                 │   → Results stored in workflow history
└─────────────────────────────────┘
```

---

## 15. TEST EXECUTION PIPELINE (Data Flow)

A typical end-to-end skill execution flows through:

```
🚗 TDI: Create Vehicle → 👤 TDI: Create Account → 📦 Catalog: Get Products
    → 🏷️ Offers: Get Offers (per channel) → 📋 Orders: Create Quote
    → ✅ Orders: Create Order → 📡 EventHub: Listen for events
```

Each step produces real data that feeds into the next step (RAG pattern). The AI sees the full accumulated context at every step.

---

## 16. USER JOURNEYS

### Business Analyst / QA Engineer
1. Browse skill library or create new SKILL.md
2. Fill input criteria (model year, make, model, country, channels)
3. Toggle GuardRails if needed
4. Click "Run Skill" → watch real-time progress
5. Review results — passed/failed/warnings with AI-generated summaries
6. Save as favorite for re-runs

### Platform Admin
1. Manage Service Registry — add/edit API endpoints, credentials
2. Monitor executions — throughput, failure rates, slow APIs
3. Manage users and permissions
4. Review GuardRails-flagged results

### Developer
1. Write SKILL.md files using VS Code + Copilot (with MCP for live API discovery)
2. For Temporal workflows: use IntelliJ + Copilot Chat + Claude Opus to generate Java
3. Deploy skills to the platform
4. Debug with live API responses via MCP in IDE

---

## 17. UI LAYOUT — SKILLS EXECUTION VIEW

### Left Sidebar Navigation
- ⚡ SSIUV (logo)
- 📊 Dashboard
- **SKILLS** section:
  - 📝 Definition
  - ▶ Execution (active)
  - ⭐ Favorites
  - 📋 Past Executions
- **ADMIN** section:
  - 🔧 Service Registry
  - 👥 Users

### Main Content — Execute Skill Form
- **Select Skill** — Dropdown with skill name + version (e.g., "⭐ Test US 2025 GMC Offers and Orders (v1.2)")
- **Input Criteria** — 3-column grid of dynamic form fields:
  - Model Year*, Make*, Model* (text inputs)
  - Country* (select: US/CA/MX), Sales Segment* (select), Locale (select)
  - Sales Channels* (multi-select chips: MC_GMOC, MC_ONECRM, MC_ADVSR + "Add Channel")
- **Options row** — separated by line:
  - ☑ Validate Tax, ☐ Validate Pricing (blue checkboxes)
  - Divider
  - ☑ ⛨ GuardRails Enabled (amber checkbox, "+~15s validation" hint)
- **Buttons row:**
  - ▶ Run Skill (green gradient button)
  - 📋 Save as Favorite (indigo gradient button)
  - Right-aligned: "Execution mode: AI • Model: Claude Sonnet 4.5"

### Title Bar
- Dark slate background
- Traffic light dots (red/yellow/green)
- Center: "SSIUV — Sales Services Intelligent Unified Validations"
- Right: "● Staging" green pill badge

### Styling Notes for UI Mockup
- Independent color palette — NOT the same as the document theme
- Dark slate title bar (#0f172a)
- Light gray sidebar with subtle gradient (#f1f5f9 → #e8edf4)
- White main content area (#ffffff)
- Active sidebar item: solid blue pill (#1e40af white text)
- Form fields: clean borders (#cbd5e1), slightly off-white fill (#f8fafc)
- Channel tags: blue pills on light blue (#dbeafe, text #1e40af)
- Run button: green gradient (#059669)
- Save button: indigo gradient (#6366f1)
- GuardRails checkbox: amber theme (#f59e0b border, #fef3c7 bg)
- Box shadow on outer frame for depth

---

## 18. SYSTEM COMPONENTS

The complete component inventory:

| Component          | Technology              | Purpose                                          |
|--------------------|-------------------------|--------------------------------------------------|
| React Frontend     | React 18 + TypeScript   | SPA with dynamic forms, real-time execution view |
| Spring Boot API    | Java 17, Spring Boot 3  | REST + WebSocket, orchestration                  |
| AI Engine          | Claude CLI / Anthropic SDK | Read SKILL.md, call APIs, generate assertions |
| Temporal Workers   | Temporal Java SDK       | Deterministic workflow execution                 |
| PostgreSQL         | PostgreSQL 15+          | Skills, executions, users, registry              |
| S3 Storage         | AWS S3                  | SKILL.md files, scripts, execution artifacts     |
| Service Registry   | PostgreSQL table        | API endpoints, credentials, Swagger specs        |
| MCP Servers        | Spring AI               | Expose APIs as typed AI tools                    |
| Redis (optional)   | Redis                   | Execution status cache, real-time pub/sub        |
| EventHub Listener  | Node.js / Spring        | Async event consumption for skill assertions     |

---

## 19. DOCUMENT STRUCTURE FOR ARCHITECTURE DIAGRAMS

If generating an HTML architecture document, use this page structure:

1. **Introduction** — What SSIUV is, the core idea
2. **Claude Skills** — What SKILL.md files are, the pattern
3. **Architecture** — High-level system overview (Users → Platform → APIs), with RAG and GuardRails
4. **AI Engine** — Two-phase approach (CLI short-term, SDK long-term), RAG pattern, GuardRails
5. **Dev Tools** — GitHub Copilot Enterprise (VS Code, IntelliJ, CLI), tech stack
6. **Three Layers** — Presentation, Orchestration, Enterprise APIs
7. **SKILL.md Anatomy** — Full structure breakdown
8. **Execution Flow** — Routing decision (AI vs Temporal)
9. **Dual Path** — Side-by-side AI vs Temporal comparison
10. **Temporal Dev** — How to generate workflows from SKILL.md in IntelliJ
11. **Sales MCP** — What MCP is, conversion from Spring Boot, real API signatures
12. **MCP in Practice** — Env var setup, three personas with config, end-to-end flow, deployment options
13. **Pipeline** — TDI → Catalog → Offers → Orders → EventHub data flow
14. **User Journeys** — Business, QA, Admin persona flows
15. **Components** — Full component inventory table
16. **UI Layout** — Mockup of the execution screen

### Styling Guidelines
- Professional light theme — navy navigation bar, white/light gray content
- High contrast text (#0f172a on white)
- Color coding: Blue for frontend/backend, Purple for AI engine, Amber for GuardRails, Green for enterprise APIs, Pink for Temporal, Teal for MCP/registry
- Code blocks in dark theme (#1e293b background)
- Syntax highlighting with colored spans (keywords blue, strings green, comments gray)
- No SVG diagrams — use HTML/CSS grids, flexbox, and styled divs
- Minimum font size 12px for body text, 14px for labels

---

*End of SSIUV Complete Specification — v1.0*
