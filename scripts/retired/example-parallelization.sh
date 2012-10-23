#!/bin/bash

# Setting defaults. The script shall change these after parsing the supplied
# arguments.

INDIR="$PWD"
OUTDIR="$PWD/outdir"
NCORES=$(grep -c processor /proc/cpuinfo)
if [[ NCORES -gt 1 ]]; then
  let NCORES=$NCORES/2
fi

# Populating routines required.

## This one prints help when required (obviously). :D

function print_help(){
echo
echo " Usage:    extract_equity.sh -i=indir -o=outdir -s=stocks -n=threads"
echo " Default:  extract_equity.sh -s=stocks"
echo " Help:     extract_equity.sh -h"
echo
echo " 'indir' is the directory from which to read the order books."
echo " 'outdir' is the directory to write the extracted data to."
echo " 'stocks' is the file with list of stocknames to extract data for."
echo " 'threads' is a numerical argument."
echo " It tells the script the number of threads to start."
echo
echo " 'stocks' flag must be used. All others are optional."
echo " Default for indir is \$PWD, presently: "$PWD"."
echo " Default for indir is \$PWD/outdir, presently: "$PWD"/outdir."
echo " Note: The script shall create outdir if absent."
echo " Default number of threads are half the threads on a machine."
echo " On a single core machine this is one."
echo
echo " Help shall be provided when faced with wrong/inconsistent arguments."
echo " Or, when the -h flag is supplied."
echo
echo " Note: The script has been written to work in the background."
echo " It shall return very quickly leaving processes running behind."
echo " Use top to determine when these processes end."
echo
}

## The following two functions shall parse command line arguments.

function parse_arg {
case "$1" in
  -i=*)
    INDIR=$(echo "$1" | cut -f 2- -d '=')
    ;;
  -o=*)
    OUTDIR=$(echo "$1" | cut -f 2- -d '=')
    ;;
  -s=*)
    STOCKLIST=$(echo "$1" | cut -f 2- -d '=')
    ;;
  -n=*)
    NCORES=$(echo "$1" | cut -f 2- -d '=')
    ;;
  -h)
    WANTHELP="y"
    ;;
  *)
    WANTHELP="y"
    ;;
esac
}

function parse_args {
for d in $*; do
  parse_arg "$d"
done
}

## Small routines. 

function make_dir_if_not_found(){
if ! [[ -e "$1" ]]; then
  mkdir -p "$1"
fi
}

function grep_stock(){
zcat "$1" | egrep "$2.*$3.*$4"
}

function break_input_for_threads(){
find "$INDIR" -name ob_*gz -type f > /tmp/_list_.txt
split -n $NCORES /tmp/_list_.txt /tmp/_list_
}

## Determines the work to be done by a thread.

function thread(){
for FILE in $(cat "$1"); do
  DIRNAME=$(echo "$FILE" | awk -F '/' '{print $(NF-1)}')
  make_dir_if_not_found "$OUTDIR"/"$DIRNAME"
  TIME=$(echo "$FILE" | awk -F '/' '{print $NF}')
  TIME=${TIME:3:2}
  for STOCK in $(cat "$STOCKLIST"); do
    grep_stock "$FILE" "$STOCK" "EQ" "RL" >> "$OUTDIR"/"$DIRNAME"/"$STOCK"_"$TIME".txt
  done
done
}

# Main:

if [[ $# -lt 1 || $# -gt 4 ]]; then ## Sanity checks: ensure valid arguments.
  WANTHELP="y"
fi

parse_args $*

if [[ "$WANTHELP" == "y" ]]; then
  print_help
  exit 1
fi

make_dir_if_not_found "$OUTDIR"
break_input_for_threads
for LIST in /tmp/_list_* ; do thread "$LIST" & done 

exit 0
