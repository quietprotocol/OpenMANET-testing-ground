# opentakserver

Deploys OpenTAKServer Docker Compose configuration. Based on https://github.com/milsimdk/ots-docker

## Tasks

- Creates OpenTAKServer directory
- Backs up existing `compose.yaml` if present
- Copies `compose.yaml` configuration
- Verifies deployment

## Variables

Variables are defined in `defaults/main.yml`:

- `opentakserver_dir`: OpenTAKServer directory (default: `~/ots-docker`)
- `compose_backup`: Whether to backup existing compose.yaml (default: `true`)

Override these in `group_vars/all.yml` or `host_vars/<hostname>.yml` if needed.

## Usage

```bash
ansible-playbook playbooks/site.yml --tags ots
```

## Notes

After deployment, you need to run `make up` or `docker compose up -d` on the device.
