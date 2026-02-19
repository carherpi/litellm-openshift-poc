# LiteLLM Proxy Monitoring & Logging - Design Document

**Date:** 2026-02-19
**Purpose:** Add comprehensive monitoring, logging, and observability to the LiteLLM chat application
**Approach:** Deploy LiteLLM Proxy Server with built-in admin dashboard for cost tracking, request logging, and performance metrics

## Overview

Enhance the existing LiteLLM chat application with production-grade observability by deploying the LiteLLM Proxy Server. This adds a centralized API gateway with automatic request logging, cost tracking, performance metrics, and an admin dashboard - all without requiring external observability tools.

## Goals

- **Track LLM usage and costs:** Monitor requests, tokens, and costs per request in real-time
- **Application health:** Track response times, error rates, and uptime
- **Request/response logging:** Full payload logging for debugging and analysis
- **Visual dashboard:** Admin UI for exploring metrics without CLI tools
- **Zero external dependencies:** Self-contained observability using SQLite

## Current vs New Architecture

**Current (Phase 1):**
```
[Frontend] → [Backend + LiteLLM SDK] → [Custom LLM]
```

**New (with Proxy):**
```
[Frontend] → [Backend] → [LiteLLM Proxy + Dashboard] → [Custom LLM]
                              ↓
                         [SQLite DB]
```

**Key changes:**
1. New service: LiteLLM Proxy (runs as separate pod)
2. Backend calls proxy instead of LLM directly
3. Proxy handles observability automatically via middleware
4. Admin UI accessible via OpenShift Route

## Components

### 1. LiteLLM Proxy Container

**Image:** `ghcr.io/berriai/litellm:main-latest` (official GitHub Container Registry)

**Ports:**
- 4000: API endpoint (backend calls this)
- UI accessible at `/ui` path on same port

**Configuration:** Loaded from ConfigMap (`config.yaml`)

**Database:** SQLite at `/app/data/litellm.db` (ephemeral storage)

**Resource requirements:**
- Memory: 200-300MB
- CPU: 0.25 cores
- Storage: emptyDir volume for SQLite

### 2. Proxy Configuration (ConfigMap)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: litellm-proxy-config
data:
  config.yaml: |
    model_list:
      - model_name: custom-llm
        litellm_params:
          model: openai/gpt-3.5-turbo  # OpenAI-compatible format
          api_base: os.environ/LLM_API_BASE
          api_key: os.environ/LLM_API_KEY

    litellm_settings:
      success_callback: []
      cache: true

    general_settings:
      master_key: os.environ/PROXY_MASTER_KEY
      database_url: os.environ/DATABASE_URL
```

**Model mapping:**
- `model_name: custom-llm` - alias used by backend
- `api_base: os.environ/LLM_API_BASE` - actual LLM endpoint
- `api_key: os.environ/LLM_API_KEY` - external LLM authentication

### 3. Backend Integration

**Current backend code:**
```python
import litellm

response = litellm.completion(
    model=LLM_MODEL,
    messages=[{"role": "user", "content": request.message}],
    api_key=LLM_API_KEY,
    api_base=LLM_API_BASE
)
```

**New backend code:**
```python
from openai import OpenAI

client = OpenAI(
    api_key=PROXY_API_KEY,  # PROXY_MASTER_KEY from secret
    base_url="http://litellm-proxy:4000"
)

response = client.chat.completions.create(
    model="custom-llm",  # matches model_name in proxy config
    messages=[{"role": "user", "content": request.message}]
)
```

**Benefits:**
- Standard OpenAI SDK (widely documented)
- Proxy handles retries, caching, rate limiting
- All observability automatic
- Can switch LLM providers without backend changes

### 4. Secrets Management

**Updated .env file:**
```bash
# Existing
LLM_API_BASE=https://your-llm-endpoint.com/v1
LLM_API_KEY=your-api-key-here
LLM_MODEL=gpt-3.5-turbo

# New for proxy
PROXY_MASTER_KEY=sk-1234567890abcdef  # User creates this
```

**Secret keys explained:**
- `LLM_API_KEY`: External authentication (Proxy → Custom LLM)
- `PROXY_MASTER_KEY`: Internal authentication (Backend → Proxy, User → Admin UI)

**Environment variables:**

For proxy container:
- `LLM_API_BASE` - Custom LLM endpoint URL
- `LLM_API_KEY` - API key for custom LLM
- `PROXY_MASTER_KEY` - Admin authentication
- `DATABASE_URL` - SQLite connection string

For backend container:
- `PROXY_API_KEY` - Set to PROXY_MASTER_KEY value
- `LITELLM_PROXY_URL` - Set to `http://litellm-proxy:4000`

