# ec2ssm

# How to use

## configure profile

### Write ~/.aws/credentials 
```
# ~/.aws/credentials 

[default]
aws_access_key_id=....
aws_secret_access_key=....

[example]
region = ap-northeast-1
aws_access_key_id=....
aws_secret_access_key=....
```

## Install awscli

```
sudo pip3 install --upgrade awscli
```
- or
```
brew upgrade awscli
```

- if neither
```
rm /usr/local/bin/aws
brew install awscli
```

## Install ssm plugin

```
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo python3 sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
```

- reference
https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-macos

## Install some python packages
```
sudo pip3 install boto3 pexpect
```

## Install ec2ssm
```
cd ~
git clone https://github.com/yuhiwa/ec2ssm.git
cd ec2ssm
```

### Edit zsh setting
- add following to ~/.zshrc 
```
function ec2ssm { ~/ec2ssm/ec2ssm.py $1 $2 $3 }
function _ec2ssm { compadd $(cat ~/.aws_instances*) }
compdef _ec2ssm ec2ssm
```

## Update instance information
```
ec2ssm update
ec2ssm update --profile example
```
- In case of nothing profile option, default profile.


## Login instance (default profile)
```
ec2ssm test-web01
```
## Login instance (specific profile)
```
ec2ssm example-web01 --profile example
```



## In case of ssl errors
- need update python3
```
brew upgrade python3
pip3 install --upgrade awscli
brew switch openssl 1.0.2q
```

## User and passowrd option
- set env EC2USER, EC2PASSWORD, you can login its user automatically

## To do
- ec2ssm remove, all instance infomation file remove..
