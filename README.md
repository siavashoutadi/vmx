# vmx

A powerful wrapper script for libvirt that automates VM creation and management with cloud-init support. It simplifies the process of creating, configuring, and managing KVM virtual machines with cloud-init initialization and optional Ansible provisioning.

## Features

- **VM Lifecycle Management**: Create, list, remove, and SSH into VMs
- **Cloud-Init Integration**: Automatic VM configuration and setup
- **Multiple Distros**: Support for Ubuntu, Debian, and Fedora images
- **Flexible Disk Configuration**: Multiple disks and mount points per VM
- **Ansible Provisioning**: Optional automated provisioning with Ansible playbooks
- **Security Hardening**: Includes security role with SSH hardening, fail2ban, firewall, and auto-updates
- **Bash Completion**: Full command completion support for easy navigation
- **Image Management**: Download and cache cloud images for faster VM creation

---

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/siavashoutadi/vmx.git
cd vmx

# Source the bash completion
source vmx.bashrc

# Run vmx
./vmx --help
```

### Basic VM Creation

```bash
# Create a simple Ubuntu 24.04 VM with 2 CPUs and 2GB RAM
./vmx vm create -n myvm

# Create a Debian 12 VM with 4 CPUs and 8GB RAM
./vmx vm create -n webserver --distro debian --version 12 -c 4 -m 8G

# Create a VM with additional storage disk
./vmx vm create -n storage -d 20G,100G/data
```

---

## Usage

### Command Structure

```
vmx <command> [subcommand] [action] [arguments]
```

The `vmx` script follows a hierarchical command structure:
- **command**: Main operation (e.g., `vm`, `image`, `cloudinit`)
- **subcommand**: Optional nested subcommand
- **action**: The specific operation to perform (e.g., `create`, `list`, `remove`)
- **arguments**: Action-specific options and values

### Available Commands

#### VM Management

**List all VMs:**
```bash
./vmx vm list
```
Lists all created VMs with their status, IP addresses, and other details.

**Create a new VM:**
```bash
./vmx vm create [OPTIONS]

Options:
  -n, --name NAME              VM name (required)
  -c, --cpu CORES              Number of CPU cores (default: 2)
  -m, --memory MEMORY          Memory size (default: 2G)
  -d, --disk DISK_SPEC         Disk specification (default: 10G)
                               Format: ROOT_SIZE[,EXTRA_SIZE/MOUNT_POINT,...]
                               Example: 10G,20G/data,30G/data2
  --distro DISTRO              Linux distribution (default: ubuntu)
  --version VERSION            Distribution version (default: 24.04)
  --username USERNAME          Username for cloud-init (default: distro-specific)
  --ssh-pubkey FILE            SSH public key file (default: ~/.ssh/id_rsa.pub)
  --userdata FILE              Custom cloud-init userdata file
  --metadata FILE              Custom cloud-init metadata file
```

Examples:
```bash
# Create with custom SSH key
./vmx vm create -n dev -c 4 -m 4G --ssh-pubkey /path/to/key.pub

# Create with custom cloud-init files
./vmx vm create -n prod --userdata ./userdata.yaml --metadata ./metadata.yaml

# Create with multiple disks
./vmx vm create -n storage -d 50G,100G/data,50G/backup
```

**Remove a VM:**
```bash
./vmx vm remove -n <vm_name>
```
Removes the specified VM and its associated data.

**SSH into a VM:**
```bash
./vmx vm ssh -n <vm_name>
```
Establishes an SSH connection to the VM.

#### Image Management

**List available images:**
```bash
./vmx image list
```
Shows all cached cloud images.

**Download a cloud image:**
```bash
./vmx image download --distro <DISTRO> --version <VERSION>

Supported Images:
  ubuntu: 20.04, 22.04, 24.04
  debian: 11, 12
  fedora: 38, 39, 40
```

Examples:
```bash
./vmx image download --distro ubuntu --version 24.04
./vmx image download --distro debian --version 12
./vmx image download --distro fedora --version 40
```

Images are cached in `${VMX_IMAGES_DIR}` (default: `/var/lib/libvirt/images/vmx`) for reuse across VMs.

**Remove an image:**
```bash
./vmx image remove --distro <DISTRO> --version <VERSION>
```

#### Cloud-Init Configuration

**Create cloud-init files:**
```bash
./vmx cloudinit create [OPTIONS]

