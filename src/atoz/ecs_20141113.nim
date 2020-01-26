
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon EC2 Container Service
## version: 2014-11-13
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Elastic Container Service</fullname> <p>Amazon Elastic Container Service (Amazon ECS) is a highly scalable, fast, container management service that makes it easy to run, stop, and manage Docker containers on a cluster. You can host your cluster on a serverless infrastructure that is managed by Amazon ECS by launching your services or tasks using the Fargate launch type. For more control, you can host your tasks on a cluster of Amazon Elastic Compute Cloud (Amazon EC2) instances that you manage by using the EC2 launch type. For more information about launch types, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html">Amazon ECS Launch Types</a>.</p> <p>Amazon ECS lets you launch and stop container-based applications with simple API calls, allows you to get the state of your cluster from a centralized service, and gives you access to many familiar Amazon EC2 features.</p> <p>You can use Amazon ECS to schedule the placement of containers across your cluster based on your resource needs, isolation policies, and availability requirements. Amazon ECS eliminates the need for you to operate your own cluster management and configuration management systems or worry about scaling your management infrastructure.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ecs/
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

  OpenApiRestCall_604658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_604658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_604658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "ecs.ap-northeast-1.amazonaws.com", "ap-southeast-1": "ecs.ap-southeast-1.amazonaws.com",
                           "us-west-2": "ecs.us-west-2.amazonaws.com",
                           "eu-west-2": "ecs.eu-west-2.amazonaws.com", "ap-northeast-3": "ecs.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "ecs.eu-central-1.amazonaws.com",
                           "us-east-2": "ecs.us-east-2.amazonaws.com",
                           "us-east-1": "ecs.us-east-1.amazonaws.com", "cn-northwest-1": "ecs.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "ecs.ap-south-1.amazonaws.com",
                           "eu-north-1": "ecs.eu-north-1.amazonaws.com", "ap-northeast-2": "ecs.ap-northeast-2.amazonaws.com",
                           "us-west-1": "ecs.us-west-1.amazonaws.com",
                           "us-gov-east-1": "ecs.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "ecs.eu-west-3.amazonaws.com",
                           "cn-north-1": "ecs.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "ecs.sa-east-1.amazonaws.com",
                           "eu-west-1": "ecs.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "ecs.us-gov-west-1.amazonaws.com", "ap-southeast-2": "ecs.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "ecs.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "ecs.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ecs.ap-southeast-1.amazonaws.com",
      "us-west-2": "ecs.us-west-2.amazonaws.com",
      "eu-west-2": "ecs.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ecs.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ecs.eu-central-1.amazonaws.com",
      "us-east-2": "ecs.us-east-2.amazonaws.com",
      "us-east-1": "ecs.us-east-1.amazonaws.com",
      "cn-northwest-1": "ecs.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ecs.ap-south-1.amazonaws.com",
      "eu-north-1": "ecs.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ecs.ap-northeast-2.amazonaws.com",
      "us-west-1": "ecs.us-west-1.amazonaws.com",
      "us-gov-east-1": "ecs.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ecs.eu-west-3.amazonaws.com",
      "cn-north-1": "ecs.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ecs.sa-east-1.amazonaws.com",
      "eu-west-1": "ecs.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ecs.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ecs.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ecs.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ecs"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCapacityProvider_604996 = ref object of OpenApiRestCall_604658
