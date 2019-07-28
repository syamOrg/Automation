region = "us-east-1"
route53_hosted_zone_name = "kafka.dev.com"
project = "confluent"
kafka_cluster_size_min = 3
kafka_cluster_size_max = 10
kafka_instance_type = "t2.micro"
zookeeper_cluster_size = 3
zookeeper_instance_type = "t2.micro"
kafka_iam_role_prefix = "kafka_route53"
aws_default_user = "ec2-user"
#Ubuntu 16.04 LTS
ami= "ami-0cfee17793b08a293"