# Incidente 2026-04-23 - Travamento completo durante `pnpm tauri dev`

## O que aconteceu

Durante a etapa de validação funcional do `steam-game-idler` no Linux, a máquina do Bernardo teve um travamento total (aparentemente overflow de memória/CPU) que exigiu reboot forçado.

Contexto da última execução antes do travamento:
- frontend: `pnpm dev` subiu em `http://localhost:3000`
- backend Tauri/Rust estava sendo compilado/executado com `cargo run --no-default-features`
- watcher `next dev` (Turbopack) rodando em paralelo
- processos pesados paralelos estavam rodando no sistema: Docker Desktop com VM QEMU, Chrome, VS Code, Discord

## Impacto em arquivos

Todos os arquivos do workspace SGI estão íntegros:

- `/home/bitter/git-clones/SGI/README.md`
- `/home/bitter/git-clones/SGI/TODO.md`
- `/home/bitter/git-clones/SGI/AUDIT-P0-WINDOWS-ONLY.md`
- `/home/bitter/git-clones/SGI/LINUX-DEV-RUNLOG.md`

No projeto `steam-game-idler` as alterações locais estão preservadas:

- `src-tauri/src/achievement_manager.rs`
- `src-tauri/src/game_data.rs`
- `src-tauri/src/idling.rs`
- `src-tauri/src/lib.rs`
- `src-tauri/src/process_handler.rs`
- `src-tauri/src/utils.rs`
- `src-tauri/src/command_runner.rs` (novo)
- `src-tauri/src/steam_utility.rs` (novo)
- `src-tauri/icons/icon.png` (novo)
- `next.config.mjs` (novo)
- `scripts/dev-linux.sh` (novo)

`cargo check` do backend continua passando no Linux.

## Hipótese de causa

Combinação provável:
1. `next dev` com Turbopack
2. `cargo run --no-default-features` do app Tauri compilando dependências pesadas
3. Docker Desktop com VM QEMU
4. Chrome + VS Code + Discord
5. resultado: pressão simultânea de RAM/CPU muito alta

Não foi uma falha lógica do projeto. Foi falta de folga de recursos no host enquanto o fluxo pesado de dev rodava.

## Regras operacionais adotadas daqui pra frente

1. Não rodar `pnpm tauri dev` diretamente sem supervisão do usuário.
2. Preferir validações leves antes de rodar fluxo completo:
   - `cargo check` no `src-tauri`
   - `dotnet build` no `steam-utility-multiplataform`
   - leitura/análise estática do código
3. Se for rodar fluxo dev completo:
   - fechar processos pesados (Docker Desktop, etc.)
   - rodar com o usuário presente e controlando
   - preferir o script local `scripts/dev-linux.sh`
4. Nunca deixar `pnpm tauri dev` rodando em background por longos períodos nesta máquina.

## Próximos passos seguros

- avançar por análise estática e mudanças de código
- validar pelo menos via `cargo check` / `cargo build`
- deixar validação funcional com UI sob controle direto do Bernardo
