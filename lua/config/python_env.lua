local M = {}

local function executable(path)
  return path and vim.fn.executable(vim.fn.expand(path)) == 1
end

local function first_python(candidates)
  for _, path in ipairs(candidates) do
    path = vim.fn.expand(path)
    if executable(path) then
      return path
    end
  end
end

local function python_from_env_line(line)
  line = vim.trim(line or "")
  if line == "" or line:sub(1, 1) == "#" then
    return nil
  end

  local path = vim.fn.expand(line)
  -- 支持两种写法：
  --   /path/to/env
  --   /path/to/env/bin/python
  if vim.fn.isdirectory(path) == 1 then
    return first_python({ path .. "/bin/python", path .. "/Scripts/python.exe" })
  end
  if executable(path) then
    return path
  end
end

function M.find_env_file_python(root_dir, file_path)
  file_path = file_path and file_path ~= "" and vim.fn.fnamemodify(file_path, ":p") or vim.fn.getcwd()
  local dir = vim.fn.fnamemodify(file_path, ":p:h")
  local stop_dir = root_dir and root_dir ~= "" and vim.fn.fnamemodify(root_dir, ":p") or vim.fn.getcwd()

  while dir and dir ~= "" do
    local env_file = dir .. "/.nvim-python-env"
    if vim.fn.filereadable(env_file) == 1 then
      for _, line in ipairs(vim.fn.readfile(env_file)) do
        local python = python_from_env_line(line)
        if python then
          return python, env_file
        end
      end
    end

    if dir == stop_dir or dir == "/" then
      break
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
end

function M.resolve_python(root_dir, file_path)
  root_dir = root_dir or vim.fn.getcwd()
  file_path = file_path or vim.api.nvim_buf_get_name(0)

  -- 1. 项目内 .nvim-python-env 优先：适合 Obsidian/monorepo 下不同子项目使用不同环境。
  local env_python = M.find_env_file_python(root_dir, file_path)
  if env_python then
    return env_python
  end

  -- 2. 项目本地虚拟环境。
  local local_env_python = first_python({
    root_dir .. "/.venv/bin/python",
    root_dir .. "/venv/bin/python",
  })
  if local_env_python then
    return local_env_python
  end

  -- 3. 兼容旧规则：DeapLearning 目录默认使用 d2l_pytorch。
  local in_deeplearning = root_dir:find("/Phigent/Notes/02_Learning/DeapLearning", 1, true)
    or file_path:find("/Phigent/Notes/02_Learning/DeapLearning", 1, true)
  if in_deeplearning then
    local d2l_python = first_python({
      "~/Installation/miniconda3/envs/d2l_pytorch/bin/python",
      "~/miniconda3/envs/d2l_pytorch/bin/python",
      "~/anaconda3/envs/d2l_pytorch/bin/python",
    })
    if d2l_python then
      return d2l_python
    end
  end

  -- 4. 当前 shell 激活的 venv/conda。
  local active_env_python = first_python({
    (vim.env.VIRTUAL_ENV or "") .. "/bin/python",
    (vim.env.CONDA_PREFIX or "") .. "/bin/python",
  })
  if active_env_python then
    return active_env_python
  end

  -- 5. 系统 python3。
  return vim.fn.exepath("python3")
end

function M.apply_python(python)
  python = vim.fn.expand(python or "")
  if executable(python) then
    vim.g.python3_host_prog = python
    local bin = vim.fn.fnamemodify(python, ":h")
    local path_parts = vim.split(vim.env.PATH or "", ":", { plain = true, trimempty = true })
    local filtered = {}
    for _, part in ipairs(path_parts) do
      if part ~= bin then
        table.insert(filtered, part)
      end
    end
    table.insert(filtered, 1, bin)
    vim.env.PATH = table.concat(filtered, ":")
  end
  return python
end

return M
