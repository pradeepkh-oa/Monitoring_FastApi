# README — `buckets`

## Purpose

This README file aims to describe the content of the `buckets` directory which contains **YAML** configurations files.

## Functioning

Each configuration file is used to create a bucket using the iac [buckets.tf](../../iac/buckets.tf)
The name of the configuration file is important because it defines the name of the bucket to create:
To create a bucket with name `my_bucket` create the file `my_bucket.yaml`

### File content

* Empty file to a default bucket:

`default_bucket.yaml`:
```yaml
{}
```

=> Create a simple bucket named `default_bucket` at location `EU`

* Configured bucket with parameters:

| Parameter | Description                |
|-----------|----------------------------|
| **location**  |  optional(string): the location of bucket, default `EU`. |
| **lifecycle**  | optional(int): the number of days the data must be kept before auto remove. If omitted, no lifecycle.|
| **notification**  | optional(object): contains the parameter to add notification to existing pubsub topic. |
|notification.**topic_notification**  | required(string) : the Cloud PubSub topic to which this subscription publishes.|
|notification.**payload_format**  | required(string): the desired content of the Payload. `NONE` or `JSON_API_V1`.|
|notification.**topic_notification_prefix**  | optional(string): specifies a prefix path filter for this notification config. Cloud Storage will only send notifications for objects in this bucket whose names begin with the specified prefix.|


`my_bucket.yaml`:
```yaml
location: US
lifecycle: 2
notification:
  topic_notification: btdp-topic-arrival-mpo
  payload_format: JSON_API_V1
  topic_notification_prefix: my_prefix
```

=> Create a bucket named `my_bucket` in the location `EU` with a lifecycle rule: automatic deletion after `2` days and create the pubsub notification for this bucket on the subject `btdp-topic-arrival-mpo` with JSON payload and prefix `my_prefix`.
