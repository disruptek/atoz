
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
  Call_CancelTaskExecution_602803 = ref object of OpenApiRestCall_602466
proc url_CancelTaskExecution_602805(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelTaskExecution_602804(path: JsonNode; query: JsonNode;
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
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "FmrsService.CancelTaskExecution"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_CancelTaskExecution_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels execution of a task. </p> <p>When you cancel a task execution, the transfer of some files are abruptly interrupted. The contents of files that are transferred to the destination might be incomplete or inconsistent with the source files. However, if you start a new task execution on the same task and you allow the task execution to complete, file content on the destination is complete and consistent. This applies to other unexpected failures that interrupt a task execution. In all of these cases, AWS DataSync successfully complete the transfer when you start the next task execution.</p>
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_CancelTaskExecution_602803; body: JsonNode): Recallable =
  ## cancelTaskExecution
  ## <p>Cancels execution of a task. </p> <p>When you cancel a task execution, the transfer of some files are abruptly interrupted. The contents of files that are transferred to the destination might be incomplete or inconsistent with the source files. However, if you start a new task execution on the same task and you allow the task execution to complete, file content on the destination is complete and consistent. This applies to other unexpected failures that interrupt a task execution. In all of these cases, AWS DataSync successfully complete the transfer when you start the next task execution.</p>
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var cancelTaskExecution* = Call_CancelTaskExecution_602803(
    name: "cancelTaskExecution", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CancelTaskExecution",
    validator: validate_CancelTaskExecution_602804, base: "/",
    url: url_CancelTaskExecution_602805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAgent_603072 = ref object of OpenApiRestCall_602466
proc url_CreateAgent_603074(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAgent_603073(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "FmrsService.CreateAgent"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_CreateAgent_603072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Activates an AWS DataSync agent that you have deployed on your host. The activation process associates your agent with your account. In the activation process, you specify information such as the AWS Region that you want to activate the agent in. You activate the agent in the AWS Region where your target locations (in Amazon S3 or Amazon EFS) reside. Your tasks are created in this AWS Region.</p> <p>You can activate the agent in a VPC (Virtual private Cloud) or provide the agent access to a VPC endpoint so you can run tasks without going over the public Internet.</p> <p>You can use an agent for more than one location. If a task uses multiple agents, all of them need to have status AVAILABLE for the task to run. If you use multiple agents for a source location, the status of all the agents must be AVAILABLE for the task to run. </p> <p>Agents are automatically updated by AWS on a regular basis, using a mechanism that ensures minimal interruption to your tasks.</p> <p/>
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_CreateAgent_603072; body: JsonNode): Recallable =
  ## createAgent
  ## <p>Activates an AWS DataSync agent that you have deployed on your host. The activation process associates your agent with your account. In the activation process, you specify information such as the AWS Region that you want to activate the agent in. You activate the agent in the AWS Region where your target locations (in Amazon S3 or Amazon EFS) reside. Your tasks are created in this AWS Region.</p> <p>You can activate the agent in a VPC (Virtual private Cloud) or provide the agent access to a VPC endpoint so you can run tasks without going over the public Internet.</p> <p>You can use an agent for more than one location. If a task uses multiple agents, all of them need to have status AVAILABLE for the task to run. If you use multiple agents for a source location, the status of all the agents must be AVAILABLE for the task to run. </p> <p>Agents are automatically updated by AWS on a regular basis, using a mechanism that ensures minimal interruption to your tasks.</p> <p/>
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var createAgent* = Call_CreateAgent_603072(name: "createAgent",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.CreateAgent",
                                        validator: validate_CreateAgent_603073,
                                        base: "/", url: url_CreateAgent_603074,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationEfs_603087 = ref object of OpenApiRestCall_602466
proc url_CreateLocationEfs_603089(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLocationEfs_603088(path: JsonNode; query: JsonNode;
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "FmrsService.CreateLocationEfs"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_CreateLocationEfs_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint for an Amazon EFS file system.
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_CreateLocationEfs_603087; body: JsonNode): Recallable =
  ## createLocationEfs
  ## Creates an endpoint for an Amazon EFS file system.
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var createLocationEfs* = Call_CreateLocationEfs_603087(name: "createLocationEfs",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationEfs",
    validator: validate_CreateLocationEfs_603088, base: "/",
    url: url_CreateLocationEfs_603089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationNfs_603102 = ref object of OpenApiRestCall_602466
proc url_CreateLocationNfs_603104(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLocationNfs_603103(path: JsonNode; query: JsonNode;
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
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "FmrsService.CreateLocationNfs"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_CreateLocationNfs_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint for a Network File System (NFS) file system.
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_CreateLocationNfs_603102; body: JsonNode): Recallable =
  ## createLocationNfs
  ## Creates an endpoint for a Network File System (NFS) file system.
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var createLocationNfs* = Call_CreateLocationNfs_603102(name: "createLocationNfs",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationNfs",
    validator: validate_CreateLocationNfs_603103, base: "/",
    url: url_CreateLocationNfs_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationS3_603117 = ref object of OpenApiRestCall_602466
proc url_CreateLocationS3_603119(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLocationS3_603118(path: JsonNode; query: JsonNode;
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
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "FmrsService.CreateLocationS3"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_CreateLocationS3_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for an Amazon S3 bucket.</p> <p>For AWS DataSync to access a destination S3 bucket, it needs an AWS Identity and Access Management (IAM) role that has the required permissions. You can set up the required permissions by creating an IAM policy that grants the required permissions and attaching the policy to the role. An example of such a policy is shown in the examples section.</p> <p>For more information, see https://docs.aws.amazon.com/datasync/latest/userguide/working-with-locations.html#create-s3-location in the <i>AWS DataSync User Guide.</i> </p>
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_CreateLocationS3_603117; body: JsonNode): Recallable =
  ## createLocationS3
  ## <p>Creates an endpoint for an Amazon S3 bucket.</p> <p>For AWS DataSync to access a destination S3 bucket, it needs an AWS Identity and Access Management (IAM) role that has the required permissions. You can set up the required permissions by creating an IAM policy that grants the required permissions and attaching the policy to the role. An example of such a policy is shown in the examples section.</p> <p>For more information, see https://docs.aws.amazon.com/datasync/latest/userguide/working-with-locations.html#create-s3-location in the <i>AWS DataSync User Guide.</i> </p>
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var createLocationS3* = Call_CreateLocationS3_603117(name: "createLocationS3",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationS3",
    validator: validate_CreateLocationS3_603118, base: "/",
    url: url_CreateLocationS3_603119, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationSmb_603132 = ref object of OpenApiRestCall_602466
proc url_CreateLocationSmb_603134(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLocationSmb_603133(path: JsonNode; query: JsonNode;
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
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "FmrsService.CreateLocationSmb"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_CreateLocationSmb_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint for a Server Message Block (SMB) file system.
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_CreateLocationSmb_603132; body: JsonNode): Recallable =
  ## createLocationSmb
  ## Creates an endpoint for a Server Message Block (SMB) file system.
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var createLocationSmb* = Call_CreateLocationSmb_603132(name: "createLocationSmb",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationSmb",
    validator: validate_CreateLocationSmb_603133, base: "/",
    url: url_CreateLocationSmb_603134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTask_603147 = ref object of OpenApiRestCall_602466
proc url_CreateTask_603149(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTask_603148(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true,
                                 default = newJString("FmrsService.CreateTask"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_CreateTask_603147; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a task. A task is a set of two locations (source and destination) and a set of Options that you use to control the behavior of a task. If you don't specify Options when you create a task, AWS DataSync populates them with service defaults.</p> <p>When you create a task, it first enters the CREATING state. During CREATING AWS DataSync attempts to mount the on-premises Network File System (NFS) location. The task transitions to the AVAILABLE state without waiting for the AWS location to become mounted. If required, AWS DataSync mounts the AWS location before each task execution.</p> <p>If an agent that is associated with a source (NFS) location goes offline, the task transitions to the UNAVAILABLE status. If the status of the task remains in the CREATING status for more than a few minutes, it means that your agent might be having trouble mounting the source NFS file system. Check the task's ErrorCode and ErrorDetail. Mount issues are often caused by either a misconfigured firewall or a mistyped NFS server host name.</p>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_CreateTask_603147; body: JsonNode): Recallable =
  ## createTask
  ## <p>Creates a task. A task is a set of two locations (source and destination) and a set of Options that you use to control the behavior of a task. If you don't specify Options when you create a task, AWS DataSync populates them with service defaults.</p> <p>When you create a task, it first enters the CREATING state. During CREATING AWS DataSync attempts to mount the on-premises Network File System (NFS) location. The task transitions to the AVAILABLE state without waiting for the AWS location to become mounted. If required, AWS DataSync mounts the AWS location before each task execution.</p> <p>If an agent that is associated with a source (NFS) location goes offline, the task transitions to the UNAVAILABLE status. If the status of the task remains in the CREATING status for more than a few minutes, it means that your agent might be having trouble mounting the source NFS file system. Check the task's ErrorCode and ErrorDetail. Mount issues are often caused by either a misconfigured firewall or a mistyped NFS server host name.</p>
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var createTask* = Call_CreateTask_603147(name: "createTask",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.CreateTask",
                                      validator: validate_CreateTask_603148,
                                      base: "/", url: url_CreateTask_603149,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAgent_603162 = ref object of OpenApiRestCall_602466
proc url_DeleteAgent_603164(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAgent_603163(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "FmrsService.DeleteAgent"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_DeleteAgent_603162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an agent. To specify which agent to delete, use the Amazon Resource Name (ARN) of the agent in your request. The operation disassociates the agent from your AWS account. However, it doesn't delete the agent virtual machine (VM) from your on-premises environment.
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_DeleteAgent_603162; body: JsonNode): Recallable =
  ## deleteAgent
  ## Deletes an agent. To specify which agent to delete, use the Amazon Resource Name (ARN) of the agent in your request. The operation disassociates the agent from your AWS account. However, it doesn't delete the agent virtual machine (VM) from your on-premises environment.
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var deleteAgent* = Call_DeleteAgent_603162(name: "deleteAgent",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.DeleteAgent",
                                        validator: validate_DeleteAgent_603163,
                                        base: "/", url: url_DeleteAgent_603164,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLocation_603177 = ref object of OpenApiRestCall_602466
proc url_DeleteLocation_603179(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteLocation_603178(path: JsonNode; query: JsonNode;
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
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "FmrsService.DeleteLocation"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_DeleteLocation_603177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the configuration of a location used by AWS DataSync. 
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_DeleteLocation_603177; body: JsonNode): Recallable =
  ## deleteLocation
  ## Deletes the configuration of a location used by AWS DataSync. 
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var deleteLocation* = Call_DeleteLocation_603177(name: "deleteLocation",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DeleteLocation",
    validator: validate_DeleteLocation_603178, base: "/", url: url_DeleteLocation_603179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTask_603192 = ref object of OpenApiRestCall_602466
proc url_DeleteTask_603194(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTask_603193(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true,
                                 default = newJString("FmrsService.DeleteTask"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_DeleteTask_603192; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a task.
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_DeleteTask_603192; body: JsonNode): Recallable =
  ## deleteTask
  ## Deletes a task.
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var deleteTask* = Call_DeleteTask_603192(name: "deleteTask",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.DeleteTask",
                                      validator: validate_DeleteTask_603193,
                                      base: "/", url: url_DeleteTask_603194,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAgent_603207 = ref object of OpenApiRestCall_602466
proc url_DescribeAgent_603209(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAgent_603208(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "FmrsService.DescribeAgent"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_DescribeAgent_603207; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata such as the name, the network interfaces, and the status (that is, whether the agent is running or not) for an agent. To specify which agent to describe, use the Amazon Resource Name (ARN) of the agent in your request. 
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_DescribeAgent_603207; body: JsonNode): Recallable =
  ## describeAgent
  ## Returns metadata such as the name, the network interfaces, and the status (that is, whether the agent is running or not) for an agent. To specify which agent to describe, use the Amazon Resource Name (ARN) of the agent in your request. 
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var describeAgent* = Call_DescribeAgent_603207(name: "describeAgent",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeAgent",
    validator: validate_DescribeAgent_603208, base: "/", url: url_DescribeAgent_603209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationEfs_603222 = ref object of OpenApiRestCall_602466
proc url_DescribeLocationEfs_603224(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLocationEfs_603223(path: JsonNode; query: JsonNode;
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
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "FmrsService.DescribeLocationEfs"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_DescribeLocationEfs_603222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as the path information about an Amazon EFS location.
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_DescribeLocationEfs_603222; body: JsonNode): Recallable =
  ## describeLocationEfs
  ## Returns metadata, such as the path information about an Amazon EFS location.
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var describeLocationEfs* = Call_DescribeLocationEfs_603222(
    name: "describeLocationEfs", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationEfs",
    validator: validate_DescribeLocationEfs_603223, base: "/",
    url: url_DescribeLocationEfs_603224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationNfs_603237 = ref object of OpenApiRestCall_602466
proc url_DescribeLocationNfs_603239(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLocationNfs_603238(path: JsonNode; query: JsonNode;
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
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "FmrsService.DescribeLocationNfs"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_DescribeLocationNfs_603237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as the path information, about a NFS location.
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_DescribeLocationNfs_603237; body: JsonNode): Recallable =
  ## describeLocationNfs
  ## Returns metadata, such as the path information, about a NFS location.
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var describeLocationNfs* = Call_DescribeLocationNfs_603237(
    name: "describeLocationNfs", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationNfs",
    validator: validate_DescribeLocationNfs_603238, base: "/",
    url: url_DescribeLocationNfs_603239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationS3_603252 = ref object of OpenApiRestCall_602466
proc url_DescribeLocationS3_603254(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLocationS3_603253(path: JsonNode; query: JsonNode;
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
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "FmrsService.DescribeLocationS3"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_DescribeLocationS3_603252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as bucket name, about an Amazon S3 bucket location.
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_DescribeLocationS3_603252; body: JsonNode): Recallable =
  ## describeLocationS3
  ## Returns metadata, such as bucket name, about an Amazon S3 bucket location.
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var describeLocationS3* = Call_DescribeLocationS3_603252(
    name: "describeLocationS3", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationS3",
    validator: validate_DescribeLocationS3_603253, base: "/",
    url: url_DescribeLocationS3_603254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationSmb_603267 = ref object of OpenApiRestCall_602466
proc url_DescribeLocationSmb_603269(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLocationSmb_603268(path: JsonNode; query: JsonNode;
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
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "FmrsService.DescribeLocationSmb"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_DescribeLocationSmb_603267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as the path and user information about a SMB location.
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_DescribeLocationSmb_603267; body: JsonNode): Recallable =
  ## describeLocationSmb
  ## Returns metadata, such as the path and user information about a SMB location.
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var describeLocationSmb* = Call_DescribeLocationSmb_603267(
    name: "describeLocationSmb", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationSmb",
    validator: validate_DescribeLocationSmb_603268, base: "/",
    url: url_DescribeLocationSmb_603269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTask_603282 = ref object of OpenApiRestCall_602466
proc url_DescribeTask_603284(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTask_603283(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true, default = newJString(
      "FmrsService.DescribeTask"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_DescribeTask_603282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about a task.
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_DescribeTask_603282; body: JsonNode): Recallable =
  ## describeTask
  ## Returns metadata about a task.
  ##   body: JObject (required)
  var body_603296 = newJObject()
  if body != nil:
    body_603296 = body
  result = call_603295.call(nil, nil, nil, nil, body_603296)

var describeTask* = Call_DescribeTask_603282(name: "describeTask",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeTask",
    validator: validate_DescribeTask_603283, base: "/", url: url_DescribeTask_603284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTaskExecution_603297 = ref object of OpenApiRestCall_602466
proc url_DescribeTaskExecution_603299(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTaskExecution_603298(path: JsonNode; query: JsonNode;
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
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true, default = newJString(
      "FmrsService.DescribeTaskExecution"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_DescribeTaskExecution_603297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed metadata about a task that is being executed.
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_DescribeTaskExecution_603297; body: JsonNode): Recallable =
  ## describeTaskExecution
  ## Returns detailed metadata about a task that is being executed.
  ##   body: JObject (required)
  var body_603311 = newJObject()
  if body != nil:
    body_603311 = body
  result = call_603310.call(nil, nil, nil, nil, body_603311)

var describeTaskExecution* = Call_DescribeTaskExecution_603297(
    name: "describeTaskExecution", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeTaskExecution",
    validator: validate_DescribeTaskExecution_603298, base: "/",
    url: url_DescribeTaskExecution_603299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAgents_603312 = ref object of OpenApiRestCall_602466
proc url_ListAgents_603314(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAgents_603313(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603315 = query.getOrDefault("NextToken")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "NextToken", valid_603315
  var valid_603316 = query.getOrDefault("MaxResults")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "MaxResults", valid_603316
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
  var valid_603317 = header.getOrDefault("X-Amz-Date")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Date", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Security-Token")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Security-Token", valid_603318
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603319 = header.getOrDefault("X-Amz-Target")
  valid_603319 = validateParameter(valid_603319, JString, required = true,
                                 default = newJString("FmrsService.ListAgents"))
  if valid_603319 != nil:
    section.add "X-Amz-Target", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Content-Sha256", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Algorithm")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Algorithm", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Signature")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Signature", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-SignedHeaders", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Credential")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Credential", valid_603324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603326: Call_ListAgents_603312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of agents owned by an AWS account in the AWS Region specified in the request. The returned list is ordered by agent Amazon Resource Name (ARN).</p> <p>By default, this operation returns a maximum of 100 agents. This operation supports pagination that enables you to optionally reduce the number of agents returned in a response.</p> <p>If you have more agents than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a marker that you can specify in your next request to fetch the next page of agents.</p>
  ## 
  let valid = call_603326.validator(path, query, header, formData, body)
  let scheme = call_603326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603326.url(scheme.get, call_603326.host, call_603326.base,
                         call_603326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603326, url, valid)

proc call*(call_603327: Call_ListAgents_603312; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listAgents
  ## <p>Returns a list of agents owned by an AWS account in the AWS Region specified in the request. The returned list is ordered by agent Amazon Resource Name (ARN).</p> <p>By default, this operation returns a maximum of 100 agents. This operation supports pagination that enables you to optionally reduce the number of agents returned in a response.</p> <p>If you have more agents than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a marker that you can specify in your next request to fetch the next page of agents.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603328 = newJObject()
  var body_603329 = newJObject()
  add(query_603328, "NextToken", newJString(NextToken))
  if body != nil:
    body_603329 = body
  add(query_603328, "MaxResults", newJString(MaxResults))
  result = call_603327.call(nil, query_603328, nil, nil, body_603329)

var listAgents* = Call_ListAgents_603312(name: "listAgents",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.ListAgents",
                                      validator: validate_ListAgents_603313,
                                      base: "/", url: url_ListAgents_603314,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLocations_603331 = ref object of OpenApiRestCall_602466
proc url_ListLocations_603333(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLocations_603332(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603334 = query.getOrDefault("NextToken")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "NextToken", valid_603334
  var valid_603335 = query.getOrDefault("MaxResults")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "MaxResults", valid_603335
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
  var valid_603336 = header.getOrDefault("X-Amz-Date")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Date", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Security-Token")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Security-Token", valid_603337
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603338 = header.getOrDefault("X-Amz-Target")
  valid_603338 = validateParameter(valid_603338, JString, required = true, default = newJString(
      "FmrsService.ListLocations"))
  if valid_603338 != nil:
    section.add "X-Amz-Target", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Content-Sha256", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Algorithm")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Algorithm", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Signature")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Signature", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-SignedHeaders", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Credential")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Credential", valid_603343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603345: Call_ListLocations_603331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a lists of source and destination locations.</p> <p>If you have more locations than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a token that you can specify in your next request to fetch the next page of locations.</p>
  ## 
  let valid = call_603345.validator(path, query, header, formData, body)
  let scheme = call_603345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603345.url(scheme.get, call_603345.host, call_603345.base,
                         call_603345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603345, url, valid)

proc call*(call_603346: Call_ListLocations_603331; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLocations
  ## <p>Returns a lists of source and destination locations.</p> <p>If you have more locations than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a token that you can specify in your next request to fetch the next page of locations.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603347 = newJObject()
  var body_603348 = newJObject()
  add(query_603347, "NextToken", newJString(NextToken))
  if body != nil:
    body_603348 = body
  add(query_603347, "MaxResults", newJString(MaxResults))
  result = call_603346.call(nil, query_603347, nil, nil, body_603348)

var listLocations* = Call_ListLocations_603331(name: "listLocations",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.ListLocations",
    validator: validate_ListLocations_603332, base: "/", url: url_ListLocations_603333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603349 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603351(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_603350(path: JsonNode; query: JsonNode;
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
  var valid_603352 = query.getOrDefault("NextToken")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "NextToken", valid_603352
  var valid_603353 = query.getOrDefault("MaxResults")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "MaxResults", valid_603353
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
  var valid_603354 = header.getOrDefault("X-Amz-Date")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Date", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Security-Token")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Security-Token", valid_603355
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603356 = header.getOrDefault("X-Amz-Target")
  valid_603356 = validateParameter(valid_603356, JString, required = true, default = newJString(
      "FmrsService.ListTagsForResource"))
  if valid_603356 != nil:
    section.add "X-Amz-Target", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Content-Sha256", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Algorithm")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Algorithm", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Signature")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Signature", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-SignedHeaders", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Credential")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Credential", valid_603361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603363: Call_ListTagsForResource_603349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all the tags associated with a specified resources. 
  ## 
  let valid = call_603363.validator(path, query, header, formData, body)
  let scheme = call_603363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603363.url(scheme.get, call_603363.host, call_603363.base,
                         call_603363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603363, url, valid)

proc call*(call_603364: Call_ListTagsForResource_603349; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTagsForResource
  ## Returns all the tags associated with a specified resources. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603365 = newJObject()
  var body_603366 = newJObject()
  add(query_603365, "NextToken", newJString(NextToken))
  if body != nil:
    body_603366 = body
  add(query_603365, "MaxResults", newJString(MaxResults))
  result = call_603364.call(nil, query_603365, nil, nil, body_603366)

var listTagsForResource* = Call_ListTagsForResource_603349(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.ListTagsForResource",
    validator: validate_ListTagsForResource_603350, base: "/",
    url: url_ListTagsForResource_603351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTaskExecutions_603367 = ref object of OpenApiRestCall_602466
proc url_ListTaskExecutions_603369(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTaskExecutions_603368(path: JsonNode; query: JsonNode;
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
  var valid_603370 = query.getOrDefault("NextToken")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "NextToken", valid_603370
  var valid_603371 = query.getOrDefault("MaxResults")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "MaxResults", valid_603371
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
  var valid_603372 = header.getOrDefault("X-Amz-Date")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Date", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Security-Token")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Security-Token", valid_603373
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603374 = header.getOrDefault("X-Amz-Target")
  valid_603374 = validateParameter(valid_603374, JString, required = true, default = newJString(
      "FmrsService.ListTaskExecutions"))
  if valid_603374 != nil:
    section.add "X-Amz-Target", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Content-Sha256", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Algorithm")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Algorithm", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Signature")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Signature", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-SignedHeaders", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Credential")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Credential", valid_603379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603381: Call_ListTaskExecutions_603367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of executed tasks.
  ## 
  let valid = call_603381.validator(path, query, header, formData, body)
  let scheme = call_603381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603381.url(scheme.get, call_603381.host, call_603381.base,
                         call_603381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603381, url, valid)

proc call*(call_603382: Call_ListTaskExecutions_603367; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTaskExecutions
  ## Returns a list of executed tasks.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603383 = newJObject()
  var body_603384 = newJObject()
  add(query_603383, "NextToken", newJString(NextToken))
  if body != nil:
    body_603384 = body
  add(query_603383, "MaxResults", newJString(MaxResults))
  result = call_603382.call(nil, query_603383, nil, nil, body_603384)

var listTaskExecutions* = Call_ListTaskExecutions_603367(
    name: "listTaskExecutions", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.ListTaskExecutions",
    validator: validate_ListTaskExecutions_603368, base: "/",
    url: url_ListTaskExecutions_603369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTasks_603385 = ref object of OpenApiRestCall_602466
proc url_ListTasks_603387(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTasks_603386(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603388 = query.getOrDefault("NextToken")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "NextToken", valid_603388
  var valid_603389 = query.getOrDefault("MaxResults")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "MaxResults", valid_603389
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
  var valid_603390 = header.getOrDefault("X-Amz-Date")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Date", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603392 = header.getOrDefault("X-Amz-Target")
  valid_603392 = validateParameter(valid_603392, JString, required = true,
                                 default = newJString("FmrsService.ListTasks"))
  if valid_603392 != nil:
    section.add "X-Amz-Target", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Content-Sha256", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Algorithm")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Algorithm", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Signature")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Signature", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-SignedHeaders", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Credential")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Credential", valid_603397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603399: Call_ListTasks_603385; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all the tasks.
  ## 
  let valid = call_603399.validator(path, query, header, formData, body)
  let scheme = call_603399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603399.url(scheme.get, call_603399.host, call_603399.base,
                         call_603399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603399, url, valid)

proc call*(call_603400: Call_ListTasks_603385; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTasks
  ## Returns a list of all the tasks.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603401 = newJObject()
  var body_603402 = newJObject()
  add(query_603401, "NextToken", newJString(NextToken))
  if body != nil:
    body_603402 = body
  add(query_603401, "MaxResults", newJString(MaxResults))
  result = call_603400.call(nil, query_603401, nil, nil, body_603402)

var listTasks* = Call_ListTasks_603385(name: "listTasks", meth: HttpMethod.HttpPost,
                                    host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.ListTasks",
                                    validator: validate_ListTasks_603386,
                                    base: "/", url: url_ListTasks_603387,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTaskExecution_603403 = ref object of OpenApiRestCall_602466
proc url_StartTaskExecution_603405(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartTaskExecution_603404(path: JsonNode; query: JsonNode;
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
  var valid_603406 = header.getOrDefault("X-Amz-Date")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Date", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Security-Token")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Security-Token", valid_603407
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603408 = header.getOrDefault("X-Amz-Target")
  valid_603408 = validateParameter(valid_603408, JString, required = true, default = newJString(
      "FmrsService.StartTaskExecution"))
  if valid_603408 != nil:
    section.add "X-Amz-Target", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Content-Sha256", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Algorithm")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Algorithm", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Signature")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Signature", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-SignedHeaders", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Credential")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Credential", valid_603413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603415: Call_StartTaskExecution_603403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a specific invocation of a task. A <code>TaskExecution</code> value represents an individual run of a task. Each task can have at most one <code>TaskExecution</code> at a time.</p> <p> <code>TaskExecution</code> has the following transition phases: INITIALIZING | PREPARING | TRANSFERRING | VERIFYING | SUCCESS/FAILURE. </p> <p>For detailed information, see the Task Execution section in the Components and Terminology topic in the <i>AWS DataSync User Guide</i>.</p>
  ## 
  let valid = call_603415.validator(path, query, header, formData, body)
  let scheme = call_603415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603415.url(scheme.get, call_603415.host, call_603415.base,
                         call_603415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603415, url, valid)

proc call*(call_603416: Call_StartTaskExecution_603403; body: JsonNode): Recallable =
  ## startTaskExecution
  ## <p>Starts a specific invocation of a task. A <code>TaskExecution</code> value represents an individual run of a task. Each task can have at most one <code>TaskExecution</code> at a time.</p> <p> <code>TaskExecution</code> has the following transition phases: INITIALIZING | PREPARING | TRANSFERRING | VERIFYING | SUCCESS/FAILURE. </p> <p>For detailed information, see the Task Execution section in the Components and Terminology topic in the <i>AWS DataSync User Guide</i>.</p>
  ##   body: JObject (required)
  var body_603417 = newJObject()
  if body != nil:
    body_603417 = body
  result = call_603416.call(nil, nil, nil, nil, body_603417)

var startTaskExecution* = Call_StartTaskExecution_603403(
    name: "startTaskExecution", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.StartTaskExecution",
    validator: validate_StartTaskExecution_603404, base: "/",
    url: url_StartTaskExecution_603405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603418 = ref object of OpenApiRestCall_602466
proc url_TagResource_603420(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_603419(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603421 = header.getOrDefault("X-Amz-Date")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Date", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Security-Token")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Security-Token", valid_603422
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603423 = header.getOrDefault("X-Amz-Target")
  valid_603423 = validateParameter(valid_603423, JString, required = true, default = newJString(
      "FmrsService.TagResource"))
  if valid_603423 != nil:
    section.add "X-Amz-Target", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Content-Sha256", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Algorithm")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Algorithm", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Signature")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Signature", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-SignedHeaders", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Credential")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Credential", valid_603428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603430: Call_TagResource_603418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a key-value pair to an AWS resource.
  ## 
  let valid = call_603430.validator(path, query, header, formData, body)
  let scheme = call_603430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603430.url(scheme.get, call_603430.host, call_603430.base,
                         call_603430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603430, url, valid)

proc call*(call_603431: Call_TagResource_603418; body: JsonNode): Recallable =
  ## tagResource
  ## Applies a key-value pair to an AWS resource.
  ##   body: JObject (required)
  var body_603432 = newJObject()
  if body != nil:
    body_603432 = body
  result = call_603431.call(nil, nil, nil, nil, body_603432)

var tagResource* = Call_TagResource_603418(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.TagResource",
                                        validator: validate_TagResource_603419,
                                        base: "/", url: url_TagResource_603420,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603433 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603435(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_603434(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603436 = header.getOrDefault("X-Amz-Date")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Date", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Security-Token")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Security-Token", valid_603437
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603438 = header.getOrDefault("X-Amz-Target")
  valid_603438 = validateParameter(valid_603438, JString, required = true, default = newJString(
      "FmrsService.UntagResource"))
  if valid_603438 != nil:
    section.add "X-Amz-Target", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Content-Sha256", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Algorithm")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Algorithm", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Signature")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Signature", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-SignedHeaders", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Credential")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Credential", valid_603443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603445: Call_UntagResource_603433; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from an AWS resource.
  ## 
  let valid = call_603445.validator(path, query, header, formData, body)
  let scheme = call_603445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603445.url(scheme.get, call_603445.host, call_603445.base,
                         call_603445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603445, url, valid)

proc call*(call_603446: Call_UntagResource_603433; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from an AWS resource.
  ##   body: JObject (required)
  var body_603447 = newJObject()
  if body != nil:
    body_603447 = body
  result = call_603446.call(nil, nil, nil, nil, body_603447)

var untagResource* = Call_UntagResource_603433(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.UntagResource",
    validator: validate_UntagResource_603434, base: "/", url: url_UntagResource_603435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAgent_603448 = ref object of OpenApiRestCall_602466
proc url_UpdateAgent_603450(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAgent_603449(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603451 = header.getOrDefault("X-Amz-Date")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Date", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Security-Token")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Security-Token", valid_603452
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603453 = header.getOrDefault("X-Amz-Target")
  valid_603453 = validateParameter(valid_603453, JString, required = true, default = newJString(
      "FmrsService.UpdateAgent"))
  if valid_603453 != nil:
    section.add "X-Amz-Target", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Content-Sha256", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Algorithm")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Algorithm", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Signature")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Signature", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-SignedHeaders", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Credential")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Credential", valid_603458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603460: Call_UpdateAgent_603448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name of an agent.
  ## 
  let valid = call_603460.validator(path, query, header, formData, body)
  let scheme = call_603460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603460.url(scheme.get, call_603460.host, call_603460.base,
                         call_603460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603460, url, valid)

proc call*(call_603461: Call_UpdateAgent_603448; body: JsonNode): Recallable =
  ## updateAgent
  ## Updates the name of an agent.
  ##   body: JObject (required)
  var body_603462 = newJObject()
  if body != nil:
    body_603462 = body
  result = call_603461.call(nil, nil, nil, nil, body_603462)

var updateAgent* = Call_UpdateAgent_603448(name: "updateAgent",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.UpdateAgent",
                                        validator: validate_UpdateAgent_603449,
                                        base: "/", url: url_UpdateAgent_603450,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTask_603463 = ref object of OpenApiRestCall_602466
proc url_UpdateTask_603465(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTask_603464(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603466 = header.getOrDefault("X-Amz-Date")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Date", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Security-Token")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Security-Token", valid_603467
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603468 = header.getOrDefault("X-Amz-Target")
  valid_603468 = validateParameter(valid_603468, JString, required = true,
                                 default = newJString("FmrsService.UpdateTask"))
  if valid_603468 != nil:
    section.add "X-Amz-Target", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Content-Sha256", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Algorithm")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Algorithm", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Signature")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Signature", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-SignedHeaders", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Credential")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Credential", valid_603473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603475: Call_UpdateTask_603463; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the metadata associated with a task.
  ## 
  let valid = call_603475.validator(path, query, header, formData, body)
  let scheme = call_603475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603475.url(scheme.get, call_603475.host, call_603475.base,
                         call_603475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603475, url, valid)

proc call*(call_603476: Call_UpdateTask_603463; body: JsonNode): Recallable =
  ## updateTask
  ## Updates the metadata associated with a task.
  ##   body: JObject (required)
  var body_603477 = newJObject()
  if body != nil:
    body_603477 = body
  result = call_603476.call(nil, nil, nil, nil, body_603477)

var updateTask* = Call_UpdateTask_603463(name: "updateTask",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.UpdateTask",
                                      validator: validate_UpdateTask_603464,
                                      base: "/", url: url_UpdateTask_603465,
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
