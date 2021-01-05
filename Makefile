# Mapping from long region names to shorter ones that is to be
# used in the stack names
AWS_ap-northeast-1_PREFIX = an1
AWS_ap-northeast-2_PREFIX = an2
AWS_ap-south-1_PREFIX = as1
AWS_ap-southeast-1_PREFIX = as1
AWS_ap-southeast-2_PREFIX = as2
AWS_ca-central-1_PREFIX = cc1
AWS_eu-central-1_PREFIX = ec1
AWS_eu-north-1_PREFIX = en1
AWS_eu-west-1_PREFIX = ew1
AWS_eu-west-2_PREFIX = ew2
AWS_eu-west-3_PREFIX = ew3
AWS_sa-east-1_PREFIX = se1
AWS_us-east-1_PREFIX = ue1
AWS_us-east-2_PREFIX = ue2
AWS_us-west-1_PREFIX = uw1
AWS_us-west-2_PREFIX = uw2

# Some defaults
AWS ?= aws
AWS_REGION ?= eu-west-1
AWS_PROFILE ?= default
AWS_ACCOUNT_ID = $(eval AWS_ACCOUNT_ID := $(shell $(AWS_CMD) sts get-caller-identity --query Account --output text))$(AWS_ACCOUNT_ID)

AWS_CMD := $(AWS) --profile $(AWS_PROFILE) --region $(AWS_REGION)

STACK_REGION_PREFIX := $(AWS_$(AWS_REGION)_PREFIX)
DEPLOYMENT := $(STACK_REGION_PREFIX)-emr-studio

TAGS ?= Deployment=$(DEPLOYMENT)

# Generic deployment and teardown targets
deploy-%:
	$(AWS_CMD) cloudformation deploy \
		--stack-name $(DEPLOYMENT)-$* \
		--tags $(TAGS) \
		--parameter-overrides Deployment=$(DEPLOYMENT) \
		--template-file templates/$*.yaml \
		--capabilities CAPABILITY_NAMED_IAM \
		$(EXTRA_ARGS)

delete-%:
	$(AWS_CMD) cloudformation delete-stack \
		--stack-name $(DEPLOYMENT)-$*

# Customizations

deploy-infra-sc-portfolio: upload-cluster-template
upload-cluster-template:
	sed "s/# Default: DEPLOYMENT_DEFAULT/Default: $(DEPLOYMENT)/" templates/emr-cluster.yaml | \
		$(AWS_CMD) s3 cp - s3://$(AWS_ACCOUNT_ID)-$(AWS_REGION)-build-resources/$(DEPLOYMENT)/emr-cluster.yaml

# Targets for deploying studio (no CloudFormation Support)
VPC_ID ?= $(shell $(AWS_CMD) cloudformation list-exports --query 'Exports[?Name==`infra-vpc-VpcId`].Value' --output text)
SUBNET_ID ?= $(shell $(AWS_CMD) cloudformation list-exports --query 'Exports[?Name==`infra-vpc-sn-public-a`].Value' --output text)
SERVICE_ROLE ?= $(shell $(AWS_CMD) cloudformation list-exports --query 'Exports[?Name==`$(DEPLOYMENT)-infra-iam-EMRStudioServiceRoleArn`].Value' --output text)
USER_ROLE ?= $(shell $(AWS_CMD) cloudformation list-exports --query 'Exports[?Name==`$(DEPLOYMENT)-infra-iam-EMRStudioUserRoleArn`].Value' --output text)
WORKSPACE_SG ?= $(shell $(AWS_CMD) cloudformation list-exports --query 'Exports[?Name==`$(DEPLOYMENT)-infra-sg-WorkspaceSecurityGroup`].Value' --output text)
ENGINE_SG ?= $(shell $(AWS_CMD) cloudformation list-exports --query 'Exports[?Name==`$(DEPLOYMENT)-infra-sg-EngineSecurityGroup`].Value' --output text)

STUDIO_ID ?= $(shell $(AWS_CMD) emr list-studios --query 'Studios[0].StudioId' --output text)
BASIC_SESSION_POLICY ?= $(shell $(AWS_CMD) cloudformation list-exports --query 'Exports[?Name==`$(DEPLOYMENT)-infra-iam-EMRStudioBasicUserPolicyArn`].Value' --output text)
INTERMEDIATE_SESSION_POLICY ?= $(shell $(AWS_CMD) cloudformation list-exports --query 'Exports[?Name==`$(DEPLOYMENT)-infra-iam-EMRStudioIntermediateUserPolicyArn`].Value' --output text)

deploy-studio:
	$(AWS_CMD) emr create-studio \
		--name $(DEPLOYMENT) \
		--auth-mode SSO \
		--vpc-id $(VPC_ID) \
		--subnet-ids $(SUBNET_ID) \
		--service-role $(SERVICE_ROLE) \
		--user-role $(USER_ROLE) \
		--workspace-security-group-id $(WORKSPACE_SG) \
		--engine-security-group-id $(ENGINE_SG) \
		--default-s3-location s3://$(DEPLOYMENT)-studio-resources

deploy-studio-session-mapping:
	$(AWS_CMD) emr create-studio-session-mapping \
		--studio-id $(STUDIO_ID) \
		--identity-type $(IDENTITY_TYPE) \
		--identity-name $(IDENTITY_NAME
		) \
		--session-policy-arn $(INTERMEDIATE_SESSION_POLICY)

delete-studio:
	$(AWS_CMD) emr delete-studio --studio-id $(STUDIO_ID)

# Concrete deploy and delete targets for autocompletion
$(addprefix deploy-,$(basename $(notdir $(wildcard templates/*.yaml)))):
$(addprefix delete-,$(basename $(notdir $(wildcard templates/*.yaml)))):