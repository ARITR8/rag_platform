# 🗄️ Database Schema Diagram - Phase 2 Document Processing

## 📊 **Entity Relationship Diagram**

```mermaid
erDiagram
    %% Core Document Tables
    documents {
        uuid id PK
        varchar filename
        varchar content_type
        bigint size_bytes
        char checksum_sha256
        varchar language_code
        text storage_path
        varchar status
        varchar processing_stage
        integer processing_time_ms
        integer chunk_count
        varchar embedding_model
        varchar chunking_strategy
        decimal extraction_quality
        varchar error_code
        text error_message
        uuid user_id
        uuid organization_id
        uuid project_id
        boolean is_encrypted
        varchar encryption_key_id
        varchar data_classification
        timestamp created_at
        timestamp updated_at
        timestamp processed_at
        timestamp expires_at
    }

    document_chunks {
        uuid id PK
        uuid document_id FK
        text text
        char text_hash
        integer start_char
        integer end_char
        integer page_number
        varchar section
        integer paragraph_index
        decimal confidence
        varchar language_code
        integer word_count
        integer character_count
        uuid vector_id
        varchar embedding_model
        integer embedding_dimension
        integer chunk_index
        integer chunk_size
        integer overlap_size
        jsonb entities
        jsonb topics
        jsonb keywords
        timestamp created_at
        timestamp updated_at
    }

    %% Processing Pipeline Tables
    document_processing_jobs {
        uuid id PK
        uuid document_id FK
        varchar job_type
        varchar priority
        jsonb processing_options
        varchar chunking_strategy
        varchar embedding_model
        varchar status
        integer progress_percentage
        varchar current_stage
        varchar worker_node
        integer worker_pid
        timestamp started_at
        timestamp completed_at
        timestamp estimated_completion
        integer chunks_processed
        integer chunks_total
        integer processing_time_ms
        varchar error_code
        text error_message
        integer retry_count
        integer max_retries
        timestamp created_at
        timestamp updated_at
    }

    batch_processing_jobs {
        uuid id PK
        varchar batch_name
        text description
        integer total_documents
        jsonb processing_options
        varchar priority
        varchar status
        integer progress_percentage
        integer documents_processed
        integer documents_failed
        integer documents_pending
        uuid current_document_id FK
        timestamp started_at
        timestamp completed_at
        timestamp estimated_completion
        integer processing_time_ms
        decimal success_rate
        varchar error_code
        text error_message
        uuid user_id
        uuid organization_id
        timestamp created_at
        timestamp updated_at
    }

    batch_job_documents {
        uuid id PK
        uuid batch_job_id FK
        uuid document_id FK
        varchar status
        integer processing_time_ms
        integer chunk_count
        text error_message
        integer processing_order
        timestamp created_at
        timestamp processed_at
    }

    %% Vector Integration Tables
    vector_embeddings {
        uuid id PK
        uuid chunk_id FK
        varchar embedding_model
        integer embedding_dimension
        varchar embedding_version
        varchar vector_id
        varchar vector_database
        decimal embedding_quality
        decimal similarity_threshold
        integer generation_time_ms
        varchar worker_node
        timestamp created_at
        timestamp updated_at
    }

    %% Webhook & Event System Tables
    webhook_registrations {
        uuid id PK
        text url
        varchar secret
        jsonb events
        boolean is_active
        boolean is_verified
        integer max_requests_per_minute
        integer current_requests_this_minute
        timestamp last_request_at
        uuid user_id
        uuid organization_id
        timestamp created_at
        timestamp updated_at
        timestamp last_verified_at
    }

    webhook_deliveries {
        uuid id PK
        uuid webhook_id FK
        varchar event_type
        jsonb event_data
        varchar status
        integer http_status_code
        text response_body
        integer retry_count
        integer max_retries
        timestamp next_retry_at
        timestamp created_at
        timestamp delivered_at
    }

    %% Compliance & Audit Tables
    legal_holds {
        uuid id PK
        varchar hold_name
        text description
        text reason
        jsonb document_ids
        uuid user_id
        uuid organization_id
        varchar status
        uuid created_by
        timestamp created_at
        timestamp expires_at
        timestamp released_at
        uuid released_by
    }

    audit_trail {
        uuid id PK
        varchar event_type
        varchar event_category
        varchar entity_type
        uuid entity_id
        uuid user_id
        varchar user_email
        varchar session_id
        inet ip_address
        text user_agent
        jsonb event_data
        jsonb old_values
        jsonb new_values
        uuid request_id
        varchar api_endpoint
        varchar http_method
        timestamp created_at
    }

    %% Performance & Monitoring Tables
    processing_metrics {
        uuid id PK
        varchar metric_name
        varchar metric_type
        decimal metric_value
        varchar metric_unit
        uuid document_id FK
        uuid processing_job_id FK
        uuid batch_job_id FK
        jsonb dimensions
        timestamp recorded_at
    }

    user_quotas {
        uuid id PK
        uuid user_id
        uuid organization_id
        varchar quota_type
        bigint quota_limit
        bigint quota_used
        timestamp window_start
        timestamp window_end
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    %% Relationships
    documents ||--o{ document_chunks : "has"
    documents ||--o{ document_processing_jobs : "processed_by"
    documents ||--o{ batch_job_documents : "included_in"
    documents ||--o{ processing_metrics : "measured_by"

    document_chunks ||--o{ vector_embeddings : "embedded_as"

    batch_processing_jobs ||--o{ batch_job_documents : "contains"
    batch_processing_jobs ||--o{ processing_metrics : "measured_by"

    document_processing_jobs ||--o{ processing_metrics : "measured_by"

    webhook_registrations ||--o{ webhook_deliveries : "delivers"
```

