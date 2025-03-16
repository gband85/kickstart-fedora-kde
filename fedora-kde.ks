text
lang en_US.UTF-8
keyboard us
timezone US/Central
selinux --permissive
firewall --enabled --service=mdns
services --enabled=sshd,NetworkManager,chronyd
network --bootproto=dhcp --device=link --activate --hostname=x570plus
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
#url --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-41&arch=x86_64"
url --url="http://192.168.1.142/repos/fedora/releases/41/Everything/x86_64/os/Packages/"
repo --name=Mullvad-VPN --baseurl=https://repository.mullvad.net/rpm/stable/x86_64 --install
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

%end


%post --log=/root/ks-customization.log
wget -P /home/garrett/Downloads https://talonvoice.com/update/qyO6k0Y0jHOeI94q51eTKV/talon-linux-115-0.4.0-650-ga789.tar.xz
tar -xf /home/garrett/Downloads/talon-linux-* -C /home/garrett
cp /home/garrett/talon/10-talon.rules /etc/udev/rules.d/
wget -P /home/garrett/Downloads --content-disposition --trust-server-names https://linphone.org/releases/linux/latest_app
wget -P /home/garrett/Downloads http://jocala.com/downloads/adblink.63.zip
unzip /home/garrett/Downloads/adblink.63.zip -d /home/garrett/Downloads/
read filename < <(curl -L  --head https://linphone.org/releases/linux/latest_app 2>/dev/null | grep Location: | tail -n1 | cut -d' ' -f2 | grep -o Linphone-.*)
chmod +x /home/garrett/Downloads/$filename
mkdir -p /home/garrett/.megaCmd/
touch /home/garrett/.megaCmd/.megaignore.default
mega-login ##################### ############
mega-get settings_backup/.config /home/garrett
mega-get settings_backup/.thunderbird /home/garrett
mega-get settings_backup/.local /home/garrett/
mega-get settings_backup/.android /home/garrett/
mega-get settings_backup/.jocala /home/garrett/
mega-get settings_backup/.talon /home/garrett
git clone https://github.com/gband85/community.git /home/garrett/.talon/user/community
wget -P /home/garrett http://192.168.1.142/flatpak-install.sh
chmod +x /home/garrett/flatpak-install.sh
mkdir -p /home/garrett/.config/systemd/user/default.target.wants
wget -P /home/garrett/.config/systemd/user http://192.168.1.142/first-boot.service
ln -s /home/garrett/.config/systemd/user/first-boot.service /home/garrett/.config/systemd/user/default.target.wants/first-boot.service
kwriteconfig5 --file ~/.config/kwinrc --group Windows --key FocusStealingPreventionLevel 0
kwriteconfig5 --file ~/.config/kwinrc --group Effect-overview --key BorderActivate 9
kwriteconfig5 --file ~/.config/kscreenlockerrc --group Daemon --key AutoLock false
kwriteconfig5 --file ~/.config/kscreenlockerrc --group Daemon --key LockOnResume false
kwriteconfig5 --file ~/.config/kscreenlockerrc --group Daemon --key Timeout 0
kwriteconfig5 --file ~/.config/powerdevilrc    --group AC --group Display --key TurnOffDisplayIdleTimeoutSec 900
kwriteconfig5 --file ~/.config/powerdevilrc    --group AC --group SuspendAndShutdown --key AutoSuspendIdleTimeoutSec 7200

chown -R garrett:garrett /home/garrett
%end

%packages
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
# lpf-spotify-client
okular
gwenview
# kernel
rEFInd
scrcpy
libyui-mga-qt
libyui-qt
pcre2.i686
dracut-config-generic
glibc-all-langpacks
android-tools
plasma-workspace-x11
thunderbird
gnome-disk-utility
alsa-firmware
@vlc
@firefox
steam
@kde-spin-initial-setup
dnfdragora
fedora-release-kde
git
megacmd
-tracker-miners
-tracker
-mariadb-server-utils
plasma-welcome-fedora
kde-l10n
fuse
mediawriter

%end

user --name=garrett --password=a --plaintext --groups=wheel,pkg-build,dialout,vboxusers,vboxsf,audio,video,render,kvm,libvirt,mock,docker
