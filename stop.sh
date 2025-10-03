#!/bin/bash

# Data Engineering Project - Stop Script
# This script stops all services and optionally cleans up data

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================"
echo "Data Engineering Project - Shutdown"
echo "============================================"

# Parse arguments
CLEAN_DATA=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_DATA=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Stop services
echo -e "${YELLOW}Stopping all services...${NC}"
docker-compose down

if [ "$CLEAN_DATA" = true ]; then
    echo -e "${YELLOW}Cleaning up data volumes...${NC}"
    docker-compose down -v
    
    echo -e "${YELLOW}Removing generated data files...${NC}"
    rm -rf data/raw/* data/staging/* data/processed/*
    rm -rf airflow/logs/*
    
    echo -e "${GREEN}All data cleaned!${NC}"
fi

echo -e "${GREEN}Shutdown complete!${NC}"
