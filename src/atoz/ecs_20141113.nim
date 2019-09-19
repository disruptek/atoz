
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateCluster_600768 = ref object of OpenApiRestCall_600426
proc url_CreateCluster_600770(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateCluster_600769(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new Amazon ECS cluster. By default, your account receives a <code>default</code> cluster when you launch your first container instance. However, you can create your own cluster with a unique name with the <code>CreateCluster</code> action.</p> <note> <p>When you call the <a>CreateCluster</a> API operation, Amazon ECS attempts to create the service-linked role for your account so that required resources in other AWS services can be managed on your behalf. However, if the IAM user that makes the call does not have permissions to create the service-linked role, it is not created. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html">Using Service-Linked Roles for Amazon ECS</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
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
  ##   X-Amz-Target: JString (required)
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateCluster"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_CreateCluster_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new Amazon ECS cluster. By default, your account receives a <code>default</code> cluster when you launch your first container instance. However, you can create your own cluster with a unique name with the <code>CreateCluster</code> action.</p> <note> <p>When you call the <a>CreateCluster</a> API operation, Amazon ECS attempts to create the service-linked role for your account so that required resources in other AWS services can be managed on your behalf. However, if the IAM user that makes the call does not have permissions to create the service-linked role, it is not created. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html">Using Service-Linked Roles for Amazon ECS</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_CreateCluster_600768; body: JsonNode): Recallable =
  ## createCluster
  ## <p>Creates a new Amazon ECS cluster. By default, your account receives a <code>default</code> cluster when you launch your first container instance. However, you can create your own cluster with a unique name with the <code>CreateCluster</code> action.</p> <note> <p>When you call the <a>CreateCluster</a> API operation, Amazon ECS attempts to create the service-linked role for your account so that required resources in other AWS services can be managed on your behalf. However, if the IAM user that makes the call does not have permissions to create the service-linked role, it is not created. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using-service-linked-roles.html">Using Service-Linked Roles for Amazon ECS</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var createCluster* = Call_CreateCluster_600768(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateCluster",
    validator: validate_CreateCluster_600769, base: "/", url: url_CreateCluster_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateService_601037 = ref object of OpenApiRestCall_600426
proc url_CreateService_601039(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateService_601038(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateService"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_CreateService_601037; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs and maintains a desired number of tasks from a specified task definition. If the number of tasks running in a service drops below the <code>desiredCount</code>, Amazon ECS runs another copy of the task in the specified cluster. To update an existing service, see <a>UpdateService</a>.</p> <p>In addition to maintaining the desired count of tasks in your service, you can optionally run your service behind one or more load balancers. The load balancers distribute traffic across the tasks that are associated with the service. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html">Service Load Balancing</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and the container instance that they're hosted on is reported as healthy by the load balancer.</p> <p>There are two service scheduler strategies available:</p> <ul> <li> <p> <code>REPLICA</code> - The replica scheduling strategy places and maintains the desired number of tasks across your cluster. By default, the service scheduler spreads tasks across Availability Zones. You can use task placement strategies and constraints to customize task placement decisions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> <li> <p> <code>DAEMON</code> - The daemon scheduling strategy deploys exactly one task on each active container instance that meets all of the task placement constraints that you specify in your cluster. When using this strategy, you don't need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> </ul> <p>You can optionally specify a deployment configuration for your service. The deployment is triggered by changing properties, such as the task definition or the desired count of a service, with an <a>UpdateService</a> operation. The default value for a replica service for <code>minimumHealthyPercent</code> is 100%. The default value for a daemon service for <code>minimumHealthyPercent</code> is 0%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the minimum healthy percent represents a lower limit on the number of tasks in a service that must remain in the <code>RUNNING</code> state during a deployment, as a percentage of the desired number of tasks (rounded up to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to deploy without using additional cluster capacity. For example, if your service has a desired number of four tasks and a minimum healthy percent of 50%, the scheduler might stop two existing tasks to free up cluster capacity before starting two new tasks. Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and they're reported as healthy by the load balancer. The default value for minimum healthy percent is 100%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the <b>maximum percent</b> parameter represents an upper limit on the number of tasks in a service that are allowed in the <code>RUNNING</code> or <code>PENDING</code> state during a deployment, as a percentage of the desired number of tasks (rounded down to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to define the deployment batch size. For example, if your service has a desired number of four tasks and a maximum percent value of 200%, the scheduler may start four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available). The default value for maximum percent is 200%.</p> <p>If a service is using either the <code>CODE_DEPLOY</code> or <code>EXTERNAL</code> deployment controller types and tasks that use the EC2 launch type, the <b>minimum healthy percent</b> and <b>maximum percent</b> values are used only to define the lower and upper limit on the number of the tasks in the service that remain in the <code>RUNNING</code> state while the container instances are in the <code>DRAINING</code> state. If the tasks in the service use the Fargate launch type, the minimum healthy percent and maximum percent values aren't used, although they're currently visible when describing your service.</p> <p>When creating a service that uses the <code>EXTERNAL</code> deployment controller, you can specify only parameters that aren't controlled at the task set level. The only required parameter is the service name. You control your services using the <a>CreateTaskSet</a> operation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster using the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy) with the <code>placementStrategy</code> parameter):</p> <ul> <li> <p>Sort the valid container instances, giving priority to instances that have the fewest number of running tasks for this service in their respective Availability Zone. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul>
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_CreateService_601037; body: JsonNode): Recallable =
  ## createService
  ## <p>Runs and maintains a desired number of tasks from a specified task definition. If the number of tasks running in a service drops below the <code>desiredCount</code>, Amazon ECS runs another copy of the task in the specified cluster. To update an existing service, see <a>UpdateService</a>.</p> <p>In addition to maintaining the desired count of tasks in your service, you can optionally run your service behind one or more load balancers. The load balancers distribute traffic across the tasks that are associated with the service. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html">Service Load Balancing</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and the container instance that they're hosted on is reported as healthy by the load balancer.</p> <p>There are two service scheduler strategies available:</p> <ul> <li> <p> <code>REPLICA</code> - The replica scheduling strategy places and maintains the desired number of tasks across your cluster. By default, the service scheduler spreads tasks across Availability Zones. You can use task placement strategies and constraints to customize task placement decisions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> <li> <p> <code>DAEMON</code> - The daemon scheduling strategy deploys exactly one task on each active container instance that meets all of the task placement constraints that you specify in your cluster. When using this strategy, you don't need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html">Service Scheduler Concepts</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </li> </ul> <p>You can optionally specify a deployment configuration for your service. The deployment is triggered by changing properties, such as the task definition or the desired count of a service, with an <a>UpdateService</a> operation. The default value for a replica service for <code>minimumHealthyPercent</code> is 100%. The default value for a daemon service for <code>minimumHealthyPercent</code> is 0%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the minimum healthy percent represents a lower limit on the number of tasks in a service that must remain in the <code>RUNNING</code> state during a deployment, as a percentage of the desired number of tasks (rounded up to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to deploy without using additional cluster capacity. For example, if your service has a desired number of four tasks and a minimum healthy percent of 50%, the scheduler might stop two existing tasks to free up cluster capacity before starting two new tasks. Tasks for services that <i>do not</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state. Tasks for services that <i>do</i> use a load balancer are considered healthy if they're in the <code>RUNNING</code> state and they're reported as healthy by the load balancer. The default value for minimum healthy percent is 100%.</p> <p>If a service is using the <code>ECS</code> deployment controller, the <b>maximum percent</b> parameter represents an upper limit on the number of tasks in a service that are allowed in the <code>RUNNING</code> or <code>PENDING</code> state during a deployment, as a percentage of the desired number of tasks (rounded down to the nearest integer), and while any container instances are in the <code>DRAINING</code> state if the service contains tasks using the EC2 launch type. This parameter enables you to define the deployment batch size. For example, if your service has a desired number of four tasks and a maximum percent value of 200%, the scheduler may start four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available). The default value for maximum percent is 200%.</p> <p>If a service is using either the <code>CODE_DEPLOY</code> or <code>EXTERNAL</code> deployment controller types and tasks that use the EC2 launch type, the <b>minimum healthy percent</b> and <b>maximum percent</b> values are used only to define the lower and upper limit on the number of the tasks in the service that remain in the <code>RUNNING</code> state while the container instances are in the <code>DRAINING</code> state. If the tasks in the service use the Fargate launch type, the minimum healthy percent and maximum percent values aren't used, although they're currently visible when describing your service.</p> <p>When creating a service that uses the <code>EXTERNAL</code> deployment controller, you can specify only parameters that aren't controlled at the task set level. The only required parameter is the service name. You control your services using the <a>CreateTaskSet</a> operation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster using the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy) with the <code>placementStrategy</code> parameter):</p> <ul> <li> <p>Sort the valid container instances, giving priority to instances that have the fewest number of running tasks for this service in their respective Availability Zone. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul>
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var createService* = Call_CreateService_601037(name: "createService",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateService",
    validator: validate_CreateService_601038, base: "/", url: url_CreateService_601039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTaskSet_601052 = ref object of OpenApiRestCall_600426
proc url_CreateTaskSet_601054(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateTaskSet_601053(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.CreateTaskSet"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_CreateTaskSet_601052; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a task set in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_CreateTaskSet_601052; body: JsonNode): Recallable =
  ## createTaskSet
  ## Create a task set in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var createTaskSet* = Call_CreateTaskSet_601052(name: "createTaskSet",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.CreateTaskSet",
    validator: validate_CreateTaskSet_601053, base: "/", url: url_CreateTaskSet_601054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAccountSetting_601067 = ref object of OpenApiRestCall_600426
proc url_DeleteAccountSetting_601069(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAccountSetting_601068(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteAccountSetting"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_DeleteAccountSetting_601067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables an account setting for a specified IAM user, IAM role, or the root user for an account.
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_DeleteAccountSetting_601067; body: JsonNode): Recallable =
  ## deleteAccountSetting
  ## Disables an account setting for a specified IAM user, IAM role, or the root user for an account.
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var deleteAccountSetting* = Call_DeleteAccountSetting_601067(
    name: "deleteAccountSetting", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteAccountSetting",
    validator: validate_DeleteAccountSetting_601068, base: "/",
    url: url_DeleteAccountSetting_601069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAttributes_601082 = ref object of OpenApiRestCall_600426
proc url_DeleteAttributes_601084(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteAttributes_601083(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteAttributes"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_DeleteAttributes_601082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more custom attributes from an Amazon ECS resource.
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_DeleteAttributes_601082; body: JsonNode): Recallable =
  ## deleteAttributes
  ## Deletes one or more custom attributes from an Amazon ECS resource.
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var deleteAttributes* = Call_DeleteAttributes_601082(name: "deleteAttributes",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteAttributes",
    validator: validate_DeleteAttributes_601083, base: "/",
    url: url_DeleteAttributes_601084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_601097 = ref object of OpenApiRestCall_600426
proc url_DeleteCluster_601099(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteCluster_601098(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteCluster"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_DeleteCluster_601097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified cluster. You must deregister all container instances from this cluster before you may delete it. You can list the container instances in a cluster with <a>ListContainerInstances</a> and deregister them with <a>DeregisterContainerInstance</a>.
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_DeleteCluster_601097; body: JsonNode): Recallable =
  ## deleteCluster
  ## Deletes the specified cluster. You must deregister all container instances from this cluster before you may delete it. You can list the container instances in a cluster with <a>ListContainerInstances</a> and deregister them with <a>DeregisterContainerInstance</a>.
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var deleteCluster* = Call_DeleteCluster_601097(name: "deleteCluster",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteCluster",
    validator: validate_DeleteCluster_601098, base: "/", url: url_DeleteCluster_601099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteService_601112 = ref object of OpenApiRestCall_600426
proc url_DeleteService_601114(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteService_601113(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601117 = header.getOrDefault("X-Amz-Target")
  valid_601117 = validateParameter(valid_601117, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteService"))
  if valid_601117 != nil:
    section.add "X-Amz-Target", valid_601117
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

proc call*(call_601124: Call_DeleteService_601112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specified service within a cluster. You can delete a service if you have no running tasks in it and the desired task count is zero. If the service is actively maintaining tasks, you cannot delete it, and you must update the service to a desired task count of zero. For more information, see <a>UpdateService</a>.</p> <note> <p>When you delete a service, if there are still running tasks that require cleanup, the service status moves from <code>ACTIVE</code> to <code>DRAINING</code>, and the service is no longer visible in the console or in the <a>ListServices</a> API operation. After all tasks have transitioned to either <code>STOPPING</code> or <code>STOPPED</code> status, the service status moves from <code>DRAINING</code> to <code>INACTIVE</code>. Services in the <code>DRAINING</code> or <code>INACTIVE</code> status can still be viewed with the <a>DescribeServices</a> API operation. However, in the future, <code>INACTIVE</code> services may be cleaned up and purged from Amazon ECS record keeping, and <a>DescribeServices</a> calls on those services return a <code>ServiceNotFoundException</code> error.</p> </note> <important> <p>If you attempt to create a new service with the same name as an existing service in either <code>ACTIVE</code> or <code>DRAINING</code> status, you receive an error.</p> </important>
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_DeleteService_601112; body: JsonNode): Recallable =
  ## deleteService
  ## <p>Deletes a specified service within a cluster. You can delete a service if you have no running tasks in it and the desired task count is zero. If the service is actively maintaining tasks, you cannot delete it, and you must update the service to a desired task count of zero. For more information, see <a>UpdateService</a>.</p> <note> <p>When you delete a service, if there are still running tasks that require cleanup, the service status moves from <code>ACTIVE</code> to <code>DRAINING</code>, and the service is no longer visible in the console or in the <a>ListServices</a> API operation. After all tasks have transitioned to either <code>STOPPING</code> or <code>STOPPED</code> status, the service status moves from <code>DRAINING</code> to <code>INACTIVE</code>. Services in the <code>DRAINING</code> or <code>INACTIVE</code> status can still be viewed with the <a>DescribeServices</a> API operation. However, in the future, <code>INACTIVE</code> services may be cleaned up and purged from Amazon ECS record keeping, and <a>DescribeServices</a> calls on those services return a <code>ServiceNotFoundException</code> error.</p> </note> <important> <p>If you attempt to create a new service with the same name as an existing service in either <code>ACTIVE</code> or <code>DRAINING</code> status, you receive an error.</p> </important>
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var deleteService* = Call_DeleteService_601112(name: "deleteService",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteService",
    validator: validate_DeleteService_601113, base: "/", url: url_DeleteService_601114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTaskSet_601127 = ref object of OpenApiRestCall_600426
proc url_DeleteTaskSet_601129(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteTaskSet_601128(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601132 = header.getOrDefault("X-Amz-Target")
  valid_601132 = validateParameter(valid_601132, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeleteTaskSet"))
  if valid_601132 != nil:
    section.add "X-Amz-Target", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_DeleteTaskSet_601127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified task set within a service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_DeleteTaskSet_601127; body: JsonNode): Recallable =
  ## deleteTaskSet
  ## Deletes a specified task set within a service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var deleteTaskSet* = Call_DeleteTaskSet_601127(name: "deleteTaskSet",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeleteTaskSet",
    validator: validate_DeleteTaskSet_601128, base: "/", url: url_DeleteTaskSet_601129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterContainerInstance_601142 = ref object of OpenApiRestCall_600426
proc url_DeregisterContainerInstance_601144(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterContainerInstance_601143(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601145 = header.getOrDefault("X-Amz-Date")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Date", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Security-Token")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Security-Token", valid_601146
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601147 = header.getOrDefault("X-Amz-Target")
  valid_601147 = validateParameter(valid_601147, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeregisterContainerInstance"))
  if valid_601147 != nil:
    section.add "X-Amz-Target", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_DeregisterContainerInstance_601142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deregisters an Amazon ECS container instance from the specified cluster. This instance is no longer available to run tasks.</p> <p>If you intend to use the container instance for some other purpose after deregistration, you should stop all of the tasks running on the container instance before deregistration. That prevents any orphaned tasks from consuming resources.</p> <p>Deregistering a container instance removes the instance from a cluster, but it does not terminate the EC2 instance. If you are finished using the instance, be sure to terminate it in the Amazon EC2 console to stop billing.</p> <note> <p>If you terminate a running container instance, Amazon ECS automatically deregisters the instance from your cluster (stopped container instances or instances with disconnected agents are not automatically deregistered when terminated).</p> </note>
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_DeregisterContainerInstance_601142; body: JsonNode): Recallable =
  ## deregisterContainerInstance
  ## <p>Deregisters an Amazon ECS container instance from the specified cluster. This instance is no longer available to run tasks.</p> <p>If you intend to use the container instance for some other purpose after deregistration, you should stop all of the tasks running on the container instance before deregistration. That prevents any orphaned tasks from consuming resources.</p> <p>Deregistering a container instance removes the instance from a cluster, but it does not terminate the EC2 instance. If you are finished using the instance, be sure to terminate it in the Amazon EC2 console to stop billing.</p> <note> <p>If you terminate a running container instance, Amazon ECS automatically deregisters the instance from your cluster (stopped container instances or instances with disconnected agents are not automatically deregistered when terminated).</p> </note>
  ##   body: JObject (required)
  var body_601156 = newJObject()
  if body != nil:
    body_601156 = body
  result = call_601155.call(nil, nil, nil, nil, body_601156)

var deregisterContainerInstance* = Call_DeregisterContainerInstance_601142(
    name: "deregisterContainerInstance", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeregisterContainerInstance",
    validator: validate_DeregisterContainerInstance_601143, base: "/",
    url: url_DeregisterContainerInstance_601144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskDefinition_601157 = ref object of OpenApiRestCall_600426
proc url_DeregisterTaskDefinition_601159(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterTaskDefinition_601158(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601160 = header.getOrDefault("X-Amz-Date")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Date", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Security-Token")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Security-Token", valid_601161
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601162 = header.getOrDefault("X-Amz-Target")
  valid_601162 = validateParameter(valid_601162, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DeregisterTaskDefinition"))
  if valid_601162 != nil:
    section.add "X-Amz-Target", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Content-Sha256", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Algorithm")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Algorithm", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Signature")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Signature", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-SignedHeaders", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Credential")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Credential", valid_601167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601169: Call_DeregisterTaskDefinition_601157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deregisters the specified task definition by family and revision. Upon deregistration, the task definition is marked as <code>INACTIVE</code>. Existing tasks and services that reference an <code>INACTIVE</code> task definition continue to run without disruption. Existing services that reference an <code>INACTIVE</code> task definition can still scale up or down by modifying the service's desired count.</p> <p>You cannot use an <code>INACTIVE</code> task definition to run new tasks or create new services, and you cannot update an existing service to reference an <code>INACTIVE</code> task definition. However, there may be up to a 10-minute window following deregistration where these restrictions have not yet taken effect.</p> <note> <p>At this time, <code>INACTIVE</code> task definitions remain discoverable in your account indefinitely. However, this behavior is subject to change in the future, so you should not rely on <code>INACTIVE</code> task definitions persisting beyond the lifecycle of any associated tasks and services.</p> </note>
  ## 
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"))
  result = hook(call_601169, url, valid)

proc call*(call_601170: Call_DeregisterTaskDefinition_601157; body: JsonNode): Recallable =
  ## deregisterTaskDefinition
  ## <p>Deregisters the specified task definition by family and revision. Upon deregistration, the task definition is marked as <code>INACTIVE</code>. Existing tasks and services that reference an <code>INACTIVE</code> task definition continue to run without disruption. Existing services that reference an <code>INACTIVE</code> task definition can still scale up or down by modifying the service's desired count.</p> <p>You cannot use an <code>INACTIVE</code> task definition to run new tasks or create new services, and you cannot update an existing service to reference an <code>INACTIVE</code> task definition. However, there may be up to a 10-minute window following deregistration where these restrictions have not yet taken effect.</p> <note> <p>At this time, <code>INACTIVE</code> task definitions remain discoverable in your account indefinitely. However, this behavior is subject to change in the future, so you should not rely on <code>INACTIVE</code> task definitions persisting beyond the lifecycle of any associated tasks and services.</p> </note>
  ##   body: JObject (required)
  var body_601171 = newJObject()
  if body != nil:
    body_601171 = body
  result = call_601170.call(nil, nil, nil, nil, body_601171)

var deregisterTaskDefinition* = Call_DeregisterTaskDefinition_601157(
    name: "deregisterTaskDefinition", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DeregisterTaskDefinition",
    validator: validate_DeregisterTaskDefinition_601158, base: "/",
    url: url_DeregisterTaskDefinition_601159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeClusters_601172 = ref object of OpenApiRestCall_600426
proc url_DescribeClusters_601174(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeClusters_601173(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601175 = header.getOrDefault("X-Amz-Date")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Date", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Security-Token")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Security-Token", valid_601176
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601177 = header.getOrDefault("X-Amz-Target")
  valid_601177 = validateParameter(valid_601177, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeClusters"))
  if valid_601177 != nil:
    section.add "X-Amz-Target", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601184: Call_DescribeClusters_601172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more of your clusters.
  ## 
  let valid = call_601184.validator(path, query, header, formData, body)
  let scheme = call_601184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601184.url(scheme.get, call_601184.host, call_601184.base,
                         call_601184.route, valid.getOrDefault("path"))
  result = hook(call_601184, url, valid)

proc call*(call_601185: Call_DescribeClusters_601172; body: JsonNode): Recallable =
  ## describeClusters
  ## Describes one or more of your clusters.
  ##   body: JObject (required)
  var body_601186 = newJObject()
  if body != nil:
    body_601186 = body
  result = call_601185.call(nil, nil, nil, nil, body_601186)

var describeClusters* = Call_DescribeClusters_601172(name: "describeClusters",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeClusters",
    validator: validate_DescribeClusters_601173, base: "/",
    url: url_DescribeClusters_601174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeContainerInstances_601187 = ref object of OpenApiRestCall_600426
proc url_DescribeContainerInstances_601189(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeContainerInstances_601188(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601190 = header.getOrDefault("X-Amz-Date")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Date", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Security-Token")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Security-Token", valid_601191
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601192 = header.getOrDefault("X-Amz-Target")
  valid_601192 = validateParameter(valid_601192, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeContainerInstances"))
  if valid_601192 != nil:
    section.add "X-Amz-Target", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Content-Sha256", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Algorithm")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Algorithm", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Signature")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Signature", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-SignedHeaders", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Credential")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Credential", valid_601197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601199: Call_DescribeContainerInstances_601187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes Amazon Elastic Container Service container instances. Returns metadata about registered and remaining resources on each container instance requested.
  ## 
  let valid = call_601199.validator(path, query, header, formData, body)
  let scheme = call_601199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601199.url(scheme.get, call_601199.host, call_601199.base,
                         call_601199.route, valid.getOrDefault("path"))
  result = hook(call_601199, url, valid)

proc call*(call_601200: Call_DescribeContainerInstances_601187; body: JsonNode): Recallable =
  ## describeContainerInstances
  ## Describes Amazon Elastic Container Service container instances. Returns metadata about registered and remaining resources on each container instance requested.
  ##   body: JObject (required)
  var body_601201 = newJObject()
  if body != nil:
    body_601201 = body
  result = call_601200.call(nil, nil, nil, nil, body_601201)

var describeContainerInstances* = Call_DescribeContainerInstances_601187(
    name: "describeContainerInstances", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeContainerInstances",
    validator: validate_DescribeContainerInstances_601188, base: "/",
    url: url_DescribeContainerInstances_601189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeServices_601202 = ref object of OpenApiRestCall_600426
proc url_DescribeServices_601204(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeServices_601203(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601205 = header.getOrDefault("X-Amz-Date")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Date", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Security-Token")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Security-Token", valid_601206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601207 = header.getOrDefault("X-Amz-Target")
  valid_601207 = validateParameter(valid_601207, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeServices"))
  if valid_601207 != nil:
    section.add "X-Amz-Target", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Content-Sha256", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Algorithm")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Algorithm", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Signature")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Signature", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-SignedHeaders", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Credential")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Credential", valid_601212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601214: Call_DescribeServices_601202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the specified services running in your cluster.
  ## 
  let valid = call_601214.validator(path, query, header, formData, body)
  let scheme = call_601214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601214.url(scheme.get, call_601214.host, call_601214.base,
                         call_601214.route, valid.getOrDefault("path"))
  result = hook(call_601214, url, valid)

proc call*(call_601215: Call_DescribeServices_601202; body: JsonNode): Recallable =
  ## describeServices
  ## Describes the specified services running in your cluster.
  ##   body: JObject (required)
  var body_601216 = newJObject()
  if body != nil:
    body_601216 = body
  result = call_601215.call(nil, nil, nil, nil, body_601216)

var describeServices* = Call_DescribeServices_601202(name: "describeServices",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeServices",
    validator: validate_DescribeServices_601203, base: "/",
    url: url_DescribeServices_601204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTaskDefinition_601217 = ref object of OpenApiRestCall_600426
proc url_DescribeTaskDefinition_601219(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeTaskDefinition_601218(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601220 = header.getOrDefault("X-Amz-Date")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Date", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Security-Token")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Security-Token", valid_601221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601222 = header.getOrDefault("X-Amz-Target")
  valid_601222 = validateParameter(valid_601222, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeTaskDefinition"))
  if valid_601222 != nil:
    section.add "X-Amz-Target", valid_601222
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

proc call*(call_601229: Call_DescribeTaskDefinition_601217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a task definition. You can specify a <code>family</code> and <code>revision</code> to find information about a specific task definition, or you can simply specify the family to find the latest <code>ACTIVE</code> revision in that family.</p> <note> <p>You can only describe <code>INACTIVE</code> task definitions while an active task or service references them.</p> </note>
  ## 
  let valid = call_601229.validator(path, query, header, formData, body)
  let scheme = call_601229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601229.url(scheme.get, call_601229.host, call_601229.base,
                         call_601229.route, valid.getOrDefault("path"))
  result = hook(call_601229, url, valid)

proc call*(call_601230: Call_DescribeTaskDefinition_601217; body: JsonNode): Recallable =
  ## describeTaskDefinition
  ## <p>Describes a task definition. You can specify a <code>family</code> and <code>revision</code> to find information about a specific task definition, or you can simply specify the family to find the latest <code>ACTIVE</code> revision in that family.</p> <note> <p>You can only describe <code>INACTIVE</code> task definitions while an active task or service references them.</p> </note>
  ##   body: JObject (required)
  var body_601231 = newJObject()
  if body != nil:
    body_601231 = body
  result = call_601230.call(nil, nil, nil, nil, body_601231)

var describeTaskDefinition* = Call_DescribeTaskDefinition_601217(
    name: "describeTaskDefinition", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTaskDefinition",
    validator: validate_DescribeTaskDefinition_601218, base: "/",
    url: url_DescribeTaskDefinition_601219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTaskSets_601232 = ref object of OpenApiRestCall_600426
proc url_DescribeTaskSets_601234(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeTaskSets_601233(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601237 = header.getOrDefault("X-Amz-Target")
  valid_601237 = validateParameter(valid_601237, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeTaskSets"))
  if valid_601237 != nil:
    section.add "X-Amz-Target", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Content-Sha256", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Algorithm")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Algorithm", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Signature")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Signature", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-SignedHeaders", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Credential")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Credential", valid_601242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601244: Call_DescribeTaskSets_601232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the task sets in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_601244.validator(path, query, header, formData, body)
  let scheme = call_601244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601244.url(scheme.get, call_601244.host, call_601244.base,
                         call_601244.route, valid.getOrDefault("path"))
  result = hook(call_601244, url, valid)

proc call*(call_601245: Call_DescribeTaskSets_601232; body: JsonNode): Recallable =
  ## describeTaskSets
  ## Describes the task sets in the specified cluster and service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_601246 = newJObject()
  if body != nil:
    body_601246 = body
  result = call_601245.call(nil, nil, nil, nil, body_601246)

var describeTaskSets* = Call_DescribeTaskSets_601232(name: "describeTaskSets",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTaskSets",
    validator: validate_DescribeTaskSets_601233, base: "/",
    url: url_DescribeTaskSets_601234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTasks_601247 = ref object of OpenApiRestCall_600426
proc url_DescribeTasks_601249(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeTasks_601248(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601250 = header.getOrDefault("X-Amz-Date")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Date", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Security-Token")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Security-Token", valid_601251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601252 = header.getOrDefault("X-Amz-Target")
  valid_601252 = validateParameter(valid_601252, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DescribeTasks"))
  if valid_601252 != nil:
    section.add "X-Amz-Target", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Content-Sha256", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Algorithm")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Algorithm", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Signature")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Signature", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-SignedHeaders", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Credential")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Credential", valid_601257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601259: Call_DescribeTasks_601247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a specified task or tasks.
  ## 
  let valid = call_601259.validator(path, query, header, formData, body)
  let scheme = call_601259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601259.url(scheme.get, call_601259.host, call_601259.base,
                         call_601259.route, valid.getOrDefault("path"))
  result = hook(call_601259, url, valid)

proc call*(call_601260: Call_DescribeTasks_601247; body: JsonNode): Recallable =
  ## describeTasks
  ## Describes a specified task or tasks.
  ##   body: JObject (required)
  var body_601261 = newJObject()
  if body != nil:
    body_601261 = body
  result = call_601260.call(nil, nil, nil, nil, body_601261)

var describeTasks* = Call_DescribeTasks_601247(name: "describeTasks",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DescribeTasks",
    validator: validate_DescribeTasks_601248, base: "/", url: url_DescribeTasks_601249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DiscoverPollEndpoint_601262 = ref object of OpenApiRestCall_600426
proc url_DiscoverPollEndpoint_601264(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DiscoverPollEndpoint_601263(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601265 = header.getOrDefault("X-Amz-Date")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Date", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Security-Token")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Security-Token", valid_601266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601267 = header.getOrDefault("X-Amz-Target")
  valid_601267 = validateParameter(valid_601267, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.DiscoverPollEndpoint"))
  if valid_601267 != nil:
    section.add "X-Amz-Target", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Content-Sha256", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Algorithm")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Algorithm", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Signature")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Signature", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-SignedHeaders", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Credential")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Credential", valid_601272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601274: Call_DiscoverPollEndpoint_601262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Returns an endpoint for the Amazon ECS agent to poll for updates.</p>
  ## 
  let valid = call_601274.validator(path, query, header, formData, body)
  let scheme = call_601274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601274.url(scheme.get, call_601274.host, call_601274.base,
                         call_601274.route, valid.getOrDefault("path"))
  result = hook(call_601274, url, valid)

proc call*(call_601275: Call_DiscoverPollEndpoint_601262; body: JsonNode): Recallable =
  ## discoverPollEndpoint
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Returns an endpoint for the Amazon ECS agent to poll for updates.</p>
  ##   body: JObject (required)
  var body_601276 = newJObject()
  if body != nil:
    body_601276 = body
  result = call_601275.call(nil, nil, nil, nil, body_601276)

var discoverPollEndpoint* = Call_DiscoverPollEndpoint_601262(
    name: "discoverPollEndpoint", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.DiscoverPollEndpoint",
    validator: validate_DiscoverPollEndpoint_601263, base: "/",
    url: url_DiscoverPollEndpoint_601264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAccountSettings_601277 = ref object of OpenApiRestCall_600426
proc url_ListAccountSettings_601279(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAccountSettings_601278(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601280 = header.getOrDefault("X-Amz-Date")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Date", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Security-Token")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Security-Token", valid_601281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601282 = header.getOrDefault("X-Amz-Target")
  valid_601282 = validateParameter(valid_601282, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListAccountSettings"))
  if valid_601282 != nil:
    section.add "X-Amz-Target", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Content-Sha256", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Algorithm")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Algorithm", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Signature")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Signature", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-SignedHeaders", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Credential")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Credential", valid_601287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601289: Call_ListAccountSettings_601277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the account settings for a specified principal.
  ## 
  let valid = call_601289.validator(path, query, header, formData, body)
  let scheme = call_601289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601289.url(scheme.get, call_601289.host, call_601289.base,
                         call_601289.route, valid.getOrDefault("path"))
  result = hook(call_601289, url, valid)

proc call*(call_601290: Call_ListAccountSettings_601277; body: JsonNode): Recallable =
  ## listAccountSettings
  ## Lists the account settings for a specified principal.
  ##   body: JObject (required)
  var body_601291 = newJObject()
  if body != nil:
    body_601291 = body
  result = call_601290.call(nil, nil, nil, nil, body_601291)

var listAccountSettings* = Call_ListAccountSettings_601277(
    name: "listAccountSettings", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListAccountSettings",
    validator: validate_ListAccountSettings_601278, base: "/",
    url: url_ListAccountSettings_601279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAttributes_601292 = ref object of OpenApiRestCall_600426
proc url_ListAttributes_601294(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListAttributes_601293(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the attributes for Amazon ECS resources within a specified target type and cluster. When you specify a target type and cluster, <code>ListAttributes</code> returns a list of attribute objects, one for each attribute on each resource. You can filter the list of results to a single attribute name to only return results that have that name. You can also filter the results by attribute name and value, for example, to see which container instances in a cluster are running a Linux AMI (<code>ecs.os-type=linux</code>). 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601295 = header.getOrDefault("X-Amz-Date")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Date", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Security-Token")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Security-Token", valid_601296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601297 = header.getOrDefault("X-Amz-Target")
  valid_601297 = validateParameter(valid_601297, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListAttributes"))
  if valid_601297 != nil:
    section.add "X-Amz-Target", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Content-Sha256", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Algorithm")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Algorithm", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Signature")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Signature", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-SignedHeaders", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Credential")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Credential", valid_601302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601304: Call_ListAttributes_601292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the attributes for Amazon ECS resources within a specified target type and cluster. When you specify a target type and cluster, <code>ListAttributes</code> returns a list of attribute objects, one for each attribute on each resource. You can filter the list of results to a single attribute name to only return results that have that name. You can also filter the results by attribute name and value, for example, to see which container instances in a cluster are running a Linux AMI (<code>ecs.os-type=linux</code>). 
  ## 
  let valid = call_601304.validator(path, query, header, formData, body)
  let scheme = call_601304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601304.url(scheme.get, call_601304.host, call_601304.base,
                         call_601304.route, valid.getOrDefault("path"))
  result = hook(call_601304, url, valid)

proc call*(call_601305: Call_ListAttributes_601292; body: JsonNode): Recallable =
  ## listAttributes
  ## Lists the attributes for Amazon ECS resources within a specified target type and cluster. When you specify a target type and cluster, <code>ListAttributes</code> returns a list of attribute objects, one for each attribute on each resource. You can filter the list of results to a single attribute name to only return results that have that name. You can also filter the results by attribute name and value, for example, to see which container instances in a cluster are running a Linux AMI (<code>ecs.os-type=linux</code>). 
  ##   body: JObject (required)
  var body_601306 = newJObject()
  if body != nil:
    body_601306 = body
  result = call_601305.call(nil, nil, nil, nil, body_601306)

var listAttributes* = Call_ListAttributes_601292(name: "listAttributes",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListAttributes",
    validator: validate_ListAttributes_601293, base: "/", url: url_ListAttributes_601294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_601307 = ref object of OpenApiRestCall_600426
proc url_ListClusters_601309(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListClusters_601308(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of existing clusters.
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
  var valid_601310 = query.getOrDefault("maxResults")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "maxResults", valid_601310
  var valid_601311 = query.getOrDefault("nextToken")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "nextToken", valid_601311
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601312 = header.getOrDefault("X-Amz-Date")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Date", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Security-Token")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Security-Token", valid_601313
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601314 = header.getOrDefault("X-Amz-Target")
  valid_601314 = validateParameter(valid_601314, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListClusters"))
  if valid_601314 != nil:
    section.add "X-Amz-Target", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Content-Sha256", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Algorithm")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Algorithm", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Signature")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Signature", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-SignedHeaders", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Credential")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Credential", valid_601319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601321: Call_ListClusters_601307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of existing clusters.
  ## 
  let valid = call_601321.validator(path, query, header, formData, body)
  let scheme = call_601321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601321.url(scheme.get, call_601321.host, call_601321.base,
                         call_601321.route, valid.getOrDefault("path"))
  result = hook(call_601321, url, valid)

proc call*(call_601322: Call_ListClusters_601307; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listClusters
  ## Returns a list of existing clusters.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601323 = newJObject()
  var body_601324 = newJObject()
  add(query_601323, "maxResults", newJString(maxResults))
  add(query_601323, "nextToken", newJString(nextToken))
  if body != nil:
    body_601324 = body
  result = call_601322.call(nil, query_601323, nil, nil, body_601324)

var listClusters* = Call_ListClusters_601307(name: "listClusters",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListClusters",
    validator: validate_ListClusters_601308, base: "/", url: url_ListClusters_601309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContainerInstances_601326 = ref object of OpenApiRestCall_600426
proc url_ListContainerInstances_601328(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListContainerInstances_601327(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of container instances in a specified cluster. You can filter the results of a <code>ListContainerInstances</code> operation with cluster query language statements inside the <code>filter</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html">Cluster Query Language</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
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
  var valid_601329 = query.getOrDefault("maxResults")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "maxResults", valid_601329
  var valid_601330 = query.getOrDefault("nextToken")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "nextToken", valid_601330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601331 = header.getOrDefault("X-Amz-Date")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Date", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Security-Token")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Security-Token", valid_601332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601333 = header.getOrDefault("X-Amz-Target")
  valid_601333 = validateParameter(valid_601333, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListContainerInstances"))
  if valid_601333 != nil:
    section.add "X-Amz-Target", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Content-Sha256", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Algorithm")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Algorithm", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-Signature")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Signature", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-SignedHeaders", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Credential")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Credential", valid_601338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601340: Call_ListContainerInstances_601326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of container instances in a specified cluster. You can filter the results of a <code>ListContainerInstances</code> operation with cluster query language statements inside the <code>filter</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html">Cluster Query Language</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_601340.validator(path, query, header, formData, body)
  let scheme = call_601340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601340.url(scheme.get, call_601340.host, call_601340.base,
                         call_601340.route, valid.getOrDefault("path"))
  result = hook(call_601340, url, valid)

proc call*(call_601341: Call_ListContainerInstances_601326; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listContainerInstances
  ## Returns a list of container instances in a specified cluster. You can filter the results of a <code>ListContainerInstances</code> operation with cluster query language statements inside the <code>filter</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-query-language.html">Cluster Query Language</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601342 = newJObject()
  var body_601343 = newJObject()
  add(query_601342, "maxResults", newJString(maxResults))
  add(query_601342, "nextToken", newJString(nextToken))
  if body != nil:
    body_601343 = body
  result = call_601341.call(nil, query_601342, nil, nil, body_601343)

var listContainerInstances* = Call_ListContainerInstances_601326(
    name: "listContainerInstances", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListContainerInstances",
    validator: validate_ListContainerInstances_601327, base: "/",
    url: url_ListContainerInstances_601328, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListServices_601344 = ref object of OpenApiRestCall_600426
proc url_ListServices_601346(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListServices_601345(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the services that are running in a specified cluster.
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
  var valid_601347 = query.getOrDefault("maxResults")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "maxResults", valid_601347
  var valid_601348 = query.getOrDefault("nextToken")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "nextToken", valid_601348
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601349 = header.getOrDefault("X-Amz-Date")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Date", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Security-Token")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Security-Token", valid_601350
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601351 = header.getOrDefault("X-Amz-Target")
  valid_601351 = validateParameter(valid_601351, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListServices"))
  if valid_601351 != nil:
    section.add "X-Amz-Target", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Content-Sha256", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Algorithm")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Algorithm", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Signature")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Signature", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-SignedHeaders", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Credential")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Credential", valid_601356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601358: Call_ListServices_601344; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the services that are running in a specified cluster.
  ## 
  let valid = call_601358.validator(path, query, header, formData, body)
  let scheme = call_601358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601358.url(scheme.get, call_601358.host, call_601358.base,
                         call_601358.route, valid.getOrDefault("path"))
  result = hook(call_601358, url, valid)

proc call*(call_601359: Call_ListServices_601344; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listServices
  ## Lists the services that are running in a specified cluster.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601360 = newJObject()
  var body_601361 = newJObject()
  add(query_601360, "maxResults", newJString(maxResults))
  add(query_601360, "nextToken", newJString(nextToken))
  if body != nil:
    body_601361 = body
  result = call_601359.call(nil, query_601360, nil, nil, body_601361)

var listServices* = Call_ListServices_601344(name: "listServices",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListServices",
    validator: validate_ListServices_601345, base: "/", url: url_ListServices_601346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601362 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601364(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_601363(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601365 = header.getOrDefault("X-Amz-Date")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Date", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Security-Token")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Security-Token", valid_601366
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601367 = header.getOrDefault("X-Amz-Target")
  valid_601367 = validateParameter(valid_601367, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTagsForResource"))
  if valid_601367 != nil:
    section.add "X-Amz-Target", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Content-Sha256", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Algorithm")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Algorithm", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-Signature")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Signature", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-SignedHeaders", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Credential")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Credential", valid_601372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601374: Call_ListTagsForResource_601362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an Amazon ECS resource.
  ## 
  let valid = call_601374.validator(path, query, header, formData, body)
  let scheme = call_601374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601374.url(scheme.get, call_601374.host, call_601374.base,
                         call_601374.route, valid.getOrDefault("path"))
  result = hook(call_601374, url, valid)

proc call*(call_601375: Call_ListTagsForResource_601362; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon ECS resource.
  ##   body: JObject (required)
  var body_601376 = newJObject()
  if body != nil:
    body_601376 = body
  result = call_601375.call(nil, nil, nil, nil, body_601376)

var listTagsForResource* = Call_ListTagsForResource_601362(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTagsForResource",
    validator: validate_ListTagsForResource_601363, base: "/",
    url: url_ListTagsForResource_601364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTaskDefinitionFamilies_601377 = ref object of OpenApiRestCall_600426
proc url_ListTaskDefinitionFamilies_601379(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTaskDefinitionFamilies_601378(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of task definition families that are registered to your account (which may include task definition families that no longer have any <code>ACTIVE</code> task definition revisions).</p> <p>You can filter out task definition families that do not contain any <code>ACTIVE</code> task definition revisions by setting the <code>status</code> parameter to <code>ACTIVE</code>. You can also filter the results with the <code>familyPrefix</code> parameter.</p>
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
  var valid_601380 = query.getOrDefault("maxResults")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "maxResults", valid_601380
  var valid_601381 = query.getOrDefault("nextToken")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "nextToken", valid_601381
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601382 = header.getOrDefault("X-Amz-Date")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Date", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Security-Token")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Security-Token", valid_601383
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601384 = header.getOrDefault("X-Amz-Target")
  valid_601384 = validateParameter(valid_601384, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTaskDefinitionFamilies"))
  if valid_601384 != nil:
    section.add "X-Amz-Target", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Content-Sha256", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Algorithm")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Algorithm", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Signature")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Signature", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-SignedHeaders", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Credential")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Credential", valid_601389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601391: Call_ListTaskDefinitionFamilies_601377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of task definition families that are registered to your account (which may include task definition families that no longer have any <code>ACTIVE</code> task definition revisions).</p> <p>You can filter out task definition families that do not contain any <code>ACTIVE</code> task definition revisions by setting the <code>status</code> parameter to <code>ACTIVE</code>. You can also filter the results with the <code>familyPrefix</code> parameter.</p>
  ## 
  let valid = call_601391.validator(path, query, header, formData, body)
  let scheme = call_601391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601391.url(scheme.get, call_601391.host, call_601391.base,
                         call_601391.route, valid.getOrDefault("path"))
  result = hook(call_601391, url, valid)

proc call*(call_601392: Call_ListTaskDefinitionFamilies_601377; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listTaskDefinitionFamilies
  ## <p>Returns a list of task definition families that are registered to your account (which may include task definition families that no longer have any <code>ACTIVE</code> task definition revisions).</p> <p>You can filter out task definition families that do not contain any <code>ACTIVE</code> task definition revisions by setting the <code>status</code> parameter to <code>ACTIVE</code>. You can also filter the results with the <code>familyPrefix</code> parameter.</p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601393 = newJObject()
  var body_601394 = newJObject()
  add(query_601393, "maxResults", newJString(maxResults))
  add(query_601393, "nextToken", newJString(nextToken))
  if body != nil:
    body_601394 = body
  result = call_601392.call(nil, query_601393, nil, nil, body_601394)

var listTaskDefinitionFamilies* = Call_ListTaskDefinitionFamilies_601377(
    name: "listTaskDefinitionFamilies", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTaskDefinitionFamilies",
    validator: validate_ListTaskDefinitionFamilies_601378, base: "/",
    url: url_ListTaskDefinitionFamilies_601379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTaskDefinitions_601395 = ref object of OpenApiRestCall_600426
proc url_ListTaskDefinitions_601397(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTaskDefinitions_601396(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of task definitions that are registered to your account. You can filter the results by family name with the <code>familyPrefix</code> parameter or by status with the <code>status</code> parameter.
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
  var valid_601398 = query.getOrDefault("maxResults")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "maxResults", valid_601398
  var valid_601399 = query.getOrDefault("nextToken")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "nextToken", valid_601399
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601400 = header.getOrDefault("X-Amz-Date")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Date", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Security-Token")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Security-Token", valid_601401
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601402 = header.getOrDefault("X-Amz-Target")
  valid_601402 = validateParameter(valid_601402, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTaskDefinitions"))
  if valid_601402 != nil:
    section.add "X-Amz-Target", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Content-Sha256", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Algorithm")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Algorithm", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Signature")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Signature", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-SignedHeaders", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Credential")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Credential", valid_601407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601409: Call_ListTaskDefinitions_601395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of task definitions that are registered to your account. You can filter the results by family name with the <code>familyPrefix</code> parameter or by status with the <code>status</code> parameter.
  ## 
  let valid = call_601409.validator(path, query, header, formData, body)
  let scheme = call_601409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601409.url(scheme.get, call_601409.host, call_601409.base,
                         call_601409.route, valid.getOrDefault("path"))
  result = hook(call_601409, url, valid)

proc call*(call_601410: Call_ListTaskDefinitions_601395; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listTaskDefinitions
  ## Returns a list of task definitions that are registered to your account. You can filter the results by family name with the <code>familyPrefix</code> parameter or by status with the <code>status</code> parameter.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601411 = newJObject()
  var body_601412 = newJObject()
  add(query_601411, "maxResults", newJString(maxResults))
  add(query_601411, "nextToken", newJString(nextToken))
  if body != nil:
    body_601412 = body
  result = call_601410.call(nil, query_601411, nil, nil, body_601412)

var listTaskDefinitions* = Call_ListTaskDefinitions_601395(
    name: "listTaskDefinitions", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTaskDefinitions",
    validator: validate_ListTaskDefinitions_601396, base: "/",
    url: url_ListTaskDefinitions_601397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTasks_601413 = ref object of OpenApiRestCall_600426
proc url_ListTasks_601415(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTasks_601414(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of tasks for a specified cluster. You can filter the results by family name, by a particular container instance, or by the desired status of the task with the <code>family</code>, <code>containerInstance</code>, and <code>desiredStatus</code> parameters.</p> <p>Recently stopped tasks might appear in the returned results. Currently, stopped tasks appear in the returned results for at least one hour. </p>
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
  var valid_601416 = query.getOrDefault("maxResults")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "maxResults", valid_601416
  var valid_601417 = query.getOrDefault("nextToken")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "nextToken", valid_601417
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601418 = header.getOrDefault("X-Amz-Date")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Date", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Security-Token")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Security-Token", valid_601419
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601420 = header.getOrDefault("X-Amz-Target")
  valid_601420 = validateParameter(valid_601420, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.ListTasks"))
  if valid_601420 != nil:
    section.add "X-Amz-Target", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Content-Sha256", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Algorithm")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Algorithm", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Signature")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Signature", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-SignedHeaders", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-Credential")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Credential", valid_601425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601427: Call_ListTasks_601413; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of tasks for a specified cluster. You can filter the results by family name, by a particular container instance, or by the desired status of the task with the <code>family</code>, <code>containerInstance</code>, and <code>desiredStatus</code> parameters.</p> <p>Recently stopped tasks might appear in the returned results. Currently, stopped tasks appear in the returned results for at least one hour. </p>
  ## 
  let valid = call_601427.validator(path, query, header, formData, body)
  let scheme = call_601427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601427.url(scheme.get, call_601427.host, call_601427.base,
                         call_601427.route, valid.getOrDefault("path"))
  result = hook(call_601427, url, valid)

proc call*(call_601428: Call_ListTasks_601413; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listTasks
  ## <p>Returns a list of tasks for a specified cluster. You can filter the results by family name, by a particular container instance, or by the desired status of the task with the <code>family</code>, <code>containerInstance</code>, and <code>desiredStatus</code> parameters.</p> <p>Recently stopped tasks might appear in the returned results. Currently, stopped tasks appear in the returned results for at least one hour. </p>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601429 = newJObject()
  var body_601430 = newJObject()
  add(query_601429, "maxResults", newJString(maxResults))
  add(query_601429, "nextToken", newJString(nextToken))
  if body != nil:
    body_601430 = body
  result = call_601428.call(nil, query_601429, nil, nil, body_601430)

var listTasks* = Call_ListTasks_601413(name: "listTasks", meth: HttpMethod.HttpPost,
                                    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.ListTasks",
                                    validator: validate_ListTasks_601414,
                                    base: "/", url: url_ListTasks_601415,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSetting_601431 = ref object of OpenApiRestCall_600426
proc url_PutAccountSetting_601433(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutAccountSetting_601432(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601434 = header.getOrDefault("X-Amz-Date")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Date", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Security-Token")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Security-Token", valid_601435
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601436 = header.getOrDefault("X-Amz-Target")
  valid_601436 = validateParameter(valid_601436, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutAccountSetting"))
  if valid_601436 != nil:
    section.add "X-Amz-Target", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Content-Sha256", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Algorithm")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Algorithm", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Signature")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Signature", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-SignedHeaders", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Credential")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Credential", valid_601441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601443: Call_PutAccountSetting_601431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies an account setting. Account settings are set on a per-Region basis.</p> <p>If you change the account setting for the root user, the default settings for all of the IAM users and roles for which no individual account setting has been specified are reset. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html">Account Settings</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>serviceLongArnFormat</code>, <code>taskLongArnFormat</code>, or <code>containerInstanceLongArnFormat</code> are specified, the Amazon Resource Name (ARN) and resource ID format of the resource type for a specified IAM user, IAM role, or the root user for an account is affected. The opt-in and opt-out account setting must be set for each Amazon ECS resource separately. The ARN and resource ID format of a resource will be defined by the opt-in status of the IAM user or role that created the resource. You must enable this setting to use Amazon ECS features such as resource tagging.</p> <p>When <code>awsvpcTrunking</code> is specified, the elastic network interface (ENI) limit for any new container instances that support the feature is changed. If <code>awsvpcTrunking</code> is enabled, any new container instances that support the feature are launched have the increased ENI limits available to them. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html">Elastic Network Interface Trunking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>containerInsights</code> is specified, the default setting indicating whether CloudWatch Container Insights is enabled for your clusters is changed. If <code>containerInsights</code> is enabled, any new clusters that are created will have Container Insights enabled unless you disable it during cluster creation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-container-insights.html">CloudWatch Container Insights</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_601443.validator(path, query, header, formData, body)
  let scheme = call_601443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601443.url(scheme.get, call_601443.host, call_601443.base,
                         call_601443.route, valid.getOrDefault("path"))
  result = hook(call_601443, url, valid)

proc call*(call_601444: Call_PutAccountSetting_601431; body: JsonNode): Recallable =
  ## putAccountSetting
  ## <p>Modifies an account setting. Account settings are set on a per-Region basis.</p> <p>If you change the account setting for the root user, the default settings for all of the IAM users and roles for which no individual account setting has been specified are reset. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-account-settings.html">Account Settings</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>serviceLongArnFormat</code>, <code>taskLongArnFormat</code>, or <code>containerInstanceLongArnFormat</code> are specified, the Amazon Resource Name (ARN) and resource ID format of the resource type for a specified IAM user, IAM role, or the root user for an account is affected. The opt-in and opt-out account setting must be set for each Amazon ECS resource separately. The ARN and resource ID format of a resource will be defined by the opt-in status of the IAM user or role that created the resource. You must enable this setting to use Amazon ECS features such as resource tagging.</p> <p>When <code>awsvpcTrunking</code> is specified, the elastic network interface (ENI) limit for any new container instances that support the feature is changed. If <code>awsvpcTrunking</code> is enabled, any new container instances that support the feature are launched have the increased ENI limits available to them. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html">Elastic Network Interface Trunking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>When <code>containerInsights</code> is specified, the default setting indicating whether CloudWatch Container Insights is enabled for your clusters is changed. If <code>containerInsights</code> is enabled, any new clusters that are created will have Container Insights enabled unless you disable it during cluster creation. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-container-insights.html">CloudWatch Container Insights</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601445 = newJObject()
  if body != nil:
    body_601445 = body
  result = call_601444.call(nil, nil, nil, nil, body_601445)

var putAccountSetting* = Call_PutAccountSetting_601431(name: "putAccountSetting",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAccountSetting",
    validator: validate_PutAccountSetting_601432, base: "/",
    url: url_PutAccountSetting_601433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSettingDefault_601446 = ref object of OpenApiRestCall_600426
proc url_PutAccountSettingDefault_601448(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutAccountSettingDefault_601447(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601449 = header.getOrDefault("X-Amz-Date")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Date", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-Security-Token")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Security-Token", valid_601450
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601451 = header.getOrDefault("X-Amz-Target")
  valid_601451 = validateParameter(valid_601451, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutAccountSettingDefault"))
  if valid_601451 != nil:
    section.add "X-Amz-Target", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Content-Sha256", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Algorithm")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Algorithm", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Signature")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Signature", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-SignedHeaders", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Credential")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Credential", valid_601456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601458: Call_PutAccountSettingDefault_601446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies an account setting for all IAM users on an account for whom no individual account setting has been specified. Account settings are set on a per-Region basis.
  ## 
  let valid = call_601458.validator(path, query, header, formData, body)
  let scheme = call_601458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601458.url(scheme.get, call_601458.host, call_601458.base,
                         call_601458.route, valid.getOrDefault("path"))
  result = hook(call_601458, url, valid)

proc call*(call_601459: Call_PutAccountSettingDefault_601446; body: JsonNode): Recallable =
  ## putAccountSettingDefault
  ## Modifies an account setting for all IAM users on an account for whom no individual account setting has been specified. Account settings are set on a per-Region basis.
  ##   body: JObject (required)
  var body_601460 = newJObject()
  if body != nil:
    body_601460 = body
  result = call_601459.call(nil, nil, nil, nil, body_601460)

var putAccountSettingDefault* = Call_PutAccountSettingDefault_601446(
    name: "putAccountSettingDefault", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAccountSettingDefault",
    validator: validate_PutAccountSettingDefault_601447, base: "/",
    url: url_PutAccountSettingDefault_601448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAttributes_601461 = ref object of OpenApiRestCall_600426
proc url_PutAttributes_601463(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutAttributes_601462(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601464 = header.getOrDefault("X-Amz-Date")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-Date", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Security-Token")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Security-Token", valid_601465
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601466 = header.getOrDefault("X-Amz-Target")
  valid_601466 = validateParameter(valid_601466, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.PutAttributes"))
  if valid_601466 != nil:
    section.add "X-Amz-Target", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Content-Sha256", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Algorithm")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Algorithm", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Signature")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Signature", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-SignedHeaders", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Credential")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Credential", valid_601471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601473: Call_PutAttributes_601461; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update an attribute on an Amazon ECS resource. If the attribute does not exist, it is created. If the attribute exists, its value is replaced with the specified value. To delete an attribute, use <a>DeleteAttributes</a>. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#attributes">Attributes</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_601473.validator(path, query, header, formData, body)
  let scheme = call_601473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601473.url(scheme.get, call_601473.host, call_601473.base,
                         call_601473.route, valid.getOrDefault("path"))
  result = hook(call_601473, url, valid)

proc call*(call_601474: Call_PutAttributes_601461; body: JsonNode): Recallable =
  ## putAttributes
  ## Create or update an attribute on an Amazon ECS resource. If the attribute does not exist, it is created. If the attribute exists, its value is replaced with the specified value. To delete an attribute, use <a>DeleteAttributes</a>. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html#attributes">Attributes</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_601475 = newJObject()
  if body != nil:
    body_601475 = body
  result = call_601474.call(nil, nil, nil, nil, body_601475)

var putAttributes* = Call_PutAttributes_601461(name: "putAttributes",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.PutAttributes",
    validator: validate_PutAttributes_601462, base: "/", url: url_PutAttributes_601463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterContainerInstance_601476 = ref object of OpenApiRestCall_600426
proc url_RegisterContainerInstance_601478(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterContainerInstance_601477(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601479 = header.getOrDefault("X-Amz-Date")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Date", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Security-Token")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Security-Token", valid_601480
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601481 = header.getOrDefault("X-Amz-Target")
  valid_601481 = validateParameter(valid_601481, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.RegisterContainerInstance"))
  if valid_601481 != nil:
    section.add "X-Amz-Target", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Content-Sha256", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Algorithm")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Algorithm", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Signature")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Signature", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-SignedHeaders", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Credential")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Credential", valid_601486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601488: Call_RegisterContainerInstance_601476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Registers an EC2 instance into the specified cluster. This instance becomes available to place containers on.</p>
  ## 
  let valid = call_601488.validator(path, query, header, formData, body)
  let scheme = call_601488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601488.url(scheme.get, call_601488.host, call_601488.base,
                         call_601488.route, valid.getOrDefault("path"))
  result = hook(call_601488, url, valid)

proc call*(call_601489: Call_RegisterContainerInstance_601476; body: JsonNode): Recallable =
  ## registerContainerInstance
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Registers an EC2 instance into the specified cluster. This instance becomes available to place containers on.</p>
  ##   body: JObject (required)
  var body_601490 = newJObject()
  if body != nil:
    body_601490 = body
  result = call_601489.call(nil, nil, nil, nil, body_601490)

var registerContainerInstance* = Call_RegisterContainerInstance_601476(
    name: "registerContainerInstance", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RegisterContainerInstance",
    validator: validate_RegisterContainerInstance_601477, base: "/",
    url: url_RegisterContainerInstance_601478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskDefinition_601491 = ref object of OpenApiRestCall_600426
proc url_RegisterTaskDefinition_601493(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterTaskDefinition_601492(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601494 = header.getOrDefault("X-Amz-Date")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-Date", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Security-Token")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Security-Token", valid_601495
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601496 = header.getOrDefault("X-Amz-Target")
  valid_601496 = validateParameter(valid_601496, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.RegisterTaskDefinition"))
  if valid_601496 != nil:
    section.add "X-Amz-Target", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Content-Sha256", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Algorithm")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Algorithm", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Signature")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Signature", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-SignedHeaders", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Credential")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Credential", valid_601501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601503: Call_RegisterTaskDefinition_601491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers a new task definition from the supplied <code>family</code> and <code>containerDefinitions</code>. Optionally, you can add data volumes to your containers with the <code>volumes</code> parameter. For more information about task definition parameters and defaults, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_defintions.html">Amazon ECS Task Definitions</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify an IAM role for your task with the <code>taskRoleArn</code> parameter. When you specify an IAM role for a task, its containers can then use the latest versions of the AWS CLI or SDKs to make API requests to the AWS services that are specified in the IAM policy associated with the role. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html">IAM Roles for Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify a Docker networking mode for the containers in your task definition with the <code>networkMode</code> parameter. The available network modes correspond to those described in <a href="https://docs.docker.com/engine/reference/run/#/network-settings">Network settings</a> in the Docker run reference. If you specify the <code>awsvpc</code> network mode, the task is allocated an elastic network interface, and you must specify a <a>NetworkConfiguration</a> when you create a service or run a task with the task definition. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html">Task Networking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_601503.validator(path, query, header, formData, body)
  let scheme = call_601503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601503.url(scheme.get, call_601503.host, call_601503.base,
                         call_601503.route, valid.getOrDefault("path"))
  result = hook(call_601503, url, valid)

proc call*(call_601504: Call_RegisterTaskDefinition_601491; body: JsonNode): Recallable =
  ## registerTaskDefinition
  ## <p>Registers a new task definition from the supplied <code>family</code> and <code>containerDefinitions</code>. Optionally, you can add data volumes to your containers with the <code>volumes</code> parameter. For more information about task definition parameters and defaults, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_defintions.html">Amazon ECS Task Definitions</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify an IAM role for your task with the <code>taskRoleArn</code> parameter. When you specify an IAM role for a task, its containers can then use the latest versions of the AWS CLI or SDKs to make API requests to the AWS services that are specified in the IAM policy associated with the role. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html">IAM Roles for Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>You can specify a Docker networking mode for the containers in your task definition with the <code>networkMode</code> parameter. The available network modes correspond to those described in <a href="https://docs.docker.com/engine/reference/run/#/network-settings">Network settings</a> in the Docker run reference. If you specify the <code>awsvpc</code> network mode, the task is allocated an elastic network interface, and you must specify a <a>NetworkConfiguration</a> when you create a service or run a task with the task definition. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html">Task Networking</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601505 = newJObject()
  if body != nil:
    body_601505 = body
  result = call_601504.call(nil, nil, nil, nil, body_601505)

var registerTaskDefinition* = Call_RegisterTaskDefinition_601491(
    name: "registerTaskDefinition", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RegisterTaskDefinition",
    validator: validate_RegisterTaskDefinition_601492, base: "/",
    url: url_RegisterTaskDefinition_601493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RunTask_601506 = ref object of OpenApiRestCall_600426
proc url_RunTask_601508(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RunTask_601507(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601509 = header.getOrDefault("X-Amz-Date")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-Date", valid_601509
  var valid_601510 = header.getOrDefault("X-Amz-Security-Token")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "X-Amz-Security-Token", valid_601510
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601511 = header.getOrDefault("X-Amz-Target")
  valid_601511 = validateParameter(valid_601511, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.RunTask"))
  if valid_601511 != nil:
    section.add "X-Amz-Target", valid_601511
  var valid_601512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Content-Sha256", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Algorithm")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Algorithm", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-Signature")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-Signature", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-SignedHeaders", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Credential")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Credential", valid_601516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601518: Call_RunTask_601506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a new task using the specified task definition.</p> <p>You can allow Amazon ECS to place tasks for you, or you can customize how Amazon ECS places tasks using placement constraints and placement strategies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Alternatively, you can use <a>StartTask</a> to use your own scheduler or place tasks manually on specific container instances.</p> <p>The Amazon ECS API follows an eventual consistency model, due to the distributed nature of the system supporting the API. This means that the result of an API command you run that affects your Amazon ECS resources might not be immediately visible to all subsequent commands you run. Keep this in mind when you carry out an API command that immediately follows a previous API command.</p> <p>To manage eventual consistency, you can do the following:</p> <ul> <li> <p>Confirm the state of the resource before you run a command to modify it. Run the DescribeTasks command using an exponential backoff algorithm to ensure that you allow enough time for the previous command to propagate through the system. To do this, run the DescribeTasks command repeatedly, starting with a couple of seconds of wait time and increasing gradually up to five minutes of wait time.</p> </li> <li> <p>Add wait time between subsequent commands, even if the DescribeTasks command returns an accurate response. Apply an exponential backoff algorithm starting with a couple of seconds of wait time, and increase gradually up to about five minutes of wait time.</p> </li> </ul>
  ## 
  let valid = call_601518.validator(path, query, header, formData, body)
  let scheme = call_601518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601518.url(scheme.get, call_601518.host, call_601518.base,
                         call_601518.route, valid.getOrDefault("path"))
  result = hook(call_601518, url, valid)

proc call*(call_601519: Call_RunTask_601506; body: JsonNode): Recallable =
  ## runTask
  ## <p>Starts a new task using the specified task definition.</p> <p>You can allow Amazon ECS to place tasks for you, or you can customize how Amazon ECS places tasks using placement constraints and placement strategies. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> <p>Alternatively, you can use <a>StartTask</a> to use your own scheduler or place tasks manually on specific container instances.</p> <p>The Amazon ECS API follows an eventual consistency model, due to the distributed nature of the system supporting the API. This means that the result of an API command you run that affects your Amazon ECS resources might not be immediately visible to all subsequent commands you run. Keep this in mind when you carry out an API command that immediately follows a previous API command.</p> <p>To manage eventual consistency, you can do the following:</p> <ul> <li> <p>Confirm the state of the resource before you run a command to modify it. Run the DescribeTasks command using an exponential backoff algorithm to ensure that you allow enough time for the previous command to propagate through the system. To do this, run the DescribeTasks command repeatedly, starting with a couple of seconds of wait time and increasing gradually up to five minutes of wait time.</p> </li> <li> <p>Add wait time between subsequent commands, even if the DescribeTasks command returns an accurate response. Apply an exponential backoff algorithm starting with a couple of seconds of wait time, and increase gradually up to about five minutes of wait time.</p> </li> </ul>
  ##   body: JObject (required)
  var body_601520 = newJObject()
  if body != nil:
    body_601520 = body
  result = call_601519.call(nil, nil, nil, nil, body_601520)

var runTask* = Call_RunTask_601506(name: "runTask", meth: HttpMethod.HttpPost,
                                host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.RunTask",
                                validator: validate_RunTask_601507, base: "/",
                                url: url_RunTask_601508,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTask_601521 = ref object of OpenApiRestCall_600426
proc url_StartTask_601523(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartTask_601522(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601524 = header.getOrDefault("X-Amz-Date")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-Date", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Security-Token")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Security-Token", valid_601525
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601526 = header.getOrDefault("X-Amz-Target")
  valid_601526 = validateParameter(valid_601526, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.StartTask"))
  if valid_601526 != nil:
    section.add "X-Amz-Target", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Content-Sha256", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-Algorithm")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-Algorithm", valid_601528
  var valid_601529 = header.getOrDefault("X-Amz-Signature")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-Signature", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-SignedHeaders", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Credential")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Credential", valid_601531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601533: Call_StartTask_601521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a new task from the specified task definition on the specified container instance or instances.</p> <p>Alternatively, you can use <a>RunTask</a> to place tasks for you. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_601533.validator(path, query, header, formData, body)
  let scheme = call_601533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601533.url(scheme.get, call_601533.host, call_601533.base,
                         call_601533.route, valid.getOrDefault("path"))
  result = hook(call_601533, url, valid)

proc call*(call_601534: Call_StartTask_601521; body: JsonNode): Recallable =
  ## startTask
  ## <p>Starts a new task from the specified task definition on the specified container instance or instances.</p> <p>Alternatively, you can use <a>RunTask</a> to place tasks for you. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/scheduling_tasks.html">Scheduling Tasks</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601535 = newJObject()
  if body != nil:
    body_601535 = body
  result = call_601534.call(nil, nil, nil, nil, body_601535)

var startTask* = Call_StartTask_601521(name: "startTask", meth: HttpMethod.HttpPost,
                                    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.StartTask",
                                    validator: validate_StartTask_601522,
                                    base: "/", url: url_StartTask_601523,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTask_601536 = ref object of OpenApiRestCall_600426
proc url_StopTask_601538(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopTask_601537(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601539 = header.getOrDefault("X-Amz-Date")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Date", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Security-Token")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Security-Token", valid_601540
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601541 = header.getOrDefault("X-Amz-Target")
  valid_601541 = validateParameter(valid_601541, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.StopTask"))
  if valid_601541 != nil:
    section.add "X-Amz-Target", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Content-Sha256", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Algorithm")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Algorithm", valid_601543
  var valid_601544 = header.getOrDefault("X-Amz-Signature")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-Signature", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-SignedHeaders", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-Credential")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Credential", valid_601546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601548: Call_StopTask_601536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops a running task. Any tags associated with the task will be deleted.</p> <p>When <a>StopTask</a> is called on a task, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> value and a default 30-second timeout, after which the <code>SIGKILL</code> value is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> value gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> value is sent.</p> <note> <p>The default 30-second timeout can be configured on the Amazon ECS container agent with the <code>ECS_CONTAINER_STOP_TIMEOUT</code> variable. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html">Amazon ECS Container Agent Configuration</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ## 
  let valid = call_601548.validator(path, query, header, formData, body)
  let scheme = call_601548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601548.url(scheme.get, call_601548.host, call_601548.base,
                         call_601548.route, valid.getOrDefault("path"))
  result = hook(call_601548, url, valid)

proc call*(call_601549: Call_StopTask_601536; body: JsonNode): Recallable =
  ## stopTask
  ## <p>Stops a running task. Any tags associated with the task will be deleted.</p> <p>When <a>StopTask</a> is called on a task, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> value and a default 30-second timeout, after which the <code>SIGKILL</code> value is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> value gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> value is sent.</p> <note> <p>The default 30-second timeout can be configured on the Amazon ECS container agent with the <code>ECS_CONTAINER_STOP_TIMEOUT</code> variable. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html">Amazon ECS Container Agent Configuration</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p> </note>
  ##   body: JObject (required)
  var body_601550 = newJObject()
  if body != nil:
    body_601550 = body
  result = call_601549.call(nil, nil, nil, nil, body_601550)

var stopTask* = Call_StopTask_601536(name: "stopTask", meth: HttpMethod.HttpPost,
                                  host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.StopTask",
                                  validator: validate_StopTask_601537, base: "/",
                                  url: url_StopTask_601538,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitAttachmentStateChanges_601551 = ref object of OpenApiRestCall_600426
proc url_SubmitAttachmentStateChanges_601553(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SubmitAttachmentStateChanges_601552(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601554 = header.getOrDefault("X-Amz-Date")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-Date", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Security-Token")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Security-Token", valid_601555
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601556 = header.getOrDefault("X-Amz-Target")
  valid_601556 = validateParameter(valid_601556, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.SubmitAttachmentStateChanges"))
  if valid_601556 != nil:
    section.add "X-Amz-Target", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Content-Sha256", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Algorithm")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Algorithm", valid_601558
  var valid_601559 = header.getOrDefault("X-Amz-Signature")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-Signature", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-SignedHeaders", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-Credential")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Credential", valid_601561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601563: Call_SubmitAttachmentStateChanges_601551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that an attachment changed states.</p>
  ## 
  let valid = call_601563.validator(path, query, header, formData, body)
  let scheme = call_601563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601563.url(scheme.get, call_601563.host, call_601563.base,
                         call_601563.route, valid.getOrDefault("path"))
  result = hook(call_601563, url, valid)

proc call*(call_601564: Call_SubmitAttachmentStateChanges_601551; body: JsonNode): Recallable =
  ## submitAttachmentStateChanges
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that an attachment changed states.</p>
  ##   body: JObject (required)
  var body_601565 = newJObject()
  if body != nil:
    body_601565 = body
  result = call_601564.call(nil, nil, nil, nil, body_601565)

var submitAttachmentStateChanges* = Call_SubmitAttachmentStateChanges_601551(
    name: "submitAttachmentStateChanges", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitAttachmentStateChanges",
    validator: validate_SubmitAttachmentStateChanges_601552, base: "/",
    url: url_SubmitAttachmentStateChanges_601553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitContainerStateChange_601566 = ref object of OpenApiRestCall_600426
proc url_SubmitContainerStateChange_601568(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SubmitContainerStateChange_601567(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601569 = header.getOrDefault("X-Amz-Date")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-Date", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-Security-Token")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-Security-Token", valid_601570
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601571 = header.getOrDefault("X-Amz-Target")
  valid_601571 = validateParameter(valid_601571, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.SubmitContainerStateChange"))
  if valid_601571 != nil:
    section.add "X-Amz-Target", valid_601571
  var valid_601572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Content-Sha256", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Algorithm")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Algorithm", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Signature")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Signature", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-SignedHeaders", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-Credential")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Credential", valid_601576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601578: Call_SubmitContainerStateChange_601566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a container changed states.</p>
  ## 
  let valid = call_601578.validator(path, query, header, formData, body)
  let scheme = call_601578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601578.url(scheme.get, call_601578.host, call_601578.base,
                         call_601578.route, valid.getOrDefault("path"))
  result = hook(call_601578, url, valid)

proc call*(call_601579: Call_SubmitContainerStateChange_601566; body: JsonNode): Recallable =
  ## submitContainerStateChange
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a container changed states.</p>
  ##   body: JObject (required)
  var body_601580 = newJObject()
  if body != nil:
    body_601580 = body
  result = call_601579.call(nil, nil, nil, nil, body_601580)

var submitContainerStateChange* = Call_SubmitContainerStateChange_601566(
    name: "submitContainerStateChange", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitContainerStateChange",
    validator: validate_SubmitContainerStateChange_601567, base: "/",
    url: url_SubmitContainerStateChange_601568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SubmitTaskStateChange_601581 = ref object of OpenApiRestCall_600426
proc url_SubmitTaskStateChange_601583(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SubmitTaskStateChange_601582(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601584 = header.getOrDefault("X-Amz-Date")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Date", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-Security-Token")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Security-Token", valid_601585
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601586 = header.getOrDefault("X-Amz-Target")
  valid_601586 = validateParameter(valid_601586, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.SubmitTaskStateChange"))
  if valid_601586 != nil:
    section.add "X-Amz-Target", valid_601586
  var valid_601587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Content-Sha256", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Algorithm")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Algorithm", valid_601588
  var valid_601589 = header.getOrDefault("X-Amz-Signature")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "X-Amz-Signature", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-SignedHeaders", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Credential")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Credential", valid_601591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601593: Call_SubmitTaskStateChange_601581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a task changed states.</p>
  ## 
  let valid = call_601593.validator(path, query, header, formData, body)
  let scheme = call_601593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601593.url(scheme.get, call_601593.host, call_601593.base,
                         call_601593.route, valid.getOrDefault("path"))
  result = hook(call_601593, url, valid)

proc call*(call_601594: Call_SubmitTaskStateChange_601581; body: JsonNode): Recallable =
  ## submitTaskStateChange
  ## <note> <p>This action is only used by the Amazon ECS agent, and it is not intended for use outside of the agent.</p> </note> <p>Sent to acknowledge that a task changed states.</p>
  ##   body: JObject (required)
  var body_601595 = newJObject()
  if body != nil:
    body_601595 = body
  result = call_601594.call(nil, nil, nil, nil, body_601595)

var submitTaskStateChange* = Call_SubmitTaskStateChange_601581(
    name: "submitTaskStateChange", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.SubmitTaskStateChange",
    validator: validate_SubmitTaskStateChange_601582, base: "/",
    url: url_SubmitTaskStateChange_601583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601596 = ref object of OpenApiRestCall_600426
proc url_TagResource_601598(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_601597(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601599 = header.getOrDefault("X-Amz-Date")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-Date", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-Security-Token")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-Security-Token", valid_601600
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601601 = header.getOrDefault("X-Amz-Target")
  valid_601601 = validateParameter(valid_601601, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.TagResource"))
  if valid_601601 != nil:
    section.add "X-Amz-Target", valid_601601
  var valid_601602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-Content-Sha256", valid_601602
  var valid_601603 = header.getOrDefault("X-Amz-Algorithm")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Algorithm", valid_601603
  var valid_601604 = header.getOrDefault("X-Amz-Signature")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = nil)
  if valid_601604 != nil:
    section.add "X-Amz-Signature", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-SignedHeaders", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Credential")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Credential", valid_601606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601608: Call_TagResource_601596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_601608.validator(path, query, header, formData, body)
  let scheme = call_601608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601608.url(scheme.get, call_601608.host, call_601608.base,
                         call_601608.route, valid.getOrDefault("path"))
  result = hook(call_601608, url, valid)

proc call*(call_601609: Call_TagResource_601596; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  var body_601610 = newJObject()
  if body != nil:
    body_601610 = body
  result = call_601609.call(nil, nil, nil, nil, body_601610)

var tagResource* = Call_TagResource_601596(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.TagResource",
                                        validator: validate_TagResource_601597,
                                        base: "/", url: url_TagResource_601598,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601611 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601613(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_601612(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601614 = header.getOrDefault("X-Amz-Date")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-Date", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-Security-Token")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-Security-Token", valid_601615
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601616 = header.getOrDefault("X-Amz-Target")
  valid_601616 = validateParameter(valid_601616, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UntagResource"))
  if valid_601616 != nil:
    section.add "X-Amz-Target", valid_601616
  var valid_601617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Content-Sha256", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Algorithm")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Algorithm", valid_601618
  var valid_601619 = header.getOrDefault("X-Amz-Signature")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "X-Amz-Signature", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-SignedHeaders", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-Credential")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Credential", valid_601621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601623: Call_UntagResource_601611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_601623.validator(path, query, header, formData, body)
  let scheme = call_601623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601623.url(scheme.get, call_601623.host, call_601623.base,
                         call_601623.route, valid.getOrDefault("path"))
  result = hook(call_601623, url, valid)

proc call*(call_601624: Call_UntagResource_601611; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  var body_601625 = newJObject()
  if body != nil:
    body_601625 = body
  result = call_601624.call(nil, nil, nil, nil, body_601625)

var untagResource* = Call_UntagResource_601611(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UntagResource",
    validator: validate_UntagResource_601612, base: "/", url: url_UntagResource_601613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterSettings_601626 = ref object of OpenApiRestCall_600426
proc url_UpdateClusterSettings_601628(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateClusterSettings_601627(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601629 = header.getOrDefault("X-Amz-Date")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-Date", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-Security-Token")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Security-Token", valid_601630
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601631 = header.getOrDefault("X-Amz-Target")
  valid_601631 = validateParameter(valid_601631, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateClusterSettings"))
  if valid_601631 != nil:
    section.add "X-Amz-Target", valid_601631
  var valid_601632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Content-Sha256", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-Algorithm")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Algorithm", valid_601633
  var valid_601634 = header.getOrDefault("X-Amz-Signature")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "X-Amz-Signature", valid_601634
  var valid_601635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-SignedHeaders", valid_601635
  var valid_601636 = header.getOrDefault("X-Amz-Credential")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Credential", valid_601636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601638: Call_UpdateClusterSettings_601626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies the settings to use for a cluster.
  ## 
  let valid = call_601638.validator(path, query, header, formData, body)
  let scheme = call_601638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601638.url(scheme.get, call_601638.host, call_601638.base,
                         call_601638.route, valid.getOrDefault("path"))
  result = hook(call_601638, url, valid)

proc call*(call_601639: Call_UpdateClusterSettings_601626; body: JsonNode): Recallable =
  ## updateClusterSettings
  ## Modifies the settings to use for a cluster.
  ##   body: JObject (required)
  var body_601640 = newJObject()
  if body != nil:
    body_601640 = body
  result = call_601639.call(nil, nil, nil, nil, body_601640)

var updateClusterSettings* = Call_UpdateClusterSettings_601626(
    name: "updateClusterSettings", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateClusterSettings",
    validator: validate_UpdateClusterSettings_601627, base: "/",
    url: url_UpdateClusterSettings_601628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContainerAgent_601641 = ref object of OpenApiRestCall_600426
proc url_UpdateContainerAgent_601643(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateContainerAgent_601642(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601644 = header.getOrDefault("X-Amz-Date")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "X-Amz-Date", valid_601644
  var valid_601645 = header.getOrDefault("X-Amz-Security-Token")
  valid_601645 = validateParameter(valid_601645, JString, required = false,
                                 default = nil)
  if valid_601645 != nil:
    section.add "X-Amz-Security-Token", valid_601645
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601646 = header.getOrDefault("X-Amz-Target")
  valid_601646 = validateParameter(valid_601646, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateContainerAgent"))
  if valid_601646 != nil:
    section.add "X-Amz-Target", valid_601646
  var valid_601647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Content-Sha256", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Algorithm")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Algorithm", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Signature")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Signature", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-SignedHeaders", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Credential")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Credential", valid_601651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601653: Call_UpdateContainerAgent_601641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Amazon ECS container agent on a specified container instance. Updating the Amazon ECS container agent does not interrupt running tasks or services on the container instance. The process for updating the agent differs depending on whether your container instance was launched with the Amazon ECS-optimized AMI or another operating system.</p> <p> <code>UpdateContainerAgent</code> requires the Amazon ECS-optimized AMI or Amazon Linux with the <code>ecs-init</code> service installed and running. For help updating the Amazon ECS container agent on other operating systems, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-update.html#manually_update_agent">Manually Updating the Amazon ECS Container Agent</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ## 
  let valid = call_601653.validator(path, query, header, formData, body)
  let scheme = call_601653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601653.url(scheme.get, call_601653.host, call_601653.base,
                         call_601653.route, valid.getOrDefault("path"))
  result = hook(call_601653, url, valid)

proc call*(call_601654: Call_UpdateContainerAgent_601641; body: JsonNode): Recallable =
  ## updateContainerAgent
  ## <p>Updates the Amazon ECS container agent on a specified container instance. Updating the Amazon ECS container agent does not interrupt running tasks or services on the container instance. The process for updating the agent differs depending on whether your container instance was launched with the Amazon ECS-optimized AMI or another operating system.</p> <p> <code>UpdateContainerAgent</code> requires the Amazon ECS-optimized AMI or Amazon Linux with the <code>ecs-init</code> service installed and running. For help updating the Amazon ECS container agent on other operating systems, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-update.html#manually_update_agent">Manually Updating the Amazon ECS Container Agent</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_601655 = newJObject()
  if body != nil:
    body_601655 = body
  result = call_601654.call(nil, nil, nil, nil, body_601655)

var updateContainerAgent* = Call_UpdateContainerAgent_601641(
    name: "updateContainerAgent", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateContainerAgent",
    validator: validate_UpdateContainerAgent_601642, base: "/",
    url: url_UpdateContainerAgent_601643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateContainerInstancesState_601656 = ref object of OpenApiRestCall_600426
proc url_UpdateContainerInstancesState_601658(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateContainerInstancesState_601657(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601659 = header.getOrDefault("X-Amz-Date")
  valid_601659 = validateParameter(valid_601659, JString, required = false,
                                 default = nil)
  if valid_601659 != nil:
    section.add "X-Amz-Date", valid_601659
  var valid_601660 = header.getOrDefault("X-Amz-Security-Token")
  valid_601660 = validateParameter(valid_601660, JString, required = false,
                                 default = nil)
  if valid_601660 != nil:
    section.add "X-Amz-Security-Token", valid_601660
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601661 = header.getOrDefault("X-Amz-Target")
  valid_601661 = validateParameter(valid_601661, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateContainerInstancesState"))
  if valid_601661 != nil:
    section.add "X-Amz-Target", valid_601661
  var valid_601662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Content-Sha256", valid_601662
  var valid_601663 = header.getOrDefault("X-Amz-Algorithm")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Algorithm", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-Signature")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Signature", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-SignedHeaders", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Credential")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Credential", valid_601666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601668: Call_UpdateContainerInstancesState_601656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the status of an Amazon ECS container instance.</p> <p>Once a container instance has reached an <code>ACTIVE</code> state, you can change the status of a container instance to <code>DRAINING</code> to manually remove an instance from a cluster, for example to perform system updates, update the Docker daemon, or scale down the cluster size.</p> <important> <p>A container instance cannot be changed to <code>DRAINING</code> until it has reached an <code>ACTIVE</code> status. If the instance is in any other status, an error will be received.</p> </important> <p>When you set a container instance to <code>DRAINING</code>, Amazon ECS prevents new tasks from being scheduled for placement on the container instance and replacement service tasks are started on other container instances in the cluster if the resources are available. Service tasks on the container instance that are in the <code>PENDING</code> state are stopped immediately.</p> <p>Service tasks on the container instance that are in the <code>RUNNING</code> state are stopped and replaced according to the service's deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>. You can change the deployment configuration of your service using <a>UpdateService</a>.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during task replacement. For example, <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. If the minimum is 100%, the service scheduler can't remove existing tasks until the replacement tasks are considered healthy. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during task replacement, which enables you to define the replacement batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four tasks to be drained, provided that the cluster resources required to do this are available. If the maximum is 100%, then replacement tasks can't start until the draining tasks have stopped.</p> </li> </ul> <p>Any <code>PENDING</code> or <code>RUNNING</code> tasks that do not belong to a service are not affected. You must wait for them to finish or stop them manually.</p> <p>A container instance has completed draining when it has no more <code>RUNNING</code> tasks. You can verify this using <a>ListTasks</a>.</p> <p>When a container instance has been drained, you can set a container instance to <code>ACTIVE</code> status and once it has reached that status the Amazon ECS scheduler can begin scheduling tasks on the instance again.</p>
  ## 
  let valid = call_601668.validator(path, query, header, formData, body)
  let scheme = call_601668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601668.url(scheme.get, call_601668.host, call_601668.base,
                         call_601668.route, valid.getOrDefault("path"))
  result = hook(call_601668, url, valid)

proc call*(call_601669: Call_UpdateContainerInstancesState_601656; body: JsonNode): Recallable =
  ## updateContainerInstancesState
  ## <p>Modifies the status of an Amazon ECS container instance.</p> <p>Once a container instance has reached an <code>ACTIVE</code> state, you can change the status of a container instance to <code>DRAINING</code> to manually remove an instance from a cluster, for example to perform system updates, update the Docker daemon, or scale down the cluster size.</p> <important> <p>A container instance cannot be changed to <code>DRAINING</code> until it has reached an <code>ACTIVE</code> status. If the instance is in any other status, an error will be received.</p> </important> <p>When you set a container instance to <code>DRAINING</code>, Amazon ECS prevents new tasks from being scheduled for placement on the container instance and replacement service tasks are started on other container instances in the cluster if the resources are available. Service tasks on the container instance that are in the <code>PENDING</code> state are stopped immediately.</p> <p>Service tasks on the container instance that are in the <code>RUNNING</code> state are stopped and replaced according to the service's deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>. You can change the deployment configuration of your service using <a>UpdateService</a>.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during task replacement. For example, <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. If the minimum is 100%, the service scheduler can't remove existing tasks until the replacement tasks are considered healthy. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during task replacement, which enables you to define the replacement batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four tasks to be drained, provided that the cluster resources required to do this are available. If the maximum is 100%, then replacement tasks can't start until the draining tasks have stopped.</p> </li> </ul> <p>Any <code>PENDING</code> or <code>RUNNING</code> tasks that do not belong to a service are not affected. You must wait for them to finish or stop them manually.</p> <p>A container instance has completed draining when it has no more <code>RUNNING</code> tasks. You can verify this using <a>ListTasks</a>.</p> <p>When a container instance has been drained, you can set a container instance to <code>ACTIVE</code> status and once it has reached that status the Amazon ECS scheduler can begin scheduling tasks on the instance again.</p>
  ##   body: JObject (required)
  var body_601670 = newJObject()
  if body != nil:
    body_601670 = body
  result = call_601669.call(nil, nil, nil, nil, body_601670)

var updateContainerInstancesState* = Call_UpdateContainerInstancesState_601656(
    name: "updateContainerInstancesState", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateContainerInstancesState",
    validator: validate_UpdateContainerInstancesState_601657, base: "/",
    url: url_UpdateContainerInstancesState_601658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateService_601671 = ref object of OpenApiRestCall_600426
proc url_UpdateService_601673(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateService_601672(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601674 = header.getOrDefault("X-Amz-Date")
  valid_601674 = validateParameter(valid_601674, JString, required = false,
                                 default = nil)
  if valid_601674 != nil:
    section.add "X-Amz-Date", valid_601674
  var valid_601675 = header.getOrDefault("X-Amz-Security-Token")
  valid_601675 = validateParameter(valid_601675, JString, required = false,
                                 default = nil)
  if valid_601675 != nil:
    section.add "X-Amz-Security-Token", valid_601675
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601676 = header.getOrDefault("X-Amz-Target")
  valid_601676 = validateParameter(valid_601676, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateService"))
  if valid_601676 != nil:
    section.add "X-Amz-Target", valid_601676
  var valid_601677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "X-Amz-Content-Sha256", valid_601677
  var valid_601678 = header.getOrDefault("X-Amz-Algorithm")
  valid_601678 = validateParameter(valid_601678, JString, required = false,
                                 default = nil)
  if valid_601678 != nil:
    section.add "X-Amz-Algorithm", valid_601678
  var valid_601679 = header.getOrDefault("X-Amz-Signature")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "X-Amz-Signature", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-SignedHeaders", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Credential")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Credential", valid_601681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601683: Call_UpdateService_601671; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the parameters of a service.</p> <p>For services using the rolling update (<code>ECS</code>) deployment controller, the desired count, deployment configuration, network configuration, or task definition used can be updated.</p> <p>For services using the blue/green (<code>CODE_DEPLOY</code>) deployment controller, only the desired count, deployment configuration, and health check grace period can be updated using this API. If the network configuration, platform version, or task definition need to be updated, a new AWS CodeDeploy deployment should be created. For more information, see <a href="https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html">CreateDeployment</a> in the <i>AWS CodeDeploy API Reference</i>.</p> <p>For services using an external deployment controller, you can update only the desired count and health check grace period using this API. If the launch type, load balancer, network configuration, platform version, or task definition need to be updated, you should create a new task set. For more information, see <a>CreateTaskSet</a>.</p> <p>You can add to or subtract from the number of instantiations of a task definition in a service by specifying the cluster that the service is running in and a new <code>desiredCount</code> parameter.</p> <p>If you have updated the Docker image of your application, you can create a new task definition with that image and deploy it to your service. The service scheduler uses the minimum healthy percent and maximum percent parameters (in the service's deployment configuration) to determine the deployment strategy.</p> <note> <p>If your updated Docker image uses the same tag as what is in the existing task definition for your service (for example, <code>my_image:latest</code>), you do not need to create a new revision of your task definition. You can update the service using the <code>forceNewDeployment</code> option. The new tasks launched by the deployment pull the current image/tag combination from your repository when they start.</p> </note> <p>You can also update the deployment configuration of a service. When a deployment is triggered by updating the task definition of a service, the service scheduler uses the deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>, to determine the deployment strategy.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during a deployment. For example, if <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during a deployment, which enables you to define the deployment batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available).</p> </li> </ul> <p>When <a>UpdateService</a> stops a task during a deployment, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> and a 30-second timeout, after which <code>SIGKILL</code> is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> is sent.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster with the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy):</p> <ul> <li> <p>Sort the valid container instances by the fewest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul> <p>When the service scheduler stops running tasks, it attempts to maintain balance across the Availability Zones in your cluster using the following logic: </p> <ul> <li> <p>Sort the container instances by the largest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have two, container instances in either zone B or C are considered optimal for termination.</p> </li> <li> <p>Stop the task on a container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the largest number of running tasks for this service.</p> </li> </ul>
  ## 
  let valid = call_601683.validator(path, query, header, formData, body)
  let scheme = call_601683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601683.url(scheme.get, call_601683.host, call_601683.base,
                         call_601683.route, valid.getOrDefault("path"))
  result = hook(call_601683, url, valid)

proc call*(call_601684: Call_UpdateService_601671; body: JsonNode): Recallable =
  ## updateService
  ## <p>Modifies the parameters of a service.</p> <p>For services using the rolling update (<code>ECS</code>) deployment controller, the desired count, deployment configuration, network configuration, or task definition used can be updated.</p> <p>For services using the blue/green (<code>CODE_DEPLOY</code>) deployment controller, only the desired count, deployment configuration, and health check grace period can be updated using this API. If the network configuration, platform version, or task definition need to be updated, a new AWS CodeDeploy deployment should be created. For more information, see <a href="https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html">CreateDeployment</a> in the <i>AWS CodeDeploy API Reference</i>.</p> <p>For services using an external deployment controller, you can update only the desired count and health check grace period using this API. If the launch type, load balancer, network configuration, platform version, or task definition need to be updated, you should create a new task set. For more information, see <a>CreateTaskSet</a>.</p> <p>You can add to or subtract from the number of instantiations of a task definition in a service by specifying the cluster that the service is running in and a new <code>desiredCount</code> parameter.</p> <p>If you have updated the Docker image of your application, you can create a new task definition with that image and deploy it to your service. The service scheduler uses the minimum healthy percent and maximum percent parameters (in the service's deployment configuration) to determine the deployment strategy.</p> <note> <p>If your updated Docker image uses the same tag as what is in the existing task definition for your service (for example, <code>my_image:latest</code>), you do not need to create a new revision of your task definition. You can update the service using the <code>forceNewDeployment</code> option. The new tasks launched by the deployment pull the current image/tag combination from your repository when they start.</p> </note> <p>You can also update the deployment configuration of a service. When a deployment is triggered by updating the task definition of a service, the service scheduler uses the deployment configuration parameters, <code>minimumHealthyPercent</code> and <code>maximumPercent</code>, to determine the deployment strategy.</p> <ul> <li> <p>If <code>minimumHealthyPercent</code> is below 100%, the scheduler can ignore <code>desiredCount</code> temporarily during a deployment. For example, if <code>desiredCount</code> is four tasks, a minimum of 50% allows the scheduler to stop two existing tasks before starting two new tasks. Tasks for services that do not use a load balancer are considered healthy if they are in the <code>RUNNING</code> state. Tasks for services that use a load balancer are considered healthy if they are in the <code>RUNNING</code> state and the container instance they are hosted on is reported as healthy by the load balancer.</p> </li> <li> <p>The <code>maximumPercent</code> parameter represents an upper limit on the number of running tasks during a deployment, which enables you to define the deployment batch size. For example, if <code>desiredCount</code> is four tasks, a maximum of 200% starts four new tasks before stopping the four older tasks (provided that the cluster resources required to do this are available).</p> </li> </ul> <p>When <a>UpdateService</a> stops a task during a deployment, the equivalent of <code>docker stop</code> is issued to the containers running in the task. This results in a <code>SIGTERM</code> and a 30-second timeout, after which <code>SIGKILL</code> is sent and the containers are forcibly stopped. If the container handles the <code>SIGTERM</code> gracefully and exits within 30 seconds from receiving it, no <code>SIGKILL</code> is sent.</p> <p>When the service scheduler launches new tasks, it determines task placement in your cluster with the following logic:</p> <ul> <li> <p>Determine which of the container instances in your cluster can support your service's task definition (for example, they have the required CPU, memory, ports, and container instance attributes).</p> </li> <li> <p>By default, the service scheduler attempts to balance tasks across Availability Zones in this manner (although you can choose a different placement strategy):</p> <ul> <li> <p>Sort the valid container instances by the fewest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have zero, valid container instances in either zone B or C are considered optimal for placement.</p> </li> <li> <p>Place the new service task on a valid container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the fewest number of running tasks for this service.</p> </li> </ul> </li> </ul> <p>When the service scheduler stops running tasks, it attempts to maintain balance across the Availability Zones in your cluster using the following logic: </p> <ul> <li> <p>Sort the container instances by the largest number of running tasks for this service in the same Availability Zone as the instance. For example, if zone A has one running service task and zones B and C each have two, container instances in either zone B or C are considered optimal for termination.</p> </li> <li> <p>Stop the task on a container instance in an optimal Availability Zone (based on the previous steps), favoring container instances with the largest number of running tasks for this service.</p> </li> </ul>
  ##   body: JObject (required)
  var body_601685 = newJObject()
  if body != nil:
    body_601685 = body
  result = call_601684.call(nil, nil, nil, nil, body_601685)

var updateService* = Call_UpdateService_601671(name: "updateService",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateService",
    validator: validate_UpdateService_601672, base: "/", url: url_UpdateService_601673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServicePrimaryTaskSet_601686 = ref object of OpenApiRestCall_600426
proc url_UpdateServicePrimaryTaskSet_601688(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateServicePrimaryTaskSet_601687(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601689 = header.getOrDefault("X-Amz-Date")
  valid_601689 = validateParameter(valid_601689, JString, required = false,
                                 default = nil)
  if valid_601689 != nil:
    section.add "X-Amz-Date", valid_601689
  var valid_601690 = header.getOrDefault("X-Amz-Security-Token")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Security-Token", valid_601690
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601691 = header.getOrDefault("X-Amz-Target")
  valid_601691 = validateParameter(valid_601691, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateServicePrimaryTaskSet"))
  if valid_601691 != nil:
    section.add "X-Amz-Target", valid_601691
  var valid_601692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Content-Sha256", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-Algorithm")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Algorithm", valid_601693
  var valid_601694 = header.getOrDefault("X-Amz-Signature")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-Signature", valid_601694
  var valid_601695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-SignedHeaders", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-Credential")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Credential", valid_601696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601698: Call_UpdateServicePrimaryTaskSet_601686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies which task set in a service is the primary task set. Any parameters that are updated on the primary task set in a service will transition to the service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_601698.validator(path, query, header, formData, body)
  let scheme = call_601698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601698.url(scheme.get, call_601698.host, call_601698.base,
                         call_601698.route, valid.getOrDefault("path"))
  result = hook(call_601698, url, valid)

proc call*(call_601699: Call_UpdateServicePrimaryTaskSet_601686; body: JsonNode): Recallable =
  ## updateServicePrimaryTaskSet
  ## Modifies which task set in a service is the primary task set. Any parameters that are updated on the primary task set in a service will transition to the service. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_601700 = newJObject()
  if body != nil:
    body_601700 = body
  result = call_601699.call(nil, nil, nil, nil, body_601700)

var updateServicePrimaryTaskSet* = Call_UpdateServicePrimaryTaskSet_601686(
    name: "updateServicePrimaryTaskSet", meth: HttpMethod.HttpPost,
    host: "ecs.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateServicePrimaryTaskSet",
    validator: validate_UpdateServicePrimaryTaskSet_601687, base: "/",
    url: url_UpdateServicePrimaryTaskSet_601688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTaskSet_601701 = ref object of OpenApiRestCall_600426
proc url_UpdateTaskSet_601703(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateTaskSet_601702(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601704 = header.getOrDefault("X-Amz-Date")
  valid_601704 = validateParameter(valid_601704, JString, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "X-Amz-Date", valid_601704
  var valid_601705 = header.getOrDefault("X-Amz-Security-Token")
  valid_601705 = validateParameter(valid_601705, JString, required = false,
                                 default = nil)
  if valid_601705 != nil:
    section.add "X-Amz-Security-Token", valid_601705
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601706 = header.getOrDefault("X-Amz-Target")
  valid_601706 = validateParameter(valid_601706, JString, required = true, default = newJString(
      "AmazonEC2ContainerServiceV20141113.UpdateTaskSet"))
  if valid_601706 != nil:
    section.add "X-Amz-Target", valid_601706
  var valid_601707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-Content-Sha256", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Algorithm")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Algorithm", valid_601708
  var valid_601709 = header.getOrDefault("X-Amz-Signature")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "X-Amz-Signature", valid_601709
  var valid_601710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-SignedHeaders", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-Credential")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-Credential", valid_601711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601713: Call_UpdateTaskSet_601701; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a task set. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ## 
  let valid = call_601713.validator(path, query, header, formData, body)
  let scheme = call_601713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601713.url(scheme.get, call_601713.host, call_601713.base,
                         call_601713.route, valid.getOrDefault("path"))
  result = hook(call_601713, url, valid)

proc call*(call_601714: Call_UpdateTaskSet_601701; body: JsonNode): Recallable =
  ## updateTaskSet
  ## Modifies a task set. This is used when a service uses the <code>EXTERNAL</code> deployment controller type. For more information, see <a href="https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-types.html">Amazon ECS Deployment Types</a> in the <i>Amazon Elastic Container Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_601715 = newJObject()
  if body != nil:
    body_601715 = body
  result = call_601714.call(nil, nil, nil, nil, body_601715)

var updateTaskSet* = Call_UpdateTaskSet_601701(name: "updateTaskSet",
    meth: HttpMethod.HttpPost, host: "ecs.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerServiceV20141113.UpdateTaskSet",
    validator: validate_UpdateTaskSet_601702, base: "/", url: url_UpdateTaskSet_601703,
    schemes: {Scheme.Https, Scheme.Http})
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
