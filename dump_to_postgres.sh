#!/usr/bin/env bash
# =====================================================================
# Script: restore_db.sh
# Objetivo: baixar, mover, criar, apagar e restaurar banco de dados PostgreSQL
# via Docker
# =====================================================================

set -e  # parar se ocorrer erro
set -x  # debug

# ================================
# Função de log
# ================================
log() {
    echo -e "\n👉 $1\n"
}

# ================================
# Função ProgressBar
# ================================
ProgressBar() {
    local current=$1
    local total=$2
    local msg=$3
    local progress=$(( current * 100 / total ))
    local done=$(( progress * 40 / 100 ))
    local left=$((40 - done))
    local fill=$(printf "%${done}s" | tr ' ' '#')
    local empty=$(printf "%${left}s" | tr ' ' '-')
    printf "\rProgresso : [%s%s] %d%% %s" "$fill" "$empty" "$progress" "$msg"
}

# ================================
# Entrada de parâmetros
# ================================
# 1º parâmetro: tipo do arquivo (dump/sql)
if [[ -z "$1" ]]; then
    read -p "O arquivo é dump ou sql: " resp2
else
    if [[ "$1" =~ dump|sql ]]; then
        resp2=$1
    else
        echo "Tipo inválido. Saindo."
        exit 1
    fi
fi

# 2º parâmetro: nome do arquivo / banco
if [[ -z "$2" ]]; then
    read -p "Digite o nome do arquivo (será o mesmo nome do banco): " nome_arquivo
else
    nome_arquivo=$2
fi

# 3º parâmetro: opções (1-7)
if [[ -z "$3" ]]; then
    echo "Digite os números das operações desejadas (ex: 235):"
    echo "1 - Baixar arquivo do servidor"
    echo "2 - Descompactar"
    echo "3 - Mover para pasta Docker"
    echo "4 - Apagar banco de dados"
    echo "5 - Criar banco de dados"
    echo "6 - Restaurar banco"
    echo "7 - Setar senha '123'"
    read -p "Opções: " resp
else
    resp=$3
fi

# ================================
# Variáveis
# ================================
usuario="uilton"
userlocal="postgres"
server="localhost"
app="postgres"
docker_data="/var/lib/postgresql/data"
docker_volumes="/home/uilton/projetos/docker/volumes/PostgreSQL"
nome_banco=$nome_arquivo

# ================================
# Contador progress bar
# ================================
start=1
total=${#resp}

# ================================
# Funções para cada passo
# ================================

baixar_arquivo() {
    ProgressBar $start $total "Baixando arquivo do servidor..."
    ((start++))
    scp -p $usuario@10.142.142.208:/tmp/$nome_arquivo.tar.gz $nome_arquivo.tar.gz
}

descompactar() {
    ProgressBar $start $total "Descompactando arquivo..."
    ((start++))
    tar -xvf $nome_arquivo.tar.gz $nome_arquivo
}

mover_para_docker() {
    ProgressBar $start $total "Movendo arquivo para pasta Docker..."
    ((start++))
    sudo cp "$nome_arquivo.$resp2" "$docker_volumes/$nome_arquivo.$resp2"
}

apagar_banco() {
    ProgressBar $start $total "Apagando banco de dados..."
    ((start++))
    sudo docker exec $app psql -U $userlocal postgres -c "DROP DATABASE IF EXISTS $nome_banco;"
}

criar_banco() {
    ProgressBar $start $total "Criando banco de dados..."
    ((start++))
    sudo docker exec $app psql -U $userlocal postgres -c "CREATE DATABASE $nome_banco;"
}

restaurar_banco() {
    ProgressBar $start $total "Restaurando banco..."
    ((start++))
    if [[ "$resp2" == "sql" ]]; then
        sudo docker exec -i $app psql -U $userlocal -d $nome_banco < "$docker_data/$nome_arquivo.$resp2"
    else
        sudo docker exec -i $app pg_restore -U $userlocal -Oxv -d $nome_banco "$docker_data/$nome_arquivo.$resp2"
    fi
}

setar_senha() {
    ProgressBar $start $total "Setando senha 123..."
    ((start++))
    # comando SQL seguro
    SQL="UPDATE auth_user SET password='202cb962ac59075b964b07152d234b70';"
    sudo docker exec -i $app psql -U $userlocal -d $nome_banco -c "$SQL"
}

# ================================
# Executar operações
# ================================
[[ $resp == *1* ]] && baixar_arquivo
[[ $resp == *2* ]] && descompactar
[[ $resp == *3* ]] && mover_para_docker
[[ $resp == *4* ]] && apagar_banco
[[ $resp == *5* ]] && criar_banco
[[ $resp == *6* ]] && restaurar_banco
[[ $resp == *7* ]] && setar_senha

# ================================
# Finalização
# ================================
ProgressBar $start $total "Processo finalizado"
echo -e "\n✅ Todas as operações concluídas!"