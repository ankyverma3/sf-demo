import { CodeReviewFeedback, ReviewSummary, LLMResponse, LLMProvider } from '../types';

export abstract class BaseLLMProvider {
  protected readonly provider: LLMProvider;

  constructor(provider: LLMProvider) {
    this.provider = provider;
  }

  abstract generateReview(
    prompt: string,
    code: string,
    context: Map<string, any>,
    timeout?: number
  ): Promise<LLMResponse>;

  protected parseReviewResponse(response: string): LLMResponse {
    try {
      // Handle markdown-wrapped JSON responses (```json ... ```)
      let cleanResponse = response.trim();

      // Remove markdown code block wrapper if present
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.replace(/^```json\s*/, '').replace(/\s*```$/, '');
      } else if (cleanResponse.startsWith('```')) {
        cleanResponse = cleanResponse.replace(/^```\s*/, '').replace(/\s*```$/, '');
      }

      console.log('🔧 Cleaned JSON for parsing:', cleanResponse);

      const parsed = JSON.parse(cleanResponse);

      if (!this.isValidLLMResponse(parsed)) {
        throw new Error('Invalid LLM response format');
      }

      return parsed;
    } catch (error) {
      console.log('❌ JSON parsing failed:', error);
      console.log('📄 Original response:', response);
      return this.createFallbackResponse(response);
    }
  }

  protected isValidLLMResponse(obj: any): obj is LLMResponse {
    return (
      obj &&
      typeof obj === 'object' &&
      Array.isArray(obj.feedback) &&
      obj.summary &&
      typeof obj.summary === 'object' &&
      typeof obj.summary.totalIssues === 'number'
      // Note: qualityScore is no longer required
    );
  }

  protected createFallbackResponse(rawResponse: string): LLMResponse {
    const feedback: CodeReviewFeedback[] = [];
    const lines = rawResponse.split('\n');

    let currentFile = '';
    let currentLine = 0;

    for (const line of lines) {
      const trimmed = line.trim();

      if (trimmed.includes('Line') && trimmed.includes(':')) {
        const lineMatch = trimmed.match(/Line\s+(\d+):/);
        if (lineMatch?.[1]) {
          currentLine = parseInt(lineMatch[1], 10);
        }
      }

      if (trimmed.includes('File:')) {
        const fileMatch = trimmed.match(/File:\s*(.+)/);
        if (fileMatch?.[1]) {
          currentFile = fileMatch[1].trim();
        }
      }

      if (trimmed.length > 20 && currentFile && currentLine > 0) {
        feedback.push({
          line: currentLine,
          message: trimmed,
          severity: this.inferSeverity(trimmed),
          category: this.inferCategory(trimmed),
          file: currentFile,
        });
      }
    }

    const summary: ReviewSummary = {
      totalIssues: feedback.length,
      criticalIssues: feedback.filter((f) => f.severity === 'critical').length,
      warnings: feedback.filter((f) => f.severity === 'warning').length,
      improvements: feedback.filter((f) => f.severity === 'improvement').length,
      categories: this.categorizeIssues(feedback),
      recommendations: [],
    };

    return { feedback, summary };
  }

  private inferSeverity(message: string): 'critical' | 'warning' | 'improvement' {
    const lowerMessage = message.toLowerCase();

    if (
      lowerMessage.includes('security') ||
      lowerMessage.includes('vulnerability') ||
      lowerMessage.includes('injection') ||
      lowerMessage.includes('error')
    ) {
      return 'critical';
    }

    if (
      lowerMessage.includes('warning') ||
      lowerMessage.includes('issue') ||
      lowerMessage.includes('problem')
    ) {
      return 'warning';
    }

    return 'improvement';
  }

  private inferCategory(
    message: string
  ): 'security' | 'performance' | 'maintainability' | 'best-practice' | 'bug' {
    const lowerMessage = message.toLowerCase();

    if (
      lowerMessage.includes('security') ||
      lowerMessage.includes('injection') ||
      lowerMessage.includes('vulnerability')
    ) {
      return 'security';
    }

    if (
      lowerMessage.includes('performance') ||
      lowerMessage.includes('slow') ||
      lowerMessage.includes('optimize')
    ) {
      return 'performance';
    }

    if (
      lowerMessage.includes('maintain') ||
      lowerMessage.includes('complex') ||
      lowerMessage.includes('refactor')
    ) {
      return 'maintainability';
    }

    if (
      lowerMessage.includes('best practice') ||
      lowerMessage.includes('convention') ||
      lowerMessage.includes('standard')
    ) {
      return 'best-practice';
    }

    return 'bug';
  }

  private categorizeIssues(feedback: CodeReviewFeedback[]): Record<string, number> {
    const categories: Record<string, number> = {};

    for (const item of feedback) {
      categories[item.category] = (categories[item.category] || 0) + 1;
    }

    return categories;
  }

  protected createTimeoutPromise(timeoutMs: number): Promise<never> {
    return new Promise((_, reject) => {
      setTimeout(() => {
        reject(new Error(`LLM request timeout after ${timeoutMs}ms`));
      }, timeoutMs);
    });
  }
}
