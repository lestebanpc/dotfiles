--
-- Configuration file hyprland
-- Docs:
-- > https://wiki.hypr.land/Configuring/Start/
-- > https://github.com/hyprwm/Hyprland
--

--local mm_ucommon = require("utils.common")

------------------------------------------------------------------------------------
-- Post-Autostart
------------------------------------------------------------------------------------

require("utils.configs")
require("utils.monitors")
require("utils.envs")



------------------------------------------------------------------------------------
-- Autostart
------------------------------------------------------------------------------------

hl.on("hyprland.start", function()

    -- Las variables de entorno existentes (hasta el momento) en hyperland las propaga en el D-BUS y en SystemD
    -- del usuario. Esto no sincroniza las variables de entorno de procesos (unidades systemd, programas) iniciados
    -- o creados antes de esta sentencia.
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")

    -- Activar el target 'hyprland-session.target' el cual internamente activa el target 'graphical-session.target'.
    -- Ello permite unidades systemd que dependan que este target esta activo ya se puedan inicializar, por ejemplo:
    -- Polkit, Barras de Quickshell, programas marcadas por inicio automatico (XGD AutoStart, exec-once de GUI, etc).
    hl.exec_cmd("systemctl --user start hyprland-session.target")

end)


------------------------------------------------------------------------------------
-- Post-Autostart
------------------------------------------------------------------------------------

require("utils.workspace_rules")
require("utils.window_rules")
require("utils.binds")
