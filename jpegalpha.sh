#!/usr/bin/env bash

# Set global variables
PROGNAME=$(basename "$0")
VERSION='1.0.0'

##
# Print usage
#
##
usage() {
cat <<EOF
Usage:     $PROGNAME [OPTIONS]
Version:   $VERSION

Converts a PNG to an SVG with embedded JPGs (the image and an alpha mask).

OPTIONS:
  -q  Image quality [default: 80]
  -m  Mask quality [default is equal to image quality]

EOF
}

##
# Covert PNG to SVG with embedded JPGs (the image and an alpha mask).
#
# @param 1 PNG file to convert
##
png2svg() {
  width=$(convert "$1" -ping -format '%w' info:-)
  height=$(convert "$1" -ping -format '%h' info:-)
  mask=$(convert "$1" -alpha extract jpeg:- | jpegoptim -q -m"${MASK_QUALITY}" -s --stdin --stdout | base64)
  image=$(convert "$1" jpeg:- | jpegoptim -q -m"${QUALITY}" -s --stdin --stdout | base64)
  printf '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="100%%" height="100%%" viewBox="0 0 %d %d"><mask id="m"><image width="100%%" height="100%%" xlink:href="data:image/jpg;base64,%s"/></mask><image width="100%%" height="100%%" xlink:href="data:image/jpg;base64,%s" mask="url(#m)"/></svg>' "$width" "$height" "$mask" "$image"
}

##
# Check for a dependancy
#
# @param 1 Command to check
##
dependancy() {
  hash "$1" &>/dev/null || error "$1 must be installed"
}

##
# Throw an error
#
# @param 1 Command to check
# @param 2 [1] Error status. If '0', will not exit
##
error() {
  echo -e "Error: ${1:-"Unknown Error"}" >&2
  if [[ ! "$2" == 0 ]]; then
    [[ -n "$2" ]] && exit "$2" || exit 1
  fi
}

################################################################################

# Check dependacies
dependancy convert
dependancy jpegoptim

# Get options
while getopts ":hvm:q:" OPTION; do
  case $OPTION in
    h)
      usage
      exit 0
      ;;
    v)
      echo "$VERSION"
      exit 0
      ;;
    :)
      error "-$OPTION requires an argument" noexit
      usage
      exit 1
      ;;
    \?)
      error "unknown option -$OPTION" noexit
      usage
      exit 1
      ;;
    *)
      [[ "$OPTARG" == "" ]] && OPTARG='"-'$OPTION' 1"'
      OPTION="OPT_$OPTION"
      eval ${OPTION}=$OPTARG
      ;;
  esac
done

# Shift configured options out
shift $(($OPTIND - 1))

# Set variables based on opts
QUALITY="${OPT_q:-80}"
MASK_QUALITY="${OPT_m:-$QUALITY}"

# Run
png2svg "$1"
