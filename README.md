# Shuffle

Gra Roblox. Kod jest zarządzany przez [Rojo](https://rojo.space) — edytujesz pliki w `src/`,
a Rojo na bieżąco synchronizuje je do Roblox Studio.

## Jednorazowa konfiguracja

1. Zainstaluj [Rokit](https://github.com/rojo-rbx/rokit), potem w folderze repo:
   ```bash
   rokit install          # instaluje przypięte wersje: rojo, stylua, selene, luau-lsp
   ```
2. Zainstaluj plugin Rojo w Studio:
   ```bash
   rojo plugin install
   ```
   (albo z Creator Store: „Rojo”). Wersja pluginu musi pasować do `rojo` z `rokit.toml` (7.4.x).
3. VS Code: zainstaluj polecane rozszerzenia (`.vscode/extensions.json`) — luau-lsp, StyLua, selene, Rojo.

## Praca

```bash
rojo serve               # start serwera Rojo (port 34872)
```

1. Otwórz w Roblox Studio dowolne miejsce (np. pusty Baseplate albo `build/Shuffle.rbxl`).
2. Zakładka **Plugins → Rojo → Connect**. Od teraz kod edytujesz tylko w `src/`.
3. Jeśli gra używa DataStore / HTTP: *Game Settings → Security → Enable Studio Access to API Services*.

Zbudowanie pliku gry bez Studio:

```bash
rojo build -o build/Shuffle.rbxl
./scripts/check.sh       # format + lint + build — to samo, co CI
```

## Struktura

```
src/
  ReplicatedFirst/                         pierwsze skrypty klienta (ekran ładowania)
  ReplicatedStorage/Shared/                kod wspólny klient + serwer (Config.luau)
  ServerScriptService/Main.server.luau     start serwera
  StarterPlayer/StarterPlayerScripts/
    Main.client.luau                       start klienta
default.project.json                       mapowanie folderów na drzewo gry (Rojo)
```

Nazwy plików: `*.server.luau` = Script, `*.client.luau` = LocalScript, `*.luau` = ModuleScript,
folder z `init.luau` = ModuleScript z dziećmi.
