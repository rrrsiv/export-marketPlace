resource "kubectl_manifest" "observability" {
    yaml_body = <<-YAML
        apiVersion: v1
        kind: Namespace
        metadata:
          name: aws-observability
          labels:
            aws-observability: enabled
    YAML
    depends_on = [
      aws_eks_fargate_profile.be
    ]
}

resource "kubectl_manifest" "configmap" {
    yaml_body = <<-YAML
        kind: ConfigMap
        apiVersion: v1
        metadata:
          name: aws-logging
          namespace: aws-observability
        data:
          flb_log_cw: "true"  # Set to true to ship Fluent Bit process logs to CloudWatch.
          filters.conf: |
            [FILTER]
                Name parser
                Match *
                Key_name log
                Parser crio
            [FILTER]
                Name kubernetes
                Match kube.*
                Merge_Log On
                Keep_Log Off
                Buffer_Size 0
                Kube_Meta_Cache_TTL 300s
          output.conf: |
            [OUTPUT]
                Name cloudwatch_logs
                Match   kube.*
                region ap-south-1
                log_stream_prefix from-fluent-bit-
                log_retention_days 60
                auto_create_group true
          parsers.conf: |
            [PARSER]
                Name crio
                Format Regex
                Regex ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>P|F) (?<log>.*)$
                Time_Key    time
                Time_Format %Y-%m-%dT%H:%M:%S.%L%z
    YAML           
}


resource "aws_iam_policy" "fluentbit-policy" {
  name        = "${var.project}-eks-fargate-logging-policy-${var.env}"
  description = "Policy to send the pod logs to cloudwatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            "Effect": "Allow",
		    "Action": [
			        "logs:CreateLogStream",
			        "logs:CreateLogGroup",
			        "logs:DescribeLogStreams",
			        "logs:PutLogEvents"
		    ],
		    "Resource": "*"
            
        }
    ]
    })
}


resource "aws_iam_role_policy_attachment" "eks-fargate-logging" {
  policy_arn = aws_iam_policy.fluentbit-policy.arn
  role       = aws_iam_role.eks-fargate-profile.name
}