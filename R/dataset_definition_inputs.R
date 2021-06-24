# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/src/sagemaker/dataset_definition/inputs.py

#' @include apiutils_base_types.R

#' @import R6

#' @title DatasetDefinition for Redshift.
#' @description With this input, SQL queries will be executed using Redshift to generate datasets to S3.
#' @export
RedshiftDatasetDefinition = R6Class("RedshiftDatasetDefinition",
  inherit = ApiObject,
  public = list(

    #' @field cluster_id
    #' (str): The Redshift cluster Identifier.
    cluster_id = NULL,

    #' @field database
    #' (str): The name of the Redshift database used in Redshift query execution.
    database = NULL,

    #' @field db_user
    #' (str): The database user name used in Redshift query execution.
    db_user = NULL,

    #' @field query_string
    #' (str): The SQL query statements to be executed.
    query_string = NULL,

    #' @field cluster_role_arn
    #' (str): The IAM role attached to your Redshift cluster that
    #' Amazon SageMaker uses to generate datasets.
    cluster_role_arn = NULL,

    #' @field output_s3_uri
    #' (str): The location in Amazon S3 where the Redshift query
    #' results are stored.
    output_s3_uri = NULL,

    #' @field kms_key_id
    #' (str): The AWS Key Management Service (AWS KMS) key that Amazon
    #' SageMaker uses to encrypt data from a Redshift execution.
    kms_key_id = NULL,

    #' @field output_format
    #' (str): The data storage format for Redshift query results.
    #' Valid options are "PARQUET", "CSV"
    output_format = NULL,

    #' @field output_compression
    #' (str): The compression used for Redshift query results.
    #' Valid options are "None", "GZIP", "SNAPPY", "ZSTD", "BZIP2"
    output_compression = NULL
  ),
  lock_objects=F
)

#' @title DatasetDefinition for Athena.
#' @description With this input, SQL queries will be executed using Athena to generate datasets to S3.
#' @export
AthenaDatasetDefinition = R6Class("AthenaDatasetDefinition",
  inherit = ApiObject,
  public = list(

    #' @field catalog
    #' (str): The name of the data catalog used in Athena query execution.
    catalog = NULL,

    #' @field database
    #' (str): The name of the database used in the Athena query execution.
    database = NULL,

    #' @field query_string
    #' (str): The SQL query statements, to be executed.
    query_string = NULL,

    #' @field output_s3_uri
    #' (str): The location in Amazon S3 where Athena query results are stored.
    output_s3_uri = NULL,

    #' @field work_group
    #' (str): The name of the workgroup in which the Athena query is being started.
    work_group = NULL,

    #' @field kms_key_id
    #' (str): The AWS Key Management Service (AWS KMS) key that Amazon
    #' SageMaker uses to encrypt data generated from an Athena query execution.
    kms_key_id = NULL,

    #' @field output_format
    #' (str): The data storage format for Athena query results.
    #' Valid options are "PARQUET", "ORC", "AVRO", "JSON", "TEXTFILE"
    output_format = NULL,

    #' @field output_compression
    #' (str): The compression used for Athena query results.
    #' Valid options are "GZIP", "SNAPPY", "ZLIB"
    output_compression = NULL
  ),
  lock_objects=F
)

#' @title DatasetDefinition input.
#' @export
DatasetDefinition = R6Class("DatasetDefinition",
  inherit = ApiObject,
  public = list(

    #' @field data_distribution_type
    #' (str): Whether the generated dataset is FullyReplicated or
    #' ShardedByS3Key (default).
    data_distribution_type = "ShardedByS3Key",

    #' @field input_mode
    #' (str): Whether to use File or Pipe input mode. In File (default) mode, Amazon
    #' SageMaker copies the data from the input source onto the local Amazon Elastic Block.
    #' Store (Amazon EBS) volumes before starting your training algorithm. This is the most
    #' commonly used input mode. In Pipe mode, Amazon SageMaker streams input data from the
    #' source directly to your algorithm without using the EBS volume.
    input_mode = "File",

    #' @field local_path (str): The local path where you want Amazon SageMaker to download the Dataset
    #' Definition inputs to run a processing job. LocalPath is an absolute path to the input
    #' data. This is a required parameter when `AppManaged` is False (default).
    local_path = NULL,

    #' @field redshift_dataset_definition
    #' (:class:`~sagemaker.dataset_definition.RedshiftDatasetDefinition`): Redshift
    #' dataset definition.
    redshift_dataset_definition = NULL,


    #' @field athena_dataset_definition
    #' (:class:`~sagemaker.dataset_definition.AthenaDatasetDefinition`):
    #' Configuration for Athena Dataset Definition input.
    athena_dataset_definition = NULL
  ),
  private = list(
    .custom_paws_types = list(
      "redshift_dataset_definition"=c(RedshiftDatasetDefinition, TRUE),
      "athena_dataset_definition"=c(AthenaDatasetDefinition, TRUE)
    )
  ),
  lock_objects=F
)

#' @title Metadata of data objects stored in S3.
#' @description Two options are provided: specifying a S3 prefix or by explicitly listing the files
#'              in  manifest file and referencing the manifest file's S3 path.
#' @note  Note: Strong consistency is not guaranteed if S3Prefix is provided here.
#'              S3 list operations are not strongly consistent.
#'              Use ManifestFile if strong consistency is required.
#' @export
S3Input = R6Class("S3Input",
  inherit = ApiObject,
  public = list(
    #' @field s3_uri
    #' (str): the path to a specific S3 object or a S3 prefix
    s3_uri = NULL,

    #' @field local_path
    #' (str): the path to a local directory. If not provided, skips data download
    #' by SageMaker platform.
    local_path = NULL,

    #' @field s3_data_type
    #' (str): Valid options are "ManifestFile" or "S3Prefix".
    s3_data_type = "S3Prefix",

    #' @field s3_input_mode
    #' (str): Valid options are "Pipe" or "File".
    s3_input_mode = "File",

    #' @field s3_data_distribution_type
    #' (str): Valid options are "FullyReplicated" or "ShardedByS3Key".
    s3_data_distribution_type = "FullyReplicated",

    #' @field s3_compression_type
    #' (str): Valid options are "None" or "Gzip".
    s3_compression_type = NULL

  ),
  lock_objects=F
)
