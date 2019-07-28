data "template_file" "user_data_kafka" {
  template = "${file("./../files/templates/init_kafka_zookeper.tpl")}"

  vars {
    app_type         = "kafka"
    zookeeper_ips    = "${join(":2181,", aws_instance.zookeeper.*.private_ip)}:2181"
    hosted_zone_id   = "${aws_route53_zone.kakfa_zone.id}"
    hosted_zone_name = "${aws_route53_zone.kakfa_zone.name}"
  }
}

resource "aws_launch_configuration" "kafka_lc" {
  name_prefix          = "kafka-config"
  image_id             = "${var.ami}"
  instance_type        = "${var.kafka_instance_type}"
  key_name             = "${aws_key_pair.kafka_user.key_name}"
  security_groups      = ["${aws_security_group.ssh.id}", "${aws_security_group.kafka.id}"]
  user_data            = "${data.template_file.user_data_kafka.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.kafka_profile.id}"
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "kafka_asg" {
  name                      = "${var.project}-kafka-asg"
  max_size                  = "${var.kafka_cluster_size_max}"
  min_size                  = "${var.kafka_cluster_size_min}"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = "${var.kafka_cluster_size_min}"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.kafka_lc.name}"
  vpc_zone_identifier       = ["${data.terraform_remote_state.backend_vpc.public_subnet_ids}"]

  tags = [{
    key                 = "Name"
    value               = "${var.project}-kafka"
    propagate_at_launch = true
  },
    {
      key                 = "project"
      value               = "${var.project}"
      propagate_at_launch = true
    },
  ]
  lifecycle {
    create_before_destroy = true
  }
}
