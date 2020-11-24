#!/bin/bash
##########################################################################
# File Name: install_rke.sh
# Author: gswest
# mail: colin.shen[AT]suse.com
# Created Time: Tue 24 Nov 2020 10:32:31 AM CST
#########################################################################

echo "請輸入Case:A環境初始化,B(建立使用者金鑰),C(複製金鑰),D(開始安裝),q(結束安裝)"
install_now="$(date +'%Y-%m-%d %H:%M:%S')"
echo "$install_now"
while :
do
 read INPUT_STRING
 install_now="$(date +'%Y-%m-%d %H:%M:%S')"
 echo "$install_now" >> ~/result.log
 echo "$INPUT_STRING" >> ~/result.log
 case $INPUT_STRING in
        A)
	# check kernel module and enable kernel module
	     for module in br_netfilter ip6_udp_tunnel ip_set ip_set_hash_ip ip_set_hash_net iptable_filter iptable_nat iptable_mangle iptable_raw nf_conntrack_netlink nf_conntrack nf_conntrack_ipv4   nf_defrag_ipv4 nf_nat nf_nat_ipv4 nf_nat_masquerade_ipv4 nfnetlink udp_tunnel veth vxlan x_tables xt_addrtype xt_conntrack xt_comment xt_mark xt_multiport xt_nat xt_recent xt_set  xt_statistic xt_tcpudp;
     do
       if ! lsmod | grep -q $module; then
         echo "module $module is not present"
	 sudo modprobe $module ;
       fi;
     done
		for module in br_netfilter ip6_udp_tunnel ip_set ip_set_hash_ip ip_set_hash_net iptable_filter iptable_nat iptable_mangle iptable_raw nf_conntrack_netlink nf_conntrack nf_conntrack_ipv4   nf_defrag_ipv4 nf_nat nf_nat_ipv4 nf_nat_masquerade_ipv4 nfnetlink udp_tunnel veth vxlan x_tables xt_addrtype xt_conntrack xt_comment xt_mark xt_multiport xt_nat xt_recent xt_set  xt_statistic xt_tcpudp;
     do
       if ! lsmod | grep -q $module; then
         echo "module $module is not present" ;
       fi;
     done

	# net.bridge.bridge-nf-call-iptables=1
	sudo sysctl -a | grep "net.bridge.bridge-nf-call-iptables"
	sudo sysctl -w net.bridge.bridge-nf-call-iptables=1

	# AllowTCPForwarding
	sudo sed -i "32c PermitRootLogin yes" /etc/ssh/sshd_config
	sudo systemctl restart sshd
	sudo systemctl status sshd

	# install docker\rke\kubectl
	sudo SUSEConnect -p sle-module-containers/15.2/x86_64
	sudo zypper ref
	sudo zypper install -y docker
	sudo systemctl enable docker
	sudo systemctl start docker
	sudo systemctl status docker
	docker version --format '{{.Server.Version}}'
	
	# install yq
	sudo wget https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq
	
	# install rke
	sudo wget https://github.com/rancher/rke/releases/download/v1.0.14/rke_linux-amd64 -O /usr/bin/rke && sudo chmod +x /usr/bin/rke
	rke --version
	
	# install kubectl
	sudo wget https://storage.googleapis.com/kubernetes-release/release/v1.19.0/bin/linux/amd64/kubectl -O /usr/bin/kubectl && sudo chmod +x /usr/bin/kubectl
	kubectl version --client
	
	# install 
	sudo SUSEConnect -p PackageHub/15.2/x86_64
	sudo zypper install -y sshpass

	echo "繼續下一步"
	echo "請輸入Case:A環境初始化,B(建立使用者金鑰),C(複製金鑰),D(開始安裝),q(結束安裝)";;
	B)      #建立新使用者
		echo "請輸入欲建立的新使用者："
		read INPUT_STRING_USER
		echo "使用者：$INPUT_STRING_USER"
		sudo useradd  -m $INPUT_STRING_USER
		sudo usermod -aG docker $INPUT_STRING_USER
		sudo passwd $INPUT_STRING_USER
		sudo -su $INPUT_STRING_USER -c ssh-keygen
		echo "完成建立使用者：$INPUT_STRING_USER SSH金鑰" 
		echo "繼續下一步"
		echo "請輸入Case:A環境初始化,B(建立使用者金鑰),C(複製金鑰),D(開始安裝),q(結束安裝)";;
	C)
		
		echo "請輸入要複製ssh金鑰的使用者："
		read INPUT_STRING_CP_USER
		echo "請輸入使用者ssh金鑰的密碼"
		read TEMP_PASS
		while read HOST; 
		do	
			echo "sudo ssh-copy-id -i /home/${INPUT_STRING_CP_USER}/.ssh/id_rsa.pub ${INPUT_STRING_CP_USER}@${HOST}"
      			sudo ssh-copy-id -i /home/${INPUT_STRING_CP_USER}/.ssh/id_rsa.pub $INPUT_STRING_CP_USER@$HOST
		done < ./list_servers_ip.txt

		echo "完成複製使用者SSH金鑰：$INPUT_STRING_CP_USER"
		echo "繼續下一步"
                echo "請輸入Case:A環境初始化,B(建立使用者金鑰),C(複製金鑰),D(開始安裝),q(結束安裝)";;

	D)
		echo "開始單台部署"
		echo "請輸入要部署的使用者名稱："
		read INPUT_STRING_USER
		echo "請輸入目標機的IP："
		read INPUT_STRING_IP
		sudo -su $INPUT_STRING_USER /bin/mkdir -p /home/${INPUT_STRING_USER}/autotest-deploy
		sudo -su $INPUT_STRING_USER wget -P /home/${INPUT_STRING_USER}/autotest-deploy https://raw.githubusercontent.com/gswest/SUSE-rke-deploy/main/single_node/cluster.yml
		sudo -su $INPUT_STRING_USER yq w -i /home/${INPUT_STRING_USER}/autotest-deploy/cluster.yml nodes.*.address $INPUT_STRING_IP
		sudo -su $INPUT_STRING_USER yq w -i /home/${INPUT_STRING_USER}/autotest-deploy/cluster.yml nodes.*.user $INPUT_STRING_USER
		sudo -su $INPUT_STRING_USER yq w -i /home/${INPUT_STRING_USER}/autotest-deploy/cluster.yml nodes.*.ssh_key_path  /home/${INPUT_STRING_USER}/.ssh/id_rsa
		sudo -su $INPUT_STRING_USER rke --config /home/${INPUT_STRING_USER}/autotest-deploy/cluster.yml
		sudo -su $INPUT_STRING_USER rke --config /home/${INPUT_STRING_USER}/autotest-deploy/cluster.yml
		echo "請輸入Case:A環境初始化,B(建立使用者金鑰),C(複製金鑰),D(開始安裝),q(結束安裝)" ;;
	q)
                echo "結束安裝程式"
                exit ;;
        *)
                echo "請輸入Case:A環境初始化,B(建立使用者金鑰),C(複製金鑰),D(開始安裝),q(結束安裝)" ;;
 esac
done
echo
echo "install done!"
