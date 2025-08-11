#!/bin/bash

# Set colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}===== Test Web Server Startup Tool =====${NC}"
echo "This script will start simple web servers on ports 8080 and 8081 for testing Nginx reverse proxy"
echo ""

# Check if Python3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Python3 is not installed, please install Python3 first"
    exit 1
fi

# Create test webpage content - port 8080
mkdir -p test-web-8080
cat > test-web-8080/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>www.gerryyang.com Test Page</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            margin-top: 50px;
            background-color: #f0f8ff;
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
            color: #3366cc;
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
    </style>
</head>
<body>
    <div class="container">
        <h1>Nginx Reverse Proxy Test Page</h1>
        <h2>www.gerryyang.com</h2>
        <p class="status">✅ Successfully accessed backend server!</p>
        <p>This page is from the test server on port <span class="port">8080</span></p>
        <p>Current time: <span id="datetime"></span></p>
    </div>

    <script>
        document.getElementById('datetime').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOF

# Create test webpage content - port 8081
mkdir -p test-web-8081
cat > test-web-8081/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>llmnews.gerryyang.com Test Page</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            margin-top: 50px;
            background-color: #fff8f0;
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
            color: #cc6633;
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
    </style>
</head>
<body>
    <div class="container">
        <h1>Nginx Reverse Proxy Test Page</h1>
        <h2>llmnews.gerryyang.com</h2>
        <p class="status">✅ Successfully accessed backend server!</p>
        <p>This page is from the test server on port <span class="port">8081</span></p>
        <p>Current time: <span id="datetime"></span></p>
    </div>

    <script>
        document.getElementById('datetime').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOF

echo -e "${YELLOW}Starting test web server on port 8080...${NC}"
echo "Web server root directory: $(pwd)/test-web-8080"
cd test-web-8080
python3 -m http.server 8080 > /dev/null 2>&1 &
PID_8080=$!
cd ..

echo -e "${YELLOW}Starting test web server on port 8081...${NC}"
echo "Web server root directory: $(pwd)/test-web-8081"
cd test-web-8081
python3 -m http.server 8081 > /dev/null 2>&1 &
PID_8081=$!
cd ..

echo -e "${GREEN}Test web servers have been started${NC}"
echo "Port 8080 server process ID: $PID_8080"
echo "Port 8081 server process ID: $PID_8081"
echo ""
echo "You can now test access:"
echo "- http://www.gerryyang.com should display the page from port 8080"
echo "- http://llmnews.gerryyang.com should display the page from port 8081"
echo ""
echo "To stop the servers, run:"
echo "kill $PID_8080 $PID_8081"
echo ""
echo "These process IDs have been saved to the test-servers.pid file"

# Save process IDs to file
echo "$PID_8080 $PID_8081" > test-servers.pid