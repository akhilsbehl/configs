export type Position = { line: number; column: number; offset: number };
export type Range = { start: Position; end: Position };
export type OperationKind = "delete" | "replace" | "comment";
export type OperationStatus = "open" | "applied" | "rejected" | "needs-review" | "superseded";
export type Scope = "range" | "block" | "section" | "document" | "cell" | "row" | "column" | "media";

export type ReviewOperation = {
  id: string;
  kind: OperationKind;
  status: OperationStatus;
  scope: Scope;
  range?: Range;
  quote?: string;
  prefix?: string;
  suffix?: string;
  blockId?: string;
  headingPath?: string[];
  replacement?: string;
  comment?: string;
  placement?: "start" | "end";
  createdAt: string;
  updatedAt?: string;
};

export type ReviewState = {
  schemaVersion: 1;
  source: string;
  sourceSha256: string;
  createdAt: string;
  operations: ReviewOperation[];
};

export type Session = {
  id: string;
  token: string;
  sourcePath: string;
  source: string;
  sidecarPath: string;
  state: ReviewState;
};
