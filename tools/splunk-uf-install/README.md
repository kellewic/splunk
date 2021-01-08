## BIG WARNING

Do not use this script to upgrade Splunk as the first thing it does is delete the previous version by removing the entire Splunk main directory.


## USAGE

There is not much configuration for this to work. The install.sh script takes care of everything needed to install Splunk.

*vars.conf* is the only file you need to edit before install.sh will work.

REQUIRED:
* Set SPLUNK_PASSWORD variable to the password you want to use for Splunk

OPTIONAL:
* If you have files or directories you want Splunk to monitor and don't want to, or can't, give permission to the splunk user or group, then set SPLUNK_ALLOWED_PATHS to a space separated lists of these files and directories. The install script will setfacl on them to allow the splunk user to read the files. No write permissions are given.

DEFAULTS (should not be changed under most circumstances):
* SPLUNK_USER defaults to "splunk". If this user/group does not exist, install.sh creaters it as a system user with no login capability.
* SPLUNK_INSTALL_TGZ defaults to whatever version is packaged with this installer.
* SPLUNK_BASE_DIR defaults to "/opt"


Once the above are configured, run install.sh using either sudo or as the root user.

If something goes wrong during the install, there is an option "--remove-only" that will back out all changes performed by install.sh script. If this option is not specified and install.sh is run again, it will do the backout of changes, but also re-install Splunk which would likely just end up with the same errors.
