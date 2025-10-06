clear
echo "Loading.."

trap 'tput cnorm; echo "\nQuitting.."; exit 130' INT

printxpos() {
    local position=$1
    local text=$2
    local row=${3:-0}
    local cols=$(tput cols)
    local len=${#text}
    local padding=0

    case "$position" in
        l) padding=0 ;;
        r) padding=$(( cols - len )) ;;
        c) padding=$(( (cols - len) / 2 )) ;;
        *)
            echo "Invalid arg passed to printxpos(): $position."
            return 1
            ;;
    esac
    ((padding < 0)) && padding=0
    tput cup $row 0
    printf "%*s%s\n" $padding "" "$text"
}

floodline() {
    local fillstr=$1
    local row=${2:-1}
    local cols=$(tput cols)
    local fill_len=${#fillstr}
    local repeat_count=$(( cols / fill_len ))
    local remainder=$(( cols % fill_len ))
    local line=""
    for ((i=0; i<repeat_count; i++)); do
        line+="$fillstr"
    done
    if (( remainder > 0 )); then
        line+=${fillstr:0:remainder}
    fi
    tput cup $row 0
    printf "%s\n" "$line"
}

refresh() {
    clear
    printxpos c "OS86 [v0.1.0] - $1" 0
    floodline "-" 1
    floodline "OS86 - " 2
    floodline "-" 3
}

select_option() {
    local options=("$@")
    local selected=0
    local key
    local num_options=${#options[@]}
    local ESC=$'\e'
    tput civis

    while true; do
        tput cup 5 0
        tput ed
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                printf '%s %d) %s\n' '->' $((i+1)) "${options[i]}"
            else
                printf "   %d) %s\n" $((i+1)) "${options[i]}"
            fi
        done
        IFS= read -rsn1 key
        if [[ $key == $ESC ]]; then
            read -rsn2 key
            case "$key" in
                '[A')
                    ((selected--))
                    ((selected < 0)) && selected=$((num_options-1))
                    ;;
                '[B')
                    ((selected++))
                    ((selected >= num_options)) && selected=0
                    ;;
                '[D')
                    tput cnorm
                    return 255
                    ;;
                '[C')
                    tput cnorm
                    return $selected
                    ;;
            esac
        else
            case "$key" in
                '')
                    tput cnorm
                    return $selected
                    ;;
                $'\x7f')
                    tput cnorm
                    return 255
                    ;;
            esac
        fi
    done
}

