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
│     └─ Progress/ProgressService   rolle, posiadane karty, najlepsza rzadkość, leaderstats
│
├─ StarterPlayer/StarterPlayerScripts/Boot.client.luau    Loader
│
└─ ReplicatedStorage/
   ├─ Shared/
   │  ├─ Core/      Loader, Log, Seal
   │  ├─ Net/       init (właściciel remotów), Remotes (jedyna lista remotów)
   │  ├─ Config/    Rarities, Cards, Roll, Theme, Sounds, Input
   │  ├─ Domain/    Catalog (wyszukiwanie kart/rzadkości), Odds (zasady losowania, typ Result)
   │  └─ Util/      Scope
   └─ Client/
      ├─ Controllers/RollController     pętla: przycisk/klawisz -> serwer -> Stage -> Hud, auto-roll
      ├─ Core/Audio                     dźwięki z Config/Sounds
      └─ UI/
         ├─ Root, Fit, Make, Motion, Paint    warstwy ScreenGui, skalowanie, budowanie, tweeny, kolory
         ├─ Components/  Card/ (init, Face), Button, Chip
         ├─ Fx/          Flash, Shake, Burst, Rays, Banner
         └─ Screens/
            ├─ Stage/    init, Show, Shuffle, Pick, Celebrate      karty u góry ekranu
            └─ Hud/      init, LuckyMeter                          przyciski i statystyki na dole
```

## 4. Właściciele

| Stan | Właściciel |
|---|---|
| Remoty | `Shared/Net` |
| Losowanie i wynik rolla | `RollService` |
| Postęp gracza, leaderstats | `ProgressService` |
| Czy trwa roll, auto-roll, klawisze | `RollController` |
| Karty na ekranie i ich pokaz | `Screens/Stage` |
| Przyciski i liczniki | `Screens/Hud` |
| Warstwy ScreenGui | `UI/Root` |
| Trzęsienie kamery | `Fx/Shake` |

## 5. Przepływ jednego rolla

```
ROLL / [R]  ->  RollController.Roll
            ->  remote "Roll"  ->  RollService: cooldown, luck (co 10. roll x3), Odds.RollHand,
                                   Odds.Best, ProgressService.Collect  ->  Odds.Result
            ->  Stage:Play(result)
                   Shuffle    rozdanie, karty kręcą się jak bębny, lądują od lewej
                              (rzadka karta drży i świeci przed odsłonięciem)
                   Pick       ramka-ruletka skacze po kartach i staje na najlepszej,
                              reszta spada, zwycięzca na środek
                   Celebrate  zaciemnienie / błysk / iskry / promienie / napis — według rzadkości,
                              potem karta wlatuje do licznika „Best”
            ->  Hud:Update(result)
```

Siła każdego efektu dla każdej rzadkości: `Config/Rarities.luau` → `Fx`.
