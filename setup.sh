#! /bin/sh

RMHOME=/usr/local/rmir
BIN=/usr/local/bin
desktopdir=$HOME/.local/share/applications

fixdesktop()
{
    TEMPFILE=/tmp/${1}$$
    sed -e "s|Exec=.*|Exec=${BIN}/${2}|" -e "s/Categories=.*/Categories=AudioVideo;Java;/" < ${desktopdir}/$1.desktop > ${TEMPFILE}
    mv ${TEMPFILE} ${desktopdir}/$1.desktop
}

HERE="$(dirname -- "$(readlink -f -- "${0}")" )"

if [ ! -d ${RMHOME} ] ; then
    mkdir ${RMHOME}
fi

if [ -f "$1" ] ; then
    ZIP=$(readlink -f -- $1)
    cd ${RMHOME}
    rm -rf *
    unzip ${ZIP}
    sh ./setup.sh
fi

install ${HERE}/rmir.sh ${RMHOME}
ln -sf ${RMHOME}/rmir.sh ${BIN}/rmir
ln -sf ${RMHOME}/rmir.sh ${BIN}/remotemaster
ln -sf ${RMHOME}/rmir.sh ${BIN}/rmpb

fixdesktop RemoteMaster remotemaster
fixdesktop RMIR rmir
fixdesktop RMPB rmpb
