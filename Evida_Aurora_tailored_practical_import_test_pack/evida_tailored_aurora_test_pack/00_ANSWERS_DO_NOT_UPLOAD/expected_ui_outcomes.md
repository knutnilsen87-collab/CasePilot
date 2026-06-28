# Expected UI outcomes - tailored to Aurora developer docs

Denne pakken er laget for å teste de konkrete UX-kravene i developer-dokumentene:

- Importen skal ikke bare si "Kunne ikke behandles".
- Etter import skal modal si: "Import fullført — kontroll kreves" når noe må kontrolleres.
- Det skal finnes én tydelig neste handling.
- Dokumentkontroll skal forklare at brukeren ikke godkjenner innholdet som sant, men bare avgjør om dokumentet kan brukes som kildegrunnlag.
- Saksrom skal være begrenset til kontrollerte kilder hvis ikke alt er kontrollert.
- Tall i toppbar, sidepanel og kontrollgrunnlag skal stemme.
- æøå i filnavn og UI skal vises riktig.
- Lange filnavn og lange tekstlinjer skal ikke lage horisontal overflow.

## Medium-scenario - forventet hovedresultat

- 38 filer valgt
- 30 klare dokumenter/filer
- 6 OCR-krevende bilder
- 2 problemfiler: en korrupt PDF og en tom PDF
- 142 logiske sider i testdesignet
- 136 sider med tekst før OCR
- 6 sider krever OCR
- Ca. 96 % kildeklar dekning før OCR

Forventet primærmelding:

```text
Import fullført — kontroll kreves
```

Forventet neste handling:

```text
Kontroller 8 dokumenter
```

## Failure-scenario

Målet er ikke at alt skal importeres. Målet er at alle filer får status, forklaring og anbefalt handling.
