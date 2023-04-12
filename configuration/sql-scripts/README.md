
# README — `sql_scripts`

## Purpose

This README file aims to describe the content of the `sql_scripts` directory which contains **YAML** configurations files.

## Directory structure

This directory contains the configuration files for the BigQuery query jobs
(see [google_bigquery_job](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_job#example-usage---bigquery-job-query)) and routines
(see [google_bigquery_routine](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_routine) terraform resource).

A routine is either a stored procedure or a user-defined function (see [REST Resources: routine](https://cloud.google.com/bigquery/docs/reference/rest/v2/routines))

There are three types of files which correspond to:
- `job-queries/*.yaml` files for query jobs
- `sprocs/*.yaml` files for stored procedure routines
- `udf/*.yaml` files for user-defined function (or UDF) routines

```
.
├── job-queries/example.yaml               An example of a query job configuration file.
├── job-queries/example_ddl.yaml           An example of a query job with DDL statement configuration file.
├── sprocs/example.yaml                    An example of a stored procedure configuration file.
└── udf/example.yaml                       An example of a user-defined function configuration file.
```


**Note: BigQuery copy, extract and load jobs are not supported by the `job_query_*.yaml configuration files`.**

### Stored procedures

Stored procedures configurations files (prefix `sproc_`) have the following keys:

with:

| Key                            | Description                                                                                            |
|--------------------------------|--------------------------------------------------------------------------------------------------------|
| dataset_id                     | the dataset id where the stored procedure will be created                                              |
| routine_id                     | the id of the routine (valid characters: `[a-zA-Z]`, `[0-9]` or `_`, maximum length of 256 characters) |
| description                    | the description of the store procedure  (optional, defaults to `null`)                                  |
| language                       | the language of the procedure (optional, defaults to `SQL`)                                            |
| definition_body                | the body of the stored procedure                                                                       |
| arguments                      | the list of `name` and `data_type` key-value pairs for the input (optional)                            |

The `arguments` key is a list of the following key-value pairs:

| Key                            | Description                                                                                             |
|--------------------------------|---------------------------------------------------------------------------------------------------------|
| name                           | the name of the input variable                                                                          |
| [argument_kind](https://cloud.google.com/bigquery/docs/reference/rest/v2/routines#argumentkind)                  | the argument kind: `FIXED_TYPE` or `ANY_TYPE` (optional, defaults to `FIXED_TYPE`)                      |
| data_type                      | the data type (see [BigQuery data types in standard SQL](https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types))  |
| [mode](https://cloud.google.com/bigquery/docs/reference/rest/v2/routines#mode)                           | the input/output mode of the argument: `IN`, `OUT`, `INOUT` (optional)                                   |

See example: [sproc_example.yaml](sproc_example.yaml)

### User-defined functions

User-defined function (UDF) configurations files (prefix `udf_`) have the following keys:

| Key                            | Description                                                                                             |
|--------------------------------|---------------------------------------------------------------------------------------------------------|
| dataset_id                     | the dataset id where the UDF will be created                                                            |
| routine_id                     | the id of the routine (valid characters: `[a-zA-Z]`, `[0-9]` or `_` - maximum length of 256 characters) |
| description                    | the description of the UDF (optional, defaults to `null`)                                               |
| language                       | the language of the UDF                                                                                 |
| definition_body                | the body of the UDF                                                                                     |
| arguments                      | the list of `name` and `data_type` key-value pairs for the input (optional)                             |
| return_type                    | the return type as a JSON schema (optional if the `language` key is `SQL`)                              |

The `arguments` key is a list of the following key-value pairs:

| Key                            | Description                                                                                             |
|--------------------------------|---------------------------------------------------------------------------------------------------------|
| name                           | the name of the input variable                                                                          |
| data_type                      | the id of the routine (valid characters: `[a-zA-Z]`, `[0-9]` or `_`, maximum length of 256 characters)  |


See example: [udf_example.yaml](udf_example.yaml)

### Jobs

There are differents jobs type: query, copy, extract, load. We will have a look at each query type in the sections below.

#### Query

Query jobs configurations files (prefix `job_query_`) have the following keys:

| Key                            | Description                                                                                            |
|--------------------------------|--------------------------------------------------------------------------------------------------------|
| job_id_prefix                  | the prefix of the job id (job_id = `job_id_prefix-uuid` with uuid = [uuid()](https://www.terraform.io/docs/language/functions/uuid.html))                       |
| [query](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_job#query)                          | the query block                                                                                        |



See the detail of the [query](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_job#query) field.

**Note: Queries with DDL or DML statements must have `creation_disposition: ""` and `write_disposition: ""` in their configuration file.**

Templates are provided below:

<details>
  <summary>Template for a DDL</summary>

```yaml
job_id_prefix: job_id_prefix
labels:
  - key: "key_1"
    value: "value_1"
  - key: "key_2"
    value: "value_2"
  - key: "key_n"
    value: "value_n"
query:
  query: |-
    CREATE TABLE IF NOT EXISTS FROM `dataset.table`
    WHERE id=42;
  create_disposition: ""
  write_disposition: ""
  destination_table:
    project_id: project_id
    dataset_id: dataset_id
    table_id: dst_table_id
  default_dataset:
    project_id: project_id
    dataset_id: default_dataset_id
  user_defined_function_resources:
    resource_uri: gcs_uri_path
    inline_code: |-
      inline code can be provided instead
      of specifying the resource_uri to
      the file containing the code
    priority: INTERACTIVE | BATCH
    use_query_cache: true | false
    use_legacy_sql: true | false
    allow_large_results: true | false
    flatten_results: true | false
    parameter_mode: POSITIONAL | NAMED
    maximum_billing_tier: maximum_billing_tier
    maximum_bytes_billed: maximum_bytes_billed
    schema_update_options:
      - ALLOW_FIELD_ADDITION
      - ALLOW_FIELD_RELAXATION
```
</details>

#### Copy
_Not implemented._

#### Extract
_Not implemented._

#### Load
_Not implemented._