# MacMouse

A lightweight native macOS app for customizing your mouse.

MacMouse associa i pulsanti aggiuntivi del mouse alle azioni che usi ogni giorno. Una finestra compatta in SwiftUI, controlli Liquid Glass e un menu nella barra di macOS. Gratuita, interamente offline, senza account, telemetria o dipendenze esterne.

<img src="docs/images/macmouse-light.png" alt="Finestra reale di MacMouse in modalità chiara, in attesa del permesso Accessibilità" width="460">

Screenshot reale della beta su macOS 27, prima della concessione di Accessibilità e del collegamento di un mouse.

## Funzionalità

- Due pulsanti configurabili, riconosciuti con **Rileva pulsante** senza codici prestabiliti.
- Indietro e Avanti, azioni macOS, apertura di applicazioni e scorciatoie personalizzate.
- Clic centrale con trascinamento, disattivazione e comportamento originale.
- Scorciatoie con Command, Shift, Option, Control e tasti funzione.
- Impostazioni locali persistenti; funzionamento continuo a finestra chiusa.
- Avvio al login tramite ServiceManagement e diagnostica su richiesta.

Il profilo è **globale**: gli eventi Quartz non identificano in modo affidabile il mouse di origine. IOKit mostra i mouse enumerati e le variazioni di connessione, senza attribuire loro gli eventi globali. Le associazioni valgono per tutti i dispositivi con lo stesso numero di pulsante. Clic sinistro, clic destro, puntatore, scorrimento e gesti standard del trackpad non vengono rimappati.

## Compatibilità

macOS **27 o successivo**, **Apple Silicon**. Build arm64 compilata su macOS 27.0.1 con Swift 6.4 e SDK macOS 27.0. Il progetto Xcode richiede Xcode 27; sul Mac di sviluppo sono presenti i Command Line Tools, senza Xcode completo. La verifica del progetto Xcode è prevista anche nella [pipeline](https://github.com/andrelombardo/MacMouse/actions).

Il dispositivo di riferimento è il **TECKNET TK-MS317**, via Bluetooth o ricevitore USB. **La verifica fisica del dispositivo non è stata eseguita**: la prima versione è una beta. Non è distribuita una build Intel.

## Download

[Scarica MacMouse 0.1.0 beta 1](https://github.com/andrelombardo/MacMouse/releases/tag/v0.1.0-beta.1).

Scegli `MacMouse-v0.1.0-macOS.zip` oppure `MacMouse-v0.1.0-macOS.dmg`. `SHA256SUMS.txt` contiene i checksum degli archivi. Le [Release](https://github.com/andrelombardo/MacMouse/releases) sono l’unico canale di aggiornamento; l’app non effettua richieste di rete.

## Installazione

1. Estrai lo ZIP, oppure apri il DMG.
2. Copia **MacMouse.app** in **Applicazioni** e aprila da quella posizione.
3. Concedi Accessibilità e scegli **Verifica**.
4. Apri il menu **•••** della prima riga, scegli **Rileva pulsante** e premi il primo tasto laterale. Ripeti con la seconda riga.
5. Scegli le azioni; puoi chiudere la finestra e riaprirla dall’icona del mouse nella barra dei menu.

La beta ha una **firma ad hoc**, senza **Developer ID** e senza **notarizzazione**. Gatekeeper può bloccarne l’apertura. Se ti fidi della provenienza, usa la procedura di approvazione offerta da macOS in **Impostazioni di Sistema → Privacy e sicurezza → Apri comunque**, quando disponibile. Su un Mac gestito questa scelta può essere vietata. Non occorre disabilitare Gatekeeper né rimuovere attributi di sicurezza. In alternativa compila il codice localmente. Vedi la [procedura Apple](https://support.apple.com/it-it/102445).

## Autorizzazioni

**Accessibilità** serve al filtro attivo dei pulsanti e all’invio delle scorciatoie. MacMouse legge i menu dell’app in primo piano solo quando richiedi Indietro o Avanti. La registrazione di una scorciatoia avviene esclusivamente nel campo dedicato della finestra; il motore globale ascolta solo gli eventi dei pulsanti aggiuntivi del mouse.

Monitoraggio input non viene richiesto preventivamente. Se, dopo aver concesso Accessibilità, macOS rifiuta ancora l’event tap, compare il relativo comando opzionale. Il servizio HID enumera i dispositivi senza aprirli o leggere report di input. Nessun accesso a rete, microfono o registrazione dello schermo.

Per Indietro/Avanti viene cercata un’azione di menu abilitata in italiano o inglese; in mancanza, viene tentata la scorciatoia Command–parentesi quadra se il layout la espone. Non tutte le applicazioni o i layout la supportano. Se necessario assegna una scorciatoia personalizzata. Le azioni Mission Control, App Exposé e Mostra scrivania usano rispettivamente Control–↑, Control–↓ e F11: devono essere abilitate nelle impostazioni della tastiera. Dal menu **•••** puoi modificarle. Cambio applicazione invia un singolo Command–Tab; Cambio finestra richiede una combinazione disponibile nel layout attivo o una registrazione personalizzata. Launchpad / Applicazioni richiede sempre la scorciatoia configurata dall’utente; non vengono usate API private.

## Compilazione dal sorgente

Apri `MacMouse.xcodeproj` in Xcode 27, seleziona **MacMouse → My Mac** e compila. I test sono nel package Swift: apri `Package.swift` in Xcode per eseguirli, oppure usa gli script seguenti con Xcode o i Command Line Tools 27:

```sh
scripts/test.sh
scripts/build.sh
scripts/package.sh
```

L’app si trova in `build/MacMouse.app`; ZIP, DMG e checksum in `dist/`. Non sono richiesti gestori di pacchetti o dipendenze di terze parti. `scripts/generate-icon.swift` rigenera gli asset originali tramite AppKit; `scripts/generate-project.py` rigenera il progetto Xcode dai sorgenti.

La pipeline usa un runner Apple Silicon con Xcode 27, esegue test e build Release sia del progetto Xcode sia del package, quindi conserva gli archivi. Sui tag pubblica una Release solo dopo la riuscita della build. Firma Developer ID e notarizzazione sono opzionali, configurabili esclusivamente tramite GitHub Secrets. La compilazione automatica non certifica i test fisici del mouse.

Consulta [verifiche e limiti](docs/VALIDATION.md), [test manuali](docs/MANUAL_TESTS.md), [note tecniche](docs/ARCHITECTURE.md) e [procedura di rilascio](docs/RELEASING.md).

## Licenza

[MIT](LICENSE). Codice e geometria dell’icona originali. I simboli di sistema sono forniti da macOS.
