#!/bin/sh
# This script was generated using Makeself 2.4.5
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1356726151"
MD5="539723f5bd520458101b1d4d37125ec8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
SIGNATURE=""
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"
export USER_PWD
ARCHIVE_DIR=`dirname "$0"`
export ARCHIVE_DIR

label="CCDC Self-Extract"
script="./initial_setup.sh"
scriptargs=""
cleanup_script=""
licensetxt=""
helpheader=''
targetdir="/opt/ccdc"
filesizes="102400"
totalsize="102400"
keep="y"
nooverwrite="n"
quiet="n"
accept="n"
nodiskspace="n"
export_conf="n"
decrypt_cmd=""
skip="718"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

if test -d /usr/xpg4/bin; then
    PATH=/usr/xpg4/bin:$PATH
    export PATH
fi

if test -d /usr/sfw/bin; then
    PATH=$PATH:/usr/sfw/bin
    export PATH
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  PAGER=${PAGER:=more}
  if test x"$licensetxt" != x; then
    PAGER_PATH=`exec <&- 2>&-; which $PAGER || command -v $PAGER || type $PAGER`
    if test -x "$PAGER_PATH"; then
      echo "$licensetxt" | $PAGER
    else
      echo "$licensetxt"
    fi
    if test x"$accept" != xy; then
      while true
      do
        MS_Printf "Please type y to accept, n otherwise: "
        read yn
        if test x"$yn" = xn; then
          keep=n
          eval $finish; exit 1
          break;
        elif test x"$yn" = xy; then
          break;
        fi
      done
    fi
  fi
}

MS_diskspace()
{
	(
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    # Test for ibs, obs and conv feature
    if dd if=/dev/zero of=/dev/null count=1 ibs=512 obs=512 conv=sync 2> /dev/null; then
        dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
        { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
          test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
    else
        dd if="$1" bs=$2 skip=1 2> /dev/null
    fi
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd "$@"
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 count=0 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
${helpheader}Makeself version 2.4.5
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive
  $0 --verify-sig key Verify signature agains a provided key id

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet               Do not print anything except error messages
  --accept              Accept the license
  --noexec              Do not run embedded script (implies --noexec-cleanup)
  --noexec-cleanup      Do not run embedded cleanup script
  --keep                Do not erase target directory after running
                        the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the target folder to the current user
  --chown               Give the target folder to the current user recursively
  --nodiskspace         Do not check for available disk space
  --target dir          Extract directly to a target directory (absolute or relative)
                        This directory may undergo recursive chown (see --nochown).
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --ssl-pass-src src    Use the given src as the source of password to decrypt the data
                        using OpenSSL. See "PASS PHRASE ARGUMENTS" in man openssl.
                        Default is to prompt the user to enter decryption password
                        on the current terminal.
  --cleanup-args args   Arguments to the cleanup script. Wrap in quotes to provide
                        multiple arguments.
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Verify_Sig()
{
    GPG_PATH=`exec <&- 2>&-; which gpg || command -v gpg || type gpg`
    MKTEMP_PATH=`exec <&- 2>&-; which mktemp || command -v mktemp || type mktemp`
    test -x "$GPG_PATH" || GPG_PATH=`exec <&- 2>&-; which gpg || command -v gpg || type gpg`
    test -x "$MKTEMP_PATH" || MKTEMP_PATH=`exec <&- 2>&-; which mktemp || command -v mktemp || type mktemp`
	offset=`head -n "$skip" "$1" | wc -c | tr -d " "`
    temp_sig=`mktemp -t XXXXX`
    echo $SIGNATURE | base64 --decode > "$temp_sig"
    gpg_output=`MS_dd "$1" $offset $totalsize | LC_ALL=C "$GPG_PATH" --verify "$temp_sig" - 2>&1`
    gpg_res=$?
    rm -f "$temp_sig"
    if test $gpg_res -eq 0 && test `echo $gpg_output | grep -c Good` -eq 1; then
        if test `echo $gpg_output | grep -c $sig_key` -eq 1; then
            test x"$quiet" = xn && echo "GPG signature is good" >&2
        else
            echo "GPG Signature key does not match" >&2
            exit 2
        fi
    else
        test x"$quiet" = xn && echo "GPG signature failed to verify" >&2
        exit 2
    fi
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    SHA_PATH=`exec <&- 2>&-; which shasum || command -v shasum || type shasum`
    test -x "$SHA_PATH" || SHA_PATH=`exec <&- 2>&-; which sha256sum || command -v sha256sum || type sha256sum`

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n "$skip" "$1" | wc -c | tr -d " "`
    fsize=`cat "$1" | wc -c | tr -d " "`
    if test $totalsize -ne `expr $fsize - $offset`; then
        echo " Unexpected archive size." >&2
        exit 2
    fi
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$SHA_PATH"; then
			if test x"`basename $SHA_PATH`" = xshasum; then
				SHA_ARG="-a 256"
			fi
			sha=`echo $SHA | cut -d" " -f$i`
			if test x"$sha" = x0000000000000000000000000000000000000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded SHA256 checksum." >&2
			else
				shasum=`MS_dd_Progress "$1" $offset $s | eval "$SHA_PATH $SHA_ARG" | cut -b-64`;
				if test x"$shasum" != x"$sha"; then
					echo "Error in SHA256 checksums: $shasum is different from $sha" >&2
					exit 2
				elif test x"$quiet" = xn; then
					MS_Printf " SHA256 checksums are OK." >&2
				fi
				crc="0000000000";
			fi
		fi
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				elif test x"$quiet" = xn; then
					MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" != x"$crc"; then
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2
			elif test x"$quiet" = xn; then
				MS_Printf " CRC checksums are OK." >&2
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

MS_Decompress()
{
    if test x"$decrypt_cmd" != x""; then
        { eval "$decrypt_cmd" || echo " ... Decryption failed." >&2; } | eval "cat"
    else
        eval "cat"
    fi
    
    if test $? -ne 0; then
        echo " ... Decompression failed." >&2
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf -  2>&1 || { echo " ... Extraction failed." >&2; kill -15 $$; }
    else
		tar $1f -  2>&1 || { echo Extraction failed. >&2; kill -15 $$; }
    fi
}

MS_exec_cleanup() {
    if test x"$cleanup" = xy && test x"$cleanup_script" != x""; then
        cleanup=n
        cd "$tmpdir"
        eval "\"$cleanup_script\" $scriptargs $cleanupargs"
    fi
}

MS_cleanup()
{
    echo 'Signal caught, cleaning up' >&2
    MS_exec_cleanup
    cd "$TMPROOT"
    rm -rf "$tmpdir"
    eval $finish; exit 15
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=none
ownership=n
verbose=n
cleanup=y
cleanupargs=
sig_key=

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
	--accept)
	accept=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 100 KB
	echo Compression: none
	if test x"n" != x""; then
	    echo Encryption: n
	fi
	echo Date of packaging: Sun Feb 16 16:55:18 EST 2025
	echo Built with Makeself version 2.4.5
	echo Build command was: "/nix/store/7ys9lb0wy6schavmza5m0q6xb3p12vzg-makeself-2.4.5/bin/makeself \\
    \"--nocomp\" \\
    \"--header\" \\
    \"/nix/store/7ys9lb0wy6schavmza5m0q6xb3p12vzg-makeself-2.4.5/share/makeself/makeself-header.sh\" \\
    \"--target\" \\
    \"/opt/ccdc\" \\
    \"linux/scripts\" \\
    \"linux.sh\" \\
    \"CCDC Self-Extract\" \\
    \"./initial_setup.sh\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
    echo CLEANUPSCRIPT=\"$cleanup_script\"
	echo archdirname=\"/opt/ccdc\"
	echo KEEP=y
	echo NOOVERWRITE=n
	echo COMPRESS=none
	echo filesizes=\"$filesizes\"
    echo totalsize=\"$totalsize\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5sum\"
	echo SHAsum=\"$SHAsum\"
	echo SKIP=\"$skip\"
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n "$skip" "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | MS_Decompress | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n "$skip" "$0" | wc -c | tr -d " "`
	arg1="$2"
    shift 2 || { MS_Help; exit 1; }
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | MS_Decompress | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --verify-sig)
    sig_key="$2"
    shift 2 || { MS_Help; exit 1; }
    MS_Verify_Sig "$0"
    ;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
    cleanup_script=""
	shift
	;;
    --noexec-cleanup)
    cleanup_script=""
    shift
    ;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir="${2:-.}"
    shift 2 || { MS_Help; exit 1; }
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --chown)
        ownership=y
        shift
        ;;
    --nodiskspace)
	nodiskspace=y
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
	--ssl-pass-src)
	if test x"n" != x"openssl"; then
	    echo "Invalid option --ssl-pass-src: $0 was not encrypted with OpenSSL!" >&2
	    exit 1
	fi
	decrypt_cmd="$decrypt_cmd -pass $2"
    shift 2 || { MS_Help; exit 1; }
	;;
    --cleanup-args)
    cleanupargs="$2"
    shift 2 || { MS_Help; exit 1; }
    ;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir="$TMPROOT"/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -e "$0 --xwin $initargs"
                else
                    exec $XTERM -e "./$0 --xwin $initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp "$tmpdir" || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n "$skip" "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 100 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
    # Decrypting with openssl will ask for password,
    # the prompt needs to start on new line
	if test x"n" = x"openssl"; then
	    echo "Decrypting and uncompressing $label..."
	else
        MS_Printf "Uncompressing $label"
	fi
fi
res=3
if test x"$keep" = xn; then
    trap MS_cleanup 1 2 3 15
fi

if test x"$nodiskspace" = xn; then
    leftspace=`MS_diskspace "$tmpdir"`
    if test -n "$leftspace"; then
        if test "$leftspace" -lt 100; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (100 KB)" >&2
            echo "Use --nodiskspace option to skip this check and proceed anyway" >&2
            if test x"$keep" = xn; then
                echo "Consider setting TMPDIR to a directory with more free space."
            fi
            eval $finish; exit 1
        fi
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | MS_Decompress | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$export_conf" = x"y"; then
        MS_BUNDLE="$0"
        MS_LABEL="$label"
        MS_SCRIPT="$script"
        MS_SCRIPTARGS="$scriptargs"
        MS_ARCHDIRNAME="$archdirname"
        MS_KEEP="$KEEP"
        MS_NOOVERWRITE="$NOOVERWRITE"
        MS_COMPRESS="$COMPRESS"
        MS_CLEANUP="$cleanup"
        export MS_BUNDLE MS_LABEL MS_SCRIPT MS_SCRIPTARGS
        export MS_ARCHDIRNAME MS_KEEP MS_NOOVERWRITE MS_COMPRESS
    fi

    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi

