import React from "react";
import { Card } from "./Card";
import { EmptyState } from "./EmptyState";
import { ListRow } from "./ListRow";
import { Metric, MetricRow } from "./Metric";
import { PrimaryButton, QuietLink, SecondaryButton } from "./Button";
import { ScreenScaffold } from "./ScreenScaffold";
import { StatusBadge } from "./StatusBadge";

export function DesignSystemKit() {
  return (
    <div className="ds-kit">
      <h1 style={{ fontSize: 22, fontWeight: 600, margin: 0 }}>Evida designsystem</h1>

      <section>
        <p className="ds-kit__section-title">StatusBadge</p>
        <div className="ds-kit__row">
          <StatusBadge state="ready" label="Klar" />
          <StatusBadge state="review" label="Delvis klar" />
          <StatusBadge state="muted" label="Ikke klar" />
        </div>
      </section>

      <section>
        <p className="ds-kit__section-title">Knapper</p>
        <div className="ds-kit__row">
          <PrimaryButton onClick={() => undefined}>Primærhandling</PrimaryButton>
          <SecondaryButton onClick={() => undefined}>Sekundær</SecondaryButton>
          <QuietLink onClick={() => undefined}>Stille lenke</QuietLink>
          <PrimaryButton disabled>Deaktivert</PrimaryButton>
        </div>
      </section>

      <section>
        <p className="ds-kit__section-title">Metric</p>
        <Card>
          <MetricRow>
            <Metric label="Dokumenter" value={44} />
            <Metric label="Sider" value={312} />
            <Metric label="Kilder" value={2119} />
            <Metric label="Tom verdi" value={null} />
          </MetricRow>
        </Card>
      </section>

      <section>
        <p className="ds-kit__section-title">Card</p>
        <Card>Standard kortinnhold her</Card>
        <div style={{ height: 8 }} />
        <Card compact>Kompakt kort</Card>
      </section>

      <section>
        <p className="ds-kit__section-title">ListRow</p>
        <Card compact>
          <ListRow
            name="Årsrapport 2023.pdf"
            badge={{ state: "ready", label: "Klar" }}
            metric="97 %"
          />
          <ListRow
            name="Vedlegg B — kontraktsvilkår.pdf"
            badge={{ state: "review", label: "Kontroll" }}
            metric="41 %"
            details={<p style={{ margin: "8px 0" }}>Årsak: Skannet dokument</p>}
          />
          <ListRow
            name="Skannet notat.pdf"
            badge={{ state: "muted", label: "OCR pågår" }}
          />
        </Card>
      </section>

      <section>
        <p className="ds-kit__section-title">EmptyState</p>
        <Card>
          <EmptyState
            icon="📂"
            message="Ingen dokumenter importert ennå. Start med å velge filer."
            action={<PrimaryButton onClick={() => undefined}>Importer dokumenter</PrimaryButton>}
          />
        </Card>
      </section>

      <section>
        <p className="ds-kit__section-title">ScreenScaffold</p>
        <ScreenScaffold
          label="Eksempel"
          title="Dokumentimport"
          primaryAction={<PrimaryButton onClick={() => undefined}>Importer</PrimaryButton>}
        >
          <Card>Innhold her</Card>
        </ScreenScaffold>
      </section>
    </div>
  );
}
