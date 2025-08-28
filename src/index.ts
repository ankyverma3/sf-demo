import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from './config';
import { logger } from './utils/logger';
import { WebhookHandler } from './handlers/webhook-handler';

class CirusApp {
  private readonly app: express.Application;
  private readonly webhookHandler: WebhookHandler;

  constructor() {
    this.app = express();
    this.webhookHandler = new WebhookHandler();
    this.setupMiddleware();
    this.setupRoutes();
    this.setupErrorHandling();
  }

  private setupMiddleware(): void {
    this.app.use(helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'"],
          scriptSrc: ["'self'"],
          imgSrc: ["'self'", "data:", "https:"],
        },
      },
    }));

    this.app.use(cors({
      origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
      credentials: true,
    }));

    this.app.use(express.json({ 
      limit: '10mb',
      verify: (req: any, _res, buf) => {
        req.rawBody = buf;
      }
    }));

    this.app.use(express.urlencoded({ extended: true, limit: '10mb' }));

    this.app.use((req, _res, next) => {
      logger.info(`${req.method} ${req.path}`, {
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        timestamp: new Date().toISOString(),
      });
      next();
    });
  }

  private setupRoutes(): void {
    this.app.get('/health', this.webhookHandler.healthCheck.bind(this.webhookHandler));
    
    this.app.get('/', (_req, res) => {
      res.json({
        name: 'Cirus GitHub App',
        version: '1.0.0',
        description: 'AI-powered Salesforce code review bot',
        status: 'running',
        endpoints: {
          health: '/health',
          webhook: '/webhook',
        },
      });
    });

    this.app.post('/webhook', this.webhookHandler.handleWebhook.bind(this.webhookHandler));

    this.app.use('*', (_req, res) => {
      res.status(404).json({
        error: 'Not Found',
        message: 'The requested endpoint does not exist',
      });
    });
  }

  private setupErrorHandling(): void {
    this.app.use((error: Error, req: express.Request, res: express.Response, _next: express.NextFunction) => {
      logger.error('Unhandled error:', {
        error: error.message,
        stack: error.stack,
        method: req.method,
        path: req.path,
        timestamp: new Date().toISOString(),
      });

      if (config.server.nodeEnv === 'production') {
        res.status(500).json({
          error: 'Internal Server Error',
          message: 'Something went wrong. Please try again later.',
        });
      } else {
        res.status(500).json({
          error: 'Internal Server Error',
          message: error.message,
          stack: error.stack,
        });
      }
    });

    process.on('uncaughtException', (error) => {
      logger.error('Uncaught Exception:', error);
      process.exit(1);
    });

    process.on('unhandledRejection', (reason, promise) => {
      logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
      process.exit(1);
    });

    process.on('SIGTERM', () => {
      logger.info('SIGTERM received, shutting down gracefully');
      process.exit(0);
    });

    process.on('SIGINT', () => {
      logger.info('SIGINT received, shutting down gracefully');
      process.exit(0);
    });
  }

  public start(): void {
    const port = config.server.port;
    
    this.app.listen(port, '0.0.0.0', () => {
      logger.info(`🚀 Cirus GitHub App started successfully`);
      logger.info(`📡 Server running on port ${port}`);
      logger.info(`🔧 Environment: ${config.server.nodeEnv}`);
      logger.info(`🤖 LLM Provider: ${config.llm.primary.name} (${config.llm.primary.model})`);
      logger.info(`🔄 Fallback Provider: ${config.llm.fallback.name} (${config.llm.fallback.model})`);
      
      if (config.server.nodeEnv === 'development') {
        logger.info(`🌐 Health check: http://localhost:${port}/health`);
        logger.info(`📋 Webhook endpoint: http://localhost:${port}/webhook`);
      }
    });
  }
}

if (require.main === module) {
  const app = new CirusApp();
  app.start();
}

export default CirusApp;