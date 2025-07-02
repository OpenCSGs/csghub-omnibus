Name:           omnibus-csghub
Version:        TAG
Release:        REL%{?dist}
Summary:        All-in-one package for deploying and managing CSGHub

License:        Commercial
Vendor:         opencsg
URL:            https://www.opencsg.com
Packager:       opencsg <support@opencsg.com>

Requires:       ca-certificates, libicu, readline, nmap-ncat, apr-util, GeoIP, gd, libxml2, libxslt, libcurl, lsof, glibc, libstdc++
Conflicts:      %{name} < %{version}
Obsoletes:      %{name} <= %{version}
BuildArch:      ARCH

AutoReq:        no
AutoProv:       no

%description
An all-in-one package for deploying and managing CSGHub.
Bundles all necessary components, dependencies, and tools,
ensuring quick and reliable installation without complex setup.

%files
%defattr(-,root,root,-)
%dir %attr(0755, root, root) /opt/csghub
/opt/csghub/*
%config(noreplace) %attr(0644, root, root) /etc/systemd/system/csghub-runsvdir.service

%install
mkdir -p %{buildroot}/etc/systemd/system
mkdir -p %{buildroot}/etc/csghub
mkdir -p %{buildroot}/opt/csghub

cp -a %{_builddir}/opt/csghub/* %{buildroot}/opt/csghub/
cp -a %{_builddir}/opt/csghub/etc/csghub/templates/system/csghub-runsvdir.service %{buildroot}/etc/systemd/system/

%pre
#!/bin/sh
# Stop service if running before installation
if systemctl is-active csghub-runsvdir.service >/dev/null 2>&1; then
    systemctl stop csghub-runsvdir.service >/dev/null 2>&1
fi

%post
#!/bin/sh
# Create symlinks for binaries
for binfile in /opt/csghub/bin/*; do
    [ -f "$binfile" ] && ln -sf "$binfile" /usr/bin/ 2>/dev/null || :
done

# Create central configuration file
if [ ! -e /etc/csghub/csghub.yaml ]; then
    mkdir -p /etc/csghub || true
    cp /opt/csghub/etc/csghub/templates/csghub/csghub.yaml.sample /etc/csghub/csghub.yaml
fi

# Enable and start service
systemctl daemon-reload >/dev/null 2>&1 || :
systemctl enable csghub-runsvdir.service >/dev/null 2>&1 || :

case "$1" in
    1)  # Initial installation
        systemctl start csghub-runsvdir.service >/dev/null 2>&1 || :
        ;;
    2)  # Upgrade
        systemctl restart csghub-runsvdir.service >/dev/null 2>&1 || :
        /opt/csghub/bin/csghub-ctl reconfigure
        ;;
esac

%preun
#!/bin/sh
if [ "$1" = 0 ]; then  # Only on complete uninstall
    # Stop service
    systemctl stop csghub-runsvdir.service >/dev/null 2>&1 || :
    systemctl disable csghub-runsvdir.service >/dev/null 2>&1 || :

    # Backup configuration
    BACKUP_DIR="$HOME/csghub-backup-$(date +%s)"
    [ -d "/etc/csghub" ] && cp -a /etc/csghub "$BACKUP_DIR" && \
        echo "CSGHub configuration backed up to: $BACKUP_DIR"
fi

%postun
#!/bin/sh
if [ "$1" = 0 ]; then  # Only on complete uninstall
    # Clean up symlinks
    find /usr/bin -type l -lname '/opt/csghub/bin/*' -delete >/dev/null 2>&1 || :

    # Remove installed files
    rm -f /etc/systemd/system/csghub-runsvdir.service >/dev/null 2>&1
    rm -rf /opt/csghub >/dev/null 2>&1
    [ "$KEEPCONFIG" != "1" ] && rm -rf /etc/csghub >/dev/null 2>&1

    # Reload systemd
    systemctl daemon-reload >/dev/null 2>&1 || :
    echo "CSGHub uninstallation completed at $(date)"
fi