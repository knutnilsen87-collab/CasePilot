import type { DocumentSummary, SourceObjectSummary } from "../../types";
import { EvidenceChip } from "../EvidenceChip";

interface SourceButtonListProps {
  ids: string[];
  sourcesById: Map<string, SourceObjectSummary>;
  documentsById?: Map<string, DocumentSummary>;
  onOpenSource: (sourceId: string) => void;
}

export function sourceTitle(source?: SourceObjectSummary, documentsById?: Map<string, DocumentSummary>) {
  if (!source) {
    return "Ingen kilde";
  }
  const name = documentsById?.get(source.document_id)?.original_name;
  return `${name || source.document_id.slice(0, 8)} side ${source.page_start}`;
}

export function SourceButtonList({ ids, sourcesById, documentsById, onOpenSource }: SourceButtonListProps) {
  if (ids.length === 0) {
    return <span className="muted">Ingen</span>;
  }

  return (
    <div className="source-chip-list">
      {ids.map((id) => {
        const source = sourcesById.get(id);
        const docName = source ? documentsById?.get(source.document_id)?.original_name : undefined;
        return (
          <EvidenceChip
            key={id}
            sourceId={id}
            documentLabel={docName || source?.document_id}
            page={source?.page_start}
            excerpt={source?.text_excerpt}
            confidence="medium"
            status="verified"
            onClick={() => onOpenSource(id)}
          />
        );
      })}
    </div>
  );
}
