apiVersion: kops/v1alpha2
kind: Cluster
metadata:
  name: {{.cluster_name.value}}
spec:
  api:
    loadBalancer:
      type: Public
      additionalSecurityGroups: ["{{.k8s_api_http_security_group_id.value}}"]
  authorization:
    rbac: {}
  channel: stable
  cloudProvider: aws
  configBase: s3://{{.kops_s3_bucket_name.value}}/{{.cluster_name.value}}
  # Create one etcd member per AZ
  etcdClusters:
  - etcdMembers:
  {{range $i, $az := .availability_zones.value}}
    - instanceGroup: master-{{.}}
      name: {{. | replace $.region.value "" }}
  {{end}}
    name: main
  - etcdMembers:
  {{range $i, $az := .availability_zones.value}}
    - instanceGroup: master-{{.}}
      name: {{. | replace $.region.value "" }}
  {{end}}
    name: events
  iam:
    allowContainerRegistry: true
    legacy: false
  kubernetesVersion: 1.11.6
  masterPublicName: api.{{.cluster_name.value}}
  networkCIDR: {{.vpc_cidr_block.value}}
  kubeControllerManager:
    clusterCIDR: {{.vpc_cidr_block.value}}
  kubeProxy:
    clusterCIDR: {{.vpc_cidr_block.value}}
  networkID: {{.vpc_id.value}}
  kubelet:
    anonymousAuth: false
  networking:
    amazonvpc: {}
  nonMasqueradeCIDR: {{.vpc_cidr_block.value}}
  sshAccess:
  - 0.0.0.0/0
  subnets:
  # Public (utility) subnets, one per AZ
  {{range $i, $id := .public_subnet_ids.value}}
  - id: {{.}}
    name: utility-{{index $.availability_zones.value $i}}
    type: Utility
    zone: {{index $.availability_zones.value $i}}
  {{end}}
  # Private subnets, one per AZ
  {{range $i, $id := .private_subnet_ids.value}}
  - id: {{.}}
    name: {{index $.availability_zones.value $i}}
    type: Private
    zone: {{index $.availability_zones.value $i}}
    egress: {{index $.nat_gateway_ids.value 0}}
  {{end}}
  topology:
    bastion:
      bastionPublicName: bastion.{{.cluster_name.value}}
    dns:
      type: Public
    masters: private
    nodes: private
---

# Create one master per AZ
{{range .availability_zones.value}}
apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  labels:
    kops.k8s.io/cluster: {{$.cluster_name.value}}
  name: master-{{.}}
spec:
  image: kope.io/k8s-1.11-debian-stretch-amd64-hvm-ebs-2018-08-17
  machineType: t2.medium
  maxSize: 1
  minSize: 1
  role: Master
  nodeLabels:
    kops.k8s.io/instancegroup: master-{{.}}
  subnets:
  - {{.}}
---
  {{end}}

apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  labels:
    kops.k8s.io/cluster: {{.cluster_name.value}}
  name: nodes
spec:
  image: kope.io/k8s-1.11-debian-stretch-amd64-hvm-ebs-2018-08-17
  machineType: t2.small
  maxSize: 2
  minSize: 2
  role: Node
  nodeLabels:
    kops.k8s.io/instancegroup: nodes
  subnets:
  {{range .availability_zones.value}}
  - {{.}}
  {{end}}
---

apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  labels:
    kops.k8s.io/cluster: {{.cluster_name.value}}
  name: bastions
spec:
  image: kope.io/k8s-1.11-debian-stretch-amd64-hvm-ebs-2018-08-17
  machineType: t2.micro
  maxSize: 1
  minSize: 1
  nodeLabels:
    kops.k8s.io/instancegroup: bastions
  role: Bastion
  subnets:
  {{range .availability_zones.value}}
  - utility-{{.}}
  {{end}}