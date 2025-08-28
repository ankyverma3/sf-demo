# Cirus GitHub App

AI-powered GitHub App for automated Salesforce code reviews with context-aware analysis.

## Features

🤖 **AI-Powered Reviews**: Leverages Anthropic Claude and OpenAI GPT models for intelligent code analysis  
🔍 **Context-Aware**: Automatically fetches related files to provide comprehensive review context  
⚡ **Salesforce-Focused**: Specialized prompts and analysis for Apex, LWC, Aura, Flows, and metadata  
💬 **Inline Comments**: Precise line-by-line feedback directly on PR diffs  
📊 **Review Summaries**: Comprehensive PR summaries with quality scores and categorized issues  
🔒 **Secure**: Webhook signature verification and proper GitHub App authentication  
🚀 **Scalable**: Built with TypeScript, Express.js, and enterprise-grade architecture  

## Architecture

```
GitHub PR Event → Webhook → Context Fetcher → AI Analysis → Inline Comments + Summary
```

### Core Components

- **Webhook Handler**: Processes GitHub PR events securely
- **Context Fetcher**: Intelligently fetches related Salesforce files with loop prevention  
- **LLM Manager**: Handles multiple AI providers with fallback support
- **Review Service**: Orchestrates the complete review workflow
- **Salesforce Analyzers**: Specialized prompts for different Salesforce file types

## Installation

### Prerequisites

- Node.js 18+
- GitHub App with appropriate permissions
- Anthropic and/or OpenAI API keys

### Setup

1. **Clone and install dependencies**:
```bash
git clone <repository-url>
cd cirus-github-app
npm install
```

2. **Configure environment variables**:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Build and start**:
```bash
npm run build
npm start

# For development:
npm run dev
```

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `GITHUB_APP_ID` | GitHub App ID | ✅ |
| `GITHUB_PRIVATE_KEY` | GitHub App private key | ✅ |
| `GITHUB_WEBHOOK_SECRET` | Webhook secret for signature verification | ✅ |
| `LLM_PROVIDER` | Primary AI provider (`anthropic` or `openai`) | ✅ |
| `LLM_MODEL` | Primary model name | ✅ |
| `LLM_API_KEY` | Primary provider API key | ✅ |
| `FALLBACK_LLM_PROVIDER` | Backup AI provider | ✅ |
| `FALLBACK_LLM_MODEL` | Backup model name | ✅ |
| `FALLBACK_LLM_API_KEY` | Backup provider API key | ✅ |

### GitHub App Permissions

Configure your GitHub App with these permissions:
- **Contents**: Read (to fetch file contents)
- **Pull Requests**: Read & Write (to read PRs and post comments)
- **Metadata**: Read (to access repository info)

### Supported File Types

**High Priority**: `.cls` (Apex Classes), `.trigger` (Triggers)  
**Medium Priority**: `.js/.html/.css` (LWC), `.cmp/.app` (Aura), `.object-meta.xml` (Objects)  
**Low Priority**: `.flow-meta.xml` (Flows), Permission sets, Profiles  

## Usage

1. **Install the GitHub App** on your Salesforce repositories
2. **Create a PR** with Salesforce code changes
3. **Get automated reviews** with:
   - Inline comments on specific code issues
   - Comprehensive PR summary with quality metrics
   - Context-aware analysis using related files

### Review Categories

- 🔒 **Security**: SOQL injection, sharing violations, data exposure
- ⚡ **Performance**: Governor limits, inefficient queries, bulkification
- 🔧 **Maintainability**: Code complexity, duplication, organization  
- 📚 **Best Practices**: Salesforce conventions, proper patterns
- 🐛 **Bugs**: Logic errors, null pointer risks, incorrect implementations

## API Endpoints

- `GET /` - Application info
- `GET /health` - Health check with system status
- `POST /webhook` - GitHub webhook endpoint

## Development

### Scripts

```bash
npm run dev          # Start development server with hot reload
npm run build        # Build TypeScript to JavaScript  
npm run test         # Run test suite
npm run test:watch   # Run tests in watch mode
npm run lint         # Lint code with ESLint
npm run typecheck    # Type check without building
```

### Testing

```bash
npm test                    # Run all tests
npm run test:watch         # Run tests in watch mode
npm run test -- --coverage # Run tests with coverage report
```

## Architecture Details

### Context-Aware File Fetching

The system intelligently identifies dependencies:

1. **Direct Dependencies**: Parses imports, class extensions, method calls
2. **File Resolution**: Uses multiple strategies to locate related files  
3. **Loop Prevention**: Tracks visited files to prevent infinite recursion
4. **Smart Limits**: Respects configured limits for performance

### LLM Provider Management  

- **Multi-Provider Support**: Anthropic Claude, OpenAI GPT
- **Automatic Fallback**: Switches to backup provider on failures
- **Timeout Handling**: Prevents hanging requests
- **Response Parsing**: Handles both JSON and fallback text formats

### Security

- ✅ Webhook signature verification
- ✅ GitHub App authentication  
- ✅ Request rate limiting
- ✅ Input validation and sanitization
- ✅ Secure environment variable handling

## Deployment

### Docker

```bash
# Build image
docker build -t cirus-github-app .

# Run container  
docker run -p 3000:3000 --env-file .env cirus-github-app
```

### AWS/Cloud Deployment

1. Set up environment variables in your cloud provider
2. Configure webhook URL: `https://your-domain.com/webhook`
3. Ensure proper networking and security groups
4. Set up monitoring and logging

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with proper tests
4. Run linting and type checking
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

---

*🚀 Built with ❤️ for the Salesforce developer community*