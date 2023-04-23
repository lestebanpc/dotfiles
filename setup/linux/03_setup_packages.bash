#!/bin/bash


#Inicialización Global {{{

#Funciones generales, determinar el tipo del SO y si es root
. ~/.files/terminal/linux/functions/func_utility.bash

#Variable global pero solo se usar localmente en las funciones
_g_tmp=""

#Determinar la clase del SO
get_os_type
declare -r g_os_type=$?

#Deteriminar el tipo de distribución Linux
if [ $g_os_type -le 10 ]; then
    _g_tmp=$(get_linux_type_id)
    declare -r g_os_subtype_id=$?
    declare -r g_os_subtype_name="$_g_tmp"
    _g_tmp=$(get_linux_type_version)
    declare -r g_os_subtype_version="$_g_tmp"
fi

#Determinar si es root
g_is_root=1
if [ "$UID" -eq 0 -o "$EUID" -eq 0 ]; then
    g_is_root=0
fi


#Variables y funciones para mostrar las opciones dinamicas del menu.



#}}}

#
#La instalación/desintalación de Python
#La instalación/desintalación de NVM y Node.JS
#La instalacion/desintalación VIM-enhanced
#



