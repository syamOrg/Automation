apiVersion: kops/v1alpha2
kind: InstanceGroup
metadata:
  labels:
    kops.k8s.io/cluster: {{$.kubernetes_clustername.value}}
  name: master-us-east-1c
spec:
  image: {{ $.kubernetes_masternode_image.value}}
  kubernetesVersion: 1.10.6
  machineType: {{ $.kubernetes_masternode_type.value}}
  rootVolumeSize: 100
  rootVolumeType: gp2
  maxSize: 1
  minSize: 1
  nodeLabels:
    kops.k8s.io/instancegroup: master-us-east-1c
  role: Master
  subnets:
  - us-east-1c
---
