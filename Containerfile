# FROM registry.redhat.io/rhel9/rhel-bootc:9.4
# FROM registry.redhat.io/rhel9-eus/rhel-9.4-bootc
# FROM quay.coe.muc.redhat.com/proxy_registry_redhat_io/rhel9-eus/rhel-9.4-bootc
FROM quay.coe.muc.redhat.com/proxy_registry_redhat_io/rhel9/rhel-bootc:9.4

ARG USHIFT_VER=4.17
RUN dnf config-manager \
        --set-enabled rhocp-${USHIFT_VER}-for-rhel-9-$(uname -m)-rpms \
        --set-enabled fast-datapath-for-rhel-9-$(uname -m)-rpms
RUN dnf install -y firewalld microshift && \
    systemctl enable microshift && \
    dnf clean all && \

# Mandatory firewall configuration for microshift
    firewall-offline-cmd --zone=public --add-port=22/tcp && \
    firewall-offline-cmd --zone=trusted --add-source=10.42.0.0/16 && \
    firewall-offline-cmd --zone=trusted --add-source=169.254.169.1

# Create a systemd unit to recursively make the root filesystem subtree
# shared as required by OVN images
COPY templates/microshift-make-rshared.service /etc/systemd/system/
RUN systemctl enable microshift-make-rshared.service && \

# Registry with bootc image has cert from custom CA,
# need to add that to for later update:
RUN curl https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem -o /etc/pki/ca-trust/source/anchors && \
    update-ca-trust && \
# Make the KUBECONFIG from MicroShift directly available for the root user
    echo -e 'export KUBECONFIG=/var/lib/microshift/resources/kubeadmin/kubeconfig' >> /root/.profile

# Registry with bootc image requires auth, need to add token for that:
COPY /workspace/dockerconfig/.dockerconfigjson /etc/ostree/auth.json

# Add helpful demo commands to bash history
COPY templates/bash_history.txt /root/.bash_history


# Demo an update:
# RUN date >>/usr/DanielWasHere.txt
