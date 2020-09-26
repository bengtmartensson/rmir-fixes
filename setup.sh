#! /bin/sh

# Script for downloading and installing of RMIR
#
# Author: Bengt Martensson
# License: public domain

# Where the files go, modify if desired
RMHOME=/usr/local/rmir

# Where the executable links go, should probably not modify
BIN=/usr/local/bin

# Where the desktiop files go, change only if you know what you are doing
DESKTOPDIR=$HOME/.local/share/applications

# Should probably not change
URL=https://sourceforge.net/projects/controlremote/files/latest/download

# Should probably not change
DOWNLOAD=/tmp/rmir$$.zip

fixdesktop()
{
    sed -e "s|Exec=.*|Exec=${BIN}/${2}|" -e "s/Categories=.*/Categories=AudioVideo;Java;/" "${RMHOME}/$1.desktop" > ${DESKTOPDIR}/$1.desktop
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
#JAVA_HOME=/opt/jdk1.8.0_112
#JAVA=\${JAVA_HOME}/bin/java
JAVA=\${JAVA:-java}

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

FILES=\$(realpath "\$@")

cd "\$RMHOME"

exec "\${JAVA}" -Djava.library.path="\${RMHOME}" \
     -jar "\${RMHOME}/RemoteMaster.jar" \
     -h "\${RMHOME}" -properties "\${CONFIG}" \
     -errors "\${CACHE_HOME}/rmaster.err" \${ARG} \
     \$FILES
EOF

    chmod +x ${RMHOME}/rmir.sh
}

if [ ! -d "${RMHOME}" ] ; then
    mkdir "${RMHOME}"
fi

if [ $# -eq 0 ] ; then
    wget -O "${DOWNLOAD}" $URL
    ZIP=$DOWNLOAD
fi

if [ -f "$1" ] ; then
    ZIP=$(readlink -f -- "$1")
fi

if [ -f "$ZIP" ] ; then 
    cd "${RMHOME}"
    rm -rf *
    unzip -q "${ZIP}"
    sh ./setup.sh
fi

mkwrapper

mklink ${RMHOME}/rmir.sh ${BIN}/rmir
mklink ${RMHOME}/rmir.sh ${BIN}/remotemaster
mklink ${RMHOME}/rmir.sh ${BIN}/rmdu
mklink ${RMHOME}/rmir.sh ${BIN}/rmpb

fixdesktop RMDU rmdu
fixdesktop RMIR rmir
fixdesktop RMPB rmpb
