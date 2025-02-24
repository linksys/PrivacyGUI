#!/uer/bin/bash

 #base64 encode
  base64Encode(){
    local password=$1
    echo -n "admin:${password}" | base64
  }
  base64Decode(){
    local str=$1
    echo -n $str | base64 -d
  }

  action=$1
  password=$(base64Encode $2)
  echo $action
  if [ -z "$action" ] || [ -z "$password" ]; then
    echo "Usage: $0 <action> <password>"
    exit 1
  fi

  echo base64 encode: $password
  
  curl 'https://localhost/JNAP/' \
  -H 'Accept: text/plain, */*; q=0.01' \
  -H 'Content-Type: application/json;charset=UTF-8' \
  -H "X-JNAP-Action: $action" \
  -H "X-JNAP-Authorization: Basic $password" \
  --data-raw $'{}'