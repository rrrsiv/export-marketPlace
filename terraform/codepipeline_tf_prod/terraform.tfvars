project = "emp"
env = "prod"
region = "ap-south-1"
vpc_id = "vpc-0e8b63a01995cc13a"
subnet1_id = "subnet-0e02a6300e6a2ce39"
subnet2_id = "subnet-0ea8f344692d1f569"
sellerCodebuildName = "seller-service"
security_group_id = "sg-01ee7276c633760f0"
AWS_ACCESS_KEY_ID = "AKIAZRYDUTDGNBJGHJHI"
AWS_SECRET_ACCESS_KEY = "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"
sourceCodeUrl = "https://git-codecommit.ap-south-1.amazonaws.com/v1/repos/"
seller_repo_name = "emp-seller-service"
source_repo_branch = "refs/heads/main"
repo_branch = "main"
user_repo_name = "emp-user-service"
catalogue_repo_name = "emp-catalogue-service"
configuration_repo_name = "emp-configuration-service"
notification_repo_name = "emp-notification-service"
react_repo_name = "emp-react"
rfq_repo_name = "emp-rfq-service"
buyer_repo_name = "emp-buyer-service"
buyerCodebuildName = "buyer-service"
catalogueCodebuildName = "catalogue-service"
configurationCodebuildName = "configuration-service"
notificationCodebuildName = "notification-service"
rfqCodebuildName = "rfq-service"
reactCodebuildName = "react-service"
userCodebuildName = "user-service"
s3_bucket = "codepipeline-ap-south-1-403910783684"
pipeline_role = "AWSCodePipelineServiceRole-ap-south-1-emp-seller-service-qa"
build_role = "codebuild-emp-seller-service-service-role"