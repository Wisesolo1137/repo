# Implementation Decisions & Thought Process

## Architecture Choices
- **Blue/Green Pattern**: Traditional active/backup approach for zero-downtime deployments
- **Nginx Load Balancer**: Chosen for its reliability, performance, and built-in load balancing features
- **Docker Compose**: For easy container orchestration and local development

## Technical Implementation
- **Backup Directive**: Used Nginx `backup` parameter for automatic failover
- **Header Preservation**: Custom Node.js servers to ensure X-App-Pool and X-Release-Id headers
- **Health Checks**: Implemented for service reliability and failover detection
- **Environment Variables**: Full parameterization for CI/CD compatibility

## Challenges Overcome
1. **Docker Installation**: Resolved Kali Linux repository and network issues
2. **Health Check Timing**: Optimized for Node.js application startup
3. **Header Management**: Implemented custom servers for proper header control
4. **Auto-Failover Configuration**: Fine-tuned Nginx timeouts and retry settings

## Learning Outcomes
- Deep understanding of Blue/Green deployment patterns in production
- Nginx configuration for load balancing and high availability
- Docker Compose for multi-container application orchestration
- Environment-based configuration management
- Troubleshooting complex DevOps tooling issues

## Trade-offs & Considerations
- Used test images due to access limitations to original task images
- Backup failover timing vs. instant failover requirements
- Simulated endpoints vs. actual application logic