proc url_CreateCapacityProvider_604998(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCapacityProvider_604997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new capacity provider. Capacity providers are associated with an Amazon ECS cluster and are used in capacity provider strategies to facilitate cluster auto scaling.</p> <p>Only capacity providers using an Auto Scaling group can be created. Amazon ECS tasks on AWS Fargate use the <code>FARGATE</code> and <code>FARGATE_SPOT</code> capacity providers which are already created and available to all accounts in Regions supported by AWS Fargate.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605123 = header.getOrDefault("X-Amz-Target")
  valid_605123 = validateParameter(valid_605123, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateCapacityProvider"))
  if valid_605123 != nil:
    section.add "X-Amz-Target", valid_605123
  var valid_605124 = header.getOrDefault("X-Amz-Signature")
  valid_605124 = validateParameter(valid_605124, JString, required = false,
                                 default = nil)
  if valid_605124 != nil:
    section.add "X-Amz-Signature", valid_605124
  var valid_605125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605125 = validateParameter(valid_605125, JString, required = false,
                                 default = nil)
  if valid_605125 != nil:
    section.add "X-Amz-Content-Sha256", valid_605125
  var valid_605126 = header.getOrDefault("X-Amz-Date")
  valid_605126 = validateParameter(valid_605126, JString, required = false,
                                 default = nil)
  if valid_605126 != nil:
    section.add "X-Amz-Date", valid_605126
  var valid_605127 = header.getOrDefault("X-Amz-Credential")
  valid_605127 = validateParameter(valid_605127, JString, required = false,
                                 default = nil)
  if valid_605127 != nil:
    section.add "X-Amz-Credential", valid_605127
  var valid_605128 = header.getOrDefault("X-Amz-Security-Token")
  valid_605128 = validateParameter(valid_605128, JString, required = false,
                                 default = nil)
  if valid_605128 != nil:
    section.add "X-Amz-Security-Token", valid_605128
  var valid_605129 = header.getOrDefault("X-Amz-Algorithm")
  valid_605129 = validateParameter(valid_605129, JString, required = false,
                                 default = nil)
  if valid_605129 != nil:
    section.add "X-Amz-Algorithm", valid_605129
  var valid_605130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605130 = validateParameter(valid_605130, JString, required = false,
                                 default = nil)
  if valid_605130 != nil:
    section.add "X-Amz-SignedHeaders", valid_605130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605154: Call_CreateCapacityProvider_604996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new capacity provider. Capacity providers are associated with an Amazon ECS cluster and are used in capacity provider strategies to facilitate cluster auto scaling.</p> <p>Only capacity providers using an Auto Scaling group can be created. Amazon ECS tasks on AWS Fargate use the <code>FARGATE</code> and <code>FARGATE_SPOT</code> capacity providers which are already created and available to all accounts in Regions supported by AWS Fargate.</p>
  ## 
  let valid = call_605154.validator(path, query, header, formData, body)
  let scheme = call_605154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605154.url(scheme.get, call_605154.host, call_605154.base,
                         call_605154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605154, url, valid)

proc call*(call_605225: Call_CreateCapacityProvider_604996; body: JsonNode): Recallable =
  ## createCapacityProvider
  ## <p>Creates a new capacity provider. Capacity providers are associated with an Amazon ECS cluster and are used in capacity provider strategies to facilitate cluster auto scaling.</p> <p>Only capacity providers using an Auto Scaling group can be created. Amazon ECS tasks on AWS Fargate use the <code>FARGATE</code> and <code>FARGATE_SPOT</code> capacity providers which are already created and available to all accounts in Regions supported by AWS Fargate.</p>
  ##   body: JObject (required)
  var body_605226 = newJObject()
  if body != nil:
    body_605226 = body
  result = call_605225.call(nil, nil, nil, nil, body_605226)

var createCapacityProvider* = Call_CreateCapacityProvider_604996(
    name: "createCapacityProvider", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateCapacityProvider",
    validator: validate_CreateCapacityProvider_604997, base: "/",
    url: url_CreateCapacityProvider_604998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCluster_605265 = ref object of OpenApiRestCall_604658
proc url_CreateCluster_605267(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCluster_605266(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new Amazon ECS cluster. By default, your account receives a <code>default</code> cluster when you launch your first container instance. However, you can create your own cluster with a unique name with the <code>CreateCluster</code> action.</p> <note> <p>When you call the <a>CreateCluster</a> API operation, Amazon ECS attempts to create the Amazon ECS service-linked role for your account so that required resources in other AWS services can be managed on your behalf. However, if the IAM user that makes the call does not have permissions to create the service-linked role, it is not created. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html">Using Service-Linked Roles for Amazon ECS</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605268 = header.getOrDefault("X-Amz-Target")
  valid_605268 = validateParameter(valid_605268, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateCluster"))
  if valid_605268 != nil:
    section.add "X-Amz-Target", valid_605268
  var valid_605269 = header.getOrDefault("X-Amz-Signature")
  valid_605269 = validateParameter(valid_605269, JString, required = false,
                                 default = nil)
  if valid_605269 != nil:
    section.add "X-Amz-Signature", valid_605269
  var valid_605270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605270 = validateParameter(valid_605270, JString, required = false,
                                 default = nil)
  if valid_605270 != nil:
    section.add "X-Amz-Content-Sha256", valid_605270
  var valid_605271 = header.getOrDefault("X-Amz-Date")
  valid_605271 = validateParameter(valid_605271, JString, required = false,
                                 default = nil)
  if valid_605271 != nil:
    section.add "X-Amz-Date", valid_605271
  var valid_605272 = header.getOrDefault("X-Amz-Credential")
  valid_605272 = validateParameter(valid_605272, JString, required = false,
                                 default = nil)
  if valid_605272 != nil:
    section.add "X-Amz-Credential", valid_605272
  var valid_605273 = header.getOrDefault("X-Amz-Security-Token")
  valid_605273 = validateParameter(valid_605273, JString, required = false,
                                 default = nil)
  if valid_605273 != nil:
    section.add "X-Amz-Security-Token", valid_605273
  var valid_605274 = header.getOrDefault("X-Amz-Algorithm")
  valid_605274 = validateParameter(valid_605274, JString, required = false,
                                 default = nil)
  if valid_605274 != nil:
    section.add "X-Amz-Algorithm", valid_605274
  var valid_605275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605275 = validateParameter(valid_605275, JString, required = false,
                                 default = nil)
  if valid_605275 != nil:
    section.add "X-Amz-SignedHeaders", valid_605275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605277: Call_CreateCluster_605265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Amazon ECS cluster. By default, your account receives a <code>default</code> cluster when you launch your first container instance. However, you can create your own cluster with a unique name with the <code>CreateCluster</code> action.</p> <note> <p>When you call the <a>CreateCluster</a> API operation, Amazon ECS attempts to create the Amazon ECS service-linked role for your account so that required resources in other AWS services can be managed on your behalf. However, if the IAM user that makes the call does not have permissions to create the service-linked role, it is not created. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html">Using Service-Linked Roles for Amazon ECS</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_605277.validator(path, query, header, formData, body)
  let scheme = call_605277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605277.url(scheme.get, call_605277.host, call_605277.base,
                         call_605277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605277, url, valid)

proc call*(call_605278: Call_CreateCluster_605265; body: JsonNode): Recallable =
  ## createCluster
  ## <p>Creates a new Amazon ECS cluster. By default, your account receives a <code>default</code> cluster when you launch your first container instance. However, you can create your own cluster with a unique name with the <code>CreateCluster</code> action.</p> <note> <p>When you call the <a>CreateCluster</a> API operation, Amazon ECS attempts to create the Amazon ECS service-linked role for your account so that required resources in other AWS services can be managed on your behalf. However, if the IAM user that makes the call does not have permissions to create the service-linked role, it is not created. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html">Using Service-Linked Roles for Amazon ECS</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_605279 = newJObject()
  if body != nil:
    body_605279 = body
  result = call_605278.call(nil, nil, nil, nil, body_605279)

var createCluster* = Call_CreateCluster_605265(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateCluster",
    validator: validate_CreateCluster_605266, base: "/", url: url_CreateCluster_605267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateService_605280 = ref object of OpenApiRestCall_604658
proc url_CreateService_605282(protocol: Scheme; host: string; base: string;
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

proc validate_CreateService_605281(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Runs and maintains a desired number of tasks from a specified task definition. If the number of tasks running in a service drops below the <code>desiredCount</code>, Amazon ECS runs another copy of the task in the specified cluster. To update an existing service, see <a>UpdateService</a>.</p> <p>In addition to maintaining the desired count of tasks in your service, you can optionally run your service behind one or more load balancers. The load balancers distribute traffic across the tasks that are associated with the service. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html">Service Load Balancing</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and the container instance that they're hosted on is reported as healthy by the load balancer.</p> <p>There are two service scheduler strategies available:</p> <ul> <li> <p> <code>REPLICA</code> - The replica scheduling strategy places and maintains the desired number of tasks across your cluster. By default, the service scheduler spreads tasks across Availability Zones. You can use task placement strategies and constraints to customize task placement decisions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> <li> <p> <code>DAEMON</code> - The daemon scheduling strategy deploys exactly one task on each active container instance that meets all of the task placement constraints that you specify in your cluster. When using this strategy, you don't need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> </ul> <p>You can optionally specify a deployment configuration for your service. The deployment is triggered by changing properties, such as the task definition or the desired count of a service, with an <a>UpdateService</a> operation. The default value for a replica service for <code>minimumHealthyPercent</code> is 100%. The default value for a daemon service for <code>minimumHealthyPercent</code> is 0%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the minimum healthy percent represents a lower limit on the number of tasks in a service that must remain in the <code>RUNNING</code> state during a deployment, as a percentage of the desired number of tasks (rounded up to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to deploy without using additional cluster capacity. For example, if your service has a desired number of four tasks and a minimum healthy percent of 50%, the scheduler might stop two existing tasks to free up cluster capacity before starting two new tasks. Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and they're reported as healthy by the load balancer. The default value for minimum healthy percent is 100%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the <b>maximum percent</b> parameter represents an upper limit on the number of tasks in a service that are allowed in the <code>RUNNING</code> or <code>PENDING</code> state during a deployment, as a percentage of the desired number of tasks (rounded down to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to define the deployment batch size. For example, if your service has a desired number of four tasks and a maximum percent value of 200%, the scheduler may start four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available). The default value for maximum percent is 200%.</p> <p>If a service is using either the <code>CODE_DEPLOY</code> or <code>EXTERNAL</code> deployment controller types and tasks that use the EC2 launch type, the <b>minimum healthy percent</b> and <b>maximum percent</b> values are used only to define the lower and upper limit on the number of the tasks in the service that remain in the <code>RUNNING</code> state while the container instances are in the <code>DRAINING</code> state. If the tasks in the service use the Fargate launch type, the minimum healthy percent and maximum percent values aren't used, although they're currently visible when describing your service.</p> <p>When creating a service that uses the <code>EXTERNAL</code> deployment controller, you can specify only parameters that aren't controlled at the task set level. The only required parameter is the service name. You control your services using the <a>CreateTaskSet</a> operation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster using the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy) with the <code>placementStrategy</code> parameter):</p> <ul> <li> <p>Sort the valid container instances, giving priority to instances that have the fewest number of running tasks for this service in their respective Availability Zone. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605283 = header.getOrDefault("X-Amz-Target")
  valid_605283 = validateParameter(valid_605283, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateService"))
  if valid_605283 != nil:
    section.add "X-Amz-Target", valid_605283
  var valid_605284 = header.getOrDefault("X-Amz-Signature")
  valid_605284 = validateParameter(valid_605284, JString, required = false,
                                 default = nil)
  if valid_605284 != nil:
    section.add "X-Amz-Signature", valid_605284
  var valid_605285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605285 = validateParameter(valid_605285, JString, required = false,
                                 default = nil)
  if valid_605285 != nil:
    section.add "X-Amz-Content-Sha256", valid_605285
  var valid_605286 = header.getOrDefault("X-Amz-Date")
  valid_605286 = validateParameter(valid_605286, JString, required = false,
                                 default = nil)
  if valid_605286 != nil:
    section.add "X-Amz-Date", valid_605286
  var valid_605287 = header.getOrDefault("X-Amz-Credential")
  valid_605287 = validateParameter(valid_605287, JString, required = false,
                                 default = nil)
  if valid_605287 != nil:
    section.add "X-Amz-Credential", valid_605287
  var valid_605288 = header.getOrDefault("X-Amz-Security-Token")
  valid_605288 = validateParameter(valid_605288, JString, required = false,
                                 default = nil)
  if valid_605288 != nil:
    section.add "X-Amz-Security-Token", valid_605288
  var valid_605289 = header.getOrDefault("X-Amz-Algorithm")
  valid_605289 = validateParameter(valid_605289, JString, required = false,
                                 default = nil)
  if valid_605289 != nil:
    section.add "X-Amz-Algorithm", valid_605289
  var valid_605290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605290 = validateParameter(valid_605290, JString, required = false,
                                 default = nil)
  if valid_605290 != nil:
    section.add "X-Amz-SignedHeaders", valid_605290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605292: Call_CreateService_605280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs and maintains a desired number of tasks from a specified task definition. If the number of tasks running in a service drops below the <code>desiredCount</code>, Amazon ECS runs another copy of the task in the specified cluster. To update an existing service, see <a>UpdateService</a>.</p> <p>In addition to maintaining the desired count of tasks in your service, you can optionally run your service behind one or more load balancers. The load balancers distribute traffic across the tasks that are associated with the service. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html">Service Load Balancing</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and the container instance that they're hosted on is reported as healthy by the load balancer.</p> <p>There are two service scheduler strategies available:</p> <ul> <li> <p> <code>REPLICA</code> - The replica scheduling strategy places and maintains the desired number of tasks across your cluster. By default, the service scheduler spreads tasks across Availability Zones. You can use task placement strategies and constraints to customize task placement decisions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> <li> <p> <code>DAEMON</code> - The daemon scheduling strategy deploys exactly one task on each active container instance that meets all of the task placement constraints that you specify in your cluster. When using this strategy, you don't need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> </ul> <p>You can optionally specify a deployment configuration for your service. The deployment is triggered by changing properties, such as the task definition or the desired count of a service, with an <a>UpdateService</a> operation. The default value for a replica service for <code>minimumHealthyPercent</code> is 100%. The default value for a daemon service for <code>minimumHealthyPercent</code> is 0%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the minimum healthy percent represents a lower limit on the number of tasks in a service that must remain in the <code>RUNNING</code> state during a deployment, as a percentage of the desired number of tasks (rounded up to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to deploy without using additional cluster capacity. For example, if your service has a desired number of four tasks and a minimum healthy percent of 50%, the scheduler might stop two existing tasks to free up cluster capacity before starting two new tasks. Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and they're reported as healthy by the load balancer. The default value for minimum healthy percent is 100%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the <b>maximum percent</b> parameter represents an upper limit on the number of tasks in a service that are allowed in the <code>RUNNING</code> or <code>PENDING</code> state during a deployment, as a percentage of the desired number of tasks (rounded down to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to define the deployment batch size. For example, if your service has a desired number of four tasks and a maximum percent value of 200%, the scheduler may start four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available). The default value for maximum percent is 200%.</p> <p>If a service is using either the <code>CODE_DEPLOY</code> or <code>EXTERNAL</code> deployment controller types and tasks that use the EC2 launch type, the <b>minimum healthy percent</b> and <b>maximum percent</b> values are used only to define the lower and upper limit on the number of the tasks in the service that remain in the <code>RUNNING</code> state while the container instances are in the <code>DRAINING</code> state. If the tasks in the service use the Fargate launch type, the minimum healthy percent and maximum percent values aren't used, although they're currently visible when describing your service.</p> <p>When creating a service that uses the <code>EXTERNAL</code> deployment controller, you can specify only parameters that aren't controlled at the task set level. The only required parameter is the service name. You control your services using the <a>CreateTaskSet</a> operation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster using the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy) with the <code>placementStrategy</code> parameter):</p> <ul> <li> <p>Sort the valid container instances, giving priority to instances that have the fewest number of running tasks for this service in their respective Availability Zone. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul>
  ## 
  let valid = call_605292.validator(path, query, header, formData, body)
  let scheme = call_605292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605292.url(scheme.get, call_605292.host, call_605292.base,
                         call_605292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605292, url, valid)

proc call*(call_605293: Call_CreateService_605280; body: JsonNode): Recallable =
  ## createService
  ## <p>Runs and maintains a desired number of tasks from a specified task definition. If the number of tasks running in a service drops below the <code>desiredCount</code>, Amazon ECS runs another copy of the task in the specified cluster. To update an existing service, see <a>UpdateService</a>.</p> <p>In addition to maintaining the desired count of tasks in your service, you can optionally run your service behind one or more load balancers. The load balancers distribute traffic across the tasks that are associated with the service. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html">Service Load Balancing</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and the container instance that they're hosted on is reported as healthy by the load balancer.</p> <p>There are two service scheduler strategies available:</p> <ul> <li> <p> <code>REPLICA</code> - The replica scheduling strategy places and maintains the desired number of tasks across your cluster. By default, the service scheduler spreads tasks across Availability Zones. You can use task placement strategies and constraints to customize task placement decisions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> <li> <p> <code>DAEMON</code> - The daemon scheduling strategy deploys exactly one task on each active container instance that meets all of the task placement constraints that you specify in your cluster. When using this strategy, you don't need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> </ul> <p>You can optionally specify a deployment configuration for your service. The deployment is triggered by changing properties, such as the task definition or the desired count of a service, with an <a>UpdateService</a> operation. The default value for a replica service for <code>minimumHealthyPercent</code> is 100%. The default value for a daemon service for <code>minimumHealthyPercent</code> is 0%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the minimum healthy percent represents a lower limit on the number of tasks in a service that must remain in the <code>RUNNING</code> state during a deployment, as a percentage of the desired number of tasks (rounded up to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to deploy without using additional cluster capacity. For example, if your service has a desired number of four tasks and a minimum healthy percent of 50%, the scheduler might stop two existing tasks to free up cluster capacity before starting two new tasks. Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and they're reported as healthy by the load balancer. The default value for minimum healthy percent is 100%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the <b>maximum percent</b> parameter represents an upper limit on the number of tasks in a service that are allowed in the <code>RUNNING</code> or <code>PENDING</code> state during a deployment, as a percentage of the desired number of tasks (rounded down to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to define the deployment batch size. For example, if your service has a desired number of four tasks and a maximum percent value of 200%, the scheduler may start four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available). The default value for maximum percent is 200%.</p> <p>If a service is using either the <code>CODE_DEPLOY</code> or <code>EXTERNAL</code> deployment controller types and tasks that use the EC2 launch type, the <b>minimum healthy percent</b> and <b>maximum percent</b> values are used only to define the lower and upper limit on the number of the tasks in the service that remain in the <code>RUNNING</code> state while the container instances are in the <code>DRAINING</code> state. If the tasks in the service use the Fargate launch type, the minimum healthy percent and maximum percent values aren't used, although they're currently visible when describing your service.</p> <p>When creating a service that uses the <code>EXTERNAL</code> deployment controller, you can specify only parameters that aren't controlled at the task set level. The only required parameter is the service name. You control your services using the <a>CreateTaskSet</a> operation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster using the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy) with the <code>placementStrategy</code> parameter):</p> <ul> <li> <p>Sort the valid container instances, giving priority to instances that have the fewest number of running tasks for this service in their respective Availability Zone. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_605294 = newJObject()
  if body != nil:
    body_605294 = body
  result = call_605293.call(nil, nil, nil, nil, body_605294)

var createService* = Call_CreateService_605280(name: "createService",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateService",
    validator: validate_CreateService_605281, base: "/", url: url_CreateService_605282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTaskSet_605295 = ref object of OpenApiRestCall_604658
proc url_CreateTaskSet_605297(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTaskSet_605296(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a task set in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605298 = header.getOrDefault("X-Amz-Target")
  valid_605298 = validateParameter(valid_605298, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateTaskSet"))
  if valid_605298 != nil:
    section.add "X-Amz-Target", valid_605298
  var valid_605299 = header.getOrDefault("X-Amz-Signature")
  valid_605299 = validateParameter(valid_605299, JString, required = false,
                                 default = nil)
  if valid_605299 != nil:
    section.add "X-Amz-Signature", valid_605299
  var valid_605300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605300 = validateParameter(valid_605300, JString, required = false,
                                 default = nil)
  if valid_605300 != nil:
    section.add "X-Amz-Content-Sha256", valid_605300
  var valid_605301 = header.getOrDefault("X-Amz-Date")
  valid_605301 = validateParameter(valid_605301, JString, required = false,
                                 default = nil)
  if valid_605301 != nil:
    section.add "X-Amz-Date", valid_605301
  var valid_605302 = header.getOrDefault("X-Amz-Credential")
  valid_605302 = validateParameter(valid_605302, JString, required = false,
                                 default = nil)
  if valid_605302 != nil:
    section.add "X-Amz-Credential", valid_605302
  var valid_605303 = header.getOrDefault("X-Amz-Security-Token")
  valid_605303 = validateParameter(valid_605303, JString, required = false,
                                 default = nil)
  if valid_605303 != nil:
    section.add "X-Amz-Security-Token", valid_605303
  var valid_605304 = header.getOrDefault("X-Amz-Algorithm")
  valid_605304 = validateParameter(valid_605304, JString, required = false,
                                 default = nil)
  if valid_605304 != nil:
    section.add "X-Amz-Algorithm", valid_605304
  var valid_605305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605305 = validateParameter(valid_605305, JString, required = false,
                                 default = nil)
  if valid_605305 != nil:
    section.add "X-Amz-SignedHeaders", valid_605305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605307: Call_CreateTaskSet_605295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a task set in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_605307.validator(path, query, header, formData, body)
  let scheme = call_605307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605307.url(scheme.get, call_605307.host, call_605307.base,
                         call_605307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605307, url, valid)

proc call*(call_605308: Call_CreateTaskSet_605295; body: JsonNode): Recallable =
  ## createTaskSet
  ## Create a task set in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_605309 = newJObject()
  if body != nil:
    body_605309 = body
  result = call_605308.call(nil, nil, nil, nil, body_605309)

var createTaskSet* = Call_CreateTaskSet_605295(name: "createTaskSet",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateTaskSet",
    validator: validate_CreateTaskSet_605296, base: "/", url: url_CreateTaskSet_605297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccountSetting_605310 = ref object of OpenApiRestCall_604658
proc url_DeleteAccountSetting_605312(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAccountSetting_605311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables an account setting for a specified IAM user, IAM role, or the root user for an account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605313 = header.getOrDefault("X-Amz-Target")
  valid_605313 = validateParameter(valid_605313, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteAccountSetting"))
  if valid_605313 != nil:
    section.add "X-Amz-Target", valid_605313
  var valid_605314 = header.getOrDefault("X-Amz-Signature")
  valid_605314 = validateParameter(valid_605314, JString, required = false,
                                 default = nil)
  if valid_605314 != nil:
    section.add "X-Amz-Signature", valid_605314
  var valid_605315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605315 = validateParameter(valid_605315, JString, required = false,
                                 default = nil)
  if valid_605315 != nil:
    section.add "X-Amz-Content-Sha256", valid_605315
  var valid_605316 = header.getOrDefault("X-Amz-Date")
  valid_605316 = validateParameter(valid_605316, JString, required = false,
                                 default = nil)
  if valid_605316 != nil:
    section.add "X-Amz-Date", valid_605316
  var valid_605317 = header.getOrDefault("X-Amz-Credential")
  valid_605317 = validateParameter(valid_605317, JString, required = false,
                                 default = nil)
  if valid_605317 != nil:
    section.add "X-Amz-Credential", valid_605317
  var valid_605318 = header.getOrDefault("X-Amz-Security-Token")
  valid_605318 = validateParameter(valid_605318, JString, required = false,
                                 default = nil)
  if valid_605318 != nil:
    section.add "X-Amz-Security-Token", valid_605318
  var valid_605319 = header.getOrDefault("X-Amz-Algorithm")
  valid_605319 = validateParameter(valid_605319, JString, required = false,
                                 default = nil)
  if valid_605319 != nil:
    section.add "X-Amz-Algorithm", valid_605319
  var valid_605320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605320 = validateParameter(valid_605320, JString, required = false,
                                 default = nil)
  if valid_605320 != nil:
    section.add "X-Amz-SignedHeaders", valid_605320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605322: Call_DeleteAccountSetting_605310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables an account setting for a specified IAM user, IAM role, or the root user for an account.
  ## 
  let valid = call_605322.validator(path, query, header, formData, body)
  let scheme = call_605322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605322.url(scheme.get, call_605322.host, call_605322.base,
                         call_605322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605322, url, valid)

proc call*(call_605323: Call_DeleteAccountSetting_605310; body: JsonNode): Recallable =
  ## deleteAccountSetting
  ## Disables an account setting for a specified IAM user, IAM role, or the root user for an account.
  ##   body: JObject (required)
  var body_605324 = newJObject()
  if body != nil:
    body_605324 = body
  result = call_605323.call(nil, nil, nil, nil, body_605324)

var deleteAccountSetting* = Call_DeleteAccountSetting_605310(
    name: "deleteAccountSetting", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteAccountSetting",
    validator: validate_DeleteAccountSetting_605311, base: "/",
    url: url_DeleteAccountSetting_605312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAttributes_605325 = ref object of OpenApiRestCall_604658
proc url_DeleteAttributes_605327(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAttributes_605326(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes one or more custom attributes from an Amazon ECS resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605328 = header.getOrDefault("X-Amz-Target")
  valid_605328 = validateParameter(valid_605328, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteAttributes"))
  if valid_605328 != nil:
    section.add "X-Amz-Target", valid_605328
  var valid_605329 = header.getOrDefault("X-Amz-Signature")
  valid_605329 = validateParameter(valid_605329, JString, required = false,
                                 default = nil)
  if valid_605329 != nil:
    section.add "X-Amz-Signature", valid_605329
  var valid_605330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605330 = validateParameter(valid_605330, JString, required = false,
                                 default = nil)
  if valid_605330 != nil:
    section.add "X-Amz-Content-Sha256", valid_605330
  var valid_605331 = header.getOrDefault("X-Amz-Date")
  valid_605331 = validateParameter(valid_605331, JString, required = false,
                                 default = nil)
  if valid_605331 != nil:
    section.add "X-Amz-Date", valid_605331
  var valid_605332 = header.getOrDefault("X-Amz-Credential")
  valid_605332 = validateParameter(valid_605332, JString, required = false,
                                 default = nil)
  if valid_605332 != nil:
    section.add "X-Amz-Credential", valid_605332
  var valid_605333 = header.getOrDefault("X-Amz-Security-Token")
  valid_605333 = validateParameter(valid_605333, JString, required = false,
                                 default = nil)
  if valid_605333 != nil:
    section.add "X-Amz-Security-Token", valid_605333
  var valid_605334 = header.getOrDefault("X-Amz-Algorithm")
  valid_605334 = validateParameter(valid_605334, JString, required = false,
                                 default = nil)
  if valid_605334 != nil:
    section.add "X-Amz-Algorithm", valid_605334
  var valid_605335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605335 = validateParameter(valid_605335, JString, required = false,
                                 default = nil)
  if valid_605335 != nil:
    section.add "X-Amz-SignedHeaders", valid_605335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605337: Call_DeleteAttributes_605325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more custom attributes from an Amazon ECS resource.
  ## 
  let valid = call_605337.validator(path, query, header, formData, body)
  let scheme = call_605337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605337.url(scheme.get, call_605337.host, call_605337.base,
                         call_605337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605337, url, valid)

proc call*(call_605338: Call_DeleteAttributes_605325; body: JsonNode): Recallable =
  ## deleteAttributes
  ## Deletes one or more custom attributes from an Amazon ECS resource.
  ##   body: JObject (required)
  var body_605339 = newJObject()
  if body != nil:
    body_605339 = body
  result = call_605338.call(nil, nil, nil, nil, body_605339)

var deleteAttributes* = Call_DeleteAttributes_605325(name: "deleteAttributes",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteAttributes",
    validator: validate_DeleteAttributes_605326, base: "/",
    url: url_DeleteAttributes_605327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_605340 = ref object of OpenApiRestCall_604658
proc url_DeleteCluster_605342(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCluster_605341(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified cluster. The cluster will transition to the <code>INACTIVE</code> state. Clusters with an <code>INACTIVE</code> status may remain discoverable in your account for a period of time. However, this behavior is subject to change in the future, so you should not rely on <code>INACTIVE</code> clusters persisting.</p> <p>You must deregister all container instances from this cluster before you may delete it. You can list the container instances in a cluster with <a>ListContainerInstances</a> and deregister them with <a>DeregisterContainerInstance</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605343 = header.getOrDefault("X-Amz-Target")
  valid_605343 = validateParameter(valid_605343, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteCluster"))
  if valid_605343 != nil:
    section.add "X-Amz-Target", valid_605343
  var valid_605344 = header.getOrDefault("X-Amz-Signature")
  valid_605344 = validateParameter(valid_605344, JString, required = false,
                                 default = nil)
  if valid_605344 != nil:
    section.add "X-Amz-Signature", valid_605344
  var valid_605345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605345 = validateParameter(valid_605345, JString, required = false,
                                 default = nil)
  if valid_605345 != nil:
    section.add "X-Amz-Content-Sha256", valid_605345
  var valid_605346 = header.getOrDefault("X-Amz-Date")
  valid_605346 = validateParameter(valid_605346, JString, required = false,
                                 default = nil)
  if valid_605346 != nil:
    section.add "X-Amz-Date", valid_605346
  var valid_605347 = header.getOrDefault("X-Amz-Credential")
  valid_605347 = validateParameter(valid_605347, JString, required = false,
                                 default = nil)
  if valid_605347 != nil:
    section.add "X-Amz-Credential", valid_605347
  var valid_605348 = header.getOrDefault("X-Amz-Security-Token")
  valid_605348 = validateParameter(valid_605348, JString, required = false,
                                 default = nil)
  if valid_605348 != nil:
    section.add "X-Amz-Security-Token", valid_605348
  var valid_605349 = header.getOrDefault("X-Amz-Algorithm")
  valid_605349 = validateParameter(valid_605349, JString, required = false,
                                 default = nil)
  if valid_605349 != nil:
    section.add "X-Amz-Algorithm", valid_605349
  var valid_605350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605350 = validateParameter(valid_605350, JString, required = false,
                                 default = nil)
  if valid_605350 != nil:
    section.add "X-Amz-SignedHeaders", valid_605350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605352: Call_DeleteCluster_605340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified cluster. The cluster will transition to the <code>INACTIVE</code> state. Clusters with an <code>INACTIVE</code> status may remain discoverable in your account for a period of time. However, this behavior is subject to change in the future, so you should not rely on <code>INACTIVE</code> clusters persisting.</p> <p>You must deregister all container instances from this cluster before you may delete it. You can list the container instances in a cluster with <a>ListContainerInstances</a> and deregister them with <a>DeregisterContainerInstance</a>.</p>
  ## 
  let valid = call_605352.validator(path, query, header, formData, body)
  let scheme = call_605352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605352.url(scheme.get, call_605352.host, call_605352.base,
                         call_605352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605352, url, valid)

proc call*(call_605353: Call_DeleteCluster_605340; body: JsonNode): Recallable =
  ## deleteCluster
  ## <p>Deletes the specified cluster. The cluster will transition to the <code>INACTIVE</code> state. Clusters with an <code>INACTIVE</code> status may remain discoverable in your account for a period of time. However, this behavior is subject to change in the future, so you should not rely on <code>INACTIVE</code> clusters persisting.</p> <p>You must deregister all container instances from this cluster before you may delete it. You can list the container instances in a cluster with <a>ListContainerInstances</a> and deregister them with <a>DeregisterContainerInstance</a>.</p>
  ##   body: JObject (required)
  var body_605354 = newJObject()
  if body != nil:
    body_605354 = body
  result = call_605353.call(nil, nil, nil, nil, body_605354)

var deleteCluster* = Call_DeleteCluster_605340(name: "deleteCluster",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteCluster",
    validator: validate_DeleteCluster_605341, base: "/", url: url_DeleteCluster_605342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteService_605355 = ref object of OpenApiRestCall_604658
proc url_DeleteService_605357(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteService_605356(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a specified service within a cluster. You can delete a service if you have no running tasks in it and the desired task count is zero. If the service is actively maintaining tasks, you cannot delete it, and you must update the service to a desired task count of zero. For more information, see <a>UpdateService</a>.</p> <note> <p>When you delete a service, if there are still running tasks that require cleanup, the service status moves from <code>ACTIVE</code> to <code>DRAINING</code>, and the service is no longer visible in the console or in the <a>ListServices</a> API operation. After all tasks have transitioned to either <code>STOPPING</code> or <code>STOPPED</code> status, the service status moves from <code>DRAINING</code> to <code>INACTIVE</code>. Services in the <code>DRAINING</code> or <code>INACTIVE</code> status can still be viewed with the <a>DescribeServices</a> API operation. However, in the future, <code>INACTIVE</code> services may be cleaned up and purged from Amazon ECS record keeping, and <a>DescribeServices</a> calls on those services return a <code>ServiceNotFoundException</code> error.</p> </note> <important> <p>If you attempt to create a new service with the same name as an existing service in either <code>ACTIVE</code> or <code>DRAINING</code> status, you receive an error.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605358 = header.getOrDefault("X-Amz-Target")
  valid_605358 = validateParameter(valid_605358, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteService"))
  if valid_605358 != nil:
    section.add "X-Amz-Target", valid_605358
  var valid_605359 = header.getOrDefault("X-Amz-Signature")
  valid_605359 = validateParameter(valid_605359, JString, required = false,
                                 default = nil)
  if valid_605359 != nil:
    section.add "X-Amz-Signature", valid_605359
  var valid_605360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605360 = validateParameter(valid_605360, JString, required = false,
                                 default = nil)
  if valid_605360 != nil:
    section.add "X-Amz-Content-Sha256", valid_605360
  var valid_605361 = header.getOrDefault("X-Amz-Date")
  valid_605361 = validateParameter(valid_605361, JString, required = false,
                                 default = nil)
  if valid_605361 != nil:
    section.add "X-Amz-Date", valid_605361
  var valid_605362 = header.getOrDefault("X-Amz-Credential")
  valid_605362 = validateParameter(valid_605362, JString, required = false,
                                 default = nil)
  if valid_605362 != nil:
    section.add "X-Amz-Credential", valid_605362
  var valid_605363 = header.getOrDefault("X-Amz-Security-Token")
  valid_605363 = validateParameter(valid_605363, JString, required = false,
                                 default = nil)
  if valid_605363 != nil:
    section.add "X-Amz-Security-Token", valid_605363
  var valid_605364 = header.getOrDefault("X-Amz-Algorithm")
  valid_605364 = validateParameter(valid_605364, JString, required = false,
                                 default = nil)
  if valid_605364 != nil:
    section.add "X-Amz-Algorithm", valid_605364
  var valid_605365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605365 = validateParameter(valid_605365, JString, required = false,
                                 default = nil)
  if valid_605365 != nil:
    section.add "X-Amz-SignedHeaders", valid_605365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605367: Call_DeleteService_605355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specified service within a cluster. You can delete a service if you have no running tasks in it and the desired task count is zero. If the service is actively maintaining tasks, you cannot delete it, and you must update the service to a desired task count of zero. For more information, see <a>UpdateService</a>.</p> <note> <p>When you delete a service, if there are still running tasks that require cleanup, the service status moves from <code>ACTIVE</code> to <code>DRAINING</code>, and the service is no longer visible in the console or in the <a>ListServices</a> API operation. After all tasks have transitioned to either <code>STOPPING</code> or <code>STOPPED</code> status, the service status moves from <code>DRAINING</code> to <code>INACTIVE</code>. Services in the <code>DRAINING</code> or <code>INACTIVE</code> status can still be viewed with the <a>DescribeServices</a> API operation. However, in the future, <code>INACTIVE</code> services may be cleaned up and purged from Amazon ECS record keeping, and <a>DescribeServices</a> calls on those services return a <code>ServiceNotFoundException</code> error.</p> </note> <important> <p>If you attempt to create a new service with the same name as an existing service in either <code>ACTIVE</code> or <code>DRAINING</code> status, you receive an error.</p> </important>
  ## 
  let valid = call_605367.validator(path, query, header, formData, body)
  let scheme = call_605367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605367.url(scheme.get, call_605367.host, call_605367.base,
                         call_605367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605367, url, valid)

proc call*(call_605368: Call_DeleteService_605355; body: JsonNode): Recallable =
  ## deleteService
  ## <p>Deletes a specified service within a cluster. You can delete a service if you have no running tasks in it and the desired task count is zero. If the service is actively maintaining tasks, you cannot delete it, and you must update the service to a desired task count of zero. For more information, see <a>UpdateService</a>.</p> <note> <p>When you delete a service, if there are still running tasks that require cleanup, the service status moves from <code>ACTIVE</code> to <code>DRAINING</code>, and the service is no longer visible in the console or in the <a>ListServices</a> API operation. After all tasks have transitioned to either <code>STOPPING</code> or <code>STOPPED</code> status, the service status moves from <code>DRAINING</code> to <code>INACTIVE</code>. Services in the <code>DRAINING</code> or <code>INACTIVE</code> status can still be viewed with the <a>DescribeServices</a> API operation. However, in the future, <code>INACTIVE</code> services may be cleaned up and purged from Amazon ECS record keeping, and <a>DescribeServices</a> calls on those services return a <code>ServiceNotFoundException</code> error.</p> </note> <important> <p>If you attempt to create a new service with the same name as an existing service in either <code>ACTIVE</code> or <code>DRAINING</code> status, you receive an error.</p> </important>
  ##   body: JObject (required)
  var body_605369 = newJObject()
  if body != nil:
    body_605369 = body
  result = call_605368.call(nil, nil, nil, nil, body_605369)

var deleteService* = Call_DeleteService_605355(name: "deleteService",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteService",
    validator: validate_DeleteService_605356, base: "/", url: url_DeleteService_605357,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTaskSet_605370 = ref object of OpenApiRestCall_604658
proc url_DeleteTaskSet_605372(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTaskSet_605371(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified task set within a service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605373 = header.getOrDefault("X-Amz-Target")
  valid_605373 = validateParameter(valid_605373, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteTaskSet"))
  if valid_605373 != nil:
    section.add "X-Amz-Target", valid_605373
  var valid_605374 = header.getOrDefault("X-Amz-Signature")
  valid_605374 = validateParameter(valid_605374, JString, required = false,
                                 default = nil)
  if valid_605374 != nil:
    section.add "X-Amz-Signature", valid_605374
  var valid_605375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605375 = validateParameter(valid_605375, JString, required = false,
                                 default = nil)
  if valid_605375 != nil:
    section.add "X-Amz-Content-Sha256", valid_605375
  var valid_605376 = header.getOrDefault("X-Amz-Date")
  valid_605376 = validateParameter(valid_605376, JString, required = false,
                                 default = nil)
  if valid_605376 != nil:
    section.add "X-Amz-Date", valid_605376
  var valid_605377 = header.getOrDefault("X-Amz-Credential")
  valid_605377 = validateParameter(valid_605377, JString, required = false,
                                 default = nil)
  if valid_605377 != nil:
    section.add "X-Amz-Credential", valid_605377
  var valid_605378 = header.getOrDefault("X-Amz-Security-Token")
  valid_605378 = validateParameter(valid_605378, JString, required = false,
                                 default = nil)
  if valid_605378 != nil:
    section.add "X-Amz-Security-Token", valid_605378
  var valid_605379 = header.getOrDefault("X-Amz-Algorithm")
  valid_605379 = validateParameter(valid_605379, JString, required = false,
                                 default = nil)
  if valid_605379 != nil:
    section.add "X-Amz-Algorithm", valid_605379
  var valid_605380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605380 = validateParameter(valid_605380, JString, required = false,
                                 default = nil)
  if valid_605380 != nil:
    section.add "X-Amz-SignedHeaders", valid_605380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605382: Call_DeleteTaskSet_605370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified task set within a service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_605382.validator(path, query, header, formData, body)
  let scheme = call_605382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605382.url(scheme.get, call_605382.host, call_605382.base,
                         call_605382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605382, url, valid)

proc call*(call_605383: Call_DeleteTaskSet_605370; body: JsonNode): Recallable =
  ## deleteTaskSet
  ## Deletes a specified task set within a service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_605384 = newJObject()
  if body != nil:
    body_605384 = body
  result = call_605383.call(nil, nil, nil, nil, body_605384)

var deleteTaskSet* = Call_DeleteTaskSet_605370(name: "deleteTaskSet",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteTaskSet",
    validator: validate_DeleteTaskSet_605371, base: "/", url: url_DeleteTaskSet_605372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterContainerInstance_605385 = ref object of OpenApiRestCall_604658
proc url_DeregisterContainerInstance_605387(protocol: Scheme; host: string;
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

proc validate_DeregisterContainerInstance_605386(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deregisters an Amazon ECS container instance from the specified cluster. This instance is no longer available to run tasks.</p> <p>If you intend to use the container instance for some other purpose after deregistration, you should stop all of the tasks running on the container instance before deregistration. That prevents any orphaned tasks from consuming resources.</p> <p>Deregistering a container instance removes the instance from a cluster, but it does not terminate the EC2 instance. If you are finished using the instance, be sure to terminate it in the Amazon EC2 console to stop billing.</p> <note> <p>If you terminate a running container instance, Amazon ECS automatically deregisters the instance from your cluster (stopped container instances or instances with disconnected agents are not automatically deregistered when terminated).</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605388 = header.getOrDefault("X-Amz-Target")
  valid_605388 = validateParameter(valid_605388, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeregisterContainerInstance"))
  if valid_605388 != nil:
    section.add "X-Amz-Target", valid_605388
  var valid_605389 = header.getOrDefault("X-Amz-Signature")
  valid_605389 = validateParameter(valid_605389, JString, required = false,
                                 default = nil)
  if valid_605389 != nil:
    section.add "X-Amz-Signature", valid_605389
  var valid_605390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605390 = validateParameter(valid_605390, JString, required = false,
                                 default = nil)
  if valid_605390 != nil:
    section.add "X-Amz-Content-Sha256", valid_605390
  var valid_605391 = header.getOrDefault("X-Amz-Date")
  valid_605391 = validateParameter(valid_605391, JString, required = false,
                                 default = nil)
  if valid_605391 != nil:
    section.add "X-Amz-Date", valid_605391
  var valid_605392 = header.getOrDefault("X-Amz-Credential")
  valid_605392 = validateParameter(valid_605392, JString, required = false,
                                 default = nil)
  if valid_605392 != nil:
    section.add "X-Amz-Credential", valid_605392
  var valid_605393 = header.getOrDefault("X-Amz-Security-Token")
  valid_605393 = validateParameter(valid_605393, JString, required = false,
                                 default = nil)
  if valid_605393 != nil:
    section.add "X-Amz-Security-Token", valid_605393
  var valid_605394 = header.getOrDefault("X-Amz-Algorithm")
  valid_605394 = validateParameter(valid_605394, JString, required = false,
                                 default = nil)
  if valid_605394 != nil:
    section.add "X-Amz-Algorithm", valid_605394
  var valid_605395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605395 = validateParameter(valid_605395, JString, required = false,
                                 default = nil)
  if valid_605395 != nil:
    section.add "X-Amz-SignedHeaders", valid_605395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605397: Call_DeregisterContainerInstance_605385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deregisters an Amazon ECS container instance from the specified cluster. This instance is no longer available to run tasks.</p> <p>If you intend to use the container instance for some other purpose after deregistration, you should stop all of the tasks running on the container instance before deregistration. That prevents any orphaned tasks from consuming resources.</p> <p>Deregistering a container instance removes the instance from a cluster, but it does not terminate the EC2 instance. If you are finished using the instance, be sure to terminate it in the Amazon EC2 console to stop billing.</p> <note> <p>If you terminate a running container instance, Amazon ECS automatically deregisters the instance from your cluster (stopped container instances or instances with disconnected agents are not automatically deregistered when terminated).</p> </note>
  ## 
  let valid = call_605397.validator(path, query, header, formData, body)
  let scheme = call_605397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605397.url(scheme.get, call_605397.host, call_605397.base,
                         call_605397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605397, url, valid)

proc call*(call_605398: Call_DeregisterContainerInstance_605385; body: JsonNode): Recallable =
  ## deregisterContainerInstance
  ## <p>Deregisters an Amazon ECS container instance from the specified cluster. This instance is no longer available to run tasks.</p> <p>If you intend to use the container instance for some other purpose after deregistration, you should stop all of the tasks running on the container instance before deregistration. That prevents any orphaned tasks from consuming resources.</p> <p>Deregistering a container instance removes the instance from a cluster, but it does not terminate the EC2 instance. If you are finished using the instance, be sure to terminate it in the Amazon EC2 console to stop billing.</p> <note> <p>If you terminate a running container instance, Amazon ECS automatically deregisters the instance from your cluster (stopped container instances or instances with disconnected agents are not automatically deregistered when terminated).</p> </note>
  ##   body: JObject (required)
  var body_605399 = newJObject()
  if body != nil:
    body_605399 = body
  result = call_605398.call(nil, nil, nil, nil, body_605399)

var deregisterContainerInstance* = Call_DeregisterContainerInstance_605385(
    name: "deregisterContainerInstance", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeregisterContainerInstance",
    validator: validate_DeregisterContainerInstance_605386, base: "/",
    url: url_DeregisterContainerInstance_605387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskDefinition_605400 = ref object of OpenApiRestCall_604658
proc url_DeregisterTaskDefinition_605402(protocol: Scheme; host: string;
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

proc validate_DeregisterTaskDefinition_605401(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deregisters the specified task definition by family and revision. Upon deregistration, the task definition is marked as <code>INACTIVE</code>. Existing tasks and services that reference an <code>INACTIVE</code> task definition continue to run without disruption. Existing services that reference an <code>INACTIVE</code> task definition can still scale up or down by modifying the service's desired count.</p> <p>You cannot use an <code>INACTIVE</code> task definition to run new tasks or create new services, and you cannot update an existing service to reference an <code>INACTIVE</code> task definition. However, there may be up to a 10-minute window following deregistration where these restrictions have not yet taken effect.</p> <note> <p>At this time, <code>INACTIVE</code> task definitions remain discoverable in your account indefinitely. However, this behavior is subject to change in the future, so you should not rely on <code>INACTIVE</code> task definitions persisting beyond the lifecycle of any associated tasks and services.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605403 = header.getOrDefault("X-Amz-Target")
  valid_605403 = validateParameter(valid_605403, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeregisterTaskDefinition"))
  if valid_605403 != nil:
    section.add "X-Amz-Target", valid_605403
  var valid_605404 = header.getOrDefault("X-Amz-Signature")
  valid_605404 = validateParameter(valid_605404, JString, required = false,
                                 default = nil)
  if valid_605404 != nil:
    section.add "X-Amz-Signature", valid_605404
  var valid_605405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605405 = validateParameter(valid_605405, JString, required = false,
                                 default = nil)
  if valid_605405 != nil:
    section.add "X-Amz-Content-Sha256", valid_605405
  var valid_605406 = header.getOrDefault("X-Amz-Date")
  valid_605406 = validateParameter(valid_605406, JString, required = false,
                                 default = nil)
  if valid_605406 != nil:
    section.add "X-Amz-Date", valid_605406
  var valid_605407 = header.getOrDefault("X-Amz-Credential")
  valid_605407 = validateParameter(valid_605407, JString, required = false,
                                 default = nil)
  if valid_605407 != nil:
    section.add "X-Amz-Credential", valid_605407
  var valid_605408 = header.getOrDefault("X-Amz-Security-Token")
  valid_605408 = validateParameter(valid_605408, JString, required = false,
                                 default = nil)
  if valid_605408 != nil:
    section.add "X-Amz-Security-Token", valid_605408
  var valid_605409 = header.getOrDefault("X-Amz-Algorithm")
  valid_605409 = validateParameter(valid_605409, JString, required = false,
                                 default = nil)
  if valid_605409 != nil:
    section.add "X-Amz-Algorithm", valid_605409
  var valid_605410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605410 = validateParameter(valid_605410, JString, required = false,
                                 default = nil)
  if valid_605410 != nil:
    section.add "X-Amz-SignedHeaders", valid_605410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605412: Call_DeregisterTaskDefinition_605400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deregisters the specified task definition by family and revision. Upon deregistration, the task definition is marked as <code>INACTIVE</code>. Existing tasks and services that reference an <code>INACTIVE</code> task definition continue to run without disruption. Existing services that reference an <code>INACTIVE</code> task definition can still scale up or down by modifying the service's desired count.</p> <p>You cannot use an <code>INACTIVE</code> task definition to run new tasks or create new services, and you cannot update an existing service to reference an <code>INACTIVE</code> task definition. However, there may be up to a 10-minute window following deregistration where these restrictions have not yet taken effect.</p> <note> <p>At this time, <code>INACTIVE</code> task definitions remain discoverable in your account indefinitely. However, this behavior is subject to change in the future, so you should not rely on <code>INACTIVE</code> task definitions persisting beyond the lifecycle of any associated tasks and services.</p> </note>
  ## 
  let valid = call_605412.validator(path, query, header, formData, body)
  let scheme = call_605412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605412.url(scheme.get, call_605412.host, call_605412.base,
                         call_605412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605412, url, valid)

proc call*(call_605413: Call_DeregisterTaskDefinition_605400; body: JsonNode): Recallable =
  ## deregisterTaskDefinition
  ## <p>Deregisters the specified task definition by family and revision. Upon deregistration, the task definition is marked as <code>INACTIVE</code>. Existing tasks and services that reference an <code>INACTIVE</code> task definition continue to run without disruption. Existing services that reference an <code>INACTIVE</code> task definition can still scale up or down by modifying the service's desired count.</p> <p>You cannot use an <code>INACTIVE</code> task definition to run new tasks or create new services, and you cannot update an existing service to reference an <code>INACTIVE</code> task definition. However, there may be up to a 10-minute window following deregistration where these restrictions have not yet taken effect.</p> <note> <p>At this time, <code>INACTIVE</code> task definitions remain discoverable in your account indefinitely. However, this behavior is subject to change in the future, so you should not rely on <code>INACTIVE</code> task definitions persisting beyond the lifecycle of any associated tasks and services.</p> </note>
  ##   body: JObject (required)
  var body_605414 = newJObject()
  if body != nil:
    body_605414 = body
  result = call_605413.call(nil, nil, nil, nil, body_605414)

var deregisterTaskDefinition* = Call_DeregisterTaskDefinition_605400(
    name: "deregisterTaskDefinition", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeregisterTaskDefinition",
    validator: validate_DeregisterTaskDefinition_605401, base: "/",
    url: url_DeregisterTaskDefinition_605402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCapacityProviders_605415 = ref object of OpenApiRestCall_604658
proc url_DescribeCapacityProviders_605417(protocol: Scheme; host: string;
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

proc validate_DescribeCapacityProviders_605416(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes one or more of your capacity providers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605418 = header.getOrDefault("X-Amz-Target")
  valid_605418 = validateParameter(valid_605418, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeCapacityProviders"))
  if valid_605418 != nil:
    section.add "X-Amz-Target", valid_605418
  var valid_605419 = header.getOrDefault("X-Amz-Signature")
  valid_605419 = validateParameter(valid_605419, JString, required = false,
                                 default = nil)
  if valid_605419 != nil:
    section.add "X-Amz-Signature", valid_605419
  var valid_605420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605420 = validateParameter(valid_605420, JString, required = false,
                                 default = nil)
  if valid_605420 != nil:
    section.add "X-Amz-Content-Sha256", valid_605420
  var valid_605421 = header.getOrDefault("X-Amz-Date")
  valid_605421 = validateParameter(valid_605421, JString, required = false,
                                 default = nil)
  if valid_605421 != nil:
    section.add "X-Amz-Date", valid_605421
  var valid_605422 = header.getOrDefault("X-Amz-Credential")
  valid_605422 = validateParameter(valid_605422, JString, required = false,
                                 default = nil)
  if valid_605422 != nil:
    section.add "X-Amz-Credential", valid_605422
  var valid_605423 = header.getOrDefault("X-Amz-Security-Token")
  valid_605423 = validateParameter(valid_605423, JString, required = false,
                                 default = nil)
  if valid_605423 != nil:
    section.add "X-Amz-Security-Token", valid_605423
  var valid_605424 = header.getOrDefault("X-Amz-Algorithm")
  valid_605424 = validateParameter(valid_605424, JString, required = false,
                                 default = nil)
  if valid_605424 != nil:
    section.add "X-Amz-Algorithm", valid_605424
  var valid_605425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605425 = validateParameter(valid_605425, JString, required = false,
                                 default = nil)
  if valid_605425 != nil:
    section.add "X-Amz-SignedHeaders", valid_605425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605427: Call_DescribeCapacityProviders_605415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your capacity providers.
  ## 
  let valid = call_605427.validator(path, query, header, formData, body)
  let scheme = call_605427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605427.url(scheme.get, call_605427.host, call_605427.base,
                         call_605427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605427, url, valid)

proc call*(call_605428: Call_DescribeCapacityProviders_605415; body: JsonNode): Recallable =
  ## describeCapacityProviders
  ## Describes one or more of your capacity providers.
  ##   body: JObject (required)
  var body_605429 = newJObject()
  if body != nil:
    body_605429 = body
  result = call_605428.call(nil, nil, nil, nil, body_605429)

var describeCapacityProviders* = Call_DescribeCapacityProviders_605415(
    name: "describeCapacityProviders", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeCapacityProviders",
    validator: validate_DescribeCapacityProviders_605416, base: "/",
    url: url_DescribeCapacityProviders_605417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusters_605430 = ref object of OpenApiRestCall_604658
proc url_DescribeClusters_605432(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeClusters_605431(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes one or more of your clusters.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605433 = header.getOrDefault("X-Amz-Target")
  valid_605433 = validateParameter(valid_605433, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeClusters"))
  if valid_605433 != nil:
    section.add "X-Amz-Target", valid_605433
  var valid_605434 = header.getOrDefault("X-Amz-Signature")
  valid_605434 = validateParameter(valid_605434, JString, required = false,
                                 default = nil)
  if valid_605434 != nil:
    section.add "X-Amz-Signature", valid_605434
  var valid_605435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605435 = validateParameter(valid_605435, JString, required = false,
                                 default = nil)
  if valid_605435 != nil:
    section.add "X-Amz-Content-Sha256", valid_605435
  var valid_605436 = header.getOrDefault("X-Amz-Date")
  valid_605436 = validateParameter(valid_605436, JString, required = false,
                                 default = nil)
  if valid_605436 != nil:
    section.add "X-Amz-Date", valid_605436
  var valid_605437 = header.getOrDefault("X-Amz-Credential")
  valid_605437 = validateParameter(valid_605437, JString, required = false,
                                 default = nil)
  if valid_605437 != nil:
    section.add "X-Amz-Credential", valid_605437
  var valid_605438 = header.getOrDefault("X-Amz-Security-Token")
  valid_605438 = validateParameter(valid_605438, JString, required = false,
                                 default = nil)
  if valid_605438 != nil:
    section.add "X-Amz-Security-Token", valid_605438
  var valid_605439 = header.getOrDefault("X-Amz-Algorithm")
  valid_605439 = validateParameter(valid_605439, JString, required = false,
                                 default = nil)
  if valid_605439 != nil:
    section.add "X-Amz-Algorithm", valid_605439
  var valid_605440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605440 = validateParameter(valid_605440, JString, required = false,
                                 default = nil)
  if valid_605440 != nil:
    section.add "X-Amz-SignedHeaders", valid_605440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605442: Call_DescribeClusters_605430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your clusters.
  ## 
  let valid = call_605442.validator(path, query, header, formData, body)
  let scheme = call_605442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605442.url(scheme.get, call_605442.host, call_605442.base,
                         call_605442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605442, url, valid)

proc call*(call_605443: Call_DescribeClusters_605430; body: JsonNode): Recallable =
  ## describeClusters
  ## Describes one or more of your clusters.
  ##   body: JObject (required)
  var body_605444 = newJObject()
  if body != nil:
    body_605444 = body
  result = call_605443.call(nil, nil, nil, nil, body_605444)

var describeClusters* = Call_DescribeClusters_605430(name: "describeClusters",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeClusters",
    validator: validate_DescribeClusters_605431, base: "/",
    url: url_DescribeClusters_605432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeContainerInstances_605445 = ref object of OpenApiRestCall_604658
proc url_DescribeContainerInstances_605447(protocol: Scheme; host: string;
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

proc validate_DescribeContainerInstances_605446(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes Amazon Elastic Container Service container instances. Returns metadata about registered and remaining resources on each container instance requested.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605448 = header.getOrDefault("X-Amz-Target")
  valid_605448 = validateParameter(valid_605448, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeContainerInstances"))
  if valid_605448 != nil:
    section.add "X-Amz-Target", valid_605448
  var valid_605449 = header.getOrDefault("X-Amz-Signature")
  valid_605449 = validateParameter(valid_605449, JString, required = false,
                                 default = nil)
  if valid_605449 != nil:
    section.add "X-Amz-Signature", valid_605449
  var valid_605450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605450 = validateParameter(valid_605450, JString, required = false,
                                 default = nil)
  if valid_605450 != nil:
    section.add "X-Amz-Content-Sha256", valid_605450
  var valid_605451 = header.getOrDefault("X-Amz-Date")
  valid_605451 = validateParameter(valid_605451, JString, required = false,
                                 default = nil)
  if valid_605451 != nil:
    section.add "X-Amz-Date", valid_605451
  var valid_605452 = header.getOrDefault("X-Amz-Credential")
  valid_605452 = validateParameter(valid_605452, JString, required = false,
                                 default = nil)
  if valid_605452 != nil:
    section.add "X-Amz-Credential", valid_605452
  var valid_605453 = header.getOrDefault("X-Amz-Security-Token")
  valid_605453 = validateParameter(valid_605453, JString, required = false,
                                 default = nil)
  if valid_605453 != nil:
    section.add "X-Amz-Security-Token", valid_605453
  var valid_605454 = header.getOrDefault("X-Amz-Algorithm")
  valid_605454 = validateParameter(valid_605454, JString, required = false,
                                 default = nil)
  if valid_605454 != nil:
    section.add "X-Amz-Algorithm", valid_605454
  var valid_605455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605455 = validateParameter(valid_605455, JString, required = false,
                                 default = nil)
  if valid_605455 != nil:
    section.add "X-Amz-SignedHeaders", valid_605455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605457: Call_DescribeContainerInstances_605445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes Amazon Elastic Container Service container instances. Returns metadata about registered and remaining resources on each container instance requested.
  ## 
  let valid = call_605457.validator(path, query, header, formData, body)
  let scheme = call_605457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605457.url(scheme.get, call_605457.host, call_605457.base,
                         call_605457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605457, url, valid)

proc call*(call_605458: Call_DescribeContainerInstances_605445; body: JsonNode): Recallable =
  ## describeContainerInstances
  ## Describes Amazon Elastic Container Service container instances. Returns metadata about registered and remaining resources on each container instance requested.
  ##   body: JObject (required)
  var body_605459 = newJObject()
  if body != nil:
    body_605459 = body
  result = call_605458.call(nil, nil, nil, nil, body_605459)

var describeContainerInstances* = Call_DescribeContainerInstances_605445(
    name: "describeContainerInstances", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeContainerInstances",
    validator: validate_DescribeContainerInstances_605446, base: "/",
    url: url_DescribeContainerInstances_605447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServices_605460 = ref object of OpenApiRestCall_604658
proc url_DescribeServices_605462(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeServices_605461(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes the specified services running in your cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605463 = header.getOrDefault("X-Amz-Target")
  valid_605463 = validateParameter(valid_605463, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeServices"))
  if valid_605463 != nil:
    section.add "X-Amz-Target", valid_605463
  var valid_605464 = header.getOrDefault("X-Amz-Signature")
  valid_605464 = validateParameter(valid_605464, JString, required = false,
                                 default = nil)
  if valid_605464 != nil:
    section.add "X-Amz-Signature", valid_605464
  var valid_605465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605465 = validateParameter(valid_605465, JString, required = false,
                                 default = nil)
  if valid_605465 != nil:
    section.add "X-Amz-Content-Sha256", valid_605465
  var valid_605466 = header.getOrDefault("X-Amz-Date")
  valid_605466 = validateParameter(valid_605466, JString, required = false,
                                 default = nil)
  if valid_605466 != nil:
    section.add "X-Amz-Date", valid_605466
  var valid_605467 = header.getOrDefault("X-Amz-Credential")
  valid_605467 = validateParameter(valid_605467, JString, required = false,
                                 default = nil)
  if valid_605467 != nil:
    section.add "X-Amz-Credential", valid_605467
  var valid_605468 = header.getOrDefault("X-Amz-Security-Token")
  valid_605468 = validateParameter(valid_605468, JString, required = false,
                                 default = nil)
  if valid_605468 != nil:
    section.add "X-Amz-Security-Token", valid_605468
  var valid_605469 = header.getOrDefault("X-Amz-Algorithm")
  valid_605469 = validateParameter(valid_605469, JString, required = false,
                                 default = nil)
  if valid_605469 != nil:
    section.add "X-Amz-Algorithm", valid_605469
  var valid_605470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605470 = validateParameter(valid_605470, JString, required = false,
                                 default = nil)
  if valid_605470 != nil:
    section.add "X-Amz-SignedHeaders", valid_605470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605472: Call_DescribeServices_605460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified services running in your cluster.
  ## 
  let valid = call_605472.validator(path, query, header, formData, body)
  let scheme = call_605472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605472.url(scheme.get, call_605472.host, call_605472.base,
                         call_605472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605472, url, valid)

proc call*(call_605473: Call_DescribeServices_605460; body: JsonNode): Recallable =
  ## describeServices
  ## Describes the specified services running in your cluster.
  ##   body: JObject (required)
  var body_605474 = newJObject()
  if body != nil:
    body_605474 = body
  result = call_605473.call(nil, nil, nil, nil, body_605474)

var describeServices* = Call_DescribeServices_605460(name: "describeServices",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeServices",
    validator: validate_DescribeServices_605461, base: "/",
    url: url_DescribeServices_605462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTaskDefinition_605475 = ref object of OpenApiRestCall_604658
proc url_DescribeTaskDefinition_605477(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTaskDefinition_605476(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes a task definition. You can specify a <code>family</code> and <code>revision</code> to find information about a specific task definition, or you can simply specify the family to find the latest <code>ACTIVE</code> revision in that family.</p> <note> <p>You can only describe <code>INACTIVE</code> task definitions while an active task or service references them.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605478 = header.getOrDefault("X-Amz-Target")
  valid_605478 = validateParameter(valid_605478, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeTaskDefinition"))
  if valid_605478 != nil:
    section.add "X-Amz-Target", valid_605478
  var valid_605479 = header.getOrDefault("X-Amz-Signature")
  valid_605479 = validateParameter(valid_605479, JString, required = false,
                                 default = nil)
  if valid_605479 != nil:
    section.add "X-Amz-Signature", valid_605479
  var valid_605480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605480 = validateParameter(valid_605480, JString, required = false,
                                 default = nil)
  if valid_605480 != nil:
    section.add "X-Amz-Content-Sha256", valid_605480
  var valid_605481 = header.getOrDefault("X-Amz-Date")
  valid_605481 = validateParameter(valid_605481, JString, required = false,
                                 default = nil)
  if valid_605481 != nil:
    section.add "X-Amz-Date", valid_605481
  var valid_605482 = header.getOrDefault("X-Amz-Credential")
  valid_605482 = validateParameter(valid_605482, JString, required = false,
                                 default = nil)
  if valid_605482 != nil:
    section.add "X-Amz-Credential", valid_605482
  var valid_605483 = header.getOrDefault("X-Amz-Security-Token")
  valid_605483 = validateParameter(valid_605483, JString, required = false,
                                 default = nil)
  if valid_605483 != nil:
    section.add "X-Amz-Security-Token", valid_605483
  var valid_605484 = header.getOrDefault("X-Amz-Algorithm")
  valid_605484 = validateParameter(valid_605484, JString, required = false,
                                 default = nil)
  if valid_605484 != nil:
    section.add "X-Amz-Algorithm", valid_605484
  var valid_605485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605485 = validateParameter(valid_605485, JString, required = false,
                                 default = nil)
  if valid_605485 != nil:
    section.add "X-Amz-SignedHeaders", valid_605485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605487: Call_DescribeTaskDefinition_605475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a task definition. You can specify a <code>family</code> and <code>revision</code> to find information about a specific task definition, or you can simply specify the family to find the latest <code>ACTIVE</code> revision in that family.</p> <note> <p>You can only describe <code>INACTIVE</code> task definitions while an active task or service references them.</p> </note>
  ## 
  let valid = call_605487.validator(path, query, header, formData, body)
  let scheme = call_605487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605487.url(scheme.get, call_605487.host, call_605487.base,
                         call_605487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605487, url, valid)

proc call*(call_605488: Call_DescribeTaskDefinition_605475; body: JsonNode): Recallable =
  ## describeTaskDefinition
  ## <p>Describes a task definition. You can specify a <code>family</code> and <code>revision</code> to find information about a specific task definition, or you can simply specify the family to find the latest <code>ACTIVE</code> revision in that family.</p> <note> <p>You can only describe <code>INACTIVE</code> task definitions while an active task or service references them.</p> </note>
  ##   body: JObject (required)
  var body_605489 = newJObject()
  if body != nil:
    body_605489 = body
  result = call_605488.call(nil, nil, nil, nil, body_605489)

var describeTaskDefinition* = Call_DescribeTaskDefinition_605475(
    name: "describeTaskDefinition", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTaskDefinition",
    validator: validate_DescribeTaskDefinition_605476, base: "/",
    url: url_DescribeTaskDefinition_605477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTaskSets_605490 = ref object of OpenApiRestCall_604658
proc url_DescribeTaskSets_605492(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTaskSets_605491(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes the task sets in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605493 = header.getOrDefault("X-Amz-Target")
  valid_605493 = validateParameter(valid_605493, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeTaskSets"))
  if valid_605493 != nil:
    section.add "X-Amz-Target", valid_605493
  var valid_605494 = header.getOrDefault("X-Amz-Signature")
  valid_605494 = validateParameter(valid_605494, JString, required = false,
                                 default = nil)
  if valid_605494 != nil:
    section.add "X-Amz-Signature", valid_605494
  var valid_605495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605495 = validateParameter(valid_605495, JString, required = false,
                                 default = nil)
  if valid_605495 != nil:
    section.add "X-Amz-Content-Sha256", valid_605495
  var valid_605496 = header.getOrDefault("X-Amz-Date")
  valid_605496 = validateParameter(valid_605496, JString, required = false,
                                 default = nil)
  if valid_605496 != nil:
    section.add "X-Amz-Date", valid_605496
  var valid_605497 = header.getOrDefault("X-Amz-Credential")
  valid_605497 = validateParameter(valid_605497, JString, required = false,
                                 default = nil)
  if valid_605497 != nil:
    section.add "X-Amz-Credential", valid_605497
  var valid_605498 = header.getOrDefault("X-Amz-Security-Token")
  valid_605498 = validateParameter(valid_605498, JString, required = false,
                                 default = nil)
  if valid_605498 != nil:
    section.add "X-Amz-Security-Token", valid_605498
  var valid_605499 = header.getOrDefault("X-Amz-Algorithm")
  valid_605499 = validateParameter(valid_605499, JString, required = false,
                                 default = nil)
  if valid_605499 != nil:
    section.add "X-Amz-Algorithm", valid_605499
  var valid_605500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605500 = validateParameter(valid_605500, JString, required = false,
                                 default = nil)
  if valid_605500 != nil:
    section.add "X-Amz-SignedHeaders", valid_605500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605502: Call_DescribeTaskSets_605490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the task sets in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_605502.validator(path, query, header, formData, body)
  let scheme = call_605502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605502.url(scheme.get, call_605502.host, call_605502.base,
                         call_605502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605502, url, valid)

proc call*(call_605503: Call_DescribeTaskSets_605490; body: JsonNode): Recallable =
  ## describeTaskSets
  ## Describes the task sets in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_605504 = newJObject()
  if body != nil:
    body_605504 = body
  result = call_605503.call(nil, nil, nil, nil, body_605504)

var describeTaskSets* = Call_DescribeTaskSets_605490(name: "describeTaskSets",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTaskSets",
    validator: validate_DescribeTaskSets_605491, base: "/",
    url: url_DescribeTaskSets_605492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTasks_605505 = ref object of OpenApiRestCall_604658
proc url_DescribeTasks_605507(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTasks_605506(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a specified task or tasks.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605508 = header.getOrDefault("X-Amz-Target")
  valid_605508 = validateParameter(valid_605508, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeTasks"))
  if valid_605508 != nil:
    section.add "X-Amz-Target", valid_605508
  var valid_605509 = header.getOrDefault("X-Amz-Signature")
  valid_605509 = validateParameter(valid_605509, JString, required = false,
                                 default = nil)
  if valid_605509 != nil:
    section.add "X-Amz-Signature", valid_605509
  var valid_605510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605510 = validateParameter(valid_605510, JString, required = false,
                                 default = nil)
  if valid_605510 != nil:
    section.add "X-Amz-Content-Sha256", valid_605510
  var valid_605511 = header.getOrDefault("X-Amz-Date")
  valid_605511 = validateParameter(valid_605511, JString, required = false,
                                 default = nil)
  if valid_605511 != nil:
    section.add "X-Amz-Date", valid_605511
  var valid_605512 = header.getOrDefault("X-Amz-Credential")
  valid_605512 = validateParameter(valid_605512, JString, required = false,
                                 default = nil)
  if valid_605512 != nil:
    section.add "X-Amz-Credential", valid_605512
  var valid_605513 = header.getOrDefault("X-Amz-Security-Token")
  valid_605513 = validateParameter(valid_605513, JString, required = false,
                                 default = nil)
  if valid_605513 != nil:
    section.add "X-Amz-Security-Token", valid_605513
  var valid_605514 = header.getOrDefault("X-Amz-Algorithm")
  valid_605514 = validateParameter(valid_605514, JString, required = false,
                                 default = nil)
  if valid_605514 != nil:
    section.add "X-Amz-Algorithm", valid_605514
  var valid_605515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605515 = validateParameter(valid_605515, JString, required = false,
                                 default = nil)
  if valid_605515 != nil:
    section.add "X-Amz-SignedHeaders", valid_605515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605517: Call_DescribeTasks_605505; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specified task or tasks.
  ## 
  let valid = call_605517.validator(path, query, header, formData, body)
  let scheme = call_605517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605517.url(scheme.get, call_605517.host, call_605517.base,
                         call_605517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605517, url, valid)

proc call*(call_605518: Call_DescribeTasks_605505; body: JsonNode): Recallable =
  ## describeTasks
  ## Describes a specified task or tasks.
  ##   body: JObject (required)
  var body_605519 = newJObject()
  if body != nil:
    body_605519 = body
  result = call_605518.call(nil, nil, nil, nil, body_605519)

var describeTasks* = Call_DescribeTasks_605505(name: "describeTasks",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTasks",
    validator: validate_DescribeTasks_605506, base: "/", url: url_DescribeTasks_605507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DiscoverPollEndpoint_605520 = ref object of OpenApiRestCall_604658
proc url_DiscoverPollEndpoint_605522(protocol: Scheme; host: string; base: string;
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

proc validate_DiscoverPollEndpoint_605521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Returns an endpoint for the Amazon ECS agent to poll for updates.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605523 = header.getOrDefault("X-Amz-Target")
  valid_605523 = validateParameter(valid_605523, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DiscoverPollEndpoint"))
  if valid_605523 != nil:
    section.add "X-Amz-Target", valid_605523
  var valid_605524 = header.getOrDefault("X-Amz-Signature")
  valid_605524 = validateParameter(valid_605524, JString, required = false,
                                 default = nil)
  if valid_605524 != nil:
    section.add "X-Amz-Signature", valid_605524
  var valid_605525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605525 = validateParameter(valid_605525, JString, required = false,
                                 default = nil)
  if valid_605525 != nil:
    section.add "X-Amz-Content-Sha256", valid_605525
  var valid_605526 = header.getOrDefault("X-Amz-Date")
  valid_605526 = validateParameter(valid_605526, JString, required = false,
                                 default = nil)
  if valid_605526 != nil:
    section.add "X-Amz-Date", valid_605526
  var valid_605527 = header.getOrDefault("X-Amz-Credential")
  valid_605527 = validateParameter(valid_605527, JString, required = false,
                                 default = nil)
  if valid_605527 != nil:
    section.add "X-Amz-Credential", valid_605527
  var valid_605528 = header.getOrDefault("X-Amz-Security-Token")
  valid_605528 = validateParameter(valid_605528, JString, required = false,
                                 default = nil)
  if valid_605528 != nil:
    section.add "X-Amz-Security-Token", valid_605528
  var valid_605529 = header.getOrDefault("X-Amz-Algorithm")
  valid_605529 = validateParameter(valid_605529, JString, required = false,
                                 default = nil)
  if valid_605529 != nil:
    section.add "X-Amz-Algorithm", valid_605529
  var valid_605530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605530 = validateParameter(valid_605530, JString, required = false,
                                 default = nil)
  if valid_605530 != nil:
    section.add "X-Amz-SignedHeaders", valid_605530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605532: Call_DiscoverPollEndpoint_605520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Returns an endpoint for the Amazon ECS agent to poll for updates.</p>
  ## 
  let valid = call_605532.validator(path, query, header, formData, body)
  let scheme = call_605532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605532.url(scheme.get, call_605532.host, call_605532.base,
                         call_605532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605532, url, valid)

proc call*(call_605533: Call_DiscoverPollEndpoint_605520; body: JsonNode): Recallable =
  ## discoverPollEndpoint
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Returns an endpoint for the Amazon ECS agent to poll for updates.</p>
  ##   body: JObject (required)
  var body_605534 = newJObject()
  if body != nil:
    body_605534 = body
  result = call_605533.call(nil, nil, nil, nil, body_605534)

var discoverPollEndpoint* = Call_DiscoverPollEndpoint_605520(
    name: "discoverPollEndpoint", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DiscoverPollEndpoint",
    validator: validate_DiscoverPollEndpoint_605521, base: "/",
    url: url_DiscoverPollEndpoint_605522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountSettings_605535 = ref object of OpenApiRestCall_604658
proc url_ListAccountSettings_605537(protocol: Scheme; host: string; base: string;
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

proc validate_ListAccountSettings_605536(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the account settings for a specified principal.
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
  var valid_605538 = query.getOrDefault("nextToken")
  valid_605538 = validateParameter(valid_605538, JString, required = false,
                                 default = nil)
  if valid_605538 != nil:
    section.add "nextToken", valid_605538
  var valid_605539 = query.getOrDefault("maxResults")
  valid_605539 = validateParameter(valid_605539, JString, required = false,
                                 default = nil)
  if valid_605539 != nil:
    section.add "maxResults", valid_605539
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605540 = header.getOrDefault("X-Amz-Target")
  valid_605540 = validateParameter(valid_605540, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListAccountSettings"))
  if valid_605540 != nil:
    section.add "X-Amz-Target", valid_605540
  var valid_605541 = header.getOrDefault("X-Amz-Signature")
  valid_605541 = validateParameter(valid_605541, JString, required = false,
                                 default = nil)
  if valid_605541 != nil:
    section.add "X-Amz-Signature", valid_605541
  var valid_605542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605542 = validateParameter(valid_605542, JString, required = false,
                                 default = nil)
  if valid_605542 != nil:
    section.add "X-Amz-Content-Sha256", valid_605542
  var valid_605543 = header.getOrDefault("X-Amz-Date")
  valid_605543 = validateParameter(valid_605543, JString, required = false,
                                 default = nil)
  if valid_605543 != nil:
    section.add "X-Amz-Date", valid_605543
  var valid_605544 = header.getOrDefault("X-Amz-Credential")
  valid_605544 = validateParameter(valid_605544, JString, required = false,
                                 default = nil)
  if valid_605544 != nil:
    section.add "X-Amz-Credential", valid_605544
  var valid_605545 = header.getOrDefault("X-Amz-Security-Token")
  valid_605545 = validateParameter(valid_605545, JString, required = false,
                                 default = nil)
  if valid_605545 != nil:
    section.add "X-Amz-Security-Token", valid_605545
  var valid_605546 = header.getOrDefault("X-Amz-Algorithm")
  valid_605546 = validateParameter(valid_605546, JString, required = false,
                                 default = nil)
  if valid_605546 != nil:
    section.add "X-Amz-Algorithm", valid_605546
  var valid_605547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605547 = validateParameter(valid_605547, JString, required = false,
                                 default = nil)
  if valid_605547 != nil:
    section.add "X-Amz-SignedHeaders", valid_605547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605549: Call_ListAccountSettings_605535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the account settings for a specified principal.
  ## 
  let valid = call_605549.validator(path, query, header, formData, body)
  let scheme = call_605549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605549.url(scheme.get, call_605549.host, call_605549.base,
                         call_605549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605549, url, valid)

proc call*(call_605550: Call_ListAccountSettings_605535; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAccountSettings
  ## Lists the account settings for a specified principal.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_605551 = newJObject()
  var body_605552 = newJObject()
  add(query_605551, "nextToken", newJString(nextToken))
  if body != nil:
    body_605552 = body
  add(query_605551, "maxResults", newJString(maxResults))
  result = call_605550.call(nil, query_605551, nil, nil, body_605552)

var listAccountSettings* = Call_ListAccountSettings_605535(
    name: "listAccountSettings", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListAccountSettings",
    validator: validate_ListAccountSettings_605536, base: "/",
    url: url_ListAccountSettings_605537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttributes_605554 = ref object of OpenApiRestCall_604658
proc url_ListAttributes_605556(protocol: Scheme; host: string; base: string;
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

proc validate_ListAttributes_605555(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the attributes for Amazon ECS resources within a specified target type and cluster. When you specify a target type and cluster, <code>ListAttributes</code> returns a list of attribute objects, one for each attribute on each resource. You can filter the list of results to a single attribute name to only return results that have that name. You can also filter the results by attribute name and value, for example, to see which container instances in a cluster are running a Linux AMI (<code>ecs.os-type=linux</code>). 
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
  var valid_605557 = query.getOrDefault("nextToken")
  valid_605557 = validateParameter(valid_605557, JString, required = false,
                                 default = nil)
  if valid_605557 != nil:
    section.add "nextToken", valid_605557
  var valid_605558 = query.getOrDefault("maxResults")
  valid_605558 = validateParameter(valid_605558, JString, required = false,
                                 default = nil)
  if valid_605558 != nil:
    section.add "maxResults", valid_605558
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605559 = header.getOrDefault("X-Amz-Target")
  valid_605559 = validateParameter(valid_605559, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListAttributes"))
  if valid_605559 != nil:
    section.add "X-Amz-Target", valid_605559
  var valid_605560 = header.getOrDefault("X-Amz-Signature")
  valid_605560 = validateParameter(valid_605560, JString, required = false,
                                 default = nil)
  if valid_605560 != nil:
    section.add "X-Amz-Signature", valid_605560
  var valid_605561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605561 = validateParameter(valid_605561, JString, required = false,
                                 default = nil)
  if valid_605561 != nil:
    section.add "X-Amz-Content-Sha256", valid_605561
  var valid_605562 = header.getOrDefault("X-Amz-Date")
  valid_605562 = validateParameter(valid_605562, JString, required = false,
                                 default = nil)
  if valid_605562 != nil:
    section.add "X-Amz-Date", valid_605562
  var valid_605563 = header.getOrDefault("X-Amz-Credential")
  valid_605563 = validateParameter(valid_605563, JString, required = false,
                                 default = nil)
  if valid_605563 != nil:
    section.add "X-Amz-Credential", valid_605563
  var valid_605564 = header.getOrDefault("X-Amz-Security-Token")
  valid_605564 = validateParameter(valid_605564, JString, required = false,
                                 default = nil)
  if valid_605564 != nil:
    section.add "X-Amz-Security-Token", valid_605564
  var valid_605565 = header.getOrDefault("X-Amz-Algorithm")
  valid_605565 = validateParameter(valid_605565, JString, required = false,
                                 default = nil)
  if valid_605565 != nil:
    section.add "X-Amz-Algorithm", valid_605565
  var valid_605566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605566 = validateParameter(valid_605566, JString, required = false,
                                 default = nil)
  if valid_605566 != nil:
    section.add "X-Amz-SignedHeaders", valid_605566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605568: Call_ListAttributes_605554; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the attributes for Amazon ECS resources within a specified target type and cluster. When you specify a target type and cluster, <code>ListAttributes</code> returns a list of attribute objects, one for each attribute on each resource. You can filter the list of results to a single attribute name to only return results that have that name. You can also filter the results by attribute name and value, for example, to see which container instances in a cluster are running a Linux AMI (<code>ecs.os-type=linux</code>). 
  ## 
  let valid = call_605568.validator(path, query, header, formData, body)
  let scheme = call_605568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605568.url(scheme.get, call_605568.host, call_605568.base,
                         call_605568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605568, url, valid)

proc call*(call_605569: Call_ListAttributes_605554; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAttributes
  ## Lists the attributes for Amazon ECS resources within a specified target type and cluster. When you specify a target type and cluster, <code>ListAttributes</code> returns a list of attribute objects, one for each attribute on each resource. You can filter the list of results to a single attribute name to only return results that have that name. You can also filter the results by attribute name and value, for example, to see which container instances in a cluster are running a Linux AMI (<code>ecs.os-type=linux</code>). 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_605570 = newJObject()
  var body_605571 = newJObject()
  add(query_605570, "nextToken", newJString(nextToken))
  if body != nil:
    body_605571 = body
  add(query_605570, "maxResults", newJString(maxResults))
  result = call_605569.call(nil, query_605570, nil, nil, body_605571)

var listAttributes* = Call_ListAttributes_605554(name: "listAttributes",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListAttributes",
    validator: validate_ListAttributes_605555, base: "/", url: url_ListAttributes_605556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_605572 = ref object of OpenApiRestCall_604658
proc url_ListClusters_605574(protocol: Scheme; host: string; base: string;
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

proc validate_ListClusters_605573(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing clusters.
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
  var valid_605575 = query.getOrDefault("nextToken")
  valid_605575 = validateParameter(valid_605575, JString, required = false,
                                 default = nil)
  if valid_605575 != nil:
    section.add "nextToken", valid_605575
  var valid_605576 = query.getOrDefault("maxResults")
  valid_605576 = validateParameter(valid_605576, JString, required = false,
                                 default = nil)
  if valid_605576 != nil:
    section.add "maxResults", valid_605576
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605577 = header.getOrDefault("X-Amz-Target")
  valid_605577 = validateParameter(valid_605577, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListClusters"))
  if valid_605577 != nil:
    section.add "X-Amz-Target", valid_605577
  var valid_605578 = header.getOrDefault("X-Amz-Signature")
  valid_605578 = validateParameter(valid_605578, JString, required = false,
                                 default = nil)
  if valid_605578 != nil:
    section.add "X-Amz-Signature", valid_605578
  var valid_605579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605579 = validateParameter(valid_605579, JString, required = false,
                                 default = nil)
  if valid_605579 != nil:
    section.add "X-Amz-Content-Sha256", valid_605579
  var valid_605580 = header.getOrDefault("X-Amz-Date")
  valid_605580 = validateParameter(valid_605580, JString, required = false,
                                 default = nil)
  if valid_605580 != nil:
    section.add "X-Amz-Date", valid_605580
  var valid_605581 = header.getOrDefault("X-Amz-Credential")
  valid_605581 = validateParameter(valid_605581, JString, required = false,
                                 default = nil)
  if valid_605581 != nil:
    section.add "X-Amz-Credential", valid_605581
  var valid_605582 = header.getOrDefault("X-Amz-Security-Token")
  valid_605582 = validateParameter(valid_605582, JString, required = false,
                                 default = nil)
  if valid_605582 != nil:
    section.add "X-Amz-Security-Token", valid_605582
  var valid_605583 = header.getOrDefault("X-Amz-Algorithm")
  valid_605583 = validateParameter(valid_605583, JString, required = false,
                                 default = nil)
  if valid_605583 != nil:
    section.add "X-Amz-Algorithm", valid_605583
  var valid_605584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605584 = validateParameter(valid_605584, JString, required = false,
                                 default = nil)
  if valid_605584 != nil:
    section.add "X-Amz-SignedHeaders", valid_605584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605586: Call_ListClusters_605572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing clusters.
  ## 
  let valid = call_605586.validator(path, query, header, formData, body)
  let scheme = call_605586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605586.url(scheme.get, call_605586.host, call_605586.base,
                         call_605586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605586, url, valid)

proc call*(call_605587: Call_ListClusters_605572; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listClusters
  ## Returns a list of existing clusters.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_605588 = newJObject()
  var body_605589 = newJObject()
  add(query_605588, "nextToken", newJString(nextToken))
  if body != nil:
    body_605589 = body
  add(query_605588, "maxResults", newJString(maxResults))
  result = call_605587.call(nil, query_605588, nil, nil, body_605589)

var listClusters* = Call_ListClusters_605572(name: "listClusters",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListClusters",
    validator: validate_ListClusters_605573, base: "/", url: url_ListClusters_605574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContainerInstances_605590 = ref object of OpenApiRestCall_604658
proc url_ListContainerInstances_605592(protocol: Scheme; host: string; base: string;
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

proc validate_ListContainerInstances_605591(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of container instances in a specified cluster. You can filter the results of a <code>ListContainerInstances</code> operation with cluster query language statements inside the <code>filter</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html">Cluster Query Language</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
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
  var valid_605593 = query.getOrDefault("nextToken")
  valid_605593 = validateParameter(valid_605593, JString, required = false,
                                 default = nil)
  if valid_605593 != nil:
    section.add "nextToken", valid_605593
  var valid_605594 = query.getOrDefault("maxResults")
  valid_605594 = validateParameter(valid_605594, JString, required = false,
                                 default = nil)
  if valid_605594 != nil:
    section.add "maxResults", valid_605594
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605595 = header.getOrDefault("X-Amz-Target")
  valid_605595 = validateParameter(valid_605595, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListContainerInstances"))
  if valid_605595 != nil:
    section.add "X-Amz-Target", valid_605595
  var valid_605596 = header.getOrDefault("X-Amz-Signature")
  valid_605596 = validateParameter(valid_605596, JString, required = false,
                                 default = nil)
  if valid_605596 != nil:
    section.add "X-Amz-Signature", valid_605596
  var valid_605597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605597 = validateParameter(valid_605597, JString, required = false,
                                 default = nil)
  if valid_605597 != nil:
    section.add "X-Amz-Content-Sha256", valid_605597
  var valid_605598 = header.getOrDefault("X-Amz-Date")
  valid_605598 = validateParameter(valid_605598, JString, required = false,
                                 default = nil)
  if valid_605598 != nil:
    section.add "X-Amz-Date", valid_605598
  var valid_605599 = header.getOrDefault("X-Amz-Credential")
  valid_605599 = validateParameter(valid_605599, JString, required = false,
                                 default = nil)
  if valid_605599 != nil:
    section.add "X-Amz-Credential", valid_605599
  var valid_605600 = header.getOrDefault("X-Amz-Security-Token")
  valid_605600 = validateParameter(valid_605600, JString, required = false,
                                 default = nil)
  if valid_605600 != nil:
    section.add "X-Amz-Security-Token", valid_605600
  var valid_605601 = header.getOrDefault("X-Amz-Algorithm")
  valid_605601 = validateParameter(valid_605601, JString, required = false,
                                 default = nil)
  if valid_605601 != nil:
    section.add "X-Amz-Algorithm", valid_605601
  var valid_605602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605602 = validateParameter(valid_605602, JString, required = false,
                                 default = nil)
  if valid_605602 != nil:
    section.add "X-Amz-SignedHeaders", valid_605602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605604: Call_ListContainerInstances_605590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of container instances in a specified cluster. You can filter the results of a <code>ListContainerInstances</code> operation with cluster query language statements inside the <code>filter</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html">Cluster Query Language</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_605604.validator(path, query, header, formData, body)
  let scheme = call_605604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605604.url(scheme.get, call_605604.host, call_605604.base,
                         call_605604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605604, url, valid)

proc call*(call_605605: Call_ListContainerInstances_605590; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listContainerInstances
  ## Returns a list of container instances in a specified cluster. You can filter the results of a <code>ListContainerInstances</code> operation with cluster query language statements inside the <code>filter</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html">Cluster Query Language</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_605606 = newJObject()
  var body_605607 = newJObject()
  add(query_605606, "nextToken", newJString(nextToken))
  if body != nil:
    body_605607 = body
  add(query_605606, "maxResults", newJString(maxResults))
  result = call_605605.call(nil, query_605606, nil, nil, body_605607)

var listContainerInstances* = Call_ListContainerInstances_605590(
    name: "listContainerInstances", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListContainerInstances",
    validator: validate_ListContainerInstances_605591, base: "/",
    url: url_ListContainerInstances_605592, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServices_605608 = ref object of OpenApiRestCall_604658
proc url_ListServices_605610(protocol: Scheme; host: string; base: string;
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

proc validate_ListServices_605609(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the services that are running in a specified cluster.
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
  var valid_605611 = query.getOrDefault("nextToken")
  valid_605611 = validateParameter(valid_605611, JString, required = false,
                                 default = nil)
  if valid_605611 != nil:
    section.add "nextToken", valid_605611
  var valid_605612 = query.getOrDefault("maxResults")
  valid_605612 = validateParameter(valid_605612, JString, required = false,
                                 default = nil)
  if valid_605612 != nil:
    section.add "maxResults", valid_605612
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605613 = header.getOrDefault("X-Amz-Target")
  valid_605613 = validateParameter(valid_605613, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListServices"))
  if valid_605613 != nil:
    section.add "X-Amz-Target", valid_605613
  var valid_605614 = header.getOrDefault("X-Amz-Signature")
  valid_605614 = validateParameter(valid_605614, JString, required = false,
                                 default = nil)
  if valid_605614 != nil:
    section.add "X-Amz-Signature", valid_605614
  var valid_605615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605615 = validateParameter(valid_605615, JString, required = false,
                                 default = nil)
  if valid_605615 != nil:
    section.add "X-Amz-Content-Sha256", valid_605615
  var valid_605616 = header.getOrDefault("X-Amz-Date")
  valid_605616 = validateParameter(valid_605616, JString, required = false,
                                 default = nil)
  if valid_605616 != nil:
    section.add "X-Amz-Date", valid_605616
  var valid_605617 = header.getOrDefault("X-Amz-Credential")
  valid_605617 = validateParameter(valid_605617, JString, required = false,
                                 default = nil)
  if valid_605617 != nil:
    section.add "X-Amz-Credential", valid_605617
  var valid_605618 = header.getOrDefault("X-Amz-Security-Token")
  valid_605618 = validateParameter(valid_605618, JString, required = false,
                                 default = nil)
  if valid_605618 != nil:
    section.add "X-Amz-Security-Token", valid_605618
  var valid_605619 = header.getOrDefault("X-Amz-Algorithm")
  valid_605619 = validateParameter(valid_605619, JString, required = false,
                                 default = nil)
  if valid_605619 != nil:
    section.add "X-Amz-Algorithm", valid_605619
  var valid_605620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605620 = validateParameter(valid_605620, JString, required = false,
                                 default = nil)
  if valid_605620 != nil:
    section.add "X-Amz-SignedHeaders", valid_605620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605622: Call_ListServices_605608; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the services that are running in a specified cluster.
  ## 
  let valid = call_605622.validator(path, query, header, formData, body)
  let scheme = call_605622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605622.url(scheme.get, call_605622.host, call_605622.base,
                         call_605622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605622, url, valid)

proc call*(call_605623: Call_ListServices_605608; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listServices
  ## Lists the services that are running in a specified cluster.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_605624 = newJObject()
  var body_605625 = newJObject()
  add(query_605624, "nextToken", newJString(nextToken))
  if body != nil:
    body_605625 = body
  add(query_605624, "maxResults", newJString(maxResults))
  result = call_605623.call(nil, query_605624, nil, nil, body_605625)

var listServices* = Call_ListServices_605608(name: "listServices",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListServices",
    validator: validate_ListServices_605609, base: "/", url: url_ListServices_605610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_605626 = ref object of OpenApiRestCall_604658
proc url_ListTagsForResource_605628(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_605627(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## List the tags for an Amazon ECS resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605629 = header.getOrDefault("X-Amz-Target")
  valid_605629 = validateParameter(valid_605629, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTagsForResource"))
  if valid_605629 != nil:
    section.add "X-Amz-Target", valid_605629
  var valid_605630 = header.getOrDefault("X-Amz-Signature")
  valid_605630 = validateParameter(valid_605630, JString, required = false,
                                 default = nil)
  if valid_605630 != nil:
    section.add "X-Amz-Signature", valid_605630
  var valid_605631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605631 = validateParameter(valid_605631, JString, required = false,
                                 default = nil)
  if valid_605631 != nil:
    section.add "X-Amz-Content-Sha256", valid_605631
  var valid_605632 = header.getOrDefault("X-Amz-Date")
  valid_605632 = validateParameter(valid_605632, JString, required = false,
                                 default = nil)
  if valid_605632 != nil:
    section.add "X-Amz-Date", valid_605632
  var valid_605633 = header.getOrDefault("X-Amz-Credential")
  valid_605633 = validateParameter(valid_605633, JString, required = false,
                                 default = nil)
  if valid_605633 != nil:
    section.add "X-Amz-Credential", valid_605633
  var valid_605634 = header.getOrDefault("X-Amz-Security-Token")
  valid_605634 = validateParameter(valid_605634, JString, required = false,
                                 default = nil)
  if valid_605634 != nil:
    section.add "X-Amz-Security-Token", valid_605634
  var valid_605635 = header.getOrDefault("X-Amz-Algorithm")
  valid_605635 = validateParameter(valid_605635, JString, required = false,
                                 default = nil)
  if valid_605635 != nil:
    section.add "X-Amz-Algorithm", valid_605635
  var valid_605636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605636 = validateParameter(valid_605636, JString, required = false,
                                 default = nil)
  if valid_605636 != nil:
    section.add "X-Amz-SignedHeaders", valid_605636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605638: Call_ListTagsForResource_605626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an Amazon ECS resource.
  ## 
  let valid = call_605638.validator(path, query, header, formData, body)
  let scheme = call_605638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605638.url(scheme.get, call_605638.host, call_605638.base,
                         call_605638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605638, url, valid)

proc call*(call_605639: Call_ListTagsForResource_605626; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon ECS resource.
  ##   body: JObject (required)
  var body_605640 = newJObject()
  if body != nil:
    body_605640 = body
  result = call_605639.call(nil, nil, nil, nil, body_605640)

var listTagsForResource* = Call_ListTagsForResource_605626(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTagsForResource",
    validator: validate_ListTagsForResource_605627, base: "/",
    url: url_ListTagsForResource_605628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTaskDefinitionFamilies_605641 = ref object of OpenApiRestCall_604658
proc url_ListTaskDefinitionFamilies_605643(protocol: Scheme; host: string;
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

proc validate_ListTaskDefinitionFamilies_605642(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of task definition families that are registered to your account (which may include task definition families that no longer have any <code>ACTIVE</code> task definition revisions).</p> <p>You can filter out task definition families that do not contain any <code>ACTIVE</code> task definition revisions by setting the <code>status</code> parameter to <code>ACTIVE</code>. You can also filter the results with the <code>familyPrefix</code> parameter.</p>
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
  var valid_605644 = query.getOrDefault("nextToken")
  valid_605644 = validateParameter(valid_605644, JString, required = false,
                                 default = nil)
  if valid_605644 != nil:
    section.add "nextToken", valid_605644
  var valid_605645 = query.getOrDefault("maxResults")
  valid_605645 = validateParameter(valid_605645, JString, required = false,
                                 default = nil)
  if valid_605645 != nil:
    section.add "maxResults", valid_605645
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605646 = header.getOrDefault("X-Amz-Target")
  valid_605646 = validateParameter(valid_605646, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTaskDefinitionFamilies"))
  if valid_605646 != nil:
    section.add "X-Amz-Target", valid_605646
  var valid_605647 = header.getOrDefault("X-Amz-Signature")
  valid_605647 = validateParameter(valid_605647, JString, required = false,
                                 default = nil)
  if valid_605647 != nil:
    section.add "X-Amz-Signature", valid_605647
  var valid_605648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605648 = validateParameter(valid_605648, JString, required = false,
                                 default = nil)
  if valid_605648 != nil:
    section.add "X-Amz-Content-Sha256", valid_605648
  var valid_605649 = header.getOrDefault("X-Amz-Date")
  valid_605649 = validateParameter(valid_605649, JString, required = false,
                                 default = nil)
  if valid_605649 != nil:
    section.add "X-Amz-Date", valid_605649
  var valid_605650 = header.getOrDefault("X-Amz-Credential")
  valid_605650 = validateParameter(valid_605650, JString, required = false,
                                 default = nil)
  if valid_605650 != nil:
    section.add "X-Amz-Credential", valid_605650
  var valid_605651 = header.getOrDefault("X-Amz-Security-Token")
  valid_605651 = validateParameter(valid_605651, JString, required = false,
                                 default = nil)
  if valid_605651 != nil:
    section.add "X-Amz-Security-Token", valid_605651
  var valid_605652 = header.getOrDefault("X-Amz-Algorithm")
  valid_605652 = validateParameter(valid_605652, JString, required = false,
                                 default = nil)
  if valid_605652 != nil:
    section.add "X-Amz-Algorithm", valid_605652
  var valid_605653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605653 = validateParameter(valid_605653, JString, required = false,
                                 default = nil)
  if valid_605653 != nil:
    section.add "X-Amz-SignedHeaders", valid_605653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605655: Call_ListTaskDefinitionFamilies_605641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of task definition families that are registered to your account (which may include task definition families that no longer have any <code>ACTIVE</code> task definition revisions).</p> <p>You can filter out task definition families that do not contain any <code>ACTIVE</code> task definition revisions by setting the <code>status</code> parameter to <code>ACTIVE</code>. You can also filter the results with the <code>familyPrefix</code> parameter.</p>
  ## 
  let valid = call_605655.validator(path, query, header, formData, body)
  let scheme = call_605655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605655.url(scheme.get, call_605655.host, call_605655.base,
                         call_605655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605655, url, valid)

proc call*(call_605656: Call_ListTaskDefinitionFamilies_605641; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTaskDefinitionFamilies
  ## <p>Returns a list of task definition families that are registered to your account (which may include task definition families that no longer have any <code>ACTIVE</code> task definition revisions).</p> <p>You can filter out task definition families that do not contain any <code>ACTIVE</code> task definition revisions by setting the <code>status</code> parameter to <code>ACTIVE</code>. You can also filter the results with the <code>familyPrefix</code> parameter.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_605657 = newJObject()
  var body_605658 = newJObject()
  add(query_605657, "nextToken", newJString(nextToken))
  if body != nil:
    body_605658 = body
  add(query_605657, "maxResults", newJString(maxResults))
  result = call_605656.call(nil, query_605657, nil, nil, body_605658)

var listTaskDefinitionFamilies* = Call_ListTaskDefinitionFamilies_605641(
    name: "listTaskDefinitionFamilies", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTaskDefinitionFamilies",
    validator: validate_ListTaskDefinitionFamilies_605642, base: "/",
    url: url_ListTaskDefinitionFamilies_605643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTaskDefinitions_605659 = ref object of OpenApiRestCall_604658
proc url_ListTaskDefinitions_605661(protocol: Scheme; host: string; base: string;
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

proc validate_ListTaskDefinitions_605660(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of task definitions that are registered to your account. You can filter the results by family name with the <code>familyPrefix</code> parameter or by status with the <code>status</code> parameter.
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
  var valid_605662 = query.getOrDefault("nextToken")
  valid_605662 = validateParameter(valid_605662, JString, required = false,
                                 default = nil)
  if valid_605662 != nil:
    section.add "nextToken", valid_605662
  var valid_605663 = query.getOrDefault("maxResults")
  valid_605663 = validateParameter(valid_605663, JString, required = false,
                                 default = nil)
  if valid_605663 != nil:
    section.add "maxResults", valid_605663
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605664 = header.getOrDefault("X-Amz-Target")
  valid_605664 = validateParameter(valid_605664, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTaskDefinitions"))
  if valid_605664 != nil:
    section.add "X-Amz-Target", valid_605664
  var valid_605665 = header.getOrDefault("X-Amz-Signature")
  valid_605665 = validateParameter(valid_605665, JString, required = false,
                                 default = nil)
  if valid_605665 != nil:
    section.add "X-Amz-Signature", valid_605665
  var valid_605666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605666 = validateParameter(valid_605666, JString, required = false,
                                 default = nil)
  if valid_605666 != nil:
    section.add "X-Amz-Content-Sha256", valid_605666
  var valid_605667 = header.getOrDefault("X-Amz-Date")
  valid_605667 = validateParameter(valid_605667, JString, required = false,
                                 default = nil)
  if valid_605667 != nil:
    section.add "X-Amz-Date", valid_605667
  var valid_605668 = header.getOrDefault("X-Amz-Credential")
  valid_605668 = validateParameter(valid_605668, JString, required = false,
                                 default = nil)
  if valid_605668 != nil:
    section.add "X-Amz-Credential", valid_605668
  var valid_605669 = header.getOrDefault("X-Amz-Security-Token")
  valid_605669 = validateParameter(valid_605669, JString, required = false,
                                 default = nil)
  if valid_605669 != nil:
    section.add "X-Amz-Security-Token", valid_605669
  var valid_605670 = header.getOrDefault("X-Amz-Algorithm")
  valid_605670 = validateParameter(valid_605670, JString, required = false,
                                 default = nil)
  if valid_605670 != nil:
    section.add "X-Amz-Algorithm", valid_605670
  var valid_605671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605671 = validateParameter(valid_605671, JString, required = false,
                                 default = nil)
  if valid_605671 != nil:
    section.add "X-Amz-SignedHeaders", valid_605671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605673: Call_ListTaskDefinitions_605659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of task definitions that are registered to your account. You can filter the results by family name with the <code>familyPrefix</code> parameter or by status with the <code>status</code> parameter.
  ## 
  let valid = call_605673.validator(path, query, header, formData, body)
  let scheme = call_605673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605673.url(scheme.get, call_605673.host, call_605673.base,
                         call_605673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605673, url, valid)

proc call*(call_605674: Call_ListTaskDefinitions_605659; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTaskDefinitions
  ## Returns a list of task definitions that are registered to your account. You can filter the results by family name with the <code>familyPrefix</code> parameter or by status with the <code>status</code> parameter.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_605675 = newJObject()
  var body_605676 = newJObject()
  add(query_605675, "nextToken", newJString(nextToken))
  if body != nil:
    body_605676 = body
  add(query_605675, "maxResults", newJString(maxResults))
  result = call_605674.call(nil, query_605675, nil, nil, body_605676)

var listTaskDefinitions* = Call_ListTaskDefinitions_605659(
    name: "listTaskDefinitions", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTaskDefinitions",
    validator: validate_ListTaskDefinitions_605660, base: "/",
    url: url_ListTaskDefinitions_605661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTasks_605677 = ref object of OpenApiRestCall_604658
proc url_ListTasks_605679(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTasks_605678(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of tasks for a specified cluster. You can filter the results by family name, by a particular container instance, or by the desired status of the task with the <code>family</code>, <code>containerInstance</code>, and <code>desiredStatus</code> parameters.</p> <p>Recently stopped tasks might appear in the returned results. Currently, stopped tasks appear in the returned results for at least one hour. </p>
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
  var valid_605680 = query.getOrDefault("nextToken")
  valid_605680 = validateParameter(valid_605680, JString, required = false,
                                 default = nil)
  if valid_605680 != nil:
    section.add "nextToken", valid_605680
  var valid_605681 = query.getOrDefault("maxResults")
  valid_605681 = validateParameter(valid_605681, JString, required = false,
                                 default = nil)
  if valid_605681 != nil:
    section.add "maxResults", valid_605681
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605682 = header.getOrDefault("X-Amz-Target")
  valid_605682 = validateParameter(valid_605682, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTasks"))
  if valid_605682 != nil:
    section.add "X-Amz-Target", valid_605682
  var valid_605683 = header.getOrDefault("X-Amz-Signature")
  valid_605683 = validateParameter(valid_605683, JString, required = false,
                                 default = nil)
  if valid_605683 != nil:
    section.add "X-Amz-Signature", valid_605683
  var valid_605684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605684 = validateParameter(valid_605684, JString, required = false,
                                 default = nil)
  if valid_605684 != nil:
    section.add "X-Amz-Content-Sha256", valid_605684
  var valid_605685 = header.getOrDefault("X-Amz-Date")
  valid_605685 = validateParameter(valid_605685, JString, required = false,
                                 default = nil)
  if valid_605685 != nil:
    section.add "X-Amz-Date", valid_605685
  var valid_605686 = header.getOrDefault("X-Amz-Credential")
  valid_605686 = validateParameter(valid_605686, JString, required = false,
                                 default = nil)
  if valid_605686 != nil:
    section.add "X-Amz-Credential", valid_605686
  var valid_605687 = header.getOrDefault("X-Amz-Security-Token")
  valid_605687 = validateParameter(valid_605687, JString, required = false,
                                 default = nil)
  if valid_605687 != nil:
    section.add "X-Amz-Security-Token", valid_605687
  var valid_605688 = header.getOrDefault("X-Amz-Algorithm")
  valid_605688 = validateParameter(valid_605688, JString, required = false,
                                 default = nil)
  if valid_605688 != nil:
    section.add "X-Amz-Algorithm", valid_605688
  var valid_605689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605689 = validateParameter(valid_605689, JString, required = false,
                                 default = nil)
  if valid_605689 != nil:
    section.add "X-Amz-SignedHeaders", valid_605689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605691: Call_ListTasks_605677; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of tasks for a specified cluster. You can filter the results by family name, by a particular container instance, or by the desired status of the task with the <code>family</code>, <code>containerInstance</code>, and <code>desiredStatus</code> parameters.</p> <p>Recently stopped tasks might appear in the returned results. Currently, stopped tasks appear in the returned results for at least one hour. </p>
  ## 
  let valid = call_605691.validator(path, query, header, formData, body)
  let scheme = call_605691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605691.url(scheme.get, call_605691.host, call_605691.base,
                         call_605691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605691, url, valid)

proc call*(call_605692: Call_ListTasks_605677; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTasks
  ## <p>Returns a list of tasks for a specified cluster. You can filter the results by family name, by a particular container instance, or by the desired status of the task with the <code>family</code>, <code>containerInstance</code>, and <code>desiredStatus</code> parameters.</p> <p>Recently stopped tasks might appear in the returned results. Currently, stopped tasks appear in the returned results for at least one hour. </p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_605693 = newJObject()
  var body_605694 = newJObject()
  add(query_605693, "nextToken", newJString(nextToken))
  if body != nil:
    body_605694 = body
  add(query_605693, "maxResults", newJString(maxResults))
  result = call_605692.call(nil, query_605693, nil, nil, body_605694)

var listTasks* = Call_ListTasks_605677(name: "listTasks", meth: HttpMethod.HttpPost,
                                    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTasks",
                                    validator: validate_ListTasks_605678,
                                    base: "/", url: url_ListTasks_605679,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSetting_605695 = ref object of OpenApiRestCall_604658
proc url_PutAccountSetting_605697(protocol: Scheme; host: string; base: string;
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

proc validate_PutAccountSetting_605696(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Modifies an account setting. Account settings are set on a per-Region basis.</p> <p>If you change the account setting for the root user, the default settings for all of the IAM users and roles for which no individual account setting has been specified are reset. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html">Account Settings</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>serviceLongArnFormat</code>, <code>taskLongArnFormat</code>, or <code>containerInstanceLongArnFormat</code> are specified, the Amazon Resource Name (ARN) and resource ID format of the resource type for a specified IAM user, IAM role, or the root user for an account is affected. The opt-in and opt-out account setting must be set for each Amazon ECS resource separately. The ARN and resource ID format of a resource will be defined by the opt-in status of the IAM user or role that created the resource. You must enable this setting to use Amazon ECS features such as resource tagging.</p> <p>When <code>awsvpcTrunking</code> is specified, the elastic network interface (ENI) limit for any new container instances that support the feature is changed. If <code>awsvpcTrunking</code> is enabled, any new container instances that support the feature are launched have the increased ENI limits available to them. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html">Elastic Network Interface Trunking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>containerInsights</code> is specified, the default setting indicating whether CloudWatch Container Insights is enabled for your clusters is changed. If <code>containerInsights</code> is enabled, any new clusters that are created will have Container Insights enabled unless you disable it during cluster creation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-container-insights.html">CloudWatch Container Insights</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605698 = header.getOrDefault("X-Amz-Target")
  valid_605698 = validateParameter(valid_605698, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutAccountSetting"))
  if valid_605698 != nil:
    section.add "X-Amz-Target", valid_605698
  var valid_605699 = header.getOrDefault("X-Amz-Signature")
  valid_605699 = validateParameter(valid_605699, JString, required = false,
                                 default = nil)
  if valid_605699 != nil:
    section.add "X-Amz-Signature", valid_605699
  var valid_605700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605700 = validateParameter(valid_605700, JString, required = false,
                                 default = nil)
  if valid_605700 != nil:
    section.add "X-Amz-Content-Sha256", valid_605700
  var valid_605701 = header.getOrDefault("X-Amz-Date")
  valid_605701 = validateParameter(valid_605701, JString, required = false,
                                 default = nil)
  if valid_605701 != nil:
    section.add "X-Amz-Date", valid_605701
  var valid_605702 = header.getOrDefault("X-Amz-Credential")
  valid_605702 = validateParameter(valid_605702, JString, required = false,
                                 default = nil)
  if valid_605702 != nil:
    section.add "X-Amz-Credential", valid_605702
  var valid_605703 = header.getOrDefault("X-Amz-Security-Token")
  valid_605703 = validateParameter(valid_605703, JString, required = false,
                                 default = nil)
  if valid_605703 != nil:
    section.add "X-Amz-Security-Token", valid_605703
  var valid_605704 = header.getOrDefault("X-Amz-Algorithm")
  valid_605704 = validateParameter(valid_605704, JString, required = false,
                                 default = nil)
  if valid_605704 != nil:
    section.add "X-Amz-Algorithm", valid_605704
  var valid_605705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605705 = validateParameter(valid_605705, JString, required = false,
                                 default = nil)
  if valid_605705 != nil:
    section.add "X-Amz-SignedHeaders", valid_605705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605707: Call_PutAccountSetting_605695; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies an account setting. Account settings are set on a per-Region basis.</p> <p>If you change the account setting for the root user, the default settings for all of the IAM users and roles for which no individual account setting has been specified are reset. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html">Account Settings</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>serviceLongArnFormat</code>, <code>taskLongArnFormat</code>, or <code>containerInstanceLongArnFormat</code> are specified, the Amazon Resource Name (ARN) and resource ID format of the resource type for a specified IAM user, IAM role, or the root user for an account is affected. The opt-in and opt-out account setting must be set for each Amazon ECS resource separately. The ARN and resource ID format of a resource will be defined by the opt-in status of the IAM user or role that created the resource. You must enable this setting to use Amazon ECS features such as resource tagging.</p> <p>When <code>awsvpcTrunking</code> is specified, the elastic network interface (ENI) limit for any new container instances that support the feature is changed. If <code>awsvpcTrunking</code> is enabled, any new container instances that support the feature are launched have the increased ENI limits available to them. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html">Elastic Network Interface Trunking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>containerInsights</code> is specified, the default setting indicating whether CloudWatch Container Insights is enabled for your clusters is changed. If <code>containerInsights</code> is enabled, any new clusters that are created will have Container Insights enabled unless you disable it during cluster creation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-container-insights.html">CloudWatch Container Insights</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_605707.validator(path, query, header, formData, body)
  let scheme = call_605707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605707.url(scheme.get, call_605707.host, call_605707.base,
                         call_605707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605707, url, valid)

proc call*(call_605708: Call_PutAccountSetting_605695; body: JsonNode): Recallable =
  ## putAccountSetting
  ## <p>Modifies an account setting. Account settings are set on a per-Region basis.</p> <p>If you change the account setting for the root user, the default settings for all of the IAM users and roles for which no individual account setting has been specified are reset. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html">Account Settings</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>serviceLongArnFormat</code>, <code>taskLongArnFormat</code>, or <code>containerInstanceLongArnFormat</code> are specified, the Amazon Resource Name (ARN) and resource ID format of the resource type for a specified IAM user, IAM role, or the root user for an account is affected. The opt-in and opt-out account setting must be set for each Amazon ECS resource separately. The ARN and resource ID format of a resource will be defined by the opt-in status of the IAM user or role that created the resource. You must enable this setting to use Amazon ECS features such as resource tagging.</p> <p>When <code>awsvpcTrunking</code> is specified, the elastic network interface (ENI) limit for any new container instances that support the feature is changed. If <code>awsvpcTrunking</code> is enabled, any new container instances that support the feature are launched have the increased ENI limits available to them. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html">Elastic Network Interface Trunking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>containerInsights</code> is specified, the default setting indicating whether CloudWatch Container Insights is enabled for your clusters is changed. If <code>containerInsights</code> is enabled, any new clusters that are created will have Container Insights enabled unless you disable it during cluster creation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-container-insights.html">CloudWatch Container Insights</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_605709 = newJObject()
  if body != nil:
    body_605709 = body
  result = call_605708.call(nil, nil, nil, nil, body_605709)

var putAccountSetting* = Call_PutAccountSetting_605695(name: "putAccountSetting",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAccountSetting",
    validator: validate_PutAccountSetting_605696, base: "/",
    url: url_PutAccountSetting_605697, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSettingDefault_605710 = ref object of OpenApiRestCall_604658
proc url_PutAccountSettingDefault_605712(protocol: Scheme; host: string;
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

proc validate_PutAccountSettingDefault_605711(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies an account setting for all IAM users on an account for whom no individual account setting has been specified. Account settings are set on a per-Region basis.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605713 = header.getOrDefault("X-Amz-Target")
  valid_605713 = validateParameter(valid_605713, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutAccountSettingDefault"))
  if valid_605713 != nil:
    section.add "X-Amz-Target", valid_605713
  var valid_605714 = header.getOrDefault("X-Amz-Signature")
  valid_605714 = validateParameter(valid_605714, JString, required = false,
                                 default = nil)
  if valid_605714 != nil:
    section.add "X-Amz-Signature", valid_605714
  var valid_605715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605715 = validateParameter(valid_605715, JString, required = false,
                                 default = nil)
  if valid_605715 != nil:
    section.add "X-Amz-Content-Sha256", valid_605715
  var valid_605716 = header.getOrDefault("X-Amz-Date")
  valid_605716 = validateParameter(valid_605716, JString, required = false,
                                 default = nil)
  if valid_605716 != nil:
    section.add "X-Amz-Date", valid_605716
  var valid_605717 = header.getOrDefault("X-Amz-Credential")
  valid_605717 = validateParameter(valid_605717, JString, required = false,
                                 default = nil)
  if valid_605717 != nil:
    section.add "X-Amz-Credential", valid_605717
  var valid_605718 = header.getOrDefault("X-Amz-Security-Token")
  valid_605718 = validateParameter(valid_605718, JString, required = false,
                                 default = nil)
  if valid_605718 != nil:
    section.add "X-Amz-Security-Token", valid_605718
  var valid_605719 = header.getOrDefault("X-Amz-Algorithm")
  valid_605719 = validateParameter(valid_605719, JString, required = false,
                                 default = nil)
  if valid_605719 != nil:
    section.add "X-Amz-Algorithm", valid_605719
  var valid_605720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605720 = validateParameter(valid_605720, JString, required = false,
                                 default = nil)
  if valid_605720 != nil:
    section.add "X-Amz-SignedHeaders", valid_605720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605722: Call_PutAccountSettingDefault_605710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an account setting for all IAM users on an account for whom no individual account setting has been specified. Account settings are set on a per-Region basis.
  ## 
  let valid = call_605722.validator(path, query, header, formData, body)
  let scheme = call_605722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605722.url(scheme.get, call_605722.host, call_605722.base,
                         call_605722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605722, url, valid)

proc call*(call_605723: Call_PutAccountSettingDefault_605710; body: JsonNode): Recallable =
  ## putAccountSettingDefault
  ## Modifies an account setting for all IAM users on an account for whom no individual account setting has been specified. Account settings are set on a per-Region basis.
  ##   body: JObject (required)
  var body_605724 = newJObject()
  if body != nil:
    body_605724 = body
  result = call_605723.call(nil, nil, nil, nil, body_605724)

var putAccountSettingDefault* = Call_PutAccountSettingDefault_605710(
    name: "putAccountSettingDefault", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAccountSettingDefault",
    validator: validate_PutAccountSettingDefault_605711, base: "/",
    url: url_PutAccountSettingDefault_605712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAttributes_605725 = ref object of OpenApiRestCall_604658
proc url_PutAttributes_605727(protocol: Scheme; host: string; base: string;
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

proc validate_PutAttributes_605726(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Create or update an attribute on an Amazon ECS resource. If the attribute does not exist, it is created. If the attribute exists, its value is replaced with the specified value. To delete an attribute, use <a>DeleteAttributes</a>. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#attributes">Attributes</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605728 = header.getOrDefault("X-Amz-Target")
  valid_605728 = validateParameter(valid_605728, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutAttributes"))
  if valid_605728 != nil:
    section.add "X-Amz-Target", valid_605728
  var valid_605729 = header.getOrDefault("X-Amz-Signature")
  valid_605729 = validateParameter(valid_605729, JString, required = false,
                                 default = nil)
  if valid_605729 != nil:
    section.add "X-Amz-Signature", valid_605729
  var valid_605730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605730 = validateParameter(valid_605730, JString, required = false,
                                 default = nil)
  if valid_605730 != nil:
    section.add "X-Amz-Content-Sha256", valid_605730
  var valid_605731 = header.getOrDefault("X-Amz-Date")
  valid_605731 = validateParameter(valid_605731, JString, required = false,
                                 default = nil)
  if valid_605731 != nil:
    section.add "X-Amz-Date", valid_605731
  var valid_605732 = header.getOrDefault("X-Amz-Credential")
  valid_605732 = validateParameter(valid_605732, JString, required = false,
                                 default = nil)
  if valid_605732 != nil:
    section.add "X-Amz-Credential", valid_605732
  var valid_605733 = header.getOrDefault("X-Amz-Security-Token")
  valid_605733 = validateParameter(valid_605733, JString, required = false,
                                 default = nil)
  if valid_605733 != nil:
    section.add "X-Amz-Security-Token", valid_605733
  var valid_605734 = header.getOrDefault("X-Amz-Algorithm")
  valid_605734 = validateParameter(valid_605734, JString, required = false,
                                 default = nil)
  if valid_605734 != nil:
    section.add "X-Amz-Algorithm", valid_605734
  var valid_605735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605735 = validateParameter(valid_605735, JString, required = false,
                                 default = nil)
  if valid_605735 != nil:
    section.add "X-Amz-SignedHeaders", valid_605735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605737: Call_PutAttributes_605725; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update an attribute on an Amazon ECS resource. If the attribute does not exist, it is created. If the attribute exists, its value is replaced with the specified value. To delete an attribute, use <a>DeleteAttributes</a>. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#attributes">Attributes</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_605737.validator(path, query, header, formData, body)
  let scheme = call_605737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605737.url(scheme.get, call_605737.host, call_605737.base,
                         call_605737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605737, url, valid)

proc call*(call_605738: Call_PutAttributes_605725; body: JsonNode): Recallable =
  ## putAttributes
  ## Create or update an attribute on an Amazon ECS resource. If the attribute does not exist, it is created. If the attribute exists, its value is replaced with the specified value. To delete an attribute, use <a>DeleteAttributes</a>. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#attributes">Attributes</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_605739 = newJObject()
  if body != nil:
    body_605739 = body
  result = call_605738.call(nil, nil, nil, nil, body_605739)

var putAttributes* = Call_PutAttributes_605725(name: "putAttributes",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAttributes",
    validator: validate_PutAttributes_605726, base: "/", url: url_PutAttributes_605727,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutClusterCapacityProviders_605740 = ref object of OpenApiRestCall_604658
proc url_PutClusterCapacityProviders_605742(protocol: Scheme; host: string;
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

proc validate_PutClusterCapacityProviders_605741(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the available capacity providers and the default capacity provider strategy for a cluster.</p> <p>You must specify both the available capacity providers and a default capacity provider strategy for the cluster. If the specified cluster has existing capacity providers associated with it, you must specify all existing capacity providers in addition to any new ones you want to add. Any existing capacity providers associated with a cluster that are omitted from a <a>PutClusterCapacityProviders</a> API call will be disassociated with the cluster. You can only disassociate an existing capacity provider from a cluster if it's not being used by any existing tasks.</p> <p>When creating a service or running a task on a cluster, if no capacity provider or launch type is specified, then the cluster's default capacity provider strategy is used. It is recommended to define a default capacity provider strategy for your cluster, however you may specify an empty array (<code>[]</code>) to bypass defining a default strategy.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605743 = header.getOrDefault("X-Amz-Target")
  valid_605743 = validateParameter(valid_605743, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutClusterCapacityProviders"))
  if valid_605743 != nil:
    section.add "X-Amz-Target", valid_605743
  var valid_605744 = header.getOrDefault("X-Amz-Signature")
  valid_605744 = validateParameter(valid_605744, JString, required = false,
                                 default = nil)
  if valid_605744 != nil:
    section.add "X-Amz-Signature", valid_605744
  var valid_605745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605745 = validateParameter(valid_605745, JString, required = false,
                                 default = nil)
  if valid_605745 != nil:
    section.add "X-Amz-Content-Sha256", valid_605745
  var valid_605746 = header.getOrDefault("X-Amz-Date")
  valid_605746 = validateParameter(valid_605746, JString, required = false,
                                 default = nil)
  if valid_605746 != nil:
    section.add "X-Amz-Date", valid_605746
  var valid_605747 = header.getOrDefault("X-Amz-Credential")
  valid_605747 = validateParameter(valid_605747, JString, required = false,
                                 default = nil)
  if valid_605747 != nil:
    section.add "X-Amz-Credential", valid_605747
  var valid_605748 = header.getOrDefault("X-Amz-Security-Token")
  valid_605748 = validateParameter(valid_605748, JString, required = false,
                                 default = nil)
  if valid_605748 != nil:
    section.add "X-Amz-Security-Token", valid_605748
  var valid_605749 = header.getOrDefault("X-Amz-Algorithm")
  valid_605749 = validateParameter(valid_605749, JString, required = false,
                                 default = nil)
  if valid_605749 != nil:
    section.add "X-Amz-Algorithm", valid_605749
  var valid_605750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605750 = validateParameter(valid_605750, JString, required = false,
                                 default = nil)
  if valid_605750 != nil:
    section.add "X-Amz-SignedHeaders", valid_605750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605752: Call_PutClusterCapacityProviders_605740; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the available capacity providers and the default capacity provider strategy for a cluster.</p> <p>You must specify both the available capacity providers and a default capacity provider strategy for the cluster. If the specified cluster has existing capacity providers associated with it, you must specify all existing capacity providers in addition to any new ones you want to add. Any existing capacity providers associated with a cluster that are omitted from a <a>PutClusterCapacityProviders</a> API call will be disassociated with the cluster. You can only disassociate an existing capacity provider from a cluster if it's not being used by any existing tasks.</p> <p>When creating a service or running a task on a cluster, if no capacity provider or launch type is specified, then the cluster's default capacity provider strategy is used. It is recommended to define a default capacity provider strategy for your cluster, however you may specify an empty array (<code>[]</code>) to bypass defining a default strategy.</p>
  ## 
  let valid = call_605752.validator(path, query, header, formData, body)
  let scheme = call_605752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605752.url(scheme.get, call_605752.host, call_605752.base,
                         call_605752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605752, url, valid)

proc call*(call_605753: Call_PutClusterCapacityProviders_605740; body: JsonNode): Recallable =
  ## putClusterCapacityProviders
  ## <p>Modifies the available capacity providers and the default capacity provider strategy for a cluster.</p> <p>You must specify both the available capacity providers and a default capacity provider strategy for the cluster. If the specified cluster has existing capacity providers associated with it, you must specify all existing capacity providers in addition to any new ones you want to add. Any existing capacity providers associated with a cluster that are omitted from a <a>PutClusterCapacityProviders</a> API call will be disassociated with the cluster. You can only disassociate an existing capacity provider from a cluster if it's not being used by any existing tasks.</p> <p>When creating a service or running a task on a cluster, if no capacity provider or launch type is specified, then the cluster's default capacity provider strategy is used. It is recommended to define a default capacity provider strategy for your cluster, however you may specify an empty array (<code>[]</code>) to bypass defining a default strategy.</p>
  ##   body: JObject (required)
  var body_605754 = newJObject()
  if body != nil:
    body_605754 = body
  result = call_605753.call(nil, nil, nil, nil, body_605754)

var putClusterCapacityProviders* = Call_PutClusterCapacityProviders_605740(
    name: "putClusterCapacityProviders", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutClusterCapacityProviders",
    validator: validate_PutClusterCapacityProviders_605741, base: "/",
    url: url_PutClusterCapacityProviders_605742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterContainerInstance_605755 = ref object of OpenApiRestCall_604658
proc url_RegisterContainerInstance_605757(protocol: Scheme; host: string;
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

proc validate_RegisterContainerInstance_605756(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Registers an EC2 instance into the specified cluster. This instance becomes available to place containers on.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605758 = header.getOrDefault("X-Amz-Target")
  valid_605758 = validateParameter(valid_605758, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.RegisterContainerInstance"))
  if valid_605758 != nil:
    section.add "X-Amz-Target", valid_605758
  var valid_605759 = header.getOrDefault("X-Amz-Signature")
  valid_605759 = validateParameter(valid_605759, JString, required = false,
                                 default = nil)
  if valid_605759 != nil:
    section.add "X-Amz-Signature", valid_605759
  var valid_605760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605760 = validateParameter(valid_605760, JString, required = false,
                                 default = nil)
  if valid_605760 != nil:
    section.add "X-Amz-Content-Sha256", valid_605760
  var valid_605761 = header.getOrDefault("X-Amz-Date")
  valid_605761 = validateParameter(valid_605761, JString, required = false,
                                 default = nil)
  if valid_605761 != nil:
    section.add "X-Amz-Date", valid_605761
  var valid_605762 = header.getOrDefault("X-Amz-Credential")
  valid_605762 = validateParameter(valid_605762, JString, required = false,
                                 default = nil)
  if valid_605762 != nil:
    section.add "X-Amz-Credential", valid_605762
  var valid_605763 = header.getOrDefault("X-Amz-Security-Token")
  valid_605763 = validateParameter(valid_605763, JString, required = false,
                                 default = nil)
  if valid_605763 != nil:
    section.add "X-Amz-Security-Token", valid_605763
  var valid_605764 = header.getOrDefault("X-Amz-Algorithm")
  valid_605764 = validateParameter(valid_605764, JString, required = false,
                                 default = nil)
  if valid_605764 != nil:
    section.add "X-Amz-Algorithm", valid_605764
  var valid_605765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605765 = validateParameter(valid_605765, JString, required = false,
                                 default = nil)
  if valid_605765 != nil:
    section.add "X-Amz-SignedHeaders", valid_605765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605767: Call_RegisterContainerInstance_605755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Registers an EC2 instance into the specified cluster. This instance becomes available to place containers on.</p>
  ## 
  let valid = call_605767.validator(path, query, header, formData, body)
  let scheme = call_605767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605767.url(scheme.get, call_605767.host, call_605767.base,
                         call_605767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605767, url, valid)

proc call*(call_605768: Call_RegisterContainerInstance_605755; body: JsonNode): Recallable =
  ## registerContainerInstance
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Registers an EC2 instance into the specified cluster. This instance becomes available to place containers on.</p>
  ##   body: JObject (required)
  var body_605769 = newJObject()
  if body != nil:
    body_605769 = body
  result = call_605768.call(nil, nil, nil, nil, body_605769)

var registerContainerInstance* = Call_RegisterContainerInstance_605755(
    name: "registerContainerInstance", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RegisterContainerInstance",
    validator: validate_RegisterContainerInstance_605756, base: "/",
    url: url_RegisterContainerInstance_605757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskDefinition_605770 = ref object of OpenApiRestCall_604658
proc url_RegisterTaskDefinition_605772(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterTaskDefinition_605771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Registers a new task definition from the supplied <code>family</code> and <code>containerDefinitions</code>. Optionally, you can add data volumes to your containers with the <code>volumes</code> parameter. For more information about task definition parameters and defaults, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_defintions.html">Amazon ECS Task Definitions</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify an IAM role for your task with the <code>taskRoleArn</code> parameter. When you specify an IAM role for a task, its containers can then use the latest versions of the AWS CLI or SDKs to make API requests to the AWS services that are specified in the IAM policy associated with the role. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html">IAM Roles for Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify a Docker networking mode for the containers in your task definition with the <code>networkMode</code> parameter. The available network modes correspond to those described in <a href="https://docs.docker.com/engine/reference/run/#/network-settings">Network settings</a> in the Docker run reference. If you specify the <code>awsvpc</code> network mode, the task is allocated an elastic network interface, and you must specify a <a>NetworkConfiguration</a> when you create a service or run a task with the task definition. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html">Task Networking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605773 = header.getOrDefault("X-Amz-Target")
  valid_605773 = validateParameter(valid_605773, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.RegisterTaskDefinition"))
  if valid_605773 != nil:
    section.add "X-Amz-Target", valid_605773
  var valid_605774 = header.getOrDefault("X-Amz-Signature")
  valid_605774 = validateParameter(valid_605774, JString, required = false,
                                 default = nil)
  if valid_605774 != nil:
    section.add "X-Amz-Signature", valid_605774
  var valid_605775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605775 = validateParameter(valid_605775, JString, required = false,
                                 default = nil)
  if valid_605775 != nil:
    section.add "X-Amz-Content-Sha256", valid_605775
  var valid_605776 = header.getOrDefault("X-Amz-Date")
  valid_605776 = validateParameter(valid_605776, JString, required = false,
                                 default = nil)
  if valid_605776 != nil:
    section.add "X-Amz-Date", valid_605776
  var valid_605777 = header.getOrDefault("X-Amz-Credential")
  valid_605777 = validateParameter(valid_605777, JString, required = false,
                                 default = nil)
  if valid_605777 != nil:
    section.add "X-Amz-Credential", valid_605777
  var valid_605778 = header.getOrDefault("X-Amz-Security-Token")
  valid_605778 = validateParameter(valid_605778, JString, required = false,
                                 default = nil)
  if valid_605778 != nil:
    section.add "X-Amz-Security-Token", valid_605778
  var valid_605779 = header.getOrDefault("X-Amz-Algorithm")
  valid_605779 = validateParameter(valid_605779, JString, required = false,
                                 default = nil)
  if valid_605779 != nil:
    section.add "X-Amz-Algorithm", valid_605779
  var valid_605780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605780 = validateParameter(valid_605780, JString, required = false,
                                 default = nil)
  if valid_605780 != nil:
    section.add "X-Amz-SignedHeaders", valid_605780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605782: Call_RegisterTaskDefinition_605770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a new task definition from the supplied <code>family</code> and <code>containerDefinitions</code>. Optionally, you can add data volumes to your containers with the <code>volumes</code> parameter. For more information about task definition parameters and defaults, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_defintions.html">Amazon ECS Task Definitions</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify an IAM role for your task with the <code>taskRoleArn</code> parameter. When you specify an IAM role for a task, its containers can then use the latest versions of the AWS CLI or SDKs to make API requests to the AWS services that are specified in the IAM policy associated with the role. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html">IAM Roles for Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify a Docker networking mode for the containers in your task definition with the <code>networkMode</code> parameter. The available network modes correspond to those described in <a href="https://docs.docker.com/engine/reference/run/#/network-settings">Network settings</a> in the Docker run reference. If you specify the <code>awsvpc</code> network mode, the task is allocated an elastic network interface, and you must specify a <a>NetworkConfiguration</a> when you create a service or run a task with the task definition. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html">Task Networking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_605782.validator(path, query, header, formData, body)
  let scheme = call_605782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605782.url(scheme.get, call_605782.host, call_605782.base,
                         call_605782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605782, url, valid)

proc call*(call_605783: Call_RegisterTaskDefinition_605770; body: JsonNode): Recallable =
  ## registerTaskDefinition
  ## <p>Registers a new task definition from the supplied <code>family</code> and <code>containerDefinitions</code>. Optionally, you can add data volumes to your containers with the <code>volumes</code> parameter. For more information about task definition parameters and defaults, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_defintions.html">Amazon ECS Task Definitions</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify an IAM role for your task with the <code>taskRoleArn</code> parameter. When you specify an IAM role for a task, its containers can then use the latest versions of the AWS CLI or SDKs to make API requests to the AWS services that are specified in the IAM policy associated with the role. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html">IAM Roles for Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify a Docker networking mode for the containers in your task definition with the <code>networkMode</code> parameter. The available network modes correspond to those described in <a href="https://docs.docker.com/engine/reference/run/#/network-settings">Network settings</a> in the Docker run reference. If you specify the <code>awsvpc</code> network mode, the task is allocated an elastic network interface, and you must specify a <a>NetworkConfiguration</a> when you create a service or run a task with the task definition. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html">Task Networking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_605784 = newJObject()
  if body != nil:
    body_605784 = body
  result = call_605783.call(nil, nil, nil, nil, body_605784)

var registerTaskDefinition* = Call_RegisterTaskDefinition_605770(
    name: "registerTaskDefinition", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RegisterTaskDefinition",
    validator: validate_RegisterTaskDefinition_605771, base: "/",
    url: url_RegisterTaskDefinition_605772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RunTask_605785 = ref object of OpenApiRestCall_604658
proc url_RunTask_605787(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_RunTask_605786(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts a new task using the specified task definition.</p> <p>You can allow Amazon ECS to place tasks for you, or you can customize how Amazon ECS places tasks using placement constraints and placement strategies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Alternatively, you can use <a>StartTask</a> to use your own scheduler or place tasks manually on specific container instances.</p> <p>The Amazon ECS API follows an eventual consistency model, due to the distributed nature of the system supporting the API. This means that the result of an API command you run that affects your Amazon ECS resources might not be immediately visible to all subsequent commands you run. Keep this in mind when you carry out an API command that immediately follows a previous API command.</p> <p>To manage eventual consistency, you can do the following:</p> <ul> <li> <p>Confirm the state of the resource before you run a command to modify it. Run the DescribeTasks command using an exponential backoff algorithm to ensure that you allow enough time for the previous command to propagate through the system. To do this, run the DescribeTasks command repeatedly, starting with a couple of seconds of wait time and increasing gradually up to five minutes of wait time.</p> </li> <li> <p>Add wait time between subsequent commands, even if the DescribeTasks command returns an accurate response. Apply an exponential backoff algorithm starting with a couple of seconds of wait time, and increase gradually up to about five minutes of wait time.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605788 = header.getOrDefault("X-Amz-Target")
  valid_605788 = validateParameter(valid_605788, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.RunTask"))
  if valid_605788 != nil:
    section.add "X-Amz-Target", valid_605788
  var valid_605789 = header.getOrDefault("X-Amz-Signature")
  valid_605789 = validateParameter(valid_605789, JString, required = false,
                                 default = nil)
  if valid_605789 != nil:
    section.add "X-Amz-Signature", valid_605789
  var valid_605790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605790 = validateParameter(valid_605790, JString, required = false,
                                 default = nil)
  if valid_605790 != nil:
    section.add "X-Amz-Content-Sha256", valid_605790
  var valid_605791 = header.getOrDefault("X-Amz-Date")
  valid_605791 = validateParameter(valid_605791, JString, required = false,
                                 default = nil)
  if valid_605791 != nil:
    section.add "X-Amz-Date", valid_605791
  var valid_605792 = header.getOrDefault("X-Amz-Credential")
  valid_605792 = validateParameter(valid_605792, JString, required = false,
                                 default = nil)
  if valid_605792 != nil:
    section.add "X-Amz-Credential", valid_605792
  var valid_605793 = header.getOrDefault("X-Amz-Security-Token")
  valid_605793 = validateParameter(valid_605793, JString, required = false,
                                 default = nil)
  if valid_605793 != nil:
    section.add "X-Amz-Security-Token", valid_605793
  var valid_605794 = header.getOrDefault("X-Amz-Algorithm")
  valid_605794 = validateParameter(valid_605794, JString, required = false,
                                 default = nil)
  if valid_605794 != nil:
    section.add "X-Amz-Algorithm", valid_605794
  var valid_605795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605795 = validateParameter(valid_605795, JString, required = false,
                                 default = nil)
  if valid_605795 != nil:
    section.add "X-Amz-SignedHeaders", valid_605795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605797: Call_RunTask_605785; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a new task using the specified task definition.</p> <p>You can allow Amazon ECS to place tasks for you, or you can customize how Amazon ECS places tasks using placement constraints and placement strategies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Alternatively, you can use <a>StartTask</a> to use your own scheduler or place tasks manually on specific container instances.</p> <p>The Amazon ECS API follows an eventual consistency model, due to the distributed nature of the system supporting the API. This means that the result of an API command you run that affects your Amazon ECS resources might not be immediately visible to all subsequent commands you run. Keep this in mind when you carry out an API command that immediately follows a previous API command.</p> <p>To manage eventual consistency, you can do the following:</p> <ul> <li> <p>Confirm the state of the resource before you run a command to modify it. Run the DescribeTasks command using an exponential backoff algorithm to ensure that you allow enough time for the previous command to propagate through the system. To do this, run the DescribeTasks command repeatedly, starting with a couple of seconds of wait time and increasing gradually up to five minutes of wait time.</p> </li> <li> <p>Add wait time between subsequent commands, even if the DescribeTasks command returns an accurate response. Apply an exponential backoff algorithm starting with a couple of seconds of wait time, and increase gradually up to about five minutes of wait time.</p> </li> </ul>
  ## 
  let valid = call_605797.validator(path, query, header, formData, body)
  let scheme = call_605797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605797.url(scheme.get, call_605797.host, call_605797.base,
                         call_605797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605797, url, valid)

proc call*(call_605798: Call_RunTask_605785; body: JsonNode): Recallable =
  ## runTask
  ## <p>Starts a new task using the specified task definition.</p> <p>You can allow Amazon ECS to place tasks for you, or you can customize how Amazon ECS places tasks using placement constraints and placement strategies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Alternatively, you can use <a>StartTask</a> to use your own scheduler or place tasks manually on specific container instances.</p> <p>The Amazon ECS API follows an eventual consistency model, due to the distributed nature of the system supporting the API. This means that the result of an API command you run that affects your Amazon ECS resources might not be immediately visible to all subsequent commands you run. Keep this in mind when you carry out an API command that immediately follows a previous API command.</p> <p>To manage eventual consistency, you can do the following:</p> <ul> <li> <p>Confirm the state of the resource before you run a command to modify it. Run the DescribeTasks command using an exponential backoff algorithm to ensure that you allow enough time for the previous command to propagate through the system. To do this, run the DescribeTasks command repeatedly, starting with a couple of seconds of wait time and increasing gradually up to five minutes of wait time.</p> </li> <li> <p>Add wait time between subsequent commands, even if the DescribeTasks command returns an accurate response. Apply an exponential backoff algorithm starting with a couple of seconds of wait time, and increase gradually up to about five minutes of wait time.</p> </li> </ul>
  ##   body: JObject (required)
  var body_605799 = newJObject()
  if body != nil:
    body_605799 = body
  result = call_605798.call(nil, nil, nil, nil, body_605799)

var runTask* = Call_RunTask_605785(name: "runTask", meth: HttpMethod.HttpPost,
                                host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RunTask",
                                validator: validate_RunTask_605786, base: "/",
                                url: url_RunTask_605787,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTask_605800 = ref object of OpenApiRestCall_604658
proc url_StartTask_605802(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StartTask_605801(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts a new task from the specified task definition on the specified container instance or instances.</p> <p>Alternatively, you can use <a>RunTask</a> to place tasks for you. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605803 = header.getOrDefault("X-Amz-Target")
  valid_605803 = validateParameter(valid_605803, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.StartTask"))
  if valid_605803 != nil:
    section.add "X-Amz-Target", valid_605803
  var valid_605804 = header.getOrDefault("X-Amz-Signature")
  valid_605804 = validateParameter(valid_605804, JString, required = false,
                                 default = nil)
  if valid_605804 != nil:
    section.add "X-Amz-Signature", valid_605804
  var valid_605805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605805 = validateParameter(valid_605805, JString, required = false,
                                 default = nil)
  if valid_605805 != nil:
    section.add "X-Amz-Content-Sha256", valid_605805
  var valid_605806 = header.getOrDefault("X-Amz-Date")
  valid_605806 = validateParameter(valid_605806, JString, required = false,
                                 default = nil)
  if valid_605806 != nil:
    section.add "X-Amz-Date", valid_605806
  var valid_605807 = header.getOrDefault("X-Amz-Credential")
  valid_605807 = validateParameter(valid_605807, JString, required = false,
                                 default = nil)
  if valid_605807 != nil:
    section.add "X-Amz-Credential", valid_605807
  var valid_605808 = header.getOrDefault("X-Amz-Security-Token")
  valid_605808 = validateParameter(valid_605808, JString, required = false,
                                 default = nil)
  if valid_605808 != nil:
    section.add "X-Amz-Security-Token", valid_605808
  var valid_605809 = header.getOrDefault("X-Amz-Algorithm")
  valid_605809 = validateParameter(valid_605809, JString, required = false,
                                 default = nil)
  if valid_605809 != nil:
    section.add "X-Amz-Algorithm", valid_605809
  var valid_605810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605810 = validateParameter(valid_605810, JString, required = false,
                                 default = nil)
  if valid_605810 != nil:
    section.add "X-Amz-SignedHeaders", valid_605810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605812: Call_StartTask_605800; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a new task from the specified task definition on the specified container instance or instances.</p> <p>Alternatively, you can use <a>RunTask</a> to place tasks for you. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_605812.validator(path, query, header, formData, body)
  let scheme = call_605812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605812.url(scheme.get, call_605812.host, call_605812.base,
                         call_605812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605812, url, valid)

proc call*(call_605813: Call_StartTask_605800; body: JsonNode): Recallable =
  ## startTask
  ## <p>Starts a new task from the specified task definition on the specified container instance or instances.</p> <p>Alternatively, you can use <a>RunTask</a> to place tasks for you. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_605814 = newJObject()
  if body != nil:
    body_605814 = body
  result = call_605813.call(nil, nil, nil, nil, body_605814)

var startTask* = Call_StartTask_605800(name: "startTask", meth: HttpMethod.HttpPost,
                                    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.StartTask",
                                    validator: validate_StartTask_605801,
                                    base: "/", url: url_StartTask_605802,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTask_605815 = ref object of OpenApiRestCall_604658
proc url_StopTask_605817(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopTask_605816(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Stops a running task. Any tags associated with the task will be deleted.</p> <p>When <a>StopTask</a> is called on a task, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> value and a default 30-second timeout, after which the <code>SIGKILL</code> value is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> value gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> value is sent.</p> <note> <p>The default 30-second timeout can be configured on the Amazon ECS container agent with the <code>ECS_CONTAINER_STOP_TIMEOUT</code> variable. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html">Amazon ECS Container Agent Configuration</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605818 = header.getOrDefault("X-Amz-Target")
  valid_605818 = validateParameter(valid_605818, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.StopTask"))
  if valid_605818 != nil:
    section.add "X-Amz-Target", valid_605818
  var valid_605819 = header.getOrDefault("X-Amz-Signature")
  valid_605819 = validateParameter(valid_605819, JString, required = false,
                                 default = nil)
  if valid_605819 != nil:
    section.add "X-Amz-Signature", valid_605819
  var valid_605820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605820 = validateParameter(valid_605820, JString, required = false,
                                 default = nil)
  if valid_605820 != nil:
    section.add "X-Amz-Content-Sha256", valid_605820
  var valid_605821 = header.getOrDefault("X-Amz-Date")
  valid_605821 = validateParameter(valid_605821, JString, required = false,
                                 default = nil)
  if valid_605821 != nil:
    section.add "X-Amz-Date", valid_605821
  var valid_605822 = header.getOrDefault("X-Amz-Credential")
  valid_605822 = validateParameter(valid_605822, JString, required = false,
                                 default = nil)
  if valid_605822 != nil:
    section.add "X-Amz-Credential", valid_605822
  var valid_605823 = header.getOrDefault("X-Amz-Security-Token")
  valid_605823 = validateParameter(valid_605823, JString, required = false,
                                 default = nil)
  if valid_605823 != nil:
    section.add "X-Amz-Security-Token", valid_605823
  var valid_605824 = header.getOrDefault("X-Amz-Algorithm")
  valid_605824 = validateParameter(valid_605824, JString, required = false,
                                 default = nil)
  if valid_605824 != nil:
    section.add "X-Amz-Algorithm", valid_605824
  var valid_605825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605825 = validateParameter(valid_605825, JString, required = false,
                                 default = nil)
  if valid_605825 != nil:
    section.add "X-Amz-SignedHeaders", valid_605825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605827: Call_StopTask_605815; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a running task. Any tags associated with the task will be deleted.</p> <p>When <a>StopTask</a> is called on a task, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> value and a default 30-second timeout, after which the <code>SIGKILL</code> value is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> value gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> value is sent.</p> <note> <p>The default 30-second timeout can be configured on the Amazon ECS container agent with the <code>ECS_CONTAINER_STOP_TIMEOUT</code> variable. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html">Amazon ECS Container Agent Configuration</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_605827.validator(path, query, header, formData, body)
  let scheme = call_605827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605827.url(scheme.get, call_605827.host, call_605827.base,
                         call_605827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605827, url, valid)

proc call*(call_605828: Call_StopTask_605815; body: JsonNode): Recallable =
  ## stopTask
  ## <p>Stops a running task. Any tags associated with the task will be deleted.</p> <p>When <a>StopTask</a> is called on a task, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> value and a default 30-second timeout, after which the <code>SIGKILL</code> value is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> value gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> value is sent.</p> <note> <p>The default 30-second timeout can be configured on the Amazon ECS container agent with the <code>ECS_CONTAINER_STOP_TIMEOUT</code> variable. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html">Amazon ECS Container Agent Configuration</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_605829 = newJObject()
  if body != nil:
    body_605829 = body
  result = call_605828.call(nil, nil, nil, nil, body_605829)

var stopTask* = Call_StopTask_605815(name: "stopTask", meth: HttpMethod.HttpPost,
                                  host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.StopTask",
                                  validator: validate_StopTask_605816, base: "/",
                                  url: url_StopTask_605817,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitAttachmentStateChanges_605830 = ref object of OpenApiRestCall_604658
proc url_SubmitAttachmentStateChanges_605832(protocol: Scheme; host: string;
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

proc validate_SubmitAttachmentStateChanges_605831(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that an attachment changed states.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605833 = header.getOrDefault("X-Amz-Target")
  valid_605833 = validateParameter(valid_605833, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.SubmitAttachmentStateChanges"))
  if valid_605833 != nil:
    section.add "X-Amz-Target", valid_605833
  var valid_605834 = header.getOrDefault("X-Amz-Signature")
  valid_605834 = validateParameter(valid_605834, JString, required = false,
                                 default = nil)
  if valid_605834 != nil:
    section.add "X-Amz-Signature", valid_605834
  var valid_605835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605835 = validateParameter(valid_605835, JString, required = false,
                                 default = nil)
  if valid_605835 != nil:
    section.add "X-Amz-Content-Sha256", valid_605835
  var valid_605836 = header.getOrDefault("X-Amz-Date")
  valid_605836 = validateParameter(valid_605836, JString, required = false,
                                 default = nil)
  if valid_605836 != nil:
    section.add "X-Amz-Date", valid_605836
  var valid_605837 = header.getOrDefault("X-Amz-Credential")
  valid_605837 = validateParameter(valid_605837, JString, required = false,
                                 default = nil)
  if valid_605837 != nil:
    section.add "X-Amz-Credential", valid_605837
  var valid_605838 = header.getOrDefault("X-Amz-Security-Token")
  valid_605838 = validateParameter(valid_605838, JString, required = false,
                                 default = nil)
  if valid_605838 != nil:
    section.add "X-Amz-Security-Token", valid_605838
  var valid_605839 = header.getOrDefault("X-Amz-Algorithm")
  valid_605839 = validateParameter(valid_605839, JString, required = false,
                                 default = nil)
  if valid_605839 != nil:
    section.add "X-Amz-Algorithm", valid_605839
  var valid_605840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605840 = validateParameter(valid_605840, JString, required = false,
                                 default = nil)
  if valid_605840 != nil:
    section.add "X-Amz-SignedHeaders", valid_605840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605842: Call_SubmitAttachmentStateChanges_605830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that an attachment changed states.</p>
  ## 
  let valid = call_605842.validator(path, query, header, formData, body)
  let scheme = call_605842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605842.url(scheme.get, call_605842.host, call_605842.base,
                         call_605842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605842, url, valid)

proc call*(call_605843: Call_SubmitAttachmentStateChanges_605830; body: JsonNode): Recallable =
  ## submitAttachmentStateChanges
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that an attachment changed states.</p>
  ##   body: JObject (required)
  var body_605844 = newJObject()
  if body != nil:
    body_605844 = body
  result = call_605843.call(nil, nil, nil, nil, body_605844)

var submitAttachmentStateChanges* = Call_SubmitAttachmentStateChanges_605830(
    name: "submitAttachmentStateChanges", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitAttachmentStateChanges",
    validator: validate_SubmitAttachmentStateChanges_605831, base: "/",
    url: url_SubmitAttachmentStateChanges_605832,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitContainerStateChange_605845 = ref object of OpenApiRestCall_604658
proc url_SubmitContainerStateChange_605847(protocol: Scheme; host: string;
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

proc validate_SubmitContainerStateChange_605846(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a container changed states.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605848 = header.getOrDefault("X-Amz-Target")
  valid_605848 = validateParameter(valid_605848, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.SubmitContainerStateChange"))
  if valid_605848 != nil:
    section.add "X-Amz-Target", valid_605848
  var valid_605849 = header.getOrDefault("X-Amz-Signature")
  valid_605849 = validateParameter(valid_605849, JString, required = false,
                                 default = nil)
  if valid_605849 != nil:
    section.add "X-Amz-Signature", valid_605849
  var valid_605850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605850 = validateParameter(valid_605850, JString, required = false,
                                 default = nil)
  if valid_605850 != nil:
    section.add "X-Amz-Content-Sha256", valid_605850
  var valid_605851 = header.getOrDefault("X-Amz-Date")
  valid_605851 = validateParameter(valid_605851, JString, required = false,
                                 default = nil)
  if valid_605851 != nil:
    section.add "X-Amz-Date", valid_605851
  var valid_605852 = header.getOrDefault("X-Amz-Credential")
  valid_605852 = validateParameter(valid_605852, JString, required = false,
                                 default = nil)
  if valid_605852 != nil:
    section.add "X-Amz-Credential", valid_605852
  var valid_605853 = header.getOrDefault("X-Amz-Security-Token")
  valid_605853 = validateParameter(valid_605853, JString, required = false,
                                 default = nil)
  if valid_605853 != nil:
    section.add "X-Amz-Security-Token", valid_605853
  var valid_605854 = header.getOrDefault("X-Amz-Algorithm")
  valid_605854 = validateParameter(valid_605854, JString, required = false,
                                 default = nil)
  if valid_605854 != nil:
    section.add "X-Amz-Algorithm", valid_605854
  var valid_605855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605855 = validateParameter(valid_605855, JString, required = false,
                                 default = nil)
  if valid_605855 != nil:
    section.add "X-Amz-SignedHeaders", valid_605855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605857: Call_SubmitContainerStateChange_605845; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a container changed states.</p>
  ## 
  let valid = call_605857.validator(path, query, header, formData, body)
  let scheme = call_605857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605857.url(scheme.get, call_605857.host, call_605857.base,
                         call_605857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605857, url, valid)

proc call*(call_605858: Call_SubmitContainerStateChange_605845; body: JsonNode): Recallable =
  ## submitContainerStateChange
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a container changed states.</p>
  ##   body: JObject (required)
  var body_605859 = newJObject()
  if body != nil:
    body_605859 = body
  result = call_605858.call(nil, nil, nil, nil, body_605859)

var submitContainerStateChange* = Call_SubmitContainerStateChange_605845(
    name: "submitContainerStateChange", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitContainerStateChange",
    validator: validate_SubmitContainerStateChange_605846, base: "/",
    url: url_SubmitContainerStateChange_605847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitTaskStateChange_605860 = ref object of OpenApiRestCall_604658
proc url_SubmitTaskStateChange_605862(protocol: Scheme; host: string; base: string;
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

proc validate_SubmitTaskStateChange_605861(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a task changed states.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605863 = header.getOrDefault("X-Amz-Target")
  valid_605863 = validateParameter(valid_605863, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.SubmitTaskStateChange"))
  if valid_605863 != nil:
    section.add "X-Amz-Target", valid_605863
  var valid_605864 = header.getOrDefault("X-Amz-Signature")
  valid_605864 = validateParameter(valid_605864, JString, required = false,
                                 default = nil)
  if valid_605864 != nil:
    section.add "X-Amz-Signature", valid_605864
  var valid_605865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605865 = validateParameter(valid_605865, JString, required = false,
                                 default = nil)
  if valid_605865 != nil:
    section.add "X-Amz-Content-Sha256", valid_605865
  var valid_605866 = header.getOrDefault("X-Amz-Date")
  valid_605866 = validateParameter(valid_605866, JString, required = false,
                                 default = nil)
  if valid_605866 != nil:
    section.add "X-Amz-Date", valid_605866
  var valid_605867 = header.getOrDefault("X-Amz-Credential")
  valid_605867 = validateParameter(valid_605867, JString, required = false,
                                 default = nil)
  if valid_605867 != nil:
    section.add "X-Amz-Credential", valid_605867
  var valid_605868 = header.getOrDefault("X-Amz-Security-Token")
  valid_605868 = validateParameter(valid_605868, JString, required = false,
                                 default = nil)
  if valid_605868 != nil:
    section.add "X-Amz-Security-Token", valid_605868
  var valid_605869 = header.getOrDefault("X-Amz-Algorithm")
  valid_605869 = validateParameter(valid_605869, JString, required = false,
                                 default = nil)
  if valid_605869 != nil:
    section.add "X-Amz-Algorithm", valid_605869
  var valid_605870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605870 = validateParameter(valid_605870, JString, required = false,
                                 default = nil)
  if valid_605870 != nil:
    section.add "X-Amz-SignedHeaders", valid_605870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605872: Call_SubmitTaskStateChange_605860; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a task changed states.</p>
  ## 
  let valid = call_605872.validator(path, query, header, formData, body)
  let scheme = call_605872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605872.url(scheme.get, call_605872.host, call_605872.base,
                         call_605872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605872, url, valid)

proc call*(call_605873: Call_SubmitTaskStateChange_605860; body: JsonNode): Recallable =
  ## submitTaskStateChange
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a task changed states.</p>
  ##   body: JObject (required)
  var body_605874 = newJObject()
  if body != nil:
    body_605874 = body
  result = call_605873.call(nil, nil, nil, nil, body_605874)

var submitTaskStateChange* = Call_SubmitTaskStateChange_605860(
    name: "submitTaskStateChange", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitTaskStateChange",
    validator: validate_SubmitTaskStateChange_605861, base: "/",
    url: url_SubmitTaskStateChange_605862, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_605875 = ref object of OpenApiRestCall_604658
proc url_TagResource_605877(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_605876(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605878 = header.getOrDefault("X-Amz-Target")
  valid_605878 = validateParameter(valid_605878, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.TagResource"))
  if valid_605878 != nil:
    section.add "X-Amz-Target", valid_605878
  var valid_605879 = header.getOrDefault("X-Amz-Signature")
  valid_605879 = validateParameter(valid_605879, JString, required = false,
                                 default = nil)
  if valid_605879 != nil:
    section.add "X-Amz-Signature", valid_605879
  var valid_605880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605880 = validateParameter(valid_605880, JString, required = false,
                                 default = nil)
  if valid_605880 != nil:
    section.add "X-Amz-Content-Sha256", valid_605880
  var valid_605881 = header.getOrDefault("X-Amz-Date")
  valid_605881 = validateParameter(valid_605881, JString, required = false,
                                 default = nil)
  if valid_605881 != nil:
    section.add "X-Amz-Date", valid_605881
  var valid_605882 = header.getOrDefault("X-Amz-Credential")
  valid_605882 = validateParameter(valid_605882, JString, required = false,
                                 default = nil)
  if valid_605882 != nil:
    section.add "X-Amz-Credential", valid_605882
  var valid_605883 = header.getOrDefault("X-Amz-Security-Token")
  valid_605883 = validateParameter(valid_605883, JString, required = false,
                                 default = nil)
  if valid_605883 != nil:
    section.add "X-Amz-Security-Token", valid_605883
  var valid_605884 = header.getOrDefault("X-Amz-Algorithm")
  valid_605884 = validateParameter(valid_605884, JString, required = false,
                                 default = nil)
  if valid_605884 != nil:
    section.add "X-Amz-Algorithm", valid_605884
  var valid_605885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605885 = validateParameter(valid_605885, JString, required = false,
                                 default = nil)
  if valid_605885 != nil:
    section.add "X-Amz-SignedHeaders", valid_605885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605887: Call_TagResource_605875; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_605887.validator(path, query, header, formData, body)
  let scheme = call_605887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605887.url(scheme.get, call_605887.host, call_605887.base,
                         call_605887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605887, url, valid)

proc call*(call_605888: Call_TagResource_605875; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  var body_605889 = newJObject()
  if body != nil:
    body_605889 = body
  result = call_605888.call(nil, nil, nil, nil, body_605889)

var tagResource* = Call_TagResource_605875(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.TagResource",
                                        validator: validate_TagResource_605876,
                                        base: "/", url: url_TagResource_605877,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_605890 = ref object of OpenApiRestCall_604658
proc url_UntagResource_605892(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_605891(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes specified tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605893 = header.getOrDefault("X-Amz-Target")
  valid_605893 = validateParameter(valid_605893, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UntagResource"))
  if valid_605893 != nil:
    section.add "X-Amz-Target", valid_605893
  var valid_605894 = header.getOrDefault("X-Amz-Signature")
  valid_605894 = validateParameter(valid_605894, JString, required = false,
                                 default = nil)
  if valid_605894 != nil:
    section.add "X-Amz-Signature", valid_605894
  var valid_605895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605895 = validateParameter(valid_605895, JString, required = false,
                                 default = nil)
  if valid_605895 != nil:
    section.add "X-Amz-Content-Sha256", valid_605895
  var valid_605896 = header.getOrDefault("X-Amz-Date")
  valid_605896 = validateParameter(valid_605896, JString, required = false,
                                 default = nil)
  if valid_605896 != nil:
    section.add "X-Amz-Date", valid_605896
  var valid_605897 = header.getOrDefault("X-Amz-Credential")
  valid_605897 = validateParameter(valid_605897, JString, required = false,
                                 default = nil)
  if valid_605897 != nil:
    section.add "X-Amz-Credential", valid_605897
  var valid_605898 = header.getOrDefault("X-Amz-Security-Token")
  valid_605898 = validateParameter(valid_605898, JString, required = false,
                                 default = nil)
  if valid_605898 != nil:
    section.add "X-Amz-Security-Token", valid_605898
  var valid_605899 = header.getOrDefault("X-Amz-Algorithm")
  valid_605899 = validateParameter(valid_605899, JString, required = false,
                                 default = nil)
  if valid_605899 != nil:
    section.add "X-Amz-Algorithm", valid_605899
  var valid_605900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605900 = validateParameter(valid_605900, JString, required = false,
                                 default = nil)
  if valid_605900 != nil:
    section.add "X-Amz-SignedHeaders", valid_605900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605902: Call_UntagResource_605890; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_605902.validator(path, query, header, formData, body)
  let scheme = call_605902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605902.url(scheme.get, call_605902.host, call_605902.base,
                         call_605902.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605902, url, valid)

proc call*(call_605903: Call_UntagResource_605890; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  var body_605904 = newJObject()
  if body != nil:
    body_605904 = body
  result = call_605903.call(nil, nil, nil, nil, body_605904)

var untagResource* = Call_UntagResource_605890(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UntagResource",
    validator: validate_UntagResource_605891, base: "/", url: url_UntagResource_605892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterSettings_605905 = ref object of OpenApiRestCall_604658
proc url_UpdateClusterSettings_605907(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClusterSettings_605906(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies the settings to use for a cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605908 = header.getOrDefault("X-Amz-Target")
  valid_605908 = validateParameter(valid_605908, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateClusterSettings"))
  if valid_605908 != nil:
    section.add "X-Amz-Target", valid_605908
  var valid_605909 = header.getOrDefault("X-Amz-Signature")
  valid_605909 = validateParameter(valid_605909, JString, required = false,
                                 default = nil)
  if valid_605909 != nil:
    section.add "X-Amz-Signature", valid_605909
  var valid_605910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605910 = validateParameter(valid_605910, JString, required = false,
                                 default = nil)
  if valid_605910 != nil:
    section.add "X-Amz-Content-Sha256", valid_605910
  var valid_605911 = header.getOrDefault("X-Amz-Date")
  valid_605911 = validateParameter(valid_605911, JString, required = false,
                                 default = nil)
  if valid_605911 != nil:
    section.add "X-Amz-Date", valid_605911
  var valid_605912 = header.getOrDefault("X-Amz-Credential")
  valid_605912 = validateParameter(valid_605912, JString, required = false,
                                 default = nil)
  if valid_605912 != nil:
    section.add "X-Amz-Credential", valid_605912
  var valid_605913 = header.getOrDefault("X-Amz-Security-Token")
  valid_605913 = validateParameter(valid_605913, JString, required = false,
                                 default = nil)
  if valid_605913 != nil:
    section.add "X-Amz-Security-Token", valid_605913
  var valid_605914 = header.getOrDefault("X-Amz-Algorithm")
  valid_605914 = validateParameter(valid_605914, JString, required = false,
                                 default = nil)
  if valid_605914 != nil:
    section.add "X-Amz-Algorithm", valid_605914
  var valid_605915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605915 = validateParameter(valid_605915, JString, required = false,
                                 default = nil)
  if valid_605915 != nil:
    section.add "X-Amz-SignedHeaders", valid_605915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605917: Call_UpdateClusterSettings_605905; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the settings to use for a cluster.
  ## 
  let valid = call_605917.validator(path, query, header, formData, body)
  let scheme = call_605917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605917.url(scheme.get, call_605917.host, call_605917.base,
                         call_605917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605917, url, valid)

proc call*(call_605918: Call_UpdateClusterSettings_605905; body: JsonNode): Recallable =
  ## updateClusterSettings
  ## Modifies the settings to use for a cluster.
  ##   body: JObject (required)
  var body_605919 = newJObject()
  if body != nil:
    body_605919 = body
  result = call_605918.call(nil, nil, nil, nil, body_605919)

var updateClusterSettings* = Call_UpdateClusterSettings_605905(
    name: "updateClusterSettings", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateClusterSettings",
    validator: validate_UpdateClusterSettings_605906, base: "/",
    url: url_UpdateClusterSettings_605907, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContainerAgent_605920 = ref object of OpenApiRestCall_604658
proc url_UpdateContainerAgent_605922(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateContainerAgent_605921(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the Amazon ECS container agent on a specified container instance. Updating the Amazon ECS container agent does not interrupt running tasks or services on the container instance. The process for updating the agent differs depending on whether your container instance was launched with the Amazon ECS-optimized AMI or another operating system.</p> <p> <code>UpdateContainerAgent</code> requires the Amazon ECS-optimized AMI or Amazon Linux with the <code>ecs-init</code> service installed and running. For help updating the Amazon ECS container agent on other operating systems, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-update.html#manually_update_agent">Manually Updating the Amazon ECS Container Agent</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605923 = header.getOrDefault("X-Amz-Target")
  valid_605923 = validateParameter(valid_605923, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateContainerAgent"))
  if valid_605923 != nil:
    section.add "X-Amz-Target", valid_605923
  var valid_605924 = header.getOrDefault("X-Amz-Signature")
  valid_605924 = validateParameter(valid_605924, JString, required = false,
                                 default = nil)
  if valid_605924 != nil:
    section.add "X-Amz-Signature", valid_605924
  var valid_605925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605925 = validateParameter(valid_605925, JString, required = false,
                                 default = nil)
  if valid_605925 != nil:
    section.add "X-Amz-Content-Sha256", valid_605925
  var valid_605926 = header.getOrDefault("X-Amz-Date")
  valid_605926 = validateParameter(valid_605926, JString, required = false,
                                 default = nil)
  if valid_605926 != nil:
    section.add "X-Amz-Date", valid_605926
  var valid_605927 = header.getOrDefault("X-Amz-Credential")
  valid_605927 = validateParameter(valid_605927, JString, required = false,
                                 default = nil)
  if valid_605927 != nil:
    section.add "X-Amz-Credential", valid_605927
  var valid_605928 = header.getOrDefault("X-Amz-Security-Token")
  valid_605928 = validateParameter(valid_605928, JString, required = false,
                                 default = nil)
  if valid_605928 != nil:
    section.add "X-Amz-Security-Token", valid_605928
  var valid_605929 = header.getOrDefault("X-Amz-Algorithm")
  valid_605929 = validateParameter(valid_605929, JString, required = false,
                                 default = nil)
  if valid_605929 != nil:
    section.add "X-Amz-Algorithm", valid_605929
  var valid_605930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605930 = validateParameter(valid_605930, JString, required = false,
                                 default = nil)
  if valid_605930 != nil:
    section.add "X-Amz-SignedHeaders", valid_605930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605932: Call_UpdateContainerAgent_605920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Amazon ECS container agent on a specified container instance. Updating the Amazon ECS container agent does not interrupt running tasks or services on the container instance. The process for updating the agent differs depending on whether your container instance was launched with the Amazon ECS-optimized AMI or another operating system.</p> <p> <code>UpdateContainerAgent</code> requires the Amazon ECS-optimized AMI or Amazon Linux with the <code>ecs-init</code> service installed and running. For help updating the Amazon ECS container agent on other operating systems, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-update.html#manually_update_agent">Manually Updating the Amazon ECS Container Agent</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_605932.validator(path, query, header, formData, body)
  let scheme = call_605932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605932.url(scheme.get, call_605932.host, call_605932.base,
                         call_605932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605932, url, valid)

proc call*(call_605933: Call_UpdateContainerAgent_605920; body: JsonNode): Recallable =
  ## updateContainerAgent
  ## <p>Updates the Amazon ECS container agent on a specified container instance. Updating the Amazon ECS container agent does not interrupt running tasks or services on the container instance. The process for updating the agent differs depending on whether your container instance was launched with the Amazon ECS-optimized AMI or another operating system.</p> <p> <code>UpdateContainerAgent</code> requires the Amazon ECS-optimized AMI or Amazon Linux with the <code>ecs-init</code> service installed and running. For help updating the Amazon ECS container agent on other operating systems, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-update.html#manually_update_agent">Manually Updating the Amazon ECS Container Agent</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_605934 = newJObject()
  if body != nil:
    body_605934 = body
  result = call_605933.call(nil, nil, nil, nil, body_605934)

var updateContainerAgent* = Call_UpdateContainerAgent_605920(
    name: "updateContainerAgent", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateContainerAgent",
    validator: validate_UpdateContainerAgent_605921, base: "/",
    url: url_UpdateContainerAgent_605922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContainerInstancesState_605935 = ref object of OpenApiRestCall_604658
proc url_UpdateContainerInstancesState_605937(protocol: Scheme; host: string;
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

proc validate_UpdateContainerInstancesState_605936(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the status of an Amazon ECS container instance.</p> <p>Once a container instance has reached an <code>ACTIVE</code> state, you can change the status of a container instance to <code>DRAINING</code> to manually remove an instance from a cluster, for example to perform system updates, update the Docker daemon, or scale down the cluster size.</p> <important> <p>A container instance cannot be changed to <code>DRAINING</code> until it has reached an <code>ACTIVE</code> status. If the instance is in any other status, an error will be received.</p> </important> <p>When you set a container instance to <code>DRAINING</code>, Amazon ECS prevents new tasks from being scheduled for placement on the container instance and replacement service tasks are started on other container instances in the cluster if the resources are available. Service tasks on the container instance that are in the <code>PENDING</code> state are stopped immediately.</p> <p>Service tasks on the container instance that are in the <code>RUNNING</code> state are stopped and replaced according to the service's deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>. You can change the deployment configuration of your service using <a>UpdateService</a>.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during task replacement. For example, <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. If the minimum is 100%, the service scheduler can't remove existing tasks until the replacement tasks are considered healthy. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during task replacement, which enables you to define the replacement batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four tasks to be drained, provided that the cluster resources required to do this are available. If the maximum is 100%, then replacement tasks can't start until the draining tasks have stopped.</p> </li> </ul> <p>Any <code>PENDING</code> or <code>RUNNING</code> tasks that do not belong to a service are not affected. You must wait for them to finish or stop them manually.</p> <p>A container instance has completed draining when it has no more <code>RUNNING</code> tasks. You can verify this using <a>ListTasks</a>.</p> <p>When a container instance has been drained, you can set a container instance to <code>ACTIVE</code> status and once it has reached that status the Amazon ECS scheduler can begin scheduling tasks on the instance again.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605938 = header.getOrDefault("X-Amz-Target")
  valid_605938 = validateParameter(valid_605938, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateContainerInstancesState"))
  if valid_605938 != nil:
    section.add "X-Amz-Target", valid_605938
  var valid_605939 = header.getOrDefault("X-Amz-Signature")
  valid_605939 = validateParameter(valid_605939, JString, required = false,
                                 default = nil)
  if valid_605939 != nil:
    section.add "X-Amz-Signature", valid_605939
  var valid_605940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605940 = validateParameter(valid_605940, JString, required = false,
                                 default = nil)
  if valid_605940 != nil:
    section.add "X-Amz-Content-Sha256", valid_605940
  var valid_605941 = header.getOrDefault("X-Amz-Date")
  valid_605941 = validateParameter(valid_605941, JString, required = false,
                                 default = nil)
  if valid_605941 != nil:
    section.add "X-Amz-Date", valid_605941
  var valid_605942 = header.getOrDefault("X-Amz-Credential")
  valid_605942 = validateParameter(valid_605942, JString, required = false,
                                 default = nil)
  if valid_605942 != nil:
    section.add "X-Amz-Credential", valid_605942
  var valid_605943 = header.getOrDefault("X-Amz-Security-Token")
  valid_605943 = validateParameter(valid_605943, JString, required = false,
                                 default = nil)
  if valid_605943 != nil:
    section.add "X-Amz-Security-Token", valid_605943
  var valid_605944 = header.getOrDefault("X-Amz-Algorithm")
  valid_605944 = validateParameter(valid_605944, JString, required = false,
                                 default = nil)
  if valid_605944 != nil:
    section.add "X-Amz-Algorithm", valid_605944
  var valid_605945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605945 = validateParameter(valid_605945, JString, required = false,
                                 default = nil)
  if valid_605945 != nil:
    section.add "X-Amz-SignedHeaders", valid_605945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605947: Call_UpdateContainerInstancesState_605935; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the status of an Amazon ECS container instance.</p> <p>Once a container instance has reached an <code>ACTIVE</code> state, you can change the status of a container instance to <code>DRAINING</code> to manually remove an instance from a cluster, for example to perform system updates, update the Docker daemon, or scale down the cluster size.</p> <important> <p>A container instance cannot be changed to <code>DRAINING</code> until it has reached an <code>ACTIVE</code> status. If the instance is in any other status, an error will be received.</p> </important> <p>When you set a container instance to <code>DRAINING</code>, Amazon ECS prevents new tasks from being scheduled for placement on the container instance and replacement service tasks are started on other container instances in the cluster if the resources are available. Service tasks on the container instance that are in the <code>PENDING</code> state are stopped immediately.</p> <p>Service tasks on the container instance that are in the <code>RUNNING</code> state are stopped and replaced according to the service's deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>. You can change the deployment configuration of your service using <a>UpdateService</a>.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during task replacement. For example, <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. If the minimum is 100%, the service scheduler can't remove existing tasks until the replacement tasks are considered healthy. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during task replacement, which enables you to define the replacement batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four tasks to be drained, provided that the cluster resources required to do this are available. If the maximum is 100%, then replacement tasks can't start until the draining tasks have stopped.</p> </li> </ul> <p>Any <code>PENDING</code> or <code>RUNNING</code> tasks that do not belong to a service are not affected. You must wait for them to finish or stop them manually.</p> <p>A container instance has completed draining when it has no more <code>RUNNING</code> tasks. You can verify this using <a>ListTasks</a>.</p> <p>When a container instance has been drained, you can set a container instance to <code>ACTIVE</code> status and once it has reached that status the Amazon ECS scheduler can begin scheduling tasks on the instance again.</p>
  ## 
  let valid = call_605947.validator(path, query, header, formData, body)
  let scheme = call_605947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605947.url(scheme.get, call_605947.host, call_605947.base,
                         call_605947.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605947, url, valid)

proc call*(call_605948: Call_UpdateContainerInstancesState_605935; body: JsonNode): Recallable =
  ## updateContainerInstancesState
  ## <p>Modifies the status of an Amazon ECS container instance.</p> <p>Once a container instance has reached an <code>ACTIVE</code> state, you can change the status of a container instance to <code>DRAINING</code> to manually remove an instance from a cluster, for example to perform system updates, update the Docker daemon, or scale down the cluster size.</p> <important> <p>A container instance cannot be changed to <code>DRAINING</code> until it has reached an <code>ACTIVE</code> status. If the instance is in any other status, an error will be received.</p> </important> <p>When you set a container instance to <code>DRAINING</code>, Amazon ECS prevents new tasks from being scheduled for placement on the container instance and replacement service tasks are started on other container instances in the cluster if the resources are available. Service tasks on the container instance that are in the <code>PENDING</code> state are stopped immediately.</p> <p>Service tasks on the container instance that are in the <code>RUNNING</code> state are stopped and replaced according to the service's deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>. You can change the deployment configuration of your service using <a>UpdateService</a>.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during task replacement. For example, <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. If the minimum is 100%, the service scheduler can't remove existing tasks until the replacement tasks are considered healthy. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during task replacement, which enables you to define the replacement batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four tasks to be drained, provided that the cluster resources required to do this are available. If the maximum is 100%, then replacement tasks can't start until the draining tasks have stopped.</p> </li> </ul> <p>Any <code>PENDING</code> or <code>RUNNING</code> tasks that do not belong to a service are not affected. You must wait for them to finish or stop them manually.</p> <p>A container instance has completed draining when it has no more <code>RUNNING</code> tasks. You can verify this using <a>ListTasks</a>.</p> <p>When a container instance has been drained, you can set a container instance to <code>ACTIVE</code> status and once it has reached that status the Amazon ECS scheduler can begin scheduling tasks on the instance again.</p>
  ##   body: JObject (required)
  var body_605949 = newJObject()
  if body != nil:
    body_605949 = body
  result = call_605948.call(nil, nil, nil, nil, body_605949)

var updateContainerInstancesState* = Call_UpdateContainerInstancesState_605935(
    name: "updateContainerInstancesState", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateContainerInstancesState",
    validator: validate_UpdateContainerInstancesState_605936, base: "/",
    url: url_UpdateContainerInstancesState_605937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateService_605950 = ref object of OpenApiRestCall_604658
proc url_UpdateService_605952(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateService_605951(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modifies the parameters of a service.</p> <p>For services using the rolling update (<code>ECS</code>) deployment controller, the desired count, deployment configuration, network configuration, or task definition used can be updated.</p> <p>For services using the blue/green (<code>CODE_DEPLOY</code>) deployment controller, only the desired count, deployment configuration, and health check grace period can be updated using this API. If the network configuration, platform version, or task definition need to be updated, a new AWS CodeDeploy deployment should be created. For more information, see <a href="https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html">CreateDeployment</a> in the <i>AWS CodeDeploy API Reference</i>.</p> <p>For services using an external deployment controller, you can update only the desired count and health check grace period using this API. If the launch type, load balancer, network configuration, platform version, or task definition need to be updated, you should create a new task set. For more information, see <a>CreateTaskSet</a>.</p> <p>You can add to or subtract from the number of instantiations of a task definition in a service by specifying the cluster that the service is running in and a new <code>desiredCount</code> parameter.</p> <p>If you have updated the Docker image of your application, you can create a new task definition with that image and deploy it to your service. The service scheduler uses the minimum healthy percent and maximum percent parameters (in the service's deployment configuration) to determine the deployment strategy.</p> <note> <p>If your updated Docker image uses the same tag as what is in the existing task definition for your service (for example, <code>my_image:latest</code>), you do not need to create a new revision of your task definition. You can update the service using the <code>forceNewDeployment</code> option. The new tasks launched by the deployment pull the current image/tag combination from your repository when they start.</p> </note> <p>You can also update the deployment configuration of a service. When a deployment is triggered by updating the task definition of a service, the service scheduler uses the deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>, to determine the deployment strategy.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during a deployment. For example, if <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during a deployment, which enables you to define the deployment batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available).</p> </li> </ul> <p>When <a>UpdateService</a> stops a task during a deployment, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> and a 30-second timeout, after which <code>SIGKILL</code> is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> is sent.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster with the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy):</p> <ul> <li> <p>Sort the valid container instances by the fewest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul> <p>When the service scheduler stops running tasks, it attempts to maintain balance across the Availability Zones in your cluster using the following logic: </p> <ul> <li> <p>Sort the container instances by the largest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have two, container instances in either zone B or C are considered optimal for termination.</p> </li> <li> <p>Stop the task on a container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the largest number of running tasks for this service.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605953 = header.getOrDefault("X-Amz-Target")
  valid_605953 = validateParameter(valid_605953, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateService"))
  if valid_605953 != nil:
    section.add "X-Amz-Target", valid_605953
  var valid_605954 = header.getOrDefault("X-Amz-Signature")
  valid_605954 = validateParameter(valid_605954, JString, required = false,
                                 default = nil)
  if valid_605954 != nil:
    section.add "X-Amz-Signature", valid_605954
  var valid_605955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605955 = validateParameter(valid_605955, JString, required = false,
                                 default = nil)
  if valid_605955 != nil:
    section.add "X-Amz-Content-Sha256", valid_605955
  var valid_605956 = header.getOrDefault("X-Amz-Date")
  valid_605956 = validateParameter(valid_605956, JString, required = false,
                                 default = nil)
  if valid_605956 != nil:
    section.add "X-Amz-Date", valid_605956
  var valid_605957 = header.getOrDefault("X-Amz-Credential")
  valid_605957 = validateParameter(valid_605957, JString, required = false,
                                 default = nil)
  if valid_605957 != nil:
    section.add "X-Amz-Credential", valid_605957
  var valid_605958 = header.getOrDefault("X-Amz-Security-Token")
  valid_605958 = validateParameter(valid_605958, JString, required = false,
                                 default = nil)
  if valid_605958 != nil:
    section.add "X-Amz-Security-Token", valid_605958
  var valid_605959 = header.getOrDefault("X-Amz-Algorithm")
  valid_605959 = validateParameter(valid_605959, JString, required = false,
                                 default = nil)
  if valid_605959 != nil:
    section.add "X-Amz-Algorithm", valid_605959
  var valid_605960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605960 = validateParameter(valid_605960, JString, required = false,
                                 default = nil)
  if valid_605960 != nil:
    section.add "X-Amz-SignedHeaders", valid_605960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605962: Call_UpdateService_605950; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the parameters of a service.</p> <p>For services using the rolling update (<code>ECS</code>) deployment controller, the desired count, deployment configuration, network configuration, or task definition used can be updated.</p> <p>For services using the blue/green (<code>CODE_DEPLOY</code>) deployment controller, only the desired count, deployment configuration, and health check grace period can be updated using this API. If the network configuration, platform version, or task definition need to be updated, a new AWS CodeDeploy deployment should be created. For more information, see <a href="https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html">CreateDeployment</a> in the <i>AWS CodeDeploy API Reference</i>.</p> <p>For services using an external deployment controller, you can update only the desired count and health check grace period using this API. If the launch type, load balancer, network configuration, platform version, or task definition need to be updated, you should create a new task set. For more information, see <a>CreateTaskSet</a>.</p> <p>You can add to or subtract from the number of instantiations of a task definition in a service by specifying the cluster that the service is running in and a new <code>desiredCount</code> parameter.</p> <p>If you have updated the Docker image of your application, you can create a new task definition with that image and deploy it to your service. The service scheduler uses the minimum healthy percent and maximum percent parameters (in the service's deployment configuration) to determine the deployment strategy.</p> <note> <p>If your updated Docker image uses the same tag as what is in the existing task definition for your service (for example, <code>my_image:latest</code>), you do not need to create a new revision of your task definition. You can update the service using the <code>forceNewDeployment</code> option. The new tasks launched by the deployment pull the current image/tag combination from your repository when they start.</p> </note> <p>You can also update the deployment configuration of a service. When a deployment is triggered by updating the task definition of a service, the service scheduler uses the deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>, to determine the deployment strategy.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during a deployment. For example, if <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during a deployment, which enables you to define the deployment batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available).</p> </li> </ul> <p>When <a>UpdateService</a> stops a task during a deployment, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> and a 30-second timeout, after which <code>SIGKILL</code> is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> is sent.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster with the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy):</p> <ul> <li> <p>Sort the valid container instances by the fewest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul> <p>When the service scheduler stops running tasks, it attempts to maintain balance across the Availability Zones in your cluster using the following logic: </p> <ul> <li> <p>Sort the container instances by the largest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have two, container instances in either zone B or C are considered optimal for termination.</p> </li> <li> <p>Stop the task on a container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the largest number of running tasks for this service.</p> </li> </ul>
  ## 
  let valid = call_605962.validator(path, query, header, formData, body)
  let scheme = call_605962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605962.url(scheme.get, call_605962.host, call_605962.base,
                         call_605962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605962, url, valid)

proc call*(call_605963: Call_UpdateService_605950; body: JsonNode): Recallable =
  ## updateService
  ## <p>Modifies the parameters of a service.</p> <p>For services using the rolling update (<code>ECS</code>) deployment controller, the desired count, deployment configuration, network configuration, or task definition used can be updated.</p> <p>For services using the blue/green (<code>CODE_DEPLOY</code>) deployment controller, only the desired count, deployment configuration, and health check grace period can be updated using this API. If the network configuration, platform version, or task definition need to be updated, a new AWS CodeDeploy deployment should be created. For more information, see <a href="https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html">CreateDeployment</a> in the <i>AWS CodeDeploy API Reference</i>.</p> <p>For services using an external deployment controller, you can update only the desired count and health check grace period using this API. If the launch type, load balancer, network configuration, platform version, or task definition need to be updated, you should create a new task set. For more information, see <a>CreateTaskSet</a>.</p> <p>You can add to or subtract from the number of instantiations of a task definition in a service by specifying the cluster that the service is running in and a new <code>desiredCount</code> parameter.</p> <p>If you have updated the Docker image of your application, you can create a new task definition with that image and deploy it to your service. The service scheduler uses the minimum healthy percent and maximum percent parameters (in the service's deployment configuration) to determine the deployment strategy.</p> <note> <p>If your updated Docker image uses the same tag as what is in the existing task definition for your service (for example, <code>my_image:latest</code>), you do not need to create a new revision of your task definition. You can update the service using the <code>forceNewDeployment</code> option. The new tasks launched by the deployment pull the current image/tag combination from your repository when they start.</p> </note> <p>You can also update the deployment configuration of a service. When a deployment is triggered by updating the task definition of a service, the service scheduler uses the deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>, to determine the deployment strategy.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during a deployment. For example, if <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during a deployment, which enables you to define the deployment batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available).</p> </li> </ul> <p>When <a>UpdateService</a> stops a task during a deployment, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> and a 30-second timeout, after which <code>SIGKILL</code> is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> is sent.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster with the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy):</p> <ul> <li> <p>Sort the valid container instances by the fewest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul> <p>When the service scheduler stops running tasks, it attempts to maintain balance across the Availability Zones in your cluster using the following logic: </p> <ul> <li> <p>Sort the container instances by the largest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have two, container instances in either zone B or C are considered optimal for termination.</p> </li> <li> <p>Stop the task on a container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the largest number of running tasks for this service.</p> </li> </ul>
  ##   body: JObject (required)
  var body_605964 = newJObject()
  if body != nil:
    body_605964 = body
  result = call_605963.call(nil, nil, nil, nil, body_605964)

var updateService* = Call_UpdateService_605950(name: "updateService",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateService",
    validator: validate_UpdateService_605951, base: "/", url: url_UpdateService_605952,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServicePrimaryTaskSet_605965 = ref object of OpenApiRestCall_604658
proc url_UpdateServicePrimaryTaskSet_605967(protocol: Scheme; host: string;
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

proc validate_UpdateServicePrimaryTaskSet_605966(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies which task set in a service is the primary task set. Any parameters that are updated on the primary task set in a service will transition to the service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605968 = header.getOrDefault("X-Amz-Target")
  valid_605968 = validateParameter(valid_605968, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateServicePrimaryTaskSet"))
  if valid_605968 != nil:
    section.add "X-Amz-Target", valid_605968
  var valid_605969 = header.getOrDefault("X-Amz-Signature")
  valid_605969 = validateParameter(valid_605969, JString, required = false,
                                 default = nil)
  if valid_605969 != nil:
    section.add "X-Amz-Signature", valid_605969
  var valid_605970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605970 = validateParameter(valid_605970, JString, required = false,
                                 default = nil)
  if valid_605970 != nil:
    section.add "X-Amz-Content-Sha256", valid_605970
  var valid_605971 = header.getOrDefault("X-Amz-Date")
  valid_605971 = validateParameter(valid_605971, JString, required = false,
                                 default = nil)
  if valid_605971 != nil:
    section.add "X-Amz-Date", valid_605971
  var valid_605972 = header.getOrDefault("X-Amz-Credential")
  valid_605972 = validateParameter(valid_605972, JString, required = false,
                                 default = nil)
  if valid_605972 != nil:
    section.add "X-Amz-Credential", valid_605972
  var valid_605973 = header.getOrDefault("X-Amz-Security-Token")
  valid_605973 = validateParameter(valid_605973, JString, required = false,
                                 default = nil)
  if valid_605973 != nil:
    section.add "X-Amz-Security-Token", valid_605973
  var valid_605974 = header.getOrDefault("X-Amz-Algorithm")
  valid_605974 = validateParameter(valid_605974, JString, required = false,
                                 default = nil)
  if valid_605974 != nil:
    section.add "X-Amz-Algorithm", valid_605974
  var valid_605975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605975 = validateParameter(valid_605975, JString, required = false,
                                 default = nil)
  if valid_605975 != nil:
    section.add "X-Amz-SignedHeaders", valid_605975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605977: Call_UpdateServicePrimaryTaskSet_605965; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies which task set in a service is the primary task set. Any parameters that are updated on the primary task set in a service will transition to the service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_605977.validator(path, query, header, formData, body)
  let scheme = call_605977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605977.url(scheme.get, call_605977.host, call_605977.base,
                         call_605977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605977, url, valid)

proc call*(call_605978: Call_UpdateServicePrimaryTaskSet_605965; body: JsonNode): Recallable =
  ## updateServicePrimaryTaskSet
  ## Modifies which task set in a service is the primary task set. Any parameters that are updated on the primary task set in a service will transition to the service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_605979 = newJObject()
  if body != nil:
    body_605979 = body
  result = call_605978.call(nil, nil, nil, nil, body_605979)

var updateServicePrimaryTaskSet* = Call_UpdateServicePrimaryTaskSet_605965(
    name: "updateServicePrimaryTaskSet", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateServicePrimaryTaskSet",
    validator: validate_UpdateServicePrimaryTaskSet_605966, base: "/",
    url: url_UpdateServicePrimaryTaskSet_605967,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTaskSet_605980 = ref object of OpenApiRestCall_604658
proc url_UpdateTaskSet_605982(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTaskSet_605981(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies a task set. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605983 = header.getOrDefault("X-Amz-Target")
  valid_605983 = validateParameter(valid_605983, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateTaskSet"))
  if valid_605983 != nil:
    section.add "X-Amz-Target", valid_605983
  var valid_605984 = header.getOrDefault("X-Amz-Signature")
  valid_605984 = validateParameter(valid_605984, JString, required = false,
                                 default = nil)
  if valid_605984 != nil:
    section.add "X-Amz-Signature", valid_605984
  var valid_605985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605985 = validateParameter(valid_605985, JString, required = false,
                                 default = nil)
  if valid_605985 != nil:
    section.add "X-Amz-Content-Sha256", valid_605985
  var valid_605986 = header.getOrDefault("X-Amz-Date")
  valid_605986 = validateParameter(valid_605986, JString, required = false,
                                 default = nil)
  if valid_605986 != nil:
    section.add "X-Amz-Date", valid_605986
  var valid_605987 = header.getOrDefault("X-Amz-Credential")
  valid_605987 = validateParameter(valid_605987, JString, required = false,
                                 default = nil)
  if valid_605987 != nil:
    section.add "X-Amz-Credential", valid_605987
  var valid_605988 = header.getOrDefault("X-Amz-Security-Token")
  valid_605988 = validateParameter(valid_605988, JString, required = false,
                                 default = nil)
  if valid_605988 != nil:
    section.add "X-Amz-Security-Token", valid_605988
  var valid_605989 = header.getOrDefault("X-Amz-Algorithm")
  valid_605989 = validateParameter(valid_605989, JString, required = false,
                                 default = nil)
  if valid_605989 != nil:
    section.add "X-Amz-Algorithm", valid_605989
  var valid_605990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605990 = validateParameter(valid_605990, JString, required = false,
                                 default = nil)
  if valid_605990 != nil:
    section.add "X-Amz-SignedHeaders", valid_605990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605992: Call_UpdateTaskSet_605980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a task set. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_605992.validator(path, query, header, formData, body)
  let scheme = call_605992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605992.url(scheme.get, call_605992.host, call_605992.base,
                         call_605992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605992, url, valid)

proc call*(call_605993: Call_UpdateTaskSet_605980; body: JsonNode): Recallable =
  ## updateTaskSet
  ## Modifies a task set. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_605994 = newJObject()
  if body != nil:
    body_605994 = body
  result = call_605993.call(nil, nil, nil, nil, body_605994)

var updateTaskSet* = Call_UpdateTaskSet_605980(name: "updateTaskSet",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateTaskSet",
    validator: validate_UpdateTaskSet_605981, base: "/", url: url_UpdateTaskSet_605982,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
