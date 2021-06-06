#!/bin/sh
# Script for deleting entries in the local maven repository.
# Does not take transitive dependencies into account.

REPOS=$HOME/.m2/repository
NUKE="rm -rf"

${NUKE} ${REPOS}/jlfgr/jlfgr/1.0
${NUKE} ${REPOS}/com/codeminders/hidapi/1.1
${NUKE} ${REPOS}/org/apache/commons/commons-lang3/3.4
${NUKE} ${REPOS}/com/fazecast/jSerialComm/2.5.0
${NUKE} ${REPOS}/tablelayout/TableLayout/20050920
${NUKE} ${REPOS}/com/l2fprod/common/l2fprod-common-directorychooser/6.9.1
${NUKE} ${REPOS}/org/harctoolbox/Girr/2.2.10-SNAPSHOT
${NUKE} ${REPOS}/org/harctoolbox/IrpTransmogrifier/1.2.10-SNAPSHOT
${NUKE} ${REPOS}/com/hifiremote/jp1/ExtInstall/2.0.0
${NUKE} ${REPOS}/org/thingml/bglib-protocol-1.0.3-43/1.1.0
${NUKE} ${REPOS}/net/sf/jni4net/jni4net.j/0.8.9.0
${NUKE} ${REPOS}/org/testng/testng/7.3.0
