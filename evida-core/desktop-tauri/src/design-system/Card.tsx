import React from "react";

type Props = React.HTMLAttributes<HTMLDivElement> & {
  compact?: boolean;
};

export function Card({ children, compact, className, ...rest }: Props) {
  const cls = ["ds-card", compact ? "ds-card--compact" : "", className ?? ""]
    .filter(Boolean)
    .join(" ");
  return <div className={cls} {...rest}>{children}</div>;
}
