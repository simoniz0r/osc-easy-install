#!/bin/bash
# Title: osc-easy-install
# Author: simonizor
# License: MIT
# Description: A simple script that finds packages on the openSUSE Build Service based on user input
# Dependencies: osc, zenity or qarma, xterm, zypper, rpm

RUNNING_LOC="$(readlink -f $0)"
RUNNING_DIR="$(dirname $RUNNING_LOC)"

for arg in $@; do
    case $arg in
        --debug)
            set -x
            shift
            ;;
    esac
done

# Check for necessary dependencies
# Also check whether qarma is installed because behavior is a little different than zenity
if type qarma >/dev/null 2>&1; then
    NEW_LINE="<br>"
    ICON_NAME="/usr/share/icons/oxygen/48x48/apps/suse.png"
elif type zenity >/dev/null 2>&1; then
    NEW_LINE="\n"
    ICON_NAME="suse"
else
    MISSING_DEPS="TRUE"
    echo "qarma or zenity not installed!"
fi
if ! type osc >/dev/null 2>&1; then
    MISSING_DEPS="TRUE"
    echo "osc not installed!"
fi
if ! type xterm >/dev/null 2>&1; then
    MISSING_DEPS="TRUE"
    echo "xterm not installed!"
fi
if ! type zypper >/dev/null 2>&1; then
    MISSING_DEPS="TRUE"
    echo "zypper not installed; why are you using this script lol ?!"
fi
if [ "$MISSING_DEPS" = "TRUE" ]; then
    echo "Missing one or more dependencies required to run; exiting..."
    exit 1
fi

# TODO set this as default entry without duplicates
# Get openSUSE version using /etc/os-release as default selection
# Use tr to replace spaces with underscores as used in OBS URLs
# . /etc/os-release
# case $NAME in
#     *Tumbleweed*)
#         SUSE_RELEASE="$(echo "$NAME" | tr '[:blank:]' '_')"
#         ;;
#     *)
#         SUSE_RELEASE="$(echo "$NAME" | tr '[:blank:]' '_')_$VERSION"
#         ;;
# esac

# Use zenity or qarma to provide a GUI for inputting Package and Release
if type wmctrl >/dev/null 2>&1; then
    (sleep 1 && wmctrl -F -a "osc-easy-install" -b add,above) &
fi
SEARCH_INPUT="$(zenity --forms --separator="," --title="osc-easy-install" --text="Find and install packages from the openSUSE Build Service$(echo $NEW_LINE)" \
--window-icon="$ICON_NAME" --ok-label="Search" --add-entry="Package:" --add-combo="Release:" \
--combo-values="openSUSE_Tumbleweed|openSUSE_Factory|openSUSE_Leap_15.0|openSUSE_Leap_42.3|All")"
# Exit on cancel
case $? in
    1)
        exit 0
        ;;
esac
# Set variables using separator set above and cut
PACKAGE_NAME="$(echo $SEARCH_INPUT | cut -f1 -d',')"
# Set default SUSE_RELEASE in case user doesn't select it when using zenity
if [ ! -z "$(echo $SEARCH_INPUT | cut -f2 -d',')" ]; then
    SUSE_RELEASE="$(echo $SEARCH_INPUT | cut -f2 -d',')"
fi
if [ "$SUSE_RELEASE" = "All" ]; then
    unset SUSE_RELEASE
fi

# Use osc to search for package based on user input
# Popup to let user know we're doing things and not just dead
if type wmctrl >/dev/null 2>&1; then
    (sleep 1 && wmctrl -F -a "osc-easy-install" -b add,above) &
fi
zenity --info --title="osc-easy-install" --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" --ok-label="" \
--text="Searching openSUSE Build Service$(echo $NEW_LINE)Package: <b>$PACKAGE_NAME</b>$(echo $NEW_LINE)Release: <b>$SUSE_RELEASE</b>$(echo $NEW_LINE)This may take a moment..." &
PID_OF_SEARCHBOX="$!"
rm -f /tmp/zenobshresults
# Run a for loop on osc se to put projects and packages in correct order and eliminate duplicate projects
touch /tmp/zenobshresults
osc se -s --csv --binary "$PACKAGE_NAME" | grep "$SUSE_RELEASE" | grep "$(uname -m)\|noarch" | grep -v 'src.rpm' > /tmp/zenobshsearch 2>&1
for search_result in $(cat /tmp/zenobshsearch); do
    PROJECT_NAME="$(echo $search_result | cut -f1 -d'|')"
    BINARY_VERSION="$(echo $search_result | cut -f3 -d'|' | rev | cut -f1 -d'/' | rev)"
    RELEASE_REPO="$(echo $search_result | cut -f3 -d'|' | rev | cut -f3 -d'/' | rev)"
    if [[ "$PROJECT_NAME" =~ "rpm" ]]; then
        PROJECT_NAME="$(echo $search_result | cut -f2 -d'|')"
        BINARY_VERSION="$(echo $search_result | cut -f1 -d'|' | rev | cut -f1 -d'/' | rev)"
        RELEASE_REPO="$(echo $search_result | cut -f1 -d'|' | rev | cut -f3 -d'/' | rev)"
    fi
    if [[ ! "$BINARY_VERSION" =~ ".rpm" ]]; then
        PROJECT_NAME="$(echo $search_result | cut -f3 -d'|')"
        BINARY_VERSION="$(echo $search_result | cut -f2 -d'|' | rev | cut -f1 -d'/' | rev)"
        RELEASE_REPO="$(echo $search_result | cut -f2 -d'|' | rev | cut -f3 -d'/' | rev)"
    fi
    BINARY_VERSION="$(echo $BINARY_VERSION | sed 's%.rpm%%g' | rev | cut -f2- -d'-' | rev)"
    echo "$PROJECT_NAME/$RELEASE_REPO/$BINARY_VERSION" >> /tmp/zenobshresults
