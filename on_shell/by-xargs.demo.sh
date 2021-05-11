
# simple eg

## ssh
awk /clustertest/{print\$1} /etc/hosts | xargs -P1 -i{x} ssh -n {x} bash\ -c\ 'hostname -i'
## kube
kubectl get po | awk /clustertest/{print\$1} | xargs -P0 -i{x} kubectl exec {x} -- bash -c 'echo '"'"{x}"'"' ; hostname'

### 可以看出，用 xargs 的好处在于，并发度非常容易控制，要停止也非常容易
### 并且，即便在并发的情况下，用 xargs 仍然能够让同一个进程的打印能够在一起，而不是像自己写放后台并发那样全乱套
