import { GitHubClient } from '../github/client';
import { SalesforceFileDetector } from '../utils/salesforce-files';
import { logger } from '../utils/logger';
import { config } from '../config';
import { FileChange } from '../types';

interface ContextFile {
  path: string;
  content: string;
  type: string;
}

export class ContextFetcher {
  private readonly githubClient: GitHubClient;
  private readonly visitedFiles: Set<string> = new Set();
  private readonly contextFiles: Map<string, ContextFile> = new Map();

  constructor(githubClient: GitHubClient) {
    this.githubClient = githubClient;
  }

  async fetchContextFiles(
    owner: string,
    repo: string,
    ref: string,
    changedFiles: FileChange[],
    installationId: number
  ): Promise<Map<string, ContextFile>> {
    this.visitedFiles.clear();
    this.contextFiles.clear();

    logger.info(`Starting context fetch for ${changedFiles.length} changed files`);

    const salesforceFiles = changedFiles.filter((file) =>
      SalesforceFileDetector.isSalesforceFile(file.filename)
    );

    const prioritizedFiles = SalesforceFileDetector.getFilesByPriority(
      salesforceFiles.map((f) => f.filename)
    );

    const processOrder = [
      ...prioritizedFiles.high,
      ...prioritizedFiles.medium,
      ...prioritizedFiles.low,
    ];

    for (const filePath of processOrder) {
      if (this.contextFiles.size >= config.review.maxContextFiles) {
        logger.info(`Reached maximum context files limit: ${config.review.maxContextFiles}`);
        break;
      }

      try {
        await this.processFile(owner, repo, ref, filePath, installationId);
      } catch (error) {
        logger.error(`Failed to process file ${filePath}:`, error);
      }
    }

    logger.info(`Fetched ${this.contextFiles.size} context files`);
    return new Map(this.contextFiles);
  }

  private async processFile(
    owner: string,
    repo: string,
    ref: string,
    filePath: string,
    installationId: number
  ): Promise<void> {
    if (this.visitedFiles.has(filePath)) {
      return;
    }

    this.visitedFiles.add(filePath);

    try {
      const content = await this.githubClient.getFileContent(
        owner,
        repo,
        filePath,
        ref,
        installationId
      );

      if (!content) {
        logger.warn(`Empty content for file: ${filePath}`);
        return;
      }

      const fileType = SalesforceFileDetector.getFileType(filePath);
      if (!fileType) {
        return;
      }

      this.contextFiles.set(filePath, {
        path: filePath,
        content,
        type: fileType.type,
      });

      await this.fetchDependencies(owner, repo, ref, filePath, content, fileType, installationId);
    } catch (error) {
      logger.error(`Failed to fetch content for ${filePath}:`, error);
    }
  }

  private async fetchDependencies(
    owner: string,
    repo: string,
    ref: string,
    currentFile: string,
    content: string,
    fileType: any,
    installationId: number
  ): Promise<void> {
    if (this.contextFiles.size >= config.review.maxContextFiles) {
      return;
    }

    const dependencies = SalesforceFileDetector.extractDependencies(content, fileType);

    if (dependencies.length === 0) {
      return;
    }

    logger.debug(`Found ${dependencies.length} dependencies in ${currentFile}:`, dependencies);

    const dependencyPaths = await this.resolveDependencyPaths(
      owner,
      repo,
      ref,
      dependencies,
      currentFile,
      installationId
    );

    for (const depPath of dependencyPaths) {
      if (this.contextFiles.size >= config.review.maxContextFiles) {
        break;
      }

      if (!this.visitedFiles.has(depPath)) {
        await this.processFile(owner, repo, ref, depPath, installationId);
      }
    }
  }

  private async resolveDependencyPaths(
    owner: string,
    repo: string,
    ref: string,
    dependencies: string[],
    currentFile: string,
    installationId: number
  ): Promise<string[]> {
    const resolvedPaths: string[] = [];
    const currentDir = currentFile.substring(0, currentFile.lastIndexOf('/'));

    for (const dependency of dependencies) {
      const possiblePaths = this.generatePossiblePaths(dependency, currentDir);

      const existingPaths = await this.githubClient.findExistingFiles(
        owner,
        repo,
        ref,
        possiblePaths,
        installationId
      );

      resolvedPaths.push(...existingPaths);

      if (existingPaths.length === 0) {
        const searchResults = await this.githubClient.searchCodeInRepository(
          owner,
          repo,
          `class ${dependency} OR interface ${dependency}`,
          installationId
        );

        const salesforceResults = searchResults.filter((path) =>
          SalesforceFileDetector.isSalesforceFile(path)
        );

        resolvedPaths.push(...salesforceResults.slice(0, 2));
      }
    }

    return [...new Set(resolvedPaths)];
  }

  private generatePossiblePaths(dependency: string, currentDir: string): string[] {
    const paths: string[] = [];

    const apexExtensions = ['.cls', '.trigger'];
    const lwcExtensions = ['.js', '.html', '.css'];
    const metadataExtensions = ['.object-meta.xml', '.field-meta.xml'];

    for (const ext of apexExtensions) {
      paths.push(`${currentDir}/${dependency}${ext}`);
      paths.push(`force-app/main/default/classes/${dependency}${ext}`);
      paths.push(`src/classes/${dependency}${ext}`);
      paths.push(`classes/${dependency}${ext}`);
    }

    for (const ext of lwcExtensions) {
      paths.push(`${currentDir}/${dependency}/${dependency}${ext}`);
      paths.push(`force-app/main/default/lwc/${dependency}/${dependency}${ext}`);
      paths.push(`src/lwc/${dependency}/${dependency}${ext}`);
    }

    for (const ext of metadataExtensions) {
      paths.push(`force-app/main/default/objects/${dependency}/${dependency}${ext}`);
      paths.push(`src/objects/${dependency}${ext}`);
    }

    return paths;
  }

  reset(): void {
    this.visitedFiles.clear();
    this.contextFiles.clear();
  }
}
