text
lang en_US.UTF-8
keyboard us
timezone US/Central
selinux --permissive
firewall --enabled --service=mdns
services --enabled=sshd,NetworkManager,chronyd
network --bootproto=dhcp --device=link --activate
rootpw --lock --iscrypted locked
reboot

bootloader --timeout=1

zerombr
clearpart --all --initlabel --disklabel=msdos

# make sure that initial-setup runs and lets us do all the configuration bits
firstboot --enable

# Include the appropriate repo definitions

# For non-master branches the following should be uncommented


ignoredisk --only-use=sda



%post

# Find the architecture we are on
arch=$(uname -m)

releasever=$(rpm --eval '%{fedora}')
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-primary
echo "Packages within this disk image"
rpm -qa --qf '%{size}\t%{name}-%{version}-%{release}.%{arch}\n' |sort -rn

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

# The enp1s0 interface is a left over from the imagefactory install, clean this up
rm -f /etc/NetworkManager/system-connections/*.nmconnection

dnf -y remove dracut-config-generic

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# Explicitly set graphical.target as default as this is how initial-setup detects which version to run
systemctl set-default graphical.target


echo -e "[Autologin]\nRelogin=true\nSession=plasmax11\nUser=garrett\n\n[General]\nHaltCommand=\nRebootCommand=\n\n[Theme]\nCurrent=01-breeze-fedora\n\n[Users]\nMaximumUid=60000\nMinimumUid=1000\n\n" > /etc/sddm.conf.d/kde_settings.conf

#echo -e "/dev/disk/by-uuid/01DAA737153362E0 /mnt/sdb1 auto nosuid,nodev,nofail,x-gvfs-show 0 0\n/dev/disk/by-uuid/01D74E861C2A08E0 /mnt/sdc1 auto nosuid,nodev,nofail,x-gvfs-show 0 0\n" >> /etc/fstab

dnf copr enable zeno/scrcpy && dnf install scrcpy
%end


%packages
# install env-group to resolve RhBug:1891500
@^kde-desktop-environment
kernel
rEFInd
# remove this in %post
dracut-config-generic
-dracut-config-rescue

# make sure all the locales are available for inital-setup and anaconda to work
glibc-all-langpacks
@firefox
android-tools
plasma-workspace-x11
thunderbird
gnome-disk-utility
@kde-apps
-neochat
-kmouth
alsa-firmware
@kde-media
-ktnef
-korganizer
-kmail
-pim-data-exporter-libs
-pim-data-exporter

# Ensure we have Anaconda initial setup using kwin
@kde-spin-initial-setup
@libreoffice
# add libreoffice-draw and libreoffice-math (pagureio:fedora-kde/SIG#103)
libreoffice-draw
libreoffice-math
glibc-all-langpacks
dnfdragora
fedora-release-kde

-@admin-tools

# drop tracker stuff pulled in by gtk3 (pagureio:fedora-kde/SIG#124)
-tracker-miners
-tracker

# Not needed on desktops. See: https://pagure.io/fedora-kde/SIG/issue/566
-mariadb-server-utils

### The KDE-Desktop

# fedora-specific packages
plasma-welcome-fedora

### fixes

# minimal localization support - allows installing the kde-l10n-* packages
kde-l10n

# Additional packages that are not default in kde-* groups, but useful
fuse
mediawriter

### space issues
-ktorrent			# kget has also basic torrent features (~3 megs)
-digikam			# digikam has duplicate functionality with gwenview (~28 megs)
-kipi-plugins			# ~8 megs + drags in Marble
-krusader			# ~4 megs
-k3b				# ~15 megs

## avoid serious bugs by omitting broken stuff

%end


part /boot/efi --size=513 --fstype="efi" --ondisk=sda --fsoptions="umask=0077"
part btrfs.01 --fstype="btrfs" --ondisk=sda --size=446000
part swap --fstype="swap" --ondisk=sda --grow
btrfs / btrfs.01

# Create User Account
user --name=garrett --password=a --plaintext --groups=wheel
