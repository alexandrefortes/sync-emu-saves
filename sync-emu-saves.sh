#!/bin/bash

# Steam shortcut
# target: konsole
# start: ./
# start option: -e "/home/deck/Games/sync-emu-saves/sync-emu-saves.sh"

# Fix for Steam Deck "wrong ELF class" noise
unset LD_PRELOAD

# Configura o locale
export LANG=en_US.UTF-8

# Cores
GREEN='\e[1;32m'
RED='\e[1;31m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
NC='\e[0m'

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LOG_TEMP="$SCRIPT_DIR/sync_current_run.log"
LOG_SUCCESS="$SCRIPT_DIR/sync-last-success.log"
LOG_ERROR="$SCRIPT_DIR/sync-last-error.log"

ERRO_DETECTADO=0

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   SYNC INTELIGENTE DE SAVES              ${NC}"
echo -e "${BLUE}==========================================${NC}"
echo "Iniciado em: $(date)" > "$LOG_TEMP"

sync_file() {
    local local_path="$1"
    local remote_path="$2"
    local game_name=$(basename "$local_path")

    echo -e "\n${YELLOW}>> Sincronizando:${NC} $game_name"
    echo "--------------------------------------------" >> "$LOG_TEMP"

    # --- LÓGICA DE DETECÇÃO AUTOMÁTICA ---
    local cmd="copyto" # Padrão: trata como arquivo (File -> File)

    # 1. Se o caminho local existe e é um DIRETÓRIO: usa 'copy'
    if [ -d "$local_path" ]; then
        cmd="copy"
    # 2. Se o caminho local NÃO existe, mas termina com barra (/): trata como diretório
    elif [[ ! -e "$local_path" && "$local_path" == */ ]]; then
        cmd="copy"
    fi
    # Caso contrário (arquivo existente ou caminho novo sem barra), mantém 'copyto'

    # Debug visual (opcional, para você saber o que ele decidiu)
    echo -e "${BLUE}   [Modo detectado]:${NC} $cmd"

    # 1. Nuvem -> Deck
    echo -e "${BLUE}[1/2]${NC} Checando nuvem..."
    # Se o local não existe e é arquivo, o rclone cria.
    rclone $cmd "$remote_path" "$local_path" --update --verbose 2>&1 | tee -a "$LOG_TEMP"
    [ ${PIPESTATUS[0]} -ne 0 ] && ERRO_DETECTADO=1

    # 2. Deck -> Nuvem
    if [ -e "$local_path" ]; then
        echo -e "${BLUE}[2/2]${NC} Subindo para nuvem..."
        rclone $cmd "$local_path" "$remote_path" --update --verbose 2>&1 | tee -a "$LOG_TEMP"
        [ ${PIPESTATUS[0]} -ne 0 ] && ERRO_DETECTADO=1
    else
        echo -e "${RED}⚠️ Arquivo local ainda não existe (apenas download realizado ou falha).${NC}"
    fi
}

# --- LISTA DE JOGOS ---
sync_file "/home/deck/Games/ps1/Gran Turismo 2/SCUS94455.mcr" "google-drive:Games/saves-rclone/SCUS94455.mcr"
sync_file "/home/deck/Games/pcsx2 ops/pcsx2 saves/saves/Gran Turismo 4.ps2/" "google-drive:Games/saves-rclone/Gran Turismo 4.ps2/"
sync_file "/home/deck/Games/pcsx2 ops/pcsx2 saves/saves/Gran Turismo 3.ps2/" "google-drive:Games/saves-rclone/Gran Turismo 3.ps2/"
sync_file "/home/deck/Games/pcsx2 ops/pcsx2 saves/saves/Tourist Trophy.ps2/" "google-drive:Games/saves-rclone/Tourist Trophy.ps2/"
sync_file "/home/deck/Games/Pirata/NFS Most Wanted Redux/nfs 3.04 - Main/SAVE/" "google-drive:Games/saves-rclone/NFS Most Wanted Redux/nfs 3.04 - Main/"

# --- FINALIZAÇÃO ---
echo -e "\n${BLUE}==========================================${NC}"
if [ $ERRO_DETECTADO -eq 0 ]; then
    echo -e "${GREEN}✅ SYNC CONCLUÍDO!${NC}"
    mv "$LOG_TEMP" "$LOG_SUCCESS"
    rm -f "$LOG_ERROR"
    notify-send "Sync OK" "Saves atualizados!" 2>/dev/null
else
    echo -e "${RED}❌ ERRO DETECTADO${NC}"
    mv "$LOG_TEMP" "$LOG_ERROR"
    notify-send "Sync Falhou" "Verifique o log de erro." 2>/dev/null
fi
echo -e "${BLUE}==========================================${NC}"

echo -e "\nPressione [ENTER] para sair."
read
