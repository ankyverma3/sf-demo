import { Request, Response } from 'express';
import { Webhooks } from '@octokit/webhooks';
import crypto from 'crypto';
import { config } from '../config';
import { logger } from '../utils/logger';
import { ReviewService } from '../services/review-service';
import { ReviewRequest } from '../types';
import { PullRequestEvent } from '@octokit/webhooks-types';

export class WebhookHandler {
  private readonly webhooks: Webhooks;
  private readonly reviewService: ReviewService;

  constructor() {
    this.webhooks = new Webhooks({
      secret: config.github.webhookSecret,
    });

    this.reviewService = new ReviewService();
    this.setupEventHandlers();
  }

  async handleWebhook(req: Request, res: Response): Promise<void> {
    const signature = req.headers['x-hub-signature-256'] as string;
    const payload = JSON.stringify(req.body);

    try {
      if (!this.verifySignature(payload, signature)) {
        logger.warn('Invalid webhook signature');
        res.status(401).json({ error: 'Invalid signature' });
        return;
      }

      const event = req.headers['x-github-event'] as string;
      const deliveryId = req.headers['x-github-delivery'] as string;

      logger.info(`Received webhook: ${event} (${deliveryId})`);

      await this.webhooks.verifyAndReceive({
        id: deliveryId,
        name: event as any,
        payload: payload,
        signature: signature,
      });

      res.status(200).json({ message: 'Webhook processed successfully' });
    } catch (error) {
      logger.error('Webhook processing failed:', error);
      res.status(500).json({ error: 'Webhook processing failed' });
    }
  }

  private setupEventHandlers(): void {
    this.webhooks.on('pull_request.opened', this.handlePullRequestEvent.bind(this));
    this.webhooks.on('pull_request.synchronize', this.handlePullRequestEvent.bind(this));
    this.webhooks.on('pull_request.reopened', this.handlePullRequestEvent.bind(this));

    this.webhooks.onError((error) => {
      logger.error('Webhook error:', error);
    });
  }

  private async handlePullRequestEvent({ payload }: { payload: PullRequestEvent }): Promise<void> {
    const { action, pull_request, repository, installation } = payload;

    if (!installation) {
      logger.warn('No installation found in webhook payload');
      return;
    }

    logger.info(`Processing PR ${action}: ${repository.full_name}#${pull_request.number}`);

    if (action === 'closed') {
      logger.info('PR closed, skipping review');
      return;
    }

    try {
      const reviewRequest: ReviewRequest = {
        repositoryName: repository.full_name,
        pullRequestNumber: pull_request.number,
        changedFiles: [], // Will be fetched by ReviewService
        contextFiles: [],
        installationId: installation.id,
        headSha: pull_request.head.sha,
      };

      // Process review asynchronously to avoid webhook timeout
      this.processReviewAsync(reviewRequest);
    } catch (error) {
      logger.error(`Failed to process PR event:`, error);
    }
  }

  private async processReviewAsync(request: ReviewRequest): Promise<void> {
    try {
      await this.reviewService.reviewPullRequest(request);
    } catch (error) {
      logger.error('Async review processing failed:', error);
    }
  }

  private verifySignature(payload: string, signature: string): boolean {
    try {
      if (!signature || !signature.startsWith('sha256=')) {
        return false;
      }

      const expectedSignature = crypto
        .createHmac('sha256', config.github.webhookSecret)
        .update(payload)
        .digest('hex');

      const receivedSignature = signature.replace('sha256=', '');

      return crypto.timingSafeEqual(
        Buffer.from(expectedSignature, 'hex'),
        Buffer.from(receivedSignature, 'hex')
      );
    } catch (error) {
      logger.error('Signature verification failed:', error);
      return false;
    }
  }

  async healthCheck(_req: Request, res: Response): Promise<void> {
    const llmStatus = this.reviewService['llmManager']?.getProviderStatus() || {
      primary: { name: 'unknown', model: 'unknown', available: false },
      fallback: { name: 'unknown', model: 'unknown', available: false },
    };

    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
      github: {
        appId: config.github.appId,
        webhookConfigured: !!config.github.webhookSecret,
      },
      llm: llmStatus,
      environment: config.server.nodeEnv,
    };

    res.status(200).json(health);
  }
}
