#! /bin/bash

# Script for downloading and installing of RMIR
#
# Author: Bengt Martensson, barf@bengt-martensson.de
# License: public domain

PROJECT=rmir
COMMANDS="rmir rmdu rmpb remotemaster irptransmogrifier"

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

mkdesktop()
{
    upper="$(echo $1 | tr '[a-z]' '[A-Z]')"
    # Construct paths to the new files and to the jar file
    desktop_file=${RMHOME}/${upper}.desktop

    # Create the .desktop files.
    cat > "$desktop_file" << EOF
[Desktop Entry]
Comment=$2
Categories=AudioVideo
Terminal=false
Name=${upper}
Exec="${LINKDIR}/$1"
Type=Application
Icon=${RMHOME}/${upper}.ico
StartupNotify=true
Version=1.0
EOF

    ln -sf "$desktop_file" "${DESKTOPDIR}"
}

assert_dialout()
{
    # Test if the dialout group exists, exit with message if not
    if ! grep -q dialout /etc/group ; then
        echo "There is no group named \"dialout\" on your system." \
             "Access to serial devices cannot be guaranteed."
        return
    fi

    # Dialout group exists, test if user is a member, exit if so
    if id -Gn | grep -q dialout ; then
        return
    fi

    # User is not a member, test if user is root, exit if so
    if [ "$(id -u)" -eq 0 ]; then
        return
    fi

    # User is not root, so ask if user wishes to be added
    if ! modify_user ; then
        echo "You will need to run the command \"sudo usermod -aG dialout $USER\" " \
             "before \"$USER\" can use a USB serial interface with RMIR. " \
             "Then you need to log out and log in again for the change to take effect."
    fi
}

modify_user()
{
    # If no terminal access, bail out
    if ! tty --quiet ; then
        return 1
    fi

    echo "To use a USB serial interface with RMIR, \"$USER\" needs to be a member of the " \
         "dialout group, which is currently not so. This script can add \"$USER\" " \
         "to that group using sudo."

    read -p "Add \"$USER\" to group \"dialout\" (y/n)? " ans
    if [ "${ans}" = "y" ] ; then
        sudo usermod -aG dialout $USER || return 1
        echo "You will need to log out and log in again for the change to take effect."
        return 0
    else
        return 1
    fi
}

mklink()
{
    if [ "$(readlink -f -- "$1")" != "${WRAPPER}" ] ; then
	ln --symbolic --force "$(realpath --relative-to="${LINKDIR}" "${WRAPPER}")" "${LINKDIR}/$1"
        echo "Command $1 created."
    fi
}

