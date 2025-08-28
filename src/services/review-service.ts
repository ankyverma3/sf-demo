import { GitHubClient } from '../github/client';
// import { ContextFetcher } from './context-fetcher'; // TODO: Re-enable for context fetching
import { LLMManager } from '../llm/llm-manager';
import { SalesforcePrompts } from '../analyzers/salesforce-prompts';
import { SalesforceFileDetector } from '../utils/salesforce-files';
import { logger } from '../utils/logger';
import {
  ReviewRequest,
  LLMResponse,
  CodeReviewFeedback,
  GitHubPullRequestReview,
  GitHubReviewComment,
  PRAnalysisContext,
  FileChange,
} from '../types';

export class ReviewService {
  private readonly githubClient: GitHubClient;
  private readonly llmManager: LLMManager;

  constructor() {
    this.githubClient = new GitHubClient();
    this.llmManager = new LLMManager();
  }

  async reviewPullRequest(request: ReviewRequest): Promise<void> {
    const { repositoryName, pullRequestNumber, installationId, headSha } = request;
    const repoParts = repositoryName.split('/');

    if (repoParts.length !== 2) {
      throw new Error(`Invalid repository name format: ${repositoryName}`);
    }

    const [owner, repo] = repoParts as [string, string];

    try {
      logger.info(`Starting review for PR #${pullRequestNumber} in ${repositoryName}`);

      // First, get the actual changed files from GitHub
      const actualChangedFiles = await this.githubClient.getPullRequestFiles(
        owner,
        repo,
        pullRequestNumber,
        installationId
      );

      logger.info(
        `Found ${actualChangedFiles.length} changed files:`,
        actualChangedFiles.map((f) => f.filename)
      );

      const salesforceFiles = actualChangedFiles.filter(
        (file) =>
          file.status !== 'removed' && SalesforceFileDetector.isSalesforceFile(file.filename)
      );

      logger.info(
        `Detected ${salesforceFiles.length} Salesforce files:`,
        salesforceFiles.map((f) => f.filename)
      );

      if (salesforceFiles.length === 0) {
        logger.info('No Salesforce files to review, skipping');
        logger.info('Supported Salesforce file extensions:', [
          '.cls',
          '.trigger',
          '.js',
          '.html',
          '.css',
          '.cmp',
          '.app',
          '.object-meta.xml',
          '.field-meta.xml',
          '.flow-meta.xml',
          '.permissionset-meta.xml',
          '.profile-meta.xml',
        ]);
        return;
      }

      // Use the PR head SHA for fetching the correct file versions
      const prHeadSha = headSha || 'HEAD';
      logger.info(`Using git reference: ${prHeadSha}`);

      const reviewResults: LLMResponse[] = [];
      const allFeedback: CodeReviewFeedback[] = [];

      // Process each file individually - use PR diff for focused review
      for (const file of salesforceFiles) {
        try {
          logger.info(
            `Reviewing file: ${file.filename} (${file.changes} changes, +${file.additions}/-${file.deletions})`
          );

          // Use the patch (diff) as primary content for review
          const patchContent = file.patch;
          logger.info(
            `🔍 Patch content available: ${!!patchContent}, patch length: ${patchContent?.length || 0}`
          );

          let codeToReview = patchContent || '';

          if (!patchContent) {
            logger.warn(`No patch content for ${file.filename}, fetching full file`);
            // Fallback to full file content if patch is missing
            const fileContent = await this.githubClient.getFileContent(
              owner,
              repo,
              file.filename,
              prHeadSha,
              installationId
            );
            if (!fileContent) {
              logger.warn(`Skipping empty file: ${file.filename}`);
              continue;
            }
            codeToReview = fileContent;
          }

          logger.info(`📋 Code content for ${file.filename} (length: ${codeToReview.length})`);
          console.log(
            `🔍 First 500 chars of code for ${file.filename}:`,
            codeToReview.substring(0, 500)
          );

          const fileType = SalesforceFileDetector.getFileType(file.filename);
          const prompt = this.createPRReviewPrompt(fileType, file);

          console.log(
            `📝 Generated prompt for ${file.filename}:`,
            prompt.substring(0, 800) + '...'
          );

          // For now, start with empty context - we'll add context fetching later if needed
          const emptyContext = new Map<string, any>();

          const review = await this.llmManager.generateReview(prompt, codeToReview, emptyContext);

          console.log(`🤖 LLM Response for ${file.filename}:`, JSON.stringify(review, null, 2));

          review.feedback = review.feedback.map((feedback) => ({
            ...feedback,
            file: file.filename,
          }));

          reviewResults.push(review);
          allFeedback.push(...review.feedback);

          logger.info(
            `Completed review for ${file.filename}: ${review.feedback.length} issues found`
          );
        } catch (error) {
          logger.error(`Failed to review file ${file.filename}:`, error);
        }
      }

      // Create and post single batched review instead of individual comments
      await this.postBatchedPullRequestReview(
        owner,
        repo,
        pullRequestNumber,
        prHeadSha,
        reviewResults,
        allFeedback,
        installationId
      );

      logger.info(
        `Review completed for PR #${pullRequestNumber}: ${allFeedback.length} total issues found`
      );
    } catch (error) {
      logger.error(`Review failed for PR #${pullRequestNumber}:`, error);

      await this.postErrorComment(owner, repo, pullRequestNumber, error as Error, installationId);
    }
  }

