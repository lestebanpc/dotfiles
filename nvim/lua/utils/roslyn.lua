-- Obtenido de 'https://github.com/seblyng/roslyn.nvim/blob/main/lua/roslyn/'
local M = {}


local m_is_debug_mode = false

-- Whether or not to look for solution files in the child of the (root).
-- Set this to true if you have some projects that are not a child of the
-- directory with the solution file
local m_broad_search = false

-- Whether or not to lock the solution target after the first attach.
-- This will always attach to the target in `vim.g.roslyn_nvim_selected_solution`.
-- NOTE: You can use `:Roslyn target` to change the target
local m_lock_target = false

-- Function that takes an array of targets as the only argument. Return the target you
-- want to use. If it returns `nil`, then it falls back to guessing the target like normal
local m_choose_target = nil


-- function that takes the selected target as the only argument.
-- Returns a boolean of whether it should be ignored to attach to or not
local m_ignore_target = nil


local m_iswin = vim.g.os_type == 0
local m_log_file = vim.fs.joinpath(vim.fn.stdpath("state"), "roslyn.log")



local function log(msg)

    if m_is_debug_mode then
        return
    end

    local f = io.open(m_log_file, "a")
    if f then
        local ts = os.date("%Y-%m-%d %H:%M:%S")
        f:write(string.format("[%s] %s\n", ts, msg))
        f:close()
    end

end


local function find_solutions(bufnr)

    local results = vim.fs.find(
        function(name)
            return name:match("%.sln$") or name:match("%.slnx$") or name:match("%.slnf$")
        end,
        {
            upward = true,
            path = vim.api.nvim_buf_get_name(bufnr),
            limit = math.huge
        }
    )

    log(string.format("find_solutions found: %s", vim.inspect(results)))
    return results

end


--- Attempts to extract the project path from a line in a solution file
---@param line string
---@param target string
---@return string? path The path to the project file
local function sln_match(line, target)

    local ext = vim.fn.fnamemodify(target, ":e")

    if ext == "sln" then
        local id, name, path = line:match('Project%("{(.-)}"%).*= "(.-)", "(.-)", "{.-}"')
        if id and name and path and path:match("%.csproj$") then
            return path
        end
    elseif ext == "slnx" then
        local path = line:match('<Project Path="([^"]+)"')
        if path and path:match("%.csproj$") then
            return path
        end
    elseif ext == "slnf" then
        return line:match('"(.*%.csproj)"')
    else
        error(string.format("Unknown extension `%s` for solution: `%s`", ext, target))
    end

end


---@param target string Path to solution or solution filter file
---@return string[] Table of projects in given solution
local function get_projects(target)

    local file = io.open(target, "r")
    if not file then
        return {}
    end

    local paths = {}

    for line in file:lines() do
        local path = sln_match(line, target)
        if path then
            local normalized_path = m_iswin and path or path:gsub("\\", "/")
            local dirname = vim.fs.dirname(target)
            local fullpath = vim.fs.joinpath(dirname, normalized_path)
            local normalized = vim.fs.normalize(fullpath)
            table.insert(paths, normalized)
        end
    end

    file:close()

    return paths

end


---Checks if a project is part of a solution/solution filter or not
---@param target string Path to the solution or solution filter
---@param project string Full path to the project's csproj file
---@return boolean
local function exists_in_target(target, project)

    local prjs = get_projects(target)

    local results = vim.iter(prjs):find(
        function(it)
            return it == project
        end
    )

    return results ~= nil

end



---@param targets string[]
---@param csproj string
---@return string[]
local function filter_targets(targets, csproj)

    local results = vim.iter(targets)
        :filter(function(target)
            if m_ignore_target and m_ignore_target(target) then
                return false
            end

            return not csproj or exists_in_target(target, csproj)
        end)
        :totable()

    return results

end



