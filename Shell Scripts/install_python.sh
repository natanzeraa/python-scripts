#! /usr/bin/env bash


# VARIAVEIS GLOBAIS
TIME=2
PYTHON_VERSION=$(python3 --version 2>/dev/null)



function install_python() {
        echo -e "\nIniciando instalação..."
        sudo apt install python3 python3-venv python3-pip -y
}



echo "Olá $USER"
sleep $TIME
echo -e "\nVerificando instalação do Python..."



# VERIFICANDO INSTALAÇÃO DO PYTHON NA VERSÃO 3
if command -v python3 &>/dev/null; then
        sleep $TIME
        echo "Python está instalado: $PYTHON_VERSION"
fi



# INSTALA O PYTHON CASO A VERSÃO NÃO EXISTA NO SISTEMA
if [ -z "$PYTHON_VERSION" ]; then
        sleep $TIME
        echo -e "\nPython não está instalado\n"
        read -p "Deseja instalar o prosseguir com a instalação do Python3? S (Sim) ou N (Não): " confirm

        if [ "$confirm" == "S" ]; then
                install_python
        elif [ "$confirm" == "N" ]; then
                echo -e "\nCancelando instalação"
        fi
fi
