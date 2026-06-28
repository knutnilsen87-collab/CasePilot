import { Settings } from "lucide-react";
import type { CaseSummary } from "../types";

type VisualMode = "calm" | "standard" | "focusPlus";

type Props = {
  selectedCase: CaseSummary | undefined;
  coveragePercent: number;
  hasDocuments: boolean;
  hasSources: boolean;
  pendingOcrPages: number;
  deviations: string[];
  visualMode: VisualMode;
  onOpenCommandPalette: () => void;
  onSetVisualMode: (mode: VisualMode) => void;
  onOpenCaseSwitcher: () => void;
  onNewCase: () => void;
  onOpenSettings: () => void;
};

function readinessLabel(input: Pick<Props, "coveragePercent" | "hasDocuments" | "hasSources" | "pendingOcrPages" | "deviations">) {
  if (!input.hasDocuments) {
    return { badge: "Ikke klar", message: "Start med å importere dokumenter" };
  }
  if (!input.hasSources) {
    return { badge: "Ikke klar", message: "Importert, mangler sporbare kilder" };
  }
  if (input.coveragePercent < 80 || input.pendingOcrPages > 0 || input.deviations.length > 0) {
    return { badge: "Delvis klar", message: "Foreløpig kildegrunnlag" };
  }
  return { badge: "Klar", message: "Kildegrunnlaget er klart" };
}

export function CaseHeader({
  selectedCase,
  coveragePercent,
  hasDocuments,
  hasSources,
  pendingOcrPages,
  deviations,
  visualMode,
  onOpenCommandPalette,
  onSetVisualMode,
  onOpenCaseSwitcher,
  onNewCase,
  onOpenSettings
}: Props) {
  const readiness = readinessLabel({ coveragePercent, hasDocuments, hasSources, pendingOcrPages, deviations });
  const caseName = selectedCase ? selectedCase.name : "Ingen aktiv sak";

  return (
    <header className="case-header" aria-label="Aktiv sak">
      <div className="case-header__identity">
        <h1>{caseName}</h1>
        <span className="case-header__badge">{readiness.badge}</span>
        <span className="case-header__subtitle">{readiness.message}</span>
      </div>
      <div className="case-header__actions">
        <button className="command-button button-secondary" onClick={onOpenCommandPalette}>
          Ctrl + K · Sakspilot
        </button>
        <label className="visual-mode-switcher">
          <span>Visuell modus</span>
          <select value={visualMode} onChange={(event) => onSetVisualMode(event.target.value as VisualMode)}>
            <option value="calm">Calm</option>
            <option value="standard">Standard</option>
            <option value="focusPlus">Focus+</option>
          </select>
        </label>
        <button type="button" className="button-secondary" onClick={onOpenCaseSwitcher}>
          Bytt sak
        </button>
        <button type="button" className="button-primary" onClick={onNewCase}>
          + Ny sak
        </button>
        <button type="button" className="icon-button" onClick={onOpenSettings} aria-label="Innstillinger" title="Innstillinger">
          <Settings size={18} />
        </button>
      </div>
    </header>
  );
}