---@param bufnr number
---@param solutions string[]
---@param preselected_sln string?
local function get_root_directory(bufnr, solutions, preselected_sln)

    log(string.format("root_dir solutions: %s, preselected_sln: %s", vim.inspect(solutions), preselected_sln))
    if #solutions == 1 then
        local result = vim.fs.dirname(solutions[1])
        log(string.format("root_dir single solution result: %s", result))
        return result
    end

    local csproj = vim.fs.find(
        function(name)
            return name:match("%.csproj$") ~= nil
        end,
        {
            upward = true,
            path = vim.api.nvim_buf_get_name(bufnr)
        }
    )[1]

    local filtered_targets = filter_targets(solutions, csproj)
    if #filtered_targets > 1 then

        local chosen = m_choose_target and m_choose_target(filtered_targets)
        if chosen then
            local result = vim.fs.dirname(chosen)
            log(string.format("root_dir chosen result: %s", result))
            return result
        end

        if preselected_sln and vim.list_contains(filtered_targets, preselected_sln) then
            local result = vim.fs.dirname(preselected_sln)
            log(string.format("root_dir preselected result: %s", result))
            return result
        end

        log("root_dir: Multiple potential target files found. Use :Roslyn target to select a target.")
        vim.notify(
            "Multiple potential target files found. Use `:Roslyn target` to select a target.",
            vim.log.levels.INFO,
            { title = "roslyn.nvim" }
        )

        return nil


    end

    local selected_solution = vim.g.roslyn_nvim_selected_solution
    local result = vim.fs.dirname(filtered_targets[1])
        or selected_solution and vim.fs.dirname(selected_solution)
        or csproj and vim.fs.dirname(csproj)

    log(
        string.format(
            "root_dir fallback result: %s, selected solution: %s, csproj: %s",
            result,
            selected_solution,
            csproj
        )
    )

    return result

end


---@param buffer number
local function resolve_broad_search_root(buffer)
    local sln_root = vim.fs.root(buffer,
        function(fname, _)
            return fname:match("%.sln$") ~= nil or fname:match("%.slnx$") ~= nil
        end
    )

    local git_root = vim.fs.root(buffer, ".git")
    if sln_root and git_root then
        return git_root and sln_root:find(git_root, 1, true) and git_root or sln_root
    end

    return sln_root or git_root
end


-- Dirs we are not looking for solutions inside
local ignored_dirs = {
    "obj",
    "bin",
    ".git",
}


