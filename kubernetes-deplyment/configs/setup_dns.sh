#!/bin/bash

# Set DNS to Google's 8.8.8.8 inside systemd resolver
grep -q "^DNS=" /etc/systemd/resolved.conf && \
    sed -i 's/^#DNS=.*/DNS=8.8.8.8/' /etc/systemd/resolved.conf || \
    echo "DNS=8.8.8.8" >> /etc/systemd/resolved.conf

# Restart systemd-resolved to apply changes
systemctl restart systemd-resolved