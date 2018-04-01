#!/bin/bash
prompt=$(echo $1 | sed s/_/__/g)
[ -z "$prompt" ] && prompt="Enter your password:"
ICON=/usr/share/pixmaps/gpa.png
zenity --entry --hide-text --text="$prompt" --title="ssh(1) Authentication"
