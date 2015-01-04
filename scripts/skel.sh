#!/bin/sh

# $1: file to skeletonise
# $2: output file

/Applications/MATLAB_R2013b.app/bin/matlab -nodesktop -nojvm -nosplash -r "skel('$1', '$2'); exit;"
