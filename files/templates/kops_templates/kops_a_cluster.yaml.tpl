apiVersion: kops/v1alpha2
kind: Cluster
metadata:
  name: {{.kubernetes_clustername.value}}
spec:
  kubeDNS:
    provider: CoreDNS
  api:
    dns: {}
    loadBalancer:
      securityGroupOverride: {{.kubernetes_elbsecuritygroup.value}}
      type: Internal
  authorization:
    rbac: {}
  channel: stable
  cloudProvider: aws
  configBase: s3://{{.kops_s3_bucket_name.value}}/{{.kubernetes_clustername.value}}
  etcdClusters:
  - etcdMembers:
  {{range $i, $az := .availability_zones.value}}
    - instanceGroup: master-{{.}}
      name: {{. | replace $.region.value "" }} {{/* converts eu-west-1a to a */}}
  {{end}}
    name: main
  - etcdMembers:
  {{range $i, $az := .availability_zones.value}}
    - instanceGroup: master-{{.}}
      name: {{. | replace $.region.value "" }} {{/* converts eu-west-1a to a */}}
  {{end}}
    name: events
  kubernetesVersion: 1.10.6
  masterInternalName: api.internal.{{ .kubernetes_clustername.value }}
  networkCIDR: {{.vpc_cidr_block.value}}
  networkID: {{.vpc_id.value}}
  networking:
    weave:
      mtu: 8912
  nonMasqueradeCIDR: 100.64.0.0/10
  subnets:
{{range $i, $id := .private_subnet_ids.value}}
  - id: {{.}}
    name: {{index $.availability_zones.value $i}}
    type: Private
    zone: {{index $.availability_zones.value $i}}
    egress: {{ $.nat_gateway_ids.value }}
{{end}}
  topology:
    dns:
      type: Private
    masters: private
    nodes: private
---
