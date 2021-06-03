# NOTE: This code has been modified from AWS Sagemaker Python:
# https://github.com/aws/sagemaker-python-sdk/blob/master/src/sagemaker/vpc_utils.py

#' @include r_utils.R
#' @include error.R

#' @title Vpc Configuration
#' @description Contains default vpc configurations.
#' @keywords internal
#' @export
vpc_config = Enum(
  SUBNETS_KEY = "Subnets",
  SECURITY_GROUP_IDS_KEY = "SecurityGroupIds",
  VPC_CONFIG_KEY = "VpcConfig",
  # A global constant value for methods which can optionally override VpcConfig
  # Using the default implies that VpcConfig should be reused from an existing Estimator or
  # Training Job
  VPC_CONFIG_DEFAULT = "VPC_CONFIG_DEFAULT"
)

#' @title Convert subnet and security groups in to vpc list
#' @description Prepares a VpcConfig list containing keys 'Subnets' and
#'              SecurityGroupIds' This is the dict format expected by SageMaker
#'              CreateTrainingJob and CreateModel APIs See
#'              \url{https://docs.aws.amazon.com/sagemaker/latest/dg/API_VpcConfig.html}
#' @param subnets (list): list of subnet IDs to use in VpcConfig
#' @param security_group_ids (list): list of security group IDs to use in
#'              VpcConfig
#' @return A VpcConfig dict containing keys 'Subnets' and 'SecurityGroupIds' If
#'              either or both parameters are None, returns None
#' @export
vpc_to_list <- function(subnets,
                        security_group_ids){
  if (islistempty(subnets) || islistempty(security_group_ids))
    return(NULL)
  return(list(Subnets= subnets, SecurityGroupIds= security_group_ids))
}

#' @title Extracts subnets and security group ids as lists from a VpcConfig dict
#' @param vpc_config (list): a VpcConfig list containing 'Subnets' and
#'              SecurityGroupIds'
#' @param do_sanitize (bool): whether to sanitize the VpcConfig dict before
#'              extracting values
#' @return list as (subnets, security_group_ids) If vpc_config parameter
#'              is None, returns (None, None)
#' @export
vpc_from_list <- function(vpc_config,
                          do_sanitize=FALSE){
  if (do_sanitize)
    vpc_config = vpc_sanitize(vpc_config)
  if (islistempty(vpc_config))
    return(list(Subnets= NULL, SecurityGroupIds= NULL))
  return (list(Subnets = vpc_config$Subnets, SecurityGroupIds= vpc_config$SecurityGroupIds))
}

#' @title Checks VpcConfig
#' @description Checks that an instance of VpcConfig has the expected keys and values,
#'              removes unexpected keys, and raises ValueErrors if any expectations are
#'              violated
#' @param vpc_config (list): a VpcConfig dict containing 'Subnets' and
#'              SecurityGroupIds'
#' @return  A valid VpcConfig dict containing only 'Subnets' and 'SecurityGroupIds'
#'              from the vpc_config parameter If vpc_config parameter is None, returns
#'              None
#' @export
vpc_sanitize <- function(vpc_config = NULL){
  if (is.null(vpc_config))
    return(vpc_config)
  if (!inherits(vpc_config, "list"))
    ValueError$new("vpc_config is not a `list()`: ", vpc_config, call)

  if (length(vpc_config) == 0)
    ValueError$new("vpc_config is empty")

  subnets = vpc_config[[vpc_config$SUBNETS_KEY]]

  if (is.null(subnets))
    ValueError$new(sprintf("vpc_config is missing key: %s", vpc_config$SUBNETS_KEY))
  if (!inherits(subnets, "list"))
    ValueError$new(sprintf("vpc_config value for %s is not a list: %s", vpc_config$SUBNETS_KEY, subnets))

  if (length(subnets) == 0)
    ValueError$new(sprintf("vpc_config value for %s is empty", vpc_config$SUBNETS_KEY))

  security_group_ids = vpc_config[[vpc_config$SECURITY_GROUP_IDS_KEY]]
  if (length(security_group_ids) == 0)
    ValueError$new(sprintf("vpc_config is missing key: %s", vpc_config$SECURITY_GROUP_IDS_KEY))

  if (!inherits(subnets, "list"))
    ValueError$new(sprintf("vpc_config value for %s is not a list: %s",
      vpc_config$SECURITY_GROUP_IDS_KEY, security_group_ids))

  if (length(security_group_ids) == 0)
    ValueError$new(sprintf("vpc_config value for %s is empty", vpc_config$SECURITY_GROUP_IDS_KEY))

  return(list(Subnets = subnets, SecurityGroupIds = security_group_ids))
}
