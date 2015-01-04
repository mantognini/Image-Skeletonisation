#!/bin/sh

pushd `dirname $0`/..

mkdir -p logs/

uuid=`date "+%Y.%m.%d@%H%M"`

mainlog=logs/"skeleton.$uuid.txt"

function clean_up
{
    echo "\nABORTING!" 1>&2
    exit $1
}

trap clean_up SIGHUP SIGINT SIGTERM

echo "SESSION ID: $uuid" | tee -a "$mainlog"
echo "GIT STATE: `git log --pretty=oneline -n 1`" | tee -a "$mainlog"
echo "TIME: `date`" | tee -a "$mainlog"

for input in resources/bw/*
do
    img=`basename $input`
    echo "Measuring $img..." | tee -a "$mainlog"

    for binary in bin/skeleton_*
    do
        exe=`basename $binary`
        log=logs/"$exe.$uuid.csv"

        echo "Running $exe with $img... [$log]" | tee -a "$mainlog"

        out=resources/skel/$exe.$uuid.$img
        # { time ./$binary --input "$input" --output "$out"; } 2>&1 | tee -a "$log"
        ./$binary --input "$input" --output "$out" >> "$log"
    done
    echo | tee -a "$mainlog"
done

popd
