-- =====================================================
-- RAG Platform Phase 2: Document Processing Database Schema
-- Enterprise-Grade Document Processing & RAG Integration
-- =====================================================

-- Database: rag_platform_documents
-- Engine: PostgreSQL 15+ (or CockroachDB for distributed)
-- Character Set: UTF-8
-- Timezone: UTC

-- =====================================================
-- 1. CORE DOCUMENT TABLES
-- =====================================================

-- Main documents table - stores document metadata and processing status
CREATE TABLE documents (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Document Identity
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255), -- Preserve original name if different
    content_type VARCHAR(100) NOT NULL CHECK (content_type IN (
        'application/pdf',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'text/plain',
        'text/html',
        'text/markdown',
        'application/rtf'
    )),

    -- File Properties
    size_bytes BIGINT NOT NULL CHECK (size_bytes > 0 AND size_bytes <= 104857600), -- 100MB limit
    checksum_sha256 CHAR(64) NOT NULL, -- SHA-256 hash for deduplication
    language_code VARCHAR(10) DEFAULT 'en-US' CHECK (language_code ~ '^[a-z]{2}(-[A-Z]{2})?$'),
    encoding VARCHAR(20) DEFAULT 'utf-8',

    -- Storage Information
    storage_path TEXT NOT NULL, -- S3/GCS path or local path
    storage_provider VARCHAR(20) DEFAULT 's3' CHECK (storage_provider IN ('s3', 'gcs', 'local')),
    original_url TEXT, -- Source URL if uploaded from external source

    -- Processing Status
    status VARCHAR(20) NOT NULL DEFAULT 'UPLOADING' CHECK (status IN (
        'UPLOADING', 'PROCESSING', 'COMPLETED', 'FAILED', 'ARCHIVED'
    )),
    processing_stage VARCHAR(30) DEFAULT 'upload' CHECK (processing_stage IN (
        'upload', 'extraction', 'chunking', 'embedding', 'indexing', 'completed'
    )),

    -- Processing Metadata
    processing_time_ms INTEGER,
    chunk_count INTEGER DEFAULT 0,
    embedding_model VARCHAR(100) DEFAULT 'sentence-transformers/all-MiniLM-L6-v2',
    chunking_strategy VARCHAR(20) DEFAULT 'semantic' CHECK (chunking_strategy IN (
        'semantic', 'fixed', 'sentence', 'paragraph'
    )),
    extraction_quality DECIMAL(3,2) CHECK (extraction_quality >= 0 AND extraction_quality <= 1),

    -- Error Handling
    error_code VARCHAR(50),
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,

    -- User & Organization
    user_id UUID NOT NULL, -- Reference to user/tenant
    organization_id UUID, -- Multi-tenant support
    project_id UUID, -- Optional project grouping

    -- Compliance & Security
    is_encrypted BOOLEAN DEFAULT false,
    encryption_key_id VARCHAR(100),
    data_classification VARCHAR(20) DEFAULT 'internal' CHECK (data_classification IN (
        'public', 'internal', 'confidential', 'restricted'
    )),

    -- Lifecycle Management
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE, -- Auto-deletion for compliance

    -- Indexes
    CONSTRAINT documents_checksum_unique UNIQUE (checksum_sha256, user_id), -- Prevent duplicate uploads per user
    CONSTRAINT documents_size_check CHECK (size_bytes > 0 AND size_bytes <= 104857600)
);

-- Document chunks table - stores processed text chunks
CREATE TABLE document_chunks (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,

    -- Chunk Content
    text TEXT NOT NULL CHECK (LENGTH(text) <= 10000), -- Max 10KB per chunk
    text_hash CHAR(64) NOT NULL, -- SHA-256 of text for deduplication

    -- Position Information
    start_char INTEGER NOT NULL CHECK (start_char >= 0),
    end_char INTEGER NOT NULL CHECK (end_char > start_char),
    page_number INTEGER,
    section VARCHAR(255),
    paragraph_index INTEGER,

    -- Chunk Metadata
    confidence DECIMAL(3,2) CHECK (confidence >= 0 AND confidence <= 1),
    language_code VARCHAR(10) DEFAULT 'en-US',
    word_count INTEGER,
    character_count INTEGER,

    -- Vector Integration
    vector_id UUID, -- Reference to vector embedding
    embedding_model VARCHAR(100),
    embedding_dimension INTEGER,

    -- Processing Information
    chunk_index INTEGER NOT NULL, -- Order within document
    chunk_size INTEGER NOT NULL, -- Size of this chunk
    overlap_size INTEGER DEFAULT 0, -- Overlap with previous chunk

    -- Extracted Information
    entities JSONB, -- Named entities found in chunk
    topics JSONB, -- Detected topics/categories
    keywords JSONB, -- Extracted keywords

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT chunks_position_check CHECK (end_char > start_char),
    CONSTRAINT chunks_text_length_check CHECK (LENGTH(text) <= 10000),
    CONSTRAINT chunks_unique_position UNIQUE (document_id, start_char, end_char)
);

