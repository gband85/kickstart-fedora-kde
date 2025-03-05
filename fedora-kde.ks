graphical
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
clearpart --all --initlabel

part /boot/efi --size=513 --fstype="efi" --ondisk=sda --fsoptions="umask=0077"
part btrfs.01 --fstype="btrfs" --ondisk=sda --size=30000
part swap --fstype="swap" --ondisk=sda --grow
btrfs / btrfs.01

# make sure that initial-setup runs and lets us do all the configuration bits
firstboot --enable

# Include the appropriate repo definitions
url --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-41&arch=x86_64"
repo --name=copr:copr.fedorainfracloud.org:zeno:scrcpy --baseurl=https://download.copr.fedorainfracloud.org/results/zeno/scrcpy/fedora-41-x86_64 --install
repo --name=fedora-cisco-openh264 --metalink="https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-41&arch=x86_64"
repo --name=fedora-updates --metalink="https://mirrors.fedoraproject.org/metalink?repo=updates-released-f41&arch=x86_64"
repo --name=google-chrome --baseurl="https://dl.google.com/linux/chrome/rpm/stable/x86_64" --install
repo --name=MEGAsync --baseurl=https://mega.nz/linux/repo/Fedora_41/ --install
repo --name=rpmfusion-free --metalink="https://mirrors.rpmfusion.org/metalink?repo=free-fedora-41&arch=x86_64" --install
repo --name=rpmfusion-free-updates --metalink="https://mirrors.rpmfusion.org/metalink?repo=free-fedora-updates-released-41&arch=x86_64" --install
repo --name=rpmfusion-nonfree --metalink="https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-41&arch=x86_64" --install
repo --name=rpmfusion-nonfree-updates --metalink="https://mirrors.rpmfusion.org/metalink?repo=nonfree-fedora-updates-released-41&arch=x86_64" --install

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

refind-install

echo -e "[Autologin]\nRelogin=true\nSession=plasmax11\nUser=garrett\n\n[General]\nHaltCommand=\nRebootCommand=\n\n[Theme]\nCurrent=01-breeze-fedora\n\n[Users]\nMaximumUid=60000\nMinimumUid=1000\n\n" > /etc/sddm.conf.d/kde_settings.conf

#echo -e "/dev/disk/by-uuid/01DAA737153362E0 /mnt/sdb1 auto nosuid,nodev,nofail,x-gvfs-show 0 0\n/dev/disk/by-uuid/01D74E861C2A08E0 /mnt/sdc1 auto nosuid,nodev,nofail,x-gvfs-show 0 0\n" >> /etc/fstab

wget -P /home/garrett/Downloads https://talonvoice.com/update/qyO6k0Y0jHOeI94q51eTKV/talon-linux-115-0.4.0-650-ga789.tar.xz
tar -xf /home/garrett/Downloads/talon-linux-115-0.4.0-555-g7f5f.tar.xz -C /home/garrett
wget -P /home/garrett/Downloads --content-disposition --trust-server-names https://linphone.org/releases/linux/latest_app
read filename < <(curl -L  --head https://linphone.org/releases/linux/latest_app 2>/dev/null | grep Location: | tail -n1 | cut -d' ' -f2 | grep -o Linph*)
chmod +x /home/garrett/Downloads/$filename
mkdir -p /home/garrett/.megaCmd/
touch /home/garrett/.megaCmd/.megaignore.default
mega-login gband85@mailfence.com iNaoYM8L3Mc-
mega-get settings_backup/.config /home/garrett
mega-get settings_backup/.thunderbird /home/garrett
mega-get settings_backup/.local /home/garrett/
mega-get settings_backup/.android /home/garrett/
mega-get settings_backup/.jocala /home/garrett/
mkdir -p /home/garrett/.talon/user
git clone https://github.com/gband85/community.git /home/garrett/.talon/user/community
chown -R garrett:garrett /home/garrett
%end


%packages
# install env-group to resolve RhBug:1891500
@^kde-desktop-environment
-@desktop-accessibility
-@dial-up
-@guest-desktop-agents
-@hardware-support
-@input-methods

-@kde-apps
-@kde-media
-@kde-pim

krdc
lpf-spotify-client
okular
gwenview
kernel
rEFInd
scrcpy
pcre2.i686
# remove this in %post
dracut-config-generic

# make sure all the locales are available for inital-setup and anaconda to work
glibc-all-langpacks
android-tools
plasma-workspace-x11
thunderbird
gnome-disk-utility
alsa-firmware
@vlc
steam
# Ensure we have Anaconda initial setup using kwin
@kde-spin-initial-setup
dnfdragora
fedora-release-kde
git
megacmd

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

## avoid serious bugs by omitting broken stuff

%end

# Create User Account
user --name=garrett --password=a --plaintext --groups=wheel,pkg-build,dialout,vboxusers,vboxsf,audio,video,render,kvm,libvirt
