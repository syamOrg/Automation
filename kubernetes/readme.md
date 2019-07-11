#### ../files/templates/kops_templates/ subfolder inside the templates folder specific to kops rendering

```
kops_cluster.yaml.tpl for cluster template
kops_master.yaml.tpl for master template
kops_nodes.yaml.tpl for worker template
kops_adminkey.yaml.tpl for cluster admin key template
 kops_dashboard.yaml for kubernetes dashboard

```


### Shell Commands to create Kubernetes Cluster yaml

```

TF_OUTPUT=$(terraform output -json)
export CLUSTER_NAME="$(echo ${TF_OUTPUT} | jq -r .kubernetes_clustername.value)"
export KOPS_STATE_STORE="s3://$(echo ${TF_OUTPUT} | jq -r .kops_s3_bucket_name.value)"
kops toolbox --v=4 template --name=${CLUSTER_NAME} --values <( echo ${TF_OUTPUT}) --template ../files/templates/kops_templates --format-yaml > cluster.yaml
kops create -f cluster.yaml -v=5

# Higher Version of kops >= 1.11 is required for the over ride security group prameter to be considered if not the template revokes the config 
kops update cluster --name ${CLUSTER_NAME} --yes --lifecycle-overrides SecurityGroup=ExistsAndWarnIfChanges,SecurityGroupRule=ExistsAndWarnIfChanges


# Incase Any additions are needed
kops edit cluster --name ${CLUSTER_NAME}
# Delete Cluster 
kops delete cluster --name ${CLUSTER_NAME} --yes

```
###Dashboard

```
# The kubeconfig should exist prior to executing the commands
# From Bastion
kubectl apply -f kops_dashboard.yaml 

kubectl porxy 
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/.


kubectl -n kube-system get secret
# Use any test token for test purpose to login into the dashboard
kubectl -n kube-system describe secrets service-controller-token-wsjxl
```

###ToDo



### References:

https://godoc.org/k8s.io/kops/pkg/apis/kops
https://github.com/kubernetes/kops/blob/master/docs/cluster_spec.md
https://golang.org/pkg/text/template/
https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-windows
https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
https://github.com/kubernetes/kops/blob/master/docs/security_groups.md
https://github.com/kubernetes/kops/blob/master/pkg/apis/kops/instancegroup.go#L229
https://github.com/kubernetes/kops/releases/tag/1.12.2 
https://www.terraform.io/docs/providers/aws/d/iam_policy_document.html
https://github.com/kubernetes/dashboard/wiki/Access-control#login-view

```
Parameter: 
securityGroupOverride
additionalSecurityGroups
```


### Changelog: 

```
Custom IAM Policies
Custom Security Groups 
Kubernetes Dashboard
Windows Bastion.tf file which is not included by default
Add force_detach_policies, force_delete to prevent issues during terraform destroy
```