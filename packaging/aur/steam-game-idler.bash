# steam-game-idler bash completion
_steam_game_idler() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--help --version --portable --clear-cache --reset-settings"

    case "${prev}" in
        steam-game-idler)
            mapfile -t COMPREPLY < <(compgen -W "${opts}" -- "${cur}")
            return 0
        ;;
    esac

    mapfile -t COMPREPLY < <(compgen -W "${opts}" -- "${cur}")
    return 0
}
complete -F _steam_game_idler steam-game-idler
