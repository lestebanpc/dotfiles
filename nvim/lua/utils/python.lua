local M = {}


local function get_roots()

    return coroutine.wrap(function()

        -- Directorio de trabajo actual de vim
        local cwd = vim.fn.getcwd()
        coroutine.yield(cwd)

        -- Directorio de trabajo del archivo actual (ventana actual)
        local wincwd = vim.fn.getcwd(0)
        if wincwd ~= cwd then
        coroutine.yield(wincwd)
        end

        -- Obtiene los 'root_dir' de los cliente LSP vinculados al archivo actual
        local get_clients = vim.lsp.get_clients
        for _, client in ipairs(get_clients()) do
            if client.config.root_dir then
                coroutine.yield(client.config.root_dir)
            end
        end

    end)


end


--- Devuelve la ruta de 'python' dentro de un determinado venv asociado al proyecto.
---@return string|nil
function M.get_venv_python_path()

    local venv_path = os.getenv('VIRTUAL_ENV')
    if venv_path then
        -- Si es Windows
        if vim.g.os_type == 0 then
            return venv_path .. '\\scripts\\python.exe'
        end

        -- Si no es Windows
        return venv_path .. '/bin/python'
    end

    venv_path = os.getenv("CONDA_PREFIX")
    if venv_path then
        -- Si es Windows
        if vim.g.os_type == 0 then
            return venv_path .. '\\python.exe'
        end

        -- Si no es Windows
        return venv_path .. '/bin/python'
    end

    local stat = ''
    for root in get_roots() do
        for _, folder in ipairs({ "venv", ".venv", "env", ".env" }) do
            venv_path = root .. "/" .. folder
            stat = vim.loop.fs_stat(venv_path)
            if stat and stat.type == "directory" then
                -- Si es Windows
                if vim.g.os_type == 0 then
                    return venv_path .. '\\scripts\\python.exe'
                end

                -- Si no es Windows
                return venv_path .. '/bin/python'
            end
        end
    end

end


--- Strips extra whitespace at the start of the lines
--  Ejemplo: >>> remove_indent({'    print(10)', '    if True:', '        print(20)'})
--  Output:  {'print(10)', 'if True:', '    print(20)'}
---@param lines string[]
---@return string[]
local function remove_indent(lines)

    local offset = nil
    for _, line in ipairs(lines) do
        local first_non_ws = line:find('[^%s]') or 0
        if first_non_ws >= 1 and (not offset or first_non_ws < offset) then
            offset = first_non_ws
        end
    end

    if offset > 1 then
        assert(offset)
        return vim.tbl_map(function(x) return string.sub(x, offset) end, lines)
    else
        return lines
    end

end



--- Devuelve el codigo selecionado
---@return string|nil
function M.get_selected_code()

    local start_row, _ = unpack(vim.api.nvim_buf_get_mark(0, '<'))
    local end_row, _ = unpack(vim.api.nvim_buf_get_mark(0, '>'))
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    local code = table.concat(remove_indent(lines), '\n')
    return code

end

-- Supported test frameworks are unittest, pytest and django.
-- By default it tries to detect the runner by probing for presence of pytest.ini or manage.py, or for a tool.pytest
-- directive inside pyproject.toml, if none are present it defaults to unittest.
function M.get_default_tester()

  for root in get_roots() do
    if vim.loop.fs_stat(root .. "/pytest.ini") then
      return "pytest"
    elseif vim.loop.fs_stat(root .. "/manage.py") then
      return "django"
    elseif vim.loop.fs_stat(root .. "/pyproject.toml") then
      local f = io.open(root .. "/pyproject.toml")
      if f then
        for line in f:lines() do
          if line:find("%[tool.pytest") then
            f:close()
            return "pytest"
          end
        end
        f:close()
      end
    end
  end

  return "unittest"

end

function M.get_params_by_tester(tester_type, class_names, method_name)

    local data
    local args
    local test_path
    if tester_type == "unittest" then

        -- Obtener del nombre del modulo python
        local module_name

        if vim.g.os_type == 0 then
            -- Si es Windows
            module_name = vim.fn.expand('%:.:r:gs?\\?.?')
        else
            module_name = vim.fn.expand('%:.:r:gs?/?.?')
        end

        -- Concatenar y obtener la ruta de elemento a realizar las pruebas
        data = { module_name, class_names, method_name }
        data = vim.iter(data):flatten(2):totable()

        test_path = table.concat(data, '.')
        args = {'-v', test_path}

        return "unittest", args

    end

    if tester_type == "pytest" then

        -- Obtener la ruta del archivo del modulo
        local file_path = vim.fn.expand('%:p')

        -- Concatenar y obtener la ruta de elemento a realizar las pruebas
        data = { file_path, class_names, method_name }
        data = vim.iter(data):flatten(2):totable()

        test_path = table.concat(data, '::')
        args = {'-s', test_path}

        return "pytest", args

    end

    if tester_type == "django" then

        -- Obtener del nombre del modulo python
        local module_name

        if vim.g.os_type == 0 then
            -- Si es Windows
            module_name = vim.fn.expand('%:.:r:gs?\\?.?')
        else
            module_name = vim.fn.expand('%:.:r:gs?/?.?')
        end

        -- Concatenar y obtener la ruta de elemento a realizar las pruebas
        data = { module_name, class_names, method_name }
        data = vim.iter(data):flatten(2):totable()

        test_path = table.concat(data, '.')
        args = {'test', test_path}

        return "django", args

    end

end


return M
