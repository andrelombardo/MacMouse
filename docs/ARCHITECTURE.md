# Note tecniche

MacMouse usa esclusivamente API pubbliche Apple. Il motore è implementato prima dell’interfaccia e può essere verificato separatamente mediante il package Swift.

## Input

`MouseEngine` installa un filtro `CGEvent.tapCreate` in `cgSessionEventTap`, con opzione `defaultTap`. La maschera include esclusivamente `otherMouseDown`, `otherMouseUp` e `otherMouseDragged`. Non vengono intercettati tasti della tastiera, clic primari, movimento, scroll o gesti del trackpad.

Un thread dedicato ospita un CFRunLoop in attesa. Configurazioni e comandi vi vengono inviati con `CFRunLoopPerformBlock`: la macchina a stati non è condivisa con SwiftUI. Il callback legge `mouseEventButtonNumber`, consulta `ButtonRouter` e restituisce, sopprime o converte l’evento. Le azioni applicative vengono accodate fuori dal callback. Nessuna operazione HID, accesso a disco o ricerca Accessibility avviene nel callback.

`ButtonRouter` conserva soltanto le pressioni ancora aperte. La decisione presa al down resta valida per up e drag anche se nel frattempo cambiano le impostazioni. Down duplicati non ripetono azioni. I codici configurabili sono quelli aggiuntivi Quartz, da 2 a 31, e sono acquisiti esplicitamente; i numeri non sono codici HID. La modalità rilevamento consuma un intero click e termina al primo down valido, su annullamento o dopo 15 secondi.

Un’azione tastiera genera sempre una coppia keyDown/keyUp, preparata interamente prima dell’invio. I modificatori sono flag degli eventi con una sorgente privata, senza pressioni artificiali separate da lasciare aperte. Una pressione prolungata non produce autorepeat. Il clic centrale mantiene down, drag e up; può avere un solo proprietario alla volta. Le interruzioni generano un middle-up e consumano l’eventuale rilascio fisico successivo. Ogni evento generato o convertito porta un marcatore `eventSourceUserData`, escluso prima dell’instradamento.

Su timeout il motore bilancia lo stato e riabilita il tap al massimo due volte nell’arco di un minuto; un terzo errore lo sospende. Un tap disabilitato per input utente viene sospeso senza riavvii automatici. Il comando Riprova, il ritorno nell’app o il wake consentono un nuovo tentativo. I permessi vengono ricontrollati all’attivazione, all’apertura del menu e al wake; l’unico timer periodico, ogni due secondi, esiste mentre la finestra visibile attende il permesso. Non esiste un timer in background. Revoche TCC possono richiedere il riavvio del processo da parte di macOS.

## Dispositivi e profilo

`DeviceService` usa IOHIDManager con matching Generic Desktop / Mouse e callback di aggiunta/rimozione sul runloop principale. Non invoca `IOHIDManagerOpen`, non acquisisce esclusivamente dispositivi e non registra callback di input. Esclude dispositivi marcati Built-In e prodotti identificati come trackpad. Le proprietà non sempre sono complete; un ricevitore può esporre un nome generico o più interfacce.

L’ID di registro identifica soltanto la voce attualmente collegata nell’elenco e non è salvato come identità stabile. I due binding appartengono a un unico profilo globale locale. Una riconnessione conserva quindi le impostazioni senza associazioni hardware inventate. Una disconnessione bilancia eventuali pressioni virtuali, ma non può stabilire da quale mouse provenissero. Un’identità TECKNET non è dedotta da nomi o numeri non verificati.

## Azioni

L’apertura di un’app usa NSWorkspace e il percorso scelto mediante NSOpenPanel. Non vengono eseguiti comandi di shell o AppleScript. Per Indietro/Avanti vengono visitati soltanto i menu del processo in primo piano con Accessibility, entro un budget di nodi/profondità/tempo; le richieste AX hanno un timeout breve. La ricerca è seriale fuori dal thread input. La scorciatoia di fallback viene inviata solo se il processo in primo piano non è cambiato. La traduzione delle lettere e dei simboli usa il layout tastiera attivo con `UCKeyTranslate`.

I menu di navigazione (Vai/Cronologia e corrispondenti inglesi) vengono visitati per primi. Il fallback Command–parentesi è limitato a Safari e Finder, dove ha una funzione documentata di navigazione: nelle altre app non viene inviato automaticamente, perché potrebbe modificare testo. Disattivazione, stop e cambio configurazione annullano le ricerche di navigazione in coda.

Le funzioni di sistema si basano su scorciatoie pubbliche configurabili. Non viene letto o modificato il database privato dei symbolic hotkey. L’assenza di una scorciatoia valida lascia passare il pulsante, invece di sopprimerlo senza azione.

## Stato e lifecycle

`PreferencesStore` valida schema, numero dei binding, codici, duplicati e scorciatoie prima di salvare o caricare JSON in UserDefaults. Un file danneggiato o uno schema futuro riparte dai valori iniziali senza codici assegnati e con un messaggio esplicito. Non vengono salvati eventi, PID, titoli di finestre o una cronologia tastiera.

Il processo principale è un accessorio AppKit con interfaccia interamente SwiftUI. NSStatusItem gestisce il menu; non esistono helper. La chiusura della finestra rilascia il suo hosting controller e lascia il servizio attivo. `LSMultipleInstancesProhibited` e un controllo dei processi omonimi evitano i normali avvii duplicati. Sleep e blocco sessione chiudono il tap; wake e sblocco ripristinano la configurazione.

`SMAppService.mainApp.status` è la fonte dello stato login. Il parametro pubblico dell’Apple Event di apertura distingue il login dall’apertura manuale: al login non viene creata la finestra. Il flag di test `--background` permette di provare un avvio silenzioso, senza sostituire la prova di un vero logout/login.

SwiftUI e i colori semantici gestiscono aspetto, contrasto e accessibilità. Liquid Glass è limitato a controlli e indicatore; nessuna animazione personalizzata. L’alias `ViewState` seleziona il property wrapper pubblico `SwiftUI.State`, poiché i Command Line Tools 27 non includono il nuovo plugin della macro omonima.

## Documentazione Apple consultata

- [CGEvent.tapCreate](https://developer.apple.com/documentation/coregraphics/cgevent/tapcreate(tap:place:options:eventsofinterest:callback:userinfo:))
- [CGEventType](https://developer.apple.com/documentation/coregraphics/cgeventtype)
- [IOHIDManagerSetDeviceMatching](https://developer.apple.com/documentation/iokit/1438371-iohidmanagersetdevicematching)
- [IOHIDManagerRegisterDeviceMatchingCallback](https://developer.apple.com/documentation/iokit/1438399-iohidmanagerregisterdevicematchi)
- [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- [Avvio come login item](https://developer.apple.com/documentation/coreservices/1556410-launch_apple_event_constants/keyaelaunchedasloginitem)
- [Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Scorciatoie Safari](https://support.apple.com/en-gb/guide/safari/cpsh003/mac)
- [Scorciatoie Finder](https://support.apple.com/en-my/102650)