-- =====================================================
-- 2. PROCESSING PIPELINE TABLES
-- =====================================================

-- Document processing jobs - tracks individual document processing
CREATE TABLE document_processing_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,

    -- Job Information
    job_type VARCHAR(30) NOT NULL CHECK (job_type IN (
        'initial_processing', 'rechunking', 'embedding_generation', 'reindexing'
    )),
    priority VARCHAR(10) DEFAULT 'STANDARD' CHECK (priority IN ('LOW', 'STANDARD', 'HIGH')),

    -- Processing Configuration
    processing_options JSONB NOT NULL DEFAULT '{}',
    chunking_strategy VARCHAR(20) DEFAULT 'semantic',
    embedding_model VARCHAR(100) DEFAULT 'sentence-transformers/all-MiniLM-L6-v2',

    -- Status Tracking
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN (
        'PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED'
    )),
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    current_stage VARCHAR(30),

    -- Worker Information
    worker_node VARCHAR(100),
    worker_pid INTEGER,

    -- Timing
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    estimated_completion TIMESTAMP WITH TIME ZONE,

    -- Results
    chunks_processed INTEGER DEFAULT 0,
    chunks_total INTEGER,
    processing_time_ms INTEGER,

    -- Error Handling
    error_code VARCHAR(50),
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT jobs_timing_check CHECK (completed_at IS NULL OR completed_at >= started_at)
);

-- Batch processing jobs - tracks batch operations
CREATE TABLE batch_processing_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Batch Information
    batch_name VARCHAR(255),
    description TEXT,
    total_documents INTEGER NOT NULL CHECK (total_documents > 0),

    -- Processing Configuration
    processing_options JSONB NOT NULL DEFAULT '{}',
    priority VARCHAR(10) DEFAULT 'STANDARD' CHECK (priority IN ('LOW', 'STANDARD', 'HIGH')),

    -- Status Tracking
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN (
        'PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'PARTIAL'
    )),
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),

    -- Counters
    documents_processed INTEGER DEFAULT 0,
    documents_failed INTEGER DEFAULT 0,
    documents_pending INTEGER,

    -- Current Processing
    current_document_id UUID REFERENCES documents(id),

    -- Timing
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    estimated_completion TIMESTAMP WITH TIME ZONE,

    -- Results
    processing_time_ms INTEGER,
    success_rate DECIMAL(5,2), -- Percentage of successful documents

    -- Error Handling
    error_code VARCHAR(50),
    error_message TEXT,

    -- User & Organization
    user_id UUID NOT NULL,
    organization_id UUID,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Batch job documents - links documents to batch jobs
CREATE TABLE batch_job_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_job_id UUID NOT NULL REFERENCES batch_processing_jobs(id) ON DELETE CASCADE,
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,

    -- Processing Status
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN (
        'PENDING', 'PROCESSING', 'COMPLETED', 'FAILED'
    )),

    -- Results
    processing_time_ms INTEGER,
    chunk_count INTEGER,
    error_message TEXT,

    -- Order
    processing_order INTEGER NOT NULL,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE,

    -- Constraints
    CONSTRAINT batch_docs_unique UNIQUE (batch_job_id, document_id)
);

-- =====================================================
-- 3. VECTOR INTEGRATION TABLES
-- =====================================================

-- Vector embeddings metadata - tracks embedding generation
CREATE TABLE vector_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chunk_id UUID NOT NULL REFERENCES document_chunks(id) ON DELETE CASCADE,

    -- Embedding Information
    embedding_model VARCHAR(100) NOT NULL,
    embedding_dimension INTEGER NOT NULL,
    embedding_version VARCHAR(20) DEFAULT '1.0',

    -- Vector Storage
    vector_id VARCHAR(100) NOT NULL, -- External vector DB ID (Milvus/Weaviate)
    vector_database VARCHAR(20) DEFAULT 'milvus' CHECK (vector_database IN ('milvus', 'weaviate', 'pinecone')),

    -- Quality Metrics
    embedding_quality DECIMAL(3,2) CHECK (embedding_quality >= 0 AND embedding_quality <= 1),
    similarity_threshold DECIMAL(3,2) DEFAULT 0.7,

    -- Processing Information
    generation_time_ms INTEGER,
    worker_node VARCHAR(100),

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT vectors_unique_chunk UNIQUE (chunk_id, embedding_model)
);

