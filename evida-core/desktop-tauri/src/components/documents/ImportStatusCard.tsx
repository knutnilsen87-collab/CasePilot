interface ImportStatusCardProps {
  title: string;
  processedDocuments: number;
  totalDocuments: number;
  processedPages: number;
  totalPages: number;
  sourceObjects: number;
  phase: string;
  etaLabel: string;
  progressPercent: number;
  remainingDocuments: number;
  processingDocuments: number;
  statusMessage?: string;
  isActive: boolean;
  detailsOpen: boolean;
  onToggleDetails: () => void;
}

export function ImportStatusCard({
  title,
  processedDocuments,
  totalDocuments,
  processedPages,
  totalPages,
  sourceObjects,
  phase,
  etaLabel,
  progressPercent,
  remainingDocuments,
  processingDocuments,
  statusMessage,
  isActive,
  detailsOpen,
  onToggleDetails
}: ImportStatusCardProps) {
  const safeProgress = Math.max(0, Math.min(100, progressPercent));
  const visibleStatus =
    statusMessage ||
    (isActive
      ? `${processingDocuments} ${processingDocuments === 1 ? "dokument behandles" : "dokumenter behandles"} nå. ${remainingDocuments} gjenstår.`
      : "Klargjøringen er ferdig.");

  return (
    <div className="import-status-card" aria-live="polite">
      <div className="import-status-card__header">
        <div>
          <span className="eyebrow">{isActive ? "Import pågår" : "Klargjøring ferdig"}</span>
          <h3>{title}</h3>
          <p>{visibleStatus}</p>
        </div>
        <button className="button-secondary" type="button" onClick={onToggleDetails}>
          {detailsOpen ? "Skjul tekniske detaljer" : "Vis tekniske detaljer"}
        </button>
      </div>
      <div className="import-status-card__bar" role="progressbar" aria-valuemin={0} aria-valuemax={100} aria-valuenow={safeProgress}>
        <span style={{ width: `${safeProgress}%` }} />
      </div>
      <dl className="import-status-card__grid" hidden={totalDocuments === 0}>
        <div>
          <dt>Dokumenter</dt>
          <dd>{processedDocuments} av {totalDocuments}</dd>
        </div>
        <div>
          <dt>Sider</dt>
          <dd>{processedPages} av {totalPages || processedPages}</dd>
        </div>
        <div>
          <dt>Kilder</dt>
          <dd>{sourceObjects}</dd>
        </div>
        <div>
          <dt>Fase</dt>
          <dd>{isActive ? phase : "Ferdig"}</dd>
        </div>
        {isActive ? (
          <div>
            <dt>Estimert tid</dt>
            <dd>{etaLabel}</dd>
          </div>
        ) : null}
      </dl>
    </div>
  );
}
