aws_region = "us-east-1"
additional_users = ["sam","tom"]
aws_default_user = "bastion"


aws_instance_type = "t2.medium"
#temporary variable
instance_count = 1
aws_instancetags = {

"Name" = "D-AWS-Shore-bastion"
"vv.business.owner" = "vv"
"vv.business.location" = "shore"#(shore, ship)
"vv.app.name" = "bastion" #(cms, seaware, nbx, vxp,)
"vv.app.role" = "jump server" #(webserver, message server, app server, api server)
"vv.app.cluster" ="k8s" #(EMR, K8S)
"vv.app.priority" ="non-critical" #(critical/non-crtical)
"vv.app.customerFacing" = "No" #(Yes, No)
"vv.app.env"= "dev" #(dev, cert,staging,prod)
"vv.app.tech" ="jump box" #(magnolia)
"vv.app.service" ="jump box" #(jenkins, kafka, spinnaker)
"vv.app.tagVersion" ="1" #1
"vv.app.backupSchedule" = "weekely" # (DATE TIME)
"vv.app.runtime" = "online" #(ONLINE, BATCH)
"vv.cost.scheduleTime" = "AlwaysOn" #(AlwaysOn/Weekendoff)

}