Options:
  -n, --name NAME              VM name (required)
  -u, --username USERNAME      Username for cloud-init (default: vmx)
  -k, --ssh-pubkey KEY         SSH public key (required)
  -p, --packages PKGS          Comma-separated packages to install
  --ansible-url URL            Ansible playbook repository URL
  --playbook PLAYBOOK          Playbook filename to run (e.g., ansible/playbook.yaml)
```

Examples:
```bash
# Basic cloud-init setup
./vmx cloudinit create -n myvm -k ~/.ssh/id_rsa.pub

# With custom username and packages
./vmx cloudinit create -n dev -u ubuntu -k ~/.ssh/id_rsa.pub -p "git,curl,build-essential"

# With Ansible provisioning
./vmx cloudinit create -n prod -k ~/.ssh/id_rsa.pub --ansible-url https://github.com/siavashoutadi/vmx.git --playbook ansible/playbook.yaml
```

**Show cloud-init configuration:**
```bash
./vmx cloudinit show -n <vm_name>
```
Displays the generated cloud-init configuration for a VM.

---

## Bash Completion

### Installation

Add the following to your `~/.bashrc`:

```bash
source /path/to/vmx/vmx.bashrc
```

Or install system-wide:

```bash
sudo cp vmx.bashrc /etc/bash_completion.d/vmx
```

### How It Works

The bash completion script (`vmx.bashrc`) provides intelligent command suggestions through these mechanisms:

1. **Directory Search**: Searches upward from the current working directory for the `.vmx` command directory, allowing `vmx` to work from any subdirectory within the project.

2. **Fallback Location**: If no `.vmx` directory is found in parent directories, it checks `/opt/vmx` for system-wide installations.

3. **Hierarchical Discovery**: Navigates through the command hierarchy, suggesting:
   - Subdirectories as subcommands
   - Executable files as actions
   - Automatically filters library files (starting with `_`)

4. **Context-Aware Suggestions**: Based on the current command path, provides only relevant suggestions.

### Usage Examples

```bash
# Show main commands
./vmx [TAB]
# Suggests: vm, image, cloudinit

# Show VM subcommands
./vmx vm [TAB]
# Suggests: create, list, remove, ssh

# Show create options (if implemented)
./vmx vm create [TAB]
# Suggests: available options

# Show image operations
./vmx image [TAB]
# Suggests: download, list, remove
```

---

## Ansible Provisioning

### Overview

VMX includes a comprehensive security hardening Ansible role that can be automatically applied during VM creation via cloud-init.

### Architecture

```
ansible/
├── playbook.yaml              # Main playbook
└── roles/
    └── security/              # Security hardening role
        ├── defaults/main.yaml # Default variables
        ├── handlers/main.yaml # Service restart handlers
        ├── tasks/
        │   ├── main.yaml      # Task orchestration
        │   ├── debian.yaml    # Debian/Ubuntu specific
        │   ├── redhat.yaml    # RedHat/Fedora specific
        │   ├── ssh.yaml       # SSH hardening
        │   ├── fail2ban.yaml  # Intrusion prevention
        │   ├── services.yaml  # Service management
        │   └── logging.yaml   # System logging
        └── vars/main.yaml     # Role variables
```

### Cloud-Init Integration

When creating a VM, cloud-init can optionally:
1. Clone the VMX repository
2. Install Ansible
3. Run the security hardening playbook on the new VM

```bash
# Create VM with default cloud-init (no Ansible)
./vmx vm create -n basic

