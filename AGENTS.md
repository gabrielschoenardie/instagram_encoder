> **Objetivo:** Documentar agentes e diretrizes de trabalho para o projeto **instagram_encoder**.  
> Este arquivo unifica:  
> 1. Definições do agente principal (InstagramEncoderV3) e seus requisitos de entrada/saída.  
> 2. Instruções gerais de estilo de código, testes e formatação.  
> 3. Regras para validar commits e Pull Requests (PRs).  
> 4. Metadados resumidos em formato tabular, para rápida referência.

---

## 1. Visão Geral dos Agentes

### 1.1 Tabela de Metadados dos Agentes

| Nome do Agente         | Tipo             | Função Principal                                    | Input                                                        | Output                                           | Stack / Tecnologias                                      |
|------------------------|------------------|-----------------------------------------------------|--------------------------------------------------------------|--------------------------------------------------|-----------------------------------------------------------|
| **InstagramEncoderV3** | Conversor Vídeo  | Converter vídeos para formato otimizado de Instagram | - Caminho do vídeo de entrada<br>- Resolução (1080x1920 ou 1920x1080)<br>- Modo (CRF ou Two-Pass)<br>- Valor CRF (17–22)<br>- Bitrate (se Two-Pass) | - Arquivo MP4 otimizado para Instagram<br>- Logs FFmpeg (`ffmpeg_logs/`) | - PowerShell (Windows Forms)<br>- FFmpeg<br>- Pester (para testes)<br>- PSScriptAnalyzer (lint)<br>- GitHub Actions (CI/CD)<br>- Codex AI / ChatGPT (ciclos de revisão contínua) |
| **code-generator**     | Gerador Código   | Gerar/refatorar funções PowerShell                   | - Descrição da função a ser criada/refatorada               | - Bloco de código PowerShell padronizado         | - PowerShell<br>- Codex AI / ChatGPT<br>- PSScriptAnalyzer               |
| **doc-updater**        | Documentação     | Sincronizar README.md, CHANGELOG.md, CONTRIBUTING.md  | - Detecção de novos/alterados arquivos em `src/`             | - Arquivos Markdown atualizados                  | - Markdown<br>- Codex AI / ChatGPT                                  |
| **test-creator**       | Testes           | Gerar testes Pester automáticos                       | - Funções novas/modificadas em `src/`                         | - Arquivos `.Tests.ps1` em `tests/`               | - PowerShell (Pester)<br>- Codex AI / ChatGPT                     |
| **lint-checker**       | Linter           | Aplicar correções de estilo (PSScriptAnalyzer)        | - Arquivos `.ps1` / `.psm1` modificados                      | - Arquivos corrigidos ou relatório de violações   | - PowerShell (PSScriptAnalyzer)<br>- Git                              |

---

## 2. Agente Principal: InstagramEncoderV3

### 2.1 Descrição
O **InstagramEncoderV3** é responsável por converter vídeos para o formato otimizado de Instagram (Reels 9:16 ou 16:9), suportando modos de codificação **CRF** ou **Two-Pass**. É acionado via GitHub Actions ou localmente, e gera tanto o vídeo final quanto logs detalhados de cada etapa.

### 2.2 Entradas
- **Caminho do vídeo de entrada**  
  - String: caminho absoluto ou relativo (ex.: `videos/input.mp4`).  
- **Resolução**  
  - Se **Vertical** (9:16): `1080x1920`  
  - Se **Horizontal** (16:9): `1920x1080`  
- **Modo de Codificação**  
  - `CRF` (Qualidade Constante) ou `Two-Pass` (Controle via Bitrate).  
- **Valor CRF**  
  - Inteiro (17–22), somente se Modo = `CRF`.  
- **Bitrate**  
  - String (ex.: `3000k`), somente se Modo = `Two-Pass`.

### 2.3 Saídas
- **Arquivo MP4 Otimizado**  
  - Nome: `<nome_original>_INSTA_H264_ADV.mp4`  
  - Local: Pasta de saída configurada (ex.: `convertidos_h264_instagram_avancado/`).  
- **Logs de Execução do FFmpeg**  
  - Cada passo (Passo 1, Passo 2 ou CRF) gera um arquivo de log em `ffmpeg_logs/`:
    - `<nome_base>_pass1.log`  
    - `<nome_base>_pass2.log`  
    - `<nome_base>_crf.log`  

