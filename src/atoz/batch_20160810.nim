
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Batch
## version: 2016-08-10
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS Batch enables you to run batch computing workloads on the AWS Cloud. Batch computing is a common way for developers, scientists, and engineers to access large amounts of compute resources, and AWS Batch removes the undifferentiated heavy lifting of configuring and managing the required infrastructure. AWS Batch will be familiar to users of traditional batch computing software. This service can efficiently provision resources in response to jobs submitted in order to eliminate capacity constraints, reduce compute costs, and deliver results quickly.</p> <p>As a fully managed service, AWS Batch enables developers, scientists, and engineers to run batch computing workloads of any scale. AWS Batch automatically provisions compute resources and optimizes the workload distribution based on the quantity and scale of the workloads. With AWS Batch, there is no need to install or manage batch computing software, which allows you to focus on analyzing results and solving problems. AWS Batch reduces operational complexities, saves time, and reduces costs, which makes it easy for developers, scientists, and engineers to run their batch jobs in the AWS Cloud.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/batch/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "batch.ap-northeast-1.amazonaws.com", "ap-southeast-1": "batch.ap-southeast-1.amazonaws.com",
                           "us-west-2": "batch.us-west-2.amazonaws.com",
                           "eu-west-2": "batch.eu-west-2.amazonaws.com", "ap-northeast-3": "batch.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "batch.eu-central-1.amazonaws.com",
                           "us-east-2": "batch.us-east-2.amazonaws.com",
                           "us-east-1": "batch.us-east-1.amazonaws.com", "cn-northwest-1": "batch.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "batch.ap-south-1.amazonaws.com",
                           "eu-north-1": "batch.eu-north-1.amazonaws.com", "ap-northeast-2": "batch.ap-northeast-2.amazonaws.com",
                           "us-west-1": "batch.us-west-1.amazonaws.com", "us-gov-east-1": "batch.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "batch.eu-west-3.amazonaws.com",
                           "cn-north-1": "batch.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "batch.sa-east-1.amazonaws.com",
                           "eu-west-1": "batch.eu-west-1.amazonaws.com", "us-gov-west-1": "batch.us-gov-west-1.amazonaws.com", "ap-southeast-2": "batch.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "batch.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "batch.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "batch.ap-southeast-1.amazonaws.com",
      "us-west-2": "batch.us-west-2.amazonaws.com",
      "eu-west-2": "batch.eu-west-2.amazonaws.com",
      "ap-northeast-3": "batch.ap-northeast-3.amazonaws.com",
      "eu-central-1": "batch.eu-central-1.amazonaws.com",
      "us-east-2": "batch.us-east-2.amazonaws.com",
      "us-east-1": "batch.us-east-1.amazonaws.com",
      "cn-northwest-1": "batch.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "batch.ap-south-1.amazonaws.com",
      "eu-north-1": "batch.eu-north-1.amazonaws.com",
      "ap-northeast-2": "batch.ap-northeast-2.amazonaws.com",
      "us-west-1": "batch.us-west-1.amazonaws.com",
      "us-gov-east-1": "batch.us-gov-east-1.amazonaws.com",
      "eu-west-3": "batch.eu-west-3.amazonaws.com",
      "cn-north-1": "batch.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "batch.sa-east-1.amazonaws.com",
      "eu-west-1": "batch.eu-west-1.amazonaws.com",
      "us-gov-west-1": "batch.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "batch.ap-southeast-2.amazonaws.com",
      "ca-central-1": "batch.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "batch"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CancelJob_600768 = ref object of OpenApiRestCall_600426
proc url_CancelJob_600770(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelJob_600769(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels a job in an AWS Batch job queue. Jobs that are in the <code>SUBMITTED</code>, <code>PENDING</code>, or <code>RUNNABLE</code> state are cancelled. Jobs that have progressed to <code>STARTING</code> or <code>RUNNING</code> are not cancelled (but the API operation still succeeds, even if no job is cancelled); these jobs must be terminated with the <a>TerminateJob</a> operation.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Content-Sha256", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Algorithm")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Algorithm", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Signature")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Signature", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-SignedHeaders", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Credential")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Credential", valid_600888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600912: Call_CancelJob_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels a job in an AWS Batch job queue. Jobs that are in the <code>SUBMITTED</code>, <code>PENDING</code>, or <code>RUNNABLE</code> state are cancelled. Jobs that have progressed to <code>STARTING</code> or <code>RUNNING</code> are not cancelled (but the API operation still succeeds, even if no job is cancelled); these jobs must be terminated with the <a>TerminateJob</a> operation.
  ## 
  let valid = call_600912.validator(path, query, header, formData, body)
  let scheme = call_600912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600912.url(scheme.get, call_600912.host, call_600912.base,
                         call_600912.route, valid.getOrDefault("path"))
  result = hook(call_600912, url, valid)

