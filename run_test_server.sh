#!/bin/bash

# Test Web Server Management Script
# 
# Usage:
#   ./test_server.sh start     - Start all test web servers
#   ./test_server.sh stop      - Stop all test web servers
#   ./test_server.sh restart   - Restart all test web servers
#   ./test_server.sh status    - Check test server status
#   ./test_server.sh help      - Show this help message

# Set colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test server configuration
TEST_SERVERS=(
    "8080:www.gerryyang.com"
    "8081:llmnews.gerryyang.com"
    "8082:english.gerryyang.com"
)

PID_FILE="test-servers.pid"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to create test webpage
create_test_page() {
    local port=$1
    local domain=$2
    local bg_color=$3
    local title_color=$4
    
    mkdir -p "test-web-${port}"
    cat > "test-web-${port}/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>${domain} Test Page</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            margin-top: 50px;
            background-color: ${bg_color};
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: white;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: ${title_color};
        }
        .status {
            color: #28a745;
            font-weight: bold;
            font-size: 1.2em;
        }
        .port {
            color: #dc3545;
            font-weight: bold;
        }
        .domain {
            color: #0066cc;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Nginx Reverse Proxy Test Page</h1>
        <h2>${domain}</h2>
        <p class="status">Successfully accessed backend server!</p>
        <p>This page is from the test server on port <span class="port">${port}</span></p>
        <p>Current time: <span id="datetime"></span></p>
    </div>

    <script>
        document.getElementById('datetime').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOF
}

# Function to start test servers
start_servers() {
    print_status $BLUE "===== Starting Test Web Servers ====="
    echo ""
    
    # Check if Python3 is installed
    if ! command -v python3 &> /dev/null; then
        print_status $RED "Error: Python3 is not installed"
        echo "Please install Python3 first"
        exit 1
    fi
    
    # Check if servers are already running
    if [ -f "$PID_FILE" ]; then
        EXISTING_PIDS=$(cat "$PID_FILE" 2>/dev/null)
        RUNNING_PIDS=""
        for pid in $EXISTING_PIDS; do
            if ps -p $pid > /dev/null 2>&1; then
                RUNNING_PIDS="$RUNNING_PIDS $pid"
            fi
        done
        
        if [ -n "$RUNNING_PIDS" ]; then
            print_status $YELLOW "Warning: Test servers may already be running"
            echo "Running PIDs: $RUNNING_PIDS"
            print_status $YELLOW "Use './test_server.sh restart' to restart or './test_server.sh stop' to stop first"
            return 1
        fi
    fi
    
    # Start servers for each configuration
    PIDS=""
    for server in "${TEST_SERVERS[@]}"; do
        IFS=':' read -r port domain <<< "$server"
        
        print_status $YELLOW "Starting test web server on port ${port}..."
        echo "Web server root directory: $(pwd)/test-web-${port}"
        
        # Create test page
        case $port in
            8080)  create_test_page $port $domain "#f0f8ff" "#3366cc" ;;
            8081)  create_test_page $port $domain "#fff8f0" "#cc6633" ;;
            8082)  create_test_page $port $domain "#f0fff0" "#228b22" ;;
        esac
        
        # Start HTTP server
        cd "test-web-${port}"
        python3 -m http.server ${port} > /dev/null 2>&1 &
        PID=$!
        cd ..
        
        PIDS="$PIDS $PID"
        echo -e "${GREEN}Server started on port ${port} (PID: ${PID})${NC}"
    done
    
    # Save PIDs
    echo "$PIDS" > "$PID_FILE"
    
    echo ""
    print_status $GREEN "All test web servers have been started"
    echo ""
    echo "Process IDs saved to: $PID_FILE"
    echo ""
    echo "You can now test access:"
    for server in "${TEST_SERVERS[@]}"; do
        IFS=':' read -r port domain <<< "$server"
        echo "- http://${domain} -> port ${port}"
    done
    echo ""
    echo "To stop the servers, run:"
    echo "  ./test_server.sh stop"
}