### 2.4 Fluxo de Operação
1. **Validação de Entradas**
   - Verificar existência do arquivo de entrada e extensão suportada (`.mp4, .mov, .mkv, .avi`).  
   - Verificar formato de resolução (`LARGURAxALTURA`) e correspondência a proporções 9:16 ou 16:9.  
   - Se Modo = `CRF`, garantir `17 ≤ Valor CRF ≤ 22`.  
   - Se Modo = `Two-Pass`, garantir formato correto de `Bitrate` (ex.: `3000k`).  

2. **Criação de Pastas**
   - Criar (se não existir) a pasta de saída, ex.: `convertidos_h264_instagram_avancado/`.  
   - Dentro desta, criar subpasta `ffmpeg_logs/` para armazenar logs.

3. **Seleção de Filtro de Escala**
   - **Vertical (9:16)**
     ```
     scale=if(gt(a,9/16),1080,-2):if(gt(a,9/16),-2,1920):flags=lanczos,format=yuv420p
     ```
   - **Horizontal (16:9)**
     ```
     scale=if(gt(a,16/9),1920,-2):if(gt(a,16/9),-2,1080):flags=lanczos,format=yuv420p
     ```

4. **Montagem de Argumentos FFmpeg**
   - **Modo CRF**
     ```powershell
     ffmpeg -i "<input>" -c:v libx264 -preset slow -tune film -profile:v high -level 4.1 `
            -pix_fmt yuv420p -color_primaries bt709 -color_trc bt709 -colorspace bt709 `
            -crf <Valor CRF> -r 30 -g 30 -keyint_min 30 -sc_threshold 0 `
            -vf "<filtro_escala>" `
            -x264-params "bf=3:b_strategy=2:refs=5:coder=ac:aq-mode=2:psy-rd=\"1.0:0.15\"" `
            -c:a aac -b:a 192k -ar 48000 -ac 2 -y "<output>"
     ```
   - **Modo Two-Pass**
     - **Passo 1**
       ```powershell
       ffmpeg -i "<input>" -c:v libx264 -preset slow -tune film -profile:v high -level 4.1 `
              -pix_fmt yuv420p -color_primaries bt709 -color_trc bt709 -colorspace bt709 `
              -b:v <Bitrate> -r 30 -g 30 -keyint_min 30 -sc_threshold 0 `
              -vf "<filtro_escala>" `
              -x264-params "bf=3:b_strategy=2:refs=5:coder=ac:aq-mode=2:psy-rd=\"1.0:0.15\"" `
              -pass 1 -an -f null NUL
       ```
     - **Passo 2**
       ```powershell
       ffmpeg -i "<input>" -c:v libx264 -preset slow -tune film -profile:v high -level 4.1 `
              -pix_fmt yuv420p -color_primaries bt709 -color_trc bt709 -colorspace bt709 `
              -b:v <Bitrate> -r 30 -g 30 -keyint_min 30 -sc_threshold 0 `
              -vf "<filtro_escala>" `
              -x264-params "bf=3:b_strategy=2:refs=5:coder=ac:aq-mode=2:psy-rd=\"1.0:0.15\"" `
              -pass 2 -c:a aac -b:a 192k -ar 48000 -ac 2 -y "<output>"
       ```

5. **Execução e Monitoramento**
   - Executar cada comando FFmpeg, redirecionando `stderr` de forma assíncrona para capturar logs.  
   - Registrar saída em:  
     - `convertidos_h264_instagram_avancado/ffmpeg_logs/<nome_base>_pass1.log`  
     - `convertidos_h264_instagram_avancado/ffmpeg_logs/<nome_base>_pass2.log` ou `<nome_base>_crf.log`  
   - Reportar progresso (porcentagem) ao usuário ou ao log de CI.

6. **Tratamento de Erros e Mensagens**
   - Se algum passo retornar `ExitCode != 0`, interromper sequência, gravar mensagem de erro em log e exibir mensagem didática (ex.:  
     > “Ocorreu um erro ao processar `<nome_base>`. Verifique o log: `<caminho_log>`.”)  
   - Sinalizar falha à interface (via `MessageBox`) ou ao CI (status de build vermelho).

---

## 4. Estrutura Recomendada de Pastas

```text
instagram_encoder/
├── src/                              # Código-fonte principal
│   ├── InstagramEncoder.ps1          # Script PowerShell com UI e lógica
│   ├── InstagramEncoder.psm1         # Módulo PowerShell (opcional)
│   ├── InstagramEncoder.psd1         # Manifest do módulo (opcional)
│   └── agents/                       # Definições e templates de agentes
│       ├── code-generator/
│       │   ├── templates/
│       │   │   ├── function-template.ps1
│       │   │   └── parameter-help-template.md
│       │   └── prompts/
│       │       └── generate-function.prompt.md
│       ├── doc-updater/
│       │   ├── templates/
│       │   │   ├── readme-functions-section.md
│       │   │   ├── changelog-entry-template.md
│       │   │   └── contributing-guidelines-template.md
│       │   └── prompts/
│       │       ├── update-readme.prompt.md
│       │       └── update-changelog.prompt.md
│       ├── test-creator/
│       │   ├── templates/
│       │   │   ├── pester-describe-template.ps1
│       │   │   └── invalid-value-template.md
│       │   └── prompts/
│       │       └── create-pester-tests.prompt.md
│       └── lint-checker/
│           ├── pssa-settings.psd1
│           └── prompts/
│               └── lint-fix.prompt.md
├── docs/                             # Documentação extra e diagramas
│   └── diagrams/
│       └── fluxograma.md             # Exemplo de diagrama em Markdown/Mermaid
├── examples/                         # Exemplos de vídeos de entrada/saída
│   ├── video-raw.mp4
│   └── video-insta.mp4
├── tests/                            # Testes Pester e pytest
│   └── Get-VideoMetadata.Tests.ps1   # Gerado pelo test-creator
├── .github/                          # Configurações do GitHub
│   ├── workflows/
│   │   └── ci.yml                    # GitHub Actions para CI
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── PULL_REQUEST_TEMPLATE.md
├── .gitignore                        # Padronização de arquivos ignorados
├── .gitattributes                    # Normalização de line endings
├── LICENSE                           # MIT License
├── CONTRIBUTING.md                   # Guia de contribuição
├── CHANGELOG.md                      # Histórico de versões (SemVer)
└── AGENTS.md                         # Este arquivo de instruções

