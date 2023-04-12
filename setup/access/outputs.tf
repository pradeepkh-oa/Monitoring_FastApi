# -- Summary of authorized external members on project per level
output "project" {
  value = {
    for member in distinct([for _, iam in google_project_iam_member.authorized_on_project : iam.member]) :
    member => sort([
      for _, iam in google_project_iam_member.authorized_on_project :
      iam.role
      if iam.member == member
    ])
  }
}

output "buckets" {
  value = {
    for bucket in distinct([for _, iam in google_storage_bucket_iam_member.authorized_on_buckets : iam.bucket]) :
    bucket => {
      for member in distinct([for _, iam in google_storage_bucket_iam_member.authorized_on_buckets : iam.member if iam.bucket == bucket]) :
      member => sort([
        for _, iam in google_storage_bucket_iam_member.authorized_on_buckets :
        iam.role
        if iam.member == member && iam.bucket == bucket
      ])
    }
  }
}

output "datasets" {
  value = {
    for dataset_id in distinct([for _, iam in google_bigquery_dataset_iam_member.authorized_on_datasets : iam.dataset_id]) :
    dataset_id => {
      for member in distinct([for _, iam in google_bigquery_dataset_iam_member.authorized_on_datasets : iam.member if iam.dataset_id == dataset_id]) :
      member => sort([
        for _, iam in google_bigquery_dataset_iam_member.authorized_on_datasets :
        iam.role
        if iam.member == member && iam.dataset_id == dataset_id
      ])
    }
  }
}
output "tables" {
  value = {
    for dataset_id in distinct([for _, iam in google_bigquery_table_iam_member.authorized_on_tables : iam.dataset_id]) :
    dataset_id => {
      for table_id in distinct([for _, iam in google_bigquery_table_iam_member.authorized_on_tables : iam.table_id if iam.dataset_id == dataset_id]) :
      table_id => {
        for member in distinct([for _, iam in google_bigquery_table_iam_member.authorized_on_tables : iam.member if iam.dataset_id == dataset_id && iam.table_id == table_id]) :
        member => sort([
          for _, iam in google_bigquery_table_iam_member.authorized_on_tables :
          iam.role
          if iam.member == member && iam.dataset_id == dataset_id && iam.table_id == table_id
        ])
      }
    }
  }
}

output "pubsub_topics" {
  value = {
    for topic in distinct([for _, iam in google_pubsub_topic_iam_member.authorized_on_pubsubtopics : iam.topic]) :
    topic => {
      for member in distinct([for _, iam in google_pubsub_topic_iam_member.authorized_on_pubsubtopics : iam.member if iam.topic == topic]) :
      member => sort([
        for _, iam in google_pubsub_topic_iam_member.authorized_on_pubsubtopics :
        iam.role
        if iam.member == member && iam.topic == topic
      ])
    }
  }
}

output "secrets" {
  value = {
    for secret_id in distinct([for _, iam in google_secret_manager_secret_iam_member.authorized_on_secrets : iam.secret_id]) :
    secret_id => {
      for member in distinct([for _, iam in google_secret_manager_secret_iam_member.authorized_on_secrets : iam.member if iam.secret_id == secret_id]) :
      member => sort([
        for _, iam in google_secret_manager_secret_iam_member.authorized_on_secrets :
        iam.role
        if iam.member == member && iam.secret_id == secret_id
      ])
    }
  }
}
