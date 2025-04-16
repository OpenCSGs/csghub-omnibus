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
sudo yum install -y rpm-build rpmdevtools

# Set up the RPM build tree
rpmdev-setuptree
```

##### 2. Create the package structure

```shell
# clone the repository
git clone git@git-devops.opencsg.com:product/infra/omnibus-csghub.git

# Create directories
mkdir -p ~/rpmbuild/SOURCES/omnibus-csghub-1.6.0/{etc,opt}/csghub

# Copy your files to the appropriate locations
# Assuming you have your files in /path/to/your/files
cp -r omnibus-csghub/etc/csghub/* ~/rpmbuild/SOURCES/omnibus-csghub-1.6.0/etc/csghub/
cp -r omnibus-csghub/opt/csghub/* ~/rpmbuild/SOURCES/omnibus-csghub-1.6.0/opt/csghub/
rm -rf ~/rpmbuild/SOURCES/omnibus-csghub-1.6.0/opt/csghub/embedded/{python,sv/{postgresql,patroni}/{bin,lib,include,share}}

# Copy systemd service file if you have one
cp omnibus-csghub/etc/systemd ~/rpmbuild/SOURCES/omnibus-csghub-1.6.0/etc/

# Create tarball
cd ~/rpmbuild/SOURCES
tar -czvf omnibus-csghub-1.6.0.tar.gz omnibus-csghub-1.6.0/
```

##### 3. Download other source package

```shell
cd ~/rpmbuild/SOURCES

export pgsql_version=16.8
export scws_version=1.2.3
export zhparser_version=2.3
export python_version=3.13.2

wget https://ftp.postgresql.org/pub/source/v${pgsql_version}/postgresql-${pgsql_version}.tar.gz
wget http://www.xunsearch.com/scws/down/scws-${scws_version}.tar.bz2
wget https://gh-proxy.com/github.com/amutu/zhparser/archive/refs/tags/v${zhparser_version}.zip
wget https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz
```

##### 4. Copy the spec file

```shell
cp omnibus-csghub/omnibus-csghub.spec ~/rpmbuild/SPECS/omnibus-csghub.spec
```

##### 5. Build the RPM

```shell
# Install building dependencies
yum install -y gcc make bison flex libtool readline-devel zlib-devel openssl-devel libicu-devel libxml2-devel libxslt-devel unzip patchelf chrpath systemd-devel

# Build the RPM package
QA_RPATHS=$(( 0x0001|0x0002 )) rpmbuild --define "debug_package %{nil}" --nodebuginfo -ba ~/rpmbuild/SPECS/omnibus-csghub.spec

# The built RPM will be in:
# ~/rpmbuild/RPMS/x86_64/omnibus-csghub-1.6.0-1.el7.x86_64.rpm (or similar)
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



