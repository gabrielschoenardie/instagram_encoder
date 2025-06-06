
# Instagram Encoder

![License](https://img.shields.io/badge/license-MIT-blue)
![PSVersion](https://img.shields.io/badge/PSVersion-5.1%2C7.0+-brightgreen)
![Build Status](https://github.com/gabrielschoenardie/instagram_encoder/actions/workflows/ci.yml/badge.svg)

**Conversor gráfico em PowerShell para gerar vídeos otimizados para Instagram (Reels 9:16, H.264, CRF 17, barra de progresso, etc.)**

---

## 📌 Sobre

O **Instagram Encoder** foi criado para simplificar o workflow de criadores de conteúdo que precisam converter vídeos em lote para o formato padrão de **Reels** no Instagram.  
Ele oferece:

- **Interface Windows Forms** totalmente em PowerShell, com design limpo e responsivo.  
- **Suporte a CRF (Qualidade Constante)** ou **2-pass (Controle de Bitrate)**.  
- **Corte automático** para vídeos com até 59 segundos (padrão Instagram).  
- **Filtro de escala inteligente** (vertical 9:16 ou horizontal 16:9) com `lanczos` e `format=yuv420p`.  
- **Áudio AAC 48 kHz, estéreo** (2 canais).  
- **Logging automático** em pasta `ffmpeg_logs` para cada arquivo convertido.  

Este projeto é ideal para quem deseja uma solução “tudo em um” para converter vídeos com qualidade cinematográfica para Instagram, sem depender de programas externos ou interfaces pesadas.

---

## 🚀 Começando

### 🔧 Pré-requisitos

1. **Windows 10/11 (64-bit)** com PowerShell **5.1+** ou **PowerShell 7+** instalado.  
2. **FFmpeg** instalado e disponível no `PATH` do sistema.  
   - Recomenda-se baixar a versão estável mais recente em [ffmpeg.org](https://ffmpeg.org/).  
3. **Permissões** para criar pastas e arquivos no diretório onde o script será executado.  
4. **Codificação UTF-8 sem BOM** no arquivo principal (`InstagramEncoder.ps1`).  
   - Veja [Como salvar em UTF-8 sem BOM](#como-salvar-em-utf-8-sem-bom).

### 📥 Instalação

1. Abra um terminal PowerShell e clone este repositório:
   ```powershell
   git clone https://github.com/gabrielschoenardie/instagram_encoder.git
   cd instagram_encoder
