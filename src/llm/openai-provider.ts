import OpenAI from 'openai';
import { BaseLLMProvider } from './base-provider';
import { LLMResponse, LLMProvider } from '../types';
import { logger } from '../utils/logger';
import { config } from '../config';

export class OpenAIProvider extends BaseLLMProvider {
  private readonly client: OpenAI;

  constructor(provider: LLMProvider) {
    super(provider);
    this.client = new OpenAI({
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
      logger.info(`Generating review with OpenAI model: ${this.provider.model}`);

      const contextString = this.formatContext(context);
      const fullPrompt = this.buildFullPrompt(prompt, code, contextString);

      const reviewPromise = this.client.chat.completions.create({
        model: this.provider.model,
        messages: [
          {
            role: 'system',
            content:
              'You are an expert Salesforce code reviewer. Provide detailed, actionable feedback focused on issues, bugs, and improvements. Never provide positive feedback, only constructive criticism.',
          },
          {
            role: 'user',
            content: fullPrompt,
          },
        ],
        max_tokens: 4000,
        temperature: 0.1,
        response_format: { type: 'json_object' },
      });

      const timeoutPromise = this.createTimeoutPromise(timeout);
      const response = await Promise.race([reviewPromise, timeoutPromise]);

      if (
        !response.choices ||
        response.choices.length === 0 ||
        !response.choices[0]?.message?.content
      ) {
        throw new Error('Empty response from OpenAI');
      }

      return this.parseReviewResponse(response.choices[0].message.content);
    } catch (error) {
      logger.error('OpenAI API error:', error);
      throw new Error(`OpenAI review generation failed: ${error}`);
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
