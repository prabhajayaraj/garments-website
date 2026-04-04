#################################
# Providers
#################################

provider "aws" {
  region = "us-east-1"
}

# Required for CloudFront ACM (must be us-east-1)
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

#################################
 # S3 Bucket
#################################

 resource "aws_s3_bucket" "website" {
  bucket = "demo-surya-01"
}

# ACL (new method)
resource "aws_s3_bucket_acl" "website_acl" {
  bucket = aws_s3_bucket.website.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.website.arn}/*"
    }]
  })
} 

#################################
# Route53 Hosted Zone
#################################

resource "aws_route53_zone" "arunduppu" {
  name = "arunduppu.shop"
}

#################################
# ACM Certificate (SSL)
#################################

resource "aws_acm_certificate" "certificate" {
  provider          = aws.us_east
  domain_name       = "arunduppu.shop"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.arunduppu.shop"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# DNS Validation (correct way using for_each)
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options :
    dvo.domain_name => dvo
  }

  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  zone_id = aws_route53_zone.arunduppu.zone_id
  records = [each.value.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "certificate" {
  provider                = aws.us_east
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

#################################
# CloudFront Distribution
#################################

 resource "aws_cloudfront_distribution" "website" {

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [
    "arunduppu.shop",
    "*.arunduppu.shop"
  ]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.certificate.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [aws_acm_certificate_validation.certificate]
}

#################################
# Route53 Records -> CloudFront
#################################

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.arunduppu.zone_id
  name    = "arunduppu.shop"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "wildcard" {
  zone_id = aws_route53_zone.arunduppu.zone_id
  name    = "*.arunduppu.shop"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
} 
# -----------------------------
# ECR Repository
# -----------------------------
resource "aws_ecr_repository" "repo" {
  name = "my-docker-repo"
}

# -----------------------------
# ECS Cluster
# -----------------------------
resource "aws_ecs_cluster" "cluster" {
  name = "my-ecs-cluster"
}

# -----------------------------
# IAM Role for EC2 (ECS Agent)
# -----------------------------
# Use existing IAM role
data "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"
}

# Attach policy (optional)
resource "aws_iam_role_policy_attachment" "ecs_ec2_policy" {
  role       = data.aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Instance profile
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
  role = data.aws_iam_role.ecs_instance_role.name
}


# -----------------------------
# Security Group
# -----------------------------
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-security-group"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# Get Default VPC & Subnet
# -----------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -----------------------------
# EC2 Instance (ECS Node)
# -----------------------------
resource "aws_instance" "ecs_instance" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 (update per region)
  instance_type = "t2.micro"

  subnet_id = element(data.aws_subnets.default.ids, 0)

  vpc_security_group_ids = [aws_security_group.ecs_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name

  user_data = <<EOF
#!/bin/bash
yum update -y
amazon-linux-extras install -y ecs
systemctl enable ecs
systemctl start ecs
echo ECS_CLUSTER=${aws_ecs_cluster.cluster.name} >> /etc/ecs/ecs.config
EOF

  tags = {
    Name = "ecs-ec2-instance"
  }
}

# -----------------------------
# ECS Task Definition
# -----------------------------
resource "aws_ecs_task_definition" "task" {
  family                   = "my-task"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"

  container_definitions = jsonencode([
    {
      name  = "my-container"
      image = "${aws_ecr_repository.repo.repository_url}:latest"

      memory = 256
      cpu    = 128

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

# -----------------------------
# ECS Service
# -----------------------------
resource "aws_ecs_service" "service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "EC2"
}

