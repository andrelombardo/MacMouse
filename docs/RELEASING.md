# Rilascio ripetibile

1. Aggiorna `CFBundleShortVersionString` e `CFBundleVersion` in `Sources/MacMouse/Resources/Info.plist`. Aggiorna README, note e verifiche. La beta corrente ha versione bundle 0.1.3 e tag `v0.1.3-beta.1`.
2. Esegui `scripts/test.sh`, `scripts/build.sh` e `scripts/package.sh`. Verifica il bundle estratto dallo ZIP. Non firmare di nuovo un bundle dopo la notarizzazione senza ripetere il processo.
3. Completa `MANUAL_TESTS.md` per le funzionalità dichiarate verificate. Conserva una prerelease finché il supporto hardware non è confermato. Una versione stabile richiede anche la variabile repository `HARDWARE_VERIFIED=true`, impostata soltanto dopo le prove fisiche.
4. Aggiorna `docs/RELEASE_NOTES.md`, committa su main e verifica la pipeline. Crea e pubblica un tag coerente con la versione, per esempio `git tag v0.1.3-beta.1` e `git push origin v0.1.3-beta.1`.
5. Il workflow ricompila, esegue i test, verifica il progetto Xcode, produce ZIP/DMG/checksum e crea la Release. I tag con suffisso sono prerelease. Solo il job di pubblicazione dispone di `contents: write`.
6. Controlla la pagina Release, scarica gli asset e verifica `shasum -a 256 -c SHA256SUMS.txt` dalla stessa cartella. Non sostituire silenziosamente una versione già pubblicata: usa un nuovo tag/versione.

Se occorre pubblicare gli archivi verificati localmente, dopo aver pubblicato il tag usa:

```sh
gh release create v0.1.3-beta.1 \
  dist/MacMouse-v0.1.3-macOS.zip \
  dist/MacMouse-v0.1.3-macOS.dmg \
  dist/SHA256SUMS.txt \
  --verify-tag --prerelease --title 'MacMouse 0.1.3 beta 1' \
  --notes-file docs/RELEASE_NOTES.md
```

Il workflow conserva una Release già esistente e non ne sostituisce gli asset.

## Firma opzionale

Senza credenziali gli script producono un bundle firmato ad hoc: non è una firma Developer ID e non è notarizzato. Il certificato Apple Development locale non è adatto alla distribuzione pubblica.

Per una build locale Developer ID, imposta `SIGN_IDENTITY` sull’identità **Developer ID Application** presente nel keychain. Per notarizzare imposta anche `NOTARY_KEYCHAIN_PROFILE` su un profilo creato con `xcrun notarytool store-credentials`. Lo script firma con hardened runtime e timestamp, invia l’app, controlla il successo, applica e verifica lo staple e ripete la verifica per il DMG. Una notarizzazione fallita interrompe la pubblicazione degli archivi finali.

In GitHub Actions configura soltanto questi Secrets:

- `DEVELOPER_ID_P12_BASE64`, `DEVELOPER_ID_P12_PASSWORD`
- `NOTARY_APPLE_ID`, `NOTARY_PASSWORD` (password specifica per app), `NOTARY_TEAM_ID`

Il workflow importa il certificato in un keychain temporaneo sul runner, non nel repository. Con certificato presente e credenziali notarizzazione incomplete il job fallisce esplicitamente. Certificati, password, token e profili locali non devono essere aggiunti a Git.