## 3. Diretrizes Gerais

### 3.1 Code Style (Estilo de Código)
- **PowerShell** (principal):  
  - **Callouts de Help Padrão**:  
    - Use `[CmdletBinding()]` e `param()` corretamente.  
    - Incluir `<#.SYNOPSIS .DESCRIPTION .PARAMETER .EXAMPLE .NOTES#>` em cada função.  
  - **PowerShell Script Analyzer**:  
    - Sempre rodar `Invoke-ScriptAnalyzer -Settings src/agents/lint-checker/pssa-settings.psd1 -Fix`.  
    - Principais regras:
      - `PSUseApprovedVerbs`: use verbos aprovados (Get, Set, Convert, Invoke, etc.).  
      - `PSAvoidUsingWriteHost`: use `Write-Verbose`, `Write-Output` ou `Write-Error`.  
      - `PSAvoidUsingDeprecatedAliases`: evite aliases (`gci`, `ls`, etc.).  
      - `PSAvoidUsingPlainTextForCredentials`: não deixar credenciais em texto puro.  
      - `PSAvoidUsingConvertToSecureStringWithPlainText`: promova uso de `SecureString` via prompt ou parâmetros seguros.  


### 3.2 Testing (Testes)
- **PowerShell (Pester)**:  
  - Crie testes em `tests/` com sufixo `.Tests.ps1`.  
  - Antes de finalizar PR, execute:
    ```powershell
    Invoke-Pester -Script tests/*.Tests.ps1 -Output Detailed
    ```
  - Testes básicos devem cobrir:
    - Validação de entradas (arquivo inexistente, resolução incorreta, CRF fora de faixa, bitrate inválido).  
    - Resposta de erro em casos de falha do FFmpeg.  
    - Comportamento correto em conversão bem-sucedida.  

### 3.3 PR Instructions (Instruções para Pull Request)
- **Título do PR:**  
  - Começar com `[Fix]` ou `[Feature]`, seguido de descrição curta:
    ```
    [Fix] Corrigir validação de resolução no InstagramEncoderV3
    [Feature] Adicionar segurança contra comandos inválidos no FFmpeg
    ```