MS_exec_cleanup

if test x"$keep" = xn; then
    cd "$TMPROOT"
    rm -rf "$tmpdir"
fi
eval $finish; exit $res
./.lin                                                                                              0000644 0001750 0001750 00000001000 14750407456 011363  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 script=$(mktemp)

if command -v wget &> /dev/null; then
        wget -q "https://raw.githubusercontent.com/UofL-Cyber-Defense/CCDC-Public/refs/heads/master/linux.sh" --no-check-certificate -O $script
elif command -v curl &> /dev/null; then
        curl -sSL "https://raw.githubusercontent.com/UofL-Cyber-Defense/CCDC-Public/refs/heads/master/linux.sh" --insecure -o $script
fi

if command -v sudo &> /dev/null; then
  sudo sh "$script"
else
  echo "Password for root account"
  su -c "sh $script"
fi

rm $script
./audit_check_logs.sh                                                                               0000755 0001750 0001750 00000000401 14534102626 014421  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Noah Tongate @Ap3x
# Description:
# Audit the linux system logs
# Usage:
# ./<SCRIPT NAME>

tail -n 20 /var/log/auth.log
tail -n 20 /var/log/secure
tail -n 20 /var/log/syslog
tail -n 20 /var/log/wmtp
tail -n 20 ~/.bash_history
                                                                                                                                                                                                                                                               ./audit_enum-linux.sh                                                                               0000755 0001750 0001750 00000006342 14534102626 014433  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Noah Tongate @Ap3x
# Description:
#  Audit the linux system and common checks for linux
# Usage:
# ./<SCRIPT NAME>

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

clear
x=0
echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Permission of Home Folders: ${NC}"; ls -la /home;

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Check the PATH envirnment variable: ${NC}"
echo -e "${RED}Default PATH looks like: "
echo -e "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin${NC}"; 
echo $PATH;

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Check the all envirnment variable: ${NC}"; env

echo; while [ $x -lt $ ) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Check for LD_PRELOAD envirnment variable: ${NC}"; env | grep LD_PRELOAD

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Check any odd users: ${NC}"; cat /etc/passwd | grep -v '^#\|^$|^;'

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Check any sudoer users: ${NC}"; cat /etc/sudoers | grep -v '^#\|^$|^;'

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Check for any odd commands or source of other files: ${NC}"; cat /etc/profile | grep -v '^#\|^$|^;'

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Check for odd .bash_aliases: ${NC}"; cat ~/.bash_aliases | grep -v '^#\|^$|^;'

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Check for any unnecessary SSH keys: ${NC}"; cat ~/.ssh/authorized_keys 

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Check for cron jobs in Crontab List: ${NC}"; crontab -l

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Check for cron jobs in Spool: ${NC}"; ls -la /var/spool/cron/

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Hidden files in Home Directory? ${NC}"; ls -la ~

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Check for any odd backup files: ${NC}"; ls -la /var/backups

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

# Dependent on OS
#  Ubuntu - cat /etc/apt/sources.list
#  Debian - cat /etc/apt/sources.list
#  CentOS - ls -la /etc/yum.repos.d/
echo -e "${GREEN}Check for odd repositories:  ${NC}";  cat /etc/apt/sources.list | grep -v -i '^#'

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Check for open ports:  ${NC}";  ss -tulpn

echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo

echo -e "${GREEN}Check for PAM backdoor:  ${NC}";  
echo -e "${RED}Look in /lib/x86_64-linux-gnu/security/ ${NC}";  
echo -e "${RED}Look for any odd files using this command: grep -rnw '/etc/pam.d/ ' -ie '^auth' ${NC}";
echo; while [ $x -lt $(tput cols) ];do echo -n '#'; let x=$x+1; done; x=0; echo
                                                                                                                                                                                                                                                                                              ./audit_packages.sh                                                                                 0000755 0001750 0001750 00000001256 14747643315 014122  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
# Runs either debsums or rpm verification
# Usage:
# ./<Script_Name>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check
DEST="/opt/ccdc/modified_$(date +%s)"

mkdir -p "$DEST"
if command -v apt-get >/dev/null 2>&1; then
    if ! command -v  >/dev/null 2>&1; then
        DEBIAN_FRONTEND="noninteractive" web apt-get update -y
        DEBIAN_FRONTEND="noninteractive" web apt-get install debsums -y
    fi
    debsums -ac | xargs -d '\n' -I {} cp --parents -p {} "$DEST"
elif command -v rpm >/dev/null 2>&1; then
    rpm -Va | awk '{print $NF}' | xargs -d '\n' -I {} cp --parents -p {} "$DEST"
fi                                                                                                                                                                                                                                                                                                                                                  ./audit_visual_watch_ss.sh                                                                          0000755 0001750 0001750 00000000704 14534102626 015524  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
#  Watchs for any change in connection
# Usage:
# ./<SCRIPT NAME>

snapshotFile="/tmp/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
currentFile="/tmp/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"

# Take a snapshot of the initial output
netstat -tulpn > $snapshotFile

# Watch
watch -n 1 "netstat -tulpn > $currentFile; diff $snapshotFile $currentFile"                                                            ./audit_watch-red-team.sh                                                                           0000755 0001750 0001750 00000001413 14534102626 015126  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Noah Tongate @Ap3x
# Description:
#  Watchs for any Red Team connections and logs it
# Usage:
# ./<SCRIPT NAME>

LOGFILE="/var/log/logconnection.log"
TEMPFILE1="/tmp/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
TEMPFILE2="/tmp/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"

ss -tupln | grep -v -i "^Netid" > $LOGFILE
date >> $LOGFILE
while true; do
	sleep 2s
	ss -tupln | grep -v -i "^Netid" > $TEMPFILE2
	cat $LOGFILE | grep -ie "^tcp" -ie "^udp" > $TEMPFILE1
	diff -b $TEMPFILE1 $TEMPFILE2 | grep ">" | grep -e tcp -e udp | sed 's/^..//' >> $LOGFILE
	if [[ $(diff -b $TEMPFILE1 $TEMPFILE2 | grep ">" | grep -e tcp -e udp | sed 's/^..//')  ]]; then
		date >> $LOGFILE
	fi
done
rm $TEMPFILE1
rm $TEMPFILE2
                                                                                                                                                                                                                                                     ./audit_watch_files.sh                                                                              0000755 0001750 0001750 00000002025 14534102626 014614  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Noah Tongate @Ap3x
# Description:
# Audit the linux system and common checks for linux
# Usage:
# ./<SCRIPT NAME> -p <PATH TO AUDIT> -o <OUTPUT FILE>

tailStr="ORIG"

while getopts p: flag
do
    case "${flag}" in
        p) path=${OPTARG};;
#        o) output=${OPTARG};;
    esac
done

origFilename="/tmp/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
tempFilename="/tmp/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"

find "$path" -type f -print0 | xargs -0 sha1sum > $origFilename
chmod 600 $origFilename

while true; do

    find "$path" -type f -print0 | xargs -0 sha1sum > $tempFilename
    chmod 600 $tempFilename
    if [[ $(diff $tempFilename $origFilename) ]]
    then
        outputDiff=$(diff $tempFilename $origFilename)
        wall "FILE CHANGE IN $path $outputDiff"
        echo "FILE CHANGE IN $path $outputDiff ----> $(date)" >> /var/log/filewatch.log
        chmod 600 /var/log/filewatch.log
        mv $tempFilename $origFilename
    fi
    sleep 2

done                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ./bind/ccdcrevr/db.172.20.240                                                                       0000664 0001750 0000355 00000000601 14751001216 015372  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              $TTL 86400
@   IN  SOA ns1.ccdcteam01.internal. admin.ccdcteam01.internal. (
            01        ; Serial
            604800    ; Refresh
            86400     ; Retry
            2419200   ; Expire
            86400 )   ; Negative Cache TTL
;
@       IN  NS      ns1.ccdcteam01.internal.

10      IN  PTR     docker.ccdcteam01.internal.
20      IN  PTR     ns1.ccdcteam01.internal.
                                                                                                                               ./bind/ccdcrevr/db.172.20.241                                                                       0000664 0001750 0000355 00000000650 14751001566 015407  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              $TTL 86400
@   IN  SOA ns1.ccdcteam01.public. admin.ccdcteam01.public. (
            1         ; Serial
            604800    ; Refresh
            86400     ; Retry
            2419200   ; Expire
            86400 )   ; Negative Cache TTL
;
@       IN  NS      ns1.ccdcteam01.public.

20      IN  PTR     splunk.ccdcteam01.public.
30      IN  PTR     ecomm.ccdcteam01.public.
40      IN  PTR     webmail.ccdcteam01.public.
                                                                                        ./bind/ccdcrevr/db.172.20.242                                                                       0000664 0001750 0000355 00000000641 14751001456 015406  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              $TTL 86400
@   IN  SOA ns1.ccdcteam01.user. admin.ccdcteam01.user. (
            1         ; Serial
            604800    ; Refresh
            86400     ; Retry
            2419200   ; Expire
            86400 )   ; Negative Cache TTL
;
@       IN  NS      ns1.ccdcteam01.user.

10      IN  PTR     ns1.ccdcteam01.user.
200     IN  PTR     ad-server.ccdcteam01.user.
210     IN  PTR     workstation.ccdcteam01.user.
                                                                                               ./bind/ccdcteam/db.ccdcteam01.internal                                                              0000664 0001750 0000355 00000000623 14751001144 020030  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              $TTL 86400
@   IN  SOA ns1.ccdcteam01.internal. admin.ccdcteam01.internal. (
            01        ; Serial
            604800    ; Refresh
            86400     ; Retry
            2419200   ; Expire
            86400 )   ; Negative Cache TTL
;
@       IN  NS      ns1.ccdcteam01.internal.

ns1     IN  A       172.20.240.20    ; Current DNS server
docker  IN  A       172.20.240.10    ; Docker server
                                                                                                             ./bind/ccdcteam/db.ccdcteam01.public                                                                0000664 0001750 0000355 00000000763 14751001524 017501  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              $TTL 86400
@   IN  SOA ns1.ccdcteam01.public. admin.ccdcteam01.public. (
            1         ; Serial
            604800    ; Refresh
            86400     ; Retry
            2419200   ; Expire
            86400 )   ; Negative Cache TTL
;
@       IN  NS      ns1.ccdcteam01.public.

ns1        IN  A   172.20.241.20     ; Splunk server
splunk     IN  A   172.20.241.20     ; Splunk server
ecomm      IN  A   172.20.241.30     ; E-Comm server
webmail    IN  A   172.20.241.40     ; WebMail server
             ./bind/ccdcteam/db.ccdcteam01.user                                                                  0000664 0001750 0000355 00000000722 14751001430 017170  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              $TTL 86400
