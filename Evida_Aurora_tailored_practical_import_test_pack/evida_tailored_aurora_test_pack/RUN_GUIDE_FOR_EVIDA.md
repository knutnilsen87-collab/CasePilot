# Praktisk testguide for Evida

## Runde 1 - Medium

1. Opprett ny sak.
2. Dra inn `01_MEDIUM_import_fullfort_kontroll_kreves/UPLOAD_THIS_FOLDER`.
3. Sjekk at importresultatet viser kontroll kreves, ikke bare feil.
4. Sjekk at Evida forklarer hvorfor 6 bilder krever OCR.
5. Sjekk at korrupt PDF og tom fil ikke krasjer importen.
6. Gå til Dokumentkontroll.
7. Se om dokumenter grupperes etter årsak.
8. Åpne Saksrom og spør golden prompts.

## Runde 2 - Hard

Tester nested folders, blandede formater, duplikat, unsupported, mange dokumenter og flere gold findings.

## Runde 3 - Extreme

Tester stor 1000-siders PDF med reelt tekstinnhold, dokumentseparatorer og skjulte funn langt inne i dokumentet.

## Runde 4 - Failure

Tester recovery og statusforklaringer. Her er suksess at appen ikke krasjer og at alle filer får forklaring.
