# Manually Build Reborn-Packages

1. git clone the repository.
```
git clone https://github.com/keeganmilsten/Reborn-Packages
```

2. Build the packages by entering into each package's folder and running `makepkg`, unless instructed be the README.md file of that folder not to do so.

3.Once all of the packages have been built, run the following command to update the repositor as a whole:
```
sudo repo-add /home/$USER/Dropbox/Linux/RebornOS-Repo/Reborn-OS.db.tar.xz /home/$USER/Dropbox/Linux/RebornOS-Repo/*.pkg.tar.xz
```
4. Done!

### If you do not have teh repo in  pacman.conf, follow these steps

1. Enter pacman.conf
```
sudo nano /etc/pacman.conf
```

2. Edit the file. At the very end of it, just add the following lines:
```
[Reborn-OS]
SigLevel = Never
Server = https://sourceforge.net/projects/antergos-deepin/files/
```

3. Press `CTRL X`, then `y`, and lastly `ENTER` to save the file.

4. Refresh your databases
```
sudo pacman -Syy
```

5. Done!