@   IN  SOA ns1.ccdcteam01.user. admin.ccdcteam01.user. (
            01        ; Serial
            604800    ; Refresh
            86400     ; Retry
            2419200   ; Expire
            86400 )   ; Negative Cache TTL
;
@       IN  NS      ns1.ccdcteam01.user.

ns1         IN  A   172.20.242.10    ; Ubuntu server acting as DNS
ad-server   IN  A   172.20.242.200   ; Active Directory server
workstation IN  A   172.20.242.210   ; User workstation
                                              ./bind/checkAndApply.sh                                                                             0000664 0001750 0000355 00000001461 14751001662 015307  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              # Check Bind Configuration
sudo named-checkconf

# Check Zone Files
sudo named-checkzone ccdcteam01.internal /etc/bind/db.ccdcteam01.internal
sudo named-checkzone ccdcteam01.user /etc/bind/db.ccdcteam01.user
sudo named-checkzone ccdcteam01.public /etc/bind/db.ccdcteam01.public

sudo named-checkzone 240.20.172.in-addr.arpa /etc/bind/db.172.20.240
sudo named-checkzone 242.20.172.in-addr.arpa /etc/bind/db.172.20.242
sudo named-checkzone 241.20.172.in-addr.arpa /etc/bind/db.172.20.241

# restart Bind Service
sudo systemctl restart bind9

# Test DNS Forward Lookup
dig_ @localhost ns1.ccdcteam01.internal
dig_ @localhost ad-server.ccdcteam01.user
dig_ @localhost webmail.ccdcteam01.public

# Test Reverse DNS Lookup
dig_ @localhost -x 172.20.240.10
dig_ @localhost -x 172.20.242.200
dig_ @localhost -x 172.20.241.40
                                                                                                                                                                                                               ./bind/fileReplace.sh                                                                               0000664 0001750 0000355 00000001230 14751220306 015004  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              #! /bin/bash

sudo cp ccdcteam /etc/bind/ccdcteam
sudo cp ccdcrevr /etc/bind/ccdcrevr

sudo bash -c 'cat named.conf.local > /etc/bind/named.conf.local'
sudo bash -c 'cat named.conf.options > /etc/bind/named.conf.options'

sudo chown -R bind:bind /var/log/bind9/
sudo chown -R bind:bind /etc/bind/
sudo chmod -R /var/log/bind9/
sudo chmod -R /etc/bind/


# not changed
# named.conf
# named.conf.options
# named.conf.default-zones
# named.conf.external-zones
# named.conf.internal-zones
# named.conf.options.dpkg-dist
# rndc.key
# zones file and files
# zones.rfc1918

# changed
# named.conf.local
# ccdcteam file
# ccdcrevr file
# checkAndApply.sh
# fileReplace.sh
                                                                                                                                                                                                                                                                                                                                                                        ./bind/named.conf                                                                                   0000664 0001750 0000355 00000001054 14751006430 014174  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              // This is the primary configuration file for the BIND DNS server named.
//
// Please read /usr/share/doc/bind9/README.Debain.gz for information on the
// structure of BIND configuration files in Debian, *BEFORE* you customize
// this configuration file.
//
// If you are just adding zones, please do that in /etc/bind/named.conf.local

include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
#include "/etc/bind/named.conf.default-zones";
include "/etc/bind/named.conf.internal-zones";
include "/etc/bind/named.conf.external-zones";
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ./bind/named.conf.default-zones                                                                     0000664 0001750 0000355 00000001005 14751007216 016752  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              // prime the server with knowledge of the root servers
zone "." {
	type hint;
	file "/usr/share/dns/root.hints";
}

// be authorative for the localhost forward and reverse zones, and for
// broadcast zones as per RFC 1912

zone "localhost" {
    type master;
    file "/etc/bind/db.local";
};

zone "127.in-addr.arpa" {
    type master;
    file "/etc/bind/db.127";
};

zone "0.in-addr.arpa" {
    type master;
    file "/etc/bind/db.0";
};

zone "255.in-addr.arpa" {
    type master;
    file "/etc/bind/db.255";
};
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ./bind/named.conf.external-zones                                                                    0000664 0001750 0000355 00000000271 14751010310 017141  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              view "external"
{
	match-clients {any;};
	allow-query {none;};
	zone "allsafe.com" in
	{
		type master;
		file "/etc/bind/zones/allsafe.com-external.db";
		allow-update {none;};
	};
};
                                                                                                                                                                                                                                                                                                                                       ./bind/named.conf.internal-zones                                                                    0000664 0001750 0000355 00000000354 14751010350 017141  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              view "internal"
{
	match-clients 
	{
		localhost;
		172.20.241.0/24; // public zone
	};
	
	zone "allsafe.com" in
	{
		type master;
		file "/etc/bind/zones/allsafe.com-internal.db";
	};
	#include "/etc/bind/named.conf.default-zones";
};
                                                                                                                                                                                                                                                                                    ./bind/named.conf.local                                                                             0000664 0001750 0000355 00000001505 14751022000 015255  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              //
// Do any local configuration here
//
// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

view "ccdcteam01" {
	zone "ccdcteam01.internal" {  
		type master;
		file "/etc/bind/ccdcteam/db.ccdcteam01.internal";  
	};

	zone "ccdcteam01.user" {  
		type master;
		file "/etc/bind/ccdcteam/db.ccdcteam01.user";  
	};

	zone "ccdcteam01.public" {  
	    type master;
		file "/etc/bind/ccdcteam/db.ccdcteam01.public";  
	};

	// Reverse DNS Lookup Zones (best practice)
	zone "0.240.20.172.in-addr.arpa" {
		type master;
		file "/etc/bind/ccdcrevr/db.172.20.240";
	};

	zone "0.241.20.172.in-addr.arpa" {
		type master;
		file "/etc/bind/ccdcrevr/db.172.20.241";
	};

	zone "0.242.20.172.in-addr.arpa" {
		type master;
		file "/etc/bind/ccdcrevr/db.172.20.242";
	};
};
                                                                                                                                                                                           ./bind/named.conf.options                                                                           0000664 0001750 0000355 00000001750 14751217716 015704  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              options 
{
    directory "/var/cache/bind";
    auth-nxdomain no;
    // listen-on-v6 {none;};
    querylog yes;
    statistics-file "/var/cache/bind/named.stats";
    rrset-order {order cyclic;};

    forwarders {
        172.20.242.200;  // Google DNS
    };

    allow-query { 
	    localhost; 
	    172.20.240.0/24; // Internal Zone
	    172.20.241.0/24; // Public Zone
	    172.20.242.0/24; // User Zone
    };

	allow-transfer { 
	    localhost; 
	    172.20.240.0/24; // Internal Zone
	    172.20.241.0/24; // Public Zone
	    172.20.242.0/24; // User Zone
    };
    
    allow-recursion { 
	    localhost; 
	    172.20.240.0/24; // Internal Zone
	    172.20.241.0/24; // Public Zone
	    172.20.242.0/24; // User Zone
    };

    recursion yes; // allow queries from higher DNS servers
    dnssec-validation auto;

    // listen-on { any; };
};

logging
{
	channel b_query
	{
		file "/var/log/bind9/query.log";
		print-time yes;
		severity info;
	};
	
	category queries
	{
		b_query;
	};
};
                        ./bind/named.conf.options.dpkg-dist                                                                 0000664 0001750 0000355 00000000132 14751011542 017547  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              options
{
	directory "/var/cache/bind";
	dnssec-validation auto;
	listen-on-v6 {any;};
};
                                                                                                                                                                                                                                                                                                                                                                                                                                      ./bind/rndc.key                                                                                     0000664 0001750 0000355 00000000000 14751000320 013657  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              ./bind/zones.rfc1918                                                                                0000664 0001750 0000355 00000000000 14751000320 014374  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              ./bind/zones/allsafe.com-external.db                                                                0000664 0001750 0000355 00000000000 14751000410 017670  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              ./bind/zones/allsafe.com-internal.db                                                                0000664 0001750 0000355 00000000000 14751000410 017662  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              ./disable_firewall.sh                                                                               0000755 0001750 0001750 00000001356 14750405642 014440  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Description:
# Disables the firewall
# Usage:
# ./<SCRIPT NAME>
# 

# Variables
. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

if [ -f "/usr/sbin/iptables-nft" ]; then # Oh no
    shopt -s expand_aliases
    alias iptables=/usr/sbin/iptables-nft
    alias iptables-save=/usr/sbin/iptables-nft-save
    alias ip6tables=/usr/sbin/ip6tables-nft
    alias ip6tables-save=/usr/sbin/ip6tables-nft-save
fi

# Reset IPv4
table_names=$(iptables-save | grep '^*' | sed 's/*//g' | sort | uniq)
for table_name in $table_names
do
  iptables -t $table_name -F
  iptables -t $table_name -X
done
iptables -F
iptables -X
iptables -Z
iptables -P FORWARD DROP
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT                                                                                                                                                                                                                                                                                  ./fetch_pspy.sh                                                                                     0000755 0001750 0001750 00000000500 14750401336 013276  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
# Downloads pspy
# Usage:
# ./<Script_Name>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi

download https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64 /opt/ccdc/pspy
chown_ccdc /opt/ccdc/pspy
chmod +x /opt/ccdc/pspy                                                                                                                                                                                                ./fix_postfix.sh                                                                                    0000755 0001750 0001750 00000003110 14747643323 013506  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
# Changes postfix from using LDAP to dovecot for auth. Do this. Don't say I didn't warn you.
# Usage:
# ./<Script_Name>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

# Backup Postfix and Dovecot configurations
postconf -n > /etc/postfix_config-orig
doveconf -n > /etc/dovecot_config-orig
cp -R /etc/dovecot /etc/dovecot-orig
cp -R /etc/postfix /etc/postfix-orig
cp /etc/aliases /etc/aliases-orig

encrypt /etc/postfix_config-orig
encrypt /etc/dovecot-config-orig

# REM out LDAP configuration
sed -i "s/alias_maps =/#alias_maps =/g" /etc/postfix/main.cf
sed -i "s/smtpd_sender_login_maps = proxy/#smtpd_sender_login_maps = proxy/g" /etc/postfix/main.cf
sed -i "s/virtual_mailbox_maps = proxy/#virtual_mailbox_maps = proxy/g" /etc/postfix/main.cf

# Use dovecot for authentication
echo "
alias_maps = hash:/etc/aliases
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
" >> /etc/postfix/main.cf

# Add aliases for mail users
awk -F: '$3 > 5000 {print $1 ": " $1}' /etc/passwd | tee -a /etc/aliases

