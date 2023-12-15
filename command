[공통 사항]
free -m			#메모리 확인
swapoff -a		# swap 메모리 off
free -m
vi /etc/fstab	# 재부팅 시에도 swap 메모리 off 할 수 있도록 주석 처리
cat /etc/fstab | grep swap
cat /proc/sys/net/ipv4/ip_forward		# ipv4 forword 활성화 (출력값이 1로 나와야 함)
vi /etc/hosts				# node 정보 등록
cat /etc/hosts
systemctl disable --now firewalld.service		# 방화벽 disable
vi /etc/selinux/config			# SElinux disable
setenforce 0
getenforce

[root@master01 ~]# cat /etc/hosts
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
::1 localhost6 localhost6.localdomain6 localhost6.localdomain
172.16.90.93    master01
172.16.90.94    worker01
172.16.90.95    worker02


[Master 사항]
yum install -y epel-release		# epel repo 등록
yum update -y
yum -y install python39
yum -y install ansible
yum -y install git wget
ssh-keygen -t rsa				# ssh 키 생성
ssh-copy-id master01			# node에 key 복사
ssh-copy-id worker01
ssh-copy-id worker02
git clone https://github.com/kubernetes-sigs/kubespray.git		# git 복사
cd kubespray/
pip3.9 install -r requirements.txt						# 패키지 설치
cp -rfp inventory/sample inventory/testcluster
vi inventory/testcluster/inventory.ini					# 호스트 등록

///
[root@master01 kubespray]# cat inventory/testcluster/inventory.ini
# ## Configure 'ip' variable to bind kubernetes services on a
# ## different ip than the default iface
# ## We should set etcd_member_name for etcd cluster. The node that is not a etcd member do not need to set the value, or can set the empty string value.
[all]
# node1 ansible_host=95.54.0.12  # ip=10.3.0.1 etcd_member_name=etcd1
# node2 ansible_host=95.54.0.13  # ip=10.3.0.2 etcd_member_name=etcd2
# node3 ansible_host=95.54.0.14  # ip=10.3.0.3 etcd_member_name=etcd3
# node4 ansible_host=95.54.0.15  # ip=10.3.0.4 etcd_member_name=etcd4
# node5 ansible_host=95.54.0.16  # ip=10.3.0.5 etcd_member_name=etcd5
# node6 ansible_host=95.54.0.17  # ip=10.3.0.6 etcd_member_name=etcd6
master01        ansible_host=172.16.90.93  ip=172.16.90.93
worker01        ansible_host=172.16.90.94  ip=172.16.90.94
worker02        ansible_host=172.16.90.95  ip=172.16.90.95

# ## configure a bastion host if your nodes are not directly reachable
# [bastion]
# bastion ansible_host=x.x.x.x ansible_user=some_user

[kube_control_plane]
master01

# node1
# node2
# node3

[etcd]
master01

# node1
# node2
# node3

[kube_node]
worker01
worker02

# node2
# node3
# node4
# node5
# node6

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr

///


cat inventory/testcluster/inventory.ini
ansible --version
ansible all -i inventory/testcluster/inventory.ini -m ping		# ping test
ansible-playbook -i inventory/testcluster/inventory.ini --become --become-user=root cluster.yml		# 클러스터 설치
kubectl get nodes						# 설치 확인
vi inventory/testcluster/group_vars/k8s_cluster/addons.yml			# 대시보드 활성화


///
[root@master01 kubespray]# cat inventory/testcluster/group_vars/k8s_cluster/addons.yml | grep -v '#'
---
dashboard_enabled: true

helm_enabled: false

registry_enabled: false

metrics_server_enabled: true

local_path_provisioner_enabled: false

local_volume_provisioner_enabled: false


cephfs_provisioner_enabled: false

rbd_provisioner_enabled: false

ingress_nginx_enabled: true
ingress_publish_status_address: ""

ingress_alb_enabled: false

cert_manager_enabled: false




metallb_enabled: false
metallb_speaker_enabled: "{{ metallb_enabled }}"

argocd_enabled: false

krew_enabled: false
krew_root_dir: "/usr/local/krew"

kube_vip_enabled: false

///


ansible-playbook -i inventory/testcluster/inventory.ini --become --become-user=root cluster.yml		# 클러스터 추가 설치
kubectl cluster-info
kubectl get node
kubectl get nodes -o wide
kubectl get ns
kubectl get svc -n kube-system
vi admin.yaml									# admin-user 생성
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system

kubectl -n kube-system create token admin-user			# 토큰 생성
kubectl proxy --address='127.0.0.1' --port='8001'		# proxy 생성

## http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#/login 로 접속하여 토큰 이용 대시보드 로그인
