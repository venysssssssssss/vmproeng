# Setup Python 3.11 com Pyenv

Este guia mostra como configurar Python 3.11 usando pyenv para o projeto.

## 1. Instalar pyenv (se ainda não tiver)

```bash
# Instalar dependências necessárias
sudo apt update
sudo apt install -y make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# Instalar pyenv
curl https://pyenv.run | bash

# Adicionar ao .zshrc
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc

# Recarregar o shell
exec zsh
```

## 2. Instalar Python 3.11.9

```bash
# Instalar Python 3.11.9 (versão estável)
pyenv install 3.11.9

# Verificar instalação
pyenv versions
```

## 3. Configurar Python 3.11 para o projeto

```bash
# Ir para o diretório do projeto
cd /home/synev1/dev/vmpro1

# Definir Python 3.11.9 como versão local do projeto
pyenv local 3.11.9

# Verificar versão
python --version  # Deve mostrar Python 3.11.9
```

## 4. Instalar Poetry (se ainda não tiver)

```bash
# Instalar Poetry
curl -sSL https://install.python-poetry.org | python3 -

# Adicionar ao PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
exec zsh

# Verificar instalação
poetry --version
```

## 5. Configurar Poetry para usar o pyenv

```bash
# Configurar Poetry para usar pyenv python
poetry config virtualenvs.prefer-active-python true

# Criar ambiente virtual com Python 3.11
poetry env use python

# Verificar ambiente
poetry env info
```

## 6. Instalar dependências

```bash
# Instalar todas as dependências
poetry install

# Ou adicionar individualmente
poetry add apache-airflow@2.8.0 \
  apache-airflow-providers-postgres@^5.10.0 \
  pandas@^2.1.4 \
  faker@^22.0.0 \
  sqlalchemy@^1.4.48 \
  psycopg2-binary@^2.9.9 \
  requests@^2.31.0 \
  great-expectations@^0.18.8 \
  pyspark@^3.5.0 \
  python-dotenv@^1.0.0
```

## 7. Ativar ambiente virtual

```bash
# Ativar ambiente Poetry
poetry shell

# Verificar Python dentro do ambiente
python --version  # Deve mostrar Python 3.11.9
```

## Comandos Úteis

```bash
# Ver informações do ambiente
poetry env info

# Listar ambientes virtuais
poetry env list

# Remover ambiente virtual
poetry env remove <nome>

# Atualizar dependências
poetry update

# Ver dependências instaladas
poetry show

# Exportar requirements.txt
poetry export -f requirements.txt --output requirements.txt --without-hashes
```

## Troubleshooting

### Se pyenv não funcionar após instalação:
```bash
# Adicionar manualmente ao .zshrc
nano ~/.zshrc

# Adicionar estas linhas no final:
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Salvar e recarregar
source ~/.zshrc
```

### Se Poetry não encontrar o Python correto:
```bash
# Remover ambiente virtual existente
poetry env remove --all

# Recriar com Python específico
poetry env use $(pyenv which python)
```

### Se houver erro de permissão:
```bash
# Dar permissão de execução
chmod +x ~/.pyenv/bin/pyenv
chmod +x ~/.local/bin/poetry
```
