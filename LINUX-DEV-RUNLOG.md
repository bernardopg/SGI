# Linux dev run log - steam-game-idler

Data: 2026-04-23
Workspace: `/home/bitter/git-clones/SGI`

## Objetivo

Executar a primeira subida local do `steam-game-idler` no Linux usando o binário real do `steam-utility-multiplataform`.

## Ações realizadas

### 1. Preparação do workspace

- `pnpm install` executado em `/home/bitter/git-clones/SGI/steam-game-idler`
- `.env.dev` criado com placeholder:

```ini
KEY=""
```

### 2. Binário do SteamUtility validado

Comando usado:

```bash
dotnet build steam-utility-multiplataform.sln -c Release
```

Binário Linux validado:

```text
/home/bitter/git-clones/SGI/steam-utility-multiplataform/src/SteamUtility.Cli/bin/Release/net10.0/SteamUtility.Cli
```

### 3. Primeira subida local do SGI

Comando efetivamente usado:

```bash
SGI_STEAM_UTILITY_PATH=/home/bitter/git-clones/SGI/steam-utility-multiplataform/src/SteamUtility.Cli/bin/Release/net10.0/SteamUtility.Cli pnpm tauri dev
```

## Evidências observadas

### Frontend

Logs relevantes:

```text
> steam-game-idler@0.1.0 tauri
> tauri dev

Running BeforeDevCommand (`pnpm run dev`)
> steam-game-idler@0.1.0 dev
> next dev

▲ Next.js 16.1.7 (Turbopack)
- Local: http://localhost:3000
✓ Ready in 644ms
```

### Backend Tauri/Rust

Logs relevantes:

```text
Running DevCommand (`cargo run --no-default-features --color always --`)
Info Watching .../src-tauri for changes...
```

### Processo do aplicativo

Foi confirmado um processo ativo do app:

```text
target/debug/steam-game-idler
```

Também foi confirmado que o processo herdou a variável de ambiente correta:

```text
SGI_STEAM_UTILITY_PATH=/home/bitter/git-clones/SGI/steam-utility-multiplataform/src/SteamUtility.Cli/bin/Release/net10.0/SteamUtility.Cli
```

## Bloqueios e observações restantes

### 1. Acesso direto ao `http://localhost:3000` fora do Tauri não representa o app final

Quando a página é aberta em um navegador comum, aparecem erros como:

```text
Cannot read properties of undefined (reading 'invoke')
```

Isso acontece porque o frontend depende da API Tauri (`invoke`) e o navegador comum não injeta esse contexto. Portanto:
- `localhost:3000` é útil para verificar que o frontend subiu;
- mas ele não prova sozinho que a UI web isolada funciona fora do Tauri;
- a validação correta do produto continua sendo o app nativo carregando essa mesma página dentro do WebView do Tauri.

### 2. Warning do Next.js sobre root do workspace

O Next detectou múltiplos lockfiles e inferiu a raiz como `/home/bitter` por causa de um `package-lock.json` externo ao repositório.

Impacto:
- não impediu a subida;
- mas deve ser corrigido para evitar comportamento inconsistente do Turbopack.

### 3. `.env.dev` ainda é placeholder

O app agora sobe, mas sem uma Steam Web API key real certas features continuarão limitadas.

### 3. Ainda não houve validação funcional via UI

Esta etapa provou:
- compilação local do backend no Linux;
- subida do fluxo `pnpm tauri dev`;
- injeção do caminho real do SteamUtility multiplataforma.

Esta etapa ainda não provou:
- login completo;
- chamadas reais do frontend para o backend Tauri envolvendo o SteamUtility;
- fluxos end-to-end como ownership, achievements e idle.

## Conveniência adicionada

Script criado para próximas execuções:

```text
/home/bitter/git-clones/SGI/steam-game-idler/scripts/dev-linux.sh
```

Uso:

```bash
cd /home/bitter/git-clones/SGI/steam-game-idler
./scripts/dev-linux.sh
```

O script:
- aponta automaticamente para o binário local do `steam-utility-multiplataform`;
- cria `.env.dev` placeholder se faltar;
- executa `pnpm tauri dev`.

## Conclusão

A próxima barreira não é mais “compilar no Linux”.

A próxima barreira real passa a ser validação funcional:
1. abrir o app;
2. confirmar que ações da UI disparam comandos no `SteamUtility.Cli` local;
3. ajustar os fluxos que ainda assumirem Windows em runtime real.
