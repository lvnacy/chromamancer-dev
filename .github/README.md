# Chromamancer Development Container

A security-hardened, minimal Debian Trixie-based Docker image for Node.js CLI tool development, created for use in the development of [Chromamancer](https://github.com/lvnacy/chromamancer). Built with Volta for Node.js version management and includes essential development tools while removing unnecessary system components to minimize attack surface.

## Features

### Core Technology Stack
- **Base OS**: Debian Trixie Slim
- **Node.js Management**: [Volta](https://volta.sh/) - Fast, reliable Node.js version manager
- **Node.js**: Version 20 (LTS)
- **Package Manager**: pnpm (latest)
- **User**: Non-root `node` user (UID 1000, GID 1000)

### Development Tools
- **bat**: Modern `cat` replacement with syntax highlighting
- **diff-so-fancy**: Enhanced diff output formatting
- **jq**: Command-line JSON processor
- **ripgrep**: Ultra-fast recursive search tool
- **eza**: Modern replacement for `ls` (maintained fork of `exa`)

### Security Hardening
- Two-stage build process to eliminate build dependencies
- Complete removal of package managers (`apt`, `dpkg`) from runtime image
- Removal of network tools (`curl`, `wget`)
- Removal of scripting interpreters (`perl`)
- Removal of user management utilities
- Minimal runtime dependencies only
- Non-root user operation
- Cleaned logs, temp files, and documentation

## Usage

### Pull from Docker Hub

```bash
docker pull lvnacy/chromamancer-dev
```

### Run Interactive Shell

```bash
docker run -it --rm \
  -v $(pwd):/home/node/workspace \
  lvnacy/chromamancer-dev
```

### Run with Additional Security Options

```bash
docker run -it --rm \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,nodev \
  --cap-drop=ALL \
  --security-opt=no-new-privileges:true \
  -v $(pwd):/home/node/workspace \
  lvnacy/chromamancer-dev
```

### Use as Development Container Base

```dockerfile
FROM lvnacy/chromamancer-dev

# Install project-specific dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

# Copy project files
COPY . .

# Your custom commands here
```

### VS Code Dev Container

Add to `.devcontainer/devcontainer.json`:

```json
{
  "name": "Node.js CLI Development",
  "image": "lvnacy/chromamancer-dev",
  "customizations": {
    "vscode": {
      "extensions": [
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode"
      ]
    }
  },
  "remoteUser": "node",
  "workspaceFolder": "/home/node/workspace"
}
```

## Built-in Aliases

The container includes convenient shell aliases:

- `ll` → `eza -la` (detailed directory listing)
- `cat` → `bat` (syntax-highlighted file viewing)

## Environment Variables

- `VOLTA_HOME`: `/home/node/.volta`
- `PATH`: Includes Volta bin directory
- `NODE_OPTIONS`: `--no-warnings`

## Building from Source

```bash
git clone git@github.com:lvnacy/chromamancer-dev
cd chromamancer-dev
docker build -t lvnacy/chromamancer-dev .
```

## Use Cases

This image is ideal for:

- CLI tool development and testing
- Node.js application development
- Secure CI/CD pipeline execution
- Educational environments requiring isolated Node.js environments
- Any scenario requiring a minimal, hardened Node.js runtime

## Architecture

### Stage 1: Builder
- Installs Volta, Node.js, pnpm, and diff-so-fancy
- All build tools and package managers remain in this disposable stage

### Stage 2: Runtime
- Fresh Debian Trixie base
- Installs only essential runtime dependencies and CLI tools
- Copies Volta installation from builder
- Aggressively removes all package managers and unnecessary utilities
- Configured for non-root operation

## Security Considerations

While this image removes many attack vectors by eliminating package managers and network tools, always consider your specific security requirements:

- Use `--read-only` filesystem when possible
- Drop all Linux capabilities with `--cap-drop=ALL`
- Enable no-new-privileges security option
- Mount temporary directories with `noexec`, `nosuid`, `nodev`
- Regularly update the base image to receive security patches
- Scan images for vulnerabilities using tools like Trivy or Grype

## What's Removed

The following are explicitly removed from the runtime image to reduce attack surface:

- Package managers: `apt`, `dpkg`
- Network utilities: `curl`, `wget`
- Scripting languages: `perl`
- User management: `adduser`, `deluser`
- Build artifacts: `/var/cache/apt`, `/var/lib/apt`
- Documentation: `/usr/share/man`, `/usr/share/doc`
- APT configuration: `/etc/apt`

## Version Information

Check installed versions:

```bash
docker run --rm lvnacy/chromamancer-dev node --version
docker run --rm lvnacy/chromamancer-dev pnpm --version
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT

## Credits

- Built with [Volta](https://volta.sh/)
- Inspired by security best practices from the Docker and Node.js communities
- Originally created for the [Chromamancer](https://github.com/lvnacy/chromamancer) theme conversion tool

## Support

For issues, questions, or suggestions, please open an issue on [GitHub](https://github.com/lvnacy/chromamancer-dev).