## Kubernetes Resources

### New Resources

**1. litellm-proxy Deployment**
- 1 replica
- Mounts ConfigMap at `/app/config.yaml`
- emptyDir volume for SQLite at `/app/data`
- Health checks on port 4000

**2. litellm-proxy Service**
- Type: ClusterIP
- Port: 4000
- Selector: `app: litellm-proxy`

**3. litellm-proxy-ui Route**
- Exposes proxy service
- Path: `/ui` (admin dashboard)
- TLS: edge termination

**4. litellm-proxy-config ConfigMap**
- Contains proxy configuration YAML
- Model mappings and settings

### Updated Resources

**1. litellm-secrets Secret**
- Add `PROXY_MASTER_KEY` key

**2. backend Deployment**
- Update environment variables
- Add `PROXY_API_KEY` and `LITELLM_PROXY_URL`
- New backend code requires image rebuild

## Request Flow

```
1. User types message in chat
   ↓
2. Frontend → POST /api/chat → Backend
   ↓
3. Backend → POST http://litellm-proxy:4000/chat/completions
   ↓
4. Proxy logs request metadata (timestamp, model, tokens)
   ↓
5. Proxy → POST https://custom-llm-endpoint.com/v1/chat/completions
   ↓
6. Custom LLM processes and responds
   ↓
7. Proxy logs response (tokens, cost, latency)
   ↓
8. Proxy → Backend → Frontend → User
   ↓
9. Proxy stores in SQLite for dashboard
```

## Observability Features

### Admin Dashboard

**Access:**
```bash
oc get route litellm-proxy-ui -o jsonpath='{.spec.host}'
# Visit: https://litellm-proxy-ui-<namespace>.apps.../ui
# Login: admin / <PROXY_MASTER_KEY>
```

**Dashboard tabs:**

**1. Usage Tab**
- Real-time request count
- Cost breakdown by model
- Token usage over time
- Top users/keys by usage

**2. Logs Tab**
- Searchable request/response logs
- Filter by timestamp, model, status
- Full payload inspection
- Error traces

**3. Models Tab**
- List configured models
- Add/edit/delete without redeploying
- Test models from UI
- Per-model metrics

**4. API Keys Tab**
- Create user/team keys
- Budget limits per key
- Rate limiting
- Key revocation

**5. Settings Tab**
- Cache configuration
- Logging levels
- Global rate limits
- Database info

### Automatic Metrics

**Per request:**
- Timestamp
- Model used
- Prompt tokens
- Completion tokens
- Total tokens
- Cost (USD)
- Latency (ms)
- Status code
- Error details (if failed)

**Aggregated:**
- Total requests
- Total cost
- Average latency
- Error rate
- Cache hit rate
- Requests per model
- Cost per model

## Database Strategy

**SQLite (Ephemeral)**

**Storage location:** `/app/data/litellm.db` on emptyDir volume

**Pros:**
- Zero setup complexity
- No external database needed
- Perfect for learning/POC

**Cons:**
- Data lost on pod restart
- Not suitable for production
- Single-replica only

**Tables created automatically:**
- `request_logs` - Request/response data
- `api_keys` - Generated keys with budgets
- `cache` - Cached LLM responses
- `models` - Model configurations

**Data retention:**
- All data persists until pod restart
- Acceptable for learning purposes
- Can upgrade to PostgreSQL later if needed

## Implementation Steps

### Phase 1: Infrastructure Setup
1. Create ConfigMap with proxy configuration
2. Update Secret with PROXY_MASTER_KEY
3. Create proxy Deployment
4. Create proxy Service
5. Create proxy UI Route
6. Verify proxy starts and UI accessible

### Phase 2: Backend Integration
1. Update backend/requirements.txt (add openai SDK)
2. Modify backend/app.py to call proxy
3. Update backend environment variables
4. Rebuild backend image (new version tag)
5. Push to Docker Hub
6. Update backend Deployment
7. Redeploy backend

### Phase 3: Verification
1. Test chat functionality still works
2. Access admin UI dashboard
3. Send test messages
4. Verify logs appear in dashboard
5. Check cost tracking
6. Verify metrics collection

## Security Considerations

