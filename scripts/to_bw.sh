#!/bin/sh

# $1: file to convert
# $2: output file
# $3: threshold

/Applications/MATLAB_R2013b.app/bin/matlab -nodesktop -nojvm -nosplash -r "to_bw('$1', '$2', $3); exit;"