disclaimer() {
    local file="$1" ESC=$'\e' rows=$(tput lines) cols=$(tput cols)
    local footer_row=$((rows - 2)) offset=0 view_height=$((rows - 3))
    local count=0 screen=() screen_lines=0
    tput civis
    while IFS= read -r line; do
        [[ "$line" =~ ^([[:space:]]*) ]]
        local indent="${BASH_REMATCH[1]}"
        indent="${indent//$'\t'/    }"
        local content="${line#$indent}"

        while [ "${#content}" -gt $((cols - ${#indent})) ]; do
            local cut="${content:0:$((cols - ${#indent}))}"
            local wrap="${cut% *}"
            [[ -z "$wrap" ]] && wrap="$cut"
            screen[count++]="$indent$wrap"
            content="${content#"$wrap"}"
            content="${content#"${content%%[![:space:]]*}"}"
        done
        screen[count++]="$indent$content"
    done < "$file"

    while :; do
        clear
        screen_lines=${#screen[@]}
        for ((i=0; i<view_height; i++)); do
            idx=$((offset + i))
            [[ "$idx" -lt "$screen_lines" ]] && printf "%s\n" "${screen[idx]}" || echo
        done
        tput cup $footer_row 0
        local l="DOWN - scroll down" c="ENTER - agree" r="UP - scroll up"
        local ll=${#l} cl=${#c} rl=${#r} sp=$((cols - ll - cl - rl))
        if (( sp < 2 )); then
            printf "%s %s %s\n" "$l" "$c" "$r"
        else
            local lg=$((sp / 2)) rg=$((sp - lg))
            printf "%s%*s%s%*s%s\n" "$l" "$lg" "" "$c" "$rg" "" "$r"
        fi
        IFS= read -rsn1 key
        if [[ "$key" == "$ESC" ]]; then
            read -rsn2 key
            case "$key" in
                '[A') ((offset-- < 0)) && offset=0 ;;
                '[B') ((offset++)); ((offset > screen_lines - view_height)) && offset=$((screen_lines - view_height)); ((offset<0)) && offset=0 ;;
            esac
        fi
        [[ "$key" == "" ]] && { tput cnorm; clear; return 0; }
    done
}

error() {
    clear
    echo "Oh no! The build shell script ran into an error..
Error: $1
"
    tput cnorm
    exit 1
}

check() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error "$1 command not found.
Hint: is it installed?"
    fi
}

yn() {
    local answer
    printf "%s " "${1:-Y/N:}"
    read -r answer
    case "$answer" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

quit() {
    clear
    echo "Quitting..\n$1"
    exit 0
    tput cnorm
}

while true; do
    disclaimer "./license.txt"
    refresh "Main Menu Selection"
    echo "Please select an option:"
    select_option "Build OS86 for QEMU (.img)" "Clean /build" "Read License"
    choice=$?

    case $choice in
        0)
            echo "
Preparing.."
            check "nasm"

            refresh "Bootloader Selection"
            echo "Please select a bootloader:"
            select_option "IBM BIOS (PC 8086)"
            bl=$?

            refresh "Keyboard Driver Selection"
            echo "Please select your keyboard interface"
            select_option "IBM BIOS (int 16h)"
            kbd=$?

            refresh "Hard Disk Driver Selection"
            echo "Please select your hard disk interface"
            select_option "IBM BIOS (int 13h)"
            hd=$?

            refresh "Floppy Disk Driver Selection"
            echo "Please select your floppy disk interface"
            select_option "IBM BIOS (int 13h)"
            fd=$?

            refresh "Display Driver Selection"
            echo "Please select your display interface"
            select_option "IBM BIOS (int 10h)"
            disp=$?

            refresh "Overview"
            echo "You've selected:"
            printf "Bootloader: - " 
            case $bl in
                0)
                    echo "IBM BIOS (PC 8086)"
                    ;;
            esac
            printf "Keyboard: - " 
            case $kbd in
                0)
                    echo "IBM BIOS (int 16h)"
                    ;;
            esac
            printf "Hard Disk: - "
            case $hd in
                0)
                    echo "IBM BIOS (int 13h)"
                    ;;
            esac
            printf "Floppy Disk: - "
            case $fd in
                0)
                    echo "IBM BIOS (int 13h)"
                    ;;
            esac
            printf "Display: - "
            case $disp in
                0)
                    echo "IBM BIOS (int 10h)"
                    ;;
            esac
            echo "
Confirm? Y/N
"
            yn
            confirm=$?
            if [[ confirm -eq 1 ]]; then
                quit
            fi

            refresh "Preparing to Build"
            echo "Creating floppy image.."
            dd if=/dev/zero of=OS86.img bs=512 count=2880

            refresh "Building OS86: Bootloader"
            printf "Building bootloader: "
            case $bl in
                0)
                    echo "IBM BIOS (PC 8086).."
                    nasm src/boot/ibmbios.s -o build/bootloader.bin || error "$err
Hint: Are you in the correct directory? (/OS86)";
                    ;;
            esac

            refresh "Writing OS to Image"
            echo "Writing bootloader.."
            dd if=build/bootloader.bin of=OS86.img conv=notrunc bs=512 seek=0 || error "$err
Hint: Are you in the correct directory? (/OS86)";

            quit "Done!"

            exit 0
            ;;
        1)
            echo "
Cleaning.."
            err=$(rm -r build/* 2>&1) || error "$err
Hint: Is build an empty directory?";
            echo "Cleaned."
            exit 0
            ;;
        2)
            continue
            ;;
    esac
done