{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    configure = {
      customRC = ''
        lua << EOF
        -----------------------------------------------------------
        -- 1. 基礎功能 (自動目錄、Sudo保存)
        -----------------------------------------------------------
        vim.api.nvim_create_autocmd({ "BufWritePre" }, {
          group = vim.api.nvim_create_augroup("auto_create_dir", { clear = true }),
          callback = function(event)
            if event.match:match("^%w%w+:[\\/][\\/]") then return end
            local file = vim.loop.fs_realpath(event.match) or event.match
            vim.fn.mkdir(vim.fn.fnamemodify(file, ":h"), "p")
          end,
        })

        vim.api.nvim_create_user_command('W', function()
          vim.cmd('w !sudo tee % > /dev/null')
        end, {})

        -----------------------------------------------------------
        -- 2. 現代化快捷鍵優化
        -----------------------------------------------------------
        local map = vim.keymap.set
        local opts = { noremap = true, silent = true }

        -- Ctrl + s: 保存檔案
        map({'n', 'i', 'v'}, '<C-s>', '<Esc>:w<CR>', opts)

        -- Alt + x: 剪切當前行 (取代原本衝突的 Ctrl+w)
        map({'n', 'i', 'v'}, '<A-x>', '<Esc>dd', opts)

        -- Ctrl + Shift + w: 清空文件內容
        map({'n', 'i', 'v'}, '<C-S-w>', '<Esc>ggdG', opts)

        -- 大寫 ZZ: 保存並退出
        map({'n', 'i', 'v'}, 'ZZ', '<Esc>ZZ', opts)

        -----------------------------------------------------------
        -- 3. 魔法功能：抓取另一個文件的內容插入光標處
        -----------------------------------------------------------

        -- 指令用法: :Grab 路徑
        -- 快捷鍵: Alt + r (彈出輸入框)
        local function grab_file_content()
          vim.ui.input({ prompt = '輸入要抓取的檔案路徑: ', completion = 'file' }, function(input)
            if input and input ~= "" then
              -- 檢查檔案是否存在
              if vim.fn.filereadable(input) == 1 then
                vim.cmd('read ' .. input)
                print("已抓取: " .. input)
              else
                print("錯誤: 找不到檔案 " .. input)
              end
            end
          end)
        end

        -- 建立命令
        vim.api.nvim_create_user_command('Grab', function(opts)
          vim.cmd('read ' .. opts.args)
        end, { nargs = 1, complete = 'file' })

        -- 映射快捷鍵 Alt + r
        map({'n', 'i'}, '<A-r>', function() grab_file_content() end, opts)

        -----------------------------------------------------------
        -- 4. 其他配置
        -----------------------------------------------------------
        vim.opt.clipboard = "unnamedplus"
        vim.opt.number = true         -- 顯示行號
        vim.opt.relativenumber = true -- 顯示相對行號 (切換行超快)
        EOF
      '';
    };
  };
}
