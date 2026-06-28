# Evida Aurora Tailored Practical Test Pack

Denne pakken er spesialtilpasset Evida/CasePilot slik programmet og developer-dokumentene beskriver arbeidsflyten: importutfall, Dokumentkontroll, kontrollert kildegrunnlag, Saksrom i begrenset modus, encoding, overflow og tydelige feilmeldinger.

## Bruk

Ikke dra inn hele rotmappen.

Dra inn én av disse mappene i Evida:

```text
01_MEDIUM_import_fullfort_kontroll_kreves/UPLOAD_THIS_FOLDER
02_HARD_folder_import_mixed_formats/UPLOAD_THIS_FOLDER
03_EXTREME_large_real_saksmappe_pdf/UPLOAD_THIS_FOLDER
04_FAILURE_edge_cases_status_and_recovery/UPLOAD_THIS_FOLDER
```

Ikke last opp:

```text
00_ANSWERS_DO_NOT_UPLOAD
README_START_HER.md
RUN_GUIDE_FOR_EVIDA.md
```

## Hvorfor denne pakken er annerledes

Alle sider og dokumenter har reelt fiktivt saksinnhold. Det er ikke blanke sider. Den skal derfor teste om Evida faktisk trekker ut informasjon, lager kildeutdrag, oppdager OCR-behov, oppdager feil, og gir riktig status.

## Første test du bør kjøre

Start med:

```text
01_MEDIUM_import_fullfort_kontroll_kreves/UPLOAD_THIS_FOLDER
```

Det scenarioet er laget for å utløse akkurat den brukeropplevelsen dere må få riktig:

```text
Import fullført — kontroll kreves
```
