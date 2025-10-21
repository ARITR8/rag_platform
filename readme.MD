# 🏗️ Enterprise RAG Platform

### 🚀 Intelligent Context-Aware Knowledge Retrieval for Enterprises

---

## 📘 Overview

**Enterprise RAG Platform** is a scalable, production-grade system designed to deliver **contextual, accurate, and explainable answers** over massive enterprise document collections (1M+ docs) with **sub-second latency**.

It follows a **modular microservices architecture** combining:

- **Hybrid Retrieval** (Dense + BM25),
- **Semantic Caching**, and
- **LLM-Orchestrated Generation**

The platform is built with **LangChain-style orchestration**, **Redis semantic cache**, **Vector Databases** (Milvus/Weaviate), and **LLMs** served via **Triton/vLLM** — all deployed on **Kubernetes** for auto-scaling and observability.

---

## 🎯 End Goal (Full Platform Vision)

> Build a _Google Search–level Enterprise AI Assistant_ that can:
>
> - Ingest millions of internal documents (policies, tickets, manuals)
> - Answer user questions with **grounded, source-cited, trustworthy** responses
> - Learn continuously from user feedback
> - Scale horizontally while maintaining <1 second response time
> - Operate cost-effectively and securely in multi-tenant enterprise setups

---

### 🧩 Architectural Summary

```
User → API Gateway → Auth → RAG Orchestrator
      ↳ Semantic Cache (Redis + FAISS)
      ↳ Retriever (Dense + BM25)
      ↳ Reranker (Cross-Encoder)
      ↳ Vector DB (Milvus/Weaviate)
      ↳ LLM Gateway (vLLM / Triton)
      ↳ Monitoring (Prometheus + Grafana)
      ↳ Feedback Loop (Kafka)
```

The orchestrator acts as the **brain** that coordinates retrieval, ranking, caching, generation, and feedback.

---

## 🧱 Phase Roadmap (Iterative Build Plan)

We are building the platform in **5 phases**, each producing a working increment of the full system.

| Phase       | Focus                          | Goal                                  | Expected Output                            |
| ----------- | ------------------------------ | ------------------------------------- | ------------------------------------------ |
| **Phase 1** | MVP Core Orchestrator          | Functional end-to-end mock pipeline   | `/v1/query` API returning mock answer      |
| **Phase 2** | Real Retrieval Layer           | Hybrid dense + sparse retrievers      | Real context retrieval from docs           |
| **Phase 3** | LLM Integration                | Real model inference (local or API)   | Factual generation with citations          |
| **Phase 4** | Feedback Loop & Metrics        | RAG evaluation + learning             | Continuous improvement via feedback        |
| **Phase 5** | Kubernetes & Productionization | Full infra + monitoring + autoscaling | Deployed, observable, self-healing cluster |

---

## 🧠 Phase 1 — “Mocked Brain” MVP (Current Phase)

### 🎯 Goal

To build a **working prototype** of the entire RAG pipeline using **mock components** that simulate retrieval, ranking, and generation — proving that the architecture and API contract are correct.

This establishes the **foundation** of all future phases.

---

### 🧩 Scope of Phase 1

| Component                      | Description                                       |
| ------------------------------ | ------------------------------------------------- |
| **RAG Orchestrator (FastAPI)** | Central brain coordinating the pipeline           |
| **Semantic Cache (Redis)**     | Store recent query responses (by query hash)      |
| **Mock Retriever**             | Returns fake but structured text chunks           |
| **Mock Reranker**              | Sorts mock chunks randomly or by score            |
| **Mock LLM Generator**         | Returns templated answers based on fake context   |
| **Logging + Metrics**          | Print latency and cache hits to logs              |
| **Unit Tests (pytest)**        | Validate orchestrator, caching, and output schema |
| **Local Deployment**           | Run via Docker Compose (no Kubernetes yet)        |

---

### 🧠 Example Flow (Phase 1)

1. User sends a query → `/v1/query`
2. Orchestrator checks Redis for cached answer.
3. If miss → calls mock retriever → mock reranker → mock LLM.
4. Returns structured JSON answer with fake citations.
5. Logs latency and stores result in cache.

**Example Output:**

```json
{
  "answer": "Refunds are processed within 7 days of purchase (mock).",
  "sources": [
    {
      "doc_id": "mock_doc_001",
      "snippet": "Refunds within 7 days...",
      "score": 0.91
    }
  ],
  "meta": { "cache_hit": false, "latency_ms": 420 }
}
```

---

### 🧱 Phase 1 Architecture Diagram

```
                 ┌─────────────────────┐
                 │   User / Client     │
                 │ (curl / Postman)    │
                 └──────────┬──────────┘
                            │  POST /v1/query
                            ▼
                 ┌────────────────────────┐
                 │   RAG Orchestrator     │
                 │  (FastAPI Service)     │
                 │------------------------│
                 │ - Input validation     │
                 │ - Cache check          │
                 │ - Mock retrieval       │
                 │ - Mock reranking       │
                 │ - Mock generation      │
                 │ - Response assembly    │
                 └──────────┬─────────────┘
                            │
             ┌──────────────┼────────────────┐
             │              │                │
             ▼              ▼                ▼
      ┌────────────┐ ┌──────────────┐ ┌────────────┐
      │ Redis Cache│ │ MockRetriever│ │ Mock LLM    │
      │ (Semantic) │ │ (JSON corpus)│ │ (Template)  │
      └────────────┘ └──────────────┘ └────────────┘
                            │
                            ▼
                    ┌────────────┐
                    │ Console Log│
                    └────────────┘
```