local function find_solutions_broad(bufnr)
    local root = resolve_broad_search_root(bufnr)
    local dirs = { root }
    local slns = {} --- @type string[]

    while #dirs > 0 do
        local dir = table.remove(dirs, 1)

        for other, fs_obj_type in vim.fs.dir(dir) do
            local name = vim.fs.joinpath(dir, other)

            if fs_obj_type == "file" then
                if name:match("%.sln$") or name:match("%.slnx$") or name:match("%.slnf$") then
                    slns[#slns + 1] = vim.fs.normalize(name)
                end
            elseif fs_obj_type == "directory" and not vim.list_contains(ignored_dirs, vim.fs.basename(name)) then
                dirs[#dirs + 1] = name
            end
        end
    end

    log(string.format("find_solutions_broad root: %s, found: %s", root, vim.inspect(slns)))
    return slns
end


function M.get_root_dir(bufnr, on_dir)

    local solutions = nil
    if m_broad_search then
        solutions = find_solutions_broad(bufnr)
    else
        solutions = find_solutions(bufnr)
    end

    local root_dir = get_root_directory(bufnr, solutions, vim.g.roslyn_nvim_selected_solution)
    log(string.format("lsp root_dir is: %s", root_dir))

    on_dir(root_dir)

end


local function init_sln(client, solution)
    vim.g.roslyn_nvim_selected_solution = solution
    vim.notify("Initializing Roslyn for: " .. solution, vim.log.levels.INFO, { title = "roslyn.nvim" })
    client:notify("solution/open", {
        solution = vim.uri_from_fname(solution),
    })
end

local function init_projects(client, projects)
    vim.notify("Initializing Roslyn for: projects", vim.log.levels.INFO, { title = "roslyn.nvim" })
    client:notify("project/open", {
        projects = vim.tbl_map(function(file)
            return vim.uri_from_fname(file)
        end, projects),
    })
end


--- Searches for files with a specific extension within a directory.
--- Only files matching the provided extension are returned.
---
--- @param dir string The directory path for the search.
--- @param extensions string[] The file extensions to look for (e.g., ".sln").
---
--- @return string[] List of file paths that match the specified extension.
local function find_files_with_extensions(dir, extensions)
    local matches = {}

    log(string.format("find_files_with_extensions dir: %s, extensions: %s", dir, vim.inspect(extensions)))

    for entry, type in vim.fs.dir(dir) do
        if type == "file" then
            for _, ext in ipairs(extensions) do
                if vim.endswith(entry, ext) then
                    matches[#matches + 1] = vim.fs.normalize(vim.fs.joinpath(dir, entry))
                end
            end
        end
    end

    return matches
end


---@param bufnr number
---@param targets string[]
---@return string?
local function predict_target(bufnr, targets)

    local csproj = vim.fs.find(
        function(name)
            return name:match("%.csproj$") ~= nil
        end,
        {
            upward = true,
            path = vim.api.nvim_buf_get_name(bufnr)
        }
    )[1]

    local filtered_targets = filter_targets(targets, csproj)
    local result
    if #filtered_targets > 1 then
        result = m_choose_target and m_choose_target(filtered_targets) or nil
    else
        result = filtered_targets[1]
    end

    log(string.format("predict_target targets: %s, result: %s", vim.inspect(targets), result))
    return result

end



function M.on_init(client)

    if not client.config.root_dir then
        return
    end

    log(string.format("lsp on_init root_dir: %s", client.config.root_dir))

    local selected_solution = vim.g.roslyn_nvim_selected_solution
    if m_lock_target and selected_solution then
        return init_sln(client, selected_solution)
    end

    local files = find_files_with_extensions(client.config.root_dir, { ".sln", ".slnx", ".slnf" })

    local bufnr = vim.api.nvim_get_current_buf()
    local solution = predict_target(bufnr, files)
    if solution then
        return init_sln(client, solution)
    end

    local csproj = find_files_with_extensions(client.config.root_dir, { ".csproj" })
    if #csproj > 0 then
        return init_projects(client, csproj)
    end

    if selected_solution then
        return init_sln(client, selected_solution)
    end

end


local m_events = {
    events = {},
}



local function event_off(event, callback)
    if not m_events[event] then
        return
    end
    for i, cb in ipairs(m_events[event]) do
        if cb == callback then
            table.remove(m_events[event], i)
            break
        end
    end
end



---@param event "stopped"
local function event_on(event, callback)

    if not m_events[event] then
        m_events[event] = {}
    end

    table.insert(m_events[event], callback)

    return function()
        event_off(event, callback)
    end

end

---@param event "stopped"
local function event_emit(event, ...)
    if m_events[event] then
        for _, callback in ipairs(m_events[event]) do
            callback(...)
        end
    end
end


function M.on_exit()

    vim.g.roslyn_nvim_selected_solution = nil
    vim.schedule(function()
        event_emit("stopped")
        vim.notify("Roslyn server stopped", vim.log.levels.INFO, { title = "roslyn.nvim" })
    end)

end



function M.get_roslyn_handlers()

    local handlers = {}

    handlers['workspace/projectInitializationComplete'] = function(_, _, ctx)
        vim.notify('Roslyn project initialization complete', vim.log.levels.INFO, { title = 'roslyn_ls' })

        local buffers = vim.lsp.get_buffers_by_client_id(ctx.client_id)
        for _, buf in ipairs(buffers) do
            vim.lsp.util._refresh('textDocument/diagnostic', { bufnr = buf })
        end
    end

    handlers['workspace/_roslyn_projectHasUnresolvedDependencies'] = function()
        vim.notify('Detected missing dependencies. Run `dotnet restore` command.', vim.log.levels.ERROR, {
            title = 'roslyn_ls',
        })
        return vim.NIL
    end


    --handlers['workspace/_roslyn_projectNeedsRestore'] = function(_, result, ctx)
    handlers['workspace/_roslyn_projectNeedsRestore'] = function(_, _, _)
        --local client = assert(vim.lsp.get_client_by_id(ctx.client_id))

        -----@diagnostic disable-next-line: param-type-mismatch
        --client:request('workspace/_roslyn_restore', result, function(err, response)
        --    if err then
        --        vim.notify(err.message, vim.log.levels.ERROR, { title = 'roslyn_ls' })
        --    end
        --    if response then
        --        for _, v in ipairs(response) do
        --            vim.notify(v.message, vim.log.levels.INFO, { title = 'roslyn_ls' })
        --        end
        --    end
        --end)

        return vim.NIL
    end


    handlers['workspace/refreshSourceGeneratedDocument'] = function(_, _, ctx)

        local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local uri = vim.api.nvim_buf_get_name(buf)
            if vim.api.nvim_buf_get_name(buf):match("^roslyn%-source%-generated://") then
                local function handler(err, result)
                    assert(not err, vim.inspect(err))
                    if vim.b[buf].resultId == result.resultId then
                        return
                    end
                    local content = result.text
                    if content == nil then
                        content = ""
                    end
                    local normalized = string.gsub(content, "\r\n", "\n")
                    local source_lines = vim.split(normalized, "\n", { plain = true })
                    vim.bo[buf].modifiable = true
                    vim.api.nvim_buf_set_lines(buf, 0, -1, false, source_lines)
                    vim.b[buf].resultId = result.resultId
                    vim.bo[buf].modifiable = false
                end

                local params = {
                    textDocument = {
                        uri = uri,
                    },
                    resultId = vim.b[buf].resultId,
                }

                client:request("sourceGeneratedDocument/_roslyn_getText", params, handler, buf)
            end

        end

    end


    handlers['razor/provideDynamicFileInfo'] = function(_, _, _)
        vim.notify(
            'Razor is not supported.\nPlease use https://github.com/tris203/rzls.nvim',
            vim.log.levels.WARN,
            { title = 'roslyn_ls' }
        )
        return vim.NIL
    end

    return handlers

end


---@class RoslynCodeAction
---@field title string
---@field code_action table


---@return RoslynCodeAction
local function get_code_actions(nested_code_actions)
    return vim.iter(nested_code_actions)
        :map(function(it)
            local code_action_path = it.data.CodeActionPath
            local fix_all_flavors = it.data.FixAllFlavors

            if #code_action_path == 1 then
                return {
                    title = code_action_path[1],
                    code_action = it,
                }
            end

            local title = table.concat(code_action_path, " -> ", 2)
            return {
                title = fix_all_flavors and string.format("Fix All: %s", title) or title,
                code_action = it,
            }
        end)
        :totable()
end

local function handle_fix_all_code_action(client, data)
    local flavors = data.arguments[1].FixAllFlavors
    vim.ui.select(flavors, { prompt = "Pick a fix all scope:" }, function(flavor)
        client:request("codeAction/resolveFixAll", {
            title = data.title,
            data = data.arguments[1],
            scope = flavor,
        }, function(err, response)
            if err then
                vim.notify(err.message, vim.log.levels.ERROR, { title = "roslyn.nvim" })
            end
            if response and response.edit then
                vim.lsp.util.apply_workspace_edit(response.edit, client.offset_encoding)
            end
        end)
    end)
end

local function best_cursor_pos(lines, start_row, start_col)
    local target_i, col

    for i = #lines, 1, -1 do
        local line = lines[i]
        for j = #line, 1, -1 do
            if not line:sub(j, j):match("[%s(){}]") then
                target_i = i + 1
                col = j
                break
            end
        end
        if target_i then
            break
        end
    end

    -- Fallback position if somehow not found
    if not target_i then
        target_i = #lines
        col = #lines[target_i] or 0
    end

    local row = start_row + target_i - 1
    if target_i == 1 then
        col = start_col + col
    end

    return { row, col }
end


function M.get_roslyn_commands()
    local commands = {}

    commands["roslyn.client.fixAllCodeAction"] = function(data, ctx)
        local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
        handle_fix_all_code_action(client, data)
    end

    commands["roslyn.client.nestedCodeAction"] = function(data, ctx)
        local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
        local args = data.arguments[1]
        local code_actions = get_code_actions(args.NestedCodeActions)
        local titles = vim.iter(code_actions)
            :map(function(it) return it.title end)
            :totable()

        vim.ui.select(titles,
            { prompt = args.UniqueIdentifier },
            function(selected)
                local action = vim.iter(code_actions):find(function(it)
                    return it.title == selected
                end) --[[@as RoslynCodeAction]]

                if action.code_action.data.FixAllFlavors then
                    handle_fix_all_code_action(client, action.code_action.command)
                else
                    client:request("codeAction/resolve",
                        {
                            title = action.code_action.title,
                            data = action.code_action.data,
                            ---@diagnostic disable-next-line: param-type-mismatch
                        },
                        function(err, response)
                            if err then
                                vim.notify(err.message, vim.log.levels.ERROR, { title = "roslyn.nvim" })
                            end
                            if response and response.edit then
                                vim.lsp.util.apply_workspace_edit(response.edit, client.offset_encoding)
                            end
                        end)
                end
            end)
    end

    commands["roslyn.client.completionComplexEdit"] = function(data)
        local arguments = data.arguments
        local uri = arguments[1].uri
        local edit = arguments[2]
        local bufnr = vim.uri_to_bufnr(uri)

        if not vim.api.nvim_buf_is_loaded(bufnr) then
            vim.fn.bufload(bufnr)
        end

        local start_row = edit.range.start.line
        local start_col = edit.range.start.character
        local end_row = edit.range["end"].line
        local end_col = edit.range["end"].character

        -- It's possible to get corrupted line endings in the newText from the LSP
        -- Somehow related to typing fast
        -- Notification(int what)\r\n    {\r\n        base._Notification(what);\r\n    }\r\n\r\n\r
        local newText = edit.newText:gsub("\r\n", "\n"):gsub("\r", "")
        local lines = vim.split(newText, "\n")

        vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, lines)

        local final_line = start_row + #lines - 1
        local final_line_text = vim.api.nvim_buf_get_lines(bufnr, final_line, final_line + 1, false)[1]

        -- Handle auto-inserted parentheses
        -- "}" or ";" followed only by at least one of "(", ")", or whitespace at the end of the line
        if final_line_text:match("[};][()%s]+$") then
            local new_final_line_text = final_line_text:gsub("([};])[()%s]+$", "%1")
            lines[#lines] = new_final_line_text
            vim.api.nvim_buf_set_lines(bufnr, final_line, final_line + 1, false, { new_final_line_text })
        end

        vim.api.nvim_win_set_cursor(0, best_cursor_pos(lines, start_row, start_col))
    end

    return commands

end


-- https://github.com/seblyng/roslyn.nvim/blob/main/lua/roslyn/commands.lua
-- https://github.com/seblyng/roslyn.nvim/blob/main/lua/roslyn/init.lua

local function create_vim_commands()

end


function M.setup(p_is_debug_mode, p_broad_search, p_lock_target, p_choose_target, p_ingnore_target)

    m_is_debug_mode = p_is_debug_mode
    m_broad_search = p_broad_search
    m_lock_target = p_lock_target
    m_choose_target = p_choose_target
    m_ignore_target = p_ingnore_target

    create_vim_commands()

end



return M