# Create VM and manually run Ansible later
./vmx vm create -n prod -c 4 -m 8G
./vmx vm ssh -n prod
# Then run: ansible-playbook ansible/playbook.yaml
```

### Security Hardening Role

The `security` role implements comprehensive hardening:

#### **1. OS-Specific Package Installation**
- **Debian/Ubuntu**: UFW firewall, fail2ban, unattended-upgrades
- **RedHat/Fedora**: firewalld, fail2ban, dnf-automatic

Detected via `ansible_os_family` for automatic OS adaptation.

#### **2. SSH Hardening** (`tasks/ssh.yaml`)

Default security settings applied to `/etc/ssh/sshd_config`:

| Setting | Default | Purpose |
|---------|---------|---------|
| PermitRootLogin | no | Disable root login |
| PasswordAuthentication | no | SSH key-only auth |
| PubkeyAuthentication | yes | Enable public key auth |
| X11Forwarding | no | Disable X11 |
| MaxAuthTries | 3 | Limit auth attempts |
| ClientAliveInterval | 300 | 5-minute idle timeout |

File permissions: `0600` (root only)

#### **3. Intrusion Prevention with fail2ban** (`tasks/fail2ban.yaml`)

Default settings:
- **bantime**: 3600 seconds (1 hour)
- **findtime**: 600 seconds (10-minute window)
- **maxretry**: 5 failed attempts
- **sshd_maxretry**: 3 failed attempts (stricter)

Bans IP addresses after too many failed login attempts.

#### **4. Firewall Configuration**

- **Debian**: UFW firewall with default deny incoming, SSH (port 22) allowed
- **RedHat**: firewalld with SSH service enabled

Protects VM from unwanted incoming connections.

#### **5. Automatic Security Updates** (`tasks/debian.yaml` / `redhat.yaml`)

- **Debian**: Unattended-upgrades with auto-reboot disabled
- **RedHat**: dnf-automatic with security updates

Keeps system security patches up-to-date automatically.

#### **6. System Logging** (`tasks/logging.yaml`)

- Configures rsyslog file creation mode for proper log retention
- Default: `0640` umask (root/adm readable)

#### **7. Service Management** (`tasks/services.yaml`)

- Optionally disables unnecessary services
- Customizable via `unnecessary_services` variable

### Configuration & Customization

#### Default Variables (`defaults/main.yaml`)

All settings have sensible defaults. Override by:

1. **Creating a variables file:**
```yaml
# custom_vars.yaml
ssh_permit_root_login: no
ssh_max_auth_tries: 5
fail2ban_bantime: 7200
firewall_enabled: yes
auto_updates_enabled: yes
```

2. **Running with extra variables:**
```bash
ansible-playbook ansible/playbook.yaml -e @custom_vars.yaml
```

3. **Via command-line:**
```bash
ansible-playbook ansible/playbook.yaml \
  -e ssh_max_auth_tries=10 \
  -e fail2ban_bantime=7200
```

#### Task Tags

Run specific hardening features:

```bash
# SSH hardening only
ansible-playbook ansible/playbook.yaml --tags ssh

# Firewall only
ansible-playbook ansible/playbook.yaml --tags firewall

# fail2ban only
ansible-playbook ansible/playbook.yaml --tags fail2ban

# All security updates
ansible-playbook ansible/playbook.yaml --tags security,packages,updates
```

---

## Design Decisions

### 1. **Hierarchical Command Structure**

The `.vmx` directory structure mirrors the command hierarchy, enabling extensibility without core script changes:

```
.vmx/
├── vm/
│   ├── create      (executable)
│   ├── list        (executable)
│   ├── remove      (executable)
│   └── ssh         (executable)
├── image/
│   ├── download    (executable)
│   ├── list        (executable)
│   ├── remove      (executable)
│   ├── _lib        (library, not exposed)
│   └── images.conf (config file)
└── cloudinit/
    ├── create      (executable)
    ├── show        (executable)
    └── _lib        (library, not exposed)
```

**Benefits:**
- **Extensible**: Add new commands by creating new directories/files
- **Isolated**: Each command is a separate script with clear responsibility
- **Self-Documenting**: Directory structure shows available operations
- **Bash Completion**: Auto-discovers commands from directory structure
- **Maintainable**: No monolithic command file; logic is distributed

### 2. **Two-Stage Provisioning Architecture**

**Cloud-Init (Fast, Initial)**:
- Runs once at first boot
- Lightweight and built into cloud images
- SSH key injection, users, packages, scripts
- No agent required

**Ansible (Flexible, Ongoing)**:
- Runs after cloud-init
- Can run multiple times on existing VMs
- Complex configurations and updates
- Idempotent operations

**Why This Design:**
- Cloud-init is fast and reliable for one-time setup
- Ansible is powerful for configuration management
- Separation of concerns: initialization vs. hardening
- Flexibility to apply hardening selectively

### 3. **Copy-on-Write (CoW) Disk Images**

VMs use qcow2 overlays on base images:

```bash
# Base image (shared)
/var/lib/libvirt/images/vmx/ubuntu/24.04/image.qcow2 (1.5 GB)

