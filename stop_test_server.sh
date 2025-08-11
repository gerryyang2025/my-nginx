#!/bin/bash

# Set colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}===== Stop Test Web Servers =====${NC}"

# Check if PID file exists
if [ ! -f "test-servers.pid" ]; then
    echo -e "${RED}test-servers.pid file not found!${NC}"
    echo "Please confirm that you have run the start_test_server.sh script."

    # Try to find Python HTTP servers that might be running
    echo -e "${YELLOW}Attempting to find Python HTTP server processes that might be running...${NC}"
    HTTP_SERVERS=$(ps aux | grep "[p]ython.*http.server")

    if [ -n "$HTTP_SERVERS" ]; then
        echo -e "${GREEN}Found the following possible Python HTTP servers:${NC}"
        echo "$HTTP_SERVERS"

        # Extract PIDs
        PIDS=$(echo "$HTTP_SERVERS" | awk '{print $2}')

        echo -e "${YELLOW}Do you want to terminate these processes? (y/n)${NC}"
        read -r TERMINATE

        if [[ "$TERMINATE" =~ ^[Yy]$ ]]; then
            for pid in $PIDS; do
                echo "Terminating process $pid..."
                kill $pid
            done
            echo -e "${GREEN}All found Python HTTP server processes have been terminated.${NC}"
        else
            echo "Operation cancelled."
            exit 0
        fi
    else
        echo "No running Python HTTP server processes found."
        exit 1
    fi
else
    # Read PIDs from file and terminate processes
    PIDS=$(cat test-servers.pid)
    echo "Process IDs read from test-servers.pid file: $PIDS"

    for pid in $PIDS; do
        if ps -p $pid > /dev/null; then
            echo "Terminating process $pid..."
            kill $pid
        else
            echo "Process $pid no longer exists."
        fi
    done

    # Delete PID file
    rm test-servers.pid
    echo -e "${GREEN}All test web server processes have been terminated.${NC}"
fi

echo ""
echo "If you need to start the test servers again, run:"
echo "./start_test_server.sh"