PULL_SECRET=~/.pull-secret.json
USER_PASSWD=<your_redhat_user_password>
IMAGE_NAME=microshift-4.17-bootc


sudo podman build --authfile "${PULL_SECRET}" -t "${IMAGE_NAME}" \
    --build-arg USER_PASSWD="${USER_PASSWD}" \
    -f Containerfile



Error:
STEP 2/10: ARG USHIFT_VER=4.17
--> 48dda5ab4987
STEP 3/10: RUN dnf config-manager         --set-enabled rhocp-${USHIFT_VER}-for-rhel-9-$(uname -m)-rpms         --set-enabled fast-datapath-for-rhel-9-$(uname -m)-rpms
WARN[0054] Failed to load cached network config: network podman not found in CNI cache, falling back to loading network podman from disk
WARN[0054] 1 error occurred:
	* plugin type="tuning" failed (delete): failed to find plugin "tuning" in path [/usr/local/libexec/cni /usr/libexec/cni /usr/local/lib/cni /usr/lib/cni /opt/cni/bin]

error running container: did not get container start message from parent: EOF
Error: building at STEP "RUN dnf config-manager         --set-enabled rhocp-${USHIFT_VER}-for-rhel-9-$(uname -m)-rpms         --set-enabled fast-datapath-for-rhel-9-$(uname -m)-rpms": setup network: plugin type="bridge" failed (add): failed to find plugin "bridge" in path [/usr/local/libexec/cni /usr/libexec/cni /usr/local/lib/cni /usr/lib/cni /opt/cni/bin]
[builder@ushift-imgbld bootc]$ uname -m
x86_64

--> need to install additional package:


[builder@ushift-imgbld bootc]$  dnf install containernetworking-plugins
Not root, Subscription Management repositories not updated
Error: This command has to be run with superuser privileges (under the root user on most systems).
[builder@ushift-imgbld bootc]$ sudo dnf install containernetworking-plugins
Updating Subscription Management repositories.
Last metadata expiration check: 0:29:45 ago on Mon 21 Oct 2024 07:27:22 PM CEST.
Dependencies resolved.
=============================================================================================================================================================================================================================================================
 Package                                                             Architecture                                   Version                                                   Repository                                                                Size
=============================================================================================================================================================================================================================================================
Installing:
 containernetworking-plugins                                         x86_64                                         1:1.4.0-6.el9_4                                           rhel-9-for-x86_64-appstream-rpms                                         9.3 M

Transaction Summary
=============================================================================================================================================================================================================================================================
Install  1 Package

Total download size: 9.3 M
Installed size: 62 M
Is this ok [y/N]:


sudo podman push --authfile "${PULL_SECRET}" localhost/microshift-4.17-bootc "quay.coe.muc.redhat.com/shared/microshift/microshift-4.17-bootc"


NEW: 1.5 Run the image using podman
Small intro describing the intention/purpose of when/why one would run the image using podman
NEW: 1.5.1 Configure networking (Content from old 1.4)
NEW:1.5.2 Running the container (Content from old 1.5)


**** Grub.cfg:
inst.stage2=http://ushift-imgbld.stormshift.coe.muc.redhat.com/ushift-bootc-install-iso inst.ks=http://ushift-imgbld.stormshift.coe.muc.redhat.com/ushift-bootc-install-iso/osbuild.ks
inst.stage2=hd:LABEL=Container-Installer-x86_64 inst.ks=hd:LABEL=Container-Installer-x86_64:/ushift-bootc-install-iso/osbuild.ks



****** problem:
anacondo starts:
An error occured during reading the kickstart file
no such file or directory: /run/install/repo/osbuild-base.ks

# make sure to be able to pull images from an insecure registry

scp * builder@ushift-imgbld.stormshift.coe.muc.redhat.com:/home/builder/ushift-bootc/


# build ISO image:
Docs:

https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/using_image_mode_for_rhel_to_build_deploy_and_manage_operating_systems/creating-bootc-compatible-base-disk-images-with-bootc-image-builder_using-image-mode-for-rhel-to-build-deploy-and-manage-operating-systems#creating-iso-images-by-using-bootc-image-builder_creating-bootc-compatible-base-disk-images-with-bootc-image-builder
```
sudo podman run \
    --authfile "${PULL_SECRET}" \
    --rm \
    -it \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v $(pwd)/bootc-image-builder-config.toml:/config.toml \
    -v $(pwd)/output:/output \
    registry.redhat.io/rhel9/bootc-image-builder:9.4 \
    --type iso \
    --tls-verify=false \
    --config /config.toml \
  quay.coe.muc.redhat.com/shared/microshift/microshift-4.17-bootc:install
```
--> did this on imgbld2, as imgbld1 did not work, probably due to conflicts with ostree-compose, or other previously long term created configurations

# Serve ISO on http server
Instructions:
https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/interactively_installing_rhel_over_the_network/preparing-to-install-from-the-network-using-http_rhel-installer#configuring-the-http-server-for-http-boot_preparing-to-install-from-the-network-using-http



```
ssh builder@ushift-imgbld2.stormshift.coe.muc.redhat.com
$ sudo su -
# mount -o loop,ro -t iso9660 /home/builder/ushift-bootc/output/bootiso/install.iso /var/www/html/ushift-bootc-install/iso/

cp -r /var/www/html/ushift-bootc-install/iso/images /var/www/html/ushift-bootc-install/
chmod 644 /var/www/html/ushift-bootc-install/EFI/BOOT/grub.cfg
vi /var/www/html/ushift-bootc-install/EFI/BOOT/grub.cfg

```

chmod -cR u=rwX,g=rX,o=rX /var/www/html
restorecon -FvvR /var/www/html
