#!/bin/bash

## Base directory where Splunk is installed
SPLUNK_HOME="/opt/splunk"
## Base directory for Splunk app source
APP_SRC_DIR=""
## Base directory in SPLUNK_HOME/etc/apps where the app is located
APP_DST_DIR=""
## Whether to run app-inspect or not
RUN_APP_INSPECT="0"
## User to chown APP_DST_DIR to
SPLUNK_USR="splunk"
## Group to chown APP_DST_DIR to
SPLUNK_GRP="splunk"

getopt -T > /dev/null
if [[ $? -ne 4 ]]; then
    echo "Required getopt (enhanced) not found"
    exit 1
fi

OPTIONS=
LONGOPTIONS=app-src-dir:,splunk-home:,app-inspect:,splunk-user:,splunk-group:

PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")
if [[ $? -ne 0 ]]; then
    exit 2
fi
eval set -- "$PARSED"

while true; do
    case "$1" in
        --app-src-dir)
            APP_SRC_DIR="$2"
            shift 2
            ;;
        --splunk-home)
            SPLUNK_HOME="$2"
            shift 2
            ;;
        --app-inspect)
            RUN_APP_INSPECT="$2"
            shift 2
            ;;
        --splunk-user)
            SPLUNK_USR="$2"
            shift 2
            ;;
        --splunk-group)
            SPLUNK_GRP="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

## Colors escapes
RED="\033[41;30m"
CLR="\033[0m"
echo

## Check user and group exists
if ! grep "^${SPLUNK_USR}:" /etc/passwd &>/dev/null; then
    echo -e "${RED}FAILED${CLR}: $SPLUNK_USR user doesn't exist\n"
    exit 1
fi

if ! grep "^${SPLUNK_GRP}:" /etc/group &>/dev/null; then
    echo -e "${RED}FAILED${CLR}: $SPLUNK_GRP group doesn't exist\n"
    exit 1
fi

## Check for SPLUNK_HOME
[ ! -d "$SPLUNK_HOME" ] && echo -e "${RED}FAILED${CLR}: $SPLUNK_HOME is not a directory or doesn't exist\n" && exit 1

## Splunk directories
SPLUNK_ETC="$SPLUNK_HOME/etc"
SPLUNK_APPS="$SPLUNK_ETC/apps"

## Check the SPLUNK_HOME directory for etc/apps
[ ! -d "$SPLUNK_APPS" ] && echo -e "${RED}FAILED${CLR}: $SPLUNK_HOME is not a valid SPLUNK_HOME directory\n" && exit 1

## Check Splunk app source directory
[ -z "$APP_SRC_DIR" ] && echo -e "${RED}REQUIRED${CLR}: --app-src-dir=SPLUNK_APP_SRC_DIR\n" && exit 1

## Source directory without app name
APP_SRC_ROOT_DIR="$(dirname $APP_SRC_DIR)"

## Set directory to install app in SPLUNK_HOME
APP_DIR="$(basename $APP_SRC_DIR)"
APP_DST_DIR="$SPLUNK_APPS/$APP_DIR"

## Change owner to root on all files and directories
echo "Setting ownership to 'root:root' for all files and directories"
chown -R 0.0 "$APP_SRC_DIR"

## Change permissions on files and directories
echo "Changing file perms to 0600 and directory perms to 0700"
find "$APP_SRC_DIR" -type f -exec chmod 600 {} \;
find "$APP_SRC_DIR" -type d -exec chmod 700 {} \;

## Remove all .pyc and .pyo files
find "$APP_SRC_DIR" -type f -name *.pyc -delete
find "$APP_SRC_DIR" -type f -name *.pyo -delete
find "$APP_SRC_DIR" -type d -name __pycache__ -delete

## Validate app
echo "Validating app with SLIM"
SLIM="$(which slim)"
$SLIM validate $APP_SRC_DIR &> /dev/null

if [ $? == 1 ]; then
    echo -e "${RED}FAIL${CLR}: $APP_SRC_DIR app.manifest did not validate\n"
    exit 1
fi

## Package app
echo "Packaging app"
## Use slim so we can get the tarball name
SLIM_PACKAGE="$($SLIM package $APP_SRC_DIR 2>&1 | grep "exported to" | sed 's/^.*exported to \"\(.*\)\"/\1/')"
APP_TARBALL="$(basename $SLIM_PACKAGE)"
rm -f $APP_TARBALL
## Use tar for final packaging since slim has no way to exclude specific files
tar -zcf $APP_TARBALL --exclude=.git* --exclude=.slimignore --exclude=test.sh -C $APP_SRC_ROOT_DIR $APP_DIR

if [ $RUN_APP_INSPECT == "1" ]; then
    echo "Running app-inspect"
    APP_INSPECT="$(which splunk-appinspect)"
    $APP_INSPECT inspect $SLIM_PACKAGE --mode precert
fi

## Safety precaution checks
if [ "$APP_DST_DIR" != "$SPLUNK_APPS" -a "$(dirname "$APP_DST_DIR")" == "$SPLUNK_APPS" ]; then
    ## Install package to Splunk apps directory
    echo "Installing $APP_TARBALL to $APP_DST_DIR"
    rm -rf $APP_DST_DIR
    tar -C $SPLUNK_APPS -zxf $SLIM_PACKAGE

    echo "Changing owner to '${SPLUNK_USR}:${SPLUNK_GRP}' for $APP_DST_DIR"
    chown -R ${SPLUNK_USR}:${SPLUNK_GRP} $APP_DST_DIR

    echo
fi

