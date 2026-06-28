import type { AuditEvent, DocumentSummary, ImportItem, ManualReviewItem } from "../../types";

export type DocumentProcessingState =
  | "pending"
  | "processing"
  | "ready"
  | "reviewed"
  | "needs_text_control"
  | "needs_user_action"
  | "rejected";

export interface DocumentBasisRow {
  id: string;
  caseId: string;
  name: string;
  hash: string;
  pageCount: number;
  analyzedPages: number;
  pendingOcrPages: number;
  sourceCount: number;
  sourceCoveragePercent: number;
  state: DocumentProcessingState;
  label: string;
  reason: string;
  recommendedAction: string;
  importedAt: string;
  canPreview: boolean;
  canApprove: boolean;
  canReject: boolean;
  canUseInAnswer: boolean;
  approvedAt?: string;
  approvedBy?: string;
  rejectedAt?: string;
  rejectedBy?: string;
}

export interface DocumentBasisSummary {
  rows: DocumentBasisRow[];
  readyDocuments: DocumentBasisRow[];
  needsReviewDocuments: DocumentBasisRow[];
  unreadableDocuments: DocumentBasisRow[];
  readyCount: number;
  totalCount: number;
  sourceCoveragePercent: number;
  etaLabel: string;
  primaryStatusLabel: string;
}

const READY_OCR_STATUSES = new Set(["ok", "text_extracted", "not_required"]);
const PROCESSING_IMPORT_STATUSES = new Set(["queued", "validating", "hashing", "extracting_text", "ocr_running", "chunking", "indexed"]);
const HARD_FAILURE_STATUSES = new Set(["failed", "empty", "unsupported_file_type"]);
const RAW_TECHNICAL_ERROR_PATTERNS = [
  /\bno such (column|table|index)\b/i,
  /\bcreate\s+(index|table)\b/i,
  /\bselect\b.+\bfrom\b/i,
  /\binsert\s+into\b/i,
  /\b(update|delete)\b.+\bwhere\b/i,
  /\b(create|select|insert|update|delete|alter|drop)\s+.+\b(table|index|from|into|where|column)\b/i,
  /\bat offset \d+\b/i,
  /\bstack trace\b/i,
  /\bpanicked at\b/i,
  /\brust backtrace\b/i,
  /\bsqlite\b/i,
  /\bsqlx\b/i
];

export function isRawTechnicalImportMessage(value?: string | null) {
  const normalized = value?.trim();
  return Boolean(normalized && RAW_TECHNICAL_ERROR_PATTERNS.some((pattern) => pattern.test(normalized)));
}

export function safeDocumentStatusMessage(value?: string | null, fallback = "Dokumentet må kontrolleres manuelt.") {
  if (isRawTechnicalImportMessage(value)) {
    return "Teknisk feil under import";
  }
  return value?.trim() || fallback;
}

export function canUseDocumentInAnswer(row: Pick<DocumentBasisRow, "state" | "sourceCount" | "rejectedAt">) {
  return row.sourceCount > 0 && row.state === "ready" && !row.rejectedAt;
}

export function deriveDocumentBasisSummary(args: {
  documents: DocumentSummary[];
  importItems: ImportItem[];
  manualReviewItems: ManualReviewItem[];
  audit: AuditEvent[];
  hasActiveProcessing: boolean;
}): DocumentBasisSummary {
  const rows = args.documents.map((document) =>
    deriveDocumentBasisRow(document, {
      importItem: findImportItem(document, args.importItems),
      manualReviewItems: args.manualReviewItems.filter((item) => item.document_id === document.id),
      audit: args.audit
    })
  );
  const readyDocuments = rows.filter((row) => row.state === "ready" || row.state === "reviewed");
  const needsReviewDocuments = rows.filter((row) => row.state === "needs_text_control");
  const unreadableDocuments = rows.filter((row) => row.state === "needs_user_action" || row.state === "rejected");
  const totalPages = rows.reduce((sum, row) => sum + row.pageCount, 0);
  const coveredPages = rows.reduce((sum, row) => sum + Math.round((row.pageCount * row.sourceCoveragePercent) / 100), 0);
  const sourceCoveragePercent = totalPages > 0 ? Math.round((coveredPages / totalPages) * 100) : 0;

  return {
    rows,
    readyDocuments,
    needsReviewDocuments,
    unreadableDocuments,
    readyCount: readyDocuments.length,
    totalCount: rows.length,
    sourceCoveragePercent,
    etaLabel: etaLabel(rows, args.hasActiveProcessing),
    primaryStatusLabel: primaryStatusLabel(rows, args.hasActiveProcessing)
  };
}