-- =====================================================
-- 4. WEBHOOK & EVENT SYSTEM TABLES
-- =====================================================

-- Webhook registrations
CREATE TABLE webhook_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Webhook Configuration
    url TEXT NOT NULL,
    secret VARCHAR(255), -- HMAC secret for verification
    events JSONB NOT NULL, -- Array of event types to subscribe to

    -- Status
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,

    -- Rate Limiting
    max_requests_per_minute INTEGER DEFAULT 60,
    current_requests_this_minute INTEGER DEFAULT 0,
    last_request_at TIMESTAMP WITH TIME ZONE,

    -- User & Organization
    user_id UUID NOT NULL,
    organization_id UUID,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_verified_at TIMESTAMP WITH TIME ZONE
);

-- Webhook delivery logs
CREATE TABLE webhook_deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    webhook_id UUID NOT NULL REFERENCES webhook_registrations(id) ON DELETE CASCADE,

    -- Event Information
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB NOT NULL,

    -- Delivery Information
    status VARCHAR(20) NOT NULL CHECK (status IN (
        'PENDING', 'DELIVERED', 'FAILED', 'RETRYING'
    )),
    http_status_code INTEGER,
    response_body TEXT,

    -- Retry Information
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    next_retry_at TIMESTAMP WITH TIME ZONE,

    -- Timing
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    delivered_at TIMESTAMP WITH TIME ZONE,

    -- Constraints
    CONSTRAINT webhook_delivery_timing CHECK (delivered_at IS NULL OR delivered_at >= created_at)
);

-- =====================================================
-- 5. COMPLIANCE & AUDIT TABLES
-- =====================================================

-- Legal holds - for compliance and litigation
CREATE TABLE legal_holds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Hold Information
    hold_name VARCHAR(255) NOT NULL,
    description TEXT,
    reason TEXT NOT NULL,

    -- Scope
    document_ids JSONB, -- Array of document IDs
    user_id UUID,
    organization_id UUID,

    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN (
        'ACTIVE', 'SUSPENDED', 'RELEASED'
    )),

    -- Lifecycle
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    released_at TIMESTAMP WITH TIME ZONE,
    released_by UUID,

    -- Constraints
    CONSTRAINT legal_hold_expiry CHECK (expires_at IS NULL OR expires_at > created_at)
);

-- Audit trail - comprehensive audit logging
CREATE TABLE audit_trail (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Event Information
    event_type VARCHAR(50) NOT NULL,
    event_category VARCHAR(30) NOT NULL CHECK (event_category IN (
        'document', 'processing', 'user', 'system', 'compliance'
    )),

    -- Entity Information
    entity_type VARCHAR(30) NOT NULL, -- 'document', 'chunk', 'batch_job', etc.
    entity_id UUID NOT NULL,

    -- User Information
    user_id UUID,
    user_email VARCHAR(255),
    session_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,

    -- Event Details
    event_data JSONB NOT NULL DEFAULT '{}',
    old_values JSONB,
    new_values JSONB,

    -- Request Information
    request_id UUID,
    api_endpoint VARCHAR(255),
    http_method VARCHAR(10),

    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Indexes will be created separately for performance
    CONSTRAINT audit_trail_entity_check CHECK (entity_id IS NOT NULL)
);

-- =====================================================
-- 6. PERFORMANCE & MONITORING TABLES
-- =====================================================

-- Processing metrics - for performance monitoring
CREATE TABLE processing_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Metric Information
    metric_name VARCHAR(100) NOT NULL,
    metric_type VARCHAR(20) NOT NULL CHECK (metric_type IN (
        'counter', 'gauge', 'histogram', 'timer'
    )),

    -- Values
    metric_value DECIMAL(15,4) NOT NULL,
    metric_unit VARCHAR(20),

    -- Context
    document_id UUID REFERENCES documents(id),
    processing_job_id UUID REFERENCES document_processing_jobs(id),
    batch_job_id UUID REFERENCES batch_processing_jobs(id),

    -- Dimensions
    dimensions JSONB DEFAULT '{}', -- Additional context (file_type, size_range, etc.)

    -- Timestamp
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT metrics_value_check CHECK (metric_value >= 0)
);

