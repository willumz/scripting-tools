#!/bin/bash

SCRIPT_DIR="$(dirname $BASH_SOURCE)"
GIT_DIR="$(git rev-parse --git-dir)"


# -------------------------------------------
# ------------ BEGIN select_many ------------
# -------------------------------------------
# https://github.com/willumz/scripting-tools/blob/master/bash/select_menu/select_many.sh
create_menu() { # $1 = options array

    local options=( $1 )
    local selected=( )
    # load selected with false by default
    for (( i=0; i<${#options[@]}; i++ )); do
        selected+=( false )
    done

    local escape_char=$(printf "\u1b")
    local arrow=0
    local options_length=${#options[@]}
    ((options_length++))
    local cursor_pos=0

    echo -e "SPACE to select, ENTER to confirm"
    write_menu "${options[*]}" "${selected[*]}" "$cursor_pos" # write initial menu

    # start loop
    while [ true ]; do

        echo -e "$escape_char["$options_length"A" # move cursor up
        write_menu "${options[*]}" "${selected[*]}" "$cursor_pos" # write updated menu

        IFS= read -rsn1 key # read key
        if [[ "$key" == $escape_char ]]; then
            read -rsn2 key # read rest of key
            case $key in
                '[A') arrow=1;;
                '[B') arrow=2;;
            esac
        elif [[ "$key" == ' ' ]]; then
            if [[ ${selected[$cursor_pos]} == "true" ]]; then
                selected[$cursor_pos]=false
            else
                selected[$cursor_pos]=true
            fi
        elif [[ "$key" == "" ]]; then
            break
        fi

        case $arrow in
            0) # no arrow
                ;;
            1) # up
                arrow=0
                if ((cursor_pos > 0)); then
                    ((cursor_pos--))
                fi;;
            2)
                arrow=0 
                if ((cursor_pos < options_length-2)); then
                    ((cursor_pos++))
                fi;;
        esac

    done

    # end
    local erase_length=$((options_length))
    echo -e "$escape_char["$erase_length"A$escape_char[0J$escape_char[1A" # move cursor up and overwrite menu
    SELECTED_OPTIONS=( )
    for (( i=0; i<${#options[@]}; i++ )); do
        if [[ ${selected[$i]} == "true" ]]; then
            SELECTED_OPTIONS+=( ${options[$i]} )
        fi
    done
    # for (( i=0; i<${#SELECTED_OPTIONS[@]}; i++ )); do
    #     if (( i == ${#SELECTED_OPTIONS[@]}-1 )); then echo -e -n "${SELECTED_OPTIONS[$i]}"; else echo -e "${SELECTED_OPTIONS[$i]}"; fi
    # done
}

write_menu () { # $1 = options array, $2 = selected options array, $3 = cursor position

    local options=( $1 )
    local selected=( $2 )
    local arr_len=${#options[@]}
    local star="*"
    local escape_char=$(printf "\u1b")
    local colour_code="37m"
    for (( i=0; i<$arr_len; i++ )); do
        if [[ ${selected[$i]} == true ]]; then
            star="*"
        else
            star=" "
        fi
        if [[ $i == $3 ]]; then
            colour_code="33m"
        else
            colour_code="39m"
        fi
        echo -e "$escape_char[$colour_code[${star}] ${options[$i]}$escape_char[39m"
    done

}
# -----------------------------------------
# ------------ END select_many ------------
# -----------------------------------------

shopt -s extglob

parse_header() { # $1 = file contents

    local in_header=false
    local file_contents=( $1 )
    PARSE_HEADER_SUCCESS=true
    HEADER_TYPE=""
    HEADER_ON_MODIFY=""
    HEADER_END_LINE=0 # line header ends on

    for line in "${file_contents[@]}"; do
        ((HEADER_END_LINE++))
        if [[ $line == "----" && $in_header == true ]]; then
            in_header=false
            break
        elif [[ $line == "----" ]]; then
            in_header=true
        else
            case $line in
                type=+([a-zA-Z\-]))
                    HEADER_TYPE=${line#*=};;
                on-modify=*)
                    HEADER_ON_MODIFY=${line#*=};;
                *)
                    PARSE_HEADER_SUCCESS=false;;
            esac
        fi
    done
    if [ $in_header == true ]; then
        PARSE_HEADER_SUCCESS=false
    fi

}

# get hooks from dir
hooks=( )
for file in $SCRIPT_DIR/hooks/*; do
    # IFS='/'
    # read -ra ADDR <<< "$file"
    # addr_pos=$((${#ADDR[@]}-1))
    # echo ${ADDR[$addr_pos]}
    # echo ${ADDR[2]}
    for f in $file; do echo $f; done
    basename_file=$(basename $file)
    hooks+=( "$basename_file" )
done

# select hooks
echo -e "\e[35mWARNING: existing hooks will be overwritten\e[39m"
echo -e "Select hooks to install:"
create_menu "${hooks[*]}"
echo -e "\e[1A\e[0J\e[32mHooks selected\e[39m"

# categorise hooks
applypatch_msg=( )
commit_msg=( )
fsmonitor_watchman=( )
post_update=( )
pre_applypatch=( )
pre_commit=( )
pre_merge_commit=( )
prepare_commit_msg=( )
pre_push=( )
pre_rebase=( )
pre_receive=( )
push_to_checkout=( )
update=( )

echo -e "\e[33m====PARSING HOOKS====\e[39m"

for hook in "${SELECTED_OPTIONS[@]}"; do
    echo -e "\e[33mParsing hook: $hook\e[39m"
    file_lines=( )
    while read -r line; do
        line="${line/$'\r'/}"
        file_lines+=( "$line" )
        # TODO: only read until second '----'
    done < "$SCRIPT_DIR/hooks/$hook"
    parse_header "${file_lines[*]}"
    if [ $PARSE_HEADER_SUCCESS == false ]; then echo -e "\e[1A\e[2K\e[31mError: failed to parse '$hook' (invalid metadata structure)\e[39m"
    else
        parse_success=true
        case $HEADER_TYPE in
            "applypatch-msg") applypatch_msg+=( "$hook" );;
            "commit-msg") commit_msg+=( "$hook" );;
            "fsmonitor-watchman") fsmonitor_watchman+=( "$hook" );;
            "post-update") post_update+=( "$hook" );;
            "pre-applypatch") pre_applypatch+=( "$hook" );;
            "pre-commit") pre_commit+=( "$hook" );;
            "pre-merge-commit") pre_merge_commit+=( "$hook" );;
            "prepare-commit-msg") prepare_commit_msg+=( "$hook" );;
            "pre-push") pre_push+=( "$hook" );;
            "pre-rebase") pre_rebase+=( "$hook" );;
            "pre-receive") pre_receive+=( "$hook" );;
            "push-to-checkout") push_to_checkout+=( "$hook" );;
            "update") update+=( "$hook" );;
            *) echo -e "\e[1A\e[2K\e[31mError: failed to parse '$hook' (invalid type)\e[39m"; parse_success=false;;
        esac
        if [ $parse_success == true ]; then echo -e "\e[1A\e[2K\e[32mParsed '$hook' successfully\e[39m"; fi
    fi
done

compile_hook() { # $1 = hook name, $2 = hook array
    local hooks=( $2 )
    local hook_lines=( )
    rm -f "$GIT_DIR/hooks/$1"
    if (( ${#hooks[@]} > 0 )); then
        echo -e "\e[33mCompiling hook: $1\e[39m"
        
        for hook in "${hooks[@]}"; do
            hook_lines=( )
            while IFS= read -r line; do
                line="${line/$'\r'/}"
                hook_lines+=( "$line" )
            done < "$SCRIPT_DIR/hooks/$hook"
            parse_header "${hook_lines[*]}"
            for (( i=1; i<${#hook_lines[@]}; i++ )); do
                if ((i > HEADER_END_LINE)); then
                    echo "${hook_lines[$i]}" >> "$GIT_DIR/hooks/$1"
                fi
            done
        done

        echo -e "\e[1A\e[2K\e[32mCompiled hook: $1\e[39m"
    fi

}

# compile hooks to files

echo -e "\e[33m====COMPILING HOOKS====\e[39m"

compile_hook "applypatch-msg" "${applypatch_msg[*]}"
compile_hook "commit-msg" "${commit_msg[*]}"
compile_hook "fsmonitor-watchman" "${fsmonitor_watchman[*]}"
compile_hook "post-update" "${post_update[*]}"
compile_hook "pre-applypatch" "${pre_applypatch[*]}"
compile_hook "pre-commit" "${pre_commit[*]}"
compile_hook "pre-merge-commit" "${pre_merge_commit[*]}"
compile_hook "prepare-commit-msg" "${prepare_commit_msg[*]}"
compile_hook "pre-push" "${pre_push[*]}"
compile_hook "pre-rebase" "${pre_rebase[*]}"
compile_hook "pre-receive" "${pre_receive[*]}"
compile_hook "push-to-checkout" "${push_to_checkout[*]}"
compile_hook "update" "${update[*]}"