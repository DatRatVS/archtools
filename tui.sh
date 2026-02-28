#!/bin/bash

if [ ! -t 0 ]; then
    script=$(mktemp /tmp/tui.XXXXXX.sh)
    cat > "$script"
    chmod +x "$script"
    bash "$script" "$@" < /dev/tty
    rm -f "$script"
    exit
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
UNDERLINE='\033[4m'
NC='\033[0m'

declare -a OPTIONS=("Run Arch Setup (mount and chroot)" "Exit")
SELECTED=0

show_banner() {
    clear
    cat <<"EOF"
   ___       __  ___       __    ___           __   _
  / _ \___ _/ /_/ _ \___ _/ /_  / _ | ________/ /  (_)__ ___
 / // / _ `/ __/ , _/ _ `/ __/ / __ |/ __/ __/ _ \/ (_-</ _ \
/____/\_,_/\__/_/|_|\_,_/\__/ /_/ |_/_/  \__/_//_/_/___/\___/

EOF
}

run_arch_setup() {
    echo -e "${YELLOW}Starting Arch setup...${NC}"

    echo -e "${YELLOW}Mounting filesystems...${NC}"
    mount /dev/sda2 /mnt -o subvol=@
    mount /dev/sda2 /mnt/home -o subvol=@home
    mount /dev/sda2 /mnt/.snapshots -o subvol=@.snapshots
    mount /dev/sda2 /mnt/var/log -o subvol=@log
    mount /dev/sda2 /mnt/var/cache/pacman/pkg -o subvol=@pkg
    mount /dev/sda1 /mnt/boot

    echo -e "${GREEN}Entering chroot...${NC}"
    arch-chroot /mnt
}

show_menu() {
    show_banner
    echo "Select an option (Use arrow keys, press Enter to select):"
    echo ""

    for i in "${!OPTIONS[@]}"; do
        if [ $i -eq $SELECTED ]; then
            echo -e "${GREEN}${UNDERLINE}▶ ${OPTIONS[$i]}${NC}"
        else
            echo -e "  ${OPTIONS[$i]}"
        fi
    done
    echo ""
}

read_input() {
    local key
    read -rsn1 key

    if [[ $key == $'\x1b' ]]; then
        read -rsn2 key  # Read arrow keys
        case $key in
            '[A') # Up arrow
                ((SELECTED--))
                if [ $SELECTED -lt 0 ]; then
                    SELECTED=$((${#OPTIONS[@]} - 1))
                fi
                ;;
            '[B') # Down arrow
                ((SELECTED++))
                if [ $SELECTED -ge ${#OPTIONS[@]} ]; then
                    SELECTED=0
                fi
                ;;
        esac
    elif [[ $key == '' ]]; then
        # Enter key pressed
        return 0
    fi
    return 1
}

main() {
    loadkeys br-abnt2

    local saved_stty=$(stty -g)
    trap "stty $saved_stty" EXIT
    stty -echo -icanon time 0 min 1

    while true; do
        show_menu

        while ! read_input; do
            show_menu
        done

        case $SELECTED in
            0)
                stty $saved_stty
                run_arch_setup
                saved_stty=$(stty -g)
                stty -echo -icanon time 0 min 1
                echo ""
                exit 0
                ;;
            1)
                stty $saved_stty
                echo -e "${YELLOW}Exiting...${NC}"
                exit 0
                ;;
        esac
    done
}

main
