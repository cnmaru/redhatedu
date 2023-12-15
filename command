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
cat inventory/testcluster/inventory.ini
ansible --version
ansible all -i inventory/testcluster/inventory.ini -m ping		# ping test
ansible-playbook -i inventory/testcluster/inventory.ini --become --become-user=root cluster.yml		# 클러스터 설치
kubectl get nodes						# 설치 확인
vi inventory/testcluster/group_vars/k8s_cluster/addons.yml			# 대시보드 활성화
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
