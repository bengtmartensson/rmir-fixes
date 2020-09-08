#!/bin/sh
#
# Wrapper for RemoteMaster/RMIR/RMPB on Unix-like system
#
# Author: Bengt Martensson
#
# To use: Unpack the distribution to a local directory,
# suggestion: /usr/local/rmir.
# In particular, this wrapper goes there under the name rmir.sh
# Adjust the variable JAVA_HOME and/or JAVA, and RMHOME accordingly.
# Make links from somewhere in your path, to have the commands
# rmir (and/or rmaster) and rmir available. For example
#   ln -s /usr/local/rmir/rmir.sh /usr/local/bin/rmir
#   ln -s /usr/local/rmir/rmir.sh /usr/local/bin/remotemaster
#   ln -s /usr/local/rmir/rmir.sh /usr/local/bin/rmpb
#
# Unless the libjp1parallel.so is used (which is not a good idea),
# this script needs not, and should not, be run as root.

# Set JAVA to the command that should be used to invoke the program,
# can be absolute or sought in the path.
# Presently, at least Java version 8 is needed.
#JAVA_HOME=/opt/jdk1.8.0_112
#JAVA=${JAVA_HOME}/bin/java
JAVA=${JAVA:-java}

export RMHOME="$(dirname -- "$(readlink -f -- "${0}")" )"

CACHE_HOME=${HOME}/.cache/rmir
CONFIG_HOME=${HOME}/.config/rmir
RDFS=${RMHOME}/RDF
MAPS=${RMHOME}/Images

if [ ! -d ${CONFIG_HOME} ] ; then
    mkdir -p ${CONFIG_HOME}
fi
if [ ! -d ${CACHE_HOME} ] ; then
    mkdir -p ${CACHE_HOME}
fi


# Normally, no changes below this line is necessary

CONFIG=${CONFIG_HOME}/properties
if [ ! -f ${CONFIG} ] ; then
    echo RDFPath=${RDFS}    > ${CONFIG}
    echo ImagePath=${MAPS} >> ${CONFIG}
fi

if [ `basename $0` = "rmir" ] ; then
    ARG=-ir
elif [ `basename $0` = "rmpb" ] ; then
    ARG=-pb
else
    ARG=-rm
fi

if [ $# -eq 1 ] ; then
    if [ "`dirname '$1'`" = "." ] ; then
	file=`pwd`/$1
    else
	file=$1
    fi
fi

cd $RMHOME

exec ${JAVA} -Djava.library.path=${RMHOME} -jar "${RMHOME}/RemoteMaster.jar" \
     -h "${RMHOME}" -properties "${CONFIG}" \
     -errors "${CACHE_HOME}/rmaster.err" ${ARG} \
     $file
