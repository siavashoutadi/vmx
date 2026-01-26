#!/bin/bash

# Bash completion for vmx command
# Source this file in your ~/.bashrc or ~/.bash_profile

alias vmx='./vmx'

_vmx_completion() {
    local cur prev words cword
    _init_completion || return

    # Find the .vmx directory by searching upward from the current working directory
    local searchDir="$PWD"
    local commandDir=""

    while [[ "$searchDir" != "/" ]]; do
        if [[ -d "$searchDir/.vmx" ]]; then
            commandDir="$searchDir/.vmx"
            break
        fi
        searchDir=$(dirname "$searchDir")
    done

    # Fallback: check if installed in system location
    if [[ -z "$commandDir" && -d "/usr/local/lib/vmx/.vmx" ]]; then
        commandDir="/usr/local/lib/vmx/.vmx"
    fi

    # If no .vmx directory found, no completion available
    if [[ -z "$commandDir" ]]; then
        return 0
    fi

    # Build the current command path
    local current_path="$commandDir"
    local i

    # Navigate through the command hierarchy
    for ((i=1; i < cword; i++)); do
        local next_path="$current_path/${words[i]}"
        if [[ -d "$next_path" ]]; then
            current_path="$next_path"
        else
            # We've reached an action or invalid path
            return 0
        fi
    done

    # Generate completions for the current level
    local suggestions=()

    # Add subdirectories (subcommands)
    while IFS= read -r dir; do
        [[ -n "$dir" ]] && suggestions+=("$(basename "$dir")")
    done < <(find "$current_path" -maxdepth 1 -type d ! -path "$current_path" 2>/dev/null | sort)

    # Add executable files (actions)
    while IFS= read -r file; do
        local basename=$(basename "$file")
        # Skip library files (starting with underscore)
        [[ -n "$file" && ! "$basename" =~ ^_ ]] && suggestions+=("$basename")
    done < <(find "$current_path" -maxdepth 1 -type f -executable 2>/dev/null | sort)

    # Generate completion matches
    COMPREPLY=($(compgen -W "${suggestions[*]}" -- "$cur"))

    return 0
}

complete -F _vmx_completion vmx
