import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'
import { createAutoReviewExtension } from './extension.js'

export {
  AUTHORIZER_NAME,
  CONFIG_SCHEMA_URL,
  DEFAULT_MODEL,
  DEFAULT_PROVIDER,
  DEFAULT_TIMEOUT_MS,
  EXTENSION_ID,
  autoReviewConfigSchema,
  buildAutoReviewJsonSchema,
  loadAutoReviewConfig,
} from './config.js'
export type { AutoReviewConfig, ConfigIssue, LoadConfigOptions, LoadConfigResult } from './config.js'
export { createAutoReviewExtension } from './extension.js'
export type { AutoReviewExtensionDependencies } from './extension.js'

export default function permissionAutoReviewExtension(pi: ExtensionAPI): void {
  createAutoReviewExtension(pi)
}
