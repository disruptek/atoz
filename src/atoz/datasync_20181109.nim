
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelTaskExecution_593774 = ref object of OpenApiRestCall_593437
proc url_CancelTaskExecution_593776(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelTaskExecution_593775(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593903 = header.getOrDefault("X-Amz-Target")
  valid_593903 = validateParameter(valid_593903, JString, required = true, default = newJString(
      "FmrsService.CancelTaskExecution"))
  if valid_593903 != nil:
    section.add "X-Amz-Target", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Content-Sha256", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Algorithm")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Algorithm", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Signature")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Signature", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Credential")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Credential", valid_593908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_CancelTaskExecution_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels execution of a task. </p> <p>When you cancel a task execution, the transfer of some files are abruptly interrupted. The contents of files that are transferred to the destination might be incomplete or inconsistent with the source files. However, if you start a new task execution on the same task and you allow the task execution to complete, file content on the destination is complete and consistent. This applies to other unexpected failures that interrupt a task execution. In all of these cases, AWS DataSync successfully complete the transfer when you start the next task execution.</p>
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_CancelTaskExecution_593774; body: JsonNode): Recallable =
  ## cancelTaskExecution
  ## <p>Cancels execution of a task. </p> <p>When you cancel a task execution, the transfer of some files are abruptly interrupted. The contents of files that are transferred to the destination might be incomplete or inconsistent with the source files. However, if you start a new task execution on the same task and you allow the task execution to complete, file content on the destination is complete and consistent. This applies to other unexpected failures that interrupt a task execution. In all of these cases, AWS DataSync successfully complete the transfer when you start the next task execution.</p>
  ##   body: JObject (required)
  var body_594004 = newJObject()
  if body != nil:
    body_594004 = body
  result = call_594003.call(nil, nil, nil, nil, body_594004)

