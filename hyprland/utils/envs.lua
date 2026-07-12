-- Miembros publicos del modulo
local mod = {}

-- Miembros privados de inicializacion (modificables por el usuario del modulo)
--local m_custom = {
--    data_1 = nil,
--}

-- Miembros privados constantes
--local mm_ucommon = require("utils.common")

-- Miembros privados no constantes
--local m_data_2 = nil



------------------------------------------------------------------------------------
-- Module Inicialization
------------------------------------------------------------------------------------

--function mod.setup(
--    p_data_1)
--
--    m_custom.data_1 = p_data_1
--
--end



------------------------------------------------------------------------------------
-- Main Logic
------------------------------------------------------------------------------------
--
-- Variables de entorno
--

-- Dark theme (GTK application)
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("GTK_APPLICATION_PREFER_DARK_THEME", "1")

-- Dark theme (QT6 application)
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

-- Usando el socket del Agente SSH de OpenSSH (se definira fuere de hyperland en 'enviroment.d'
-- > Las unidades socket de systemd habilitados con inicio automatico (ssh-agent.socket, pipewire.socket, etc),
--   usualmente, se inician antes que se inicia hyprland.
-- > Las unidad 'ssh-agent.socket' crea el socket IPC, crea/inicia el 'ssh-agent.service' pero no define la
--   variable de entorno 'SSH_AUTH_SOCK'.
-- > Por algun motivo, el launcher (en quick shell) no obtiene esta la variable de entorno por mas que se sincronize.
--   Por tal motivo, la variable se definira en el archivo '~/.config/environment.d/91-myvars.conf'
--env = SSH_AUTH_SOCK,$XDG_RUNTIME_DIR/ssh-agent.socket
--env = SSH_AUTH_SOCK,/run/user/1000/ssh-agent.socket



------------------------------------------------------------------------------------
--
-- Exportar
--

return mod