**1. API Key Management**
- PROXY_MASTER_KEY acts as both admin password and API key
- Use strong random string (min 32 characters)
- Never commit to Git
- Rotate periodically

**2. Network Security**
- Proxy not exposed externally (ClusterIP)
- Only UI exposed via Route with TLS
- Backend-to-proxy communication internal only

**3. Data Privacy**
- Request/response bodies stored in SQLite
- Database on ephemeral storage (auto-deleted)
- Consider disabling body logging for sensitive data
- Configure via `litellm.turn_off_message_logging=True`

## Configuration Options

**Caching:**
```yaml
litellm_settings:
  cache: true
  cache_params:
    type: redis  # or s3, local
```

**Rate Limiting:**
```yaml
general_settings:
  rpm_limit: 100  # requests per minute
  tpm_limit: 10000  # tokens per minute
```

**Budget Alerts:**
```yaml
general_settings:
  budget_alert_threshold: 10  # Alert at $10
  budget_hard_limit: 50  # Block at $50
```

**Logging Levels:**
```yaml
litellm_settings:
  set_verbose: true  # Detailed logs
  success_callback: ["langfuse"]  # External platform
```

## Learning Outcomes

After implementing LiteLLM Proxy monitoring:

**Observability:**
- Understand centralized logging patterns
- Learn cost tracking for LLM applications
- Experience real-time metrics dashboards
- Practice API gateway concepts

**Architecture:**
- Multi-service communication patterns
- ConfigMap-based configuration
- Secret management across services
- Service discovery in Kubernetes

**LiteLLM Features:**
- Model management and routing
- Caching strategies
- Rate limiting and budgets
- Multi-provider support

## Future Enhancements

**Phase 3 Options:**

1. **Persistent Storage:** Add PersistentVolumeClaim for SQLite
2. **PostgreSQL:** Upgrade to production database
3. **External Observability:** Integrate Prometheus/Grafana
4. **Multiple Models:** Add GPT-4, Claude, etc. with routing
5. **User Authentication:** Multi-tenant API key management
6. **Alerting:** Budget alerts via webhook/email

## Troubleshooting

**Common Issues:**

**Proxy won't start:**
- Check ConfigMap syntax (`oc describe cm litellm-proxy-config`)
- Verify secret keys exist (`oc get secret litellm-secrets -o yaml`)
- Check logs (`oc logs deployment/litellm-proxy`)

**Backend can't reach proxy:**
- Verify service exists (`oc get svc litellm-proxy`)
- Check backend environment variables
- Test connectivity: `oc exec -it deployment/backend -- curl http://litellm-proxy:4000/health`

**Admin UI 404:**
- Verify route exists (`oc get route litellm-proxy-ui`)
- Check path is `/ui` not `/`
- Ensure proxy is running (`oc get pods`)

**No logs appearing:**
- Verify requests reaching proxy (check proxy logs)
- Ensure database_url configured correctly
- Check SQLite file exists: `oc exec deployment/litellm-proxy -- ls -la /app/data/`

## Success Criteria

**Infrastructure:**
- ✅ Proxy pod running and healthy
- ✅ Admin UI accessible via route
- ✅ Can login with PROXY_MASTER_KEY
- ✅ ConfigMap loaded correctly

**Backend Integration:**
- ✅ Backend successfully calls proxy
- ✅ Chat functionality works end-to-end
- ✅ No errors in backend logs

**Observability:**
- ✅ Requests appear in dashboard logs
- ✅ Token counts tracked accurately
- ✅ Cost calculations displayed
- ✅ Latency metrics collected
- ✅ Can filter/search logs in UI

## Resources

- [LiteLLM Proxy Documentation](https://docs.litellm.ai/docs/proxy/deploy)
- [LiteLLM Logging](https://docs.litellm.ai/docs/proxy/logging)
- [OpenTelemetry Integration](https://docs.litellm.ai/docs/observability/opentelemetry_integration)
- [LiteLLM Datadog Integration](https://docs.datadoghq.com/integrations/litellm/)
- [Langfuse Integration](https://langfuse.com/integrations/gateways/litellm)

## Next Steps

1. Create implementation plan with detailed tasks
2. Set up proxy infrastructure (ConfigMap, Deployment, Service, Route)
3. Integrate backend with proxy
4. Test and verify observability features
5. Document usage patterns and dashboard navigation
6. Consider future enhancements (PostgreSQL, multiple models, etc.)