## 🔗 **Key Relationships**

### **1. Document Processing Flow**

```
documents → document_processing_jobs → document_chunks → vector_embeddings
```

### **2. Batch Processing Flow**

```
batch_processing_jobs → batch_job_documents → documents → document_chunks
```

### **3. Webhook Event Flow**

```
webhook_registrations → webhook_deliveries → audit_trail
```

### **4. Compliance Flow**

```
legal_holds → documents → audit_trail
```

## 📊 **Data Flow Patterns**

### **Document Upload & Processing**

1. **Document Upload** → `documents` table (status: UPLOADING)
2. **Processing Job** → `document_processing_jobs` table (status: PENDING)
3. **Text Extraction** → `document_chunks` table
4. **Embedding Generation** → `vector_embeddings` table
5. **Completion** → Update `documents` status to COMPLETED

### **Batch Processing**

1. **Batch Creation** → `batch_processing_jobs` table
2. **Document Assignment** → `batch_job_documents` table
3. **Individual Processing** → Each document follows upload flow
4. **Batch Completion** → Update batch status and metrics

### **Webhook Notifications**

1. **Event Occurrence** → Trigger webhook delivery
2. **Webhook Delivery** → `webhook_deliveries` table
3. **Audit Logging** → `audit_trail` table
4. **Retry Logic** → Handle failed deliveries

## 🎯 **Performance Considerations**

### **Indexing Strategy**

- **Primary Keys:** UUID with gen_random_uuid()
- **Foreign Keys:** Indexed for join performance
- **Status Fields:** Indexed for filtering
- **Timestamp Fields:** Indexed for time-based queries
- **Composite Indexes:** For complex queries

### **Partitioning Strategy**

- **Time-based Partitioning:** Monthly partitions for `documents` table
- **User-based Sharding:** For multi-tenant deployments
- **Status-based Partitioning:** Separate partitions for active/archived data

### **Query Optimization**

- **Views:** Pre-computed aggregations for common queries
- **Materialized Views:** For complex reporting queries
- **Connection Pooling:** Efficient database connection management

## 🔒 **Security & Compliance**

### **Data Protection**

- **Encryption:** Support for encrypted document storage
- **Access Control:** Row-level security for multi-tenant data
- **Audit Trail:** Comprehensive logging of all operations

### **Compliance Features**

- **GDPR:** Data deletion and retention policies
- **Legal Hold:** Document preservation for litigation
- **Data Classification:** Sensitivity level tracking
- **Audit Logging:** Complete audit trail for compliance

---

**Last Updated:** 2024-01-XX
**Version:** 1.0.0
**Maintainer:** Platform Engineering Team
