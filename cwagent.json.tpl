{
  "agent": {
    "run_as_user": "root",
    "debug": false,
    "metrics_collection_interval": 60,
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  },

  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/webapp/app.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}",
            "timestamp_format": "%Y-%m-%dT%H:%M:%S%z",
            "timezone": "UTC"
          }
        ]
      }
    },
    "force_flush_interval": 15
  },

  "metrics": {
    "namespace": "webapp-${env}",
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}",
      "Environment": "${env}"
    },
    "metrics_collected": {
      "statsd": {
        "service_address": ":8125",
        "metrics_collection_interval": 10,
        "metrics_aggregation_interval": 10
      }
    }
  }
}
