#!/bin/bash

hostnamectl set-hostname control-node

apt update
apt upgrade -y
