# Auditoria P0 - Pontos Windows-only no steam-game-idler

Data: 2026-04-23
Workspace: `/home/bitter/git-clones/SGI`
Projeto auditado: `/home/bitter/git-clones/SGI/steam-game-idler`

## Objetivo

Mapear os acoplamentos Windows-only que impedem ou fragilizam o porte do `steam-game-idler` para Linux, preservando o comportamento atual de Windows.

## Health check inicial

Comando executado:

```bash
cargo check
```

Diretório:

```bash
/home/bitter/git-clones/SGI/steam-game-idler/src-tauri
```

Resultado observado:
- o build não chegou a falhar primeiro por imports Windows-only;
- ele falhou antes no build script/configuração de empacotamento por ausência de `libs/*`;
- também apareceu aviso de ausência de `STEAM_API_KEY` / `.env.prod`.

Erro material mais importante desta fase:

```text
glob pattern libs/* path not found or didn't match any files.
```

Conclusão prática:
- antes de provar compilação Linux de ponta a ponta, o projeto precisa de uma estratégia local para disponibilizar o binário/artefatos do SteamUtility;
- mesmo assim, o código já mostra vários acoplamentos diretos com Windows que precisam ser abstraídos.

## Resumo executivo

O SGI hoje depende de Windows em 5 camadas diferentes:

1. resolução do executável do SteamUtility;
2. criação/encerramento/descoberta de processos;
3. integração com explorer/cmd/taskkill;
4. leitura de títulos de janelas via Win32 para identificar jogos em idle;
5. documentação e empacotamento assumindo `SteamUtility.exe` e fluxo Windows.

A boa notícia é que a maior parte do problema está concentrada no backend Tauri/Rust e em alguns pontos de frontend. Isso torna viável portar por camadas sem quebrar Windows.

## Inventário de pontos Windows-only

### 1. Dependências Rust e APIs Win32 acopladas globalmente

Arquivo: `src-tauri/Cargo.toml`

Trechos relevantes:
- linha 30: dependência `windows = { ... Win32_* ... }`
- linha 37: dependência `winapi = { ... }`

Risco:
- essas dependências estão declaradas sem segmentação por plataforma;
- o código atual usa APIs Win32 diretamente em módulos centrais.

Direção recomendada:
- mover dependências Windows para blocos `target.'cfg(windows)'` quando possível;
- deixar o código comum depender de traits/abstrações, não de APIs Win32 diretamente.

### 2. Resolução hardcoded do SteamUtility como `.exe`

Arquivo: `src-tauri/src/utils.rs`

Trecho relevante:
- linhas 149-155: `get_lib_path()` sempre resolve `libs/SteamUtility.exe`

Impacto:
- quebra Linux imediatamente;
- impede usar o `steam-utility-multiplataform` local sem adaptação;
- obriga o app a pensar em um único nome/formato de binário.

Direção recomendada:
- criar um resolvedor de binário por plataforma;
- ordem sugerida de fallback:
  1. variável de ambiente de dev, ex.: `SGI_STEAM_UTILITY_PATH`
  2. binário empacotado em `resources/externalBin`
  3. caminho legado Windows `libs/SteamUtility.exe`

### 3. Criação de processos com API específica de Windows

Arquivos afetados:
- `src-tauri/src/utils.rs`
- `src-tauri/src/game_data.rs`
- `src-tauri/src/achievement_manager.rs`
- `src-tauri/src/idling.rs`
- `src-tauri/src/process_handler.rs`

Padrão repetido:
- `use std::os::windows::process::CommandExt;`
- `.creation_flags(0x08000000)`

Impacto:
- acoplamento direto com Windows em praticamente toda invocação do SteamUtility;
- isso precisa ser centralizado, não repetido em cada comando.

Direção recomendada:
- criar um helper único para spawn de processos;
- nesse helper, aplicar flags ocultas apenas em Windows;
- no Linux, usar `Command` padrão sem `CommandExt`.

### 4. Descoberta de processo Steam dependente de `steam.exe`

Arquivo: `src-tauri/src/utils.rs`

Trecho relevante:
- linhas 24-31: `is_steam_running()` procura apenas `steam.exe`