-- User quotas - for rate limiting and resource management
CREATE TABLE user_quotas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    organization_id UUID,

    -- Quota Types
    quota_type VARCHAR(30) NOT NULL CHECK (quota_type IN (
        'documents_per_day', 'documents_per_hour', 'storage_bytes', 'processing_time_ms'
    )),

    -- Quota Limits
    quota_limit BIGINT NOT NULL CHECK (quota_limit > 0),
    quota_used BIGINT DEFAULT 0 CHECK (quota_used >= 0),

    -- Time Window
    window_start TIMESTAMP WITH TIME ZONE NOT NULL,
    window_end TIMESTAMP WITH TIME ZONE NOT NULL,

    -- Status
    is_active BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT quotas_window_check CHECK (window_end > window_start),
    CONSTRAINT quotas_usage_check CHECK (quota_used <= quota_limit),
    CONSTRAINT quotas_unique_user_type_window UNIQUE (user_id, quota_type, window_start)
);

-- =====================================================
-- 7. INDEXES FOR PERFORMANCE
-- =====================================================

-- Documents table indexes
CREATE INDEX idx_documents_user_id ON documents(user_id);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_created_at ON documents(created_at);
CREATE INDEX idx_documents_content_type ON documents(content_type);
CREATE INDEX idx_documents_organization_id ON documents(organization_id);
CREATE INDEX idx_documents_checksum ON documents(checksum_sha256);
CREATE INDEX idx_documents_expires_at ON documents(expires_at) WHERE expires_at IS NOT NULL;

-- Document chunks indexes
CREATE INDEX idx_chunks_document_id ON document_chunks(document_id);
CREATE INDEX idx_chunks_vector_id ON document_chunks(vector_id) WHERE vector_id IS NOT NULL;
CREATE INDEX idx_chunks_text_hash ON document_chunks(text_hash);
CREATE INDEX idx_chunks_confidence ON document_chunks(confidence) WHERE confidence IS NOT NULL;
CREATE INDEX idx_chunks_created_at ON document_chunks(created_at);

-- Processing jobs indexes
CREATE INDEX idx_processing_jobs_document_id ON document_processing_jobs(document_id);
CREATE INDEX idx_processing_jobs_status ON document_processing_jobs(status);
CREATE INDEX idx_processing_jobs_created_at ON document_processing_jobs(created_at);
CREATE INDEX idx_processing_jobs_worker_node ON document_processing_jobs(worker_node) WHERE worker_node IS NOT NULL;

-- Batch jobs indexes
CREATE INDEX idx_batch_jobs_user_id ON batch_processing_jobs(user_id);
CREATE INDEX idx_batch_jobs_status ON batch_processing_jobs(status);
CREATE INDEX idx_batch_jobs_created_at ON batch_processing_jobs(created_at);

-- Vector embeddings indexes
CREATE INDEX idx_vectors_chunk_id ON vector_embeddings(chunk_id);
CREATE INDEX idx_vectors_model ON vector_embeddings(embedding_model);
CREATE INDEX idx_vectors_database ON vector_embeddings(vector_database);

-- Webhook indexes
CREATE INDEX idx_webhooks_user_id ON webhook_registrations(user_id);
CREATE INDEX idx_webhooks_active ON webhook_registrations(is_active) WHERE is_active = true;
CREATE INDEX idx_webhook_deliveries_webhook_id ON webhook_deliveries(webhook_id);
CREATE INDEX idx_webhook_deliveries_status ON webhook_deliveries(status);
CREATE INDEX idx_webhook_deliveries_created_at ON webhook_deliveries(created_at);

