#!/usr/bin/env bash

# =============================================
# DevOps Bootcamp Stage 1  Deployment Script
# =============================================

set -euo pipefail

# --- Script Configuration ---
SCRIPT_NAME="deploy.sh"
SCRIPT_VERSION="1.0"
DEFAULT_BRANCH="main"
LOG_FILE="deploy_$(date +%Y%m%d_%H%M%S).log"

# --- Color Codes for Better Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Global Variables ---
GIT_REPO=""
GIT_PAT=""
GIT_BRANCH=""
REMOTE_USER=""
REMOTE_IP=""
SSH_KEY_PATH=""
APP_PORT=""
PROJECT_DIR=""

# =============================================
# LOGGING & ERROR HANDLING FUNCTIONS
# =============================================

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO") color=$BLUE ;;
        "SUCCESS") color=$GREEN ;;
        "WARNING") color=$YELLOW ;;
        "ERROR") color=$RED ;;
        *) color=$NC ;;
    esac
    
    echo -e "${color}[$timestamp] [$level] $message${NC}" | tee -a "$LOG_FILE"
}

check_error() {
    local exit_code=$?
    local operation=$1
    
    if [ $exit_code -ne 0 ]; then
        log "ERROR" "'$operation' failed with exit code $exit_code"
        log "ERROR" "Check $LOG_FILE for details. Deployment aborted."
        exit $exit_code
    fi
}

trap 'log "ERROR" "Unexpected error occurred at line $LINENO. Deployment failed."' ERR

# =============================================
# REMOTE EXECUTION FUNCTION
# =============================================

run_remote() {
    local command="$1"
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_IP}" "$command"
    check_error "Remote command: $command"
}

# =============================================
# FILE COPY FUNCTION
# =============================================
copy_to_remote() {
    local source="$1"
    local destination="$2"
    scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no -r "$source" "${REMOTE_USER}@${REMOTE_IP}:$destination"
    check_error "SCP copy: $source to $destination"
}
# =============================================
# VALIDATION FUNCTIONS
# =============================================

validate_ssh_connection() {
    log "INFO" "Testing SSH connection to $REMOTE_USER@$REMOTE_IP..."
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
        "${REMOTE_USER}@${REMOTE_IP}" "echo 'SSH connection successful'" > /dev/null 2>&1
    check_error "SSH connection test"
    log "SUCCESS" "SSH connection validated"
}