Impacto:
- em Linux, o processo do Steam normalmente não terá esse nome exato;
- monitoramento de sessão Steam tende a falhar ou mentir no Linux.

Direção recomendada:
- criar lista de nomes por plataforma, por exemplo:
  - Windows: `steam.exe`
  - Linux: `steam`, `steamwebhelper` com heurísticas mais seguras
- idealmente encapsular isso em um `SteamProcessDetector` por plataforma.

### 5. Anti-away usa `cmd /C start`

Arquivo: `src-tauri/src/utils.rs`

Trecho relevante:
- linhas 116-123: `anti_away()` usa `cmd /C start steam://friends/status/online`

Impacto:
- inviável no Linux como está.

Direção recomendada:
- abstrair abertura de URI `steam://...` por plataforma;
- em Linux, provavelmente usar `xdg-open 'steam://friends/status/online'` ou equivalente validado.

### 6. Abrir arquivo/pasta usa `explorer /select,`

Arquivo: `src-tauri/src/utils.rs`

Trecho relevante:
- linhas 126-136: `open_file_explorer()` usa `explorer` com `/select,`

Impacto:
- quebra no Linux;
- UI de debug e abertura de cache/arquivos fica sem funcionar.

Direção recomendada:
- criar helper cross-platform para abrir arquivos/pastas;
- preferir usar plugin/opener do Tauri ou comando por plataforma (`explorer`, `xdg-open`, etc.).

### 7. Identificação de processos por título de janela depende de Win32

Arquivo: `src-tauri/src/process_handler.rs`

Trechos relevantes:
- linhas 3-10: `CommandExt` + `windows::Win32::*`
- linhas 12-46: `EnumWindows`, `GetWindowTextW`, `GetWindowThreadProcessId`
- linhas 48-84: `get_running_processes()` depende do título da janela para obter `[appid]`

Impacto:
- este é um dos pontos mais Windows-only do projeto;
- a lógica atual depende de janela oculta/visível do `SteamUtility.exe (idle)`;
- o modelo de identificação de processo não é portável como está.

Direção recomendada:
- separar em duas preocupações:
  1. enumeração de processos do SteamUtility;
  2. associação processo <-> app_id.
- no Linux, provavelmente a associação precisará vir do estado interno dos processos spawnados pelo próprio SGI, e não de título de janela Win32.

### 8. Encerramento de processos usa `taskkill`

Arquivos afetados:
- `src-tauri/src/process_handler.rs`
- `src-tauri/src/idling.rs`

Trechos relevantes:
- `process_handler.rs` linhas 87-166
- `idling.rs` linhas 55-77 e 146-179

Impacto:
- quebra no Linux;
- update, logout, parada de idle e limpeza de processos dependem disso.

Direção recomendada:
- criar um `ProcessController` por plataforma;
- no Linux usar `Child::kill`, `nix`, ou estratégia equivalente;
- evitar depender de parsing de `tasklist`/`taskkill` quando já houver PIDs controlados pelo próprio app.

### 9. Toda a ponte para SteamUtility repete spawn direto do executável

Arquivos afetados:
- `src-tauri/src/game_data.rs`
- `src-tauri/src/achievement_manager.rs`
- `src-tauri/src/idling.rs`

Exemplos:
- `game_data.rs` linhas 41-46: `check_ownership`
- `achievement_manager.rs` linhas 29-33, 75-78, 89-92, 103-106, 117-120, 131-134, 145-148, 159-162
- `idling.rs` linhas 26-32 e 96-100

Impacto:
- o projeto não possui uma camada de integração com o SteamUtility; só possui chamadas espalhadas;
- isso dificulta Linux e também manutenção em Windows.

Direção recomendada:
- extrair um `SteamUtilityClient`/`SteamUtilityCommandRunner`;
- toda chamada ao utilitário deve passar por esse ponto único.

### 10. Frontend monta caminhos com separador de Windows

Arquivos afetados:
- `src/features/settings/hooks/debug/useLogs.ts` linha 16
- `src/features/achievement-manager/components/PageHeader.tsx` linha 38
- `src/features/settings/components/debug/OpenSettings.tsx` linha 16

