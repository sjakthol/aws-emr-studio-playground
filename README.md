Resources for setting up and working with EMR Studio.

## Features

* CloudFormation stacks that set up required infra for EMR and EMR Studio.

## Prerequisites

* VPC, subnet and bucket stacks from [sjakthol/aws-account-infra](https://github.com/sjakthol/aws-account-infra).

## Deployment

Deploy stacks as follows to setup EMR Studio:

```bash
# S3 buckets
make deploy-infra-storage

# Security Groups
make deploy-infra-sg

# IAM Roles
make deploy-infra-iam

# Service Catalog
make deploy-infra-sc-portfolio

# EMR Studio
make deploy-studio

# EMR Studio Session Policy Mapping (one or both; GROUP assignment might fail with AWS InternalFailure)
make deploy-studio-session-mapping IDENTITY_TYPE=USER IDENTITY_NAME=<AWS SSO user name>
make deploy-studio-session-mapping IDENTITY_TYPE=GROUP IDENTITY_NAME=<AWS SSO group name>

# Optional: EMR Cluster for testing (or skip and provision one from Studio with Service Catalog)
make deploy-emr-cluster
```

Once complete, you'll be able to login to EMR Studio using AWS SSO.

### Cleanup

Cleanup resources by deleting all resources in reverse order from deployment:

```bash
# Delete any running clusters first (if running).
make delete-emr-cluster

# Service Catalog (!! delete any provisioned applications first !!)
make delete-infra-sc-portfolio

# EMR Studio
make delete-studio

# IAM Roles
make delete-infra-iam

# Security Groups (remove rules from EMR Cluster security groups first)
make delete-infra-sg

# S3 buckets (empty them manually first)
make delete-infra-storage
```

## Stacks & Resources

* infra-storage - Buckets for storing EMR Studio resources
* infra-sg - Security Groups for EMR and EMR Studio
* infra-iam - IAM roles and policies for EMR, EMR Studio and AWS Service Catalog
  * EMRStudioServiceRole - Role EMR Studio Service uses to talk to other AWS Services.
  * EMRStudioUserRole - Role EMR Studio users use to create and manage workspaces / clusters.
    * EMRStudioBasicUserPolicy - Session policy for EMR Studio users (attach to existing cluster)
    * EMRStudioIntermediateUserPolicy - Session policy for EMR Studio users (attach to existing cluster and provision new ones with Service Catalog)
  * EMRServiceRole - Role EMR Service uses to create EMR Clusters (e.g. manage EC2 capacity).
  * EMRInstanceRole - Role EMR Cluster instances use to access AWS services (e.g. read data from S3).
  * ServiceCatalogRole - Role for AWS Service Catalog to provision EMR Clusters
* infra-sc-portfolio - Service Catalog portfolio for EMR cluster templates
  * Small_EMR_Cluster - Product for creating small EMR cluster from EMR Studio
* emr-cluster - Stack that creates an EMR cluster for testing

## Credits and References

This work is based on https://github.com/aws-samples/emr-studio-samples (AWS, MIT License).

## License

MIT.
