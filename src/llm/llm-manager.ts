import { BaseLLMProvider } from './base-provider';
import { AnthropicProvider } from './anthropic-provider';
import { OpenAIProvider } from './openai-provider';
import { LLMResponse } from '../types';
import { config } from '../config';
import { logger } from '../utils/logger';

export class LLMManager {
  private readonly primaryProvider: BaseLLMProvider;
  private readonly fallbackProvider: BaseLLMProvider;

  constructor() {
    this.primaryProvider = this.createProvider(config.llm.primary);
    this.fallbackProvider = this.createProvider(config.llm.fallback);
  }

  async generateReview(
    prompt: string,
    code: string,
    context: Map<string, any>
  ): Promise<LLMResponse> {
    try {
      logger.info(`Attempting review with primary provider: ${config.llm.primary.name}`);
      return await this.primaryProvider.generateReview(prompt, code, context);
    } catch (primaryError) {
      logger.warn(`Primary provider failed: ${primaryError}. Trying fallback provider.`);

      try {
        logger.info(`Attempting review with fallback provider: ${config.llm.fallback.name}`);
        return await this.fallbackProvider.generateReview(prompt, code, context);
      } catch (fallbackError) {
        logger.error(`Both providers failed. Primary: ${primaryError}, Fallback: ${fallbackError}`);
        throw new Error(
          `All LLM providers failed. Primary: ${primaryError}, Fallback: ${fallbackError}`
        );
      }
    }
  }

  private createProvider(providerConfig: typeof config.llm.primary): BaseLLMProvider {
    switch (providerConfig.name) {
      case 'anthropic':
        return new AnthropicProvider(providerConfig);
      case 'openai':
        return new OpenAIProvider(providerConfig);
      default:
        throw new Error(`Unsupported LLM provider: ${providerConfig.name}`);
    }
  }

  getProviderStatus(): {
    primary: { name: string; model: string; available: boolean };
    fallback: { name: string; model: string; available: boolean };
  } {
    return {
      primary: {
        name: config.llm.primary.name,
        model: config.llm.primary.model,
        available: !!config.llm.primary.apiKey,
      },
      fallback: {
        name: config.llm.fallback.name,
        model: config.llm.fallback.model,
        available: !!config.llm.fallback.apiKey,
      },
    };
  }
}