Padrão atual:
- uso de `\` para montar caminhos relativos

Impacto:
- isso vai produzir caminhos errados ou frágeis no Linux;
- mesmo que o backend seja portado, abrir arquivos específicos ainda falhará.

Direção recomendada:
- parar de montar paths no frontend;
- o frontend deve enviar segmentos ou chaves lógicas, e o backend resolve o caminho real.

### 11. Empacotamento Tauri assume recurso local `libs/*`

Arquivo: `src-tauri/tauri.conf.json`

Trechos relevantes:
- linha 38: `"resources": ["libs/*", "LICENSE", ".installed"]`
- linhas 20-28: config Windows/NSIS
- linha 19: ícone somente `.ico`

Impacto:
- o build já falhou por isso no health check;
- a estratégia de empacotamento ainda não sabe lidar com o utilitário multiplataforma;
- a presença de `resources` sem materialização local dos bins trava a build.

Direção recomendada:
- definir layout de recursos para dev e release;
- considerar `externalBin` ou diretório de recursos por target;
- manter compatibilidade com empacotamento Windows enquanto se adiciona Linux.

### 12. Documentação continua declarando fluxo Windows-only

Arquivos relevantes:
- `.gitmodules` linhas 1-4
- `docs/content/docs/get-started/build-it-yourself.mdx` linhas 14-19 e 41-42
- `docs/content/docs/troubleshooting.mdx`
- `docs/content/docs/settings/general.mdx`
- `docs/content/docs/settings/free-games.mdx`
- `docs/content/docs/features/playtime-booster.mdx`
- `docs/content/docs/features/card-farming.mdx`

Pontos observados:
- submodule ainda aponta para `zevnda/steam-utility`
- docs de build pedem `.NET Framework Developer Pack`, `VS Build Tools`, `WebView2`
- docs ainda assumem `SteamUtility.exe`
- troubleshooting e UX textual são centrados em Windows

Impacto:
- mesmo após código rodar no Linux, a documentação continuará enganando o desenvolvedor/usuário;
- porém isso é P1/P2, não precisa travar a primeira abstração técnica.

## Classificação por prioridade técnica

## P0 imediato

1. resolver caminho/binário do SteamUtility por plataforma
2. centralizar spawn de processos e esconder `creation_flags` atrás de abstração
3. substituir `taskkill` por abstração de gerenciamento de processo
4. remover dependência de títulos de janela Win32 para mapear processos em idle
5. parar de montar paths Windows no frontend

## P1 seguinte

1. ajustar `tauri.conf.json` para uma estratégia real de recursos/binários
2. integrar o `steam-utility-multiplataform` local em modo dev
3. adaptar monitoramento do processo Steam para Linux
4. adaptar `anti_away` e `open_file_explorer`

## P2 depois

1. revisar docs de build e troubleshooting
2. revisar UX/mensagens e nomenclatura `SteamUtility.exe`
3. revisar release pipeline Windows + Linux

## Primeira sequência de implementação recomendada

### Fase 1 - criar fundações sem mudar comportamento de Windows

1. criar módulo `steam_utility_resolver.rs`
2. criar módulo `command_runner.rs`
3. criar módulo `process_control.rs`
4. fazer `achievement_manager.rs`, `game_data.rs` e `idling.rs` usarem essas abstrações

### Fase 2 - remover o maior bloqueio Windows-only

5. reescrever `process_handler.rs` para não depender de enumeração de janelas Win32 como fonte primária de verdade
6. usar `SPAWNED_PROCESSES` e metadados próprios para acompanhar idles iniciados pelo SGI

### Fase 3 - compatibilizar dev Linux

7. adicionar suporte a `SGI_STEAM_UTILITY_PATH`
8. apontar esse caminho para o binário do `steam-utility-multiplataform`
9. ajustar `tauri.conf.json` para não quebrar `cargo check`/build quando `libs/*` não existir localmente

## Conclusão

O porte é viável, e o problema está bem delimitado.

A parte mais crítica não é reimplementar features, mas trocar a arquitetura de integração do SGI com o SteamUtility:
- hoje ela é Windows-centric e distribuída em vários arquivos;
- o caminho certo é centralizar resolução de binário, execução de comando e gerenciamento de processo.

Se essa camada for bem feita, o restante do porte para Linux fica muito mais previsível sem sacrificar a compatibilidade com Windows.
