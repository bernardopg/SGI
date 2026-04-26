# TODO - SGI Multiplataforma

Prioridades para portar o `steam-game-idler` para Linux usando `steam-utility-multiplataform`, sem regressão para Windows.

## Concluído agora

- [x] Criar workspace `/home/bitter/git-clones/SGI`
- [x] Mover `steam-utility-multiplataform` para dentro do workspace
- [x] Clonar `zevnda/steam-game-idler`
- [x] Documentar o contexto e a estratégia inicial em `README.md`
- [x] Executar auditoria P0 dos pontos Windows-only no `steam-game-idler`
- [x] Registrar a auditoria em `AUDIT-P0-WINDOWS-ONLY.md`
- [x] Introduzir uma camada inicial de resolução do SteamUtility por plataforma
- [x] Introduzir uma camada inicial de spawn/gerenciamento de processos sem `CommandExt` espalhado
- [x] Fazer `cargo check` do backend Tauri/Rust passar no Linux
- [x] Validar a primeira subida local do SGI no Linux usando `SGI_STEAM_UTILITY_PATH`
- [x] Criar script `scripts/dev-linux.sh` para repetir o fluxo local
- [x] Registrar a execução em `LINUX-DEV-RUNLOG.md`
- [x] Registrar incidente de travamento do host em `INCIDENT-2026-04-23-HANG.md`

## Regras operacionais imediatas

- nunca rodar `pnpm tauri dev` em background não supervisionado nesta máquina
- preferir `cargo check` e `dotnet build` para progresso seguro
- qualquer validação funcional via UI é responsabilidade direta do Bernardo até a máquina ser estabilizada

## P0 - obrigatório para começar o porte com segurança

- [x] Mapear todos os pontos Windows-only no backend Tauri/Rust do `steam-game-idler`
- [x] Catalogar onde o projeto assume `SteamUtility.exe`, `taskkill`, `explorer`, `CommandExt` e APIs Win32
- [x] Definir a estratégia de integração local entre `steam-game-idler` e `steam-utility-multiplataform`
- [x] Criar uma camada de resolução de caminho/nome do SteamUtility por plataforma → `steam_utility.rs`
- [x] Criar uma camada de gerenciamento de processos por plataforma → `command_runner.rs` + `process_handler.rs` via `SPAWNED_PROCESSES`
- [x] Garantir que o fluxo atual de Windows continue funcionando após a abstração inicial
- [x] Ajustar o backend para compilar no Linux sem imports exclusivos de Windows vazando globalmente
      → `windows`/`winapi` movidos para `[target.'cfg(windows)'.dependencies]`; zero warnings no `cargo check`
- [x] Validar uma primeira execução local do SGI no Linux chamando o `steam-utility-multiplataform`

## P1 - tornar o fluxo de desenvolvimento e build confiável

- [x] Substituir a dependência prática do submodule `libs` por uma estratégia de desenvolvimento local controlada
      → `libs/README.md` placeholder satisfaz o glob; `SGI_STEAM_UTILITY_PATH` aponta para o binário real em dev
- [x] Definir como o binário/artefato do `steam-utility-multiplataform` será consumido pelo SGI em dev e em release
      → dev: `SGI_STEAM_UTILITY_PATH` via `scripts/dev-linux.sh`; release: `libs/SteamUtility.Cli` (documentado)
- [x] Ajustar scripts/documentação de build para Linux + Windows
      → `scripts/dev-linux.sh` e `scripts/smoke-test-linux.sh` criados; `tauri.conf.json` com ícones PNG e deb.depends
- [x] Revisar requisitos do Tauri para Linux e documentar dependências do sistema
      → `tauri.conf.json` `linux.deb.depends` populado com `libwebkit2gtk-4.1-0`, `libgtk-3-0`, `libssl3`, `libappindicator3-1`, `dotnet-runtime-10`
- [x] Corrigir o warning do Next.js/Turbopack sobre root inferido por lockfile externo
      → `next.config.mjs` adicionado com `turbopack: { root: __dirname }`
- [x] Adicionar validações mínimas para o caminho Linux sem perder cobertura de Windows
      → `steam_utility.rs` com testes unitários + `scripts/smoke-test-linux.sh` (5/5 passando)
- [x] Revisar onde o frontend assume comportamentos específicos do ambiente Windows
      → `useLogs.ts`: `\\log.txt` → `/log.txt`; `open_file_explorer` já normaliza separador no backend
- [x] Definir smoke tests de integração entre SGI e SteamUtility multiplataforma
      → `scripts/smoke-test-linux.sh`: binary check, --help, no-args, unknown cmd, cargo check

## P2 - empacotamento, CI e acabamento

- [x] Adaptar pipeline de CI para validar Windows e Linux
      → `.github/workflows/ci.yml` novo: cargo check em ubuntu-22.04 + windows-latest a cada push/PR
- [x] Ajustar empacotamento/distribuição para publicar artefatos Linux sem quebrar a release Windows
      → `release.yml`: jobs `build_dotnet_linux` (SteamUtility.Cli self-contained) + `build_release_linux`
        (.deb + AppImage + .sig); ambos correm em paralelo com Windows sem alterar o fluxo existente
- [ ] Validação funcional da UI no Linux (ação do usuário — requer Tauri rodando com Steam ativo)
      → próximo passo: rodar `./scripts/dev-linux.sh` e testar idle + achievements end-to-end
- [ ] Revisar UX/mensagens de erro para diferenças entre Windows, Linux e Proton/Steam Runtime
- [ ] Atualizar documentação pública de instalação, build e troubleshooting
      → mínimo necessário: seção Linux no README com dependências do sistema e comando de instalação
- [ ] Decidir a estratégia final de upstream/fork/submodule/vendor após a integração estabilizar

## P3 - melhorias futuras

- [ ] Reduzir acoplamento entre SGI e o layout interno do SteamUtility
- [ ] Criar um contrato de integração mais estável entre app e utilitário
- [ ] Automatizar testes de regressão das features principais: idling, achievements, stats e ownership
- [ ] Avaliar suporte adicional para outros ambientes no futuro, sem prometer macOS agora

## Riscos principais

- regressão silenciosa para usuários Windows ao trocar o gerenciamento de processos;
- dependência atual do SGI no nome fixo `SteamUtility.exe`;
- diferenças de empacotamento Tauri entre Windows e Linux;
- necessidade de manter compatibilidade com o comportamento esperado pelo projeto original do Zevnda.

## Princípio guia

Toda mudança deve seguir esta regra:

1. não quebrar Windows;
2. habilitar Linux de forma incremental;
3. só depois refatorar o restante.