# Per-VM overlay (CoW)
/var/lib/libvirt/instances/vmx/myvm/root.qcow2 (small, only changes)
```

**Benefits:**
- **Disk Efficiency**: Only changes stored, base image shared
- **Fast Creation**: No copying; overlay created instantly
- **Simple Cleanup**: Delete overlay, base remains for other VMs
- **Performance**: Minimal I/O overhead

**Trade-off**: If base image is deleted, overlays become corrupted (managed via image removal).

### 4. **Flexible Disk Specification**

Disk format supports complex storage layouts in a single parameter:

```
Format: ROOT_SIZE[,EXTRA_SIZE/MOUNT_POINT,...]

Examples:
-d 10G              # Root only
-d 10G,20G/data     # Root + data disk
-d 10G,20G/data,30G/backup  # Multiple disks
```

**Benefits:**
- Single parameter handles multiple disks
- Mount points specified declaratively
- Cloud-init can auto-format and mount disks
- No manual partitioning needed
- Easy to express complex storage needs

### 5. **Bash Completion Discovery Algorithm**

Completion searches upward from current directory, enabling use from anywhere:

```bash
# Works from project root
~/vmx$ ./vmx vm [TAB]

# Works from project subdirectory
~/vmx/ansible$ ./vmx vm [TAB]

# Works from unrelated directory (finds in parent)
~/my-project$ vmx vm [TAB]  # Finds ~/vmx/.vmx
```

**Algorithm:**
1. Start from `$PWD`
2. Search upward for `.vmx` directory
3. Stop at filesystem root
4. Fallback to `/opt/vmx` if found
5. Return if found, else no completion

**Why Upward Search:**
- Works from project subdirectories
- Allows multiple projects with separate `.vmx` directories
- No system-wide installation needed (but supported)

### 6. **libvirt-qemu User Ownership**

VM data is owned by `libvirt-qemu` user:

```bash
sudo -u libvirt-qemu mkdir -p "${instance_dir}"
sudo -u libvirt-qemu qemu-img create ...
```

**Security Model:**
- VMs run as `libvirt-qemu` user by default
- Files owned by same user = proper permissions
- Root script can delegate operations safely
- Aligns with libvirt architecture
- Prevents privilege escalation

**Alternative**: Could use root-owned files, but then VMs would need `libvirt-qemu` group access.

### 7. **Environment-Based Configuration**

Key paths configurable via environment variables with sensible defaults:

```bash
VMX_IMAGES_DIR=${VMX_IMAGES_DIR:-/var/lib/libvirt/images/vmx}
VMX_CLOUDINIT_DIR=${VMX_CLOUDINIT_DIR:-/var/lib/libvirt/cloudinit/vmx}
VMX_INSTANCES_DIR=${VMX_INSTANCES_DIR:-/var/lib/libvirt/instances/vmx}
```

**Benefits:**
- Override defaults without code changes
- Support multiple storage locations
- Facilitate testing and development
- Documentation via default values

**Usage:**
```bash
export VMX_IMAGES_DIR=/fast-ssd/vmx/images
./vmx vm create -n myvm
```

### 8. **Ansible Role Best Practices**

Security role follows Ansible conventions:

- **defaults/**: Default variables (lowest precedence)
- **vars/**: Role-specific variables (higher precedence)
- **tasks/**: Operations to perform
- **handlers/**: Service restarts (triggered by tasks)
- **OS-Specific**: Separate Debian/RedHat task files

**Idempotency:**
- All tasks can run multiple times safely
- `lineinfile` for config management
- `systemd` for service state (safe re-runs)
- No side effects from re-execution

**Tagging:**
- Each task tagged for selective execution
- Example: `--tags ssh` runs only SSH hardening

---

## Environment Variables

Control default paths and behavior:

```bash
# Base image cache location (default: /var/lib/libvirt/images/vmx)
export VMX_IMAGES_DIR=/custom/images/path

# Cloud-init configuration location (default: /var/lib/libvirt/cloudinit/vmx)
export VMX_CLOUDINIT_DIR=/custom/cloudinit/path

# VM instance data location (default: /var/lib/libvirt/instances/vmx)
export VMX_INSTANCES_DIR=/custom/instances/path
```

---

## License

MIT License - see LICENSE file for details
