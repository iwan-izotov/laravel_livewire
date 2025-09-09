#!/bin/bash

USER=$1
cat >> /etc/sudoers <<EOF
$USER ALL=(ALL) NOPASSWD: ALL
EOF
