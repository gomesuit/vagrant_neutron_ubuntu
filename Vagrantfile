# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu-14.04-x64"
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
  #config.vm.network :forwarded_port, guest: 80, host: 80

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
    #vb.customize ['modifyvm', :id, '--nictype1', 'Am79C973']
    vb.customize ['modifyvm', :id, '--nicpromisc1', 'allow-all']
  end

  config.vm.define "neutron" do |host|
    host.vm.hostname = "neutron"
    host.vm.network "private_network", ip: "192.168.33.50"
    host.vm.provision :shell, :path => "provision.sh"
  end
  
end
