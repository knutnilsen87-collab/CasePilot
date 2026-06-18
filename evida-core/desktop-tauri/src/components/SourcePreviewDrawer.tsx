import { useEffect, useRef } from "react";
import type { SourceObjectSummary } from "../types";

interface SourcePreviewDrawerProps {
  source?: SourceObjectSummary;
  title?: string;
  documentName?: string;
  onClose: () => void;
}

export function SourcePreviewDrawer({ source, title, documentName, onClose }: SourcePreviewDrawerProps) {
  const dialogRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (source) {
      dialogRef.current?.focus();
    }
  }, [source]);

  if (!source) {
    return null;
  }

  const pageLabel =
    source.page_end !== source.page_start
      ? `side ${source.page_start}–${source.page_end}`
      : `side ${source.page_start}`;

  return (
    <div className="drawer-backdrop" role="presentation" onClick={onClose}>
      <aside
        ref={dialogRef}
        className="source-drawer"
        role="dialog"
        aria-modal="true"
        aria-label="Kildevisning"
        tabIndex={-1}
        onKeyDown={(event) => {
          if (event.key === "Escape") {
            event.stopPropagation();
            onClose();
          }
        }}
        onClick={(event) => event.stopPropagation()}
      >
        <div className="drawer-header">
          <div>
            <h2>{title || "Kildeutdrag"}</h2>
            <p>{documentName || "Dokument"} · {pageLabel}</p>
          </div>
          <button className="icon-button" onClick={onClose} aria-label="Lukk kildevisning">
            ×
          </button>
        </div>
        <div className="drawer-text">{source.text_excerpt}</div>
        <details className="drawer-technical">
          <summary>Tekniske detaljer</summary>
          <div className="drawer-meta">
            <span>Kilde-ID</span>
            <code>{source.id}</code>
            <span>SHA-256</span>
            <code>{source.sha256}</code>
          </div>
        </details>
      </aside>
    </div>
  );
}
