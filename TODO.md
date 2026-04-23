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

- [ ] Mapear todos os pontos Windows-only no backend Tauri/Rust do `steam-game-idler`
- [ ] Catalogar onde o projeto assume `SteamUtility.exe`, `taskkill`, `explorer`, `CommandExt` e APIs Win32
- [ ] Definir a estratégia de integração local entre `steam-game-idler` e `steam-utility-multiplataform`
- [ ] Criar uma camada de resolução de caminho/nome do SteamUtility por plataforma
- [ ] Criar uma camada de gerenciamento de processos por plataforma
- [ ] Garantir que o fluxo atual de Windows continue funcionando após a abstração inicial
- [ ] Ajustar o backend para compilar no Linux sem imports exclusivos de Windows vazando globalmente
- [ ] Validar uma primeira execução local do SGI no Linux chamando o `steam-utility-multiplataform`

## P1 - tornar o fluxo de desenvolvimento e build confiável

- [ ] Substituir a dependência prática do submodule `libs` por uma estratégia de desenvolvimento local controlada
- [ ] Definir como o binário/artefato do `steam-utility-multiplataform` será consumido pelo SGI em dev e em release
- [ ] Ajustar scripts/documentação de build para Linux + Windows
- [ ] Revisar requisitos do Tauri para Linux e documentar dependências do sistema
- [ ] Corrigir o warning do Next.js/Turbopack sobre root inferido por lockfile externo
- [ ] Adicionar validações mínimas para o caminho Linux sem perder cobertura de Windows
- [ ] Revisar onde o frontend assume comportamentos específicos do ambiente Windows
- [ ] Definir smoke tests de integração entre SGI e SteamUtility multiplataforma

## P2 - empacotamento, CI e acabamento

- [ ] Adaptar pipeline de CI para validar Windows e Linux
- [ ] Ajustar empacotamento/distribuição para publicar artefatos Linux sem quebrar a release Windows
- [ ] Revisar UX/mensagens de erro para diferenças entre Windows, Linux e Proton/Steam Runtime
- [ ] Atualizar documentação pública de instalação, build e troubleshooting
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
