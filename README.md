# acme-reloadcmd-docker

## Description
Script used as `--reloadcmd` when installing SSL certificates for Docker containers with [ACME shell script](https://github.com/Neilpang/acme.sh) (acme.sh). For more information, see the [certificate installation instructions](https://github.com/Neilpang/acme.sh#3-install-the-cert-to-apachenginx-etc) on acme.sh GitHub [page](https://github.com/Neilpang/acme.sh).

When executed the script will copy the specified SSL certificate and private key files to a specified destination path, which is used for persistent container storage. The Docker container will then be restarted to apply/read the new certificate and key.

Owner of the SSL certificate and private key file can also be changed if needed. See the `--ch-own` [option](README.md#options) and [example](README.md#examples) below.

## Options
| **Option** | **Description** |
| --- | --- |
| `-s`, `--cert-file`     | SSL certificate file to be copied to the persistent container storage. |
| `-S`, `--new-cert-file` | Name of SSL certificate copy and destination path to the persistent container storage. Cannot be used together with the '--destination' option. |
| `-k`, `--key-file`      | Private key file to be copied to the persistent container storage.     |
| `-K`, `--new-key-file`  | Name of private key copy and destination path to the persistent container storage. Cannot be used together with the '--destination' option.     |
| `-d`, `--destination`   | Destination path to the persistent container storage. Cannot be used together with '--new-cert-file' or the '--new-key-file' options.           |
| `-c`, `--container`     | Docker container name to be restarted.                                 |
| `-o`, `--ch-own`        | Change owner of the SSL certificate and private key files.             |

## Examples
Copy SSL certificate `/etc/acme/cert.pem` and private key `/etc/acme/cert.key` to the `/var/lib/docker/volumes/app/_data/cert` directory. Restart Docker container named `webapp`.

```
# sh acme-reloadcmd-docker.sh --cert-file /etc/acme/cert.pem --key-file /etc/acme/cert.key --destination /var/lib/docker/volumes/app/_data/cert --container webapp
```

Copy SSL certificate `/etc/acme/cert.pem` and private key `/etc/acme/cert.key` to the `/srv/docker/webapp/ssl` directory and rename to `webapp.pem` and `webapp.key`. Restart Docker container named `webapp`.

```
# sh acme-reloadcmd-docker.sh --cert-file /etc/acme/cert.pem --key-file /etc/acme/cert.key --new-cert-file /srv/docker/webapp/ssl/webapp.pem --new-key-file /srv/docker/webapp/ssl/webapp.key --container webapp
```

Copy SSL certificate `/etc/acme/cert.pem` and private key `/etc/acme/cert.key` to the `/var/lib/docker/volumes/app/_data/cert` directory. Change owner of the copied certificate and key files to `john:users`. Restart Docker container named `webapp`.

```
# sh acme-reloadcmd-docker.sh --cert-file /etc/acme/cert.pem --key-file /etc/acme/cert.key --destination /var/lib/docker/volumes/app/_data/cert --container webapp --ch-own john:users
```

### Example usage together with acme.sh
Script executed using the `--reloadcmd` option  with `acme.sh`. Example below will install the SSL certificate and private key file to the `/etc/acme` directory. `acme-reloadcmd-docker.sh` will then copy the certificate and key files to `/var/lib/docker/volumes/app/_data/cert` and restart the Docker container named `webapp`.

```
# acme.sh --installcert -d domain.tld --cert-file /etc/acme/cert.pem --key-file /etc/acme/cert.key --reloadcmd "sh acme-reloadcmd-docker.sh --cert-file /etc/acme/cert.pem --key-file /etc/acme/cert.key --destination /var/lib/docker/volumes/app/_data/cert --container webapp"
```

## Disclaimer
Script was created as a quick solution to achieve this specific functionality. The official [Docker image](https://github.com/Neilpang/acme.sh/wiki/Run-acme.sh-in-docker) of **acme.sh** can probably be used instead to acomplish the same goal.

## License
This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more information.