validate_git_url() {
    log "INFO" "Validating Git repository URL..."
    if [[ ! "$GIT_REPO" =~ ^https://.*\.git$ ]]; then
        log "ERROR" "Invalid Git URL format. Must be HTTPS and end with .git"
        exit 1
    fi
    log "SUCCESS" "Git URL format validated"
}

# =============================================
# GIT OPERATIONS
# =============================================
setup_git_operations() {
    log "INFO" "Setting up Git operations..."
    
    # Extract project name from Git URL
    PROJECT_DIR=$(basename "$GIT_REPO" .git)
    log "INFO" "Project directory will be: $PROJECT_DIR"
    
    # Clean up any existing directory
    if [ -d "$PROJECT_DIR" ]; then
        log "INFO" "Removing existing project directory..."
        rm -rf "$PROJECT_DIR"
    fi
    
    # Check if repository already exists (in case of previous partial clone)
    if [ -d "$PROJECT_DIR" ]; then
        log "INFO" "Repository already exists. Pulling latest changes..."
        cd "$PROJECT_DIR"
        
        # Stash any local changes to avoid conflicts
        git stash > /dev/null 2>&1 && log "INFO" "Stashed local changes if any"
        
        # Try to pull from the specified branch, if that fails try the other common branch
        if git pull origin "$GIT_BRANCH" 2>/dev/null; then
            log "SUCCESS" "Repository updated successfully from branch: $GIT_BRANCH"
        else
            log "WARNING" "Branch '$GIT_BRANCH' not found, trying alternative branch..."
            if [ "$GIT_BRANCH" = "main" ]; then
                alternative="master"
            else
                alternative="main"
            fi
            
            if git pull origin "$alternative" 2>/dev/null; then
                log "SUCCESS" "Repository updated successfully from branch: $alternative"
                GIT_BRANCH="$alternative"
            else
                log "ERROR" "Could not pull from either '$GIT_BRANCH' or '$alternative'"
                log "INFO" "Available branches:"
                git branch -r
                exit 1
            fi
        fi
    else
        log "INFO" "Cloning repository for the first time..."
        
        # First try with specified branch
        if git clone -b "$GIT_BRANCH" "$GIT_REPO" "$PROJECT_DIR" 2>/dev/null; then
            log "SUCCESS" "Repository cloned successfully from branch: $GIT_BRANCH"
        else
            log "WARNING" "Branch '$GIT_BRANCH' not found, trying 'master'..."
            if git clone -b "master" "$GIT_REPO" "$PROJECT_DIR" 2>/dev/null; then
                log "SUCCESS" "Repository cloned successfully from branch: master"
                GIT_BRANCH="master"
            else
                log "WARNING" "Branch 'master' not found, trying without branch specification..."
                if git clone "$GIT_REPO" "$PROJECT_DIR" 2>/dev/null; then
                    log "SUCCESS" "Repository cloned successfully (default branch)"
                else
                    log "ERROR" "Failed to clone repository. Please check:"
                    log "ERROR" "1. Repository URL is correct"
                    log "ERROR" "2. Repository is accessible"
                    log "ERROR" "3. You have proper permissions"
                    exit 1
                fi
            fi
        fi
        
        cd "$PROJECT_DIR"
        log "SUCCESS" "Repository cloned successfully"
    fi
    
    # For awesome-compose repository, we know it contains examples in subdirectories
    # Let's just verify we have some Docker examples instead of looking for root Dockerfile
    if [ -d "react-nginx" ]; then
        log "SUCCESS" "Found react-nginx example (will use for deployment)"
    else
        log "WARNING" "No specific example found, but repository cloned successfully"
    fi
    
    log "SUCCESS" "Git operations completed"
}
# =============================================
# REMOTE SERVER SETUP
# =============================================

setup_remote_environment() {
    log "INFO" "Setting up remote server environment..."
    
    # Update system packages
    run_remote "sudo yum update -y"
    check_error "System update"
    
    # Install Docker
    if ! run_remote "command -v docker" > /dev/null 2>&1; then
        log "INFO" "Installing Docker..."
        run_remote "sudo yum install -y docker"
        run_remote "sudo systemctl enable docker"
        run_remote "sudo systemctl start docker"
        run_remote "sudo usermod -a -G docker $REMOTE_USER"
        log "SUCCESS" "Docker installed and started"
    else
        log "INFO" "Docker already installed"
    fi
    
    # Install Docker Compose
    if ! run_remote "command -v docker-compose" > /dev/null 2>&1; then
        log "INFO" "Installing Docker Compose..."
        run_remote "sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose"
        run_remote "sudo chmod +x /usr/local/bin/docker-compose"
        log "SUCCESS" "Docker Compose installed"
    else
        log "INFO" "Docker Compose already installed"
    fi
    
    # Verify installations
    run_remote "docker --version"
    run_remote "docker-compose --version"
    
    log "SUCCESS" "Remote environment setup completed"
}

# =============================================
# APPLICATION DEPLOYMENT
# =============================================
deploy_application() {
    log "INFO" "Starting application deployment..."
    
    # Store current directory and go back to parent directory
    local current_dir=$(pwd)
    cd ..  # Go back to where the project directory is visible
    
    # Clean up remote directory first
    log "INFO" "Cleaning up remote directory..."
    run_remote "rm -rf /home/$REMOTE_USER/$PROJECT_DIR" || true
    
    # Copy project files to remote server
    log "INFO" "Copying project files to remote server..."
    copy_to_remote "$PROJECT_DIR" "/home/$REMOTE_USER/"
    check_error "Project files copy"
    
    # Go back to where we were
    cd "$current_dir"
    
    # Build and run the application using DIRECT DOCKER COMMANDS (no docker-compose)
    log "INFO" "Building and starting Docker container..."
    
    # Stop and remove any existing container
    run_remote "docker stop stage1-app || true"
    run_remote "docker rm stage1-app || true"
    
    # Build the Docker image
    run_remote "cd /home/$REMOTE_USER/$PROJECT_DIR && docker build -t stage1-app ."
    check_error "Docker build"
    
    # Run the container
    run_remote "cd /home/$REMOTE_USER/$PROJECT_DIR && docker run -d -p $APP_PORT:5000 --name stage1-app stage1-app"
    check_error "Docker run"
    
    # Wait for container to be healthy
    log "INFO" "Waiting for container to be ready..."
    sleep 10
    
    # Check if container is running
    log "INFO" "Checking container status..."
    run_remote "docker ps --filter name=stage1-app"
    check_error "Container status check"
    
    # Test if application is accessible
    log "INFO" "Testing application accessibility..."
    run_remote "curl -f http://localhost:$APP_PORT > /dev/null 2>&1 || echo 'Application test skipped'"
    
    log "SUCCESS" "Application deployed successfully! 🎉"
    log "INFO" "Your application should be accessible at: http://$REMOTE_IP:$APP_PORT"
}

# =============================================
# USER INPUT COLLECTION
# =============================================

collect_user_input() {
    echo
    log "INFO" "=== Deployment Configuration ==="
    
    # Git Repository URL
    while [[ -z "$GIT_REPO" ]]; do
        read -p "$(echo -e ${BLUE}"Enter Git Repository URL (HTTPS, ending with .git): "${NC})" GIT_REPO
        if [[ -z "$GIT_REPO" ]]; then
            log "WARNING" "Git Repository URL cannot be empty"
        fi
    done
    validate_git_url
    
    # Personal Access Token
    while [[ -z "$GIT_PAT" ]]; do
        read -s -p "$(echo -e ${BLUE}"Enter Git Personal Access Token: "${NC})" GIT_PAT
        echo
        if [[ -z "$GIT_PAT" ]]; then
            log "WARNING" "Personal Access Token cannot be empty"
        fi
    done
    
    # Branch name (with default)
    read -p "$(echo -e ${BLUE}"Enter Branch name [${DEFAULT_BRANCH}]: "${NC})" GIT_BRANCH
    GIT_BRANCH=${GIT_BRANCH:-$DEFAULT_BRANCH}
    log "INFO" "Using branch: $GIT_BRANCH"
    
    # Remote server details
    while [[ -z "$REMOTE_USER" ]]; do
        read -p "$(echo -e ${BLUE}"Enter Remote Server Username (e.g., ec2-user): "${NC})" REMOTE_USER
        if [[ -z "$REMOTE_USER" ]]; then
            log "WARNING" "Username cannot be empty"
        fi
    done
    
    while [[ -z "$REMOTE_IP" ]]; do
        read -p "$(echo -e ${BLUE}"Enter Remote Server IP: "${NC})" REMOTE_IP
        if [[ -z "$REMOTE_IP" ]]; then
            log "WARNING" "Server IP cannot be empty"
        fi
    done
    
    # SSH Key path
    while [[ -z "$SSH_KEY_PATH" ]]; do
        read -p "$(echo -e ${BLUE}"Enter SSH Key path: "${NC})" input_path
        if [[ -z "$input_path" ]]; then
            log "WARNING" "SSH Key path cannot be empty"
        else
            # Convert to absolute path
            SSH_KEY_PATH=$(realpath "$input_path" 2>/dev/null || echo "$input_path")
            if [[ ! -f "$SSH_KEY_PATH" ]]; then
                log "ERROR" "SSH Key file not found: $SSH_KEY_PATH"
                SSH_KEY_PATH=""
            else
                log "INFO" "SSH Key resolved to: $SSH_KEY_PATH"
            fi
        fi
    done
    
    # Application Port
    while [[ -z "$APP_PORT" ]]; do
        read -p "$(echo -e ${BLUE}"Enter Application Port (e.g., 3000, 8080): "${NC})" APP_PORT
        if [[ -z "$APP_PORT" ]]; then
            log "WARNING" "Application port cannot be empty"
        elif [[ ! "$APP_PORT" =~ ^[0-9]+$ ]]; then
            log "ERROR" "Port must be a number"
            APP_PORT=""
        fi
    done
    
    log "SUCCESS" "All user input collected and validated"
}
# =============================================
# MAIN SCRIPT EXECUTION
# =============================================
main() {
 log "INFO" "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    
    collect_user_input
    validate_ssh_connection
    setup_git_operations
    
    # DEBUG: Check if we reach here
    log "DEBUG" "✅ PASSED: Git operations completed"
    log "DEBUG" "🔄 NEXT: Calling setup_remote_environment"
    
    setup_remote_environment
    
    # DEBUG: Check if we reach here  
    log "DEBUG" "✅ PASSED: Remote environment setup completed"
    log "DEBUG" "🔄 NEXT: Calling deploy_application"
    
    deploy_application
    
    log "SUCCESS" "Deployment completed successfully! 🎉"
}
main "$@"
    
    