- **Descrição do PR:**  
  - **One-line summary:** resumo em uma linha do que foi alterado.  
  - **Motivação/Contexto:** por que a mudança é necessária (ex.: “para evitar injeção de comandos no parâmetro de filtro”).  
  - **Detalhes da mudança:** arquivos e funções principais modificados.  
  - **Testing Done:** lista de comandos/testes executados e seus resultados (ex.:
    - `Invoke-Pester -Script tests/Get-VideoMetadata.Tests.ps1` → passou  
    - `Invoke-ScriptAnalyzer` → sem violações  
    - `pytest` → sem erros  
  )  

- **Commit Messages:**  
  - Seguir padrão **Conventional Commits**:
    - `feat:` para novas funcionalidades  
    - `fix:` para correções  
    - `docs:` para documentação  
    - `refactor:` para refatorações  
    - `style:` para formatação sem mudanças de lógica  

---

## 7. Uso do AGENTS.md para Análise e Correção do Script

Este arquivo **AGENTS.md** deve orientar não apenas a automação via GitHub Actions, mas também servir de guia interativo para:
1. **Análise Funcional**  
   - Use as seções de entradas/saídas e o fluxo de operação do **InstagramEncoderV3** para revisar se os parâmetros do script estão sendo validados corretamente.  
   - Verifique se cada etapa descrita (validação, montagem de comandos, execução e tratamento de erros) está implementada no código PowerShell.

2. **Reforço em Validação de Entradas**  
   - Verificar se o código:
     - Confirma existência de arquivo com `Test-Path -LiteralPath $VideoPath -PathType Leaf`.  
     - Valida o formato de resolução (`LARGURAxALTURA`) e se corresponde às proporções 9:16 ou 16:9.  
     - Verifica limites de `Valor CRF` (17–22) e formato de `Bitrate` (ex.: apenas dígitos seguidos de “k”).  

3. **Detecção de Erros no FFmpeg**  
   - Assegurar que o script capture `ExitCode` do processo FFmpeg e direcione erros ao log:  
     ```powershell
     if ($process.ExitCode -ne 0) {
         # Gravar log de erro e exibir mensagem didática
         Write-Error "Falha no FFmpeg ($PassName) para $CurrentFileName. Verifique: $logFile"
         return $false
     }
     ```
   - Em caso de falha, notificar o usuário com mensagens claras, por exemplo:  
     > “Erro ao codificar vídeo `<nome_base>`. Veja o log completo em `<caminho_log>`. Se o problema persistir, verifique se o FFmpeg está instalado e configurado no PATH.”

4. **Mensagens Didáticas ao Usuário**  
   - Quando ocorrer input inválido (resolução incorreta, valor CRF fora de faixa, bitrate mal formatado), o script deve usar `MessageBox` ou `Write-Host` com tom didático:
     ```powershell
     [System.Windows.Forms.MessageBox]::Show(
         "Resolução inválida. Informe no formato LARGURAxALTURA (ex.: 1080x1920).",
         "Parâmetro Inválido",
         [System.Windows.Forms.MessageBoxButtons]::OK,
         [System.Windows.Forms.MessageBoxIcon]::Warning
     )
     return
     ```
   - Em ambiente não-GUI, exibir via `Write-Error` ou `Write-Warning` de forma clara:
     ```powershell
     Write-Error "O valor de CRF deve estar entre 17 e 22. Recebido: $crfValue"
     ```

5. **Segurança Contra Comandos Inválidos**  
   - Assegurar que todos os parâmetros usados no comando FFmpeg sejam devidamente escapados ou passados em arrays para evitar injeção de strings:
     ```powershell
     $argList = @("-i", "$VideoPath", "-vf", "$VideoFilter", "-crf", "$crfValue", "-y", "$outputPath")
     & ffmpeg @argList
     ```
   - Evitar concatenar diretamente strings que contenham variáveis vindas do usuário sem validação prévia.  

