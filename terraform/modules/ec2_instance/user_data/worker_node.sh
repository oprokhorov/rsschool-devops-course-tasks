#!/bin/bash

hostnamectl set-hostname worker-node

apt update
apt upgrade -y