function deriveDocumentBasisRow(
  document: DocumentSummary,
  args: { importItem?: ImportItem; manualReviewItems: ManualReviewItem[]; audit: AuditEvent[] }
): DocumentBasisRow {
  const approvalEvent =
    latestAudit(args.audit, document.id, "DOCUMENT_MANUAL_REVIEW_APPROVED") ||
    latestAudit(args.audit, document.id, "DOCUMENT_APPROVED_FOR_AI");
  const rejectionEvent = latestAudit(args.audit, document.id, "DOCUMENT_REJECTED_FOR_AI");
  const openReviewItems = args.manualReviewItems.filter((item) => item.status === "open" || item.status === "needs_follow_up");
  const importItem = args.importItem;
  const state = deriveDocumentProcessingState(document, importItem, openReviewItems, Boolean(approvalEvent), Boolean(rejectionEvent));
  const issueReason =
    openReviewItems[0]?.reason ||
    safeDocumentStatusMessage(importItem?.user_message, statusReason(document, importItem, state));

  return {
    id: document.id,
    caseId: document.case_id,
    name: document.original_name,
    hash: document.sha256,
    pageCount: document.page_count,
    analyzedPages: document.analyzed_page_count,
    pendingOcrPages: document.pending_ocr_page_count,
    sourceCount: document.source_count,
    sourceCoveragePercent: Math.round(document.source_coverage_percent || 0),
    state,
    label: stateLabel(state),
    reason: issueReason,
    recommendedAction:
      openReviewItems[0]?.recommended_action ||
      (isRawTechnicalImportMessage(importItem?.user_message)
        ? "Detaljer er skjult. Åpne tekniske detaljer ved behov."
        : importItem?.recommended_action) ||
      recommendedAction(state),
    importedAt: document.imported_at,
    canPreview: Boolean(document.local_path),
    canApprove: state === "needs_text_control" || state === "needs_user_action" || state === "pending",
    canReject: state !== "rejected",
    canUseInAnswer: canUseDocumentInAnswer({ state, sourceCount: document.source_count, rejectedAt: rejectionEvent?.created_at }),
    approvedAt: approvalEvent?.created_at,
    approvedBy: approvalEvent?.actor,
    rejectedAt: rejectionEvent?.created_at,
    rejectedBy: rejectionEvent?.actor
  };
}

function deriveDocumentProcessingState(
  document: DocumentSummary,
  importItem: ImportItem | undefined,
  openReviewItems: ManualReviewItem[],
  hasApproval: boolean,
  hasRejection: boolean
): DocumentProcessingState {
  if (hasRejection) {
    return "rejected";
  }
  if (hasApproval && document.source_count > 0) {
    return "ready";
  }
  if (hasApproval) {
    return "reviewed";
  }
  if (HARD_FAILURE_STATUSES.has(document.ocr_status) || importItem?.status === "failed" || importItem?.status === "unsupported") {
    return "needs_user_action";
  }
  if (document.source_count > 0 && READY_OCR_STATUSES.has(document.ocr_status) && openReviewItems.length === 0) {
    return "ready";
  }
  if (openReviewItems.length > 0) {
    return "needs_text_control";
  }
  if (importItem && PROCESSING_IMPORT_STATUSES.has(importItem.status)) {
    return "processing";
  }
  if (document.pending_ocr_page_count > 0 || document.ocr_status === "needs_ocr" || document.ocr_status === "partial_needs_ocr") {
    return "processing";
  }
  return document.source_count > 0 ? "needs_text_control" : "pending";
}

function findImportItem(document: DocumentSummary, importItems: ImportItem[]) {
  return importItems.find((item) => item.sha256 === document.sha256 || item.original_name === document.original_name);
}

function latestAudit(audit: AuditEvent[], documentId: string, action: string) {
  return audit.find((event) => event.target_type === "document" && event.target_id === documentId && event.action === action);
}

function stateLabel(state: DocumentProcessingState) {
  const labels: Record<DocumentProcessingState, string> = {
    pending: "Trenger kontroll",
    processing: "Trenger kontroll",
    ready: "Klar for Saksrom",
    reviewed: "Kontrollert",
    needs_text_control: "Trenger kontroll",
    needs_user_action: "Kunne ikke leses",
    rejected: "Kan ikke brukes som kilde"
  };
  return labels[state];
}

function statusReason(document: DocumentSummary, importItem: ImportItem | undefined, state: DocumentProcessingState) {
  if (state === "ready") {
    return "Kan brukes som kilde";
  }
  if (state === "reviewed") {
    return "Dokumentet er manuelt kontrollert, men har ikke lesbare kildeutdrag for AI-sitering.";
  }
  if (document.pending_ocr_page_count > 0) {
    return "Kontroller teksten før dokumentet brukes som kilde";
  }
  if (importItem?.issue_code) {
    return importItem.issue_code === "UNSUPPORTED_FILE_TYPE"
      ? "Filformatet eller innholdet kunne ikke leses trygt"
      : "Dokumentet må kontrolleres manuelt";
  }
  return "Kontroller teksten før dokumentet brukes som kilde";
}

function recommendedAction(state: DocumentProcessingState) {
  const actions: Record<DocumentProcessingState, string> = {
    pending: "Vent pa import eller oppdater kildeutdrag.",
    processing: "Vent til Evida er ferdig med tekst/OCR.",
    ready: "Ingen handling nodvendig.",
    reviewed: "Ingen handling nodvendig. Legg til OCR/tekst hvis dokumentet skal kunne siteres av AI.",
    needs_text_control: "Se unntaket og velg trygg neste handling.",
    needs_user_action: "Last opp en lesbar kopi, eller marker dokumentet manuelt kontrollert.",
    rejected: "Dokumentet er holdt utenfor AI-grunnlaget."
  };
  return actions[state];
}

function etaLabel(rows: DocumentBasisRow[], hasActiveProcessing: boolean) {
  if (rows.length === 0) {
    return "Venter pa dokumenter";
  }
  const remaining = rows.filter((row) => row.state !== "ready" && row.state !== "reviewed" && row.state !== "rejected").length;
  if (remaining === 0) {
    return "Klar na";
  }
  if (hasActiveProcessing) {
    return "ETA beregnes mens dokumentmotoren jobber";
  }
  return `${remaining} dokument${remaining === 1 ? "" : "er"} behandles eller trenger oppmerksomhet`;
}

function primaryStatusLabel(rows: DocumentBasisRow[], hasActiveProcessing: boolean) {
  if (rows.length === 0) {
    return "Ingen dokumenter importert";
  }
  if (hasActiveProcessing) {
    return "Behandler dokumentgrunnlag";
  }
  const ready = rows.filter((row) => row.state === "ready" || row.state === "reviewed").length;
  return `${ready} av ${rows.length} dokumenter er klare`;
}
