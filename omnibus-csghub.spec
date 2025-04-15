Name:           omnibus-csghub
Version:        1.6.0
Release:        1%{?dist}
Summary:        An all-in-one package for deploying and managing CSGHub

License:        Commercial
Vendor:         opencsg
URL:            https://www.opencsg.com
Packager:       opencsg <support@opencsg.com>

Requires:       glibc >= 2.33
Conflicts:      omnibus-csghub = 1.6.0
Obsoletes:      omnibus-csghub <= 1.6.0

%description
An all-in-one package for deploying and managing CSGHub.
Bundles all necessary components, dependencies, and tools, ensuring
quick and reliable installation without complex setup.

%pre
#!/bin/sh

# $1 = install/upgrade
# $2 = version when upgrading

echo "Stopping csghub services..."
if systemctl is-active --quiet csghub-runsvdir.service; then
    echo "Service csghub-runsvdir.service is active, stopping it..."
    systemctl stop csghub-runsvdir.service || true
else
    echo "Service csghub-runsvdir.service is not active."
fi

case "$1" in
  1) # Install
    rm -rf /opt/csghub || true
    ;;
  2) # Upgrade
    echo "Backup configuration files..."
    if [ -e /etc/csghub.bak ]; then
      rm -rf /etc/csghub.bak || true
    fi
    cp -af /etc/csghub /etc/csghub.bak

    echo "Remove executables..."
    if [ -e /opt/csghub ]; then
      rm -rf /opt/csghub || true
    fi
    ;;
esac

exit 0

%post
#!/bin/sh

# $1 = install/upgrade
# $2 = version when upgrading

create_symlinks() {
    src="$1"
    dst="$2"

    if [ -z "$src" ] || [ -z "$dst" ]; then
        echo "Error: Both source and destination directories must be specified" >&2
        return 1
    fi

    if [ ! -d "$src" ]; then
        echo "Warning: Source directory $src does not exist. Skipping symbolic link creation." >&2
        return 2
    fi

    if [ ! -d "$dst" ]; then
        echo "Destination directory $dst doesn't exist, creating it..."
        mkdir -p "$dst" || {
            echo "Error: Failed to create destination directory $dst" >&2
            return 3
        }
    fi

    echo "Creating symbolic links for all files in $src to $dst..."

    count=0
    skipped=0
    errors=0

    for file in "$src"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            link="$dst/$filename"

            if [ -e "$link" ]; then
                if [ -L "$link" ]; then
                    echo "Skipped: Symbolic link already exists - $link -> $(readlink -f "$link")"
                else
                    echo "Warning: Target exists but is not a symbolic link - $link" >&2
                fi
                skipped=$((skipped+1))
                continue
            fi

            if ln -sf "$file" "$link"; then
                echo "Created: $link -> $file"
                count=$((count+1))
            else
                echo "Error: Failed to create symbolic link $link" >&2
                errors=$((errors+1))
            fi
        fi
    done

    echo "Completed: Created $count symbolic links, skipped $skipped, failed $errors"

    if [ $errors -gt 0 ]; then
        return 4
    fi
    return 0
}

case "$1" in
  1) # Install
    create_symlinks "/opt/csghub/bin" "/usr/bin"
    create_symlinks "/opt/csghub/embedded/python/bin" "/opt/csghub/embedded/bin"

    echo "Starting csghub services..."
    systemctl daemon-reload || true
    systemctl start csghub-runsvdir.service || true
    systemctl enable csghub-runsvdir.service || true
    ;;
  2) # Upgrade
    if [ -e /etc/csghub ]; then
      rm -rf /etc/csghub || true
    fi
    mv /etc/csghub.bak /etc/csghub

    create_symlinks "/opt/csghub/bin" "/usr/bin"
    create_symlinks "/opt/csghub/embedded/python/bin" "/opt/csghub/embedded/bin"

    echo "Starting csghub services..."
    systemctl daemon-reload || true
    systemctl start csghub-runsvdir.service || true
    systemctl enable csghub-runsvdir.service || true

    echo "Reconfiguring csghub services..."
    /usr/bin/csghub-ctl reconfigure || true
    ;;
esac

exit 0

%preun
#!/bin/sh

# $1 = 0 (uninstall), 1 (upgrade)

echo "Stopping csghub services..."
if systemctl is-active --quiet csghub-runsvdir.service; then
    echo "Service csghub-runsvdir.service is active, stopping it..."
    systemctl stop csghub-runsvdir.service || true
else
    echo "Service csghub-runsvdir.service is not active."
fi

if [ "$1" -eq 0 ]; then
    systemctl disable csghub-runsvdir.service || true
fi

exit 0

%postun
#!/bin/sh

# $1 = 0 (uninstall), 1 (upgrade)

postrm_cleanup() {
    link_dir="$1"
    source_dir="$2"

    if [ -z "$link_dir" ]; then
        echo "Error: Link directory must be specified" >&2
        return 1
    fi

    if [ ! -d "$link_dir" ]; then
        echo "Warning: Link directory $link_dir does not exist. Nothing to clean up." >&2
        return 2
    fi

    echo "Starting cleanup of symbolic links in $link_dir..."

    removed=0
    skipped=0
    errors=0

    for item in "$link_dir"/*; do
        if [ -L "$item" ]; then
            if [ -n "$source_dir" ]; then
                link_target=$(readlink -f "$item")
                if [ "$link_target" != "$source_dir/*" ]; then
                    echo "Warning: Link $item points outside $source_dir - skipping" >&2
                    skipped=$((skipped+1))
                    continue
                fi
            fi

            if rm "$item"; then
                echo "Removed: $item"
                removed=$((removed+1))
            else
                echo "Error: Failed to remove $item" >&2
                errors=$((errors+1))
            fi
        elif [ -e "$item" ]; then
            echo "Warning: $item is not a symbolic link - skipping" >&2
            skipped=$((skipped+1))
        fi
    done

    if [ -d "$link_dir" ] && [ -z "$(ls -A "$link_dir")" ]; then
        if rmdir "$link_dir"; then
            echo "Removed empty directory: $link_dir"
        else
            echo "Error: Failed to remove directory $link_dir" >&2
            errors=$((errors+1))
        fi
    fi

    echo "Cleanup completed: Removed $removed links, skipped $skipped, errors $errors"

    if [ $errors -gt 0 ]; then
        return 3
    fi
    return 0
}

if [ "$1" -eq 0 ]; then
    echo "Purging all files installed with package..."

    echo "Backup configurations..."
    cp -af /etc/csghub ~/csghub_"$(date +%F_%T)" || true
    rm -rf /etc/csghub /etc/csghub.bak || true

    echo "Remove all links from /usr/bin..."
    postrm_cleanup "/usr/bin" "/opt/csghub/bin"

    echo "Remove the main program directory"
    rm -rf /opt/csghub || true

    echo "Remove csghub systemd service"
    rm -rf /etc/systemd/system/csghub-runsvdir.service || true

    systemctl daemon-reload || true
fi

exit 0

%files
%defattr(-,root,root,-)
%dir /etc/csghub
/etc/csghub/*
%dir /opt/csghub
/opt/csghub/*
%{_unitdir}/csghub-runsvdir.service