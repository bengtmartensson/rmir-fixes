#! /bin/bash

# Script for downloading and installing of RMIR
#
# Author: Bengt Martensson, barf@bengt-martensson.de
# License: public domain

PROJECT=rmir
COMMANDS="rmir rmdu rmpb"

# Where the files are installed, modify if desired.
# Can be overridden from the command line.
if [ $(id -u) -eq 0 ] ; then
    PREFIX=/usr/local
else
    PREFIX=${HOME}
fi

# Where the desktop files go
if [ $(id -u) -eq 0 ] ; then
    DESKTOPDIR=${PREFIX}/share/applications
else
    DESKTOPDIR=${PREFIX}/.local/share/applications
fi

# URL for downloading current version.
URL=https://sourceforge.net/projects/controlremote/files/latest/download

INDEX_URL=https://sourceforge.net/projects/controlremote/files/RMIRDevelopment/

# Temporary file to download to
DOWNLOAD=${TMPDIR:-/tmp}/${PROJECT}$$.zip
INDEX_DOWNLOAD=${TMPDIR:-/tmp}/${PROJECT}_index$$

fixdesktop()
{
    upper="$(echo $1 | tr '[a-z]' '[A-Z]')"
    sed -e "s|Exec=.*|Exec=${LINKDIR}/${1}|" "${RMHOME}/$upper.desktop" > ${DESKTOPDIR}/$upper.desktop
}

mklink()
{
    if [ $(readlink -f -- "$1") != "${WRAPPER}" ] ; then
	ln --symbolic --force $(realpath --relative-to="${LINKDIR}" "${WRAPPER}") "${LINKDIR}/$1"
        echo "Command $1 created."
    fi
}

mkwrapper()
{
    cat > ${WRAPPER} <<EOF
#!/bin/sh
#
# Wrapper for RMDU/RMIR/RMPB on Unix-like system

# Set JAVA to the command that should be used to invoke the program,
# can be absolute or sought in the path.
# Presently, at least Java version 8 is needed.
JAVA=\${JAVA:-${JAVA}}

SCALE_ARG=-Dsun.java2d.uiScale=\${SCALE_FACTOR:-${SCALE_FACTOR}}

export RMHOME="\$(dirname -- "\$(readlink -f -- "\${0}")" )"

if [ "\$(basename "\$0")" = "rmir" -o "\$(basename "\$0")" = "rmir.sh" ] ; then
    ARG=-ir
elif [ "\$(basename "\$0")" = "rmpb" ] ; then
    ARG=-pb
else
    ARG=-rm
fi

EOF

if [ -n "${WRITEABLE}" ] ; then
    cat >> ${WRAPPER} <<EOF
exec "\${JAVA}" \${SCALE_ARG} -Djava.library.path="\${RMHOME}" \\
     -jar "\${RMHOME}/RemoteMaster.jar" \\
     -h "\${RMHOME}" \${ARG} \\
     "\$@"
EOF
else
    cat >> ${WRAPPER} <<EOF
# Making the program(s) Freedisktop compatible.
XDG_CONFIG_HOME=\${XDG_CONFIG_HOME:-\${HOME}/.config}
XDG_CACHE_HOME=\${XDG_CACHE_HOME:-\${HOME}/.cache}

CACHE_HOME=\${XDG_CACHE_HOME}/${PROJECT}
CONFIG_HOME=\${XDG_CONFIG_HOME}/${PROJECT}

if [ ! -d "\${CONFIG_HOME}" ] ; then
    mkdir -p "\${CONFIG_HOME}"
fi
if [ ! -d "\${CACHE_HOME}" ] ; then
    mkdir -p "\${CACHE_HOME}"
fi

CONFIG=\${CONFIG_HOME}/properties

exec "\${JAVA}" \${SCALE_ARG} -Djava.library.path="\${RMHOME}" \\
     -jar "\${RMHOME}/RemoteMaster.jar" \\
     -h "\${RMHOME}" -properties "\${CONFIG}" \\
     -errors "\${CACHE_HOME}/rmaster.err" \${ARG} \\
     "\$@"
EOF
fi

    chmod +x ${WRAPPER}
    echo "Created wrapper ${WRAPPER}."
}

assertwget()
{
    if ! wget --version > /dev/null ; then
        echo "The command \"wget\" is missing or broken."
        echo "Please install it, for example with apt-get or dnf."
        exit 1
    fi
}

# Command to invoke the Java JVM. Can be an absolute or relative file name,
# or a command sought in the PATH.
if [ -z "$JAVA" ] ; then
    JAVA=java
fi

# Scaling factor for the GUI. Does not work with all JVMs;
# some JVMs accept only integer arguments.
if [ -z "$SCALE_FACTOR" ] ; then
    SCALE_FACTOR=1
fi