var cancelTaskExecution* = Call_CancelTaskExecution_593774(
    name: "cancelTaskExecution", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CancelTaskExecution",
    validator: validate_CancelTaskExecution_593775, base: "/",
    url: url_CancelTaskExecution_593776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAgent_594043 = ref object of OpenApiRestCall_593437
proc url_CreateAgent_594045(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAgent_594044(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Security-Token")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Security-Token", valid_594047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594048 = header.getOrDefault("X-Amz-Target")
  valid_594048 = validateParameter(valid_594048, JString, required = true, default = newJString(
      "FmrsService.CreateAgent"))
  if valid_594048 != nil:
    section.add "X-Amz-Target", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_CreateAgent_594043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Activates an AWS DataSync agent that you have deployed on your host. The activation process associates your agent with your account. In the activation process, you specify information such as the AWS Region that you want to activate the agent in. You activate the agent in the AWS Region where your target locations (in Amazon S3 or Amazon EFS) reside. Your tasks are created in this AWS Region.</p> <p>You can activate the agent in a VPC (Virtual private Cloud) or provide the agent access to a VPC endpoint so you can run tasks without going over the public Internet.</p> <p>You can use an agent for more than one location. If a task uses multiple agents, all of them need to have status AVAILABLE for the task to run. If you use multiple agents for a source location, the status of all the agents must be AVAILABLE for the task to run. </p> <p>Agents are automatically updated by AWS on a regular basis, using a mechanism that ensures minimal interruption to your tasks.</p> <p/>
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_CreateAgent_594043; body: JsonNode): Recallable =
  ## createAgent
  ## <p>Activates an AWS DataSync agent that you have deployed on your host. The activation process associates your agent with your account. In the activation process, you specify information such as the AWS Region that you want to activate the agent in. You activate the agent in the AWS Region where your target locations (in Amazon S3 or Amazon EFS) reside. Your tasks are created in this AWS Region.</p> <p>You can activate the agent in a VPC (Virtual private Cloud) or provide the agent access to a VPC endpoint so you can run tasks without going over the public Internet.</p> <p>You can use an agent for more than one location. If a task uses multiple agents, all of them need to have status AVAILABLE for the task to run. If you use multiple agents for a source location, the status of all the agents must be AVAILABLE for the task to run. </p> <p>Agents are automatically updated by AWS on a regular basis, using a mechanism that ensures minimal interruption to your tasks.</p> <p/>
  ##   body: JObject (required)
  var body_594057 = newJObject()
  if body != nil:
    body_594057 = body
  result = call_594056.call(nil, nil, nil, nil, body_594057)

var createAgent* = Call_CreateAgent_594043(name: "createAgent",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.CreateAgent",
                                        validator: validate_CreateAgent_594044,
                                        base: "/", url: url_CreateAgent_594045,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationEfs_594058 = ref object of OpenApiRestCall_593437
proc url_CreateLocationEfs_594060(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLocationEfs_594059(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594063 = header.getOrDefault("X-Amz-Target")
  valid_594063 = validateParameter(valid_594063, JString, required = true, default = newJString(
      "FmrsService.CreateLocationEfs"))
  if valid_594063 != nil:
    section.add "X-Amz-Target", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_CreateLocationEfs_594058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint for an Amazon EFS file system.
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_CreateLocationEfs_594058; body: JsonNode): Recallable =
  ## createLocationEfs
  ## Creates an endpoint for an Amazon EFS file system.
  ##   body: JObject (required)
  var body_594072 = newJObject()
  if body != nil:
    body_594072 = body
  result = call_594071.call(nil, nil, nil, nil, body_594072)

var createLocationEfs* = Call_CreateLocationEfs_594058(name: "createLocationEfs",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationEfs",
    validator: validate_CreateLocationEfs_594059, base: "/",
    url: url_CreateLocationEfs_594060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationNfs_594073 = ref object of OpenApiRestCall_593437
proc url_CreateLocationNfs_594075(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLocationNfs_594074(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an endpoint for a Network File System (NFS) file system.
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
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Security-Token")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Security-Token", valid_594077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594078 = header.getOrDefault("X-Amz-Target")
  valid_594078 = validateParameter(valid_594078, JString, required = true, default = newJString(
      "FmrsService.CreateLocationNfs"))
  if valid_594078 != nil:
    section.add "X-Amz-Target", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Credential")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Credential", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_CreateLocationNfs_594073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint for a Network File System (NFS) file system.
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_CreateLocationNfs_594073; body: JsonNode): Recallable =
  ## createLocationNfs
  ## Creates an endpoint for a Network File System (NFS) file system.
  ##   body: JObject (required)
  var body_594087 = newJObject()
  if body != nil:
    body_594087 = body
  result = call_594086.call(nil, nil, nil, nil, body_594087)

var createLocationNfs* = Call_CreateLocationNfs_594073(name: "createLocationNfs",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationNfs",
    validator: validate_CreateLocationNfs_594074, base: "/",
    url: url_CreateLocationNfs_594075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationS3_594088 = ref object of OpenApiRestCall_593437
proc url_CreateLocationS3_594090(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLocationS3_594089(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594093 = header.getOrDefault("X-Amz-Target")
  valid_594093 = validateParameter(valid_594093, JString, required = true, default = newJString(
      "FmrsService.CreateLocationS3"))
  if valid_594093 != nil:
    section.add "X-Amz-Target", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_CreateLocationS3_594088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for an Amazon S3 bucket.</p> <p>For AWS DataSync to access a destination S3 bucket, it needs an AWS Identity and Access Management (IAM) role that has the required permissions. You can set up the required permissions by creating an IAM policy that grants the required permissions and attaching the policy to the role. An example of such a policy is shown in the examples section.</p> <p>For more information, see https://docs.aws.amazon.com/datasync/latest/userguide/working-with-locations.html#create-s3-location in the <i>AWS DataSync User Guide.</i> </p>
  ## 
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_CreateLocationS3_594088; body: JsonNode): Recallable =
  ## createLocationS3
  ## <p>Creates an endpoint for an Amazon S3 bucket.</p> <p>For AWS DataSync to access a destination S3 bucket, it needs an AWS Identity and Access Management (IAM) role that has the required permissions. You can set up the required permissions by creating an IAM policy that grants the required permissions and attaching the policy to the role. An example of such a policy is shown in the examples section.</p> <p>For more information, see https://docs.aws.amazon.com/datasync/latest/userguide/working-with-locations.html#create-s3-location in the <i>AWS DataSync User Guide.</i> </p>
  ##   body: JObject (required)
  var body_594102 = newJObject()
  if body != nil:
    body_594102 = body
  result = call_594101.call(nil, nil, nil, nil, body_594102)

var createLocationS3* = Call_CreateLocationS3_594088(name: "createLocationS3",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationS3",
    validator: validate_CreateLocationS3_594089, base: "/",
    url: url_CreateLocationS3_594090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationSmb_594103 = ref object of OpenApiRestCall_593437
proc url_CreateLocationSmb_594105(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLocationSmb_594104(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an endpoint for a Server Message Block (SMB) file system.
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
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Security-Token")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Security-Token", valid_594107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594108 = header.getOrDefault("X-Amz-Target")
  valid_594108 = validateParameter(valid_594108, JString, required = true, default = newJString(
      "FmrsService.CreateLocationSmb"))
  if valid_594108 != nil:
    section.add "X-Amz-Target", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Signature")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Signature", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-SignedHeaders", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Credential")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Credential", valid_594113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_CreateLocationSmb_594103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint for a Server Message Block (SMB) file system.
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_CreateLocationSmb_594103; body: JsonNode): Recallable =
  ## createLocationSmb
  ## Creates an endpoint for a Server Message Block (SMB) file system.
  ##   body: JObject (required)
  var body_594117 = newJObject()
  if body != nil:
    body_594117 = body
  result = call_594116.call(nil, nil, nil, nil, body_594117)

var createLocationSmb* = Call_CreateLocationSmb_594103(name: "createLocationSmb",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationSmb",
    validator: validate_CreateLocationSmb_594104, base: "/",
    url: url_CreateLocationSmb_594105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTask_594118 = ref object of OpenApiRestCall_593437
proc url_CreateTask_594120(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTask_594119(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594121 = header.getOrDefault("X-Amz-Date")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Date", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Security-Token")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Security-Token", valid_594122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594123 = header.getOrDefault("X-Amz-Target")
  valid_594123 = validateParameter(valid_594123, JString, required = true,
                                 default = newJString("FmrsService.CreateTask"))
  if valid_594123 != nil:
    section.add "X-Amz-Target", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Content-Sha256", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Signature")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Signature", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-SignedHeaders", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_CreateTask_594118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a task. A task is a set of two locations (source and destination) and a set of Options that you use to control the behavior of a task. If you don't specify Options when you create a task, AWS DataSync populates them with service defaults.</p> <p>When you create a task, it first enters the CREATING state. During CREATING AWS DataSync attempts to mount the on-premises Network File System (NFS) location. The task transitions to the AVAILABLE state without waiting for the AWS location to become mounted. If required, AWS DataSync mounts the AWS location before each task execution.</p> <p>If an agent that is associated with a source (NFS) location goes offline, the task transitions to the UNAVAILABLE status. If the status of the task remains in the CREATING status for more than a few minutes, it means that your agent might be having trouble mounting the source NFS file system. Check the task's ErrorCode and ErrorDetail. Mount issues are often caused by either a misconfigured firewall or a mistyped NFS server host name.</p>
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_CreateTask_594118; body: JsonNode): Recallable =
  ## createTask
  ## <p>Creates a task. A task is a set of two locations (source and destination) and a set of Options that you use to control the behavior of a task. If you don't specify Options when you create a task, AWS DataSync populates them with service defaults.</p> <p>When you create a task, it first enters the CREATING state. During CREATING AWS DataSync attempts to mount the on-premises Network File System (NFS) location. The task transitions to the AVAILABLE state without waiting for the AWS location to become mounted. If required, AWS DataSync mounts the AWS location before each task execution.</p> <p>If an agent that is associated with a source (NFS) location goes offline, the task transitions to the UNAVAILABLE status. If the status of the task remains in the CREATING status for more than a few minutes, it means that your agent might be having trouble mounting the source NFS file system. Check the task's ErrorCode and ErrorDetail. Mount issues are often caused by either a misconfigured firewall or a mistyped NFS server host name.</p>
  ##   body: JObject (required)
  var body_594132 = newJObject()
  if body != nil:
    body_594132 = body
  result = call_594131.call(nil, nil, nil, nil, body_594132)

var createTask* = Call_CreateTask_594118(name: "createTask",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.CreateTask",
                                      validator: validate_CreateTask_594119,
                                      base: "/", url: url_CreateTask_594120,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAgent_594133 = ref object of OpenApiRestCall_593437
proc url_DeleteAgent_594135(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAgent_594134(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594136 = header.getOrDefault("X-Amz-Date")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Date", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Security-Token")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Security-Token", valid_594137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594138 = header.getOrDefault("X-Amz-Target")
  valid_594138 = validateParameter(valid_594138, JString, required = true, default = newJString(
      "FmrsService.DeleteAgent"))
  if valid_594138 != nil:
    section.add "X-Amz-Target", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Content-Sha256", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Signature")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Signature", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-SignedHeaders", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Credential")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Credential", valid_594143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594145: Call_DeleteAgent_594133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an agent. To specify which agent to delete, use the Amazon Resource Name (ARN) of the agent in your request. The operation disassociates the agent from your AWS account. However, it doesn't delete the agent virtual machine (VM) from your on-premises environment.
  ## 
  let valid = call_594145.validator(path, query, header, formData, body)
  let scheme = call_594145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594145.url(scheme.get, call_594145.host, call_594145.base,
                         call_594145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594145, url, valid)

proc call*(call_594146: Call_DeleteAgent_594133; body: JsonNode): Recallable =
  ## deleteAgent
  ## Deletes an agent. To specify which agent to delete, use the Amazon Resource Name (ARN) of the agent in your request. The operation disassociates the agent from your AWS account. However, it doesn't delete the agent virtual machine (VM) from your on-premises environment.
  ##   body: JObject (required)
  var body_594147 = newJObject()
  if body != nil:
    body_594147 = body
  result = call_594146.call(nil, nil, nil, nil, body_594147)

var deleteAgent* = Call_DeleteAgent_594133(name: "deleteAgent",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.DeleteAgent",
                                        validator: validate_DeleteAgent_594134,
                                        base: "/", url: url_DeleteAgent_594135,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLocation_594148 = ref object of OpenApiRestCall_593437
proc url_DeleteLocation_594150(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteLocation_594149(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594151 = header.getOrDefault("X-Amz-Date")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Date", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Security-Token")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Security-Token", valid_594152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594153 = header.getOrDefault("X-Amz-Target")
  valid_594153 = validateParameter(valid_594153, JString, required = true, default = newJString(
      "FmrsService.DeleteLocation"))
  if valid_594153 != nil:
    section.add "X-Amz-Target", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_DeleteLocation_594148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the configuration of a location used by AWS DataSync. 
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_DeleteLocation_594148; body: JsonNode): Recallable =
  ## deleteLocation
  ## Deletes the configuration of a location used by AWS DataSync. 
  ##   body: JObject (required)
  var body_594162 = newJObject()
  if body != nil:
    body_594162 = body
  result = call_594161.call(nil, nil, nil, nil, body_594162)

var deleteLocation* = Call_DeleteLocation_594148(name: "deleteLocation",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DeleteLocation",
    validator: validate_DeleteLocation_594149, base: "/", url: url_DeleteLocation_594150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTask_594163 = ref object of OpenApiRestCall_593437
proc url_DeleteTask_594165(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTask_594164(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594166 = header.getOrDefault("X-Amz-Date")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Date", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594168 = header.getOrDefault("X-Amz-Target")
  valid_594168 = validateParameter(valid_594168, JString, required = true,
                                 default = newJString("FmrsService.DeleteTask"))
  if valid_594168 != nil:
    section.add "X-Amz-Target", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Content-Sha256", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Signature")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Signature", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-SignedHeaders", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Credential")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Credential", valid_594173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_DeleteTask_594163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a task.
  ## 
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_DeleteTask_594163; body: JsonNode): Recallable =
  ## deleteTask
  ## Deletes a task.
  ##   body: JObject (required)
  var body_594177 = newJObject()
  if body != nil:
    body_594177 = body
  result = call_594176.call(nil, nil, nil, nil, body_594177)

var deleteTask* = Call_DeleteTask_594163(name: "deleteTask",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.DeleteTask",
                                      validator: validate_DeleteTask_594164,
                                      base: "/", url: url_DeleteTask_594165,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAgent_594178 = ref object of OpenApiRestCall_593437
proc url_DescribeAgent_594180(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAgent_594179(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594181 = header.getOrDefault("X-Amz-Date")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Date", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Security-Token")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Security-Token", valid_594182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594183 = header.getOrDefault("X-Amz-Target")
  valid_594183 = validateParameter(valid_594183, JString, required = true, default = newJString(
      "FmrsService.DescribeAgent"))
  if valid_594183 != nil:
    section.add "X-Amz-Target", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Content-Sha256", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Signature")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Signature", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-SignedHeaders", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Credential")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Credential", valid_594188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594190: Call_DescribeAgent_594178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata such as the name, the network interfaces, and the status (that is, whether the agent is running or not) for an agent. To specify which agent to describe, use the Amazon Resource Name (ARN) of the agent in your request. 
  ## 
  let valid = call_594190.validator(path, query, header, formData, body)
  let scheme = call_594190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594190.url(scheme.get, call_594190.host, call_594190.base,
                         call_594190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594190, url, valid)

proc call*(call_594191: Call_DescribeAgent_594178; body: JsonNode): Recallable =
  ## describeAgent
  ## Returns metadata such as the name, the network interfaces, and the status (that is, whether the agent is running or not) for an agent. To specify which agent to describe, use the Amazon Resource Name (ARN) of the agent in your request. 
  ##   body: JObject (required)
  var body_594192 = newJObject()
  if body != nil:
    body_594192 = body
  result = call_594191.call(nil, nil, nil, nil, body_594192)

var describeAgent* = Call_DescribeAgent_594178(name: "describeAgent",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeAgent",
    validator: validate_DescribeAgent_594179, base: "/", url: url_DescribeAgent_594180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationEfs_594193 = ref object of OpenApiRestCall_593437
proc url_DescribeLocationEfs_594195(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLocationEfs_594194(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594196 = header.getOrDefault("X-Amz-Date")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Date", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Security-Token")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Security-Token", valid_594197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594198 = header.getOrDefault("X-Amz-Target")
  valid_594198 = validateParameter(valid_594198, JString, required = true, default = newJString(
      "FmrsService.DescribeLocationEfs"))
  if valid_594198 != nil:
    section.add "X-Amz-Target", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_DescribeLocationEfs_594193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as the path information about an Amazon EFS location.
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_DescribeLocationEfs_594193; body: JsonNode): Recallable =
  ## describeLocationEfs
  ## Returns metadata, such as the path information about an Amazon EFS location.
  ##   body: JObject (required)
  var body_594207 = newJObject()
  if body != nil:
    body_594207 = body
  result = call_594206.call(nil, nil, nil, nil, body_594207)

var describeLocationEfs* = Call_DescribeLocationEfs_594193(
    name: "describeLocationEfs", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationEfs",
    validator: validate_DescribeLocationEfs_594194, base: "/",
    url: url_DescribeLocationEfs_594195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationNfs_594208 = ref object of OpenApiRestCall_593437
proc url_DescribeLocationNfs_594210(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLocationNfs_594209(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594211 = header.getOrDefault("X-Amz-Date")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Date", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Security-Token")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Security-Token", valid_594212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594213 = header.getOrDefault("X-Amz-Target")
  valid_594213 = validateParameter(valid_594213, JString, required = true, default = newJString(
      "FmrsService.DescribeLocationNfs"))
  if valid_594213 != nil:
    section.add "X-Amz-Target", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Content-Sha256", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Signature")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Signature", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-SignedHeaders", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Credential")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Credential", valid_594218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594220: Call_DescribeLocationNfs_594208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as the path information, about a NFS location.
  ## 
  let valid = call_594220.validator(path, query, header, formData, body)
  let scheme = call_594220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594220.url(scheme.get, call_594220.host, call_594220.base,
                         call_594220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594220, url, valid)

proc call*(call_594221: Call_DescribeLocationNfs_594208; body: JsonNode): Recallable =
  ## describeLocationNfs
  ## Returns metadata, such as the path information, about a NFS location.
  ##   body: JObject (required)
  var body_594222 = newJObject()
  if body != nil:
    body_594222 = body
  result = call_594221.call(nil, nil, nil, nil, body_594222)

var describeLocationNfs* = Call_DescribeLocationNfs_594208(
    name: "describeLocationNfs", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationNfs",
    validator: validate_DescribeLocationNfs_594209, base: "/",
    url: url_DescribeLocationNfs_594210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationS3_594223 = ref object of OpenApiRestCall_593437
proc url_DescribeLocationS3_594225(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLocationS3_594224(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594226 = header.getOrDefault("X-Amz-Date")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Date", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Security-Token")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Security-Token", valid_594227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594228 = header.getOrDefault("X-Amz-Target")
  valid_594228 = validateParameter(valid_594228, JString, required = true, default = newJString(
      "FmrsService.DescribeLocationS3"))
  if valid_594228 != nil:
    section.add "X-Amz-Target", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Content-Sha256", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Signature")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Signature", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-SignedHeaders", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Credential")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Credential", valid_594233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594235: Call_DescribeLocationS3_594223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as bucket name, about an Amazon S3 bucket location.
  ## 
  let valid = call_594235.validator(path, query, header, formData, body)
  let scheme = call_594235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594235.url(scheme.get, call_594235.host, call_594235.base,
                         call_594235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594235, url, valid)

proc call*(call_594236: Call_DescribeLocationS3_594223; body: JsonNode): Recallable =
  ## describeLocationS3
  ## Returns metadata, such as bucket name, about an Amazon S3 bucket location.
  ##   body: JObject (required)
  var body_594237 = newJObject()
  if body != nil:
    body_594237 = body
  result = call_594236.call(nil, nil, nil, nil, body_594237)

var describeLocationS3* = Call_DescribeLocationS3_594223(
    name: "describeLocationS3", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationS3",
    validator: validate_DescribeLocationS3_594224, base: "/",
    url: url_DescribeLocationS3_594225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationSmb_594238 = ref object of OpenApiRestCall_593437
proc url_DescribeLocationSmb_594240(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLocationSmb_594239(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594241 = header.getOrDefault("X-Amz-Date")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Date", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Security-Token")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Security-Token", valid_594242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594243 = header.getOrDefault("X-Amz-Target")
  valid_594243 = validateParameter(valid_594243, JString, required = true, default = newJString(
      "FmrsService.DescribeLocationSmb"))
  if valid_594243 != nil:
    section.add "X-Amz-Target", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Content-Sha256", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Algorithm")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Algorithm", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Signature")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Signature", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-SignedHeaders", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Credential")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Credential", valid_594248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594250: Call_DescribeLocationSmb_594238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as the path and user information about a SMB location.
  ## 
  let valid = call_594250.validator(path, query, header, formData, body)
  let scheme = call_594250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594250.url(scheme.get, call_594250.host, call_594250.base,
                         call_594250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594250, url, valid)

proc call*(call_594251: Call_DescribeLocationSmb_594238; body: JsonNode): Recallable =
  ## describeLocationSmb
  ## Returns metadata, such as the path and user information about a SMB location.
  ##   body: JObject (required)
  var body_594252 = newJObject()
  if body != nil:
    body_594252 = body
  result = call_594251.call(nil, nil, nil, nil, body_594252)

var describeLocationSmb* = Call_DescribeLocationSmb_594238(
    name: "describeLocationSmb", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationSmb",
    validator: validate_DescribeLocationSmb_594239, base: "/",
    url: url_DescribeLocationSmb_594240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTask_594253 = ref object of OpenApiRestCall_593437
proc url_DescribeTask_594255(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTask_594254(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594256 = header.getOrDefault("X-Amz-Date")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Date", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Security-Token")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Security-Token", valid_594257
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594258 = header.getOrDefault("X-Amz-Target")
  valid_594258 = validateParameter(valid_594258, JString, required = true, default = newJString(
      "FmrsService.DescribeTask"))
  if valid_594258 != nil:
    section.add "X-Amz-Target", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Content-Sha256", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Algorithm")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Algorithm", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Signature")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Signature", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-SignedHeaders", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Credential")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Credential", valid_594263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594265: Call_DescribeTask_594253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about a task.
  ## 
  let valid = call_594265.validator(path, query, header, formData, body)
  let scheme = call_594265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594265.url(scheme.get, call_594265.host, call_594265.base,
                         call_594265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594265, url, valid)

proc call*(call_594266: Call_DescribeTask_594253; body: JsonNode): Recallable =
  ## describeTask
  ## Returns metadata about a task.
  ##   body: JObject (required)
  var body_594267 = newJObject()
  if body != nil:
    body_594267 = body
  result = call_594266.call(nil, nil, nil, nil, body_594267)

var describeTask* = Call_DescribeTask_594253(name: "describeTask",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeTask",
    validator: validate_DescribeTask_594254, base: "/", url: url_DescribeTask_594255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTaskExecution_594268 = ref object of OpenApiRestCall_593437
proc url_DescribeTaskExecution_594270(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTaskExecution_594269(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594271 = header.getOrDefault("X-Amz-Date")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Date", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Security-Token")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Security-Token", valid_594272
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594273 = header.getOrDefault("X-Amz-Target")
  valid_594273 = validateParameter(valid_594273, JString, required = true, default = newJString(
      "FmrsService.DescribeTaskExecution"))
  if valid_594273 != nil:
    section.add "X-Amz-Target", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Content-Sha256", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Algorithm")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Algorithm", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Signature")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Signature", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-SignedHeaders", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-Credential")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Credential", valid_594278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594280: Call_DescribeTaskExecution_594268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed metadata about a task that is being executed.
  ## 
  let valid = call_594280.validator(path, query, header, formData, body)
  let scheme = call_594280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594280.url(scheme.get, call_594280.host, call_594280.base,
                         call_594280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594280, url, valid)

proc call*(call_594281: Call_DescribeTaskExecution_594268; body: JsonNode): Recallable =
  ## describeTaskExecution
  ## Returns detailed metadata about a task that is being executed.
  ##   body: JObject (required)
  var body_594282 = newJObject()
  if body != nil:
    body_594282 = body
  result = call_594281.call(nil, nil, nil, nil, body_594282)

var describeTaskExecution* = Call_DescribeTaskExecution_594268(
    name: "describeTaskExecution", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeTaskExecution",
    validator: validate_DescribeTaskExecution_594269, base: "/",
    url: url_DescribeTaskExecution_594270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAgents_594283 = ref object of OpenApiRestCall_593437
proc url_ListAgents_594285(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAgents_594284(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of agents owned by an AWS account in the AWS Region specified in the request. The returned list is ordered by agent Amazon Resource Name (ARN).</p> <p>By default, this operation returns a maximum of 100 agents. This operation supports pagination that enables you to optionally reduce the number of agents returned in a response.</p> <p>If you have more agents than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a marker that you can specify in your next request to fetch the next page of agents.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594286 = query.getOrDefault("NextToken")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "NextToken", valid_594286
  var valid_594287 = query.getOrDefault("MaxResults")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "MaxResults", valid_594287
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
  var valid_594288 = header.getOrDefault("X-Amz-Date")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Date", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Security-Token")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Security-Token", valid_594289
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594290 = header.getOrDefault("X-Amz-Target")
  valid_594290 = validateParameter(valid_594290, JString, required = true,
                                 default = newJString("FmrsService.ListAgents"))
  if valid_594290 != nil:
    section.add "X-Amz-Target", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Content-Sha256", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-Algorithm")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-Algorithm", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Signature")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Signature", valid_594293
  var valid_594294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-SignedHeaders", valid_594294
  var valid_594295 = header.getOrDefault("X-Amz-Credential")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Credential", valid_594295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594297: Call_ListAgents_594283; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of agents owned by an AWS account in the AWS Region specified in the request. The returned list is ordered by agent Amazon Resource Name (ARN).</p> <p>By default, this operation returns a maximum of 100 agents. This operation supports pagination that enables you to optionally reduce the number of agents returned in a response.</p> <p>If you have more agents than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a marker that you can specify in your next request to fetch the next page of agents.</p>
  ## 
  let valid = call_594297.validator(path, query, header, formData, body)
  let scheme = call_594297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594297.url(scheme.get, call_594297.host, call_594297.base,
                         call_594297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594297, url, valid)

proc call*(call_594298: Call_ListAgents_594283; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAgents
  ## <p>Returns a list of agents owned by an AWS account in the AWS Region specified in the request. The returned list is ordered by agent Amazon Resource Name (ARN).</p> <p>By default, this operation returns a maximum of 100 agents. This operation supports pagination that enables you to optionally reduce the number of agents returned in a response.</p> <p>If you have more agents than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a marker that you can specify in your next request to fetch the next page of agents.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594299 = newJObject()
  var body_594300 = newJObject()
  add(query_594299, "NextToken", newJString(NextToken))
  if body != nil:
    body_594300 = body
  add(query_594299, "MaxResults", newJString(MaxResults))
  result = call_594298.call(nil, query_594299, nil, nil, body_594300)

var listAgents* = Call_ListAgents_594283(name: "listAgents",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.ListAgents",
                                      validator: validate_ListAgents_594284,
                                      base: "/", url: url_ListAgents_594285,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLocations_594302 = ref object of OpenApiRestCall_593437
proc url_ListLocations_594304(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLocations_594303(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a lists of source and destination locations.</p> <p>If you have more locations than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a token that you can specify in your next request to fetch the next page of locations.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594305 = query.getOrDefault("NextToken")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "NextToken", valid_594305
  var valid_594306 = query.getOrDefault("MaxResults")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "MaxResults", valid_594306
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
  var valid_594307 = header.getOrDefault("X-Amz-Date")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Date", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Security-Token")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Security-Token", valid_594308
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594309 = header.getOrDefault("X-Amz-Target")
  valid_594309 = validateParameter(valid_594309, JString, required = true, default = newJString(
      "FmrsService.ListLocations"))
  if valid_594309 != nil:
    section.add "X-Amz-Target", valid_594309
  var valid_594310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Content-Sha256", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-Algorithm")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-Algorithm", valid_594311
  var valid_594312 = header.getOrDefault("X-Amz-Signature")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "X-Amz-Signature", valid_594312
  var valid_594313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "X-Amz-SignedHeaders", valid_594313
  var valid_594314 = header.getOrDefault("X-Amz-Credential")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-Credential", valid_594314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594316: Call_ListLocations_594302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a lists of source and destination locations.</p> <p>If you have more locations than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a token that you can specify in your next request to fetch the next page of locations.</p>
  ## 
  let valid = call_594316.validator(path, query, header, formData, body)
  let scheme = call_594316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594316.url(scheme.get, call_594316.host, call_594316.base,
                         call_594316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594316, url, valid)

proc call*(call_594317: Call_ListLocations_594302; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLocations
  ## <p>Returns a lists of source and destination locations.</p> <p>If you have more locations than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a token that you can specify in your next request to fetch the next page of locations.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594318 = newJObject()
  var body_594319 = newJObject()
  add(query_594318, "NextToken", newJString(NextToken))
  if body != nil:
    body_594319 = body
  add(query_594318, "MaxResults", newJString(MaxResults))
  result = call_594317.call(nil, query_594318, nil, nil, body_594319)

var listLocations* = Call_ListLocations_594302(name: "listLocations",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.ListLocations",
    validator: validate_ListLocations_594303, base: "/", url: url_ListLocations_594304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594320 = ref object of OpenApiRestCall_593437
proc url_ListTagsForResource_594322(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_594321(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns all the tags associated with a specified resources. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594323 = query.getOrDefault("NextToken")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "NextToken", valid_594323
  var valid_594324 = query.getOrDefault("MaxResults")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "MaxResults", valid_594324
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
  var valid_594325 = header.getOrDefault("X-Amz-Date")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Date", valid_594325
  var valid_594326 = header.getOrDefault("X-Amz-Security-Token")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "X-Amz-Security-Token", valid_594326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594327 = header.getOrDefault("X-Amz-Target")
  valid_594327 = validateParameter(valid_594327, JString, required = true, default = newJString(
      "FmrsService.ListTagsForResource"))
  if valid_594327 != nil:
    section.add "X-Amz-Target", valid_594327
  var valid_594328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "X-Amz-Content-Sha256", valid_594328
  var valid_594329 = header.getOrDefault("X-Amz-Algorithm")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Algorithm", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Signature")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Signature", valid_594330
  var valid_594331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-SignedHeaders", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Credential")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Credential", valid_594332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594334: Call_ListTagsForResource_594320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all the tags associated with a specified resources. 
  ## 
  let valid = call_594334.validator(path, query, header, formData, body)
  let scheme = call_594334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594334.url(scheme.get, call_594334.host, call_594334.base,
                         call_594334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594334, url, valid)

proc call*(call_594335: Call_ListTagsForResource_594320; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTagsForResource
  ## Returns all the tags associated with a specified resources. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594336 = newJObject()
  var body_594337 = newJObject()
  add(query_594336, "NextToken", newJString(NextToken))
  if body != nil:
    body_594337 = body
  add(query_594336, "MaxResults", newJString(MaxResults))
  result = call_594335.call(nil, query_594336, nil, nil, body_594337)

var listTagsForResource* = Call_ListTagsForResource_594320(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.ListTagsForResource",
    validator: validate_ListTagsForResource_594321, base: "/",
    url: url_ListTagsForResource_594322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTaskExecutions_594338 = ref object of OpenApiRestCall_593437
proc url_ListTaskExecutions_594340(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTaskExecutions_594339(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of executed tasks.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594341 = query.getOrDefault("NextToken")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "NextToken", valid_594341
  var valid_594342 = query.getOrDefault("MaxResults")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "MaxResults", valid_594342
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
  var valid_594343 = header.getOrDefault("X-Amz-Date")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Date", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Security-Token")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Security-Token", valid_594344
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594345 = header.getOrDefault("X-Amz-Target")
  valid_594345 = validateParameter(valid_594345, JString, required = true, default = newJString(
      "FmrsService.ListTaskExecutions"))
  if valid_594345 != nil:
    section.add "X-Amz-Target", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Content-Sha256", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Algorithm")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Algorithm", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Signature")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Signature", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-SignedHeaders", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Credential")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Credential", valid_594350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594352: Call_ListTaskExecutions_594338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of executed tasks.
  ## 
  let valid = call_594352.validator(path, query, header, formData, body)
  let scheme = call_594352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594352.url(scheme.get, call_594352.host, call_594352.base,
                         call_594352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594352, url, valid)

proc call*(call_594353: Call_ListTaskExecutions_594338; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTaskExecutions
  ## Returns a list of executed tasks.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594354 = newJObject()
  var body_594355 = newJObject()
  add(query_594354, "NextToken", newJString(NextToken))
  if body != nil:
    body_594355 = body
  add(query_594354, "MaxResults", newJString(MaxResults))
  result = call_594353.call(nil, query_594354, nil, nil, body_594355)

var listTaskExecutions* = Call_ListTaskExecutions_594338(
    name: "listTaskExecutions", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.ListTaskExecutions",
    validator: validate_ListTaskExecutions_594339, base: "/",
    url: url_ListTaskExecutions_594340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTasks_594356 = ref object of OpenApiRestCall_593437
proc url_ListTasks_594358(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTasks_594357(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all the tasks.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594359 = query.getOrDefault("NextToken")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "NextToken", valid_594359
  var valid_594360 = query.getOrDefault("MaxResults")
  valid_594360 = validateParameter(valid_594360, JString, required = false,
                                 default = nil)
  if valid_594360 != nil:
    section.add "MaxResults", valid_594360
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
  var valid_594361 = header.getOrDefault("X-Amz-Date")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Date", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Security-Token")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Security-Token", valid_594362
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594363 = header.getOrDefault("X-Amz-Target")
  valid_594363 = validateParameter(valid_594363, JString, required = true,
                                 default = newJString("FmrsService.ListTasks"))
  if valid_594363 != nil:
    section.add "X-Amz-Target", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Content-Sha256", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Algorithm")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Algorithm", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Signature")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Signature", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-SignedHeaders", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Credential")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Credential", valid_594368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594370: Call_ListTasks_594356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all the tasks.
  ## 
  let valid = call_594370.validator(path, query, header, formData, body)
  let scheme = call_594370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594370.url(scheme.get, call_594370.host, call_594370.base,
                         call_594370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594370, url, valid)

proc call*(call_594371: Call_ListTasks_594356; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTasks
  ## Returns a list of all the tasks.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594372 = newJObject()
  var body_594373 = newJObject()
  add(query_594372, "NextToken", newJString(NextToken))
  if body != nil:
    body_594373 = body
  add(query_594372, "MaxResults", newJString(MaxResults))
  result = call_594371.call(nil, query_594372, nil, nil, body_594373)

var listTasks* = Call_ListTasks_594356(name: "listTasks", meth: HttpMethod.HttpPost,
                                    host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.ListTasks",
                                    validator: validate_ListTasks_594357,
                                    base: "/", url: url_ListTasks_594358,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTaskExecution_594374 = ref object of OpenApiRestCall_593437
proc url_StartTaskExecution_594376(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartTaskExecution_594375(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594377 = header.getOrDefault("X-Amz-Date")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Date", valid_594377
  var valid_594378 = header.getOrDefault("X-Amz-Security-Token")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-Security-Token", valid_594378
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594379 = header.getOrDefault("X-Amz-Target")
  valid_594379 = validateParameter(valid_594379, JString, required = true, default = newJString(
      "FmrsService.StartTaskExecution"))
  if valid_594379 != nil:
    section.add "X-Amz-Target", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Content-Sha256", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Algorithm")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Algorithm", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Signature")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Signature", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-SignedHeaders", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-Credential")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Credential", valid_594384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594386: Call_StartTaskExecution_594374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a specific invocation of a task. A <code>TaskExecution</code> value represents an individual run of a task. Each task can have at most one <code>TaskExecution</code> at a time.</p> <p> <code>TaskExecution</code> has the following transition phases: INITIALIZING | PREPARING | TRANSFERRING | VERIFYING | SUCCESS/FAILURE. </p> <p>For detailed information, see the Task Execution section in the Components and Terminology topic in the <i>AWS DataSync User Guide</i>.</p>
  ## 
  let valid = call_594386.validator(path, query, header, formData, body)
  let scheme = call_594386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594386.url(scheme.get, call_594386.host, call_594386.base,
                         call_594386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594386, url, valid)

proc call*(call_594387: Call_StartTaskExecution_594374; body: JsonNode): Recallable =
  ## startTaskExecution
  ## <p>Starts a specific invocation of a task. A <code>TaskExecution</code> value represents an individual run of a task. Each task can have at most one <code>TaskExecution</code> at a time.</p> <p> <code>TaskExecution</code> has the following transition phases: INITIALIZING | PREPARING | TRANSFERRING | VERIFYING | SUCCESS/FAILURE. </p> <p>For detailed information, see the Task Execution section in the Components and Terminology topic in the <i>AWS DataSync User Guide</i>.</p>
  ##   body: JObject (required)
  var body_594388 = newJObject()
  if body != nil:
    body_594388 = body
  result = call_594387.call(nil, nil, nil, nil, body_594388)

var startTaskExecution* = Call_StartTaskExecution_594374(
    name: "startTaskExecution", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.StartTaskExecution",
    validator: validate_StartTaskExecution_594375, base: "/",
    url: url_StartTaskExecution_594376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594389 = ref object of OpenApiRestCall_593437
proc url_TagResource_594391(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_594390(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594392 = header.getOrDefault("X-Amz-Date")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Date", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-Security-Token")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Security-Token", valid_594393
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594394 = header.getOrDefault("X-Amz-Target")
  valid_594394 = validateParameter(valid_594394, JString, required = true, default = newJString(
      "FmrsService.TagResource"))
  if valid_594394 != nil:
    section.add "X-Amz-Target", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Content-Sha256", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Algorithm")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Algorithm", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Signature")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Signature", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-SignedHeaders", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-Credential")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Credential", valid_594399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594401: Call_TagResource_594389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a key-value pair to an AWS resource.
  ## 
  let valid = call_594401.validator(path, query, header, formData, body)
  let scheme = call_594401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594401.url(scheme.get, call_594401.host, call_594401.base,
                         call_594401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594401, url, valid)

proc call*(call_594402: Call_TagResource_594389; body: JsonNode): Recallable =
  ## tagResource
  ## Applies a key-value pair to an AWS resource.
  ##   body: JObject (required)
  var body_594403 = newJObject()
  if body != nil:
    body_594403 = body
  result = call_594402.call(nil, nil, nil, nil, body_594403)

var tagResource* = Call_TagResource_594389(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.TagResource",
                                        validator: validate_TagResource_594390,
                                        base: "/", url: url_TagResource_594391,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594404 = ref object of OpenApiRestCall_593437
proc url_UntagResource_594406(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_594405(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594407 = header.getOrDefault("X-Amz-Date")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Date", valid_594407
  var valid_594408 = header.getOrDefault("X-Amz-Security-Token")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-Security-Token", valid_594408
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594409 = header.getOrDefault("X-Amz-Target")
  valid_594409 = validateParameter(valid_594409, JString, required = true, default = newJString(
      "FmrsService.UntagResource"))
  if valid_594409 != nil:
    section.add "X-Amz-Target", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Content-Sha256", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Algorithm")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Algorithm", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-Signature")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Signature", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-SignedHeaders", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Credential")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Credential", valid_594414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594416: Call_UntagResource_594404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from an AWS resource.
  ## 
  let valid = call_594416.validator(path, query, header, formData, body)
  let scheme = call_594416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594416.url(scheme.get, call_594416.host, call_594416.base,
                         call_594416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594416, url, valid)

proc call*(call_594417: Call_UntagResource_594404; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from an AWS resource.
  ##   body: JObject (required)
  var body_594418 = newJObject()
  if body != nil:
    body_594418 = body
  result = call_594417.call(nil, nil, nil, nil, body_594418)

var untagResource* = Call_UntagResource_594404(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.UntagResource",
    validator: validate_UntagResource_594405, base: "/", url: url_UntagResource_594406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAgent_594419 = ref object of OpenApiRestCall_593437
proc url_UpdateAgent_594421(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAgent_594420(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594422 = header.getOrDefault("X-Amz-Date")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-Date", valid_594422
  var valid_594423 = header.getOrDefault("X-Amz-Security-Token")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "X-Amz-Security-Token", valid_594423
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594424 = header.getOrDefault("X-Amz-Target")
  valid_594424 = validateParameter(valid_594424, JString, required = true, default = newJString(
      "FmrsService.UpdateAgent"))
  if valid_594424 != nil:
    section.add "X-Amz-Target", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Content-Sha256", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Algorithm")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Algorithm", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Signature")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Signature", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-SignedHeaders", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Credential")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Credential", valid_594429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594431: Call_UpdateAgent_594419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name of an agent.
  ## 
  let valid = call_594431.validator(path, query, header, formData, body)
  let scheme = call_594431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594431.url(scheme.get, call_594431.host, call_594431.base,
                         call_594431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594431, url, valid)

proc call*(call_594432: Call_UpdateAgent_594419; body: JsonNode): Recallable =
  ## updateAgent
  ## Updates the name of an agent.
  ##   body: JObject (required)
  var body_594433 = newJObject()
  if body != nil:
    body_594433 = body
  result = call_594432.call(nil, nil, nil, nil, body_594433)

var updateAgent* = Call_UpdateAgent_594419(name: "updateAgent",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.UpdateAgent",
                                        validator: validate_UpdateAgent_594420,
                                        base: "/", url: url_UpdateAgent_594421,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTask_594434 = ref object of OpenApiRestCall_593437
proc url_UpdateTask_594436(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTask_594435(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594437 = header.getOrDefault("X-Amz-Date")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-Date", valid_594437
  var valid_594438 = header.getOrDefault("X-Amz-Security-Token")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-Security-Token", valid_594438
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594439 = header.getOrDefault("X-Amz-Target")
  valid_594439 = validateParameter(valid_594439, JString, required = true,
                                 default = newJString("FmrsService.UpdateTask"))
  if valid_594439 != nil:
    section.add "X-Amz-Target", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Content-Sha256", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Algorithm")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Algorithm", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Signature")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Signature", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-SignedHeaders", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Credential")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Credential", valid_594444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594446: Call_UpdateTask_594434; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the metadata associated with a task.
  ## 
  let valid = call_594446.validator(path, query, header, formData, body)
  let scheme = call_594446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594446.url(scheme.get, call_594446.host, call_594446.base,
                         call_594446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594446, url, valid)

proc call*(call_594447: Call_UpdateTask_594434; body: JsonNode): Recallable =
  ## updateTask
  ## Updates the metadata associated with a task.
  ##   body: JObject (required)
  var body_594448 = newJObject()
  if body != nil:
    body_594448 = body
  result = call_594447.call(nil, nil, nil, nil, body_594448)

var updateTask* = Call_UpdateTask_594434(name: "updateTask",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.UpdateTask",
                                      validator: validate_UpdateTask_594435,
                                      base: "/", url: url_UpdateTask_594436,
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
