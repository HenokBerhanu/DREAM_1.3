sudo kubeadm join 192.168.56.102:6443 --token ixufk3.kl3mjscxgrqrlls7 \
        --discovery-token-ca-cert-hash sha256:386ec6af1308351cd4efeb97ac471d3a52629aa1fc28e174a1ae1038ae727185


sudo kubeadm join 192.168.56.102:6443 --token bqcu79.rf4o0hfgiztsyp46 \
	--discovery-token-ca-cert-hash sha256:e32c575bec6970958303bb84e287752ba7b30d8656310fcd0daef6501c36fb33

kubeadm join 192.168.56.102:6443 --token 9d9ba9.ulogb6j3sfg0gly6 \
	--discovery-token-ca-cert-hash sha256:4cd22d34ca8c19bce0730660ff22fbabfa3f6d0122ee015a2c1a8f9c7cbfbecd 

sudo kubeadm join 192.168.56.102:6443 --token jhxs97.3z9icyh2vt96hokq \
	--discovery-token-ca-cert-hash sha256:87c7a12e45dd95579f281fc83861c77ab2515bc52ead320cebcf95c721c8ca65

kubectl label node cloudnode node-role.kubernetes.io/worker-node=

sudo kubeadm join 192.168.56.102:6443 --token i3eae7.7jsj5n0c0gdieimo \
	--discovery-token-ca-cert-hash sha256:fba6973f1a44fb75d9c7d6459d09dbd3785b1d9bd212c6d1080a5c7bf2983cd2 