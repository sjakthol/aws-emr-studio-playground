Resources for setting up and working with EMR Studio.

## Features

* CloudFormation stacks that set up required infra for EMR and EMR Studio.

## Prerequisites

* VPC, subnet and bucket stacks from [sjakthol/aws-account-infra](https://github.com/sjakthol/aws-account-infra).

## Deployment

Deploy stacks as follows to setup EMR Studio:

```bash
# Infra for EMR Clusters
make deploy-infra-emr

# Infra for EMR Studio
make deploy-infra-studio

# Service Catalog Portfolio for EMR Cluster creation
make deploy-studio-sc-portfolio

# EMR Studio with AWS SSO auth & access granted to single SSO user
make deploy-studio-sso IDENTITY_TYPE=USER IDENTITY_NAME=<AWS SSO user name>

# ... or with SSO auth & access granted to a group
make deploy-studio-sso IDENTITY_TYPE=GROUP IDENTITY_NAME=<AWS SSO group name>

# EMR Studio with AWS IAM auth
make deploy-studio-iam

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
make delete-studio-sc-portfolio

# EMR Studio
make -j delete-studio-sso delete-studio-iam

# Infra for EMR Studio
make delete-infra-studio

# Infra for EMR Clusters
make delete-infra-emr
```

## Stacks & Resources

* infra-emr - IAM roles and security groups for EMR Clusters
  * EMRServiceRole - Role EMR Service uses to create EMR Clusters (e.g. manage EC2 capacity).
  * EMRInstanceRole - Role EMR Cluster instances use to access AWS services (e.g. read data from S3).
* infra-studio - IAM roles and security groups for EMR Studio
  * EMRStudioServiceRole - Role EMR Studio Service uses to create and modify resources needed to connect a Studio workspace to EMR clusters.
  * EMRStudioUserRole - Role EMR Studio users use to create and manage workspaces / clusters.
    * EMRStudioBasicUserPolicy - Session policy for EMR Studio users (attach to existing cluster)
    * EMRStudioIntermediateUserPolicy - Session policy for EMR Studio users (attach to existing cluster and provision new ones with Service Catalog)
  * ServiceCatalogRole - Role for AWS Service Catalog to provision EMR Clusters
* studio-sc-portfolio - Service Catalog portfolio for EMR cluster templates
  * EMR-Cluster - Product for creating EMR cluster from EMR Studio
* studio-sso - EMR Studio instance with AWS SSO authentication
* studio-iam - EMR Studio instance with AWS IAM authentication
* emr-cluster - Stack that creates an EMR cluster for testing

## Credits and References

This work is based on https://github.com/aws-samples/emr-studio-samples (AWS, MIT License).

## License

MIT.
