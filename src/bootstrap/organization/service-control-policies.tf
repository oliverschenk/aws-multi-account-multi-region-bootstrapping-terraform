resource "aws_organizations_policy" "regional_restrictions" {
  name        = "DenyAllOutsideAURegions"
  description = "Prevent resources from being created outside of the AU region"

  content = <<CONTENT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyAllOutsideAURegions",
            "Effect": "Deny",
            "NotAction": [
               "iam:*",
               "sts:*",
               "organizations:*",
               "route53:*",
               "budgets:*",
               "waf:*",
               "cloudfront:*",
               "cloudwatch:*",
               "globalaccelerator:*",
               "importexport:*",
               "support:*",
               "consolidatedbilling:*",
               "trustedadvisor:*"
            ],
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "aws:RequestedRegion": [
                        "ap-southeast-2",
                        "ap-southeast-4"
                    ]
                }
            }
        }
    ]
}
CONTENT

}

resource "aws_organizations_policy_attachment" "regional_restrictions_attachment" {
  policy_id = aws_organizations_policy.regional_restrictions.id
  target_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_policy" "cloudtrail_restrictions" {
  name        = "ProtectCloudTrails"
  description = "Deny access to deleting or stopping CloudTrails"

  content = <<CONTENT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ProtectCloudTrail",
            "Effect": "Deny",
            "Action": [
                "cloudtrail:DeleteTrail",
                "cloudtrail:StopLogging"
            ],
            "Resource": "*"
        }
    ]
}
CONTENT

}

resource "aws_organizations_policy_attachment" "cloudtrail_restrictions_attachment" {
  policy_id = aws_organizations_policy.cloudtrail_restrictions.id
  target_id = aws_organizations_organization.org.roots[0].id
}

# resource "aws_organizations_policy" "security_account_restrictions" {
#   name        = "SecurityAccountRestrictions"
#   description = "Restrict creating resources in the security account"

#   content = <<CONTENT
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "SecurityAccountRestrictions",
#             "Effect": "Deny",
#             "NotAction": [
#                 "iam:*",
#                 "sts:*",
#                 "s3:*",
#                 "cloudtrail:*",
#                 "sns:*",
#                 "guardduty:*"
#             ],
#             "Resource": "*"
#         }
#     ]
# }
# CONTENT

# }

# resource "aws_organizations_policy_attachment" "security_account_restrictions_attachment" {
#   policy_id = aws_organizations_policy.security_account_restrictions.id
#   target_id = aws_organizations_account.security.id
# }

# resource "aws_organizations_policy" "deployment_account_restrictions" {
#   name        = "DeploymentAccountRestrictions"
#   description = "Restrict creating resources in the deployment account"

#   content = <<CONTENT
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "DeploymentAccountRestrictions",
#             "Effect": "Deny",
#             "NotAction": [
#                 "iam:*",
#                 "sts:*",
#                 "dynamodb:*",
#                 "s3:*",
#                 "kms:*",
#                 "cloudtrail:*",
#                 "events:*",
#                 "sns:*",
#                 "guardduty:*",
#                 "codeartifact:*",
#                 "codebuild:*",
#                 "codecommit:*",
#                 "codedeploy:*",
#                 "codepipeline:*",
#                 "servicequotas:*",
#                 "support:*"
#             ],
#             "Resource": "*"
#         }
#     ]
# }
# CONTENT

# }

# resource "aws_organizations_policy_attachment" "deployment_account_restrictions_attachment" {
#   policy_id = aws_organizations_policy.deployment_account_restrictions.id
#   target_id = aws_organizations_account.deployment.id
# }
