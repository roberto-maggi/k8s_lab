# ubuntu_srv_2004_kube

Creation of a HA Kubernetes Reverse proxy cluster with three nodes, two Control Plane nodes and two Worker Nodes.
HA granted with keepalived and HAProxy, although this wouldn't be the best scenario I'll put the LBs on the CP nodes,
just for testing purposes

cluster setup 

NAME                 STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
k-master-2           Ready    control-plane   17h   v1.26.5   192.168.1.111   <none>        Ubuntu 20.04.6 LTS   5.4.0-150-generic   containerd://1.6.21
k-worker-1           Ready    <none>          17h   v1.26.5   192.168.1.112   <none>        Ubuntu 20.04.6 LTS   5.4.0-150-generic   containerd://1.6.21
k-worker-2           Ready    <none>          17h   v1.26.5   192.168.1.113   <none>        Ubuntu 20.04.6 LTS   5.4.0-150-generic   containerd://1.6.21

una volta finito il provisioning delle vm 

vagrant status 

controlla le cpu e la ram

grep -i 'cpu cores' /proc/cpuinfo  | head -n 1
free -h

# Installazione di k8s

per ora kubelet risultera' installato, caricato ma inattivo.

sysctl --system && echo 'KUBELET_EXTRA_ARGS="--cgroup-driver=cgroupfs"' > /etc/default/kubelet 

---

kubeadm init --control-plane-endpoint=192.168.1.231:6443--pod-network-cidr=10.244.0.0/16 --upload-certs

<!-- KUBE_VERSIONE=1.30.1
VIP=192.168.1.230
VIP_PORT=6444
CP1_IP=192.168.1.231
CP_API_PORT=6443
echo -e "KUBE_VERSIONE=$KUBE_VERSIONE , VIP=$VIP, VIP_PORT=$VIP_PORT, CP1_IP=$CP1_IP, CP_API_PORT=$CP_API_PORT"

kubeadm init --control-plane-endpoint=$VIP:$VIP_PORT --apiserver-advertise-address=$CP1_IP --apiserver-bind-port=$CP_API_PORT --pod-network-cidr=10.244.0.0/16 --kubernetes-version=$KUBE_VERSIONE --upload-certs -->

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

### Taints e Labels
for CP in $(kubectl get nodes -l node-role.kubernetes.io/control-plane -o 'jsonpath={.items[*].metadata.name}') ; do k taint node $CP node-role.kubernetes.io/control-plane=:NoSchedule ;  done
kubectl describe nodes | egrep "Taints:|Name:"
for WN in $(k get nodes -l '!node-role.kubernetes.io/control-plane' -o 'jsonpath={.items[*].metadata.name}') ; do k label nodes $WN kubernetes.io/role=worker ; done

fai il join di tutti i nodi con le credenziali che ti appaiono a monitor

installa il cni

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

dalla vm master1

join dei worker nodes

( se te lo perdi... )

kubeadm token create --print-join-command   

### Installazione di MetalLB

 <!-- kubectl edit configmap -n kube-system kube-proxy -->

kubectl --kubeconfig=/etc/kubernetes/admin.conf get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl --kubeconfig=/etc/kubernetes/admin.conf diff -f - -n kube-system

kubectl --kubeconfig=/etc/kubernetes/admin.conf get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f - -n kube-system  

a questo punto si può deployare

kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml


poi deploy il file IPaddress-pool e L2-advertise

k apply -f IPaddress-pool.yaml
kg IPAddressPool  -n metallb-system
k apply -f L2Advertisement.yaml
kg l2advertisement -n metallb-system

### deploy default Storage Class

### Reset
kubeadm	reset --force
systemctl stop containerd
systemctl stop kubelet
pkill kubelet kube-proxy kube-apiserver kube-scheduler
ipvsadm --clear
for x in $(mount | grep kube | awk '{print $3}') ; do umount $x ; done
rm -rf /etc/kubernetes ~/.kube /var/lib/etcd/ /etc/cni/net.d
iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
sudo swapoff -a
 iptables -F && iptables -X
for IF in $(ip a s |awk 'BEGIN { FS = ":" } ; { print $2 }' |  egrep '(dock|cni|fla|cal)') ; do ip link set $IF down && ip link delete $IF && brctl delbr $IF ; done
systemctl restart containerd
systemctl restart kubelet

se dice che non riesce ad avviare "kubeadm init ..." sdraia tutto

### destroy
pt-mark unhold kubelet kubeadm kubectl containerd.io && GNUTLS_CPUID_OVERRIDE=0x1 apt -y remove containerd.io kubectl=1.28.0-00 kubeadm=1.28.0-00  kubelet=1.28.0-00 kubernetes-cni && apt autoremove -y && find / -type d -iname "*kube*" -not -name "*kubepods*" -exec rm -rf {} + ; find / -type d -iname "*cni*"  -exec rm -rf {} + ; find / -type d -iname "*containerd*"  -exec rm -rf {} ; find / -type d -iname "*etcd*"  -exec rm -rf {} + ; find /etc/ /root/  -type f -iname "*kube*" -exec rm -f {} + ; find /etc/ /root/  -type f -iname "*containerd*" -exec rm -f  {} + && apt -y update && apt -y upgrade && reboot
