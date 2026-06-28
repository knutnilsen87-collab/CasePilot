import React from "react";

type Props = {
  icon?: React.ReactNode;
  message: string;
  action?: React.ReactNode;
};

export function EmptyState({ icon, message, action }: Props) {
  return (
    <div className="ds-empty">
      {icon && <span className="ds-empty__icon">{icon}</span>}
      <p className="ds-empty__message">{message}</p>
      {action}
    </div>
  );
}
