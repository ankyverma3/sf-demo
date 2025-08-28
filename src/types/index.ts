export interface GitHubWebhookPayload {
  action: 'opened' | 'synchronize' | 'reopened' | 'closed';
  pull_request: {
    id: number;
    number: number;
    head: {
      sha: string;
      ref: string;
    };
    base: {
      sha: string;
      ref: string;
    };
    user: {
      login: string;
    };
    title: string;
    body: string | null;
  };
  repository: {
    id: number;
    name: string;
    full_name: string;
    owner: {
      login: string;
    };
  };
  installation: {
    id: number;
  };
}

export interface FileChange {
  filename: string;
  status: 'added' | 'modified' | 'removed';
  additions: number;
  deletions: number;
  changes: number;
  patch?: string | undefined;
  blob_url: string;
  raw_url: string;
}

export interface SalesforceFileType {
  extension: string;
  type: 'apex-class' | 'apex-trigger' | 'lwc' | 'aura' | 'object' | 'flow' | 'permission' | 'other';
  priority: 'high' | 'medium' | 'low';
  parser?: string;
}

export interface CodeReviewFeedback {
  line: number;
  message: string;
  severity: 'critical' | 'warning' | 'improvement';
  category: 'security' | 'performance' | 'maintainability' | 'best-practice' | 'bug';
  file: string;
  suggestion?: string; // Optional actionable improvement suggestion
}

export interface ReviewSummary {
  totalIssues: number;
  criticalIssues: number;
  warnings: number;
  improvements: number;
  categories: Record<string, number>;
  recommendations: string[];
}

export interface PRAnalysisContext {
  totalFilesChanged: number;
  linesAdded: number;
  linesDeleted: number;
  overview?: string; // Brief description of what this PR does
  primaryChanges: string[]; // Main areas of change
  riskLevel?: 'low' | 'medium' | 'high'; // Only if assessment is accurate
  recommendationSummary?: string; // Overall assessment for the PR
}

export interface LLMProvider {
  name: 'anthropic' | 'openai';
  model: string;
  apiKey: string;
}

export interface ReviewRequest {
  repositoryName: string;
  pullRequestNumber: number;
  changedFiles: FileChange[];
  contextFiles: string[];
  installationId: number;
  headSha?: string;
}

export interface LLMResponse {
  feedback: CodeReviewFeedback[];
  summary: ReviewSummary;
  prAnalysis?: PRAnalysisContext; // Optional enhanced PR analysis
}

export interface GitHubReviewComment {
  path: string;
  line: number;
  body: string;
}

export interface GitHubPullRequestReview {
  event: 'COMMENT' | 'APPROVE' | 'REQUEST_CHANGES';
  body: string;
  comments: GitHubReviewComment[];
}

export interface AppConfig {
  server: {
    port: number;
    nodeEnv: string;
  };
  github: {
    appId: string;
    privateKey: string;
    webhookSecret: string;
  };
  llm: {
    primary: LLMProvider;
    fallback: LLMProvider;
  };
  review: {
    maxContextFiles: number;
    maxFileSizeKb: number;
    timeoutMs: number;
  };
  logging: {
    level: string;
  };
}
