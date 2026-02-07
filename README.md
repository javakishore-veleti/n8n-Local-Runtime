# Local n8n AI / AIOps Platform

A **fully local, multi-service AI & AIOps research platform** built around **n8n**, designed for:
- LLM-based automation
- AIOps / SRE experimentation
- Graph AI (Neo4j)
- Vector search & unstructured data (MongoDB)
- Observability (Grafana, Prometheus, OpenTelemetry)
- Safe separation of **user data** vs **deployment/runtime data**

This platform is optimized for **macOS** (Apple Silicon friendly) and supports **multiple parallel research stacks** without port or container conflicts.

---

## 🧠 Architecture Overview

```
Mac Host
├─ Ollama (native, fast)
│   └─ LLM inference & embeddings
│
└─ Docker Compose (this repo)
    ├─ n8n                (AI orchestration)
    ├─ Postgres           (n8n persistence)
    ├─ pgAdmin            (Postgres UI)
    ├─ Neo4j              (Graph + graph embeddings)
    ├─ MongoDB            (Docs + vector search)
    ├─ Grafana            (Dashboards / AIOps)
    ├─ Prometheus         (Metrics)
    └─ Jaeger             (OpenTelemetry tracing)
```

---

## 📁 Data Lake Design (VERY IMPORTANT)

The data lake lives on the **host** and is **never deleted by Docker**.

**Host path**
```
~/runtime_data/local-ai-data/n8n-local-data
```

**Mounted inside containers**
```
/data/local-ai
```

This directory can contain **any file type**, **any depth**, and is shared across all containers.

---

## 🗂️ Data Lake Folder Structure (Canonical)

| Category | Path | Purpose / Examples |
|-------|-----|--------------------|
| Blog & Research Ideas | datasets/excel/blogs-ideas/aws | AWS blog & article ideas |
|  | datasets/excel/blogs-ideas/azure | Azure research & notes |
|  | datasets/excel/blogs-ideas/gcp | GCP content ideas |
|  | datasets/excel/blogs-ideas/architecture | Architecture topics |
|  | datasets/excel/blogs-ideas/ai | AI / ML research |
|  | datasets/excel/blogs-ideas/cloud | Cloud engineering |
|  | datasets/excel/blogs-ideas/engineering | Engineering practices |
|  | datasets/excel/blogs-ideas/innovation | Innovation ideas |
|  | datasets/excel/blogs-ideas/ieee-articles | IEEE article references |
|  | datasets/excel/blogs-ideas/research | Academic research |
|  | datasets/excel/blogs-ideas/entrepreneurship | Startup & business ideas |
| Banking & Finance | datasets/excel/my-banks/bofa | Bank of America data |
|  | datasets/excel/my-banks/wellsfargo | Wells Fargo data |
|  | datasets/excel/my-banks/capitalone | Capital One data |
|  | datasets/excel/my-banks/vanguard | Vanguard investments |
|  | datasets/excel/my-banks/robinhood | Robinhood exports |
|  | datasets/excel/my-banks/acorns | Acorns data |
|  | datasets/excel/my-banks/wealthfront | Wealthfront data |
| Career & Docs | datasets/word/resume | Resume versions |
|  | datasets/word/job-descriptions | Job descriptions |
|  | datasets/word/architecture-specs | Architecture specifications |
|  | datasets/word/reference-architecture | Reference architectures |
| Certifications | datasets/pdf/certifications/togaf | TOGAF material |
|  | datasets/pdf/certifications/aws | AWS certs |
|  | datasets/pdf/certifications/azure | Azure certs |
|  | datasets/pdf/certifications/gcp | GCP certs |
|  | datasets/pdf/certifications/others | Other certifications |
| Source Code | code/java | Java projects |
|  | code/python | Python projects |
|  | code/dotnet | .NET projects |
| Incidents | incidents/2026 | Incident data & RCA |
| Extensions | *any new folder* | Future research / datasets |

> All folders are **auto-created on startup** if missing  
> Existing files are **never overwritten or deleted**

---

## 📦 Deployment / Runtime Data

Stored separately and safe to destroy:

```
~/runtime_data/local-ai-data/n8n-local-deployment-data
```

Contains:
- n8n internal state
- Databases (Postgres, MongoDB, Neo4j)
- Grafana dashboards
- Prometheus metrics

---

## 🔌 Service URLs

| Service | URL |
|------|----|
| n8n | http://localhost:9567 |
| Grafana | http://localhost:93000 |
| Neo4j Browser | http://localhost:9474 |
| pgAdmin | http://localhost:95050 |
| Prometheus | http://localhost:9909 |
| Jaeger | http://localhost:96686 |
| Postgres | localhost:9432 |
| MongoDB | localhost:9017 |

---

## 🚀 Commands

```bash
npm start        # start platform
npm run stop     # stop platform
npm run destroy  # destroy deployment data ONLY
npm run open:all # open all UIs
```

---

## 🤖 Ollama Configuration (n8n)

```
Base URL: http://host.docker.internal:11434
API Key: (leave empty)
Model: mistral | llama3 | phi3
```

---

## 🔐 Default Credentials (LOCAL ONLY)

| Service | User | Password |
|------|----|----------|
| Postgres | n8n | n8n |
| pgAdmin | admin@local.dev | admin |
| Neo4j | neo4j | password |
| Grafana | admin | admin |

---

## 🧪 Philosophy

Local-first. Reproducible. Safe experimentation.  
Designed as a **personal AI / AIOps research lab**.

---

Happy building 🚀
