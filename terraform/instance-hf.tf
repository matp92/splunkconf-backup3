
# ******************** HF ***********************

resource "aws_iam_role" "role-splunk-hf" {
  name_prefix           = "role-splunk-hf-"
  force_detach_policies = true
  description           = "iam role for splunk hf"
  assume_role_policy    = file("policy-aws/assumerolepolicy-ec2.json")
  provider              = aws.region-primary

  tags = {
    Name = "splunk"
  }
}

resource "aws_iam_instance_profile" "role-splunk-hf_profile" {
  name_prefix     = "role-splunk-hf_profile"
  role     = aws_iam_role.role-splunk-hf.name
  provider = aws.region-primary
}

resource "aws_iam_role_policy_attachment" "hf-attach-splunk-splunkconf-backup" {
  #name       = "hf-attach-splunk-splunkconf-backup"
  role = aws_iam_role.role-splunk-hf.name
  #roles      = [aws_iam_role.role-splunk-hf.name]
  policy_arn = aws_iam_policy.pol-splunk-splunkconf-backup.arn
  provider   = aws.region-primary
}

resource "aws_iam_role_policy_attachment" "hf-attach-splunk-route53-updatednsrecords" {
  #name       = "hf-attach-splunk-route53-updatednsrecords"
  #roles      = [aws_iam_role.role-splunk-hf.name]
  role       = aws_iam_role.role-splunk-hf.name
  policy_arn = aws_iam_policy.pol-splunk-route53-updatednsrecords.arn
  provider   = aws.region-primary
}

resource "aws_iam_role_policy_attachment" "hf-attach-splunk-ec2" {
  #name       = "hf-attach-splunk-ec2"
  #roles      = [aws_iam_role.role-splunk-hf.name]
  role       = aws_iam_role.role-splunk-hf.name
  policy_arn = aws_iam_policy.pol-splunk-ec2.arn
  provider   = aws.region-primary
}

resource "aws_iam_role_policy_attachment" "hf-attach-splunk-writesecret" {
  #name       = "hf-attach-splunk-ec2"
  #roles      = [aws_iam_role.role-splunk-hf.name]
  role       = aws_iam_role.role-splunk-hf.name
  policy_arn = aws_iam_policy.pol-splunk-writesecret.arn
  provider   = aws.region-primary
}

#resource "aws_iam_role_policy_attachment" "hf-attach-ssm-managedinstance" {
#  #name       = "hf-attach-ssm-managedinstance"
#  #roles      = [aws_iam_role.role-splunk-hf.name]
#  role      = aws_iam_role.role-splunk-hf.name
#  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#  provider    = aws.region-primary
#}


resource "aws_security_group_rule" "hf_from_bastion_ssh" {
  provider                 = aws.region-primary
  security_group_id        = aws_security_group.splunk-hf.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.splunk-bastion.id
  description              = "allow SSH connection from bastion host"
}

resource "aws_security_group_rule" "hf_from_splunkadmin-networks_ssh" {
  provider          = aws.region-primary
  security_group_id = aws_security_group.splunk-hf.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.splunkadmin-networks
  description       = "allow SSH connection from splunk admin networks"
}

resource "aws_security_group_rule" "hf_from_splunkadmin-networks_webui" {
  provider          = aws.region-primary
  security_group_id = aws_security_group.splunk-hf.id
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = var.splunkadmin-networks
  description       = "allow WebUI connection from splunk admin networks"
}

#resource "aws_security_group_rule" "hf_from_splunkadmin-networks-ipv6_ssh" { 
#  provider    = aws.region-primary
#  security_group_id = aws_security_group.splunk-hf.id
#  type      = "ingress"
#  from_port = 22
#  to_port   = 22
#  protocol  = "tcp"
#  ipv6_cidr_blocks = var.splunkadmin-networks-ipv6
#  description = "allow SSH connection from splunk admin networks"
#}

#resource "aws_security_group_rule" "hf_from_splunkadmin-networks-ipv6_webui" { 
#  security_group_id = aws_security_group.splunk-hf.id
#  type      = "ingress"
#  from_port = 8000
#  to_port   = 8000
#  protocol  = "tcp"
#  ipv6_cidr_blocks = var.splunkadmin-networks-ipv6
#  description = "allow Webui connection from splunk admin networks"
#}

resource "aws_security_group_rule" "hf_from_all_icmp" {
  provider          = aws.region-primary
  security_group_id = aws_security_group.splunk-hf.id
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow icmp (ping, icmp path discovery, unreachable,...)"
}

