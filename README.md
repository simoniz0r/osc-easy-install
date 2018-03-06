# osc-easy-install

osc-easy-install is a simple script that uses `zenity` to provide a GUI frontend to search for packages using the `osc` package on openSUSE.  The goal is to provide similar functionality as the "1 Click Install" from https://software.opensuse.org/search without needing to rely on using that website.

osc-easy-install should provide the same search results as the openSUSE Software site.  The `osc` package is used to get information about available packages from the openSUSE Build Service.  Getting search results using `osc` is usually a little faster than loading up the Software site.

# Dependencies

The dependencies for osc-easy-install are pretty light.  Most things required should be present on a normal openSUSE install.

Dependencies:

```
osc, zenity (or qarma, a zenity replacement), ssh-askpass, xterm, zypper, rpm
```

# Installation/Removal

To install osc-easy-install, just clone this repo and run `make install` as shown below:

```
git clone https://github.com/simoniz0r/osc-easy-install.git
cd ./osc-easy-install
sudo make install
```

To uninstall osc-easy-install, just `cd` back into the directory where you cloned the Github repo to and run the following:

```
sudo make uninstall
```

# Using osc-easy-install

### Before running osc-easy-install please make sure to run the `osc` command in a terminal and login.  osc-easy-install currently does not detect whether or not the user has logged in to `osc`, so please make sure to do this before running osc-easy-install.

After installation, either launch osc-easy-install from your menu or run `osc-easy-install` from your terminal/launcher.  Usage should be pretty straight forward.  The first screen that shows ask for a package to search for and allows for the openSUSE release to be selected.  A search can also be ran for packages on any distribution, but it will probably not work to add repositories to zypper's list that do not match the current release.

![screenshot](/screenshots/screenshot1.png)

After entering a package to search for, osc-easy-install uses `osc` to search for packages and a couple of `grep`s to make sure we get packages matching the chosen release and the user's current achitecture.  Results are outputted in Project/Release/Package format to a list which allows the user to select which project repository to add to zypper's list and which package version to install.

![screenshot2](/screenshots/screenshot2.png)

After a Project/Release/Package selection is made, a prompt is shown to confirm the selection.  If the selected package version is already installed, the user will be shown an error telling them to first uninstall that package before attempting to install it with osc-easy-install.  If the selected repository is not in zypper's repo list, it will be added.

![screenshot3](/screenshots/screenshot3.png)

If the user choses to install the selected package, `xterm` is opened (hopefully somewhere near the center of the screen), the `sudo zypper addrepo` is ran if the repository isn't already present in zypper's list, `sudo zypper refresh` is ran to make sure the repo lists are up to date, and `sudo zypper install package-version` is ran to ensure that the selected package version is installed.

![screenshot4](/screenshots/screenshot4.png)

After `xterm` closes, osc-easy-install runs `rpm -qa | grep 'package-version'` to make sure the install was successful.  The user is told whether the package installed successfully and is then asked whether or not they would like to keep the repository used for installing the package in zypper's list.  If no is chosen, `ssh-askpass` will be used along with `SUDO_ASKPASS="$(which ssh-askpass)" sudo -A zypper rr repo_alias` to remove the repository from zypper's list.

![screenshot5](/screenshots/screenshot5.png)

# Troubleshooting Problems

If there is an issue with osc-easy-install, debug mode can be enabled by running `osc-easy-install --debug` in a terminal.  This enables `set -x` and `set -v` which will output each command as it is ran and the result of each command.  If this information does not help solve the problem, feel free to post [an issue here](https://github.com/simoniz0r/osc-easy-install/issues/new) containing the output of `osc-easy-install --debug`.
