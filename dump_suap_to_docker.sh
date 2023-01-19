#!/usr/bin/env bash

set -e #o bash deve parar de executar se ocorrer algum erro
# set -x #modo depuração

if [[ -z "$1" ]]; then 
    read -p "O arquivo é dump ou sql: " resp2
else
    if echo "$1" | grep 'dump'; then
        resp2=$1
    else
        if echo "$1" | grep 'sql'; then
            resp2=$1
        else
            exit 0
        fi
    fi
fi

if [[ -z "$2" ]]; then 
    read -p "digite o nome do arquivo(será o mesmo nome do banco): " nome_arquivo
else
    nome_arquivo=$2    
fi

if [[ -z "$3" ]]; then 
    echo "Digire o número correspondente ao serviço que deseja executar"
    echo "1 - Baixar o arquivo do servidor"
    echo "2 - Descompactando"
    echo "3 - Mover arquivo para pastar $docker_volumes"
    echo "4 - Apagar banco de dados $nome_banco"
    echo "5 - Criar banco de dados $nome_banco"
    echo "6 - Restaurar banco ($nome_banco < $nome_arquivo)"
    read -p "digite as opções de 1-5 (ex: 235): " resp
else
    resp=$3    
fi

usuario="uilton"
userlocal="postgres"
nome_banco=$nome_arquivo
app="postgres"
docker_data="/var/lib/postgresql/data"  #pegar esse caminho do doker-composer
docker_volumes="/home/uilton/projetos/docker/volumes/PostgreSQL" #pegar esse caminho do 



if echo "$resp" | grep '1' ;
then
    echo "Baixando o arquivo do servidor"
    scp -p $usuario@10.142.142.208:/tmp/$nome_arquivo.tar.gz $nome_arquivo.tar.gz
fi
if echo "$resp" | grep '2' ; then
    echo "Descompactando"
    tar -xvf $nome_arquivo.tar.gz $nome_arquivo
fi
if echo "$resp" | grep '3' ; then
    echo "mover arquivo pra pasta do Docker"
    sudo cp $nome_arquivo.$resp2 /$docker_volumes/$nome_arquivo.$resp2
fi
if echo "$resp" | grep '4' ; then
    echo "Apagando banco de dados"
    sudo docker exec $app bash -c "psql -U $userlocal postgres -c 'drop DATABASE $nome_banco;'" 
fi
if echo "$resp" | grep '5' ; then
    echo "Criando um novo banco de dados"
    sudo docker exec $app bash -c "psql -U $userlocal postgres -c 'create DATABASE $nome_banco;'"
fi
if echo "$resp" | grep '6' ; then
    echo "restaurando banco"    
    if echo "$resp2" | grep 's' ; then
        sudo docker exec $app bash -c "psql -h localhost -p 5432 -U $userlocal -W -d $nome_banco < '$docker_data/$nome_arquivo.$resp2'"
    fi
    if echo "$resp2" | grep 'd' ; then
        sudo docker exec $app bash -c "pg_restore -U $userlocal -Ox -d $nome_banco  $docker_data/$nome_arquivo.$resp2"
    fi
fi

echo "==========================="
echo "====Processo finalizado===="
echo "==========================="