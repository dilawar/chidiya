#!/bin/bash
set -e
set -x
rm -f *.png *.eps
filename="$1"
python setup.py build_ext --inplace
if [[ $2 = "x" ]]; then
    echo "Extracting notes"
    python main.py -in $filename --extract_notes -c chidiya.conf
else
    echo "processing notes"
    python main.py -in $filename --process_notes -c chidiya.conf 
fi
