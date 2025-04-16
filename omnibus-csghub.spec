Name:           omnibus-csghub
Version:        1.6.0
Release:        1%{?dist}
Summary:        All-in-one package for deploying and managing CSGHub

License:        Commercial
Vendor:         opencsg
URL:            https://www.opencsg.com
Packager:       opencsg <support@opencsg.com>

Requires:       glibc >= 2.33
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
cd %{_builddir}/postgresql-%{pgsql_version}
./configure --prefix=%{pg_home} \
    --with-openssl \
    --with-icu \
    --with-readline \
    --with-libxml \
    --with-libxslt
make %{?_smp_mflags} world

# Compile scws
cd %{_builddir}/scws-%{scws_version}
./configure --prefix=%{scws_home} \
    --disable-shared \
    --enable-static
make %{?_smp_mflags}

# Compile zhparser
cd %{_builddir}/zhparser-%{zhparser_version}
export SCWS_HOME=%{_builddir}/%{name}-%{version}/opt/csghub/embedded
export PG_CONFIG=%{_builddir}/postgresql-%{pgsql_version}/src/bin/pg_config/pg_config
make %{?_smp_mflags}

# Compile python
cd %{_builddir}/Python-%{python_version}
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
cd %{_builddir}/postgresql-%{pgsql_version}
make install-world DESTDIR=%{buildroot}

# Install scws
cd %{_builddir}/scws-%{scws_version}
make install DESTDIR=%{buildroot}
libtool --finish %{buildroot}/opt/csghub/embedded/lib

# Install zhparser
export SCWS_HOME=%{scws_home}
export PG_CONFIG=%{buildroot}%{pg_home}/bin/pg_config
cd %{_builddir}/zhparser-%{zhparser_version}
make install

# Install python
cd %{_builddir}/Python-%{python_version}
make altinstall DESTDIR=%{buildroot}

# Install patroni
export PYTHONHOME=%{buildroot}/opt/csghub/embedded/python
export PYTHONPATH=/opt/csghub/embedded/sv:$PYTHONPATH
export PGHOME=%{buildroot}/opt/csghub/embedded/sv/postgresql
export PATH=$PYTHONHOME/bin:$PGHOME/bin:$PATH
export LD_LIBRARY_PATH=$PYTHONHOME/lib:$PGHOME/lib:$LD_LIBRARY_PATH
python3.13 -m pip install --no-cache-dir \
    --prefix=/opt/csghub/embedded/sv/patroni patroni[consul] psycopg2-binary

# Fix path references
find %{buildroot} -type f -name "*.so" -exec chmod 755 {} \;
find %{buildroot} -type f -name "*.so" -exec patchelf --remove-rpath {} \; 2>/dev/null || true
find %{buildroot} -type f -name "*.so" -exec patchelf --set-rpath '$ORIGIN/../lib:%{scws_home}/lib:%{pg_home}/lib:%{python_home}/lib:/lib:/lib64:/usr/lib:/usr/lib64:/usr/local/lib:/usr/local/lib64' {} \; 2>/dev/null || true

# Clean up temporary paths
find %{buildroot} -type f \( -name "*.py" -o -name "Makefile" \) \
  -exec sed -i '/BUILDROOT\|LD_LIBRARY_PATH/d' {} \;

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
for binfile in /opt/csghub/embedded/bin/*; do
    [ -f "$binfile" ] && ln -sf "$binfile" /usr/bin/ 2>/dev/null || true
done

systemctl daemon-reload >/dev/null 2>&1 || true
systemctl enable csghub-runsvdir.service >/dev/null 2>&1 || true
if [ "$1" -ge 1 ]; then
    systemctl restart csghub-runsvdir.service >/dev/null 2>&1 || true
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
    find /usr/bin -type l -lname '/opt/csghub/bin/*' -delete
    # Remove program main directory
    rm -rf /opt/csghub
    # Remove configuration files
    rm -rf /etc/csghub
    # Reload systemd daemon
    systemctl daemon-reload >/dev/null 2>&1 || true
    echo "Uninstallation completed at $(date)"
fi

%changelog
* %(date +"%a %b %d %Y") OpenCSG <support@opencsg.com> - 1.6.0-1
- Fixed buildroot contamination
- Optimized library path handling
- Improved build isolation