provider "aws" {
  region = "${var.aws_region}"
}

data "terraform_remote_state" "backend_vpc" {
  backend = "s3"

  config {
    bucket = "sams3backend"
    key    = "vpc/terraform.tfsate"
    region = "us-east-1"
  }
}

module "iam" {
  source = "./iam"
}

module "security" {
  source             = "./security"
  vpc_id             = "${data.terraform_remote_state.backend_vpc.vpc_id}"
  private_subnet_ids = "${data.terraform_remote_state.backend_vpc.private_subnet_ids}"
  public_subnet_ids  = "${data.terraform_remote_state.backend_vpc.public_subnet_ids}"
}

resource "aws_key_pair" "elk_auth" {
  key_name   = "${var.aws_default_user}"
  public_key = "${file(format("./files/userkeys/%s_rsa.pub",var.aws_default_user))}"
}

data "template_file" "install_elk" {
  template = "${(file("./user_data/init_elk.tpl"))}"

  vars {
    elasticsearch_cluster  = "${var.elasticsearch_cluster}"
    elasticsearch_data_dir = "${var.elasticsearch_data_dir}"
    elk_useradd            = "${join("\n",data.template_file.add_users.*.rendered)}"
  }
}

data "template_file" "add_users" {
  count    = "${length(var.additional_users)}"
  template = "${(file("./user_data/user_add.tpl"))}"

  vars {
    user_name      = "${element(var.additional_users, count.index)}"
    user_publickey = "${file(format("./files/userkeys/%s_rsa.pub",element(var.additional_users, count.index)))}"
  }
}

output "elkuserdata" {
  value = "${data.template_file.install_elk.rendered}"
}

resource "aws_eip" "temp_eip" {
  count = "${var.instance_count}"

  # count = "${length(data.terraform_remote_state.backend_vpc.private_subnet_ids)}" in actual use
  instance = "${element(aws_instance.elkinstances.*.id,count.index)}"
  vpc      = true

  depends_on = ["aws_instance.elkinstances"]
}

output "instanceips" {
  value = "${join(",",aws_eip.temp_eip.*.public_ip)}"
}

locals {
  elk_privateips = "${aws_instance.elkinstances.*.private_ip}"
  elk_publicips  = "${join(",",aws_eip.temp_eip.*.public_ip)}"
}

resource "aws_instance" "elkinstances" {
  count = "${var.instance_count}"

  # count = "${length(data.terraform_remote_state.backend_vpc.private_subnet_ids)}" in actual use
  ami             = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type   = "${var.elk_instance_type}"
  key_name        = "${aws_key_pair.elk_auth.key_name}"
  security_groups = ["${module.security.elk_sc_id}", "${module.security.esearch_sc_id}", "${module.security.elasticsearch_sc_id}"]
  subnet_id       = "${element(data.terraform_remote_state.backend_vpc.public_subnet_ids,count.index)}"

  #subnet_id            = "${data.terraform_remote_state.backend_vpc.private_subnet_ids}" in actual use
  iam_instance_profile = "${module.iam.es_iam_id}"

  #https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html
  ebs_block_device = {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = "20"
    iops        = "500"
  }

  lifecycle {
    ignore_changes = ["ebs_block_device", "security_groups"]
  }

  user_data   = "${data.template_file.install_elk.rendered}"
  volume_tags = "${var.aws_instancetags}"
  tags        = "${var.aws_instancetags}"
}

resource "null_resource" "configuration" {
  triggers = {
    trigger_a = "${sha1(file("files/ansible_plays/main.yml"))}"
    trigger_b = "${sha1(file("files/ansible_plays/templates/elasticsearch.yml.j2"))}"
    trigger_c = "${sha1(file("files/ansible_plays/templates/logstash.conf.j2"))}"
    trigger_d = "${sha1(file("files/ansible_plays/templates/kibana.yml.j2"))}"
  }
  provisioner "local-exec" {
    command = "ansible-playbook -i ${local.elk_publicips}, files/ansible_plays/main.yml -e elasticsearch_cluster=${var.elasticsearch_cluster} -e ansible_python_interpreter=/usr/bin/python3"

    environment = {
      ANSIBLE_HOST_KEY_CHECKING   = "False"
      ANSIBLE_PYTHON_INTERPRETER  = "/usr/bin/python3"
      ANSIBLE_BECOME              = "True"
      ANSIBLE_REMOTE_USER         = "ubuntu"
      ANSIBLE_PRIVATE_KEY_FILE    = "/home/nero/naveen.pem"
      ANSIBLE_RETRY_FILES_ENABLED = "False"
    }
  }
}
