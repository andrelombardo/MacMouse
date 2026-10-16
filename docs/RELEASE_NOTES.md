MacMouse 0.1.1 beta 1 aggiorna il rilevamento dei pulsanti e la gestione delle autorizzazioni.

- **Rileva pulsante** apre un pop-up con anteprima del numero, stato premuto/rilasciato, prove ripetute e pulsanti Conferma/Annulla. È accessibile direttamente sotto ogni riga.
- Le associazioni vengono salvate solo dopo Conferma. I duplicati sono segnalati prima del salvataggio.
- Il riquadro riceve i pulsanti locali anche senza Accessibilità, senza abilitare il controllo globale e senza acquisire tasti della tastiera.
- Il consenso al controllo del dispositivo e quello all’invio delle scorciatoie sono mostrati separatamente. La diagnostica mostra i valori reali e il percorso della copia in uso.
- Build e installazione sostituiscono un bundle completo verificato; lo script di installazione locale può usare un certificato già disponibile nel keychain per mantenere l’identità tra le compilazioni.

**Requisiti:** macOS 27+, Apple Silicon. Scarica `MacMouse-v0.1.1-macOS.zip` oppure il DMG e verifica `SHA256SUMS.txt`.

**Firma della Release pubblica:** ad hoc, senza Developer ID e senza notarizzazione. La firma Apple Development eventualmente usata per l’installazione locale non è inclusa in questi archivi. Gatekeeper può richiedere la procedura di approvazione offerta da macOS; nessuna protezione viene disabilitata.

**Consenso macOS:** una compilazione ad hoc può richiedere di riaggiungere l’app in Privacy e sicurezza → Controllo del dispositivo e accesso ai dati. Se macOS conserva ancora un’identità precedente, può essere necessario un riavvio del Mac. Il rilevamento locale nel pop-up non sostituisce il permesso necessario per rimappare globalmente.

**Verifiche:** 30 test automatici su pressione/rilascio, selezione provvisoria e conferma, annullamento, duplicati, isolamento dei clic primari, eventi sintetici, stati delle autorizzazioni, persistenza e recupero del tap. La build Release Xcode e i pacchetti sono verificati dal workflow prima della pubblicazione.

**Limiti:** profilo globale, senza attribuzione degli eventi al singolo mouse. Il supporto fisico completo al TECKNET TK-MS317 resta da verificare con la [procedura manuale](https://github.com/andrelombardo/MacMouse/blob/main/docs/MANUAL_TESTS.md). Navigazione dipendente dai menu dell’app e dal layout; le azioni di sistema richiedono scorciatoie abilitate. Logout/login reale, sleep/wake e uso prolungato richiedono ancora verifica manuale.
