#!/bin/bash

###########################################
# Script for "Printifying" PDF Files
#
# This script processes a PDF file by converting it to grayscale
# and applying brightness and contrast adjustments. The resulting
# PDF is then resized to the specified paper format (default is A4)
# and saved as a new file.
#
# Options:
#  -p, --paperformat  Set the paper format (default: a4paper)
#  -r, --resolution   Set the resolution for the output images (default: 300)
#  -b, --brightness   Set the brightness adjustment (default: 5)
#  -c, --contrast     Set the contrast adjustment (default: 45)
#  -q, --quiet        Run the script with minimal output (no logging)
#  -h, --help         Display a help message and exit
#
# Example usage:
# ./script.sh input.pdf -r 600 -b 10 -c 50 -p letterpaper
#
# Dependencies:
# - pdftoppm (to convert PDF to images)
# - convert (from ImageMagick for image manipulation)
# - pdftk (to concatenate PDFs)
# - pdfjam (to resize PDFs)
#
# Author: Florian Jäckel (tutebatti)
# Date: 2024-11
###########################################

# Default values
resolution=300
pageformat="a4paper"
brightness=5
contrast=45

# Parse command-line arguments (flags)
parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -p|--paperformat)
                pageformat="$2"
                shift 2
                ;;
            -r|--resolution)
                resolution="$2"
                shift 2
                ;;
            -b|--brightness)
                brightness="$2"
                shift 2
                ;;
            -c|--contrast)
                contrast="$2"
                shift 2
                ;;
            -q|--quiet)
                quiet=True
                shift
                ;;
            -h|--help)
                echo "Usage: $0 <input_pdf> [-p paperformat] [-r resolution] [-b brightness] [-c contrast] [-q|--quiet]"
                echo "  -p, --paperformat  Set the paper format (default: a4paper)"
                echo "  -r, --resolution   Set the resolution for the output images (default: 300)"
                echo "  -b, --brightness   Set the brightness adjustment (default: 5)"
                echo "  -c, --contrast     Set the contrast adjustment (default: 45)"
                echo "  -q, --quiet        Run the script with minimal output (no logging)"
                exit 0
                ;;
            *)
                infile="$1"
                shift
                ;;
        esac
    done
}

check_input() {
    if [ -z "$infile" ]; then
        echo "Usage: $0 <input_pdf> [-p paperformat] [-r resolution] [-b brightness] [-c contrast]"
        exit 1
    fi
    if [ ! -f "$infile" ]; then
        echo "Input file '$infile' does not exist."
        exit 1
    fi
}

check_integer() {
    local value="$1"
    if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
        echo "Invalid value '$value'. Please provide a valid integer."
        return 1
    fi
    return 0
}

check_if_command_is_installed() {
    local cmd="$1"
    if ! command -v "$cmd" > /dev/null 2>&1; then
        echo "'$cmd' is not installed. Please install it and try again."
        return 1
    fi
    return 0
}

check_overwrite() {
    if [ -e "$outfile" ]; then
        echo "Output file '$outfile' already exists."
        while true; do
            read -p "Do you want to overwrite it? (y/n): " response
            case "$response" in
                [Yy]*)
                    echo "Overwriting the file."
                    break
                    ;;
                [Nn]*)
                    echo "Please specify a different output file name or move the existing file."
                    exit 1
                    ;;
                *)
                    echo "Invalid response. Please enter 'y' or 'n'."
                    ;;
            esac
        done
    fi
}

# Quiet handling for commands
run_command() {
    local cmd="$1"
    shift
    if [ -z "$quiet" ]; then
        "$cmd" "$@"
    else
        "$cmd" "$@" &>/dev/null
    fi
    if [ $? -ne 0 ]; then
        echo "Error: '$cmd' failed"
        exit 1
    fi
}

# Main execution starts here

# Check if necessary commands are installed
commands=("pdftoppm" "convert" "pdftk" "pdfjam")
for cmd in "${commands[@]}"; do
    check_if_command_is_installed "$cmd" || exit 1
done

parse_args "$@"
outfile=${infile%.pdf}_printified.pdf

check_input
check_integer "$brightness" || exit 1
check_integer "$resolution" || exit 1
check_integer "$contrast" || exit 1
check_overwrite

# Temporary directory for intermediate files
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"; echo "Temporary files cleaned up."' EXIT

echo "Printifying $infile"

# Generate PNG files from the input PDF
echo "Generating PNG files with resolution of $resolution DPI"
run_command pdftoppm -png -r "$resolution" "$infile" "$tmpdir/.p"

# Create adapted versions of the PNG files
echo "Creating adapted versions of each PNG"
run_command find "$tmpdir" -name ".p*.png" -execdir \
    convert -density "$resolution" "{}" -adaptive-sharpen 1 -colorspace Gray -brightness-contrast "${brightness}x${contrast}" -quality 100 "{%.png}_adapted.png" \;

# Convert adapted PNG files to PDFs
echo "Converting adapted PNG files to PDFs"
run_command find "$tmpdir" -name "*_adapted.png" -execdir \
    convert "{}" "{%.png}.pdf" \;

# Concatenate the individual PDFs into one
echo "Concatenating individual PDFs"
run_command pdftk "$tmpdir"/*_adapted.pdf cat output "$tmpdir/bw.pdf"

# Resize PDF to the desired page format
echo "Resizing PDF to desired page format"
run_command pdfjam --paper "$pageformat" --outfile "$outfile" "$tmpdir/bw.pdf"

echo "Done. Output saved to $outfile"
exit 0
