#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
# 
# 应用通用业务处理函数

# 加载依赖脚本
. /usr/local/scripts/libcommon.sh       # 通用函数库

. /usr/local/scripts/libfile.sh
. /usr/local/scripts/libfs.sh
. /usr/local/scripts/libos.sh
. /usr/local/scripts/libservice.sh
. /usr/local/scripts/libvalidations.sh

# 函数列表

# 使用环境变量中以 "<PREFIX>" 开头的的全局变量更新指定配置文件中对应项（以"."分隔）
# 如果需要全部转换为小写，可使用命令： tr '[:upper:]' '[:lower:]'
# 全局变量:
#   <PREFIX>_* : 
#       替换规则（变量中字符  ==>  替换后全局变量中字符）：
#           - "." ==> "_"
#           - "_" ==> "__"
#           - "-" ==> "___"
#           
# 变量：
#   $1 - 配置文件
#   $2 - 前缀(不含结束的"_")
#   
# 举例：
#   CORE_CONF_fs_defaultFS 对应配置文件中的配置项：fs.defaultFS
hadoop_configure_from_environment() {
    local path="${1:?missing file}"
    local envPrefix="${2:?missing parameters}"

    LOG_D "  File: ${path}"
    # Map environment variables to config properties
    #for var in `printenv | grep ${envPrefix} | "${!${envPrefix}_@}"`; do
    #    LOG_D "  Process: ${!var}"
    #    key="$(echo "${!var}" | sed -e 's/^${envPrefix}_//g' -e 's/___/-/g' -e 's/__/_/g' -e 's/_/\./g')"
    #    value="${var}"
    #    hadoop_common_xml_set "${path}"  "${key}" "${value}"
    #done
    #for var in $(printenv | grep ${envPrefix}); do
    #    LOG_D "  Process: ${!var}"
    #    key="$(echo "${!var}" | sed -e 's/^${envPrefix}_//g' -e 's/___/-/g' -e 's/__/_/g' -e 's/_/\./g' )"
    #    value="${var}"
    #    hadoop_common_xml_set "${path}" "${key}" "${value}"
    #done
    for c in `printenv | perl -sne 'print "$1 " if m/^${envPrefix}_(.+?)=.*/' -- -envPrefix=${envPrefix}`; do 
        name=`echo ${c} | perl -pe 's/___/-/g; s/__/_/g; s/_/./g;'`
        key="${envPrefix}_${c}"
        #LOG_D "  Process: ${key} => ${!key}"
        value="${!key}"
        hadoop_common_xml_set "${path}" "${name}" "${value}"
    done
}

# 将变量配置更新至配置文件
# 参数:
#   $1 - 文件
#   $2 - 变量
#   $3 - 值（列表）
hadoop_common_conf_set() {
    local file="${1:?missing file}"
    local key="${2:?missing key}"
    shift
    shift
    local values=("$@")

    if [[ "${#values[@]}" -eq 0 ]]; then
        LOG_E "missing value"
        return 1
    elif [[ "${#values[@]}" -ne 1 ]]; then
        for i in "${!values[@]}"; do
            hadoop_common_conf_set "$file" "${key[$i]}" "${values[$i]}"
        done
    else
        value="${values[0]}"
        # Check if the value was set before
        if grep -q "^[#\\s]*$key\s*=.*" "$file"; then
            # Update the existing key
            replace_in_file "$file" "^[#\\s]*${key}\s*=.*" "${key} = \'${value}\'" false
        else
            # 增加一个新的配置项；如果在其他位置有类似操作，需要注意换行
            printf "%s = %s" "$key" "$value" >>"$file"
        fi
    fi
}

