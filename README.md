<!-- Badges -->
![FFmpeg](https://img.shields.io/badge/FFmpeg-H.264-green?logo=ffmpeg)
![Instagram Ready](https://img.shields.io/badge/Instagram-Ready-purple)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)  

---

# 🎬 Instagram Encoder

> **"Do seu computador direto para as telas do mundo inteiro."**  
> Uma jornada cinematográfica em cada frame, trazendo vídeos comuns ao auge da perfeição otimizada para Instagram.

---

## 🌟 Visão Geral

No auge da indústria cinematográfica, cada detalhe importa: cores, proporções, qualidade. Assim como um diretor exige excelência em cada cena, o **Instagram Encoder** eleva seus vídeos à experiência de cinema — agora no seu Instagram Reels, Stories ou Feed. Desenvolvido em PowerShell, este projeto encapsula a força do FFmpeg, a elegância do PSScriptAnalyzer e a robustez de testes Pester para oferecer um pipeline de conversão de vídeo digno de Hollywood.

---

## 🎥 Recursos Principais

- **Conversão Cinematográfica**  
  - Ajuste automático de resolução para padrões verticais 9:16 (Reels/Stories) e horizontais 16:9 (Feed).
  - Dois modos de codificação:
    - **CRF**: qualidade constante, garantindo brilho máximo em cada cena.
    - **Two-Pass**: precisão de bitrate, para máxima fidelidade em momentos decisivos.
- **Validação Avançada de Entradas**  
  - Verifica existência do arquivo e formatos suportados (`.mp4`, `.mov`, `.mkv`, `.avi`).
  - Checa rigorosamente proporções e faixas de CRF (17–22) ou Bitrate (`\d+k`).
- **Tratamento de Erros de Estreia**  
  - Captura e grava cada mensagem de erro do FFmpeg.
  - Mensagens salas de cinema: diálogos claros e instrutivos para o usuário em caso de falha.
- **Testes de Qualidade (Pester)**  
  - Cenários de unidade cobrindo desde arquivos inexistentes até conversões bem-sucedidas.
  - Garante que cada take (frame) do processo seja aprovado antes do release.
- **Lint & Estilo (PSScriptAnalyzer)**  
  - Padrões de nomenclatura e chamadas recomendadas (sem `Write-Host`, só verbos aprovados).
  - Formatação impecável, como roteiros de grandes produções.
- **Integração Contínua (GitHub Actions)**  
  - Pipeline automatizado para rodar lint, testes Pester e checar consistência dos prompts/AGENTS.md.
  - Garante que cada commit seja uma cena pronta para estrear no palco principal (branch `main`).

---

## 📦 Requisitos

Antes da grande produção, assegure-se de ter em mãos:

1. **Windows PowerShell 5.1+** ou **PowerShell 7+**  
   - Execute `pwsh --version` para confirmar.
2. **FFmpeg**  
   - Disponível no `PATH` do sistema.  
   - Para instalar rapidamente no Windows:  
     ```powershell
     winget install -e --id Gyan.FFmpeg
     ```
3. **PSScriptAnalyzer** (para lint automático)  
   ```powershell
   Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
