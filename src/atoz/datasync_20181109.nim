
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS DataSync
## version: 2018-11-09
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS DataSync</fullname> <p>AWS DataSync is a managed data transfer service that makes it simpler for you to automate moving data between on-premises storage and Amazon Simple Storage Service (Amazon S3) or Amazon Elastic File System (Amazon EFS). </p> <p>This API interface reference for AWS DataSync contains documentation for a programming interface that you can use to manage AWS DataSync.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/datasync/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "datasync.ap-northeast-1.amazonaws.com", "ap-southeast-1": "datasync.ap-southeast-1.amazonaws.com",
                           "us-west-2": "datasync.us-west-2.amazonaws.com",
                           "eu-west-2": "datasync.eu-west-2.amazonaws.com", "ap-northeast-3": "datasync.ap-northeast-3.amazonaws.com", "eu-central-1": "datasync.eu-central-1.amazonaws.com",
                           "us-east-2": "datasync.us-east-2.amazonaws.com",
                           "us-east-1": "datasync.us-east-1.amazonaws.com", "cn-northwest-1": "datasync.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "datasync.ap-south-1.amazonaws.com",
                           "eu-north-1": "datasync.eu-north-1.amazonaws.com", "ap-northeast-2": "datasync.ap-northeast-2.amazonaws.com",
                           "us-west-1": "datasync.us-west-1.amazonaws.com", "us-gov-east-1": "datasync.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "datasync.eu-west-3.amazonaws.com", "cn-north-1": "datasync.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "datasync.sa-east-1.amazonaws.com",
                           "eu-west-1": "datasync.eu-west-1.amazonaws.com", "us-gov-west-1": "datasync.us-gov-west-1.amazonaws.com", "ap-southeast-2": "datasync.ap-southeast-2.amazonaws.com", "ca-central-1": "datasync.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "datasync.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "datasync.ap-southeast-1.amazonaws.com",
      "us-west-2": "datasync.us-west-2.amazonaws.com",
      "eu-west-2": "datasync.eu-west-2.amazonaws.com",
      "ap-northeast-3": "datasync.ap-northeast-3.amazonaws.com",
      "eu-central-1": "datasync.eu-central-1.amazonaws.com",
      "us-east-2": "datasync.us-east-2.amazonaws.com",
      "us-east-1": "datasync.us-east-1.amazonaws.com",
      "cn-northwest-1": "datasync.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "datasync.ap-south-1.amazonaws.com",
      "eu-north-1": "datasync.eu-north-1.amazonaws.com",
      "ap-northeast-2": "datasync.ap-northeast-2.amazonaws.com",
      "us-west-1": "datasync.us-west-1.amazonaws.com",
      "us-gov-east-1": "datasync.us-gov-east-1.amazonaws.com",
      "eu-west-3": "datasync.eu-west-3.amazonaws.com",
      "cn-north-1": "datasync.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "datasync.sa-east-1.amazonaws.com",
      "eu-west-1": "datasync.eu-west-1.amazonaws.com",
      "us-gov-west-1": "datasync.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "datasync.ap-southeast-2.amazonaws.com",
      "ca-central-1": "datasync.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "datasync"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelTaskExecution_604996 = ref object of OpenApiRestCall_604658
proc url_CancelTaskExecution_604998(protocol: Scheme; host: string; base: string;
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

proc validate_CancelTaskExecution_604997(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Cancels execution of a task. </p> <p>When you cancel a task execution, the transfer of some files are abruptly interrupted. The contents of files that are transferred to the destination might be incomplete or inconsistent with the source files. However, if you start a new task execution on the same task and you allow the task execution to complete, file content on the destination is complete and consistent. This applies to other unexpected failures that interrupt a task execution. In all of these cases, AWS DataSync successfully complete the transfer when you start the next task execution.</p>
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
      "FmrsService.CancelTaskExecution"))
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

