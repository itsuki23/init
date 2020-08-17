ec2 info
```s
.bashrc
---
function aws_ec2_ls(){
  command aws ec2 --profile $1 describe-instances | jq -r '.Reservations[] | .Instances[] | select(.State.Name != "terminated") | select(has("PublicIpAddress")) | [.PublicIpAddress,.PrivateIpAddress,.State.Name,(.Tags[] | select(.Key == "Name") | .Value // "")] | join("\t")' 
}
```