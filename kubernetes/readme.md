TF_OUTPUT=$(terraform output -json)
CLUSTER_NAME="$(echo ${TF_OUTPUT} | jq -r .kubernetes_clustername.value)"
kops toolbox template --name ${CLUSTER_NAME} --values <( echo ${TF_OUTPUT}) --template ../files/templates/kops.yaml.tpl --format-yaml > cluster.yaml

STATE="s3://$(echo ${TF_OUTPUT} | jq -r .kops_s3_bucket.value)"
kops replace -f cluster.yaml --state ${STATE} --name ${CLUSTER_NAME} --force
kops update cluster --target terraform --state ${STATE} --name ${CLUSTER_NAME} --out .

kops create secret --name ${CLUSTER_NAME} --state ${STATE} --name ${CLUSTER_NAME} sshpublickey admin -i ~/.ssh/id_rsa.pub
kops export kubecfg --name ${CLUSTER_NAME} --state ${STATE}
kubectl config set-cluster ${CLUSTER_NAME} --server=https://api.${CLUSTER_NAME}

#https://godoc.org/k8s.io/kops/pkg/apis/kops
#https://github.com/kubernetes/kops/blob/master/docs/cluster_spec.md
#https://golang.org/pkg/text/template/