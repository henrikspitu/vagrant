#!/bin/bash
echo "KEY FILE $1"
sudo yum update
sudo yum install -y  dnsutils
sudo yum install -y curl
sudo apt-add-repository ppa:ansible/ansible -y
sudo yum update
sudo yum install -y ansible
sudo yum install git -y
sudo yum install docker -y
sudo useradd -m hspo
sudo mkdir /home/hspo/.ssh
sudo chown -R hspo:hspo /home/hspo/.ssh
sudo mkdir /home/hspo/workspace
sudo chown -R hspo:hspo /home/hspo/workspace
sudo mkdir /home/hspo/prometheus
sudo chown -R hspo:hspo /home/hspo/prometheus
sudo wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.3.1/jmx_prometheus_javaagent-0.3.1.jar -O /home/hspo/prometheus/jmx_prometheus_javaagent-0.3.1.jar 
sudo wget https://raw.githubusercontent.com/prometheus/jmx_exporter/master/example_configs/kafka-0-8-2.yml -O /home/hspo/prometheus/kafka-0-8-2.yml
sudo chown -R hspo:hspo /home/hspo/rometheus
sudo echo "$1" >> /home/hspo/.ssh/authorized_keys
#sudo echo "$1" >> /root/.ssh/authorized_keys
sudo chown -R hspo:hspo /home/hspo/.ssh
sudo echo "hspo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/hspo
sudo useradd -m ansible -p ansible
sudo mkdir /home/ansible/.ssh
sudo chown -R ansible:ansible /home/ansible/.ssh
sudo echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo /bin/systemctl start docker.service
sudo usermod -a -G docker ec2-user
sudo groupadd docker
sudo  useradd -m ec2-user
sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


sudo  echo "ALL DONE"