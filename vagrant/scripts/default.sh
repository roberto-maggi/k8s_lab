systemctl set-default multi-user.target
export DEBIAN_FRONTEND=noninteractive
apt -y update
apt install -y bzip2 chrony net-tools vim net-tools console-data bash-completion
apt -y remove firewalld-filesystem apparmor ufw

if test -e /usr/sbin/iptables ;
	then
		iptables -F
		iptables -X ;
fi

timedatectl set-timezone Europe/Rome

# there's a bug in debian/ubuntu on keymap ...
 wget https://mirrors.edge.kernel.org/pub/linux/utils/kbd/kbd-2.5.1.tar.gz -O /tmp/kbd-2.5.1.tar.gz
 cd /tmp/ && tar xzf kbd-2.5.1.tar.gz
 cp -Rp /tmp/kbd-2.5.1/data/keymaps/* /usr/share/keymaps/
localectl set-keymap it
rm -fr /tmp/kbd-*

# user 		vagrant
# password 	vagrant
usermod -aG sudo vagrant
chmod 700 /home/vagrant/		
ln -sf /vagrant/ /home/vagrant/
mkdir -p /home/vagrant/.ssh
chmod -R 700 /home/vagrant/.ssh
cp -a /home/vagrant/vagrant/keys/* /home/vagrant/.ssh/
chmod 600 /home/vagrant/.ssh/*
chown -R vagrant:vagrant /home/vagrant/
# root 
ln -sf /vagrant/ /root/
mkdir -p /root/.ssh
cp -a /home/vagrant/vagrant/keys/* /root/.ssh/
chmod 700 /root/.ssh
chmod 600 /root/.ssh/*
chown -R root:root /root
# VIM
# users=(vagrant)
# for x in ${users[@]}; 
# 	do
# 		echo -e 'set mouse-=a' >> /home/$x/.vimrc
# 		echo -e 'syntax on' >> /home/$x/.vimrc
# 		echo -e 'colorscheme desert' >> /home/$x/.vimrc
# 		mkdir -p /.vim /home/${users[$x]}/.vim/colors;
# done

		echo -e 'set mouse-=a' >> ~/.vimrc
		echo -e 'syntax on' >> ~/.vimrc
		echo -e 'colorscheme desert' >> ~/.vimrc
		mkdir -p /.vim ~/.vim/colors;

# change root settings and password
# ROOT PASSWORD IS "vagrant"
sed -i '/root/d' /etc/shadow
sed -i '/root/d' /etc/passwd
echo -e 'root:$y$j9T$QRUL1vvFTES9KBZQPTbmU0$0UP00dtIsELRf7b2p4YnTZ3TfytpD9ty49VA63Ko4.9:19874:0:99999:7:::' >> /etc/shadow
echo -e 'root:x:0:0:root:/root:/bin/bash' >> /etc/passwd
cp -a /vagrant/files/chrony.conf /etc/chrony/
chronyc -a makestep
systemctl restart chrony

# give system wide access to sudoers
sed -i '/sudo/d' /etc/sudoers
echo -e '%sudo   ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

# ssh setup
mkdir -p /etc/systemd/system/ssh.socket.d/
echo -e "[Socket]" > /etc/systemd/system/ssh.socket.d/listen.conf 
echo -e "ListenStream=22" >> /etc/systemd/system/ssh.socket.d/listen.conf
sed -i 's/^#Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
sed -i 's/prohibit-password/yes/g' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication/PubkeyAuthentication/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#Port/Port/g' /etc/ssh/sshd_config
sed -i 's/#AllowAgentForwarding/AllowAgentForwarding/g' /etc/ssh/sshd_config
systemctl daemon-reload
# systemctl restart ssh.socket

## k8s

[ -e $(which setenforce) ] || setenforce 0
echo "swapoff -a" > /etc/profile.d/swapoff.sh
chmod +x /etc/profile.d/swapoff.sh
/etc/profile.d/swapoff.sh
sed -i '/swap/d'  /etc/fstab
modprobe overlay
modprobe br_netfilter

echo -e "overlay" > /etc/modules-load.d/containerd.conf
echo -e "br_netfilter" >> /etc/modules-load.d/containerd.conf
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
echo '1' > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
sysctl --system
echo -e "net.bridge.bridge-nf-call-ip6tables = 1\n net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/k8s.conf

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y 
apt -y upgrade
apt -y install lsb-release gnupg gnupg2 curl software-properties-common keepalived haproxy containerd apt-transport-https kubectl kubeadm  kubelet kubernetes-cni
apt-mark hold kubelet kubeadm kubectl
mkdir -p /etc/containerd
rm -f  /etc/containerd/config.toml
containerd config default > /etc/containerd/config.toml
sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
systemctl stop snapd.apparmor.service
systemctl disable snapd.apparmor.service
systemctl restart containerd.service
systemctl restart kubelet.service
systemctl enable containerd
systemctl enable kubelet
systemctl status --no-pager containerd
systemctl status --no-pager kubelet
netstat -avtpn | grep -Ei '(containerd)'

cat /vagrant/files/bash_rc >> /root/.bashrc

cp -a /vagrant/keepalived /etc/
chmod 0700  /etc/keepalived/
chmod 0400 /etc/keepalived/keepalived.conf
chmod 0100 /etc/keepalived/check_ha.sh
cp -a /vagrant/haproxy /etc
chmod 0700  /etc/haproxy/
chmod 0400  /etc/haproxy/haproxy.cfg

mkdir -p /root/deploy
cp -a /vagrant/metal-lb /root/deploy

