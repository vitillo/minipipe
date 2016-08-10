#!/bin/bash

function wait() {
    while [ $(kubectl get pods | awk '{print $3}' | tail -n +2 | grep -v Running | wc -l) != 0 ]; do
        sleep 1
    done
}

function start() {
    kubectl create -f ./minipipe/zookeeper.yaml && wait
    kubectl create -f ./minipipe/hdfs.yaml && wait
    kubectl create -f ./minipipe/kafka.yaml && wait
    kubectl create -f ./minipipe/metastore.yaml && wait
    kubectl create -f ./minipipe/presto.yaml && wait
}

function delete() {
    kubectl delete -f minipipe
}

cd "$(dirname "$0")"
while [ $# -gt 0 ]; do
    case "$1" in
        --start)
            start
            ;;
        --delete)
            delete
            ;;
        -*)
            # do not exit out, just note failure
            echo 1>&2 "unrecognized option: $1"
            ;;
        *)
            break;
            ;;
    esac
    shift
done
