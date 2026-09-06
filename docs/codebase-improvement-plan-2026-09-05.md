# Förbättringsplan för FrosthavenAssistant

**Status: implementation beställd 2026-09-05.** Se [genomförandestatus](improvement-plan-progress.md). Texten nedan är det ursprungliga granskningsunderlaget.
Granskad 2026-09-05, commit `f73e6e2c`, gren `codex/windows-android-releases`, inklusive arbetsytans befintliga ändringar.

Min rekommendation är att först täppa till luckor i sparning, synkronisering och verifiering, därefter förbättra tillgänglighet och layout. Behåll Flutter, kommandon, snapshots och ValueNotifier. Arkitekturen behöver tydligare ansvar och beroenden; underlaget motiverar inte ett byte av ramverk eller tillståndsbibliotek.

**Omfattning och tillförlitlighet**

Hela kodbasens huvudområden har inventerats. Genomgången kombinerar breda sökningar, närläsning av centrala flöden, testgranskning och befintliga skärmbilder. Det är inte en garanti att varje rad är felfri.

| Område | Inventerat underlag |
| --- | --- |
| Flutter Layout | 170 Dart-filer, cirka 21 472 rader |
| Flutter Resource | 132 Dart-filer, cirka 12 616 rader |
| Modeller | 7 Dart-filer, cirka 858 rader |
| Flutter services | 12 Dart-filer, cirka 1 273 rader |
| Appstart och livscykel | main.dart och main_state.dart |
| Standalone-server | Samtliga 6 lib-filer, cirka 895 rader, och båda testfilerna |
| Datakonverterare | Samtliga 3 lib-filer, cirka 336 rader, test och konfiguration |
| Övrigt | Lokala show_fps-paketet, plattformskod/byggkonfiguration, CI, språkfiler, assets och manual |

De tre huvudpaketens lib-mappar omfattar 332 Dart-filer och cirka 37 893 rader exklusive genererad lokalisering. Det lokala show_fps-paketet tillkommer. Genererad plattformsregistrering och bilder har inventerats, inte behandlats som handskriven affärslogik. Andra worktrees, byggcache och tidigare artefakter ingår inte som produktkod.

Arbetet delades mellan GPT-5.6 Sol för arkitektur, Terra för UI och regeltextrendering samt Luna för server och verktyg. Huvudgranskningen verifierade fynd, läste plattformarnas start-/stängningskod, körde baslinjen och sammanfogade prioriteringarna. Misstankar som inte höll vid kontroll har strukits.

Plattformspasset omfattade särskilt Androids cachade FlutterEngine och foreground-service med MethodChannel, iOS/macOS appdelegater och behörighetskonfiguration, Windows-runnern och Linux GTK-fönstrets stängning. Inga nya nativefel fastställdes genom körning. Behåll befintliga livscykelåtgärder och verifiera dem tillsammans med F03/F08 på respektive plattform.

Fysiska Android-/iOS-enheter, releasebyggd desktop, skärmläsare och faktisk GitHub-publicering har inte verifierats här. UI-bedömningar från äldre skärmbilder är hypoteser tills de har kontrollerats i den aktuella appen. Prioriteringen utgår från det dokumenterade användningsfallet: stridshjälp vid spelbordet, på mobil och desktop, med LAN-synkronisering.

**Verifierad baslinje**

| Kontroll | Resultat |
| --- | --- |
| Lokal miljö | Flutter 3.44.8, Dart 3.12.2, Windows |
| Generera befintliga testmockar | Klart |
| Flutter analyze, enligt projektets flaggor | Inga anmärkningar |
| Hela Flutter-testsviten, concurrency 4 | 1 676 passerade, 1 överhoppat |
| Separat prestandatest, concurrency 1 | 6 passerade |
| Serveranalys | Inga anmärkningar |
| Servertester | 7 passerade |