  private async postBatchedPullRequestReview(
    owner: string,
    repo: string,
    pullNumber: number,
    commitSha: string,
    reviewResults: LLMResponse[],
    allFeedback: CodeReviewFeedback[],
    installationId: number
  ): Promise<void> {
    try {
      // Create inline comments from all feedback
      const inlineComments: GitHubReviewComment[] = allFeedback.map((feedback) => {
        const emoji = this.getSeverityEmoji(feedback.severity);
        const categoryTag = this.getCategoryTag(feedback.category);
        
        let body = `${emoji} **${categoryTag}**\n\n${feedback.message}`;
        
        // Add suggestion if available and valuable
        if (feedback.suggestion && feedback.suggestion.trim().length > 0) {
          body += `\n\n**💡 Suggestion:**\n${feedback.suggestion}`;
        }

        return {
          path: feedback.file,
          line: feedback.line,
          body,
        };
      });

      // Generate comprehensive summary with actual changed files data
      const actualChangedFilesForSummary = await this.githubClient.getPullRequestFiles(
        owner,
        repo,
        pullNumber,
        installationId
      );
      const summaryBody = this.generateSummary(reviewResults, allFeedback, actualChangedFilesForSummary);

      // Determine review event based on findings
      const hasCritical = allFeedback.some((f) => f.severity === 'critical');
      const reviewEvent = hasCritical
        ? 'REQUEST_CHANGES'
        : allFeedback.length > 0
          ? 'COMMENT'
          : 'APPROVE';

      // Create single batched PR review
      const pullRequestReview: GitHubPullRequestReview = {
        event: reviewEvent,
        body: summaryBody,
        comments: inlineComments,
      };

      await this.githubClient.createPullRequestReview(
        owner,
        repo,
        pullNumber,
        commitSha,
        pullRequestReview,
        installationId
      );

      logger.info(
        `Successfully posted batched PR review with ${inlineComments.length} inline comments and summary`
      );
    } catch (error) {
      logger.error('Failed to post batched PR review:', error);
      // Fallback to individual comments if batched review fails
      logger.info('Falling back to individual comments...');
      await this.postInlineComments(
        owner,
        repo,
        pullNumber,
        commitSha,
        allFeedback,
        installationId
      );
      await this.postSummaryComment(
        owner,
        repo,
        pullNumber,
        reviewResults,
        allFeedback,
        installationId
      );
    }
  }

  private async postInlineComments(
    owner: string,
    repo: string,
    pullNumber: number,
    commitSha: string,
    feedback: CodeReviewFeedback[],
    installationId: number
  ): Promise<void> {
    for (const comment of feedback) {
      try {
        const emoji = this.getSeverityEmoji(comment.severity);
        const categoryTag = this.getCategoryTag(comment.category);

        const body = `${emoji} **${categoryTag}**\n\n${comment.message}`;

        await this.githubClient.createReviewComment(
          owner,
          repo,
          pullNumber,
          commitSha,
          comment.file,
          comment.line,
          body,
          installationId
        );
      } catch (error) {
        logger.error(`Failed to post inline comment for ${comment.file}:${comment.line}:`, error);
      }
    }
  }

  private async postSummaryComment(
    owner: string,
    repo: string,
    pullNumber: number,
    reviewResults: LLMResponse[],
    allFeedback: CodeReviewFeedback[],
    installationId: number
  ): Promise<void> {
    try {
      const summary = this.generateSummary(reviewResults, allFeedback, []);
      await this.githubClient.createIssueComment(owner, repo, pullNumber, summary, installationId);
    } catch (error) {
      logger.error('Failed to post summary comment:', error);
    }
  }

