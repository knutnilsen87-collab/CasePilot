import React from "react";

type BadgeState = "ready" | "review" | "muted";

type Props = {
  state: BadgeState;
  label: string;
};

export function StatusBadge({ state, label }: Props) {
  return (
    <span className={`ds-badge ds-badge--${state}`}>{label}</span>
  );
}
