#!/usr/bin/env bash

line="---------------------------------------------------------------------------------------------------------------"

#vminsert=false
#vmstore=false
#vmselect=false
#vmagent=false

echo "Beginning tests"

echo $line

# test 1 verifies vmstorage
echo "Test 1: testing vmstorage"
res=$(curl -s 'http://192.168.0.5:8482/metrics' | grep vm_rows_added_to_storage_total | cut -d ' ' -f 2 )

echo query: "expect vm_rows_added_to_storage_total to be > 0"
echo result: $res
echo expect: "> 0"
if [[ $res -gt 0 ]]; then
  echo test: pass
  vmstore=true
else
  echo test: fail
fi

echo $line

# test 2 is vminsert
echo "Test 2: testing vminsert"
res=$(curl -s http://192.168.0.5:8480/metrics | grep vm_rows_inserted_total | grep promremotewrite | cut -d ' ' -f 2)
echo "test: vm_rows_inserted_total{type=\"promremotewrite\"} should be nonzero"
echo result: $res
echo expect: "> 0"
if [[ $res -gt 0 ]]; then
  echo test: pass
  vminsert=true
else
  echo test: fail
fi

echo $line

# test 2 verifies vmselect can query the storage engine
echo "Test 2: testing vmselect"
res=$(curl -s 'http://192.168.0.5:8481/select/0/prometheus/api/v1/query?query=irate(vm_rows_added_to_storage_total)' | jq ".data.result[].value[1]" | tr -d "\"" | cut -d '.' -f 1 )

echo query: "irate(vm_rows_added_to_storage_total)"
echo result: $res
echo expect: "> 10"
if [[ ! -z "$res" && $res -gt 10 ]]; then
  echo test: pass
  vmselect=true
else
  echo test: fail
fi

echo $line

# test 4 verifies that vmagent is able to scrape and dispatch to vminsert

echo "Test 4: testing vmagent"
write=$(curl -s 'http://192.168.0.5:8429/metrics' | grep vmagent_remotewrite_conn_writes_total | cut -d ' ' -f 2 )
writeerr=$(curl -s 'http://192.168.0.5:8429/metrics' | grep vmagent_remotewrite_conn_write_errors_total | cut -d ' ' -f 2 )

echo test: "write > 0 && writeerr == 0"
echo write: $write
echo writeerr: $writeerr
echo expect: "not equal"
if [[ "$writeerr" != "$write" && $write -gt "0" ]]; then
  echo test: pass
  vmagent=true
else
  echo test: fail
fi

echo "---------------------------------------------------------------------------------------------------------------"
if [[ ! -z "$vmstore"  ]]; then echo "vmstorage: ok"; else echo "vmstorage: failed"; fi
if [[ ! -z "$vmselect" ]]; then echo "vmselect:  ok"; else echo "vmselect:  failed"; fi
if [[ ! -z "$vminsert" ]]; then echo "vminsert:  ok"; else echo "vminsert:  failed"; fi
if [[ ! -z "$vmagent"  ]]; then echo "vmagent:   ok"; else echo "vmagent:   failed"; fi
if [[ -z "$vmstore" || -z "$vmselect" || -z "$vminsert" || -z "$vmagent" ]]; then echo "Platform is not functional"; else echo "Platform is stable"; fi