# 将变量配置更新至 xml 配置文件
# 参数:
#   $1 - 文件
#   $2 - 变量
#   $3 - 值（列表）
hadoop_common_xml_set() {
    local path="${1:?missing file}"
    local name="${2:?missing key}"
    local value="${3:?missing value}"

    local entry="<property><name>${name}</name><value>${value}</value></property>"
    # 将参数中的 '/' 替换为 '\/', '*' 替换为 '\*' 以使得参数可以放置在后续的 sed 命令中
    local escapedEntry=$(echo $entry | sed 's/\//\\\//g' | sed 's/\*/\\\*/g')

    LOG_D "  Property: ${name} = ${value}"

    if grep -q "^[#\\s]*${escapedEntry}.*" "$path"; then
        # 跳过已存在且参数值相同的配置项
        LOG_D "    Skip property: ${name}"
        :;
    elif grep -q "^[#\\s]*<property><name>${name}<\/name>.*" "$path"; then
        # 更新已存在的配置项
        LOG_D "    Update property: ${name}"
        replace_in_file "${path}" "^[#\\s]*<property><name>${name}<\/name>.*" "${escapedEntry}" false
        #sed -i "/<property><name>${name}<\/name>.*/${escapedEntry}/" "${path}"
    else
        # 增加一个新的配置项；如果在其他位置有类似操作，需要注意换行
        sed -i "/<\/configuration>/ s/.*/${escapedEntry}\n&/" "${path}"
        LOG_D "    Add new property: ${name}"
    fi
}

# 更新 core-site.xml 配置文件中指定变量值
# 变量:
#   $1 - 变量
#   $2 - 值（列表）
hadoop_core_set() {
    hadoop_common_xml_set "${APP_CONF_DIR}/core-site.xml" "$@"
}

# 更新 hdfs-site.xml 配置文件中指定变量值
# 变量:
#   $1 - 变量
#   $2 - 值（列表）
hadoop_hdfs_set() {
    hadoop_common_xml_set "${APP_CONF_DIR}/hdfs-site.xml" "$@"
}

# 更新 yarn-site.xml 配置文件中指定变量值
# 变量:
#   $1 - 变量
#   $2 - 值（列表）
hadoop_yarn_set() {
    hadoop_common_xml_set "${APP_CONF_DIR}/yarn-site.xml" "$@"
}

# 更新 mapred-site.xml 配置文件中指定变量值
# 变量:
#   $1 - 变量
#   $2 - 值（列表）
hadoop_mapred_set() {
    hadoop_common_xml_set "${APP_CONF_DIR}/mapred-site.xml" "$@"
}

# 更新 log4j.properties 配置文件中指定变量值
# 变量:
#   $1 - 变量
#   $2 - 值（列表）
hadoop_log4j_set() {
    hadoop_common_conf_set "${APP_CONF_DIR}/log4j.properties" "$@"
}

# 使用环境变量中配置，更新配置文件
hadoop_update_conf() {
    LOG_I "Update configure files..."

    LOG_D "Update configure file for core"
    hadoop_configure_from_environment ${APP_CONF_DIR}/core-site.xml CORE_CONF

    LOG_D "Update configure file for hdfs"
    hadoop_configure_from_environment ${APP_CONF_DIR}/hdfs-site.xml HDFS_CONF

    LOG_D "Update configure file for yarn"
    hadoop_configure_from_environment ${APP_CONF_DIR}/yarn-site.xml YARN_CONF

    LOG_D "Update configure file for httpfs"
    hadoop_configure_from_environment ${APP_CONF_DIR}/httpfs-site.xml HTTPFS_CONF

    LOG_D "Update configure file for kms"
    hadoop_configure_from_environment ${APP_CONF_DIR}/kms-site.xml KMS_CONF

    LOG_D "Update configure file for mapred"
    hadoop_configure_from_environment ${APP_CONF_DIR}/mapred-site.xml MAPRED_CONF
}

# 生成默认配置文件
hadoop_generate_conf() {
    LOG_I "Generate Base configure files..."

    hadoop_update_conf

    hadoop_log4j_set "hadoop.log.dir" "${APP_LOG_DIR}"
}

