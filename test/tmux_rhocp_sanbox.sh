#!/bin/sh

ltime=0.5
lpath='/mnt/e/Work/UContinental/10_Proyectos/97_RHOCP/11_Deployment_SIT'

#Crear la nueva session desvinculada y su ventana principal (ID 0)
tmux new-session -d -s admission -n exec01 -c "${lpath}/psit-sis-admission-srvs"
sleep $ltime

#Ventana 0: Renombrar el nombre del panel principal (ID 0) y ejecutar un comando
#tmux set -p @mytitle "main"
tmux send-keys -t admission 'oc get pod --selector app=sis -n psit-sis-admission-srvs' C-m

#Ventana 0: Dividir el panel principal y cambiarla de nombre
tmux split-window -v -c "${lpath}/psit-sis-admission-srvs"
#tmux set -p @mytitle "auxi"
tmux send-keys -t admission 'oc get pod --selector app=sis -n psit-sis-financial-srvs' C-m

#Ventana 1: Crear la ventana
tmux new-window -n appl-srv -c "${lpath}/psit-sis-admission-srvs"
#tmux set -p @mytitle "main"
tmux send-keys -t admission 'oc get pod --selector program=applicant-srv -n psit-sis-admission-srvs' C-m

#Ventana 2: Crear la ventana
tmux new-window -n acc-mng -c "${lpath}/psit-sis-admission-srvs"
#tmux set -p @mytitle "main"
tmux send-keys -t admission 'oc get pod --selector program=applicant-acc-mng -n psit-sis-admission-srvs' C-m

#Ventana 3: Crear la ventana
tmux new-window -n crm-hspot -c "${lpath}/psit-sis-admission-srvs"
#tmux set -p @mytitle "main"
tmux send-keys -t admission 'oc get pod --selector program=recruitment-crm -n psit-sis-admission-srvs' C-m

#Ventana 4: Crear la ventana
tmux new-window -n adm-paym -c "${lpath}/psit-sis-admission-srvs"
#tmux set -p @mytitle "main"
tmux send-keys -t admission 'oc get pod --selector program=admission-payment -n psit-sis-admission-srvs' C-m

#Ventana 5: Crear la ventana
tmux new-window -n paym-gtw -c "${lpath}/psit-sis-admission-srvs"
#tmux set -p @mytitle "main"
tmux send-keys -t admission 'oc get pod --selector program=payment-gateway -n psit-sis-admission-srvs' C-m

#Ventana 6: Crear la ventana
tmux new-window -n cta-cte -c "${lpath}/psit-sis-financial-srvs"
#tmux set -p @mytitle "main"
tmux send-keys -t admission 'oc get pod --selector program=financial-account -n psit-sis-financial-srvs' C-m

#Selecionar la ventana principal
tmux select-window -t exec01

#Vincular a la session creara
tmux attach -t admission
