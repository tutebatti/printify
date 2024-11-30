# printify.sh

Script for "Printifying" PDF Files

This script processes a PDF file by converting it to grayscale
and applying brightness and contrast adjustments. The resulting
PDF is then resized to the specified paper format (default is A4)
and saved as a new file.

Options:
 -p, --paperformat  Set the paper format (default: a4paper)
 -r, --resolution   Set the resolution for the output images (default: 300)
 -b, --brightness   Set the brightness adjustment (default: 5)
 -c, --contrast     Set the contrast adjustment (default: 45)
 -Q, --quality      Set the quality (default: 80)
 -q, --quiet        Run the script with minimal output (no logging)
 -h, --help         Display a help message and exit

Example usage:
./script.sh input.pdf -r 600 -b 10 -c 50 -p letterpaper

Dependencies:

- pdftoppm (to convert PDF to images)
- convert (from ImageMagick for image manipulation)
- pdftk (to concatenate PDFs)
- gs (to resize PDFs)

Author: Florian Jäckel (tutebatti)
Date: 2024-11
