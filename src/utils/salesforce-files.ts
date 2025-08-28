import { SalesforceFileType } from '../types';

export const SALESFORCE_FILE_TYPES: SalesforceFileType[] = [
  // High Priority - Core Apex
  { extension: '.cls', type: 'apex-class', priority: 'high', parser: 'apex' },
  { extension: '.cls-meta.xml', type: 'apex-class', priority: 'high', parser: 'xml' },
  { extension: '.trigger', type: 'apex-trigger', priority: 'high', parser: 'apex' },
  { extension: '.trigger-meta.xml', type: 'apex-trigger', priority: 'high', parser: 'xml' },

  // Medium Priority - Frontend & Metadata
  { extension: '.js', type: 'lwc', priority: 'medium', parser: 'javascript' },
  { extension: '.js-meta.xml', type: 'lwc', priority: 'medium', parser: 'xml' },
  { extension: '.html', type: 'lwc', priority: 'medium', parser: 'html' },
  { extension: '.css', type: 'lwc', priority: 'medium', parser: 'css' },
  { extension: '.cmp', type: 'aura', priority: 'medium', parser: 'html' },
  { extension: '.cmp-meta.xml', type: 'aura', priority: 'medium', parser: 'xml' },
  { extension: '.app', type: 'aura', priority: 'medium', parser: 'html' },
  { extension: '.app-meta.xml', type: 'aura', priority: 'medium', parser: 'xml' },
  { extension: '.object-meta.xml', type: 'object', priority: 'medium', parser: 'xml' },
  { extension: '.field-meta.xml', type: 'object', priority: 'medium', parser: 'xml' },

  // Low Priority - Configuration & Flows
  { extension: '.flow-meta.xml', type: 'flow', priority: 'low', parser: 'xml' },
  { extension: '.permissionset-meta.xml', type: 'permission', priority: 'low', parser: 'xml' },
  { extension: '.profile-meta.xml', type: 'permission', priority: 'low', parser: 'xml' },
  { extension: '.layout-meta.xml', type: 'other', priority: 'low', parser: 'xml' },
  { extension: '.component', type: 'other', priority: 'low', parser: 'html' },
  { extension: '.page', type: 'other', priority: 'low', parser: 'html' },
];

export class SalesforceFileDetector {
  static isSalesforceFile(filename: string): boolean {
    return SALESFORCE_FILE_TYPES.some((type) => filename.endsWith(type.extension));
  }

  static getFileType(filename: string): SalesforceFileType | null {
    return SALESFORCE_FILE_TYPES.find((type) => filename.endsWith(type.extension)) || null;
  }

  static getFilesByPriority(filenames: string[]): {
    high: string[];
    medium: string[];
    low: string[];
    other: string[];
  } {
    const result = { high: [], medium: [], low: [], other: [] } as {
      high: string[];
      medium: string[];
      low: string[];
      other: string[];
    };

    for (const filename of filenames) {
      const fileType = this.getFileType(filename);
      if (fileType) {
        result[fileType.priority].push(filename);
      } else {
        result.other.push(filename);
      }
    }

    return result;
  }

  static extractDependencies(content: string, fileType: SalesforceFileType): string[] {
    const dependencies: string[] = [];

    switch (fileType.type) {
      case 'apex-class':
      case 'apex-trigger':
        dependencies.push(...this.extractApexDependencies(content));
        break;
      case 'lwc':
        dependencies.push(...this.extractLWCDependencies(content));
        break;
      case 'aura':
        dependencies.push(...this.extractAuraDependencies(content));
        break;
      default:
        break;
    }

    return [...new Set(dependencies)];
  }

  private static extractApexDependencies(content: string): string[] {
    const dependencies: string[] = [];

    const classPattern = /\b(?:extends|implements)\s+([A-Za-z_][A-Za-z0-9_]*)/g;
    const newInstancePattern = /\bnew\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(/g;
    const staticCallPattern = /\b([A-Za-z_][A-Za-z0-9_]*)\.[A-Za-z_][A-Za-z0-9_]*\s*\(/g;

    let match;
    while ((match = classPattern.exec(content)) !== null) {
      if (match[1]) dependencies.push(match[1]);
    }
    while ((match = newInstancePattern.exec(content)) !== null) {
      if (match[1]) dependencies.push(match[1]);
    }
    while ((match = staticCallPattern.exec(content)) !== null) {
      if (match[1]) dependencies.push(match[1]);
    }

    return dependencies;
  }

  private static extractLWCDependencies(content: string): string[] {
    const dependencies: string[] = [];

    const importPattern = /import\s+.*?\s+from\s+['"]([^'"]+)['"]/g;
    let match;
    while ((match = importPattern.exec(content)) !== null) {
      if (match[1]) dependencies.push(match[1]);
    }

    return dependencies;
  }

  private static extractAuraDependencies(content: string): string[] {
    const dependencies: string[] = [];

    const componentPattern = /<([a-zA-Z]+:[a-zA-Z_][a-zA-Z0-9_]*)/g;
    let match;
    while ((match = componentPattern.exec(content)) !== null) {
      if (match[1]) dependencies.push(match[1]);
    }

    return dependencies;
  }
}
