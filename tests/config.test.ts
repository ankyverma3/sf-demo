import { config } from '../src/config';

describe('Configuration', () => {
  it('should load configuration from environment variables', () => {
    expect(config.server.port).toBe(3000);
    expect(config.server.nodeEnv).toBe('test');
    expect(config.github.appId).toBe('test_app_id');
    expect(config.llm.primary.name).toBe('anthropic');
    expect(config.llm.fallback.name).toBe('openai');
  });

  it('should have valid LLM configuration', () => {
    expect(config.llm.primary.apiKey).toBeTruthy();
    expect(config.llm.fallback.apiKey).toBeTruthy();
  });

  it('should have review limits configured', () => {
    expect(config.review.maxContextFiles).toBe(10);
    expect(config.review.maxFileSizeKb).toBe(1000);
    expect(config.review.timeoutMs).toBe(300000);
  });
});