#!/bin/bash

# Definição de cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sem cor

TIME=2

echo -e "${YELLOW}Iniciando configuração do servidor SSH...${NC}"
sleep $TIME

echo -e "${YELLOW}Verificando instalação pré-existente do openssh-server..."
sleep $TIME
if command -v sshd >/dev/null 2>&1; then
    echo -e "${YELLOW}Atualizando pacotes do sistema...${NC}"
    sudo apt update && echo -e "${GREEN}Atualização concluída!${NC}" || echo -e "${RED}Erro ao atualizar pacotes!${NC}"
    sleep $TIME

    echo -e "${YELLOW}Instalando openssh-server...${NC}"
    sudo apt install openssh-server -y && echo -e "${GREEN}Instalação concluída!${NC}" || echo -e "${RED}Erro na instalação!${NC}"
    sleep $TIME

    echo -e "${YELLOW}Iniciando servidor SSH...${NC}"
    sudo systemctl start ssh && sudo systemctl status ssh && echo -e "${GREEN}Servidor SSH iniciado com sucesso!${NC}" || echo -e "${RED}Erro ao iniciar o servidor SSH!${NC}"
    sleep $TIME

    echo -e "${GREEN}Servidor SSH instalado e configurado com sucesso!${NC}"
else
    echo "${GREEN}openssh-server já está instalado no seu sistema!${NC}"
    echo "${GREEN}Verifique a instalação executando o comando: ${YELLOW}sudo systemctl status sshd${NC}"
    exit 1
fi