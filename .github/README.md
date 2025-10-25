# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the RAG Platform.

## Workflows

### 1. `ci-cd.yml` - Full CI/CD Pipeline

**Triggers:** Push to main/develop, Pull Requests, Manual

**Jobs:**

- **Test**: Code quality, linting, testing with PostgreSQL and Redis
- **Build & Scan**: Docker build with security scanning
- **Integration Test**: Full Docker Compose integration tests
- **Deploy Staging**: Deploy to staging on develop branch
- **Deploy Production**: Deploy to production on main branch
- **Notify**: Success/failure notifications

### 2. `simple-build.yml` - Quick Build Test

**Triggers:** Push to main, Manual

**Jobs:**

- **Build**: Simple Python and Docker build test

## Getting Started

1. **Push your code to GitHub**
2. **Go to Actions tab** in your repository
3. **Watch the workflows run automatically**

## Manual Trigger

You can manually trigger workflows:

1. Go to Actions tab
2. Select the workflow
3. Click "Run workflow"

## Environment Variables

The workflows use these environment variables:

- `REGISTRY`: GitHub Container Registry (ghcr.io)
- `IMAGE_NAME`: Your repository name

## Services Used

- **PostgreSQL 15**: For database testing
- **Redis 7**: For caching testing
- **Docker**: For container builds
- **Trivy**: For security scanning

## Artifacts

The workflows generate:

- **Test coverage reports**
- **Docker images** (pushed to GitHub Container Registry)
- **Security scan results**

## Troubleshooting

### Common Issues:

1. **Tests failing**: Check database/Redis connection
2. **Docker build failing**: Check Dockerfile syntax
3. **Permission errors**: Ensure GitHub token has proper permissions

### Debug Steps:

1. Check the Actions tab for detailed logs
2. Look for specific error messages
3. Test locally first if possible