proc call*(call_605154: Call_CancelTaskExecution_604996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels execution of a task. </p> <p>When you cancel a task execution, the transfer of some files are abruptly interrupted. The contents of files that are transferred to the destination might be incomplete or inconsistent with the source files. However, if you start a new task execution on the same task and you allow the task execution to complete, file content on the destination is complete and consistent. This applies to other unexpected failures that interrupt a task execution. In all of these cases, AWS DataSync successfully complete the transfer when you start the next task execution.</p>
  ## 
  let valid = call_605154.validator(path, query, header, formData, body)
  let scheme = call_605154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605154.url(scheme.get, call_605154.host, call_605154.base,
                         call_605154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605154, url, valid)

proc call*(call_605225: Call_CancelTaskExecution_604996; body: JsonNode): Recallable =
  ## cancelTaskExecution
  ## <p>Cancels execution of a task. </p> <p>When you cancel a task execution, the transfer of some files are abruptly interrupted. The contents of files that are transferred to the destination might be incomplete or inconsistent with the source files. However, if you start a new task execution on the same task and you allow the task execution to complete, file content on the destination is complete and consistent. This applies to other unexpected failures that interrupt a task execution. In all of these cases, AWS DataSync successfully complete the transfer when you start the next task execution.</p>
  ##   body: JObject (required)
  var body_605226 = newJObject()
  if body != nil:
    body_605226 = body
  result = call_605225.call(nil, nil, nil, nil, body_605226)

var cancelTaskExecution* = Call_CancelTaskExecution_604996(
    name: "cancelTaskExecution", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CancelTaskExecution",
    validator: validate_CancelTaskExecution_604997, base: "/",
    url: url_CancelTaskExecution_604998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAgent_605265 = ref object of OpenApiRestCall_604658
proc url_CreateAgent_605267(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAgent_605266(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Activates an AWS DataSync agent that you have deployed on your host. The activation process associates your agent with your account. In the activation process, you specify information such as the AWS Region that you want to activate the agent in. You activate the agent in the AWS Region where your target locations (in Amazon S3 or Amazon EFS) reside. Your tasks are created in this AWS Region.</p> <p>You can activate the agent in a VPC (Virtual private Cloud) or provide the agent access to a VPC endpoint so you can run tasks without going over the public Internet.</p> <p>You can use an agent for more than one location. If a task uses multiple agents, all of them need to have status AVAILABLE for the task to run. If you use multiple agents for a source location, the status of all the agents must be AVAILABLE for the task to run. </p> <p>Agents are automatically updated by AWS on a regular basis, using a mechanism that ensures minimal interruption to your tasks.</p> <p/>
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
      "FmrsService.CreateAgent"))
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

proc call*(call_605277: Call_CreateAgent_605265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Activates an AWS DataSync agent that you have deployed on your host. The activation process associates your agent with your account. In the activation process, you specify information such as the AWS Region that you want to activate the agent in. You activate the agent in the AWS Region where your target locations (in Amazon S3 or Amazon EFS) reside. Your tasks are created in this AWS Region.</p> <p>You can activate the agent in a VPC (Virtual private Cloud) or provide the agent access to a VPC endpoint so you can run tasks without going over the public Internet.</p> <p>You can use an agent for more than one location. If a task uses multiple agents, all of them need to have status AVAILABLE for the task to run. If you use multiple agents for a source location, the status of all the agents must be AVAILABLE for the task to run. </p> <p>Agents are automatically updated by AWS on a regular basis, using a mechanism that ensures minimal interruption to your tasks.</p> <p/>
  ## 
  let valid = call_605277.validator(path, query, header, formData, body)
  let scheme = call_605277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605277.url(scheme.get, call_605277.host, call_605277.base,
                         call_605277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605277, url, valid)

proc call*(call_605278: Call_CreateAgent_605265; body: JsonNode): Recallable =
  ## createAgent
  ## <p>Activates an AWS DataSync agent that you have deployed on your host. The activation process associates your agent with your account. In the activation process, you specify information such as the AWS Region that you want to activate the agent in. You activate the agent in the AWS Region where your target locations (in Amazon S3 or Amazon EFS) reside. Your tasks are created in this AWS Region.</p> <p>You can activate the agent in a VPC (Virtual private Cloud) or provide the agent access to a VPC endpoint so you can run tasks without going over the public Internet.</p> <p>You can use an agent for more than one location. If a task uses multiple agents, all of them need to have status AVAILABLE for the task to run. If you use multiple agents for a source location, the status of all the agents must be AVAILABLE for the task to run. </p> <p>Agents are automatically updated by AWS on a regular basis, using a mechanism that ensures minimal interruption to your tasks.</p> <p/>
  ##   body: JObject (required)
  var body_605279 = newJObject()
  if body != nil:
    body_605279 = body
  result = call_605278.call(nil, nil, nil, nil, body_605279)

var createAgent* = Call_CreateAgent_605265(name: "createAgent",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.CreateAgent",
                                        validator: validate_CreateAgent_605266,
                                        base: "/", url: url_CreateAgent_605267,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationEfs_605280 = ref object of OpenApiRestCall_604658
proc url_CreateLocationEfs_605282(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLocationEfs_605281(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an endpoint for an Amazon EFS file system.
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
      "FmrsService.CreateLocationEfs"))
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

proc call*(call_605292: Call_CreateLocationEfs_605280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint for an Amazon EFS file system.
  ## 
  let valid = call_605292.validator(path, query, header, formData, body)
  let scheme = call_605292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605292.url(scheme.get, call_605292.host, call_605292.base,
                         call_605292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605292, url, valid)

proc call*(call_605293: Call_CreateLocationEfs_605280; body: JsonNode): Recallable =
  ## createLocationEfs
  ## Creates an endpoint for an Amazon EFS file system.
  ##   body: JObject (required)
  var body_605294 = newJObject()
  if body != nil:
    body_605294 = body
  result = call_605293.call(nil, nil, nil, nil, body_605294)

var createLocationEfs* = Call_CreateLocationEfs_605280(name: "createLocationEfs",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationEfs",
    validator: validate_CreateLocationEfs_605281, base: "/",
    url: url_CreateLocationEfs_605282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationFsxWindows_605295 = ref object of OpenApiRestCall_604658
proc url_CreateLocationFsxWindows_605297(protocol: Scheme; host: string;
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

proc validate_CreateLocationFsxWindows_605296(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an endpoint for an Amazon FSx for Windows file system.
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
      "FmrsService.CreateLocationFsxWindows"))
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

proc call*(call_605307: Call_CreateLocationFsxWindows_605295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint for an Amazon FSx for Windows file system.
  ## 
  let valid = call_605307.validator(path, query, header, formData, body)
  let scheme = call_605307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605307.url(scheme.get, call_605307.host, call_605307.base,
                         call_605307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605307, url, valid)

proc call*(call_605308: Call_CreateLocationFsxWindows_605295; body: JsonNode): Recallable =
  ## createLocationFsxWindows
  ## Creates an endpoint for an Amazon FSx for Windows file system.
  ##   body: JObject (required)
  var body_605309 = newJObject()
  if body != nil:
    body_605309 = body
  result = call_605308.call(nil, nil, nil, nil, body_605309)

var createLocationFsxWindows* = Call_CreateLocationFsxWindows_605295(
    name: "createLocationFsxWindows", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationFsxWindows",
    validator: validate_CreateLocationFsxWindows_605296, base: "/",
    url: url_CreateLocationFsxWindows_605297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationNfs_605310 = ref object of OpenApiRestCall_604658
proc url_CreateLocationNfs_605312(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLocationNfs_605311(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Defines a file system on a Network File System (NFS) server that can be read from or written to
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
      "FmrsService.CreateLocationNfs"))
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

proc call*(call_605322: Call_CreateLocationNfs_605310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines a file system on a Network File System (NFS) server that can be read from or written to
  ## 
  let valid = call_605322.validator(path, query, header, formData, body)
  let scheme = call_605322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605322.url(scheme.get, call_605322.host, call_605322.base,
                         call_605322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605322, url, valid)

proc call*(call_605323: Call_CreateLocationNfs_605310; body: JsonNode): Recallable =
  ## createLocationNfs
  ## Defines a file system on a Network File System (NFS) server that can be read from or written to
  ##   body: JObject (required)
  var body_605324 = newJObject()
  if body != nil:
    body_605324 = body
  result = call_605323.call(nil, nil, nil, nil, body_605324)

var createLocationNfs* = Call_CreateLocationNfs_605310(name: "createLocationNfs",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationNfs",
    validator: validate_CreateLocationNfs_605311, base: "/",
    url: url_CreateLocationNfs_605312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationS3_605325 = ref object of OpenApiRestCall_604658
proc url_CreateLocationS3_605327(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLocationS3_605326(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates an endpoint for an Amazon S3 bucket.</p> <p>For AWS DataSync to access a destination S3 bucket, it needs an AWS Identity and Access Management (IAM) role that has the required permissions. You can set up the required permissions by creating an IAM policy that grants the required permissions and attaching the policy to the role. An example of such a policy is shown in the examples section.</p> <p>For more information, see https://docs.aws.amazon.com/datasync/latest/userguide/working-with-locations.html#create-s3-location in the <i>AWS DataSync User Guide.</i> </p>
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
      "FmrsService.CreateLocationS3"))
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

proc call*(call_605337: Call_CreateLocationS3_605325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for an Amazon S3 bucket.</p> <p>For AWS DataSync to access a destination S3 bucket, it needs an AWS Identity and Access Management (IAM) role that has the required permissions. You can set up the required permissions by creating an IAM policy that grants the required permissions and attaching the policy to the role. An example of such a policy is shown in the examples section.</p> <p>For more information, see https://docs.aws.amazon.com/datasync/latest/userguide/working-with-locations.html#create-s3-location in the <i>AWS DataSync User Guide.</i> </p>
  ## 
  let valid = call_605337.validator(path, query, header, formData, body)
  let scheme = call_605337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605337.url(scheme.get, call_605337.host, call_605337.base,
                         call_605337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605337, url, valid)

proc call*(call_605338: Call_CreateLocationS3_605325; body: JsonNode): Recallable =
  ## createLocationS3
  ## <p>Creates an endpoint for an Amazon S3 bucket.</p> <p>For AWS DataSync to access a destination S3 bucket, it needs an AWS Identity and Access Management (IAM) role that has the required permissions. You can set up the required permissions by creating an IAM policy that grants the required permissions and attaching the policy to the role. An example of such a policy is shown in the examples section.</p> <p>For more information, see https://docs.aws.amazon.com/datasync/latest/userguide/working-with-locations.html#create-s3-location in the <i>AWS DataSync User Guide.</i> </p>
  ##   body: JObject (required)
  var body_605339 = newJObject()
  if body != nil:
    body_605339 = body
  result = call_605338.call(nil, nil, nil, nil, body_605339)

var createLocationS3* = Call_CreateLocationS3_605325(name: "createLocationS3",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationS3",
    validator: validate_CreateLocationS3_605326, base: "/",
    url: url_CreateLocationS3_605327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationSmb_605340 = ref object of OpenApiRestCall_604658
proc url_CreateLocationSmb_605342(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLocationSmb_605341(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Defines a file system on an Server Message Block (SMB) server that can be read from or written to.
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
      "FmrsService.CreateLocationSmb"))
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

proc call*(call_605352: Call_CreateLocationSmb_605340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines a file system on an Server Message Block (SMB) server that can be read from or written to.
  ## 
  let valid = call_605352.validator(path, query, header, formData, body)
  let scheme = call_605352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605352.url(scheme.get, call_605352.host, call_605352.base,
                         call_605352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605352, url, valid)

proc call*(call_605353: Call_CreateLocationSmb_605340; body: JsonNode): Recallable =
  ## createLocationSmb
  ## Defines a file system on an Server Message Block (SMB) server that can be read from or written to.
  ##   body: JObject (required)
  var body_605354 = newJObject()
  if body != nil:
    body_605354 = body
  result = call_605353.call(nil, nil, nil, nil, body_605354)

var createLocationSmb* = Call_CreateLocationSmb_605340(name: "createLocationSmb",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationSmb",
    validator: validate_CreateLocationSmb_605341, base: "/",
    url: url_CreateLocationSmb_605342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTask_605355 = ref object of OpenApiRestCall_604658
proc url_CreateTask_605357(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateTask_605356(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a task. A task is a set of two locations (source and destination) and a set of Options that you use to control the behavior of a task. If you don't specify Options when you create a task, AWS DataSync populates them with service defaults.</p> <p>When you create a task, it first enters the CREATING state. During CREATING AWS DataSync attempts to mount the on-premises Network File System (NFS) location. The task transitions to the AVAILABLE state without waiting for the AWS location to become mounted. If required, AWS DataSync mounts the AWS location before each task execution.</p> <p>If an agent that is associated with a source (NFS) location goes offline, the task transitions to the UNAVAILABLE status. If the status of the task remains in the CREATING status for more than a few minutes, it means that your agent might be having trouble mounting the source NFS file system. Check the task's ErrorCode and ErrorDetail. Mount issues are often caused by either a misconfigured firewall or a mistyped NFS server host name.</p>
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
  valid_605358 = validateParameter(valid_605358, JString, required = true,
                                 default = newJString("FmrsService.CreateTask"))
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

proc call*(call_605367: Call_CreateTask_605355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a task. A task is a set of two locations (source and destination) and a set of Options that you use to control the behavior of a task. If you don't specify Options when you create a task, AWS DataSync populates them with service defaults.</p> <p>When you create a task, it first enters the CREATING state. During CREATING AWS DataSync attempts to mount the on-premises Network File System (NFS) location. The task transitions to the AVAILABLE state without waiting for the AWS location to become mounted. If required, AWS DataSync mounts the AWS location before each task execution.</p> <p>If an agent that is associated with a source (NFS) location goes offline, the task transitions to the UNAVAILABLE status. If the status of the task remains in the CREATING status for more than a few minutes, it means that your agent might be having trouble mounting the source NFS file system. Check the task's ErrorCode and ErrorDetail. Mount issues are often caused by either a misconfigured firewall or a mistyped NFS server host name.</p>
  ## 
  let valid = call_605367.validator(path, query, header, formData, body)
  let scheme = call_605367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605367.url(scheme.get, call_605367.host, call_605367.base,
                         call_605367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605367, url, valid)

proc call*(call_605368: Call_CreateTask_605355; body: JsonNode): Recallable =
  ## createTask
  ## <p>Creates a task. A task is a set of two locations (source and destination) and a set of Options that you use to control the behavior of a task. If you don't specify Options when you create a task, AWS DataSync populates them with service defaults.</p> <p>When you create a task, it first enters the CREATING state. During CREATING AWS DataSync attempts to mount the on-premises Network File System (NFS) location. The task transitions to the AVAILABLE state without waiting for the AWS location to become mounted. If required, AWS DataSync mounts the AWS location before each task execution.</p> <p>If an agent that is associated with a source (NFS) location goes offline, the task transitions to the UNAVAILABLE status. If the status of the task remains in the CREATING status for more than a few minutes, it means that your agent might be having trouble mounting the source NFS file system. Check the task's ErrorCode and ErrorDetail. Mount issues are often caused by either a misconfigured firewall or a mistyped NFS server host name.</p>
  ##   body: JObject (required)
  var body_605369 = newJObject()
  if body != nil:
    body_605369 = body
  result = call_605368.call(nil, nil, nil, nil, body_605369)

var createTask* = Call_CreateTask_605355(name: "createTask",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.CreateTask",
                                      validator: validate_CreateTask_605356,
                                      base: "/", url: url_CreateTask_605357,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAgent_605370 = ref object of OpenApiRestCall_604658
proc url_DeleteAgent_605372(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAgent_605371(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an agent. To specify which agent to delete, use the Amazon Resource Name (ARN) of the agent in your request. The operation disassociates the agent from your AWS account. However, it doesn't delete the agent virtual machine (VM) from your on-premises environment.
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
      "FmrsService.DeleteAgent"))
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

proc call*(call_605382: Call_DeleteAgent_605370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an agent. To specify which agent to delete, use the Amazon Resource Name (ARN) of the agent in your request. The operation disassociates the agent from your AWS account. However, it doesn't delete the agent virtual machine (VM) from your on-premises environment.
  ## 
  let valid = call_605382.validator(path, query, header, formData, body)
  let scheme = call_605382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605382.url(scheme.get, call_605382.host, call_605382.base,
                         call_605382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605382, url, valid)

proc call*(call_605383: Call_DeleteAgent_605370; body: JsonNode): Recallable =
  ## deleteAgent
  ## Deletes an agent. To specify which agent to delete, use the Amazon Resource Name (ARN) of the agent in your request. The operation disassociates the agent from your AWS account. However, it doesn't delete the agent virtual machine (VM) from your on-premises environment.
  ##   body: JObject (required)
  var body_605384 = newJObject()
  if body != nil:
    body_605384 = body
  result = call_605383.call(nil, nil, nil, nil, body_605384)

var deleteAgent* = Call_DeleteAgent_605370(name: "deleteAgent",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.DeleteAgent",
                                        validator: validate_DeleteAgent_605371,
                                        base: "/", url: url_DeleteAgent_605372,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLocation_605385 = ref object of OpenApiRestCall_604658
proc url_DeleteLocation_605387(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLocation_605386(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes the configuration of a location used by AWS DataSync. 
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
      "FmrsService.DeleteLocation"))
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

proc call*(call_605397: Call_DeleteLocation_605385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the configuration of a location used by AWS DataSync. 
  ## 
  let valid = call_605397.validator(path, query, header, formData, body)
  let scheme = call_605397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605397.url(scheme.get, call_605397.host, call_605397.base,
                         call_605397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605397, url, valid)

proc call*(call_605398: Call_DeleteLocation_605385; body: JsonNode): Recallable =
  ## deleteLocation
  ## Deletes the configuration of a location used by AWS DataSync. 
  ##   body: JObject (required)
  var body_605399 = newJObject()
  if body != nil:
    body_605399 = body
  result = call_605398.call(nil, nil, nil, nil, body_605399)

var deleteLocation* = Call_DeleteLocation_605385(name: "deleteLocation",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DeleteLocation",
    validator: validate_DeleteLocation_605386, base: "/", url: url_DeleteLocation_605387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTask_605400 = ref object of OpenApiRestCall_604658
proc url_DeleteTask_605402(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTask_605401(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a task.
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
  valid_605403 = validateParameter(valid_605403, JString, required = true,
                                 default = newJString("FmrsService.DeleteTask"))
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

proc call*(call_605412: Call_DeleteTask_605400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a task.
  ## 
  let valid = call_605412.validator(path, query, header, formData, body)
  let scheme = call_605412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605412.url(scheme.get, call_605412.host, call_605412.base,
                         call_605412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605412, url, valid)

proc call*(call_605413: Call_DeleteTask_605400; body: JsonNode): Recallable =
  ## deleteTask
  ## Deletes a task.
  ##   body: JObject (required)
  var body_605414 = newJObject()
  if body != nil:
    body_605414 = body
  result = call_605413.call(nil, nil, nil, nil, body_605414)

var deleteTask* = Call_DeleteTask_605400(name: "deleteTask",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.DeleteTask",
                                      validator: validate_DeleteTask_605401,
                                      base: "/", url: url_DeleteTask_605402,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAgent_605415 = ref object of OpenApiRestCall_604658
proc url_DescribeAgent_605417(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeAgent_605416(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns metadata such as the name, the network interfaces, and the status (that is, whether the agent is running or not) for an agent. To specify which agent to describe, use the Amazon Resource Name (ARN) of the agent in your request. 
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
      "FmrsService.DescribeAgent"))
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

proc call*(call_605427: Call_DescribeAgent_605415; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata such as the name, the network interfaces, and the status (that is, whether the agent is running or not) for an agent. To specify which agent to describe, use the Amazon Resource Name (ARN) of the agent in your request. 
  ## 
  let valid = call_605427.validator(path, query, header, formData, body)
  let scheme = call_605427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605427.url(scheme.get, call_605427.host, call_605427.base,
                         call_605427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605427, url, valid)

proc call*(call_605428: Call_DescribeAgent_605415; body: JsonNode): Recallable =
  ## describeAgent
  ## Returns metadata such as the name, the network interfaces, and the status (that is, whether the agent is running or not) for an agent. To specify which agent to describe, use the Amazon Resource Name (ARN) of the agent in your request. 
  ##   body: JObject (required)
  var body_605429 = newJObject()
  if body != nil:
    body_605429 = body
  result = call_605428.call(nil, nil, nil, nil, body_605429)

var describeAgent* = Call_DescribeAgent_605415(name: "describeAgent",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeAgent",
    validator: validate_DescribeAgent_605416, base: "/", url: url_DescribeAgent_605417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationEfs_605430 = ref object of OpenApiRestCall_604658
proc url_DescribeLocationEfs_605432(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLocationEfs_605431(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns metadata, such as the path information about an Amazon EFS location.
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
      "FmrsService.DescribeLocationEfs"))
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

proc call*(call_605442: Call_DescribeLocationEfs_605430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as the path information about an Amazon EFS location.
  ## 
  let valid = call_605442.validator(path, query, header, formData, body)
  let scheme = call_605442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605442.url(scheme.get, call_605442.host, call_605442.base,
                         call_605442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605442, url, valid)

proc call*(call_605443: Call_DescribeLocationEfs_605430; body: JsonNode): Recallable =
  ## describeLocationEfs
  ## Returns metadata, such as the path information about an Amazon EFS location.
  ##   body: JObject (required)
  var body_605444 = newJObject()
  if body != nil:
    body_605444 = body
  result = call_605443.call(nil, nil, nil, nil, body_605444)

var describeLocationEfs* = Call_DescribeLocationEfs_605430(
    name: "describeLocationEfs", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationEfs",
    validator: validate_DescribeLocationEfs_605431, base: "/",
    url: url_DescribeLocationEfs_605432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationFsxWindows_605445 = ref object of OpenApiRestCall_604658
proc url_DescribeLocationFsxWindows_605447(protocol: Scheme; host: string;
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

proc validate_DescribeLocationFsxWindows_605446(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns metadata, such as the path information about an Amazon FSx for Windows location.
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
      "FmrsService.DescribeLocationFsxWindows"))
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

proc call*(call_605457: Call_DescribeLocationFsxWindows_605445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as the path information about an Amazon FSx for Windows location.
  ## 
  let valid = call_605457.validator(path, query, header, formData, body)
  let scheme = call_605457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605457.url(scheme.get, call_605457.host, call_605457.base,
                         call_605457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605457, url, valid)

proc call*(call_605458: Call_DescribeLocationFsxWindows_605445; body: JsonNode): Recallable =
  ## describeLocationFsxWindows
  ## Returns metadata, such as the path information about an Amazon FSx for Windows location.
  ##   body: JObject (required)
  var body_605459 = newJObject()
  if body != nil:
    body_605459 = body
  result = call_605458.call(nil, nil, nil, nil, body_605459)

var describeLocationFsxWindows* = Call_DescribeLocationFsxWindows_605445(
    name: "describeLocationFsxWindows", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationFsxWindows",
    validator: validate_DescribeLocationFsxWindows_605446, base: "/",
    url: url_DescribeLocationFsxWindows_605447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationNfs_605460 = ref object of OpenApiRestCall_604658
proc url_DescribeLocationNfs_605462(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLocationNfs_605461(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns metadata, such as the path information, about a NFS location.
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
      "FmrsService.DescribeLocationNfs"))
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

proc call*(call_605472: Call_DescribeLocationNfs_605460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as the path information, about a NFS location.
  ## 
  let valid = call_605472.validator(path, query, header, formData, body)
  let scheme = call_605472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605472.url(scheme.get, call_605472.host, call_605472.base,
                         call_605472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605472, url, valid)

proc call*(call_605473: Call_DescribeLocationNfs_605460; body: JsonNode): Recallable =
  ## describeLocationNfs
  ## Returns metadata, such as the path information, about a NFS location.
  ##   body: JObject (required)
  var body_605474 = newJObject()
  if body != nil:
    body_605474 = body
  result = call_605473.call(nil, nil, nil, nil, body_605474)

var describeLocationNfs* = Call_DescribeLocationNfs_605460(
    name: "describeLocationNfs", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationNfs",
    validator: validate_DescribeLocationNfs_605461, base: "/",
    url: url_DescribeLocationNfs_605462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationS3_605475 = ref object of OpenApiRestCall_604658
proc url_DescribeLocationS3_605477(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLocationS3_605476(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns metadata, such as bucket name, about an Amazon S3 bucket location.
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
      "FmrsService.DescribeLocationS3"))
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

proc call*(call_605487: Call_DescribeLocationS3_605475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as bucket name, about an Amazon S3 bucket location.
  ## 
  let valid = call_605487.validator(path, query, header, formData, body)
  let scheme = call_605487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605487.url(scheme.get, call_605487.host, call_605487.base,
                         call_605487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605487, url, valid)

proc call*(call_605488: Call_DescribeLocationS3_605475; body: JsonNode): Recallable =
  ## describeLocationS3
  ## Returns metadata, such as bucket name, about an Amazon S3 bucket location.
  ##   body: JObject (required)
  var body_605489 = newJObject()
  if body != nil:
    body_605489 = body
  result = call_605488.call(nil, nil, nil, nil, body_605489)

var describeLocationS3* = Call_DescribeLocationS3_605475(
    name: "describeLocationS3", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationS3",
    validator: validate_DescribeLocationS3_605476, base: "/",
    url: url_DescribeLocationS3_605477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationSmb_605490 = ref object of OpenApiRestCall_604658
proc url_DescribeLocationSmb_605492(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLocationSmb_605491(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns metadata, such as the path and user information about a SMB location.
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
      "FmrsService.DescribeLocationSmb"))
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

proc call*(call_605502: Call_DescribeLocationSmb_605490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as the path and user information about a SMB location.
  ## 
  let valid = call_605502.validator(path, query, header, formData, body)
  let scheme = call_605502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605502.url(scheme.get, call_605502.host, call_605502.base,
                         call_605502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605502, url, valid)

proc call*(call_605503: Call_DescribeLocationSmb_605490; body: JsonNode): Recallable =
  ## describeLocationSmb
  ## Returns metadata, such as the path and user information about a SMB location.
  ##   body: JObject (required)
  var body_605504 = newJObject()
  if body != nil:
    body_605504 = body
  result = call_605503.call(nil, nil, nil, nil, body_605504)

var describeLocationSmb* = Call_DescribeLocationSmb_605490(
    name: "describeLocationSmb", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationSmb",
    validator: validate_DescribeLocationSmb_605491, base: "/",
    url: url_DescribeLocationSmb_605492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTask_605505 = ref object of OpenApiRestCall_604658
proc url_DescribeTask_605507(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTask_605506(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns metadata about a task.
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
      "FmrsService.DescribeTask"))
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

proc call*(call_605517: Call_DescribeTask_605505; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about a task.
  ## 
  let valid = call_605517.validator(path, query, header, formData, body)
  let scheme = call_605517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605517.url(scheme.get, call_605517.host, call_605517.base,
                         call_605517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605517, url, valid)

proc call*(call_605518: Call_DescribeTask_605505; body: JsonNode): Recallable =
  ## describeTask
  ## Returns metadata about a task.
  ##   body: JObject (required)
  var body_605519 = newJObject()
  if body != nil:
    body_605519 = body
  result = call_605518.call(nil, nil, nil, nil, body_605519)

var describeTask* = Call_DescribeTask_605505(name: "describeTask",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeTask",
    validator: validate_DescribeTask_605506, base: "/", url: url_DescribeTask_605507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTaskExecution_605520 = ref object of OpenApiRestCall_604658
proc url_DescribeTaskExecution_605522(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTaskExecution_605521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns detailed metadata about a task that is being executed.
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
      "FmrsService.DescribeTaskExecution"))
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

proc call*(call_605532: Call_DescribeTaskExecution_605520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed metadata about a task that is being executed.
  ## 
  let valid = call_605532.validator(path, query, header, formData, body)
  let scheme = call_605532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605532.url(scheme.get, call_605532.host, call_605532.base,
                         call_605532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605532, url, valid)

proc call*(call_605533: Call_DescribeTaskExecution_605520; body: JsonNode): Recallable =
  ## describeTaskExecution
  ## Returns detailed metadata about a task that is being executed.
  ##   body: JObject (required)
  var body_605534 = newJObject()
  if body != nil:
    body_605534 = body
  result = call_605533.call(nil, nil, nil, nil, body_605534)

var describeTaskExecution* = Call_DescribeTaskExecution_605520(
    name: "describeTaskExecution", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeTaskExecution",
    validator: validate_DescribeTaskExecution_605521, base: "/",
    url: url_DescribeTaskExecution_605522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAgents_605535 = ref object of OpenApiRestCall_604658
proc url_ListAgents_605537(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListAgents_605536(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of agents owned by an AWS account in the AWS Region specified in the request. The returned list is ordered by agent Amazon Resource Name (ARN).</p> <p>By default, this operation returns a maximum of 100 agents. This operation supports pagination that enables you to optionally reduce the number of agents returned in a response.</p> <p>If you have more agents than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a marker that you can specify in your next request to fetch the next page of agents.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_605538 = query.getOrDefault("MaxResults")
  valid_605538 = validateParameter(valid_605538, JString, required = false,
                                 default = nil)
  if valid_605538 != nil:
    section.add "MaxResults", valid_605538
  var valid_605539 = query.getOrDefault("NextToken")
  valid_605539 = validateParameter(valid_605539, JString, required = false,
                                 default = nil)
  if valid_605539 != nil:
    section.add "NextToken", valid_605539
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
  valid_605540 = validateParameter(valid_605540, JString, required = true,
                                 default = newJString("FmrsService.ListAgents"))
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

proc call*(call_605549: Call_ListAgents_605535; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of agents owned by an AWS account in the AWS Region specified in the request. The returned list is ordered by agent Amazon Resource Name (ARN).</p> <p>By default, this operation returns a maximum of 100 agents. This operation supports pagination that enables you to optionally reduce the number of agents returned in a response.</p> <p>If you have more agents than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a marker that you can specify in your next request to fetch the next page of agents.</p>
  ## 
  let valid = call_605549.validator(path, query, header, formData, body)
  let scheme = call_605549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605549.url(scheme.get, call_605549.host, call_605549.base,
                         call_605549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605549, url, valid)

proc call*(call_605550: Call_ListAgents_605535; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAgents
  ## <p>Returns a list of agents owned by an AWS account in the AWS Region specified in the request. The returned list is ordered by agent Amazon Resource Name (ARN).</p> <p>By default, this operation returns a maximum of 100 agents. This operation supports pagination that enables you to optionally reduce the number of agents returned in a response.</p> <p>If you have more agents than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a marker that you can specify in your next request to fetch the next page of agents.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605551 = newJObject()
  var body_605552 = newJObject()
  add(query_605551, "MaxResults", newJString(MaxResults))
  add(query_605551, "NextToken", newJString(NextToken))
  if body != nil:
    body_605552 = body
  result = call_605550.call(nil, query_605551, nil, nil, body_605552)

var listAgents* = Call_ListAgents_605535(name: "listAgents",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.ListAgents",
                                      validator: validate_ListAgents_605536,
                                      base: "/", url: url_ListAgents_605537,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLocations_605554 = ref object of OpenApiRestCall_604658
proc url_ListLocations_605556(protocol: Scheme; host: string; base: string;
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

proc validate_ListLocations_605555(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a lists of source and destination locations.</p> <p>If you have more locations than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a token that you can specify in your next request to fetch the next page of locations.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_605557 = query.getOrDefault("MaxResults")
  valid_605557 = validateParameter(valid_605557, JString, required = false,
                                 default = nil)
  if valid_605557 != nil:
    section.add "MaxResults", valid_605557
  var valid_605558 = query.getOrDefault("NextToken")
  valid_605558 = validateParameter(valid_605558, JString, required = false,
                                 default = nil)
  if valid_605558 != nil:
    section.add "NextToken", valid_605558
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
      "FmrsService.ListLocations"))
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

proc call*(call_605568: Call_ListLocations_605554; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a lists of source and destination locations.</p> <p>If you have more locations than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a token that you can specify in your next request to fetch the next page of locations.</p>
  ## 
  let valid = call_605568.validator(path, query, header, formData, body)
  let scheme = call_605568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605568.url(scheme.get, call_605568.host, call_605568.base,
                         call_605568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605568, url, valid)

proc call*(call_605569: Call_ListLocations_605554; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLocations
  ## <p>Returns a lists of source and destination locations.</p> <p>If you have more locations than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a token that you can specify in your next request to fetch the next page of locations.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605570 = newJObject()
  var body_605571 = newJObject()
  add(query_605570, "MaxResults", newJString(MaxResults))
  add(query_605570, "NextToken", newJString(NextToken))
  if body != nil:
    body_605571 = body
  result = call_605569.call(nil, query_605570, nil, nil, body_605571)

var listLocations* = Call_ListLocations_605554(name: "listLocations",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.ListLocations",
    validator: validate_ListLocations_605555, base: "/", url: url_ListLocations_605556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_605572 = ref object of OpenApiRestCall_604658
proc url_ListTagsForResource_605574(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_605573(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns all the tags associated with a specified resources. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_605575 = query.getOrDefault("MaxResults")
  valid_605575 = validateParameter(valid_605575, JString, required = false,
                                 default = nil)
  if valid_605575 != nil:
    section.add "MaxResults", valid_605575
  var valid_605576 = query.getOrDefault("NextToken")
  valid_605576 = validateParameter(valid_605576, JString, required = false,
                                 default = nil)
  if valid_605576 != nil:
    section.add "NextToken", valid_605576
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
      "FmrsService.ListTagsForResource"))
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

proc call*(call_605586: Call_ListTagsForResource_605572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all the tags associated with a specified resources. 
  ## 
  let valid = call_605586.validator(path, query, header, formData, body)
  let scheme = call_605586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605586.url(scheme.get, call_605586.host, call_605586.base,
                         call_605586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605586, url, valid)

proc call*(call_605587: Call_ListTagsForResource_605572; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Returns all the tags associated with a specified resources. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605588 = newJObject()
  var body_605589 = newJObject()
  add(query_605588, "MaxResults", newJString(MaxResults))
  add(query_605588, "NextToken", newJString(NextToken))
  if body != nil:
    body_605589 = body
  result = call_605587.call(nil, query_605588, nil, nil, body_605589)

var listTagsForResource* = Call_ListTagsForResource_605572(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.ListTagsForResource",
    validator: validate_ListTagsForResource_605573, base: "/",
    url: url_ListTagsForResource_605574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTaskExecutions_605590 = ref object of OpenApiRestCall_604658
proc url_ListTaskExecutions_605592(protocol: Scheme; host: string; base: string;
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

proc validate_ListTaskExecutions_605591(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of executed tasks.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_605593 = query.getOrDefault("MaxResults")
  valid_605593 = validateParameter(valid_605593, JString, required = false,
                                 default = nil)
  if valid_605593 != nil:
    section.add "MaxResults", valid_605593
  var valid_605594 = query.getOrDefault("NextToken")
  valid_605594 = validateParameter(valid_605594, JString, required = false,
                                 default = nil)
  if valid_605594 != nil:
    section.add "NextToken", valid_605594
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
      "FmrsService.ListTaskExecutions"))
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

proc call*(call_605604: Call_ListTaskExecutions_605590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of executed tasks.
  ## 
  let valid = call_605604.validator(path, query, header, formData, body)
  let scheme = call_605604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605604.url(scheme.get, call_605604.host, call_605604.base,
                         call_605604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605604, url, valid)

proc call*(call_605605: Call_ListTaskExecutions_605590; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTaskExecutions
  ## Returns a list of executed tasks.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605606 = newJObject()
  var body_605607 = newJObject()
  add(query_605606, "MaxResults", newJString(MaxResults))
  add(query_605606, "NextToken", newJString(NextToken))
  if body != nil:
    body_605607 = body
  result = call_605605.call(nil, query_605606, nil, nil, body_605607)

var listTaskExecutions* = Call_ListTaskExecutions_605590(
    name: "listTaskExecutions", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.ListTaskExecutions",
    validator: validate_ListTaskExecutions_605591, base: "/",
    url: url_ListTaskExecutions_605592, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTasks_605608 = ref object of OpenApiRestCall_604658
proc url_ListTasks_605610(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTasks_605609(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all the tasks.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_605611 = query.getOrDefault("MaxResults")
  valid_605611 = validateParameter(valid_605611, JString, required = false,
                                 default = nil)
  if valid_605611 != nil:
    section.add "MaxResults", valid_605611
  var valid_605612 = query.getOrDefault("NextToken")
  valid_605612 = validateParameter(valid_605612, JString, required = false,
                                 default = nil)
  if valid_605612 != nil:
    section.add "NextToken", valid_605612
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
  valid_605613 = validateParameter(valid_605613, JString, required = true,
                                 default = newJString("FmrsService.ListTasks"))
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

proc call*(call_605622: Call_ListTasks_605608; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all the tasks.
  ## 
  let valid = call_605622.validator(path, query, header, formData, body)
  let scheme = call_605622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605622.url(scheme.get, call_605622.host, call_605622.base,
                         call_605622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605622, url, valid)

proc call*(call_605623: Call_ListTasks_605608; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTasks
  ## Returns a list of all the tasks.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_605624 = newJObject()
  var body_605625 = newJObject()
  add(query_605624, "MaxResults", newJString(MaxResults))
  add(query_605624, "NextToken", newJString(NextToken))
  if body != nil:
    body_605625 = body
  result = call_605623.call(nil, query_605624, nil, nil, body_605625)

var listTasks* = Call_ListTasks_605608(name: "listTasks", meth: HttpMethod.HttpPost,
                                    host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.ListTasks",
                                    validator: validate_ListTasks_605609,
                                    base: "/", url: url_ListTasks_605610,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTaskExecution_605626 = ref object of OpenApiRestCall_604658
proc url_StartTaskExecution_605628(protocol: Scheme; host: string; base: string;
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

proc validate_StartTaskExecution_605627(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Starts a specific invocation of a task. A <code>TaskExecution</code> value represents an individual run of a task. Each task can have at most one <code>TaskExecution</code> at a time.</p> <p> <code>TaskExecution</code> has the following transition phases: INITIALIZING | PREPARING | TRANSFERRING | VERIFYING | SUCCESS/FAILURE. </p> <p>For detailed information, see the Task Execution section in the Components and Terminology topic in the <i>AWS DataSync User Guide</i>.</p>
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
      "FmrsService.StartTaskExecution"))
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

proc call*(call_605638: Call_StartTaskExecution_605626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a specific invocation of a task. A <code>TaskExecution</code> value represents an individual run of a task. Each task can have at most one <code>TaskExecution</code> at a time.</p> <p> <code>TaskExecution</code> has the following transition phases: INITIALIZING | PREPARING | TRANSFERRING | VERIFYING | SUCCESS/FAILURE. </p> <p>For detailed information, see the Task Execution section in the Components and Terminology topic in the <i>AWS DataSync User Guide</i>.</p>
  ## 
  let valid = call_605638.validator(path, query, header, formData, body)
  let scheme = call_605638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605638.url(scheme.get, call_605638.host, call_605638.base,
                         call_605638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605638, url, valid)

proc call*(call_605639: Call_StartTaskExecution_605626; body: JsonNode): Recallable =
  ## startTaskExecution
  ## <p>Starts a specific invocation of a task. A <code>TaskExecution</code> value represents an individual run of a task. Each task can have at most one <code>TaskExecution</code> at a time.</p> <p> <code>TaskExecution</code> has the following transition phases: INITIALIZING | PREPARING | TRANSFERRING | VERIFYING | SUCCESS/FAILURE. </p> <p>For detailed information, see the Task Execution section in the Components and Terminology topic in the <i>AWS DataSync User Guide</i>.</p>
  ##   body: JObject (required)
  var body_605640 = newJObject()
  if body != nil:
    body_605640 = body
  result = call_605639.call(nil, nil, nil, nil, body_605640)

var startTaskExecution* = Call_StartTaskExecution_605626(
    name: "startTaskExecution", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.StartTaskExecution",
    validator: validate_StartTaskExecution_605627, base: "/",
    url: url_StartTaskExecution_605628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_605641 = ref object of OpenApiRestCall_604658
proc url_TagResource_605643(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_605642(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Applies a key-value pair to an AWS resource.
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
  var valid_605644 = header.getOrDefault("X-Amz-Target")
  valid_605644 = validateParameter(valid_605644, JString, required = true, default = newJString(
      "FmrsService.TagResource"))
  if valid_605644 != nil:
    section.add "X-Amz-Target", valid_605644
  var valid_605645 = header.getOrDefault("X-Amz-Signature")
  valid_605645 = validateParameter(valid_605645, JString, required = false,
                                 default = nil)
  if valid_605645 != nil:
    section.add "X-Amz-Signature", valid_605645
  var valid_605646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605646 = validateParameter(valid_605646, JString, required = false,
                                 default = nil)
  if valid_605646 != nil:
    section.add "X-Amz-Content-Sha256", valid_605646
  var valid_605647 = header.getOrDefault("X-Amz-Date")
  valid_605647 = validateParameter(valid_605647, JString, required = false,
                                 default = nil)
  if valid_605647 != nil:
    section.add "X-Amz-Date", valid_605647
  var valid_605648 = header.getOrDefault("X-Amz-Credential")
  valid_605648 = validateParameter(valid_605648, JString, required = false,
                                 default = nil)
  if valid_605648 != nil:
    section.add "X-Amz-Credential", valid_605648
  var valid_605649 = header.getOrDefault("X-Amz-Security-Token")
  valid_605649 = validateParameter(valid_605649, JString, required = false,
                                 default = nil)
  if valid_605649 != nil:
    section.add "X-Amz-Security-Token", valid_605649
  var valid_605650 = header.getOrDefault("X-Amz-Algorithm")
  valid_605650 = validateParameter(valid_605650, JString, required = false,
                                 default = nil)
  if valid_605650 != nil:
    section.add "X-Amz-Algorithm", valid_605650
  var valid_605651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605651 = validateParameter(valid_605651, JString, required = false,
                                 default = nil)
  if valid_605651 != nil:
    section.add "X-Amz-SignedHeaders", valid_605651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605653: Call_TagResource_605641; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a key-value pair to an AWS resource.
  ## 
  let valid = call_605653.validator(path, query, header, formData, body)
  let scheme = call_605653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605653.url(scheme.get, call_605653.host, call_605653.base,
                         call_605653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605653, url, valid)

proc call*(call_605654: Call_TagResource_605641; body: JsonNode): Recallable =
  ## tagResource
  ## Applies a key-value pair to an AWS resource.
  ##   body: JObject (required)
  var body_605655 = newJObject()
  if body != nil:
    body_605655 = body
  result = call_605654.call(nil, nil, nil, nil, body_605655)

var tagResource* = Call_TagResource_605641(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.TagResource",
                                        validator: validate_TagResource_605642,
                                        base: "/", url: url_TagResource_605643,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_605656 = ref object of OpenApiRestCall_604658
proc url_UntagResource_605658(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_605657(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a tag from an AWS resource.
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
  var valid_605659 = header.getOrDefault("X-Amz-Target")
  valid_605659 = validateParameter(valid_605659, JString, required = true, default = newJString(
      "FmrsService.UntagResource"))
  if valid_605659 != nil:
    section.add "X-Amz-Target", valid_605659
  var valid_605660 = header.getOrDefault("X-Amz-Signature")
  valid_605660 = validateParameter(valid_605660, JString, required = false,
                                 default = nil)
  if valid_605660 != nil:
    section.add "X-Amz-Signature", valid_605660
  var valid_605661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605661 = validateParameter(valid_605661, JString, required = false,
                                 default = nil)
  if valid_605661 != nil:
    section.add "X-Amz-Content-Sha256", valid_605661
  var valid_605662 = header.getOrDefault("X-Amz-Date")
  valid_605662 = validateParameter(valid_605662, JString, required = false,
                                 default = nil)
  if valid_605662 != nil:
    section.add "X-Amz-Date", valid_605662
  var valid_605663 = header.getOrDefault("X-Amz-Credential")
  valid_605663 = validateParameter(valid_605663, JString, required = false,
                                 default = nil)
  if valid_605663 != nil:
    section.add "X-Amz-Credential", valid_605663
  var valid_605664 = header.getOrDefault("X-Amz-Security-Token")
  valid_605664 = validateParameter(valid_605664, JString, required = false,
                                 default = nil)
  if valid_605664 != nil:
    section.add "X-Amz-Security-Token", valid_605664
  var valid_605665 = header.getOrDefault("X-Amz-Algorithm")
  valid_605665 = validateParameter(valid_605665, JString, required = false,
                                 default = nil)
  if valid_605665 != nil:
    section.add "X-Amz-Algorithm", valid_605665
  var valid_605666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605666 = validateParameter(valid_605666, JString, required = false,
                                 default = nil)
  if valid_605666 != nil:
    section.add "X-Amz-SignedHeaders", valid_605666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605668: Call_UntagResource_605656; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from an AWS resource.
  ## 
  let valid = call_605668.validator(path, query, header, formData, body)
  let scheme = call_605668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605668.url(scheme.get, call_605668.host, call_605668.base,
                         call_605668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605668, url, valid)

proc call*(call_605669: Call_UntagResource_605656; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from an AWS resource.
  ##   body: JObject (required)
  var body_605670 = newJObject()
  if body != nil:
    body_605670 = body
  result = call_605669.call(nil, nil, nil, nil, body_605670)

var untagResource* = Call_UntagResource_605656(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.UntagResource",
    validator: validate_UntagResource_605657, base: "/", url: url_UntagResource_605658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAgent_605671 = ref object of OpenApiRestCall_604658
proc url_UpdateAgent_605673(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAgent_605672(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the name of an agent.
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
  var valid_605674 = header.getOrDefault("X-Amz-Target")
  valid_605674 = validateParameter(valid_605674, JString, required = true, default = newJString(
      "FmrsService.UpdateAgent"))
  if valid_605674 != nil:
    section.add "X-Amz-Target", valid_605674
  var valid_605675 = header.getOrDefault("X-Amz-Signature")
  valid_605675 = validateParameter(valid_605675, JString, required = false,
                                 default = nil)
  if valid_605675 != nil:
    section.add "X-Amz-Signature", valid_605675
  var valid_605676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605676 = validateParameter(valid_605676, JString, required = false,
                                 default = nil)
  if valid_605676 != nil:
    section.add "X-Amz-Content-Sha256", valid_605676
  var valid_605677 = header.getOrDefault("X-Amz-Date")
  valid_605677 = validateParameter(valid_605677, JString, required = false,
                                 default = nil)
  if valid_605677 != nil:
    section.add "X-Amz-Date", valid_605677
  var valid_605678 = header.getOrDefault("X-Amz-Credential")
  valid_605678 = validateParameter(valid_605678, JString, required = false,
                                 default = nil)
  if valid_605678 != nil:
    section.add "X-Amz-Credential", valid_605678
  var valid_605679 = header.getOrDefault("X-Amz-Security-Token")
  valid_605679 = validateParameter(valid_605679, JString, required = false,
                                 default = nil)
  if valid_605679 != nil:
    section.add "X-Amz-Security-Token", valid_605679
  var valid_605680 = header.getOrDefault("X-Amz-Algorithm")
  valid_605680 = validateParameter(valid_605680, JString, required = false,
                                 default = nil)
  if valid_605680 != nil:
    section.add "X-Amz-Algorithm", valid_605680
  var valid_605681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605681 = validateParameter(valid_605681, JString, required = false,
                                 default = nil)
  if valid_605681 != nil:
    section.add "X-Amz-SignedHeaders", valid_605681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605683: Call_UpdateAgent_605671; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name of an agent.
  ## 
  let valid = call_605683.validator(path, query, header, formData, body)
  let scheme = call_605683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605683.url(scheme.get, call_605683.host, call_605683.base,
                         call_605683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605683, url, valid)

proc call*(call_605684: Call_UpdateAgent_605671; body: JsonNode): Recallable =
  ## updateAgent
  ## Updates the name of an agent.
  ##   body: JObject (required)
  var body_605685 = newJObject()
  if body != nil:
    body_605685 = body
  result = call_605684.call(nil, nil, nil, nil, body_605685)

var updateAgent* = Call_UpdateAgent_605671(name: "updateAgent",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.UpdateAgent",
                                        validator: validate_UpdateAgent_605672,
                                        base: "/", url: url_UpdateAgent_605673,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTask_605686 = ref object of OpenApiRestCall_604658
proc url_UpdateTask_605688(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateTask_605687(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the metadata associated with a task.
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
  var valid_605689 = header.getOrDefault("X-Amz-Target")
  valid_605689 = validateParameter(valid_605689, JString, required = true,
                                 default = newJString("FmrsService.UpdateTask"))
  if valid_605689 != nil:
    section.add "X-Amz-Target", valid_605689
  var valid_605690 = header.getOrDefault("X-Amz-Signature")
  valid_605690 = validateParameter(valid_605690, JString, required = false,
                                 default = nil)
  if valid_605690 != nil:
    section.add "X-Amz-Signature", valid_605690
  var valid_605691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605691 = validateParameter(valid_605691, JString, required = false,
                                 default = nil)
  if valid_605691 != nil:
    section.add "X-Amz-Content-Sha256", valid_605691
  var valid_605692 = header.getOrDefault("X-Amz-Date")
  valid_605692 = validateParameter(valid_605692, JString, required = false,
                                 default = nil)
  if valid_605692 != nil:
    section.add "X-Amz-Date", valid_605692
  var valid_605693 = header.getOrDefault("X-Amz-Credential")
  valid_605693 = validateParameter(valid_605693, JString, required = false,
                                 default = nil)
  if valid_605693 != nil:
    section.add "X-Amz-Credential", valid_605693
  var valid_605694 = header.getOrDefault("X-Amz-Security-Token")
  valid_605694 = validateParameter(valid_605694, JString, required = false,
                                 default = nil)
  if valid_605694 != nil:
    section.add "X-Amz-Security-Token", valid_605694
  var valid_605695 = header.getOrDefault("X-Amz-Algorithm")
  valid_605695 = validateParameter(valid_605695, JString, required = false,
                                 default = nil)
  if valid_605695 != nil:
    section.add "X-Amz-Algorithm", valid_605695
  var valid_605696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605696 = validateParameter(valid_605696, JString, required = false,
                                 default = nil)
  if valid_605696 != nil:
    section.add "X-Amz-SignedHeaders", valid_605696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605698: Call_UpdateTask_605686; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the metadata associated with a task.
  ## 
  let valid = call_605698.validator(path, query, header, formData, body)
  let scheme = call_605698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605698.url(scheme.get, call_605698.host, call_605698.base,
                         call_605698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605698, url, valid)

proc call*(call_605699: Call_UpdateTask_605686; body: JsonNode): Recallable =
  ## updateTask
  ## Updates the metadata associated with a task.
  ##   body: JObject (required)
  var body_605700 = newJObject()
  if body != nil:
    body_605700 = body
  result = call_605699.call(nil, nil, nil, nil, body_605700)

var updateTask* = Call_UpdateTask_605686(name: "updateTask",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.UpdateTask",
                                      validator: validate_UpdateTask_605687,
                                      base: "/", url: url_UpdateTask_605688,
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
