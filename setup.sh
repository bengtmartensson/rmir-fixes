#! /bin/sh

RMHOME=/usr/local/rmir
BIN=/usr/local/bin
DESKTOPDIR=$HOME/.local/share/applications
URL=https://sourceforge.net/projects/controlremote/files/latest/download
DOWNLOAD=/tmp/rmir$$.zip

fixdesktop()
{
    TEMPFILE=/tmp/${1}$$
    sed -e "s|Exec=.*|Exec=${BIN}/${2}|" -e "s/Categories=.*/Categories=AudioVideo;Java;/" < ${DESKTOPDIR}/$1.desktop > ${TEMPFILE}
    mv ${TEMPFILE} ${DESKTOPDIR}/$1.desktop
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
ln -sf ${RMHOME}/rmir.sh ${BIN}/rmir
ln -sf ${RMHOME}/rmir.sh ${BIN}/remotemaster
ln -sf ${RMHOME}/rmir.sh ${BIN}/rmdu
ln -sf ${RMHOME}/rmir.sh ${BIN}/rmpb

fixdesktop RemoteMaster remotemaster
fixdesktop RMIR rmir
fixdesktop RMPB rmpb
