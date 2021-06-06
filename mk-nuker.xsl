<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:pom="http://maven.apache.org/POM/4.0.0">
    <xsl:output method="text"/>

    <xsl:template match="/">
        <xsl:text>#!/bin/sh
# Script for deleting entries in the local maven repository.
# Does not take transitive dependencies into account.

REPOS=$HOME/.m2/repository
NUKE="rm -rf"

</xsl:text>
        <xsl:apply-templates select="pom:project/pom:dependencies/pom:dependency"/>
    </xsl:template>

    <xsl:template match="pom:dependency">
        <xsl:text>${NUKE} ${REPOS}/</xsl:text>
        <xsl:value-of select="translate(pom:groupId, '.', '/')"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="pom:artifactId/text()"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="pom:version"/>
        <xsl:text>
</xsl:text>
    </xsl:template>
</xsl:stylesheet>