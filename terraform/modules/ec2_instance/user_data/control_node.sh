#!/bin/bash

hostnamectl set-hostname bastion

apt update
apt upgrade -y
