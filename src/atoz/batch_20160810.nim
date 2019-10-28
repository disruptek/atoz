
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelJob_590703 = ref object of OpenApiRestCall_590364
proc url_CancelJob_590705(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelJob_590704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_590817 = header.getOrDefault("X-Amz-Signature")
  valid_590817 = validateParameter(valid_590817, JString, required = false,
                                 default = nil)
  if valid_590817 != nil:
    section.add "X-Amz-Signature", valid_590817
  var valid_590818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590818 = validateParameter(valid_590818, JString, required = false,
                                 default = nil)
  if valid_590818 != nil:
    section.add "X-Amz-Content-Sha256", valid_590818
  var valid_590819 = header.getOrDefault("X-Amz-Date")
  valid_590819 = validateParameter(valid_590819, JString, required = false,
                                 default = nil)
  if valid_590819 != nil:
    section.add "X-Amz-Date", valid_590819
  var valid_590820 = header.getOrDefault("X-Amz-Credential")
  valid_590820 = validateParameter(valid_590820, JString, required = false,
                                 default = nil)
  if valid_590820 != nil:
    section.add "X-Amz-Credential", valid_590820
  var valid_590821 = header.getOrDefault("X-Amz-Security-Token")
  valid_590821 = validateParameter(valid_590821, JString, required = false,
                                 default = nil)
  if valid_590821 != nil:
    section.add "X-Amz-Security-Token", valid_590821
  var valid_590822 = header.getOrDefault("X-Amz-Algorithm")
  valid_590822 = validateParameter(valid_590822, JString, required = false,
                                 default = nil)
  if valid_590822 != nil:
    section.add "X-Amz-Algorithm", valid_590822
  var valid_590823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590823 = validateParameter(valid_590823, JString, required = false,
                                 default = nil)
  if valid_590823 != nil:
    section.add "X-Amz-SignedHeaders", valid_590823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590847: Call_CancelJob_590703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels a job in an AWS Batch job queue. Jobs that are in the <code>SUBMITTED</code>, <code>PENDING</code>, or <code>RUNNABLE</code> state are cancelled. Jobs that have progressed to <code>STARTING</code> or <code>RUNNING</code> are not cancelled (but the API operation still succeeds, even if no job is cancelled); these jobs must be terminated with the <a>TerminateJob</a> operation.
  ## 
  let valid = call_590847.validator(path, query, header, formData, body)
  let scheme = call_590847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590847.url(scheme.get, call_590847.host, call_590847.base,
                         call_590847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590847, url, valid)

proc call*(call_590918: Call_CancelJob_590703; body: JsonNode): Recallable =
  ## cancelJob
  ## Cancels a job in an AWS Batch job queue. Jobs that are in the <code>SUBMITTED</code>, <code>PENDING</code>, or <code>RUNNABLE</code> state are cancelled. Jobs that have progressed to <code>STARTING</code> or <code>RUNNING</code> are not cancelled (but the API operation still succeeds, even if no job is cancelled); these jobs must be terminated with the <a>TerminateJob</a> operation.
  ##   body: JObject (required)
  var body_590919 = newJObject()
  if body != nil:
    body_590919 = body
  result = call_590918.call(nil, nil, nil, nil, body_590919)

var cancelJob* = Call_CancelJob_590703(name: "cancelJob", meth: HttpMethod.HttpPost,
                                    host: "batch.amazonaws.com",
                                    route: "/v1/canceljob",
                                    validator: validate_CancelJob_590704,
                                    base: "/", url: url_CancelJob_590705,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComputeEnvironment_590958 = ref object of OpenApiRestCall_590364
proc url_CreateComputeEnvironment_590960(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateComputeEnvironment_590959(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_590961 = header.getOrDefault("X-Amz-Signature")
  valid_590961 = validateParameter(valid_590961, JString, required = false,
                                 default = nil)
  if valid_590961 != nil:
    section.add "X-Amz-Signature", valid_590961
  var valid_590962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590962 = validateParameter(valid_590962, JString, required = false,
                                 default = nil)
  if valid_590962 != nil:
    section.add "X-Amz-Content-Sha256", valid_590962
  var valid_590963 = header.getOrDefault("X-Amz-Date")
  valid_590963 = validateParameter(valid_590963, JString, required = false,
                                 default = nil)
  if valid_590963 != nil:
    section.add "X-Amz-Date", valid_590963
  var valid_590964 = header.getOrDefault("X-Amz-Credential")
  valid_590964 = validateParameter(valid_590964, JString, required = false,
                                 default = nil)
  if valid_590964 != nil:
    section.add "X-Amz-Credential", valid_590964
  var valid_590965 = header.getOrDefault("X-Amz-Security-Token")
  valid_590965 = validateParameter(valid_590965, JString, required = false,
                                 default = nil)
  if valid_590965 != nil:
    section.add "X-Amz-Security-Token", valid_590965
  var valid_590966 = header.getOrDefault("X-Amz-Algorithm")
  valid_590966 = validateParameter(valid_590966, JString, required = false,
                                 default = nil)
  if valid_590966 != nil:
    section.add "X-Amz-Algorithm", valid_590966
  var valid_590967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590967 = validateParameter(valid_590967, JString, required = false,
                                 default = nil)
  if valid_590967 != nil:
    section.add "X-Amz-SignedHeaders", valid_590967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590969: Call_CreateComputeEnvironment_590958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Batch compute environment. You can create <code>MANAGED</code> or <code>UNMANAGED</code> compute environments.</p> <p>In a managed compute environment, AWS Batch manages the capacity and instance types of the compute resources within the environment. This is based on the compute resource specification that you define or the <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html">launch template</a> that you specify when you create the compute environment. You can choose to use Amazon EC2 On-Demand Instances or Spot Instances in your managed compute environment. You can optionally set a maximum price so that Spot Instances only launch when the Spot Instance price is below a specified percentage of the On-Demand price.</p> <note> <p>Multi-node parallel jobs are not supported on Spot Instances.</p> </note> <p>In an unmanaged compute environment, you can manage your own compute resources. This provides more compute resource configuration options, such as using a custom AMI, but you must ensure that your AMI meets the Amazon ECS container instance AMI specification. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container_instance_AMIs.html">Container Instance AMIs</a> in the <i>Amazon Elastic Container Service Developer Guide</i>. After you have created your unmanaged compute environment, you can use the <a>DescribeComputeEnvironments</a> operation to find the Amazon ECS cluster that is associated with it. Then, manually launch your container instances into that Amazon ECS cluster. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html">Launching an Amazon ECS Container Instance</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <note> <p>AWS Batch does not upgrade the AMIs in a compute environment after it is created (for example, when a newer version of the Amazon ECS-optimized AMI is available). You are responsible for the management of the guest operating system (including updates and security patches) and any additional application software or utilities that you install on the compute resources. To use a new AMI for your AWS Batch jobs:</p> <ol> <li> <p>Create a new compute environment with the new AMI.</p> </li> <li> <p>Add the compute environment to an existing job queue.</p> </li> <li> <p>Remove the old compute environment from your job queue.</p> </li> <li> <p>Delete the old compute environment.</p> </li> </ol> </note>
  ## 
  let valid = call_590969.validator(path, query, header, formData, body)
  let scheme = call_590969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590969.url(scheme.get, call_590969.host, call_590969.base,
                         call_590969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590969, url, valid)

proc call*(call_590970: Call_CreateComputeEnvironment_590958; body: JsonNode): Recallable =
  ## createComputeEnvironment
  ## <p>Creates an AWS Batch compute environment. You can create <code>MANAGED</code> or <code>UNMANAGED</code> compute environments.</p> <p>In a managed compute environment, AWS Batch manages the capacity and instance types of the compute resources within the environment. This is based on the compute resource specification that you define or the <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html">launch template</a> that you specify when you create the compute environment. You can choose to use Amazon EC2 On-Demand Instances or Spot Instances in your managed compute environment. You can optionally set a maximum price so that Spot Instances only launch when the Spot Instance price is below a specified percentage of the On-Demand price.</p> <note> <p>Multi-node parallel jobs are not supported on Spot Instances.</p> </note> <p>In an unmanaged compute environment, you can manage your own compute resources. This provides more compute resource configuration options, such as using a custom AMI, but you must ensure that your AMI meets the Amazon ECS container instance AMI specification. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container_instance_AMIs.html">Container Instance AMIs</a> in the <i>Amazon Elastic Container Service Developer Guide</i>. After you have created your unmanaged compute environment, you can use the <a>DescribeComputeEnvironments</a> operation to find the Amazon ECS cluster that is associated with it. Then, manually launch your container instances into that Amazon ECS cluster. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html">Launching an Amazon ECS Container Instance</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <note> <p>AWS Batch does not upgrade the AMIs in a compute environment after it is created (for example, when a newer version of the Amazon ECS-optimized AMI is available). You are responsible for the management of the guest operating system (including updates and security patches) and any additional application software or utilities that you install on the compute resources. To use a new AMI for your AWS Batch jobs:</p> <ol> <li> <p>Create a new compute environment with the new AMI.</p> </li> <li> <p>Add the compute environment to an existing job queue.</p> </li> <li> <p>Remove the old compute environment from your job queue.</p> </li> <li> <p>Delete the old compute environment.</p> </li> </ol> </note>
  ##   body: JObject (required)
  var body_590971 = newJObject()
  if body != nil:
    body_590971 = body
  result = call_590970.call(nil, nil, nil, nil, body_590971)

var createComputeEnvironment* = Call_CreateComputeEnvironment_590958(
    name: "createComputeEnvironment", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/createcomputeenvironment",
    validator: validate_CreateComputeEnvironment_590959, base: "/",
    url: url_CreateComputeEnvironment_590960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJobQueue_590972 = ref object of OpenApiRestCall_590364
proc url_CreateJobQueue_590974(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJobQueue_590973(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_590975 = header.getOrDefault("X-Amz-Signature")
  valid_590975 = validateParameter(valid_590975, JString, required = false,
                                 default = nil)
  if valid_590975 != nil:
    section.add "X-Amz-Signature", valid_590975
  var valid_590976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590976 = validateParameter(valid_590976, JString, required = false,
                                 default = nil)
  if valid_590976 != nil:
    section.add "X-Amz-Content-Sha256", valid_590976
  var valid_590977 = header.getOrDefault("X-Amz-Date")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "X-Amz-Date", valid_590977
  var valid_590978 = header.getOrDefault("X-Amz-Credential")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Credential", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Security-Token")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Security-Token", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Algorithm")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Algorithm", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-SignedHeaders", valid_590981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590983: Call_CreateJobQueue_590972; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Batch job queue. When you create a job queue, you associate one or more compute environments to the queue and assign an order of preference for the compute environments.</p> <p>You also set a priority to the job queue that determines the order in which the AWS Batch scheduler places jobs onto its associated compute environments. For example, if a compute environment is associated with more than one job queue, the job queue with a higher priority is given preference for scheduling jobs to that compute environment.</p>
  ## 
  let valid = call_590983.validator(path, query, header, formData, body)
  let scheme = call_590983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590983.url(scheme.get, call_590983.host, call_590983.base,
                         call_590983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590983, url, valid)

proc call*(call_590984: Call_CreateJobQueue_590972; body: JsonNode): Recallable =
  ## createJobQueue
  ## <p>Creates an AWS Batch job queue. When you create a job queue, you associate one or more compute environments to the queue and assign an order of preference for the compute environments.</p> <p>You also set a priority to the job queue that determines the order in which the AWS Batch scheduler places jobs onto its associated compute environments. For example, if a compute environment is associated with more than one job queue, the job queue with a higher priority is given preference for scheduling jobs to that compute environment.</p>
  ##   body: JObject (required)
  var body_590985 = newJObject()
  if body != nil:
    body_590985 = body
  result = call_590984.call(nil, nil, nil, nil, body_590985)

var createJobQueue* = Call_CreateJobQueue_590972(name: "createJobQueue",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/createjobqueue", validator: validate_CreateJobQueue_590973,
    base: "/", url: url_CreateJobQueue_590974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComputeEnvironment_590986 = ref object of OpenApiRestCall_590364
proc url_DeleteComputeEnvironment_590988(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteComputeEnvironment_590987(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_590989 = header.getOrDefault("X-Amz-Signature")
  valid_590989 = validateParameter(valid_590989, JString, required = false,
                                 default = nil)
  if valid_590989 != nil:
    section.add "X-Amz-Signature", valid_590989
  var valid_590990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590990 = validateParameter(valid_590990, JString, required = false,
                                 default = nil)
  if valid_590990 != nil:
    section.add "X-Amz-Content-Sha256", valid_590990
  var valid_590991 = header.getOrDefault("X-Amz-Date")
  valid_590991 = validateParameter(valid_590991, JString, required = false,
                                 default = nil)
  if valid_590991 != nil:
    section.add "X-Amz-Date", valid_590991
  var valid_590992 = header.getOrDefault("X-Amz-Credential")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Credential", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Security-Token")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Security-Token", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Algorithm")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Algorithm", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-SignedHeaders", valid_590995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590997: Call_DeleteComputeEnvironment_590986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Batch compute environment.</p> <p>Before you can delete a compute environment, you must set its state to <code>DISABLED</code> with the <a>UpdateComputeEnvironment</a> API operation and disassociate it from any job queues with the <a>UpdateJobQueue</a> API operation.</p>
  ## 
  let valid = call_590997.validator(path, query, header, formData, body)
  let scheme = call_590997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590997.url(scheme.get, call_590997.host, call_590997.base,
                         call_590997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590997, url, valid)

proc call*(call_590998: Call_DeleteComputeEnvironment_590986; body: JsonNode): Recallable =
  ## deleteComputeEnvironment
  ## <p>Deletes an AWS Batch compute environment.</p> <p>Before you can delete a compute environment, you must set its state to <code>DISABLED</code> with the <a>UpdateComputeEnvironment</a> API operation and disassociate it from any job queues with the <a>UpdateJobQueue</a> API operation.</p>
  ##   body: JObject (required)
  var body_590999 = newJObject()
  if body != nil:
    body_590999 = body
  result = call_590998.call(nil, nil, nil, nil, body_590999)

var deleteComputeEnvironment* = Call_DeleteComputeEnvironment_590986(
    name: "deleteComputeEnvironment", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/deletecomputeenvironment",
    validator: validate_DeleteComputeEnvironment_590987, base: "/",
    url: url_DeleteComputeEnvironment_590988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJobQueue_591000 = ref object of OpenApiRestCall_590364
proc url_DeleteJobQueue_591002(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteJobQueue_591001(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes the specified job queue. You must first disable submissions for a queue with the <a>UpdateJobQueue</a> operation. All jobs in the queue are terminated when you delete a job queue.</p> <p>It is not necessary to disassociate compute environments from a queue before submitting a <code>DeleteJobQueue</code> request.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591003 = header.getOrDefault("X-Amz-Signature")
  valid_591003 = validateParameter(valid_591003, JString, required = false,
                                 default = nil)
  if valid_591003 != nil:
    section.add "X-Amz-Signature", valid_591003
  var valid_591004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591004 = validateParameter(valid_591004, JString, required = false,
                                 default = nil)
  if valid_591004 != nil:
    section.add "X-Amz-Content-Sha256", valid_591004
  var valid_591005 = header.getOrDefault("X-Amz-Date")
  valid_591005 = validateParameter(valid_591005, JString, required = false,
                                 default = nil)
  if valid_591005 != nil:
    section.add "X-Amz-Date", valid_591005
  var valid_591006 = header.getOrDefault("X-Amz-Credential")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "X-Amz-Credential", valid_591006
  var valid_591007 = header.getOrDefault("X-Amz-Security-Token")
  valid_591007 = validateParameter(valid_591007, JString, required = false,
                                 default = nil)
  if valid_591007 != nil:
    section.add "X-Amz-Security-Token", valid_591007
  var valid_591008 = header.getOrDefault("X-Amz-Algorithm")
  valid_591008 = validateParameter(valid_591008, JString, required = false,
                                 default = nil)
  if valid_591008 != nil:
    section.add "X-Amz-Algorithm", valid_591008
  var valid_591009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591009 = validateParameter(valid_591009, JString, required = false,
                                 default = nil)
  if valid_591009 != nil:
    section.add "X-Amz-SignedHeaders", valid_591009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591011: Call_DeleteJobQueue_591000; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified job queue. You must first disable submissions for a queue with the <a>UpdateJobQueue</a> operation. All jobs in the queue are terminated when you delete a job queue.</p> <p>It is not necessary to disassociate compute environments from a queue before submitting a <code>DeleteJobQueue</code> request.</p>
  ## 
  let valid = call_591011.validator(path, query, header, formData, body)
  let scheme = call_591011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591011.url(scheme.get, call_591011.host, call_591011.base,
                         call_591011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591011, url, valid)

proc call*(call_591012: Call_DeleteJobQueue_591000; body: JsonNode): Recallable =
  ## deleteJobQueue
  ## <p>Deletes the specified job queue. You must first disable submissions for a queue with the <a>UpdateJobQueue</a> operation. All jobs in the queue are terminated when you delete a job queue.</p> <p>It is not necessary to disassociate compute environments from a queue before submitting a <code>DeleteJobQueue</code> request.</p>
  ##   body: JObject (required)
  var body_591013 = newJObject()
  if body != nil:
    body_591013 = body
  result = call_591012.call(nil, nil, nil, nil, body_591013)

var deleteJobQueue* = Call_DeleteJobQueue_591000(name: "deleteJobQueue",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/deletejobqueue", validator: validate_DeleteJobQueue_591001,
    base: "/", url: url_DeleteJobQueue_591002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterJobDefinition_591014 = ref object of OpenApiRestCall_590364
proc url_DeregisterJobDefinition_591016(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterJobDefinition_591015(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591017 = header.getOrDefault("X-Amz-Signature")
  valid_591017 = validateParameter(valid_591017, JString, required = false,
                                 default = nil)
  if valid_591017 != nil:
    section.add "X-Amz-Signature", valid_591017
  var valid_591018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591018 = validateParameter(valid_591018, JString, required = false,
                                 default = nil)
  if valid_591018 != nil:
    section.add "X-Amz-Content-Sha256", valid_591018
  var valid_591019 = header.getOrDefault("X-Amz-Date")
  valid_591019 = validateParameter(valid_591019, JString, required = false,
                                 default = nil)
  if valid_591019 != nil:
    section.add "X-Amz-Date", valid_591019
  var valid_591020 = header.getOrDefault("X-Amz-Credential")
  valid_591020 = validateParameter(valid_591020, JString, required = false,
                                 default = nil)
  if valid_591020 != nil:
    section.add "X-Amz-Credential", valid_591020
  var valid_591021 = header.getOrDefault("X-Amz-Security-Token")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "X-Amz-Security-Token", valid_591021
  var valid_591022 = header.getOrDefault("X-Amz-Algorithm")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = nil)
  if valid_591022 != nil:
    section.add "X-Amz-Algorithm", valid_591022
  var valid_591023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-SignedHeaders", valid_591023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591025: Call_DeregisterJobDefinition_591014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters an AWS Batch job definition.
  ## 
  let valid = call_591025.validator(path, query, header, formData, body)
  let scheme = call_591025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591025.url(scheme.get, call_591025.host, call_591025.base,
                         call_591025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591025, url, valid)

proc call*(call_591026: Call_DeregisterJobDefinition_591014; body: JsonNode): Recallable =
  ## deregisterJobDefinition
  ## Deregisters an AWS Batch job definition.
  ##   body: JObject (required)
  var body_591027 = newJObject()
  if body != nil:
    body_591027 = body
  result = call_591026.call(nil, nil, nil, nil, body_591027)

var deregisterJobDefinition* = Call_DeregisterJobDefinition_591014(
    name: "deregisterJobDefinition", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/deregisterjobdefinition",
    validator: validate_DeregisterJobDefinition_591015, base: "/",
    url: url_DeregisterJobDefinition_591016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComputeEnvironments_591028 = ref object of OpenApiRestCall_590364
proc url_DescribeComputeEnvironments_591030(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeComputeEnvironments_591029(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes one or more of your compute environments.</p> <p>If you are using an unmanaged compute environment, you can use the <code>DescribeComputeEnvironment</code> operation to determine the <code>ecsClusterArn</code> that you should launch your Amazon ECS container instances into.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_591031 = query.getOrDefault("nextToken")
  valid_591031 = validateParameter(valid_591031, JString, required = false,
                                 default = nil)
  if valid_591031 != nil:
    section.add "nextToken", valid_591031
  var valid_591032 = query.getOrDefault("maxResults")
  valid_591032 = validateParameter(valid_591032, JString, required = false,
                                 default = nil)
  if valid_591032 != nil:
    section.add "maxResults", valid_591032
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591033 = header.getOrDefault("X-Amz-Signature")
  valid_591033 = validateParameter(valid_591033, JString, required = false,
                                 default = nil)
  if valid_591033 != nil:
    section.add "X-Amz-Signature", valid_591033
  var valid_591034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591034 = validateParameter(valid_591034, JString, required = false,
                                 default = nil)
  if valid_591034 != nil:
    section.add "X-Amz-Content-Sha256", valid_591034
  var valid_591035 = header.getOrDefault("X-Amz-Date")
  valid_591035 = validateParameter(valid_591035, JString, required = false,
                                 default = nil)
  if valid_591035 != nil:
    section.add "X-Amz-Date", valid_591035
  var valid_591036 = header.getOrDefault("X-Amz-Credential")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-Credential", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-Security-Token")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Security-Token", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Algorithm")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Algorithm", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-SignedHeaders", valid_591039
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591041: Call_DescribeComputeEnvironments_591028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes one or more of your compute environments.</p> <p>If you are using an unmanaged compute environment, you can use the <code>DescribeComputeEnvironment</code> operation to determine the <code>ecsClusterArn</code> that you should launch your Amazon ECS container instances into.</p>
  ## 
  let valid = call_591041.validator(path, query, header, formData, body)
  let scheme = call_591041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591041.url(scheme.get, call_591041.host, call_591041.base,
                         call_591041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591041, url, valid)

proc call*(call_591042: Call_DescribeComputeEnvironments_591028; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeComputeEnvironments
  ## <p>Describes one or more of your compute environments.</p> <p>If you are using an unmanaged compute environment, you can use the <code>DescribeComputeEnvironment</code> operation to determine the <code>ecsClusterArn</code> that you should launch your Amazon ECS container instances into.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_591043 = newJObject()
  var body_591044 = newJObject()
  add(query_591043, "nextToken", newJString(nextToken))
  if body != nil:
    body_591044 = body
  add(query_591043, "maxResults", newJString(maxResults))
  result = call_591042.call(nil, query_591043, nil, nil, body_591044)

var describeComputeEnvironments* = Call_DescribeComputeEnvironments_591028(
    name: "describeComputeEnvironments", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/describecomputeenvironments",
    validator: validate_DescribeComputeEnvironments_591029, base: "/",
    url: url_DescribeComputeEnvironments_591030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobDefinitions_591046 = ref object of OpenApiRestCall_590364
proc url_DescribeJobDefinitions_591048(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeJobDefinitions_591047(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a list of job definitions. You can specify a <code>status</code> (such as <code>ACTIVE</code>) to only return job definitions that match that status.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_591049 = query.getOrDefault("nextToken")
  valid_591049 = validateParameter(valid_591049, JString, required = false,
                                 default = nil)
  if valid_591049 != nil:
    section.add "nextToken", valid_591049
  var valid_591050 = query.getOrDefault("maxResults")
  valid_591050 = validateParameter(valid_591050, JString, required = false,
                                 default = nil)
  if valid_591050 != nil:
    section.add "maxResults", valid_591050
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591051 = header.getOrDefault("X-Amz-Signature")
  valid_591051 = validateParameter(valid_591051, JString, required = false,
                                 default = nil)
  if valid_591051 != nil:
    section.add "X-Amz-Signature", valid_591051
  var valid_591052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591052 = validateParameter(valid_591052, JString, required = false,
                                 default = nil)
  if valid_591052 != nil:
    section.add "X-Amz-Content-Sha256", valid_591052
  var valid_591053 = header.getOrDefault("X-Amz-Date")
  valid_591053 = validateParameter(valid_591053, JString, required = false,
                                 default = nil)
  if valid_591053 != nil:
    section.add "X-Amz-Date", valid_591053
  var valid_591054 = header.getOrDefault("X-Amz-Credential")
  valid_591054 = validateParameter(valid_591054, JString, required = false,
                                 default = nil)
  if valid_591054 != nil:
    section.add "X-Amz-Credential", valid_591054
  var valid_591055 = header.getOrDefault("X-Amz-Security-Token")
  valid_591055 = validateParameter(valid_591055, JString, required = false,
                                 default = nil)
  if valid_591055 != nil:
    section.add "X-Amz-Security-Token", valid_591055
  var valid_591056 = header.getOrDefault("X-Amz-Algorithm")
  valid_591056 = validateParameter(valid_591056, JString, required = false,
                                 default = nil)
  if valid_591056 != nil:
    section.add "X-Amz-Algorithm", valid_591056
  var valid_591057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591057 = validateParameter(valid_591057, JString, required = false,
                                 default = nil)
  if valid_591057 != nil:
    section.add "X-Amz-SignedHeaders", valid_591057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591059: Call_DescribeJobDefinitions_591046; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a list of job definitions. You can specify a <code>status</code> (such as <code>ACTIVE</code>) to only return job definitions that match that status.
  ## 
  let valid = call_591059.validator(path, query, header, formData, body)
  let scheme = call_591059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591059.url(scheme.get, call_591059.host, call_591059.base,
                         call_591059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591059, url, valid)

proc call*(call_591060: Call_DescribeJobDefinitions_591046; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeJobDefinitions
  ## Describes a list of job definitions. You can specify a <code>status</code> (such as <code>ACTIVE</code>) to only return job definitions that match that status.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_591061 = newJObject()
  var body_591062 = newJObject()
  add(query_591061, "nextToken", newJString(nextToken))
  if body != nil:
    body_591062 = body
  add(query_591061, "maxResults", newJString(maxResults))
  result = call_591060.call(nil, query_591061, nil, nil, body_591062)

var describeJobDefinitions* = Call_DescribeJobDefinitions_591046(
    name: "describeJobDefinitions", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/describejobdefinitions",
    validator: validate_DescribeJobDefinitions_591047, base: "/",
    url: url_DescribeJobDefinitions_591048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobQueues_591063 = ref object of OpenApiRestCall_590364
proc url_DescribeJobQueues_591065(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeJobQueues_591064(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Describes one or more of your job queues.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_591066 = query.getOrDefault("nextToken")
  valid_591066 = validateParameter(valid_591066, JString, required = false,
                                 default = nil)
  if valid_591066 != nil:
    section.add "nextToken", valid_591066
  var valid_591067 = query.getOrDefault("maxResults")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "maxResults", valid_591067
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591068 = header.getOrDefault("X-Amz-Signature")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = nil)
  if valid_591068 != nil:
    section.add "X-Amz-Signature", valid_591068
  var valid_591069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591069 = validateParameter(valid_591069, JString, required = false,
                                 default = nil)
  if valid_591069 != nil:
    section.add "X-Amz-Content-Sha256", valid_591069
  var valid_591070 = header.getOrDefault("X-Amz-Date")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Date", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Credential")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Credential", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-Security-Token")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-Security-Token", valid_591072
  var valid_591073 = header.getOrDefault("X-Amz-Algorithm")
  valid_591073 = validateParameter(valid_591073, JString, required = false,
                                 default = nil)
  if valid_591073 != nil:
    section.add "X-Amz-Algorithm", valid_591073
  var valid_591074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591074 = validateParameter(valid_591074, JString, required = false,
                                 default = nil)
  if valid_591074 != nil:
    section.add "X-Amz-SignedHeaders", valid_591074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591076: Call_DescribeJobQueues_591063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your job queues.
  ## 
  let valid = call_591076.validator(path, query, header, formData, body)
  let scheme = call_591076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591076.url(scheme.get, call_591076.host, call_591076.base,
                         call_591076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591076, url, valid)

proc call*(call_591077: Call_DescribeJobQueues_591063; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeJobQueues
  ## Describes one or more of your job queues.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_591078 = newJObject()
  var body_591079 = newJObject()
  add(query_591078, "nextToken", newJString(nextToken))
  if body != nil:
    body_591079 = body
  add(query_591078, "maxResults", newJString(maxResults))
  result = call_591077.call(nil, query_591078, nil, nil, body_591079)

var describeJobQueues* = Call_DescribeJobQueues_591063(name: "describeJobQueues",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/describejobqueues", validator: validate_DescribeJobQueues_591064,
    base: "/", url: url_DescribeJobQueues_591065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobs_591080 = ref object of OpenApiRestCall_590364
proc url_DescribeJobs_591082(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeJobs_591081(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591083 = header.getOrDefault("X-Amz-Signature")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-Signature", valid_591083
  var valid_591084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591084 = validateParameter(valid_591084, JString, required = false,
                                 default = nil)
  if valid_591084 != nil:
    section.add "X-Amz-Content-Sha256", valid_591084
  var valid_591085 = header.getOrDefault("X-Amz-Date")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-Date", valid_591085
  var valid_591086 = header.getOrDefault("X-Amz-Credential")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Credential", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-Security-Token")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-Security-Token", valid_591087
  var valid_591088 = header.getOrDefault("X-Amz-Algorithm")
  valid_591088 = validateParameter(valid_591088, JString, required = false,
                                 default = nil)
  if valid_591088 != nil:
    section.add "X-Amz-Algorithm", valid_591088
  var valid_591089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591089 = validateParameter(valid_591089, JString, required = false,
                                 default = nil)
  if valid_591089 != nil:
    section.add "X-Amz-SignedHeaders", valid_591089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591091: Call_DescribeJobs_591080; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a list of AWS Batch jobs.
  ## 
  let valid = call_591091.validator(path, query, header, formData, body)
  let scheme = call_591091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591091.url(scheme.get, call_591091.host, call_591091.base,
                         call_591091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591091, url, valid)

proc call*(call_591092: Call_DescribeJobs_591080; body: JsonNode): Recallable =
  ## describeJobs
  ## Describes a list of AWS Batch jobs.
  ##   body: JObject (required)
  var body_591093 = newJObject()
  if body != nil:
    body_591093 = body
  result = call_591092.call(nil, nil, nil, nil, body_591093)

var describeJobs* = Call_DescribeJobs_591080(name: "describeJobs",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/describejobs", validator: validate_DescribeJobs_591081, base: "/",
    url: url_DescribeJobs_591082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_591094 = ref object of OpenApiRestCall_590364
proc url_ListJobs_591096(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobs_591095(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of AWS Batch jobs.</p> <p>You must specify only one of the following:</p> <ul> <li> <p>a job queue ID to return a list of jobs in that job queue</p> </li> <li> <p>a multi-node parallel job ID to return a list of that job's nodes</p> </li> <li> <p>an array job ID to return a list of that job's children</p> </li> </ul> <p>You can filter the results by job status with the <code>jobStatus</code> parameter. If you do not specify a status, only <code>RUNNING</code> jobs are returned.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_591097 = query.getOrDefault("nextToken")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "nextToken", valid_591097
  var valid_591098 = query.getOrDefault("maxResults")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "maxResults", valid_591098
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591099 = header.getOrDefault("X-Amz-Signature")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Signature", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-Content-Sha256", valid_591100
  var valid_591101 = header.getOrDefault("X-Amz-Date")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-Date", valid_591101
  var valid_591102 = header.getOrDefault("X-Amz-Credential")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "X-Amz-Credential", valid_591102
  var valid_591103 = header.getOrDefault("X-Amz-Security-Token")
  valid_591103 = validateParameter(valid_591103, JString, required = false,
                                 default = nil)
  if valid_591103 != nil:
    section.add "X-Amz-Security-Token", valid_591103
  var valid_591104 = header.getOrDefault("X-Amz-Algorithm")
  valid_591104 = validateParameter(valid_591104, JString, required = false,
                                 default = nil)
  if valid_591104 != nil:
    section.add "X-Amz-Algorithm", valid_591104
  var valid_591105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591105 = validateParameter(valid_591105, JString, required = false,
                                 default = nil)
  if valid_591105 != nil:
    section.add "X-Amz-SignedHeaders", valid_591105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591107: Call_ListJobs_591094; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of AWS Batch jobs.</p> <p>You must specify only one of the following:</p> <ul> <li> <p>a job queue ID to return a list of jobs in that job queue</p> </li> <li> <p>a multi-node parallel job ID to return a list of that job's nodes</p> </li> <li> <p>an array job ID to return a list of that job's children</p> </li> </ul> <p>You can filter the results by job status with the <code>jobStatus</code> parameter. If you do not specify a status, only <code>RUNNING</code> jobs are returned.</p>
  ## 
  let valid = call_591107.validator(path, query, header, formData, body)
  let scheme = call_591107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591107.url(scheme.get, call_591107.host, call_591107.base,
                         call_591107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591107, url, valid)

proc call*(call_591108: Call_ListJobs_591094; body: JsonNode; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## listJobs
  ## <p>Returns a list of AWS Batch jobs.</p> <p>You must specify only one of the following:</p> <ul> <li> <p>a job queue ID to return a list of jobs in that job queue</p> </li> <li> <p>a multi-node parallel job ID to return a list of that job's nodes</p> </li> <li> <p>an array job ID to return a list of that job's children</p> </li> </ul> <p>You can filter the results by job status with the <code>jobStatus</code> parameter. If you do not specify a status, only <code>RUNNING</code> jobs are returned.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_591109 = newJObject()
  var body_591110 = newJObject()
  add(query_591109, "nextToken", newJString(nextToken))
  if body != nil:
    body_591110 = body
  add(query_591109, "maxResults", newJString(maxResults))
  result = call_591108.call(nil, query_591109, nil, nil, body_591110)

var listJobs* = Call_ListJobs_591094(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "batch.amazonaws.com",
                                  route: "/v1/listjobs",
                                  validator: validate_ListJobs_591095, base: "/",
                                  url: url_ListJobs_591096,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterJobDefinition_591111 = ref object of OpenApiRestCall_590364
proc url_RegisterJobDefinition_591113(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterJobDefinition_591112(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591114 = header.getOrDefault("X-Amz-Signature")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-Signature", valid_591114
  var valid_591115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Content-Sha256", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-Date")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-Date", valid_591116
  var valid_591117 = header.getOrDefault("X-Amz-Credential")
  valid_591117 = validateParameter(valid_591117, JString, required = false,
                                 default = nil)
  if valid_591117 != nil:
    section.add "X-Amz-Credential", valid_591117
  var valid_591118 = header.getOrDefault("X-Amz-Security-Token")
  valid_591118 = validateParameter(valid_591118, JString, required = false,
                                 default = nil)
  if valid_591118 != nil:
    section.add "X-Amz-Security-Token", valid_591118
  var valid_591119 = header.getOrDefault("X-Amz-Algorithm")
  valid_591119 = validateParameter(valid_591119, JString, required = false,
                                 default = nil)
  if valid_591119 != nil:
    section.add "X-Amz-Algorithm", valid_591119
  var valid_591120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591120 = validateParameter(valid_591120, JString, required = false,
                                 default = nil)
  if valid_591120 != nil:
    section.add "X-Amz-SignedHeaders", valid_591120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591122: Call_RegisterJobDefinition_591111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers an AWS Batch job definition.
  ## 
  let valid = call_591122.validator(path, query, header, formData, body)
  let scheme = call_591122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591122.url(scheme.get, call_591122.host, call_591122.base,
                         call_591122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591122, url, valid)

proc call*(call_591123: Call_RegisterJobDefinition_591111; body: JsonNode): Recallable =
  ## registerJobDefinition
  ## Registers an AWS Batch job definition.
  ##   body: JObject (required)
  var body_591124 = newJObject()
  if body != nil:
    body_591124 = body
  result = call_591123.call(nil, nil, nil, nil, body_591124)

var registerJobDefinition* = Call_RegisterJobDefinition_591111(
    name: "registerJobDefinition", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/registerjobdefinition",
    validator: validate_RegisterJobDefinition_591112, base: "/",
    url: url_RegisterJobDefinition_591113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitJob_591125 = ref object of OpenApiRestCall_590364
proc url_SubmitJob_591127(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SubmitJob_591126(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591128 = header.getOrDefault("X-Amz-Signature")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-Signature", valid_591128
  var valid_591129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Content-Sha256", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Date")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Date", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-Credential")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-Credential", valid_591131
  var valid_591132 = header.getOrDefault("X-Amz-Security-Token")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "X-Amz-Security-Token", valid_591132
  var valid_591133 = header.getOrDefault("X-Amz-Algorithm")
  valid_591133 = validateParameter(valid_591133, JString, required = false,
                                 default = nil)
  if valid_591133 != nil:
    section.add "X-Amz-Algorithm", valid_591133
  var valid_591134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591134 = validateParameter(valid_591134, JString, required = false,
                                 default = nil)
  if valid_591134 != nil:
    section.add "X-Amz-SignedHeaders", valid_591134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591136: Call_SubmitJob_591125; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Submits an AWS Batch job from a job definition. Parameters specified during <a>SubmitJob</a> override parameters defined in the job definition.
  ## 
  let valid = call_591136.validator(path, query, header, formData, body)
  let scheme = call_591136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591136.url(scheme.get, call_591136.host, call_591136.base,
                         call_591136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591136, url, valid)

proc call*(call_591137: Call_SubmitJob_591125; body: JsonNode): Recallable =
  ## submitJob
  ## Submits an AWS Batch job from a job definition. Parameters specified during <a>SubmitJob</a> override parameters defined in the job definition.
  ##   body: JObject (required)
  var body_591138 = newJObject()
  if body != nil:
    body_591138 = body
  result = call_591137.call(nil, nil, nil, nil, body_591138)

var submitJob* = Call_SubmitJob_591125(name: "submitJob", meth: HttpMethod.HttpPost,
                                    host: "batch.amazonaws.com",
                                    route: "/v1/submitjob",
                                    validator: validate_SubmitJob_591126,
                                    base: "/", url: url_SubmitJob_591127,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateJob_591139 = ref object of OpenApiRestCall_590364
proc url_TerminateJob_591141(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TerminateJob_591140(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591142 = header.getOrDefault("X-Amz-Signature")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Signature", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Content-Sha256", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-Date")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-Date", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-Credential")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-Credential", valid_591145
  var valid_591146 = header.getOrDefault("X-Amz-Security-Token")
  valid_591146 = validateParameter(valid_591146, JString, required = false,
                                 default = nil)
  if valid_591146 != nil:
    section.add "X-Amz-Security-Token", valid_591146
  var valid_591147 = header.getOrDefault("X-Amz-Algorithm")
  valid_591147 = validateParameter(valid_591147, JString, required = false,
                                 default = nil)
  if valid_591147 != nil:
    section.add "X-Amz-Algorithm", valid_591147
  var valid_591148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591148 = validateParameter(valid_591148, JString, required = false,
                                 default = nil)
  if valid_591148 != nil:
    section.add "X-Amz-SignedHeaders", valid_591148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591150: Call_TerminateJob_591139; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates a job in a job queue. Jobs that are in the <code>STARTING</code> or <code>RUNNING</code> state are terminated, which causes them to transition to <code>FAILED</code>. Jobs that have not progressed to the <code>STARTING</code> state are cancelled.
  ## 
  let valid = call_591150.validator(path, query, header, formData, body)
  let scheme = call_591150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591150.url(scheme.get, call_591150.host, call_591150.base,
                         call_591150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591150, url, valid)

proc call*(call_591151: Call_TerminateJob_591139; body: JsonNode): Recallable =
  ## terminateJob
  ## Terminates a job in a job queue. Jobs that are in the <code>STARTING</code> or <code>RUNNING</code> state are terminated, which causes them to transition to <code>FAILED</code>. Jobs that have not progressed to the <code>STARTING</code> state are cancelled.
  ##   body: JObject (required)
  var body_591152 = newJObject()
  if body != nil:
    body_591152 = body
  result = call_591151.call(nil, nil, nil, nil, body_591152)

var terminateJob* = Call_TerminateJob_591139(name: "terminateJob",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/terminatejob", validator: validate_TerminateJob_591140, base: "/",
    url: url_TerminateJob_591141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComputeEnvironment_591153 = ref object of OpenApiRestCall_590364
proc url_UpdateComputeEnvironment_591155(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateComputeEnvironment_591154(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591156 = header.getOrDefault("X-Amz-Signature")
  valid_591156 = validateParameter(valid_591156, JString, required = false,
                                 default = nil)
  if valid_591156 != nil:
    section.add "X-Amz-Signature", valid_591156
  var valid_591157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Content-Sha256", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Date")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Date", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-Credential")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-Credential", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-Security-Token")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-Security-Token", valid_591160
  var valid_591161 = header.getOrDefault("X-Amz-Algorithm")
  valid_591161 = validateParameter(valid_591161, JString, required = false,
                                 default = nil)
  if valid_591161 != nil:
    section.add "X-Amz-Algorithm", valid_591161
  var valid_591162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591162 = validateParameter(valid_591162, JString, required = false,
                                 default = nil)
  if valid_591162 != nil:
    section.add "X-Amz-SignedHeaders", valid_591162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591164: Call_UpdateComputeEnvironment_591153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an AWS Batch compute environment.
  ## 
  let valid = call_591164.validator(path, query, header, formData, body)
  let scheme = call_591164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591164.url(scheme.get, call_591164.host, call_591164.base,
                         call_591164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591164, url, valid)

proc call*(call_591165: Call_UpdateComputeEnvironment_591153; body: JsonNode): Recallable =
  ## updateComputeEnvironment
  ## Updates an AWS Batch compute environment.
  ##   body: JObject (required)
  var body_591166 = newJObject()
  if body != nil:
    body_591166 = body
  result = call_591165.call(nil, nil, nil, nil, body_591166)

var updateComputeEnvironment* = Call_UpdateComputeEnvironment_591153(
    name: "updateComputeEnvironment", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/updatecomputeenvironment",
    validator: validate_UpdateComputeEnvironment_591154, base: "/",
    url: url_UpdateComputeEnvironment_591155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobQueue_591167 = ref object of OpenApiRestCall_590364
proc url_UpdateJobQueue_591169(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateJobQueue_591168(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_591170 = header.getOrDefault("X-Amz-Signature")
  valid_591170 = validateParameter(valid_591170, JString, required = false,
                                 default = nil)
  if valid_591170 != nil:
    section.add "X-Amz-Signature", valid_591170
  var valid_591171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-Content-Sha256", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Date")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Date", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Credential")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Credential", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-Security-Token")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Security-Token", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Algorithm")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Algorithm", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-SignedHeaders", valid_591176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591178: Call_UpdateJobQueue_591167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a job queue.
  ## 
  let valid = call_591178.validator(path, query, header, formData, body)
  let scheme = call_591178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591178.url(scheme.get, call_591178.host, call_591178.base,
                         call_591178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591178, url, valid)

proc call*(call_591179: Call_UpdateJobQueue_591167; body: JsonNode): Recallable =
  ## updateJobQueue
  ## Updates a job queue.
  ##   body: JObject (required)
  var body_591180 = newJObject()
  if body != nil:
    body_591180 = body
  result = call_591179.call(nil, nil, nil, nil, body_591180)

var updateJobQueue* = Call_UpdateJobQueue_591167(name: "updateJobQueue",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/updatejobqueue", validator: validate_UpdateJobQueue_591168,
    base: "/", url: url_UpdateJobQueue_591169, schemes: {Scheme.Https, Scheme.Http})
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