done
if [ $(cat /tmp/zenobshresults | wc -l) -eq 0 ]; then
    rm -f /tmp/zenobshresults
else
    echo # -e "$(cat /tmp/zenobshresults | tr '\n' ' ')\n" > /tmp/zenobshresults
fi
rm -f /tmp/zenobshsearch
# Kill popup box
kill -SIGTERM -f $PID_OF_SEARCHBOX
# If no search results, error
if [ ! -f "/tmp/zenobshresults" ]; then
    if type wmctrl >/dev/null 2>&1; then
        (sleep 1 && wmctrl -F -a "osc-easy-install" -b add,above) &
    fi
    zenity --error --icon-name="$ICON_NAME" --title="osc-easy-install" --text="<b>$PACKAGE_NAME</b> not found!"
    "$RUNNING_LOC"
    exit 0
# Else allow user to select Project name from list of valid results
else
    if type wmctrl >/dev/null 2>&1; then
        (sleep 1 && wmctrl -F -a "osc-easy-install" -b add,above) &
    fi
    PROJECT_NAME="$(zenity --list --width=800 --height=600 --separator="," --title="osc-easy-install" --text="openSUSE Build Service search results for <b>$PACKAGE_NAME</b>.$(echo $NEW_LINE)\
    Select a Project/Release/Package to add to zyper's repo list and install:" \
    --window-icon="$ICON_NAME" --column="Project/Release/Package" $(cat /tmp/zenobshresults))"
    if [ -z "$PROJECT_NAME" ]; then
        rm -f /tmp/zenobshresults
        "$RUNNING_LOC"
        exit 0
    fi
    # echo "$(cat /tmp/zenobshresults | sed 's%/ %/%g;s% %\n%g')" > /tmp/zenobshresults
    # BINARY_VERSION="$(grep -wm1 "^$PROJECT_NAME" /tmp/zenobshresults | cut -f2 -d'/')"
    BINARY_VERSION="$(echo $PROJECT_NAME | cut -f3 -d'/')"
    SUSE_RELEASE="$(echo $PROJECT_NAME | cut -f2 -d'/')"
    PROJECT_NAME="$(echo $PROJECT_NAME | cut -f1 -d'/')"
    REPO_URL="http://download.opensuse.org/repositories/$(echo ${PROJECT_NAME} | sed 's%:%:/%g')/${SUSE_RELEASE}/"
    rm -f /tmp/zenobshresults
fi
# Check if repo already is in zypper's list
if rpm -qa | grep -qm1 "$BINARY_VERSION"; then
    zenity --error --title="osc-easy-install" --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" --text="<b>$BINARY_VERSION</b> is already installed!$(echo $NEW_LINE)Please remove <b>$BINARY_VERSION</b> before attempting to install it!"
    "$RUNNING_LOC"
    exit 0
fi
if ! zypper lr -U | grep -qm1 "$REPO_URL"; then
    if type wmctrl >/dev/null 2>&1; then
        (sleep 1 && wmctrl -F -a "osc-easy-install" -b add,above) &
    fi
    zenity --question --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" --title="osc-easy-install" --text="<b>$REPO_URL</b> will be added to zypper's list of repos!$(echo $NEW_LINE)<b>$BINARY_VERSION</b> will be installed!$(echo $NEW_LINE)Continue?"
else
    if type wmctrl >/dev/null 2>&1; then
        (sleep 1 && wmctrl -F -a "osc-easy-install" -b add,above) &
    fi
    zenity --question --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" --title="osc-easy-install" --text="<b>$REPO_URL</b> is already in zypper's list of repos.$(echo $NEW_LINE)<b>$BINARY_VERSION</b> will be installed!$(echo $NEW_LINE)Continue?"
