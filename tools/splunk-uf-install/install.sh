#!/bin/bash

## Figure out from where we were called from
BASE_DIR="$(dirname $(readlink -fn $0))"

. "$BASE_DIR/vars.conf"

if [ -z "$SPLUNK_PASSWORD" ]; then
    echo "You must set a SPLUNK_PASSWORD in vars.conf"
    exit 1
fi

##  Import logging function
. "$BASE_DIR/log.sh"

SPLUNK_INSTALL_FILE="$BASE_DIR/$SPLUNK_INSTALL_TGZ"
SPLUNK_GROUP="$SPLUNK_USER"
SPLUNK_HOME="$SPLUNK_BASE_DIR/splunkforwarder"
SPLUNK_CMD="$SPLUNK_HOME/bin/splunk"
SPLUNK_USER_SEED_FILE="$SPLUNK_HOME/etc/system/local/user-seed.conf"
SPLUNK_INITD_FILE="/etc/init.d/splunk"
SPLUNK_SYSTEMD_FILE="/etc/systemd/system/splunkd.service"
SPLUNK_SYSTEMD_SYMLINK_FILES="/etc/systemd/system/multi-user.target.wants/splunkd.service"
HAS_SYSTEMD="$(which systemctl 2>/dev/null)"

## CLEANUP PREVIOUS
log_write stdout "Cleaning up any previous installation attempts"
if [ -e "$SPLUNK_INITD_FILE" ]; then
    $(which service) splunk stop
else
    if [ -e $SPLUNK_SYSTEMD_FILE ]; then
        $(which systemctl) stop splunkd
    fi
fi

if [ ! -z "$SPLUNK_ALLOWED_PATHS" ]; then
    setfacl -R -x u:$SPLUNK_USER $SPLUNK_ALLOWED_PATHS &>/dev/null
fi

userdel $SPLUNK_USER &>/dev/null
rm -rf "$SPLUNK_HOME" &>/dev/null
find /etc/rc.d -type l -iregex .*splunk.* -delete
rm -f $SPLUNK_INITD_FILE $SPLUNK_SYSTEMD_FILE $SPLUNK_SYSTEMD_SYMLINK_FILES
echo

if [ "$1" == "--remove-only" ]; then
    exit
fi

log_write stdout "Starting Splunk installation"

## Create system user "splunk" with no login shell
## This also creates a "splunk" group
log_write stdout "Adding splunk user and group"
$(which useradd) -Ur -s /bin/bash -d $SPLUNK_BASE_DIR/splunkforwarder $SPLUNK_USER &>/dev/null

## Install Splunk forwarder
log_write stdout "Installing Splunk to $SPLUNK_BASE_DIR"
tar -C $SPLUNK_BASE_DIR --checkpoint=90 --checkpoint-action=dot -zxf $SPLUNK_INSTALL_FILE
echo

echo "SPLUNK_HOME = $SPLUNK_HOME" >>$SPLUNK_HOME/etc/splunk-launch.conf
echo -e "[user_info]\nUSERNAME = $SPLUNK_USER\nPASSWORD = $SPLUNK_PASSWORD" >$SPLUNK_USER_SEED_FILE

## Install default apps
log_write stdout "Installing default Splunk apps"
tar -C $SPLUNK_HOME/etc/apps -zxf $BASE_DIR/deployment_client.tar.gz

## Set permissions
log_write stdout "Changing $SPLUNK_HOME owner to $SPLUNK_USER:$SPLUNK_GROUP"
chown -R $SPLUNK_USER:$SPLUNK_GROUP $SPLUNK_HOME

if [ ! -z "$SPLUNK_ALLOWED_PATHS" ]; then
    log_write stdout "Allowing $SPLUNK_USER to read $SPLUNK_ALLOWED_PATHS"
    $(which setfacl) -R -m u:${SPLUNK_USER}:rx $SPLUNK_ALLOWED_PATHS
fi

## Enable Splunk to start on boot
log_write stdout "Setting Splunk to start on boot"

if [ -z "$HAS_SYSTEMD" ]; then
    $SPLUNK_CMD enable boot-start -user $SPLUNK_USER --accept-license
else
    $SPLUNK_CMD enable boot-start -systemd-managed 1 -user $SPLUNK_USER --accept-license
fi

## Start up Splunk
if [ -e "$SPLUNK_INITD_FILE" ]; then
    $(which service) splunk start
else
    $(which systemctl) start splunkd
fi

INPUTS_CONF_HOST="$(cat $SPLUNK_HOME/etc/system/local/inputs.conf | grep 'host *= *' | sed 's/^ *host *= *//')"
echo
log_write stdout "Check host in Splunk: $INPUTS_CONF_HOST"

