# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

geminicli2api is a FastAPI-based proxy server that converts Google's Gemini CLI tool into both OpenAI-compatible and native Gemini API endpoints. It allows users to leverage Google's free Gemini API quota through familiar OpenAI API interfaces.

## Development Commands

### Local Development
```bash
# Install dependencies
pip install -r requirements.txt

# Run the application (standard port 8888)
python run.py

# Run for Hugging Face Spaces (port 7860)
python app.py
```

### Docker Development
```bash
# Build Docker image
docker build -t geminicli2api .

# Run with Docker Compose
docker-compose up

# Build and run in one command
docker-compose up --build
```

### Testing
The application includes health check endpoints for monitoring:
- `/health` - Basic health check
- Health checks are integrated into Docker containers

## Architecture Overview

### Core Components

1. **FastAPI Application** (`src/main.py`)
   - Main application with CORS middleware
   - Startup event handling for credential validation
   - Route registration for both API types

2. **Authentication System** (`src/auth.py`)
   - Multiple auth methods: Bearer token, Basic auth, API key, Google header
   - OAuth2 flow for Google credentials with automatic token refresh
   - User onboarding process

3. **Dual API Layer**
   - **OpenAI Compatibility** (`src/openai_routes.py`): `/v1/chat/completions`, `/v1/models`
   - **Native Gemini Proxy** (`src/gemini_routes.py`): `/v1beta/models`, etc.
   - **Request/Response Transformation** (`src/openai_transformers.py`): Bidirectional conversion

4. **Google API Client** (`src/google_api_client.py`)
   - Direct communication with Google's Gemini API
   - Handles authentication and request formatting

### Key Files Structure

```
src/
├── main.py              # FastAPI app setup and route registration
├── config.py            # Configuration constants and model definitions
├── models.py            # Pydantic models for OpenAI and Gemini formats
├── auth.py              # Authentication and OAuth2 flow handling
├── utils.py             # Utility functions (user agent, platform detection)
├── openai_routes.py     # OpenAI-compatible API endpoints
├── gemini_routes.py     # Native Gemini API endpoints
├── openai_transformers.py  # Request/response format conversion
└── google_api_client.py # Google API communication layer
```

### Model Variants System

The application supports advanced model variants:
- **Base models**: `gemini-2.5-pro`, `gemini-2.5-flash`, etc.
- **Search grounding**: Add `-search` suffix (e.g., `gemini-2.5-pro-search`)
- **Thinking control**: Add `-nothinking` or `-maxthinking` suffix

Model handling logic is centralized in `src/config.py` with the `get_base_model()` function.

### Authentication Flow

1. **Multiple Auth Methods**: The system checks for credentials in this order:
   - Bearer token in Authorization header
   - Basic auth credentials
   - API key in various headers
   - Google-specific headers

2. **OAuth2 Integration**: Automatic Google OAuth2 flow with token refresh
3. **Credential Sources**: Environment variables, credential files, or runtime OAuth

### Environment Configuration

**Required:**
- `GEMINI_AUTH_PASSWORD` - API authentication password

**Optional (in priority order):**
- `GEMINI_CREDENTIALS` - JSON credentials string
- `GOOGLE_APPLICATION_CREDENTIALS` - Path to credentials file
- `GOOGLE_CLOUD_PROJECT` - Google Cloud project ID

### Request/Response Transformation

The `openai_transformers.py` module handles:
- **OpenAI to Gemini**: Message format, role mapping, multimodal content
- **Gemini to OpenAI**: Response format, streaming support, usage statistics
- **Streaming Support**: Real-time response streaming for both API types

### Deployment Patterns

1. **Local Development**: Direct Python execution
2. **Docker**: Multi-stage build with security best practices (non-root user)
3. **Docker Compose**: Environment variable configuration
4. **Hugging Face Spaces**: Automatic deployment via `app.py`
5. **CI/CD**: GitHub Actions workflow builds and pushes to GHCR

### Security Considerations

- Non-root Docker execution
- Credential handling with multiple fallback methods
- CORS middleware configuration
- API key authentication with multiple header support
- OAuth2 flow with automatic token refresh

## Common Development Patterns

### Adding New Model Support
1. Update model lists in `src/config.py`
2. Add any special handling in `get_base_model()` function
3. Update transformation logic in `openai_transformers.py` if needed

### Extending Authentication
1. Modify `extract_credentials()` function in `src/auth.py`
2. Add new authentication method to the priority chain
3. Update credential validation logic

### Adding New API Endpoints
1. Create route handlers in appropriate files (`openai_routes.py` or `gemini_routes.py`)
2. Add request/response models to `src/models.py`
3. Register routes in `src/main.py`

### Environment Variables
All environment configuration is handled in `src/config.py`. Add new environment variables there with appropriate defaults and validation.