fi
# Exit if cancel
case $? in
    1)
        "$RUNNING_LOC"
        exit 0
        ;;
    0)
        # Check if repo already is in zypper's list and launch xterm to add repo if not in list, refresh list, and install Package
        CURRENT_WIDTH=$(xrandr --current | head -n 1 | cut -f2 -d',' | cut -f-1 -d'x' | cut -f3 -d' ')
        CURRENT_HEIGHT=$(xrandr --current | head -n 1 | cut -f2 -d',' | cut -f2 -d'x' | cut -f2 -d' ')
        HALF_WIDTH=$(echo $CURRENT_WIDTH | awk '{print $1 * .40}')
        HALF_HEIGHT=$(echo $CURRENT_HEIGHT | awk '{print $1 * .40}')
        if ! zypper lr -U | grep -qm1 "$REPO_URL"; then
            xterm -geometry 90x30+${HALF_WIDTH}+${HALF_HEIGHT} -e "sudo zypper addrepo -f https://download.opensuse.org/repositories/${PROJECT_NAME}/${SUSE_RELEASE}/${PROJECT_NAME}.repo && sudo zypper refresh && sudo zypper install $BINARY_VERSION"
        else
            xterm -geometry 90x30+${HALF_WIDTH}+${HALF_HEIGHT} -e "sudo zypper refresh && sudo zypper install $BINARY_VERSION"
        fi
        # Check if Package was installed using rpm -qa and grep
        if rpm -qa | grep -qm1 "$BINARY_VERSION"; then
            if type wmctrl >/dev/null 2>&1; then
                (sleep 1 && wmctrl -F -a "osc-easy-install" -b add,above) &
            fi
            REPO_ALIAS="$(zypper -x lr | grep -m1 -A1 "$REPO_URL" | head -n 1 | cut -f2 -d'"')"
            if [ -z "$REPO_ALIAS" ]; then
                zenity --error --title="osc-easy-install" --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" --text="Failed to add <b>$REPO_URL</b> and install <b>$BINARY_VERSION</b>!"
                "$RUNNING_LOC"
                exit 0
            fi
            zenity --question --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" \
            --title="osc-easy-install" --text="<b>$BINARY_VERSION</b> has been installed!$(echo $NEW_LINE)\
            Repo URL: <b>$REPO_URL</b>$(echo $NEW_LINE)Repo Alias: <b>$REPO_ALIAS</b>$(echo $NEW_LINE)\
            Would you like to keep <b>$REPO_ALIAS</b> in zypper's list?"
            case $? in
                0)
                    zenity --info --title="osc-easy-install" --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" --text="<b>$REPO_URL</b> will remain in zypper's list."
                    "$RUNNING_LOC"
                    exit 0
                    ;;
                1)
                    SUDO_ASKPASS="$RUNNING_DIR/osc-easy-install-askpass" sudo -A zypper rr "$REPO_ALIAS" || { zenity --error --title="osc-easy-install" --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" --text="<b>$REPO_URL</b> was not removed."; "$RUNNING_LOC"; exit 0; }
                    zenity --info --title="osc-easy-install" --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" --text="<b>$REPO_URL</b> was removed!"
                    "$RUNNING_LOC"
                    exit 0
                    ;;
            esac
        else
            if type wmctrl >/dev/null 2>&1; then
                (sleep 1 && wmctrl -F -a "osc-easy-install" -b add,above) &
            fi
            REPO_ALIAS="$(zypper -x lr | grep -m1 -A1 "$REPO_URL" | head -n 1 | cut -f2 -d'"')"
            if [ -z "$REPO_ALIAS" ]; then
                zenity --error --title="osc-easy-install" --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" --text="Failed to add <b>$REPO_URL</b> and install <b>$BINARY_VERSION</b>!"
                "$RUNNING_LOC"
                exit 0
            fi
            zenity --question --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" \
            --title="osc-easy-install" --text="Failed to install <b>$BINARY_VERSION</b>!$(echo $NEW_LINE)\
            Repo URL: <b>$REPO_URL</b>$(echo $NEW_LINE)Repo Alias: <b>$REPO_ALIAS</b>$(echo $NEW_LINE)\
            Would you like to keep <b>$REPO_ALIAS</b> in zypper's list?"
            case $? in
                0)
                    zenity --info --title="osc-easy-install" --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" --text="<b>$REPO_URL</b> will remain in zypper's list."
                    "$RUNNING_LOC"
                    exit 0
                    ;;
                1)
                    SUDO_ASKPASS="$RUNNING_DIR/osc-easy-install-askpass" sudo -A zypper rr "$REPO_ALIAS" || { zenity --error --title="osc-easy-install" --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" --text="<b>$REPO_URL</b> was not removed."; "$RUNNING_LOC"; exit 0; }
                    zenity --info --title="osc-easy-install" --window-icon="$ICON_NAME" --icon-name="$ICON_NAME" --text="<b>$REPO_URL</b> was removed!"
                    "$RUNNING_LOC"
                    exit 0
                    ;;
            esac
        fi
        ;;
esac
exit 0
