# How to build DEB/RPM packages locally

## Summary

This document is only used to guide users on how to build deb/rpm packages and container images.

## Build method

### Linux

#### DEB

_Tips: There is currently no need to distinguish between Debian distributions_

```shell
git clone git@git-devops.opencsg.com:product/infra/omnibus-csghub.git
cd omnibus-csghub && rm -rf .git* .idea Dockerfile *.md *.spec
cd .. 
dpkg-deb -Z xz -b omnibus-csghub omnibus-csghub_1.6.0-ee.0_amd64.deb
```

#### RPM

##### 1. Prepare the build environment

```shell
# Install required tools
dnf install -y rpm-build rpmdevtools dnf-plugins-core openssh-clients

# Install building dependencies
dnf install -y gcc make bison flex libtool readline-devel zlib-devel openssl-devel libicu-devel libxml2-devel libxslt-devel unzip patchelf chrpath systemd-devel

# or
# Install build dependencies
# yum-builddep ~/rpmbuild/SPECS/omnibus-csghub.spec

# Set up the RPM build tree
rpmdev-setuptree
```

##### 2. Create the package structure

```shell
# clone the repository
git clone git@git-devops.opencsg.com:product/infra/omnibus-csghub.git

# Copy your files to the appropriate locations
mkdir -p omnibus-csghub-1.6.0 && cp -a omnibus-csghub/{etc,opt} omnibus-csghub-1.6.0
rm -rf omnibus-csghub-1.6.0/opt/csghub/embedded/{python,sv/{postgresql,patroni}/{bin,lib,include,share}}

# Create source code packages
tar -zcf ~/rpmbuild/SOURCES/omnibus-csghub-1.6.0.tar.gz omnibus-csghub-1.6.0
```

##### 3. Download other source package

```shell
export pgsql_version=16.8
export scws_version=1.2.3
export zhparser_version=2.3
export python_version=3.13.2

wget -O ~/rpmbuild/SOURCES/postgresql-${pgsql_version}.tar.gz https://ftp.postgresql.org/pub/source/v${pgsql_version}/postgresql-${pgsql_version}.tar.gz
wget -O ~/rpmbuild/SOURCES/scws-${scws_version}.tar.bz2 http://www.xunsearch.com/scws/down/scws-${scws_version}.tar.bz2
wget -O ~/rpmbuild/SOURCES/v${zhparser_version}.zip https://gh-proxy.com/github.com/amutu/zhparser/archive/refs/tags/v${zhparser_version}.zip
wget -O ~/rpmbuild/SOURCES/Python-${python_version}.tgz https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz
```

##### 4. Copy the spec file

```shell
cp omnibus-csghub/omnibus-csghub.spec ~/rpmbuild/SPECS/omnibus-csghub.spec
```

##### 5. Build the RPM

```shell
# Using en locale
export LANG="" 
# Ignore rpath check error
export QA_RPATHS=$(( 0x0001|0x0002 )) 
# Build the RPM package
rpmbuild -ba --define 'dist .oe2203sp4' ~/rpmbuild/SPECS/omnibus-csghub.spec

# The built RPM will be in:
# ~/rpmbuild/RPMS/x86_64/omnibus-csghub-1.6.0-1.oe2203sp4.x86_64.rpm (or similar)
```

##### 6. Verification

```shell
# Check the package contents
rpm -qlp ~/rpmbuild/RPMS/x86_64/omnibus-csghub-*.rpm
rpm -qlp ~/rpmbuild/SRPMS/omnibus-csghub-*.src.rpm

# Check the package metadata
rpm -qip ~/rpmbuild/RPMS/x86_64/omnibus-csghub-*.rpm
rpm -qip ~/rpmbuild/SRPMS/omnibus-csghub-*.src.rpm
```

#### RPM (Build from source package)

##### Auto re-build from src package

```shell
# Install required tools
dnf install -y rpm-build rpmdevtools dnf-plugins-core openssh-clients

# Install build dependencies
dnf install -y gcc make bison flex libicu-devel libtool libxml2-devel libxslt-devel openssl-devel readline-devel systemd-devel zlib-devel chrpath

# Rebuild from source code package
rpmbuild --rebuild --define 'dist .oe2109' ~/omnibus-csghub-1.6.0-1.src.rpm
```

##### Manual re-build from src package

###### 1. Prepare the build environment

```shell
# Install required tools
dnf install -y rpm-build rpmdevtools dnf-plugins-core

# Set up the RPM build tree
rpmdev-setuptree
```

###### 2. Install src packages

```shell
rpm -ivh omnibus-csghub-1.6.0-1.src.rpm
```

###### 3. Verify build tree

```shell
tree rpmbuild/

rpmbuild/
|-- BUILD
|-- RPMS
|-- SOURCES
|   |-- Python-3.13.2.tgz
|   |-- omnibus-csghub-1.6.0.tar.gz
|   |-- postgresql-16.8.tar.gz
|   |-- scws-1.2.3.tar.bz2
|   `-- v2.3.zip
|-- SPECS
|   `-- omnibus-csghub.spec
`-- SRPMS
```

###### 4. Install build dependencies

```shell
# Install build dependencies
dnf install gcc make bison flex libicu-devel libtool libxml2-devel libxslt-devel openssl-devel readline-devel systemd-devel zlib-devel chrpath

# If patchelf cannot be installed automatically
# CentOS 7
dnf install -y https://rpmfind.net/linux/openmandriva/5.0/repository/x86_64/unsupported/release/patchelf-0.11-1-omv4002.x86_64.rpm
# CentOS 8
dnf install -y https://rpmfind.net/linux/epel/8/Everything/x86_64/Packages/p/patchelf-0.12-1.el8.x86_64.rpm
```

###### 5. Rebuild package

```shell
# Build all
rpmbuild -ba ~/rpmbuild/SPECS/omnibus-csghub.spec

# Debugging
# Unzip the source code and prepare the build environment
rpmbuild -bp ~/rpmbuild/SPECS/omnibus-csghub.spec
# Compile
rpmbuild -bc ~/rpmbuild/SPECS/omnibus-csghub.spec
# Install to virtual root directory
rpmbuild -bi ~/rpmbuild/SPECS/omnibus-csghub.spec
# Generate RPM packages only
rpmbuild -bb ~/rpmbuild/SPECS/omnibus-csghub.spec
```

#### Key Differences from Debian to RPM

1. **Spec File Structure**: RPM uses a single `.spec` file instead of multiple control files
2. **Script Sections**:
    - `%pre` replaces `preinst`
    - `%post` replaces `postinst`
    - `%preun` replaces `prerm`
    - `%postun` replaces `postrm`
3. **File Ownership**: RPM uses `%defattr` and `%attr` macros for file permissions
4. **Dependencies**:
    - `Requires` replaces `Depends`
    - `Obsoletes` replaces `Replaces`
5. **Version Comparison**: RPM handles version comparisons internally, no need for dpkg checks



