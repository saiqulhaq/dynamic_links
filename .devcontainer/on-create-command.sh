#!/bin/bash

# Setup database configuration
bash .devcontainer/docker-compose-setup.sh

cat << EOF
╭────────────────────────────────────────────────────╮
│                                                    │
│  🎉 Welcome to Dynamic Links Development Container! │
│                                                    │
╰────────────────────────────────────────────────────╯

Project is set up and ready to go with Docker Compose!

Services available:
  * PostgreSQL on postgres:5432
  * Redis on redis:6379
  * App container with Ruby and Rails

Useful commands:
  * cd test/dummy && bin/rails server   - Start the Rails server
  * cd test/dummy && bin/rails console  - Open Rails console
  * cd test/dummy && bin/rails test     - Run tests

VS Code shortcuts:
  * Use Command Palette (F1) and type "Tasks" to see available project tasks
  * You can also use the "Run and Debug" tab for debugging (Ctrl+Shift+D)

Happy coding!
EOF
