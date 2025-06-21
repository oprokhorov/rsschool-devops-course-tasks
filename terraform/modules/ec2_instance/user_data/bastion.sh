#!/bin/bash
sudo dnf update -y
sudo dnf install -y nginx
sudo systemctl enable nginx
sudo hostnamectl set-hostname bastion
