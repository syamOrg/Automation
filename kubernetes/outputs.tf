output "region" {
  value = "${var.aws_region}"
}

output "vpc_id" {
  value = "${data.aws_vpc.kubernetesvpc.id}"
}

output "vpc_cidr_block" {
  value = "${data.aws_vpc.kubernetesvpc.cidr_block}"
}

output "public_subnet_ids" {
  value = "${data.terraform_remote_state.backend_vpc.public_subnet_ids}"
}

output "public_route_table_ids" {
  value = "${data.terraform_remote_state.backend_vpc.public_routetable_ids}"
}

output "private_subnet_ids" {
  value =  "${data.terraform_remote_state.backend_vpc.private_subnet_ids}"
}

output "private_route_table_ids" {
  value = "${data.terraform_remote_state.backend_vpc.private_routetable_ids}"
}

output "kubernetes_security_group_id" {
  value = "${aws_security_group.kops_app_sg.id}"
}

output "nat_gateway_ids" {
  value = ["${data.terraform_remote_state.backend_vpc.vpc_natgw_id}"]
}

output "availability_zones" {
  value = "${distinct(data.aws_subnet.privatecidrs.*.availability_zone)}"
}

output "kops_s3_bucket_name" {
  value = "${aws_s3_bucket.kops_state.bucket}"
}

output "kubernetes_clustername" {
  value = "${var.kubernetes_clustername}"
}

output "kubernetes_elbsecuritygroup"{
  value = "${aws_security_group.kops_elb_sg.id}"
}

output "kubernetes_masternode_type"{
  value = "${var.kubernetes_masternode_type}"
}

output "kubernetes_workernode_type"{
  value = "${var.kubernetes_workernode_type}"
}

# etcd count is defaulted to master count
output "kubernetes_masternode_count"{
  value = "${var.kubernetes_masternode_count}"
}

output "kubernetes_workernode_count"{
  value = "${var.kubernetes_workernode_count}"
}

output "kubernetes_masternode_image"{
  value = "${var.kubernetes_masternode_image}"
}

output "kubernetes_workernode_image"{
  value = "${var.kubernetes_workernode_image}"
}


#https://godoc.org/k8s.io/kops/pkg/apis/kops
#https://github.com/kubernetes/kops/blob/master/docs/cluster_spec.md