#!/usr/bin/env sh

# Reload script for Docker containers when installing SSL certificate
# with ACME shell script (acme.sh).
# Copyright (C) 2019 Patrik Wyde <patrik@wyde.se>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

print_help() {
echo "
Description:
  Script used as '--reloadcmd' when installing SSL certificates for Docker
  containers with ACME shell script (acme.sh). For more information, see
  https://github.com/Neilpang/acme.sh#3-install-the-cert-to-apachenginx-etc

  Script will copy the SSL certificate and private key files to a specified
  destination path used for persistent container storage and restarts the
  Docker container.

  Owner of the SSL certificate and private key file can also be changed if
  needed.

Examples:
  ${0} --cert-file /etc/acme/cert.pem --key-file /etc/acme/cert.key --destination /var/lib/docker/volumes/app/_data/cert --container webapp

  ${0} --cert-file /etc/acme/cert.pem --key-file /etc/acme/cert.key --new-cert-file /srv/docker/webapp/ssl/webapp.pem --new-key-file /srv/docker/webapp/ssl/webapp.key --container webapp

  ${0} --cert-file /etc/acme/cert.pem --key-file /etc/acme/cert.key --destination /var/lib/docker/volumes/app/_data/cert --container webapp --ch-own john:users

Example usage together with acme.sh:
  acme.sh --installcert -d domain.tld --cert-file /etc/acme/cert.pem --key-file /etc/acme/cert.key --reloadcmd '""${0}" --cert-file /etc/acme/cert.pem --key-file /etc/acme/cert.key --destination /var/lib/docker/volumes/app/_data/cert --container webapp"'

Options:
  -s, --cert-file      SSL certificate file to be copied to the persistent
                       container storage.

  -S, --new-cert-file  Name of SSL certificate copy and destination path to
                       the persistent container storage. Cannot be used
                       together with the '--destination' option.

  -k, --key-file       Private key file to be copied to the persistent
                       container storage.

  -K, --new-key-file   Name of private key copy and destination path to the
                       persistent container storage. Cannot be used together
                       with the '--destination' option.

  -d, --destination    Destination path to the persistent container storage.
                       Cannot be used together with '--new-cert-file' or the
                       '--new-key-file' options.

  -c, --container      Docker container name to be restarted.

  -o, --ch-own         Change owner of the SSL certificate and private key
                       files.
" >&2
}

# Print help if no argument is specified.
if [ "${#}" -le 0 ]; then
    print_help
    exit 1
fi

# Loop as long as there is at least one more argument.
while [ "${#}" -gt 0 ]; do
    arg="${1}"
    case "${arg}" in
        # This is an arg value type option. Will catch both '-s' or
        # '--cert-file' value.
        -s|--cert-file) shift; cert="${1}" ;;
        # This is an arg value type option. Will catch both '-S' or
        # '--new-cert-file' value.
        -S|--new-cert-file) shift; new_cert="${1}" ;;
        # This is an arg value type option. Will catch both '-k' or
        # '--key-file' value.
        -k|--key-file) shift; key="${1}" ;;
        # This is an arg value type option. Will catch both '-K' or
        # '--new-key-file' value.
        -K|--new-key-file) shift; new_key="${1}" ;;
        # This is an arg value type option. Will catch both '-d' or
        # '--destination' value.
        -d|--destination) shift; destination="${1}" ;;
        # This is an arg value type option. Will catch both '-c' or
        # '--container' value.
        -c|--container) shift; container="${1}" ;;
        # This is an arg value type option. Will catch both '-o' or
        # '--ch-own' value.
        -o|--ch-own) shift; owner="${1}" ;;
        # This is an arg value type option. Will catch both '-h' or
        # '--help' value.
        -h|--help) print_help; exit ;;
        *) echo "Invalid option '${arg}'." >&2; print_help; exit 1 ;;
    esac
    # Shift after checking all the cases to get the next option.
    shift > /dev/null 2>&1;
done

print_msg() {
    echo "=>" "${@}" >&1
}

# Verify that all mandatory script options are specified.
validate_options() {
    if [ -z "${cert}" ]; then
        echo "No SSL certificate specified!" >&2
        print_help
        exit 1
    fi
    if [ -z "${key}" ]; then
        echo "No private key specified!" >&2
        print_help
        exit 1
    fi
    if [ -z "${destination}" ]; then
        if [ -z "${new_cert}" ] || [ -z "${new_key}" ]; then
            echo "No destination for SSL certificate and/or private key specified!" >&2
            print_help
            exit 1
        fi
    fi
    if [ "${destination}" ]; then
        if [ "${new_cert}" ] || [ "${new_key}" ]; then
            echo "Invalid use of options! '--destination' cannot be used together with '--new-cert-file' or '--new-key-file'." >&2
            print_help
            exit 1
        fi
    fi

    if [ -z "${container}" ]; then
        echo "No Docker container specified to restart!" >&2
        print_help
        exit 1
    fi
}

copy_files() {
    if [ ! -d "${destination}" ]; then
        echo "Destination directory does not exist!" >&2
        exit 1
    else
        # Remove trailing slash in destination if it exists.
        case "${destination}" in
            */) destination="${destination%?}" ;;
        esac
        if cp "${cert}" "${destination}"; then
            # Removes directory path in string if it exists.
            cert="${cert##*/}"
            print_msg "Successfully copied SSL certificate to '$destination/$cert'."
        else
            echo "Unable to copy SSL certificate!" >&2
            exit 1
        fi
        if cp "${key}" "${destination}"; then
            # Removes directory path in string if it exists.
            key="${key##*/}"
            print_msg "Successfully copied private key to '$destination/$key'."
        else
            echo "Unable to copy private key!" >&2
            exit 1
        fi
    fi
}

copy_new_files() {
    if cp "${cert}" "${new_cert}"; then
        print_msg "Successfully copied SSL certificate to '$new_cert'."
    else
        echo "Unable to copy SSL certificate!" >&2
        exit 1
    fi
    if cp "${key}" "${new_key}"; then
        print_msg "Successfully copied private key to '$new_key'."
    else
        echo "Unable to copy private key!" >&2
        exit 1
    fi
}

restart_container() {
    if /usr/bin/docker restart "${container}"; then
        print_msg "Restarted Docker container '$container'."
    else
        echo "Unable to restart Docker container!" >&2
        exit 1
    fi
}

change_owner() {
    if [ -n "${owner}" ]; then
        if chown "${owner}" "${destination}"/"${cert}"; then
            print_msg "Changed owner to '$owner' on SSL certificate file."
        else
            echo "Unable to change owner of SSL certificate file!" >&2
        fi
        if chown "${owner}" "${destination}"/"${key}"; then
            print_msg "Changed owner to '$owner' on private key file."
        else
            echo "Unable to change owner of private key file!" >&2
        fi
    fi
}

validate_options
if [ "${destination}" ]; then
    copy_files
else
    copy_new_files
fi
change_owner
restart_container
