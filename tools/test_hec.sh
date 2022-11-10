#!/bin/bash

HEC_HOST="127.0.0.1"
HEC_PORT="8088"
HEC_TOKEN=""
OUTFILE="json_data.txt"
TIME="$(date +'%s')"

HOST=""

(
cat <<EOF
{"time": $TIME,
"event": {
"startTime": 1538630771187,
"finishTime": 1538630787446,
"elapsedTime": 16259,
"progress": 100.0,
"id": "attempt_1538604110704_7819_m_000003_1",
"rack": "/default-rack",
"state": "FAILED",
"status": "",
"nodeHttpAddress": "abc.example.com:8042",
"diagnostics": "Error: java.lang.RuntimeException: org.apache.hadoop.hive.ql.metadata.HiveException: Hive Runtime Error while processing row {\"cust_xref_id\":2040912099,\"phone1\":\"8717336186\",\"phone2\":\":\",\"phone3\":null,\"phone4\":null}\n\tat org.apache.hadoop.hive.ql.exec.mr.ExecMapper.map(ExecMapper.java:172)\n\tat org.apache.hadoop.mapred.MapRunner.run(MapRunner.java:54)\n\tat org.apache.hadoop.mapred.MapTask.runOldMapper(MapTask.java:458)\n\tat
org.apache.hadoop.mapred.MapTask.run(MapTask.java:348)\n\tat org.apache.hadoop.mapred.YarnChild$2.run(YarnChild.java:163)\n\tat java.security.AccessController.doPrivileged(Native Method)\n\tat javax.security.auth.Subject.doAs(Subject.java:422)\n\tat org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1633)\n\tat org.apache.hadoop.mapred.YarnChild.main(YarnChild.java:158)\nCaused by: org.apache.hadoop.hive.ql.metadata.HiveException: Hive Runtime Error while processing
row {\"cust_xref_id\":2040912099,\"phone1\":\"8717336186\",\"phone2\":\":\",\"phone3\":null,\"phone4\":null}\n\tat org.apache.hadoop.hive.ql.exec.MapOperator.process(MapOperator.java:546)\n\tat org.apache.hadoop.hive.ql.exec.mr.ExecMapper.map(ExecMapper.java:163)\n\t... 8 more\nCaused by: org.apache.hadoop.hive.ql.metadata.HiveException: Unable to execute method public org.apache.hadoop.io.Text
com.example.abc.c360.hive.udf.naamex.standardization.PhoneStandardizerUDF.evaluate(org.apache.hadoop.io.Text,java.util.Map)  on object com.example.abc.c360.hive.udf.naamex.standardization.PhoneStandardizerUDF@1a411233 of class com.example.abc.c360.hive.udf.naamex.standardization.PhoneStandardizerUDF with arguments {::org.apache.hadoop.io.Text, {country_code=FRA}:java.util.HashMap} of size 2\n\tat org.apache.hadoop.hive.ql.exec.FunctionRegistry.invoke(FunctionRegistry.java:981)\n\tat
org.apache.hadoop.hive.ql.udf.generic.GenericUDFBridge.evaluate(GenericUDFBridge.java:182)\n\tat org.apache.hadoop.hive.ql.exec.ExprNodeGenericFuncEvaluator._evaluate(ExprNodeGenericFuncEvaluator.java:186)\n\tat org.apache.hadoop.hive.ql.exec.ExprNodeEvaluator.evaluate(ExprNodeEvaluator.java:77)\n\tat org.apache.hadoop.hive.ql.exec.ExprNodeEvaluatorHead._evaluate(ExprNodeEvaluatorHead.java:44)\n\tat org.apache.hadoop.hive.ql.exec.ExprNodeEvaluator.evaluate(ExprNodeEvaluator.java:77)\n\tat
org.apache.hadoop.hive.ql.exec.ExprNodeEvaluator.evaluate(ExprNodeEvaluator.java:65)\n\tat org.apache.hadoop.hive.ql.exec.SelectOperator.process(SelectOperator.java:81)\n\tat org.apache.hadoop.hive.ql.exec.Operator.forward(Operator.java:838)\n\tat org.apache.hadoop.hive.ql.exec.TableScanOperator.process(TableScanOperator.java:97)\n\tat org.apache.hadoop.hive.ql.exec.MapOperator$MapOpCtx.forward(MapOperator.java:165)\n\tat
org.apache.hadoop.hive.ql.exec.MapOperator.process(MapOperator.java:536)\n\t... 9 more\nCaused by: java.lang.reflect.InvocationTargetException\n\tat sun.reflect.GeneratedMethodAccessor4.invoke(Unknown Source)\n\tat sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)\n\tat java.lang.reflect.Method.invoke(Method.java:498)\n\tat org.apache.hadoop.hive.ql.exec.FunctionRegistry.invoke(FunctionRegistry.java:957)\n\t... 20 more\nCaused by:
java.lang.ArrayIndexOutOfBoundsException: 0\n\tat com.example.abc.cr2020.naamex.standardization.phone.PhoneStandardizer.getStandardizeMap(PhoneStandardizer.java:80)\n\tat com.eaxmple.abc.cr2020.naamex.standardization.phone.PhoneStandardizer.standardize(PhoneStandardizer.java:57)\n\tat com.example.abc.c360.hive.udf.naamex.standardization.PhoneStandardizerUDF.evaluate(PhoneStandardizerUDF.java:30)\n\t... 24 more\n",
"type": "MAP",
"assignedContainerId": "container_e133_1538604110704_7219_01_000023"
}}
EOF
) > $OUTFILE

curl -vk -H "Authorization: Splunk $HEC_TOKEN" https://${HEC_HOST}:${HEC_PORT}/services/collector/event -d @$OUTFILE

rm -f $OUTFILE