-- Audit trail indexes
CREATE INDEX idx_audit_trail_entity ON audit_trail(entity_type, entity_id);
CREATE INDEX idx_audit_trail_user_id ON audit_trail(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_audit_trail_event_type ON audit_trail(event_type);
CREATE INDEX idx_audit_trail_created_at ON audit_trail(created_at);
CREATE INDEX idx_audit_trail_request_id ON audit_trail(request_id) WHERE request_id IS NOT NULL;

-- Processing metrics indexes
CREATE INDEX idx_metrics_name ON processing_metrics(metric_name);
CREATE INDEX idx_metrics_recorded_at ON processing_metrics(recorded_at);
CREATE INDEX idx_metrics_document_id ON processing_metrics(document_id) WHERE document_id IS NOT NULL;

-- User quotas indexes
CREATE INDEX idx_quotas_user_id ON user_quotas(user_id);
CREATE INDEX idx_quotas_type_window ON user_quotas(quota_type, window_start, window_end);
CREATE INDEX idx_quotas_active ON user_quotas(is_active) WHERE is_active = true;

-- =====================================================
-- 8. TRIGGERS FOR AUTOMATIC UPDATES
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to all relevant tables
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chunks_updated_at BEFORE UPDATE ON document_chunks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_processing_jobs_updated_at BEFORE UPDATE ON document_processing_jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_batch_jobs_updated_at BEFORE UPDATE ON batch_processing_jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vectors_updated_at BEFORE UPDATE ON vector_embeddings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_webhooks_updated_at BEFORE UPDATE ON webhook_registrations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quotas_updated_at BEFORE UPDATE ON user_quotas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 9. VIEWS FOR COMMON QUERIES
-- =====================================================

-- Document processing status view
CREATE VIEW document_processing_status AS
SELECT
    d.id,
    d.filename,
    d.status,
    d.processing_stage,
    d.chunk_count,
    d.processing_time_ms,
    d.created_at,
    d.updated_at,
    d.processed_at,
    pj.status as job_status,
    pj.progress_percentage,
    pj.current_stage as job_stage
FROM documents d
LEFT JOIN document_processing_jobs pj ON d.id = pj.document_id
    AND pj.status IN ('PENDING', 'PROCESSING');

-- Batch processing summary view
CREATE VIEW batch_processing_summary AS
SELECT
    bj.id,
    bj.batch_name,
    bj.status,
    bj.total_documents,
    bj.documents_processed,
    bj.documents_failed,
    bj.progress_percentage,
    bj.success_rate,
    bj.created_at,
    bj.started_at,
    bj.completed_at,
    bj.processing_time_ms
FROM batch_processing_jobs bj;

-- Document chunk statistics view
CREATE VIEW document_chunk_stats AS
SELECT
    d.id as document_id,
    d.filename,
    COUNT(dc.id) as total_chunks,
    AVG(LENGTH(dc.text)) as avg_chunk_length,
    MIN(LENGTH(dc.text)) as min_chunk_length,
    MAX(LENGTH(dc.text)) as max_chunk_length,
    AVG(dc.confidence) as avg_confidence,
    COUNT(ve.id) as embedded_chunks
FROM documents d
LEFT JOIN document_chunks dc ON d.id = dc.document_id
LEFT JOIN vector_embeddings ve ON dc.id = ve.chunk_id
GROUP BY d.id, d.filename;

-- =====================================================
-- 10. PARTITIONING STRATEGY (for large-scale deployments)
-- =====================================================

-- Partition documents table by created_at (monthly partitions)
-- Uncomment for production deployment with high volume
/*
CREATE TABLE documents_y2024m01 PARTITION OF documents
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE documents_y2024m02 PARTITION OF documents
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Add more partitions as needed
*/

-- =====================================================
-- 11. DATA RETENTION POLICIES
-- =====================================================

-- Function to clean up expired documents
CREATE OR REPLACE FUNCTION cleanup_expired_documents()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete documents that have expired
    DELETE FROM documents
    WHERE expires_at IS NOT NULL
    AND expires_at < NOW()
    AND status != 'ARCHIVED';

    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    -- Log the cleanup
    INSERT INTO audit_trail (event_type, event_category, entity_type, entity_id, event_data)
    VALUES ('cleanup_expired_documents', 'system', 'system', gen_random_uuid(),
            jsonb_build_object('deleted_count', deleted_count));

    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 12. SAMPLE DATA FOR TESTING
-- =====================================================

-- Insert sample document for testing
INSERT INTO documents (
    filename, content_type, size_bytes, checksum_sha256,
    storage_path, user_id, status
) VALUES (
    'sample-document.pdf', 'application/pdf', 1024000,
    'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456',
    's3://documents/sample-document.pdf',
    gen_random_uuid(), 'COMPLETED'
);

-- =====================================================
-- SCHEMA CREATION COMPLETE
-- =====================================================

-- Grant permissions (adjust as needed for your environment)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rag_platform_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rag_platform_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO rag_platform_user;
