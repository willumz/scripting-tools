#!/bin/bash

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
