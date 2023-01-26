helm upgrade --install --namespace kube-system aws-vpc-cni eks/aws-vpc-cni \
         --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::824331038818:role/plt-or-test-k8s-role-aws-nodeau5b
