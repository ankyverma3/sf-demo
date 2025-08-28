import Anthropic from '@anthropic-ai/sdk';
import { BaseLLMProvider } from './base-provider';
import { LLMResponse, LLMProvider } from '../types';
import { logger } from '../utils/logger';
import { config } from '../config';

export class AnthropicProvider extends BaseLLMProvider {
  private readonly client: Anthropic;

  constructor(provider: LLMProvider) {
    super(provider);
    this.client = new Anthropic({
      apiKey: provider.apiKey,
    });
  }

  async generateReview(
    prompt: string,
    code: string,
    context: Map<string, any>,
    timeout = config.review.timeoutMs
  ): Promise<LLMResponse> {
    try {
      logger.info(`Generating review with Anthropic model: ${this.provider.model}`);

      const contextString = this.formatContext(context);
      const fullPrompt = this.buildFullPrompt(prompt, code, contextString);

      logger.info(`📤 Anthropic API Request:`);
      logger.info(`📝 Prompt length: ${fullPrompt.length}`);
      console.log(`🔍 Full prompt:`, fullPrompt);

      const reviewPromise = this.client.messages.create({
        model: this.provider.model,
        max_tokens: 4000,
        temperature: 0.1,
        messages: [
          {
            role: 'user',
            content: fullPrompt,
          },
        ],
      });

      const timeoutPromise = this.createTimeoutPromise(timeout);
      const response = await Promise.race([reviewPromise, timeoutPromise]);

      if (!response.content || response.content.length === 0) {
        throw new Error('Empty response from Anthropic');
      }

      const textContent = response.content[0];
      if (!textContent || textContent.type !== 'text') {
        throw new Error('Invalid response type from Anthropic');
      }

      logger.info(`📥 Anthropic API Response:`);
      logger.info(`📊 Response length: ${textContent.text.length}`);
      console.log(`🔍 Raw response:`, textContent.text);

      const parsedResponse = this.parseReviewResponse(textContent.text);
      console.log(`✅ Parsed response:`, JSON.stringify(parsedResponse, null, 2));

      return parsedResponse;
    } catch (error) {
      logger.error('Anthropic API error:', error);
      throw new Error(`Anthropic review generation failed: ${error}`);
    }
  }

  private formatContext(context: Map<string, any>): string {
    if (context.size === 0) {
      return '';
    }

    let contextStr = '\n\n## Context Files:\n';

    for (const [filePath, fileData] of context.entries()) {
      contextStr += `\n### ${filePath} (${fileData.type}):\n`;
      contextStr += '```\n';
      contextStr += fileData.content.substring(0, 2000);
      if (fileData.content.length > 2000) {
        contextStr += '\n... (truncated)';
      }
      contextStr += '\n```\n';
    }

    return contextStr;
  }

  private buildFullPrompt(prompt: string, code: string, context: string): string {
    return `${prompt}

## Code to Review:
\`\`\`
${code}
\`\`\`
${context}

**CRITICAL INSTRUCTIONS:**

1. **ONLY PROVIDE FEEDBACK IF GENUINE ISSUES EXIST** - Do not create fake issues for the sake of review
2. **IF CODE IS PERFECT** - Return empty feedback array and say "No issues found"
3. **SUGGESTIONS** - Only provide if you are highly confident and the suggestion adds real value
4. **CODE EXAMPLES** - Include only when beneficial and you are certain of correctness
5. **BE PRECISE** - Every feedback must be necessary and actionable

Please provide your response in the following JSON format:
{
  "feedback": [
    {
      "line": 10,
      "message": "Specific issue description",
      "severity": "critical|warning|improvement",
      "category": "security|performance|maintainability|best-practice|bug",
      "file": "filename",
      "suggestion": "Optional: Actionable solution with code example if confident and beneficial"
    }
  ],
  "summary": {
    "totalIssues": 0,
    "criticalIssues": 0,
    "warnings": 0,
    "improvements": 0,
    "categories": {},
    "recommendations": []
  },
  "prAnalysis": {
    "totalFilesChanged": 2,
    "linesAdded": 45,
    "linesDeleted": 12,
    "overview": "Optional: Brief description of what this PR accomplishes",
    "primaryChanges": ["Main change area 1", "Main change area 2"],
    "riskLevel": "low|medium|high (only if you can assess accurately)",
    "recommendationSummary": "Optional: Overall assessment"
  }
}

**REMEMBER:** If no real issues exist, return empty feedback array. Quality over quantity!`;
  }
}