resource "aws_security_group_rule" "hf_from_all_icmpv6" {
  provider          = aws.region-primary
  security_group_id = aws_security_group.splunk-hf.id
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmpv6"
  ipv6_cidr_blocks  = ["::/0"]
  description       = "allow icmp v6 (ping, icmp path discovery, unreachable,...)"
}

resource "aws_security_group_rule" "hf_from_mc_8089" {
  provider                 = aws.region-primary
  security_group_id        = aws_security_group.splunk-hf.id
  type                     = "ingress"
  from_port                = 8089
  to_port                  = 8089
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.splunk-mc.id
  description              = "allow MC to connect to instance on mgt port (rest api)"
}

# only when hf used as hec intermediate (instead of direct to idx via LB)
resource "aws_security_group_rule" "hf_from_networks_8088" {
  security_group_id = aws_security_group.splunk-hf.id
  type              = "ingress"
  from_port         = 8088
  to_port           = 8088
  protocol          = "tcp"
  cidr_blocks       = var.hec-in-allowed-networks
  description       = "allow HF to receive hec from authorized networks"
}

resource "aws_autoscaling_group" "autoscaling-splunk-hf" {
  provider            = aws.region-primary
  name                = "asg-splunk-hf"
  vpc_zone_identifier = (var.associate_public_ip == "true" ? [local.subnet_pub_1_id, local.subnet_pub_2_id, local.subnet_pub_3_id] : [local.subnet_priv_1_id, local.subnet_priv_2_id, local.subnet_priv_3_id])
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.splunk-hf.id
        version            = "$Latest"
      }
      override {
        instance_type = local.instance-type-hf
      }
    }
  }
  tag {
    key                 = "Type"
    value               = "Splunk"
    propagate_at_launch = false
  }
  tag {
    key                 = "splunkdnszone"
    value               = var.dns-zone-name
    propagate_at_launch = false
  }
  tag {
    key                 = "splunkdnsnames"
    value               = var.hf
    propagate_at_launch = false
  }
  tag {
    key                 = "splunkdnsprefix"
    value               = local.dns-prefix
    propagate_at_launch = false
  }

  #depends_on = [null_resource.bucket_sync, aws_autoscaling_group.autoscaling-splunk-bastion, aws_iam_role.role-splunk-hf]
  depends_on = [null_resource.bucket_sync, aws_iam_role.role-splunk-hf]
}

resource "aws_launch_template" "splunk-hf" {
  provider = aws.region-primary
  #name          = "splunk-hf"
  name_prefix   = "launch-template-splunk-hf"
  image_id      = data.aws_ssm_parameter.linuxAmi.value
  key_name      = local.ssh_key_name
  instance_type = "t3a.nano"
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.disk-size-hf
      volume_type = "gp3"
    }
  }
  #  ebs_optimized = true
  iam_instance_profile {
    name = aws_iam_instance_profile.role-splunk-hf_profile.name
    #name = "role-splunk-hf_profile"
  }
  network_interfaces {
    device_index                = 0
    associate_public_ip_address = var.associate_public_ip
    security_groups             = [aws_security_group.splunk-outbound.id, aws_security_group.splunk-hf.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name                  = var.hf
      splunkinstanceType    = var.hf
      splunks3backupbucket  = aws_s3_bucket.s3_backup.id
      splunks3installbucket = aws_s3_bucket.s3_install.id
      splunks3databucket    = aws_s3_bucket.s3_data.id
      splunkdnszone         = var.dns-zone-name
      splunkdnsmode         = "lambda"
      splunkorg             = var.splunkorg
      splunktargetenv       = var.splunktargetenv
      splunktargetbinary    = var.splunktargetbinary
      splunktargetcm        = var.cm
      splunktargetlm        = var.lm
      splunktargetds        = var.ds
      splunkcloudmode       = var.splunkcloudmode
      splunkosupdatemode    = var.splunkosupdatemode
      splunkconnectedmode   = var.splunkconnectedmode
      splunkacceptlicense   = var.splunkacceptlicense
      splunkpwdinit         = var.splunkpwdinit
      splunkpwdarn          = aws_secretsmanager_secret.splunk_admin.id
    }
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = (var.imdsv2 == "required" ? "required" : "optional")
    http_put_response_hop_limit = 1
  }
  user_data = filebase64("./user-data/user-data.txt")
}



output "hf-dns-name" {
  value       = "${local.dns-prefix}${var.hf}.${var.dns-zone-name}"
  description = "hf dns name (private ip)"
}

