import dotenv from 'dotenv';
import Joi from 'joi';
import { AppConfig } from '../types';

dotenv.config();

const configSchema = Joi.object({
  PORT: Joi.number().default(3000),
  NODE_ENV: Joi.string().valid('development', 'production', 'test').default('development'),

  GITHUB_APP_ID: Joi.string().required(),
  GITHUB_PRIVATE_KEY: Joi.string().required(),
  GITHUB_WEBHOOK_SECRET: Joi.string().required(),

  LLM_PROVIDER: Joi.string().valid('anthropic', 'openai').required(),
  LLM_MODEL: Joi.string().required(),
  LLM_API_KEY: Joi.string().required(),

  FALLBACK_LLM_PROVIDER: Joi.string().valid('anthropic', 'openai').required(),
  FALLBACK_LLM_MODEL: Joi.string().required(),
  FALLBACK_LLM_API_KEY: Joi.string().required(),

  MAX_CONTEXT_FILES: Joi.number().default(10),
  MAX_FILE_SIZE_KB: Joi.number().default(100),
  REVIEW_TIMEOUT_MS: Joi.number().default(300000),

  LOG_LEVEL: Joi.string().valid('error', 'warn', 'info', 'debug').default('info'),
});

const { error, value: envVars } = configSchema.validate(process.env, { allowUnknown: true });

if (error) {
  throw new Error(`Config validation error: ${error.message}`);
}

export const config: AppConfig = {
  server: {
    port: envVars.PORT,
    nodeEnv: envVars.NODE_ENV,
  },
  github: {
    appId: envVars.GITHUB_APP_ID,
    privateKey: envVars.GITHUB_PRIVATE_KEY.replace(/\\n/g, '\n'),
    webhookSecret: envVars.GITHUB_WEBHOOK_SECRET,
  },
  llm: {
    primary: {
      name: envVars.LLM_PROVIDER,
      model: envVars.LLM_MODEL,
      apiKey: envVars.LLM_API_KEY,
    },
    fallback: {
      name: envVars.FALLBACK_LLM_PROVIDER,
      model: envVars.FALLBACK_LLM_MODEL,
      apiKey: envVars.FALLBACK_LLM_API_KEY,
    },
  },
  review: {
    maxContextFiles: envVars.MAX_CONTEXT_FILES,
    maxFileSizeKb: envVars.MAX_FILE_SIZE_KB,
    timeoutMs: envVars.REVIEW_TIMEOUT_MS,
  },
  logging: {
    level: envVars.LOG_LEVEL,
  },
};
