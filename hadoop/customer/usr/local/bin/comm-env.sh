#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
# 
# 应用环境变量定义及初始化

# 通用设置
export ENV_DEBUG=${ENV_DEBUG:-false}
export ALLOW_ANONYMOUS_LOGIN="${ALLOW_ANONYMOUS_LOGIN:-no}"

# 通过读取变量名对应的 *_FILE 文件，获取变量值；如果对应文件存在，则通过传入参数设置的变量值会被文件中对应的值覆盖
# 变量优先级： *_FILE > 传入变量 > 默认值
app_env_file_lists=(
	APP_PASSWORD
)
for env_var in "${app_env_file_lists[@]}"; do
    file_env_var="${env_var}_FILE"
    if [[ -n "${!file_env_var:-}" ]]; then
        export "${env_var}=$(< "${!file_env_var}")"
        unset "${file_env_var}"
    fi
done
unset app_env_file_lists

# 应用路径参数
export APP_HOME_DIR="/usr/local/${APP_NAME}"
export APP_DEF_DIR="/etc/${APP_NAME}"
export APP_CONF_DIR="/srv/conf/${APP_NAME}"
export APP_DATA_DIR="/srv/data/${APP_NAME}"
export APP_DATA_LOG_DIR="/srv/datalog/${APP_NAME}"
export APP_CACHE_DIR="/var/cache/${APP_NAME}"
export APP_RUN_DIR="/var/run/${APP_NAME}"
export APP_LOG_DIR="/var/log/${APP_NAME}"
export APP_CERT_DIR="/srv/cert/${APP_NAME}"

# 应用配置参数
export USER=hadoop
export MULTIHOMED_NETWORK=${MULTIHOMED_NETWORK:-1}
export HADOOP_HOME=${APP_HOME_DIR}

export HADOOP_ACTIVED_NAMENODE=${HADOOP_ACTIVED_NAMENODE:-}
export HADOOP_CURRENT_NAMENODE=${HADOOP_CURRENT_NAMENODE:-`hostname -f`}

export CORE_CONF_fs_defaultFS=${CORE_CONF_fs_defaultFS:-hdfs://`hostname -f`}
export CORE_CONF_hadoop_tmp_dir=${CORE_CONF_hadoop_tmp_dir:-${APP_DATA_DIR}/tmp}
export HDFS_CONF_dfs_namenode_name_dir=${HDFS_CONF_dfs_namenode_name_dir:-${APP_DATA_DIR}/dfs/namenode}
export HDFS_CONF_dfs_datanode_data_dir=${HDFS_CONF_dfs_datanode_data_dir:-${APP_DATA_DIR}/dfs/datanode}
export HDFS_CONF_dfs_journalnode_edits_dir=${HDFS_CONF_dfs_journalnode_edits_dir:-${APP_DATA_DIR}/dfs/journal}
export YARN_CONF_yarn_timeline___service_leveldb___timeline___store_path=${YARN_CONF_yarn_timeline___service_leveldb___timeline___store_path:-${APP_DATA_DIR}/yarn/timeline}
export MAPRED_CONF_mapreduce_jobhistory_done___dir=${MAPRED_CONF_mapreduce_jobhistory_done___dir:-${APP_DATA_DIR}/mapreduce/done}
export MAPRED_CONF_mapreduce_jobhistory_intermediate___done___dir=${MAPRED_CONF_mapreduce_jobhistory_intermediate___done___dir:-${APP_DATA_DIR}/mapreduce/tmp}

export MAPRED_CONF_mapreduce_application_classpath=${MAPRED_CONF_mapreduce_application_classpath:-${HADOOP_MAPRED_HOME}/share/hadoop/mapreduce/*:${HADOOP_MAPRED_HOME}/share/hadoop/mapreduce/lib/*}
export YARN_CONF_yarn_application_classpath=${YARN_CONF_yarn_application_classpath:-${HADOOP_YARN_HOME}/share/hadoop/yarn/*:${HADOOP_YARN_HOME}/share/hadoop/yarn/lib/*}

# 内部变量
export HADOOP_MAPRED_HOME=${HADOOP_HOME}
export HADOOP_COMMON_HOME=${HADOOP_HOME}
export HADOOP_HDFS_HOME=${HADOOP_HOME}
export HADOOP_YARN_HOME=${HADOOP_HOME}
export YARN_HOME=${HADOOP_HOME}
export HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_HOME}/lib/native
export HADOOP_LIBEXEC_DIR=${HADOOP_HOME}/libexec
export HADOOP_INSTALL=${HADOOP_HOME}
export HADOOP_OPTS="-Djava.library.path=${HADOOP_HOME}/lib/native" 
export HADOOP_CONF_DIR=${APP_CONF_DIR}
export HADOOP_LOG_DIR=${APP_LOG_DIR}

export HADOOP_TMP_DIR=${CORE_CONF_hadoop_tmp_dir}
export HDFS_NAMENODE_DATA_DIR=${HDFS_CONF_dfs_namenode_name_dir}
export HDFS_DATANODE_DATA_DIR=${HDFS_CONF_dfs_datanode_data_dir}
export HDFS_JOURNALNODE_DATA_DIR=${HDFS_CONF_dfs_journalnode_edits_dir}
export YARN_TIMELINE_DATA_DIR=${YARN_CONF_yarn_timeline___service_leveldb___timeline___store_path}
export MAPRED_JOBHISTORY_DONE_DATA_DIR=${MAPRED_CONF_mapreduce_jobhistory_done___dir}
export MAPRED_JOBHISTORY_TMP_DATA_DIR=${MAPRED_CONF_mapreduce_jobhistory_intermediate___done___dir}

# 个性化变量

