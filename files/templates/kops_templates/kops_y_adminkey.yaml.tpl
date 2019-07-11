apiVersion: kops/v1alpha2
kind: SSHCredential
metadata:
  labels:
    kops.k8s.io/cluster: {{ .kubernetes_clustername.value}}
spec:
  publicKey: "{{ .kubernetes_adminpubkey.value }}"