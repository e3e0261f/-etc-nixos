{ pkgs, ... }:

{

  environment.systemPackages = [ pkgs.gcc pkgs.gnumake ];
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    configure = {
      customRC = ''
        lua << EOF
        -- 1. 原有的：自動建立不存在的目錄
        vim.api.nvim_create_autocmd({ "BufWritePre" }, {
          group = vim.api.nvim_create_augroup("auto_create_dir", { clear = true }),
          callback = function(event)
            if event.match:match("^%w%w+:[\\/][\\/]") then
              return
            end
            local file = vim.loop.fs_realpath(event.match) or event.match
            vim.fn.mkdir(vim.fn.fnamemodify(file, ":h"), "p")
          end,
        })

        -- 2. 原有的：魔法 Sudo 保存命令 (:W)
        vim.api.nvim_create_user_command('W', function()
          vim.cmd('w !sudo tee % > /dev/null')
        end, {})

        -----------------------------------------------------------
        -- 新增功能：現代化快捷鍵 (支援 Normal, Insert, Visual 模式)
        -----------------------------------------------------------
        local map = vim.keymap.set
        local opts = { noremap = true, silent = true }

        -- Ctrl + s: 保存檔案
        map({'n', 'i', 'v'}, '<C-s>', '<Esc>:w<CR>', opts)

        -- Ctrl + w: 剪切當前行
        -- 注意：這會覆蓋 Neovim 預設的窗口管理功能 (原本是 Ctrl-w + 方向鍵)
        map({'n', 'i', 'v'}, '<C-w>', '<Esc>dd', opts)

        -- Ctrl + Shift + w: 剪切全部文本
        -- 注意：某些終端機可能需要額外設定才能偵測到 Ctrl+Shift 組合鍵
        map({'n', 'i', 'v'}, '<C-S-w>', '<Esc>ggdG', opts)

        EOF
      '';
    };
  };
}
