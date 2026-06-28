import type { DocumentBasisRow } from "../documents/documentBasis";
import type { DocumentControlBulkPlan } from "./documentControl.types";

export const PRODUCTION_GRADE_DOCUMENT_REPLACE_ENABLED = false;
export const DOCUMENT_REPLACE_DISABLED_REASON =
  "Erstatt fil er deaktivert til versjonert erstatning med supersede er produksjonsklar.";

export function canBulkMarkControlled(row: DocumentBasisRow) {
  return (
    row.canApprove &&
    row.pendingOcrPages <= 0 &&
    row.state !== "processing" &&
    row.state !== "needs_user_action" &&
    row.state !== "rejected"
  );
}

export function deriveDocumentControlBulkPlan(selectedRows: DocumentBasisRow[]): DocumentControlBulkPlan {
  const eligibleForControlled = selectedRows.filter(canBulkMarkControlled);
  const eligibleAsSource = eligibleForControlled.filter((row) => row.sourceCount > 0);
  const eligibleNotCitable = eligibleForControlled.filter((row) => row.sourceCount <= 0);
  const ocrRows = selectedRows.filter((row) => row.pendingOcrPages > 0 || row.state === "needs_text_control");
  const excludeRows = selectedRows.filter((row) => row.canReject);
  const replaceRows = selectedRows.filter((row) => row.state === "needs_user_action");

  return {
    selectedRows,
    eligibleForControlled,
    eligibleAsSource,
    eligibleNotCitable,
    ocrRows,
    excludeRows,
    replaceRows,
    actions: [
      {
        id: "approve_as_source",
        label: "Godkjenn valgte som kilde",
        description:
          eligibleForControlled.length > eligibleAsSource.length
            ? `${eligibleForControlled.length - eligibleAsSource.length} valgte dokumenter mangler lesbar tekst og kan ikke godkjennes som kilder.`
            : "Dokumentene kan brukes i Saksrom-svar med kildehenvisning.",
        enabled: eligibleAsSource.length > 0 && eligibleAsSource.length === selectedRows.length,
        requiresConfirmation: true
      },
      {
        id: "mark_not_citable",
        label: "Kontrollert, men ikke siterbar",
        description: "Dokumentene blir håndtert, men brukes ikke som AI-kilder i Saksrom.",
        enabled: eligibleNotCitable.length > 0,
        requiresConfirmation: true
      },
      {
        id: "run_ocr",
        label: "OCR kjores automatisk",
        description: "OCR er en del av importmotoren og krever ikke manuell dokumentkontroll.",
        enabled: false,
        requiresConfirmation: false
      },
      {
        id: "exclude",
        label: "Hold utenfor kildegrunnlaget",
        description: "Dokumentene brukes ikke som kildegrunnlag for Saksrom.",
        enabled: excludeRows.length > 0,
        requiresConfirmation: true
      },
      {
        id: "replace",
        label: "Erstatt fil",
        description: PRODUCTION_GRADE_DOCUMENT_REPLACE_ENABLED
          ? "Velg en lesbar kopi for første valgte dokument som krever erstatning."
          : DOCUMENT_REPLACE_DISABLED_REASON,
        enabled: PRODUCTION_GRADE_DOCUMENT_REPLACE_ENABLED && replaceRows.length > 0,
        requiresConfirmation: false
      }
    ]
  };
}
