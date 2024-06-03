wordpress con mysql e secret opaque per gestire la root pwd di mysql
si aggancia alla SC gestita dall'nfs-provisioner

il deploy viene fatto contro l'nginx ingress controller a cui viene fornito 
l'IP di tipo LoadBalancer da MetalLB