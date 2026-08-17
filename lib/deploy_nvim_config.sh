#!/usr/bin/env bash
# 供 setup_linux.sh 與 setup_mac.sh source；不得改變 caller 的 shell options。

deploy_nvim_config() {
    local source_dir="$1"
    local target_dir="$2"
    local backup_dir="${2}.bak"
    local target_parent
    local staged_dir
    local had_previous=false

    if [[ ! -d "$source_dir" || ! -f "$source_dir/init.lua" ]]; then
        printf '錯誤：Neovim 配置來源無效：%s\n' "$source_dir" >&2
        return 1
    fi
    if [[ "$target_dir" == "/" || "$(basename "$target_dir")" != "nvim" ]]; then
        printf '錯誤：Neovim 配置目標路徑不安全：%s\n' "$target_dir" >&2
        return 1
    fi
    if [[ -e "$target_dir" && ( ! -d "$target_dir" || -L "$target_dir" ) ]]; then
        printf '錯誤：Neovim 配置目標不是一般目錄：%s\n' "$target_dir" >&2
        return 1
    fi
    if [[ -d "$target_dir" ]] && diff -qr "$source_dir" "$target_dir" >/dev/null 2>&1; then
        printf 'Neovim 配置已是最新版本，略過：%s\n' "$target_dir"
        return 0
    fi
    target_parent="$(dirname "$target_dir")"
    mkdir -p "$target_parent"
    staged_dir="$(mktemp -d "$target_parent/.nvim.deploy.XXXXXXXX")"
    case "$staged_dir" in
        "$target_parent"/.nvim.deploy.*) ;;
        *)
            printf '錯誤：Neovim 暫存目錄不在預期位置：%s\n' "$staged_dir" >&2
            return 1
            ;;
    esac

    if ! cp -R "$source_dir/." "$staged_dir/" || ! diff -qr "$source_dir" "$staged_dir" >/dev/null 2>&1; then
        find "$staged_dir" -depth -delete
        printf '錯誤：Neovim 配置暫存驗證失敗\n' >&2
        return 1
    fi
    if [[ -d "$target_dir" ]]; then
        if [[ -e "$backup_dir" || -L "$backup_dir" ]]; then
            if ! rm -rf "$backup_dir"; then
                find "$staged_dir" -depth -delete
                printf '錯誤：無法替換既有 Neovim backup：%s\n' "$backup_dir" >&2
                return 1
            fi
        fi
        if ! mv "$target_dir" "$backup_dir"; then
            find "$staged_dir" -depth -delete
            printf '錯誤：無法備份既有 Neovim 配置：%s\n' "$target_dir" >&2
            return 1
        fi
        had_previous=true
        printf '既有 Neovim 配置已備份至：%s\n' "$backup_dir"
    fi

    if ! mv "$staged_dir" "$target_dir"; then
        if [[ "$had_previous" == true && ! -e "$target_dir" && -d "$backup_dir" ]]; then
            mv "$backup_dir" "$target_dir" || true
        fi
        find "$staged_dir" -depth -delete
        printf '錯誤：Neovim 配置部署失敗：%s\n' "$target_dir" >&2
        return 1
    fi
    printf 'Neovim 配置已部署至：%s\n' "$target_dir"
}