  private async postErrorComment(
    owner: string,
    repo: string,
    pullNumber: number,
    error: Error,
    installationId: number
  ): Promise<void> {
    const errorMessage = `🤖 **Cirus Code Review - Error**

Unfortunately, I encountered an error while reviewing this PR:

\`\`\`
${error.message}
\`\`\`

Please check the logs or contact the maintainers if this persists.

---
*Powered by Cirus AI*`;

    try {
      await this.githubClient.createIssueComment(
        owner,
        repo,
        pullNumber,
        errorMessage,
        installationId
      );
    } catch (commentError) {
      logger.error('Failed to post error comment:', commentError);
    }
  }

  private generateSummary(reviewResults: LLMResponse[], allFeedback: CodeReviewFeedback[], changedFiles: FileChange[]): string {
    const totalIssues = allFeedback.length;
    const criticalIssues = allFeedback.filter((f) => f.severity === 'critical').length;
    const warnings = allFeedback.filter((f) => f.severity === 'warning').length;
    const improvements = allFeedback.filter((f) => f.severity === 'improvement').length;

    const categories = allFeedback.reduce(
      (acc, feedback) => {
        acc[feedback.category] = (acc[feedback.category] || 0) + 1;
        return acc;
      },
      {} as Record<string, number>
    );

    // Extract PR analysis context from LLM responses and actual file changes
    const prAnalysis = this.extractPRAnalysis(reviewResults, changedFiles);

    let summary = `## 🔍 **Code Review Analysis**

### **Overview**
${this.generateOverview(prAnalysis, reviewResults.length)}

${this.generateImpactAssessment(prAnalysis, totalIssues, criticalIssues)}

### **📊 Analysis Results**
- **Files Reviewed:** ${reviewResults.length} Salesforce files
- **Lines Changed:** +${prAnalysis.linesAdded}/-${prAnalysis.linesDeleted}
${totalIssues > 0 ? `- **Issues Found:** ${totalIssues} items requiring attention` : '- **Issues Found:** None'}`;

    if (totalIssues > 0) {
      summary += `\n\n### **🚨 Priority Actions**
- 🔴 **Critical (${criticalIssues})**: ${criticalIssues > 0 ? 'Requires immediate attention' : 'None'}
- 🟡 **Warning (${warnings})**: ${warnings > 0 ? 'Should be addressed' : 'None'}
- 🔵 **Enhancement (${improvements})**: ${improvements > 0 ? 'Optional improvements' : 'None'}`;

      if (Object.keys(categories).length > 0) {
        summary += `\n\n### **📋 Findings by Category**`;
        for (const [category, count] of Object.entries(categories)) {
          const categoryEmoji = this.getCategoryEmoji(category);
          summary += `\n- ${categoryEmoji} **${category}**: ${count}`;
        }
      }
    }

    summary += `\n\n### **✅ Recommendation**
${this.generateRecommendation(totalIssues, criticalIssues, prAnalysis)}

---
*🚀 Powered by Cirus AI - Context-aware Salesforce code reviews*`;

    return summary;
  }

  private extractPRAnalysis(reviewResults: LLMResponse[], changedFiles: FileChange[]): PRAnalysisContext {
    // Combine PR analysis from all LLM responses
    const combinedAnalysis = reviewResults.find(r => r.prAnalysis)?.prAnalysis;
    
    // Calculate actual stats from changed files
    const totalFiles = changedFiles.length;
    const totalAdded = changedFiles.reduce((sum, file) => sum + file.additions, 0);
    const totalDeleted = changedFiles.reduce((sum, file) => sum + file.deletions, 0);
    
    if (combinedAnalysis) {
      // Merge LLM analysis with actual file stats
      return {
        ...combinedAnalysis,
        totalFilesChanged: totalFiles,
        linesAdded: totalAdded,
        linesDeleted: totalDeleted,
      };
    }

    // Fallback: calculate basic stats from actual data
    return {
      totalFilesChanged: totalFiles,
      linesAdded: totalAdded,
      linesDeleted: totalDeleted,
      primaryChanges: [],
    };
  }

