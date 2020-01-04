
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelJob_601727 = ref object of OpenApiRestCall_601389
proc url_CancelJob_601729(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelJob_601728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601841 = header.getOrDefault("X-Amz-Signature")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Signature", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Content-Sha256", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Date")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Date", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Credential")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Credential", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Security-Token")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Security-Token", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Algorithm")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Algorithm", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-SignedHeaders", valid_601847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601871: Call_CancelJob_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels a job in an AWS Batch job queue. Jobs that are in the <code>SUBMITTED</code>, <code>PENDING</code>, or <code>RUNNABLE</code> state are cancelled. Jobs that have progressed to <code>STARTING</code> or <code>RUNNING</code> are not cancelled (but the API operation still succeeds, even if no job is cancelled); these jobs must be terminated with the <a>TerminateJob</a> operation.
  ## 
  let valid = call_601871.validator(path, query, header, formData, body)
  let scheme = call_601871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601871.url(scheme.get, call_601871.host, call_601871.base,
                         call_601871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601871, url, valid)

proc call*(call_601942: Call_CancelJob_601727; body: JsonNode): Recallable =
  ## cancelJob
  ## Cancels a job in an AWS Batch job queue. Jobs that are in the <code>SUBMITTED</code>, <code>PENDING</code>, or <code>RUNNABLE</code> state are cancelled. Jobs that have progressed to <code>STARTING</code> or <code>RUNNING</code> are not cancelled (but the API operation still succeeds, even if no job is cancelled); these jobs must be terminated with the <a>TerminateJob</a> operation.
  ##   body: JObject (required)
  var body_601943 = newJObject()
  if body != nil:
    body_601943 = body
  result = call_601942.call(nil, nil, nil, nil, body_601943)

var cancelJob* = Call_CancelJob_601727(name: "cancelJob", meth: HttpMethod.HttpPost,
                                    host: "batch.amazonaws.com",
                                    route: "/v1/canceljob",
                                    validator: validate_CancelJob_601728,
                                    base: "/", url: url_CancelJob_601729,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComputeEnvironment_601982 = ref object of OpenApiRestCall_601389
proc url_CreateComputeEnvironment_601984(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateComputeEnvironment_601983(path: JsonNode; query: JsonNode;
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
  var valid_601985 = header.getOrDefault("X-Amz-Signature")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "X-Amz-Signature", valid_601985
  var valid_601986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "X-Amz-Content-Sha256", valid_601986
  var valid_601987 = header.getOrDefault("X-Amz-Date")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Date", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-Credential")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Credential", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-Security-Token")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Security-Token", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Algorithm")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Algorithm", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-SignedHeaders", valid_601991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601993: Call_CreateComputeEnvironment_601982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Batch compute environment. You can create <code>MANAGED</code> or <code>UNMANAGED</code> compute environments.</p> <p>In a managed compute environment, AWS Batch manages the capacity and instance types of the compute resources within the environment. This is based on the compute resource specification that you define or the <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html">launch template</a> that you specify when you create the compute environment. You can choose to use Amazon EC2 On-Demand Instances or Spot Instances in your managed compute environment. You can optionally set a maximum price so that Spot Instances only launch when the Spot Instance price is below a specified percentage of the On-Demand price.</p> <note> <p>Multi-node parallel jobs are not supported on Spot Instances.</p> </note> <p>In an unmanaged compute environment, you can manage your own compute resources. This provides more compute resource configuration options, such as using a custom AMI, but you must ensure that your AMI meets the Amazon ECS container instance AMI specification. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container_instance_AMIs.html">Container Instance AMIs</a> in the <i>Amazon Elastic Container Service Developer Guide</i>. After you have created your unmanaged compute environment, you can use the <a>DescribeComputeEnvironments</a> operation to find the Amazon ECS cluster that is associated with it. Then, manually launch your container instances into that Amazon ECS cluster. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html">Launching an Amazon ECS Container Instance</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <note> <p>AWS Batch does not upgrade the AMIs in a compute environment after it is created (for example, when a newer version of the Amazon ECS-optimized AMI is available). You are responsible for the management of the guest operating system (including updates and security patches) and any additional application software or utilities that you install on the compute resources. To use a new AMI for your AWS Batch jobs:</p> <ol> <li> <p>Create a new compute environment with the new AMI.</p> </li> <li> <p>Add the compute environment to an existing job queue.</p> </li> <li> <p>Remove the old compute environment from your job queue.</p> </li> <li> <p>Delete the old compute environment.</p> </li> </ol> </note>
  ## 
  let valid = call_601993.validator(path, query, header, formData, body)
  let scheme = call_601993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601993.url(scheme.get, call_601993.host, call_601993.base,
                         call_601993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601993, url, valid)

proc call*(call_601994: Call_CreateComputeEnvironment_601982; body: JsonNode): Recallable =
  ## createComputeEnvironment
  ## <p>Creates an AWS Batch compute environment. You can create <code>MANAGED</code> or <code>UNMANAGED</code> compute environments.</p> <p>In a managed compute environment, AWS Batch manages the capacity and instance types of the compute resources within the environment. This is based on the compute resource specification that you define or the <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html">launch template</a> that you specify when you create the compute environment. You can choose to use Amazon EC2 On-Demand Instances or Spot Instances in your managed compute environment. You can optionally set a maximum price so that Spot Instances only launch when the Spot Instance price is below a specified percentage of the On-Demand price.</p> <note> <p>Multi-node parallel jobs are not supported on Spot Instances.</p> </note> <p>In an unmanaged compute environment, you can manage your own compute resources. This provides more compute resource configuration options, such as using a custom AMI, but you must ensure that your AMI meets the Amazon ECS container instance AMI specification. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container_instance_AMIs.html">Container Instance AMIs</a> in the <i>Amazon Elastic Container Service Developer Guide</i>. After you have created your unmanaged compute environment, you can use the <a>DescribeComputeEnvironments</a> operation to find the Amazon ECS cluster that is associated with it. Then, manually launch your container instances into that Amazon ECS cluster. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html">Launching an Amazon ECS Container Instance</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <note> <p>AWS Batch does not upgrade the AMIs in a compute environment after it is created (for example, when a newer version of the Amazon ECS-optimized AMI is available). You are responsible for the management of the guest operating system (including updates and security patches) and any additional application software or utilities that you install on the compute resources. To use a new AMI for your AWS Batch jobs:</p> <ol> <li> <p>Create a new compute environment with the new AMI.</p> </li> <li> <p>Add the compute environment to an existing job queue.</p> </li> <li> <p>Remove the old compute environment from your job queue.</p> </li> <li> <p>Delete the old compute environment.</p> </li> </ol> </note>
  ##   body: JObject (required)
  var body_601995 = newJObject()
  if body != nil:
    body_601995 = body
  result = call_601994.call(nil, nil, nil, nil, body_601995)

var createComputeEnvironment* = Call_CreateComputeEnvironment_601982(
    name: "createComputeEnvironment", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/createcomputeenvironment",
    validator: validate_CreateComputeEnvironment_601983, base: "/",
    url: url_CreateComputeEnvironment_601984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJobQueue_601996 = ref object of OpenApiRestCall_601389
proc url_CreateJobQueue_601998(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJobQueue_601997(path: JsonNode; query: JsonNode;
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
  var valid_601999 = header.getOrDefault("X-Amz-Signature")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-Signature", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Content-Sha256", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Date")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Date", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Credential")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Credential", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Security-Token")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Security-Token", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Algorithm")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Algorithm", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-SignedHeaders", valid_602005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602007: Call_CreateJobQueue_601996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Batch job queue. When you create a job queue, you associate one or more compute environments to the queue and assign an order of preference for the compute environments.</p> <p>You also set a priority to the job queue that determines the order in which the AWS Batch scheduler places jobs onto its associated compute environments. For example, if a compute environment is associated with more than one job queue, the job queue with a higher priority is given preference for scheduling jobs to that compute environment.</p>
  ## 
  let valid = call_602007.validator(path, query, header, formData, body)
  let scheme = call_602007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602007.url(scheme.get, call_602007.host, call_602007.base,
                         call_602007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602007, url, valid)

proc call*(call_602008: Call_CreateJobQueue_601996; body: JsonNode): Recallable =
  ## createJobQueue
  ## <p>Creates an AWS Batch job queue. When you create a job queue, you associate one or more compute environments to the queue and assign an order of preference for the compute environments.</p> <p>You also set a priority to the job queue that determines the order in which the AWS Batch scheduler places jobs onto its associated compute environments. For example, if a compute environment is associated with more than one job queue, the job queue with a higher priority is given preference for scheduling jobs to that compute environment.</p>
  ##   body: JObject (required)
  var body_602009 = newJObject()
  if body != nil:
    body_602009 = body
  result = call_602008.call(nil, nil, nil, nil, body_602009)

var createJobQueue* = Call_CreateJobQueue_601996(name: "createJobQueue",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/createjobqueue", validator: validate_CreateJobQueue_601997,
    base: "/", url: url_CreateJobQueue_601998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComputeEnvironment_602010 = ref object of OpenApiRestCall_601389
proc url_DeleteComputeEnvironment_602012(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteComputeEnvironment_602011(path: JsonNode; query: JsonNode;
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
  var valid_602013 = header.getOrDefault("X-Amz-Signature")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Signature", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Content-Sha256", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Date")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Date", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Credential")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Credential", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Security-Token")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Security-Token", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Algorithm")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Algorithm", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-SignedHeaders", valid_602019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602021: Call_DeleteComputeEnvironment_602010; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Batch compute environment.</p> <p>Before you can delete a compute environment, you must set its state to <code>DISABLED</code> with the <a>UpdateComputeEnvironment</a> API operation and disassociate it from any job queues with the <a>UpdateJobQueue</a> API operation.</p>
  ## 
  let valid = call_602021.validator(path, query, header, formData, body)
  let scheme = call_602021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602021.url(scheme.get, call_602021.host, call_602021.base,
                         call_602021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602021, url, valid)

proc call*(call_602022: Call_DeleteComputeEnvironment_602010; body: JsonNode): Recallable =
  ## deleteComputeEnvironment
  ## <p>Deletes an AWS Batch compute environment.</p> <p>Before you can delete a compute environment, you must set its state to <code>DISABLED</code> with the <a>UpdateComputeEnvironment</a> API operation and disassociate it from any job queues with the <a>UpdateJobQueue</a> API operation.</p>
  ##   body: JObject (required)
  var body_602023 = newJObject()
  if body != nil:
    body_602023 = body
  result = call_602022.call(nil, nil, nil, nil, body_602023)

var deleteComputeEnvironment* = Call_DeleteComputeEnvironment_602010(
    name: "deleteComputeEnvironment", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/deletecomputeenvironment",
    validator: validate_DeleteComputeEnvironment_602011, base: "/",
    url: url_DeleteComputeEnvironment_602012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteJobQueue_602024 = ref object of OpenApiRestCall_601389
proc url_DeleteJobQueue_602026(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteJobQueue_602025(path: JsonNode; query: JsonNode;
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
  var valid_602027 = header.getOrDefault("X-Amz-Signature")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Signature", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Content-Sha256", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Date")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Date", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Credential")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Credential", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Security-Token")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Security-Token", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Algorithm")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Algorithm", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-SignedHeaders", valid_602033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602035: Call_DeleteJobQueue_602024; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified job queue. You must first disable submissions for a queue with the <a>UpdateJobQueue</a> operation. All jobs in the queue are terminated when you delete a job queue.</p> <p>It is not necessary to disassociate compute environments from a queue before submitting a <code>DeleteJobQueue</code> request.</p>
  ## 
  let valid = call_602035.validator(path, query, header, formData, body)
  let scheme = call_602035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602035.url(scheme.get, call_602035.host, call_602035.base,
                         call_602035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602035, url, valid)

proc call*(call_602036: Call_DeleteJobQueue_602024; body: JsonNode): Recallable =
  ## deleteJobQueue
  ## <p>Deletes the specified job queue. You must first disable submissions for a queue with the <a>UpdateJobQueue</a> operation. All jobs in the queue are terminated when you delete a job queue.</p> <p>It is not necessary to disassociate compute environments from a queue before submitting a <code>DeleteJobQueue</code> request.</p>
  ##   body: JObject (required)
  var body_602037 = newJObject()
  if body != nil:
    body_602037 = body
  result = call_602036.call(nil, nil, nil, nil, body_602037)

var deleteJobQueue* = Call_DeleteJobQueue_602024(name: "deleteJobQueue",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/deletejobqueue", validator: validate_DeleteJobQueue_602025,
    base: "/", url: url_DeleteJobQueue_602026, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterJobDefinition_602038 = ref object of OpenApiRestCall_601389
proc url_DeregisterJobDefinition_602040(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterJobDefinition_602039(path: JsonNode; query: JsonNode;
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
  var valid_602041 = header.getOrDefault("X-Amz-Signature")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Signature", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Content-Sha256", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Date")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Date", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Credential")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Credential", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Security-Token")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Security-Token", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Algorithm")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Algorithm", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-SignedHeaders", valid_602047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602049: Call_DeregisterJobDefinition_602038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters an AWS Batch job definition.
  ## 
  let valid = call_602049.validator(path, query, header, formData, body)
  let scheme = call_602049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602049.url(scheme.get, call_602049.host, call_602049.base,
                         call_602049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602049, url, valid)

proc call*(call_602050: Call_DeregisterJobDefinition_602038; body: JsonNode): Recallable =
  ## deregisterJobDefinition
  ## Deregisters an AWS Batch job definition.
  ##   body: JObject (required)
  var body_602051 = newJObject()
  if body != nil:
    body_602051 = body
  result = call_602050.call(nil, nil, nil, nil, body_602051)

var deregisterJobDefinition* = Call_DeregisterJobDefinition_602038(
    name: "deregisterJobDefinition", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/deregisterjobdefinition",
    validator: validate_DeregisterJobDefinition_602039, base: "/",
    url: url_DeregisterJobDefinition_602040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComputeEnvironments_602052 = ref object of OpenApiRestCall_601389
proc url_DescribeComputeEnvironments_602054(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComputeEnvironments_602053(path: JsonNode; query: JsonNode;
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
  var valid_602055 = query.getOrDefault("nextToken")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "nextToken", valid_602055
  var valid_602056 = query.getOrDefault("maxResults")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "maxResults", valid_602056
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
  var valid_602057 = header.getOrDefault("X-Amz-Signature")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Signature", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Content-Sha256", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Date")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Date", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Credential")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Credential", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Security-Token")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Security-Token", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Algorithm")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Algorithm", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-SignedHeaders", valid_602063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602065: Call_DescribeComputeEnvironments_602052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes one or more of your compute environments.</p> <p>If you are using an unmanaged compute environment, you can use the <code>DescribeComputeEnvironment</code> operation to determine the <code>ecsClusterArn</code> that you should launch your Amazon ECS container instances into.</p>
  ## 
  let valid = call_602065.validator(path, query, header, formData, body)
  let scheme = call_602065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602065.url(scheme.get, call_602065.host, call_602065.base,
                         call_602065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602065, url, valid)

proc call*(call_602066: Call_DescribeComputeEnvironments_602052; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeComputeEnvironments
  ## <p>Describes one or more of your compute environments.</p> <p>If you are using an unmanaged compute environment, you can use the <code>DescribeComputeEnvironment</code> operation to determine the <code>ecsClusterArn</code> that you should launch your Amazon ECS container instances into.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602067 = newJObject()
  var body_602068 = newJObject()
  add(query_602067, "nextToken", newJString(nextToken))
  if body != nil:
    body_602068 = body
  add(query_602067, "maxResults", newJString(maxResults))
  result = call_602066.call(nil, query_602067, nil, nil, body_602068)

var describeComputeEnvironments* = Call_DescribeComputeEnvironments_602052(
    name: "describeComputeEnvironments", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/describecomputeenvironments",
    validator: validate_DescribeComputeEnvironments_602053, base: "/",
    url: url_DescribeComputeEnvironments_602054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobDefinitions_602070 = ref object of OpenApiRestCall_601389
proc url_DescribeJobDefinitions_602072(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeJobDefinitions_602071(path: JsonNode; query: JsonNode;
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
  var valid_602073 = query.getOrDefault("nextToken")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "nextToken", valid_602073
  var valid_602074 = query.getOrDefault("maxResults")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "maxResults", valid_602074
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
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Algorithm")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Algorithm", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-SignedHeaders", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_DescribeJobDefinitions_602070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a list of job definitions. You can specify a <code>status</code> (such as <code>ACTIVE</code>) to only return job definitions that match that status.
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_DescribeJobDefinitions_602070; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeJobDefinitions
  ## Describes a list of job definitions. You can specify a <code>status</code> (such as <code>ACTIVE</code>) to only return job definitions that match that status.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602085 = newJObject()
  var body_602086 = newJObject()
  add(query_602085, "nextToken", newJString(nextToken))
  if body != nil:
    body_602086 = body
  add(query_602085, "maxResults", newJString(maxResults))
  result = call_602084.call(nil, query_602085, nil, nil, body_602086)

var describeJobDefinitions* = Call_DescribeJobDefinitions_602070(
    name: "describeJobDefinitions", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/describejobdefinitions",
    validator: validate_DescribeJobDefinitions_602071, base: "/",
    url: url_DescribeJobDefinitions_602072, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobQueues_602087 = ref object of OpenApiRestCall_601389
proc url_DescribeJobQueues_602089(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeJobQueues_602088(path: JsonNode; query: JsonNode;
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
  var valid_602090 = query.getOrDefault("nextToken")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "nextToken", valid_602090
  var valid_602091 = query.getOrDefault("maxResults")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "maxResults", valid_602091
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
  var valid_602092 = header.getOrDefault("X-Amz-Signature")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Signature", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Content-Sha256", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Date")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Date", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Credential")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Credential", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Security-Token")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Security-Token", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Algorithm")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Algorithm", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-SignedHeaders", valid_602098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602100: Call_DescribeJobQueues_602087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your job queues.
  ## 
  let valid = call_602100.validator(path, query, header, formData, body)
  let scheme = call_602100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602100.url(scheme.get, call_602100.host, call_602100.base,
                         call_602100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602100, url, valid)

proc call*(call_602101: Call_DescribeJobQueues_602087; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeJobQueues
  ## Describes one or more of your job queues.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602102 = newJObject()
  var body_602103 = newJObject()
  add(query_602102, "nextToken", newJString(nextToken))
  if body != nil:
    body_602103 = body
  add(query_602102, "maxResults", newJString(maxResults))
  result = call_602101.call(nil, query_602102, nil, nil, body_602103)

var describeJobQueues* = Call_DescribeJobQueues_602087(name: "describeJobQueues",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/describejobqueues", validator: validate_DescribeJobQueues_602088,
    base: "/", url: url_DescribeJobQueues_602089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobs_602104 = ref object of OpenApiRestCall_601389
proc url_DescribeJobs_602106(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeJobs_602105(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602107 = header.getOrDefault("X-Amz-Signature")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Signature", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Content-Sha256", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Date")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Date", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Credential")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Credential", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Security-Token")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Security-Token", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Algorithm")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Algorithm", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-SignedHeaders", valid_602113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602115: Call_DescribeJobs_602104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a list of AWS Batch jobs.
  ## 
  let valid = call_602115.validator(path, query, header, formData, body)
  let scheme = call_602115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602115.url(scheme.get, call_602115.host, call_602115.base,
                         call_602115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602115, url, valid)

proc call*(call_602116: Call_DescribeJobs_602104; body: JsonNode): Recallable =
  ## describeJobs
  ## Describes a list of AWS Batch jobs.
  ##   body: JObject (required)
  var body_602117 = newJObject()
  if body != nil:
    body_602117 = body
  result = call_602116.call(nil, nil, nil, nil, body_602117)

var describeJobs* = Call_DescribeJobs_602104(name: "describeJobs",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/describejobs", validator: validate_DescribeJobs_602105, base: "/",
    url: url_DescribeJobs_602106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_602118 = ref object of OpenApiRestCall_601389
proc url_ListJobs_602120(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_602119(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602121 = query.getOrDefault("nextToken")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "nextToken", valid_602121
  var valid_602122 = query.getOrDefault("maxResults")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "maxResults", valid_602122
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
  var valid_602123 = header.getOrDefault("X-Amz-Signature")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Signature", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Content-Sha256", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Date")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Date", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Credential")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Credential", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Security-Token")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Security-Token", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Algorithm")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Algorithm", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-SignedHeaders", valid_602129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602131: Call_ListJobs_602118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of AWS Batch jobs.</p> <p>You must specify only one of the following:</p> <ul> <li> <p>a job queue ID to return a list of jobs in that job queue</p> </li> <li> <p>a multi-node parallel job ID to return a list of that job's nodes</p> </li> <li> <p>an array job ID to return a list of that job's children</p> </li> </ul> <p>You can filter the results by job status with the <code>jobStatus</code> parameter. If you do not specify a status, only <code>RUNNING</code> jobs are returned.</p>
  ## 
  let valid = call_602131.validator(path, query, header, formData, body)
  let scheme = call_602131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602131.url(scheme.get, call_602131.host, call_602131.base,
                         call_602131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602131, url, valid)

proc call*(call_602132: Call_ListJobs_602118; body: JsonNode; nextToken: string = "";
          maxResults: string = ""): Recallable =
  ## listJobs
  ## <p>Returns a list of AWS Batch jobs.</p> <p>You must specify only one of the following:</p> <ul> <li> <p>a job queue ID to return a list of jobs in that job queue</p> </li> <li> <p>a multi-node parallel job ID to return a list of that job's nodes</p> </li> <li> <p>an array job ID to return a list of that job's children</p> </li> </ul> <p>You can filter the results by job status with the <code>jobStatus</code> parameter. If you do not specify a status, only <code>RUNNING</code> jobs are returned.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602133 = newJObject()
  var body_602134 = newJObject()
  add(query_602133, "nextToken", newJString(nextToken))
  if body != nil:
    body_602134 = body
  add(query_602133, "maxResults", newJString(maxResults))
  result = call_602132.call(nil, query_602133, nil, nil, body_602134)

var listJobs* = Call_ListJobs_602118(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "batch.amazonaws.com",
                                  route: "/v1/listjobs",
                                  validator: validate_ListJobs_602119, base: "/",
                                  url: url_ListJobs_602120,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterJobDefinition_602135 = ref object of OpenApiRestCall_601389
proc url_RegisterJobDefinition_602137(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterJobDefinition_602136(path: JsonNode; query: JsonNode;
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
  var valid_602138 = header.getOrDefault("X-Amz-Signature")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Signature", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Content-Sha256", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Date")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Date", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Credential")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Credential", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Security-Token")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Security-Token", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Algorithm")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Algorithm", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-SignedHeaders", valid_602144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602146: Call_RegisterJobDefinition_602135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers an AWS Batch job definition.
  ## 
  let valid = call_602146.validator(path, query, header, formData, body)
  let scheme = call_602146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602146.url(scheme.get, call_602146.host, call_602146.base,
                         call_602146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602146, url, valid)

proc call*(call_602147: Call_RegisterJobDefinition_602135; body: JsonNode): Recallable =
  ## registerJobDefinition
  ## Registers an AWS Batch job definition.
  ##   body: JObject (required)
  var body_602148 = newJObject()
  if body != nil:
    body_602148 = body
  result = call_602147.call(nil, nil, nil, nil, body_602148)

var registerJobDefinition* = Call_RegisterJobDefinition_602135(
    name: "registerJobDefinition", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/registerjobdefinition",
    validator: validate_RegisterJobDefinition_602136, base: "/",
    url: url_RegisterJobDefinition_602137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitJob_602149 = ref object of OpenApiRestCall_601389
proc url_SubmitJob_602151(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SubmitJob_602150(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602152 = header.getOrDefault("X-Amz-Signature")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Signature", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Content-Sha256", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Date")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Date", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Credential")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Credential", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Security-Token")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Security-Token", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Algorithm")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Algorithm", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-SignedHeaders", valid_602158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602160: Call_SubmitJob_602149; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Submits an AWS Batch job from a job definition. Parameters specified during <a>SubmitJob</a> override parameters defined in the job definition.
  ## 
  let valid = call_602160.validator(path, query, header, formData, body)
  let scheme = call_602160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602160.url(scheme.get, call_602160.host, call_602160.base,
                         call_602160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602160, url, valid)

proc call*(call_602161: Call_SubmitJob_602149; body: JsonNode): Recallable =
  ## submitJob
  ## Submits an AWS Batch job from a job definition. Parameters specified during <a>SubmitJob</a> override parameters defined in the job definition.
  ##   body: JObject (required)
  var body_602162 = newJObject()
  if body != nil:
    body_602162 = body
  result = call_602161.call(nil, nil, nil, nil, body_602162)

var submitJob* = Call_SubmitJob_602149(name: "submitJob", meth: HttpMethod.HttpPost,
                                    host: "batch.amazonaws.com",
                                    route: "/v1/submitjob",
                                    validator: validate_SubmitJob_602150,
                                    base: "/", url: url_SubmitJob_602151,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateJob_602163 = ref object of OpenApiRestCall_601389
proc url_TerminateJob_602165(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TerminateJob_602164(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602166 = header.getOrDefault("X-Amz-Signature")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Signature", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Content-Sha256", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Date")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Date", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Credential")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Credential", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Security-Token")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Security-Token", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Algorithm")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Algorithm", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-SignedHeaders", valid_602172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602174: Call_TerminateJob_602163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates a job in a job queue. Jobs that are in the <code>STARTING</code> or <code>RUNNING</code> state are terminated, which causes them to transition to <code>FAILED</code>. Jobs that have not progressed to the <code>STARTING</code> state are cancelled.
  ## 
  let valid = call_602174.validator(path, query, header, formData, body)
  let scheme = call_602174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602174.url(scheme.get, call_602174.host, call_602174.base,
                         call_602174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602174, url, valid)

proc call*(call_602175: Call_TerminateJob_602163; body: JsonNode): Recallable =
  ## terminateJob
  ## Terminates a job in a job queue. Jobs that are in the <code>STARTING</code> or <code>RUNNING</code> state are terminated, which causes them to transition to <code>FAILED</code>. Jobs that have not progressed to the <code>STARTING</code> state are cancelled.
  ##   body: JObject (required)
  var body_602176 = newJObject()
  if body != nil:
    body_602176 = body
  result = call_602175.call(nil, nil, nil, nil, body_602176)

var terminateJob* = Call_TerminateJob_602163(name: "terminateJob",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/terminatejob", validator: validate_TerminateJob_602164, base: "/",
    url: url_TerminateJob_602165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComputeEnvironment_602177 = ref object of OpenApiRestCall_601389
proc url_UpdateComputeEnvironment_602179(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateComputeEnvironment_602178(path: JsonNode; query: JsonNode;
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
  var valid_602180 = header.getOrDefault("X-Amz-Signature")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Signature", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Content-Sha256", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Date")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Date", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Credential")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Credential", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Security-Token")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Security-Token", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Algorithm")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Algorithm", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-SignedHeaders", valid_602186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602188: Call_UpdateComputeEnvironment_602177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an AWS Batch compute environment.
  ## 
  let valid = call_602188.validator(path, query, header, formData, body)
  let scheme = call_602188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602188.url(scheme.get, call_602188.host, call_602188.base,
                         call_602188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602188, url, valid)

proc call*(call_602189: Call_UpdateComputeEnvironment_602177; body: JsonNode): Recallable =
  ## updateComputeEnvironment
  ## Updates an AWS Batch compute environment.
  ##   body: JObject (required)
  var body_602190 = newJObject()
  if body != nil:
    body_602190 = body
  result = call_602189.call(nil, nil, nil, nil, body_602190)

var updateComputeEnvironment* = Call_UpdateComputeEnvironment_602177(
    name: "updateComputeEnvironment", meth: HttpMethod.HttpPost,
    host: "batch.amazonaws.com", route: "/v1/updatecomputeenvironment",
    validator: validate_UpdateComputeEnvironment_602178, base: "/",
    url: url_UpdateComputeEnvironment_602179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJobQueue_602191 = ref object of OpenApiRestCall_601389
proc url_UpdateJobQueue_602193(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateJobQueue_602192(path: JsonNode; query: JsonNode;
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
  var valid_602194 = header.getOrDefault("X-Amz-Signature")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Signature", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Content-Sha256", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Date")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Date", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Credential")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Credential", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Security-Token")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Security-Token", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Algorithm")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Algorithm", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-SignedHeaders", valid_602200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602202: Call_UpdateJobQueue_602191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a job queue.
  ## 
  let valid = call_602202.validator(path, query, header, formData, body)
  let scheme = call_602202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602202.url(scheme.get, call_602202.host, call_602202.base,
                         call_602202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602202, url, valid)

proc call*(call_602203: Call_UpdateJobQueue_602191; body: JsonNode): Recallable =
  ## updateJobQueue
  ## Updates a job queue.
  ##   body: JObject (required)
  var body_602204 = newJObject()
  if body != nil:
    body_602204 = body
  result = call_602203.call(nil, nil, nil, nil, body_602204)

var updateJobQueue* = Call_UpdateJobQueue_602191(name: "updateJobQueue",
    meth: HttpMethod.HttpPost, host: "batch.amazonaws.com",
    route: "/v1/updatejobqueue", validator: validate_UpdateJobQueue_602192,
    base: "/", url: url_UpdateJobQueue_602193, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
