# ssm-wrapper

# How to use

## Install ssm-wrapper
```
cd ~
git clone https://github.com/yuhiwa/ec2ssm.git
cd ec2ssm
```


## awscli

```
pip3 install --upgrade awscli
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

## ssm plugin install

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

## configure profile

### example
- .aws/config 
```
[default]
region = ap-northeast-1
aws_access_key_id=ABCDDDDXXXXX
aws_secret_access_key=aaaaaaaaaaaaaaaaaaaaa

[profile prod]
region = ap-northeast-1
aws_access_key_id=APRODDDDDDDDD
aws_secret_access_key=pppproorddddddxxxxxxx
```

### zsh setting
- add following to ~/.zshrc.local 
```
function ec2ssm { ~/ec2ssm/ec2ssm.py $1 $2 $3 }
function _ec2ssm { compadd $(cat ~/.aws_instances*) }
compdef _ec2ssm ec2ssm
```

## login instance (example)
```
ec2ssm example-web01
```
- refer to Name tag


## update instance information
```
ec2ssm update
ec2ssm update --profile prod
```
- In case of nothing profile option, default profile.

## in case of ssl errors
- need update python3
```
brew upgrade python3
pip3 install --upgrade awscli
brew switch openssl 1.0.2q
```

## user, passowrd option
- set env EC2USER, EC2PASSWORD, you can login its user automatically