# Where to install the files
if [ -z "$RMHOME" ] ; then
    RMHOME=${PREFIX}/share/${PROJECT}
fi

# Where the executable links go.
if [ -z "$LINKDIR" ] ; then
    LINKDIR=${PREFIX}/bin
fi

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
    echo "    -d, --development                 Try to download from the development folder instead of \"latest\"."
    echo "    -?, -h, --help                    Display this help and exit."
    echo "    -j, --java command-for-java       Command to invoke Java, default \"${JAVA}\"."
    echo "    -s, --scale scale-factor          scale factor for the GUI, default ${SCALE_FACTOR}. Not supported by all JVMs."
    echo "    -H, --rmhome RM-install-dir       Directory in which to install, default ${RMHOME}."
    echo "    -l, --link directory-for-links    Directory in which to create start links, default ${LINKDIR}."
    echo "    -u, --uninstall                   Undo previous installation."
    echo "    -w, --writeable-install           Write config and logs in installation directory."
    echo ""
    echo "This script should be run with the privileges necessary for writing"
    echo "to the locations selected."
}

while [ -n "$1" ] ; do
    case $1 in
        -d | --development )    DEVELOPMENT="y"
                                ;;
        -\? | -h | --help )     usage
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
        -H | --home | --rmhome ) shift
                                RMHOME=$(realpath "$1")
                                ;;
        -u | --uninstall )      UNINSTALL="y"
                                ;;
        -w | --writeable-install ) WRITEABLE="y"
                                ;;
        * )                     ZIP="$1"
                                ;;
    esac
    shift
done

# Generated wrapper
WRAPPER=${RMHOME}/${PROJECT}.sh

if [ -n "${UNINSTALL}" ] ; then
    read -p "You sure you want to deinstall RMIR in directory ${RMHOME} (y/n)? " ans
    if [ "${ans}" != "y" ] ; then
        echo "Bailing out, nothing deleted."
        exit 0
    fi

    rm -rf "${RMHOME}"

    for c in ${COMMANDS}; do
        upper="$(echo $c | tr '[a-z]' '[A-Z]')"
        rm  -f ${DESKTOPDIR}/$upper.desktop
        rm -f ${LINKDIR}/$c
    done
    rm -f ${LINKDIR}/remotemaster

    echo "RMIR and friends successfully uninstalled."
    echo "Personal configuration files have not been deleted."
    exit 0
fi

if [ -n "${DEVELOPMENT}" ] ; then
    if [ -n "${ZIP}" ] ; then
        echo "Must not use --development together with file name"
        exit 1
    fi

    # Download the index file and parse it.
    # This is not a well-formed XML file (it is HTML, with "junk" within <script> elements),
    # so we have to parse it in an ad-hoc way. This code is of course somewhat fragile.
    assertwget
    wget --no-verbose -O "${INDEX_DOWNLOAD}" "${INDEX_URL}"
    URL=$(grep 'https://sourceforge.net/projects/controlremote/files/RMIRDevelopment/RMIR\.v2.*-bin.zip/download' "${INDEX_DOWNLOAD}" \
        | grep scope \
        | sed -e 's/<th scope="row" headers="files_name_h"><a href="//' -e 's/"//' -e 's/^ +//' \
        | head --lines 1)
    rm -f "${INDEX_DOWNLOAD}"
fi

if [ -z ${ZIP} ] ; then
    assertwget

    echo "Downloading ${URL} from SourceForge or a mirror..."
    wget --no-verbose -O "${DOWNLOAD}" ${URL}  || exit 1
    ZIP=${DOWNLOAD}
    DID_DOWNLOAD=yes
fi

if [ ! -d "${RMHOME}" ] ; then
    mkdir -p "${RMHOME}" || exit 1
fi

cd "${RMHOME}" || exit 1
rm -rf * || exit 1
unzip -q "${ZIP}" || exit 1

# Invoke RMIR's setup. If it fails, bail out.
# Since we are setting scaling in the wrapper, make the setup script non-interactive.
sh ./setup.sh < /dev/null || exit 1

mkwrapper

if [ ! -d ${LINKDIR} ] ; then
    mkdir -p ${LINKDIR} || exit 1
fi

if [ ! -d ${DESKTOPDIR} ] ; then
    mkdir -p ${DESKTOPDIR} || exit 1
fi

for c in ${COMMANDS}; do
    mklink $c
    fixdesktop $c
done
mklink remotemaster

if [ -n "${DID_DOWNLOAD}" ] ; then
    if tty --quiet ; then
       read -p "Delete downloaded file ${ZIP} (y/n)? " ans
        if [ "${ans}" = "y" ] ; then
            rm ${ZIP}
        else
            echo "You can tweak the installation with the command \"$0 [options] ${ZIP}\"."
        fi
    else
        rm ${ZIP}
    fi
fi
