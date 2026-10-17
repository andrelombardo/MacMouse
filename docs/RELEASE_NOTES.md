MacMouse 1.0.0 è la prima versione stabile del progetto.

- Installazione dal DMG con la classica finestra di trascinamento in Applicazioni.
- Inversione della rotella del mouse senza modificare scorrimento, gesti o inerzia del trackpad.
- Interfaccia semplificata con controlli nativi di macOS e un piccolo indicatore verde di attività.
- Modello del mouse sotto il nome, letto automaticamente dal dispositivo collegato e mostrato solo se disponibile e diverso dal nome.
- Stato di Accessibilità e collegamento alle impostazioni in una sola riga.
- Icona nella barra dei menu nascondibile; menu con soltanto Apri MacMouse ed Esci da MacMouse.
- Icona nel Dock quando la finestra è aperta; chiudendola con il pulsante rosso, MacMouse continua a funzionare in background.
- Diagnostica rimossa. Nessun polling o timer periodico; nessuna acquisizione dello scorrimento quando l’inversione è disattivata.
- Le associazioni e l’avvio al login esistenti vengono conservati durante l’aggiornamento.

**Requisiti:** macOS 27+, Apple Silicon. Archivi `MacMouse-v1.0.0-macOS.dmg` e `.zip`, con `SHA256SUMS.txt`.

I mouse che inviano scorrimento continuo mantengono la direzione di sistema. Il profilo dei pulsanti è globale. Le azioni macOS richiedono scorciatoie abilitate; il cambio scrivania richiede almeno due spazi.

La firma Developer ID e la notarizzazione dipendono dalle credenziali di rilascio. La sola firma ad hoc non equivale alla notarizzazione.
