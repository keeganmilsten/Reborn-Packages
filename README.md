# Reborn Repository Packages
![Reborn_Repository](/reborn-repo.png)
# Manually Build Reborn-Packages (for Reborn OS Team) 

1. git clone the repository.
```
git clone https://github.com/keeganmilsten/Reborn-Packages
```

2. Build the packages by entering into each package's folder and running `makepkg`, unless instructed by the README.md file of that folder not to do so.

3.Once all of the packages have been built, run the following command to update the repository as a whole:
```
sudo repo-add /home/$USER/Dropbox/Linux/RebornOS-Repo/Reborn-OS.db.tar.xz /home/$USER/Dropbox/Linux/RebornOS-Repo/*.pkg.tar.xz

check-repo.sh
```
4. Done!

5. Afterwards, to remove packages that you have deleted from the repo,simply use this command:
```
repo-remove /home/$USER/Dropbox/Linux/RebornOS-Repo/Reborn-OS.db.tar.xz {PACKAGE_NAME}
```

# Add The Repository to Your System (for users)
1. Enter pacman.conf
```
sudo nano /etc/pacman.conf
```

2. Edit the file. At the very end of it, just add the following lines:
```
[Reborn-OS]
SigLevel = Never
Server = https://repo.itmettke.de/Reborn-OS/
Server = https://github.com/keeganmilsten/Reborn-Packages/releases/download/1.0/
```

3. Press `CTRL X`, then `y`, and lastly `ENTER` to save the file.

4. Refresh your databases
```
sudo pacman -Syy
```

5. Done!
