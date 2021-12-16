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

    #' @description Initialize RedshiftDatasetDefinition.
    #' @param cluster_id (str, default=None): The Redshift cluster Identifier.
    #'              database (str, default=None):
    #'              The name of the Redshift database used in Redshift query execution.
    #' @param db_user (str, default=None): The database user name used in Redshift query execution.
    #' @param query_string (str, default=None): The SQL query statements to be executed.
    #' @param cluster_role_arn (str, default=None): The IAM role attached to your Redshift cluster
    #'              that Amazon SageMaker uses to generate datasets.
    #' @param output_s3_uri (str, default=None): The location in Amazon S3 where the Redshift query
    #'              results are stored.
    #' @param kms_key_id (str, default=None): The AWS Key Management Service (AWS KMS) key that Amazon
    #'              SageMaker uses to encrypt data from a Redshift execution.
    #' @param output_format (str, default=None): The data storage format for Redshift query results.
    #'              Valid options are "PARQUET", "CSV"
    #' @param output_compression (str, default=None): The compression used for Redshift query results.
    #'              Valid options are "None", "GZIP", "SNAPPY", "ZSTD", "BZIP2"
    initialize = function(cluster_id=NULL,
                          database=NULL,
                          db_user=NULL,
                          query_string=NULL,
                          cluster_role_arn=NULL,
                          output_s3_uri=NULL,
                          kms_key_id=NULL,
                          output_format=NULL,
                          output_compression=NULL){
      super$initialize(
        cluster_id=cluster_id,
        database=database,
        db_user=db_user,
        query_string=query_string,
        cluster_role_arn=cluster_role_arn,
        output_s3_uri=output_s3_uri,
        kms_key_id=kms_key_id,
        output_format=output_format,
        output_compression=output_compression
      )
    }
  ),
  lock_objects=F
)

#' @title DatasetDefinition for Athena.
#' @description With this input, SQL queries will be executed using Athena to generate datasets to S3.
#' @export
AthenaDatasetDefinition = R6Class("AthenaDatasetDefinition",
  inherit = ApiObject,
  public = list(

    #' @description Initialize AthenaDatasetDefinition.
    #' @param catalog (str, default=None): The name of the data catalog used in Athena query
    #'              execution.
    #' @param database (str, default=None): The name of the database used in the Athena query
    #'              execution.
    #' @param query_string (str, default=None): The SQL query statements, to be executed.
    #' @param output_s3_uri (str, default=None):
    #'              The location in Amazon S3 where Athena query results are stored.
    #' @param work_group (str, default=None):
    #'              The name of the workgroup in which the Athena query is being started.
    #' @param kms_key_id (str, default=None): The AWS Key Management Service (AWS KMS) key that Amazon
    #'              SageMaker uses to encrypt data generated from an Athena query execution.
    #' @param output_format (str, default=None): The data storage format for Athena query results.
    #'              Valid options are "PARQUET", "ORC", "AVRO", "JSON", "TEXTFILE"
    #' @param output_compression (str, default=None): The compression used for Athena query results.
    #'              Valid options are "GZIP", "SNAPPY", "ZLIB"
    initialize = function(catalog=NULL,
                          database=NULL,
                          query_string=NULL,
                          output_s3_uri=NULL,
                          work_group=NULL,
                          kms_key_id=NULL,
                          output_format=NULL,
                          output_compression=NULL){
      super$initialize(
        catalog=catalog,
        database=database,
        query_string=query_string,
        output_s3_uri=output_s3_uri,
        work_group=work_group,
        kms_key_id=kms_key_id,
        output_format=output_format,
        output_compression=output_compression
      )
    }
  ),
  lock_objects=F
)

#' @title DatasetDefinition input.
#' @export
DatasetDefinition = R6Class("DatasetDefinition",
  inherit = ApiObject,
  public = list(
    #' @description Initialize DatasetDefinition.
    #' @param data_distribution_type (str, default="ShardedByS3Key"):
    #'              Whether the generated dataset is FullyReplicated or ShardedByS3Key (default).
    #' @param input_mode (str, default="File"):
    #'              Whether to use File or Pipe input mode. In File (default) mode, Amazon
    #'              SageMaker copies the data from the input source onto the local Amazon Elastic Block
    #'              Store (Amazon EBS) volumes before starting your training algorithm. This is the most
    #'              commonly used input mode. In Pipe mode, Amazon SageMaker streams input data from the
    #'              source directly to your algorithm without using the EBS volume.
    #' @param local_path (str, default=None):
    #'              The local path where you want Amazon SageMaker to download the Dataset
    #'              Definition inputs to run a processing job. LocalPath is an absolute path to the
    #'              input data. This is a required parameter when `AppManaged` is False (default).
    #' @param redshift_dataset_definition
    #'              (:class:\code{R6sagemaker.common::RedshiftDatasetDefinition},
    #'              default=None):
    #'              Configuration for Redshift Dataset Definition input.
    #' @param athena_dataset_definition
    #'              (:class:\code{R6sagemaker.common::AthenaDatasetDefinition},
    #'              default=None):
    #'              Configuration for Athena Dataset Definition input.
    initialize = function(data_distribution_type="ShardedByS3Key",
                          input_mode="File",
                          local_path=NULL,
                          redshift_dataset_definition=NULL,
                          athena_dataset_definition=NULL){
      super$initialize(
        data_distribution_type=data_distribution_type,
        input_mode=input_mode,
        local_path=local_path,
        redshift_dataset_definition=redshift_dataset_definition,
        athena_dataset_definition=athena_dataset_definition
      )
    }
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
    #' @description Initialize S3Input.
    #' @param s3_uri (str, default=None): the path to a specific S3 object or a S3 prefix
    #' @param local_path (str, default=None):
    #'              the path to a local directory. If not provided, skips data download
    #'              by SageMaker platform.
    #' @param s3_data_type (str, default="S3Prefix"): Valid options are "ManifestFile" or "S3Prefix".
    #' @param s3_input_mode (str, default="File"): Valid options are "Pipe" or "File".
    #' @param s3_data_distribution_type (str, default="FullyReplicated"):
    #'              Valid options are "FullyReplicated" or "ShardedByS3Key".
    #' @param s3_compression_type (str, default=None): Valid options are "None" or "Gzip"
    initialize = function(s3_uri=NULL,
                          local_path=NULL,
                          s3_data_type="S3Prefix",
                          s3_input_mode="File",
                          s3_data_distribution_type="FullyReplicated",
                          s3_compression_type=NULL){
      super$initialize(
        s3_uri=s3_uri,
        local_path=local_path,
        s3_data_type=s3_data_type,
        s3_input_mode=s3_input_mode,
        s3_data_distribution_type=s3_data_distribution_type,
        s3_compression_type=s3_compression_type
      )
    }
  ),
  lock_objects=F
)