# Set group override
mkdir -p /etc/systemd/system/postfix.service.d
mkdir -p /etc/systemd/system/dovecot.service.d
cat "[Service]
Group=mail_in" > /etc/systemd/system/postfix.service.d/override.conf
cat "[Service]
Group=mail_in" > /etc/systemd/system/dovecot.service.d/override.conf

# Restart services
systemctl daemon-reload
systemctl restart postfix
systemctl restart dovecot                                                                                                                                                                                                                                                                                                                                                                                                                                                        ./get_info.sh                                                                                       0000755 0001750 0001750 00000002625 14750406005 012734  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
# Lists basic system information and important services
# Usage:
# ./<Script_Name>

file=system_info.txt

cat /etc/hostname | tee $file
cat /etc/os-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | cut -d\" -f2 | tee -a $file
uname -r | tee -a $file
netstat -tulpn | tee -a $file

systemctl list-unit-files --state=enabled --no-pager | awk '/.service|.socket|.timer/ && !/logrotate/ && !/systemd-tmpfiles-clean/ && !/clamav-scan/ && !/getty@/ && !/lvm2-*/ && !/nix-/ && !/systemd-/ && !/user@/ {system("systemctl show "$1" -p Description | sed \"s%Description=%"$1"|%g\"")}' | sort | column -t -s '|' | tee $file 2>&1

echo '''#!/usr/bin/env bash
disable=(''' > disable.sh
systemctl list-unit-files --state=enabled --no-pager | awk '/.service|.socket|.timer/ && !/logrotate/ && !/systemd-tmpfiles-clean/ && !/clamav-scan/ && !/auditd/ && !/chrony/ && !/clamav-/ && !/getty@/ && !/lvm2-*/ && !/NetworkManager/ && !/nix-/ && !/ntpd/ && !/rsyslog/ && !/systemd-/ && !/user@/ && !/iptables/ && !/user-runtime-dir/ && !/dbus/ && !/console-setup/ && !/ifup@/ && !/networking/ && !/keyboard-setup/ && !/resolvconf/ && /service/ {system("echo \\\""$1"\\\" >> disable.sh")}'
echo ''')
for i in "${disable[@]}"; do
    systemctl disable $i
    systemctl stop $i
done''' >> disable.sh
chmod 777 disable.sh
chmod 666 system_info.txt
echo "View disable.sh and edit accordingly"                                                                                                           ./helper.sh                                                                                         0000755 0001750 0000355 00000006567 14751166455 013175  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
# Helper functions
# Usage:
# . $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi

PUBLIC_KEY=age16r0xhfs07tr83qeu0a76x99pyds68sj2wn7yl34l0v5qenfplaaq803cnz
export PATH=$PATH:/sbin # Debian doesn't have /sbin by default in the path. Agony.

function create_user {
	if ! id "$1" >/dev/null 2>&1; then
		if [ -z "$2" ]; then
			useradd "$1" -s /usr/sbin/nologin -N -M
		else
			useradd "$1" -s /usr/sbin/nologin -N -M -g "$2"
		fi
	fi
}

function create_group {
	if ! getent group "$1" >/dev/null 2>&1; then
		groupadd "$1"
	fi
}

function download_unsafe {
	if command -v wget &> /dev/null; then
		web wget -q -O "$2" "$1" --no-check-certificate
	elif command -v curl &> /dev/null; then
		web curl -sSL -o "$2" "$1" --insecure
	else
		echo "Install curl, or wget."
		exit 1
	fi
}

function interactive_quit {
    if [[ $- != *i* ]]; then # Not interactive
        exit 1
    else
        return 1
    fi
}

function download {
    if [ -z "$2" ]; then
        filename=$(basename "$1")
        set -- "$1" "$filename"
    fi

    download_unsafe "$1" "$2"

    if [ -f "$2" ]; then
        file_size=$(stat -c%s "$2")
        if [ ! "$file_size" -gt 0 ]; then
            echo "Download failed: File Empty"
            interactive_quit
        fi
    else
        echo "$2 download failed"
        interactive_quit
    fi
}

function root_check {
    if [[ $EUID -ne 0 ]]; then
        if [ -n "$1" ]; then
            echo "$1"
        else
            echo "This script must be run as root."
        fi
        interactive_quit
    fi
}

function chown_ccdc {
    if [[ $EUID -eq 0 ]]; then
        chown ccdc $1
    fi
}

function force_kill {
	root_check
	if command -v killall &> /dev/null; then
		killall -9 "$1" >/dev/null 2>&1
	else
		kill -9 "$(pidof $1)" >/dev/null 2>&1
	fi
}

function is_in_nix_shell {
  if echo "$PATH" | grep -qc '/nix/store'; then
    export IN_NIX_SHELL=impure
  else
    unset IN_NIX_SHELL
  fi
}

function nix_shell_guard {
	is_in_nix_shell
	if [[ -z "${IN_NIX_SHELL}" ]]; then
  		echo "You need to have Nix installed for this script"
  		interactive_quit
	fi
}

function web { # Eval is dumb
    root_check "Type y and press enter to use the internet" # Stupid way to get sg
    cmd="sg internet_out -c \"$@\""
    eval "$cmd"
}

function sudoweb { # Eval is dumb
    cmd="sg internet_out -c \"$@\""
    eval "sudo $cmd"
}

# Avoids segault when using sudo with Nix (May have been fixed?)
function nix_fix {
	root_check
	su root -c "$1"
}

function if_systemd {
    if [ $(ps -p 1 -o comm=) == "systemd" ]; then
	    "$@"
    fi
}

function encrypt {
    pushd $(dirname $1) > /dev/null
    if [ -f "/bin/nix" ]; then
        if [ -d "$1" ]; then
            tar -cvzf - "$1" | nix run nixpkgs#age -- -r $PUBLIC_KEY -o "$1.age" "$1"
        elif [ -f "$1" ]; then
            nix run nixpkgs#age -- -r $PUBLIC_KEY -o "$1.age" "$1"
        fi
    else 
        echo "Failed encryption - Install Nix"
    fi
    popd > /dev/null
}

function decrypt {
    echo "Please enter your private key:"
    read key
    loc=$(mktemp)
    echo "$key" > "$loc"

    pushd $(dirname $1) > /dev/null
    if [ -d "$1" ]; then
        nix run nixpkgs#age -- --identity $loc -d "$1.age" | tar -xvf -
    elif [ -f "$1" ]; then
        nix run nixpkgs#age -- --identity $loc -d "$1.age" > "$1"
    fi
    popd > /dev/null

    rm "$loc"
    unset key
}
                                                                                                                                         ./initial_setup.sh                                                                                  0000755 0001750 0001750 00000002204 14750003052 013777  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
# Stuff that needs to get done right away. Only safe things, so no firewall.
# Usage:
# ./<Script_Name>

# Permission fix
chmod 755 /opt/ccdc
cd /opt/ccdc

# Kill SSH
if [ -f /usr/lib/systemd/system/sshd.service ] || [ -f /lib/systemd/system/sshd.service ]; then
    NAME=sshd
else
    NAME=ssh
fi

if systemctl is-active --quiet $NAME 2>/dev/null; then
    systemctl stop $NAME
fi

if ! systemctl is-enabled --quiet $NAME 2>/dev/null; then
    systemctl mask $NAME
fi

if pgrep sshd >/dev/null; then
    kill -9 $(pgrep sshd)
fi

# Setup users and passwords and junk (Hopefully safe)
/opt/ccdc/setup_users.sh

# Kernel settings (Safe)
/opt/ccdc/kernel_settings.sh

# Update certificates (I don't think this will break things?
/opt/ccdc/update_certificates.sh

# Dump info about the computer
/opt/ccdc/get_info.sh

# Misc
/opt/ccdc/misc_tweaks.sh

# Download pspy
/opt/ccdc/fetch_pspy.sh

# Syslog
/opt/ccdc/setup_syslog.sh 172.20.241.20

# Everything else is either dangerous or needs nix

# Get the user to sign in again
echo "Please login to the newly created ccdc user. Press enter"; read
exit                                                                                                                                                                                                                                                                                                                                                                                             ./install_wazuh_agent_apt.sh                                                                        0000755 0001750 0000355 00000004215 14751162272 016601  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              #!/usr/bin/env bash
#
# Author: Nicholas Hooper
# Description:
# Install & Configure Wazuh Agent ( apt )
# Usage:
# ./<Script_Name>

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
fi

if ! command -v curl &> /dev/null
then
    echo "curl could not be found, please install curl."
    exit 1
fi

WAZUH_GPG_KEY="https://packages.wazuh.com/key/GPG-KEY-WAZUH"
KEYRING_PATH="/usr/share/keyrings/wazuh.gpg"
WAZUH_REPO_FILE="/etc/apt/sources.list.d/wazuh.list"
AGENT_CONF="/var/ossec/etc/ossec.conf"

#read -p "Enter manager IP: " WAZUH_MANAGER

echo "Creating backup . . ."

cp "$AGENT_CONF" "${AGENT_CONF}.bak"

echo "Importing Wazuh GPG key..."
if ! curl -s "$WAZUH_GPG_KEY" | gpg --no-default-keyring --keyring gnupg-ring:"$KEYRING_PATH" --import; then
    echo "Failed to import Wazuh GPG key." >&2
    exit 1
fi
chmod 644 "$KEYRING_PATH"

echo "Adding Wazuh repository to $WAZUH_REPO_FILE..."
echo "deb [signed-by=$KEYRING_PATH] https://packages.wazuh.com/4.x/apt/ stable main" >"$WAZUH_REPO_FILE"

echo "Updating package lists..."
apt update

echo "Installing Wazuh agent..."
if ! apt install -y wazuh-agent; then
    echo "Failed to install Wazuh agent." >&2
    exit 1
fi

echo "Configuring and starting Wazuh agent..."
systemctl daemon-reload
systemctl enable wazuh-agent || {
    echo "Failed to enable wazuh-agent service."
    exit 1
}
systemctl start wazuh-agent || {
    echo "Failed to start wazuh-agent service."
    exit 1
}

if [[ -f $AGENT_CONF ]]; then
    echo "Updating config in $AGENT_CONF..."
    sed -i "s#<address>.*</address>#<address>172.20.241.20</address>#g" "$AGENT_CONF"
    
    systemctl restart wazuh-agent || {
        echo "Failed to restart wazuh-agent after configuration."
        exit 1
    }
else
    echo "Configuration file $AGENT_CONF not found. Please update the Wazuh manager IP manually." >&2
fi

echo "Disabling Wazuh repository..."
sed -i "s/^deb/#deb/" "$WAZUH_REPO_FILE"

echo "Refreshing package lists after disabling the Wazuh repository..."
if ! apt update; then
    echo "Failed to update package lists after disabling the repository." >&2
    exit 1
