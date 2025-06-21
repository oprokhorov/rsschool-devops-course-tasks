#!/bin/bash
sudo dnf update -y
sudo dnf install nmap-ncat -y # to probe ports
sudo hostnamectl set-hostname public-vm