# Function to stop test servers
stop_servers() {
    print_status $BLUE "===== Stopping Test Web Servers ====="
    echo ""
    
    if [ ! -f "$PID_FILE" ]; then
        print_status $YELLOW "PID file not found: $PID_FILE"
        echo "Attempting to find Python HTTP server processes..."
        
        # Try to find Python HTTP servers
        HTTP_SERVERS=$(ps aux | grep "[p]ython.*http.server" | grep -v grep)
        
        if [ -n "$HTTP_SERVERS" ]; then
            print_status $YELLOW "Found the following Python HTTP server processes:"
            echo "$HTTP_SERVERS"
            echo ""
            
            # Extract PIDs
            PIDS=$(echo "$HTTP_SERVERS" | awk '{print $2}')
            
            print_status $YELLOW "Terminating processes..."
            for pid in $PIDS; do
                if ps -p $pid > /dev/null 2>&1; then
                    kill $pid 2>/dev/null
                    echo "Terminated process $pid"
                fi
            done
            print_status $GREEN "All found processes have been terminated"
        else
            print_status $YELLOW "No running Python HTTP server processes found"
        fi
    else
        # Read PIDs from file
        PIDS=$(cat "$PID_FILE")
        echo "Process IDs from $PID_FILE: $PIDS"
        echo ""
        
        TERMINATED=0
        FAILED=0
        
        for pid in $PIDS; do
            if ps -p $pid > /dev/null 2>&1; then
                kill $pid 2>/dev/null
                sleep 0.5
                if ps -p $pid > /dev/null 2>&1; then
                    kill -9 $pid 2>/dev/null
                fi
                
                if ps -p $pid > /dev/null 2>&1; then
                    print_status $RED "Failed to terminate process $pid"
                    FAILED=$((FAILED + 1))
                else
                    echo "Terminated process $pid"
                    TERMINATED=$((TERMINATED + 1))
                fi
            else
                echo "Process $pid no longer exists"
            fi
        done
        
        # Clean up PID file and test directories
        rm -f "$PID_FILE"
        rm -rf test-web-*
        
        echo ""
        if [ $FAILED -eq 0 ]; then
            print_status $GREEN "All test web server processes have been terminated"
        else
            print_status $YELLOW "Some processes could not be terminated, but PID file has been removed"
        fi
    fi
    
    echo ""
    echo "To start the servers again, run:"
    echo "  ./test_server.sh start"
}

# Function to restart test servers
restart_servers() {
    print_status $BLUE "===== Restarting Test Web Servers ====="
    echo ""
    
    stop_servers
    sleep 1
    start_servers
}

# Function to check server status
status_servers() {
    print_status $BLUE "===== Test Web Server Status ====="
    echo ""
    
    # Check if PID file exists
    if [ -f "$PID_FILE" ]; then
        echo "PID file exists: $PID_FILE"
        PIDS=$(cat "$PID_FILE")
        echo "Expected PIDs: $PIDS"
        echo ""
    else
        echo "PID file not found: $PID_FILE"
        echo ""
    fi
    
    # Check for running servers
    print_status $YELLOW "Running Test Servers:"
    echo ""
    
    RUNNING_COUNT=0
    TOTAL_COUNT=0
    
    for server in "${TEST_SERVERS[@]}"; do
        IFS=':' read -r port domain <<< "$server"
        TOTAL_COUNT=$((TOTAL_COUNT + 1))
        
        # Check if port is listening
        if ss -tuln | grep -q ":${port}"; then
            # Try to find the process
            HTTP_SERVERS=$(ps aux | grep "[p]ython.*http.server.*${port}" | grep -v grep)
            
            if [ -n "$HTTP_SERVERS" ]; then
                PID=$(echo "$HTTP_SERVERS" | awk '{print $2}' | head -1)
                print_status $GREEN "✓ Port ${port} (${domain}) - Running (PID: ${PID})"
                RUNNING_COUNT=$((RUNNING_COUNT + 1))
            else
                print_status $GREEN "✓ Port ${port} (${domain}) - Listening"
                RUNNING_COUNT=$((RUNNING_COUNT + 1))
            fi
        else
            print_status $RED "✗ Port ${port} (${domain}) - Not running"
        fi
    done
    
    echo ""
    echo "Summary: ${RUNNING_COUNT}/${TOTAL_COUNT} test servers running"
    
    # Show test URLs
    echo ""
    echo "Test URLs:"
    for server in "${TEST_SERVERS[@]}"; do
        IFS=':' read -r port domain <<< "$server"
        echo "  http://${domain} -> port ${port}"
    done
}

# Function to show help
show_help() {
    echo "Test Web Server Management Script"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  start   - Start all test web servers"
    echo "  stop    - Stop all test web servers"
    echo "  restart - Restart all test web servers"
    echo "  status  - Check test server status"
    echo "  help    - Show this help message"
    echo ""
    echo "Test Servers:"
    for server in "${TEST_SERVERS[@]}"; do
        IFS=':' read -r port domain <<< "$server"
        echo "  Port ${port}: ${domain}"
    done
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 stop"
    echo "  $0 status"
    echo ""
    echo "For more information, see README.md"
}

# Main script logic
main() {
    # Parse command
    case "${1:-help}" in
        start)
            start_servers
            ;;
        stop)
            stop_servers
            ;;
        restart)
            restart_servers
            ;;
        status)
            status_servers
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_status $RED "Error: Unknown command '$1'"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
