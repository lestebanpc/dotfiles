local M = {}


--- Reverse list inline
---@param list any[]
local function reverse(list)
    local len = #list
    for i = 1, math.floor(len * 0.5) do
        local opposite = len - i + 1
        list[i], list[opposite] = list[opposite], list[i]
    end
end


---@param node TSNode
---@result TSNode[]
local function get_parent_classes(node)
    local parent = node:parent()
    local result = {}
    while parent ~= nil do
        if parent:type() == "class_definition" then
            local ident = parent:child(1)
            assert(ident and ident:type() == "identifier")
            table.insert(result, ident)
        end
        parent = parent:parent()
    end
    reverse(result)
    return result
end


local function get_node_text(node)
    if vim.treesitter.get_node_text then
        return vim.treesitter.get_node_text(node, 0)
    end
    local row1, col1, row2, col2 = node:range()
    if row1 == row2 then
        row2 = row2 + 1
    end
    local lines = vim.api.nvim_buf_get_lines(0, row1, row2, true)
    if #lines == 1 then
        return (lines[1]):sub(col1 + 1, col2)
    end
    return table.concat(lines, '\n')
end


---@param source string|integer
---@param subject "function"|"class"
---@param end_row integer? defaults to cursor
---@return TSNode[]
local function get_nodes(source, subject, end_row)
    end_row = end_row or vim.api.nvim_win_get_cursor(0)[1]
    local query_text = [[
    (function_definition
      name: (identifier) @function
    )

    (class_definition
      name: (identifier) @class
    )
    ]]

    local lang = "python"
    local query = (vim.treesitter.query.parse
        and vim.treesitter.query.parse(lang, query_text)
        or vim.treesitter.parse_query(lang, query_text)
    )
    local parser = (
        type(source) == "number"
        and vim.treesitter.get_parser(source, lang)
        or vim.treesitter.get_string_parser(source --[[@as string]], lang)
    )
    local trees = parser:parse()
    local root = trees[1]:root()
    local nodes = {}
    for id, node in query:iter_captures(root, source, 0, end_row) do
        local capture = query.captures[id]
        if capture == subject then
            table.insert(nodes, node)
        end
    end
    if not next(nodes) then
        return nodes
    end
    if subject == "function" then
        local result = nodes[#nodes]
        local parent = result
        while parent ~= nil do
            if parent:type() == "function_definition" then
                local ident
                if parent:child(1):type() == "identifier" then
                    ident = parent:child(1)
                elseif parent:child(2) and parent:child(2):type() == "identifier" then
                    ident = parent:child(2)
                end
                result = ident
            end
            parent = parent:parent()
        end
        return { result }
    elseif subject == "class" then
        local last = nodes[#nodes]
        local parent = last
        local results = {}
        while parent ~= nil do
            if parent:type() == "class_definition" then
                local ident = parent:child(1)
                assert(ident:type() == "identifier")
                table.insert(results, ident)
            end
            parent = parent:parent()
        end
        reverse(results)
        return results
    else
        error("Expected subject 'function' or 'class', not: " .. subject)
    end
end


function M.get_nearest_method()

    --1. Obtener el nodo de la funcion mas cercana al cursor actual
    local functions = get_nodes(0, "function")
    if not functions or not functions[1] then
        return
    end

    local fn = functions[1]

    --2. Obtener los nombres de las clases al caul pertenece la funcion
    local parent_classes = get_parent_classes(fn)

    -- Geberar una tabla indexada con todos los nombres de las clases al cual pertenece la funcion.
    -- Aplica la funcion 'get_node_text' a todos los elementos del arreglo de nodos 'parent_classes'
    local class_names = vim.tbl_map(get_node_text, parent_classes)

    -- Obtener el nombre de la funcion
    local method_name = get_node_text(fn)
    return class_names, method_name

end

function M.get_nearest_class()

    --2. Obtener las clases del buffer actual
    local candidates = get_nodes(0, "class")
    if not candidates then
        return
    end

    -- Geberar una tabla indexada con todos los nombres asociado a los nodos de las clases
    -- Aplica la funcion 'get_node_text' a todos los elementos del arreglo de nodos 'parent_classes'
    local names = vim.tbl_map(get_node_text, candidates)
    return names

end


return M
