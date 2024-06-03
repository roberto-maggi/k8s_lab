############################
#
#	project specific 
#		ONLY for
#		k8s on debian vms
#
############################

apt -y install nfs-kernel-server
mkdir -p /nfs
echo -e "/nfs 192.168.1.0/24(rw,sync,no_root_squash,no_subtree_check)"  > /etc/exports
exportfs -ra 
