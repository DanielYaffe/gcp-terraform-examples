# Private Service Connect (PSC) with Cloud SQL and Cloud Run

This Terraform configuration demonstrates how to set up a secure, private connection between Cloud Run and Cloud SQL using Google Cloud's Private Service Connect (PSC) technology with IAM authentication.

## Overview

This example implements a cross-project architecture where:
- A **producer project** hosts a Cloud SQL PostgreSQL database with PSC enabled
- A **consumer project** runs a Cloud Run service that connects to the database via PSC
- All connections use IAM authentication (no passwords)
- Traffic never leaves Google's internal network

## Architecture

```
Consumer Project                          Producer Project
┌─────────────────────────────────┐      ┌─────────────────────────────┐
│                                 │      │                             │
│  Cloud Run Service              │      │  Cloud SQL Instance         │
│  └─ Service Account             │      │  └─ PSC Enabled             │
│     └─ IAM Auth                 │      │     └─ IAM Auth Enabled     │
│                                 │      │                             │
│  Consumer VPC                   │      │  Producer VPC               │
│  ├─ Cloud Run Subnet            │      │  └─ DB Subnet               │
│  └─ PSC Subnet                  │      │                             │
│     └─ PSC Forwarding Rule ─────┼──────┼─> Service Attachment        │
│                                 │      │                             │
│  Private DNS Zones              │      │                             │
│  ├─ googleapis.com              │      │                             │
│  └─ {region}.sql.goog           │      │                             │
└─────────────────────────────────┘      └─────────────────────────────┘
```

## Components

### Network Infrastructure ([network.tf](network.tf))
- **Producer VPC**: Isolated network for the Cloud SQL database
- **Consumer VPC**: Network for Cloud Run with dedicated subnets:
  - Cloud Run residency subnet (10.1.0.0/24)
  - PSC endpoint subnet (10.2.0.0/20)

### Cloud SQL Database ([compute.tf](compute.tf))
- PostgreSQL 15 instance with PSC enabled
- IAM authentication enabled
- Private-only access (no public IP)
- Service account with appropriate Cloud SQL roles

### Private Service Connect Endpoint ([compute.tf](compute.tf#L54-L71))
- Internal IP address in the PSC subnet
- Forwarding rule connecting to the database's PSC service attachment
- Provides stable private endpoint for database access

### DNS Configuration ([dns.tf](dns.tf))
- **Google APIs zone**: Routes API calls to restricted.googleapis.com (199.36.153.4/30)
- **Cloud SQL zone**: Custom DNS mapping for the database's connection name to the PSC endpoint IP

### Cloud Run Service ([compute.tf](compute.tf#L74-L116))
- Flask application that validates database connectivity
- VPC-native deployment with egress through consumer VPC
- Uses service account identity for IAM authentication
- Automatic image build and deployment via Artifact Registry

### Container Application ([main.py](main.py))
- Simple Flask web app that tests database connectivity
- Uses Cloud SQL Python Connector with PSC support
- Displays connection details and current database user

## Prerequisites

- Two GCP projects (producer and consumer) or one project used for both
- Organization-level access (for org-level API management)
- Terraform >= 1.10.0
- Docker installed locally
- gcloud CLI configured with appropriate credentials

## Required APIs

The following APIs must be enabled in both projects:
- Compute Engine API
- Cloud SQL Admin API
- Cloud Run API
- Artifact Registry API
- Service Networking API
- DNS API

## Variables

Configure the following variables in [terraform.tfvars](terraform.tfvars):

| Variable | Description | Required |
|----------|-------------|----------|
| `organization_id` | Numeric ID of your GCP organization | Yes |
| `billing_project_id` | Project ID for billing/API calls | Yes |
| `producer_project_id` | Project hosting the Cloud SQL database | Yes |
| `consumer_project_id` | Project hosting the Cloud Run service | Yes |
| `region` | GCP region for resources | No (default: europe-west1) |

## Usage

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Configure Variables**
   Create a `terraform.tfvars` file:
   ```hcl
   organization_id      = "123456789012"
   billing_project_id   = "my-billing-project"
   producer_project_id  = "my-producer-project"
   consumer_project_id  = "my-consumer-project"
   region              = "europe-west1"
   ```

The first is for the null resource docker as it cant use the application default login that the terraform uses
4. **Authenticate**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```
5. **Plan and Apply**
   ```bash
   terraform plan
   terraform apply
   ```

6. **Access the Application**
   After deployment, Terraform outputs the Cloud Run service URL. Visit it to verify the database connection.

## How It Works

### Connection Flow

1. **Cloud Run** makes a connection request to the Cloud SQL instance
2. The **Cloud SQL Python Connector** resolves the instance connection name via DNS
3. **Private DNS** routes the query to the PSC forwarding rule's IP address
4. The **PSC Forwarding Rule** forwards traffic through the service attachment
5. Traffic reaches the **Cloud SQL instance** in the producer project
6. **IAM authentication** validates the service account identity
7. Database connection is established without any passwords

### IAM Authentication

The service account is granted:
- `roles/cloudsql.client` - Allows connections via Cloud SQL Proxy/Connector
- `roles/cloudsql.instanceUser` - Allows IAM authentication to the database

The database user is created with type `CLOUD_IAM_SERVICE_ACCOUNT`, enabling passwordless authentication using the service account's identity token.

### DNS Configuration

Two private DNS zones ensure proper routing:
1. **googleapis.com**: Routes Google API calls to restricted.googleapis.com
2. **{region}.sql.goog**: Maps the database's DNS name to the PSC endpoint IP

## Security Features

- No public IP addresses on the database
- All traffic stays within Google's network
- IAM-based authentication (no passwords to manage)
- Cross-project isolation
- VPC-native Cloud Run deployment
- Dedicated PSC subnet for endpoint isolation

## Files

- [terraform.tf](terraform.tf) - Provider and backend configuration
- [variables.tf](variables.tf) - Input variable definitions
- [network.tf](network.tf) - VPC and subnet resources
- [compute.tf](compute.tf) - Cloud SQL, PSC endpoint, Cloud Run
- [dns.tf](dns.tf) - Private DNS zones and records
- [artifact_registry.tf](artifact_registry.tf) - Container registry and image build
- [main.py](main.py) - Flask application code
- [Dockerfile](Dockerfile) - Container image definition

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Troubleshooting

### Connection Failures

1. **Check DNS resolution**: Ensure the private DNS zones are properly configured
2. **Verify IAM roles**: Service account must have both Cloud SQL roles
3. **PSC status**: Confirm the forwarding rule is active
4. **VPC egress**: Cloud Run must have `egress = "ALL_TRAFFIC"` to use VPC

### Common Issues

- **"connection refused"**: DNS may not be routing to PSC endpoint
- **"authentication failed"**: Service account may not be granted database user role
- **"timeout"**: PSC forwarding rule may not be properly configured

## Additional Resources

- [Private Service Connect Documentation](https://cloud.google.com/vpc/docs/private-service-connect)
- [Cloud SQL IAM Authentication](https://cloud.google.com/sql/docs/postgres/authentication)
- [Cloud Run VPC Integration](https://cloud.google.com/run/docs/configuring/vpc-direct-vpc)
- [Cloud SQL Python Connector](https://github.com/GoogleCloudPlatform/cloud-sql-python-connector)
