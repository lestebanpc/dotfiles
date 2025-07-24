-- Miembros privado del modulo que ser modificado por el usario del modulo
local m_config = {

    -- Parametros usados para listar los parametros de zoxide
    zoxide_args = {},
}


-- Miembros privados de uso interno
local mm_wezterm = require("wezterm")
local m_waction = mm_wezterm.action
local m_wmux = mm_wezterm.mux

local mm_ucommon = require("utils.commom")

-- Determinar el tipo de SO
--   0 > Si es Linux
--   1 > Si es Windows
--   2 > Si es MacOS (Apple Silicon)
--   3 > Si es MacOS (Intel)
local m_os_type = mm_ucommon.get_os_type()


---@field m_zoxide_path string
local m_zoxide_path = "zoxide"

---@field m_choices {get_zoxide_elements: (fun(choices: InputSelector_choices, opts: choice_opts?): InputSelector_choices), get_workspace_elements: (fun(choices: InputSelector_choices): (InputSelector_choices, workspace_ids))}
local m_choices = {}

---@param label string
---@return string
local function m_workspace_formatter(label)
    return mm_wezterm.format({
        { Text = "󱂬 : " .. label },
	})
end

---@alias action_callback any
---@alias MuxWindow any
---@alias Pane any

---@alias workspace_ids table<string, boolean>
---@alias choice_opts {extra_args?: string, workspace_ids?: workspace_ids}
---@alias InputSelector_choices { id: string, label: string }[]

-- Miembros publicos del modulo
---@class public_module
local mod = {}


function mod.setup(p_zoxide_args)

    if p_zoxide_args ~= nil then
        m_config.zoxide_args = p_zoxide_args
    end

end


---@param cmd string
---@return string
local function run_child_process(cmd)

	local process_args = { os.getenv("SHELL"), "-c", cmd }

    -- Si es Windows
	if m_os_type == 1 then
		process_args = { "cmd", "/c", cmd }
	end
	local success, stdout, stderr = mm_wezterm.run_child_process(process_args)

	if not success then
		mm_wezterm.log_error("Child process '" .. cmd .. "' failed with stderr: '" .. stderr .. "'")
	end
	return stdout

end

---@param choice_table InputSelector_choices
---@return InputSelector_choices, workspace_ids
function m_choices.get_workspace_elements(choice_table)
	local workspace_ids = {}
	for _, workspace in ipairs(m_wmux.get_workspace_names()) do
		table.insert(choice_table, {
			id = workspace,
			label = m_workspace_formatter(workspace),
		})
		workspace_ids[workspace] = true
	end
	return choice_table, workspace_ids
end

---@param choice_table InputSelector_choices
---@param opts? choice_opts
---@return InputSelector_choices
function m_choices.get_zoxide_elements(choice_table, opts)
	if opts == nil then
		opts = { extra_args = "", workspace_ids = {} }
	end

	local stdout = run_child_process(m_zoxide_path .. " query -l " .. (opts.extra_args or ""))

	for _, path in ipairs(mm_wezterm.split_by_newlines(stdout)) do
		local updated_path = string.gsub(path, mm_wezterm.home_dir, "~")
		if not opts.workspace_ids[updated_path] then
			table.insert(choice_table, {
				id = path,
				label = updated_path,
			})
		end
	end
	return choice_table
end

---Returns choices for the InputSelector
---@param opts? choice_opts
---@return InputSelector_choices
function mod.get_choices(opts)
	if opts == nil then
		opts = { extra_args = "" }
	end
	---@type InputSelector_choices
	local choices = {}
	choices, opts.workspace_ids = m_choices.get_workspace_elements(choices)
	choices = m_choices.get_zoxide_elements(choices, opts)
	return choices
end

---@param workspace string
---@return MuxWindow
local function get_current_mux_window(workspace)
	for _, mux_win in ipairs(m_wmux.all_windows()) do
		if mux_win:get_workspace() == workspace then
			return mux_win
		end
	end
	error("Could not find a workspace with the name: " .. workspace)
end

---Check if the workspace exists
---@param workspace string
---@return boolean
local function workspace_exists(workspace)
	for _, workspace_name in ipairs(m_wmux.get_workspace_names()) do
		if workspace == workspace_name then
			return true
		end
	end
	return false
end

---InputSelector callback when zoxide supplied element is chosen
---@param window MuxWindow
---@param pane Pane
---@param path string
---@param label_path string
local function zoxide_chosen(window, pane, path, label_path)
	window:perform_action(
		m_waction.SwitchToWorkspace({
			name = label_path,
			spawn = {
				label = "Workspace: " .. label_path,
				cwd = path,
			},
		}),
		pane
	)
	-- increment zoxide path score
	run_child_process(m_zoxide_path .. " add " .. path)
end

---InputSelector callback when workspace element is chosen
---@param window MuxWindow
---@param pane Pane
---@param workspace string
---@param label_workspace string
local function workspace_chosen(window, pane, workspace, label_workspace)
	window:perform_action(
		m_waction.SwitchToWorkspace({
			name = workspace,
		}),
		pane
	)
end

---@return action_callback
function mod.callback_chose_workspace(window, pane)

    local choices = mod.get_choices(m_config.zoxide_args)

    window:perform_action(
    	m_waction.InputSelector({
    		action = mm_wezterm.action_callback(function(inner_window, inner_pane, id, label)
    			if id and label then

    				if workspace_exists(id) then
    					-- workspace is choosen
    					workspace_chosen(inner_window, inner_pane, id, label)
    				else
    					-- path is choosen
    					zoxide_chosen(inner_window, inner_pane, id, label)
    				end
    			end
    		end),
    		title = "Choose Workspace",
    		description = "Select a workspace and press Enter = accept, Esc = cancel, / = filter",
    		fuzzy_description = "Workspace to switch: ",
    		choices = choices,
    		fuzzy = true,
    	}),
    	pane
    )

end

function mod.callback_go_to_prev_workspace(window, pane)

    local current_workspace = window:active_workspace()
    local previous_workspace = mm_wezterm.GLOBAL.previous_workspace

    if current_workspace == previous_workspace or previous_workspace == nil then
    	return
    end

    mm_wezterm.GLOBAL.previous_workspace = current_workspace

    window:perform_action(
    	m_waction.SwitchToWorkspace({
    		name = previous_workspace,
    	}),
    	pane
    )

end


return mod
