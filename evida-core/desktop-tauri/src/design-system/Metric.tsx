import React from "react";

type Props = {
  label: string;
  value: string | number | null | undefined;
};

export function Metric({ label, value }: Props) {
  if (value === null || value === undefined || value === "") return null;
  return (
    <div className="ds-metric">
      <span className="ds-metric__label">{label}</span>
      <span className="ds-metric__value">{value}</span>
    </div>
  );
}

export function MetricRow({ children }: { children: React.ReactNode }) {
  return <div className="ds-metric-row">{children}</div>;
}
