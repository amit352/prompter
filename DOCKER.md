# Docker Setup for Prompter

This guide explains how to run Prompter using Docker and Docker Compose.

## Quick Start

```bash
# Build and run with default schema
docker-compose up

# Or run interactively
docker-compose run --rm prompter

# Access shell for development
docker-compose run --rm --profile dev prompter-shell
```

## Prerequisites

- Docker 20.10+
- Docker Compose 1.29+

## Architecture

The Docker setup includes:

- **Dockerfile**: Builds a container with Ruby 3.2 and Prompter gem installed
- **docker-compose.yml**: Defines services for running Prompter
- **deployment/**: Volume-mounted directory for schemas and outputs

## Directory Structure

```
prompter/
├── Dockerfile                 # Container definition
├── docker-compose.yml         # Service orchestration
├── deployment/                # Configuration directory (mounted as volume)
│   ├── schema.yml            # Default schema (customize this)
│   ├── output.yml            # Generated output (created after run)
│   └── README.md             # Deployment documentation
```

## Usage

### Basic Usage

Run Prompter with the default schema:

```bash
docker-compose run --rm prompter
```

This will:
1. Build the Docker image (first time only)
2. Mount `./deployment` to `/app/deployment` in the container
3. Run `prompter schema.yml output.yml`
4. Save results to `deployment/output.yml`

### Custom Schema

To use a different schema file:

```bash
# Place your schema in deployment/my-schema.yml
docker-compose run --rm prompter my-schema.yml my-output.yml
```

### Interactive Mode

The container runs in interactive mode with TTY enabled, allowing you to:
- Answer prompts interactively
- Use arrow keys for selection
- Press Ctrl+C to exit with save options

### Development Shell

For debugging or advanced usage:

```bash
# Access bash shell in container
docker-compose run --rm --profile dev prompter-shell

# Inside the container, you can:
prompter schema.yml output.yml
ruby -Ilib bin/prompter schema.yml output.yml
gem list | grep prompter
```

## Customizing the Schema

1. Edit `deployment/schema.yml` to define your configuration prompts
2. Run Prompter to test your schema
3. Output is saved to `deployment/output.yml`

Example schema structure:

```yaml
project_name:
  type: string
  prompt: "Project name?"
  required: true

environment:
  type: select
  prompt: "Select environment"
  options: ["dev", "staging", "prod"]
  default: "dev"
```

## Using Processors

If your schema uses custom processors for dynamic options:

### Option 1: Define in Schema Directory

```bash
# Create processor file
cat > deployment/my_processor.rb << 'EOF'
class MyProcessor
  def self.get_options(answers:, config:)
    # Your logic here
    ["option1", "option2"]
  end
end
EOF

# Load it before running
docker-compose run --rm prompter bash -c "ruby -r ./my_processor.rb $(which prompter) schema.yml output.yml"
```

### Option 2: Build Custom Image

Create a custom Dockerfile:

```dockerfile
FROM prompter:latest

# Copy your processors
COPY processors/ /app/processors/

# Load processors
ENV RUBYOPT="-r /app/processors/my_processor.rb"
```

## Environment Variables

You can pass environment variables to the container:

```bash
# Via command line
docker-compose run --rm -e TERM=xterm-256color prompter

# Via .env file
echo "TERM=xterm-256color" > .env
docker-compose run --rm prompter
```

## Volume Mounts

The `deployment/` directory is mounted as a volume, which means:

- Files edited on your host are immediately available in the container
- Output files created in the container appear on your host
- You can use your favorite editor to modify schemas

## Troubleshooting

### Build Issues

```bash
# Rebuild from scratch
docker-compose build --no-cache

# Check build logs
docker-compose build --progress=plain
```

### Container Issues

```bash
# Check running containers
docker ps -a

# View logs
docker-compose logs

# Remove all containers
docker-compose down
```

### Permission Issues

If you encounter permission issues with mounted volumes:

```bash
# On Linux, ensure proper ownership
sudo chown -R $USER:$USER deployment/

# On macOS/Windows with Docker Desktop, this is usually not needed
```

## Production Deployment

### As a Standalone Container

```bash
# Build the image
docker build -t myapp/prompter:latest .

# Run with volume mount
docker run -it --rm \
  -v $(pwd)/deployment:/app/deployment \
  myapp/prompter:latest \
  schema.yml output.yml
```

### In CI/CD Pipeline

```yaml
# Example GitLab CI
generate-config:
  image: myapp/prompter:latest
  script:
    - prompter schema.yml output.yml < answers.txt
  artifacts:
    paths:
      - output.yml
```

### As Part of Application Stack

```yaml
# docker-compose.yml for your application
services:
  config-generator:
    build: ./prompter
    volumes:
      - ./config:/app/deployment
    command: prompter schema.yml config.yml

  app:
    build: .
    depends_on:
      - config-generator
    volumes:
      - ./config:/app/config
```

## Advanced Configuration

### Multi-Stage Build

Optimize image size with multi-stage builds:

```dockerfile
# Build stage
FROM ruby:3.2-alpine AS builder
WORKDIR /app
COPY . .
RUN gem build prompter.gemspec

# Runtime stage
FROM ruby:3.2-alpine
COPY --from=builder /app/prompter-*.gem /tmp/
RUN gem install /tmp/prompter-*.gem && rm /tmp/*.gem
WORKDIR /app/deployment
CMD ["prompter", "schema.yml", "output.yml"]
```

### Custom Entrypoint

Create a custom entrypoint for initialization:

```bash
#!/bin/bash
# entrypoint.sh

# Initialize deployment directory if empty
if [ ! -f /app/deployment/schema.yml ]; then
  cp /app/examples/full_feature_test.yml /app/deployment/schema.yml
fi

# Run prompter with provided arguments
exec prompter "$@"
```

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Prompter GitHub Repository](https://github.com/yourusername/prompter)

## Support

For issues related to Docker setup:
1. Check this documentation
2. Review Docker logs: `docker-compose logs`
3. Open an issue on GitHub with Docker version and error output
