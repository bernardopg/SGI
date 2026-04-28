# SGI Workspace

Workspace de integração para evoluir o Steam Game Idler com suporte Linux sem quebrar o fluxo Windows.

## Estrutura remota

```text
SGI/
├── steam-game-idler/
└── steam-utility-multiplataform/
```

Os dois projetos filhos são mantidos como submodules Git:

- `steam-game-idler` -> `https://github.com/bernardopg/steam-game-idler.git`
- `steam-utility-multiplataform` -> `https://github.com/bernardopg/steam-utility-multiplataform.git`

## Como clonar

```bash
git clone --recurse-submodules <repo-sgi>
cd SGI
```

Se o clone já existir:

```bash
git submodule update --init --recursive
```

## Rodando no Linux

O fluxo local usa o binário do `steam-utility-multiplataform` via `SGI_STEAM_UTILITY_PATH`.

```bash
cd /home/bitter/git-clones/SGI
./steam-game-idler/scripts/dev-linux.sh
```

O script:

- valida o binário `SteamUtility.Cli`;
- encerra helpers `SteamUtility.Cli idle` órfãos;
- limpa cache temporário de idlers;
- limpa `.next/dev`;
- sobe `tauri dev`.

## Estado atual

### Concluído

- Backend Tauri compila no Linux.
- `SteamUtility.Cli` multiplataforma é resolvido por plataforma/env var.
- Farm de cartas no Linux usa diretórios temporários isolados por AppID, evitando alterações em `src-tauri/steam_appid.txt`.
- Farm de cartas no Linux limita sessões Steam API simultâneas para reduzir pressão no IPC da Steam.
- `next dev` roda com Webpack no app Tauri para evitar instabilidade do WebKit com Turbopack/HMR.
- Menu de contexto customizado e notificações nativas ficam desativados em caminhos problemáticos de dev/Linux.
- `/health` existe para readiness checks.

### Validações recentes

```bash
cd steam-game-idler
pnpm typecheck
pnpm build
cd src-tauri
cargo check
```

Também foi validado manualmente que o farm de cartas roda por período prolongado no Linux sem o crash inicial observado.

## Repositórios

- `steam-game-idler`: app Tauri/Next principal.
- `steam-utility-multiplataform`: utilitário .NET responsável pela integração Steamworks multiplataforma.

## AUR

O pacote AUR é publicado como `steam-game-idler-git`.

Arquivos de distribuição:

- `packaging/aur/PKGBUILD`
- `packaging/aur/.SRCINFO`
- `.github/workflows/publish-aur.yml`

O PKGBUILD usa o repo `SGI` na branch `master`, inicializa os submodules, compila o `SteamUtility.Cli`, gera o bundle `.deb` pelo Tauri e instala o conteúdo extraído no pacote Arch.

Publicação local:

```bash
AUR_PACKAGE=steam-game-idler-git ./scripts/publish-aur.sh
```

Publicação pelo GitHub Actions requer o secret `AUR_SSH_PRIVATE_KEY`.

## Princípios

1. Preservar Windows.
2. Habilitar Linux incrementalmente.
3. Manter a integração entre app e utilitário explícita e testável.
4. Evitar dependência de estado gerado dentro de diretórios observados pelo `tauri dev`.
