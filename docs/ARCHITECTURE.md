# Architektura Shuffle

## 1. Zasady

1. **Jeden boot serwera, jeden boot klienta.** `Boot.server.luau` i `Boot.client.luau` tylko
   uruchamiają resztę. Wszystko inne to ModuleScripty (`scripts/guard.sh` tego pilnuje).
2. **Małe moduły.** Żaden plik nie przekracza **300 linii** (guard). Gdy moduł rośnie, staje się
   folderem: `Nazwa/init.luau` + części (np. `Screens/Stage/`, `Components/Card/`).
3. **Jeden właściciel.** Każdy stan ma jeden moduł, który go zmienia (tabela niżej). Dwa moduły
   nigdy nie robią tej samej rzeczy; wspólna logika idzie do `Shared/Domain` albo `Shared/Util`.
4. **Serwer decyduje.** Klient tylko prosi o roll i pokazuje wynik. Losowanie, szanse, wybór
   najlepszej karty i postęp są na serwerze — nie da się ich oszukać.
5. **Dane osobno od logiki.** Liczby, kolory, teksty i dźwięki są w `Shared/Config` (przez `Seal`:
   literówka w kluczu = błąd od razu, nie cichy `nil`).
6. **Zależności tylko w dół:** `Shared` nie wymaga `Client` ani serwera.
7. **Sprzątanie.** Wszystko, co tworzy jeden pokaz losowania, trafia do jego `Scope`; jedno
   `Clean()` zostawia scenę pustą, nawet gdy coś się wywali.

## 2. Cykl życia

`Shared/Core/Loader` ładuje tylko moduły o nazwie `*Service` (serwer, z `ServerScriptService/Services`)
i `*Controller` (klient, z `Client/Controllers`). Najpierw wszystkie `Init` (nie mogą czekać),
potem każde `Start` w osobnym wątku. Pozostałe moduły to biblioteki, wymagane przez właściciela.

## 3. Drzewo

```
src/
├─ ServerScriptService/
│  ├─ Boot.server.luau              Net.Setup + Loader
│  └─ Services/
│     ├─ Roll/RollService           remote "Roll": cooldown, szczęście, losowanie ręki, wybór najlepszej
│     ├─ Progress/ProgressService   rolle, kolekcja, deck, poziom, leaderstats, remoty "Inventory"
│     │                             i "SetDeck"; zapis przez Store (DataStore)
│     └─ Battle/BattleService       walka: co tick każda karta decku bije potwora; śmierć = poziom wyżej
│
├─ StarterPlayer/StarterPlayerScripts/Boot.client.luau    Loader
│
└─ ReplicatedStorage/
   ├─ Shared/
   │  ├─ Core/      Loader, Log, Seal
   │  ├─ Net/       init (właściciel remotów), Remotes (jedyna lista remotów)
   │  ├─ Config/    Rarities (+ Power), Cards, CardArt (ID obrazków kart), Battle (potwory, HP),
   │  │             Roll, Theme, Sounds, Input
   │  ├─ Domain/    Catalog (wyszukiwanie kart/rzadkości), Odds (zasady losowania, typ Result),
   │  │             Power (siła kart, HP potworów, BattleEvent), Deck (zasady decku)
   │  └─ Util/      Scope
   └─ Client/
      ├─ Controllers/RollController     pętla: przycisk/klawisz -> serwer -> Stage -> plecak, auto-roll
      ├─ Controllers/BackpackController kolekcja i deck klienta, nowe karty (licznik), okno plecaka
      ├─ Controllers/BattleController   potwór w świecie, pasek HP, strzały z kart, liczby obrażeń
      ├─ Controllers/HudController      właściciel dolnego paska (deck + przyciski)
      ├─ World/                         Monsters/ (Rig + Slime, Golem, Demon), Arena, HealthBar,
      │                                 DamageText
      ├─ Core/Audio                     dźwięki z Config/Sounds (na razie wyłączone: Sounds > Enabled)
      └─ UI/
         ├─ Root, Fit, Make, Motion, Paint    warstwy ScreenGui, skalowanie, budowanie, tweeny, kolory
         ├─ Components/  Card/ (init, Art = karty z obrazków, Front/Back = zastępcze z ramek, Kit),
         │               MiniCard (karta w liście), Button
         ├─ Fx/          Flash, Shake, Zoom, Burst, Ring, Aura, Flood, Converge, Confetti, Rays, Banner,
         │               Bolt (strzał karty w potwora)
         └─ Screens/
            ├─ Stage/    init, Show, Deal, Reels, Pick, Celebrate  karty u góry ekranu
            ├─ Hud/      init, Badge                               BACKPACK + AUTO ROLL + ROLL na dole
            ├─ DeckBar/  init                                      5 kart decku nad przyciskami
            └─ Backpack/ init, Parts, DeckRow, Collection          okno: deck + kolekcja
```

Poza `src/`: `assets/cards/` (PNG kart do wgrania), `tools/cardart/` (projekt kart w HTML/CSS +
`render.mjs`, który zapisuje PNG), `scripts/` (check.sh, guard.sh).

## 4. Właściciele

| Stan | Właściciel |
|---|---|
| Remoty | `Shared/Net` |
| Losowanie i wynik rolla | `RollService` |
| Postęp gracza (zapis), leaderstats | `ProgressService` (+ `Store`) |
| Kolekcja i deck po stronie klienta, okno plecaka | `BackpackController` |
| Walka (HP potwora, obrażenia, poziom) | `BattleService` (klient tylko odtwarza: `BattleController`) |
| Dolny pasek | `HudController` |
| Czy trwa roll, auto-roll, klawisze | `RollController` |
| Karty na ekranie i ich pokaz | `Screens/Stage` |
| Przyciski na dole | `Screens/Hud` |
| Warstwy ScreenGui | `UI/Root` |
| Trzęsienie kamery | `Fx/Shake` |

## 5. Przepływ jednego rolla

```
ROLL / [R]  ->  RollController.Roll
            ->  remote "Roll"  ->  RollService: cooldown, luck (co 10. roll x3), Odds.RollHand,
                                   Odds.Best, ProgressService.Collect  ->  Odds.Result
            ->  Stage:Play(result, przycisk ROLL)
                   Deal       3 zakryte karty wylatują z przycisku ROLL ze smugą i uderzają w miejsca
                   Reels      karty otwierają się i kręcą jak bębny (twarze wpadają, poświata miga
                              kolorem); zwykła karta prawie zatrzymuje się na lepszej (near miss);
                              Rare+ zamyka się i wspina po rzadkościach (zielony, niebieski,
                              fioletowy, złoty...) z wybuchem i nazwą przy każdym kroku;
                              odsłonięcie: biały błysk, squash, iskry, fala, gwiazdki
                   Pick       promień światła przelatuje po kartach, wygrana podskakuje, reszta
                              pęka w odłamki, wygrana obraca się na środek
                   Celebrate  (Blackout) ciemność i smugi światła wpadające w kartę; potem naraz:
                              błysk, trzęsienie, iskry, fale, promienie + drobiny, zalanie kolorem
                              + banner, konfetti — według rzadkości; karta wraca do przycisku ROLL

Siła każdego efektu dla każdej rzadkości: `Config/Rarities.luau` → `Fx`.
