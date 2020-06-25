#!/usr/bin/env bash

SONAR_TOKEN=$1

if [ $# -eq 0 ]
  then
    echo "Informe o token do projeto no sonar"
fi

source target/sonar/report-task.txt

COMANDO=$(curl -f -u ${SONAR_TOKEN}: $ceTaskUrl --silent --raw )
if [ $? -eq 0 ]; then
    echo 
else
    echo Ocorreu algum erro ao executar a analise do sonar, verifique o token informado.
    exit 1
fi

set -e
STATUS_TASK=$(curl -f -u ${SONAR_TOKEN}: --raw --silent $ceTaskUrl | jq -r .task.status)


while [[ "$STATUS_TASK" != "PENDING"  ||  "$STATUS_TASK" != "IN_PROGRESS" ]];
do
    echo "verificando o quality gate do projeto..."
    STATUS_TASK=$(curl -u ${SONAR_TOKEN}: --raw --silent $ceTaskUrl | jq -r .task.status)
    sleep 3

    if [[ "$STATUS_TASK" == "FAILED" || "$STATUS_TASK" == "CANCELED" ]]; then
        echo 
        echo "Ocorreu algum erro na analise do quality gate. Para maiores detalhes acesse o dashboard do projeto em: $dashboardUrl"
        echo 
        echo "FALHA NA ANALISE"
        echo
        exit 1
    fi

    if [ "$STATUS_TASK" == "SUCCESS" ]; then
        ANALYSIS_ID=$(curl -u ${SONAR_TOKEN}: --raw --silent $ceTaskUrl | jq -r .task.analysisId)
        
        ANALYSIS_STATUS=$(curl -u ${SONAR_TOKEN}: --raw --silent "${serverUrl}/api/qualitygates/project_status?analysisId=${ANALYSIS_ID}" | jq -r .projectStatus.status)

        if [ "$ANALYSIS_STATUS" == "ERROR" ]; then
            echo 
            echo "O projeto NÃO ATENDEU ao quality gate. Para maiores detalhes acesse o dashboard do projeto em: $dashboardUrl"
            echo 
            echo "FALHOU"
            echo
            exit 1
        fi

        if [ "$ANALYSIS_STATUS" == "OK" ]; then
            echo 
            echo "O projeto atendeu ao quality gate. Para maiores detalhes acesse o dashboard do projeto em:$dashboardUrl"
            echo
            echo "SUCESSO"
            echo
            exit 0
        fi
    fi
done
