resource "aws_glue_catalog_database" "alb_logs" {
  name        = "${var.govuk_environment}_alb_logs"
  description = "Contains access logs from application load balancers in the account"
}

resource "aws_iam_role" "alb_glue_role" {
  name               = "govuk-${var.govuk_environment}-alb-logs-glue-role"
  assume_role_policy = data.aws_iam_policy_document.alb_glue_role_assume_role_policy.json
}

data "aws_iam_policy_document" "alb_glue_role_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "alb_logs_iam_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      data.tfe_outputs.logging.nonsensitive_values.aws_logging_bucket_arn,
      "${data.tfe_outputs.logging.nonsensitive_values.aws_logging_bucket_arn}/elb/*"

    ]
  }
}

resource "aws_iam_role_policy_attachment" "alb_logs_glue_service_policy" {
  role       = aws_iam_role.alb_glue_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "alb_logs_iam_policy" {
  name   = "govuk-${var.govuk_environment}-alb-logs-glue-policy"
  role   = aws_iam_role.alb_glue_role.id
  policy = data.aws_iam_policy_document.alb_logs_iam_policy.json
}

resource "aws_glue_crawler" "alb_logs" {
  name          = "ALB logs crawler"
  description   = "Crawls all ALB logs for Athena querying"
  database_name = aws_glue_catalog_database.alb_logs.name
  role          = aws_iam_role.alb_glue_role.name

  schedule = "cron(0 * * * ? *)"

  s3_target {
    path = "s3://${data.tfe_outputs.logging.nonsensitive_values.aws_logging_bucket_id}/elb/"
  }

  schema_change_policy {
    delete_behavior = "DELETE_FROM_DATABASE"
    update_behavior = "LOG"
  }

  configuration = jsonencode({
    Version : "1.0",
    CrawlerOutput : {
      Partitions : {
        AddOrUpdateBehavior : "InheritFromTable"
      }
    }
  })
}

resource "aws_glue_catalog_table" "alb_logs" {
  name          = "${var.govuk_environment}_alb_logs"
  description   = "Holds all ALB access logs for ${var.govuk_environment} environment"
  database_name = aws_glue_catalog_database.alb_logs.name
  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    location     = "s3://${data.tfe_outputs.logging.nonsensitive_values.aws_logging_bucket_id}/elb/"
    input_format = "org.apache.hadoop.hive.serde2.RegexSerDe"

    # columns sourced from
    # https://docs.aws.amazon.com/athena/latest/ug/create-alb-access-logs-table.html
    columns {
      name = "type"
      type = "string"
    }
    columns {
      name = "time"
      type = "string"
    }
    columns {
      name = "elb"
      type = "string"
    }
    columns {
      name = "client_ip"
      type = "string"
    }
    columns {
      name = "client_port"
      type = "int"
    }
    columns {
      name = "target_ip"
      type = "string"
    }
    columns {
      name = "target_port"
      type = "int"
    }
    columns {
      name = "request_processing_time"
      type = "double"
    }
    columns {
      name = "target_processing_time"
      type = "double"
    }
    columns {
      name = "response_processing_time"
      type = "double"
    }
    columns {
      name = "elb_status_code"
      type = "int"
    }
    columns {
      name = "target_status_code"
      type = "string"
    }
    columns {
      name = "received_bytes"
      type = "bigint"
    }
    columns {
      name = "sent_bytes"
      type = "bigint"
    }
    columns {
      name = "request_verb"
      type = "string"
    }
    columns {
      name = "request_url"
      type = "string"
    }
    columns {
      name = "request_proto"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "ssl_cipher"
      type = "string"
    }
    columns {
      name = "ssl_protocol"
      type = "string"
    }
    columns {
      name = "target_group_arn"
      type = "string"
    }
    columns {
      name = "trace_id"
      type = "string"
    }
    columns {
      name = "domain_name"
      type = "string"
    }
    columns {
      name = "chosen_cert_arn"
      type = "string"
    }
    columns {
      name = "matched_rule_priority"
      type = "string"
    }
    columns {
      name = "request_creation_time"
      type = "string"
    }
    columns {
      name = "actions_executed"
      type = "string"
    }
    columns {
      name = "redirect_url"
      type = "string"
    }
    columns {
      name = "lambda_error_reason"
      type = "string"
    }
    columns {
      name = "target_port_list"
      type = "string"
    }
    columns {
      name = "target_status_code_list"
      type = "string"
    }
    columns {
      name = "classification"
      type = "string"
    }
    columns {
      name = "classification_reason"
      type = "string"
    }
    columns {
      name = "conn_trace_id"
      type = "string"
    }
  }

  partition_keys {
    name = "year"
    type = "int"
  }

  partition_keys {
    name = "month"
    type = "int"
  }

  partition_keys {
    name = "date"
    type = "int"
  }
}