# 针对 GANGLIA_HOST 修改配置
hadoop_ganglia_host_conf() {
    LOG_I "Generate Ganglia configure files..."

    [ -f ${APP_CONF_DIR}/hadoop-metrics.properties ] && mv ${APP_CONF_DIR}/hadoop-metrics.properties ${APP_CONF_DIR}/hadoop-metrics.properties.orig
    [ -f ${APP_CONF_DIR}/hadoop-metrics2.properties ] && mv ${APP_CONF_DIR}/hadoop-metrics2.properties ${APP_CONF_DIR}/hadoop-metrics2.properties.orig

    for module in mapred jvm rpc ugi; do
        echo "$module.class=org.apache.hadoop.metrics.ganglia.GangliaContext31"
        echo "$module.period=10"
        echo "$module.servers=${GANGLIA_HOST}:8649"
    done > ${APP_CONF_DIR}/hadoop-metrics.properties
    
    for module in namenode datanode resourcemanager nodemanager mrappmaster jobhistoryserver; do
        echo "$module.sink.ganglia.class=org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31"
        echo "$module.sink.ganglia.period=10"
        echo "$module.sink.ganglia.supportsparse=true"
        echo "$module.sink.ganglia.slope=jvm.metrics.gcCount=zero,jvm.metrics.memHeapUsedM=both"
        echo "$module.sink.ganglia.dmax=jvm.metrics.threadsBlocked=70,jvm.metrics.memHeapUsedM=40"
        echo "$module.sink.ganglia.servers=${GANGLIA_HOST}:8649"
    done > ${APP_CONF_DIR}/hadoop-metrics2.properties
}

# 针对 MULTIHOMED_NETWORK 修改配置
hadoop_multihome_network_conf() {
    LOG_I "Configuring for multihomed network"

    # HDFS
    hadoop_hdfs_set dfs.namenode.rpc-bind-host 0.0.0.0
    hadoop_hdfs_set dfs.namenode.servicerpc-bind-host 0.0.0.0
    hadoop_hdfs_set dfs.namenode.lifeline.rpc-bind-host 0.0.0.0
    hadoop_hdfs_set dfs.namenode.http-bind-host 0.0.0.0
    hadoop_hdfs_set dfs.namenode.https-bind-host 0.0.0.0
    hadoop_hdfs_set dfs.journalnode.rpc-bind-host 0.0.0.0
    hadoop_hdfs_set dfs.journalnode.http-bind-host 0.0.0.0
    hadoop_hdfs_set dfs.journalnode.https-bind-host 0.0.0.0

    # YARN
    hadoop_yarn_set yarn.resourcemanager.bind-host 0.0.0.0
    hadoop_yarn_set yarn.nodemanager.bind-host 0.0.0.0
    hadoop_yarn_set yarn.web-proxy.bind-host 0.0.0.0
    hadoop_yarn_set yarn.timeline-service.bind-host 0.0.0.0
    hadoop_yarn_set yarn.router.bind-host 0.0.0.0
    hadoop_yarn_set yarn.timeline-service.reader.bind-host 0.0.0.0
}

# 设置环境变量 JVMFLAGS
# 参数:
#   $1 - value
hadoop_export_jvmflags() {
    local -r value="${1:?value is required}"

    export JVMFLAGS="${JVMFLAGS} ${value}"
    echo "export JVMFLAGS=\"${JVMFLAGS}\"" > "${APP_CONF_DIR}/java.env"
}

# 配置 HEAP 大小
# 参数:
#   $1 - HEAP 大小
hadoop_configure_heap_size() {
    local -r heap_size="${1:?heap_size is required}"

    if [[ "${JVMFLAGS}" =~ -Xm[xs].*-Xm[xs] ]]; then
        LOG_D "Using specified values (JVMFLAGS=${JVMFLAGS})"
    else
        LOG_D "Setting '-Xmx${heap_size}m -Xms${heap_size}m' heap options..."
        hadoop_export_jvmflags "-Xmx${heap_size}m -Xms${heap_size}m"
    fi
}

# 检测用户参数信息是否满足条件; 针对部分权限过于开放情况，打印提示信息
hadoop_verify_minimum_env() {
    local error_code=0

    LOG_D "Validating settings in HADOOP_* env vars..."

    print_validation_error() {
        LOG_E "$1"
        error_code=1
    }

    # 检测认证设置。如果不允许匿名登录，检测登录用户名及密码是否设置
#    if is_boolean_yes "$ALLOW_ANONYMOUS_LOGIN"; then
#        LOG_W "You have set the environment variable ALLOW_ANONYMOUS_LOGIN=${ALLOW_ANONYMOUS_LOGIN}. For safety reasons, do not use this flag in a production environment."
#    elif ! is_boolean_yes "$ZOO_ENABLE_AUTH"; then
#        print_validation_error "The ZOO_ENABLE_AUTH environment variable does not configure authentication. Set the environment variable ALLOW_ANONYMOUS_LOGIN=yes to allow unauthenticated users to connect to ZooKeeper."
#    fi

    # TODO: 其他参数检测

    [[ "$error_code" -eq 0 ]] || exit "$error_code"
}

