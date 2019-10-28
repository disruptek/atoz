
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
  Call_CancelTaskExecution_590703 = ref object of OpenApiRestCall_590364
proc url_CancelTaskExecution_590705(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelTaskExecution_590704(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590830 = header.getOrDefault("X-Amz-Target")
  valid_590830 = validateParameter(valid_590830, JString, required = true, default = newJString(
      "FmrsService.CancelTaskExecution"))
  if valid_590830 != nil:
    section.add "X-Amz-Target", valid_590830
  var valid_590831 = header.getOrDefault("X-Amz-Signature")
  valid_590831 = validateParameter(valid_590831, JString, required = false,
                                 default = nil)
  if valid_590831 != nil:
    section.add "X-Amz-Signature", valid_590831
  var valid_590832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590832 = validateParameter(valid_590832, JString, required = false,
                                 default = nil)
  if valid_590832 != nil:
    section.add "X-Amz-Content-Sha256", valid_590832
  var valid_590833 = header.getOrDefault("X-Amz-Date")
  valid_590833 = validateParameter(valid_590833, JString, required = false,
                                 default = nil)
  if valid_590833 != nil:
    section.add "X-Amz-Date", valid_590833
  var valid_590834 = header.getOrDefault("X-Amz-Credential")
  valid_590834 = validateParameter(valid_590834, JString, required = false,
                                 default = nil)
  if valid_590834 != nil:
    section.add "X-Amz-Credential", valid_590834
  var valid_590835 = header.getOrDefault("X-Amz-Security-Token")
  valid_590835 = validateParameter(valid_590835, JString, required = false,
                                 default = nil)
  if valid_590835 != nil:
    section.add "X-Amz-Security-Token", valid_590835
  var valid_590836 = header.getOrDefault("X-Amz-Algorithm")
  valid_590836 = validateParameter(valid_590836, JString, required = false,
                                 default = nil)
  if valid_590836 != nil:
    section.add "X-Amz-Algorithm", valid_590836
  var valid_590837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590837 = validateParameter(valid_590837, JString, required = false,
                                 default = nil)
  if valid_590837 != nil:
    section.add "X-Amz-SignedHeaders", valid_590837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590861: Call_CancelTaskExecution_590703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Cancels execution of a task. </p> <p>When you cancel a task execution, the transfer of some files are abruptly interrupted. The contents of files that are transferred to the destination might be incomplete or inconsistent with the source files. However, if you start a new task execution on the same task and you allow the task execution to complete, file content on the destination is complete and consistent. This applies to other unexpected failures that interrupt a task execution. In all of these cases, AWS DataSync successfully complete the transfer when you start the next task execution.</p>
  ## 
  let valid = call_590861.validator(path, query, header, formData, body)
  let scheme = call_590861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590861.url(scheme.get, call_590861.host, call_590861.base,
                         call_590861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590861, url, valid)

proc call*(call_590932: Call_CancelTaskExecution_590703; body: JsonNode): Recallable =
  ## cancelTaskExecution
  ## <p>Cancels execution of a task. </p> <p>When you cancel a task execution, the transfer of some files are abruptly interrupted. The contents of files that are transferred to the destination might be incomplete or inconsistent with the source files. However, if you start a new task execution on the same task and you allow the task execution to complete, file content on the destination is complete and consistent. This applies to other unexpected failures that interrupt a task execution. In all of these cases, AWS DataSync successfully complete the transfer when you start the next task execution.</p>
  ##   body: JObject (required)
  var body_590933 = newJObject()
  if body != nil:
    body_590933 = body
  result = call_590932.call(nil, nil, nil, nil, body_590933)

var cancelTaskExecution* = Call_CancelTaskExecution_590703(
    name: "cancelTaskExecution", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CancelTaskExecution",
    validator: validate_CancelTaskExecution_590704, base: "/",
    url: url_CancelTaskExecution_590705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAgent_590972 = ref object of OpenApiRestCall_590364
proc url_CreateAgent_590974(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAgent_590973(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590975 = header.getOrDefault("X-Amz-Target")
  valid_590975 = validateParameter(valid_590975, JString, required = true, default = newJString(
      "FmrsService.CreateAgent"))
  if valid_590975 != nil:
    section.add "X-Amz-Target", valid_590975
  var valid_590976 = header.getOrDefault("X-Amz-Signature")
  valid_590976 = validateParameter(valid_590976, JString, required = false,
                                 default = nil)
  if valid_590976 != nil:
    section.add "X-Amz-Signature", valid_590976
  var valid_590977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "X-Amz-Content-Sha256", valid_590977
  var valid_590978 = header.getOrDefault("X-Amz-Date")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Date", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Credential")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Credential", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Security-Token")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Security-Token", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-Algorithm")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-Algorithm", valid_590981
  var valid_590982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590982 = validateParameter(valid_590982, JString, required = false,
                                 default = nil)
  if valid_590982 != nil:
    section.add "X-Amz-SignedHeaders", valid_590982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590984: Call_CreateAgent_590972; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Activates an AWS DataSync agent that you have deployed on your host. The activation process associates your agent with your account. In the activation process, you specify information such as the AWS Region that you want to activate the agent in. You activate the agent in the AWS Region where your target locations (in Amazon S3 or Amazon EFS) reside. Your tasks are created in this AWS Region.</p> <p>You can activate the agent in a VPC (Virtual private Cloud) or provide the agent access to a VPC endpoint so you can run tasks without going over the public Internet.</p> <p>You can use an agent for more than one location. If a task uses multiple agents, all of them need to have status AVAILABLE for the task to run. If you use multiple agents for a source location, the status of all the agents must be AVAILABLE for the task to run. </p> <p>Agents are automatically updated by AWS on a regular basis, using a mechanism that ensures minimal interruption to your tasks.</p> <p/>
  ## 
  let valid = call_590984.validator(path, query, header, formData, body)
  let scheme = call_590984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590984.url(scheme.get, call_590984.host, call_590984.base,
                         call_590984.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590984, url, valid)

proc call*(call_590985: Call_CreateAgent_590972; body: JsonNode): Recallable =
  ## createAgent
  ## <p>Activates an AWS DataSync agent that you have deployed on your host. The activation process associates your agent with your account. In the activation process, you specify information such as the AWS Region that you want to activate the agent in. You activate the agent in the AWS Region where your target locations (in Amazon S3 or Amazon EFS) reside. Your tasks are created in this AWS Region.</p> <p>You can activate the agent in a VPC (Virtual private Cloud) or provide the agent access to a VPC endpoint so you can run tasks without going over the public Internet.</p> <p>You can use an agent for more than one location. If a task uses multiple agents, all of them need to have status AVAILABLE for the task to run. If you use multiple agents for a source location, the status of all the agents must be AVAILABLE for the task to run. </p> <p>Agents are automatically updated by AWS on a regular basis, using a mechanism that ensures minimal interruption to your tasks.</p> <p/>
  ##   body: JObject (required)
  var body_590986 = newJObject()
  if body != nil:
    body_590986 = body
  result = call_590985.call(nil, nil, nil, nil, body_590986)

var createAgent* = Call_CreateAgent_590972(name: "createAgent",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.CreateAgent",
                                        validator: validate_CreateAgent_590973,
                                        base: "/", url: url_CreateAgent_590974,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationEfs_590987 = ref object of OpenApiRestCall_590364
proc url_CreateLocationEfs_590989(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLocationEfs_590988(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_590990 = header.getOrDefault("X-Amz-Target")
  valid_590990 = validateParameter(valid_590990, JString, required = true, default = newJString(
      "FmrsService.CreateLocationEfs"))
  if valid_590990 != nil:
    section.add "X-Amz-Target", valid_590990
  var valid_590991 = header.getOrDefault("X-Amz-Signature")
  valid_590991 = validateParameter(valid_590991, JString, required = false,
                                 default = nil)
  if valid_590991 != nil:
    section.add "X-Amz-Signature", valid_590991
  var valid_590992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Content-Sha256", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Date")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Date", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Credential")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Credential", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-Security-Token")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-Security-Token", valid_590995
  var valid_590996 = header.getOrDefault("X-Amz-Algorithm")
  valid_590996 = validateParameter(valid_590996, JString, required = false,
                                 default = nil)
  if valid_590996 != nil:
    section.add "X-Amz-Algorithm", valid_590996
  var valid_590997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590997 = validateParameter(valid_590997, JString, required = false,
                                 default = nil)
  if valid_590997 != nil:
    section.add "X-Amz-SignedHeaders", valid_590997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590999: Call_CreateLocationEfs_590987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an endpoint for an Amazon EFS file system.
  ## 
  let valid = call_590999.validator(path, query, header, formData, body)
  let scheme = call_590999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590999.url(scheme.get, call_590999.host, call_590999.base,
                         call_590999.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590999, url, valid)

proc call*(call_591000: Call_CreateLocationEfs_590987; body: JsonNode): Recallable =
  ## createLocationEfs
  ## Creates an endpoint for an Amazon EFS file system.
  ##   body: JObject (required)
  var body_591001 = newJObject()
  if body != nil:
    body_591001 = body
  result = call_591000.call(nil, nil, nil, nil, body_591001)

var createLocationEfs* = Call_CreateLocationEfs_590987(name: "createLocationEfs",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationEfs",
    validator: validate_CreateLocationEfs_590988, base: "/",
    url: url_CreateLocationEfs_590989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationNfs_591002 = ref object of OpenApiRestCall_590364
proc url_CreateLocationNfs_591004(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLocationNfs_591003(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591005 = header.getOrDefault("X-Amz-Target")
  valid_591005 = validateParameter(valid_591005, JString, required = true, default = newJString(
      "FmrsService.CreateLocationNfs"))
  if valid_591005 != nil:
    section.add "X-Amz-Target", valid_591005
  var valid_591006 = header.getOrDefault("X-Amz-Signature")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "X-Amz-Signature", valid_591006
  var valid_591007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591007 = validateParameter(valid_591007, JString, required = false,
                                 default = nil)
  if valid_591007 != nil:
    section.add "X-Amz-Content-Sha256", valid_591007
  var valid_591008 = header.getOrDefault("X-Amz-Date")
  valid_591008 = validateParameter(valid_591008, JString, required = false,
                                 default = nil)
  if valid_591008 != nil:
    section.add "X-Amz-Date", valid_591008
  var valid_591009 = header.getOrDefault("X-Amz-Credential")
  valid_591009 = validateParameter(valid_591009, JString, required = false,
                                 default = nil)
  if valid_591009 != nil:
    section.add "X-Amz-Credential", valid_591009
  var valid_591010 = header.getOrDefault("X-Amz-Security-Token")
  valid_591010 = validateParameter(valid_591010, JString, required = false,
                                 default = nil)
  if valid_591010 != nil:
    section.add "X-Amz-Security-Token", valid_591010
  var valid_591011 = header.getOrDefault("X-Amz-Algorithm")
  valid_591011 = validateParameter(valid_591011, JString, required = false,
                                 default = nil)
  if valid_591011 != nil:
    section.add "X-Amz-Algorithm", valid_591011
  var valid_591012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591012 = validateParameter(valid_591012, JString, required = false,
                                 default = nil)
  if valid_591012 != nil:
    section.add "X-Amz-SignedHeaders", valid_591012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591014: Call_CreateLocationNfs_591002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines a file system on a Network File System (NFS) server that can be read from or written to
  ## 
  let valid = call_591014.validator(path, query, header, formData, body)
  let scheme = call_591014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591014.url(scheme.get, call_591014.host, call_591014.base,
                         call_591014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591014, url, valid)

proc call*(call_591015: Call_CreateLocationNfs_591002; body: JsonNode): Recallable =
  ## createLocationNfs
  ## Defines a file system on a Network File System (NFS) server that can be read from or written to
  ##   body: JObject (required)
  var body_591016 = newJObject()
  if body != nil:
    body_591016 = body
  result = call_591015.call(nil, nil, nil, nil, body_591016)

var createLocationNfs* = Call_CreateLocationNfs_591002(name: "createLocationNfs",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationNfs",
    validator: validate_CreateLocationNfs_591003, base: "/",
    url: url_CreateLocationNfs_591004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationS3_591017 = ref object of OpenApiRestCall_590364
proc url_CreateLocationS3_591019(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLocationS3_591018(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591020 = header.getOrDefault("X-Amz-Target")
  valid_591020 = validateParameter(valid_591020, JString, required = true, default = newJString(
      "FmrsService.CreateLocationS3"))
  if valid_591020 != nil:
    section.add "X-Amz-Target", valid_591020
  var valid_591021 = header.getOrDefault("X-Amz-Signature")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "X-Amz-Signature", valid_591021
  var valid_591022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = nil)
  if valid_591022 != nil:
    section.add "X-Amz-Content-Sha256", valid_591022
  var valid_591023 = header.getOrDefault("X-Amz-Date")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-Date", valid_591023
  var valid_591024 = header.getOrDefault("X-Amz-Credential")
  valid_591024 = validateParameter(valid_591024, JString, required = false,
                                 default = nil)
  if valid_591024 != nil:
    section.add "X-Amz-Credential", valid_591024
  var valid_591025 = header.getOrDefault("X-Amz-Security-Token")
  valid_591025 = validateParameter(valid_591025, JString, required = false,
                                 default = nil)
  if valid_591025 != nil:
    section.add "X-Amz-Security-Token", valid_591025
  var valid_591026 = header.getOrDefault("X-Amz-Algorithm")
  valid_591026 = validateParameter(valid_591026, JString, required = false,
                                 default = nil)
  if valid_591026 != nil:
    section.add "X-Amz-Algorithm", valid_591026
  var valid_591027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591027 = validateParameter(valid_591027, JString, required = false,
                                 default = nil)
  if valid_591027 != nil:
    section.add "X-Amz-SignedHeaders", valid_591027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591029: Call_CreateLocationS3_591017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for an Amazon S3 bucket.</p> <p>For AWS DataSync to access a destination S3 bucket, it needs an AWS Identity and Access Management (IAM) role that has the required permissions. You can set up the required permissions by creating an IAM policy that grants the required permissions and attaching the policy to the role. An example of such a policy is shown in the examples section.</p> <p>For more information, see https://docs.aws.amazon.com/datasync/latest/userguide/working-with-locations.html#create-s3-location in the <i>AWS DataSync User Guide.</i> </p>
  ## 
  let valid = call_591029.validator(path, query, header, formData, body)
  let scheme = call_591029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591029.url(scheme.get, call_591029.host, call_591029.base,
                         call_591029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591029, url, valid)

proc call*(call_591030: Call_CreateLocationS3_591017; body: JsonNode): Recallable =
  ## createLocationS3
  ## <p>Creates an endpoint for an Amazon S3 bucket.</p> <p>For AWS DataSync to access a destination S3 bucket, it needs an AWS Identity and Access Management (IAM) role that has the required permissions. You can set up the required permissions by creating an IAM policy that grants the required permissions and attaching the policy to the role. An example of such a policy is shown in the examples section.</p> <p>For more information, see https://docs.aws.amazon.com/datasync/latest/userguide/working-with-locations.html#create-s3-location in the <i>AWS DataSync User Guide.</i> </p>
  ##   body: JObject (required)
  var body_591031 = newJObject()
  if body != nil:
    body_591031 = body
  result = call_591030.call(nil, nil, nil, nil, body_591031)

var createLocationS3* = Call_CreateLocationS3_591017(name: "createLocationS3",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationS3",
    validator: validate_CreateLocationS3_591018, base: "/",
    url: url_CreateLocationS3_591019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLocationSmb_591032 = ref object of OpenApiRestCall_590364
proc url_CreateLocationSmb_591034(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLocationSmb_591033(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Defines a file system on an Server Message Block (SMB) server that can be read from or written to
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
  var valid_591035 = header.getOrDefault("X-Amz-Target")
  valid_591035 = validateParameter(valid_591035, JString, required = true, default = newJString(
      "FmrsService.CreateLocationSmb"))
  if valid_591035 != nil:
    section.add "X-Amz-Target", valid_591035
  var valid_591036 = header.getOrDefault("X-Amz-Signature")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-Signature", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-Content-Sha256", valid_591037
  var valid_591038 = header.getOrDefault("X-Amz-Date")
  valid_591038 = validateParameter(valid_591038, JString, required = false,
                                 default = nil)
  if valid_591038 != nil:
    section.add "X-Amz-Date", valid_591038
  var valid_591039 = header.getOrDefault("X-Amz-Credential")
  valid_591039 = validateParameter(valid_591039, JString, required = false,
                                 default = nil)
  if valid_591039 != nil:
    section.add "X-Amz-Credential", valid_591039
  var valid_591040 = header.getOrDefault("X-Amz-Security-Token")
  valid_591040 = validateParameter(valid_591040, JString, required = false,
                                 default = nil)
  if valid_591040 != nil:
    section.add "X-Amz-Security-Token", valid_591040
  var valid_591041 = header.getOrDefault("X-Amz-Algorithm")
  valid_591041 = validateParameter(valid_591041, JString, required = false,
                                 default = nil)
  if valid_591041 != nil:
    section.add "X-Amz-Algorithm", valid_591041
  var valid_591042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591042 = validateParameter(valid_591042, JString, required = false,
                                 default = nil)
  if valid_591042 != nil:
    section.add "X-Amz-SignedHeaders", valid_591042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591044: Call_CreateLocationSmb_591032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Defines a file system on an Server Message Block (SMB) server that can be read from or written to
  ## 
  let valid = call_591044.validator(path, query, header, formData, body)
  let scheme = call_591044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591044.url(scheme.get, call_591044.host, call_591044.base,
                         call_591044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591044, url, valid)

proc call*(call_591045: Call_CreateLocationSmb_591032; body: JsonNode): Recallable =
  ## createLocationSmb
  ## Defines a file system on an Server Message Block (SMB) server that can be read from or written to
  ##   body: JObject (required)
  var body_591046 = newJObject()
  if body != nil:
    body_591046 = body
  result = call_591045.call(nil, nil, nil, nil, body_591046)

var createLocationSmb* = Call_CreateLocationSmb_591032(name: "createLocationSmb",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.CreateLocationSmb",
    validator: validate_CreateLocationSmb_591033, base: "/",
    url: url_CreateLocationSmb_591034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTask_591047 = ref object of OpenApiRestCall_590364
proc url_CreateTask_591049(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateTask_591048(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591050 = header.getOrDefault("X-Amz-Target")
  valid_591050 = validateParameter(valid_591050, JString, required = true,
                                 default = newJString("FmrsService.CreateTask"))
  if valid_591050 != nil:
    section.add "X-Amz-Target", valid_591050
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

proc call*(call_591059: Call_CreateTask_591047; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a task. A task is a set of two locations (source and destination) and a set of Options that you use to control the behavior of a task. If you don't specify Options when you create a task, AWS DataSync populates them with service defaults.</p> <p>When you create a task, it first enters the CREATING state. During CREATING AWS DataSync attempts to mount the on-premises Network File System (NFS) location. The task transitions to the AVAILABLE state without waiting for the AWS location to become mounted. If required, AWS DataSync mounts the AWS location before each task execution.</p> <p>If an agent that is associated with a source (NFS) location goes offline, the task transitions to the UNAVAILABLE status. If the status of the task remains in the CREATING status for more than a few minutes, it means that your agent might be having trouble mounting the source NFS file system. Check the task's ErrorCode and ErrorDetail. Mount issues are often caused by either a misconfigured firewall or a mistyped NFS server host name.</p>
  ## 
  let valid = call_591059.validator(path, query, header, formData, body)
  let scheme = call_591059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591059.url(scheme.get, call_591059.host, call_591059.base,
                         call_591059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591059, url, valid)

proc call*(call_591060: Call_CreateTask_591047; body: JsonNode): Recallable =
  ## createTask
  ## <p>Creates a task. A task is a set of two locations (source and destination) and a set of Options that you use to control the behavior of a task. If you don't specify Options when you create a task, AWS DataSync populates them with service defaults.</p> <p>When you create a task, it first enters the CREATING state. During CREATING AWS DataSync attempts to mount the on-premises Network File System (NFS) location. The task transitions to the AVAILABLE state without waiting for the AWS location to become mounted. If required, AWS DataSync mounts the AWS location before each task execution.</p> <p>If an agent that is associated with a source (NFS) location goes offline, the task transitions to the UNAVAILABLE status. If the status of the task remains in the CREATING status for more than a few minutes, it means that your agent might be having trouble mounting the source NFS file system. Check the task's ErrorCode and ErrorDetail. Mount issues are often caused by either a misconfigured firewall or a mistyped NFS server host name.</p>
  ##   body: JObject (required)
  var body_591061 = newJObject()
  if body != nil:
    body_591061 = body
  result = call_591060.call(nil, nil, nil, nil, body_591061)

var createTask* = Call_CreateTask_591047(name: "createTask",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.CreateTask",
                                      validator: validate_CreateTask_591048,
                                      base: "/", url: url_CreateTask_591049,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAgent_591062 = ref object of OpenApiRestCall_590364
proc url_DeleteAgent_591064(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAgent_591063(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591065 = header.getOrDefault("X-Amz-Target")
  valid_591065 = validateParameter(valid_591065, JString, required = true, default = newJString(
      "FmrsService.DeleteAgent"))
  if valid_591065 != nil:
    section.add "X-Amz-Target", valid_591065
  var valid_591066 = header.getOrDefault("X-Amz-Signature")
  valid_591066 = validateParameter(valid_591066, JString, required = false,
                                 default = nil)
  if valid_591066 != nil:
    section.add "X-Amz-Signature", valid_591066
  var valid_591067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591067 = validateParameter(valid_591067, JString, required = false,
                                 default = nil)
  if valid_591067 != nil:
    section.add "X-Amz-Content-Sha256", valid_591067
  var valid_591068 = header.getOrDefault("X-Amz-Date")
  valid_591068 = validateParameter(valid_591068, JString, required = false,
                                 default = nil)
  if valid_591068 != nil:
    section.add "X-Amz-Date", valid_591068
  var valid_591069 = header.getOrDefault("X-Amz-Credential")
  valid_591069 = validateParameter(valid_591069, JString, required = false,
                                 default = nil)
  if valid_591069 != nil:
    section.add "X-Amz-Credential", valid_591069
  var valid_591070 = header.getOrDefault("X-Amz-Security-Token")
  valid_591070 = validateParameter(valid_591070, JString, required = false,
                                 default = nil)
  if valid_591070 != nil:
    section.add "X-Amz-Security-Token", valid_591070
  var valid_591071 = header.getOrDefault("X-Amz-Algorithm")
  valid_591071 = validateParameter(valid_591071, JString, required = false,
                                 default = nil)
  if valid_591071 != nil:
    section.add "X-Amz-Algorithm", valid_591071
  var valid_591072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591072 = validateParameter(valid_591072, JString, required = false,
                                 default = nil)
  if valid_591072 != nil:
    section.add "X-Amz-SignedHeaders", valid_591072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591074: Call_DeleteAgent_591062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an agent. To specify which agent to delete, use the Amazon Resource Name (ARN) of the agent in your request. The operation disassociates the agent from your AWS account. However, it doesn't delete the agent virtual machine (VM) from your on-premises environment.
  ## 
  let valid = call_591074.validator(path, query, header, formData, body)
  let scheme = call_591074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591074.url(scheme.get, call_591074.host, call_591074.base,
                         call_591074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591074, url, valid)

proc call*(call_591075: Call_DeleteAgent_591062; body: JsonNode): Recallable =
  ## deleteAgent
  ## Deletes an agent. To specify which agent to delete, use the Amazon Resource Name (ARN) of the agent in your request. The operation disassociates the agent from your AWS account. However, it doesn't delete the agent virtual machine (VM) from your on-premises environment.
  ##   body: JObject (required)
  var body_591076 = newJObject()
  if body != nil:
    body_591076 = body
  result = call_591075.call(nil, nil, nil, nil, body_591076)

var deleteAgent* = Call_DeleteAgent_591062(name: "deleteAgent",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.DeleteAgent",
                                        validator: validate_DeleteAgent_591063,
                                        base: "/", url: url_DeleteAgent_591064,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLocation_591077 = ref object of OpenApiRestCall_590364
proc url_DeleteLocation_591079(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteLocation_591078(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591080 = header.getOrDefault("X-Amz-Target")
  valid_591080 = validateParameter(valid_591080, JString, required = true, default = newJString(
      "FmrsService.DeleteLocation"))
  if valid_591080 != nil:
    section.add "X-Amz-Target", valid_591080
  var valid_591081 = header.getOrDefault("X-Amz-Signature")
  valid_591081 = validateParameter(valid_591081, JString, required = false,
                                 default = nil)
  if valid_591081 != nil:
    section.add "X-Amz-Signature", valid_591081
  var valid_591082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591082 = validateParameter(valid_591082, JString, required = false,
                                 default = nil)
  if valid_591082 != nil:
    section.add "X-Amz-Content-Sha256", valid_591082
  var valid_591083 = header.getOrDefault("X-Amz-Date")
  valid_591083 = validateParameter(valid_591083, JString, required = false,
                                 default = nil)
  if valid_591083 != nil:
    section.add "X-Amz-Date", valid_591083
  var valid_591084 = header.getOrDefault("X-Amz-Credential")
  valid_591084 = validateParameter(valid_591084, JString, required = false,
                                 default = nil)
  if valid_591084 != nil:
    section.add "X-Amz-Credential", valid_591084
  var valid_591085 = header.getOrDefault("X-Amz-Security-Token")
  valid_591085 = validateParameter(valid_591085, JString, required = false,
                                 default = nil)
  if valid_591085 != nil:
    section.add "X-Amz-Security-Token", valid_591085
  var valid_591086 = header.getOrDefault("X-Amz-Algorithm")
  valid_591086 = validateParameter(valid_591086, JString, required = false,
                                 default = nil)
  if valid_591086 != nil:
    section.add "X-Amz-Algorithm", valid_591086
  var valid_591087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-SignedHeaders", valid_591087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591089: Call_DeleteLocation_591077; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the configuration of a location used by AWS DataSync. 
  ## 
  let valid = call_591089.validator(path, query, header, formData, body)
  let scheme = call_591089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591089.url(scheme.get, call_591089.host, call_591089.base,
                         call_591089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591089, url, valid)

proc call*(call_591090: Call_DeleteLocation_591077; body: JsonNode): Recallable =
  ## deleteLocation
  ## Deletes the configuration of a location used by AWS DataSync. 
  ##   body: JObject (required)
  var body_591091 = newJObject()
  if body != nil:
    body_591091 = body
  result = call_591090.call(nil, nil, nil, nil, body_591091)

var deleteLocation* = Call_DeleteLocation_591077(name: "deleteLocation",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DeleteLocation",
    validator: validate_DeleteLocation_591078, base: "/", url: url_DeleteLocation_591079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTask_591092 = ref object of OpenApiRestCall_590364
proc url_DeleteTask_591094(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteTask_591093(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591095 = header.getOrDefault("X-Amz-Target")
  valid_591095 = validateParameter(valid_591095, JString, required = true,
                                 default = newJString("FmrsService.DeleteTask"))
  if valid_591095 != nil:
    section.add "X-Amz-Target", valid_591095
  var valid_591096 = header.getOrDefault("X-Amz-Signature")
  valid_591096 = validateParameter(valid_591096, JString, required = false,
                                 default = nil)
  if valid_591096 != nil:
    section.add "X-Amz-Signature", valid_591096
  var valid_591097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591097 = validateParameter(valid_591097, JString, required = false,
                                 default = nil)
  if valid_591097 != nil:
    section.add "X-Amz-Content-Sha256", valid_591097
  var valid_591098 = header.getOrDefault("X-Amz-Date")
  valid_591098 = validateParameter(valid_591098, JString, required = false,
                                 default = nil)
  if valid_591098 != nil:
    section.add "X-Amz-Date", valid_591098
  var valid_591099 = header.getOrDefault("X-Amz-Credential")
  valid_591099 = validateParameter(valid_591099, JString, required = false,
                                 default = nil)
  if valid_591099 != nil:
    section.add "X-Amz-Credential", valid_591099
  var valid_591100 = header.getOrDefault("X-Amz-Security-Token")
  valid_591100 = validateParameter(valid_591100, JString, required = false,
                                 default = nil)
  if valid_591100 != nil:
    section.add "X-Amz-Security-Token", valid_591100
  var valid_591101 = header.getOrDefault("X-Amz-Algorithm")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-Algorithm", valid_591101
  var valid_591102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "X-Amz-SignedHeaders", valid_591102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591104: Call_DeleteTask_591092; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a task.
  ## 
  let valid = call_591104.validator(path, query, header, formData, body)
  let scheme = call_591104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591104.url(scheme.get, call_591104.host, call_591104.base,
                         call_591104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591104, url, valid)

proc call*(call_591105: Call_DeleteTask_591092; body: JsonNode): Recallable =
  ## deleteTask
  ## Deletes a task.
  ##   body: JObject (required)
  var body_591106 = newJObject()
  if body != nil:
    body_591106 = body
  result = call_591105.call(nil, nil, nil, nil, body_591106)

var deleteTask* = Call_DeleteTask_591092(name: "deleteTask",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.DeleteTask",
                                      validator: validate_DeleteTask_591093,
                                      base: "/", url: url_DeleteTask_591094,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAgent_591107 = ref object of OpenApiRestCall_590364
proc url_DescribeAgent_591109(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAgent_591108(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591110 = header.getOrDefault("X-Amz-Target")
  valid_591110 = validateParameter(valid_591110, JString, required = true, default = newJString(
      "FmrsService.DescribeAgent"))
  if valid_591110 != nil:
    section.add "X-Amz-Target", valid_591110
  var valid_591111 = header.getOrDefault("X-Amz-Signature")
  valid_591111 = validateParameter(valid_591111, JString, required = false,
                                 default = nil)
  if valid_591111 != nil:
    section.add "X-Amz-Signature", valid_591111
  var valid_591112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591112 = validateParameter(valid_591112, JString, required = false,
                                 default = nil)
  if valid_591112 != nil:
    section.add "X-Amz-Content-Sha256", valid_591112
  var valid_591113 = header.getOrDefault("X-Amz-Date")
  valid_591113 = validateParameter(valid_591113, JString, required = false,
                                 default = nil)
  if valid_591113 != nil:
    section.add "X-Amz-Date", valid_591113
  var valid_591114 = header.getOrDefault("X-Amz-Credential")
  valid_591114 = validateParameter(valid_591114, JString, required = false,
                                 default = nil)
  if valid_591114 != nil:
    section.add "X-Amz-Credential", valid_591114
  var valid_591115 = header.getOrDefault("X-Amz-Security-Token")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Security-Token", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-Algorithm")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-Algorithm", valid_591116
  var valid_591117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591117 = validateParameter(valid_591117, JString, required = false,
                                 default = nil)
  if valid_591117 != nil:
    section.add "X-Amz-SignedHeaders", valid_591117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591119: Call_DescribeAgent_591107; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata such as the name, the network interfaces, and the status (that is, whether the agent is running or not) for an agent. To specify which agent to describe, use the Amazon Resource Name (ARN) of the agent in your request. 
  ## 
  let valid = call_591119.validator(path, query, header, formData, body)
  let scheme = call_591119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591119.url(scheme.get, call_591119.host, call_591119.base,
                         call_591119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591119, url, valid)

proc call*(call_591120: Call_DescribeAgent_591107; body: JsonNode): Recallable =
  ## describeAgent
  ## Returns metadata such as the name, the network interfaces, and the status (that is, whether the agent is running or not) for an agent. To specify which agent to describe, use the Amazon Resource Name (ARN) of the agent in your request. 
  ##   body: JObject (required)
  var body_591121 = newJObject()
  if body != nil:
    body_591121 = body
  result = call_591120.call(nil, nil, nil, nil, body_591121)

var describeAgent* = Call_DescribeAgent_591107(name: "describeAgent",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeAgent",
    validator: validate_DescribeAgent_591108, base: "/", url: url_DescribeAgent_591109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationEfs_591122 = ref object of OpenApiRestCall_590364
proc url_DescribeLocationEfs_591124(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLocationEfs_591123(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591125 = header.getOrDefault("X-Amz-Target")
  valid_591125 = validateParameter(valid_591125, JString, required = true, default = newJString(
      "FmrsService.DescribeLocationEfs"))
  if valid_591125 != nil:
    section.add "X-Amz-Target", valid_591125
  var valid_591126 = header.getOrDefault("X-Amz-Signature")
  valid_591126 = validateParameter(valid_591126, JString, required = false,
                                 default = nil)
  if valid_591126 != nil:
    section.add "X-Amz-Signature", valid_591126
  var valid_591127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591127 = validateParameter(valid_591127, JString, required = false,
                                 default = nil)
  if valid_591127 != nil:
    section.add "X-Amz-Content-Sha256", valid_591127
  var valid_591128 = header.getOrDefault("X-Amz-Date")
  valid_591128 = validateParameter(valid_591128, JString, required = false,
                                 default = nil)
  if valid_591128 != nil:
    section.add "X-Amz-Date", valid_591128
  var valid_591129 = header.getOrDefault("X-Amz-Credential")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Credential", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Security-Token")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Security-Token", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-Algorithm")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-Algorithm", valid_591131
  var valid_591132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "X-Amz-SignedHeaders", valid_591132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591134: Call_DescribeLocationEfs_591122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as the path information about an Amazon EFS location.
  ## 
  let valid = call_591134.validator(path, query, header, formData, body)
  let scheme = call_591134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591134.url(scheme.get, call_591134.host, call_591134.base,
                         call_591134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591134, url, valid)

proc call*(call_591135: Call_DescribeLocationEfs_591122; body: JsonNode): Recallable =
  ## describeLocationEfs
  ## Returns metadata, such as the path information about an Amazon EFS location.
  ##   body: JObject (required)
  var body_591136 = newJObject()
  if body != nil:
    body_591136 = body
  result = call_591135.call(nil, nil, nil, nil, body_591136)

var describeLocationEfs* = Call_DescribeLocationEfs_591122(
    name: "describeLocationEfs", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationEfs",
    validator: validate_DescribeLocationEfs_591123, base: "/",
    url: url_DescribeLocationEfs_591124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationNfs_591137 = ref object of OpenApiRestCall_590364
proc url_DescribeLocationNfs_591139(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLocationNfs_591138(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591140 = header.getOrDefault("X-Amz-Target")
  valid_591140 = validateParameter(valid_591140, JString, required = true, default = newJString(
      "FmrsService.DescribeLocationNfs"))
  if valid_591140 != nil:
    section.add "X-Amz-Target", valid_591140
  var valid_591141 = header.getOrDefault("X-Amz-Signature")
  valid_591141 = validateParameter(valid_591141, JString, required = false,
                                 default = nil)
  if valid_591141 != nil:
    section.add "X-Amz-Signature", valid_591141
  var valid_591142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591142 = validateParameter(valid_591142, JString, required = false,
                                 default = nil)
  if valid_591142 != nil:
    section.add "X-Amz-Content-Sha256", valid_591142
  var valid_591143 = header.getOrDefault("X-Amz-Date")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Date", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-Credential")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-Credential", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-Security-Token")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-Security-Token", valid_591145
  var valid_591146 = header.getOrDefault("X-Amz-Algorithm")
  valid_591146 = validateParameter(valid_591146, JString, required = false,
                                 default = nil)
  if valid_591146 != nil:
    section.add "X-Amz-Algorithm", valid_591146
  var valid_591147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591147 = validateParameter(valid_591147, JString, required = false,
                                 default = nil)
  if valid_591147 != nil:
    section.add "X-Amz-SignedHeaders", valid_591147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591149: Call_DescribeLocationNfs_591137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as the path information, about a NFS location.
  ## 
  let valid = call_591149.validator(path, query, header, formData, body)
  let scheme = call_591149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591149.url(scheme.get, call_591149.host, call_591149.base,
                         call_591149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591149, url, valid)

proc call*(call_591150: Call_DescribeLocationNfs_591137; body: JsonNode): Recallable =
  ## describeLocationNfs
  ## Returns metadata, such as the path information, about a NFS location.
  ##   body: JObject (required)
  var body_591151 = newJObject()
  if body != nil:
    body_591151 = body
  result = call_591150.call(nil, nil, nil, nil, body_591151)

var describeLocationNfs* = Call_DescribeLocationNfs_591137(
    name: "describeLocationNfs", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationNfs",
    validator: validate_DescribeLocationNfs_591138, base: "/",
    url: url_DescribeLocationNfs_591139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationS3_591152 = ref object of OpenApiRestCall_590364
proc url_DescribeLocationS3_591154(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLocationS3_591153(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591155 = header.getOrDefault("X-Amz-Target")
  valid_591155 = validateParameter(valid_591155, JString, required = true, default = newJString(
      "FmrsService.DescribeLocationS3"))
  if valid_591155 != nil:
    section.add "X-Amz-Target", valid_591155
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

proc call*(call_591164: Call_DescribeLocationS3_591152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as bucket name, about an Amazon S3 bucket location.
  ## 
  let valid = call_591164.validator(path, query, header, formData, body)
  let scheme = call_591164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591164.url(scheme.get, call_591164.host, call_591164.base,
                         call_591164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591164, url, valid)

proc call*(call_591165: Call_DescribeLocationS3_591152; body: JsonNode): Recallable =
  ## describeLocationS3
  ## Returns metadata, such as bucket name, about an Amazon S3 bucket location.
  ##   body: JObject (required)
  var body_591166 = newJObject()
  if body != nil:
    body_591166 = body
  result = call_591165.call(nil, nil, nil, nil, body_591166)

var describeLocationS3* = Call_DescribeLocationS3_591152(
    name: "describeLocationS3", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationS3",
    validator: validate_DescribeLocationS3_591153, base: "/",
    url: url_DescribeLocationS3_591154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLocationSmb_591167 = ref object of OpenApiRestCall_590364
proc url_DescribeLocationSmb_591169(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeLocationSmb_591168(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591170 = header.getOrDefault("X-Amz-Target")
  valid_591170 = validateParameter(valid_591170, JString, required = true, default = newJString(
      "FmrsService.DescribeLocationSmb"))
  if valid_591170 != nil:
    section.add "X-Amz-Target", valid_591170
  var valid_591171 = header.getOrDefault("X-Amz-Signature")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-Signature", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Content-Sha256", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Date")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Date", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-Credential")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Credential", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Security-Token")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Security-Token", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-Algorithm")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-Algorithm", valid_591176
  var valid_591177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591177 = validateParameter(valid_591177, JString, required = false,
                                 default = nil)
  if valid_591177 != nil:
    section.add "X-Amz-SignedHeaders", valid_591177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591179: Call_DescribeLocationSmb_591167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata, such as the path and user information about a SMB location.
  ## 
  let valid = call_591179.validator(path, query, header, formData, body)
  let scheme = call_591179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591179.url(scheme.get, call_591179.host, call_591179.base,
                         call_591179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591179, url, valid)

proc call*(call_591180: Call_DescribeLocationSmb_591167; body: JsonNode): Recallable =
  ## describeLocationSmb
  ## Returns metadata, such as the path and user information about a SMB location.
  ##   body: JObject (required)
  var body_591181 = newJObject()
  if body != nil:
    body_591181 = body
  result = call_591180.call(nil, nil, nil, nil, body_591181)

var describeLocationSmb* = Call_DescribeLocationSmb_591167(
    name: "describeLocationSmb", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeLocationSmb",
    validator: validate_DescribeLocationSmb_591168, base: "/",
    url: url_DescribeLocationSmb_591169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTask_591182 = ref object of OpenApiRestCall_590364
proc url_DescribeTask_591184(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTask_591183(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591185 = header.getOrDefault("X-Amz-Target")
  valid_591185 = validateParameter(valid_591185, JString, required = true, default = newJString(
      "FmrsService.DescribeTask"))
  if valid_591185 != nil:
    section.add "X-Amz-Target", valid_591185
  var valid_591186 = header.getOrDefault("X-Amz-Signature")
  valid_591186 = validateParameter(valid_591186, JString, required = false,
                                 default = nil)
  if valid_591186 != nil:
    section.add "X-Amz-Signature", valid_591186
  var valid_591187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "X-Amz-Content-Sha256", valid_591187
  var valid_591188 = header.getOrDefault("X-Amz-Date")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "X-Amz-Date", valid_591188
  var valid_591189 = header.getOrDefault("X-Amz-Credential")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "X-Amz-Credential", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-Security-Token")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-Security-Token", valid_591190
  var valid_591191 = header.getOrDefault("X-Amz-Algorithm")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "X-Amz-Algorithm", valid_591191
  var valid_591192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591192 = validateParameter(valid_591192, JString, required = false,
                                 default = nil)
  if valid_591192 != nil:
    section.add "X-Amz-SignedHeaders", valid_591192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591194: Call_DescribeTask_591182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns metadata about a task.
  ## 
  let valid = call_591194.validator(path, query, header, formData, body)
  let scheme = call_591194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591194.url(scheme.get, call_591194.host, call_591194.base,
                         call_591194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591194, url, valid)

proc call*(call_591195: Call_DescribeTask_591182; body: JsonNode): Recallable =
  ## describeTask
  ## Returns metadata about a task.
  ##   body: JObject (required)
  var body_591196 = newJObject()
  if body != nil:
    body_591196 = body
  result = call_591195.call(nil, nil, nil, nil, body_591196)

var describeTask* = Call_DescribeTask_591182(name: "describeTask",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeTask",
    validator: validate_DescribeTask_591183, base: "/", url: url_DescribeTask_591184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTaskExecution_591197 = ref object of OpenApiRestCall_590364
proc url_DescribeTaskExecution_591199(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeTaskExecution_591198(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591200 = header.getOrDefault("X-Amz-Target")
  valid_591200 = validateParameter(valid_591200, JString, required = true, default = newJString(
      "FmrsService.DescribeTaskExecution"))
  if valid_591200 != nil:
    section.add "X-Amz-Target", valid_591200
  var valid_591201 = header.getOrDefault("X-Amz-Signature")
  valid_591201 = validateParameter(valid_591201, JString, required = false,
                                 default = nil)
  if valid_591201 != nil:
    section.add "X-Amz-Signature", valid_591201
  var valid_591202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591202 = validateParameter(valid_591202, JString, required = false,
                                 default = nil)
  if valid_591202 != nil:
    section.add "X-Amz-Content-Sha256", valid_591202
  var valid_591203 = header.getOrDefault("X-Amz-Date")
  valid_591203 = validateParameter(valid_591203, JString, required = false,
                                 default = nil)
  if valid_591203 != nil:
    section.add "X-Amz-Date", valid_591203
  var valid_591204 = header.getOrDefault("X-Amz-Credential")
  valid_591204 = validateParameter(valid_591204, JString, required = false,
                                 default = nil)
  if valid_591204 != nil:
    section.add "X-Amz-Credential", valid_591204
  var valid_591205 = header.getOrDefault("X-Amz-Security-Token")
  valid_591205 = validateParameter(valid_591205, JString, required = false,
                                 default = nil)
  if valid_591205 != nil:
    section.add "X-Amz-Security-Token", valid_591205
  var valid_591206 = header.getOrDefault("X-Amz-Algorithm")
  valid_591206 = validateParameter(valid_591206, JString, required = false,
                                 default = nil)
  if valid_591206 != nil:
    section.add "X-Amz-Algorithm", valid_591206
  var valid_591207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591207 = validateParameter(valid_591207, JString, required = false,
                                 default = nil)
  if valid_591207 != nil:
    section.add "X-Amz-SignedHeaders", valid_591207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591209: Call_DescribeTaskExecution_591197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns detailed metadata about a task that is being executed.
  ## 
  let valid = call_591209.validator(path, query, header, formData, body)
  let scheme = call_591209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591209.url(scheme.get, call_591209.host, call_591209.base,
                         call_591209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591209, url, valid)

proc call*(call_591210: Call_DescribeTaskExecution_591197; body: JsonNode): Recallable =
  ## describeTaskExecution
  ## Returns detailed metadata about a task that is being executed.
  ##   body: JObject (required)
  var body_591211 = newJObject()
  if body != nil:
    body_591211 = body
  result = call_591210.call(nil, nil, nil, nil, body_591211)

var describeTaskExecution* = Call_DescribeTaskExecution_591197(
    name: "describeTaskExecution", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.DescribeTaskExecution",
    validator: validate_DescribeTaskExecution_591198, base: "/",
    url: url_DescribeTaskExecution_591199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAgents_591212 = ref object of OpenApiRestCall_590364
proc url_ListAgents_591214(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAgents_591213(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591215 = query.getOrDefault("MaxResults")
  valid_591215 = validateParameter(valid_591215, JString, required = false,
                                 default = nil)
  if valid_591215 != nil:
    section.add "MaxResults", valid_591215
  var valid_591216 = query.getOrDefault("NextToken")
  valid_591216 = validateParameter(valid_591216, JString, required = false,
                                 default = nil)
  if valid_591216 != nil:
    section.add "NextToken", valid_591216
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
  var valid_591217 = header.getOrDefault("X-Amz-Target")
  valid_591217 = validateParameter(valid_591217, JString, required = true,
                                 default = newJString("FmrsService.ListAgents"))
  if valid_591217 != nil:
    section.add "X-Amz-Target", valid_591217
  var valid_591218 = header.getOrDefault("X-Amz-Signature")
  valid_591218 = validateParameter(valid_591218, JString, required = false,
                                 default = nil)
  if valid_591218 != nil:
    section.add "X-Amz-Signature", valid_591218
  var valid_591219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591219 = validateParameter(valid_591219, JString, required = false,
                                 default = nil)
  if valid_591219 != nil:
    section.add "X-Amz-Content-Sha256", valid_591219
  var valid_591220 = header.getOrDefault("X-Amz-Date")
  valid_591220 = validateParameter(valid_591220, JString, required = false,
                                 default = nil)
  if valid_591220 != nil:
    section.add "X-Amz-Date", valid_591220
  var valid_591221 = header.getOrDefault("X-Amz-Credential")
  valid_591221 = validateParameter(valid_591221, JString, required = false,
                                 default = nil)
  if valid_591221 != nil:
    section.add "X-Amz-Credential", valid_591221
  var valid_591222 = header.getOrDefault("X-Amz-Security-Token")
  valid_591222 = validateParameter(valid_591222, JString, required = false,
                                 default = nil)
  if valid_591222 != nil:
    section.add "X-Amz-Security-Token", valid_591222
  var valid_591223 = header.getOrDefault("X-Amz-Algorithm")
  valid_591223 = validateParameter(valid_591223, JString, required = false,
                                 default = nil)
  if valid_591223 != nil:
    section.add "X-Amz-Algorithm", valid_591223
  var valid_591224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591224 = validateParameter(valid_591224, JString, required = false,
                                 default = nil)
  if valid_591224 != nil:
    section.add "X-Amz-SignedHeaders", valid_591224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591226: Call_ListAgents_591212; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of agents owned by an AWS account in the AWS Region specified in the request. The returned list is ordered by agent Amazon Resource Name (ARN).</p> <p>By default, this operation returns a maximum of 100 agents. This operation supports pagination that enables you to optionally reduce the number of agents returned in a response.</p> <p>If you have more agents than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a marker that you can specify in your next request to fetch the next page of agents.</p>
  ## 
  let valid = call_591226.validator(path, query, header, formData, body)
  let scheme = call_591226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591226.url(scheme.get, call_591226.host, call_591226.base,
                         call_591226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591226, url, valid)

proc call*(call_591227: Call_ListAgents_591212; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAgents
  ## <p>Returns a list of agents owned by an AWS account in the AWS Region specified in the request. The returned list is ordered by agent Amazon Resource Name (ARN).</p> <p>By default, this operation returns a maximum of 100 agents. This operation supports pagination that enables you to optionally reduce the number of agents returned in a response.</p> <p>If you have more agents than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a marker that you can specify in your next request to fetch the next page of agents.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591228 = newJObject()
  var body_591229 = newJObject()
  add(query_591228, "MaxResults", newJString(MaxResults))
  add(query_591228, "NextToken", newJString(NextToken))
  if body != nil:
    body_591229 = body
  result = call_591227.call(nil, query_591228, nil, nil, body_591229)

var listAgents* = Call_ListAgents_591212(name: "listAgents",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.ListAgents",
                                      validator: validate_ListAgents_591213,
                                      base: "/", url: url_ListAgents_591214,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLocations_591231 = ref object of OpenApiRestCall_590364
proc url_ListLocations_591233(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLocations_591232(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591234 = query.getOrDefault("MaxResults")
  valid_591234 = validateParameter(valid_591234, JString, required = false,
                                 default = nil)
  if valid_591234 != nil:
    section.add "MaxResults", valid_591234
  var valid_591235 = query.getOrDefault("NextToken")
  valid_591235 = validateParameter(valid_591235, JString, required = false,
                                 default = nil)
  if valid_591235 != nil:
    section.add "NextToken", valid_591235
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
  var valid_591236 = header.getOrDefault("X-Amz-Target")
  valid_591236 = validateParameter(valid_591236, JString, required = true, default = newJString(
      "FmrsService.ListLocations"))
  if valid_591236 != nil:
    section.add "X-Amz-Target", valid_591236
  var valid_591237 = header.getOrDefault("X-Amz-Signature")
  valid_591237 = validateParameter(valid_591237, JString, required = false,
                                 default = nil)
  if valid_591237 != nil:
    section.add "X-Amz-Signature", valid_591237
  var valid_591238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591238 = validateParameter(valid_591238, JString, required = false,
                                 default = nil)
  if valid_591238 != nil:
    section.add "X-Amz-Content-Sha256", valid_591238
  var valid_591239 = header.getOrDefault("X-Amz-Date")
  valid_591239 = validateParameter(valid_591239, JString, required = false,
                                 default = nil)
  if valid_591239 != nil:
    section.add "X-Amz-Date", valid_591239
  var valid_591240 = header.getOrDefault("X-Amz-Credential")
  valid_591240 = validateParameter(valid_591240, JString, required = false,
                                 default = nil)
  if valid_591240 != nil:
    section.add "X-Amz-Credential", valid_591240
  var valid_591241 = header.getOrDefault("X-Amz-Security-Token")
  valid_591241 = validateParameter(valid_591241, JString, required = false,
                                 default = nil)
  if valid_591241 != nil:
    section.add "X-Amz-Security-Token", valid_591241
  var valid_591242 = header.getOrDefault("X-Amz-Algorithm")
  valid_591242 = validateParameter(valid_591242, JString, required = false,
                                 default = nil)
  if valid_591242 != nil:
    section.add "X-Amz-Algorithm", valid_591242
  var valid_591243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591243 = validateParameter(valid_591243, JString, required = false,
                                 default = nil)
  if valid_591243 != nil:
    section.add "X-Amz-SignedHeaders", valid_591243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591245: Call_ListLocations_591231; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a lists of source and destination locations.</p> <p>If you have more locations than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a token that you can specify in your next request to fetch the next page of locations.</p>
  ## 
  let valid = call_591245.validator(path, query, header, formData, body)
  let scheme = call_591245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591245.url(scheme.get, call_591245.host, call_591245.base,
                         call_591245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591245, url, valid)

proc call*(call_591246: Call_ListLocations_591231; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLocations
  ## <p>Returns a lists of source and destination locations.</p> <p>If you have more locations than are returned in a response (that is, the response returns only a truncated list of your agents), the response contains a token that you can specify in your next request to fetch the next page of locations.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591247 = newJObject()
  var body_591248 = newJObject()
  add(query_591247, "MaxResults", newJString(MaxResults))
  add(query_591247, "NextToken", newJString(NextToken))
  if body != nil:
    body_591248 = body
  result = call_591246.call(nil, query_591247, nil, nil, body_591248)

var listLocations* = Call_ListLocations_591231(name: "listLocations",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.ListLocations",
    validator: validate_ListLocations_591232, base: "/", url: url_ListLocations_591233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_591249 = ref object of OpenApiRestCall_590364
proc url_ListTagsForResource_591251(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_591250(path: JsonNode; query: JsonNode;
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
  var valid_591252 = query.getOrDefault("MaxResults")
  valid_591252 = validateParameter(valid_591252, JString, required = false,
                                 default = nil)
  if valid_591252 != nil:
    section.add "MaxResults", valid_591252
  var valid_591253 = query.getOrDefault("NextToken")
  valid_591253 = validateParameter(valid_591253, JString, required = false,
                                 default = nil)
  if valid_591253 != nil:
    section.add "NextToken", valid_591253
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
  var valid_591254 = header.getOrDefault("X-Amz-Target")
  valid_591254 = validateParameter(valid_591254, JString, required = true, default = newJString(
      "FmrsService.ListTagsForResource"))
  if valid_591254 != nil:
    section.add "X-Amz-Target", valid_591254
  var valid_591255 = header.getOrDefault("X-Amz-Signature")
  valid_591255 = validateParameter(valid_591255, JString, required = false,
                                 default = nil)
  if valid_591255 != nil:
    section.add "X-Amz-Signature", valid_591255
  var valid_591256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591256 = validateParameter(valid_591256, JString, required = false,
                                 default = nil)
  if valid_591256 != nil:
    section.add "X-Amz-Content-Sha256", valid_591256
  var valid_591257 = header.getOrDefault("X-Amz-Date")
  valid_591257 = validateParameter(valid_591257, JString, required = false,
                                 default = nil)
  if valid_591257 != nil:
    section.add "X-Amz-Date", valid_591257
  var valid_591258 = header.getOrDefault("X-Amz-Credential")
  valid_591258 = validateParameter(valid_591258, JString, required = false,
                                 default = nil)
  if valid_591258 != nil:
    section.add "X-Amz-Credential", valid_591258
  var valid_591259 = header.getOrDefault("X-Amz-Security-Token")
  valid_591259 = validateParameter(valid_591259, JString, required = false,
                                 default = nil)
  if valid_591259 != nil:
    section.add "X-Amz-Security-Token", valid_591259
  var valid_591260 = header.getOrDefault("X-Amz-Algorithm")
  valid_591260 = validateParameter(valid_591260, JString, required = false,
                                 default = nil)
  if valid_591260 != nil:
    section.add "X-Amz-Algorithm", valid_591260
  var valid_591261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591261 = validateParameter(valid_591261, JString, required = false,
                                 default = nil)
  if valid_591261 != nil:
    section.add "X-Amz-SignedHeaders", valid_591261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591263: Call_ListTagsForResource_591249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all the tags associated with a specified resources. 
  ## 
  let valid = call_591263.validator(path, query, header, formData, body)
  let scheme = call_591263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591263.url(scheme.get, call_591263.host, call_591263.base,
                         call_591263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591263, url, valid)

proc call*(call_591264: Call_ListTagsForResource_591249; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTagsForResource
  ## Returns all the tags associated with a specified resources. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591265 = newJObject()
  var body_591266 = newJObject()
  add(query_591265, "MaxResults", newJString(MaxResults))
  add(query_591265, "NextToken", newJString(NextToken))
  if body != nil:
    body_591266 = body
  result = call_591264.call(nil, query_591265, nil, nil, body_591266)

var listTagsForResource* = Call_ListTagsForResource_591249(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.ListTagsForResource",
    validator: validate_ListTagsForResource_591250, base: "/",
    url: url_ListTagsForResource_591251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTaskExecutions_591267 = ref object of OpenApiRestCall_590364
proc url_ListTaskExecutions_591269(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTaskExecutions_591268(path: JsonNode; query: JsonNode;
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
  var valid_591270 = query.getOrDefault("MaxResults")
  valid_591270 = validateParameter(valid_591270, JString, required = false,
                                 default = nil)
  if valid_591270 != nil:
    section.add "MaxResults", valid_591270
  var valid_591271 = query.getOrDefault("NextToken")
  valid_591271 = validateParameter(valid_591271, JString, required = false,
                                 default = nil)
  if valid_591271 != nil:
    section.add "NextToken", valid_591271
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
  var valid_591272 = header.getOrDefault("X-Amz-Target")
  valid_591272 = validateParameter(valid_591272, JString, required = true, default = newJString(
      "FmrsService.ListTaskExecutions"))
  if valid_591272 != nil:
    section.add "X-Amz-Target", valid_591272
  var valid_591273 = header.getOrDefault("X-Amz-Signature")
  valid_591273 = validateParameter(valid_591273, JString, required = false,
                                 default = nil)
  if valid_591273 != nil:
    section.add "X-Amz-Signature", valid_591273
  var valid_591274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591274 = validateParameter(valid_591274, JString, required = false,
                                 default = nil)
  if valid_591274 != nil:
    section.add "X-Amz-Content-Sha256", valid_591274
  var valid_591275 = header.getOrDefault("X-Amz-Date")
  valid_591275 = validateParameter(valid_591275, JString, required = false,
                                 default = nil)
  if valid_591275 != nil:
    section.add "X-Amz-Date", valid_591275
  var valid_591276 = header.getOrDefault("X-Amz-Credential")
  valid_591276 = validateParameter(valid_591276, JString, required = false,
                                 default = nil)
  if valid_591276 != nil:
    section.add "X-Amz-Credential", valid_591276
  var valid_591277 = header.getOrDefault("X-Amz-Security-Token")
  valid_591277 = validateParameter(valid_591277, JString, required = false,
                                 default = nil)
  if valid_591277 != nil:
    section.add "X-Amz-Security-Token", valid_591277
  var valid_591278 = header.getOrDefault("X-Amz-Algorithm")
  valid_591278 = validateParameter(valid_591278, JString, required = false,
                                 default = nil)
  if valid_591278 != nil:
    section.add "X-Amz-Algorithm", valid_591278
  var valid_591279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591279 = validateParameter(valid_591279, JString, required = false,
                                 default = nil)
  if valid_591279 != nil:
    section.add "X-Amz-SignedHeaders", valid_591279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591281: Call_ListTaskExecutions_591267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of executed tasks.
  ## 
  let valid = call_591281.validator(path, query, header, formData, body)
  let scheme = call_591281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591281.url(scheme.get, call_591281.host, call_591281.base,
                         call_591281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591281, url, valid)

proc call*(call_591282: Call_ListTaskExecutions_591267; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTaskExecutions
  ## Returns a list of executed tasks.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591283 = newJObject()
  var body_591284 = newJObject()
  add(query_591283, "MaxResults", newJString(MaxResults))
  add(query_591283, "NextToken", newJString(NextToken))
  if body != nil:
    body_591284 = body
  result = call_591282.call(nil, query_591283, nil, nil, body_591284)

var listTaskExecutions* = Call_ListTaskExecutions_591267(
    name: "listTaskExecutions", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.ListTaskExecutions",
    validator: validate_ListTaskExecutions_591268, base: "/",
    url: url_ListTaskExecutions_591269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTasks_591285 = ref object of OpenApiRestCall_590364
proc url_ListTasks_591287(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTasks_591286(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591288 = query.getOrDefault("MaxResults")
  valid_591288 = validateParameter(valid_591288, JString, required = false,
                                 default = nil)
  if valid_591288 != nil:
    section.add "MaxResults", valid_591288
  var valid_591289 = query.getOrDefault("NextToken")
  valid_591289 = validateParameter(valid_591289, JString, required = false,
                                 default = nil)
  if valid_591289 != nil:
    section.add "NextToken", valid_591289
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
  var valid_591290 = header.getOrDefault("X-Amz-Target")
  valid_591290 = validateParameter(valid_591290, JString, required = true,
                                 default = newJString("FmrsService.ListTasks"))
  if valid_591290 != nil:
    section.add "X-Amz-Target", valid_591290
  var valid_591291 = header.getOrDefault("X-Amz-Signature")
  valid_591291 = validateParameter(valid_591291, JString, required = false,
                                 default = nil)
  if valid_591291 != nil:
    section.add "X-Amz-Signature", valid_591291
  var valid_591292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591292 = validateParameter(valid_591292, JString, required = false,
                                 default = nil)
  if valid_591292 != nil:
    section.add "X-Amz-Content-Sha256", valid_591292
  var valid_591293 = header.getOrDefault("X-Amz-Date")
  valid_591293 = validateParameter(valid_591293, JString, required = false,
                                 default = nil)
  if valid_591293 != nil:
    section.add "X-Amz-Date", valid_591293
  var valid_591294 = header.getOrDefault("X-Amz-Credential")
  valid_591294 = validateParameter(valid_591294, JString, required = false,
                                 default = nil)
  if valid_591294 != nil:
    section.add "X-Amz-Credential", valid_591294
  var valid_591295 = header.getOrDefault("X-Amz-Security-Token")
  valid_591295 = validateParameter(valid_591295, JString, required = false,
                                 default = nil)
  if valid_591295 != nil:
    section.add "X-Amz-Security-Token", valid_591295
  var valid_591296 = header.getOrDefault("X-Amz-Algorithm")
  valid_591296 = validateParameter(valid_591296, JString, required = false,
                                 default = nil)
  if valid_591296 != nil:
    section.add "X-Amz-Algorithm", valid_591296
  var valid_591297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591297 = validateParameter(valid_591297, JString, required = false,
                                 default = nil)
  if valid_591297 != nil:
    section.add "X-Amz-SignedHeaders", valid_591297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591299: Call_ListTasks_591285; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all the tasks.
  ## 
  let valid = call_591299.validator(path, query, header, formData, body)
  let scheme = call_591299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591299.url(scheme.get, call_591299.host, call_591299.base,
                         call_591299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591299, url, valid)

proc call*(call_591300: Call_ListTasks_591285; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTasks
  ## Returns a list of all the tasks.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_591301 = newJObject()
  var body_591302 = newJObject()
  add(query_591301, "MaxResults", newJString(MaxResults))
  add(query_591301, "NextToken", newJString(NextToken))
  if body != nil:
    body_591302 = body
  result = call_591300.call(nil, query_591301, nil, nil, body_591302)

var listTasks* = Call_ListTasks_591285(name: "listTasks", meth: HttpMethod.HttpPost,
                                    host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.ListTasks",
                                    validator: validate_ListTasks_591286,
                                    base: "/", url: url_ListTasks_591287,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTaskExecution_591303 = ref object of OpenApiRestCall_590364
proc url_StartTaskExecution_591305(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartTaskExecution_591304(path: JsonNode; query: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591306 = header.getOrDefault("X-Amz-Target")
  valid_591306 = validateParameter(valid_591306, JString, required = true, default = newJString(
      "FmrsService.StartTaskExecution"))
  if valid_591306 != nil:
    section.add "X-Amz-Target", valid_591306
  var valid_591307 = header.getOrDefault("X-Amz-Signature")
  valid_591307 = validateParameter(valid_591307, JString, required = false,
                                 default = nil)
  if valid_591307 != nil:
    section.add "X-Amz-Signature", valid_591307
  var valid_591308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591308 = validateParameter(valid_591308, JString, required = false,
                                 default = nil)
  if valid_591308 != nil:
    section.add "X-Amz-Content-Sha256", valid_591308
  var valid_591309 = header.getOrDefault("X-Amz-Date")
  valid_591309 = validateParameter(valid_591309, JString, required = false,
                                 default = nil)
  if valid_591309 != nil:
    section.add "X-Amz-Date", valid_591309
  var valid_591310 = header.getOrDefault("X-Amz-Credential")
  valid_591310 = validateParameter(valid_591310, JString, required = false,
                                 default = nil)
  if valid_591310 != nil:
    section.add "X-Amz-Credential", valid_591310
  var valid_591311 = header.getOrDefault("X-Amz-Security-Token")
  valid_591311 = validateParameter(valid_591311, JString, required = false,
                                 default = nil)
  if valid_591311 != nil:
    section.add "X-Amz-Security-Token", valid_591311
  var valid_591312 = header.getOrDefault("X-Amz-Algorithm")
  valid_591312 = validateParameter(valid_591312, JString, required = false,
                                 default = nil)
  if valid_591312 != nil:
    section.add "X-Amz-Algorithm", valid_591312
  var valid_591313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591313 = validateParameter(valid_591313, JString, required = false,
                                 default = nil)
  if valid_591313 != nil:
    section.add "X-Amz-SignedHeaders", valid_591313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591315: Call_StartTaskExecution_591303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts a specific invocation of a task. A <code>TaskExecution</code> value represents an individual run of a task. Each task can have at most one <code>TaskExecution</code> at a time.</p> <p> <code>TaskExecution</code> has the following transition phases: INITIALIZING | PREPARING | TRANSFERRING | VERIFYING | SUCCESS/FAILURE. </p> <p>For detailed information, see the Task Execution section in the Components and Terminology topic in the <i>AWS DataSync User Guide</i>.</p>
  ## 
  let valid = call_591315.validator(path, query, header, formData, body)
  let scheme = call_591315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591315.url(scheme.get, call_591315.host, call_591315.base,
                         call_591315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591315, url, valid)

proc call*(call_591316: Call_StartTaskExecution_591303; body: JsonNode): Recallable =
  ## startTaskExecution
  ## <p>Starts a specific invocation of a task. A <code>TaskExecution</code> value represents an individual run of a task. Each task can have at most one <code>TaskExecution</code> at a time.</p> <p> <code>TaskExecution</code> has the following transition phases: INITIALIZING | PREPARING | TRANSFERRING | VERIFYING | SUCCESS/FAILURE. </p> <p>For detailed information, see the Task Execution section in the Components and Terminology topic in the <i>AWS DataSync User Guide</i>.</p>
  ##   body: JObject (required)
  var body_591317 = newJObject()
  if body != nil:
    body_591317 = body
  result = call_591316.call(nil, nil, nil, nil, body_591317)

var startTaskExecution* = Call_StartTaskExecution_591303(
    name: "startTaskExecution", meth: HttpMethod.HttpPost,
    host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.StartTaskExecution",
    validator: validate_StartTaskExecution_591304, base: "/",
    url: url_StartTaskExecution_591305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_591318 = ref object of OpenApiRestCall_590364
proc url_TagResource_591320(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_591319(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591321 = header.getOrDefault("X-Amz-Target")
  valid_591321 = validateParameter(valid_591321, JString, required = true, default = newJString(
      "FmrsService.TagResource"))
  if valid_591321 != nil:
    section.add "X-Amz-Target", valid_591321
  var valid_591322 = header.getOrDefault("X-Amz-Signature")
  valid_591322 = validateParameter(valid_591322, JString, required = false,
                                 default = nil)
  if valid_591322 != nil:
    section.add "X-Amz-Signature", valid_591322
  var valid_591323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591323 = validateParameter(valid_591323, JString, required = false,
                                 default = nil)
  if valid_591323 != nil:
    section.add "X-Amz-Content-Sha256", valid_591323
  var valid_591324 = header.getOrDefault("X-Amz-Date")
  valid_591324 = validateParameter(valid_591324, JString, required = false,
                                 default = nil)
  if valid_591324 != nil:
    section.add "X-Amz-Date", valid_591324
  var valid_591325 = header.getOrDefault("X-Amz-Credential")
  valid_591325 = validateParameter(valid_591325, JString, required = false,
                                 default = nil)
  if valid_591325 != nil:
    section.add "X-Amz-Credential", valid_591325
  var valid_591326 = header.getOrDefault("X-Amz-Security-Token")
  valid_591326 = validateParameter(valid_591326, JString, required = false,
                                 default = nil)
  if valid_591326 != nil:
    section.add "X-Amz-Security-Token", valid_591326
  var valid_591327 = header.getOrDefault("X-Amz-Algorithm")
  valid_591327 = validateParameter(valid_591327, JString, required = false,
                                 default = nil)
  if valid_591327 != nil:
    section.add "X-Amz-Algorithm", valid_591327
  var valid_591328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591328 = validateParameter(valid_591328, JString, required = false,
                                 default = nil)
  if valid_591328 != nil:
    section.add "X-Amz-SignedHeaders", valid_591328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591330: Call_TagResource_591318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a key-value pair to an AWS resource.
  ## 
  let valid = call_591330.validator(path, query, header, formData, body)
  let scheme = call_591330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591330.url(scheme.get, call_591330.host, call_591330.base,
                         call_591330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591330, url, valid)

proc call*(call_591331: Call_TagResource_591318; body: JsonNode): Recallable =
  ## tagResource
  ## Applies a key-value pair to an AWS resource.
  ##   body: JObject (required)
  var body_591332 = newJObject()
  if body != nil:
    body_591332 = body
  result = call_591331.call(nil, nil, nil, nil, body_591332)

var tagResource* = Call_TagResource_591318(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.TagResource",
                                        validator: validate_TagResource_591319,
                                        base: "/", url: url_TagResource_591320,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_591333 = ref object of OpenApiRestCall_590364
proc url_UntagResource_591335(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_591334(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591336 = header.getOrDefault("X-Amz-Target")
  valid_591336 = validateParameter(valid_591336, JString, required = true, default = newJString(
      "FmrsService.UntagResource"))
  if valid_591336 != nil:
    section.add "X-Amz-Target", valid_591336
  var valid_591337 = header.getOrDefault("X-Amz-Signature")
  valid_591337 = validateParameter(valid_591337, JString, required = false,
                                 default = nil)
  if valid_591337 != nil:
    section.add "X-Amz-Signature", valid_591337
  var valid_591338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591338 = validateParameter(valid_591338, JString, required = false,
                                 default = nil)
  if valid_591338 != nil:
    section.add "X-Amz-Content-Sha256", valid_591338
  var valid_591339 = header.getOrDefault("X-Amz-Date")
  valid_591339 = validateParameter(valid_591339, JString, required = false,
                                 default = nil)
  if valid_591339 != nil:
    section.add "X-Amz-Date", valid_591339
  var valid_591340 = header.getOrDefault("X-Amz-Credential")
  valid_591340 = validateParameter(valid_591340, JString, required = false,
                                 default = nil)
  if valid_591340 != nil:
    section.add "X-Amz-Credential", valid_591340
  var valid_591341 = header.getOrDefault("X-Amz-Security-Token")
  valid_591341 = validateParameter(valid_591341, JString, required = false,
                                 default = nil)
  if valid_591341 != nil:
    section.add "X-Amz-Security-Token", valid_591341
  var valid_591342 = header.getOrDefault("X-Amz-Algorithm")
  valid_591342 = validateParameter(valid_591342, JString, required = false,
                                 default = nil)
  if valid_591342 != nil:
    section.add "X-Amz-Algorithm", valid_591342
  var valid_591343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591343 = validateParameter(valid_591343, JString, required = false,
                                 default = nil)
  if valid_591343 != nil:
    section.add "X-Amz-SignedHeaders", valid_591343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591345: Call_UntagResource_591333; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag from an AWS resource.
  ## 
  let valid = call_591345.validator(path, query, header, formData, body)
  let scheme = call_591345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591345.url(scheme.get, call_591345.host, call_591345.base,
                         call_591345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591345, url, valid)

proc call*(call_591346: Call_UntagResource_591333; body: JsonNode): Recallable =
  ## untagResource
  ## Removes a tag from an AWS resource.
  ##   body: JObject (required)
  var body_591347 = newJObject()
  if body != nil:
    body_591347 = body
  result = call_591346.call(nil, nil, nil, nil, body_591347)

var untagResource* = Call_UntagResource_591333(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "datasync.amazonaws.com",
    route: "/#X-Amz-Target=FmrsService.UntagResource",
    validator: validate_UntagResource_591334, base: "/", url: url_UntagResource_591335,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAgent_591348 = ref object of OpenApiRestCall_590364
proc url_UpdateAgent_591350(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateAgent_591349(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591351 = header.getOrDefault("X-Amz-Target")
  valid_591351 = validateParameter(valid_591351, JString, required = true, default = newJString(
      "FmrsService.UpdateAgent"))
  if valid_591351 != nil:
    section.add "X-Amz-Target", valid_591351
  var valid_591352 = header.getOrDefault("X-Amz-Signature")
  valid_591352 = validateParameter(valid_591352, JString, required = false,
                                 default = nil)
  if valid_591352 != nil:
    section.add "X-Amz-Signature", valid_591352
  var valid_591353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591353 = validateParameter(valid_591353, JString, required = false,
                                 default = nil)
  if valid_591353 != nil:
    section.add "X-Amz-Content-Sha256", valid_591353
  var valid_591354 = header.getOrDefault("X-Amz-Date")
  valid_591354 = validateParameter(valid_591354, JString, required = false,
                                 default = nil)
  if valid_591354 != nil:
    section.add "X-Amz-Date", valid_591354
  var valid_591355 = header.getOrDefault("X-Amz-Credential")
  valid_591355 = validateParameter(valid_591355, JString, required = false,
                                 default = nil)
  if valid_591355 != nil:
    section.add "X-Amz-Credential", valid_591355
  var valid_591356 = header.getOrDefault("X-Amz-Security-Token")
  valid_591356 = validateParameter(valid_591356, JString, required = false,
                                 default = nil)
  if valid_591356 != nil:
    section.add "X-Amz-Security-Token", valid_591356
  var valid_591357 = header.getOrDefault("X-Amz-Algorithm")
  valid_591357 = validateParameter(valid_591357, JString, required = false,
                                 default = nil)
  if valid_591357 != nil:
    section.add "X-Amz-Algorithm", valid_591357
  var valid_591358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591358 = validateParameter(valid_591358, JString, required = false,
                                 default = nil)
  if valid_591358 != nil:
    section.add "X-Amz-SignedHeaders", valid_591358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591360: Call_UpdateAgent_591348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name of an agent.
  ## 
  let valid = call_591360.validator(path, query, header, formData, body)
  let scheme = call_591360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591360.url(scheme.get, call_591360.host, call_591360.base,
                         call_591360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591360, url, valid)

proc call*(call_591361: Call_UpdateAgent_591348; body: JsonNode): Recallable =
  ## updateAgent
  ## Updates the name of an agent.
  ##   body: JObject (required)
  var body_591362 = newJObject()
  if body != nil:
    body_591362 = body
  result = call_591361.call(nil, nil, nil, nil, body_591362)

var updateAgent* = Call_UpdateAgent_591348(name: "updateAgent",
                                        meth: HttpMethod.HttpPost,
                                        host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.UpdateAgent",
                                        validator: validate_UpdateAgent_591349,
                                        base: "/", url: url_UpdateAgent_591350,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTask_591363 = ref object of OpenApiRestCall_590364
proc url_UpdateTask_591365(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateTask_591364(path: JsonNode; query: JsonNode; header: JsonNode;
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_591366 = header.getOrDefault("X-Amz-Target")
  valid_591366 = validateParameter(valid_591366, JString, required = true,
                                 default = newJString("FmrsService.UpdateTask"))
  if valid_591366 != nil:
    section.add "X-Amz-Target", valid_591366
  var valid_591367 = header.getOrDefault("X-Amz-Signature")
  valid_591367 = validateParameter(valid_591367, JString, required = false,
                                 default = nil)
  if valid_591367 != nil:
    section.add "X-Amz-Signature", valid_591367
  var valid_591368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591368 = validateParameter(valid_591368, JString, required = false,
                                 default = nil)
  if valid_591368 != nil:
    section.add "X-Amz-Content-Sha256", valid_591368
  var valid_591369 = header.getOrDefault("X-Amz-Date")
  valid_591369 = validateParameter(valid_591369, JString, required = false,
                                 default = nil)
  if valid_591369 != nil:
    section.add "X-Amz-Date", valid_591369
  var valid_591370 = header.getOrDefault("X-Amz-Credential")
  valid_591370 = validateParameter(valid_591370, JString, required = false,
                                 default = nil)
  if valid_591370 != nil:
    section.add "X-Amz-Credential", valid_591370
  var valid_591371 = header.getOrDefault("X-Amz-Security-Token")
  valid_591371 = validateParameter(valid_591371, JString, required = false,
                                 default = nil)
  if valid_591371 != nil:
    section.add "X-Amz-Security-Token", valid_591371
  var valid_591372 = header.getOrDefault("X-Amz-Algorithm")
  valid_591372 = validateParameter(valid_591372, JString, required = false,
                                 default = nil)
  if valid_591372 != nil:
    section.add "X-Amz-Algorithm", valid_591372
  var valid_591373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591373 = validateParameter(valid_591373, JString, required = false,
                                 default = nil)
  if valid_591373 != nil:
    section.add "X-Amz-SignedHeaders", valid_591373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591375: Call_UpdateTask_591363; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the metadata associated with a task.
  ## 
  let valid = call_591375.validator(path, query, header, formData, body)
  let scheme = call_591375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591375.url(scheme.get, call_591375.host, call_591375.base,
                         call_591375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591375, url, valid)

proc call*(call_591376: Call_UpdateTask_591363; body: JsonNode): Recallable =
  ## updateTask
  ## Updates the metadata associated with a task.
  ##   body: JObject (required)
  var body_591377 = newJObject()
  if body != nil:
    body_591377 = body
  result = call_591376.call(nil, nil, nil, nil, body_591377)

var updateTask* = Call_UpdateTask_591363(name: "updateTask",
                                      meth: HttpMethod.HttpPost,
                                      host: "datasync.amazonaws.com", route: "/#X-Amz-Target=FmrsService.UpdateTask",
                                      validator: validate_UpdateTask_591364,
                                      base: "/", url: url_UpdateTask_591365,
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
