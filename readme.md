# Log-kit

This is a toolbox of scripts, log examples, regex pattern (to improve) and an env of ELk to make some tests

I used a lot of things from internet, but I would like to thank https://www.youtube.com/@jbravovideos for all his knowledge sharing



## Logsender 
A lot of logs examples into labfiles and also scripts to send logs

### logrun.py
Some scripts to send logs based on work from dpgbox@gmail.com.  
An example:  
```
cd logsender
./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --filename readme.syslog --sourceip 127.0.0.127 -v 1000
```
also you can automate sending logs with run_cases.sh that you can adapt with all labfiles.  

What's nice with udp is that you can spoof an other source IP.  

You'll find also some (maybe working) examples from internet in log-sender/inspiration.  


### installation
sudo apt-get install python3-scapy

or pipenv install  

## Send logs manually

### UDP
Sending manually some logs in udp, could be interesting with a simple copy/past of logs from labfiles:  
```
nc -u localhost 5000
```

with windows
https://www.microsoft.com/en-us/download/details.aspx?id=24009&wa=wsignin1.0
https://docs.microsoft.com/en-us/troubleshoot/windows-server/networking/portqry-command-line-port-scanner-v2

### TCP
Sending manually some logs in tcp, could be interesting with a simple copy/past of logs from labfiles:  
``` 
nc localhost 5000
telnet localhost 5000
```


## docker-elk-main
```
source .env
docker-compose up
docker-compose down -v //delete all volumes and builds
docker-compose rm -a //remove all
```

nb: docker-compose en version 1.25 > 1.29 un bug avec '' dans la définition des mots de passe il ne faut donc pas en mettre

### Get IP
```
docker exec docker-elk-main_logstash_1 cat /etc/hosts
```
172.21.0.4

Also you'll find in docker-elk-main/logstash/pipeline a pipeline configuration to digest logs :)

### Users
elastic
changeme

## Jupyter
A small docker compose and example to access Elastic database to make request directly to index

## Regex-pattern
An intent to collect various guides for creating regex.  