fi

echo "Wazuh agent installation complete."



                                                                                                                                                                                                                                                                                                                                                                                   ./install_wazuh_agent_yum.sh                                                                        0000755 0001750 0000355 00000003334 14751162272 016630  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              #!/usr/bin/env bash
#
# Author: Nicholas Hooper
# Description:
# Install & Configure Wazuh Agent ( yum )
# Usage:
# ./<Script_Name>

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." >&2
   exit 1
fi

if ! command -v curl &> /dev/null
then
    echo "curl could not be found, please install curl."
    exit 1
fi

WAZUH_GPG_KEY="https://packages.wazuh.com/key/GPG-KEY-WAZUH"
WAZUH_REPO_FILE="/etc/yum.repos.d/wazuh.repo"
AGENT_CONF="/var/ossec/etc/ossec.conf"

# read -p "Enter manager IP: " WAZUH_MANAGER

echo "Importing Wazuh GPG key..."
rpm --import "$WAZUH_GPG_KEY" || { echo "Failed to import GPG key"; exit 1; }

echo "Creating Wazuh repository file at $WAZUH_REPO_FILE..."
cat > "$WAZUH_REPO_FILE" << EOF
[wazuh]
gpgcheck=1
gpgkey=$WAZUH_GPG_KEY
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF

echo "Installing Wazuh agent..."
if ! yum install -y wazuh-agent; then
    echo "Failed to install Wazuh agent. Exiting." >&2
    exit 1
fi

echo "Configuring and starting Wazuh agent..."
systemctl daemon-reload
systemctl enable wazuh-agent || { echo "Failed to enable wazuh-agent"; exit 1; }
systemctl start wazuh-agent || { echo "Failed to start wazuh-agent"; exit 1; }

echo "Disabling Wazuh repository..."
sed -i "s/^enabled=1/enabled=0/" "$WAZUH_REPO_FILE"

if [[ -f $AGENT_CONF ]]; then
    echo "Updating config in $AGENT_CONF..."
    sed -i "s#<address>.*</address>#<address>172.20.241.20</address>#g" "$AGENT_CONF"
     
    systemctl restart wazuh-agent || { echo "Failed to restart wazuh-agent after configuration"; exit 1; }
else
    echo "Configuration file $AGENT_CONF not found. Please update the Wazuh manager IP manually."
fi

echo "Wazuh agent installation complete."
                                                                                                                                                                                                                                                                                                    ./install_wazuh_server.sh                                                                           0000755 0001750 0000355 00000002123 14751162272 016141  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              #!/usr/bin/env bash
#
# Author: Nicholas Hooper
# Description:
# Initializes Wazuh Server Central Components via Docker 
# Usage:
# ./<Script_Name>


if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
fi

if ! command -v git &> /dev/null
then
    echo "installing git. . ."
    yum install git
    exit 1
fi

if ! command -v docker &> /dev/null
then
    echo "installing docker. . ."
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl start docker
    exit 1
fi

sysctl -w vm.max_map_count=262144


if [ ! -d "wazuh-docker" ]; then

    git clone https://github.com/wazuh/wazuh-docker.git -b v4.10.1
else
    echo "directory 'wazuh-docker' already exists - skipping clone."

    cd wazuh-docker && git pull origin v4.10.1
    cd ..
fi

cd ./wazuh-docker/single-node || { echo "Failed to enter wazuh-docker directory"; exit 1; }

docker compose -f generate-indexer-certs.yml run --rm generator

docker compose up -d
                                                                                                                                                                                                                                                                                                                                                                                                                                             ./kernel_settings.sh                                                                                0000755 0001750 0001750 00000001715 14747657376 014372  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
# Tweaks
# Usage:
# ./<Script_Name>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

echo '''kernel.sysrq = 1
kernel.panic = 5
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 5
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
kernel.randomize_va_space=2
fs.inotify.max_user_watches=524288
''' >> /etc/sysctl.d/99-sysctl.conf

/sbin/sysctl -p /etc/sysctl.d/99-sysctl.conf                                                   ./login_banner.sh                                                                                   0000755 0001750 0001750 00000001753 14747643342 013615  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env nix
#! nix shell nixpkgs#bash nixpkgs#initool --command bash
# Author: Collin Dewey
# Description:
# Creates a login banner for Linux devices
# Usage: 
# ./<Script_Name> <Banner Text> <Splunk Location>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

