# SGI Workspace

Workspace local para a evolução do Steam Game Idler rumo ao suporte multiplataforma, sem quebrar a experiência atual dos usuários Windows.

## Objetivo

Transformar o `steam-game-idler` em um aplicativo realmente multiplataforma, usando como base o `steam-utility-multiplataform`, que já recebeu a maior parte do trabalho de portabilidade e modernização.

## Estrutura criada

```text
/home/bitter/git-clones/SGI/
├── steam-game-idler/
└── steam-utility-multiplataform/
```

## O que foi feito agora

- o repositório local `steam-utility-multiplataform` foi movido de `/home/bitter/development/steam-utility-multiplataform` para este workspace;
- o repositório original `zevnda/steam-game-idler` foi clonado ao lado;
- o objetivo desta organização é trabalhar com os dois projetos lado a lado, com contexto completo e sem misturar tudo cedo demais.

## Estado atual observado

### steam-utility-multiplataform

- já está em .NET 10;
- já possui foco explícito em Linux + Windows;
- já implementa autodetecção de plataforma, descoberta de Steam, Proton/compatdata e runtime nativo;
- ainda possui alterações locais não commitadas que foram preservadas no movimento do diretório.

### steam-game-idler

O clone original ainda está fortemente orientado a Windows em pontos críticos do backend Tauri/Rust. Exemplos já identificados:

- uso de `std::os::windows::process::CommandExt`;
- uso de `taskkill` para encerramento de processos;
- uso de `explorer` para abrir diretórios;
- resolução hardcoded de `libs/SteamUtility.exe`;
- dependência do submodule `libs` apontando para `https://github.com/zevnda/steam-utility.git`;
- documentação de build ainda assumindo `dotnet build ./libs/SteamUtility.csproj` e pré-requisitos Windows.

Isso confirma que a parte mais sensível agora não é o `steam-utility`, e sim a camada de integração do `steam-game-idler` com ele.

## Melhor estratégia daqui para frente

A abordagem mais segura é incremental:

1. preservar o comportamento atual de Windows como baseline;
2. trocar acoplamentos Windows-only por abstrações por plataforma no backend do `steam-game-idler`;
3. permitir que o SGI consuma o `steam-utility-multiplataform` localmente durante o desenvolvimento;
4. só depois ajustar build, empacotamento e distribuição Linux.

## Decisões de arquitetura recomendadas

### 1. Não substituir tudo de uma vez

Evitar uma migração “big bang”. O ideal é manter compatibilidade com Windows em cada etapa.

### 2. Desacoplar o caminho/binário do SteamUtility

Em vez de assumir `SteamUtility.exe`, o SGI deve resolver:

- nome do executável por plataforma;
- caminho do binário empacotado;
- caminho alternativo de desenvolvimento local.

A melhor direção é criar uma camada de resolução do SteamUtility com fallback em ordem, por exemplo:

1. variável de ambiente/config de desenvolvimento;
2. binário empacotado pelo app;
3. caminho legado Windows, quando aplicável.

### 3. Isolar operações específicas de SO

Matar processo, abrir explorador de arquivos, esconder janela, descobrir processos em execução e quaisquer flags específicas de criação de processo devem virar uma camada própria por plataforma.

### 4. Manter o clone upstream limpo no começo

Neste primeiro momento, o mais seguro é trabalhar com o `steam-game-idler` original clonado e documentar a integração com o `steam-utility-multiplataform`, em vez de já reestruturar submodules ou forçar mudanças grandes no layout do upstream.

## Resultado esperado da próxima fase

Ao final da fase inicial, o `steam-game-idler` deverá:

- compilar no Linux;
- localizar e executar o `steam-utility-multiplataform` corretamente;
- preservar o fluxo atual de Windows;
- ter uma base de código preparada para empacotamento multiplataforma.

## Observação importante

Este workspace é de desenvolvimento e integração. O objetivo aqui é provar a estratégia técnica com segurança antes de decidir como isso será publicado, forkado ou enviado upstream.
