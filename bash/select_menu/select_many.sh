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

    write_menu "${options[*]}" "${selected[*]}" "$cursor_pos" # write initial menu

    # start loop
    while [ true ]; do

        echo -e "$escape_char["$options_length"A" # move cursor up
        write_menu "${options[*]}" "${selected[*]}" "$cursor_pos" # write updated menu

        read -rsn1 key # read key
        if [[ $key == $escape_char ]]; then
            read -rsn2 key # read rest of key
            case $key in
                '[A') arrow=1;;
                '[B') arrow=2;;
            esac
        elif [[ $key == '' ]]; then
            if [[ ${selected[$cursor_pos]} == "true" ]]; then
                selected[$cursor_pos]=false
            else
                selected[$cursor_pos]=true
            fi
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


options2=( "hi" "hello" "hey" )
create_menu "${options2[*]}"
#selected2=( true false true )
#write_menu "${options2[*]}" "${selected2[*]}"