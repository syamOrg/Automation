data "template_file" "user_data_zookeeper" {
  template = "${file("./../files/templates/init_kafka_zookeper.tpl")}"

  vars {
    app_type         = "zookeeper"
    zookeeper_ips    = ""
    hosted_zone_id   = "${aws_route53_zone.kakfa_zone.id}"
    hosted_zone_name = "${aws_route53_zone.kakfa_zone.name}"
  }
}

resource "aws_instance" "zookeeper" {
  count                  = "${var.zookeeper_cluster_size}"
  ami             = "${var.ami}"
  instance_type          = "${var.zookeeper_instance_type}"
  key_name               = "${aws_key_pair.kafka_user.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}", "${aws_security_group.zookeeper.id}"]
  subnet_id              = "${element(data.terraform_remote_state.backend_vpc.private_subnet_ids, count.index)}"
  user_data              = "${data.template_file.user_data_zookeeper.rendered}"

  tags {
    Name    = "${var.project}-zookeeper"
    project = "${var.project}"
  }
}