Det överhoppade testet är ett anslutningstest med en kommenterad portfråga, [connection_test.dart](../frosthaven_assistant/test/services/connection_test.dart#L217). En grön svit är inte ett fullständigt UI-kvitto: 70 testfiler använder en hjälpare som kan filtrera bort layout- och assetfel.

Serverns `dart test` löste om äldre utvecklingsberoenden för den installerade SDK:n. Den versionshanterade lockfilens innehåll återställdes efter körningen. Serverresultatet gäller därför den lösta testmiljön, inte en verifiering av att den gamla lockfilen fungerar oförändrad. Den lösta filen finns i [server-resolved.pubspec.lock](../artifacts/codebase-review-2026-09-05/server-resolved.pubspec.lock).

Loggar: [Flutter-tester](../artifacts/codebase-review-2026-09-05/flutter-test.log), [Flutter-analys](../artifacts/codebase-review-2026-09-05/flutter-analyze.log), [servertester](../artifacts/codebase-review-2026-09-05/server-test.log), [serveranalys](../artifacts/codebase-review-2026-09-05/server-analyze.log), [separat prestandakörning](../artifacts/codebase-review-2026-09-05/performance.log).

| Fixture | Snapshot, byte | Serialisering p95 | Action p95 | Full listrebuild p95 |
| --- | ---: | ---: | ---: | ---: |
| Small | 3 577 | 0,489 ms | 0,301 ms | 33,85 ms |
| Medium | 11 071 | 0,299 ms | 0,335 ms | 84,74 ms |
| Stress | 24 221 | 0,509 ms | 0,724 ms | 141,50 ms |

Detta är debug-/widgettester, inte uppmätt bildfrekvens i produktion. Full listrebuild filtrerar dessutom bort vissa overflowfel. Samma stresstest under parallell test/analys gav cirka 295 ms, vilket visar varför dessa tider inte ska användas som precisa optimeringslöften. Utfallet ger inget stöd för att omedelbart flytta JSON till en separat isolate. Tidigare mätningar och redan genomförda försök finns i [performance-benchmarks.md](performance-benchmarks.md).

**Behåll det som redan fungerar**

Den befintliga [förbättringsplanen](performance-ux-improvement-plan.md) har jämförts med implementationen. Följande ska bevaras:

- Appens begränsade historik, direkta rollback och återanvändning av samma snapshot för historik och nätverk.
- Kön som behåller den senaste väntande spelsparningen. Förbättra felhanteringen, ersätt inte själva köidén.
- Återläsning som återanvänder befintliga figur-/deckobjekt och därmed bevarar UI-prenumerationer.
- Bytebaserad nätverksinramning, storleksgräns, protokollhandshake och skydd mot inaktuella anslutningsförsök.
- Befintliga storlekstoken, desktopinställningar, listdragning med mus, tangentbordsstöd och komponentuppdelningar.

**Prioriterad arbetslista**

P1 betyder hög nytta eller konkret fel att ta tidigt. P2 är nästa steg eller en avgränsad arkitekturförbättring. P3 är underhåll eller ett produktbeslut. Insatser är grova utvecklardagar inklusive relevanta tester och granskning; de är inte kalenderlöften. Översättningsgranskning och väntan på fysisk testutrustning tillkommer.

| ID | Prioritet | Förbättring | Insats | Beroende |
| --- | --- | --- | ---: | --- |
| F01 | P1 | Trovärdig CI- och UI-verifiering | 2–3 d | Inget |
| F02 | P1 | Omedelbara, korrekta snapshots för mottagna nätverkstillstånd | 1–2 d | Riktade tester |
| F03 | P1 | Robust sparning, inställningsläsning och appstart | 3–5 d | Inget |
| F04 | P1 | Begränsa standalone-historik och städa anslutningar | 3–4 d | F02:s synkregler |
| F05 | P1 | Tillgänglig kärn-UI och fungerande textskalning | 4–6 d | F01:s strikta UI-tester |
| F06 | P1 | Gemensam kolumnplanering för beräkning och rendering | 2–3 d | F01 |
| F07 | P1/P2 | Rätta ignorerad injektion; pröva tydligare domängräns | 2–3 d pilot | F01–F03 |
| F08 | P2 | Livscykelägda UI-effekter och färre sidoeffekter i build | 1–2 d | Samordnas med F07 |
| F09 | P2 | En protokollcodec och tillförlitlig adressuppdatering | 2–4 d | F02, F04 |
| F10 | P2 | Språkparitet och tydligare spelkontroller | 3–5 d | F05, F06 |
| F11 | P1 mätning | Profilera verklig rendering, uppstart och minne | 1–2 d | Ren baseline efter F01 |
| F12 | P2 | Validera regeltext; separera parser och rendering i en pilot | 4–7 d | F01, F10:s tokenkontrakt |
| F13 | P2 | Versionshanterad sparcodec och skyddad publicerad speldata | 3–5 d | F02, F03, F07 |
| F14 | P2/P3 | Återställ datakonverterarens användbarhet | 2–3 d | Bekräfta att verktyget används |
| F15 | P3 | Dokumentation, byggverktyg och tydlig publiceringsyta | 1–2 d | Vald plattforms-/publiceringsinriktning |

Tabellen är en valbar backlog. Rekommendationen är att godkänna en första etapp och utvärdera nästa, inte att beställa hela listan på en gång.

**F01 – Trovärdig CI- och UI-verifiering**

Evidens: [flutter.yml](../.github/workflows/flutter.yml#L30) analyserar innan mockar genereras, medan mockfilerna ignoreras av Git. En ren checkout får därför ett annat analysunderlag än arbetsytan med genererade mockar. [test_helpers.dart](../frosthaven_assistant/test/command/test_helpers.dart#L87) ignorerar både alla meddelanden som börjar med RenderFlex-overflow och saknade assets. Hjälparen förekommer i 70 testfiler.

Ändring: lägg codegen före analys i samma ordning som de andra relevanta workflow-filerna. Skapa en liten, strikt UI-svit för huvudlista, statusdialog och inställningar med verkliga assets och realistiska viewports. Flytta kvarvarande avsiktliga undantag till enskilda tester med exakt förväntat fel. Behåll isolerade enhetstester som inte behöver full appgrafik.

Klart när: en ren checkout genererar, analyserar och testar i rätt ordning; ett avsiktligt introducerat overflow eller saknat asset får den strikta sviten att fallera; desktop-/mobilmatrisen nedan passerar för de tre valda vyerna.

Risk: uppdämt testbrus. Migrera i små grupper; dölj inte nya fel genom att höja toleranser generellt. Kontrollera även vilka lintregler som faktiskt körs: en `dart_code_metrics`-sektion och paketet `dart_code_metrics_presets` är inte i sig bevis för ett aktivt DCM-steg i CI.

**F02 – Mottagna tillstånd ska få sin egen snapshot direkt**

Evidens: [client.dart](../frosthaven_assistant/lib/services/network/client.dart#L245) läser in state/index direkt men anropar save efter 100 ms. [GameState.save](../frosthaven_assistant/lib/Resource/state/game_state.dart#L266) fångar det tillstånd och index som finns när callbacken körs. A och B inom 100 ms kan därför ge två sparningar av B och ingen snapshot för A. I [action_log_menu.dart](../frosthaven_assistant/lib/Layout/menus/action_log_menu.dart#L101) blir poster utan återställbar snapshot inaktiva.

Ändring: inför en avgränsad operation för mottagna övergångar som validerar state, binder snapshot till just mottaget index och uppdaterar historik/event innan övergången är färdig. Disk-I/O får fortfarande köas. Ta bort snapshotfördröjningen och skilj ett nytt steg från auktoritativ korrigering/rollback. Låt klient och Flutter-host använda samma regler där deras roller överlappar. Publicera en avslutande övergångsrevision eller motsvarande så att historik-UI uppdateras när appliceringen är klar. En gemensam metod garanterar inte att alla separata ValueNotifiers slutar avge mellanvärden; full observatörsatomik ingår inte i detta steg.

Klart när: två inkommande envelopes utan tidsframflyttning får var sin korrekt snapshot; historikpanelen kan nå båda; felaktigt paket lämnar state/index/historik oförändrade; reconnect eller reset kan inte påverkas av en gammal callback. Behåll identiteten hos notifierade figur-/deckobjekt.

Risk: index efter mismatch, undo och en ny historikgren. Vanlig Undo/Redo medan klienten är ansluten skickas till hosten och är inte visad som trasig av detta fynd.

**F03 – Sparning och uppstart ska kunna rapportera och återhämta fel**

Evidens: [settings.dart](../frosthaven_assistant/lib/Resource/settings.dart#L222) gör fristående skrivningar, sväljer undantag och läser sedan JSON utanför läsningens try/catch. Style läses med ett obegränsat enumindex på rad 294. [game_state.dart](../frosthaven_assistant/lib/Resource/state/game_state.dart#L283) sväljer också skrivfel och kontrollerar inte ett false-resultat från setString. Därmed kan flush signalera framgång trots misslyckad lagring. [main.dart](../frosthaven_assistant/lib/main.dart#L144) slår av loading både vid framgång och vid fel, även om återstående initiering inte har körts.

Ändring, i två små leveranser:

1. Inför en validerande SettingsCodec som först tolkar till temporära värden, använder dokumenterade standardvärden för ogiltiga fält och sedan applicerar dem. Lägg inställningsskrivningar i samma slags latest-value-kö som speltillståndet.
2. Gör skrivfel observerbara genom en ägd sparstatus och ett konsekvent resultat för explicit save/flush. Hantera fel från bakgrundssparning utan oägda futures. Använd tydliga startup-lägen för laddning, färdig och återhämtningsbart fel. Behåll en felaktig sparning tills användaren uttryckligen väljer återställning.

Klart när: trasig JSON, fel typer och enumindex inte ger en delvis initierad app; kastade skrivfel och false ger misslyckad explicit save/flush; en senare lyckad skrivning återställer status; snabb följd av inställningar lagrar det senaste värdet. Desktopstängning ska erbjuda försök igen eller ett uttryckligt val att stänga ändå, så ett ihållande lagringsfel inte låser appen. Rollbyte ska hantera fel enligt dokumenterad policy. Mobilens pause/detached får bara lova ett sparförsök och diagnostik; operativsystemets avslutning kan hindra att asynkron lagring blir färdig.

Risk: ofrivillig dataförlust vid automatisk fallback. Ändra inte sparformat, standardvärden eller återställningspolicy i samma steg utan fixtures.

**F04 – Begränsa standalone-serverns resursanvändning**

Evidens: [server_state.dart](../frosthaven_assistant_server/lib/server_state.dart#L3) har obegränsade snapshot-/beskrivningslistor, trots att Flutter-appen redan har gränser. [standalone_server.dart](../frosthaven_assistant_server/lib/standalone_server.dart#L69) tar bort aktiva sockets men lämnar poster i _connectionHealth. Skrivfel loggas utan motsvarande borttagning på rad 154.

Ändring: inför explicit retained-index-intervall och gräns för antal snapshots samt sammanlagrad snapshotstorlek. Utgå från appens historikprinciper, men gör en eventuell delad kärna till ren Dart utan beroende från servern till Flutter. Ta bort den oanvända parallella commands-strukturen. Samla socketstädning i en idempotent operation och iterera över en säker kopia när en broadcast kan ta bort klienter.

Klart när: exempelvis 10 000 uppdateringar håller historiken inom den konfigurerade gränsen; undo/redo/branch fungerar vid eviction; begäran om för gammal rollback ger ett definierat svar. Upprepade connect/disconnect-cykler lämnar inga health-poster och ett skrivfel stoppar senare försök till samma döda socket.

Risk: nätverksindex måste fortsätta vara absoluta efter eviction. Base-klassen rensar redan handshake-set i normal onDone; det är fel att kalla dem permanent läckande. Stop/start-vägen behöver ett eget test eftersom dess cleanup beror på serverEnabled.

**F05 – Gör kärnåtgärder tillgängliga**

Evidens: [main.dart](../frosthaven_assistant/lib/main.dart#L203) placerar hela appen under ExcludeSemantics, vilket även slår ut lokala semantiketiketter. [main_state.dart](../frosthaven_assistant/lib/main_state.dart#L197) använder global OverrideTextScaleFactor.

Ändring: ta bort den globala semantikexkluderingen och exkludera endast dekorativa bilder. Ge Draw/Next round, initiativ, HP, status, element och menyer namn, värden och handlingar. Gör systemtextskalning till standard för operativa kontroller/dialoger. Spelkortens grafiska layout kan behöva behålla sin egen skala; erbjud då motsvarande läsbara text-/statusdetaljer. Gör inte hela spelkortet större genom en blind global ändring.

Klart när: TalkBack/VoiceOver kan genomföra kärnflödena; semantiktester verifierar åtgärder och läsordning; operativ UI fungerar vid 100/150/200 procent systemtext på valda storlekar. Touchytor får inte krympa under den beslutade miniminivån när listskalan minskar. Använd Flutter-guideline-tester där de passar.

Risk: dubbla annonseringar, för tät layout och konflikt mellan kortskala och textskala. Validera en kärnvy i taget. Flutter beskriver semantik och anpassningar för tillgänglighet i sin [officiella vägledning](https://docs.flutter.dev/ui/accessibility).

**F06 – Beräkna och rendera samma kolumner**

Evidens: [main_list_view_model.dart](../frosthaven_assistant/lib/Layout/view_models/main_list_view_model.dart#L124) uppskattar passform genom lika många poster per kolumn. [game_list.dart](../frosthaven_assistant/lib/Layout/MainList/game_list.dart#L349) flyttar därefter brytpunkten för en länkad anteckning och använder det nya antalet för alla kolumner. Nio poster kan beräknas som 3+3+3 men renderas som 4+4+1. Vid listslutet kan koden också återgå till den gamla brytpunkten och dela ett länkat par.

Ändring: skapa en gemensam ColumnPlan över sammanhållna grupper av målrad och länkade anteckningar. Låt både auto-val och rendering konsumera planen. Om ReorderableWrap inte kan uttrycka olika brytpunkter, avgränsa först en kompatibel lösning för gruppering; byt inte hela listkomponenten i samma PR. Bevara platt indexordning för kommandon och nätverk.

Klart när: alla brytpunkter och flera anteckningar per mål är testade; prediktor/renderare använder identiska grupper; fixture-layout väljer minsta fungerande antal 1–3 kolumner enligt dokumenterad höjdtolerans. Ett mål med anteckningar som är högre än en hel viewport får scrolla som en sammanhållen grupp. Ingen oväntad horisontell overflow, och mus-/touch-/tangentbordsomordning fungerar.

Risk: gruppdragning, återställd fokusposition och visuellt ändrad kolumnbalans. Höjderna är uppskattningar; kräv inte artificiell precision på en pixel.

**F07 – Gör injicerade beroenden till verkliga beroenden**

Evidens: [SetScenarioCommand](../frosthaven_assistant/lib/Resource/commands/set_scenario_command.dart#L8) tar emot GameState men använder det inte. [UnlockSpecialCommand](../frosthaven_assistant/lib/Resource/commands/unlock_special_command.dart#L9) läser ett injicerat state men muterar via globala helpers. [game_actions.dart](../frosthaven_assistant/lib/Resource/game_actions.dart#L24) tar emot state/settings men anropar canDraw utan dem. Totalt finns GetIt-anrop i 122 lib-filer; antalet är en kopplingsindikator, inte ensamt ett fel.

Ändring: rätta dessa konkreta fall först. Migrera sedan scenario- och rundkommandon som pilot till explicita state/data/settings-beroenden. Begränsa GetIt till sammansättning och övergångsvis UI-konstruktorer. Behåll GameState.action som kompatibel fasad under arbetet.

Låt piloten pröva en liten GameSession-/applikationskoordinator som äger övergångens ordning: validera, exekvera, registrera historik och notifiera portar för sparning/synk. Inför inte ett nytt lager som bara skickar samma argument vidare.

Klart när: två separata GameState-instanser kan användas i samma test och en operation endast påverkar sitt avsedda spel; pilotens kommandon behöver inget globalt registrerat speltillstånd; inga nya GetIt-anrop tillkommer i migrerade domänfiler.

Risk: många signaturer och lokalisering av kommandobeskrivningar. Lägg översättningsberoenden vid användargränsen eller injicera en beskrivare. En bredare migrering uppskattas först efter piloten; 4–7 extra dagar kan behövas beroende på vald omfattning.

**F08 – Låt UI äga UI-effekter och prenumerationer**

Evidens: [GameState](../frosthaven_assistant/lib/Resource/state/game_state.dart#L14) importerar konkret UI; [scenario_methods.dart](../frosthaven_assistant/lib/Resource/scenario_methods.dart#L425) och rundkommandon scrollar huvudlistan. [network_ui.dart](../frosthaven_assistant/lib/services/network/network_ui.dart#L26) skapar delayed-callbacks i build som läser ett senare globalt meddelande. A följt av B inom 200 ms kan därför tappa A. [main_state.dart](../frosthaven_assistant/lib/main_state.dart#L183) behåller inte tangentbordets StreamSubscription för avregistrering.

Ändring: returnera eller publicera typade, lokala UI-effekter och konsumera dem i monterad UI med tydlig ägare. Skilj dessa från nätverkets serialiserade GameEvent. Definiera om meddelanden ska köas eller om endast det senaste gäller; behandla viktiga fel uttryckligen. Äg scrollcontroller och tangentbordsprenumeration i rätt livscykel. Flytta menynavigering ur de view-models som idag bygger konkreta menyer.

Klart när: kommandon inte behöver ett widgetträd för att kunna köras; en effekt konsumeras enligt beslutad policy; dispose/reconnect lämnar inga callbacks som ändrar ny UI; gamla meddelanden kan inte rensa nyare fel.

Risk: animationstidpunkt och spam från informationsmeddelanden. Generella dubbla network-toastar är inte bevisade; fyndet gäller förlust/överskrivning och ägarskap.

**F09 – Dela protokollkontrakt och gör nätverksinformation aktuell**

Evidens: [communication.dart](../frosthaven_assistant/lib/services/network/communication.dart#L11) och [game_server.dart](../frosthaven_assistant_server/lib/game_server.dart#L66) har separata codecs för samma i/d/e/s-format. [network_info.dart](../frosthaven_assistant/lib/services/network/network_info.dart#L87) uppdaterar en adressmängd genom att lägga till utan att ta bort gamla adresser, och startar ny refresh vid varje connectivity-event.

Ändring: dela en kanonisk envelope-typ/codec i det redan gemensamma Dart-paketet. Bevara wire-formatet. Samla IP-refresh till högst en aktiv operation, publicera hela aktuella adressuppsättningen atomiskt och ignorera gamla resultat. Hämta LAN-adress oberoende av extern public-IP-tjänst; använd timeout och hämta publik IP när den behövs. Rätta IPv6-namn som i praktiken betyder IPv4.

Klart när: app/server använder samma codec och har fixturebaserade kompatibilitetstester; ett borttaget interface försvinner från UI; ett gammalt refreshresultat kan inte skriva över ett nytt; LAN-hostning fungerar när public-IP-tjänsten inte svarar.

Risk: verkliga nätverksbyten på mobil och äldre klienter. Prova även DNS-adresser där första adressen misslyckas men nästa fungerar; [connection.dart](../frosthaven_assistant/lib/services/network/connection.dart#L31) väljer idag den första.

**F10 – Språkparitet och tydligare spelkontroller**

Evidens: samtliga nio icke-engelska ARB-filer saknar samma 28 UI-strängar som finns i [app_en.arb](../frosthaven_assistant/lib/l10n/app_en.arb#L20). Historikrubriken säger dessutom Last 20 Actions trots att vyn kan visa 500. [character_xp_widget.dart](../frosthaven_assistant/lib/Layout/CharacterWidget/character_xp_widget.dart#L26) använder tryck för plus och dubbeltryck för minus; HP-dragning och andra snabbgester kräver förkunskap.

Ändring: komplettera de stödda språkens UI-nycklar och rätta felvisande historiktext. Lägg paritetskontroll för ARB inklusive platshållare. För speldataöversättningar: validera markup/tokenbevarande och tillåt uttryckligen dokumenterad engelsk fallback. Översättningarnas existens är inte bevis för språklig kvalitet.

Gör därefter en liten UX-pilot för XP, monster-HP och status: konsekventa hover-/fokustexter, begripliga träffytor och en synlig väg till exakt redigering. Behåll snabbgester. Prova en kort kontextuell hjälp innan en bred onboarding byggs. Konsolidera operativa färg-/typografitoken och mät läsbarhet mot verkliga bakgrunder; anta inte att alla kontraster är fel.

Klart när: inga saknade UI-nycklar återstår för stödda språk, platshållare är intakta och långa texter klarar strikt layouttest. I ett litet uppgiftstest hittar minst 4 av 5 nya användare HP-/statusändring utan manual; resultatet är en formativ kontroll, inte statistiskt bevis. Gör touch- och tangentbordsvägar likvärdigt åtkomliga.

Risk: oavsiktlig ändring av snabbspelandets rytm och felöversatta regeltermer. Språkarbetet gäller de språk som appen redan stöder.

**F11 – Mät innan större prestandaändringar**

Det finns verifierade kostnadskandidater, men ännu inga mätningar på målenheter som motiverar stora ombyggnader:

| Kandidat | Kodbevis | Första experiment |
| --- | --- | --- |
| Breda rebuilds vid återupptagning | main_state.dart:99,148 markerar hela underträdet | Mät resume och ersätt med riktade notifieringar om detta dominerar |
| Upprepat kopierade listvyer | game_state.dart:118; main_list_view_model.dart:49 | Mät allokeringar; prova en snapshot per beräkningspass |
| Alla huvudlistans barn byggs | main_list.dart:109 och game_list.dart:274 | Mät stress-scroll; pröva virtualization endast om kostnaden är betydande |
| All kampanjdata laddas sekventiellt | game_data.dart:17–74 | Mät kallstart, JSON-tolkning och minne separat; pröva begränsad parallell laddning |
| Stora bildkällor utan enhetlig decodepolicy | monster_image_part.dart:51 och flera kortfronter | Mät decoded-image-minne och prova befintliga decodehjälpare för ett bildslag |

Assets omfattar cirka 62,69 MiB PNG, 5,44 MiB JSON och 1,58 MiB typsnitt i källträdet. Detta är varken installerad appstorlek eller RAM-förbrukning. Bakgrunder och vissa figurresurser har redan storleksanpassad avkodning.

Mätplan: en överenskommen Android-enhet med begränsat minne samt Windows i profileläge, small/medium/stress, 30 upprepningar efter uppvärmning. Separera build/raster, action-till-synlig-uppdatering, kallstart, resume, minne efter lång session och trafik under två klienter. Dokumentera enhet, upplösning, skala och scenario. Kör baslinjen utan appens show_fps-overlay så att dess egna uppdateringar inte påverkar idle-/rebuildmätning. Flutter rekommenderar att dyra rebuilds och listlayout undersöks med profilering; lazy-byggare är relevanta för stora listor. [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices).

Föreslagen beslutsregel: gå vidare med en optimering först när ett identifierat problem reproduceras och samma experiment visar tydlig förbättring utanför mätbruset, utan sämre minne, skärpa eller beteende. Använd 60 Hz/16,7 ms som ett mål att diskutera för bildrutebudget, inte som ett redan uppnått krav. Paketera optimeringar separat från arkitekturändringar.

**F12 – Separera regeltextens grammatik från widgetträdet**

Evidens: [LineBuilder.createLines](../frosthaven_assistant/lib/Resource/line_builder/line_builder.dart#L89) blandar parsing, stats, layout och animation. [FrosthavenConverter](../frosthaven_assistant/lib/Resource/line_builder/frosthaven_converter.dart#L252) läser tillbaka markörsträngar ur redan byggda Container/Text-widgets. På rad 63, 69 och 115 finns antaganden om föregående/nästa rad och stränglängd. Det är en robusthetsrisk för felaktig data, inte ett påvisat fel i alla paketerade kort.

Ändring: börja med en korpusvalidator för all paketerad regeltext och relevanta dataformler. Dokumentera den faktiskt stödda grammatiken och ge rad-/kortidentifierad diagnostik för felaktig input. Lägg därefter ett litet internt mellanformat för text, token, rad, kolumn och conditional/subline i en pilot. Renderaren ska konsumera noder och aldrig tolka ett widgetträd som data.

Klart när: legacy-korpusen kan tolkas, gränsfall inte kastar under widgetbygge och statformler har definierade resultat över stödda nivåer/gruppstorlekar. Jämför representativa GH-/FH-/boss-/element-/nested-row-kort med godkända bilder.

Risk: radbrytningar och specialregler. Behåll gammal fasad under migreringen och undvik samtidigt ändrat dataformat, styling eller caching. Första validatorsteget kan levereras för 1–2 dagar; resten är en separat granskningspunkt.

**F13 – Gör stateövergångar och sparformat hållbara**

Evidens: [action_handler.dart](../frosthaven_assistant/lib/Resource/action_handler.dart#L183) muterar först och registrerar historik efteråt; ett kommando som kastar mitt i arbetet kan lämna en partiell mutation. Detta är en verifierad designrisk, inte ett reproducerat användarfall i denna granskning. [game_state.dart](../frosthaven_assistant/lib/Resource/state/game_state.dart#L225) saknar top-level schemaversion och skriver enumindex. [game_save_state.dart](../frosthaven_assistant/lib/Resource/state/game_save_state.dart#L19) muterar observerbara fält under parsing. Publicerade kampanjmodeller innehåller dessutom muterbara samlingar.

Ändring: validera en inkommande snapshot till ett temporärt värde innan den appliceras på befintliga notifierobjekt. Gör command-fel till en misslyckad övergång utan nytt historiksteg eller broadcast; återanvänd den befintliga snapshoten för återställning där den säkert representerar startläget. Bevara fel i diagnostiken. Inför top-level codec/version först när kompatibilitetsfixtures finns, med läsning av legacy-enumindex. Frys färdigbyggd kampanjdata innan publicering.

Klart när: ett testkommando som muterar och kastar återställer state/historik när giltig startsnapshot finns och återställningen lyckas, utan ny disk-/nätverksskrivning. Testa även misslyckad återställning: visa ett återhämtningsläge och stoppa vidare mutation/sparning/sändning tills tillståndet har återställts eller lästs om. Felaktigt inkommande state ska inte lämna en halvuppdaterad modell som fortsätter användas. Gamla sparningar ska fortfarande kunna läsas. Nya format får inte skickas till äldre klienter utan en uttrycklig kompatibilitetsregel.

Risk: högre än vanlig städning. Att notifierare hinner avge mellanliggande värden är ett separat problem; full notifieringsbatchning ska vara ett medvetet nästa steg om det behövs. Ändra inte samtidigt schemaversion, nätverksprotokoll och hela tillståndsmodellen.

**F14 – Gör datakonverteraren deterministisk om den ska underhållas**

Evidens: [room_data_converter.dart](../room-data-converter/lib/room_data_converter.dart#L7) startar flera oawaitade läs-/skrivkedjor som delar samma sträng, append-skriver och returnerar 42 innan arbetet är klart. På rad 136 ignoreras replaceAll-resultatet. [testet](../room-data-converter/test/room_data_converter_test.dart#L4) verifierar inte den producerade filen. Paketet kräver dessutom Dart under version 3. Källmappens Frosthaven.json och random.json gick inte att JSON-tolka; detta gäller konverterarens filer, inte automatiskt appens speldata.

Ändring: välj att antingen underhålla verktyget eller tydligt arkivera det. Vid underhåll: uppdatera SDK-kontraktet, ta input/output som parametrar, invänta alla steg, samla typade resultat och skriv en komplett JSON-fil via temporär fil i stället för append av strängfragment. Lägg ett CI-jobb som inte skriver över produktdata.

Klart när: en färdig await betyder färdig fil, resultatet går att läsa, upprepad körning är byteidentisk och fixturekontroller verifierar ordning och namnkonvertering. Kör inte dagens calculate mot verkliga data som ett test.

Risk: få dokumenterade inputantaganden och oklar faktisk användning. Denna punkt kan avföras genom ett medvetet arkiveringsbeslut.

**F15 – Minska underhållsbrus och klargör publiceringen**

Evidens: manualen beskriver long press där desktop numera har direktdragning och Alt+pil; CLAUDE.md innehåller inaktuella arkitektur-/kommandobeskrivningar. [static.yml](../.github/workflows/static.yml#L35) laddar hela repository-roten till Pages. README dokumenterar primärt nativeplattformar, så en trasig Flutter-webbdeployment är inte fastställd.

Ändring: uppdatera dokumentation samtidigt med berörd funktion och behåll stabila manualankare. Dokumentera en stödd SDK-/lockfilstrategi för app och server. Flytta rena ikon-/splashbyggverktyg till utvecklingsberoenden efter verifiering av användningen. Rensa oanvända stubbar/fasader när deras sista anrop har försvunnit; gör inte en stor katalogomdöpning för konsekvensens skull.

För Pages behövs ett produktbeslut: manual, annan statisk resurs eller ingen publicering. En manualpublicering ska paketera både HTML och refererade screenshots med fungerande relativa länkar. Webbläsarversion av Flutter är en separat produktkanal och ingår inte utan ett sådant beslut.

Klart när: dokumenterade gester/kommandon stämmer, reproducerbar SDK/codegen-ordning är beskriven och en vald publiceringsartefakt innehåller den avsedda startsidan med fungerande länkar. Ingen deployment görs som del av denna granskning.

**Arkitekturriktning att granska**

I nuläget går beroenden åt båda håll mellan spellogik, UI, globala tjänster och transport. Filuppdelningarna har förbättrat läsbarheten, men delar ansvaret fortfarande samma globala tillstånd.

Föreslagen riktning, där GameSession är ett möjligt nytt ansvar och övriga delar huvudsakligen finns redan:

~~~mermaid
flowchart TD
  UI["Widgets och dialoger"] --> VM["View-models: värden och användaravsikter"]
  VM --> SESSION["GameSession: samordnar en övergång"]
  SESSION --> CMD["Kommandon och spelregler"]
  CMD --> STATE["GameState och notifierade läsvyer"]
  SESSION --> HISTORY["Begränsad historik"]
  SESSION --> CODEC["Validerad snapshot / codec"]
  CODEC --> PORTS["Portar för sparning och synkronisering"]
  PORTS --> IO["SharedPreferences och LAN-transport"]
  SESSION -. "Lokala UI-effekter" .-> UI
~~~

Pröva gränserna i scenario-/rundflödet före bred migrering. Behåll notifierobjektens identitet och mutationernas samlade ingång. Behåll state-libraryns part-filer tills det finns ett konkret skäl att dela dem; den privata mutationstoken gör en mekanisk paketsplit olämplig.

Arkitekturen behöver också ett uttryckligt beslut om synkronisering: hosten ordnar idag klienternas färdigberäknade snapshots via index och korrigerar konflikter. Det ger enkel återställning, men en klientändring som bygger på ett gammalt index kan skrivas över. F02 löser historikens hantering av mottagna tillstånd; det gör inte protokollet konfliktfritt. Om samtidiga ändringar visar sig vara ett viktigt användarproblem bör nästa design vara kommandointentioner till en auktoritativ spelmotor, med definierade slumpresultat och konfliktregler. Det är en separat, större migration.

Följande alternativ har övervägts:

| Alternativ | Bedömning |
| --- | --- |
| Fortsätt endast dela stora filer | Billigt lokalt, men löser inte ignorerad injektion eller otydliga övergångar |
| Behåll stommen, gör beroenden/övergångar explicita | Rekommenderad pilot: löser konkreta problem och går att införa stegvis |
| Kommandosynk till en auktoritativ host | Kan hantera samtidiga avsikter bättre; kräver delad spelmotor, definierad slump och protokollmigration. Utred vid ett verifierat behov |
| Ny state-stack, full immutable rewrite eller event sourcing | Hög migrationsrisk; ingen uppmätt nytta som motiverar kostnaden idag |

**Rekommenderad genomförandeordning efter godkännande**

1. **Etapp A, cirka 7–11 utvecklardagar:** F01, F02, F03 och de konkreta injektionsfelen i början av F07. Leverera separata små PR:er. Granska resultatet innan bredare arkitekturarbete.
2. **Etapp B, valbar efter A:** F04 för den som använder standalone-hosting; F05–F06 för allmän produktnytta. UI- och serverarbete kan ske parallellt. F11 tar fram enhetsmätningar inför faktiska optimeringar.
3. **Etapp C, välj utifrån utfall:** F07:s fortsatta pilot, F08–F10 och F12:s validator. Gå vidare med parserombyggnad eller F13 endast när kontraktstester och en avgränsad design är granskade.
4. **Underhåll vid behov:** F14 och F15. Lägg inte datakonverterarens återupplivning eller ny webbkanal på den kritiska vägen utan ett behov.

Arbetsytans pågående ändringar i character-health/widget och deras två testfiler ska integreras som befintligt arbete innan närliggande UI-PR:er startas.

**Gemensamma acceptanskrav**

| Område | Minsta relevanta kontroll |
| --- | --- |
| UI | Telefon cirka 360×800, tablet 800×1280, desktop 1280×720 / 1920×1080 / 2560×1440; 1–3 kolumner där tillämpligt |
| Skalning | Relevanta min-/maxinställningar, 100/150/200 procent systemtext för operativ UI, långa översättningar |
| Interaktion | Mus, touch, tangentbord, fokus efter omordning och dialogstängning; skärmläsare för F05 |
| Spellogik | GH/FH, boss/allierade, summons, länkade anteckningar, undo/redo och ny gren efter undo |
| Nätverk | Host + två klienter, burst, stale index, mismatch, reconnect och rollbyte |
| Sparning | Äldre fixtures, ogiltig input, kastade skrivfel/false, senaste väntande värde och återhämtning |
| Prestanda | Samma scenario/enhet före och efter, separerad mätning och redovisad mätosäkerhet |

Varje PR behöver bara den del av matrisen som berör ändringen. Kör inte hela plattformsmatrisen för en ren codec- eller dokumentationsändring.

**Beslut som planen lämnar till granskningen**

Det första beslutet är om etapp A är rätt start. Därefter behövs prioritet mellan standalone-hosting och UI, en representativ Android-enhet för mätning samt avsikten med Pages och datakonverteraren. Dessa val hindrar inte granskning av de konkreta felen ovan.

Inga produktförbättringar, protokolländringar eller publiceringar har genomförts. Planen och testloggarna är leveransen för detta steg.
