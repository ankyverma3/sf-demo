import { Octokit } from '@octokit/rest';
import { createAppAuth } from '@octokit/auth-app';
import { config } from '../config';
import { logger } from '../utils/logger';
import { FileChange, GitHubPullRequestReview } from '../types';

export class GitHubClient {
  constructor() {
    // Base octokit instance not needed since we create installation-specific instances
  }

  async getInstallationOctokit(installationId: number): Promise<Octokit> {
    return new Octokit({
      authStrategy: createAppAuth,
      auth: {
        appId: config.github.appId,
        privateKey: config.github.privateKey,
        installationId,
      },
    });
  }

  async getPullRequestFiles(
    owner: string,
    repo: string,
    pullNumber: number,
    installationId: number
  ): Promise<FileChange[]> {
    try {
      const octokit = await this.getInstallationOctokit(installationId);

      const { data: files } = await octokit.rest.pulls.listFiles({
        owner,
        repo,
        pull_number: pullNumber,
      });

      return files.map((file) => ({
        filename: file.filename,
        status: file.status as 'added' | 'modified' | 'removed',
        additions: file.additions,
        deletions: file.deletions,
        changes: file.changes,
        patch: file.patch || undefined,
        blob_url: file.blob_url,
        raw_url: file.raw_url,
      }));
    } catch (error) {
      logger.error('Failed to fetch PR files:', error);
      throw new Error(`Failed to fetch PR files: ${error}`);
    }
  }

  async getFileContent(
    owner: string,
    repo: string,
    path: string,
    ref: string,
    installationId: number
  ): Promise<string> {
    try {
      const octokit = await this.getInstallationOctokit(installationId);

      const { data } = await octokit.rest.repos.getContent({
        owner,
        repo,
        path,
        ref,
      });

      if (Array.isArray(data) || data.type !== 'file') {
        throw new Error(`Path ${path} is not a file`);
      }

      if (data.size > config.review.maxFileSizeKb * 1024) {
        logger.warn(`File ${path} exceeds size limit: ${data.size} bytes`);
        return '';
      }

      return Buffer.from(data.content, 'base64').toString('utf-8');
    } catch (error) {
      logger.error(`Failed to fetch file content for ${path}:`, error);
      throw new Error(`Failed to fetch file content: ${error}`);
    }
  }

  async createReviewComment(
    owner: string,
    repo: string,
    pullNumber: number,
    commitSha: string,
    path: string,
    line: number,
    body: string,
    installationId: number
  ): Promise<void> {
    try {
      const octokit = await this.getInstallationOctokit(installationId);

      await octokit.rest.pulls.createReviewComment({
        owner,
        repo,
        pull_number: pullNumber,
        commit_id: commitSha,
        path,
        line,
        body,
      });

      logger.info(`Created review comment on ${path}:${line}`);
    } catch (error) {
      logger.error(`Failed to create review comment on ${path}:${line}:`, error);
      throw new Error(`Failed to create review comment: ${error}`);
    }
  }

  async createIssueComment(
    owner: string,
    repo: string,
    issueNumber: number,
    body: string,
    installationId: number
  ): Promise<void> {
    try {
      const octokit = await this.getInstallationOctokit(installationId);

      await octokit.rest.issues.createComment({
        owner,
        repo,
        issue_number: issueNumber,
        body,
      });

      logger.info(`Created issue comment on PR #${issueNumber}`);
    } catch (error) {
      logger.error(`Failed to create issue comment on PR #${issueNumber}:`, error);
      throw new Error(`Failed to create issue comment: ${error}`);
    }
  }

  async findExistingFiles(
    owner: string,
    repo: string,
    ref: string,
    filePaths: string[],
    installationId: number
  ): Promise<string[]> {
    const existingFiles: string[] = [];
    const octokit = await this.getInstallationOctokit(installationId);

    for (const filePath of filePaths) {
      try {
        await octokit.rest.repos.getContent({
          owner,
          repo,
          path: filePath,
          ref,
        });
        existingFiles.push(filePath);
      } catch (error) {
        logger.debug(`File ${filePath} not found in repository`);
      }
    }

    return existingFiles;
  }

  async searchCodeInRepository(
    owner: string,
    repo: string,
    query: string,
    installationId: number
  ): Promise<string[]> {
    try {
      const octokit = await this.getInstallationOctokit(installationId);

      const { data } = await octokit.rest.search.code({
        q: `${query} repo:${owner}/${repo}`,
        per_page: 10,
      });

      return data.items.map((item) => item.path);
    } catch (error) {
      logger.error(`Failed to search code in repository:`, error);
      return [];
    }
  }

  async createPullRequestReview(
    owner: string,
    repo: string,
    pullNumber: number,
    commitSha: string,
    review: GitHubPullRequestReview,
    installationId: number
  ): Promise<void> {
    try {
      const octokit = await this.getInstallationOctokit(installationId);

      logger.info(`Creating PR review with ${review.comments.length} inline comments`);

      const reviewData = {
        owner,
        repo,
        pull_number: pullNumber,
        commit_id: commitSha,
        event: review.event,
        body: review.body,
        comments: review.comments.map((comment) => ({
          path: comment.path,
          line: comment.line,
          body: comment.body,
        })),
      };

      const { data } = await octokit.rest.pulls.createReview(reviewData);

      logger.info(
        `Successfully created PR review #${data.id} with ${review.comments.length} comments`
      );
    } catch (error) {
      logger.error(`Failed to create PR review:`, error);
      throw new Error(`Failed to create PR review: ${error}`);
    }
  }
}