---

### 🧩 Phase 1 Deliverables

- ✅ `/v1/query` REST endpoint
- ✅ Structured JSON responses
- ✅ Redis cache integration
- ✅ Basic logging & latency metrics
- ✅ Unit tests (pytest) passing
- ✅ Docker Compose setup (`orchestrator + redis`)
- ✅ README & design docs

---

### 🧠 Success Criteria for Phase 1

| Category      | Metric / Goal                                 |
| ------------- | --------------------------------------------- |
| API Response  | < 1 second average latency                    |
| Cache Hit     | Confirmed on repeated queries                 |
| Test Coverage | ≥ 80% orchestrator coverage                   |
| Stability     | Containers restart cleanly via Docker Compose |
| Observability | Logs show latency, cache hits                 |

---

## 🧱 Brief Preview of Next Phases

### **Phase 2 — Real Retrieval Layer**

- Replace MockRetriever with hybrid retrieval:

  - BM25 (ElasticSearch or Postgres full-text)
  - Dense retrieval (FAISS or Milvus)

- Add score normalization & reranker model
- Measure recall/precision on test corpus

### **Phase 3 — LLM Integration**

- Integrate real LLM via vLLM, Triton, or OpenAI API
- Add prompt templates, context packing, token budgeting
- Implement fallback & retry logic
- Measure factual accuracy and latency

### **Phase 4 — Feedback & Evaluation**

- Add Kafka-based feedback pipeline
- Integrate RAGAS evaluation framework
- Build feedback dashboard (Grafana + API)
- Start continuous improvement loop

### **Phase 5 — Kubernetes & Productionization**

- Deploy all services (RAG orchestrator, retrievers, LLM, cache)
- Add observability (Prometheus, Loki, Jaeger)
- Enable autoscaling (HPA)
- Implement canary rollout (Argo Rollouts)
- Meet SLOs: p95 latency < 1s, uptime > 99.9%

---

## 🧰 Tech Stack Summary

| Layer                 | Technology                            |
| --------------------- | ------------------------------------- |
| **Backend Framework** | FastAPI (Python 3.11)                 |
| **Cache**             | Redis                                 |
| **Database**          | PostgreSQL (Phase 2+)                 |
| **Vector DB**         | Milvus / FAISS (Phase 2+)             |
| **LLM Serving**       | vLLM / Triton / OpenAI API (Phase 3+) |
| **Queue / Feedback**  | Kafka (Phase 4)                       |
| **Infra & Deploy**    | Docker Compose → Kubernetes (Phase 5) |
| **Monitoring**        | Prometheus, Grafana, Loki (Phase 5)   |
| **CI/CD**             | GitHub Actions + ArgoCD               |
| **Testing**           | pytest (TDD), behave/pytest-bdd (BDD) |

---

## 🧭 Development Approach

- **Test-Driven Development (TDD)** for service logic
- **Behavior-Driven Development (BDD)** for user flows
- **Infrastructure-as-Code (IaC)** via Terraform + Helm (Phase 5)
- **GitOps Deployment** using ArgoCD (Phase 5)

---

## 💡 Why Build Incrementally?

Because each phase is a **complete working slice** that can:

- Be tested, deployed, and benchmarked independently
- Serve as a learning checkpoint
- Prevent wasted work on premature optimization

By Phase 2, you’ll have a functioning RAG backend.
By Phase 3, a real AI system with context-based answers.
By Phase 5, a fully scalable, observable production system.

---

## 📈 Final Vision Diagram (Phase 5 Reference)

```
 End User → API Gateway → Auth → RAG Orchestrator
               ↓           ↓
        ┌──────────────┐   │
        │ SemanticCache│   │
        │ (Redis/FAISS)│   │
        └──────────────┘   │
               ↓            ↓
        ┌──────────────┐ ┌───────────────┐
        │ Retriever     │ │ Vector DB     │
        │ (BM25 + ANN)  │ │ (Milvus/FAISS)│
        └──────────────┘ └───────────────┘
               ↓
        ┌──────────────┐
        │ Reranker     │
        │ (CrossEnc.)  │
        └──────────────┘
               ↓
        ┌──────────────┐
        │ LLM Inference│
        │ (vLLM/Triton)│
        └──────────────┘
               ↓
        ┌──────────────┐
        │ Feedback Loop│
        │ (Kafka + Eval)│
        └──────────────┘
               ↓
        ┌──────────────┐
        │ Monitoring   │
        │ (Prom/Grafana)│
        └──────────────┘
```

---

## 🏁 Summary

- We’re currently building **Phase 1: the Mock Orchestrator MVP.**
- This gives us a **working skeleton** of the system: `/v1/query` → mock retrieval → mock LLM → cached output.
- Next, we’ll plug in **real retrievers and LLMs** while preserving this tested foundation.
