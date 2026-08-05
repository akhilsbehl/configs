import { Authorizer, PermissionsService } from "@gotgenes/pi-permission-system";
import { z } from "zod";
import { ExtensionAPI, ModelRegistry, SessionManager } from "@earendil-works/pi-coding-agent";
//#region src/config.d.ts
declare const EXTENSION_ID = "pi-permission-auto-review";
declare const AUTHORIZER_NAME = "auto-review";
declare const DEFAULT_PROVIDER = "openai-codex";
declare const DEFAULT_MODEL = "codex-auto-review";
declare const DEFAULT_TIMEOUT_MS = 90000;
declare const CONFIG_SCHEMA_URL = "https://raw.githubusercontent.com/mzwing/pi-packages/main/packages/pi-permission-auto-review/schemas/config.schema.json";
type AutoReviewConfigSchema = z.ZodObject<{
  $schema: z.ZodOptional<z.ZodString>;
  additionalPolicy: z.ZodOptional<z.ZodString>;
  provider: z.ZodDefault<z.ZodString>;
  model: z.ZodDefault<z.ZodString>;
  reasoning: z.ZodDefault<z.ZodEnum<{
    off: 'off';
    minimal: 'minimal';
    low: 'low';
    medium: 'medium';
    high: 'high';
    xhigh: 'xhigh';
    max: 'max';
  }>>;
  timeoutMs: z.ZodDefault<z.ZodNumber>;
  includeBaselinePolicy: z.ZodDefault<z.ZodBoolean>;
}, z.core.$strict>;
declare const autoReviewConfigSchema: AutoReviewConfigSchema;
type AutoReviewConfig = z.infer<typeof autoReviewConfigSchema>;
interface ConfigIssue {
  sourcePath: string;
  message: string;
}
interface LoadConfigResult {
  config: AutoReviewConfig | undefined;
  issues: ConfigIssue[];
  globalPath: string;
  projectPath: string;
}
interface LoadConfigOptions {
  cwd: string;
  agentDir?: string;
  readFile?: (path: string) => string | undefined;
}
declare function loadAutoReviewConfig(options: LoadConfigOptions): LoadConfigResult;
declare function buildAutoReviewJsonSchema(): Record<string, unknown>;
//#endregion
//#region src/circuit-breaker.d.ts
declare class DenialCircuitBreaker {
  private consecutiveDenials;
  private recentDenials;
  isOpen(): boolean;
  recordDenied(): void;
  recordNonDenial(): void;
  resetTurn(): void;
  private recordRecent;
}
//#endregion
//#region src/extension.d.ts
interface ReviewerFactoryOptions {
  config: AutoReviewConfig;
  registry: ModelRegistry;
  sessionManager: Pick<SessionManager, 'buildContextEntries'>;
  circuitBreaker: DenialCircuitBreaker;
  sessionSignal: AbortSignal;
}
interface AutoReviewExtensionDependencies {
  loadConfig?: (cwd: string) => LoadConfigResult;
  getPermissionsService?: () => PermissionsService | undefined;
  createReviewer?: (options: ReviewerFactoryOptions) => Authorizer['authorize'];
}
declare function createAutoReviewExtension(pi: ExtensionAPI, dependencies?: AutoReviewExtensionDependencies): void;
//#endregion
//#region src/index.d.ts
declare function permissionAutoReviewExtension(pi: ExtensionAPI): void;
//#endregion
export { AUTHORIZER_NAME, type AutoReviewConfig, type AutoReviewExtensionDependencies, CONFIG_SCHEMA_URL, type ConfigIssue, DEFAULT_MODEL, DEFAULT_PROVIDER, DEFAULT_TIMEOUT_MS, EXTENSION_ID, type LoadConfigOptions, type LoadConfigResult, autoReviewConfigSchema, buildAutoReviewJsonSchema, createAutoReviewExtension, permissionAutoReviewExtension as default, loadAutoReviewConfig };