require 'yaml'
conf = YAML.load_file('config.yaml')

IP = conf["ip"]
Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/trusty64"
	config.vm.provider "virtualbox" do |vb|
      #  vb.gui = true
        vb.name = "lab-vm"
        vb.memory = conf["memory"]
        vb.cpus = conf["cpus"]
    end
	config.vm.network :private_network, ip: IP
	config.vm.network :forwarded_port, guest: 80, host: 8080, auto_correct: true
    config.vm.provision "shell", path: "setup.sh"
end