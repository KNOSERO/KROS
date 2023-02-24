# -*- mode: ruby -*-
# vi: set ft=ruby :

#=========================
#       Config
#=========================

Vagrant.require_version ">= 1.6.0"
VAGRANTFILE_API_VERSION = "2"

ROOTPATH = File.dirname(__FILE__)

require 'yaml'
require "#{ROOTPATH}/dependency.rb"

CONFIG_FILE = YAML.load_file("#{ROOTPATH}/config.yml")

VIRTUAL_MACHINE = CONFIG_FILE["virtualMachine"]

#=========================
#       Box
#=========================

BOX = VIRTUAL_MACHINE["box"]
BOX["name"] = ENV['BOX_NAME'] || BOX["name"]

#=========================
#       Host
#=========================

HOST = VIRTUAL_MACHINE["host"]
HOST["name"] = ENV['HOST_NAME'] || HOST["name"]
HOST["ip"] = ENV['HOST_IP'] || HOST["ip"]

#=========================
#       Network
#=========================

MACHINE = VIRTUAL_MACHINE["machine"]
MACHINE["name"] = ENV['NAME_MACHINE'] || MACHINE["name"]

#=========================
#   Install Version
#=========================

INSTALL = VIRTUAL_MACHINE["install"]
DOCKER_IMAGE = INSTALL["docker"]

#=========================
#       Plugin
#=========================

check_plugins ["vagrant-vbguest"]

#=========================
#       Process
#=========================

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = BOX["name"]
  config.vm.box_version = BOX["version"]

  config.vm.define HOST["name"]
  config.vm.hostname = HOST["name"]
  config.vm.network 'private_network', ip: HOST["ip"]

  #=========================
  #       Provider
  #=========================

  config.vm.provider "virtualbox" do |vb|
    vb.name = MACHINE["name"]
    vb.memory = MACHINE["memory"]
    vb.cpus = MACHINE["cpus"]

    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]

    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
  end

  config.vm.synced_folder ".", "/vagrant", disabled:true

  #=========================
  #       Install
  #=========================

  config.vm.provision 'shell',
                      path: 'provision/install.sh',
                      run: 'always',
                      keep_color: true,
                      args: [
                        INSTALL["java"],
                        INSTALL["gradle"],
                        INSTALL["node"],
                        INSTALL["npm"],
                        INSTALL["yarn"]
                      ]

  #=========================
  #       Docker
  #=========================

  config.vm.provision "docker" do |docker|
    docker.pull_images DOCKER_IMAGE["postgres"]
    docker.pull_images DOCKER_IMAGE["treafic"]
  end

  config.ssh.forward_agent = true
  config.vbguest.auto_update = false
  config.vbguest.no_remote = true

  config.vm.post_up_message =
    "
      ---------------------------------------------------------
      Vagrant machine ready to use
    "
end
