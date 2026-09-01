{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # NixOS 系統級別的配置寫法
    configure = {
      customRC = ''
        lua << EOF
        -- 1. 自動建立不存在的目錄 (解決 E212)
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

        -- 2. 魔法 Sudo 保存命令 (解決權限問題)
        -- 以後在 nvim 裡輸入 :W (大寫) 就能強制保存
        vim.api.nvim_create_user_command('W', function()
          vim.cmd('w !sudo tee % > /dev/null')
        end, {})
        EOF
      '';
    };
  };
}
