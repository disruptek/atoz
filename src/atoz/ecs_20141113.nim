
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_CreateCapacityProvider_605927 = ref object of OpenApiRestCall_605589
proc url_CreateCapacityProvider_605929(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCapacityProvider_605928(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateCapacityProvider"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_CreateCapacityProvider_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new capacity provider. Capacity providers are associated with an Amazon ECS cluster and are used in capacity provider strategies to facilitate cluster auto scaling.</p> <p>Only capacity providers using an Auto Scaling group can be created. Amazon ECS tasks on AWS Fargate use the <code>FARGATE</code> and <code>FARGATE_SPOT</code> capacity providers which are already created and available to all accounts in Regions supported by AWS Fargate.</p>
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_CreateCapacityProvider_605927; body: JsonNode): Recallable =
  ## createCapacityProvider
  ## <p>Creates a new capacity provider. Capacity providers are associated with an Amazon ECS cluster and are used in capacity provider strategies to facilitate cluster auto scaling.</p> <p>Only capacity providers using an Auto Scaling group can be created. Amazon ECS tasks on AWS Fargate use the <code>FARGATE</code> and <code>FARGATE_SPOT</code> capacity providers which are already created and available to all accounts in Regions supported by AWS Fargate.</p>
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var createCapacityProvider* = Call_CreateCapacityProvider_605927(
    name: "createCapacityProvider", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateCapacityProvider",
    validator: validate_CreateCapacityProvider_605928, base: "/",
    url: url_CreateCapacityProvider_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCluster_606196 = ref object of OpenApiRestCall_605589
proc url_CreateCluster_606198(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCluster_606197(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateCluster"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_CreateCluster_606196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Amazon ECS cluster. By default, your account receives a <code>default</code> cluster when you launch your first container instance. However, you can create your own cluster with a unique name with the <code>CreateCluster</code> action.</p> <note> <p>When you call the <a>CreateCluster</a> API operation, Amazon ECS attempts to create the Amazon ECS service-linked role for your account so that required resources in other AWS services can be managed on your behalf. However, if the IAM user that makes the call does not have permissions to create the service-linked role, it is not created. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html">Using Service-Linked Roles for Amazon ECS</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_CreateCluster_606196; body: JsonNode): Recallable =
  ## createCluster
  ## <p>Creates a new Amazon ECS cluster. By default, your account receives a <code>default</code> cluster when you launch your first container instance. However, you can create your own cluster with a unique name with the <code>CreateCluster</code> action.</p> <note> <p>When you call the <a>CreateCluster</a> API operation, Amazon ECS attempts to create the Amazon ECS service-linked role for your account so that required resources in other AWS services can be managed on your behalf. However, if the IAM user that makes the call does not have permissions to create the service-linked role, it is not created. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html">Using Service-Linked Roles for Amazon ECS</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var createCluster* = Call_CreateCluster_606196(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateCluster",
    validator: validate_CreateCluster_606197, base: "/", url: url_CreateCluster_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateService_606211 = ref object of OpenApiRestCall_605589
proc url_CreateService_606213(protocol: Scheme; host: string; base: string;
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

proc validate_CreateService_606212(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateService"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_CreateService_606211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs and maintains a desired number of tasks from a specified task definition. If the number of tasks running in a service drops below the <code>desiredCount</code>, Amazon ECS runs another copy of the task in the specified cluster. To update an existing service, see <a>UpdateService</a>.</p> <p>In addition to maintaining the desired count of tasks in your service, you can optionally run your service behind one or more load balancers. The load balancers distribute traffic across the tasks that are associated with the service. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html">Service Load Balancing</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and the container instance that they're hosted on is reported as healthy by the load balancer.</p> <p>There are two service scheduler strategies available:</p> <ul> <li> <p> <code>REPLICA</code> - The replica scheduling strategy places and maintains the desired number of tasks across your cluster. By default, the service scheduler spreads tasks across Availability Zones. You can use task placement strategies and constraints to customize task placement decisions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> <li> <p> <code>DAEMON</code> - The daemon scheduling strategy deploys exactly one task on each active container instance that meets all of the task placement constraints that you specify in your cluster. When using this strategy, you don't need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> </ul> <p>You can optionally specify a deployment configuration for your service. The deployment is triggered by changing properties, such as the task definition or the desired count of a service, with an <a>UpdateService</a> operation. The default value for a replica service for <code>minimumHealthyPercent</code> is 100%. The default value for a daemon service for <code>minimumHealthyPercent</code> is 0%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the minimum healthy percent represents a lower limit on the number of tasks in a service that must remain in the <code>RUNNING</code> state during a deployment, as a percentage of the desired number of tasks (rounded up to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to deploy without using additional cluster capacity. For example, if your service has a desired number of four tasks and a minimum healthy percent of 50%, the scheduler might stop two existing tasks to free up cluster capacity before starting two new tasks. Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and they're reported as healthy by the load balancer. The default value for minimum healthy percent is 100%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the <b>maximum percent</b> parameter represents an upper limit on the number of tasks in a service that are allowed in the <code>RUNNING</code> or <code>PENDING</code> state during a deployment, as a percentage of the desired number of tasks (rounded down to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to define the deployment batch size. For example, if your service has a desired number of four tasks and a maximum percent value of 200%, the scheduler may start four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available). The default value for maximum percent is 200%.</p> <p>If a service is using either the <code>CODE_DEPLOY</code> or <code>EXTERNAL</code> deployment controller types and tasks that use the EC2 launch type, the <b>minimum healthy percent</b> and <b>maximum percent</b> values are used only to define the lower and upper limit on the number of the tasks in the service that remain in the <code>RUNNING</code> state while the container instances are in the <code>DRAINING</code> state. If the tasks in the service use the Fargate launch type, the minimum healthy percent and maximum percent values aren't used, although they're currently visible when describing your service.</p> <p>When creating a service that uses the <code>EXTERNAL</code> deployment controller, you can specify only parameters that aren't controlled at the task set level. The only required parameter is the service name. You control your services using the <a>CreateTaskSet</a> operation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster using the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy) with the <code>placementStrategy</code> parameter):</p> <ul> <li> <p>Sort the valid container instances, giving priority to instances that have the fewest number of running tasks for this service in their respective Availability Zone. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul>
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_CreateService_606211; body: JsonNode): Recallable =
  ## createService
  ## <p>Runs and maintains a desired number of tasks from a specified task definition. If the number of tasks running in a service drops below the <code>desiredCount</code>, Amazon ECS runs another copy of the task in the specified cluster. To update an existing service, see <a>UpdateService</a>.</p> <p>In addition to maintaining the desired count of tasks in your service, you can optionally run your service behind one or more load balancers. The load balancers distribute traffic across the tasks that are associated with the service. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html">Service Load Balancing</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and the container instance that they're hosted on is reported as healthy by the load balancer.</p> <p>There are two service scheduler strategies available:</p> <ul> <li> <p> <code>REPLICA</code> - The replica scheduling strategy places and maintains the desired number of tasks across your cluster. By default, the service scheduler spreads tasks across Availability Zones. You can use task placement strategies and constraints to customize task placement decisions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> <li> <p> <code>DAEMON</code> - The daemon scheduling strategy deploys exactly one task on each active container instance that meets all of the task placement constraints that you specify in your cluster. When using this strategy, you don't need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> </ul> <p>You can optionally specify a deployment configuration for your service. The deployment is triggered by changing properties, such as the task definition or the desired count of a service, with an <a>UpdateService</a> operation. The default value for a replica service for <code>minimumHealthyPercent</code> is 100%. The default value for a daemon service for <code>minimumHealthyPercent</code> is 0%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the minimum healthy percent represents a lower limit on the number of tasks in a service that must remain in the <code>RUNNING</code> state during a deployment, as a percentage of the desired number of tasks (rounded up to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to deploy without using additional cluster capacity. For example, if your service has a desired number of four tasks and a minimum healthy percent of 50%, the scheduler might stop two existing tasks to free up cluster capacity before starting two new tasks. Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and they're reported as healthy by the load balancer. The default value for minimum healthy percent is 100%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the <b>maximum percent</b> parameter represents an upper limit on the number of tasks in a service that are allowed in the <code>RUNNING</code> or <code>PENDING</code> state during a deployment, as a percentage of the desired number of tasks (rounded down to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to define the deployment batch size. For example, if your service has a desired number of four tasks and a maximum percent value of 200%, the scheduler may start four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available). The default value for maximum percent is 200%.</p> <p>If a service is using either the <code>CODE_DEPLOY</code> or <code>EXTERNAL</code> deployment controller types and tasks that use the EC2 launch type, the <b>minimum healthy percent</b> and <b>maximum percent</b> values are used only to define the lower and upper limit on the number of the tasks in the service that remain in the <code>RUNNING</code> state while the container instances are in the <code>DRAINING</code> state. If the tasks in the service use the Fargate launch type, the minimum healthy percent and maximum percent values aren't used, although they're currently visible when describing your service.</p> <p>When creating a service that uses the <code>EXTERNAL</code> deployment controller, you can specify only parameters that aren't controlled at the task set level. The only required parameter is the service name. You control your services using the <a>CreateTaskSet</a> operation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster using the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy) with the <code>placementStrategy</code> parameter):</p> <ul> <li> <p>Sort the valid container instances, giving priority to instances that have the fewest number of running tasks for this service in their respective Availability Zone. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var createService* = Call_CreateService_606211(name: "createService",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateService",
    validator: validate_CreateService_606212, base: "/", url: url_CreateService_606213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTaskSet_606226 = ref object of OpenApiRestCall_605589
proc url_CreateTaskSet_606228(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTaskSet_606227(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateTaskSet"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_CreateTaskSet_606226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a task set in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_CreateTaskSet_606226; body: JsonNode): Recallable =
  ## createTaskSet
  ## Create a task set in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var createTaskSet* = Call_CreateTaskSet_606226(name: "createTaskSet",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateTaskSet",
    validator: validate_CreateTaskSet_606227, base: "/", url: url_CreateTaskSet_606228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccountSetting_606241 = ref object of OpenApiRestCall_605589
proc url_DeleteAccountSetting_606243(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAccountSetting_606242(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteAccountSetting"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_DeleteAccountSetting_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables an account setting for a specified IAM user, IAM role, or the root user for an account.
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_DeleteAccountSetting_606241; body: JsonNode): Recallable =
  ## deleteAccountSetting
  ## Disables an account setting for a specified IAM user, IAM role, or the root user for an account.
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var deleteAccountSetting* = Call_DeleteAccountSetting_606241(
    name: "deleteAccountSetting", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteAccountSetting",
    validator: validate_DeleteAccountSetting_606242, base: "/",
    url: url_DeleteAccountSetting_606243, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAttributes_606256 = ref object of OpenApiRestCall_605589
proc url_DeleteAttributes_606258(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAttributes_606257(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteAttributes"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_DeleteAttributes_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more custom attributes from an Amazon ECS resource.
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_DeleteAttributes_606256; body: JsonNode): Recallable =
  ## deleteAttributes
  ## Deletes one or more custom attributes from an Amazon ECS resource.
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var deleteAttributes* = Call_DeleteAttributes_606256(name: "deleteAttributes",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteAttributes",
    validator: validate_DeleteAttributes_606257, base: "/",
    url: url_DeleteAttributes_606258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_606271 = ref object of OpenApiRestCall_605589
proc url_DeleteCluster_606273(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCluster_606272(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified cluster. You must deregister all container instances from this cluster before you may delete it. You can list the container instances in a cluster with <a>ListContainerInstances</a> and deregister them with <a>DeregisterContainerInstance</a>.
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteCluster"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_DeleteCluster_606271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified cluster. You must deregister all container instances from this cluster before you may delete it. You can list the container instances in a cluster with <a>ListContainerInstances</a> and deregister them with <a>DeregisterContainerInstance</a>.
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_DeleteCluster_606271; body: JsonNode): Recallable =
  ## deleteCluster
  ## Deletes the specified cluster. You must deregister all container instances from this cluster before you may delete it. You can list the container instances in a cluster with <a>ListContainerInstances</a> and deregister them with <a>DeregisterContainerInstance</a>.
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var deleteCluster* = Call_DeleteCluster_606271(name: "deleteCluster",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteCluster",
    validator: validate_DeleteCluster_606272, base: "/", url: url_DeleteCluster_606273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteService_606286 = ref object of OpenApiRestCall_605589
proc url_DeleteService_606288(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteService_606287(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteService"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_DeleteService_606286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specified service within a cluster. You can delete a service if you have no running tasks in it and the desired task count is zero. If the service is actively maintaining tasks, you cannot delete it, and you must update the service to a desired task count of zero. For more information, see <a>UpdateService</a>.</p> <note> <p>When you delete a service, if there are still running tasks that require cleanup, the service status moves from <code>ACTIVE</code> to <code>DRAINING</code>, and the service is no longer visible in the console or in the <a>ListServices</a> API operation. After all tasks have transitioned to either <code>STOPPING</code> or <code>STOPPED</code> status, the service status moves from <code>DRAINING</code> to <code>INACTIVE</code>. Services in the <code>DRAINING</code> or <code>INACTIVE</code> status can still be viewed with the <a>DescribeServices</a> API operation. However, in the future, <code>INACTIVE</code> services may be cleaned up and purged from Amazon ECS record keeping, and <a>DescribeServices</a> calls on those services return a <code>ServiceNotFoundException</code> error.</p> </note> <important> <p>If you attempt to create a new service with the same name as an existing service in either <code>ACTIVE</code> or <code>DRAINING</code> status, you receive an error.</p> </important>
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_DeleteService_606286; body: JsonNode): Recallable =
  ## deleteService
  ## <p>Deletes a specified service within a cluster. You can delete a service if you have no running tasks in it and the desired task count is zero. If the service is actively maintaining tasks, you cannot delete it, and you must update the service to a desired task count of zero. For more information, see <a>UpdateService</a>.</p> <note> <p>When you delete a service, if there are still running tasks that require cleanup, the service status moves from <code>ACTIVE</code> to <code>DRAINING</code>, and the service is no longer visible in the console or in the <a>ListServices</a> API operation. After all tasks have transitioned to either <code>STOPPING</code> or <code>STOPPED</code> status, the service status moves from <code>DRAINING</code> to <code>INACTIVE</code>. Services in the <code>DRAINING</code> or <code>INACTIVE</code> status can still be viewed with the <a>DescribeServices</a> API operation. However, in the future, <code>INACTIVE</code> services may be cleaned up and purged from Amazon ECS record keeping, and <a>DescribeServices</a> calls on those services return a <code>ServiceNotFoundException</code> error.</p> </note> <important> <p>If you attempt to create a new service with the same name as an existing service in either <code>ACTIVE</code> or <code>DRAINING</code> status, you receive an error.</p> </important>
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var deleteService* = Call_DeleteService_606286(name: "deleteService",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteService",
    validator: validate_DeleteService_606287, base: "/", url: url_DeleteService_606288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTaskSet_606301 = ref object of OpenApiRestCall_605589
proc url_DeleteTaskSet_606303(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTaskSet_606302(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteTaskSet"))
  if valid_606304 != nil:
    section.add "X-Amz-Target", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_DeleteTaskSet_606301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified task set within a service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_DeleteTaskSet_606301; body: JsonNode): Recallable =
  ## deleteTaskSet
  ## Deletes a specified task set within a service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var deleteTaskSet* = Call_DeleteTaskSet_606301(name: "deleteTaskSet",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteTaskSet",
    validator: validate_DeleteTaskSet_606302, base: "/", url: url_DeleteTaskSet_606303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterContainerInstance_606316 = ref object of OpenApiRestCall_605589
proc url_DeregisterContainerInstance_606318(protocol: Scheme; host: string;
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

proc validate_DeregisterContainerInstance_606317(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeregisterContainerInstance"))
  if valid_606319 != nil:
    section.add "X-Amz-Target", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Algorithm")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Algorithm", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-SignedHeaders", valid_606326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_DeregisterContainerInstance_606316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deregisters an Amazon ECS container instance from the specified cluster. This instance is no longer available to run tasks.</p> <p>If you intend to use the container instance for some other purpose after deregistration, you should stop all of the tasks running on the container instance before deregistration. That prevents any orphaned tasks from consuming resources.</p> <p>Deregistering a container instance removes the instance from a cluster, but it does not terminate the EC2 instance. If you are finished using the instance, be sure to terminate it in the Amazon EC2 console to stop billing.</p> <note> <p>If you terminate a running container instance, Amazon ECS automatically deregisters the instance from your cluster (stopped container instances or instances with disconnected agents are not automatically deregistered when terminated).</p> </note>
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_DeregisterContainerInstance_606316; body: JsonNode): Recallable =
  ## deregisterContainerInstance
  ## <p>Deregisters an Amazon ECS container instance from the specified cluster. This instance is no longer available to run tasks.</p> <p>If you intend to use the container instance for some other purpose after deregistration, you should stop all of the tasks running on the container instance before deregistration. That prevents any orphaned tasks from consuming resources.</p> <p>Deregistering a container instance removes the instance from a cluster, but it does not terminate the EC2 instance. If you are finished using the instance, be sure to terminate it in the Amazon EC2 console to stop billing.</p> <note> <p>If you terminate a running container instance, Amazon ECS automatically deregisters the instance from your cluster (stopped container instances or instances with disconnected agents are not automatically deregistered when terminated).</p> </note>
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var deregisterContainerInstance* = Call_DeregisterContainerInstance_606316(
    name: "deregisterContainerInstance", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeregisterContainerInstance",
    validator: validate_DeregisterContainerInstance_606317, base: "/",
    url: url_DeregisterContainerInstance_606318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskDefinition_606331 = ref object of OpenApiRestCall_605589
proc url_DeregisterTaskDefinition_606333(protocol: Scheme; host: string;
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

proc validate_DeregisterTaskDefinition_606332(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeregisterTaskDefinition"))
  if valid_606334 != nil:
    section.add "X-Amz-Target", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_DeregisterTaskDefinition_606331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deregisters the specified task definition by family and revision. Upon deregistration, the task definition is marked as <code>INACTIVE</code>. Existing tasks and services that reference an <code>INACTIVE</code> task definition continue to run without disruption. Existing services that reference an <code>INACTIVE</code> task definition can still scale up or down by modifying the service's desired count.</p> <p>You cannot use an <code>INACTIVE</code> task definition to run new tasks or create new services, and you cannot update an existing service to reference an <code>INACTIVE</code> task definition. However, there may be up to a 10-minute window following deregistration where these restrictions have not yet taken effect.</p> <note> <p>At this time, <code>INACTIVE</code> task definitions remain discoverable in your account indefinitely. However, this behavior is subject to change in the future, so you should not rely on <code>INACTIVE</code> task definitions persisting beyond the lifecycle of any associated tasks and services.</p> </note>
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_DeregisterTaskDefinition_606331; body: JsonNode): Recallable =
  ## deregisterTaskDefinition
  ## <p>Deregisters the specified task definition by family and revision. Upon deregistration, the task definition is marked as <code>INACTIVE</code>. Existing tasks and services that reference an <code>INACTIVE</code> task definition continue to run without disruption. Existing services that reference an <code>INACTIVE</code> task definition can still scale up or down by modifying the service's desired count.</p> <p>You cannot use an <code>INACTIVE</code> task definition to run new tasks or create new services, and you cannot update an existing service to reference an <code>INACTIVE</code> task definition. However, there may be up to a 10-minute window following deregistration where these restrictions have not yet taken effect.</p> <note> <p>At this time, <code>INACTIVE</code> task definitions remain discoverable in your account indefinitely. However, this behavior is subject to change in the future, so you should not rely on <code>INACTIVE</code> task definitions persisting beyond the lifecycle of any associated tasks and services.</p> </note>
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var deregisterTaskDefinition* = Call_DeregisterTaskDefinition_606331(
    name: "deregisterTaskDefinition", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeregisterTaskDefinition",
    validator: validate_DeregisterTaskDefinition_606332, base: "/",
    url: url_DeregisterTaskDefinition_606333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCapacityProviders_606346 = ref object of OpenApiRestCall_605589
proc url_DescribeCapacityProviders_606348(protocol: Scheme; host: string;
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

proc validate_DescribeCapacityProviders_606347(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606349 = header.getOrDefault("X-Amz-Target")
  valid_606349 = validateParameter(valid_606349, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeCapacityProviders"))
  if valid_606349 != nil:
    section.add "X-Amz-Target", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_DescribeCapacityProviders_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your capacity providers.
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_DescribeCapacityProviders_606346; body: JsonNode): Recallable =
  ## describeCapacityProviders
  ## Describes one or more of your capacity providers.
  ##   body: JObject (required)
  var body_606360 = newJObject()
  if body != nil:
    body_606360 = body
  result = call_606359.call(nil, nil, nil, nil, body_606360)

var describeCapacityProviders* = Call_DescribeCapacityProviders_606346(
    name: "describeCapacityProviders", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeCapacityProviders",
    validator: validate_DescribeCapacityProviders_606347, base: "/",
    url: url_DescribeCapacityProviders_606348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusters_606361 = ref object of OpenApiRestCall_605589
proc url_DescribeClusters_606363(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeClusters_606362(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606364 = header.getOrDefault("X-Amz-Target")
  valid_606364 = validateParameter(valid_606364, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeClusters"))
  if valid_606364 != nil:
    section.add "X-Amz-Target", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Signature")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Signature", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Content-Sha256", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Date")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Date", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Credential")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Credential", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_DescribeClusters_606361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your clusters.
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_DescribeClusters_606361; body: JsonNode): Recallable =
  ## describeClusters
  ## Describes one or more of your clusters.
  ##   body: JObject (required)
  var body_606375 = newJObject()
  if body != nil:
    body_606375 = body
  result = call_606374.call(nil, nil, nil, nil, body_606375)

var describeClusters* = Call_DescribeClusters_606361(name: "describeClusters",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeClusters",
    validator: validate_DescribeClusters_606362, base: "/",
    url: url_DescribeClusters_606363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeContainerInstances_606376 = ref object of OpenApiRestCall_605589
proc url_DescribeContainerInstances_606378(protocol: Scheme; host: string;
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

proc validate_DescribeContainerInstances_606377(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606379 = header.getOrDefault("X-Amz-Target")
  valid_606379 = validateParameter(valid_606379, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeContainerInstances"))
  if valid_606379 != nil:
    section.add "X-Amz-Target", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_DescribeContainerInstances_606376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes Amazon Elastic Container Service container instances. Returns metadata about registered and remaining resources on each container instance requested.
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_DescribeContainerInstances_606376; body: JsonNode): Recallable =
  ## describeContainerInstances
  ## Describes Amazon Elastic Container Service container instances. Returns metadata about registered and remaining resources on each container instance requested.
  ##   body: JObject (required)
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  result = call_606389.call(nil, nil, nil, nil, body_606390)

var describeContainerInstances* = Call_DescribeContainerInstances_606376(
    name: "describeContainerInstances", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeContainerInstances",
    validator: validate_DescribeContainerInstances_606377, base: "/",
    url: url_DescribeContainerInstances_606378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServices_606391 = ref object of OpenApiRestCall_605589
proc url_DescribeServices_606393(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeServices_606392(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606394 = header.getOrDefault("X-Amz-Target")
  valid_606394 = validateParameter(valid_606394, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeServices"))
  if valid_606394 != nil:
    section.add "X-Amz-Target", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_DescribeServices_606391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified services running in your cluster.
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_DescribeServices_606391; body: JsonNode): Recallable =
  ## describeServices
  ## Describes the specified services running in your cluster.
  ##   body: JObject (required)
  var body_606405 = newJObject()
  if body != nil:
    body_606405 = body
  result = call_606404.call(nil, nil, nil, nil, body_606405)

var describeServices* = Call_DescribeServices_606391(name: "describeServices",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeServices",
    validator: validate_DescribeServices_606392, base: "/",
    url: url_DescribeServices_606393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTaskDefinition_606406 = ref object of OpenApiRestCall_605589
proc url_DescribeTaskDefinition_606408(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTaskDefinition_606407(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606409 = header.getOrDefault("X-Amz-Target")
  valid_606409 = validateParameter(valid_606409, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeTaskDefinition"))
  if valid_606409 != nil:
    section.add "X-Amz-Target", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Signature")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Signature", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Content-Sha256", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Date")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Date", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Credential")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Credential", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Security-Token")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Security-Token", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Algorithm")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Algorithm", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-SignedHeaders", valid_606416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_DescribeTaskDefinition_606406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a task definition. You can specify a <code>family</code> and <code>revision</code> to find information about a specific task definition, or you can simply specify the family to find the latest <code>ACTIVE</code> revision in that family.</p> <note> <p>You can only describe <code>INACTIVE</code> task definitions while an active task or service references them.</p> </note>
  ## 
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_DescribeTaskDefinition_606406; body: JsonNode): Recallable =
  ## describeTaskDefinition
  ## <p>Describes a task definition. You can specify a <code>family</code> and <code>revision</code> to find information about a specific task definition, or you can simply specify the family to find the latest <code>ACTIVE</code> revision in that family.</p> <note> <p>You can only describe <code>INACTIVE</code> task definitions while an active task or service references them.</p> </note>
  ##   body: JObject (required)
  var body_606420 = newJObject()
  if body != nil:
    body_606420 = body
  result = call_606419.call(nil, nil, nil, nil, body_606420)

var describeTaskDefinition* = Call_DescribeTaskDefinition_606406(
    name: "describeTaskDefinition", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTaskDefinition",
    validator: validate_DescribeTaskDefinition_606407, base: "/",
    url: url_DescribeTaskDefinition_606408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTaskSets_606421 = ref object of OpenApiRestCall_605589
proc url_DescribeTaskSets_606423(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTaskSets_606422(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606424 = header.getOrDefault("X-Amz-Target")
  valid_606424 = validateParameter(valid_606424, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeTaskSets"))
  if valid_606424 != nil:
    section.add "X-Amz-Target", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606433: Call_DescribeTaskSets_606421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the task sets in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_606433.validator(path, query, header, formData, body)
  let scheme = call_606433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606433.url(scheme.get, call_606433.host, call_606433.base,
                         call_606433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606433, url, valid)

proc call*(call_606434: Call_DescribeTaskSets_606421; body: JsonNode): Recallable =
  ## describeTaskSets
  ## Describes the task sets in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_606435 = newJObject()
  if body != nil:
    body_606435 = body
  result = call_606434.call(nil, nil, nil, nil, body_606435)

var describeTaskSets* = Call_DescribeTaskSets_606421(name: "describeTaskSets",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTaskSets",
    validator: validate_DescribeTaskSets_606422, base: "/",
    url: url_DescribeTaskSets_606423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTasks_606436 = ref object of OpenApiRestCall_605589
proc url_DescribeTasks_606438(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTasks_606437(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606439 = header.getOrDefault("X-Amz-Target")
  valid_606439 = validateParameter(valid_606439, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeTasks"))
  if valid_606439 != nil:
    section.add "X-Amz-Target", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Signature")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Signature", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Content-Sha256", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Date")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Date", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Credential")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Credential", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Security-Token")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Security-Token", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Algorithm")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Algorithm", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-SignedHeaders", valid_606446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606448: Call_DescribeTasks_606436; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specified task or tasks.
  ## 
  let valid = call_606448.validator(path, query, header, formData, body)
  let scheme = call_606448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606448.url(scheme.get, call_606448.host, call_606448.base,
                         call_606448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606448, url, valid)

proc call*(call_606449: Call_DescribeTasks_606436; body: JsonNode): Recallable =
  ## describeTasks
  ## Describes a specified task or tasks.
  ##   body: JObject (required)
  var body_606450 = newJObject()
  if body != nil:
    body_606450 = body
  result = call_606449.call(nil, nil, nil, nil, body_606450)

var describeTasks* = Call_DescribeTasks_606436(name: "describeTasks",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTasks",
    validator: validate_DescribeTasks_606437, base: "/", url: url_DescribeTasks_606438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DiscoverPollEndpoint_606451 = ref object of OpenApiRestCall_605589
proc url_DiscoverPollEndpoint_606453(protocol: Scheme; host: string; base: string;
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

proc validate_DiscoverPollEndpoint_606452(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606454 = header.getOrDefault("X-Amz-Target")
  valid_606454 = validateParameter(valid_606454, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DiscoverPollEndpoint"))
  if valid_606454 != nil:
    section.add "X-Amz-Target", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_DiscoverPollEndpoint_606451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Returns an endpoint for the Amazon ECS agent to poll for updates.</p>
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_DiscoverPollEndpoint_606451; body: JsonNode): Recallable =
  ## discoverPollEndpoint
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Returns an endpoint for the Amazon ECS agent to poll for updates.</p>
  ##   body: JObject (required)
  var body_606465 = newJObject()
  if body != nil:
    body_606465 = body
  result = call_606464.call(nil, nil, nil, nil, body_606465)

var discoverPollEndpoint* = Call_DiscoverPollEndpoint_606451(
    name: "discoverPollEndpoint", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DiscoverPollEndpoint",
    validator: validate_DiscoverPollEndpoint_606452, base: "/",
    url: url_DiscoverPollEndpoint_606453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountSettings_606466 = ref object of OpenApiRestCall_605589
proc url_ListAccountSettings_606468(protocol: Scheme; host: string; base: string;
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

proc validate_ListAccountSettings_606467(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the account settings for a specified principal.
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606469 = header.getOrDefault("X-Amz-Target")
  valid_606469 = validateParameter(valid_606469, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListAccountSettings"))
  if valid_606469 != nil:
    section.add "X-Amz-Target", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Signature")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Signature", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Content-Sha256", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Date")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Date", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Credential")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Credential", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Security-Token")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Security-Token", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Algorithm")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Algorithm", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-SignedHeaders", valid_606476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606478: Call_ListAccountSettings_606466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the account settings for a specified principal.
  ## 
  let valid = call_606478.validator(path, query, header, formData, body)
  let scheme = call_606478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606478.url(scheme.get, call_606478.host, call_606478.base,
                         call_606478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606478, url, valid)

proc call*(call_606479: Call_ListAccountSettings_606466; body: JsonNode): Recallable =
  ## listAccountSettings
  ## Lists the account settings for a specified principal.
  ##   body: JObject (required)
  var body_606480 = newJObject()
  if body != nil:
    body_606480 = body
  result = call_606479.call(nil, nil, nil, nil, body_606480)

var listAccountSettings* = Call_ListAccountSettings_606466(
    name: "listAccountSettings", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListAccountSettings",
    validator: validate_ListAccountSettings_606467, base: "/",
    url: url_ListAccountSettings_606468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttributes_606481 = ref object of OpenApiRestCall_605589
proc url_ListAttributes_606483(protocol: Scheme; host: string; base: string;
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

proc validate_ListAttributes_606482(path: JsonNode; query: JsonNode;
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
  var valid_606484 = query.getOrDefault("nextToken")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "nextToken", valid_606484
  var valid_606485 = query.getOrDefault("maxResults")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "maxResults", valid_606485
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606486 = header.getOrDefault("X-Amz-Target")
  valid_606486 = validateParameter(valid_606486, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListAttributes"))
  if valid_606486 != nil:
    section.add "X-Amz-Target", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Signature")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Signature", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Content-Sha256", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Date")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Date", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Credential")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Credential", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Security-Token")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Security-Token", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Algorithm")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Algorithm", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-SignedHeaders", valid_606493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606495: Call_ListAttributes_606481; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the attributes for Amazon ECS resources within a specified target type and cluster. When you specify a target type and cluster, <code>ListAttributes</code> returns a list of attribute objects, one for each attribute on each resource. You can filter the list of results to a single attribute name to only return results that have that name. You can also filter the results by attribute name and value, for example, to see which container instances in a cluster are running a Linux AMI (<code>ecs.os-type=linux</code>). 
  ## 
  let valid = call_606495.validator(path, query, header, formData, body)
  let scheme = call_606495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606495.url(scheme.get, call_606495.host, call_606495.base,
                         call_606495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606495, url, valid)

proc call*(call_606496: Call_ListAttributes_606481; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAttributes
  ## Lists the attributes for Amazon ECS resources within a specified target type and cluster. When you specify a target type and cluster, <code>ListAttributes</code> returns a list of attribute objects, one for each attribute on each resource. You can filter the list of results to a single attribute name to only return results that have that name. You can also filter the results by attribute name and value, for example, to see which container instances in a cluster are running a Linux AMI (<code>ecs.os-type=linux</code>). 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606497 = newJObject()
  var body_606498 = newJObject()
  add(query_606497, "nextToken", newJString(nextToken))
  if body != nil:
    body_606498 = body
  add(query_606497, "maxResults", newJString(maxResults))
  result = call_606496.call(nil, query_606497, nil, nil, body_606498)

var listAttributes* = Call_ListAttributes_606481(name: "listAttributes",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListAttributes",
    validator: validate_ListAttributes_606482, base: "/", url: url_ListAttributes_606483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_606500 = ref object of OpenApiRestCall_605589
proc url_ListClusters_606502(protocol: Scheme; host: string; base: string;
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

proc validate_ListClusters_606501(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606503 = query.getOrDefault("nextToken")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "nextToken", valid_606503
  var valid_606504 = query.getOrDefault("maxResults")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "maxResults", valid_606504
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606505 = header.getOrDefault("X-Amz-Target")
  valid_606505 = validateParameter(valid_606505, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListClusters"))
  if valid_606505 != nil:
    section.add "X-Amz-Target", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-Signature")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Signature", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-Content-Sha256", valid_606507
  var valid_606508 = header.getOrDefault("X-Amz-Date")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-Date", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Credential")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Credential", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-Security-Token")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Security-Token", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Algorithm")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Algorithm", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-SignedHeaders", valid_606512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606514: Call_ListClusters_606500; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing clusters.
  ## 
  let valid = call_606514.validator(path, query, header, formData, body)
  let scheme = call_606514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606514.url(scheme.get, call_606514.host, call_606514.base,
                         call_606514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606514, url, valid)

proc call*(call_606515: Call_ListClusters_606500; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listClusters
  ## Returns a list of existing clusters.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606516 = newJObject()
  var body_606517 = newJObject()
  add(query_606516, "nextToken", newJString(nextToken))
  if body != nil:
    body_606517 = body
  add(query_606516, "maxResults", newJString(maxResults))
  result = call_606515.call(nil, query_606516, nil, nil, body_606517)

var listClusters* = Call_ListClusters_606500(name: "listClusters",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListClusters",
    validator: validate_ListClusters_606501, base: "/", url: url_ListClusters_606502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContainerInstances_606518 = ref object of OpenApiRestCall_605589
proc url_ListContainerInstances_606520(protocol: Scheme; host: string; base: string;
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

proc validate_ListContainerInstances_606519(path: JsonNode; query: JsonNode;
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
  var valid_606521 = query.getOrDefault("nextToken")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "nextToken", valid_606521
  var valid_606522 = query.getOrDefault("maxResults")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "maxResults", valid_606522
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606523 = header.getOrDefault("X-Amz-Target")
  valid_606523 = validateParameter(valid_606523, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListContainerInstances"))
  if valid_606523 != nil:
    section.add "X-Amz-Target", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Signature")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Signature", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Content-Sha256", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Date")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Date", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-Credential")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-Credential", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-Security-Token")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-Security-Token", valid_606528
  var valid_606529 = header.getOrDefault("X-Amz-Algorithm")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Algorithm", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-SignedHeaders", valid_606530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606532: Call_ListContainerInstances_606518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of container instances in a specified cluster. You can filter the results of a <code>ListContainerInstances</code> operation with cluster query language statements inside the <code>filter</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html">Cluster Query Language</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_606532.validator(path, query, header, formData, body)
  let scheme = call_606532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606532.url(scheme.get, call_606532.host, call_606532.base,
                         call_606532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606532, url, valid)

proc call*(call_606533: Call_ListContainerInstances_606518; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listContainerInstances
  ## Returns a list of container instances in a specified cluster. You can filter the results of a <code>ListContainerInstances</code> operation with cluster query language statements inside the <code>filter</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html">Cluster Query Language</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606534 = newJObject()
  var body_606535 = newJObject()
  add(query_606534, "nextToken", newJString(nextToken))
  if body != nil:
    body_606535 = body
  add(query_606534, "maxResults", newJString(maxResults))
  result = call_606533.call(nil, query_606534, nil, nil, body_606535)

var listContainerInstances* = Call_ListContainerInstances_606518(
    name: "listContainerInstances", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListContainerInstances",
    validator: validate_ListContainerInstances_606519, base: "/",
    url: url_ListContainerInstances_606520, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServices_606536 = ref object of OpenApiRestCall_605589
proc url_ListServices_606538(protocol: Scheme; host: string; base: string;
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

proc validate_ListServices_606537(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606539 = query.getOrDefault("nextToken")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "nextToken", valid_606539
  var valid_606540 = query.getOrDefault("maxResults")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "maxResults", valid_606540
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606541 = header.getOrDefault("X-Amz-Target")
  valid_606541 = validateParameter(valid_606541, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListServices"))
  if valid_606541 != nil:
    section.add "X-Amz-Target", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-Signature")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Signature", valid_606542
  var valid_606543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-Content-Sha256", valid_606543
  var valid_606544 = header.getOrDefault("X-Amz-Date")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Date", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Credential")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Credential", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Security-Token")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Security-Token", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Algorithm")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Algorithm", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-SignedHeaders", valid_606548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606550: Call_ListServices_606536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the services that are running in a specified cluster.
  ## 
  let valid = call_606550.validator(path, query, header, formData, body)
  let scheme = call_606550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606550.url(scheme.get, call_606550.host, call_606550.base,
                         call_606550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606550, url, valid)

proc call*(call_606551: Call_ListServices_606536; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listServices
  ## Lists the services that are running in a specified cluster.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606552 = newJObject()
  var body_606553 = newJObject()
  add(query_606552, "nextToken", newJString(nextToken))
  if body != nil:
    body_606553 = body
  add(query_606552, "maxResults", newJString(maxResults))
  result = call_606551.call(nil, query_606552, nil, nil, body_606553)

var listServices* = Call_ListServices_606536(name: "listServices",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListServices",
    validator: validate_ListServices_606537, base: "/", url: url_ListServices_606538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606554 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606556(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606555(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606557 = header.getOrDefault("X-Amz-Target")
  valid_606557 = validateParameter(valid_606557, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTagsForResource"))
  if valid_606557 != nil:
    section.add "X-Amz-Target", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Signature")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Signature", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Content-Sha256", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Date")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Date", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Credential")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Credential", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Security-Token")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Security-Token", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Algorithm")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Algorithm", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-SignedHeaders", valid_606564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606566: Call_ListTagsForResource_606554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an Amazon ECS resource.
  ## 
  let valid = call_606566.validator(path, query, header, formData, body)
  let scheme = call_606566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606566.url(scheme.get, call_606566.host, call_606566.base,
                         call_606566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606566, url, valid)

proc call*(call_606567: Call_ListTagsForResource_606554; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon ECS resource.
  ##   body: JObject (required)
  var body_606568 = newJObject()
  if body != nil:
    body_606568 = body
  result = call_606567.call(nil, nil, nil, nil, body_606568)

var listTagsForResource* = Call_ListTagsForResource_606554(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTagsForResource",
    validator: validate_ListTagsForResource_606555, base: "/",
    url: url_ListTagsForResource_606556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTaskDefinitionFamilies_606569 = ref object of OpenApiRestCall_605589
proc url_ListTaskDefinitionFamilies_606571(protocol: Scheme; host: string;
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

proc validate_ListTaskDefinitionFamilies_606570(path: JsonNode; query: JsonNode;
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
  var valid_606572 = query.getOrDefault("nextToken")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "nextToken", valid_606572
  var valid_606573 = query.getOrDefault("maxResults")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "maxResults", valid_606573
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606574 = header.getOrDefault("X-Amz-Target")
  valid_606574 = validateParameter(valid_606574, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTaskDefinitionFamilies"))
  if valid_606574 != nil:
    section.add "X-Amz-Target", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Signature")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Signature", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Content-Sha256", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Date")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Date", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Credential")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Credential", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Security-Token")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Security-Token", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Algorithm")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Algorithm", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-SignedHeaders", valid_606581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606583: Call_ListTaskDefinitionFamilies_606569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of task definition families that are registered to your account (which may include task definition families that no longer have any <code>ACTIVE</code> task definition revisions).</p> <p>You can filter out task definition families that do not contain any <code>ACTIVE</code> task definition revisions by setting the <code>status</code> parameter to <code>ACTIVE</code>. You can also filter the results with the <code>familyPrefix</code> parameter.</p>
  ## 
  let valid = call_606583.validator(path, query, header, formData, body)
  let scheme = call_606583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606583.url(scheme.get, call_606583.host, call_606583.base,
                         call_606583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606583, url, valid)

proc call*(call_606584: Call_ListTaskDefinitionFamilies_606569; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTaskDefinitionFamilies
  ## <p>Returns a list of task definition families that are registered to your account (which may include task definition families that no longer have any <code>ACTIVE</code> task definition revisions).</p> <p>You can filter out task definition families that do not contain any <code>ACTIVE</code> task definition revisions by setting the <code>status</code> parameter to <code>ACTIVE</code>. You can also filter the results with the <code>familyPrefix</code> parameter.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606585 = newJObject()
  var body_606586 = newJObject()
  add(query_606585, "nextToken", newJString(nextToken))
  if body != nil:
    body_606586 = body
  add(query_606585, "maxResults", newJString(maxResults))
  result = call_606584.call(nil, query_606585, nil, nil, body_606586)

var listTaskDefinitionFamilies* = Call_ListTaskDefinitionFamilies_606569(
    name: "listTaskDefinitionFamilies", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTaskDefinitionFamilies",
    validator: validate_ListTaskDefinitionFamilies_606570, base: "/",
    url: url_ListTaskDefinitionFamilies_606571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTaskDefinitions_606587 = ref object of OpenApiRestCall_605589
proc url_ListTaskDefinitions_606589(protocol: Scheme; host: string; base: string;
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

proc validate_ListTaskDefinitions_606588(path: JsonNode; query: JsonNode;
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
  var valid_606590 = query.getOrDefault("nextToken")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "nextToken", valid_606590
  var valid_606591 = query.getOrDefault("maxResults")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "maxResults", valid_606591
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606592 = header.getOrDefault("X-Amz-Target")
  valid_606592 = validateParameter(valid_606592, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTaskDefinitions"))
  if valid_606592 != nil:
    section.add "X-Amz-Target", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Signature")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Signature", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Content-Sha256", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Date")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Date", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Credential")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Credential", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Security-Token")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Security-Token", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Algorithm")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Algorithm", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-SignedHeaders", valid_606599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606601: Call_ListTaskDefinitions_606587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of task definitions that are registered to your account. You can filter the results by family name with the <code>familyPrefix</code> parameter or by status with the <code>status</code> parameter.
  ## 
  let valid = call_606601.validator(path, query, header, formData, body)
  let scheme = call_606601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606601.url(scheme.get, call_606601.host, call_606601.base,
                         call_606601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606601, url, valid)

proc call*(call_606602: Call_ListTaskDefinitions_606587; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTaskDefinitions
  ## Returns a list of task definitions that are registered to your account. You can filter the results by family name with the <code>familyPrefix</code> parameter or by status with the <code>status</code> parameter.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606603 = newJObject()
  var body_606604 = newJObject()
  add(query_606603, "nextToken", newJString(nextToken))
  if body != nil:
    body_606604 = body
  add(query_606603, "maxResults", newJString(maxResults))
  result = call_606602.call(nil, query_606603, nil, nil, body_606604)

var listTaskDefinitions* = Call_ListTaskDefinitions_606587(
    name: "listTaskDefinitions", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTaskDefinitions",
    validator: validate_ListTaskDefinitions_606588, base: "/",
    url: url_ListTaskDefinitions_606589, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTasks_606605 = ref object of OpenApiRestCall_605589
proc url_ListTasks_606607(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTasks_606606(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606608 = query.getOrDefault("nextToken")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "nextToken", valid_606608
  var valid_606609 = query.getOrDefault("maxResults")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "maxResults", valid_606609
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606610 = header.getOrDefault("X-Amz-Target")
  valid_606610 = validateParameter(valid_606610, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTasks"))
  if valid_606610 != nil:
    section.add "X-Amz-Target", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Signature")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Signature", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Content-Sha256", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Date")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Date", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Credential")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Credential", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-Security-Token")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Security-Token", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Algorithm")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Algorithm", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-SignedHeaders", valid_606617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606619: Call_ListTasks_606605; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of tasks for a specified cluster. You can filter the results by family name, by a particular container instance, or by the desired status of the task with the <code>family</code>, <code>containerInstance</code>, and <code>desiredStatus</code> parameters.</p> <p>Recently stopped tasks might appear in the returned results. Currently, stopped tasks appear in the returned results for at least one hour. </p>
  ## 
  let valid = call_606619.validator(path, query, header, formData, body)
  let scheme = call_606619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606619.url(scheme.get, call_606619.host, call_606619.base,
                         call_606619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606619, url, valid)

proc call*(call_606620: Call_ListTasks_606605; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTasks
  ## <p>Returns a list of tasks for a specified cluster. You can filter the results by family name, by a particular container instance, or by the desired status of the task with the <code>family</code>, <code>containerInstance</code>, and <code>desiredStatus</code> parameters.</p> <p>Recently stopped tasks might appear in the returned results. Currently, stopped tasks appear in the returned results for at least one hour. </p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_606621 = newJObject()
  var body_606622 = newJObject()
  add(query_606621, "nextToken", newJString(nextToken))
  if body != nil:
    body_606622 = body
  add(query_606621, "maxResults", newJString(maxResults))
  result = call_606620.call(nil, query_606621, nil, nil, body_606622)

var listTasks* = Call_ListTasks_606605(name: "listTasks", meth: HttpMethod.HttpPost,
                                    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTasks",
                                    validator: validate_ListTasks_606606,
                                    base: "/", url: url_ListTasks_606607,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSetting_606623 = ref object of OpenApiRestCall_605589
proc url_PutAccountSetting_606625(protocol: Scheme; host: string; base: string;
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

proc validate_PutAccountSetting_606624(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606626 = header.getOrDefault("X-Amz-Target")
  valid_606626 = validateParameter(valid_606626, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutAccountSetting"))
  if valid_606626 != nil:
    section.add "X-Amz-Target", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Signature")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Signature", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Content-Sha256", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-Date")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Date", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-Credential")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Credential", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-Security-Token")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-Security-Token", valid_606631
  var valid_606632 = header.getOrDefault("X-Amz-Algorithm")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-Algorithm", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-SignedHeaders", valid_606633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606635: Call_PutAccountSetting_606623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies an account setting. Account settings are set on a per-Region basis.</p> <p>If you change the account setting for the root user, the default settings for all of the IAM users and roles for which no individual account setting has been specified are reset. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html">Account Settings</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>serviceLongArnFormat</code>, <code>taskLongArnFormat</code>, or <code>containerInstanceLongArnFormat</code> are specified, the Amazon Resource Name (ARN) and resource ID format of the resource type for a specified IAM user, IAM role, or the root user for an account is affected. The opt-in and opt-out account setting must be set for each Amazon ECS resource separately. The ARN and resource ID format of a resource will be defined by the opt-in status of the IAM user or role that created the resource. You must enable this setting to use Amazon ECS features such as resource tagging.</p> <p>When <code>awsvpcTrunking</code> is specified, the elastic network interface (ENI) limit for any new container instances that support the feature is changed. If <code>awsvpcTrunking</code> is enabled, any new container instances that support the feature are launched have the increased ENI limits available to them. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html">Elastic Network Interface Trunking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>containerInsights</code> is specified, the default setting indicating whether CloudWatch Container Insights is enabled for your clusters is changed. If <code>containerInsights</code> is enabled, any new clusters that are created will have Container Insights enabled unless you disable it during cluster creation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-container-insights.html">CloudWatch Container Insights</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_606635.validator(path, query, header, formData, body)
  let scheme = call_606635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606635.url(scheme.get, call_606635.host, call_606635.base,
                         call_606635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606635, url, valid)

proc call*(call_606636: Call_PutAccountSetting_606623; body: JsonNode): Recallable =
  ## putAccountSetting
  ## <p>Modifies an account setting. Account settings are set on a per-Region basis.</p> <p>If you change the account setting for the root user, the default settings for all of the IAM users and roles for which no individual account setting has been specified are reset. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html">Account Settings</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>serviceLongArnFormat</code>, <code>taskLongArnFormat</code>, or <code>containerInstanceLongArnFormat</code> are specified, the Amazon Resource Name (ARN) and resource ID format of the resource type for a specified IAM user, IAM role, or the root user for an account is affected. The opt-in and opt-out account setting must be set for each Amazon ECS resource separately. The ARN and resource ID format of a resource will be defined by the opt-in status of the IAM user or role that created the resource. You must enable this setting to use Amazon ECS features such as resource tagging.</p> <p>When <code>awsvpcTrunking</code> is specified, the elastic network interface (ENI) limit for any new container instances that support the feature is changed. If <code>awsvpcTrunking</code> is enabled, any new container instances that support the feature are launched have the increased ENI limits available to them. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html">Elastic Network Interface Trunking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>containerInsights</code> is specified, the default setting indicating whether CloudWatch Container Insights is enabled for your clusters is changed. If <code>containerInsights</code> is enabled, any new clusters that are created will have Container Insights enabled unless you disable it during cluster creation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-container-insights.html">CloudWatch Container Insights</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_606637 = newJObject()
  if body != nil:
    body_606637 = body
  result = call_606636.call(nil, nil, nil, nil, body_606637)

var putAccountSetting* = Call_PutAccountSetting_606623(name: "putAccountSetting",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAccountSetting",
    validator: validate_PutAccountSetting_606624, base: "/",
    url: url_PutAccountSetting_606625, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSettingDefault_606638 = ref object of OpenApiRestCall_605589
proc url_PutAccountSettingDefault_606640(protocol: Scheme; host: string;
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

proc validate_PutAccountSettingDefault_606639(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606641 = header.getOrDefault("X-Amz-Target")
  valid_606641 = validateParameter(valid_606641, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutAccountSettingDefault"))
  if valid_606641 != nil:
    section.add "X-Amz-Target", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Signature")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Signature", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Content-Sha256", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Date")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Date", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-Credential")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Credential", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-Security-Token")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-Security-Token", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-Algorithm")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Algorithm", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-SignedHeaders", valid_606648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606650: Call_PutAccountSettingDefault_606638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an account setting for all IAM users on an account for whom no individual account setting has been specified. Account settings are set on a per-Region basis.
  ## 
  let valid = call_606650.validator(path, query, header, formData, body)
  let scheme = call_606650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606650.url(scheme.get, call_606650.host, call_606650.base,
                         call_606650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606650, url, valid)

proc call*(call_606651: Call_PutAccountSettingDefault_606638; body: JsonNode): Recallable =
  ## putAccountSettingDefault
  ## Modifies an account setting for all IAM users on an account for whom no individual account setting has been specified. Account settings are set on a per-Region basis.
  ##   body: JObject (required)
  var body_606652 = newJObject()
  if body != nil:
    body_606652 = body
  result = call_606651.call(nil, nil, nil, nil, body_606652)

var putAccountSettingDefault* = Call_PutAccountSettingDefault_606638(
    name: "putAccountSettingDefault", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAccountSettingDefault",
    validator: validate_PutAccountSettingDefault_606639, base: "/",
    url: url_PutAccountSettingDefault_606640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAttributes_606653 = ref object of OpenApiRestCall_605589
proc url_PutAttributes_606655(protocol: Scheme; host: string; base: string;
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

proc validate_PutAttributes_606654(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606656 = header.getOrDefault("X-Amz-Target")
  valid_606656 = validateParameter(valid_606656, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutAttributes"))
  if valid_606656 != nil:
    section.add "X-Amz-Target", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Signature")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Signature", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Content-Sha256", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Date")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Date", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-Credential")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Credential", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-Security-Token")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-Security-Token", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-Algorithm")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-Algorithm", valid_606662
  var valid_606663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-SignedHeaders", valid_606663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606665: Call_PutAttributes_606653; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update an attribute on an Amazon ECS resource. If the attribute does not exist, it is created. If the attribute exists, its value is replaced with the specified value. To delete an attribute, use <a>DeleteAttributes</a>. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#attributes">Attributes</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_606665.validator(path, query, header, formData, body)
  let scheme = call_606665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606665.url(scheme.get, call_606665.host, call_606665.base,
                         call_606665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606665, url, valid)

proc call*(call_606666: Call_PutAttributes_606653; body: JsonNode): Recallable =
  ## putAttributes
  ## Create or update an attribute on an Amazon ECS resource. If the attribute does not exist, it is created. If the attribute exists, its value is replaced with the specified value. To delete an attribute, use <a>DeleteAttributes</a>. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#attributes">Attributes</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_606667 = newJObject()
  if body != nil:
    body_606667 = body
  result = call_606666.call(nil, nil, nil, nil, body_606667)

var putAttributes* = Call_PutAttributes_606653(name: "putAttributes",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAttributes",
    validator: validate_PutAttributes_606654, base: "/", url: url_PutAttributes_606655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutClusterCapacityProviders_606668 = ref object of OpenApiRestCall_605589
proc url_PutClusterCapacityProviders_606670(protocol: Scheme; host: string;
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

proc validate_PutClusterCapacityProviders_606669(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606671 = header.getOrDefault("X-Amz-Target")
  valid_606671 = validateParameter(valid_606671, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutClusterCapacityProviders"))
  if valid_606671 != nil:
    section.add "X-Amz-Target", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Signature")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Signature", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Content-Sha256", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Date")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Date", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Credential")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Credential", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Security-Token")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Security-Token", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-Algorithm")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Algorithm", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-SignedHeaders", valid_606678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606680: Call_PutClusterCapacityProviders_606668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the available capacity providers and the default capacity provider strategy for a cluster.</p> <p>You must specify both the available capacity providers and a default capacity provider strategy for the cluster. If the specified cluster has existing capacity providers associated with it, you must specify all existing capacity providers in addition to any new ones you want to add. Any existing capacity providers associated with a cluster that are omitted from a <a>PutClusterCapacityProviders</a> API call will be disassociated with the cluster. You can only disassociate an existing capacity provider from a cluster if it's not being used by any existing tasks.</p> <p>When creating a service or running a task on a cluster, if no capacity provider or launch type is specified, then the cluster's default capacity provider strategy is used. It is recommended to define a default capacity provider strategy for your cluster, however you may specify an empty array (<code>[]</code>) to bypass defining a default strategy.</p>
  ## 
  let valid = call_606680.validator(path, query, header, formData, body)
  let scheme = call_606680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606680.url(scheme.get, call_606680.host, call_606680.base,
                         call_606680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606680, url, valid)

proc call*(call_606681: Call_PutClusterCapacityProviders_606668; body: JsonNode): Recallable =
  ## putClusterCapacityProviders
  ## <p>Modifies the available capacity providers and the default capacity provider strategy for a cluster.</p> <p>You must specify both the available capacity providers and a default capacity provider strategy for the cluster. If the specified cluster has existing capacity providers associated with it, you must specify all existing capacity providers in addition to any new ones you want to add. Any existing capacity providers associated with a cluster that are omitted from a <a>PutClusterCapacityProviders</a> API call will be disassociated with the cluster. You can only disassociate an existing capacity provider from a cluster if it's not being used by any existing tasks.</p> <p>When creating a service or running a task on a cluster, if no capacity provider or launch type is specified, then the cluster's default capacity provider strategy is used. It is recommended to define a default capacity provider strategy for your cluster, however you may specify an empty array (<code>[]</code>) to bypass defining a default strategy.</p>
  ##   body: JObject (required)
  var body_606682 = newJObject()
  if body != nil:
    body_606682 = body
  result = call_606681.call(nil, nil, nil, nil, body_606682)

var putClusterCapacityProviders* = Call_PutClusterCapacityProviders_606668(
    name: "putClusterCapacityProviders", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutClusterCapacityProviders",
    validator: validate_PutClusterCapacityProviders_606669, base: "/",
    url: url_PutClusterCapacityProviders_606670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterContainerInstance_606683 = ref object of OpenApiRestCall_605589
proc url_RegisterContainerInstance_606685(protocol: Scheme; host: string;
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

proc validate_RegisterContainerInstance_606684(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606686 = header.getOrDefault("X-Amz-Target")
  valid_606686 = validateParameter(valid_606686, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.RegisterContainerInstance"))
  if valid_606686 != nil:
    section.add "X-Amz-Target", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-Signature")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Signature", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Content-Sha256", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Date")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Date", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Credential")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Credential", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Security-Token")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Security-Token", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-Algorithm")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-Algorithm", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-SignedHeaders", valid_606693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606695: Call_RegisterContainerInstance_606683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Registers an EC2 instance into the specified cluster. This instance becomes available to place containers on.</p>
  ## 
  let valid = call_606695.validator(path, query, header, formData, body)
  let scheme = call_606695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606695.url(scheme.get, call_606695.host, call_606695.base,
                         call_606695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606695, url, valid)

proc call*(call_606696: Call_RegisterContainerInstance_606683; body: JsonNode): Recallable =
  ## registerContainerInstance
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Registers an EC2 instance into the specified cluster. This instance becomes available to place containers on.</p>
  ##   body: JObject (required)
  var body_606697 = newJObject()
  if body != nil:
    body_606697 = body
  result = call_606696.call(nil, nil, nil, nil, body_606697)

var registerContainerInstance* = Call_RegisterContainerInstance_606683(
    name: "registerContainerInstance", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RegisterContainerInstance",
    validator: validate_RegisterContainerInstance_606684, base: "/",
    url: url_RegisterContainerInstance_606685,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskDefinition_606698 = ref object of OpenApiRestCall_605589
proc url_RegisterTaskDefinition_606700(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterTaskDefinition_606699(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606701 = header.getOrDefault("X-Amz-Target")
  valid_606701 = validateParameter(valid_606701, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.RegisterTaskDefinition"))
  if valid_606701 != nil:
    section.add "X-Amz-Target", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-Signature")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Signature", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Content-Sha256", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-Date")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Date", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Credential")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Credential", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Security-Token")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Security-Token", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-Algorithm")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Algorithm", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-SignedHeaders", valid_606708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606710: Call_RegisterTaskDefinition_606698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a new task definition from the supplied <code>family</code> and <code>containerDefinitions</code>. Optionally, you can add data volumes to your containers with the <code>volumes</code> parameter. For more information about task definition parameters and defaults, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_defintions.html">Amazon ECS Task Definitions</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify an IAM role for your task with the <code>taskRoleArn</code> parameter. When you specify an IAM role for a task, its containers can then use the latest versions of the AWS CLI or SDKs to make API requests to the AWS services that are specified in the IAM policy associated with the role. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html">IAM Roles for Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify a Docker networking mode for the containers in your task definition with the <code>networkMode</code> parameter. The available network modes correspond to those described in <a href="https://docs.docker.com/engine/reference/run/#/network-settings">Network settings</a> in the Docker run reference. If you specify the <code>awsvpc</code> network mode, the task is allocated an elastic network interface, and you must specify a <a>NetworkConfiguration</a> when you create a service or run a task with the task definition. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html">Task Networking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_606710.validator(path, query, header, formData, body)
  let scheme = call_606710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606710.url(scheme.get, call_606710.host, call_606710.base,
                         call_606710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606710, url, valid)

proc call*(call_606711: Call_RegisterTaskDefinition_606698; body: JsonNode): Recallable =
  ## registerTaskDefinition
  ## <p>Registers a new task definition from the supplied <code>family</code> and <code>containerDefinitions</code>. Optionally, you can add data volumes to your containers with the <code>volumes</code> parameter. For more information about task definition parameters and defaults, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_defintions.html">Amazon ECS Task Definitions</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify an IAM role for your task with the <code>taskRoleArn</code> parameter. When you specify an IAM role for a task, its containers can then use the latest versions of the AWS CLI or SDKs to make API requests to the AWS services that are specified in the IAM policy associated with the role. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html">IAM Roles for Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify a Docker networking mode for the containers in your task definition with the <code>networkMode</code> parameter. The available network modes correspond to those described in <a href="https://docs.docker.com/engine/reference/run/#/network-settings">Network settings</a> in the Docker run reference. If you specify the <code>awsvpc</code> network mode, the task is allocated an elastic network interface, and you must specify a <a>NetworkConfiguration</a> when you create a service or run a task with the task definition. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html">Task Networking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_606712 = newJObject()
  if body != nil:
    body_606712 = body
  result = call_606711.call(nil, nil, nil, nil, body_606712)

var registerTaskDefinition* = Call_RegisterTaskDefinition_606698(
    name: "registerTaskDefinition", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RegisterTaskDefinition",
    validator: validate_RegisterTaskDefinition_606699, base: "/",
    url: url_RegisterTaskDefinition_606700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RunTask_606713 = ref object of OpenApiRestCall_605589
proc url_RunTask_606715(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_RunTask_606714(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606716 = header.getOrDefault("X-Amz-Target")
  valid_606716 = validateParameter(valid_606716, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.RunTask"))
  if valid_606716 != nil:
    section.add "X-Amz-Target", valid_606716
  var valid_606717 = header.getOrDefault("X-Amz-Signature")
  valid_606717 = validateParameter(valid_606717, JString, required = false,
                                 default = nil)
  if valid_606717 != nil:
    section.add "X-Amz-Signature", valid_606717
  var valid_606718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "X-Amz-Content-Sha256", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-Date")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Date", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Credential")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Credential", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Security-Token")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Security-Token", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Algorithm")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Algorithm", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-SignedHeaders", valid_606723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606725: Call_RunTask_606713; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a new task using the specified task definition.</p> <p>You can allow Amazon ECS to place tasks for you, or you can customize how Amazon ECS places tasks using placement constraints and placement strategies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Alternatively, you can use <a>StartTask</a> to use your own scheduler or place tasks manually on specific container instances.</p> <p>The Amazon ECS API follows an eventual consistency model, due to the distributed nature of the system supporting the API. This means that the result of an API command you run that affects your Amazon ECS resources might not be immediately visible to all subsequent commands you run. Keep this in mind when you carry out an API command that immediately follows a previous API command.</p> <p>To manage eventual consistency, you can do the following:</p> <ul> <li> <p>Confirm the state of the resource before you run a command to modify it. Run the DescribeTasks command using an exponential backoff algorithm to ensure that you allow enough time for the previous command to propagate through the system. To do this, run the DescribeTasks command repeatedly, starting with a couple of seconds of wait time and increasing gradually up to five minutes of wait time.</p> </li> <li> <p>Add wait time between subsequent commands, even if the DescribeTasks command returns an accurate response. Apply an exponential backoff algorithm starting with a couple of seconds of wait time, and increase gradually up to about five minutes of wait time.</p> </li> </ul>
  ## 
  let valid = call_606725.validator(path, query, header, formData, body)
  let scheme = call_606725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606725.url(scheme.get, call_606725.host, call_606725.base,
                         call_606725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606725, url, valid)

proc call*(call_606726: Call_RunTask_606713; body: JsonNode): Recallable =
  ## runTask
  ## <p>Starts a new task using the specified task definition.</p> <p>You can allow Amazon ECS to place tasks for you, or you can customize how Amazon ECS places tasks using placement constraints and placement strategies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Alternatively, you can use <a>StartTask</a> to use your own scheduler or place tasks manually on specific container instances.</p> <p>The Amazon ECS API follows an eventual consistency model, due to the distributed nature of the system supporting the API. This means that the result of an API command you run that affects your Amazon ECS resources might not be immediately visible to all subsequent commands you run. Keep this in mind when you carry out an API command that immediately follows a previous API command.</p> <p>To manage eventual consistency, you can do the following:</p> <ul> <li> <p>Confirm the state of the resource before you run a command to modify it. Run the DescribeTasks command using an exponential backoff algorithm to ensure that you allow enough time for the previous command to propagate through the system. To do this, run the DescribeTasks command repeatedly, starting with a couple of seconds of wait time and increasing gradually up to five minutes of wait time.</p> </li> <li> <p>Add wait time between subsequent commands, even if the DescribeTasks command returns an accurate response. Apply an exponential backoff algorithm starting with a couple of seconds of wait time, and increase gradually up to about five minutes of wait time.</p> </li> </ul>
  ##   body: JObject (required)
  var body_606727 = newJObject()
  if body != nil:
    body_606727 = body
  result = call_606726.call(nil, nil, nil, nil, body_606727)

var runTask* = Call_RunTask_606713(name: "runTask", meth: HttpMethod.HttpPost,
                                host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RunTask",
                                validator: validate_RunTask_606714, base: "/",
                                url: url_RunTask_606715,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTask_606728 = ref object of OpenApiRestCall_605589
proc url_StartTask_606730(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StartTask_606729(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606731 = header.getOrDefault("X-Amz-Target")
  valid_606731 = validateParameter(valid_606731, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.StartTask"))
  if valid_606731 != nil:
    section.add "X-Amz-Target", valid_606731
  var valid_606732 = header.getOrDefault("X-Amz-Signature")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "X-Amz-Signature", valid_606732
  var valid_606733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606733 = validateParameter(valid_606733, JString, required = false,
                                 default = nil)
  if valid_606733 != nil:
    section.add "X-Amz-Content-Sha256", valid_606733
  var valid_606734 = header.getOrDefault("X-Amz-Date")
  valid_606734 = validateParameter(valid_606734, JString, required = false,
                                 default = nil)
  if valid_606734 != nil:
    section.add "X-Amz-Date", valid_606734
  var valid_606735 = header.getOrDefault("X-Amz-Credential")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Credential", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-Security-Token")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-Security-Token", valid_606736
  var valid_606737 = header.getOrDefault("X-Amz-Algorithm")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Algorithm", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-SignedHeaders", valid_606738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606740: Call_StartTask_606728; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a new task from the specified task definition on the specified container instance or instances.</p> <p>Alternatively, you can use <a>RunTask</a> to place tasks for you. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_606740.validator(path, query, header, formData, body)
  let scheme = call_606740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606740.url(scheme.get, call_606740.host, call_606740.base,
                         call_606740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606740, url, valid)

proc call*(call_606741: Call_StartTask_606728; body: JsonNode): Recallable =
  ## startTask
  ## <p>Starts a new task from the specified task definition on the specified container instance or instances.</p> <p>Alternatively, you can use <a>RunTask</a> to place tasks for you. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_606742 = newJObject()
  if body != nil:
    body_606742 = body
  result = call_606741.call(nil, nil, nil, nil, body_606742)

var startTask* = Call_StartTask_606728(name: "startTask", meth: HttpMethod.HttpPost,
                                    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.StartTask",
                                    validator: validate_StartTask_606729,
                                    base: "/", url: url_StartTask_606730,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTask_606743 = ref object of OpenApiRestCall_605589
proc url_StopTask_606745(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopTask_606744(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606746 = header.getOrDefault("X-Amz-Target")
  valid_606746 = validateParameter(valid_606746, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.StopTask"))
  if valid_606746 != nil:
    section.add "X-Amz-Target", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Signature")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Signature", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Content-Sha256", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Date")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Date", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Credential")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Credential", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-Security-Token")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-Security-Token", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-Algorithm")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-Algorithm", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-SignedHeaders", valid_606753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606755: Call_StopTask_606743; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a running task. Any tags associated with the task will be deleted.</p> <p>When <a>StopTask</a> is called on a task, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> value and a default 30-second timeout, after which the <code>SIGKILL</code> value is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> value gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> value is sent.</p> <note> <p>The default 30-second timeout can be configured on the Amazon ECS container agent with the <code>ECS_CONTAINER_STOP_TIMEOUT</code> variable. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html">Amazon ECS Container Agent Configuration</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_606755.validator(path, query, header, formData, body)
  let scheme = call_606755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606755.url(scheme.get, call_606755.host, call_606755.base,
                         call_606755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606755, url, valid)

proc call*(call_606756: Call_StopTask_606743; body: JsonNode): Recallable =
  ## stopTask
  ## <p>Stops a running task. Any tags associated with the task will be deleted.</p> <p>When <a>StopTask</a> is called on a task, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> value and a default 30-second timeout, after which the <code>SIGKILL</code> value is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> value gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> value is sent.</p> <note> <p>The default 30-second timeout can be configured on the Amazon ECS container agent with the <code>ECS_CONTAINER_STOP_TIMEOUT</code> variable. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html">Amazon ECS Container Agent Configuration</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_606757 = newJObject()
  if body != nil:
    body_606757 = body
  result = call_606756.call(nil, nil, nil, nil, body_606757)

var stopTask* = Call_StopTask_606743(name: "stopTask", meth: HttpMethod.HttpPost,
                                  host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.StopTask",
                                  validator: validate_StopTask_606744, base: "/",
                                  url: url_StopTask_606745,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitAttachmentStateChanges_606758 = ref object of OpenApiRestCall_605589
proc url_SubmitAttachmentStateChanges_606760(protocol: Scheme; host: string;
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

proc validate_SubmitAttachmentStateChanges_606759(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606761 = header.getOrDefault("X-Amz-Target")
  valid_606761 = validateParameter(valid_606761, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.SubmitAttachmentStateChanges"))
  if valid_606761 != nil:
    section.add "X-Amz-Target", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-Signature")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-Signature", valid_606762
  var valid_606763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Content-Sha256", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Date")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Date", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Credential")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Credential", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Security-Token")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Security-Token", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Algorithm")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Algorithm", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-SignedHeaders", valid_606768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606770: Call_SubmitAttachmentStateChanges_606758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that an attachment changed states.</p>
  ## 
  let valid = call_606770.validator(path, query, header, formData, body)
  let scheme = call_606770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606770.url(scheme.get, call_606770.host, call_606770.base,
                         call_606770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606770, url, valid)

proc call*(call_606771: Call_SubmitAttachmentStateChanges_606758; body: JsonNode): Recallable =
  ## submitAttachmentStateChanges
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that an attachment changed states.</p>
  ##   body: JObject (required)
  var body_606772 = newJObject()
  if body != nil:
    body_606772 = body
  result = call_606771.call(nil, nil, nil, nil, body_606772)

var submitAttachmentStateChanges* = Call_SubmitAttachmentStateChanges_606758(
    name: "submitAttachmentStateChanges", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitAttachmentStateChanges",
    validator: validate_SubmitAttachmentStateChanges_606759, base: "/",
    url: url_SubmitAttachmentStateChanges_606760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitContainerStateChange_606773 = ref object of OpenApiRestCall_605589
proc url_SubmitContainerStateChange_606775(protocol: Scheme; host: string;
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

proc validate_SubmitContainerStateChange_606774(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606776 = header.getOrDefault("X-Amz-Target")
  valid_606776 = validateParameter(valid_606776, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.SubmitContainerStateChange"))
  if valid_606776 != nil:
    section.add "X-Amz-Target", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-Signature")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Signature", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Content-Sha256", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Date")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Date", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Credential")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Credential", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Security-Token")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Security-Token", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Algorithm")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Algorithm", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-SignedHeaders", valid_606783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606785: Call_SubmitContainerStateChange_606773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a container changed states.</p>
  ## 
  let valid = call_606785.validator(path, query, header, formData, body)
  let scheme = call_606785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606785.url(scheme.get, call_606785.host, call_606785.base,
                         call_606785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606785, url, valid)

proc call*(call_606786: Call_SubmitContainerStateChange_606773; body: JsonNode): Recallable =
  ## submitContainerStateChange
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a container changed states.</p>
  ##   body: JObject (required)
  var body_606787 = newJObject()
  if body != nil:
    body_606787 = body
  result = call_606786.call(nil, nil, nil, nil, body_606787)

var submitContainerStateChange* = Call_SubmitContainerStateChange_606773(
    name: "submitContainerStateChange", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitContainerStateChange",
    validator: validate_SubmitContainerStateChange_606774, base: "/",
    url: url_SubmitContainerStateChange_606775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitTaskStateChange_606788 = ref object of OpenApiRestCall_605589
proc url_SubmitTaskStateChange_606790(protocol: Scheme; host: string; base: string;
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

proc validate_SubmitTaskStateChange_606789(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606791 = header.getOrDefault("X-Amz-Target")
  valid_606791 = validateParameter(valid_606791, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.SubmitTaskStateChange"))
  if valid_606791 != nil:
    section.add "X-Amz-Target", valid_606791
  var valid_606792 = header.getOrDefault("X-Amz-Signature")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "X-Amz-Signature", valid_606792
  var valid_606793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-Content-Sha256", valid_606793
  var valid_606794 = header.getOrDefault("X-Amz-Date")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Date", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Credential")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Credential", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Security-Token")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Security-Token", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Algorithm")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Algorithm", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-SignedHeaders", valid_606798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606800: Call_SubmitTaskStateChange_606788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a task changed states.</p>
  ## 
  let valid = call_606800.validator(path, query, header, formData, body)
  let scheme = call_606800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606800.url(scheme.get, call_606800.host, call_606800.base,
                         call_606800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606800, url, valid)

proc call*(call_606801: Call_SubmitTaskStateChange_606788; body: JsonNode): Recallable =
  ## submitTaskStateChange
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a task changed states.</p>
  ##   body: JObject (required)
  var body_606802 = newJObject()
  if body != nil:
    body_606802 = body
  result = call_606801.call(nil, nil, nil, nil, body_606802)

var submitTaskStateChange* = Call_SubmitTaskStateChange_606788(
    name: "submitTaskStateChange", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitTaskStateChange",
    validator: validate_SubmitTaskStateChange_606789, base: "/",
    url: url_SubmitTaskStateChange_606790, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606803 = ref object of OpenApiRestCall_605589
proc url_TagResource_606805(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606804(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606806 = header.getOrDefault("X-Amz-Target")
  valid_606806 = validateParameter(valid_606806, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.TagResource"))
  if valid_606806 != nil:
    section.add "X-Amz-Target", valid_606806
  var valid_606807 = header.getOrDefault("X-Amz-Signature")
  valid_606807 = validateParameter(valid_606807, JString, required = false,
                                 default = nil)
  if valid_606807 != nil:
    section.add "X-Amz-Signature", valid_606807
  var valid_606808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606808 = validateParameter(valid_606808, JString, required = false,
                                 default = nil)
  if valid_606808 != nil:
    section.add "X-Amz-Content-Sha256", valid_606808
  var valid_606809 = header.getOrDefault("X-Amz-Date")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Date", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Credential")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Credential", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Security-Token")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Security-Token", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Algorithm")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Algorithm", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-SignedHeaders", valid_606813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606815: Call_TagResource_606803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_606815.validator(path, query, header, formData, body)
  let scheme = call_606815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606815.url(scheme.get, call_606815.host, call_606815.base,
                         call_606815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606815, url, valid)

proc call*(call_606816: Call_TagResource_606803; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  var body_606817 = newJObject()
  if body != nil:
    body_606817 = body
  result = call_606816.call(nil, nil, nil, nil, body_606817)

var tagResource* = Call_TagResource_606803(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.TagResource",
                                        validator: validate_TagResource_606804,
                                        base: "/", url: url_TagResource_606805,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606818 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606820(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606819(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606821 = header.getOrDefault("X-Amz-Target")
  valid_606821 = validateParameter(valid_606821, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UntagResource"))
  if valid_606821 != nil:
    section.add "X-Amz-Target", valid_606821
  var valid_606822 = header.getOrDefault("X-Amz-Signature")
  valid_606822 = validateParameter(valid_606822, JString, required = false,
                                 default = nil)
  if valid_606822 != nil:
    section.add "X-Amz-Signature", valid_606822
  var valid_606823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606823 = validateParameter(valid_606823, JString, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "X-Amz-Content-Sha256", valid_606823
  var valid_606824 = header.getOrDefault("X-Amz-Date")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-Date", valid_606824
  var valid_606825 = header.getOrDefault("X-Amz-Credential")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Credential", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-Security-Token")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Security-Token", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Algorithm")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Algorithm", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-SignedHeaders", valid_606828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606830: Call_UntagResource_606818; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_606830.validator(path, query, header, formData, body)
  let scheme = call_606830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606830.url(scheme.get, call_606830.host, call_606830.base,
                         call_606830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606830, url, valid)

proc call*(call_606831: Call_UntagResource_606818; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  var body_606832 = newJObject()
  if body != nil:
    body_606832 = body
  result = call_606831.call(nil, nil, nil, nil, body_606832)

var untagResource* = Call_UntagResource_606818(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UntagResource",
    validator: validate_UntagResource_606819, base: "/", url: url_UntagResource_606820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterSettings_606833 = ref object of OpenApiRestCall_605589
proc url_UpdateClusterSettings_606835(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClusterSettings_606834(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606836 = header.getOrDefault("X-Amz-Target")
  valid_606836 = validateParameter(valid_606836, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateClusterSettings"))
  if valid_606836 != nil:
    section.add "X-Amz-Target", valid_606836
  var valid_606837 = header.getOrDefault("X-Amz-Signature")
  valid_606837 = validateParameter(valid_606837, JString, required = false,
                                 default = nil)
  if valid_606837 != nil:
    section.add "X-Amz-Signature", valid_606837
  var valid_606838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606838 = validateParameter(valid_606838, JString, required = false,
                                 default = nil)
  if valid_606838 != nil:
    section.add "X-Amz-Content-Sha256", valid_606838
  var valid_606839 = header.getOrDefault("X-Amz-Date")
  valid_606839 = validateParameter(valid_606839, JString, required = false,
                                 default = nil)
  if valid_606839 != nil:
    section.add "X-Amz-Date", valid_606839
  var valid_606840 = header.getOrDefault("X-Amz-Credential")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "X-Amz-Credential", valid_606840
  var valid_606841 = header.getOrDefault("X-Amz-Security-Token")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Security-Token", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Algorithm")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Algorithm", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-SignedHeaders", valid_606843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606845: Call_UpdateClusterSettings_606833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the settings to use for a cluster.
  ## 
  let valid = call_606845.validator(path, query, header, formData, body)
  let scheme = call_606845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606845.url(scheme.get, call_606845.host, call_606845.base,
                         call_606845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606845, url, valid)

proc call*(call_606846: Call_UpdateClusterSettings_606833; body: JsonNode): Recallable =
  ## updateClusterSettings
  ## Modifies the settings to use for a cluster.
  ##   body: JObject (required)
  var body_606847 = newJObject()
  if body != nil:
    body_606847 = body
  result = call_606846.call(nil, nil, nil, nil, body_606847)

var updateClusterSettings* = Call_UpdateClusterSettings_606833(
    name: "updateClusterSettings", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateClusterSettings",
    validator: validate_UpdateClusterSettings_606834, base: "/",
    url: url_UpdateClusterSettings_606835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContainerAgent_606848 = ref object of OpenApiRestCall_605589
proc url_UpdateContainerAgent_606850(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateContainerAgent_606849(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606851 = header.getOrDefault("X-Amz-Target")
  valid_606851 = validateParameter(valid_606851, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateContainerAgent"))
  if valid_606851 != nil:
    section.add "X-Amz-Target", valid_606851
  var valid_606852 = header.getOrDefault("X-Amz-Signature")
  valid_606852 = validateParameter(valid_606852, JString, required = false,
                                 default = nil)
  if valid_606852 != nil:
    section.add "X-Amz-Signature", valid_606852
  var valid_606853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606853 = validateParameter(valid_606853, JString, required = false,
                                 default = nil)
  if valid_606853 != nil:
    section.add "X-Amz-Content-Sha256", valid_606853
  var valid_606854 = header.getOrDefault("X-Amz-Date")
  valid_606854 = validateParameter(valid_606854, JString, required = false,
                                 default = nil)
  if valid_606854 != nil:
    section.add "X-Amz-Date", valid_606854
  var valid_606855 = header.getOrDefault("X-Amz-Credential")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "X-Amz-Credential", valid_606855
  var valid_606856 = header.getOrDefault("X-Amz-Security-Token")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Security-Token", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Algorithm")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Algorithm", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-SignedHeaders", valid_606858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606860: Call_UpdateContainerAgent_606848; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Amazon ECS container agent on a specified container instance. Updating the Amazon ECS container agent does not interrupt running tasks or services on the container instance. The process for updating the agent differs depending on whether your container instance was launched with the Amazon ECS-optimized AMI or another operating system.</p> <p> <code>UpdateContainerAgent</code> requires the Amazon ECS-optimized AMI or Amazon Linux with the <code>ecs-init</code> service installed and running. For help updating the Amazon ECS container agent on other operating systems, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-update.html#manually_update_agent">Manually Updating the Amazon ECS Container Agent</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_606860.validator(path, query, header, formData, body)
  let scheme = call_606860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606860.url(scheme.get, call_606860.host, call_606860.base,
                         call_606860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606860, url, valid)

proc call*(call_606861: Call_UpdateContainerAgent_606848; body: JsonNode): Recallable =
  ## updateContainerAgent
  ## <p>Updates the Amazon ECS container agent on a specified container instance. Updating the Amazon ECS container agent does not interrupt running tasks or services on the container instance. The process for updating the agent differs depending on whether your container instance was launched with the Amazon ECS-optimized AMI or another operating system.</p> <p> <code>UpdateContainerAgent</code> requires the Amazon ECS-optimized AMI or Amazon Linux with the <code>ecs-init</code> service installed and running. For help updating the Amazon ECS container agent on other operating systems, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-update.html#manually_update_agent">Manually Updating the Amazon ECS Container Agent</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_606862 = newJObject()
  if body != nil:
    body_606862 = body
  result = call_606861.call(nil, nil, nil, nil, body_606862)

var updateContainerAgent* = Call_UpdateContainerAgent_606848(
    name: "updateContainerAgent", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateContainerAgent",
    validator: validate_UpdateContainerAgent_606849, base: "/",
    url: url_UpdateContainerAgent_606850, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContainerInstancesState_606863 = ref object of OpenApiRestCall_605589
proc url_UpdateContainerInstancesState_606865(protocol: Scheme; host: string;
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

proc validate_UpdateContainerInstancesState_606864(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606866 = header.getOrDefault("X-Amz-Target")
  valid_606866 = validateParameter(valid_606866, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateContainerInstancesState"))
  if valid_606866 != nil:
    section.add "X-Amz-Target", valid_606866
  var valid_606867 = header.getOrDefault("X-Amz-Signature")
  valid_606867 = validateParameter(valid_606867, JString, required = false,
                                 default = nil)
  if valid_606867 != nil:
    section.add "X-Amz-Signature", valid_606867
  var valid_606868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606868 = validateParameter(valid_606868, JString, required = false,
                                 default = nil)
  if valid_606868 != nil:
    section.add "X-Amz-Content-Sha256", valid_606868
  var valid_606869 = header.getOrDefault("X-Amz-Date")
  valid_606869 = validateParameter(valid_606869, JString, required = false,
                                 default = nil)
  if valid_606869 != nil:
    section.add "X-Amz-Date", valid_606869
  var valid_606870 = header.getOrDefault("X-Amz-Credential")
  valid_606870 = validateParameter(valid_606870, JString, required = false,
                                 default = nil)
  if valid_606870 != nil:
    section.add "X-Amz-Credential", valid_606870
  var valid_606871 = header.getOrDefault("X-Amz-Security-Token")
  valid_606871 = validateParameter(valid_606871, JString, required = false,
                                 default = nil)
  if valid_606871 != nil:
    section.add "X-Amz-Security-Token", valid_606871
  var valid_606872 = header.getOrDefault("X-Amz-Algorithm")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-Algorithm", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-SignedHeaders", valid_606873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606875: Call_UpdateContainerInstancesState_606863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the status of an Amazon ECS container instance.</p> <p>Once a container instance has reached an <code>ACTIVE</code> state, you can change the status of a container instance to <code>DRAINING</code> to manually remove an instance from a cluster, for example to perform system updates, update the Docker daemon, or scale down the cluster size.</p> <important> <p>A container instance cannot be changed to <code>DRAINING</code> until it has reached an <code>ACTIVE</code> status. If the instance is in any other status, an error will be received.</p> </important> <p>When you set a container instance to <code>DRAINING</code>, Amazon ECS prevents new tasks from being scheduled for placement on the container instance and replacement service tasks are started on other container instances in the cluster if the resources are available. Service tasks on the container instance that are in the <code>PENDING</code> state are stopped immediately.</p> <p>Service tasks on the container instance that are in the <code>RUNNING</code> state are stopped and replaced according to the service's deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>. You can change the deployment configuration of your service using <a>UpdateService</a>.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during task replacement. For example, <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. If the minimum is 100%, the service scheduler can't remove existing tasks until the replacement tasks are considered healthy. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during task replacement, which enables you to define the replacement batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four tasks to be drained, provided that the cluster resources required to do this are available. If the maximum is 100%, then replacement tasks can't start until the draining tasks have stopped.</p> </li> </ul> <p>Any <code>PENDING</code> or <code>RUNNING</code> tasks that do not belong to a service are not affected. You must wait for them to finish or stop them manually.</p> <p>A container instance has completed draining when it has no more <code>RUNNING</code> tasks. You can verify this using <a>ListTasks</a>.</p> <p>When a container instance has been drained, you can set a container instance to <code>ACTIVE</code> status and once it has reached that status the Amazon ECS scheduler can begin scheduling tasks on the instance again.</p>
  ## 
  let valid = call_606875.validator(path, query, header, formData, body)
  let scheme = call_606875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606875.url(scheme.get, call_606875.host, call_606875.base,
                         call_606875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606875, url, valid)

proc call*(call_606876: Call_UpdateContainerInstancesState_606863; body: JsonNode): Recallable =
  ## updateContainerInstancesState
  ## <p>Modifies the status of an Amazon ECS container instance.</p> <p>Once a container instance has reached an <code>ACTIVE</code> state, you can change the status of a container instance to <code>DRAINING</code> to manually remove an instance from a cluster, for example to perform system updates, update the Docker daemon, or scale down the cluster size.</p> <important> <p>A container instance cannot be changed to <code>DRAINING</code> until it has reached an <code>ACTIVE</code> status. If the instance is in any other status, an error will be received.</p> </important> <p>When you set a container instance to <code>DRAINING</code>, Amazon ECS prevents new tasks from being scheduled for placement on the container instance and replacement service tasks are started on other container instances in the cluster if the resources are available. Service tasks on the container instance that are in the <code>PENDING</code> state are stopped immediately.</p> <p>Service tasks on the container instance that are in the <code>RUNNING</code> state are stopped and replaced according to the service's deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>. You can change the deployment configuration of your service using <a>UpdateService</a>.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during task replacement. For example, <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. If the minimum is 100%, the service scheduler can't remove existing tasks until the replacement tasks are considered healthy. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during task replacement, which enables you to define the replacement batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four tasks to be drained, provided that the cluster resources required to do this are available. If the maximum is 100%, then replacement tasks can't start until the draining tasks have stopped.</p> </li> </ul> <p>Any <code>PENDING</code> or <code>RUNNING</code> tasks that do not belong to a service are not affected. You must wait for them to finish or stop them manually.</p> <p>A container instance has completed draining when it has no more <code>RUNNING</code> tasks. You can verify this using <a>ListTasks</a>.</p> <p>When a container instance has been drained, you can set a container instance to <code>ACTIVE</code> status and once it has reached that status the Amazon ECS scheduler can begin scheduling tasks on the instance again.</p>
  ##   body: JObject (required)
  var body_606877 = newJObject()
  if body != nil:
    body_606877 = body
  result = call_606876.call(nil, nil, nil, nil, body_606877)

var updateContainerInstancesState* = Call_UpdateContainerInstancesState_606863(
    name: "updateContainerInstancesState", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateContainerInstancesState",
    validator: validate_UpdateContainerInstancesState_606864, base: "/",
    url: url_UpdateContainerInstancesState_606865,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateService_606878 = ref object of OpenApiRestCall_605589
proc url_UpdateService_606880(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateService_606879(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606881 = header.getOrDefault("X-Amz-Target")
  valid_606881 = validateParameter(valid_606881, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateService"))
  if valid_606881 != nil:
    section.add "X-Amz-Target", valid_606881
  var valid_606882 = header.getOrDefault("X-Amz-Signature")
  valid_606882 = validateParameter(valid_606882, JString, required = false,
                                 default = nil)
  if valid_606882 != nil:
    section.add "X-Amz-Signature", valid_606882
  var valid_606883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606883 = validateParameter(valid_606883, JString, required = false,
                                 default = nil)
  if valid_606883 != nil:
    section.add "X-Amz-Content-Sha256", valid_606883
  var valid_606884 = header.getOrDefault("X-Amz-Date")
  valid_606884 = validateParameter(valid_606884, JString, required = false,
                                 default = nil)
  if valid_606884 != nil:
    section.add "X-Amz-Date", valid_606884
  var valid_606885 = header.getOrDefault("X-Amz-Credential")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Credential", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Security-Token")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Security-Token", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-Algorithm")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-Algorithm", valid_606887
  var valid_606888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-SignedHeaders", valid_606888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606890: Call_UpdateService_606878; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the parameters of a service.</p> <p>For services using the rolling update (<code>ECS</code>) deployment controller, the desired count, deployment configuration, network configuration, or task definition used can be updated.</p> <p>For services using the blue/green (<code>CODE_DEPLOY</code>) deployment controller, only the desired count, deployment configuration, and health check grace period can be updated using this API. If the network configuration, platform version, or task definition need to be updated, a new AWS CodeDeploy deployment should be created. For more information, see <a href="https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html">CreateDeployment</a> in the <i>AWS CodeDeploy API Reference</i>.</p> <p>For services using an external deployment controller, you can update only the desired count and health check grace period using this API. If the launch type, load balancer, network configuration, platform version, or task definition need to be updated, you should create a new task set. For more information, see <a>CreateTaskSet</a>.</p> <p>You can add to or subtract from the number of instantiations of a task definition in a service by specifying the cluster that the service is running in and a new <code>desiredCount</code> parameter.</p> <p>If you have updated the Docker image of your application, you can create a new task definition with that image and deploy it to your service. The service scheduler uses the minimum healthy percent and maximum percent parameters (in the service's deployment configuration) to determine the deployment strategy.</p> <note> <p>If your updated Docker image uses the same tag as what is in the existing task definition for your service (for example, <code>my_image:latest</code>), you do not need to create a new revision of your task definition. You can update the service using the <code>forceNewDeployment</code> option. The new tasks launched by the deployment pull the current image/tag combination from your repository when they start.</p> </note> <p>You can also update the deployment configuration of a service. When a deployment is triggered by updating the task definition of a service, the service scheduler uses the deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>, to determine the deployment strategy.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during a deployment. For example, if <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during a deployment, which enables you to define the deployment batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available).</p> </li> </ul> <p>When <a>UpdateService</a> stops a task during a deployment, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> and a 30-second timeout, after which <code>SIGKILL</code> is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> is sent.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster with the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy):</p> <ul> <li> <p>Sort the valid container instances by the fewest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul> <p>When the service scheduler stops running tasks, it attempts to maintain balance across the Availability Zones in your cluster using the following logic: </p> <ul> <li> <p>Sort the container instances by the largest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have two, container instances in either zone B or C are considered optimal for termination.</p> </li> <li> <p>Stop the task on a container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the largest number of running tasks for this service.</p> </li> </ul>
  ## 
  let valid = call_606890.validator(path, query, header, formData, body)
  let scheme = call_606890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606890.url(scheme.get, call_606890.host, call_606890.base,
                         call_606890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606890, url, valid)

proc call*(call_606891: Call_UpdateService_606878; body: JsonNode): Recallable =
  ## updateService
  ## <p>Modifies the parameters of a service.</p> <p>For services using the rolling update (<code>ECS</code>) deployment controller, the desired count, deployment configuration, network configuration, or task definition used can be updated.</p> <p>For services using the blue/green (<code>CODE_DEPLOY</code>) deployment controller, only the desired count, deployment configuration, and health check grace period can be updated using this API. If the network configuration, platform version, or task definition need to be updated, a new AWS CodeDeploy deployment should be created. For more information, see <a href="https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html">CreateDeployment</a> in the <i>AWS CodeDeploy API Reference</i>.</p> <p>For services using an external deployment controller, you can update only the desired count and health check grace period using this API. If the launch type, load balancer, network configuration, platform version, or task definition need to be updated, you should create a new task set. For more information, see <a>CreateTaskSet</a>.</p> <p>You can add to or subtract from the number of instantiations of a task definition in a service by specifying the cluster that the service is running in and a new <code>desiredCount</code> parameter.</p> <p>If you have updated the Docker image of your application, you can create a new task definition with that image and deploy it to your service. The service scheduler uses the minimum healthy percent and maximum percent parameters (in the service's deployment configuration) to determine the deployment strategy.</p> <note> <p>If your updated Docker image uses the same tag as what is in the existing task definition for your service (for example, <code>my_image:latest</code>), you do not need to create a new revision of your task definition. You can update the service using the <code>forceNewDeployment</code> option. The new tasks launched by the deployment pull the current image/tag combination from your repository when they start.</p> </note> <p>You can also update the deployment configuration of a service. When a deployment is triggered by updating the task definition of a service, the service scheduler uses the deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>, to determine the deployment strategy.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during a deployment. For example, if <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during a deployment, which enables you to define the deployment batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available).</p> </li> </ul> <p>When <a>UpdateService</a> stops a task during a deployment, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> and a 30-second timeout, after which <code>SIGKILL</code> is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> is sent.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster with the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy):</p> <ul> <li> <p>Sort the valid container instances by the fewest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul> <p>When the service scheduler stops running tasks, it attempts to maintain balance across the Availability Zones in your cluster using the following logic: </p> <ul> <li> <p>Sort the container instances by the largest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have two, container instances in either zone B or C are considered optimal for termination.</p> </li> <li> <p>Stop the task on a container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the largest number of running tasks for this service.</p> </li> </ul>
  ##   body: JObject (required)
  var body_606892 = newJObject()
  if body != nil:
    body_606892 = body
  result = call_606891.call(nil, nil, nil, nil, body_606892)

var updateService* = Call_UpdateService_606878(name: "updateService",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateService",
    validator: validate_UpdateService_606879, base: "/", url: url_UpdateService_606880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServicePrimaryTaskSet_606893 = ref object of OpenApiRestCall_605589
proc url_UpdateServicePrimaryTaskSet_606895(protocol: Scheme; host: string;
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

proc validate_UpdateServicePrimaryTaskSet_606894(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606896 = header.getOrDefault("X-Amz-Target")
  valid_606896 = validateParameter(valid_606896, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateServicePrimaryTaskSet"))
  if valid_606896 != nil:
    section.add "X-Amz-Target", valid_606896
  var valid_606897 = header.getOrDefault("X-Amz-Signature")
  valid_606897 = validateParameter(valid_606897, JString, required = false,
                                 default = nil)
  if valid_606897 != nil:
    section.add "X-Amz-Signature", valid_606897
  var valid_606898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-Content-Sha256", valid_606898
  var valid_606899 = header.getOrDefault("X-Amz-Date")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Date", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Credential")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Credential", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Security-Token")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Security-Token", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-Algorithm")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-Algorithm", valid_606902
  var valid_606903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "X-Amz-SignedHeaders", valid_606903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606905: Call_UpdateServicePrimaryTaskSet_606893; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies which task set in a service is the primary task set. Any parameters that are updated on the primary task set in a service will transition to the service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_606905.validator(path, query, header, formData, body)
  let scheme = call_606905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606905.url(scheme.get, call_606905.host, call_606905.base,
                         call_606905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606905, url, valid)

proc call*(call_606906: Call_UpdateServicePrimaryTaskSet_606893; body: JsonNode): Recallable =
  ## updateServicePrimaryTaskSet
  ## Modifies which task set in a service is the primary task set. Any parameters that are updated on the primary task set in a service will transition to the service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_606907 = newJObject()
  if body != nil:
    body_606907 = body
  result = call_606906.call(nil, nil, nil, nil, body_606907)

var updateServicePrimaryTaskSet* = Call_UpdateServicePrimaryTaskSet_606893(
    name: "updateServicePrimaryTaskSet", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateServicePrimaryTaskSet",
    validator: validate_UpdateServicePrimaryTaskSet_606894, base: "/",
    url: url_UpdateServicePrimaryTaskSet_606895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTaskSet_606908 = ref object of OpenApiRestCall_605589
proc url_UpdateTaskSet_606910(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTaskSet_606909(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606911 = header.getOrDefault("X-Amz-Target")
  valid_606911 = validateParameter(valid_606911, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateTaskSet"))
  if valid_606911 != nil:
    section.add "X-Amz-Target", valid_606911
  var valid_606912 = header.getOrDefault("X-Amz-Signature")
  valid_606912 = validateParameter(valid_606912, JString, required = false,
                                 default = nil)
  if valid_606912 != nil:
    section.add "X-Amz-Signature", valid_606912
  var valid_606913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606913 = validateParameter(valid_606913, JString, required = false,
                                 default = nil)
  if valid_606913 != nil:
    section.add "X-Amz-Content-Sha256", valid_606913
  var valid_606914 = header.getOrDefault("X-Amz-Date")
  valid_606914 = validateParameter(valid_606914, JString, required = false,
                                 default = nil)
  if valid_606914 != nil:
    section.add "X-Amz-Date", valid_606914
  var valid_606915 = header.getOrDefault("X-Amz-Credential")
  valid_606915 = validateParameter(valid_606915, JString, required = false,
                                 default = nil)
  if valid_606915 != nil:
    section.add "X-Amz-Credential", valid_606915
  var valid_606916 = header.getOrDefault("X-Amz-Security-Token")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = nil)
  if valid_606916 != nil:
    section.add "X-Amz-Security-Token", valid_606916
  var valid_606917 = header.getOrDefault("X-Amz-Algorithm")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-Algorithm", valid_606917
  var valid_606918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-SignedHeaders", valid_606918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606920: Call_UpdateTaskSet_606908; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a task set. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_606920.validator(path, query, header, formData, body)
  let scheme = call_606920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606920.url(scheme.get, call_606920.host, call_606920.base,
                         call_606920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606920, url, valid)

proc call*(call_606921: Call_UpdateTaskSet_606908; body: JsonNode): Recallable =
  ## updateTaskSet
  ## Modifies a task set. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_606922 = newJObject()
  if body != nil:
    body_606922 = body
  result = call_606921.call(nil, nil, nil, nil, body_606922)

var updateTaskSet* = Call_UpdateTaskSet_606908(name: "updateTaskSet",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateTaskSet",
    validator: validate_UpdateTaskSet_606909, base: "/", url: url_UpdateTaskSet_606910,
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