  private generateOverview(prAnalysis: PRAnalysisContext, filesCount: number): string {
    if (prAnalysis.overview) {
      return prAnalysis.overview;
    }

    // Fallback generic overview
    return `This pull request modifies ${filesCount} Salesforce ${filesCount === 1 ? 'file' : 'files'} with various improvements and updates.`;
  }

  private generateImpactAssessment(prAnalysis: PRAnalysisContext, totalIssues: number, criticalIssues: number): string {
    let riskLevel = prAnalysis.riskLevel;
    
    // Override risk assessment based on issues found if not provided
    if (!riskLevel) {
      if (criticalIssues > 0 || totalIssues > 10) {
        riskLevel = 'high';
      } else if (totalIssues > 3 || prAnalysis.linesAdded + prAnalysis.linesDeleted > 100) {
        riskLevel = 'medium';
      } else {
        riskLevel = 'low';
      }
    }

    const riskEmoji = riskLevel === 'high' ? '🔴' : riskLevel === 'medium' ? '🟡' : '🟢';
    const riskText = riskLevel === 'high' ? 'high' : riskLevel === 'medium' ? 'medium' : 'low';
    
    let impactAreas = '';
    if (prAnalysis.primaryChanges && prAnalysis.primaryChanges.length > 0) {
      impactAreas = ` affecting ${prAnalysis.primaryChanges.join(', ')}`;
    }

    return `**Impact Assessment:** ${riskEmoji} ${riskText.charAt(0).toUpperCase() + riskText.slice(1)} risk changes${impactAreas}.`;
  }

  private generateRecommendation(totalIssues: number, criticalIssues: number, prAnalysis: PRAnalysisContext): string {
    if (prAnalysis.recommendationSummary) {
      return prAnalysis.recommendationSummary;
    }

    if (totalIssues === 0) {
      return '**APPROVE** - No issues found. The code looks good to merge.';
    } else if (criticalIssues > 0) {
      return `**REQUEST_CHANGES** - Address ${criticalIssues} critical ${criticalIssues === 1 ? 'issue' : 'issues'} before merge. Other improvements will enhance code quality.`;
    } else {
      return `**COMMENT** - Consider addressing ${totalIssues} ${totalIssues === 1 ? 'suggestion' : 'suggestions'} to improve code quality, but no blocking issues found.`;
    }
  }

  private getSeverityEmoji(severity: string): string {
    switch (severity) {
      case 'critical':
        return '🔴';
      case 'warning':
        return '🟡';
      case 'improvement':
        return '🔵';
      default:
        return '📝';
    }
  }

  private getCategoryTag(category: string): string {
    switch (category) {
      case 'security':
        return 'Security Issue';
      case 'performance':
        return 'Performance';
      case 'maintainability':
        return 'Maintainability';
      case 'best-practice':
        return 'Best Practice';
      case 'bug':
        return 'Potential Bug';
      default:
        return 'Code Quality';
    }
  }

  private getCategoryEmoji(category: string): string {
    switch (category) {
      case 'security':
        return '🔒';
      case 'performance':
        return '⚡';
      case 'maintainability':
        return '🔧';
      case 'best-practice':
        return '📚';
      case 'bug':
        return '🐛';
      default:
        return '📝';
    }
  }

  private createPRReviewPrompt(fileType: any, file: any): string {
    const basePrompt = SalesforcePrompts.getPromptForFileType(fileType);

    return `${basePrompt}

**PULL REQUEST DIFF REVIEW INSTRUCTIONS:**

You are reviewing a GitHub Pull Request diff, not a complete file. Focus your analysis on:

1. **CHANGED LINES ONLY**: Only review the lines marked with + (additions) and - (deletions)
2. **CHANGE CONTEXT**: Consider how the changes affect the surrounding unchanged code
3. **DIFF FORMAT**: The input is in git diff format:
   - Lines starting with '+' are additions (NEW CODE TO REVIEW)
   - Lines starting with '-' are deletions (OLD CODE BEING REMOVED)
   - Lines starting with ' ' (space) are context (unchanged)
   - @@ lines show line numbers

**KEY FOCUS AREAS:**
- New bugs introduced by the added code
- Security vulnerabilities in new code
- Performance issues with new logic
- Salesforce governor limit violations in new operations
- Best practice violations in changed code

**IMPORTANT**: 
- Provide line numbers relative to the NEW file (+ lines)
- Only flag issues with the CHANGED code, not existing unchanged code
- Be more critical since this is new code being added

File: ${file.filename}
Changes: +${file.additions} -${file.deletions} (${file.changes} total changes)`;
  }
}
