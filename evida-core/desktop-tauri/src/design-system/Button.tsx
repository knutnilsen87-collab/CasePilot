import React from "react";

type CommonProps = {
  children: React.ReactNode;
  onClick?: () => void;
  disabled?: boolean;
};

export function PrimaryButton({ children, onClick, disabled }: CommonProps) {
  return (
    <button
      className="ds-btn ds-btn--primary"
      onClick={onClick}
      disabled={disabled}
      type="button"
    >
      {children}
    </button>
  );
}

export function SecondaryButton({ children, onClick, disabled }: CommonProps) {
  return (
    <button
      className="ds-btn ds-btn--secondary"
      onClick={onClick}
      disabled={disabled}
      type="button"
    >
      {children}
    </button>
  );
}

export function QuietLink({ children, onClick }: CommonProps) {
  return (
    <button className="ds-quiet-link" onClick={onClick} type="button">
      {children}
    </button>
  );
}