proc call*(call_600983: Call_CancelJob_600768; body: JsonNode): Recallable =
  ## cancelJob
  ## Cancels a job in an AWS Batch job queue. Jobs that are in the <code>SUBMITTED</code>, <code>PENDING</code>, or <code>RUNNABLE</code> state are cancelled. Jobs that have progressed to <code>STARTING</code> or <code>RUNNING</code> are not cancelled (but the API operation still succeeds, even if no job is cancelled); these jobs must be terminated with the <a>TerminateJob</a> operation.
  ##   body: JObject (required)
  var body_600984 = newJObject()
  if body != nil:
    body_600984 = body
  result = call_600983.call(nil, nil, nil, nil, body_600984)

var cancelJob* = Call_CancelJob_600768(name: "cancelJob", meth: HttpMethod.HttpPost,
                                    host: "batch.amazonaws.com",
                                    route: "/v1/canceljob",
                                    validator: validate_CancelJob_600769,
                                    base: "/", url: url_CancelJob_600770,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComputeEnvironment_601023 = ref object of OpenApiRestCall_600426
proc url_CreateComputeEnvironment_601025(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateComputeEnvironment_601024(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an AWS Batch compute environment. You can create <code>MANAGED</code> or <code>UNMANAGED</code> compute environments.</p> <p>In a managed compute environment, AWS Batch manages the capacity and instance types of the compute resources within the environment. This is based on the compute resource specification that you define or the <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html">launch template</a> that you specify when you create the compute environment. You can choose to use Amazon EC2 On-Demand Instances or Spot Instances in your managed compute environment. You can optionally set a maximum price so that Spot Instances only launch when the Spot Instance price is below a specified percentage of the On-Demand price.</p> <note> <p>Multi-node parallel jobs are not supported on Spot Instances.</p> </note> <p>In an unmanaged compute environment, you can manage your own compute resources. This provides more compute resource configuration options, such as using a custom AMI, but you must ensure that your AMI meets the Amazon ECS container instance AMI specification. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container_instance_AMIs.html">Container Instance AMIs</a> in the <i>Amazon Elastic Container Service Developer Guide</i>. After you have created your unmanaged compute environment, you can use the <a>DescribeComputeEnvironments</a> operation to find the Amazon ECS cluster that is associated with it. Then, manually launch your container instances into that Amazon ECS cluster. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html">Launching an Amazon ECS Container Instance</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <note> <p>AWS Batch does not upgrade the AMIs in a compute environment after it is created (for example, when a newer version of the Amazon ECS-optimized AMI is available). You are responsible for the management of the guest operating system (including updates and security patches) and any additional application software or utilities that you install on the compute resources. To use a new AMI for your AWS Batch jobs:</p> <ol> <li> <p>Create a new compute environment with the new AMI.</p> </li> <li> <p>Add the compute environment to an existing job queue.</p> </li> <li> <p>Remove the old compute environment from your job queue.</p> </li> <li> <p>Delete the old compute environment.</p> </li> </ol> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601026 = header.getOrDefault("X-Amz-Date")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Date", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Security-Token")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Security-Token", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Content-Sha256", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Algorithm")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Algorithm", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Signature")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Signature", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-SignedHeaders", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Credential")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Credential", valid_601032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601034: Call_CreateComputeEnvironment_601023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Batch compute environment. You can create <code>MANAGED</code> or <code>UNMANAGED</code> compute environments.</p> <p>In a managed compute environment, AWS Batch manages the capacity and instance types of the compute resources within the environment. This is based on the compute resource specification that you define or the <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html">launch template</a> that you specify when you create the compute environment. You can choose to use Amazon EC2 On-Demand Instances or Spot Instances in your managed compute environment. You can optionally set a maximum price so that Spot Instances only launch when the Spot Instance price is below a specified percentage of the On-Demand price.</p> <note> <p>Multi-node parallel jobs are not supported on Spot Instances.</p> </note> <p>In an unmanaged compute environment, you can manage your own compute resources. This provides more compute resource configuration options, such as using a custom AMI, but you must ensure that your AMI meets the Amazon ECS container instance AMI specification. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container_instance_AMIs.html">Container Instance AMIs</a> in the <i>Amazon Elastic Container Service Developer Guide</i>. After you have created your unmanaged compute environment, you can use the <a>DescribeComputeEnvironments</a> operation to find the Amazon ECS cluster that is associated with it. Then, manually launch your container instances into that Amazon ECS cluster. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html">Launching an Amazon ECS Container Instance</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <note> <p>AWS Batch does not upgrade the AMIs in a compute environment after it is created (for example, when a newer version of the Amazon ECS-optimized AMI is available). You are responsible for the management of the guest operating system (including updates and security patches) and any additional application software or utilities that you install on the compute resources. To use a new AMI for your AWS Batch jobs:</p> <ol> <li> <p>Create a new compute environment with the new AMI.</p> </li> <li> <p>Add the compute environment to an existing job queue.</p> </li> <li> <p>Remove the old compute environment from your job queue.</p> </li> <li> <p>Delete the old compute environment.</p> </li> </ol> </note>
  ## 
  let valid = call_601034.validator(path, query, header, formData, body)
  let scheme = call_601034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601034.url(scheme.get, call_601034.host, call_601034.base,
                         call_601034.route, valid.getOrDefault("path"))
  result = hook(call_601034, url, valid)

proc call*(call_601035: Call_CreateComputeEnvironment_601023; body: JsonNode): Recallable =
  ## createComputeEnvironment
  ## <p>Creates an AWS Batch compute environment. You can create <code>MANAGED</code> or <code>UNMANAGED</code> compute environments.</p> <p>In a managed compute environment, AWS Batch manages the capacity and instance types of the compute resources within the environment. This is based on the compute resource specification that you define or the <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html">launch template</a> that you specify when you create the compute environment. You can choose to use Amazon EC2 On-Demand Instances or Spot Instances in your managed compute environment. You can optionally set a maximum price so that Spot Instances only launch when the Spot Instance price is below a specified percentage of the On-Demand price.</p> <note> <p>Multi-node parallel jobs are not supported on Spot Instances.</p> </note> <p>In an unmanaged compute environment, you can manage your own compute resources. This provides more compute resource configuration options, such as using a custom AMI, but you must ensure that your AMI meets the Amazon ECS container instance AMI specification. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container_instance_AMIs.html">Container Instance AMIs</a> in the <i>Amazon Elastic Container Service Developer Guide</i>. After you have created your unmanaged compute environment, you can use the <a>DescribeComputeEnvironments</a> operation to find the Amazon ECS cluster that is associated with it. Then, manually launch your container instances into that Amazon ECS cluster. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html">Launching an Amazon ECS Container Instance</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <note> <p>AWS Batch does not upgrade the AMIs in a compute environment after it is created (for example, when a newer version of the Amazon ECS-optimized AMI is available). You are responsible for the management of the guest operating system (including updates and security patches) and any additional application software or utilities that you install on the compute resources. To use a new AMI for your AWS Batch jobs:</p> <ol> <li> <p>Create a new compute environment with the new AMI.</p> </li> <li> <p>Add the compute environment to an existing job queue.</p> </li> <li> <p>Remove the old compute environment from your job queue.</p> </li> <li> <p>Delete the old compute environment.</p> </li> </ol> </note>
  ##   body: JObject (required)
  var body_601036 = newJObject()
  if body != nil:
    body_601036 = body
  result = call_601035.call(nil, nil, nil, nil, body_601036)

var createComputeEnvironment* = Call_CreateComputeEnvironment_601023(
    name: "createComputeEnvironment", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/createcomputeenvironment",
    validator: validate_CreateComputeEnvironment_601024, base: "/",
    url: url_CreateComputeEnvironment_601025, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJobQueue_601037 = ref object of OpenApiRestCall_600426
proc url_CreateJobQueue_601039(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateJobQueue_601038(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates an AWS Batch job queue. When you create a job queue, you associate one or more compute environments to the queue and assign an order of preference for the compute environments.</p> <p>You also set a priority to the job queue that determines the order in which the AWS Batch scheduler places jobs onto its associated compute environments. For example, if a compute environment is associated with more than one job queue, the job queue with a higher priority is given preference for scheduling jobs to that compute environment.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Content-Sha256", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Algorithm")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Algorithm", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Signature")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Signature", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-SignedHeaders", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Credential")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Credential", valid_601046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601048: Call_CreateJobQueue_601037; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Batch job queue. When you create a job queue, you associate one or more compute environments to the queue and assign an order of preference for the compute environments.</p> <p>You also set a priority to the job queue that determines the order in which the AWS Batch scheduler places jobs onto its associated compute environments. For example, if a compute environment is associated with more than one job queue, the job queue with a higher priority is given preference for scheduling jobs to that compute environment.</p>
  ## 
  let valid = call_601048.validator(path, query, header, formData, body)
  let scheme = call_601048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601048.url(scheme.get, call_601048.host, call_601048.base,
                         call_601048.route, valid.getOrDefault("path"))
  result = hook(call_601048, url, valid)

proc call*(call_601049: Call_CreateJobQueue_601037; body: JsonNode): Recallable =
  ## createJobQueue
  ## <p>Creates an AWS Batch job queue. When you create a job queue, you associate one or more compute environments to the queue and assign an order of preference for the compute environments.</p> <p>You also set a priority to the job queue that determines the order in which the AWS Batch scheduler places jobs onto its associated compute environments. For example, if a compute environment is associated with more than one job queue, the job queue with a higher priority is given preference for scheduling jobs to that compute environment.</p>
  ##   body: JObject (required)
  var body_601050 = newJObject()
  if body != nil:
    body_601050 = body
  result = call_601049.call(nil, nil, nil, nil, body_601050)

var createJobQueue* = Call_CreateJobQueue_601037(name: "createJobQueue",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/createjobqueue", validator: validate_CreateJobQueue_601038,
    base: "/", url: url_CreateJobQueue_601039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComputeEnvironment_601051 = ref object of OpenApiRestCall_600426
proc url_DeleteComputeEnvironment_601053(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteComputeEnvironment_601052(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an AWS Batch compute environment.</p> <p>Before you can delete a compute environment, you must set its state to <code>DISABLED</code> with the <a>UpdateComputeEnvironment</a> API operation and disassociate it from any job queues with the <a>UpdateJobQueue</a> API operation.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601054 = header.getOrDefault("X-Amz-Date")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Date", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Security-Token")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Security-Token", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Content-Sha256", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Algorithm")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Algorithm", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Signature")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Signature", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-SignedHeaders", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Credential")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Credential", valid_601060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601062: Call_DeleteComputeEnvironment_601051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Batch compute environment.</p> <p>Before you can delete a compute environment, you must set its state to <code>DISABLED</code> with the <a>UpdateComputeEnvironment</a> API operation and disassociate it from any job queues with the <a>UpdateJobQueue</a> API operation.</p>
  ## 
  let valid = call_601062.validator(path, query, header, formData, body)
  let scheme = call_601062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601062.url(scheme.get, call_601062.host, call_601062.base,
                         call_601062.route, valid.getOrDefault("path"))
  result = hook(call_601062, url, valid)

proc call*(call_601063: Call_DeleteComputeEnvironment_601051; body: JsonNode): Recallable =
  ## deleteComputeEnvironment
  ## <p>Deletes an AWS Batch compute environment.</p> <p>Before you can delete a compute environment, you must set its state to <code>DISABLED</code> with the <a>UpdateComputeEnvironment</a> API operation and disassociate it from any job queues with the <a>UpdateJobQueue</a> API operation.</p>
  ##   body: JObject (required)
  var body_601064 = newJObject()
  if body != nil:
    body_601064 = body
  result = call_601063.call(nil, nil, nil, nil, body_601064)

var deleteComputeEnvironment* = Call_DeleteComputeEnvironment_601051(
    name: "deleteComputeEnvironment", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/deletecomputeenvironment",
    validator: validate_DeleteComputeEnvironment_601052, base: "/",
    url: url_DeleteComputeEnvironment_601053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJobQueue_601065 = ref object of OpenApiRestCall_600426
proc url_DeleteJobQueue_601067(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteJobQueue_601066(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes the specified job queue. You must first disable submissions for a queue with the <a>UpdateJobQueue</a> operation. All jobs in the queue are terminated when you delete a job queue.</p> <p>It is not necessary to disassociate compute environments from a queue before submitting a <code>DeleteJobQueue</code> request. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601068 = header.getOrDefault("X-Amz-Date")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Date", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Security-Token")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Security-Token", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Content-Sha256", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Algorithm")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Algorithm", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Signature")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Signature", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-SignedHeaders", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Credential")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Credential", valid_601074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601076: Call_DeleteJobQueue_601065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified job queue. You must first disable submissions for a queue with the <a>UpdateJobQueue</a> operation. All jobs in the queue are terminated when you delete a job queue.</p> <p>It is not necessary to disassociate compute environments from a queue before submitting a <code>DeleteJobQueue</code> request. </p>
  ## 
  let valid = call_601076.validator(path, query, header, formData, body)
  let scheme = call_601076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601076.url(scheme.get, call_601076.host, call_601076.base,
                         call_601076.route, valid.getOrDefault("path"))
  result = hook(call_601076, url, valid)

proc call*(call_601077: Call_DeleteJobQueue_601065; body: JsonNode): Recallable =
  ## deleteJobQueue
  ## <p>Deletes the specified job queue. You must first disable submissions for a queue with the <a>UpdateJobQueue</a> operation. All jobs in the queue are terminated when you delete a job queue.</p> <p>It is not necessary to disassociate compute environments from a queue before submitting a <code>DeleteJobQueue</code> request. </p>
  ##   body: JObject (required)
  var body_601078 = newJObject()
  if body != nil:
    body_601078 = body
  result = call_601077.call(nil, nil, nil, nil, body_601078)

var deleteJobQueue* = Call_DeleteJobQueue_601065(name: "deleteJobQueue",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/deletejobqueue", validator: validate_DeleteJobQueue_601066,
    base: "/", url: url_DeleteJobQueue_601067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterJobDefinition_601079 = ref object of OpenApiRestCall_600426
proc url_DeregisterJobDefinition_601081(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterJobDefinition_601080(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deregisters an AWS Batch job definition.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601082 = header.getOrDefault("X-Amz-Date")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Date", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Security-Token")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Security-Token", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Content-Sha256", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Algorithm")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Algorithm", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Signature")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Signature", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-SignedHeaders", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Credential")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Credential", valid_601088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601090: Call_DeregisterJobDefinition_601079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters an AWS Batch job definition.
  ## 
  let valid = call_601090.validator(path, query, header, formData, body)
  let scheme = call_601090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601090.url(scheme.get, call_601090.host, call_601090.base,
                         call_601090.route, valid.getOrDefault("path"))
  result = hook(call_601090, url, valid)

proc call*(call_601091: Call_DeregisterJobDefinition_601079; body: JsonNode): Recallable =
  ## deregisterJobDefinition
  ## Deregisters an AWS Batch job definition.
  ##   body: JObject (required)
  var body_601092 = newJObject()
  if body != nil:
    body_601092 = body
  result = call_601091.call(nil, nil, nil, nil, body_601092)

var deregisterJobDefinition* = Call_DeregisterJobDefinition_601079(
    name: "deregisterJobDefinition", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/deregisterjobdefinition",
    validator: validate_DeregisterJobDefinition_601080, base: "/",
    url: url_DeregisterJobDefinition_601081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComputeEnvironments_601093 = ref object of OpenApiRestCall_600426
proc url_DescribeComputeEnvironments_601095(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeComputeEnvironments_601094(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes one or more of your compute environments.</p> <p>If you are using an unmanaged compute environment, you can use the <code>DescribeComputeEnvironment</code> operation to determine the <code>ecsClusterArn</code> that you should launch your Amazon ECS container instances into.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601096 = query.getOrDefault("maxResults")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "maxResults", valid_601096
  var valid_601097 = query.getOrDefault("nextToken")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "nextToken", valid_601097
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601098 = header.getOrDefault("X-Amz-Date")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Date", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Security-Token")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Security-Token", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Content-Sha256", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Algorithm")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Algorithm", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Signature")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Signature", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-SignedHeaders", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Credential")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Credential", valid_601104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601106: Call_DescribeComputeEnvironments_601093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes one or more of your compute environments.</p> <p>If you are using an unmanaged compute environment, you can use the <code>DescribeComputeEnvironment</code> operation to determine the <code>ecsClusterArn</code> that you should launch your Amazon ECS container instances into.</p>
  ## 
  let valid = call_601106.validator(path, query, header, formData, body)
  let scheme = call_601106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601106.url(scheme.get, call_601106.host, call_601106.base,
                         call_601106.route, valid.getOrDefault("path"))
  result = hook(call_601106, url, valid)

proc call*(call_601107: Call_DescribeComputeEnvironments_601093; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeComputeEnvironments
  ## <p>Describes one or more of your compute environments.</p> <p>If you are using an unmanaged compute environment, you can use the <code>DescribeComputeEnvironment</code> operation to determine the <code>ecsClusterArn</code> that you should launch your Amazon ECS container instances into.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601108 = newJObject()
  var body_601109 = newJObject()
  add(query_601108, "maxResults", newJString(maxResults))
  add(query_601108, "nextToken", newJString(nextToken))
  if body != nil:
    body_601109 = body
  result = call_601107.call(nil, query_601108, nil, nil, body_601109)

var describeComputeEnvironments* = Call_DescribeComputeEnvironments_601093(
    name: "describeComputeEnvironments", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/describecomputeenvironments",
    validator: validate_DescribeComputeEnvironments_601094, base: "/",
    url: url_DescribeComputeEnvironments_601095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobDefinitions_601111 = ref object of OpenApiRestCall_600426
proc url_DescribeJobDefinitions_601113(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeJobDefinitions_601112(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a list of job definitions. You can specify a <code>status</code> (such as <code>ACTIVE</code>) to only return job definitions that match that status.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601114 = query.getOrDefault("maxResults")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "maxResults", valid_601114
  var valid_601115 = query.getOrDefault("nextToken")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "nextToken", valid_601115
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601116 = header.getOrDefault("X-Amz-Date")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Date", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Security-Token")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Security-Token", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_DescribeJobDefinitions_601111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a list of job definitions. You can specify a <code>status</code> (such as <code>ACTIVE</code>) to only return job definitions that match that status.
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_DescribeJobDefinitions_601111; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeJobDefinitions
  ## Describes a list of job definitions. You can specify a <code>status</code> (such as <code>ACTIVE</code>) to only return job definitions that match that status.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601126 = newJObject()
  var body_601127 = newJObject()
  add(query_601126, "maxResults", newJString(maxResults))
  add(query_601126, "nextToken", newJString(nextToken))
  if body != nil:
    body_601127 = body
  result = call_601125.call(nil, query_601126, nil, nil, body_601127)

var describeJobDefinitions* = Call_DescribeJobDefinitions_601111(
    name: "describeJobDefinitions", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/describejobdefinitions",
    validator: validate_DescribeJobDefinitions_601112, base: "/",
    url: url_DescribeJobDefinitions_601113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobQueues_601128 = ref object of OpenApiRestCall_600426
proc url_DescribeJobQueues_601130(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeJobQueues_601129(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Describes one or more of your job queues.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601131 = query.getOrDefault("maxResults")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "maxResults", valid_601131
  var valid_601132 = query.getOrDefault("nextToken")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "nextToken", valid_601132
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601133 = header.getOrDefault("X-Amz-Date")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Date", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Security-Token")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Security-Token", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Content-Sha256", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Algorithm")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Algorithm", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Signature")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Signature", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-SignedHeaders", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Credential")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Credential", valid_601139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601141: Call_DescribeJobQueues_601128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your job queues.
  ## 
  let valid = call_601141.validator(path, query, header, formData, body)
  let scheme = call_601141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601141.url(scheme.get, call_601141.host, call_601141.base,
                         call_601141.route, valid.getOrDefault("path"))
  result = hook(call_601141, url, valid)

proc call*(call_601142: Call_DescribeJobQueues_601128; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describeJobQueues
  ## Describes one or more of your job queues.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601143 = newJObject()
  var body_601144 = newJObject()
  add(query_601143, "maxResults", newJString(maxResults))
  add(query_601143, "nextToken", newJString(nextToken))
  if body != nil:
    body_601144 = body
  result = call_601142.call(nil, query_601143, nil, nil, body_601144)

var describeJobQueues* = Call_DescribeJobQueues_601128(name: "describeJobQueues",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/describejobqueues", validator: validate_DescribeJobQueues_601129,
    base: "/", url: url_DescribeJobQueues_601130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobs_601145 = ref object of OpenApiRestCall_600426
proc url_DescribeJobs_601147(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeJobs_601146(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a list of AWS Batch jobs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601148 = header.getOrDefault("X-Amz-Date")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Date", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Security-Token")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Security-Token", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Content-Sha256", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Algorithm")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Algorithm", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Signature")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Signature", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-SignedHeaders", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Credential")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Credential", valid_601154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601156: Call_DescribeJobs_601145; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a list of AWS Batch jobs.
  ## 
  let valid = call_601156.validator(path, query, header, formData, body)
  let scheme = call_601156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601156.url(scheme.get, call_601156.host, call_601156.base,
                         call_601156.route, valid.getOrDefault("path"))
  result = hook(call_601156, url, valid)

proc call*(call_601157: Call_DescribeJobs_601145; body: JsonNode): Recallable =
  ## describeJobs
  ## Describes a list of AWS Batch jobs.
  ##   body: JObject (required)
  var body_601158 = newJObject()
  if body != nil:
    body_601158 = body
  result = call_601157.call(nil, nil, nil, nil, body_601158)

var describeJobs* = Call_DescribeJobs_601145(name: "describeJobs",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/describejobs", validator: validate_DescribeJobs_601146, base: "/",
    url: url_DescribeJobs_601147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_601159 = ref object of OpenApiRestCall_600426
proc url_ListJobs_601161(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListJobs_601160(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of AWS Batch jobs.</p> <p>You must specify only one of the following:</p> <ul> <li> <p>a job queue ID to return a list of jobs in that job queue</p> </li> <li> <p>a multi-node parallel job ID to return a list of that job's nodes</p> </li> <li> <p>an array job ID to return a list of that job's children</p> </li> </ul> <p>You can filter the results by job status with the <code>jobStatus</code> parameter. If you do not specify a status, only <code>RUNNING</code> jobs are returned.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601162 = query.getOrDefault("maxResults")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "maxResults", valid_601162
  var valid_601163 = query.getOrDefault("nextToken")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "nextToken", valid_601163
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601164 = header.getOrDefault("X-Amz-Date")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Date", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Security-Token")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Security-Token", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Content-Sha256", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Algorithm")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Algorithm", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Signature")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Signature", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-SignedHeaders", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Credential")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Credential", valid_601170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601172: Call_ListJobs_601159; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of AWS Batch jobs.</p> <p>You must specify only one of the following:</p> <ul> <li> <p>a job queue ID to return a list of jobs in that job queue</p> </li> <li> <p>a multi-node parallel job ID to return a list of that job's nodes</p> </li> <li> <p>an array job ID to return a list of that job's children</p> </li> </ul> <p>You can filter the results by job status with the <code>jobStatus</code> parameter. If you do not specify a status, only <code>RUNNING</code> jobs are returned.</p>
  ## 
  let valid = call_601172.validator(path, query, header, formData, body)
  let scheme = call_601172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601172.url(scheme.get, call_601172.host, call_601172.base,
                         call_601172.route, valid.getOrDefault("path"))
  result = hook(call_601172, url, valid)

proc call*(call_601173: Call_ListJobs_601159; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listJobs
  ## <p>Returns a list of AWS Batch jobs.</p> <p>You must specify only one of the following:</p> <ul> <li> <p>a job queue ID to return a list of jobs in that job queue</p> </li> <li> <p>a multi-node parallel job ID to return a list of that job's nodes</p> </li> <li> <p>an array job ID to return a list of that job's children</p> </li> </ul> <p>You can filter the results by job status with the <code>jobStatus</code> parameter. If you do not specify a status, only <code>RUNNING</code> jobs are returned.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601174 = newJObject()
  var body_601175 = newJObject()
  add(query_601174, "maxResults", newJString(maxResults))
  add(query_601174, "nextToken", newJString(nextToken))
  if body != nil:
    body_601175 = body
  result = call_601173.call(nil, query_601174, nil, nil, body_601175)

var listJobs* = Call_ListJobs_601159(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "batch.amazonaws.com",
                                  route: "/v1/listjobs",
                                  validator: validate_ListJobs_601160, base: "/",
                                  url: url_ListJobs_601161,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterJobDefinition_601176 = ref object of OpenApiRestCall_600426
proc url_RegisterJobDefinition_601178(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterJobDefinition_601177(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Registers an AWS Batch job definition. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601179 = header.getOrDefault("X-Amz-Date")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Date", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Security-Token")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Security-Token", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Content-Sha256", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Algorithm")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Algorithm", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Signature")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Signature", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-SignedHeaders", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Credential")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Credential", valid_601185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601187: Call_RegisterJobDefinition_601176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers an AWS Batch job definition. 
  ## 
  let valid = call_601187.validator(path, query, header, formData, body)
  let scheme = call_601187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601187.url(scheme.get, call_601187.host, call_601187.base,
                         call_601187.route, valid.getOrDefault("path"))
  result = hook(call_601187, url, valid)

proc call*(call_601188: Call_RegisterJobDefinition_601176; body: JsonNode): Recallable =
  ## registerJobDefinition
  ## Registers an AWS Batch job definition. 
  ##   body: JObject (required)
  var body_601189 = newJObject()
  if body != nil:
    body_601189 = body
  result = call_601188.call(nil, nil, nil, nil, body_601189)

var registerJobDefinition* = Call_RegisterJobDefinition_601176(
    name: "registerJobDefinition", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/registerjobdefinition",
    validator: validate_RegisterJobDefinition_601177, base: "/",
    url: url_RegisterJobDefinition_601178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitJob_601190 = ref object of OpenApiRestCall_600426
proc url_SubmitJob_601192(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SubmitJob_601191(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Submits an AWS Batch job from a job definition. Parameters specified during <a>SubmitJob</a> override parameters defined in the job definition. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601193 = header.getOrDefault("X-Amz-Date")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Date", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Security-Token")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Security-Token", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Content-Sha256", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Algorithm")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Algorithm", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Signature")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Signature", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-SignedHeaders", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Credential")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Credential", valid_601199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601201: Call_SubmitJob_601190; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Submits an AWS Batch job from a job definition. Parameters specified during <a>SubmitJob</a> override parameters defined in the job definition. 
  ## 
  let valid = call_601201.validator(path, query, header, formData, body)
  let scheme = call_601201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601201.url(scheme.get, call_601201.host, call_601201.base,
                         call_601201.route, valid.getOrDefault("path"))
  result = hook(call_601201, url, valid)

proc call*(call_601202: Call_SubmitJob_601190; body: JsonNode): Recallable =
  ## submitJob
  ## Submits an AWS Batch job from a job definition. Parameters specified during <a>SubmitJob</a> override parameters defined in the job definition. 
  ##   body: JObject (required)
  var body_601203 = newJObject()
  if body != nil:
    body_601203 = body
  result = call_601202.call(nil, nil, nil, nil, body_601203)

var submitJob* = Call_SubmitJob_601190(name: "submitJob", meth: HttpMethod.HttpPost,
                                    host: "batch.amazonaws.com",
                                    route: "/v1/submitjob",
                                    validator: validate_SubmitJob_601191,
                                    base: "/", url: url_SubmitJob_601192,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateJob_601204 = ref object of OpenApiRestCall_600426
proc url_TerminateJob_601206(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TerminateJob_601205(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Terminates a job in a job queue. Jobs that are in the <code>STARTING</code> or <code>RUNNING</code> state are terminated, which causes them to transition to <code>FAILED</code>. Jobs that have not progressed to the <code>STARTING</code> state are cancelled.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601207 = header.getOrDefault("X-Amz-Date")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Date", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Security-Token")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Security-Token", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Content-Sha256", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Algorithm")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Algorithm", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Signature")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Signature", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-SignedHeaders", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Credential")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Credential", valid_601213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601215: Call_TerminateJob_601204; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates a job in a job queue. Jobs that are in the <code>STARTING</code> or <code>RUNNING</code> state are terminated, which causes them to transition to <code>FAILED</code>. Jobs that have not progressed to the <code>STARTING</code> state are cancelled.
  ## 
  let valid = call_601215.validator(path, query, header, formData, body)
  let scheme = call_601215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601215.url(scheme.get, call_601215.host, call_601215.base,
                         call_601215.route, valid.getOrDefault("path"))
  result = hook(call_601215, url, valid)

proc call*(call_601216: Call_TerminateJob_601204; body: JsonNode): Recallable =
  ## terminateJob
  ## Terminates a job in a job queue. Jobs that are in the <code>STARTING</code> or <code>RUNNING</code> state are terminated, which causes them to transition to <code>FAILED</code>. Jobs that have not progressed to the <code>STARTING</code> state are cancelled.
  ##   body: JObject (required)
  var body_601217 = newJObject()
  if body != nil:
    body_601217 = body
  result = call_601216.call(nil, nil, nil, nil, body_601217)

var terminateJob* = Call_TerminateJob_601204(name: "terminateJob",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/terminatejob", validator: validate_TerminateJob_601205, base: "/",
    url: url_TerminateJob_601206, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComputeEnvironment_601218 = ref object of OpenApiRestCall_600426
proc url_UpdateComputeEnvironment_601220(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateComputeEnvironment_601219(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an AWS Batch compute environment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601221 = header.getOrDefault("X-Amz-Date")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Date", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Security-Token")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Security-Token", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Content-Sha256", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Algorithm")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Algorithm", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Signature")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Signature", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-SignedHeaders", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Credential")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Credential", valid_601227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601229: Call_UpdateComputeEnvironment_601218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an AWS Batch compute environment.
  ## 
  let valid = call_601229.validator(path, query, header, formData, body)
  let scheme = call_601229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601229.url(scheme.get, call_601229.host, call_601229.base,
                         call_601229.route, valid.getOrDefault("path"))
  result = hook(call_601229, url, valid)

proc call*(call_601230: Call_UpdateComputeEnvironment_601218; body: JsonNode): Recallable =
  ## updateComputeEnvironment
  ## Updates an AWS Batch compute environment.
  ##   body: JObject (required)
  var body_601231 = newJObject()
  if body != nil:
    body_601231 = body
  result = call_601230.call(nil, nil, nil, nil, body_601231)

var updateComputeEnvironment* = Call_UpdateComputeEnvironment_601218(
    name: "updateComputeEnvironment", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/updatecomputeenvironment",
    validator: validate_UpdateComputeEnvironment_601219, base: "/",
    url: url_UpdateComputeEnvironment_601220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobQueue_601232 = ref object of OpenApiRestCall_600426
proc url_UpdateJobQueue_601234(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateJobQueue_601233(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates a job queue.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601235 = header.getOrDefault("X-Amz-Date")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Date", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Security-Token")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Security-Token", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Content-Sha256", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Algorithm")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Algorithm", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Signature")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Signature", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-SignedHeaders", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-Credential")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Credential", valid_601241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601243: Call_UpdateJobQueue_601232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a job queue.
  ## 
  let valid = call_601243.validator(path, query, header, formData, body)
  let scheme = call_601243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601243.url(scheme.get, call_601243.host, call_601243.base,
                         call_601243.route, valid.getOrDefault("path"))
  result = hook(call_601243, url, valid)

proc call*(call_601244: Call_UpdateJobQueue_601232; body: JsonNode): Recallable =
  ## updateJobQueue
  ## Updates a job queue.
  ##   body: JObject (required)
  var body_601245 = newJObject()
  if body != nil:
    body_601245 = body
  result = call_601244.call(nil, nil, nil, nil, body_601245)

var updateJobQueue* = Call_UpdateJobQueue_601232(name: "updateJobQueue",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/updatejobqueue", validator: validate_UpdateJobQueue_601233,
    base: "/", url: url_UpdateJobQueue_601234, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
