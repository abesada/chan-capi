#!/bin/sh
#
# create_config.sh
#
# Script to create config.h for compatibility with
# different asterisk versions.
#
# (C) 2005 Cytronics & Melware
# Armin Schindler <armin@melware.de>
#

CONFIGFILE="config.h"
rm -f "$CONFIGFILE"

VER=1_2

if [ $# -lt 1 ]; then
	echo >&2 "Missing argument"
	exit 1
fi

INCLUDEDIR="$1/asterisk"

if [ ! -d "$INCLUDEDIR" ]; then
	echo >&2 "Include directory '$INCLUDEDIR' does not exist"
	exit 1
fi

echo -n "Checking Asterisk version... "
AVERSION=`sed -n '/.*ASTERISK_VERSION /s/^.*ASTERISK_VERSION //p' $INCLUDEDIR/version.h`
AVERSION=`echo $AVERSION | sed 's/\"//g'`
echo $AVERSION

echo "/*" >$CONFIGFILE
echo " * automatically generated by $0 `date`" >>$CONFIGFILE
echo " */" >>$CONFIGFILE
echo >>$CONFIGFILE
echo "#ifndef CHAN_CAPI_CONFIG_H" >>$CONFIGFILE
echo "#define CHAN_CAPI_CONFIG_H" >>$CONFIGFILE
echo >>$CONFIGFILE

if grep -q "ASTERISK_VERSION_NUM 0104" $INCLUDEDIR/version.h; then
	echo "#define CC_AST_HAS_VERSION_1_4" >>$CONFIGFILE
	echo " * found Asterisk version 1.4"
	VER=1_4
else
	if [ -f "$INCLUDEDIR/../asterisk.h" ]; then
		echo "#define CC_AST_HAS_VERSION_1_4" >>$CONFIGFILE
		echo " * assuming Asterisk version 1.4"
		VER=1_4
	else
		echo "#undef CC_AST_HAS_VERSION_1_4" >>$CONFIGFILE
	fi
fi

if grep -q "AST_STRING_FIELD(name)" $INCLUDEDIR/channel.h; then
	echo "#define CC_AST_HAS_STRINGFIELD_IN_CHANNEL" >>$CONFIGFILE
	echo " * found stringfield in ast_channel"
else
	echo "#undef CC_AST_HAS_STRINGFIELD_IN_CHANNEL" >>$CONFIGFILE
	echo " * no stringfield in ast_channel"
fi

if grep -q "const indicate.*datalen" $INCLUDEDIR/channel.h; then
	echo "#define CC_AST_HAS_INDICATE_DATA" >>$CONFIGFILE
	echo " * found 'indicate' with data"
else
	echo "#undef CC_AST_HAS_INDICATE_DATA" >>$CONFIGFILE
	echo " * no data on 'indicate'"
fi

if grep -q "ast_channel_alloc.*name_fmt" $INCLUDEDIR/channel.h; then
	echo "#define CC_AST_HAS_EXT_CHAN_ALLOC" >>$CONFIGFILE
	echo " * found extended ast_channel_alloc"
else
	echo "#undef CC_AST_HAS_EXT_CHAN_ALLOC" >>$CONFIGFILE
	echo " * no extended ast_channel_alloc"
fi

if [ "$VER" = "1_2" ]; then
if grep -q "AST_JB" $INCLUDEDIR/channel.h; then
	if [ ! -f "$INCLUDEDIR/../../lib/asterisk/modules/chan_sip.so" ]; then
		echo "/* AST_JB */" >>$CONFIGFILE
		echo "#define CC_AST_HAS_JB_PATCH" >>$CONFIGFILE
		echo " * assuming generic jitter-buffer patch"
	else
		if grep -q "ast_jb" "$INCLUDEDIR/../../lib/asterisk/modules/chan_sip.so"; then
			echo "/* AST_JB */" >>$CONFIGFILE
			echo "#define CC_AST_HAS_JB_PATCH" >>$CONFIGFILE
			echo " * found generic jitter-buffer patch"
		else
			echo "#undef CC_AST_HAS_JB_PATCH" >>$CONFIGFILE
			echo " * found DISABLED generic jitter-buffer patch"
		fi
	fi
else
	echo "#undef CC_AST_HAS_JB_PATCH" >>$CONFIGFILE
	echo " * without generic jitter-buffer patch"
fi
fi

echo "" >>$CONFIGFILE
echo "#endif /* CHAN_CAPI_CONFIG_H */" >>$CONFIGFILE
echo "" >>$CONFIGFILE

echo "config.h complete."
exit 0

