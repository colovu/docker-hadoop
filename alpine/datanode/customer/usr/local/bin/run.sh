#!/bin/bash

. /usr/local/bin/appcommon.sh			# 应用专用函数库

eval "$(app_env)"

hdfs --config ${APP_CONF_DIR} datanode