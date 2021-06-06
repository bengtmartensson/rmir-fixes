#!/bin/sh

RMHOME="$(dirname -- "$(readlink -f -- "${0}")" )"

PROG=$RMHOME/$(basename $0)

REPOS=$RMHOME/repository

if [ $# = 0 ] ; then
    exec $PROG $REPOS
fi

if [ -d $1 ] ; then
    cd $1
    for f in * ; do
        $PROG $f
    done
else
    case $1 in
        *.jar | *.pom | *.xml )
            md5sum  $1 > $1.md5
            sha1sum $1 > $1.sha1
            ;;
        * )
            ;;
    esac
fi