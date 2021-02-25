#! /bin/sh

# Script for downloading and installing of RMIR
#
# Author: Bengt Martensson, barf@bengt-martensson.de
# License: public domain

# Where the files are installed, modify if desired.
# Can be overridden from the command line.
RMHOME=/usr/local/share/rmir

# Where the executable links go-
# Can be overridden from the command line.
LINKDIR=/usr/local/bin

# Command to invoke the Java JVM. Can be an absolute or relative file name,
# or a command sought in the PATH.
# Can be overridden from the command line.
JAVA=java

# Scaling factor for the GUI. Does not work with all JVMs;
# some JVMs accept only integer arguments.
# Can be overridden from the command line.
SCALE_FACTOR=1

# Where the desktop files go, change only if you know what you are doing
DESKTOPDIR=$HOME/.local/share/applications

# Should probably not change
URL=https://sourceforge.net/projects/controlremote/files/latest/download

# Should probably not change
DOWNLOAD=/tmp/rmir$$.zip

fixdesktop()
{
    sed -e "s|Exec=.*|Exec=${LINKDIR}/${2}|" -e "s/Categories=.*/Categories=AudioVideo;/" "${RMHOME}/$1.desktop" > ${DESKTOPDIR}/$1.desktop
}

mklink()
{
    if [ $(readlink -f -- "$2") != "$1" ] ; then
	ln -sf "$1" "$2"
    fi
}

mkwrapper()
{
    cat > ${RMHOME}/rmir.sh <<EOF
#!/bin/sh
#
# Wrapper for RMDU/RMIR/RMPB on Unix-like system
# Makes the program(s) Freedisktop compatible.

# Set JAVA to the command that should be used to invoke the program,
# can be absolute or sought in the path.
# Presently, at least Java version 8 is needed.
JAVA=\${JAVA:-${JAVA}}

SCALE_ARG=-Dsun.java2d.uiScale=\${SCALE_FACTOR:-${SCALE_FACTOR}}

export RMHOME="\$(dirname -- "\$(readlink -f -- "\${0}")" )"

XDG_CONFIG_HOME=\${XDG_CONFIG_HOME:-\${HOME}/.config}
XDG_CACHE_HOME=\${XDG_CACHE_HOME:-\${HOME}/.cache}

CACHE_HOME=\${XDG_CACHE_HOME}/rmir
CONFIG_HOME=\${XDG_CONFIG_HOME}/rmir

if [ ! -d "\${CONFIG_HOME}" ] ; then
    mkdir -p "\${CONFIG_HOME}"
fi
if [ ! -d "\${CACHE_HOME}" ] ; then
    mkdir -p "\${CACHE_HOME}"
fi

CONFIG=\${CONFIG_HOME}/properties

if [ "\$(basename "\$0")" = "rmir" ] ; then
    ARG=-ir
elif [ "\$(basename "\$0")" = "rmpb" ] ; then
    ARG=-pb
else
    ARG=-rm
fi

if [ \$# -gt 0 ] ; then
    FILES=\$(realpath "\$@")
fi

cd "\$RMHOME"

exec "\${JAVA}" \${SCALE_ARG} -Djava.library.path="\${RMHOME}" \\
     -jar "\${RMHOME}/RemoteMaster.jar" \\
     -h "\${RMHOME}" -properties "\${CONFIG}" \\
     -errors "\${CACHE_HOME}/rmaster.err" \${ARG} \\
     \${FILES}
EOF

    chmod +x ${RMHOME}/rmir.sh
}

usage()
{
    echo "Usage: $0 [OPTIONS] [zip-file]"
    echo ""
    echo "Installs RMIR, RMDU, and RMPB in the system, compatible with the"
    echo "Freedesktop standard (https://www.freedesktop.org)."
    echo "If a zip-file is not given as argument, it is downloaded from"
    echo "${URL}."
    echo ""
    echo "Options:"
    echo "    -?, --help                        Display this help and exit."
    echo "    -j, --java command-for-java       Command to invoke Java, default \"${JAVA}\"."
    echo "    -s, --scale scale-factor          scale factor for the GUI, default ${SCALE_FACTOR}. Not supported by all JVMs."
    echo "    -h, --rmhome RM-install-dir       Directory in which to install, default ${RMHOME}."
    echo "    -l, --link directory-for-links    Directory in which to create start links, default ${LINKDIR}."
    echo ""
    echo "This script should be run with the privileges necessary for writing"
    echo "to the locations selected."
}

while [ -n "$1" ] ; do
    case $1 in
        -\? | --help )          usage
                                exit 0
                                ;;
        -j | --java )           shift
                                JAVA="$1"
                                ;;
        -s | --scale )          shift
                                SCALE_FACTOR="$1"
                                ;;
        -l | --linkdir )        shift
                                LINKDIR="$1"
                                ;;
        -h | --home | --rmhome ) shift
                                RMHOME="$1"
                                ;;
        * )                     ZIP="$1"
                                ;;
    esac
    shift
done

if [ -z ${ZIP} ] ; then
    wget -O "${DOWNLOAD}" $URL
    ZIP=$DOWNLOAD
fi

if [ ! -d "${RMHOME}" ] ; then
    mkdir "${RMHOME}" || exit 1
fi

cd "${RMHOME}" || exit 1
rm -rf *
unzip -q "${ZIP}"

# Invoke RMIR's setup.
sh ./setup.sh

mkwrapper

mklink ${RMHOME}/rmir.sh ${LINKDIR}/rmir
mklink ${RMHOME}/rmir.sh ${LINKDIR}/remotemaster
mklink ${RMHOME}/rmir.sh ${LINKDIR}/rmdu
mklink ${RMHOME}/rmir.sh ${LINKDIR}/rmpb

fixdesktop RMDU rmdu
fixdesktop RMIR rmir
fixdesktop RMPB rmpb
