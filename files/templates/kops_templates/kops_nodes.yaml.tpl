apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  labels:
    kops.k8s.io/cluster: {{.kubernetes_clustername.value}}
  name: nodes
spec:
  image: {{ .kubernetes_workernode_image.value}}
  kubernetesVersion: 1.10.6
  machineType: {{.kubernetes_workernode_type.value}}
  maxSize: 2
  minSize: 2
  rootVolumeSize: 100
  rootVolumeType: gp2
  nodeLabels:
    kops.k8s.io/instancegroup: nodes
  role: Node
  subnets:
{{range $i, $az := .availability_zones.value}}
  - {{.}}
  {{end}}
---
