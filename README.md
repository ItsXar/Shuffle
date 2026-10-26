# Shuffle

Gra Roblox typu „roll”: klikasz **ROLL**, u góry ekranu losują się **3 karty**, a system sam wybiera
najlepszą i ją zachowuje. Każda rzadkość ma swój pokaz: od małego błysku po zaciemnienie ekranu,
wybuch iskier, promienie, trzęsienie kamery i wielki napis.

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
3. **ROLL** (albo klawisz `R`) losuje, **AUTO** (`T`) losuje w kółko.

```bash
./scripts/check.sh       # format + lint + typy + zasady architektury + build — to samo, co CI
```

## Strojenie gry (bez dotykania logiki)

| Co | Gdzie |
|---|---|
| Rzadkości, szanse „1 in N”, kolory, siła efektów | `src/ReplicatedStorage/Shared/Config/Rarities.luau` |
| Karty (nazwa, rzadkość, ikona) | `src/ReplicatedStorage/Shared/Config/Cards.luau` |
| Kart na losowanie, lucky roll, cooldown | `src/ReplicatedStorage/Shared/Config/Roll.luau` |
| Kolory UI, rozmiary, czcionki | `src/ReplicatedStorage/Shared/Config/Theme.luau` |
| Dźwięki | `src/ReplicatedStorage/Shared/Config/Sounds.luau` |
| Klawisze | `src/ReplicatedStorage/Shared/Config/Input.luau` |

Postęp (liczba rolli, najlepsza karta) trwa na razie tylko do wyjścia z serwera — zapisu jeszcze nie ma.
