
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

  OpenApiRestCall_597389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597389): Option[Scheme] {.used.} =
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
  Call_CreateCapacityProvider_597727 = ref object of OpenApiRestCall_597389
proc url_CreateCapacityProvider_597729(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCapacityProvider_597728(path: JsonNode; query: JsonNode;
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
  var valid_597854 = header.getOrDefault("X-Amz-Target")
  valid_597854 = validateParameter(valid_597854, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateCapacityProvider"))
  if valid_597854 != nil:
    section.add "X-Amz-Target", valid_597854
  var valid_597855 = header.getOrDefault("X-Amz-Signature")
  valid_597855 = validateParameter(valid_597855, JString, required = false,
                                 default = nil)
  if valid_597855 != nil:
    section.add "X-Amz-Signature", valid_597855
  var valid_597856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597856 = validateParameter(valid_597856, JString, required = false,
                                 default = nil)
  if valid_597856 != nil:
    section.add "X-Amz-Content-Sha256", valid_597856
  var valid_597857 = header.getOrDefault("X-Amz-Date")
  valid_597857 = validateParameter(valid_597857, JString, required = false,
                                 default = nil)
  if valid_597857 != nil:
    section.add "X-Amz-Date", valid_597857
  var valid_597858 = header.getOrDefault("X-Amz-Credential")
  valid_597858 = validateParameter(valid_597858, JString, required = false,
                                 default = nil)
  if valid_597858 != nil:
    section.add "X-Amz-Credential", valid_597858
  var valid_597859 = header.getOrDefault("X-Amz-Security-Token")
  valid_597859 = validateParameter(valid_597859, JString, required = false,
                                 default = nil)
  if valid_597859 != nil:
    section.add "X-Amz-Security-Token", valid_597859
  var valid_597860 = header.getOrDefault("X-Amz-Algorithm")
  valid_597860 = validateParameter(valid_597860, JString, required = false,
                                 default = nil)
  if valid_597860 != nil:
    section.add "X-Amz-Algorithm", valid_597860
  var valid_597861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597861 = validateParameter(valid_597861, JString, required = false,
                                 default = nil)
  if valid_597861 != nil:
    section.add "X-Amz-SignedHeaders", valid_597861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597885: Call_CreateCapacityProvider_597727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new capacity provider. Capacity providers are associated with an Amazon ECS cluster and are used in capacity provider strategies to facilitate cluster auto scaling.</p> <p>Only capacity providers using an Auto Scaling group can be created. Amazon ECS tasks on AWS Fargate use the <code>FARGATE</code> and <code>FARGATE_SPOT</code> capacity providers which are already created and available to all accounts in Regions supported by AWS Fargate.</p>
  ## 
  let valid = call_597885.validator(path, query, header, formData, body)
  let scheme = call_597885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597885.url(scheme.get, call_597885.host, call_597885.base,
                         call_597885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597885, url, valid)

proc call*(call_597956: Call_CreateCapacityProvider_597727; body: JsonNode): Recallable =
  ## createCapacityProvider
  ## <p>Creates a new capacity provider. Capacity providers are associated with an Amazon ECS cluster and are used in capacity provider strategies to facilitate cluster auto scaling.</p> <p>Only capacity providers using an Auto Scaling group can be created. Amazon ECS tasks on AWS Fargate use the <code>FARGATE</code> and <code>FARGATE_SPOT</code> capacity providers which are already created and available to all accounts in Regions supported by AWS Fargate.</p>
  ##   body: JObject (required)
  var body_597957 = newJObject()
  if body != nil:
    body_597957 = body
  result = call_597956.call(nil, nil, nil, nil, body_597957)

var createCapacityProvider* = Call_CreateCapacityProvider_597727(
    name: "createCapacityProvider", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateCapacityProvider",
    validator: validate_CreateCapacityProvider_597728, base: "/",
    url: url_CreateCapacityProvider_597729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCluster_597996 = ref object of OpenApiRestCall_597389
proc url_CreateCluster_597998(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCluster_597997(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_597999 = header.getOrDefault("X-Amz-Target")
  valid_597999 = validateParameter(valid_597999, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateCluster"))
  if valid_597999 != nil:
    section.add "X-Amz-Target", valid_597999
  var valid_598000 = header.getOrDefault("X-Amz-Signature")
  valid_598000 = validateParameter(valid_598000, JString, required = false,
                                 default = nil)
  if valid_598000 != nil:
    section.add "X-Amz-Signature", valid_598000
  var valid_598001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598001 = validateParameter(valid_598001, JString, required = false,
                                 default = nil)
  if valid_598001 != nil:
    section.add "X-Amz-Content-Sha256", valid_598001
  var valid_598002 = header.getOrDefault("X-Amz-Date")
  valid_598002 = validateParameter(valid_598002, JString, required = false,
                                 default = nil)
  if valid_598002 != nil:
    section.add "X-Amz-Date", valid_598002
  var valid_598003 = header.getOrDefault("X-Amz-Credential")
  valid_598003 = validateParameter(valid_598003, JString, required = false,
                                 default = nil)
  if valid_598003 != nil:
    section.add "X-Amz-Credential", valid_598003
  var valid_598004 = header.getOrDefault("X-Amz-Security-Token")
  valid_598004 = validateParameter(valid_598004, JString, required = false,
                                 default = nil)
  if valid_598004 != nil:
    section.add "X-Amz-Security-Token", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-Algorithm")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-Algorithm", valid_598005
  var valid_598006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598006 = validateParameter(valid_598006, JString, required = false,
                                 default = nil)
  if valid_598006 != nil:
    section.add "X-Amz-SignedHeaders", valid_598006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598008: Call_CreateCluster_597996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Amazon ECS cluster. By default, your account receives a <code>default</code> cluster when you launch your first container instance. However, you can create your own cluster with a unique name with the <code>CreateCluster</code> action.</p> <note> <p>When you call the <a>CreateCluster</a> API operation, Amazon ECS attempts to create the Amazon ECS service-linked role for your account so that required resources in other AWS services can be managed on your behalf. However, if the IAM user that makes the call does not have permissions to create the service-linked role, it is not created. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html">Using Service-Linked Roles for Amazon ECS</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_598008.validator(path, query, header, formData, body)
  let scheme = call_598008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598008.url(scheme.get, call_598008.host, call_598008.base,
                         call_598008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598008, url, valid)

proc call*(call_598009: Call_CreateCluster_597996; body: JsonNode): Recallable =
  ## createCluster
  ## <p>Creates a new Amazon ECS cluster. By default, your account receives a <code>default</code> cluster when you launch your first container instance. However, you can create your own cluster with a unique name with the <code>CreateCluster</code> action.</p> <note> <p>When you call the <a>CreateCluster</a> API operation, Amazon ECS attempts to create the Amazon ECS service-linked role for your account so that required resources in other AWS services can be managed on your behalf. However, if the IAM user that makes the call does not have permissions to create the service-linked role, it is not created. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html">Using Service-Linked Roles for Amazon ECS</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_598010 = newJObject()
  if body != nil:
    body_598010 = body
  result = call_598009.call(nil, nil, nil, nil, body_598010)

var createCluster* = Call_CreateCluster_597996(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateCluster",
    validator: validate_CreateCluster_597997, base: "/", url: url_CreateCluster_597998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateService_598011 = ref object of OpenApiRestCall_597389
proc url_CreateService_598013(protocol: Scheme; host: string; base: string;
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

proc validate_CreateService_598012(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598014 = header.getOrDefault("X-Amz-Target")
  valid_598014 = validateParameter(valid_598014, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateService"))
  if valid_598014 != nil:
    section.add "X-Amz-Target", valid_598014
  var valid_598015 = header.getOrDefault("X-Amz-Signature")
  valid_598015 = validateParameter(valid_598015, JString, required = false,
                                 default = nil)
  if valid_598015 != nil:
    section.add "X-Amz-Signature", valid_598015
  var valid_598016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598016 = validateParameter(valid_598016, JString, required = false,
                                 default = nil)
  if valid_598016 != nil:
    section.add "X-Amz-Content-Sha256", valid_598016
  var valid_598017 = header.getOrDefault("X-Amz-Date")
  valid_598017 = validateParameter(valid_598017, JString, required = false,
                                 default = nil)
  if valid_598017 != nil:
    section.add "X-Amz-Date", valid_598017
  var valid_598018 = header.getOrDefault("X-Amz-Credential")
  valid_598018 = validateParameter(valid_598018, JString, required = false,
                                 default = nil)
  if valid_598018 != nil:
    section.add "X-Amz-Credential", valid_598018
  var valid_598019 = header.getOrDefault("X-Amz-Security-Token")
  valid_598019 = validateParameter(valid_598019, JString, required = false,
                                 default = nil)
  if valid_598019 != nil:
    section.add "X-Amz-Security-Token", valid_598019
  var valid_598020 = header.getOrDefault("X-Amz-Algorithm")
  valid_598020 = validateParameter(valid_598020, JString, required = false,
                                 default = nil)
  if valid_598020 != nil:
    section.add "X-Amz-Algorithm", valid_598020
  var valid_598021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598021 = validateParameter(valid_598021, JString, required = false,
                                 default = nil)
  if valid_598021 != nil:
    section.add "X-Amz-SignedHeaders", valid_598021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598023: Call_CreateService_598011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs and maintains a desired number of tasks from a specified task definition. If the number of tasks running in a service drops below the <code>desiredCount</code>, Amazon ECS runs another copy of the task in the specified cluster. To update an existing service, see <a>UpdateService</a>.</p> <p>In addition to maintaining the desired count of tasks in your service, you can optionally run your service behind one or more load balancers. The load balancers distribute traffic across the tasks that are associated with the service. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html">Service Load Balancing</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and the container instance that they're hosted on is reported as healthy by the load balancer.</p> <p>There are two service scheduler strategies available:</p> <ul> <li> <p> <code>REPLICA</code> - The replica scheduling strategy places and maintains the desired number of tasks across your cluster. By default, the service scheduler spreads tasks across Availability Zones. You can use task placement strategies and constraints to customize task placement decisions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> <li> <p> <code>DAEMON</code> - The daemon scheduling strategy deploys exactly one task on each active container instance that meets all of the task placement constraints that you specify in your cluster. When using this strategy, you don't need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> </ul> <p>You can optionally specify a deployment configuration for your service. The deployment is triggered by changing properties, such as the task definition or the desired count of a service, with an <a>UpdateService</a> operation. The default value for a replica service for <code>minimumHealthyPercent</code> is 100%. The default value for a daemon service for <code>minimumHealthyPercent</code> is 0%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the minimum healthy percent represents a lower limit on the number of tasks in a service that must remain in the <code>RUNNING</code> state during a deployment, as a percentage of the desired number of tasks (rounded up to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to deploy without using additional cluster capacity. For example, if your service has a desired number of four tasks and a minimum healthy percent of 50%, the scheduler might stop two existing tasks to free up cluster capacity before starting two new tasks. Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and they're reported as healthy by the load balancer. The default value for minimum healthy percent is 100%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the <b>maximum percent</b> parameter represents an upper limit on the number of tasks in a service that are allowed in the <code>RUNNING</code> or <code>PENDING</code> state during a deployment, as a percentage of the desired number of tasks (rounded down to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to define the deployment batch size. For example, if your service has a desired number of four tasks and a maximum percent value of 200%, the scheduler may start four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available). The default value for maximum percent is 200%.</p> <p>If a service is using either the <code>CODE_DEPLOY</code> or <code>EXTERNAL</code> deployment controller types and tasks that use the EC2 launch type, the <b>minimum healthy percent</b> and <b>maximum percent</b> values are used only to define the lower and upper limit on the number of the tasks in the service that remain in the <code>RUNNING</code> state while the container instances are in the <code>DRAINING</code> state. If the tasks in the service use the Fargate launch type, the minimum healthy percent and maximum percent values aren't used, although they're currently visible when describing your service.</p> <p>When creating a service that uses the <code>EXTERNAL</code> deployment controller, you can specify only parameters that aren't controlled at the task set level. The only required parameter is the service name. You control your services using the <a>CreateTaskSet</a> operation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster using the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy) with the <code>placementStrategy</code> parameter):</p> <ul> <li> <p>Sort the valid container instances, giving priority to instances that have the fewest number of running tasks for this service in their respective Availability Zone. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul>
  ## 
  let valid = call_598023.validator(path, query, header, formData, body)
  let scheme = call_598023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598023.url(scheme.get, call_598023.host, call_598023.base,
                         call_598023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598023, url, valid)

proc call*(call_598024: Call_CreateService_598011; body: JsonNode): Recallable =
  ## createService
  ## <p>Runs and maintains a desired number of tasks from a specified task definition. If the number of tasks running in a service drops below the <code>desiredCount</code>, Amazon ECS runs another copy of the task in the specified cluster. To update an existing service, see <a>UpdateService</a>.</p> <p>In addition to maintaining the desired count of tasks in your service, you can optionally run your service behind one or more load balancers. The load balancers distribute traffic across the tasks that are associated with the service. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html">Service Load Balancing</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and the container instance that they're hosted on is reported as healthy by the load balancer.</p> <p>There are two service scheduler strategies available:</p> <ul> <li> <p> <code>REPLICA</code> - The replica scheduling strategy places and maintains the desired number of tasks across your cluster. By default, the service scheduler spreads tasks across Availability Zones. You can use task placement strategies and constraints to customize task placement decisions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> <li> <p> <code>DAEMON</code> - The daemon scheduling strategy deploys exactly one task on each active container instance that meets all of the task placement constraints that you specify in your cluster. When using this strategy, you don't need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> </ul> <p>You can optionally specify a deployment configuration for your service. The deployment is triggered by changing properties, such as the task definition or the desired count of a service, with an <a>UpdateService</a> operation. The default value for a replica service for <code>minimumHealthyPercent</code> is 100%. The default value for a daemon service for <code>minimumHealthyPercent</code> is 0%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the minimum healthy percent represents a lower limit on the number of tasks in a service that must remain in the <code>RUNNING</code> state during a deployment, as a percentage of the desired number of tasks (rounded up to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to deploy without using additional cluster capacity. For example, if your service has a desired number of four tasks and a minimum healthy percent of 50%, the scheduler might stop two existing tasks to free up cluster capacity before starting two new tasks. Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and they're reported as healthy by the load balancer. The default value for minimum healthy percent is 100%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the <b>maximum percent</b> parameter represents an upper limit on the number of tasks in a service that are allowed in the <code>RUNNING</code> or <code>PENDING</code> state during a deployment, as a percentage of the desired number of tasks (rounded down to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to define the deployment batch size. For example, if your service has a desired number of four tasks and a maximum percent value of 200%, the scheduler may start four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available). The default value for maximum percent is 200%.</p> <p>If a service is using either the <code>CODE_DEPLOY</code> or <code>EXTERNAL</code> deployment controller types and tasks that use the EC2 launch type, the <b>minimum healthy percent</b> and <b>maximum percent</b> values are used only to define the lower and upper limit on the number of the tasks in the service that remain in the <code>RUNNING</code> state while the container instances are in the <code>DRAINING</code> state. If the tasks in the service use the Fargate launch type, the minimum healthy percent and maximum percent values aren't used, although they're currently visible when describing your service.</p> <p>When creating a service that uses the <code>EXTERNAL</code> deployment controller, you can specify only parameters that aren't controlled at the task set level. The only required parameter is the service name. You control your services using the <a>CreateTaskSet</a> operation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster using the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy) with the <code>placementStrategy</code> parameter):</p> <ul> <li> <p>Sort the valid container instances, giving priority to instances that have the fewest number of running tasks for this service in their respective Availability Zone. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_598025 = newJObject()
  if body != nil:
    body_598025 = body
  result = call_598024.call(nil, nil, nil, nil, body_598025)

var createService* = Call_CreateService_598011(name: "createService",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateService",
    validator: validate_CreateService_598012, base: "/", url: url_CreateService_598013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTaskSet_598026 = ref object of OpenApiRestCall_597389
proc url_CreateTaskSet_598028(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTaskSet_598027(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598029 = header.getOrDefault("X-Amz-Target")
  valid_598029 = validateParameter(valid_598029, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateTaskSet"))
  if valid_598029 != nil:
    section.add "X-Amz-Target", valid_598029
  var valid_598030 = header.getOrDefault("X-Amz-Signature")
  valid_598030 = validateParameter(valid_598030, JString, required = false,
                                 default = nil)
  if valid_598030 != nil:
    section.add "X-Amz-Signature", valid_598030
  var valid_598031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598031 = validateParameter(valid_598031, JString, required = false,
                                 default = nil)
  if valid_598031 != nil:
    section.add "X-Amz-Content-Sha256", valid_598031
  var valid_598032 = header.getOrDefault("X-Amz-Date")
  valid_598032 = validateParameter(valid_598032, JString, required = false,
                                 default = nil)
  if valid_598032 != nil:
    section.add "X-Amz-Date", valid_598032
  var valid_598033 = header.getOrDefault("X-Amz-Credential")
  valid_598033 = validateParameter(valid_598033, JString, required = false,
                                 default = nil)
  if valid_598033 != nil:
    section.add "X-Amz-Credential", valid_598033
  var valid_598034 = header.getOrDefault("X-Amz-Security-Token")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "X-Amz-Security-Token", valid_598034
  var valid_598035 = header.getOrDefault("X-Amz-Algorithm")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "X-Amz-Algorithm", valid_598035
  var valid_598036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598036 = validateParameter(valid_598036, JString, required = false,
                                 default = nil)
  if valid_598036 != nil:
    section.add "X-Amz-SignedHeaders", valid_598036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598038: Call_CreateTaskSet_598026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a task set in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_598038.validator(path, query, header, formData, body)
  let scheme = call_598038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598038.url(scheme.get, call_598038.host, call_598038.base,
                         call_598038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598038, url, valid)

proc call*(call_598039: Call_CreateTaskSet_598026; body: JsonNode): Recallable =
  ## createTaskSet
  ## Create a task set in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_598040 = newJObject()
  if body != nil:
    body_598040 = body
  result = call_598039.call(nil, nil, nil, nil, body_598040)

var createTaskSet* = Call_CreateTaskSet_598026(name: "createTaskSet",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateTaskSet",
    validator: validate_CreateTaskSet_598027, base: "/", url: url_CreateTaskSet_598028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccountSetting_598041 = ref object of OpenApiRestCall_597389
proc url_DeleteAccountSetting_598043(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAccountSetting_598042(path: JsonNode; query: JsonNode;
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
  var valid_598044 = header.getOrDefault("X-Amz-Target")
  valid_598044 = validateParameter(valid_598044, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteAccountSetting"))
  if valid_598044 != nil:
    section.add "X-Amz-Target", valid_598044
  var valid_598045 = header.getOrDefault("X-Amz-Signature")
  valid_598045 = validateParameter(valid_598045, JString, required = false,
                                 default = nil)
  if valid_598045 != nil:
    section.add "X-Amz-Signature", valid_598045
  var valid_598046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598046 = validateParameter(valid_598046, JString, required = false,
                                 default = nil)
  if valid_598046 != nil:
    section.add "X-Amz-Content-Sha256", valid_598046
  var valid_598047 = header.getOrDefault("X-Amz-Date")
  valid_598047 = validateParameter(valid_598047, JString, required = false,
                                 default = nil)
  if valid_598047 != nil:
    section.add "X-Amz-Date", valid_598047
  var valid_598048 = header.getOrDefault("X-Amz-Credential")
  valid_598048 = validateParameter(valid_598048, JString, required = false,
                                 default = nil)
  if valid_598048 != nil:
    section.add "X-Amz-Credential", valid_598048
  var valid_598049 = header.getOrDefault("X-Amz-Security-Token")
  valid_598049 = validateParameter(valid_598049, JString, required = false,
                                 default = nil)
  if valid_598049 != nil:
    section.add "X-Amz-Security-Token", valid_598049
  var valid_598050 = header.getOrDefault("X-Amz-Algorithm")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "X-Amz-Algorithm", valid_598050
  var valid_598051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598051 = validateParameter(valid_598051, JString, required = false,
                                 default = nil)
  if valid_598051 != nil:
    section.add "X-Amz-SignedHeaders", valid_598051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598053: Call_DeleteAccountSetting_598041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables an account setting for a specified IAM user, IAM role, or the root user for an account.
  ## 
  let valid = call_598053.validator(path, query, header, formData, body)
  let scheme = call_598053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598053.url(scheme.get, call_598053.host, call_598053.base,
                         call_598053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598053, url, valid)

proc call*(call_598054: Call_DeleteAccountSetting_598041; body: JsonNode): Recallable =
  ## deleteAccountSetting
  ## Disables an account setting for a specified IAM user, IAM role, or the root user for an account.
  ##   body: JObject (required)
  var body_598055 = newJObject()
  if body != nil:
    body_598055 = body
  result = call_598054.call(nil, nil, nil, nil, body_598055)

var deleteAccountSetting* = Call_DeleteAccountSetting_598041(
    name: "deleteAccountSetting", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteAccountSetting",
    validator: validate_DeleteAccountSetting_598042, base: "/",
    url: url_DeleteAccountSetting_598043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAttributes_598056 = ref object of OpenApiRestCall_597389
proc url_DeleteAttributes_598058(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAttributes_598057(path: JsonNode; query: JsonNode;
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
  var valid_598059 = header.getOrDefault("X-Amz-Target")
  valid_598059 = validateParameter(valid_598059, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteAttributes"))
  if valid_598059 != nil:
    section.add "X-Amz-Target", valid_598059
  var valid_598060 = header.getOrDefault("X-Amz-Signature")
  valid_598060 = validateParameter(valid_598060, JString, required = false,
                                 default = nil)
  if valid_598060 != nil:
    section.add "X-Amz-Signature", valid_598060
  var valid_598061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598061 = validateParameter(valid_598061, JString, required = false,
                                 default = nil)
  if valid_598061 != nil:
    section.add "X-Amz-Content-Sha256", valid_598061
  var valid_598062 = header.getOrDefault("X-Amz-Date")
  valid_598062 = validateParameter(valid_598062, JString, required = false,
                                 default = nil)
  if valid_598062 != nil:
    section.add "X-Amz-Date", valid_598062
  var valid_598063 = header.getOrDefault("X-Amz-Credential")
  valid_598063 = validateParameter(valid_598063, JString, required = false,
                                 default = nil)
  if valid_598063 != nil:
    section.add "X-Amz-Credential", valid_598063
  var valid_598064 = header.getOrDefault("X-Amz-Security-Token")
  valid_598064 = validateParameter(valid_598064, JString, required = false,
                                 default = nil)
  if valid_598064 != nil:
    section.add "X-Amz-Security-Token", valid_598064
  var valid_598065 = header.getOrDefault("X-Amz-Algorithm")
  valid_598065 = validateParameter(valid_598065, JString, required = false,
                                 default = nil)
  if valid_598065 != nil:
    section.add "X-Amz-Algorithm", valid_598065
  var valid_598066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598066 = validateParameter(valid_598066, JString, required = false,
                                 default = nil)
  if valid_598066 != nil:
    section.add "X-Amz-SignedHeaders", valid_598066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598068: Call_DeleteAttributes_598056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more custom attributes from an Amazon ECS resource.
  ## 
  let valid = call_598068.validator(path, query, header, formData, body)
  let scheme = call_598068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598068.url(scheme.get, call_598068.host, call_598068.base,
                         call_598068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598068, url, valid)

proc call*(call_598069: Call_DeleteAttributes_598056; body: JsonNode): Recallable =
  ## deleteAttributes
  ## Deletes one or more custom attributes from an Amazon ECS resource.
  ##   body: JObject (required)
  var body_598070 = newJObject()
  if body != nil:
    body_598070 = body
  result = call_598069.call(nil, nil, nil, nil, body_598070)

var deleteAttributes* = Call_DeleteAttributes_598056(name: "deleteAttributes",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteAttributes",
    validator: validate_DeleteAttributes_598057, base: "/",
    url: url_DeleteAttributes_598058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_598071 = ref object of OpenApiRestCall_597389
proc url_DeleteCluster_598073(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCluster_598072(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598074 = header.getOrDefault("X-Amz-Target")
  valid_598074 = validateParameter(valid_598074, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteCluster"))
  if valid_598074 != nil:
    section.add "X-Amz-Target", valid_598074
  var valid_598075 = header.getOrDefault("X-Amz-Signature")
  valid_598075 = validateParameter(valid_598075, JString, required = false,
                                 default = nil)
  if valid_598075 != nil:
    section.add "X-Amz-Signature", valid_598075
  var valid_598076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598076 = validateParameter(valid_598076, JString, required = false,
                                 default = nil)
  if valid_598076 != nil:
    section.add "X-Amz-Content-Sha256", valid_598076
  var valid_598077 = header.getOrDefault("X-Amz-Date")
  valid_598077 = validateParameter(valid_598077, JString, required = false,
                                 default = nil)
  if valid_598077 != nil:
    section.add "X-Amz-Date", valid_598077
  var valid_598078 = header.getOrDefault("X-Amz-Credential")
  valid_598078 = validateParameter(valid_598078, JString, required = false,
                                 default = nil)
  if valid_598078 != nil:
    section.add "X-Amz-Credential", valid_598078
  var valid_598079 = header.getOrDefault("X-Amz-Security-Token")
  valid_598079 = validateParameter(valid_598079, JString, required = false,
                                 default = nil)
  if valid_598079 != nil:
    section.add "X-Amz-Security-Token", valid_598079
  var valid_598080 = header.getOrDefault("X-Amz-Algorithm")
  valid_598080 = validateParameter(valid_598080, JString, required = false,
                                 default = nil)
  if valid_598080 != nil:
    section.add "X-Amz-Algorithm", valid_598080
  var valid_598081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598081 = validateParameter(valid_598081, JString, required = false,
                                 default = nil)
  if valid_598081 != nil:
    section.add "X-Amz-SignedHeaders", valid_598081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598083: Call_DeleteCluster_598071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified cluster. You must deregister all container instances from this cluster before you may delete it. You can list the container instances in a cluster with <a>ListContainerInstances</a> and deregister them with <a>DeregisterContainerInstance</a>.
  ## 
  let valid = call_598083.validator(path, query, header, formData, body)
  let scheme = call_598083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598083.url(scheme.get, call_598083.host, call_598083.base,
                         call_598083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598083, url, valid)

proc call*(call_598084: Call_DeleteCluster_598071; body: JsonNode): Recallable =
  ## deleteCluster
  ## Deletes the specified cluster. You must deregister all container instances from this cluster before you may delete it. You can list the container instances in a cluster with <a>ListContainerInstances</a> and deregister them with <a>DeregisterContainerInstance</a>.
  ##   body: JObject (required)
  var body_598085 = newJObject()
  if body != nil:
    body_598085 = body
  result = call_598084.call(nil, nil, nil, nil, body_598085)

var deleteCluster* = Call_DeleteCluster_598071(name: "deleteCluster",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteCluster",
    validator: validate_DeleteCluster_598072, base: "/", url: url_DeleteCluster_598073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteService_598086 = ref object of OpenApiRestCall_597389
proc url_DeleteService_598088(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteService_598087(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598089 = header.getOrDefault("X-Amz-Target")
  valid_598089 = validateParameter(valid_598089, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteService"))
  if valid_598089 != nil:
    section.add "X-Amz-Target", valid_598089
  var valid_598090 = header.getOrDefault("X-Amz-Signature")
  valid_598090 = validateParameter(valid_598090, JString, required = false,
                                 default = nil)
  if valid_598090 != nil:
    section.add "X-Amz-Signature", valid_598090
  var valid_598091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598091 = validateParameter(valid_598091, JString, required = false,
                                 default = nil)
  if valid_598091 != nil:
    section.add "X-Amz-Content-Sha256", valid_598091
  var valid_598092 = header.getOrDefault("X-Amz-Date")
  valid_598092 = validateParameter(valid_598092, JString, required = false,
                                 default = nil)
  if valid_598092 != nil:
    section.add "X-Amz-Date", valid_598092
  var valid_598093 = header.getOrDefault("X-Amz-Credential")
  valid_598093 = validateParameter(valid_598093, JString, required = false,
                                 default = nil)
  if valid_598093 != nil:
    section.add "X-Amz-Credential", valid_598093
  var valid_598094 = header.getOrDefault("X-Amz-Security-Token")
  valid_598094 = validateParameter(valid_598094, JString, required = false,
                                 default = nil)
  if valid_598094 != nil:
    section.add "X-Amz-Security-Token", valid_598094
  var valid_598095 = header.getOrDefault("X-Amz-Algorithm")
  valid_598095 = validateParameter(valid_598095, JString, required = false,
                                 default = nil)
  if valid_598095 != nil:
    section.add "X-Amz-Algorithm", valid_598095
  var valid_598096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598096 = validateParameter(valid_598096, JString, required = false,
                                 default = nil)
  if valid_598096 != nil:
    section.add "X-Amz-SignedHeaders", valid_598096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598098: Call_DeleteService_598086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specified service within a cluster. You can delete a service if you have no running tasks in it and the desired task count is zero. If the service is actively maintaining tasks, you cannot delete it, and you must update the service to a desired task count of zero. For more information, see <a>UpdateService</a>.</p> <note> <p>When you delete a service, if there are still running tasks that require cleanup, the service status moves from <code>ACTIVE</code> to <code>DRAINING</code>, and the service is no longer visible in the console or in the <a>ListServices</a> API operation. After all tasks have transitioned to either <code>STOPPING</code> or <code>STOPPED</code> status, the service status moves from <code>DRAINING</code> to <code>INACTIVE</code>. Services in the <code>DRAINING</code> or <code>INACTIVE</code> status can still be viewed with the <a>DescribeServices</a> API operation. However, in the future, <code>INACTIVE</code> services may be cleaned up and purged from Amazon ECS record keeping, and <a>DescribeServices</a> calls on those services return a <code>ServiceNotFoundException</code> error.</p> </note> <important> <p>If you attempt to create a new service with the same name as an existing service in either <code>ACTIVE</code> or <code>DRAINING</code> status, you receive an error.</p> </important>
  ## 
  let valid = call_598098.validator(path, query, header, formData, body)
  let scheme = call_598098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598098.url(scheme.get, call_598098.host, call_598098.base,
                         call_598098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598098, url, valid)

proc call*(call_598099: Call_DeleteService_598086; body: JsonNode): Recallable =
  ## deleteService
  ## <p>Deletes a specified service within a cluster. You can delete a service if you have no running tasks in it and the desired task count is zero. If the service is actively maintaining tasks, you cannot delete it, and you must update the service to a desired task count of zero. For more information, see <a>UpdateService</a>.</p> <note> <p>When you delete a service, if there are still running tasks that require cleanup, the service status moves from <code>ACTIVE</code> to <code>DRAINING</code>, and the service is no longer visible in the console or in the <a>ListServices</a> API operation. After all tasks have transitioned to either <code>STOPPING</code> or <code>STOPPED</code> status, the service status moves from <code>DRAINING</code> to <code>INACTIVE</code>. Services in the <code>DRAINING</code> or <code>INACTIVE</code> status can still be viewed with the <a>DescribeServices</a> API operation. However, in the future, <code>INACTIVE</code> services may be cleaned up and purged from Amazon ECS record keeping, and <a>DescribeServices</a> calls on those services return a <code>ServiceNotFoundException</code> error.</p> </note> <important> <p>If you attempt to create a new service with the same name as an existing service in either <code>ACTIVE</code> or <code>DRAINING</code> status, you receive an error.</p> </important>
  ##   body: JObject (required)
  var body_598100 = newJObject()
  if body != nil:
    body_598100 = body
  result = call_598099.call(nil, nil, nil, nil, body_598100)

var deleteService* = Call_DeleteService_598086(name: "deleteService",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteService",
    validator: validate_DeleteService_598087, base: "/", url: url_DeleteService_598088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTaskSet_598101 = ref object of OpenApiRestCall_597389
proc url_DeleteTaskSet_598103(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTaskSet_598102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598104 = header.getOrDefault("X-Amz-Target")
  valid_598104 = validateParameter(valid_598104, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteTaskSet"))
  if valid_598104 != nil:
    section.add "X-Amz-Target", valid_598104
  var valid_598105 = header.getOrDefault("X-Amz-Signature")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "X-Amz-Signature", valid_598105
  var valid_598106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598106 = validateParameter(valid_598106, JString, required = false,
                                 default = nil)
  if valid_598106 != nil:
    section.add "X-Amz-Content-Sha256", valid_598106
  var valid_598107 = header.getOrDefault("X-Amz-Date")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "X-Amz-Date", valid_598107
  var valid_598108 = header.getOrDefault("X-Amz-Credential")
  valid_598108 = validateParameter(valid_598108, JString, required = false,
                                 default = nil)
  if valid_598108 != nil:
    section.add "X-Amz-Credential", valid_598108
  var valid_598109 = header.getOrDefault("X-Amz-Security-Token")
  valid_598109 = validateParameter(valid_598109, JString, required = false,
                                 default = nil)
  if valid_598109 != nil:
    section.add "X-Amz-Security-Token", valid_598109
  var valid_598110 = header.getOrDefault("X-Amz-Algorithm")
  valid_598110 = validateParameter(valid_598110, JString, required = false,
                                 default = nil)
  if valid_598110 != nil:
    section.add "X-Amz-Algorithm", valid_598110
  var valid_598111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598111 = validateParameter(valid_598111, JString, required = false,
                                 default = nil)
  if valid_598111 != nil:
    section.add "X-Amz-SignedHeaders", valid_598111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598113: Call_DeleteTaskSet_598101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified task set within a service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_598113.validator(path, query, header, formData, body)
  let scheme = call_598113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598113.url(scheme.get, call_598113.host, call_598113.base,
                         call_598113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598113, url, valid)

proc call*(call_598114: Call_DeleteTaskSet_598101; body: JsonNode): Recallable =
  ## deleteTaskSet
  ## Deletes a specified task set within a service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_598115 = newJObject()
  if body != nil:
    body_598115 = body
  result = call_598114.call(nil, nil, nil, nil, body_598115)

var deleteTaskSet* = Call_DeleteTaskSet_598101(name: "deleteTaskSet",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteTaskSet",
    validator: validate_DeleteTaskSet_598102, base: "/", url: url_DeleteTaskSet_598103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterContainerInstance_598116 = ref object of OpenApiRestCall_597389
proc url_DeregisterContainerInstance_598118(protocol: Scheme; host: string;
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

proc validate_DeregisterContainerInstance_598117(path: JsonNode; query: JsonNode;
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
  var valid_598119 = header.getOrDefault("X-Amz-Target")
  valid_598119 = validateParameter(valid_598119, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeregisterContainerInstance"))
  if valid_598119 != nil:
    section.add "X-Amz-Target", valid_598119
  var valid_598120 = header.getOrDefault("X-Amz-Signature")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "X-Amz-Signature", valid_598120
  var valid_598121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598121 = validateParameter(valid_598121, JString, required = false,
                                 default = nil)
  if valid_598121 != nil:
    section.add "X-Amz-Content-Sha256", valid_598121
  var valid_598122 = header.getOrDefault("X-Amz-Date")
  valid_598122 = validateParameter(valid_598122, JString, required = false,
                                 default = nil)
  if valid_598122 != nil:
    section.add "X-Amz-Date", valid_598122
  var valid_598123 = header.getOrDefault("X-Amz-Credential")
  valid_598123 = validateParameter(valid_598123, JString, required = false,
                                 default = nil)
  if valid_598123 != nil:
    section.add "X-Amz-Credential", valid_598123
  var valid_598124 = header.getOrDefault("X-Amz-Security-Token")
  valid_598124 = validateParameter(valid_598124, JString, required = false,
                                 default = nil)
  if valid_598124 != nil:
    section.add "X-Amz-Security-Token", valid_598124
  var valid_598125 = header.getOrDefault("X-Amz-Algorithm")
  valid_598125 = validateParameter(valid_598125, JString, required = false,
                                 default = nil)
  if valid_598125 != nil:
    section.add "X-Amz-Algorithm", valid_598125
  var valid_598126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598126 = validateParameter(valid_598126, JString, required = false,
                                 default = nil)
  if valid_598126 != nil:
    section.add "X-Amz-SignedHeaders", valid_598126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598128: Call_DeregisterContainerInstance_598116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deregisters an Amazon ECS container instance from the specified cluster. This instance is no longer available to run tasks.</p> <p>If you intend to use the container instance for some other purpose after deregistration, you should stop all of the tasks running on the container instance before deregistration. That prevents any orphaned tasks from consuming resources.</p> <p>Deregistering a container instance removes the instance from a cluster, but it does not terminate the EC2 instance. If you are finished using the instance, be sure to terminate it in the Amazon EC2 console to stop billing.</p> <note> <p>If you terminate a running container instance, Amazon ECS automatically deregisters the instance from your cluster (stopped container instances or instances with disconnected agents are not automatically deregistered when terminated).</p> </note>
  ## 
  let valid = call_598128.validator(path, query, header, formData, body)
  let scheme = call_598128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598128.url(scheme.get, call_598128.host, call_598128.base,
                         call_598128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598128, url, valid)

proc call*(call_598129: Call_DeregisterContainerInstance_598116; body: JsonNode): Recallable =
  ## deregisterContainerInstance
  ## <p>Deregisters an Amazon ECS container instance from the specified cluster. This instance is no longer available to run tasks.</p> <p>If you intend to use the container instance for some other purpose after deregistration, you should stop all of the tasks running on the container instance before deregistration. That prevents any orphaned tasks from consuming resources.</p> <p>Deregistering a container instance removes the instance from a cluster, but it does not terminate the EC2 instance. If you are finished using the instance, be sure to terminate it in the Amazon EC2 console to stop billing.</p> <note> <p>If you terminate a running container instance, Amazon ECS automatically deregisters the instance from your cluster (stopped container instances or instances with disconnected agents are not automatically deregistered when terminated).</p> </note>
  ##   body: JObject (required)
  var body_598130 = newJObject()
  if body != nil:
    body_598130 = body
  result = call_598129.call(nil, nil, nil, nil, body_598130)

var deregisterContainerInstance* = Call_DeregisterContainerInstance_598116(
    name: "deregisterContainerInstance", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeregisterContainerInstance",
    validator: validate_DeregisterContainerInstance_598117, base: "/",
    url: url_DeregisterContainerInstance_598118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskDefinition_598131 = ref object of OpenApiRestCall_597389
proc url_DeregisterTaskDefinition_598133(protocol: Scheme; host: string;
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

proc validate_DeregisterTaskDefinition_598132(path: JsonNode; query: JsonNode;
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
  var valid_598134 = header.getOrDefault("X-Amz-Target")
  valid_598134 = validateParameter(valid_598134, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeregisterTaskDefinition"))
  if valid_598134 != nil:
    section.add "X-Amz-Target", valid_598134
  var valid_598135 = header.getOrDefault("X-Amz-Signature")
  valid_598135 = validateParameter(valid_598135, JString, required = false,
                                 default = nil)
  if valid_598135 != nil:
    section.add "X-Amz-Signature", valid_598135
  var valid_598136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598136 = validateParameter(valid_598136, JString, required = false,
                                 default = nil)
  if valid_598136 != nil:
    section.add "X-Amz-Content-Sha256", valid_598136
  var valid_598137 = header.getOrDefault("X-Amz-Date")
  valid_598137 = validateParameter(valid_598137, JString, required = false,
                                 default = nil)
  if valid_598137 != nil:
    section.add "X-Amz-Date", valid_598137
  var valid_598138 = header.getOrDefault("X-Amz-Credential")
  valid_598138 = validateParameter(valid_598138, JString, required = false,
                                 default = nil)
  if valid_598138 != nil:
    section.add "X-Amz-Credential", valid_598138
  var valid_598139 = header.getOrDefault("X-Amz-Security-Token")
  valid_598139 = validateParameter(valid_598139, JString, required = false,
                                 default = nil)
  if valid_598139 != nil:
    section.add "X-Amz-Security-Token", valid_598139
  var valid_598140 = header.getOrDefault("X-Amz-Algorithm")
  valid_598140 = validateParameter(valid_598140, JString, required = false,
                                 default = nil)
  if valid_598140 != nil:
    section.add "X-Amz-Algorithm", valid_598140
  var valid_598141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598141 = validateParameter(valid_598141, JString, required = false,
                                 default = nil)
  if valid_598141 != nil:
    section.add "X-Amz-SignedHeaders", valid_598141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598143: Call_DeregisterTaskDefinition_598131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deregisters the specified task definition by family and revision. Upon deregistration, the task definition is marked as <code>INACTIVE</code>. Existing tasks and services that reference an <code>INACTIVE</code> task definition continue to run without disruption. Existing services that reference an <code>INACTIVE</code> task definition can still scale up or down by modifying the service's desired count.</p> <p>You cannot use an <code>INACTIVE</code> task definition to run new tasks or create new services, and you cannot update an existing service to reference an <code>INACTIVE</code> task definition. However, there may be up to a 10-minute window following deregistration where these restrictions have not yet taken effect.</p> <note> <p>At this time, <code>INACTIVE</code> task definitions remain discoverable in your account indefinitely. However, this behavior is subject to change in the future, so you should not rely on <code>INACTIVE</code> task definitions persisting beyond the lifecycle of any associated tasks and services.</p> </note>
  ## 
  let valid = call_598143.validator(path, query, header, formData, body)
  let scheme = call_598143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598143.url(scheme.get, call_598143.host, call_598143.base,
                         call_598143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598143, url, valid)

proc call*(call_598144: Call_DeregisterTaskDefinition_598131; body: JsonNode): Recallable =
  ## deregisterTaskDefinition
  ## <p>Deregisters the specified task definition by family and revision. Upon deregistration, the task definition is marked as <code>INACTIVE</code>. Existing tasks and services that reference an <code>INACTIVE</code> task definition continue to run without disruption. Existing services that reference an <code>INACTIVE</code> task definition can still scale up or down by modifying the service's desired count.</p> <p>You cannot use an <code>INACTIVE</code> task definition to run new tasks or create new services, and you cannot update an existing service to reference an <code>INACTIVE</code> task definition. However, there may be up to a 10-minute window following deregistration where these restrictions have not yet taken effect.</p> <note> <p>At this time, <code>INACTIVE</code> task definitions remain discoverable in your account indefinitely. However, this behavior is subject to change in the future, so you should not rely on <code>INACTIVE</code> task definitions persisting beyond the lifecycle of any associated tasks and services.</p> </note>
  ##   body: JObject (required)
  var body_598145 = newJObject()
  if body != nil:
    body_598145 = body
  result = call_598144.call(nil, nil, nil, nil, body_598145)

var deregisterTaskDefinition* = Call_DeregisterTaskDefinition_598131(
    name: "deregisterTaskDefinition", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeregisterTaskDefinition",
    validator: validate_DeregisterTaskDefinition_598132, base: "/",
    url: url_DeregisterTaskDefinition_598133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCapacityProviders_598146 = ref object of OpenApiRestCall_597389
proc url_DescribeCapacityProviders_598148(protocol: Scheme; host: string;
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

proc validate_DescribeCapacityProviders_598147(path: JsonNode; query: JsonNode;
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
  var valid_598149 = header.getOrDefault("X-Amz-Target")
  valid_598149 = validateParameter(valid_598149, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeCapacityProviders"))
  if valid_598149 != nil:
    section.add "X-Amz-Target", valid_598149
  var valid_598150 = header.getOrDefault("X-Amz-Signature")
  valid_598150 = validateParameter(valid_598150, JString, required = false,
                                 default = nil)
  if valid_598150 != nil:
    section.add "X-Amz-Signature", valid_598150
  var valid_598151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598151 = validateParameter(valid_598151, JString, required = false,
                                 default = nil)
  if valid_598151 != nil:
    section.add "X-Amz-Content-Sha256", valid_598151
  var valid_598152 = header.getOrDefault("X-Amz-Date")
  valid_598152 = validateParameter(valid_598152, JString, required = false,
                                 default = nil)
  if valid_598152 != nil:
    section.add "X-Amz-Date", valid_598152
  var valid_598153 = header.getOrDefault("X-Amz-Credential")
  valid_598153 = validateParameter(valid_598153, JString, required = false,
                                 default = nil)
  if valid_598153 != nil:
    section.add "X-Amz-Credential", valid_598153
  var valid_598154 = header.getOrDefault("X-Amz-Security-Token")
  valid_598154 = validateParameter(valid_598154, JString, required = false,
                                 default = nil)
  if valid_598154 != nil:
    section.add "X-Amz-Security-Token", valid_598154
  var valid_598155 = header.getOrDefault("X-Amz-Algorithm")
  valid_598155 = validateParameter(valid_598155, JString, required = false,
                                 default = nil)
  if valid_598155 != nil:
    section.add "X-Amz-Algorithm", valid_598155
  var valid_598156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598156 = validateParameter(valid_598156, JString, required = false,
                                 default = nil)
  if valid_598156 != nil:
    section.add "X-Amz-SignedHeaders", valid_598156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598158: Call_DescribeCapacityProviders_598146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your capacity providers.
  ## 
  let valid = call_598158.validator(path, query, header, formData, body)
  let scheme = call_598158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598158.url(scheme.get, call_598158.host, call_598158.base,
                         call_598158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598158, url, valid)

proc call*(call_598159: Call_DescribeCapacityProviders_598146; body: JsonNode): Recallable =
  ## describeCapacityProviders
  ## Describes one or more of your capacity providers.
  ##   body: JObject (required)
  var body_598160 = newJObject()
  if body != nil:
    body_598160 = body
  result = call_598159.call(nil, nil, nil, nil, body_598160)

var describeCapacityProviders* = Call_DescribeCapacityProviders_598146(
    name: "describeCapacityProviders", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeCapacityProviders",
    validator: validate_DescribeCapacityProviders_598147, base: "/",
    url: url_DescribeCapacityProviders_598148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusters_598161 = ref object of OpenApiRestCall_597389
proc url_DescribeClusters_598163(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeClusters_598162(path: JsonNode; query: JsonNode;
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
  var valid_598164 = header.getOrDefault("X-Amz-Target")
  valid_598164 = validateParameter(valid_598164, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeClusters"))
  if valid_598164 != nil:
    section.add "X-Amz-Target", valid_598164
  var valid_598165 = header.getOrDefault("X-Amz-Signature")
  valid_598165 = validateParameter(valid_598165, JString, required = false,
                                 default = nil)
  if valid_598165 != nil:
    section.add "X-Amz-Signature", valid_598165
  var valid_598166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598166 = validateParameter(valid_598166, JString, required = false,
                                 default = nil)
  if valid_598166 != nil:
    section.add "X-Amz-Content-Sha256", valid_598166
  var valid_598167 = header.getOrDefault("X-Amz-Date")
  valid_598167 = validateParameter(valid_598167, JString, required = false,
                                 default = nil)
  if valid_598167 != nil:
    section.add "X-Amz-Date", valid_598167
  var valid_598168 = header.getOrDefault("X-Amz-Credential")
  valid_598168 = validateParameter(valid_598168, JString, required = false,
                                 default = nil)
  if valid_598168 != nil:
    section.add "X-Amz-Credential", valid_598168
  var valid_598169 = header.getOrDefault("X-Amz-Security-Token")
  valid_598169 = validateParameter(valid_598169, JString, required = false,
                                 default = nil)
  if valid_598169 != nil:
    section.add "X-Amz-Security-Token", valid_598169
  var valid_598170 = header.getOrDefault("X-Amz-Algorithm")
  valid_598170 = validateParameter(valid_598170, JString, required = false,
                                 default = nil)
  if valid_598170 != nil:
    section.add "X-Amz-Algorithm", valid_598170
  var valid_598171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598171 = validateParameter(valid_598171, JString, required = false,
                                 default = nil)
  if valid_598171 != nil:
    section.add "X-Amz-SignedHeaders", valid_598171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598173: Call_DescribeClusters_598161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your clusters.
  ## 
  let valid = call_598173.validator(path, query, header, formData, body)
  let scheme = call_598173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598173.url(scheme.get, call_598173.host, call_598173.base,
                         call_598173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598173, url, valid)

proc call*(call_598174: Call_DescribeClusters_598161; body: JsonNode): Recallable =
  ## describeClusters
  ## Describes one or more of your clusters.
  ##   body: JObject (required)
  var body_598175 = newJObject()
  if body != nil:
    body_598175 = body
  result = call_598174.call(nil, nil, nil, nil, body_598175)

var describeClusters* = Call_DescribeClusters_598161(name: "describeClusters",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeClusters",
    validator: validate_DescribeClusters_598162, base: "/",
    url: url_DescribeClusters_598163, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeContainerInstances_598176 = ref object of OpenApiRestCall_597389
proc url_DescribeContainerInstances_598178(protocol: Scheme; host: string;
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

proc validate_DescribeContainerInstances_598177(path: JsonNode; query: JsonNode;
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
  var valid_598179 = header.getOrDefault("X-Amz-Target")
  valid_598179 = validateParameter(valid_598179, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeContainerInstances"))
  if valid_598179 != nil:
    section.add "X-Amz-Target", valid_598179
  var valid_598180 = header.getOrDefault("X-Amz-Signature")
  valid_598180 = validateParameter(valid_598180, JString, required = false,
                                 default = nil)
  if valid_598180 != nil:
    section.add "X-Amz-Signature", valid_598180
  var valid_598181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598181 = validateParameter(valid_598181, JString, required = false,
                                 default = nil)
  if valid_598181 != nil:
    section.add "X-Amz-Content-Sha256", valid_598181
  var valid_598182 = header.getOrDefault("X-Amz-Date")
  valid_598182 = validateParameter(valid_598182, JString, required = false,
                                 default = nil)
  if valid_598182 != nil:
    section.add "X-Amz-Date", valid_598182
  var valid_598183 = header.getOrDefault("X-Amz-Credential")
  valid_598183 = validateParameter(valid_598183, JString, required = false,
                                 default = nil)
  if valid_598183 != nil:
    section.add "X-Amz-Credential", valid_598183
  var valid_598184 = header.getOrDefault("X-Amz-Security-Token")
  valid_598184 = validateParameter(valid_598184, JString, required = false,
                                 default = nil)
  if valid_598184 != nil:
    section.add "X-Amz-Security-Token", valid_598184
  var valid_598185 = header.getOrDefault("X-Amz-Algorithm")
  valid_598185 = validateParameter(valid_598185, JString, required = false,
                                 default = nil)
  if valid_598185 != nil:
    section.add "X-Amz-Algorithm", valid_598185
  var valid_598186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598186 = validateParameter(valid_598186, JString, required = false,
                                 default = nil)
  if valid_598186 != nil:
    section.add "X-Amz-SignedHeaders", valid_598186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598188: Call_DescribeContainerInstances_598176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes Amazon Elastic Container Service container instances. Returns metadata about registered and remaining resources on each container instance requested.
  ## 
  let valid = call_598188.validator(path, query, header, formData, body)
  let scheme = call_598188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598188.url(scheme.get, call_598188.host, call_598188.base,
                         call_598188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598188, url, valid)

proc call*(call_598189: Call_DescribeContainerInstances_598176; body: JsonNode): Recallable =
  ## describeContainerInstances
  ## Describes Amazon Elastic Container Service container instances. Returns metadata about registered and remaining resources on each container instance requested.
  ##   body: JObject (required)
  var body_598190 = newJObject()
  if body != nil:
    body_598190 = body
  result = call_598189.call(nil, nil, nil, nil, body_598190)

var describeContainerInstances* = Call_DescribeContainerInstances_598176(
    name: "describeContainerInstances", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeContainerInstances",
    validator: validate_DescribeContainerInstances_598177, base: "/",
    url: url_DescribeContainerInstances_598178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServices_598191 = ref object of OpenApiRestCall_597389
proc url_DescribeServices_598193(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeServices_598192(path: JsonNode; query: JsonNode;
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
  var valid_598194 = header.getOrDefault("X-Amz-Target")
  valid_598194 = validateParameter(valid_598194, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeServices"))
  if valid_598194 != nil:
    section.add "X-Amz-Target", valid_598194
  var valid_598195 = header.getOrDefault("X-Amz-Signature")
  valid_598195 = validateParameter(valid_598195, JString, required = false,
                                 default = nil)
  if valid_598195 != nil:
    section.add "X-Amz-Signature", valid_598195
  var valid_598196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598196 = validateParameter(valid_598196, JString, required = false,
                                 default = nil)
  if valid_598196 != nil:
    section.add "X-Amz-Content-Sha256", valid_598196
  var valid_598197 = header.getOrDefault("X-Amz-Date")
  valid_598197 = validateParameter(valid_598197, JString, required = false,
                                 default = nil)
  if valid_598197 != nil:
    section.add "X-Amz-Date", valid_598197
  var valid_598198 = header.getOrDefault("X-Amz-Credential")
  valid_598198 = validateParameter(valid_598198, JString, required = false,
                                 default = nil)
  if valid_598198 != nil:
    section.add "X-Amz-Credential", valid_598198
  var valid_598199 = header.getOrDefault("X-Amz-Security-Token")
  valid_598199 = validateParameter(valid_598199, JString, required = false,
                                 default = nil)
  if valid_598199 != nil:
    section.add "X-Amz-Security-Token", valid_598199
  var valid_598200 = header.getOrDefault("X-Amz-Algorithm")
  valid_598200 = validateParameter(valid_598200, JString, required = false,
                                 default = nil)
  if valid_598200 != nil:
    section.add "X-Amz-Algorithm", valid_598200
  var valid_598201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598201 = validateParameter(valid_598201, JString, required = false,
                                 default = nil)
  if valid_598201 != nil:
    section.add "X-Amz-SignedHeaders", valid_598201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598203: Call_DescribeServices_598191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified services running in your cluster.
  ## 
  let valid = call_598203.validator(path, query, header, formData, body)
  let scheme = call_598203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598203.url(scheme.get, call_598203.host, call_598203.base,
                         call_598203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598203, url, valid)

proc call*(call_598204: Call_DescribeServices_598191; body: JsonNode): Recallable =
  ## describeServices
  ## Describes the specified services running in your cluster.
  ##   body: JObject (required)
  var body_598205 = newJObject()
  if body != nil:
    body_598205 = body
  result = call_598204.call(nil, nil, nil, nil, body_598205)

var describeServices* = Call_DescribeServices_598191(name: "describeServices",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeServices",
    validator: validate_DescribeServices_598192, base: "/",
    url: url_DescribeServices_598193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTaskDefinition_598206 = ref object of OpenApiRestCall_597389
proc url_DescribeTaskDefinition_598208(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTaskDefinition_598207(path: JsonNode; query: JsonNode;
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
  var valid_598209 = header.getOrDefault("X-Amz-Target")
  valid_598209 = validateParameter(valid_598209, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeTaskDefinition"))
  if valid_598209 != nil:
    section.add "X-Amz-Target", valid_598209
  var valid_598210 = header.getOrDefault("X-Amz-Signature")
  valid_598210 = validateParameter(valid_598210, JString, required = false,
                                 default = nil)
  if valid_598210 != nil:
    section.add "X-Amz-Signature", valid_598210
  var valid_598211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598211 = validateParameter(valid_598211, JString, required = false,
                                 default = nil)
  if valid_598211 != nil:
    section.add "X-Amz-Content-Sha256", valid_598211
  var valid_598212 = header.getOrDefault("X-Amz-Date")
  valid_598212 = validateParameter(valid_598212, JString, required = false,
                                 default = nil)
  if valid_598212 != nil:
    section.add "X-Amz-Date", valid_598212
  var valid_598213 = header.getOrDefault("X-Amz-Credential")
  valid_598213 = validateParameter(valid_598213, JString, required = false,
                                 default = nil)
  if valid_598213 != nil:
    section.add "X-Amz-Credential", valid_598213
  var valid_598214 = header.getOrDefault("X-Amz-Security-Token")
  valid_598214 = validateParameter(valid_598214, JString, required = false,
                                 default = nil)
  if valid_598214 != nil:
    section.add "X-Amz-Security-Token", valid_598214
  var valid_598215 = header.getOrDefault("X-Amz-Algorithm")
  valid_598215 = validateParameter(valid_598215, JString, required = false,
                                 default = nil)
  if valid_598215 != nil:
    section.add "X-Amz-Algorithm", valid_598215
  var valid_598216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598216 = validateParameter(valid_598216, JString, required = false,
                                 default = nil)
  if valid_598216 != nil:
    section.add "X-Amz-SignedHeaders", valid_598216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598218: Call_DescribeTaskDefinition_598206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a task definition. You can specify a <code>family</code> and <code>revision</code> to find information about a specific task definition, or you can simply specify the family to find the latest <code>ACTIVE</code> revision in that family.</p> <note> <p>You can only describe <code>INACTIVE</code> task definitions while an active task or service references them.</p> </note>
  ## 
  let valid = call_598218.validator(path, query, header, formData, body)
  let scheme = call_598218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598218.url(scheme.get, call_598218.host, call_598218.base,
                         call_598218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598218, url, valid)

proc call*(call_598219: Call_DescribeTaskDefinition_598206; body: JsonNode): Recallable =
  ## describeTaskDefinition
  ## <p>Describes a task definition. You can specify a <code>family</code> and <code>revision</code> to find information about a specific task definition, or you can simply specify the family to find the latest <code>ACTIVE</code> revision in that family.</p> <note> <p>You can only describe <code>INACTIVE</code> task definitions while an active task or service references them.</p> </note>
  ##   body: JObject (required)
  var body_598220 = newJObject()
  if body != nil:
    body_598220 = body
  result = call_598219.call(nil, nil, nil, nil, body_598220)

var describeTaskDefinition* = Call_DescribeTaskDefinition_598206(
    name: "describeTaskDefinition", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTaskDefinition",
    validator: validate_DescribeTaskDefinition_598207, base: "/",
    url: url_DescribeTaskDefinition_598208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTaskSets_598221 = ref object of OpenApiRestCall_597389
proc url_DescribeTaskSets_598223(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTaskSets_598222(path: JsonNode; query: JsonNode;
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
  var valid_598224 = header.getOrDefault("X-Amz-Target")
  valid_598224 = validateParameter(valid_598224, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeTaskSets"))
  if valid_598224 != nil:
    section.add "X-Amz-Target", valid_598224
  var valid_598225 = header.getOrDefault("X-Amz-Signature")
  valid_598225 = validateParameter(valid_598225, JString, required = false,
                                 default = nil)
  if valid_598225 != nil:
    section.add "X-Amz-Signature", valid_598225
  var valid_598226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598226 = validateParameter(valid_598226, JString, required = false,
                                 default = nil)
  if valid_598226 != nil:
    section.add "X-Amz-Content-Sha256", valid_598226
  var valid_598227 = header.getOrDefault("X-Amz-Date")
  valid_598227 = validateParameter(valid_598227, JString, required = false,
                                 default = nil)
  if valid_598227 != nil:
    section.add "X-Amz-Date", valid_598227
  var valid_598228 = header.getOrDefault("X-Amz-Credential")
  valid_598228 = validateParameter(valid_598228, JString, required = false,
                                 default = nil)
  if valid_598228 != nil:
    section.add "X-Amz-Credential", valid_598228
  var valid_598229 = header.getOrDefault("X-Amz-Security-Token")
  valid_598229 = validateParameter(valid_598229, JString, required = false,
                                 default = nil)
  if valid_598229 != nil:
    section.add "X-Amz-Security-Token", valid_598229
  var valid_598230 = header.getOrDefault("X-Amz-Algorithm")
  valid_598230 = validateParameter(valid_598230, JString, required = false,
                                 default = nil)
  if valid_598230 != nil:
    section.add "X-Amz-Algorithm", valid_598230
  var valid_598231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598231 = validateParameter(valid_598231, JString, required = false,
                                 default = nil)
  if valid_598231 != nil:
    section.add "X-Amz-SignedHeaders", valid_598231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598233: Call_DescribeTaskSets_598221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the task sets in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_598233.validator(path, query, header, formData, body)
  let scheme = call_598233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598233.url(scheme.get, call_598233.host, call_598233.base,
                         call_598233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598233, url, valid)

proc call*(call_598234: Call_DescribeTaskSets_598221; body: JsonNode): Recallable =
  ## describeTaskSets
  ## Describes the task sets in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_598235 = newJObject()
  if body != nil:
    body_598235 = body
  result = call_598234.call(nil, nil, nil, nil, body_598235)

var describeTaskSets* = Call_DescribeTaskSets_598221(name: "describeTaskSets",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTaskSets",
    validator: validate_DescribeTaskSets_598222, base: "/",
    url: url_DescribeTaskSets_598223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTasks_598236 = ref object of OpenApiRestCall_597389
proc url_DescribeTasks_598238(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTasks_598237(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598239 = header.getOrDefault("X-Amz-Target")
  valid_598239 = validateParameter(valid_598239, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeTasks"))
  if valid_598239 != nil:
    section.add "X-Amz-Target", valid_598239
  var valid_598240 = header.getOrDefault("X-Amz-Signature")
  valid_598240 = validateParameter(valid_598240, JString, required = false,
                                 default = nil)
  if valid_598240 != nil:
    section.add "X-Amz-Signature", valid_598240
  var valid_598241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598241 = validateParameter(valid_598241, JString, required = false,
                                 default = nil)
  if valid_598241 != nil:
    section.add "X-Amz-Content-Sha256", valid_598241
  var valid_598242 = header.getOrDefault("X-Amz-Date")
  valid_598242 = validateParameter(valid_598242, JString, required = false,
                                 default = nil)
  if valid_598242 != nil:
    section.add "X-Amz-Date", valid_598242
  var valid_598243 = header.getOrDefault("X-Amz-Credential")
  valid_598243 = validateParameter(valid_598243, JString, required = false,
                                 default = nil)
  if valid_598243 != nil:
    section.add "X-Amz-Credential", valid_598243
  var valid_598244 = header.getOrDefault("X-Amz-Security-Token")
  valid_598244 = validateParameter(valid_598244, JString, required = false,
                                 default = nil)
  if valid_598244 != nil:
    section.add "X-Amz-Security-Token", valid_598244
  var valid_598245 = header.getOrDefault("X-Amz-Algorithm")
  valid_598245 = validateParameter(valid_598245, JString, required = false,
                                 default = nil)
  if valid_598245 != nil:
    section.add "X-Amz-Algorithm", valid_598245
  var valid_598246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598246 = validateParameter(valid_598246, JString, required = false,
                                 default = nil)
  if valid_598246 != nil:
    section.add "X-Amz-SignedHeaders", valid_598246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598248: Call_DescribeTasks_598236; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specified task or tasks.
  ## 
  let valid = call_598248.validator(path, query, header, formData, body)
  let scheme = call_598248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598248.url(scheme.get, call_598248.host, call_598248.base,
                         call_598248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598248, url, valid)

proc call*(call_598249: Call_DescribeTasks_598236; body: JsonNode): Recallable =
  ## describeTasks
  ## Describes a specified task or tasks.
  ##   body: JObject (required)
  var body_598250 = newJObject()
  if body != nil:
    body_598250 = body
  result = call_598249.call(nil, nil, nil, nil, body_598250)

var describeTasks* = Call_DescribeTasks_598236(name: "describeTasks",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTasks",
    validator: validate_DescribeTasks_598237, base: "/", url: url_DescribeTasks_598238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DiscoverPollEndpoint_598251 = ref object of OpenApiRestCall_597389
proc url_DiscoverPollEndpoint_598253(protocol: Scheme; host: string; base: string;
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

proc validate_DiscoverPollEndpoint_598252(path: JsonNode; query: JsonNode;
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
  var valid_598254 = header.getOrDefault("X-Amz-Target")
  valid_598254 = validateParameter(valid_598254, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DiscoverPollEndpoint"))
  if valid_598254 != nil:
    section.add "X-Amz-Target", valid_598254
  var valid_598255 = header.getOrDefault("X-Amz-Signature")
  valid_598255 = validateParameter(valid_598255, JString, required = false,
                                 default = nil)
  if valid_598255 != nil:
    section.add "X-Amz-Signature", valid_598255
  var valid_598256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598256 = validateParameter(valid_598256, JString, required = false,
                                 default = nil)
  if valid_598256 != nil:
    section.add "X-Amz-Content-Sha256", valid_598256
  var valid_598257 = header.getOrDefault("X-Amz-Date")
  valid_598257 = validateParameter(valid_598257, JString, required = false,
                                 default = nil)
  if valid_598257 != nil:
    section.add "X-Amz-Date", valid_598257
  var valid_598258 = header.getOrDefault("X-Amz-Credential")
  valid_598258 = validateParameter(valid_598258, JString, required = false,
                                 default = nil)
  if valid_598258 != nil:
    section.add "X-Amz-Credential", valid_598258
  var valid_598259 = header.getOrDefault("X-Amz-Security-Token")
  valid_598259 = validateParameter(valid_598259, JString, required = false,
                                 default = nil)
  if valid_598259 != nil:
    section.add "X-Amz-Security-Token", valid_598259
  var valid_598260 = header.getOrDefault("X-Amz-Algorithm")
  valid_598260 = validateParameter(valid_598260, JString, required = false,
                                 default = nil)
  if valid_598260 != nil:
    section.add "X-Amz-Algorithm", valid_598260
  var valid_598261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598261 = validateParameter(valid_598261, JString, required = false,
                                 default = nil)
  if valid_598261 != nil:
    section.add "X-Amz-SignedHeaders", valid_598261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598263: Call_DiscoverPollEndpoint_598251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Returns an endpoint for the Amazon ECS agent to poll for updates.</p>
  ## 
  let valid = call_598263.validator(path, query, header, formData, body)
  let scheme = call_598263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598263.url(scheme.get, call_598263.host, call_598263.base,
                         call_598263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598263, url, valid)

proc call*(call_598264: Call_DiscoverPollEndpoint_598251; body: JsonNode): Recallable =
  ## discoverPollEndpoint
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Returns an endpoint for the Amazon ECS agent to poll for updates.</p>
  ##   body: JObject (required)
  var body_598265 = newJObject()
  if body != nil:
    body_598265 = body
  result = call_598264.call(nil, nil, nil, nil, body_598265)

var discoverPollEndpoint* = Call_DiscoverPollEndpoint_598251(
    name: "discoverPollEndpoint", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DiscoverPollEndpoint",
    validator: validate_DiscoverPollEndpoint_598252, base: "/",
    url: url_DiscoverPollEndpoint_598253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountSettings_598266 = ref object of OpenApiRestCall_597389
proc url_ListAccountSettings_598268(protocol: Scheme; host: string; base: string;
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

proc validate_ListAccountSettings_598267(path: JsonNode; query: JsonNode;
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
  var valid_598269 = header.getOrDefault("X-Amz-Target")
  valid_598269 = validateParameter(valid_598269, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListAccountSettings"))
  if valid_598269 != nil:
    section.add "X-Amz-Target", valid_598269
  var valid_598270 = header.getOrDefault("X-Amz-Signature")
  valid_598270 = validateParameter(valid_598270, JString, required = false,
                                 default = nil)
  if valid_598270 != nil:
    section.add "X-Amz-Signature", valid_598270
  var valid_598271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598271 = validateParameter(valid_598271, JString, required = false,
                                 default = nil)
  if valid_598271 != nil:
    section.add "X-Amz-Content-Sha256", valid_598271
  var valid_598272 = header.getOrDefault("X-Amz-Date")
  valid_598272 = validateParameter(valid_598272, JString, required = false,
                                 default = nil)
  if valid_598272 != nil:
    section.add "X-Amz-Date", valid_598272
  var valid_598273 = header.getOrDefault("X-Amz-Credential")
  valid_598273 = validateParameter(valid_598273, JString, required = false,
                                 default = nil)
  if valid_598273 != nil:
    section.add "X-Amz-Credential", valid_598273
  var valid_598274 = header.getOrDefault("X-Amz-Security-Token")
  valid_598274 = validateParameter(valid_598274, JString, required = false,
                                 default = nil)
  if valid_598274 != nil:
    section.add "X-Amz-Security-Token", valid_598274
  var valid_598275 = header.getOrDefault("X-Amz-Algorithm")
  valid_598275 = validateParameter(valid_598275, JString, required = false,
                                 default = nil)
  if valid_598275 != nil:
    section.add "X-Amz-Algorithm", valid_598275
  var valid_598276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598276 = validateParameter(valid_598276, JString, required = false,
                                 default = nil)
  if valid_598276 != nil:
    section.add "X-Amz-SignedHeaders", valid_598276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598278: Call_ListAccountSettings_598266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the account settings for a specified principal.
  ## 
  let valid = call_598278.validator(path, query, header, formData, body)
  let scheme = call_598278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598278.url(scheme.get, call_598278.host, call_598278.base,
                         call_598278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598278, url, valid)

proc call*(call_598279: Call_ListAccountSettings_598266; body: JsonNode): Recallable =
  ## listAccountSettings
  ## Lists the account settings for a specified principal.
  ##   body: JObject (required)
  var body_598280 = newJObject()
  if body != nil:
    body_598280 = body
  result = call_598279.call(nil, nil, nil, nil, body_598280)

var listAccountSettings* = Call_ListAccountSettings_598266(
    name: "listAccountSettings", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListAccountSettings",
    validator: validate_ListAccountSettings_598267, base: "/",
    url: url_ListAccountSettings_598268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttributes_598281 = ref object of OpenApiRestCall_597389
proc url_ListAttributes_598283(protocol: Scheme; host: string; base: string;
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

proc validate_ListAttributes_598282(path: JsonNode; query: JsonNode;
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
  var valid_598284 = query.getOrDefault("nextToken")
  valid_598284 = validateParameter(valid_598284, JString, required = false,
                                 default = nil)
  if valid_598284 != nil:
    section.add "nextToken", valid_598284
  var valid_598285 = query.getOrDefault("maxResults")
  valid_598285 = validateParameter(valid_598285, JString, required = false,
                                 default = nil)
  if valid_598285 != nil:
    section.add "maxResults", valid_598285
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
  var valid_598286 = header.getOrDefault("X-Amz-Target")
  valid_598286 = validateParameter(valid_598286, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListAttributes"))
  if valid_598286 != nil:
    section.add "X-Amz-Target", valid_598286
  var valid_598287 = header.getOrDefault("X-Amz-Signature")
  valid_598287 = validateParameter(valid_598287, JString, required = false,
                                 default = nil)
  if valid_598287 != nil:
    section.add "X-Amz-Signature", valid_598287
  var valid_598288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598288 = validateParameter(valid_598288, JString, required = false,
                                 default = nil)
  if valid_598288 != nil:
    section.add "X-Amz-Content-Sha256", valid_598288
  var valid_598289 = header.getOrDefault("X-Amz-Date")
  valid_598289 = validateParameter(valid_598289, JString, required = false,
                                 default = nil)
  if valid_598289 != nil:
    section.add "X-Amz-Date", valid_598289
  var valid_598290 = header.getOrDefault("X-Amz-Credential")
  valid_598290 = validateParameter(valid_598290, JString, required = false,
                                 default = nil)
  if valid_598290 != nil:
    section.add "X-Amz-Credential", valid_598290
  var valid_598291 = header.getOrDefault("X-Amz-Security-Token")
  valid_598291 = validateParameter(valid_598291, JString, required = false,
                                 default = nil)
  if valid_598291 != nil:
    section.add "X-Amz-Security-Token", valid_598291
  var valid_598292 = header.getOrDefault("X-Amz-Algorithm")
  valid_598292 = validateParameter(valid_598292, JString, required = false,
                                 default = nil)
  if valid_598292 != nil:
    section.add "X-Amz-Algorithm", valid_598292
  var valid_598293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598293 = validateParameter(valid_598293, JString, required = false,
                                 default = nil)
  if valid_598293 != nil:
    section.add "X-Amz-SignedHeaders", valid_598293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598295: Call_ListAttributes_598281; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the attributes for Amazon ECS resources within a specified target type and cluster. When you specify a target type and cluster, <code>ListAttributes</code> returns a list of attribute objects, one for each attribute on each resource. You can filter the list of results to a single attribute name to only return results that have that name. You can also filter the results by attribute name and value, for example, to see which container instances in a cluster are running a Linux AMI (<code>ecs.os-type=linux</code>). 
  ## 
  let valid = call_598295.validator(path, query, header, formData, body)
  let scheme = call_598295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598295.url(scheme.get, call_598295.host, call_598295.base,
                         call_598295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598295, url, valid)

proc call*(call_598296: Call_ListAttributes_598281; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAttributes
  ## Lists the attributes for Amazon ECS resources within a specified target type and cluster. When you specify a target type and cluster, <code>ListAttributes</code> returns a list of attribute objects, one for each attribute on each resource. You can filter the list of results to a single attribute name to only return results that have that name. You can also filter the results by attribute name and value, for example, to see which container instances in a cluster are running a Linux AMI (<code>ecs.os-type=linux</code>). 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598297 = newJObject()
  var body_598298 = newJObject()
  add(query_598297, "nextToken", newJString(nextToken))
  if body != nil:
    body_598298 = body
  add(query_598297, "maxResults", newJString(maxResults))
  result = call_598296.call(nil, query_598297, nil, nil, body_598298)

var listAttributes* = Call_ListAttributes_598281(name: "listAttributes",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListAttributes",
    validator: validate_ListAttributes_598282, base: "/", url: url_ListAttributes_598283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_598300 = ref object of OpenApiRestCall_597389
proc url_ListClusters_598302(protocol: Scheme; host: string; base: string;
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

proc validate_ListClusters_598301(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598303 = query.getOrDefault("nextToken")
  valid_598303 = validateParameter(valid_598303, JString, required = false,
                                 default = nil)
  if valid_598303 != nil:
    section.add "nextToken", valid_598303
  var valid_598304 = query.getOrDefault("maxResults")
  valid_598304 = validateParameter(valid_598304, JString, required = false,
                                 default = nil)
  if valid_598304 != nil:
    section.add "maxResults", valid_598304
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
  var valid_598305 = header.getOrDefault("X-Amz-Target")
  valid_598305 = validateParameter(valid_598305, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListClusters"))
  if valid_598305 != nil:
    section.add "X-Amz-Target", valid_598305
  var valid_598306 = header.getOrDefault("X-Amz-Signature")
  valid_598306 = validateParameter(valid_598306, JString, required = false,
                                 default = nil)
  if valid_598306 != nil:
    section.add "X-Amz-Signature", valid_598306
  var valid_598307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598307 = validateParameter(valid_598307, JString, required = false,
                                 default = nil)
  if valid_598307 != nil:
    section.add "X-Amz-Content-Sha256", valid_598307
  var valid_598308 = header.getOrDefault("X-Amz-Date")
  valid_598308 = validateParameter(valid_598308, JString, required = false,
                                 default = nil)
  if valid_598308 != nil:
    section.add "X-Amz-Date", valid_598308
  var valid_598309 = header.getOrDefault("X-Amz-Credential")
  valid_598309 = validateParameter(valid_598309, JString, required = false,
                                 default = nil)
  if valid_598309 != nil:
    section.add "X-Amz-Credential", valid_598309
  var valid_598310 = header.getOrDefault("X-Amz-Security-Token")
  valid_598310 = validateParameter(valid_598310, JString, required = false,
                                 default = nil)
  if valid_598310 != nil:
    section.add "X-Amz-Security-Token", valid_598310
  var valid_598311 = header.getOrDefault("X-Amz-Algorithm")
  valid_598311 = validateParameter(valid_598311, JString, required = false,
                                 default = nil)
  if valid_598311 != nil:
    section.add "X-Amz-Algorithm", valid_598311
  var valid_598312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598312 = validateParameter(valid_598312, JString, required = false,
                                 default = nil)
  if valid_598312 != nil:
    section.add "X-Amz-SignedHeaders", valid_598312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598314: Call_ListClusters_598300; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing clusters.
  ## 
  let valid = call_598314.validator(path, query, header, formData, body)
  let scheme = call_598314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598314.url(scheme.get, call_598314.host, call_598314.base,
                         call_598314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598314, url, valid)

proc call*(call_598315: Call_ListClusters_598300; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listClusters
  ## Returns a list of existing clusters.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598316 = newJObject()
  var body_598317 = newJObject()
  add(query_598316, "nextToken", newJString(nextToken))
  if body != nil:
    body_598317 = body
  add(query_598316, "maxResults", newJString(maxResults))
  result = call_598315.call(nil, query_598316, nil, nil, body_598317)

var listClusters* = Call_ListClusters_598300(name: "listClusters",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListClusters",
    validator: validate_ListClusters_598301, base: "/", url: url_ListClusters_598302,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContainerInstances_598318 = ref object of OpenApiRestCall_597389
proc url_ListContainerInstances_598320(protocol: Scheme; host: string; base: string;
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

proc validate_ListContainerInstances_598319(path: JsonNode; query: JsonNode;
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
  var valid_598321 = query.getOrDefault("nextToken")
  valid_598321 = validateParameter(valid_598321, JString, required = false,
                                 default = nil)
  if valid_598321 != nil:
    section.add "nextToken", valid_598321
  var valid_598322 = query.getOrDefault("maxResults")
  valid_598322 = validateParameter(valid_598322, JString, required = false,
                                 default = nil)
  if valid_598322 != nil:
    section.add "maxResults", valid_598322
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
  var valid_598323 = header.getOrDefault("X-Amz-Target")
  valid_598323 = validateParameter(valid_598323, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListContainerInstances"))
  if valid_598323 != nil:
    section.add "X-Amz-Target", valid_598323
  var valid_598324 = header.getOrDefault("X-Amz-Signature")
  valid_598324 = validateParameter(valid_598324, JString, required = false,
                                 default = nil)
  if valid_598324 != nil:
    section.add "X-Amz-Signature", valid_598324
  var valid_598325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598325 = validateParameter(valid_598325, JString, required = false,
                                 default = nil)
  if valid_598325 != nil:
    section.add "X-Amz-Content-Sha256", valid_598325
  var valid_598326 = header.getOrDefault("X-Amz-Date")
  valid_598326 = validateParameter(valid_598326, JString, required = false,
                                 default = nil)
  if valid_598326 != nil:
    section.add "X-Amz-Date", valid_598326
  var valid_598327 = header.getOrDefault("X-Amz-Credential")
  valid_598327 = validateParameter(valid_598327, JString, required = false,
                                 default = nil)
  if valid_598327 != nil:
    section.add "X-Amz-Credential", valid_598327
  var valid_598328 = header.getOrDefault("X-Amz-Security-Token")
  valid_598328 = validateParameter(valid_598328, JString, required = false,
                                 default = nil)
  if valid_598328 != nil:
    section.add "X-Amz-Security-Token", valid_598328
  var valid_598329 = header.getOrDefault("X-Amz-Algorithm")
  valid_598329 = validateParameter(valid_598329, JString, required = false,
                                 default = nil)
  if valid_598329 != nil:
    section.add "X-Amz-Algorithm", valid_598329
  var valid_598330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598330 = validateParameter(valid_598330, JString, required = false,
                                 default = nil)
  if valid_598330 != nil:
    section.add "X-Amz-SignedHeaders", valid_598330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598332: Call_ListContainerInstances_598318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of container instances in a specified cluster. You can filter the results of a <code>ListContainerInstances</code> operation with cluster query language statements inside the <code>filter</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html">Cluster Query Language</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_598332.validator(path, query, header, formData, body)
  let scheme = call_598332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598332.url(scheme.get, call_598332.host, call_598332.base,
                         call_598332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598332, url, valid)

proc call*(call_598333: Call_ListContainerInstances_598318; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listContainerInstances
  ## Returns a list of container instances in a specified cluster. You can filter the results of a <code>ListContainerInstances</code> operation with cluster query language statements inside the <code>filter</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html">Cluster Query Language</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598334 = newJObject()
  var body_598335 = newJObject()
  add(query_598334, "nextToken", newJString(nextToken))
  if body != nil:
    body_598335 = body
  add(query_598334, "maxResults", newJString(maxResults))
  result = call_598333.call(nil, query_598334, nil, nil, body_598335)

var listContainerInstances* = Call_ListContainerInstances_598318(
    name: "listContainerInstances", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListContainerInstances",
    validator: validate_ListContainerInstances_598319, base: "/",
    url: url_ListContainerInstances_598320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServices_598336 = ref object of OpenApiRestCall_597389
proc url_ListServices_598338(protocol: Scheme; host: string; base: string;
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

proc validate_ListServices_598337(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598339 = query.getOrDefault("nextToken")
  valid_598339 = validateParameter(valid_598339, JString, required = false,
                                 default = nil)
  if valid_598339 != nil:
    section.add "nextToken", valid_598339
  var valid_598340 = query.getOrDefault("maxResults")
  valid_598340 = validateParameter(valid_598340, JString, required = false,
                                 default = nil)
  if valid_598340 != nil:
    section.add "maxResults", valid_598340
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
  var valid_598341 = header.getOrDefault("X-Amz-Target")
  valid_598341 = validateParameter(valid_598341, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListServices"))
  if valid_598341 != nil:
    section.add "X-Amz-Target", valid_598341
  var valid_598342 = header.getOrDefault("X-Amz-Signature")
  valid_598342 = validateParameter(valid_598342, JString, required = false,
                                 default = nil)
  if valid_598342 != nil:
    section.add "X-Amz-Signature", valid_598342
  var valid_598343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598343 = validateParameter(valid_598343, JString, required = false,
                                 default = nil)
  if valid_598343 != nil:
    section.add "X-Amz-Content-Sha256", valid_598343
  var valid_598344 = header.getOrDefault("X-Amz-Date")
  valid_598344 = validateParameter(valid_598344, JString, required = false,
                                 default = nil)
  if valid_598344 != nil:
    section.add "X-Amz-Date", valid_598344
  var valid_598345 = header.getOrDefault("X-Amz-Credential")
  valid_598345 = validateParameter(valid_598345, JString, required = false,
                                 default = nil)
  if valid_598345 != nil:
    section.add "X-Amz-Credential", valid_598345
  var valid_598346 = header.getOrDefault("X-Amz-Security-Token")
  valid_598346 = validateParameter(valid_598346, JString, required = false,
                                 default = nil)
  if valid_598346 != nil:
    section.add "X-Amz-Security-Token", valid_598346
  var valid_598347 = header.getOrDefault("X-Amz-Algorithm")
  valid_598347 = validateParameter(valid_598347, JString, required = false,
                                 default = nil)
  if valid_598347 != nil:
    section.add "X-Amz-Algorithm", valid_598347
  var valid_598348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598348 = validateParameter(valid_598348, JString, required = false,
                                 default = nil)
  if valid_598348 != nil:
    section.add "X-Amz-SignedHeaders", valid_598348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598350: Call_ListServices_598336; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the services that are running in a specified cluster.
  ## 
  let valid = call_598350.validator(path, query, header, formData, body)
  let scheme = call_598350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598350.url(scheme.get, call_598350.host, call_598350.base,
                         call_598350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598350, url, valid)

proc call*(call_598351: Call_ListServices_598336; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listServices
  ## Lists the services that are running in a specified cluster.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598352 = newJObject()
  var body_598353 = newJObject()
  add(query_598352, "nextToken", newJString(nextToken))
  if body != nil:
    body_598353 = body
  add(query_598352, "maxResults", newJString(maxResults))
  result = call_598351.call(nil, query_598352, nil, nil, body_598353)

var listServices* = Call_ListServices_598336(name: "listServices",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListServices",
    validator: validate_ListServices_598337, base: "/", url: url_ListServices_598338,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_598354 = ref object of OpenApiRestCall_597389
proc url_ListTagsForResource_598356(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_598355(path: JsonNode; query: JsonNode;
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
  var valid_598357 = header.getOrDefault("X-Amz-Target")
  valid_598357 = validateParameter(valid_598357, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTagsForResource"))
  if valid_598357 != nil:
    section.add "X-Amz-Target", valid_598357
  var valid_598358 = header.getOrDefault("X-Amz-Signature")
  valid_598358 = validateParameter(valid_598358, JString, required = false,
                                 default = nil)
  if valid_598358 != nil:
    section.add "X-Amz-Signature", valid_598358
  var valid_598359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598359 = validateParameter(valid_598359, JString, required = false,
                                 default = nil)
  if valid_598359 != nil:
    section.add "X-Amz-Content-Sha256", valid_598359
  var valid_598360 = header.getOrDefault("X-Amz-Date")
  valid_598360 = validateParameter(valid_598360, JString, required = false,
                                 default = nil)
  if valid_598360 != nil:
    section.add "X-Amz-Date", valid_598360
  var valid_598361 = header.getOrDefault("X-Amz-Credential")
  valid_598361 = validateParameter(valid_598361, JString, required = false,
                                 default = nil)
  if valid_598361 != nil:
    section.add "X-Amz-Credential", valid_598361
  var valid_598362 = header.getOrDefault("X-Amz-Security-Token")
  valid_598362 = validateParameter(valid_598362, JString, required = false,
                                 default = nil)
  if valid_598362 != nil:
    section.add "X-Amz-Security-Token", valid_598362
  var valid_598363 = header.getOrDefault("X-Amz-Algorithm")
  valid_598363 = validateParameter(valid_598363, JString, required = false,
                                 default = nil)
  if valid_598363 != nil:
    section.add "X-Amz-Algorithm", valid_598363
  var valid_598364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598364 = validateParameter(valid_598364, JString, required = false,
                                 default = nil)
  if valid_598364 != nil:
    section.add "X-Amz-SignedHeaders", valid_598364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598366: Call_ListTagsForResource_598354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an Amazon ECS resource.
  ## 
  let valid = call_598366.validator(path, query, header, formData, body)
  let scheme = call_598366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598366.url(scheme.get, call_598366.host, call_598366.base,
                         call_598366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598366, url, valid)

proc call*(call_598367: Call_ListTagsForResource_598354; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon ECS resource.
  ##   body: JObject (required)
  var body_598368 = newJObject()
  if body != nil:
    body_598368 = body
  result = call_598367.call(nil, nil, nil, nil, body_598368)

var listTagsForResource* = Call_ListTagsForResource_598354(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTagsForResource",
    validator: validate_ListTagsForResource_598355, base: "/",
    url: url_ListTagsForResource_598356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTaskDefinitionFamilies_598369 = ref object of OpenApiRestCall_597389
proc url_ListTaskDefinitionFamilies_598371(protocol: Scheme; host: string;
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

proc validate_ListTaskDefinitionFamilies_598370(path: JsonNode; query: JsonNode;
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
  var valid_598372 = query.getOrDefault("nextToken")
  valid_598372 = validateParameter(valid_598372, JString, required = false,
                                 default = nil)
  if valid_598372 != nil:
    section.add "nextToken", valid_598372
  var valid_598373 = query.getOrDefault("maxResults")
  valid_598373 = validateParameter(valid_598373, JString, required = false,
                                 default = nil)
  if valid_598373 != nil:
    section.add "maxResults", valid_598373
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
  var valid_598374 = header.getOrDefault("X-Amz-Target")
  valid_598374 = validateParameter(valid_598374, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTaskDefinitionFamilies"))
  if valid_598374 != nil:
    section.add "X-Amz-Target", valid_598374
  var valid_598375 = header.getOrDefault("X-Amz-Signature")
  valid_598375 = validateParameter(valid_598375, JString, required = false,
                                 default = nil)
  if valid_598375 != nil:
    section.add "X-Amz-Signature", valid_598375
  var valid_598376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598376 = validateParameter(valid_598376, JString, required = false,
                                 default = nil)
  if valid_598376 != nil:
    section.add "X-Amz-Content-Sha256", valid_598376
  var valid_598377 = header.getOrDefault("X-Amz-Date")
  valid_598377 = validateParameter(valid_598377, JString, required = false,
                                 default = nil)
  if valid_598377 != nil:
    section.add "X-Amz-Date", valid_598377
  var valid_598378 = header.getOrDefault("X-Amz-Credential")
  valid_598378 = validateParameter(valid_598378, JString, required = false,
                                 default = nil)
  if valid_598378 != nil:
    section.add "X-Amz-Credential", valid_598378
  var valid_598379 = header.getOrDefault("X-Amz-Security-Token")
  valid_598379 = validateParameter(valid_598379, JString, required = false,
                                 default = nil)
  if valid_598379 != nil:
    section.add "X-Amz-Security-Token", valid_598379
  var valid_598380 = header.getOrDefault("X-Amz-Algorithm")
  valid_598380 = validateParameter(valid_598380, JString, required = false,
                                 default = nil)
  if valid_598380 != nil:
    section.add "X-Amz-Algorithm", valid_598380
  var valid_598381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598381 = validateParameter(valid_598381, JString, required = false,
                                 default = nil)
  if valid_598381 != nil:
    section.add "X-Amz-SignedHeaders", valid_598381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598383: Call_ListTaskDefinitionFamilies_598369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of task definition families that are registered to your account (which may include task definition families that no longer have any <code>ACTIVE</code> task definition revisions).</p> <p>You can filter out task definition families that do not contain any <code>ACTIVE</code> task definition revisions by setting the <code>status</code> parameter to <code>ACTIVE</code>. You can also filter the results with the <code>familyPrefix</code> parameter.</p>
  ## 
  let valid = call_598383.validator(path, query, header, formData, body)
  let scheme = call_598383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598383.url(scheme.get, call_598383.host, call_598383.base,
                         call_598383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598383, url, valid)

proc call*(call_598384: Call_ListTaskDefinitionFamilies_598369; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTaskDefinitionFamilies
  ## <p>Returns a list of task definition families that are registered to your account (which may include task definition families that no longer have any <code>ACTIVE</code> task definition revisions).</p> <p>You can filter out task definition families that do not contain any <code>ACTIVE</code> task definition revisions by setting the <code>status</code> parameter to <code>ACTIVE</code>. You can also filter the results with the <code>familyPrefix</code> parameter.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598385 = newJObject()
  var body_598386 = newJObject()
  add(query_598385, "nextToken", newJString(nextToken))
  if body != nil:
    body_598386 = body
  add(query_598385, "maxResults", newJString(maxResults))
  result = call_598384.call(nil, query_598385, nil, nil, body_598386)

var listTaskDefinitionFamilies* = Call_ListTaskDefinitionFamilies_598369(
    name: "listTaskDefinitionFamilies", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTaskDefinitionFamilies",
    validator: validate_ListTaskDefinitionFamilies_598370, base: "/",
    url: url_ListTaskDefinitionFamilies_598371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTaskDefinitions_598387 = ref object of OpenApiRestCall_597389
proc url_ListTaskDefinitions_598389(protocol: Scheme; host: string; base: string;
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

proc validate_ListTaskDefinitions_598388(path: JsonNode; query: JsonNode;
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
  var valid_598390 = query.getOrDefault("nextToken")
  valid_598390 = validateParameter(valid_598390, JString, required = false,
                                 default = nil)
  if valid_598390 != nil:
    section.add "nextToken", valid_598390
  var valid_598391 = query.getOrDefault("maxResults")
  valid_598391 = validateParameter(valid_598391, JString, required = false,
                                 default = nil)
  if valid_598391 != nil:
    section.add "maxResults", valid_598391
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
  var valid_598392 = header.getOrDefault("X-Amz-Target")
  valid_598392 = validateParameter(valid_598392, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTaskDefinitions"))
  if valid_598392 != nil:
    section.add "X-Amz-Target", valid_598392
  var valid_598393 = header.getOrDefault("X-Amz-Signature")
  valid_598393 = validateParameter(valid_598393, JString, required = false,
                                 default = nil)
  if valid_598393 != nil:
    section.add "X-Amz-Signature", valid_598393
  var valid_598394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598394 = validateParameter(valid_598394, JString, required = false,
                                 default = nil)
  if valid_598394 != nil:
    section.add "X-Amz-Content-Sha256", valid_598394
  var valid_598395 = header.getOrDefault("X-Amz-Date")
  valid_598395 = validateParameter(valid_598395, JString, required = false,
                                 default = nil)
  if valid_598395 != nil:
    section.add "X-Amz-Date", valid_598395
  var valid_598396 = header.getOrDefault("X-Amz-Credential")
  valid_598396 = validateParameter(valid_598396, JString, required = false,
                                 default = nil)
  if valid_598396 != nil:
    section.add "X-Amz-Credential", valid_598396
  var valid_598397 = header.getOrDefault("X-Amz-Security-Token")
  valid_598397 = validateParameter(valid_598397, JString, required = false,
                                 default = nil)
  if valid_598397 != nil:
    section.add "X-Amz-Security-Token", valid_598397
  var valid_598398 = header.getOrDefault("X-Amz-Algorithm")
  valid_598398 = validateParameter(valid_598398, JString, required = false,
                                 default = nil)
  if valid_598398 != nil:
    section.add "X-Amz-Algorithm", valid_598398
  var valid_598399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598399 = validateParameter(valid_598399, JString, required = false,
                                 default = nil)
  if valid_598399 != nil:
    section.add "X-Amz-SignedHeaders", valid_598399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598401: Call_ListTaskDefinitions_598387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of task definitions that are registered to your account. You can filter the results by family name with the <code>familyPrefix</code> parameter or by status with the <code>status</code> parameter.
  ## 
  let valid = call_598401.validator(path, query, header, formData, body)
  let scheme = call_598401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598401.url(scheme.get, call_598401.host, call_598401.base,
                         call_598401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598401, url, valid)

proc call*(call_598402: Call_ListTaskDefinitions_598387; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTaskDefinitions
  ## Returns a list of task definitions that are registered to your account. You can filter the results by family name with the <code>familyPrefix</code> parameter or by status with the <code>status</code> parameter.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598403 = newJObject()
  var body_598404 = newJObject()
  add(query_598403, "nextToken", newJString(nextToken))
  if body != nil:
    body_598404 = body
  add(query_598403, "maxResults", newJString(maxResults))
  result = call_598402.call(nil, query_598403, nil, nil, body_598404)

var listTaskDefinitions* = Call_ListTaskDefinitions_598387(
    name: "listTaskDefinitions", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTaskDefinitions",
    validator: validate_ListTaskDefinitions_598388, base: "/",
    url: url_ListTaskDefinitions_598389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTasks_598405 = ref object of OpenApiRestCall_597389
proc url_ListTasks_598407(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTasks_598406(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598408 = query.getOrDefault("nextToken")
  valid_598408 = validateParameter(valid_598408, JString, required = false,
                                 default = nil)
  if valid_598408 != nil:
    section.add "nextToken", valid_598408
  var valid_598409 = query.getOrDefault("maxResults")
  valid_598409 = validateParameter(valid_598409, JString, required = false,
                                 default = nil)
  if valid_598409 != nil:
    section.add "maxResults", valid_598409
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
  var valid_598410 = header.getOrDefault("X-Amz-Target")
  valid_598410 = validateParameter(valid_598410, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTasks"))
  if valid_598410 != nil:
    section.add "X-Amz-Target", valid_598410
  var valid_598411 = header.getOrDefault("X-Amz-Signature")
  valid_598411 = validateParameter(valid_598411, JString, required = false,
                                 default = nil)
  if valid_598411 != nil:
    section.add "X-Amz-Signature", valid_598411
  var valid_598412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598412 = validateParameter(valid_598412, JString, required = false,
                                 default = nil)
  if valid_598412 != nil:
    section.add "X-Amz-Content-Sha256", valid_598412
  var valid_598413 = header.getOrDefault("X-Amz-Date")
  valid_598413 = validateParameter(valid_598413, JString, required = false,
                                 default = nil)
  if valid_598413 != nil:
    section.add "X-Amz-Date", valid_598413
  var valid_598414 = header.getOrDefault("X-Amz-Credential")
  valid_598414 = validateParameter(valid_598414, JString, required = false,
                                 default = nil)
  if valid_598414 != nil:
    section.add "X-Amz-Credential", valid_598414
  var valid_598415 = header.getOrDefault("X-Amz-Security-Token")
  valid_598415 = validateParameter(valid_598415, JString, required = false,
                                 default = nil)
  if valid_598415 != nil:
    section.add "X-Amz-Security-Token", valid_598415
  var valid_598416 = header.getOrDefault("X-Amz-Algorithm")
  valid_598416 = validateParameter(valid_598416, JString, required = false,
                                 default = nil)
  if valid_598416 != nil:
    section.add "X-Amz-Algorithm", valid_598416
  var valid_598417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598417 = validateParameter(valid_598417, JString, required = false,
                                 default = nil)
  if valid_598417 != nil:
    section.add "X-Amz-SignedHeaders", valid_598417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598419: Call_ListTasks_598405; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of tasks for a specified cluster. You can filter the results by family name, by a particular container instance, or by the desired status of the task with the <code>family</code>, <code>containerInstance</code>, and <code>desiredStatus</code> parameters.</p> <p>Recently stopped tasks might appear in the returned results. Currently, stopped tasks appear in the returned results for at least one hour. </p>
  ## 
  let valid = call_598419.validator(path, query, header, formData, body)
  let scheme = call_598419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598419.url(scheme.get, call_598419.host, call_598419.base,
                         call_598419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598419, url, valid)

proc call*(call_598420: Call_ListTasks_598405; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listTasks
  ## <p>Returns a list of tasks for a specified cluster. You can filter the results by family name, by a particular container instance, or by the desired status of the task with the <code>family</code>, <code>containerInstance</code>, and <code>desiredStatus</code> parameters.</p> <p>Recently stopped tasks might appear in the returned results. Currently, stopped tasks appear in the returned results for at least one hour. </p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_598421 = newJObject()
  var body_598422 = newJObject()
  add(query_598421, "nextToken", newJString(nextToken))
  if body != nil:
    body_598422 = body
  add(query_598421, "maxResults", newJString(maxResults))
  result = call_598420.call(nil, query_598421, nil, nil, body_598422)

var listTasks* = Call_ListTasks_598405(name: "listTasks", meth: HttpMethod.HttpPost,
                                    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTasks",
                                    validator: validate_ListTasks_598406,
                                    base: "/", url: url_ListTasks_598407,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSetting_598423 = ref object of OpenApiRestCall_597389
proc url_PutAccountSetting_598425(protocol: Scheme; host: string; base: string;
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

proc validate_PutAccountSetting_598424(path: JsonNode; query: JsonNode;
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
  var valid_598426 = header.getOrDefault("X-Amz-Target")
  valid_598426 = validateParameter(valid_598426, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutAccountSetting"))
  if valid_598426 != nil:
    section.add "X-Amz-Target", valid_598426
  var valid_598427 = header.getOrDefault("X-Amz-Signature")
  valid_598427 = validateParameter(valid_598427, JString, required = false,
                                 default = nil)
  if valid_598427 != nil:
    section.add "X-Amz-Signature", valid_598427
  var valid_598428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598428 = validateParameter(valid_598428, JString, required = false,
                                 default = nil)
  if valid_598428 != nil:
    section.add "X-Amz-Content-Sha256", valid_598428
  var valid_598429 = header.getOrDefault("X-Amz-Date")
  valid_598429 = validateParameter(valid_598429, JString, required = false,
                                 default = nil)
  if valid_598429 != nil:
    section.add "X-Amz-Date", valid_598429
  var valid_598430 = header.getOrDefault("X-Amz-Credential")
  valid_598430 = validateParameter(valid_598430, JString, required = false,
                                 default = nil)
  if valid_598430 != nil:
    section.add "X-Amz-Credential", valid_598430
  var valid_598431 = header.getOrDefault("X-Amz-Security-Token")
  valid_598431 = validateParameter(valid_598431, JString, required = false,
                                 default = nil)
  if valid_598431 != nil:
    section.add "X-Amz-Security-Token", valid_598431
  var valid_598432 = header.getOrDefault("X-Amz-Algorithm")
  valid_598432 = validateParameter(valid_598432, JString, required = false,
                                 default = nil)
  if valid_598432 != nil:
    section.add "X-Amz-Algorithm", valid_598432
  var valid_598433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598433 = validateParameter(valid_598433, JString, required = false,
                                 default = nil)
  if valid_598433 != nil:
    section.add "X-Amz-SignedHeaders", valid_598433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598435: Call_PutAccountSetting_598423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies an account setting. Account settings are set on a per-Region basis.</p> <p>If you change the account setting for the root user, the default settings for all of the IAM users and roles for which no individual account setting has been specified are reset. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html">Account Settings</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>serviceLongArnFormat</code>, <code>taskLongArnFormat</code>, or <code>containerInstanceLongArnFormat</code> are specified, the Amazon Resource Name (ARN) and resource ID format of the resource type for a specified IAM user, IAM role, or the root user for an account is affected. The opt-in and opt-out account setting must be set for each Amazon ECS resource separately. The ARN and resource ID format of a resource will be defined by the opt-in status of the IAM user or role that created the resource. You must enable this setting to use Amazon ECS features such as resource tagging.</p> <p>When <code>awsvpcTrunking</code> is specified, the elastic network interface (ENI) limit for any new container instances that support the feature is changed. If <code>awsvpcTrunking</code> is enabled, any new container instances that support the feature are launched have the increased ENI limits available to them. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html">Elastic Network Interface Trunking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>containerInsights</code> is specified, the default setting indicating whether CloudWatch Container Insights is enabled for your clusters is changed. If <code>containerInsights</code> is enabled, any new clusters that are created will have Container Insights enabled unless you disable it during cluster creation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-container-insights.html">CloudWatch Container Insights</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_598435.validator(path, query, header, formData, body)
  let scheme = call_598435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598435.url(scheme.get, call_598435.host, call_598435.base,
                         call_598435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598435, url, valid)

proc call*(call_598436: Call_PutAccountSetting_598423; body: JsonNode): Recallable =
  ## putAccountSetting
  ## <p>Modifies an account setting. Account settings are set on a per-Region basis.</p> <p>If you change the account setting for the root user, the default settings for all of the IAM users and roles for which no individual account setting has been specified are reset. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html">Account Settings</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>serviceLongArnFormat</code>, <code>taskLongArnFormat</code>, or <code>containerInstanceLongArnFormat</code> are specified, the Amazon Resource Name (ARN) and resource ID format of the resource type for a specified IAM user, IAM role, or the root user for an account is affected. The opt-in and opt-out account setting must be set for each Amazon ECS resource separately. The ARN and resource ID format of a resource will be defined by the opt-in status of the IAM user or role that created the resource. You must enable this setting to use Amazon ECS features such as resource tagging.</p> <p>When <code>awsvpcTrunking</code> is specified, the elastic network interface (ENI) limit for any new container instances that support the feature is changed. If <code>awsvpcTrunking</code> is enabled, any new container instances that support the feature are launched have the increased ENI limits available to them. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html">Elastic Network Interface Trunking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>containerInsights</code> is specified, the default setting indicating whether CloudWatch Container Insights is enabled for your clusters is changed. If <code>containerInsights</code> is enabled, any new clusters that are created will have Container Insights enabled unless you disable it during cluster creation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-container-insights.html">CloudWatch Container Insights</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_598437 = newJObject()
  if body != nil:
    body_598437 = body
  result = call_598436.call(nil, nil, nil, nil, body_598437)

var putAccountSetting* = Call_PutAccountSetting_598423(name: "putAccountSetting",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAccountSetting",
    validator: validate_PutAccountSetting_598424, base: "/",
    url: url_PutAccountSetting_598425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSettingDefault_598438 = ref object of OpenApiRestCall_597389
proc url_PutAccountSettingDefault_598440(protocol: Scheme; host: string;
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

proc validate_PutAccountSettingDefault_598439(path: JsonNode; query: JsonNode;
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
  var valid_598441 = header.getOrDefault("X-Amz-Target")
  valid_598441 = validateParameter(valid_598441, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutAccountSettingDefault"))
  if valid_598441 != nil:
    section.add "X-Amz-Target", valid_598441
  var valid_598442 = header.getOrDefault("X-Amz-Signature")
  valid_598442 = validateParameter(valid_598442, JString, required = false,
                                 default = nil)
  if valid_598442 != nil:
    section.add "X-Amz-Signature", valid_598442
  var valid_598443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598443 = validateParameter(valid_598443, JString, required = false,
                                 default = nil)
  if valid_598443 != nil:
    section.add "X-Amz-Content-Sha256", valid_598443
  var valid_598444 = header.getOrDefault("X-Amz-Date")
  valid_598444 = validateParameter(valid_598444, JString, required = false,
                                 default = nil)
  if valid_598444 != nil:
    section.add "X-Amz-Date", valid_598444
  var valid_598445 = header.getOrDefault("X-Amz-Credential")
  valid_598445 = validateParameter(valid_598445, JString, required = false,
                                 default = nil)
  if valid_598445 != nil:
    section.add "X-Amz-Credential", valid_598445
  var valid_598446 = header.getOrDefault("X-Amz-Security-Token")
  valid_598446 = validateParameter(valid_598446, JString, required = false,
                                 default = nil)
  if valid_598446 != nil:
    section.add "X-Amz-Security-Token", valid_598446
  var valid_598447 = header.getOrDefault("X-Amz-Algorithm")
  valid_598447 = validateParameter(valid_598447, JString, required = false,
                                 default = nil)
  if valid_598447 != nil:
    section.add "X-Amz-Algorithm", valid_598447
  var valid_598448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598448 = validateParameter(valid_598448, JString, required = false,
                                 default = nil)
  if valid_598448 != nil:
    section.add "X-Amz-SignedHeaders", valid_598448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598450: Call_PutAccountSettingDefault_598438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an account setting for all IAM users on an account for whom no individual account setting has been specified. Account settings are set on a per-Region basis.
  ## 
  let valid = call_598450.validator(path, query, header, formData, body)
  let scheme = call_598450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598450.url(scheme.get, call_598450.host, call_598450.base,
                         call_598450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598450, url, valid)

proc call*(call_598451: Call_PutAccountSettingDefault_598438; body: JsonNode): Recallable =
  ## putAccountSettingDefault
  ## Modifies an account setting for all IAM users on an account for whom no individual account setting has been specified. Account settings are set on a per-Region basis.
  ##   body: JObject (required)
  var body_598452 = newJObject()
  if body != nil:
    body_598452 = body
  result = call_598451.call(nil, nil, nil, nil, body_598452)

var putAccountSettingDefault* = Call_PutAccountSettingDefault_598438(
    name: "putAccountSettingDefault", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAccountSettingDefault",
    validator: validate_PutAccountSettingDefault_598439, base: "/",
    url: url_PutAccountSettingDefault_598440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAttributes_598453 = ref object of OpenApiRestCall_597389
proc url_PutAttributes_598455(protocol: Scheme; host: string; base: string;
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

proc validate_PutAttributes_598454(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598456 = header.getOrDefault("X-Amz-Target")
  valid_598456 = validateParameter(valid_598456, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutAttributes"))
  if valid_598456 != nil:
    section.add "X-Amz-Target", valid_598456
  var valid_598457 = header.getOrDefault("X-Amz-Signature")
  valid_598457 = validateParameter(valid_598457, JString, required = false,
                                 default = nil)
  if valid_598457 != nil:
    section.add "X-Amz-Signature", valid_598457
  var valid_598458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598458 = validateParameter(valid_598458, JString, required = false,
                                 default = nil)
  if valid_598458 != nil:
    section.add "X-Amz-Content-Sha256", valid_598458
  var valid_598459 = header.getOrDefault("X-Amz-Date")
  valid_598459 = validateParameter(valid_598459, JString, required = false,
                                 default = nil)
  if valid_598459 != nil:
    section.add "X-Amz-Date", valid_598459
  var valid_598460 = header.getOrDefault("X-Amz-Credential")
  valid_598460 = validateParameter(valid_598460, JString, required = false,
                                 default = nil)
  if valid_598460 != nil:
    section.add "X-Amz-Credential", valid_598460
  var valid_598461 = header.getOrDefault("X-Amz-Security-Token")
  valid_598461 = validateParameter(valid_598461, JString, required = false,
                                 default = nil)
  if valid_598461 != nil:
    section.add "X-Amz-Security-Token", valid_598461
  var valid_598462 = header.getOrDefault("X-Amz-Algorithm")
  valid_598462 = validateParameter(valid_598462, JString, required = false,
                                 default = nil)
  if valid_598462 != nil:
    section.add "X-Amz-Algorithm", valid_598462
  var valid_598463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598463 = validateParameter(valid_598463, JString, required = false,
                                 default = nil)
  if valid_598463 != nil:
    section.add "X-Amz-SignedHeaders", valid_598463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598465: Call_PutAttributes_598453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update an attribute on an Amazon ECS resource. If the attribute does not exist, it is created. If the attribute exists, its value is replaced with the specified value. To delete an attribute, use <a>DeleteAttributes</a>. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#attributes">Attributes</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_598465.validator(path, query, header, formData, body)
  let scheme = call_598465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598465.url(scheme.get, call_598465.host, call_598465.base,
                         call_598465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598465, url, valid)

proc call*(call_598466: Call_PutAttributes_598453; body: JsonNode): Recallable =
  ## putAttributes
  ## Create or update an attribute on an Amazon ECS resource. If the attribute does not exist, it is created. If the attribute exists, its value is replaced with the specified value. To delete an attribute, use <a>DeleteAttributes</a>. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#attributes">Attributes</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_598467 = newJObject()
  if body != nil:
    body_598467 = body
  result = call_598466.call(nil, nil, nil, nil, body_598467)

var putAttributes* = Call_PutAttributes_598453(name: "putAttributes",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAttributes",
    validator: validate_PutAttributes_598454, base: "/", url: url_PutAttributes_598455,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutClusterCapacityProviders_598468 = ref object of OpenApiRestCall_597389
proc url_PutClusterCapacityProviders_598470(protocol: Scheme; host: string;
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

proc validate_PutClusterCapacityProviders_598469(path: JsonNode; query: JsonNode;
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
  var valid_598471 = header.getOrDefault("X-Amz-Target")
  valid_598471 = validateParameter(valid_598471, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutClusterCapacityProviders"))
  if valid_598471 != nil:
    section.add "X-Amz-Target", valid_598471
  var valid_598472 = header.getOrDefault("X-Amz-Signature")
  valid_598472 = validateParameter(valid_598472, JString, required = false,
                                 default = nil)
  if valid_598472 != nil:
    section.add "X-Amz-Signature", valid_598472
  var valid_598473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598473 = validateParameter(valid_598473, JString, required = false,
                                 default = nil)
  if valid_598473 != nil:
    section.add "X-Amz-Content-Sha256", valid_598473
  var valid_598474 = header.getOrDefault("X-Amz-Date")
  valid_598474 = validateParameter(valid_598474, JString, required = false,
                                 default = nil)
  if valid_598474 != nil:
    section.add "X-Amz-Date", valid_598474
  var valid_598475 = header.getOrDefault("X-Amz-Credential")
  valid_598475 = validateParameter(valid_598475, JString, required = false,
                                 default = nil)
  if valid_598475 != nil:
    section.add "X-Amz-Credential", valid_598475
  var valid_598476 = header.getOrDefault("X-Amz-Security-Token")
  valid_598476 = validateParameter(valid_598476, JString, required = false,
                                 default = nil)
  if valid_598476 != nil:
    section.add "X-Amz-Security-Token", valid_598476
  var valid_598477 = header.getOrDefault("X-Amz-Algorithm")
  valid_598477 = validateParameter(valid_598477, JString, required = false,
                                 default = nil)
  if valid_598477 != nil:
    section.add "X-Amz-Algorithm", valid_598477
  var valid_598478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598478 = validateParameter(valid_598478, JString, required = false,
                                 default = nil)
  if valid_598478 != nil:
    section.add "X-Amz-SignedHeaders", valid_598478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598480: Call_PutClusterCapacityProviders_598468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the available capacity providers and the default capacity provider strategy for a cluster.</p> <p>You must specify both the available capacity providers and a default capacity provider strategy for the cluster. If the specified cluster has existing capacity providers associated with it, you must specify all existing capacity providers in addition to any new ones you want to add. Any existing capacity providers associated with a cluster that are omitted from a <a>PutClusterCapacityProviders</a> API call will be disassociated with the cluster. You can only disassociate an existing capacity provider from a cluster if it's not being used by any existing tasks.</p> <p>When creating a service or running a task on a cluster, if no capacity provider or launch type is specified, then the cluster's default capacity provider strategy is used. It is recommended to define a default capacity provider strategy for your cluster, however you may specify an empty array (<code>[]</code>) to bypass defining a default strategy.</p>
  ## 
  let valid = call_598480.validator(path, query, header, formData, body)
  let scheme = call_598480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598480.url(scheme.get, call_598480.host, call_598480.base,
                         call_598480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598480, url, valid)

proc call*(call_598481: Call_PutClusterCapacityProviders_598468; body: JsonNode): Recallable =
  ## putClusterCapacityProviders
  ## <p>Modifies the available capacity providers and the default capacity provider strategy for a cluster.</p> <p>You must specify both the available capacity providers and a default capacity provider strategy for the cluster. If the specified cluster has existing capacity providers associated with it, you must specify all existing capacity providers in addition to any new ones you want to add. Any existing capacity providers associated with a cluster that are omitted from a <a>PutClusterCapacityProviders</a> API call will be disassociated with the cluster. You can only disassociate an existing capacity provider from a cluster if it's not being used by any existing tasks.</p> <p>When creating a service or running a task on a cluster, if no capacity provider or launch type is specified, then the cluster's default capacity provider strategy is used. It is recommended to define a default capacity provider strategy for your cluster, however you may specify an empty array (<code>[]</code>) to bypass defining a default strategy.</p>
  ##   body: JObject (required)
  var body_598482 = newJObject()
  if body != nil:
    body_598482 = body
  result = call_598481.call(nil, nil, nil, nil, body_598482)

var putClusterCapacityProviders* = Call_PutClusterCapacityProviders_598468(
    name: "putClusterCapacityProviders", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutClusterCapacityProviders",
    validator: validate_PutClusterCapacityProviders_598469, base: "/",
    url: url_PutClusterCapacityProviders_598470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterContainerInstance_598483 = ref object of OpenApiRestCall_597389
proc url_RegisterContainerInstance_598485(protocol: Scheme; host: string;
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

proc validate_RegisterContainerInstance_598484(path: JsonNode; query: JsonNode;
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
  var valid_598486 = header.getOrDefault("X-Amz-Target")
  valid_598486 = validateParameter(valid_598486, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.RegisterContainerInstance"))
  if valid_598486 != nil:
    section.add "X-Amz-Target", valid_598486
  var valid_598487 = header.getOrDefault("X-Amz-Signature")
  valid_598487 = validateParameter(valid_598487, JString, required = false,
                                 default = nil)
  if valid_598487 != nil:
    section.add "X-Amz-Signature", valid_598487
  var valid_598488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598488 = validateParameter(valid_598488, JString, required = false,
                                 default = nil)
  if valid_598488 != nil:
    section.add "X-Amz-Content-Sha256", valid_598488
  var valid_598489 = header.getOrDefault("X-Amz-Date")
  valid_598489 = validateParameter(valid_598489, JString, required = false,
                                 default = nil)
  if valid_598489 != nil:
    section.add "X-Amz-Date", valid_598489
  var valid_598490 = header.getOrDefault("X-Amz-Credential")
  valid_598490 = validateParameter(valid_598490, JString, required = false,
                                 default = nil)
  if valid_598490 != nil:
    section.add "X-Amz-Credential", valid_598490
  var valid_598491 = header.getOrDefault("X-Amz-Security-Token")
  valid_598491 = validateParameter(valid_598491, JString, required = false,
                                 default = nil)
  if valid_598491 != nil:
    section.add "X-Amz-Security-Token", valid_598491
  var valid_598492 = header.getOrDefault("X-Amz-Algorithm")
  valid_598492 = validateParameter(valid_598492, JString, required = false,
                                 default = nil)
  if valid_598492 != nil:
    section.add "X-Amz-Algorithm", valid_598492
  var valid_598493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598493 = validateParameter(valid_598493, JString, required = false,
                                 default = nil)
  if valid_598493 != nil:
    section.add "X-Amz-SignedHeaders", valid_598493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598495: Call_RegisterContainerInstance_598483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Registers an EC2 instance into the specified cluster. This instance becomes available to place containers on.</p>
  ## 
  let valid = call_598495.validator(path, query, header, formData, body)
  let scheme = call_598495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598495.url(scheme.get, call_598495.host, call_598495.base,
                         call_598495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598495, url, valid)

proc call*(call_598496: Call_RegisterContainerInstance_598483; body: JsonNode): Recallable =
  ## registerContainerInstance
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Registers an EC2 instance into the specified cluster. This instance becomes available to place containers on.</p>
  ##   body: JObject (required)
  var body_598497 = newJObject()
  if body != nil:
    body_598497 = body
  result = call_598496.call(nil, nil, nil, nil, body_598497)

var registerContainerInstance* = Call_RegisterContainerInstance_598483(
    name: "registerContainerInstance", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RegisterContainerInstance",
    validator: validate_RegisterContainerInstance_598484, base: "/",
    url: url_RegisterContainerInstance_598485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskDefinition_598498 = ref object of OpenApiRestCall_597389
proc url_RegisterTaskDefinition_598500(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterTaskDefinition_598499(path: JsonNode; query: JsonNode;
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
  var valid_598501 = header.getOrDefault("X-Amz-Target")
  valid_598501 = validateParameter(valid_598501, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.RegisterTaskDefinition"))
  if valid_598501 != nil:
    section.add "X-Amz-Target", valid_598501
  var valid_598502 = header.getOrDefault("X-Amz-Signature")
  valid_598502 = validateParameter(valid_598502, JString, required = false,
                                 default = nil)
  if valid_598502 != nil:
    section.add "X-Amz-Signature", valid_598502
  var valid_598503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598503 = validateParameter(valid_598503, JString, required = false,
                                 default = nil)
  if valid_598503 != nil:
    section.add "X-Amz-Content-Sha256", valid_598503
  var valid_598504 = header.getOrDefault("X-Amz-Date")
  valid_598504 = validateParameter(valid_598504, JString, required = false,
                                 default = nil)
  if valid_598504 != nil:
    section.add "X-Amz-Date", valid_598504
  var valid_598505 = header.getOrDefault("X-Amz-Credential")
  valid_598505 = validateParameter(valid_598505, JString, required = false,
                                 default = nil)
  if valid_598505 != nil:
    section.add "X-Amz-Credential", valid_598505
  var valid_598506 = header.getOrDefault("X-Amz-Security-Token")
  valid_598506 = validateParameter(valid_598506, JString, required = false,
                                 default = nil)
  if valid_598506 != nil:
    section.add "X-Amz-Security-Token", valid_598506
  var valid_598507 = header.getOrDefault("X-Amz-Algorithm")
  valid_598507 = validateParameter(valid_598507, JString, required = false,
                                 default = nil)
  if valid_598507 != nil:
    section.add "X-Amz-Algorithm", valid_598507
  var valid_598508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598508 = validateParameter(valid_598508, JString, required = false,
                                 default = nil)
  if valid_598508 != nil:
    section.add "X-Amz-SignedHeaders", valid_598508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598510: Call_RegisterTaskDefinition_598498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a new task definition from the supplied <code>family</code> and <code>containerDefinitions</code>. Optionally, you can add data volumes to your containers with the <code>volumes</code> parameter. For more information about task definition parameters and defaults, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_defintions.html">Amazon ECS Task Definitions</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify an IAM role for your task with the <code>taskRoleArn</code> parameter. When you specify an IAM role for a task, its containers can then use the latest versions of the AWS CLI or SDKs to make API requests to the AWS services that are specified in the IAM policy associated with the role. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html">IAM Roles for Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify a Docker networking mode for the containers in your task definition with the <code>networkMode</code> parameter. The available network modes correspond to those described in <a href="https://docs.docker.com/engine/reference/run/#/network-settings">Network settings</a> in the Docker run reference. If you specify the <code>awsvpc</code> network mode, the task is allocated an elastic network interface, and you must specify a <a>NetworkConfiguration</a> when you create a service or run a task with the task definition. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html">Task Networking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_598510.validator(path, query, header, formData, body)
  let scheme = call_598510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598510.url(scheme.get, call_598510.host, call_598510.base,
                         call_598510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598510, url, valid)

proc call*(call_598511: Call_RegisterTaskDefinition_598498; body: JsonNode): Recallable =
  ## registerTaskDefinition
  ## <p>Registers a new task definition from the supplied <code>family</code> and <code>containerDefinitions</code>. Optionally, you can add data volumes to your containers with the <code>volumes</code> parameter. For more information about task definition parameters and defaults, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_defintions.html">Amazon ECS Task Definitions</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify an IAM role for your task with the <code>taskRoleArn</code> parameter. When you specify an IAM role for a task, its containers can then use the latest versions of the AWS CLI or SDKs to make API requests to the AWS services that are specified in the IAM policy associated with the role. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html">IAM Roles for Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify a Docker networking mode for the containers in your task definition with the <code>networkMode</code> parameter. The available network modes correspond to those described in <a href="https://docs.docker.com/engine/reference/run/#/network-settings">Network settings</a> in the Docker run reference. If you specify the <code>awsvpc</code> network mode, the task is allocated an elastic network interface, and you must specify a <a>NetworkConfiguration</a> when you create a service or run a task with the task definition. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html">Task Networking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_598512 = newJObject()
  if body != nil:
    body_598512 = body
  result = call_598511.call(nil, nil, nil, nil, body_598512)

var registerTaskDefinition* = Call_RegisterTaskDefinition_598498(
    name: "registerTaskDefinition", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RegisterTaskDefinition",
    validator: validate_RegisterTaskDefinition_598499, base: "/",
    url: url_RegisterTaskDefinition_598500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RunTask_598513 = ref object of OpenApiRestCall_597389
proc url_RunTask_598515(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_RunTask_598514(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598516 = header.getOrDefault("X-Amz-Target")
  valid_598516 = validateParameter(valid_598516, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.RunTask"))
  if valid_598516 != nil:
    section.add "X-Amz-Target", valid_598516
  var valid_598517 = header.getOrDefault("X-Amz-Signature")
  valid_598517 = validateParameter(valid_598517, JString, required = false,
                                 default = nil)
  if valid_598517 != nil:
    section.add "X-Amz-Signature", valid_598517
  var valid_598518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598518 = validateParameter(valid_598518, JString, required = false,
                                 default = nil)
  if valid_598518 != nil:
    section.add "X-Amz-Content-Sha256", valid_598518
  var valid_598519 = header.getOrDefault("X-Amz-Date")
  valid_598519 = validateParameter(valid_598519, JString, required = false,
                                 default = nil)
  if valid_598519 != nil:
    section.add "X-Amz-Date", valid_598519
  var valid_598520 = header.getOrDefault("X-Amz-Credential")
  valid_598520 = validateParameter(valid_598520, JString, required = false,
                                 default = nil)
  if valid_598520 != nil:
    section.add "X-Amz-Credential", valid_598520
  var valid_598521 = header.getOrDefault("X-Amz-Security-Token")
  valid_598521 = validateParameter(valid_598521, JString, required = false,
                                 default = nil)
  if valid_598521 != nil:
    section.add "X-Amz-Security-Token", valid_598521
  var valid_598522 = header.getOrDefault("X-Amz-Algorithm")
  valid_598522 = validateParameter(valid_598522, JString, required = false,
                                 default = nil)
  if valid_598522 != nil:
    section.add "X-Amz-Algorithm", valid_598522
  var valid_598523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598523 = validateParameter(valid_598523, JString, required = false,
                                 default = nil)
  if valid_598523 != nil:
    section.add "X-Amz-SignedHeaders", valid_598523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598525: Call_RunTask_598513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a new task using the specified task definition.</p> <p>You can allow Amazon ECS to place tasks for you, or you can customize how Amazon ECS places tasks using placement constraints and placement strategies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Alternatively, you can use <a>StartTask</a> to use your own scheduler or place tasks manually on specific container instances.</p> <p>The Amazon ECS API follows an eventual consistency model, due to the distributed nature of the system supporting the API. This means that the result of an API command you run that affects your Amazon ECS resources might not be immediately visible to all subsequent commands you run. Keep this in mind when you carry out an API command that immediately follows a previous API command.</p> <p>To manage eventual consistency, you can do the following:</p> <ul> <li> <p>Confirm the state of the resource before you run a command to modify it. Run the DescribeTasks command using an exponential backoff algorithm to ensure that you allow enough time for the previous command to propagate through the system. To do this, run the DescribeTasks command repeatedly, starting with a couple of seconds of wait time and increasing gradually up to five minutes of wait time.</p> </li> <li> <p>Add wait time between subsequent commands, even if the DescribeTasks command returns an accurate response. Apply an exponential backoff algorithm starting with a couple of seconds of wait time, and increase gradually up to about five minutes of wait time.</p> </li> </ul>
  ## 
  let valid = call_598525.validator(path, query, header, formData, body)
  let scheme = call_598525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598525.url(scheme.get, call_598525.host, call_598525.base,
                         call_598525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598525, url, valid)

proc call*(call_598526: Call_RunTask_598513; body: JsonNode): Recallable =
  ## runTask
  ## <p>Starts a new task using the specified task definition.</p> <p>You can allow Amazon ECS to place tasks for you, or you can customize how Amazon ECS places tasks using placement constraints and placement strategies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Alternatively, you can use <a>StartTask</a> to use your own scheduler or place tasks manually on specific container instances.</p> <p>The Amazon ECS API follows an eventual consistency model, due to the distributed nature of the system supporting the API. This means that the result of an API command you run that affects your Amazon ECS resources might not be immediately visible to all subsequent commands you run. Keep this in mind when you carry out an API command that immediately follows a previous API command.</p> <p>To manage eventual consistency, you can do the following:</p> <ul> <li> <p>Confirm the state of the resource before you run a command to modify it. Run the DescribeTasks command using an exponential backoff algorithm to ensure that you allow enough time for the previous command to propagate through the system. To do this, run the DescribeTasks command repeatedly, starting with a couple of seconds of wait time and increasing gradually up to five minutes of wait time.</p> </li> <li> <p>Add wait time between subsequent commands, even if the DescribeTasks command returns an accurate response. Apply an exponential backoff algorithm starting with a couple of seconds of wait time, and increase gradually up to about five minutes of wait time.</p> </li> </ul>
  ##   body: JObject (required)
  var body_598527 = newJObject()
  if body != nil:
    body_598527 = body
  result = call_598526.call(nil, nil, nil, nil, body_598527)

var runTask* = Call_RunTask_598513(name: "runTask", meth: HttpMethod.HttpPost,
                                host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RunTask",
                                validator: validate_RunTask_598514, base: "/",
                                url: url_RunTask_598515,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTask_598528 = ref object of OpenApiRestCall_597389
proc url_StartTask_598530(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StartTask_598529(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598531 = header.getOrDefault("X-Amz-Target")
  valid_598531 = validateParameter(valid_598531, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.StartTask"))
  if valid_598531 != nil:
    section.add "X-Amz-Target", valid_598531
  var valid_598532 = header.getOrDefault("X-Amz-Signature")
  valid_598532 = validateParameter(valid_598532, JString, required = false,
                                 default = nil)
  if valid_598532 != nil:
    section.add "X-Amz-Signature", valid_598532
  var valid_598533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598533 = validateParameter(valid_598533, JString, required = false,
                                 default = nil)
  if valid_598533 != nil:
    section.add "X-Amz-Content-Sha256", valid_598533
  var valid_598534 = header.getOrDefault("X-Amz-Date")
  valid_598534 = validateParameter(valid_598534, JString, required = false,
                                 default = nil)
  if valid_598534 != nil:
    section.add "X-Amz-Date", valid_598534
  var valid_598535 = header.getOrDefault("X-Amz-Credential")
  valid_598535 = validateParameter(valid_598535, JString, required = false,
                                 default = nil)
  if valid_598535 != nil:
    section.add "X-Amz-Credential", valid_598535
  var valid_598536 = header.getOrDefault("X-Amz-Security-Token")
  valid_598536 = validateParameter(valid_598536, JString, required = false,
                                 default = nil)
  if valid_598536 != nil:
    section.add "X-Amz-Security-Token", valid_598536
  var valid_598537 = header.getOrDefault("X-Amz-Algorithm")
  valid_598537 = validateParameter(valid_598537, JString, required = false,
                                 default = nil)
  if valid_598537 != nil:
    section.add "X-Amz-Algorithm", valid_598537
  var valid_598538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598538 = validateParameter(valid_598538, JString, required = false,
                                 default = nil)
  if valid_598538 != nil:
    section.add "X-Amz-SignedHeaders", valid_598538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598540: Call_StartTask_598528; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a new task from the specified task definition on the specified container instance or instances.</p> <p>Alternatively, you can use <a>RunTask</a> to place tasks for you. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_598540.validator(path, query, header, formData, body)
  let scheme = call_598540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598540.url(scheme.get, call_598540.host, call_598540.base,
                         call_598540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598540, url, valid)

proc call*(call_598541: Call_StartTask_598528; body: JsonNode): Recallable =
  ## startTask
  ## <p>Starts a new task from the specified task definition on the specified container instance or instances.</p> <p>Alternatively, you can use <a>RunTask</a> to place tasks for you. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_598542 = newJObject()
  if body != nil:
    body_598542 = body
  result = call_598541.call(nil, nil, nil, nil, body_598542)

var startTask* = Call_StartTask_598528(name: "startTask", meth: HttpMethod.HttpPost,
                                    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.StartTask",
                                    validator: validate_StartTask_598529,
                                    base: "/", url: url_StartTask_598530,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTask_598543 = ref object of OpenApiRestCall_597389
proc url_StopTask_598545(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_StopTask_598544(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598546 = header.getOrDefault("X-Amz-Target")
  valid_598546 = validateParameter(valid_598546, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.StopTask"))
  if valid_598546 != nil:
    section.add "X-Amz-Target", valid_598546
  var valid_598547 = header.getOrDefault("X-Amz-Signature")
  valid_598547 = validateParameter(valid_598547, JString, required = false,
                                 default = nil)
  if valid_598547 != nil:
    section.add "X-Amz-Signature", valid_598547
  var valid_598548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598548 = validateParameter(valid_598548, JString, required = false,
                                 default = nil)
  if valid_598548 != nil:
    section.add "X-Amz-Content-Sha256", valid_598548
  var valid_598549 = header.getOrDefault("X-Amz-Date")
  valid_598549 = validateParameter(valid_598549, JString, required = false,
                                 default = nil)
  if valid_598549 != nil:
    section.add "X-Amz-Date", valid_598549
  var valid_598550 = header.getOrDefault("X-Amz-Credential")
  valid_598550 = validateParameter(valid_598550, JString, required = false,
                                 default = nil)
  if valid_598550 != nil:
    section.add "X-Amz-Credential", valid_598550
  var valid_598551 = header.getOrDefault("X-Amz-Security-Token")
  valid_598551 = validateParameter(valid_598551, JString, required = false,
                                 default = nil)
  if valid_598551 != nil:
    section.add "X-Amz-Security-Token", valid_598551
  var valid_598552 = header.getOrDefault("X-Amz-Algorithm")
  valid_598552 = validateParameter(valid_598552, JString, required = false,
                                 default = nil)
  if valid_598552 != nil:
    section.add "X-Amz-Algorithm", valid_598552
  var valid_598553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598553 = validateParameter(valid_598553, JString, required = false,
                                 default = nil)
  if valid_598553 != nil:
    section.add "X-Amz-SignedHeaders", valid_598553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598555: Call_StopTask_598543; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a running task. Any tags associated with the task will be deleted.</p> <p>When <a>StopTask</a> is called on a task, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> value and a default 30-second timeout, after which the <code>SIGKILL</code> value is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> value gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> value is sent.</p> <note> <p>The default 30-second timeout can be configured on the Amazon ECS container agent with the <code>ECS_CONTAINER_STOP_TIMEOUT</code> variable. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html">Amazon ECS Container Agent Configuration</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_598555.validator(path, query, header, formData, body)
  let scheme = call_598555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598555.url(scheme.get, call_598555.host, call_598555.base,
                         call_598555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598555, url, valid)

proc call*(call_598556: Call_StopTask_598543; body: JsonNode): Recallable =
  ## stopTask
  ## <p>Stops a running task. Any tags associated with the task will be deleted.</p> <p>When <a>StopTask</a> is called on a task, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> value and a default 30-second timeout, after which the <code>SIGKILL</code> value is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> value gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> value is sent.</p> <note> <p>The default 30-second timeout can be configured on the Amazon ECS container agent with the <code>ECS_CONTAINER_STOP_TIMEOUT</code> variable. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html">Amazon ECS Container Agent Configuration</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_598557 = newJObject()
  if body != nil:
    body_598557 = body
  result = call_598556.call(nil, nil, nil, nil, body_598557)

var stopTask* = Call_StopTask_598543(name: "stopTask", meth: HttpMethod.HttpPost,
                                  host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.StopTask",
                                  validator: validate_StopTask_598544, base: "/",
                                  url: url_StopTask_598545,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitAttachmentStateChanges_598558 = ref object of OpenApiRestCall_597389
proc url_SubmitAttachmentStateChanges_598560(protocol: Scheme; host: string;
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

proc validate_SubmitAttachmentStateChanges_598559(path: JsonNode; query: JsonNode;
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
  var valid_598561 = header.getOrDefault("X-Amz-Target")
  valid_598561 = validateParameter(valid_598561, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.SubmitAttachmentStateChanges"))
  if valid_598561 != nil:
    section.add "X-Amz-Target", valid_598561
  var valid_598562 = header.getOrDefault("X-Amz-Signature")
  valid_598562 = validateParameter(valid_598562, JString, required = false,
                                 default = nil)
  if valid_598562 != nil:
    section.add "X-Amz-Signature", valid_598562
  var valid_598563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598563 = validateParameter(valid_598563, JString, required = false,
                                 default = nil)
  if valid_598563 != nil:
    section.add "X-Amz-Content-Sha256", valid_598563
  var valid_598564 = header.getOrDefault("X-Amz-Date")
  valid_598564 = validateParameter(valid_598564, JString, required = false,
                                 default = nil)
  if valid_598564 != nil:
    section.add "X-Amz-Date", valid_598564
  var valid_598565 = header.getOrDefault("X-Amz-Credential")
  valid_598565 = validateParameter(valid_598565, JString, required = false,
                                 default = nil)
  if valid_598565 != nil:
    section.add "X-Amz-Credential", valid_598565
  var valid_598566 = header.getOrDefault("X-Amz-Security-Token")
  valid_598566 = validateParameter(valid_598566, JString, required = false,
                                 default = nil)
  if valid_598566 != nil:
    section.add "X-Amz-Security-Token", valid_598566
  var valid_598567 = header.getOrDefault("X-Amz-Algorithm")
  valid_598567 = validateParameter(valid_598567, JString, required = false,
                                 default = nil)
  if valid_598567 != nil:
    section.add "X-Amz-Algorithm", valid_598567
  var valid_598568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598568 = validateParameter(valid_598568, JString, required = false,
                                 default = nil)
  if valid_598568 != nil:
    section.add "X-Amz-SignedHeaders", valid_598568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598570: Call_SubmitAttachmentStateChanges_598558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that an attachment changed states.</p>
  ## 
  let valid = call_598570.validator(path, query, header, formData, body)
  let scheme = call_598570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598570.url(scheme.get, call_598570.host, call_598570.base,
                         call_598570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598570, url, valid)

proc call*(call_598571: Call_SubmitAttachmentStateChanges_598558; body: JsonNode): Recallable =
  ## submitAttachmentStateChanges
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that an attachment changed states.</p>
  ##   body: JObject (required)
  var body_598572 = newJObject()
  if body != nil:
    body_598572 = body
  result = call_598571.call(nil, nil, nil, nil, body_598572)

var submitAttachmentStateChanges* = Call_SubmitAttachmentStateChanges_598558(
    name: "submitAttachmentStateChanges", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitAttachmentStateChanges",
    validator: validate_SubmitAttachmentStateChanges_598559, base: "/",
    url: url_SubmitAttachmentStateChanges_598560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitContainerStateChange_598573 = ref object of OpenApiRestCall_597389
proc url_SubmitContainerStateChange_598575(protocol: Scheme; host: string;
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

proc validate_SubmitContainerStateChange_598574(path: JsonNode; query: JsonNode;
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
  var valid_598576 = header.getOrDefault("X-Amz-Target")
  valid_598576 = validateParameter(valid_598576, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.SubmitContainerStateChange"))
  if valid_598576 != nil:
    section.add "X-Amz-Target", valid_598576
  var valid_598577 = header.getOrDefault("X-Amz-Signature")
  valid_598577 = validateParameter(valid_598577, JString, required = false,
                                 default = nil)
  if valid_598577 != nil:
    section.add "X-Amz-Signature", valid_598577
  var valid_598578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598578 = validateParameter(valid_598578, JString, required = false,
                                 default = nil)
  if valid_598578 != nil:
    section.add "X-Amz-Content-Sha256", valid_598578
  var valid_598579 = header.getOrDefault("X-Amz-Date")
  valid_598579 = validateParameter(valid_598579, JString, required = false,
                                 default = nil)
  if valid_598579 != nil:
    section.add "X-Amz-Date", valid_598579
  var valid_598580 = header.getOrDefault("X-Amz-Credential")
  valid_598580 = validateParameter(valid_598580, JString, required = false,
                                 default = nil)
  if valid_598580 != nil:
    section.add "X-Amz-Credential", valid_598580
  var valid_598581 = header.getOrDefault("X-Amz-Security-Token")
  valid_598581 = validateParameter(valid_598581, JString, required = false,
                                 default = nil)
  if valid_598581 != nil:
    section.add "X-Amz-Security-Token", valid_598581
  var valid_598582 = header.getOrDefault("X-Amz-Algorithm")
  valid_598582 = validateParameter(valid_598582, JString, required = false,
                                 default = nil)
  if valid_598582 != nil:
    section.add "X-Amz-Algorithm", valid_598582
  var valid_598583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598583 = validateParameter(valid_598583, JString, required = false,
                                 default = nil)
  if valid_598583 != nil:
    section.add "X-Amz-SignedHeaders", valid_598583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598585: Call_SubmitContainerStateChange_598573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a container changed states.</p>
  ## 
  let valid = call_598585.validator(path, query, header, formData, body)
  let scheme = call_598585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598585.url(scheme.get, call_598585.host, call_598585.base,
                         call_598585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598585, url, valid)

proc call*(call_598586: Call_SubmitContainerStateChange_598573; body: JsonNode): Recallable =
  ## submitContainerStateChange
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a container changed states.</p>
  ##   body: JObject (required)
  var body_598587 = newJObject()
  if body != nil:
    body_598587 = body
  result = call_598586.call(nil, nil, nil, nil, body_598587)

var submitContainerStateChange* = Call_SubmitContainerStateChange_598573(
    name: "submitContainerStateChange", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitContainerStateChange",
    validator: validate_SubmitContainerStateChange_598574, base: "/",
    url: url_SubmitContainerStateChange_598575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitTaskStateChange_598588 = ref object of OpenApiRestCall_597389
proc url_SubmitTaskStateChange_598590(protocol: Scheme; host: string; base: string;
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

proc validate_SubmitTaskStateChange_598589(path: JsonNode; query: JsonNode;
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
  var valid_598591 = header.getOrDefault("X-Amz-Target")
  valid_598591 = validateParameter(valid_598591, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.SubmitTaskStateChange"))
  if valid_598591 != nil:
    section.add "X-Amz-Target", valid_598591
  var valid_598592 = header.getOrDefault("X-Amz-Signature")
  valid_598592 = validateParameter(valid_598592, JString, required = false,
                                 default = nil)
  if valid_598592 != nil:
    section.add "X-Amz-Signature", valid_598592
  var valid_598593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598593 = validateParameter(valid_598593, JString, required = false,
                                 default = nil)
  if valid_598593 != nil:
    section.add "X-Amz-Content-Sha256", valid_598593
  var valid_598594 = header.getOrDefault("X-Amz-Date")
  valid_598594 = validateParameter(valid_598594, JString, required = false,
                                 default = nil)
  if valid_598594 != nil:
    section.add "X-Amz-Date", valid_598594
  var valid_598595 = header.getOrDefault("X-Amz-Credential")
  valid_598595 = validateParameter(valid_598595, JString, required = false,
                                 default = nil)
  if valid_598595 != nil:
    section.add "X-Amz-Credential", valid_598595
  var valid_598596 = header.getOrDefault("X-Amz-Security-Token")
  valid_598596 = validateParameter(valid_598596, JString, required = false,
                                 default = nil)
  if valid_598596 != nil:
    section.add "X-Amz-Security-Token", valid_598596
  var valid_598597 = header.getOrDefault("X-Amz-Algorithm")
  valid_598597 = validateParameter(valid_598597, JString, required = false,
                                 default = nil)
  if valid_598597 != nil:
    section.add "X-Amz-Algorithm", valid_598597
  var valid_598598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598598 = validateParameter(valid_598598, JString, required = false,
                                 default = nil)
  if valid_598598 != nil:
    section.add "X-Amz-SignedHeaders", valid_598598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598600: Call_SubmitTaskStateChange_598588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a task changed states.</p>
  ## 
  let valid = call_598600.validator(path, query, header, formData, body)
  let scheme = call_598600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598600.url(scheme.get, call_598600.host, call_598600.base,
                         call_598600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598600, url, valid)

proc call*(call_598601: Call_SubmitTaskStateChange_598588; body: JsonNode): Recallable =
  ## submitTaskStateChange
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a task changed states.</p>
  ##   body: JObject (required)
  var body_598602 = newJObject()
  if body != nil:
    body_598602 = body
  result = call_598601.call(nil, nil, nil, nil, body_598602)

var submitTaskStateChange* = Call_SubmitTaskStateChange_598588(
    name: "submitTaskStateChange", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitTaskStateChange",
    validator: validate_SubmitTaskStateChange_598589, base: "/",
    url: url_SubmitTaskStateChange_598590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_598603 = ref object of OpenApiRestCall_597389
proc url_TagResource_598605(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_598604(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598606 = header.getOrDefault("X-Amz-Target")
  valid_598606 = validateParameter(valid_598606, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.TagResource"))
  if valid_598606 != nil:
    section.add "X-Amz-Target", valid_598606
  var valid_598607 = header.getOrDefault("X-Amz-Signature")
  valid_598607 = validateParameter(valid_598607, JString, required = false,
                                 default = nil)
  if valid_598607 != nil:
    section.add "X-Amz-Signature", valid_598607
  var valid_598608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598608 = validateParameter(valid_598608, JString, required = false,
                                 default = nil)
  if valid_598608 != nil:
    section.add "X-Amz-Content-Sha256", valid_598608
  var valid_598609 = header.getOrDefault("X-Amz-Date")
  valid_598609 = validateParameter(valid_598609, JString, required = false,
                                 default = nil)
  if valid_598609 != nil:
    section.add "X-Amz-Date", valid_598609
  var valid_598610 = header.getOrDefault("X-Amz-Credential")
  valid_598610 = validateParameter(valid_598610, JString, required = false,
                                 default = nil)
  if valid_598610 != nil:
    section.add "X-Amz-Credential", valid_598610
  var valid_598611 = header.getOrDefault("X-Amz-Security-Token")
  valid_598611 = validateParameter(valid_598611, JString, required = false,
                                 default = nil)
  if valid_598611 != nil:
    section.add "X-Amz-Security-Token", valid_598611
  var valid_598612 = header.getOrDefault("X-Amz-Algorithm")
  valid_598612 = validateParameter(valid_598612, JString, required = false,
                                 default = nil)
  if valid_598612 != nil:
    section.add "X-Amz-Algorithm", valid_598612
  var valid_598613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598613 = validateParameter(valid_598613, JString, required = false,
                                 default = nil)
  if valid_598613 != nil:
    section.add "X-Amz-SignedHeaders", valid_598613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598615: Call_TagResource_598603; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_598615.validator(path, query, header, formData, body)
  let scheme = call_598615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598615.url(scheme.get, call_598615.host, call_598615.base,
                         call_598615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598615, url, valid)

proc call*(call_598616: Call_TagResource_598603; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  var body_598617 = newJObject()
  if body != nil:
    body_598617 = body
  result = call_598616.call(nil, nil, nil, nil, body_598617)

var tagResource* = Call_TagResource_598603(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.TagResource",
                                        validator: validate_TagResource_598604,
                                        base: "/", url: url_TagResource_598605,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_598618 = ref object of OpenApiRestCall_597389
proc url_UntagResource_598620(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_598619(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598621 = header.getOrDefault("X-Amz-Target")
  valid_598621 = validateParameter(valid_598621, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UntagResource"))
  if valid_598621 != nil:
    section.add "X-Amz-Target", valid_598621
  var valid_598622 = header.getOrDefault("X-Amz-Signature")
  valid_598622 = validateParameter(valid_598622, JString, required = false,
                                 default = nil)
  if valid_598622 != nil:
    section.add "X-Amz-Signature", valid_598622
  var valid_598623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598623 = validateParameter(valid_598623, JString, required = false,
                                 default = nil)
  if valid_598623 != nil:
    section.add "X-Amz-Content-Sha256", valid_598623
  var valid_598624 = header.getOrDefault("X-Amz-Date")
  valid_598624 = validateParameter(valid_598624, JString, required = false,
                                 default = nil)
  if valid_598624 != nil:
    section.add "X-Amz-Date", valid_598624
  var valid_598625 = header.getOrDefault("X-Amz-Credential")
  valid_598625 = validateParameter(valid_598625, JString, required = false,
                                 default = nil)
  if valid_598625 != nil:
    section.add "X-Amz-Credential", valid_598625
  var valid_598626 = header.getOrDefault("X-Amz-Security-Token")
  valid_598626 = validateParameter(valid_598626, JString, required = false,
                                 default = nil)
  if valid_598626 != nil:
    section.add "X-Amz-Security-Token", valid_598626
  var valid_598627 = header.getOrDefault("X-Amz-Algorithm")
  valid_598627 = validateParameter(valid_598627, JString, required = false,
                                 default = nil)
  if valid_598627 != nil:
    section.add "X-Amz-Algorithm", valid_598627
  var valid_598628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598628 = validateParameter(valid_598628, JString, required = false,
                                 default = nil)
  if valid_598628 != nil:
    section.add "X-Amz-SignedHeaders", valid_598628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598630: Call_UntagResource_598618; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_598630.validator(path, query, header, formData, body)
  let scheme = call_598630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598630.url(scheme.get, call_598630.host, call_598630.base,
                         call_598630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598630, url, valid)

proc call*(call_598631: Call_UntagResource_598618; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  var body_598632 = newJObject()
  if body != nil:
    body_598632 = body
  result = call_598631.call(nil, nil, nil, nil, body_598632)

var untagResource* = Call_UntagResource_598618(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UntagResource",
    validator: validate_UntagResource_598619, base: "/", url: url_UntagResource_598620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterSettings_598633 = ref object of OpenApiRestCall_597389
proc url_UpdateClusterSettings_598635(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClusterSettings_598634(path: JsonNode; query: JsonNode;
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
  var valid_598636 = header.getOrDefault("X-Amz-Target")
  valid_598636 = validateParameter(valid_598636, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateClusterSettings"))
  if valid_598636 != nil:
    section.add "X-Amz-Target", valid_598636
  var valid_598637 = header.getOrDefault("X-Amz-Signature")
  valid_598637 = validateParameter(valid_598637, JString, required = false,
                                 default = nil)
  if valid_598637 != nil:
    section.add "X-Amz-Signature", valid_598637
  var valid_598638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598638 = validateParameter(valid_598638, JString, required = false,
                                 default = nil)
  if valid_598638 != nil:
    section.add "X-Amz-Content-Sha256", valid_598638
  var valid_598639 = header.getOrDefault("X-Amz-Date")
  valid_598639 = validateParameter(valid_598639, JString, required = false,
                                 default = nil)
  if valid_598639 != nil:
    section.add "X-Amz-Date", valid_598639
  var valid_598640 = header.getOrDefault("X-Amz-Credential")
  valid_598640 = validateParameter(valid_598640, JString, required = false,
                                 default = nil)
  if valid_598640 != nil:
    section.add "X-Amz-Credential", valid_598640
  var valid_598641 = header.getOrDefault("X-Amz-Security-Token")
  valid_598641 = validateParameter(valid_598641, JString, required = false,
                                 default = nil)
  if valid_598641 != nil:
    section.add "X-Amz-Security-Token", valid_598641
  var valid_598642 = header.getOrDefault("X-Amz-Algorithm")
  valid_598642 = validateParameter(valid_598642, JString, required = false,
                                 default = nil)
  if valid_598642 != nil:
    section.add "X-Amz-Algorithm", valid_598642
  var valid_598643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598643 = validateParameter(valid_598643, JString, required = false,
                                 default = nil)
  if valid_598643 != nil:
    section.add "X-Amz-SignedHeaders", valid_598643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598645: Call_UpdateClusterSettings_598633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the settings to use for a cluster.
  ## 
  let valid = call_598645.validator(path, query, header, formData, body)
  let scheme = call_598645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598645.url(scheme.get, call_598645.host, call_598645.base,
                         call_598645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598645, url, valid)

proc call*(call_598646: Call_UpdateClusterSettings_598633; body: JsonNode): Recallable =
  ## updateClusterSettings
  ## Modifies the settings to use for a cluster.
  ##   body: JObject (required)
  var body_598647 = newJObject()
  if body != nil:
    body_598647 = body
  result = call_598646.call(nil, nil, nil, nil, body_598647)

var updateClusterSettings* = Call_UpdateClusterSettings_598633(
    name: "updateClusterSettings", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateClusterSettings",
    validator: validate_UpdateClusterSettings_598634, base: "/",
    url: url_UpdateClusterSettings_598635, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContainerAgent_598648 = ref object of OpenApiRestCall_597389
proc url_UpdateContainerAgent_598650(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateContainerAgent_598649(path: JsonNode; query: JsonNode;
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
  var valid_598651 = header.getOrDefault("X-Amz-Target")
  valid_598651 = validateParameter(valid_598651, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateContainerAgent"))
  if valid_598651 != nil:
    section.add "X-Amz-Target", valid_598651
  var valid_598652 = header.getOrDefault("X-Amz-Signature")
  valid_598652 = validateParameter(valid_598652, JString, required = false,
                                 default = nil)
  if valid_598652 != nil:
    section.add "X-Amz-Signature", valid_598652
  var valid_598653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598653 = validateParameter(valid_598653, JString, required = false,
                                 default = nil)
  if valid_598653 != nil:
    section.add "X-Amz-Content-Sha256", valid_598653
  var valid_598654 = header.getOrDefault("X-Amz-Date")
  valid_598654 = validateParameter(valid_598654, JString, required = false,
                                 default = nil)
  if valid_598654 != nil:
    section.add "X-Amz-Date", valid_598654
  var valid_598655 = header.getOrDefault("X-Amz-Credential")
  valid_598655 = validateParameter(valid_598655, JString, required = false,
                                 default = nil)
  if valid_598655 != nil:
    section.add "X-Amz-Credential", valid_598655
  var valid_598656 = header.getOrDefault("X-Amz-Security-Token")
  valid_598656 = validateParameter(valid_598656, JString, required = false,
                                 default = nil)
  if valid_598656 != nil:
    section.add "X-Amz-Security-Token", valid_598656
  var valid_598657 = header.getOrDefault("X-Amz-Algorithm")
  valid_598657 = validateParameter(valid_598657, JString, required = false,
                                 default = nil)
  if valid_598657 != nil:
    section.add "X-Amz-Algorithm", valid_598657
  var valid_598658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598658 = validateParameter(valid_598658, JString, required = false,
                                 default = nil)
  if valid_598658 != nil:
    section.add "X-Amz-SignedHeaders", valid_598658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598660: Call_UpdateContainerAgent_598648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Amazon ECS container agent on a specified container instance. Updating the Amazon ECS container agent does not interrupt running tasks or services on the container instance. The process for updating the agent differs depending on whether your container instance was launched with the Amazon ECS-optimized AMI or another operating system.</p> <p> <code>UpdateContainerAgent</code> requires the Amazon ECS-optimized AMI or Amazon Linux with the <code>ecs-init</code> service installed and running. For help updating the Amazon ECS container agent on other operating systems, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-update.html#manually_update_agent">Manually Updating the Amazon ECS Container Agent</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_598660.validator(path, query, header, formData, body)
  let scheme = call_598660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598660.url(scheme.get, call_598660.host, call_598660.base,
                         call_598660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598660, url, valid)

proc call*(call_598661: Call_UpdateContainerAgent_598648; body: JsonNode): Recallable =
  ## updateContainerAgent
  ## <p>Updates the Amazon ECS container agent on a specified container instance. Updating the Amazon ECS container agent does not interrupt running tasks or services on the container instance. The process for updating the agent differs depending on whether your container instance was launched with the Amazon ECS-optimized AMI or another operating system.</p> <p> <code>UpdateContainerAgent</code> requires the Amazon ECS-optimized AMI or Amazon Linux with the <code>ecs-init</code> service installed and running. For help updating the Amazon ECS container agent on other operating systems, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-update.html#manually_update_agent">Manually Updating the Amazon ECS Container Agent</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_598662 = newJObject()
  if body != nil:
    body_598662 = body
  result = call_598661.call(nil, nil, nil, nil, body_598662)

var updateContainerAgent* = Call_UpdateContainerAgent_598648(
    name: "updateContainerAgent", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateContainerAgent",
    validator: validate_UpdateContainerAgent_598649, base: "/",
    url: url_UpdateContainerAgent_598650, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContainerInstancesState_598663 = ref object of OpenApiRestCall_597389
proc url_UpdateContainerInstancesState_598665(protocol: Scheme; host: string;
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

proc validate_UpdateContainerInstancesState_598664(path: JsonNode; query: JsonNode;
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
  var valid_598666 = header.getOrDefault("X-Amz-Target")
  valid_598666 = validateParameter(valid_598666, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateContainerInstancesState"))
  if valid_598666 != nil:
    section.add "X-Amz-Target", valid_598666
  var valid_598667 = header.getOrDefault("X-Amz-Signature")
  valid_598667 = validateParameter(valid_598667, JString, required = false,
                                 default = nil)
  if valid_598667 != nil:
    section.add "X-Amz-Signature", valid_598667
  var valid_598668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598668 = validateParameter(valid_598668, JString, required = false,
                                 default = nil)
  if valid_598668 != nil:
    section.add "X-Amz-Content-Sha256", valid_598668
  var valid_598669 = header.getOrDefault("X-Amz-Date")
  valid_598669 = validateParameter(valid_598669, JString, required = false,
                                 default = nil)
  if valid_598669 != nil:
    section.add "X-Amz-Date", valid_598669
  var valid_598670 = header.getOrDefault("X-Amz-Credential")
  valid_598670 = validateParameter(valid_598670, JString, required = false,
                                 default = nil)
  if valid_598670 != nil:
    section.add "X-Amz-Credential", valid_598670
  var valid_598671 = header.getOrDefault("X-Amz-Security-Token")
  valid_598671 = validateParameter(valid_598671, JString, required = false,
                                 default = nil)
  if valid_598671 != nil:
    section.add "X-Amz-Security-Token", valid_598671
  var valid_598672 = header.getOrDefault("X-Amz-Algorithm")
  valid_598672 = validateParameter(valid_598672, JString, required = false,
                                 default = nil)
  if valid_598672 != nil:
    section.add "X-Amz-Algorithm", valid_598672
  var valid_598673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598673 = validateParameter(valid_598673, JString, required = false,
                                 default = nil)
  if valid_598673 != nil:
    section.add "X-Amz-SignedHeaders", valid_598673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598675: Call_UpdateContainerInstancesState_598663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the status of an Amazon ECS container instance.</p> <p>Once a container instance has reached an <code>ACTIVE</code> state, you can change the status of a container instance to <code>DRAINING</code> to manually remove an instance from a cluster, for example to perform system updates, update the Docker daemon, or scale down the cluster size.</p> <important> <p>A container instance cannot be changed to <code>DRAINING</code> until it has reached an <code>ACTIVE</code> status. If the instance is in any other status, an error will be received.</p> </important> <p>When you set a container instance to <code>DRAINING</code>, Amazon ECS prevents new tasks from being scheduled for placement on the container instance and replacement service tasks are started on other container instances in the cluster if the resources are available. Service tasks on the container instance that are in the <code>PENDING</code> state are stopped immediately.</p> <p>Service tasks on the container instance that are in the <code>RUNNING</code> state are stopped and replaced according to the service's deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>. You can change the deployment configuration of your service using <a>UpdateService</a>.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during task replacement. For example, <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. If the minimum is 100%, the service scheduler can't remove existing tasks until the replacement tasks are considered healthy. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during task replacement, which enables you to define the replacement batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four tasks to be drained, provided that the cluster resources required to do this are available. If the maximum is 100%, then replacement tasks can't start until the draining tasks have stopped.</p> </li> </ul> <p>Any <code>PENDING</code> or <code>RUNNING</code> tasks that do not belong to a service are not affected. You must wait for them to finish or stop them manually.</p> <p>A container instance has completed draining when it has no more <code>RUNNING</code> tasks. You can verify this using <a>ListTasks</a>.</p> <p>When a container instance has been drained, you can set a container instance to <code>ACTIVE</code> status and once it has reached that status the Amazon ECS scheduler can begin scheduling tasks on the instance again.</p>
  ## 
  let valid = call_598675.validator(path, query, header, formData, body)
  let scheme = call_598675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598675.url(scheme.get, call_598675.host, call_598675.base,
                         call_598675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598675, url, valid)

proc call*(call_598676: Call_UpdateContainerInstancesState_598663; body: JsonNode): Recallable =
  ## updateContainerInstancesState
  ## <p>Modifies the status of an Amazon ECS container instance.</p> <p>Once a container instance has reached an <code>ACTIVE</code> state, you can change the status of a container instance to <code>DRAINING</code> to manually remove an instance from a cluster, for example to perform system updates, update the Docker daemon, or scale down the cluster size.</p> <important> <p>A container instance cannot be changed to <code>DRAINING</code> until it has reached an <code>ACTIVE</code> status. If the instance is in any other status, an error will be received.</p> </important> <p>When you set a container instance to <code>DRAINING</code>, Amazon ECS prevents new tasks from being scheduled for placement on the container instance and replacement service tasks are started on other container instances in the cluster if the resources are available. Service tasks on the container instance that are in the <code>PENDING</code> state are stopped immediately.</p> <p>Service tasks on the container instance that are in the <code>RUNNING</code> state are stopped and replaced according to the service's deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>. You can change the deployment configuration of your service using <a>UpdateService</a>.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during task replacement. For example, <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. If the minimum is 100%, the service scheduler can't remove existing tasks until the replacement tasks are considered healthy. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during task replacement, which enables you to define the replacement batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four tasks to be drained, provided that the cluster resources required to do this are available. If the maximum is 100%, then replacement tasks can't start until the draining tasks have stopped.</p> </li> </ul> <p>Any <code>PENDING</code> or <code>RUNNING</code> tasks that do not belong to a service are not affected. You must wait for them to finish or stop them manually.</p> <p>A container instance has completed draining when it has no more <code>RUNNING</code> tasks. You can verify this using <a>ListTasks</a>.</p> <p>When a container instance has been drained, you can set a container instance to <code>ACTIVE</code> status and once it has reached that status the Amazon ECS scheduler can begin scheduling tasks on the instance again.</p>
  ##   body: JObject (required)
  var body_598677 = newJObject()
  if body != nil:
    body_598677 = body
  result = call_598676.call(nil, nil, nil, nil, body_598677)

var updateContainerInstancesState* = Call_UpdateContainerInstancesState_598663(
    name: "updateContainerInstancesState", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateContainerInstancesState",
    validator: validate_UpdateContainerInstancesState_598664, base: "/",
    url: url_UpdateContainerInstancesState_598665,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateService_598678 = ref object of OpenApiRestCall_597389
proc url_UpdateService_598680(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateService_598679(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598681 = header.getOrDefault("X-Amz-Target")
  valid_598681 = validateParameter(valid_598681, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateService"))
  if valid_598681 != nil:
    section.add "X-Amz-Target", valid_598681
  var valid_598682 = header.getOrDefault("X-Amz-Signature")
  valid_598682 = validateParameter(valid_598682, JString, required = false,
                                 default = nil)
  if valid_598682 != nil:
    section.add "X-Amz-Signature", valid_598682
  var valid_598683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598683 = validateParameter(valid_598683, JString, required = false,
                                 default = nil)
  if valid_598683 != nil:
    section.add "X-Amz-Content-Sha256", valid_598683
  var valid_598684 = header.getOrDefault("X-Amz-Date")
  valid_598684 = validateParameter(valid_598684, JString, required = false,
                                 default = nil)
  if valid_598684 != nil:
    section.add "X-Amz-Date", valid_598684
  var valid_598685 = header.getOrDefault("X-Amz-Credential")
  valid_598685 = validateParameter(valid_598685, JString, required = false,
                                 default = nil)
  if valid_598685 != nil:
    section.add "X-Amz-Credential", valid_598685
  var valid_598686 = header.getOrDefault("X-Amz-Security-Token")
  valid_598686 = validateParameter(valid_598686, JString, required = false,
                                 default = nil)
  if valid_598686 != nil:
    section.add "X-Amz-Security-Token", valid_598686
  var valid_598687 = header.getOrDefault("X-Amz-Algorithm")
  valid_598687 = validateParameter(valid_598687, JString, required = false,
                                 default = nil)
  if valid_598687 != nil:
    section.add "X-Amz-Algorithm", valid_598687
  var valid_598688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598688 = validateParameter(valid_598688, JString, required = false,
                                 default = nil)
  if valid_598688 != nil:
    section.add "X-Amz-SignedHeaders", valid_598688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598690: Call_UpdateService_598678; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the parameters of a service.</p> <p>For services using the rolling update (<code>ECS</code>) deployment controller, the desired count, deployment configuration, network configuration, or task definition used can be updated.</p> <p>For services using the blue/green (<code>CODE_DEPLOY</code>) deployment controller, only the desired count, deployment configuration, and health check grace period can be updated using this API. If the network configuration, platform version, or task definition need to be updated, a new AWS CodeDeploy deployment should be created. For more information, see <a href="https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html">CreateDeployment</a> in the <i>AWS CodeDeploy API Reference</i>.</p> <p>For services using an external deployment controller, you can update only the desired count and health check grace period using this API. If the launch type, load balancer, network configuration, platform version, or task definition need to be updated, you should create a new task set. For more information, see <a>CreateTaskSet</a>.</p> <p>You can add to or subtract from the number of instantiations of a task definition in a service by specifying the cluster that the service is running in and a new <code>desiredCount</code> parameter.</p> <p>If you have updated the Docker image of your application, you can create a new task definition with that image and deploy it to your service. The service scheduler uses the minimum healthy percent and maximum percent parameters (in the service's deployment configuration) to determine the deployment strategy.</p> <note> <p>If your updated Docker image uses the same tag as what is in the existing task definition for your service (for example, <code>my_image:latest</code>), you do not need to create a new revision of your task definition. You can update the service using the <code>forceNewDeployment</code> option. The new tasks launched by the deployment pull the current image/tag combination from your repository when they start.</p> </note> <p>You can also update the deployment configuration of a service. When a deployment is triggered by updating the task definition of a service, the service scheduler uses the deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>, to determine the deployment strategy.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during a deployment. For example, if <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during a deployment, which enables you to define the deployment batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available).</p> </li> </ul> <p>When <a>UpdateService</a> stops a task during a deployment, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> and a 30-second timeout, after which <code>SIGKILL</code> is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> is sent.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster with the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy):</p> <ul> <li> <p>Sort the valid container instances by the fewest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul> <p>When the service scheduler stops running tasks, it attempts to maintain balance across the Availability Zones in your cluster using the following logic: </p> <ul> <li> <p>Sort the container instances by the largest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have two, container instances in either zone B or C are considered optimal for termination.</p> </li> <li> <p>Stop the task on a container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the largest number of running tasks for this service.</p> </li> </ul>
  ## 
  let valid = call_598690.validator(path, query, header, formData, body)
  let scheme = call_598690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598690.url(scheme.get, call_598690.host, call_598690.base,
                         call_598690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598690, url, valid)

proc call*(call_598691: Call_UpdateService_598678; body: JsonNode): Recallable =
  ## updateService
  ## <p>Modifies the parameters of a service.</p> <p>For services using the rolling update (<code>ECS</code>) deployment controller, the desired count, deployment configuration, network configuration, or task definition used can be updated.</p> <p>For services using the blue/green (<code>CODE_DEPLOY</code>) deployment controller, only the desired count, deployment configuration, and health check grace period can be updated using this API. If the network configuration, platform version, or task definition need to be updated, a new AWS CodeDeploy deployment should be created. For more information, see <a href="https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html">CreateDeployment</a> in the <i>AWS CodeDeploy API Reference</i>.</p> <p>For services using an external deployment controller, you can update only the desired count and health check grace period using this API. If the launch type, load balancer, network configuration, platform version, or task definition need to be updated, you should create a new task set. For more information, see <a>CreateTaskSet</a>.</p> <p>You can add to or subtract from the number of instantiations of a task definition in a service by specifying the cluster that the service is running in and a new <code>desiredCount</code> parameter.</p> <p>If you have updated the Docker image of your application, you can create a new task definition with that image and deploy it to your service. The service scheduler uses the minimum healthy percent and maximum percent parameters (in the service's deployment configuration) to determine the deployment strategy.</p> <note> <p>If your updated Docker image uses the same tag as what is in the existing task definition for your service (for example, <code>my_image:latest</code>), you do not need to create a new revision of your task definition. You can update the service using the <code>forceNewDeployment</code> option. The new tasks launched by the deployment pull the current image/tag combination from your repository when they start.</p> </note> <p>You can also update the deployment configuration of a service. When a deployment is triggered by updating the task definition of a service, the service scheduler uses the deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>, to determine the deployment strategy.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during a deployment. For example, if <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during a deployment, which enables you to define the deployment batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available).</p> </li> </ul> <p>When <a>UpdateService</a> stops a task during a deployment, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> and a 30-second timeout, after which <code>SIGKILL</code> is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> is sent.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster with the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy):</p> <ul> <li> <p>Sort the valid container instances by the fewest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul> <p>When the service scheduler stops running tasks, it attempts to maintain balance across the Availability Zones in your cluster using the following logic: </p> <ul> <li> <p>Sort the container instances by the largest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have two, container instances in either zone B or C are considered optimal for termination.</p> </li> <li> <p>Stop the task on a container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the largest number of running tasks for this service.</p> </li> </ul>
  ##   body: JObject (required)
  var body_598692 = newJObject()
  if body != nil:
    body_598692 = body
  result = call_598691.call(nil, nil, nil, nil, body_598692)

var updateService* = Call_UpdateService_598678(name: "updateService",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateService",
    validator: validate_UpdateService_598679, base: "/", url: url_UpdateService_598680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServicePrimaryTaskSet_598693 = ref object of OpenApiRestCall_597389
proc url_UpdateServicePrimaryTaskSet_598695(protocol: Scheme; host: string;
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

proc validate_UpdateServicePrimaryTaskSet_598694(path: JsonNode; query: JsonNode;
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
  var valid_598696 = header.getOrDefault("X-Amz-Target")
  valid_598696 = validateParameter(valid_598696, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateServicePrimaryTaskSet"))
  if valid_598696 != nil:
    section.add "X-Amz-Target", valid_598696
  var valid_598697 = header.getOrDefault("X-Amz-Signature")
  valid_598697 = validateParameter(valid_598697, JString, required = false,
                                 default = nil)
  if valid_598697 != nil:
    section.add "X-Amz-Signature", valid_598697
  var valid_598698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598698 = validateParameter(valid_598698, JString, required = false,
                                 default = nil)
  if valid_598698 != nil:
    section.add "X-Amz-Content-Sha256", valid_598698
  var valid_598699 = header.getOrDefault("X-Amz-Date")
  valid_598699 = validateParameter(valid_598699, JString, required = false,
                                 default = nil)
  if valid_598699 != nil:
    section.add "X-Amz-Date", valid_598699
  var valid_598700 = header.getOrDefault("X-Amz-Credential")
  valid_598700 = validateParameter(valid_598700, JString, required = false,
                                 default = nil)
  if valid_598700 != nil:
    section.add "X-Amz-Credential", valid_598700
  var valid_598701 = header.getOrDefault("X-Amz-Security-Token")
  valid_598701 = validateParameter(valid_598701, JString, required = false,
                                 default = nil)
  if valid_598701 != nil:
    section.add "X-Amz-Security-Token", valid_598701
  var valid_598702 = header.getOrDefault("X-Amz-Algorithm")
  valid_598702 = validateParameter(valid_598702, JString, required = false,
                                 default = nil)
  if valid_598702 != nil:
    section.add "X-Amz-Algorithm", valid_598702
  var valid_598703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598703 = validateParameter(valid_598703, JString, required = false,
                                 default = nil)
  if valid_598703 != nil:
    section.add "X-Amz-SignedHeaders", valid_598703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598705: Call_UpdateServicePrimaryTaskSet_598693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies which task set in a service is the primary task set. Any parameters that are updated on the primary task set in a service will transition to the service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_598705.validator(path, query, header, formData, body)
  let scheme = call_598705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598705.url(scheme.get, call_598705.host, call_598705.base,
                         call_598705.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598705, url, valid)

proc call*(call_598706: Call_UpdateServicePrimaryTaskSet_598693; body: JsonNode): Recallable =
  ## updateServicePrimaryTaskSet
  ## Modifies which task set in a service is the primary task set. Any parameters that are updated on the primary task set in a service will transition to the service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_598707 = newJObject()
  if body != nil:
    body_598707 = body
  result = call_598706.call(nil, nil, nil, nil, body_598707)

var updateServicePrimaryTaskSet* = Call_UpdateServicePrimaryTaskSet_598693(
    name: "updateServicePrimaryTaskSet", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateServicePrimaryTaskSet",
    validator: validate_UpdateServicePrimaryTaskSet_598694, base: "/",
    url: url_UpdateServicePrimaryTaskSet_598695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTaskSet_598708 = ref object of OpenApiRestCall_597389
proc url_UpdateTaskSet_598710(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTaskSet_598709(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598711 = header.getOrDefault("X-Amz-Target")
  valid_598711 = validateParameter(valid_598711, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateTaskSet"))
  if valid_598711 != nil:
    section.add "X-Amz-Target", valid_598711
  var valid_598712 = header.getOrDefault("X-Amz-Signature")
  valid_598712 = validateParameter(valid_598712, JString, required = false,
                                 default = nil)
  if valid_598712 != nil:
    section.add "X-Amz-Signature", valid_598712
  var valid_598713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598713 = validateParameter(valid_598713, JString, required = false,
                                 default = nil)
  if valid_598713 != nil:
    section.add "X-Amz-Content-Sha256", valid_598713
  var valid_598714 = header.getOrDefault("X-Amz-Date")
  valid_598714 = validateParameter(valid_598714, JString, required = false,
                                 default = nil)
  if valid_598714 != nil:
    section.add "X-Amz-Date", valid_598714
  var valid_598715 = header.getOrDefault("X-Amz-Credential")
  valid_598715 = validateParameter(valid_598715, JString, required = false,
                                 default = nil)
  if valid_598715 != nil:
    section.add "X-Amz-Credential", valid_598715
  var valid_598716 = header.getOrDefault("X-Amz-Security-Token")
  valid_598716 = validateParameter(valid_598716, JString, required = false,
                                 default = nil)
  if valid_598716 != nil:
    section.add "X-Amz-Security-Token", valid_598716
  var valid_598717 = header.getOrDefault("X-Amz-Algorithm")
  valid_598717 = validateParameter(valid_598717, JString, required = false,
                                 default = nil)
  if valid_598717 != nil:
    section.add "X-Amz-Algorithm", valid_598717
  var valid_598718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598718 = validateParameter(valid_598718, JString, required = false,
                                 default = nil)
  if valid_598718 != nil:
    section.add "X-Amz-SignedHeaders", valid_598718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598720: Call_UpdateTaskSet_598708; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a task set. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_598720.validator(path, query, header, formData, body)
  let scheme = call_598720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598720.url(scheme.get, call_598720.host, call_598720.base,
                         call_598720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598720, url, valid)

proc call*(call_598721: Call_UpdateTaskSet_598708; body: JsonNode): Recallable =
  ## updateTaskSet
  ## Modifies a task set. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_598722 = newJObject()
  if body != nil:
    body_598722 = body
  result = call_598721.call(nil, nil, nil, nil, body_598722)

var updateTaskSet* = Call_UpdateTaskSet_598708(name: "updateTaskSet",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateTaskSet",
    validator: validate_UpdateTaskSet_598709, base: "/", url: url_UpdateTaskSet_598710,
    schemes: {Scheme.Https, Scheme.Http})
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
