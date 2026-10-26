# Shuffle

Gra Roblox typu „roll”: klikasz **ROLL**, u góry ekranu losują się **3 karty**, a system sam wybiera
najlepszą i ją zachowuje. Każda rzadkość ma swój pokaz: od małego błysku po zaciemnienie ekranu,
fale uderzeniowe, wybuch iskier, promienie, świecące krawędzie ekranu, trzęsienie kamery i napis.

Kod jest zarządzany przez [Rojo](https://rojo.space): edytujesz pliki w `src/`, a Rojo na bieżąco
synchronizuje je do Roblox Studio.

| Dokument | Po co |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Jak gra jest zbudowana, kto za co odpowiada, zasady pisania kodu |

## Jednorazowa konfiguracja

1. Zainstaluj [Rokit](https://github.com/rojo-rbx/rokit), potem w folderze repo:
   ```bash
   rokit install          # instaluje przypięte wersje: rojo, stylua, selene, luau-lsp
   ```
2. Zainstaluj plugin Rojo w Studio: `rojo plugin install` (wersja 7.7.x, taka jak w `rokit.toml`). Plugin Rojo z Creator Store też musi być 7.7.x.
3. VS Code: zainstaluj polecane rozszerzenia (`.vscode/extensions.json`).

## Praca

```bash
rojo serve               # start serwera Rojo (port 34872)
```

1. Otwórz w Roblox Studio pusty **Baseplate** (albo `build/Shuffle.rbxl`).
2. **Plugins → Rojo → Connect**, potem **Play**.
3. **ROLL** (albo klawisz `R`) losuje, **AUTO ROLL** (`T`) losuje w kółko, **BACKPACK** pokazuje kolekcję.

```bash
./scripts/check.sh       # format + lint + typy + zasady architektury + build — to samo, co CI
```

## Grafiki kart (jednorazowo)

Karty są obrazkami z `assets/cards/` (rewers + ramka dla każdej rzadkości). Roblox potrzebuje ich ID:

1. Studio: **View → Asset Manager → Bulk Import** i wybierz wszystkie 10 plików z `assets/cards/`.
2. W Asset Managerze (zakładka **Images**) kliknij obrazek prawym → **Copy Asset ID**.
3. Wklej ID do `src/ReplicatedStorage/Shared/Config/CardArt.luau` przy tej samej nazwie
   (`Back`, `Common`, `Uncommon`, …). Wystarczy sama liczba.

Dopóki ID są puste, gra rysuje zastępcze karty z ramek. Grafiki rysuje `tools/cardart`
(`node tools/cardart/render.mjs` przerysowuje PNG po zmianie projektu w `cards.html`).

## Strojenie gry (bez dotykania logiki)

| Co | Gdzie |
|---|---|
| Rzadkości, szanse „1 in N”, kolory, siła efektów | `src/ReplicatedStorage/Shared/Config/Rarities.luau` |
| Karty (nazwa, rzadkość, ikona) | `src/ReplicatedStorage/Shared/Config/Cards.luau` |
| ID grafik kart | `src/ReplicatedStorage/Shared/Config/CardArt.luau` |
| Kart na losowanie, lucky roll, cooldown | `src/ReplicatedStorage/Shared/Config/Roll.luau` |
| Kolory UI, rozmiary, czcionki | `src/ReplicatedStorage/Shared/Config/Theme.luau` |
| Dźwięki (na razie wyłączone, `Enabled = false`) | `src/ReplicatedStorage/Shared/Config/Sounds.luau` |
| Klawisze | `src/ReplicatedStorage/Shared/Config/Input.luau` |

Kolekcja (plecak) i liczba rolli zapisują się w DataStore. W Studio zapis działa tylko po włączeniu
*Game Settings → Security → Enable Studio Access to API Services* (miejsce musi być opublikowane);
bez tego gra działa normalnie, ale postęp znika po wyjściu.
