// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get menuSetScenario => 'Ustaw scenariusz';

  @override
  String get menuAddCharacter => 'Dodaj postać';

  @override
  String get menuRemoveCharacters => 'Usuń postacie';

  @override
  String get menuSetLevel => 'Ustaw poziom';

  @override
  String get menuLootDeck => 'Menu talii łupów';

  @override
  String get menuAddMonsters => 'Dodaj potwory';

  @override
  String get menuRemoveMonsters => 'Usuń potwory';

  @override
  String get menuShowAllyDeck => 'Pokaż talię modyfikatorów sojusznika';

  @override
  String get menuHideAllyDeck => 'Ukryj talię modyfikatorów sojusznika';

  @override
  String get menuSettings => 'Ustawienia';

  @override
  String get menuDocumentation => 'Dokumentacja';

  @override
  String get menuDonate => 'Przekaż darowiznę';

  @override
  String get menuExit => 'Wyjdź';

  @override
  String get menuAddSection => 'Dodaj sekcję';

  @override
  String get menuAddRandomDungeonCard => 'Dodaj losową kartę lochu';

  @override
  String get menuActionLog => 'Pokaż dziennik akcji';

  @override
  String get topBarOpenMainMenu => 'Open main menu';

  @override
  String get topBarMoreActions => 'More actions';

  @override
  String get elementFire => 'Fire';

  @override
  String get elementIce => 'Ice';

  @override
  String get elementAir => 'Air';

  @override
  String get elementEarth => 'Earth';

  @override
  String get elementLight => 'Light';

  @override
  String get elementDark => 'Dark';

  @override
  String get actionLogTitle => 'Action History';

  @override
  String get actionLogEmpty => 'Brak akcji';

  @override
  String get actionLogRollbackHint => 'Dotknij akcji, aby do niej wrócić';

  @override
  String get actionLogRollbackTitle => 'Cofnąć?';

  @override
  String actionLogRollbackBody(String action, int count) {
    return 'Cofnąć do \"$action\"? Odwróci to $count późniejszych akcji. Możesz je ponowić, dopóki nie wprowadzisz zmiany.';
  }

  @override
  String get actionLogRollbackConfirm => 'Cofnij';

  @override
  String get menuAddNoteRow => 'Dodaj wiersz notatki';

  @override
  String get noteRowTitle => 'Notatka';

  @override
  String get noteRowHint => 'Treść notatki…';

  @override
  String get noteRowColourLabel => 'Kolor';

  @override
  String get noteRowConnectLabel => 'Połącz z:';

  @override
  String get noteRowConnectNone => 'Nic (wolna notatka)';

  @override
  String get noteRowConnectPlayer => 'Gracz';

  @override
  String get noteRowConnectMonster => 'Potwór';

  @override
  String get noteRowWholeGroup => 'Cała grupa';

  @override
  String get noteRowAll => 'Wszystkie';

  @override
  String noteRowStandeeNr(int nr) {
    return 'Figurka $nr';
  }

  @override
  String get noteRowAddFromMenu => 'Dodaj notatkę';

  @override
  String get noteRowDelete => 'Usuń notatkę';

  @override
  String get undo => 'Cofnij';

  @override
  String undoWithDescription(String description) {
    return 'Cofnij: $description';
  }

  @override
  String get redo => 'Ponów';

  @override
  String redoWithDescription(String description) {
    return 'Ponów: $description';
  }

  @override
  String versionLabel(String version) {
    return 'Wersja $version';
  }

  @override
  String get connectedAsClient => 'Połączono jako klient';

  @override
  String get connecting => 'Łączenie…';

  @override
  String get cancelConnect => 'Cancel';

  @override
  String get connectionCancelled => 'Connection cancelled';

  @override
  String connectAsClientWithIp(String ip) {
    return 'Połącz jako klient ($ip)';
  }

  @override
  String get connectAsClientLabel => 'Połącz jako klient';

  @override
  String stopServerWithIp(String ip) {
    return 'Zatrzymaj serwer $ip';
  }

  @override
  String startHostServerWithIp(String ip) {
    return 'Uruchom serwer $ip';
  }

  @override
  String get stopServerButton => 'Zatrzymaj serwer';

  @override
  String get startHostServerButton => 'Uruchom serwer hosta';

  @override
  String get networkConnectLocal =>
      'Połącz urządzenia przez lokalną sieć Wi-Fi:';

  @override
  String get networkServerIpHint => 'adres IP serwera';

  @override
  String get networkPortHint => 'port';

  @override
  String get settingsLanguage => 'Język:';

  @override
  String get settingsCategoryDisplay => 'Display';

  @override
  String get settingsCategoryGameplay => 'Gameplay';

  @override
  String get settingsCategoryContent => 'Content';

  @override
  String get settingsCategoryNetwork => 'Network';

  @override
  String get settingsCategoryAdvanced => 'Advanced';

  @override
  String get settingsDarkMode => 'Tryb ciemny';

  @override
  String get settingsSoftNumpad => 'Programowa klawiatura numeryczna';

  @override
  String get settingsNoInit => 'Nie pytaj o inicjatywę';

  @override
  String get settingsExpireConditions => 'Wygasanie stanów';

  @override
  String get settingsNoStandees => 'Nie śledź pionków';

  @override
  String get settingsAutoAddStandees => 'Automatycznie dodawaj pionki';

  @override
  String get settingsAutoAddSpawns => 'Automatycznie dodawaj przywoływanych';

  @override
  String get settingsRandomStandees => 'Losowe pionki';

  @override
  String get settingsNoCalculations => 'Bez obliczeń';

  @override
  String get settingsHideLootDeck => 'Ukryj talię łupów';

  @override
  String get settingsShimmer => 'Migotanie tekstu na kartach statystyk';

  @override
  String get settingsPowerModeLabel => 'Power saving';

  @override
  String get powerModeNormal => 'Normal';

  @override
  String get powerModeDimWhenIdle => 'Dim when idle';

  @override
  String get settingsPowerModeInfoTitle => 'Power saving';

  @override
  String get settingsPowerModeInfo =>
      'Three levels of battery saving, from none to most.\n\nNormal — the screen is held awake at full brightness for as long as the app is open. Nothing is dimmed and nothing sleeps. Best while you are actively playing.\n\nDim when idle — the screen is still held awake and the app never locks, but after 30 seconds without input the board dims. The board stays readable from across the table, and a single tap brings it straight back with nothing lost. Good for a game in progress that you glance at between turns.\n\nReduce power use — hands the screen back to your device, so it dims and turns off on its own schedule and you unlock to return. Also lowers drawing quality to save more: card and monster box shadows become hard-edged instead of softly blurred, icons are filtered more cheaply, and shimmering text effects are turned off. Best for infrequent use and low battery capacity devices.\n\nNothing about how the game works changes at any level — no tracking, syncing or rules behaviour is affected.';

  @override
  String get settingsReducePower => 'Reduce power use';

  @override
  String get settingsReducePowerInfoTitle => 'Reduce power use';

  @override
  String get settingsReducePowerInfo =>
      'Saves battery by doing less drawing work, at the cost of some visual polish.\n\nWhat changes:\n\n• The screen is allowed to dim and turn off on its own. Normally this app keeps it awake the whole time it is open, which is by far the biggest drain on a phone or tablet.\n\n• Card and monster box shadows become hard-edged instead of softly blurred.\n\n• Icons are filtered more cheaply. You may notice slightly rougher edges on small images.\n\n• Shimmering text effects are turned off.\n\nNothing about how the game works changes — no tracking, syncing or rules behaviour is affected. You can turn this off again at any time.';

  @override
  String get settingsFhHazTerrainCalc =>
      'Obliczenia niebezp. terenu z Frosthaven w orig. Gloomhaven';

  @override
  String get settingsAllyDeckOGGloom =>
      'Talia modyfikatorów sojusznika w orig. Gloomhaven';

  @override
  String get settingsShowScenarioNames => 'Pokaż nazwy scenariuszy';

  @override
  String get settingsShowBattleGoalReminder =>
      'Pokaż przypomnienie o celu bitewnym';

  @override
  String get settingsShowCustomContent => 'Pokaż zawartość niestandardową';

  @override
  String get settingsShowSections => 'Pokaż sekcje na głównym ekranie';

  @override
  String get settingsShowReminders => 'Pokaż przypomnienia specjalnych zasad';

  @override
  String get settingsShowAmdDeck => 'Pokaż talie modyfikatorów ataku';

  @override
  String get settingsShowCharacterAmd => 'Pokaż talie modyfikatorów postaci';

  @override
  String get settingsHealthWheel =>
      'Koło życia: przeciągnij lewo-prawo by zmienić';

  @override
  String get settingsFullscreen => 'Pełny ekran';

  @override
  String get settingsFitMainListWidth =>
      'Dopasuj listę główną do szerokości ekranu';

  @override
  String get settingsMainListColumns => 'Kolumny listy głównej:';

  @override
  String get settingsMainListColumnsAuto => 'Automatycznie';

  @override
  String get settingsLayoutScalePreset => 'Scale preset:';

  @override
  String get settingsScalePresetCompact => 'Compact';

  @override
  String get settingsScalePresetDefault => 'Default';

  @override
  String get settingsScalePresetLarge => 'Large';

  @override
  String get settingsMainListScaling => 'Skalowanie listy głównej:';

  @override
  String get settingsAppBarScaling => 'Skalowanie paska aplikacji:';

  @override
  String get settingsMenuScaling => 'Menu Scaling:';

  @override
  String get settingsStyleLabel => 'Styl:';

  @override
  String get styleFrosthaven => 'Frosthaven';

  @override
  String get styleOriginal => 'Oryginalny';

  @override
  String get settingsClearUnlocked =>
      'Wyczyść odblokowane postacie i zawartość';

  @override
  String get settingsUnlockSpecials => 'Odblokuj specjalne';

  @override
  String get settingsLoadSaveState => 'Wczytaj/Zapisz stan';

  @override
  String get noResultsFound => 'Brak wyników';

  @override
  String get close => 'Zamknij';

  @override
  String get retry => 'PONÓW';

  @override
  String get specialUnlocks => 'Specjalne odblokowania';

  @override
  String get loadSaveDeleteCharacters => 'Wczytaj, zapisz lub usuń postacie.';

  @override
  String get loadAddDeleteSaves => 'Wczytaj, dodaj lub usuń zapisane stany.';

  @override
  String get addNewSave => 'Nowy zapis';

  @override
  String get addNewSaveLabel => 'Nowy zapis:';

  @override
  String get loadButton => 'Wczytaj';

  @override
  String get saveButton => 'Zapisz';

  @override
  String get deleteButton => 'Usuń';

  @override
  String get setSaveName => 'Nazwa zapisu:';

  @override
  String get loadOrSaveCharacters => 'Wczytaj lub zapisz postacie';

  @override
  String get loadCharacter => 'Wczytaj postać:';

  @override
  String get removeAll => 'Usuń wszystko';

  @override
  String get removeCardQuestion => 'Usunąć kartę?';

  @override
  String get sendToBottom => 'Wyślij na dół';

  @override
  String get shuffleUndrawnCards => 'Przetasuj niedobrane karty';

  @override
  String get returnToDiscardPile => 'Zwróć na stos odrzuconych';

  @override
  String get returnToDrawPile => 'Zwróć do talii';

  @override
  String get addExtraLootCard => 'Dodaj dodatkową kartę łupów';

  @override
  String get addStandeeNr => 'Dodaj pionek nr';

  @override
  String get summonedLabel => 'Przywołani:';

  @override
  String get characterDecks => 'Talie postaci';

  @override
  String get shuffleAndDraw => 'Tasuj\ni dobierz';

  @override
  String get draw => 'Dobierz';

  @override
  String get nextRound => ' Następna\nrunda';

  @override
  String get returnTopCard => 'Zwróć górną kartę';

  @override
  String removeCardWithDetails(String title, int nr) {
    return 'Usuń $title\n(karta nr: $nr)';
  }

  @override
  String get tapCardToAddToDeck => 'Dotknij kartę, aby dodać do talii';

  @override
  String get removeCardFromDeckQuestion => 'Usunąć kartę z talii?';

  @override
  String get changeName => 'Zmień nazwę:';

  @override
  String get characterNamePlaceholder => 'Imię';

  @override
  String get showBosses => 'Pokaż bossów';

  @override
  String get showScenarioSpecialMonsters =>
      'Pokaż specjalne potwory scenariusza';

  @override
  String get addAsAlly => 'Dodaj jako sojusznika';

  @override
  String get addMonsterLabel => 'Dodaj potwora';

  @override
  String get allCampaigns => 'Wszystkie kampanie';

  @override
  String get showMonstersFrom => '      Pokaż potwory z:   ';

  @override
  String setMonsterLevel(String name) {
    return 'Poziom $name';
  }

  @override
  String setSummonHealth(String name) {
    return 'Maks. życie $name';
  }

  @override
  String get setScenarioLevel => 'Poziom scenariusza';

  @override
  String enhancedLevel(String level) {
    return 'Ulepszone: $level';
  }

  @override
  String get soloLabel => 'Solo:';

  @override
  String get automaticScenarioLevel => 'Automatyczny poziom scenariusza:';

  @override
  String get difficultyLabel => 'Trudność:';

  @override
  String get lootCardEnhancements => 'Ulepszenia kart łupów';

  @override
  String get addPerks => 'Dodaj atuty';

  @override
  String get useFrosthavenPerks => 'Atuty Frosthaven';

  @override
  String currentCampaign(String campaign) {
    return 'Aktualna kampania: $campaign';
  }

  @override
  String get addCharacterHint => 'Dodaj postać (wpisz nazwę dla ukrytych klas)';

  @override
  String get trapDamage => 'obrażenia od pułapki';

  @override
  String get hazardousTerrainDamage => 'obrażenia od niebezpiecznego terenu';

  @override
  String get experienceAdded => 'dodane doświadczenie';

  @override
  String get goldCoinValue => 'wartość złotej monety';

  @override
  String get levelLegendLabel => 'poziom';

  @override
  String get saveStateNote =>
      'Aplikacja zapisuje postępy po każdej akcji. Te zapisy służą jako kopie zapasowe lub dla wielu kampanii.';

  @override
  String clientConnectedTo(String address) {
    return 'Klient połączony z: $address';
  }

  @override
  String clientError(String error) {
    return 'Błąd klienta: $error';
  }

  @override
  String clientListenError(String error) {
    return 'Błąd nasłuchiwania klienta: $error';
  }

  @override
  String get lostConnectionToServer => 'Utracono połączenie z serwerem';

  @override
  String get stateMismatch => 'Twój stan był nieaktualny, spróbuj ponownie.';

  @override
  String get serverUnresponsive => 'Serwer nie odpowiada. Klient rozłączony.';

  @override
  String get clientDisconnected => 'klient rozłączony';

  @override
  String get serverOffline => 'Serwer offline';

  @override
  String get clientLeft => 'Klient wyszedł.';

  @override
  String get clientTooOld =>
      'Stary klient próbował się połączyć. Zaktualizuj aplikację.';

  @override
  String networkConnection(String status) {
    return 'Połączenie sieciowe: $status';
  }

  @override
  String get failedToGetWifiIp => 'Nie udało się uzyskać adresu IP';

  @override
  String get badOmen => 'Zły omen';

  @override
  String badOmensLeft(int count) {
    return 'Pozostałe złe omeny: $count';
  }

  @override
  String get corrosiveSpew => 'Żrący wyrzut';

  @override
  String get empowersOnTop => 'Wzmocnienia na górze';

  @override
  String addMinusOneCard(String direction, int count) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'added': 'Dodaj kartę -1 (dodane: $count)',
      'removed': 'Dodaj kartę -1 (usunięte: $count)',
      'other': 'Karta -1 ($count)',
    });
    return '$_temp0';
  }

  @override
  String get removeMinusOneCard => 'Usuń kartę -1';

  @override
  String get removeMinusTwoCard => 'Usuń kartę -2';

  @override
  String get minusTwoCardRemoved => 'Karta -2 usunięta';

  @override
  String get removePlusZeroCard => 'Usuń kartę +0';

  @override
  String get plusZeroCardRemoved => 'Karta +0 usunięta';

  @override
  String get removeImbue => 'Usuń nasycenie';

  @override
  String get imbue => 'Nasyć';

  @override
  String get advancedImbue => 'Zaawansowane nasycenie';

  @override
  String get removeHailPerk => 'Usuń atut Grad';

  @override
  String get addHailPerk => 'Dodaj atut Grad';

  @override
  String get removeCassandraPerk => 'Usuń\natut Cassandry';

  @override
  String get addCassandraPerk => 'Dodaj\natut Cassandry';

  @override
  String get dontSaveRevealedCards => 'Nie zachowuj\nodsłoniętych kart';

  @override
  String get saveRevealedCards => 'Zachowaj\nodsłonięte karty';

  @override
  String removedCountLabel(int count) {
    return 'Usunięte: $count';
  }

  @override
  String get removeDonation => 'Usuń\ndarowiznę';

  @override
  String get donateSanctuary => 'Przekaż do\nsanktuarium';

  @override
  String get removePartyCard => 'Usuń\nkartę grupy:';

  @override
  String get addPartyCard => 'Dodaj\nkartę grupy:';

  @override
  String get perks => 'Atuty';

  @override
  String get revealCards => 'Odsłoń\nkarty:';

  @override
  String get revealAll => 'Wszystkie';

  @override
  String get drawExtraCard => 'Dobierz dodatkową kartę';

  @override
  String get extraShuffle => 'Dodatkowe tasowanie';

  @override
  String get inactivateMonster => 'Dezaktywuj\npotwora';

  @override
  String get activateMonster => 'Aktywuj\npotwora';

  @override
  String addEliteStandees(int count, String name) {
    return 'Dodaj $count elitarnych $name';
  }

  @override
  String addNormalStandees(int count, String name) {
    return 'Dodaj $count zwykłych $name';
  }

  @override
  String get characterLoot => 'Łup postaci';

  @override
  String addSpecialCard(int nr) {
    return 'Dodaj kartę $nr';
  }

  @override
  String removeSpecialCard(int nr) {
    return 'Usuń kartę $nr';
  }

  @override
  String get enhanceCards => 'Ulepsz karty';

  @override
  String get addLootCard => 'Dodaj kartę';

  @override
  String get returnToTop => 'Wróć na górę';

  @override
  String get returnToBottom => 'Wróć na dół';

  @override
  String characterLootTitle(String name) {
    return 'Łup $name:';
  }

  @override
  String get setLootOwner => 'Właściciel łupu:';

  @override
  String get lootNameCoin => 'moneta';

  @override
  String get lootNameHide => 'skóra';

  @override
  String get lootNameLumber => 'drewno';

  @override
  String get lootNameMetal => 'metal';

  @override
  String get lootNameArrowvine => 'strzałowiec';

  @override
  String get lootNameAxenut => 'siekierorzech';

  @override
  String get lootNameCorpsecap => 'trupielnik';

  @override
  String get lootNameFlamefruit => 'ognioowoc';

  @override
  String get lootNameRockroot => 'skalniak';

  @override
  String get lootNameSnowthistle => 'śnieżny oset';

  @override
  String get lootAmount2For2 => '2 dla 2 graczy';

  @override
  String get lootAmount2For23 => '2 dla 2-3 graczy';

  @override
  String cmdActivateMonster(String name) {
    return 'Aktywuj $name';
  }

  @override
  String cmdDeactivateMonster(String name) {
    return 'Dezaktywuj $name';
  }

  @override
  String cmdAddCharacter(String id) {
    return 'Dodaj $id';
  }

  @override
  String cmdAddCondition(String condition) {
    return 'Dodaj stan: $condition';
  }

  @override
  String cmdRemoveCondition(String condition) {
    return 'Usuń stan: $condition';
  }

  @override
  String cmdAddPartyCard(String character, String type) {
    return '$character dodaj kartę grupy $type';
  }

  @override
  String cmdRemovePartyCard(String character) {
    return '$character usuń kartę grupy';
  }

  @override
  String cmdAddFactionCard(String character) {
    return '$character dodaj kartę frakcji';
  }

  @override
  String cmdRemoveFactionCard(String character) {
    return '$character usuń kartę frakcji';
  }

  @override
  String cmdAddLootCard(String type) {
    return 'Dodaj kartę łupów $type';
  }

  @override
  String cmdAddMonster(String name) {
    return 'Dodaj $name';
  }

  @override
  String cmdAddSpecialLootCard(int nr) {
    return 'Dodaj specjalną kartę łupów $nr';
  }

  @override
  String cmdRemoveSpecialLootCard(int nr) {
    return 'Usuń specjalną kartę łupów $nr';
  }

  @override
  String get cmdAddMinusOne => 'Dodaj minus jeden';

  @override
  String get cmdRemoveMinusOne => 'Usuń minus jeden';

  @override
  String get cmdRemoveMinusTwo => 'Usuń minus dwa';

  @override
  String get cmdAddBackMinusTwo => 'Przywróć minus dwa';

  @override
  String get cmdRemovePlusZero => 'Usuń plus zero';

  @override
  String get cmdAddBackPlusZero => 'Przywróć plus zero';

  @override
  String cmdRevealModifierCards(int count) {
    return 'Odsłoń $count kart modyfikatorów';
  }

  @override
  String cmdCassandraLeaveRevealed(String deck) {
    return 'Zostaw odsłonięte karty na talii $deck';
  }

  @override
  String cmdCassandraSpecialOff(String deck) {
    return 'Specjał Cassandry wyłączony dla talii $deck';
  }

  @override
  String get cmdImbueMonsterDeck => 'Nasyć talię potworów';

  @override
  String get cmdAdvancedImbueMonsterDeck =>
      'Zaawansowane nasycenie talii potworów';

  @override
  String get cmdRemoveImbueMonsterDeck => 'Usuń nasycenie';

  @override
  String get cmdChangeName => 'Zmień nazwę postaci';

  @override
  String get cmdAddNoteRow => 'Dodaj wiersz notatki';

  @override
  String get cmdSetNoteRowText => 'Edytuj notatkę';

  @override
  String get cmdSetNoteRowColor => 'Zmień kolor notatki';

  @override
  String get cmdLinkNoteRow => 'Połącz wiersz notatki';

  @override
  String get cmdRemoveNoteRow => 'Usuń wiersz notatki';

  @override
  String get cmdAddBless => 'Dodaj błogosławieństwo';

  @override
  String get cmdRemoveBless => 'Usuń błogosławieństwo';

  @override
  String get cmdAddCurse => 'Dodaj klątwę';

  @override
  String get cmdRemoveCurse => 'Usuń klątwę';

  @override
  String get cmdAddEmpower => 'Dodaj wzmocnienie';

  @override
  String get cmdRemoveEmpower => 'Usuń wzmocnienie';

  @override
  String get cmdAddEnfeeble => 'Dodaj osłabienie';

  @override
  String get cmdRemoveEnfeeble => 'Usuń osłabienie';

  @override
  String cmdIncreaseMaxHealth(String owner) {
    return 'Zwiększ maks. życie $owner';
  }

  @override
  String cmdDecreaseMaxHealth(String owner) {
    return 'Zmniejsz maks. życie $owner';
  }

  @override
  String get cmdChangeStat => 'Zmień statystykę';

  @override
  String cmdIncreaseXp(String figure, int amount) {
    return 'Zwiększ PD $figure o $amount';
  }

  @override
  String cmdDecreaseXp(String figure, int amount) {
    return 'Zmniejsz PD $figure o $amount';
  }

  @override
  String get cmdClearUnlockedClasses => 'Wyczyść odblokowane klasy';

  @override
  String cmdDonateSanctuary(String character) {
    return '$character przekazuje do sanktuarium';
  }

  @override
  String cmdRemoveSanctuaryDonation(String character) {
    return 'Usuń darowiznę $character';
  }

  @override
  String get cmdDrawExtraAbilityCard => 'Dobierz dodatkową kartę zdolności';

  @override
  String get cmdDraw => 'Dobierz';

  @override
  String get cmdDrawLootCard => 'Dobierz kartę łupów';

  @override
  String cmdDrawModifierCard(String name) {
    return 'Dobierz kartę modyfikatora $name';
  }

  @override
  String get cmdRemoveLootEnhancement => 'Usuń ulepszenie łupów';

  @override
  String get cmdAddLootEnhancement => 'Dodaj ulepszenie łupów';

  @override
  String get cmdHideAllyDeck => 'Ukryj talię sojusznika';

  @override
  String get cmdShowAllyDeck => 'Pokaż talię sojusznika';

  @override
  String get cmdIceWraithTurnNormal => 'Lodowy zjaw staje się zwykły';

  @override
  String get cmdIceWraithTurnElite => 'Lodowy zjaw staje się elitarny';

  @override
  String cmdImbueElement(String element) {
    return 'Nasyć żywioł $element';
  }

  @override
  String cmdUseElement(String element) {
    return 'Użyj żywiołu $element';
  }

  @override
  String cmdLoadCharacter(String name) {
    return 'Wczytaj zapisaną postać: $name';
  }

  @override
  String cmdLoadGame(String name) {
    return 'Wczytaj zapisaną grę: $name';
  }

  @override
  String get cmdNextRound => 'Następna runda';

  @override
  String get cmdRemoveAmdCard => 'Usuń kartę AMD';

  @override
  String cmdRemoveCard(String deck, int nr) {
    return 'Usuń kartę $deck nr $nr';
  }

  @override
  String get cmdRemoveAllCharacters => 'Usuń wszystkie postacie';

  @override
  String cmdRemoveCharacter(String id) {
    return 'Usuń $id';
  }

  @override
  String get cmdRemoveAllMonsters => 'Usuń wszystkie potwory';

  @override
  String cmdRemoveMonster(String name) {
    return 'Usuń $name';
  }

  @override
  String get cmdReorderAbilityCards => 'Zmień kolejność kart zdolności';

  @override
  String get cmdReorderList => 'Zmień kolejność listy';

  @override
  String get cmdReorderModifierCards => 'Zmień kolejność kart modyfikatorów';

  @override
  String get cmdReturnLootCard => 'Zwróć kartę łupów';

  @override
  String get cmdReturnModifierCard => 'Zwróć kartę modyfikatora na górę';

  @override
  String get cmdReturnRemovedAmdCard => 'Zwróć usuniętą kartę AMD';

  @override
  String get cmdNoAllyDeckInOgGloom =>
      'Brak talii sojusznika w orig. Gloomhaven';

  @override
  String get cmdUseAllyDeckInOgGloom =>
      'Użyj talii sojusznika w orig. Gloomhaven';

  @override
  String cmdMarkAsSummon(String owner) {
    return 'Oznacz $owner jako przywołanego';
  }

  @override
  String cmdRemoveSummonMark(String owner) {
    return 'Usuń oznaczenie przywołania $owner';
  }

  @override
  String get cmdAutoLevelOn => 'Włącz automatyczną aktualizację poziomu';

  @override
  String get cmdAutoLevelOff => 'Wyłącz automatyczną aktualizację poziomu';

  @override
  String cmdSetCampaign(String campaign) {
    return 'Ustaw kampanię $campaign';
  }

  @override
  String cmdSetCharacterLevel(String character) {
    return 'Ustaw poziom $character';
  }

  @override
  String cmdSetDifficulty(String difficulty) {
    return 'Ustaw trudność na $difficulty';
  }

  @override
  String cmdSetInitiative(String character) {
    return 'Ustaw inicjatywę $character';
  }

  @override
  String cmdSetCharacterNote(String character) {
    return 'Ustaw notatkę dla $character';
  }

  @override
  String get characterNoteTitle => 'Notatka';

  @override
  String get characterNoteHint => 'Dodaj notatkę…';

  @override
  String get characterNoteQuickAdd => 'Szybka notatka';

  @override
  String cmdSetMonsterLevel(String monster) {
    return 'Ustaw poziom $monster';
  }

  @override
  String get cmdSetLootOwner => 'Ustaw właściciela łupu';

  @override
  String get cmdSetScenario => 'Ustaw scenariusz';

  @override
  String get cmdSetSoloOn => 'Włącz rekomendację poziomu solo';

  @override
  String get cmdSetSoloOff => 'Wyłącz rekomendację poziomu solo';

  @override
  String get cmdExtraAbilityShuffle => 'Dodatkowe tasowanie talii zdolności';

  @override
  String get cmdExtraAmdShuffle => 'Dodatkowe tasowanie talii AMD';

  @override
  String get cmdDrawnAbilityShuffle => 'Tasowanie dobranej talii zdolności';

  @override
  String get cmdDontTrackStandees => 'Nie śledź pionków';

  @override
  String get cmdTrackStandees => 'Śledź pionki';

  @override
  String cmdTurnDone(String id) {
    return 'Tura $id zakończona';
  }

  @override
  String cmdAddPerk(String character, int index) {
    return 'Dodaj atut $index postaci \'$character\'';
  }

  @override
  String cmdRemovePerk(String character, int index) {
    return 'Usuń atut $index postaci \'$character\'';
  }

  @override
  String cmdUnlock(String id) {
    return 'Odblokuj $id';
  }

  @override
  String cmdLock(String id) {
    return 'Zablokuj $id';
  }

  @override
  String get cmdSetLevel => 'Ustaw poziom';

  @override
  String get cmdAddSection => 'Dodaj sekcję';

  @override
  String cmdAddStandee(String name, int nr) {
    return 'Dodaj $name $nr';
  }

  @override
  String get cmdDrawMonsterModifierCard => 'Dobierz kartę modyfikatora potwora';

  @override
  String cmdIncreaseHealth(String figure, int amount) {
    return 'Zwiększ życie $figure o $amount';
  }

  @override
  String cmdKill(String owner) {
    return 'Zabij $owner';
  }

  @override
  String cmdDecreaseHealth(String owner, int amount) {
    return 'Zmniejsz życie $owner o $amount';
  }

  @override
  String cmdUseFhPerks(String character) {
    return '$character używa atutów Frosthaven';
  }

  @override
  String cmdDontUseFhPerks(String character) {
    return '$character nie używa atutów Frosthaven';
  }

  @override
  String get cmdRemoveNoCharacters => 'Nie usunięto postaci';

  @override
  String get cmdRemoveNoMonsters => 'Nie usunięto potworów';
}