6. **Ciclo Profissional de Revisão e Evolução Contínua**  
   - Utilize o Codex AI (ou ChatGPT) a cada nova alteração para:
     1. **Gerar sugestões de melhorias** no fluxo de validação ou montagem de comandos.  
     2. **Criar testes Pester** atualizados para cobrir novos cenários de erro ou edge cases.  
     3. **Refatorar trechos de código** para isolar lógica de validação em funções reutilizáveis, melhorando a manutenibilidade.  
     4. **Atualizar este AGENTS.md**, refletindo novas práticas de segurança, novos parâmetros ou fluxos adicionais.

7. **Checklist de Revisão Funcional**  
   - [ ] **Validação de Arquivos**: `Test-Path` e verificação de extensões suportadas.  
   - [ ] **Validação de Resolução**: Regex ou parse de `LARGURAxALTURA`, verificação de razão.  
   - [ ] **Validação de CRF/Bitrate**: intervalo numérico e formato (`^\d+(k)?$`).  
   - [ ] **Construção Segura de Argumentos FFmpeg**: uso de arrays `@()` e escapamento correto.  
   - [ ] **Tratamento de Erros**: Captura de `ExitCode`, mensagens didáticas, logs em `ffmpeg_logs/`.  
   - [ ] **UI Resposta**: Uso apropriado de `MessageBox` e/ou `Write-Error`/`Write-Warning` conforme ambiente.  
   - [ ] **Testes Automatizados**: Pester cobrindo cenários de sucesso e falha do FFmpeg.  
   - [ ] **Lint/Estilo**: Todas as funções devem estar livres de avisos do PSScriptAnalyzer.  
   - [ ] **Documentação**: Comment-based help em cada função principal.

---

## 8. Manutenção e Sincronização

1. **Adicionar novos agentes**  
   - Sempre que criar um novo agente, adicionar uma linha na tabela de metadados e uma seção detalhando entradas/saídas e papéis.  

2. **Atualizar templates e prompts**  
   - Se alterar padrões de comentários, estrutura de testes ou fluxos de CI, atualizar também os arquivos `.prompt.md` correspondentes.  

3. **Validação periódica**  
   - Execute o script PowerShell para garantir que não há prompts não referenciados:
     ```powershell
     $prompts = Get-ChildItem -Path src/agents -Recurse -Filter *.prompt.md
     foreach ($prompt in $prompts) {
         $relPath = $prompt.FullName.Replace((Get-Location).Path + "\", "")
         if (-not (Select-String -Path AGENTS.md -Pattern [regex]::Escape($relPath))) {
             Write-Warning "Prompt não referenciado: $relPath"
         }
     }
     ```
   - Verifique também se a tabela de metadados reflete todos os agentes atuais.

4. **Limpeza de agentes obsoletos**  
   - Ao descontinuar um agente, comentar sua linha na tabela e mover a pasta para:
     ```
     src/agents/archive/<nome-do-agent>/
     ```

5. **Padronizar commits automáticos**  
   - Todos os commits gerados por agentes devem começar com `[Auto-Agent] <tipo>: descrição curta`.  
   - Exemplo: `[Auto-Agent] test-creator: adicionar teste para Get-VideoMetadata`.

---

## 9. Referências e Links Úteis

- **GitHub Actions**  
  - Documentação: https://docs.github.com/actions  
  - Exemplos de workflows: https://github.com/actions/starter-workflows  

- **OpenAI Codex / ChatGPT para Programadores**  
  - Guia de prompt engineering: https://github.com/dair-ai/Prompt-Engineering-Guide  

- **PowerShell Script Analyzer (PSScriptAnalyzer)**  
  - Documentação: https://github.com/PowerShell/PSScriptAnalyzer  
  - Regras padrão: https://github.com/PowerShell/PSScriptAnalyzer/tree/master/Rules  

- **Pester (Framework de Testes PowerShell)**  
  - Site oficial: https://pester.dev/  
  - Exemplos de uso: https://github.com/pester/Pester/tree/master/Examples  

- **Mermaid (Diagramas em Markdown)**  
  - Documentação: https://mermaid-js.github.io/  

---

> **Nota Final:**  
> Este **AGENTS.md** serve como guia central para automatizar, revisar e evoluir continuamente o script **InstagramEncoderV3**.  
> Mantenha-o sempre atualizado conforme novas funcionalidades e padrões de segurança forem incorporados.  
>  
> _Criado para orientar agentes Codex AI na automação de geração de código, documentação, testes e correção de estilo._  
