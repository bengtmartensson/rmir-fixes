#! /bin/sh

RMHOME=/usr/local/rmir
BIN=/usr/local/bin
DESKTOPDIR=$HOME/.local/share/applications
URL=https://sourceforge.net/projects/controlremote/files/latest/download
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

HERE="$(dirname -- "$(readlink -f -- "${0}")" )"

if [ ! -d ${RMHOME} ] ; then
    mkdir ${RMHOME}
fi

if [ "$1" = "-d" ] ; then
    wget -O $DOWNLOAD $URL
    ZIP=$DOWNLOAD
fi

if [ -f "$1" ] ; then
    ZIP=$(readlink -f -- $1)
fi

if [ -f "$ZIP" ] ; then 
    cd ${RMHOME}
    rm -rf *
    unzip -q ${ZIP}
    sh ./setup.sh
fi

install ${HERE}/rmir.sh ${RMHOME}

mklink ${RMHOME}/rmir.sh ${BIN}/rmir
mklink ${RMHOME}/rmir.sh ${BIN}/remotemaster
mklink ${RMHOME}/rmir.sh ${BIN}/rmdu
mklink ${RMHOME}/rmir.sh ${BIN}/rmpb

fixdesktop RMDU rmdu
fixdesktop RMIR rmir
fixdesktop RMPB rmpb
