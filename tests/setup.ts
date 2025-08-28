// Test setup file

// Clear any existing environment variables that might interfere
delete process.env.GITHUB_TOKEN;

// Clear potentially conflicting environment variables
delete process.env.MAX_CONTEXT_FILES;
delete process.env.MAX_FILE_SIZE_KB;
delete process.env.REVIEW_TIMEOUT_MS;
delete process.env.PORT;
delete process.env.LOG_LEVEL;

// Set required test environment variables
process.env.NODE_ENV = 'test';
process.env.GITHUB_APP_ID = 'test_app_id';
process.env.GITHUB_PRIVATE_KEY = 'test_private_key';
process.env.GITHUB_WEBHOOK_SECRET = 'test_webhook_secret';
process.env.LLM_PROVIDER = 'anthropic';
process.env.LLM_MODEL = 'claude-3-5-sonnet';
process.env.LLM_API_KEY = 'test_api_key';
process.env.FALLBACK_LLM_PROVIDER = 'openai';
process.env.FALLBACK_LLM_MODEL = 'gpt-4';
process.env.FALLBACK_LLM_API_KEY = 'test_fallback_api_key';