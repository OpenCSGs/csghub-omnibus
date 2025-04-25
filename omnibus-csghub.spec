Name:           omnibus-csghub
Version:        1.6.0
Release:        1%{?dist}
Summary:        All-in-one package for deploying and managing CSGHub

License:        Commercial
Vendor:         opencsg
URL:            https://www.opencsg.com
Packager:       opencsg <support@opencsg.com>

Requires:       glibc >= 2.31, libicu
Conflicts:      %{name} < %{version}
Obsoletes:      %{name} <= %{version}

AutoReq:        no
AutoProv:       no
%define __requires_exclude ^.*$
%define _build_id_links none

%define pgsql_version 16.8
%define pg_home /opt/csghub/embedded/sv/postgresql
%define scws_version 1.2.3
%define scws_home /opt/csghub/embedded
%define zhparser_version 2.3
%define python_version 3.13.2
%define python_home /opt/csghub/embedded/python

Source0:        %{name}-%{version}.tar.gz
Source1:        https://ftp.postgresql.org/pub/source/v%{pgsql_version}/postgresql-%{pgsql_version}.tar.gz
Source2:        http://www.xunsearch.com/scws/down/scws-%{scws_version}.tar.bz2
Source3:        https://gh-proxy.com/github.com/amutu/zhparser/archive/refs/tags/v%{zhparser_version}.zip
Source4:        https://www.python.org/ftp/python/%{python_version}/Python-%{python_version}.tgz

BuildRequires:  gcc make bison flex libtool
BuildRequires:  readline-devel zlib-devel openssl-devel
BuildRequires:  libicu-devel libxml2-devel libxslt-devel
BuildRequires:  unzip patchelf chrpath
BuildRequires:  systemd-devel

# Disable debuginfo packet generation
%global debug_package %{nil}
%global __debug_install_post %{nil}

# Optional: Disable debug builds (optimized compilation)
%global _enable_debug_packages 0

%description
An all-in-one package for deploying and managing CSGHub.
Bundles all necessary components, dependencies, and tools.

%prep
%setup -q -n %{name}-%{version} # omnibus-csghub
%setup -q -T -D -a 1            # postgresql
%setup -q -T -D -a 2            # scws
%setup -q -T -D -a 3            # zhparser
%setup -q -T -D -a 4            # python

%build
# Compile postgresql
cd %{_builddir}/%{name}-%{version}/postgresql-%{pgsql_version}
./configure --prefix=%{pg_home} \
    --with-openssl \
    --with-icu \
    --with-readline \
    --with-libxml \
    --with-libxslt
make %{?_smp_mflags} world
make install-world DESTDIR=%{_builddir}/%{name}-%{version}/postgresql-%{pgsql_version}

# Compile scws
cd %{_builddir}/%{name}-%{version}/scws-%{scws_version}
./configure --prefix=%{scws_home}
make %{?_smp_mflags}
make install DESTDIR=%{_builddir}/%{name}-%{version}/scws-%{scws_version}

# Compile zhparser
export SCWS_HOME=%{_builddir}/%{name}-%{version}/scws-%{scws_version}%{scws_home}
export PGHOME=%{_builddir}/%{name}-%{version}/postgresql-%{pgsql_version}%{pg_home}
export PATH=$PGHOME/bin:$PATH
export LD_LIBRARY_PATH=$PGHOME/lib:$LD_LIBRARY_PATH
cd %{_builddir}/%{name}-%{version}/zhparser-%{zhparser_version}
make %{?_smp_mflags}

# Compile python
cd %{_builddir}/%{name}-%{version}/Python-%{python_version}
./configure --prefix=%{python_home} \
    --enable-optimizations \
    --enable-shared \
    --with-ensurepip=install
make %{?_smp_mflags}