# 更改默认监听地址为 "*" 或 "0.0.0.0"，以对容器外提供服务；默认配置文件应当为仅监听 localhost(127.0.0.1)
hadoop_enable_remote_connections() {
    LOG_D "Modify default config to enable all IP access"
	
}

# 检测依赖的服务端口是否就绪；该脚本依赖系统工具 'netcat'
# 参数:
#   $1 - host:port
hadoop_wait_service() {
    local serviceport=${1:?Missing server info}
    local service=${serviceport%%:*}
    local port=${serviceport#*:}
    local retry_seconds=5
    local max_try=100
    let i=1

    if [[ -z "$(which nc)" ]]; then
        LOG_E "Nedd nc installed before, command: \"apt-get install netcat\"."
        exit 1
    fi

    LOG_I "[0/${max_try}] check for ${service}:${port}..."

    set +e
    nc -z -w 2 ${service} ${port}
    result=$?

    until [ $result -eq 0 ]; do
      LOG_D "  [$i/${max_try}] not available yet"
      if (( $i == ${max_try} )); then
        LOG_E "${service}:${port} is still not available; giving up after ${max_try} tries."
        exit 1
      fi
      
      LOG_I "[$i/${max_try}] try in ${retry_seconds}s once again ..."
      let "i++"
      sleep ${retry_seconds}

      nc -z -w 2 ${service} ${port}
      result=$?
    done

    set -e
    LOG_I "[$i/${max_try}] ${service}:${port} is available."
}

# 清理初始化应用时生成的临时文件
hadoop_clean_tmp_file() {
    LOG_D "Clean ${APP_NAME} tmp files for init..."

}

# 在重新启动容器时，删除标志文件及必须删除的临时文件 (容器重新启动)
hadoop_clean_from_restart() {
    LOG_D "Clean ${APP_NAME} tmp files for restart..."
    local -r -a files=(

    )

    for file in ${files[@]}; do
        if [[ -f "$file" ]]; then
            LOG_I "Cleaning stale $file file"
            rm "$file"
        fi
    done
}

# 应用默认初始化操作
# 执行完毕后，生成文件 ${APP_CONF_DIR}/.app_init_flag 及 ${APP_DATA_DIR}/.data_init_flag 文件
hadoop_default_init() {
	hadoop_clean_from_restart
    LOG_D "Check init status of ${APP_NAME}..."

    # 检测配置文件是否存在
    if [[ ! -f "${APP_CONF_DIR}/.app_init_flag" ]]; then
        LOG_I "No injected configuration file found, creating default config files..."
        
        # 根据环境变量生成默认配置文件
        hadoop_generate_conf

        if is_boolean_yes "${MULTIHOMED_NETWORK:-1}" ;then
            hadoop_multihome_network_conf
        fi

        [ -n "${GANGLIA_HOST:-}" ] && hadoop_ganglia_host_conf

        touch "${APP_CONF_DIR}/.app_init_flag"
        echo "$(date '+%Y-%m-%d %H:%M:%S') : Init success." >> "${APP_CONF_DIR}/.app_init_flag"
    else
        LOG_I "User injected custom configuration detected!"

        LOG_D "Update configure files from environment..."
        hadoop_update_conf
    fi

    if [[ ! -f "${APP_DATA_DIR}/.data_init_flag" ]]; then
        LOG_I "Deploying ${APP_NAME} from scratch..."

        # TODO: 根据需要生成相应初始化数据

        touch ${APP_DATA_DIR}/.data_init_flag
        echo "$(date '+%Y-%m-%d %H:%M:%S') : Init success." >> ${APP_DATA_DIR}/.data_init_flag
    else
        LOG_I "Deploying ${APP_NAME} with persisted data..."
    fi

    # 获取依赖外部服务信息，去除配置信息中可能存在的双引号'"'，并进行服务状态检测
    for i in `echo ${SERVICE_PRECONDITION:-} | sed -e 's/^\"//' -e 's/\"$//'`; do
        hadoop_wait_service "${i}"
    done
}

# 用户自定义的前置初始化操作，依次执行目录 preinitdb.d 中的初始化脚本
# 执行完毕后，生成文件 ${APP_DATA_DIR}/.custom_preinit_flag
hadoop_custom_preinit() {
    LOG_I "Check custom pre-init status of ${APP_NAME}..."

    # 检测用户配置文件目录是否存在 preinitdb.d 文件夹，如果存在，尝试执行目录中的初始化脚本
    if [ -d "/srv/conf/${APP_NAME}/preinitdb.d" ]; then
        # 检测数据存储目录是否存在已初始化标志文件；如果不存在，检索可执行脚本文件并进行初始化操作
        if [[ -n $(find "/srv/conf/${APP_NAME}/preinitdb.d/" -type f -regex ".*\.\(sh\)") ]] && \
            [[ ! -f "${APP_DATA_DIR}/.custom_preinit_flag" ]]; then
            LOG_I "Process custom pre-init scripts from /srv/conf/${APP_NAME}/preinitdb.d..."

            # 检索所有可执行脚本，排序后执行
            find "/srv/conf/${APP_NAME}/preinitdb.d/" -type f -regex ".*\.\(sh\)" | sort | process_init_files

            touch "${APP_DATA_DIR}/.custom_preinit_flag"
            echo "$(date '+%Y-%m-%d %H:%M:%S') : Init success." >> "${APP_DATA_DIR}/.custom_preinit_flag"
            LOG_I "Custom preinit for ${APP_NAME} complete."
        else
            LOG_I "Custom preinit for ${APP_NAME} already done before, skipping initialization."
        fi
    fi

    # 检测依赖的服务是否就绪
    #for i in ${SERVICE_PRECONDITION[@]}; do
    #    hadoop_wait_service "${i}"
    #done
}

# 用户自定义的应用初始化操作，依次执行目录initdb.d中的初始化脚本
# 执行完毕后，生成文件 ${APP_DATA_DIR}/.custom_init_flag
hadoop_custom_init() {
    LOG_I "Check custom initdb status of ${APP_NAME}..."

    # 检测用户配置文件目录是否存在 initdb.d 文件夹，如果存在，尝试执行目录中的初始化脚本
    if [ -d "/srv/conf/${APP_NAME}/initdb.d" ]; then
    	# 检测数据存储目录是否存在已初始化标志文件；如果不存在，检索可执行脚本文件并进行初始化操作
    	if [[ -n $(find "/srv/conf/${APP_NAME}/initdb.d/" -type f -regex ".*\.\(sh\|sql\|sql.gz\)") ]] && \
            [[ ! -f "${APP_DATA_DIR}/.custom_init_flag" ]]; then
            LOG_I "Process custom init scripts from /srv/conf/${APP_NAME}/initdb.d..."

            # 检索所有可执行脚本，排序后执行
    		find "/srv/conf/${APP_NAME}/initdb.d/" -type f -regex ".*\.\(sh\|sql\|sql.gz\)" | sort | while read -r f; do
                case "$f" in
                    *.sh)
                        if [[ -x "$f" ]]; then
                            LOG_D "Executing $f"; "$f"
                        else
                            LOG_D "Sourcing $f"; . "$f"
                        fi
                        ;;
                    *.sql)    
                        LOG_D "Executing $f"; 
                        postgresql_execute "${PG_DATABASE}" "${PG_INITSCRIPTS_USERNAME}" "${PG_INITSCRIPTS_PASSWORD}" < "$f"
                        ;;
                    *.sql.gz) 
                        LOG_D "Executing $f"; 
                        gunzip -c "$f" | postgresql_execute "${PG_DATABASE}" "${PG_INITSCRIPTS_USERNAME}" "${PG_INITSCRIPTS_PASSWORD}"
                        ;;
                    *)        
                        LOG_D "Ignoring $f" ;;
                esac
            done

            touch "${APP_DATA_DIR}/.custom_init_flag"
    		echo "$(date '+%Y-%m-%d %H:%M:%S') : Init success." >> "${APP_DATA_DIR}/.custom_init_flag"
    		LOG_I "Custom init for ${APP_NAME} complete."
    	else
    		LOG_I "Custom init for ${APP_NAME} already done before, skipping initialization."
    	fi
    fi

    # 删除第一次运行生成的临时文件
    hadoop_clean_tmp_file

	# 绑定所有 IP ，启用远程访问
    hadoop_enable_remote_connections
}