if [ $# -ne 1 ]; then
    echo "Usage: $0 <Banner Text> <Splunk Location>"
    exit 1
fi

echo "$1" > /etc/issue
echo "$1" > /etc/issue.net
echo "$1" > /etc/motd

# Splunk
if [ -z "$2" ]; then
    SPLUNK_HOME=/opt/splunk
else
    SPLUNK_HOME="$2"
fi

if [ -d "$SPLUNK_HOME" ]; then 
    if ! command -v initool &> /dev/null; then
        echo "Splunk detected, but initool is not available"
        exit 1
    fi
    if [ ! -f "$SPLUNK_HOME"/etc/system/local/web.conf ]; then mkdir -p "$SPLUNK_HOME"/etc/system/local; touch "$SPLUNK_HOME"/etc/system/local/web.conf; fi
    initool set "$SPLUNK_HOME"/etc/system/local/web.conf settings login_content "$1" > "$SPLUNK_HOME"/etc/system/local/web.conf 
fi
                     ./misc_tweaks.sh                                                                                    0000755 0001750 0001750 00000001233 14750043424 013447  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Description:
# Performs various actions
# Usage:
# ./<SCRIPT NAME>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

# Rename a bunch of tools that might be useful
function move {
    if [ -f $1 ]; then
        mv "$1" "${1}.old"
    fi
}

# Executables
# move /bin/dd # This apparently breaks makeself
move /bin/dig
move /bin/base64
move /bin/at
move /bin/nc
move /bin/ncat

move /etc/ld.so.preload
# move /etc/ld.so.cache # Broke Ubuntu 16.04 for some reason
move /etc/inittab
touch /etc/inittab
chattr +i /etc/inittab

# Disable cron
move /usr/sbin/cron
cut -d: -f1 /etc/passwd | tail -n+2 >> /etc/cron.deny                                                                                                                                                                                                                                                                                                                                                                     ./scanInternal.sh                                                                                   0000755 0001750 0000355 00000000620 14751244133 014305  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              #!/bin/sh

#Internal
echo "Iternal Network scan" > Output.txt
nmap 172.20.240.10 >> Output.txt 
nmap 172.20.240.20 >> Output.txt 

#Public
echo "Public Network Scan" >> Output.txt
nmap 172.20.241.20 >> Output.txt
nmap 172.20.242.30 >> Output.txt
nmap 172.20.241.40 >> Output.txt

#User
echo "user network scan" >> Output.txt
nmap 172.20.242.10 >> Output.txt
nmap 172.20.242.200 >> Output.txt 

exit 0                                                                                                                ./setup_clamav.sh                                                                                   0000755 0001750 0001750 00000010540 14747656701 013640  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env nix
#! nix shell nixpkgs#bash nixpkgs#clamav nixpkgs#chkrootkit nixpkgs#shadow nixpkgs#killall --command bash
# Author: Collin Dewey
# Description:
# Runs ClamAV & chkrootkit
# Usage:
# ./<Script_Name>

SCAN_DIRS=( "/bin" "/home" "/lib" "/lib64" "/opt" "/root" "/sbin" "/usr" "/var" "/snap/bin" )
ONACC_SCAN_DIRS=( "/home" "/root" )

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check
nix_shell_guard

create_group clamav
create_user clamav clamav

if [ ! -d /etc/clamav ]; then
    mkdir -p /etc/clamav/quarantine
    mkdir -p /etc/clamav/db
    chown -R clamav /etc/clamav
fi

if [ ! -f /etc/clamav/freshclam.conf ]; then # https://github.com/Cisco-Talos/clamav/raw/main/etc/freshclam.conf.sample
    echo "
DatabaseMirror database.clamav.net
DatabaseDirectory /etc/clamav/db
DatabaseOwner clamav
    " > /etc/clamav/freshclam.conf
    #web freshclam
fi
# Freshclam was being weird. Download manually I guess. Cisco's mirror is behind cloudflare, so M$ it is
echo "Downloading main.cvd"
download https://packages.microsoft.com/clamav/main.cvd /etc/clamav/db/main.cvd
echo "Downloading daily.cvd"
download https://packages.microsoft.com/clamav/daily.cvd /etc/clamav/db/daily.cvd
echo "Downloading bytecode.cvd"
download https://packages.microsoft.com/clamav/bytecode.cvd /etc/clamav/db/bytecode.cvd

if [ ! -f /etc/clamav/clamd.conf ]; then # https://github.com/Cisco-Talos/clamav/raw/main/etc/clamd.conf.sample
    echo "
VirusEvent wall -n \"Alert: %v located in %f\"; chmod -x %f; chown clamav %f; mv %f /etc/clamav/quarantine
LocalSocket /run/clamav/clamd.sock
DatabaseDirectory /etc/clamav/db
OnAccessExcludeUname clamav
LogFile /var/log/clamd.log
ExcludePath ^/etc/clamav/
OnAccessPrevention no
DetectPUA yes
LogSyslog yes
ExitOnOOM yes
LogTime yes
User root
    " > /etc/clamav/clamd.conf
    for DIR in "${ONACC_SCAN_DIRS[@]}"; do
        echo "OnAccessIncludePath $DIR" >> /etc/clamav/clamd.conf
    done
fi

# SystemD
if command -v systemctl >/dev/null 2>&1; then
    echo "SystemD detected"
    if [ ! -f /etc/systemd/system/clamav-daemon.service ]; then
        echo "
[Unit]
Description=Clam AntiVirus userspace daemon

[Service]
ExecStart=$(which clamd) --foreground=true
ExecReload=$(which killall) clamd
TimeoutStartSec=420

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/clamav-daemon.service
        systemctl enable clamav-daemon.service # "enable --now" wasn't a thing on older versions of SystemD
        systemctl start clamav-daemon.service
    fi
    if [ ! -f /etc/systemd/system/clamav-clamonacc.service ]; then
    echo "
[Unit]
Description=ClamAV On-Access Scanner
Requires=clamav-daemon.service
After=clamav-daemon.service

[Service]
Type=simple
User=root
ExecStart=$(which clamonacc) -F
ExecReload=$(which killall) -9 clamonacc

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/clamav-clamonacc.service
    systemctl enable clamav-clamonacc.service
    fi
    if [ ! -f /etc/systemd/system/clamav-scan.service ]; then
    echo "
[Unit]
Description=ClamAV Routine Scan

[Service]
Type=oneshot
User=root
ExecStart=$(which bash) /etc/clamav/scan.sh

" > /etc/systemd/system/clamav-scan.service
    fi
    if [ ! -f /etc/systemd/system/clamav-scan.timer ]; then
    echo "
[Unit]
Description=ClamAV Routine Scan Timer

[Timer]
OnCalendar=*-*-* *:00/30:00

[Install]
WantedBy=timers.target
" > /etc/systemd/system/clamav-scan.timer
    fi
    systemctl start clamav-scan.timer
else
    echo "SystemD not detected"
    echo "Executing clamd"
    killall clamd -qw # Kill existing
    clamd # Forks to background
fi

# Iterate over each directory and perform the scan
echo "#!$(which bash)" > /etc/clamav/scan.sh
chmod +x /etc/clamav/scan.sh

for DIR in "${SCAN_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        echo "echo -e \"\nScanning $DIR\" | tee -a /var/log/clamdscan.log" >> /etc/clamav/scan.sh
        echo "$(which clamdscan) \"$DIR\" --multiscan --infected --wait | tee -a /var/log/clamdscan.log" >> /etc/clamav/scan.sh
    fi
done

echo "Executing chkrootkit"
chkrootkit | tee /var/log/chkrootkit.log
echo "Executing clamdscan"
bash /etc/clamav/scan.sh

echo "Results in /var/log/chkrootkit.log"
echo "Results in /var/log/clamdscan.log"

echo "Starting clamonacc"
if command -v systemctl >/dev/null 2>&1; then
    systemctl start clamav-clamonacc.service
else
    killall clamonacc -9qw # Kill existing
    clamonacc # Forks to background
fi                                                                                                                                                                ./setup_dot.sh                                                                                      0000755 0001750 0001750 00000006237 14747643357 013176  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env nix
#! nix shell nixpkgs#bash nixpkgs#stubby nixpkgs#getdns nixpkgs#openssl --command bash
# Author: Collin Dewey
# Description:
# Sets up DNS over TLS using Stubby
# Usage:
# ./<Script_Name>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check
nix_shell_guard

if [ ! -d /etc/stubby ]; then
    mkdir -p /etc/stubby/cache
    echo "
log_level: GETDNS_LOG_NOTICE
resolution_type: GETDNS_RESOLUTION_STUB
dns_transport_list:
  - GETDNS_TRANSPORT_TLS
#  - GETDNS_TRANSPORT_UDP
#  - GETDNS_TRANSPORT_TCP
#tls_authentication: GETDNS_AUTHENTICATION_NONE
tls_authentication: GETDNS_AUTHENTICATION_REQUIRED
tls_query_padding_blocksize: 128
edns_client_subnet_private : 1
round_robin_upstreams: 1
idle_timeout: 10000
tls_ca_path: "/etc/ssl/certs/"
listen_addresses:
  - 127.0.8.53
dnssec: GETDNS_EXTENSION_TRUE
appdata_dir: "/etc/stubby/cache"
upstream_recursive_servers:
  - address_data: 185.49.141.37
    tls_port: 443
    tls_auth_name: "getdnsapi.net"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: $(echo | openssl s_client -connect '185.49.141.37:443' 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64)
  - address_data: 89.234.186.112
    tls_port: 443
    tls_auth_name: "dns.neutopia.org"
    tls_pubkey_pinset:
      - digest: "sha256"
        value: $(echo | openssl s_client -connect '89.234.186.112:443' 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64)
    " > /etc/stubby/stubby.yml
fi


if command -v systemctl >/dev/null 2>&1; then
    echo "
[Unit]
Description=Stubby
After=network-online.target

[Service]
Type=simple
ExecStart=$(which stubby) -l -C /etc/stubby/stubby.yml
Group=internet_out

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/stubby.service
    systemctl enable stubby.service
    systemctl start stubby.service
else
    stubby -g -C /etc/stubby/stubby.yml
fi

# Make NetworkManager not control DNS
if [ -d /etc/NetworkManager/conf.d ]; then #https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/manually-configuring-the-etc-resolv-conf-file_configuring-and-managing-networking
    echo "[main]
dns=none" > /etc/NetworkManager/conf.d/90-dns-none.conf
    systemctl restart NetworkManager
fi

# If using systemd-resolved, use stubby
if [ -f /etc/systemd/resolved.conf ]; then
    if ! grep -q "DNS=127.0.8.53" /etc/systemd/resolved.conf; then
        echo "DNS=127.0.8.53" >> /etc/systemd/resolved.conf
        systemctl restart systemd-resolved
    fi
fi

if [ -d /etc/resolvconf/resolv.conf.d ]; then
    if ! grep -q "nameserver 127.0.8.53" /etc/resolvconf/resolv.conf.d/head; then
        echo "nameserver 127.0.8.53" >> /etc/resolvconf/resolv.conf.d/head
        resolvconf -u
    fi
fi

if ! grep -q "nameserver 127.0.8.53" /etc/resolv.conf; then
    echo "nameserver 127.0.8.53
$(cat /etc/resolv.conf)" > /etc/resolv.conf
fi

# TODO: On Ubuntu, there's a dns-nameservers line on /etc/network/interfaces & /etc/sysconfig/network

# Grab the DNSSEC Keys
getdns_query -s @127.0.8.53 github.com > /dev/null                                                                                                                                                                                                                                                                                                                                                                 ./setup_el_repo.sh                                                                                  0000755 0001750 0001750 00000000752 14747643365 014030  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
# Sets up the ELRepo
# Usage:
# ./<Script_Name>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

if [ -f /etc/centos-release ] && grep -q "CentOS release 7" /etc/centos-release; then
    rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    sed -i "s|enabled=0|enabled=1|g" /etc/yum.repos.d/elrepo.repo 
fi                      ./setup_firewall.sh                                                                                 0000755 0001750 0001750 00000013053 14751036047 014172  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Description:
# Setups sample firewall rules
# Usage:
# ./<SCRIPT NAME>
# Supports ICMP, and user defined rules in vars input_rules and output_rules

# Variables
Inside="172.20.240.0/22"
Any="0.0.0.0/0"

input_rules=(
#    "21 tcp $Any honeypot_in" # Telnet/FTP from any
#    "23 tcp $Any honeypot_in" # Telnet/FTP from any
#    "22 tcp $Any ssh_in" # SSH from any
    "25 tcp $Any all" # SMTP from any
    "53 udp $Any dns_in" # DNS from any
#    "69 udp $Any all" # TFTP from any
    "80 tcp $Any http_in" # HTTP from any
    "110 tcp $Any mail_in" # POP3 from any
    "123 udp $Inside ntp_in" # NTP from inside
    "143 tcp $Any mail_in" # IMAP from any
#    "514 udp $Inside all" # Syslog from inside (UDP)
#    "514 tcp $Inside all" # Syslog from inside (TCP)
#    "3306 tcp $Inside all" # MySQL from inside
    "8000 tcp $Any all" # Splunk from any
)

output_rules=(
    "80 tcp $Any internet_out" # HTTP to any
    "53 udp $Any internet_out" # DNS to AD
    "53 udp 172.20.242.200 internet_out" # DNS to AD
    "123 udp 172.20.240.20 all" # NTP to Debian 8.5
#    "389 tcp 172.20.242.200" # LDAP to AD
    "443 tcp $Any internet_out" # HTTPS to any
    "443 tcp 172.20.242.150 all" # HTTPS to Palo Alto
    "514 udp 172.20.241.20 root" # Syslog to Splunk
#    "3306 tcp 172.20.242.10" # MySQL to Web
    "1514 tcp 172.20.241.20 all" # Wazuh Agent Connection
    "1515 tcp 172.20.241.20 all" # Wazuh Agent Enrollment
    "1516 tcp 172.20.241.20 all" # Wazuh Agent Cluster
    "8000 tcp 172.20.241.20 internet_out" # HTTP to Splunk
)

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

if [ -f "/usr/sbin/iptables-nft" ]; then # Oh no
    shopt -s expand_aliases
    alias iptables=/usr/sbin/iptables-nft
    alias iptables-save=/usr/sbin/iptables-nft-save
    alias ip6tables=/usr/sbin/ip6tables-nft
    alias ip6tables-save=/usr/sbin/ip6tables-nft-save
fi

# Reset and disable IPv6
table_names=$(ip6tables-save | grep '^*' | sed 's/*//g' | sort | uniq)
for table_name in $table_names
do
  ip6tables -t $table_name -F
  ip6tables -t $table_name -X
done
ip6tables -F
ip6tables -X
ip6tables -Z
ip6tables -P INPUT DROP
ip6tables -P OUTPUT DROP
ip6tables -P FORWARD DROP

# Reset IPv4
table_names=$(iptables-save | grep '^*' | sed 's/*//g' | sort | uniq)
for table_name in $table_names
do
  iptables -t $table_name -F
  iptables -t $table_name -X
done
iptables -F
iptables -X
iptables -Z
iptables -P FORWARD DROP

# IPv4 inbound
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -f -j DROP
iptables -A INPUT -p icmp --icmp-type echo-reply -m length --length 40:84 -m state --state NEW,ESTABLISHED,RELATED -m hashlimit --hashlimit-name PING_IREP --hashlimit 1/sec --hashlimit-burst 3 --hashlimit-mode srcip --hashlimit-htable-expire 300000 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -m length --length 40:84 -m state --state NEW,ESTABLISHED,RELATED -m hashlimit --hashlimit-name PING_IREQ --hashlimit 1/sec --hashlimit-burst 3 --hashlimit-mode srcip --hashlimit-htable-expire 300000 -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
for i in "${input_rules[@]}"; do
    IFS=' ' read -ra rule <<< "$i"
    if [[ ${rule[3]} == "all" ]]; then
        iptables -A OUTPUT -p "${rule[1]}" --dport "${rule[0]}" -s "${rule[2]}" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    else
        iptables -A OUTPUT -p "${rule[1]}" --dport "${rule[0]}" -s "${rule[2]}" -m owner --gid-owner "${rule[3]}" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    fi
done
iptables -P INPUT DROP

# IPv4 outbound
iptables -A OUTPUT -p icmp --icmp-type echo-reply -m length --length 40:84 -m state --state NEW,ESTABLISHED,RELATED -m hashlimit --hashlimit-name PING_OREP --hashlimit 1/sec --hashlimit-burst 3 --hashlimit-mode srcip --hashlimit-htable-expire 300000 -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type echo-request -m length --length 40:84 -m state --state NEW,ESTABLISHED,RELATED -m hashlimit --hashlimit-name PING_OREQ --hashlimit 1/sec --hashlimit-burst 3 --hashlimit-mode srcip --hashlimit-htable-expire 300000 -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -o lo -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
for i in "${output_rules[@]}"; do
    IFS=' ' read -ra rule <<< "$i"
    if [[ ${rule[3]} == "all" ]]; then
        iptables -A OUTPUT -p "${rule[1]}" --dport "${rule[0]}" -d "${rule[2]}" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    else
        iptables -A OUTPUT -p "${rule[1]}" --dport "${rule[0]}" -d "${rule[2]}" -m owner --gid-owner "${rule[3]}" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    fi
done
iptables -P OUTPUT DROP

if [ -f "/etc/iptables/rules.v4" ]; then
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
fi

if [ -d "/etc/sysconfig" ]; then
    iptables-save > /etc/sysconfig/iptables
    ip6tables-save > /etc/sysconfig/ip6tables
    if [ -f "/etc/sysconfig/iptables" ] && ! systemctl list-unit-files --type=service | grep -q "\<iptables.service\>"; then
        web yum install iptables-services -y
        systemctl enable iptables.service
    fi
fi

#if [ -f "/usr/sbin/iptables-restore-translate" ]; then
#    iptables-save > tmp.iptables
#    iptables-restore-translate -f tmp.iptables > tmp.nft
#    nft -f tmp.nft
#fi

if [ ! -f "/etc/iptables/rules.v4" ] && command -v apt-get >/dev/null 2>&1; then
    web apt-get update
    web apt-get install -y iptables-persistent
fi

# TODO: Proper nftables                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ./setup_honeypot.sh                                                                                 0000755 0001750 0001750 00000003700 14747643400 014232  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env nix
#! nix shell nixpkgs#bash nixpkgs#honeytrap --command bash
# Author: Collin Dewey
# Description:
# It's a trap!
# Usage:
# ./<Script_Name>

#credentials=["root:root", "root:password"]

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check
nix_shell_guard

if [ ! -d /etc/honeytrap ]; then
    mkdir -p /etc/honeytrap
    echo '''
[listener]
type="socket"

[service.ssh-simulator]
type="ssh-simulator"
motd="UNAUTHORIZED ACCESS TO THIS DEVICE IS PROHIBITED. You must have explicit, authorized permission to access or configure this device. Unauthorized attempts and actions to access or use this system may result in civil and/or criminal penalties. All activities performed on this device are logged and monitored.\n"

[[port]]
port="tcp/22"
services=["ssh-simulator"]

[service.telnet]
type="telnet"
prompt=">"
motd="UNAUTHORIZED ACCESS TO THIS DEVICE IS PROHIBITED. You must have explicit, authorized permission to access or configure this device. Unauthorized attempts and actions to access or use this system may result in civil and/or criminal penalties. All activities performed on this device are logged and monitored.\n"

[[port]]
port="tcp/23"
services=["telnet"]

[channel.console]
type="console"

[channel.log]
type="file"
filename="/var/log/honeytrap.log"
maxsize=536870912

[[filter]]
channel=["console"]
services=["ssh-simulator telnet"]

[[filter]]
channel=["log"]
services=["ssh-simulator telnet"]

[[logging]]
output="stdout"
level="debug"''' > /etc/honeytrap/config.toml
fi

if command -v systemctl >/dev/null 2>&1; then
    echo "
[Unit]
Description=Honeytrap
After=network-online.target

[Service]
Type=simple
Group=honeypot_in
ExecStart=$(which honeytrap) --data /etc/honeytrap

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/honeytrap.service
    systemctl enable honeytrap.service
    systemctl start honeytrap.service
else
    honeytrap --config /etc/honeytrap/config.toml --data /etc/honeytrap
fi
                                                                ./setup_nix.sh                                                                                      0000755 0001750 0001750 00000003741 14750524756 013176  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
# Incorrectly installs a third party package manager
# Usage:
# ./<Script_Name>
BRANCH="maintenance-2.24" # 2.25 and above changed the way packages are distributed through hydra

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

mkdir -p /etc/nix

# Update System Certificates
download https://curl.se/ca/cacert.pem /etc/nix/ca-bundle.crt

# Download Nix
force_kill nix
download "https://hydra.nixos.org/job/nix/$BRANCH/buildStatic.nix.x86_64-linux/latest/download-by-type/file/binary-dist" /bin/nix 

# Configure
chmod +x /bin/nix
echo "extra-experimental-features = nix-command flakes auto-allocate-uids configurable-impure-env
ssl-cert-file = /etc/nix/ca-bundle.crt
auto-allocate-uids = true
use-xdg-base-directories = true
build-users-group = " > /etc/nix/nix.conf

# Create SystemD Service
if command -v systemctl >/dev/null 2>&1; then
    echo "
[Unit]
Description=Nix Daemon

[Service]
Type=simple
ExecStart=/bin/nix daemon
Group=internet_out

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/nix-daemon.service
    systemctl daemon-reload
    systemctl enable nix-daemon.service # "enable --now" wasn't a thing on older versions of SystemD
    systemctl start nix-daemon.service
    sleep 2 # Icky
fi

# Pin
web nix registry pin github:NixOS/nixpkgs/nixos-unstable

# Copy closure if exists
if [ -d "/opt/ccdc/closure" ]; then
    /bin/nix copy --from /opt/ccdc/closure
    rm -rf /opt/ccdc/closure
fi

# Setup Comma
rc="/dev/null"
if [ -f "/etc/bashrc" ]; then
    rc="/etc/bashrc"
elif [ -f "/etc/bash.bashrc" ]; then
    rc="/etc/bash.bashrc"
fi

if ! grep -q "nix" $rc; then
    echo ". $(dirname "$0")/helper.sh" >> $rc
    echo 'alias update,="mkdir -p ~/.cache/nix-index; download https://github.com/Mic92/nix-index-database/releases/latest/download/index-x86_64-linux ~/.cache/nix-index/files; chown -R "$UID" ~/.cache/nix-index"' >> $rc
    echo 'alias ,="web nix run nixpkgs#comma --"' >> $rc
fi                               ./setup_ntp.sh                                                                                      0000755 0001750 0001750 00000002504 14747643423 013174  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
# Configures timesyncd/chrony/NTPd
# Usage:
# ./<Script_Name> <NTP_SERVER>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

if [ $# -ne 1 ]; then
    echo "Usage: $0 <NTP_SERVER>"
    exit 1
fi

if [ -f "/etc/systemd/timesyncd.conf" ]; then
    mkdir -p /etc/systemd/timesyncd.conf.d
    echo "NTP=$1" >> /etc/systemd/timesyncd.conf.d/server.conf
    timedatectl set-ntp true
    systemctl restart systemd-timesyncd
    echo "systemd-timesyncd"
    exit 1
fi

if [ -f "/etc/chrony.conf" ]; then
    mv /etc/chrony.conf /etc/chrony.conf.old
    echo "server $1 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony" > /etc/chrony.conf
    systemctl restart chronyd
    echo "chronyd"
    exit 1
fi

if command -v ntp >/dev/null 2>&1 || command -v ntpd >/dev/null 2>&1; then
    echo "ntpd"
else
    if command -v apt-get >/dev/null 2>&1; then
        DEBIAN_FRONTEND="noninteractive" web apt-get update -y
        DEBIAN_FRONTEND="noninteractive" web apt-get install ntp -y
    elif command -v yum >/dev/null 2>&1; then
        web yum install -y ntp
    else
        echo "Insomnia"
        exit 1
    fi
fi
sed -i 's/^server/#&/' /etc/ntp.conf
echo "server $1" >> /etc/ntp.conf                                                                                                                                                                                            ./setup_ssh.sh                                                                                      0000755 0001750 0000355 00000005452 14751245655 013723  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              #!/usr/bin/env nix
#! nix shell nixpkgs#bash nixpkgs#openssh --command bash
# Author: Collin Dewey
# Description:
# Configures SSH
# Usage:
# ./<Script_Name>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

if [ -f /usr/lib/systemd/system/sshd.service ] || [ -f /lib/systemd/system/sshd.service ]; then
    NAME=sshd
else
    NAME=ssh
fi

if systemctl is-active --quiet $NAME; then
    systemctl stop $NAME
fi

if ! systemctl is-enabled --quiet $NAME 2>/dev/null; then
    systemctl unmask $NAME
fi

if [ ! -d /etc/ssh.orig ]; then
    mv /etc/ssh /etc/ssh.orig
else
    rm -rf /etc/ssh.old
    mv /etc/ssh /etc/ssh.old
fi
mkdir -p /etc/ssh
mkdir -p /var/empty # Why?

# https://github.com/k4yt3x/sshd_config/
# https://infosec.mozilla.org/guidelines/openssh#modern-openssh-67
echo "AuthorizedPrincipalsFile none
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
GatewayPorts no
KbdInteractiveAuthentication no
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
Macs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
PasswordAuthentication no
AuthenticationMethods publickey
LogLevel VERBOSE
AllowTcpForwarding no
ChallengeResponseAuthentication no
MaxAuthTries 3
PermitEmptyPasswords no
AllowAgentForwarding no
ClientAliveCountMax 2
ClientAliveInterval 300
Compression no
IgnoreRhosts yes
PermitUserEnvironment no
MaxSessions 2
TCPKeepAlive no
Protocol 2
AllowStreamLocalForwarding no
DisableForwarding yes
PermitTunnel no
PermitRootLogin no
StrictModes yes
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
UseDns no
X11Forwarding no
UsePAM no
Banner /etc/issue.net
AuthorizedKeysFile %h/.ssh/authorized_keys_ccdc
AddressFamily any
Port 22
ListenAddress 0.0.0.0
Subsystem sftp $(nix path-info nixpkgs#openssh)/libexec/sftp-server -f AUTHPRIV -l INFO
PrintMotd no # handled by pam_motd
AllowGroups sshusers
#Match User example
#  ForceCommand internal-sftp
#  ChrootDirectory /var/lib/sftp
" > /etc/ssh/sshd_config

cp $(nix path-info nixpkgs#openssh)/etc/ssh/moduli /etc/ssh/moduli
cp $(nix path-info nixpkgs#openssh)/etc/ssh/ssh_config /etc/ssh/ssh_config
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ""
create_group sshusers

chown root:root -R /etc/ssh
chmod 644 -R /etc/ssh
chmod 600 /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_rsa_key

mkdir -p "/etc/systemd/system/$NAME.service.d"
echo "[Service]
Type=simple
EnvironmentFile=
Group=ssh_in
ExecStartPre=
ExecStart=
ExecStart=$(which sshd)
ExecReload=
ExecReload=/bin/kill -HUP \$MAINPID" > "/etc/systemd/system/$NAME.service.d/override.conf"

systemctl daemon-reload
systemctl start $NAME                                                                                                                                                                                                                      ./setup_syslog.sh                                                                                   0000755 0001750 0001750 00000000743 14747774130 013716  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
# Forwards logs using rsyslog to a specified address
# Usage: 
# ./<Script_Name> <IP>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

IP_ADDR="$1"

echo "
*.* @$IP_ADDR:514
*.* @@$IP_ADDR:514
" >> /etc/rsyslog.conf

if [ -f /etc/systemd/journald.conf ]; then
    echo "ForwardToSyslog=yes" >> /etc/systemd/journald.conf
    systemctl restart systemd-journald
fi

systemctl restart rsyslog                             ./setup_terminal_candy.sh                                                                           0000755 0001750 0001750 00000005350 14750377453 015367  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env nix
#! nix shell nixpkgs#bash nixpkgs#zsh nixpkgs#zsh-defer nixpkgs#zsh-nix-shell nixpkgs#zsh-fast-syntax-highlighting nixpkgs#zsh-autosuggestions nixpkgs#oh-my-zsh nixpkgs#zsh-history-substring-search nixpkgs#eza nixpkgs#comma --command bash
# Author: Collin Dewey
# Description:
# Configures ZSH
# Usage:
# ./<Script_Name>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
nix_shell_guard

echo "
autoload -Uz promptinit
promptinit
prompt suse
setopt histignorealldups sharehistory
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history
source \"$(nix path-info nixpkgs#zsh-defer)/share/zsh-defer/zsh-defer.plugin.zsh\";
zsh-defer source \"$(nix path-info nixpkgs#zsh-nix-shell)/share/zsh-nix-shell/nix-shell.plugin.zsh\";
zsh-defer source \"$(nix path-info nixpkgs#zsh-fast-syntax-highlighting)/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh\";
zsh-defer source \"$(nix path-info nixpkgs#zsh-history-substring-search)/share/zsh-history-substring-search/zsh-history-substring-search.zsh\";
zsh-defer source \"$(nix path-info nixpkgs#oh-my-zsh)/share/oh-my-zsh/plugins/sudo/sudo.plugin.zsh\";
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
alias ls=\"$(which eza)\"
alias ll=\"$(which eza) -l\"
. /opt/ccdc/helper.sh # Hardcoded. It shouldn't be. But it is.
alias update,=\"mkdir -p ~/.cache/nix-index; download https://github.com/Mic92/nix-index-database/releases/latest/download/index-x86_64-linux ~/.cache/nix-index/files; chown -R \"\$UID\" ~/.cache/nix-index\"
alias ,=\"web $(which ,)\"
RPROMPT='%F{white}[%*]%f'

# From https://wiki.archlinux.org/title/Zsh#Key_bindings
typeset -g -A key

bindkey -- \"\${terminfo[khome]}\"   beginning-of-line
bindkey -- \"\${terminfo[kend]}\"    end-of-line
bindkey -- \"\${terminfo[kich1]}\"   overwrite-mode
bindkey -- \"\${terminfo[kbs]}\"     backward-delete-char
bindkey -- \"\${terminfo[kdch1]}\"   delete-char
#bindkey -- \"\${terminfo[kcuu1]}\"  up-line-or-history
bindkey -- \"\${terminfo[kcuu1]}\"   history-substring-search-up
#bindkey -- \"\${terminfo[kcud1]}\"  down-line-or-history
bindkey -- \"\${terminfo[kcud1]}\"   history-substring-search-down
bindkey -- \"\${terminfo[kcub1]}\"   backward-char
bindkey -- \"\${terminfo[kcuf1]}\"   forward-char
bindkey -- \"\${terminfo[kpp]}\"     beginning-of-buffer-or-history
bindkey -- \"\${terminfo[knp]}\"     end-of-buffer-or-history
bindkey -- \"\${terminfo[kcbt]}\"    reverse-menu-complete
" > ~/.zshrc
cp ~/.zshrc /opt/ccdc/.zshrc

if command -v sudo &> /dev/null; then
  if [ -f /bin/zsh ]; then
    sudo mv /bin/zsh /bin/zsh_
  fi
  sudo ln -s $(which zsh) /bin/zsh
else
  if [ -f /bin/zsh ]; then
    su -c "mv /bin/zsh /bin/zsh_"
  fi
  su -c "ln -s $(which zsh) /bin/zsh"
fi

echo "Run zsh"                                                                                                                                                                                                                                                                                        ./setup_users.sh                                                                                    0000755 0001750 0001750 00000003362 14750400476 013530  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
# Sets up groups and users
# Usage: 
# ./<Script_Name>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

PATH=/usr/sbin/:/sbin/:$PATH

mkdir -p /opt/ccdc

if [[ $(hostname -s) == "fedora" ]]; then
    userdel system
    chattr -i /usr/sbin/nologin
    cp /bin/false /usr/sbin/nologin
    for user in $(grep -vE '/bin/false|/usr/sbin/nologin' /etc/passwd | cut -d: -f1); do
        echo "Changing Account Shell: $user"
        usermod --shell /usr/sbin/nologin $user
    done
else
    awk -F: '($2 != "" && $2 !~ /^[!*]/) {system("echo Locking Account: "$1"; usermod --lock "$1)}' /etc/shadow # Isn't AI cool?
    for user in $(grep -vE '/bin/false|/usr/sbin/nologin' /etc/passwd | cut -d: -f1); do
        echo "Changing Account Shell: $user"
        usermod --shell /usr/sbin/nologin $user
    done
fi
create_user ccdc

while true; do
    echo "Enter new password for root"
    passwd root </dev/tty
    if [[ $? -eq 0 ]]; then
        break
    fi
done
usermod -s /bin/bash -U root
while true; do
    echo "Enter new password for ccdc"
    passwd ccdc </dev/tty
    if [[ $? -eq 0 ]]; then
        break
    fi
done
usermod -d /opt/ccdc -s /bin/bash -U ccdc
mkdir -p /etc/sudoers.d
echo "ccdc ALL=(ALL) ALL" > /etc/sudoers.d/ccdc
chown -R ccdc /opt/ccdc

# GDM
if [ -d /var/lib/AccountsService/users ]; then
    echo -e "[User]\nSystemAccount=false" > /var/lib/AccountsService/users/ccdc
fi

create_group internet_out
sed -i 's/internet_out:!::/internet_out:$1$EX3DJOZZ$mNk.jlKMwAyl1GGO2lsH90::/g' /etc/gshadow # This is a lowercase y
create_group mail_in
create_group ntp_in
create_group dns_in
create_group http_in
create_group honeypot_in
create_group ssh_in
create_group sshusers                                                                                                                                                                                                                                                                              ./update_bind9.sh                                                                                   0000755 0001750 0000355 00000001313 14751245657 014247  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              #!/usr/bin/env nix
#! nix shell nixpkgs#bash nixpkgs#bind --command bash
# Author: Collin Dewey
# Description:
# Bind9 SystemD Override
# Usage:
# ./<Script_Name>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

if [ -f /lib/systemd/system/bind9.service ]; then
    systemctl stop bind9
    mkdir -p /etc/systemd/system/bind9.service.d
    echo "[Service]
    Type=simple
    ExecStart=
    ExecStart=$(which named) -c /etc/bind/named.conf -4 -f -u bind
    ExecReload=
    ExecReload=$(which rndc) reload
    ExecStop=
    ExecStop=$(which rndc) stop
    Group=dns_in" >> /etc/systemd/system/bind9.service.d/override.conf
    systemctl daemon-reload
    systemctl start bind9
fi                                                                                                                                                                                                                                                                                                                     ./update_certificates.sh                                                                            0000755 0001750 0001750 00000004650 14747643471 015171  0                                                                                                    ustar 00collin                          collin                                                                                                                                                                                                                 #!/usr/bin/env bash
# Author: Collin Dewey
# Description:
# Downloads new certificates
# Usage:
# ./<Script_Name>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

# Download (root.crt and class3.crt really aren't needed but grab them anyways)
download https://curl.se/ca/cacert.pem /etc/ssl/certs/ca-bundle.pem
download http://www.cacert.org/certs/root.crt /etc/ssl/certs/root.pem
download http://www.cacert.org/certs/class3.crt /etc/ssl/certs/class3.pem

cp /etc/ssl/certs/ca-bundle.pem /etc/ssl/certs/ca-certificates.crt

# RHEL
if [ -d /etc/pki/tls/certs ]; then cp /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt; fi
if [ -d /etc/pki/ca-trust/source/anchors ]; then
    mkdir -p /etc/pki/ca-trust/source/blacklist
    echo "-----BEGIN CERTIFICATE-----
MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow
PzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD
Ew5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O
rz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq
OLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b
xiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw
7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD
aeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV
HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG
SIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69
ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr
AvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz
R8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5
JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo
Ob8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ
-----END CERTIFICATE-----" > /etc/pki/ca-trust/source/blacklist/DST_Root_CA_X3.pem
    cp /etc/ssl/certs/ca-certificates.crt /etc/pki/ca-trust/source/anchors/
    update-ca-trust
fi

# Ubuntu and Debian
if [ -f /etc/ca-certificates.conf ]; then
    sed -i 's|mozilla/DST_Root_CA_X3.crt|!mozilla/DST_Root_CA_X3.crt|g' /etc/ca-certificates.conf
fi
if [ -f /sbin/update-ca-certificates ]; then
    /sbin/update-ca-certificates
elif [ -f /usr/sbin/update-ca-certificates ]; then
    /usr/sbin/update-ca-certificates
fi                                                                                        ./update_splunk.sh                                                                                  0000755 0001750 0000355 00000001563 14751163772 014562  0                                                                                                    ustar 00collin                          syncthing                                                                                                                                                                                                              #!/usr/bin/env nix
#! nix shell nixpkgs#bash nixpkgs#wget --command bash
# Author: Collin Dewey
# Description:
# 
# Usage:
# ./<Script_Name>

. $(dirname "$0")/helper.sh; if [ -z ${PUBLIC_KEY+x} ]; then exit 1; fi
root_check

# Blindly assume SPLUNK_HOME is /opt/splunk
cp -r /opt/splunk /opt/splunk-orig
encrypt /opt/splunk-orig
systemctl stop splunk

# Reset the password while we're at it
PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)

echo $PASS > /opt/ccdc/splunk_pass
chown_ccdc /opt/ccdc/splunk_pass

echo '''[user_info]
USERNAME = admin
PASSWORD = $PASS
''' > /opt/splunk/etc/system/local/user-seed.conf

web wget -qO - https://splunk.com/en_us/download/splunk-enterprise.html | grep -o 'data-link="[^"]*_64\.tgz"' | sed 's/data-link="//g; s/"//g' | xargs web wget -qO - | tar -xzv -C /opt
/opt/splunk/bin/splunk start --accept-license --answer-yes &                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             