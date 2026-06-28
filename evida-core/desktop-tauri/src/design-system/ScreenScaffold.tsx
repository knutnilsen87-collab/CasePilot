import React from "react";

type Props = {
  label?: string;
  title: string;
  primaryAction?: React.ReactNode;
  children: React.ReactNode;
};

export function ScreenScaffold({ label, title, primaryAction, children }: Props) {
  return (
    <div className="ds-screen">
      <div className="ds-screen__header">
        <div>
          {label && <p className="ds-screen__label">{label}</p>}
          <h1 className="ds-screen__title">{title}</h1>
        </div>
        {primaryAction && <div>{primaryAction}</div>}
      </div>
      {children}
    </div>
  );
}