mkwrapper()
{
    cat > "${WRAPPER}" <<EOF
#!/bin/sh
#
# Wrapper for RMDU/RMIR/RMPB/irptransmogrifier on Unix-like system

# Set JAVA to the command that should be used to invoke the program,
# can be absolute or sought in the path.
# Presently, at least Java version 8 is needed.
JAVA=\${JAVA:-${JAVA}}

export RMHOME="\$(dirname -- "\$(readlink -f -- "\${0}")" )"
JAR=\${RMHOME}/RemoteMaster.jar

if [ "\$(basename "\$0")" = "irptransmogrifier" ] ; then
    MAINCLASS=org.harctoolbox.irp.IrpTransmogrifier
    exec "\${JAVA}" \\
         -cp "\${JAR}" \\
         "\${MAINCLASS}" \\
         "\$@" # does not return
fi

if [ "\$(basename "\$0")" = "rmir" -o "\$(basename "\$0")" = "rmir.sh" ] ; then
    ARG=-ir
elif [ "\$(basename "\$0")" = "rmpb" ] ; then
    ARG=-pb
else
    ARG=-rm
fi

EOF

if [ -n "${SCALE_FACTOR}" ] ; then
    echo "# Scaling factor" >> ${WRAPPER}
    echo "SCALE_ARG=\"-scaling ${SCALE_FACTOR}\"" >> ${WRAPPER}
    echo "" >> ${WRAPPER}
fi

if [ -n "${WRITEABLE}" ] ; then
    cat >> ${WRAPPER} <<EOF
exec "\${JAVA}" -Djava.library.path="\${RMHOME}" \\
     -jar "\${RMHOME}/RemoteMaster.jar" \\
     -home "\${RMHOME}" \${ARG} \${SCALE_ARG} \\
     "\$@"
EOF
else
    cat >> "${WRAPPER}" <<EOF
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

exec "\${JAVA}" -Djava.library.path="\${RMHOME}" \\
     -jar "\${JAR}" \\
     -home "\${RMHOME}" -properties "\${CONFIG}" \\
     -errors "\${CACHE_HOME}/rmaster.err" \${ARG} \${SCALE_ARG} \\
     "\$@"
EOF
fi

    chmod +x "${WRAPPER}"
    echo "Created wrapper \"${WRAPPER}\"."
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
    echo "    -s, --scale scale-factor          scale factor for the GUI, default 1. Not supported by all JVMs."
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
                                RMHOME=$(realpath --canonicalize-missing "$1")
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
        rm -f "${DESKTOPDIR}/$upper.desktop"
        rm -f "${LINKDIR}/$c"
    done
    rm -f ${LINKDIR}/remotemaster

    echo "RMIR and friends successfully uninstalled."
    read -p "Want to delete the error file and your personal preferences (y/n)? " ans
    if [ "${ans}" = "y" ] ; then
        XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-${HOME}/.config}
        XDG_CACHE_HOME=${XDG_CACHE_HOME:-${HOME}/.cache}
        CACHE_HOME=${XDG_CACHE_HOME}/${PROJECT}
        CONFIG_HOME=${XDG_CONFIG_HOME}/${PROJECT}
        CONFIG=${CONFIG_HOME}/properties
        rm -f "${CONFIG}" "${CACHE_HOME}/rmaster.err"
    else
        echo "Personal configuration files have not been deleted."
    fi
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
    URL=$(grep 'https://sourceforge.net/projects/controlremote/files/RMIRDevelopment/RMIR\.v3.*-bin.zip/download' "${INDEX_DOWNLOAD}" \
        | grep scope \
        | sed -e 's/<th scope="row" headers="files_name_h"><a href="//' -e 's/"//' -e 's/^ +//' -e 's/title=.*$//' \
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
echo "Unpacked to directory ${RMHOME}".

mkwrapper

if [ ! -d "${LINKDIR}" ] ; then
    mkdir -p "${LINKDIR}" || exit 1
fi

if [ ! -d "${DESKTOPDIR}" ] ; then
    mkdir -p "${DESKTOPDIR}" || exit 1
fi

mkdesktop rmir "Edit JP1 remotes"
mkdesktop rmdu "Edit JP1 device upgrades"
mkdesktop rmpb "Edit JP1 protocols"
for c in ${COMMANDS}; do
    mklink $c
done
echo "Desktop files created and linked."

assert_dialout

# URC6440/OARUSB04G support
if [ ! -f /etc/udev/rules.d/6440-usbremote.rules ] ; then
    echo "If using URC6440/OARUSB04G, see \"${RMHOME}/URC6440_OARUSB04G_LinuxSupport/Instructions.txt\""
fi

# XSight support
if [ ! -f /etc/udev/rules.d/linux_xsight.rules ] ; then
    echo "If using XSight, consider adding udev rules for XSight with the command:"
    echo "sudo cp \"${RMHOME}/linux_xsight.rules /etc/udev/rules.d\""
fi

if [ -n "${DID_DOWNLOAD}" ] ; then
    if tty --quiet ; then
       read -p "Delete downloaded file ${ZIP} (y/n)? " ans
        if [ "${ans}" = "y" ] ; then
            rm ${ZIP}
        else
            echo "You can tweak the installation (without new download) with the command \"$0 [options] ${ZIP}\"."
        fi
    else
        rm ${ZIP}
    fi
fi
