import React from "react";
import { StatusBadge } from "./StatusBadge";

type BadgeState = "ready" | "review" | "muted";

type Props = {
  name: string;
  badge?: { state: BadgeState; label: string };
  metric?: string;
  actions?: React.ReactNode;
  details?: React.ReactNode;
};

export function ListRow({ name, badge, metric, actions, details }: Props) {
  return (
    <div className="ds-list-row">
      <span className="ds-list-row__name" title={name}>
        {name}
      </span>
      {badge && <StatusBadge state={badge.state} label={badge.label} />}
      {metric && <span className="ds-list-row__metric">{metric}</span>}
      {(actions || details) && (
        <span className="ds-list-row__actions">
          {actions}
          {details && (
            <details>
              <summary className="ds-quiet-link">Tekniske detaljer</summary>
              {details}
            </details>
          )}
        </span>
      )}
    </div>
  );
}
