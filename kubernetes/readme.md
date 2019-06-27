#### ../files/templates/kops_templates/ subfolder inside the templates folder specific to kops rendering

```
kops_cluster.yaml.tpl for cluster template
kops_master.yaml.tpl for master template
kops_nodes.yaml.tpl for worker template


```


### Shell Commands to create Kubernetes Cluster yaml

```
TF_OUTPUT=$(terraform output -json)
kops toolbox --v=4 template --name ${CLUSTER_NAME} --values <( echo ${TF_OUTPUT}) --template ../files/templates/kops_templates/ --format-yaml > cluster.yaml
KOPS_STATE_STORE="s3://$(echo ${TF_OUTPUT} | jq -r .kops_s3_bucket_name.value)"
CLUSTER_NAME="$(echo ${TF_OUTPUT} | jq -r .kubernetes_clustername.value)"
kops create -f cluster.yaml -v=5
kops update cluster kopsdev.com --yes

```


###ToDo
```
SSH public key must be specified when running with AWS (create with `kops create secret --name kopsdev.com sshpublickey admin -i ~/.ssh/id_rsa.pub`)
```



### References:

https://godoc.org/k8s.io/kops/pkg/apis/kops
https://github.com/kubernetes/kops/blob/master/docs/cluster_spec.md
https://golang.org/pkg/text/template/