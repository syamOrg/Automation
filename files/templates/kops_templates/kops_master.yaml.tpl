apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  labels:
    kops.k8s.io/cluster: {{ .kubernetes_clustername.value}}
  name: master
spec:
  image: {{ .kubernetes_masternode_image.value}}
  kubernetesVersion: 1.10.6
  machineType: {{ .kubernetes_masternode_type.value}}
  rootVolumeSize: 100
  rootVolumeType: gp2
  maxSize: 1
  minSize: 1
  nodeLabels:
    kops.k8s.io/instancegroup: master
  role: Master
  subnets:
  {{range $i, $az := .availability_zones.value}}
  - {{.}}
  {{end}}
---
