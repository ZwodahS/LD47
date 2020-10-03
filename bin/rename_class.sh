#!/bin/bash

# sometimes I just want to rename a class to another name because I was dumb
# this script is destructive

if [ -z "$1" -o -z "$2" ]; then
    echo "$(basename $0) [old name] [new name]";
fi

find . -name '*.hx' -exec sed -i '.bak' "s/$1/$2/g" {} \;
find . -name '*.hx.bak' -exec rm {} \;
for file in $(find . -name "$1.hx"); do
    echo $file;
    dir=$(dirname $file);
    mv -f $file $dir/$2.hx;
done