%install
# Completely clean buildroot
rm -rf %{buildroot}/*

# Installation dependency directory
install -d -m 0755 %{buildroot}/etc/csghub
install -d -m 0755 %{buildroot}/etc/systemd/system
install -d -m 0755 %{buildroot}/opt/csghub/embedded/{bin,lib,python,sv}

# Securely copy files
(
    cd %{_builddir}/%{name}-%{version}
    find etc -type f -exec install -Dm644 {} %{buildroot}/{} \;
    find opt -type f -exec install -Dm755 {} %{buildroot}/{} \;
)

# Install postgresql
cd %{_builddir}/%{name}-%{version}/postgresql-%{pgsql_version}
make install-world DESTDIR=%{buildroot}

# Install scws
cd %{_builddir}/%{name}-%{version}/scws-%{scws_version}
make install DESTDIR=%{buildroot}
libtool --finish %{buildroot}%{scws_home}/lib

# Install zhparser
# Cannot add %{buildroot} as prefix
export SCWS_HOME=%{scws_home}
export PGHOME=%{buildroot}%{pg_home}
export LD_LIBRARY_PATH=$PGHOME/lib:$LD_LIBRARY_PATH
export PATH=$PGHOME/bin:$PATH
cd %{_builddir}/%{name}-%{version}/zhparser-%{zhparser_version}
make install

# Install python
cd %{_builddir}/%{name}-%{version}/Python-%{python_version}
make altinstall DESTDIR=%{buildroot}

# Install patroni
export PYTHONHOME=%{buildroot}%{python_home}
export PYTHONPATH=%{buildroot}/opt/csghub/embedded/sv
export PATH=$PYTHONHOME/bin:$PATH
export LD_LIBRARY_PATH=$PYTHONHOME/lib:$LD_LIBRARY_PATH
python3.13 -m pip install \
    --no-cache-dir \
    --root=%{buildroot} \
    --prefix=/opt/csghub/embedded/sv/patroni \
    patroni[consul] psycopg2-binary

# Fixed shebang path
find %{buildroot}/opt/csghub/embedded/sv/patroni/bin -type f -exec \
    sed -i '1s|#!.*/python3.13|#!/opt/csghub/embedded/python/bin/python3.13|' {} \;

# Fix path references
find %{buildroot} -type f -name "*.so" -exec chmod 755 {} \;
find %{buildroot} -type f -name "*.so" -exec patchelf --remove-rpath {} \; 2>/dev/null || true
find %{buildroot} -type f -name "*.so" -exec patchelf --set-rpath '$ORIGIN/../lib:%{scws_home}/lib:%{pg_home}/lib:%{python_home}/lib:/lib:/lib64:/usr/lib:/usr/lib64:/usr/local/lib:/usr/local/lib64' {} \; 2>/dev/null || true

# Clean up temporary paths
find %{buildroot} -type f -name "*.py" -o -name "*" -exec \
    sed -i "s|%{buildroot}||g" {} 2>/dev/null \;

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%config(noreplace) /etc/csghub/*
%dir /opt/csghub
/opt/csghub/*
%config(noreplace) /etc/systemd/system/csghub-runsvdir.service

%pre
#!/bin/sh
if systemctl is-active csghub-runsvdir.service >/dev/null 2>&1; then
    systemctl stop csghub-runsvdir.service >/dev/null 2>&1 || true
fi

%post
#!/bin/sh
for binfile in /opt/csghub/bin/*; do
    [ -f "$binfile" ] && ln -sf "$binfile" /usr/bin/ 2>/dev/null || true
done

systemctl daemon-reload >/dev/null 2>&1 || true
systemctl enable csghub-runsvdir.service >/dev/null 2>&1 || true

if [ "$1" -ge 1 ]; then
    systemctl restart csghub-runsvdir.service >/dev/null 2>&1 || true
fi

if [ "$1" -gt 1 ]; then
    /opt/csghub/bin/csghub-ctl reconfigure
fi

%preun
#!/bin/sh
if [ "$1" = 0 ]; then
    systemctl stop csghub-runsvdir.service >/dev/null 2>&1 || true

    BACKUP_DIR="~/csghub-$(date +%s)"
    mkdir -p "$BACKUP_DIR"
    if [ -d "/etc/csghub" ]; then
        cp -a /etc/csghub "$BACKUP_DIR"
        echo "CSGHub configuration backed up to: $BACKUP_DIR"
    fi
fi

%postun
#!/bin/sh
if [ "$1" = 0 ]; then
    # Remove systemd service
    rm -f /etc/systemd/system/csghub-runsvdir.service >/dev/null 2>&1 || true
    # Remove symbol links
    find /usr/bin -type l -lname '/opt/csghub/bin/*' -delete >/dev/null 2>&1 || true
    # Remove program main directory
    rm -rf /opt/csghub >/dev/null 2>&1 || true
    # Remove configuration files
    rm -rf /etc/csghub >/dev/null 2>&1 || true
    # Reload systemd daemon
    systemctl daemon-reload >/dev/null 2>&1 || true
    echo "Uninstallation completed at $(date)"
fi

%changelog
* %(date +"%a %b %d %Y") OpenCSG <support@opencsg.com> - 1.6.0-1
- Fixed buildroot contamination
- Optimized library path handling
- Improved build isolation