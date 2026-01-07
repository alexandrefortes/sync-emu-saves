# sync-emu-saves - Steam Deck + Rclone

* Instalação do rclone no Steam Deck
* Configuração do Google Drive com **client_id próprio**
* Estrutura e funcionamento do script `sync-emu-saves.sh`
* Integração com Steam (atalho)
* Logs, erros e decisões de design
* Premissas técnicas do SteamOS

---

Script Bash para **sincronizar saves de emuladores** do Steam Deck com **Google Drive**, usando `rclone`, com logs separados, notificações e execução direta via Steam.

---

Este projeto resolve um problema específico:

* Centralizar **saves de múltiplos emuladores**
* Garantir **backup automático** em nuvem
* Permitir **execução simples via Steam**
* Evitar dependência de interfaces gráficas

---

## Requisitos

### Sistema

* Steam Deck
* SteamOS (modo Desktop)
* Acesso sudo configurado

### Dependências

* `rclone`
* `bash`
* `notify-send` (já vem no SteamOS)

---

## Instalação do Rclone no Steam Deck

O SteamOS é baseado em Arch Linux, mas com filesystem imutável.
A abordagem correta é **instalação manual no `$HOME**`.

### 1. Entrar no Desktop Mode

Steam → Power → Switch to Desktop

---

### 2. Baixar o rclone (binário oficial)

Abra o **Konsole**:

```bash
cd ~
curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
unzip rclone-current-linux-amd64.zip

```

---

### 3. Instalar localmente (sem tocar no sistema)

```bash
mkdir -p ~/bin
mv rclone-*-linux-amd64/rclone ~/bin/
chmod +x ~/bin/rclone

```

---

### 4. Adicionar ao PATH

```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

```

Verificação:

```bash
rclone version

```

---

## Configuração do Google Drive (Client ID Próprio)

Evita rate limit e dependência do client compartilhado do rclone.

### 1. Criar OAuth Client no Google Cloud

* Ativar **Google Drive API**
* Criar OAuth Client → *Desktop App*
* Guardar:
* `client_id`
* `client_secret`

---

### 2. Configurar o remote no rclone

```bash
rclone config

```

Fluxo recomendado:

* Storage: `drive`
* client_id: **seu**
* client_secret: **seu**
* Scope: `drive`
* Auto config: **yes**
* Shared Drive: conforme necessidade

---

### 3. Nome do remote

Escolha o que quiser. No meu caso:

```text
google-drive:

```

Se mudar, ajuste no script.

---

## Instalação do Script

### 1. Criar estrutura e arquivo

```bash
mkdir -p ~/Games/sync-emu-saves
touch ~/Games/sync-emu-saves/sync-emu-saves.sh

```

### 2. Permissão de execução

Essencial para o atalho da Steam funcionar:

```bash
chmod +x ~/Games/sync-emu-saves/sync-emu-saves.sh

```

---

## Estrutura do Projeto

```text
sync-emu-saves/
├── sync-emu-saves.sh
├── sync-last-success.log
├── sync-last-error.log
└── sync_current_run.log

```

---

## Emuladores e Saves

O script foi desenhado para **saves locais**, não estados voláteis.

Exemplos comuns no Steam Deck:

```text
~/.var/app/org.DolphinEmu.dolphin-emu/data/dolphin-emu/GC/
~/.config/PCSX2/memcards/
~/.var/app/net.rpcs3.RPCS3/config/rpcs3/dev_hdd0/home/

```

Esses caminhos são definidos **explicitamente no script**.

---

## Funcionamento do Script

### Fluxo lógico

1. Sanitiza ambiente (`LD_PRELOAD`)
2. Define locale, cores e logs
3. Analisa item (detecta se é arquivo ou diretório)
4. Executa `rclone` (copy ou copyto)
5. Analisa código de retorno
6. Move logs conforme sucesso ou erro
7. Dispara notificação
8. Aguarda ENTER (execução via Steam)

---

### Logs

| Arquivo | Função |
| --- | --- |
| `sync_current_run.log` | Execução corrente |
| `sync-last-success.log` | Última execução OK |
| `sync-last-error.log` | Última execução com erro |

---

## Flags de Rclone (Escolhas Deliberadas)

O script **não usa flags agressivas por padrão**.

Premissas:

* Evitar risco de deleção acidental
* Priorizar consistência

---

## Integração com Steam (atalho)

### Criar atalho manual

Steam → Add Non-Steam Game → Browse

Configuração:

| Campo | Valor |
| --- | --- |
| Target | `konsole` |
| Start in | `/home/deck/Games/sync-emu-saves/` |
| Launch options | `-e "./sync-emu-saves.sh"` |

---

### Por que Konsole?

* Mantém stdout visível
* Permite ENTER final
* Evita execução “cego”
* Fácil

---

## Notificações

Usa:

```bash
notify-send "Sync OK" "Saves atualizados!"
notify-send "Sync Falhou" "Verifique o log de erro."

```

Funciona tanto em Desktop quanto Game Mode.

---

## Segurança

* Tokens ficam em `~/.config/rclone/rclone.conf`
* Pode ser criptografado com `rclone config` → `s`
* Script não imprime tokens
* Logs não contêm credenciais

---

## Limitações Conhecidas

* Não resolve conflitos bidirecionais
* Google Drive pode duplicar arquivos
* Emuladores Flatpak mudam paths entre versões

Aceitas por design.

---

## Uso Recomendado

* Executar **após sessão longa de jogo**
* Executar **antes de trocar de dispositivo**

Não rodar automaticamente em boot.

---

## Licença

Uso pessoal.
Sem garantias implícitas.
