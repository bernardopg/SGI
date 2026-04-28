# TODO - SGI

## Feito

- [x] Organizar workspace com a estrutura:

  ```text
  SGI/
  ├── steam-game-idler/
  └── steam-utility-multiplataform/
  ```

- [x] Registrar `steam-game-idler` e `steam-utility-multiplataform` como submodules no repo pai.
- [x] Criar fluxo Linux local em `steam-game-idler/scripts/dev-linux.sh`.
- [x] Resolver `SteamUtility.Cli` por plataforma/env var.
- [x] Fazer o backend Tauri compilar no Linux.
- [x] Corrigir o crash causado por alterações em `src-tauri/steam_appid.txt` durante o farm.
- [x] Isolar cada processo de idle em diretório temporário próprio.
- [x] Limpar helpers/diretórios temporários entre execuções.
- [x] Limitar farm de cartas no Linux para 8 sessões Steam API simultâneas.
- [x] Desativar caminhos instáveis no Linux/dev:
  - notificações nativas no `tauri dev`;
  - menu de contexto customizado via `Menu.popup()`;
  - Turbopack no `next dev`.
- [x] Adicionar `/health` para readiness checks.
- [x] Validar:
  - `pnpm typecheck`;
  - `pnpm build`;
  - `cargo check`;
  - farm de cartas em execução prolongada no Linux.

## Próximas etapas imediatas

- [ ] Fazer push dos commits dos submodules antes do commit/push do repo pai.
- [ ] Criar/confirmar remoto do repo pai `SGI`.
- [ ] Testar o fluxo completo após clone limpo com `git clone --recurse-submodules`.
- [ ] Rodar o farm por uma janela maior, por exemplo 2 a 4 horas, monitorando:
  - crash do WebKit;
  - IPC da Steam;
  - processos `SteamUtility.Cli` órfãos;
  - limpeza de `/tmp/steam-game-idler`.
- [ ] Definir se o limite Linux de 8 idlers será configuração do usuário ou constante por plataforma.
- [ ] Investigar se o WebKit volta a ser estável com Turbopack em versões futuras do Next/Tauri/WebKitGTK.

## P1 - estabilização de release Linux

- [ ] Documentar dependências Linux por distro.
- [ ] Confirmar build `.deb` e AppImage com `SteamUtility.Cli` empacotado.
- [ ] Verificar permissões Tauri em build instalado, não só `tauri dev`.
- [ ] Testar instalação em ambiente limpo.
- [ ] Revisar comportamento de tray, close-to-tray e notificações nativas fora do modo dev.
- [ ] Garantir que `steam_appid.txt` gerado nunca fique em diretórios versionados/observados.

## P2 - integração SteamUtility

- [ ] Criar contrato explícito entre SGI e `SteamUtility.Cli` para comandos e JSON.
- [ ] Separar stdout JSON de logs nativos/Steam IPC para evitar parse quebrado.
- [ ] Adicionar testes de integração para:
  - `idle`;
  - `check_ownership`;
  - `get_achievement_data`;
  - mutações de achievements/stats.
- [ ] Decidir estratégia de versionamento entre app e utilitário.

## P3 - upstream e manutenção

- [ ] Comparar branch/fork com upstream `zevnda/steam-game-idler`.
- [ ] Separar PRs pequenos quando fizer sentido upstream.
- [ ] Manter changelog de decisões Linux.
- [ ] Automatizar CI do workspace pai com atualização de submodules.

## Riscos

- Regressão Windows por mudanças em gerenciamento de processos.
- Instabilidade do WebKitGTK com APIs Tauri específicas.
- Steam IPC ficar saturado com muitos jogos simultâneos.
- Divergência entre versões do `steam-game-idler` e `steam-utility-multiplataform`.
