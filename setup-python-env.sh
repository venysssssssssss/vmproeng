#!/bin/bash
# Script para configurar Python 3.11 com pyenv e Poetry
# Uso: ./setup-python-env.sh

set -e

echo "=========================================="
echo "Setup Python 3.11 Environment com Pyenv"
echo "=========================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar se pyenv está instalado
if ! command -v pyenv &> /dev/null; then
    echo -e "${YELLOW}[1/6] Pyenv não encontrado. Instalando...${NC}"
    
    # Instalar dependências
    echo "Instalando dependências do sistema..."
    sudo apt update
    sudo apt install -y make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
        libffi-dev liblzma-dev git
    
    # Instalar pyenv
    echo "Instalando pyenv..."
    curl https://pyenv.run | bash
    
    # Configurar shell
    echo "Configurando shell..."
    if ! grep -q "PYENV_ROOT" ~/.zshrc; then
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
        echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
        echo 'eval "$(pyenv init -)"' >> ~/.zshrc
    fi
    
    # Carregar pyenv
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    
    echo -e "${GREEN}✓ Pyenv instalado com sucesso!${NC}"
else
    echo -e "${GREEN}[1/6] Pyenv já instalado${NC}"
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Verificar versão do Python 3.11
echo ""
echo -e "${YELLOW}[2/6] Verificando Python 3.11...${NC}"
if ! pyenv versions | grep -q "3.11.9"; then
    echo "Instalando Python 3.11.9... (isso pode demorar alguns minutos)"
    pyenv install 3.11.9
    echo -e "${GREEN}✓ Python 3.11.9 instalado!${NC}"
else
    echo -e "${GREEN}✓ Python 3.11.9 já instalado${NC}"
fi

# Configurar versão local
echo ""
echo -e "${YELLOW}[3/6] Configurando Python 3.11.9 para o projeto...${NC}"
cd /home/synev1/dev/vmpro1
pyenv local 3.11.9
echo -e "${GREEN}✓ Python 3.11.9 configurado como versão local${NC}"

# Verificar Poetry
echo ""
echo -e "${YELLOW}[4/6] Verificando Poetry...${NC}"
if ! command -v poetry &> /dev/null; then
    echo "Instalando Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -
    
    # Adicionar ao PATH
    if ! grep -q ".local/bin" ~/.zshrc; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    fi
    export PATH="$HOME/.local/bin:$PATH"
    
    echo -e "${GREEN}✓ Poetry instalado!${NC}"
else
    echo -e "${GREEN}✓ Poetry já instalado${NC}"
fi

# Configurar Poetry
echo ""
echo -e "${YELLOW}[5/6] Configurando Poetry...${NC}"
poetry config virtualenvs.in-project true
poetry config virtualenvs.prefer-active-python true
echo -e "${GREEN}✓ Poetry configurado${NC}"

# Criar ambiente virtual e instalar dependências
echo ""
echo -e "${YELLOW}[6/6] Criando ambiente virtual e instalando dependências...${NC}"
echo "Isso pode demorar alguns minutos..."

# Remover ambiente antigo se existir
if [ -d ".venv" ]; then
    echo "Removendo ambiente virtual antigo..."
    rm -rf .venv
fi

# Criar novo ambiente com Python 3.11
poetry env use python
poetry install --no-root

echo ""
echo -e "${GREEN}=========================================="
echo "✓ Setup concluído com sucesso!"
echo "==========================================${NC}"
echo ""
echo "Para ativar o ambiente virtual, execute:"
echo -e "${YELLOW}poetry shell${NC}"
echo ""
echo "Ou recarregue o shell:"
echo -e "${YELLOW}exec zsh${NC}"
echo ""
echo "Versão do Python:"
poetry run python --version
echo ""
echo "Para verificar as dependências instaladas:"
echo -e "${YELLOW}poetry show${NC}"
