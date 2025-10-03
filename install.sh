#!/bin/bash
if [[ ${UID} -eq 0 ]]; then
  DEST_DIR="/usr/share/icons"
else
  DEST_DIR="${HOME}/.icons"
fi

SRC_DIR=$(cd "$(dirname "${0}")" && pwd)
declare -r COLOR_VARIANTS=("standard" "doder" "ruby" "sun")
colors=()

function usage {
  printf "%s\n" "Usage: $0 [OPTIONS]"
  printf "\n%s\n" "OPTIONS:"
  printf "  %-25s%s\n" "-a" "Install all variants"
  printf "  %-25s%s\n" "-d DIR" "Destination directory (Default: ${DEST_DIR})"
  printf "  %-25s%s\n" "-n VARIANT" "Install variant by name (standard, doder, ruby, sun)"
  printf "  %-25s%s\n" "-h" "Show this help"
  printf "\n  %s\n" "Default installs base theme (einfach, standard)"
}

function install_theme {
  local variant="$1"
  case "$variant" in
    standard) theme_color='#fc9867' ;;
    doder)    theme_color='#4285F4' ;;
    ruby)     theme_color='#F0544C' ;;
    sun)      theme_color='#adbf04' ;;
    *) echo "Unknown variant: $variant"; exit 1 ;;
  esac

  [[ "$variant" != "standard" ]] && colorprefix="-$variant" || colorprefix=""
  THEME_NAME="einfach${colorprefix}"
  THEME_DIR="${DEST_DIR}/${THEME_NAME}"

  [[ -d "$THEME_DIR" ]] && rm -rf "$THEME_DIR"

  echo "Installing '${THEME_NAME}'..."
  install -d "$THEME_DIR"
  install -m644 "${SRC_DIR}/src/index.theme" "$THEME_DIR"
  sed -i "s/%NAME%/${THEME_NAME}/g" "$THEME_DIR/index.theme"

  cp -r "${SRC_DIR}"/src/{16,22,24,32,scalable,symbolic} "$THEME_DIR"
  cp -r "${SRC_DIR}"/links/{16,22,24,32,scalable,symbolic} "$THEME_DIR"

  if [[ -n "$colorprefix" ]]; then
    install -m644 "${SRC_DIR}/src/colors/color-${variant}"/*.svg "$THEME_DIR/scalable/places"
  fi

  sed -i "s/#565656/#aaaaaa/g" "$THEME_DIR"/{16,22,24}/actions/*
  sed -i "s/#727272/#aaaaaa/g" "$THEME_DIR"/{16,22,24}/{places,devices}/*
  sed -i "s/#5294e2/$theme_color/g" "$THEME_DIR"/16/places/*

  ln -sr "$THEME_DIR/16" "$THEME_DIR/16@2x"
  ln -sr "$THEME_DIR/22" "$THEME_DIR/22@2x"
  ln -sr "$THEME_DIR/24" "$THEME_DIR/24@2x"
  ln -sr "$THEME_DIR/32" "$THEME_DIR/32@2x"
  ln -sr "$THEME_DIR/scalable" "$THEME_DIR/scalable@2x"

  cp -r "${SRC_DIR}/src/cursors/dist" "$THEME_DIR/cursors"
  gtk-update-icon-cache "$THEME_DIR"
}

function clean_old_theme {
  rm -rf "${DEST_DIR}"/einfach{'-doder','-ruby','-sun'}
}

# Argument parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a)
      colors=("${COLOR_VARIANTS[@]}")
      shift
      ;;
    -d)
      DEST_DIR="$2"
      shift 2
      ;;
    -n)
      if [[ " ${COLOR_VARIANTS[*]} " == *" $2 "* ]]; then
        colors+=("$2")
      else
        echo "Unknown variant: $2"
        exit 1
      fi
      shift 2
      ;;
    -h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unrecognized option '$1'"
      exit 1
      ;;
  esac
done

: "${colors:=standard}"

clean_old_theme

for color in "${colors[@]}"; do
  install_theme "$color"
done
