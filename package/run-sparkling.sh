#!/usr/bin/env bash

# Current dir
TOPDIR=$(cd "$(dirname "$0")/.."; pwd)

source "$TOPDIR/bin/sparkling-env.sh"
# Verify there is Spark installation
checkSparkHome
# Verify if correct Spark version is used
checkSparkVersion
# Check sparkling water assembly Jar exists
checkFatJarExists
DRIVER_CLASS=ai.h2o.sparkling.SparklingWaterDriver

DRIVER_MEMORY=${DRIVER_MEMORY:-$DEFAULT_DRIVER_MEMORY}
MASTER=${MASTER:-"$DEFAULT_MASTER"}
VERBOSE=--verbose
VERBOSE=
if [ -f "$SPARK_HOME"/conf/spark-defaults.conf ]; then
    EXTRA_DRIVER_PROPS=$(grep "^spark.driver.extraJavaOptions" "$SPARK_HOME"/conf/spark-defaults.conf 2>/dev/null | sed -e 's/spark.driver.extraJavaOptions//' )
fi

EXTRA_DRIVER_PROPS+=" -DsparklingServiceName="$EGOSC_SERVICE_NAME" -Dai.h2o.flow_dir="$NOTEBOOK_DATA_DIR

# Show banner
banner 

if [ -z "$H2O_SPARK_CONF" ]; then
    H2O_SPARK_CONF=""
fi

if [ ! -z "$EGO_DATACONNECTOR" ]; then
    H2O_SPARK_CONF+=" --conf spark.ego.dataconnectors=$EGO_DATACONNECTOR"
fi

if [ ! -z "$EGO_DEFAULT_FS_DC" ]; then
    H2O_SPARK_CONF+=" --conf spark.ego.dataconnectors.defaultfs=$EGO_DEFAULT_FS_DC"
fi

if [ ! -z "$EGO_IMPERSONATE_CREDENTIAL" ]; then
    H2O_SPARK_CONF+=" --conf spark.ego.credential=$EGO_IMPERSONATE_CREDENTIAL"
elif [ ! -z "$EGO_SERVICE_CREDENTIAL" ]; then
    H2O_SPARK_CONF+=" --conf spark.ego.credential=$EGO_SERVICE_CREDENTIAL"
fi

if [ ! -z "$HIVE_DELEGATION_TOKEN_CREATION_COMMAND" ]; then
    HIVE_DELEGATION_TOKEN=$(eval "$HIVE_DELEGATION_TOKEN_CREATION_COMMAND")
    H2O_SPARK_CONF+=" --conf spark.ext.h2o.hive.token=$HIVE_DELEGATION_TOKEN"	
fi 

if [ -z "$EXTRA_DRIVER_CLASS_PATH" ]; then 
    EXTRA_DRIVER_CLASS_PATH="$TOPDIR/jars/httpclient-4.5.2.jar"
else
    EXTRA_DRIVER_CLASS_PATH+=":$TOPDIR/jars/httpclient-4.5.2.jar"
fi

if [ -z "$EXTRA_EXECUTOR_CLASS_PATH" ]; then 
    EXTRA_EXECUTOR_CLASS_PATH="$TOPDIR/jars/httpclient-4.5.2.jar"
else
    EXTRA_EXECUTOR_CLASS_PATH+=":$TOPDIR/jars/httpclient-4.5.2.jar"
fi

if [ "${NOTEBOOK_SSL_ENABLED}" == "true" ]; then
        spark-submit "$@" $VERBOSE --driver-class-path "$EXTRA_DRIVER_CLASS_PATH" --conf "spark.executor.extraClassPath=$EXTRA_EXECUTOR_CLASS_PATH" --driver-memory "$DRIVER_MEMORY" --master "$MASTER" $H2O_SPARK_CONF --conf spark.ext.h2o.jks="$H2O_KEYSTORE" --conf spark.ext.h2o.jks.pass=h2oh2o --conf spark.ext.h2o.internal.rest.verify_ssl_certificates=false --conf spark.driver.extraJavaOptions="$EXTRA_DRIVER_PROPS" --class "$DRIVER_CLASS" "$FAT_JAR_FILE"
else
	spark-submit "$@" $VERBOSE --driver-class-path "$EXTRA_DRIVER_CLASS_PATH" --conf "spark.executor.extraClassPath=$EXTRA_EXECUTOR_CLASS_PATH" --driver-memory "$DRIVER_MEMORY" --master "$MASTER" $H2O_SPARK_CONF --conf spark.driver.extraJavaOptions="$EXTRA_DRIVER_PROPS" --class "$DRIVER_CLASS" "$FAT_JAR_FILE"
fi

