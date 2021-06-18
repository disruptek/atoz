
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon GuardDuty
## version: 2017-11-28
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon GuardDuty is a continuous security monitoring service that analyzes and processes the following data sources: VPC Flow Logs, AWS CloudTrail event logs, and DNS logs. It uses threat intelligence feeds, such as lists of malicious IPs and domains, and machine learning to identify unexpected and potentially unauthorized and malicious activity within your AWS environment. This can include issues like escalations of privileges, uses of exposed credentials, or communication with malicious IPs, URLs, or domains. For example, GuardDuty can detect compromised EC2 instances serving malware or mining bitcoin. It also monitors AWS account access behavior for signs of compromise, such as unauthorized infrastructure deployments, like instances deployed in a region that has never been used, or unusual API calls, like a password policy change to reduce password strength. GuardDuty informs you of the status of your AWS environment by producing security findings that you can view in the GuardDuty console or through Amazon CloudWatch events. For more information, see <a href="https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html">Amazon GuardDuty User Guide</a>. 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/guardduty/
type
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "guardduty.ap-northeast-1.amazonaws.com", "ap-southeast-1": "guardduty.ap-southeast-1.amazonaws.com", "us-west-2": "guardduty.us-west-2.amazonaws.com", "eu-west-2": "guardduty.eu-west-2.amazonaws.com", "ap-northeast-3": "guardduty.ap-northeast-3.amazonaws.com", "eu-central-1": "guardduty.eu-central-1.amazonaws.com", "us-east-2": "guardduty.us-east-2.amazonaws.com", "us-east-1": "guardduty.us-east-1.amazonaws.com", "cn-northwest-1": "guardduty.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "guardduty.ap-south-1.amazonaws.com", "eu-north-1": "guardduty.eu-north-1.amazonaws.com", "ap-northeast-2": "guardduty.ap-northeast-2.amazonaws.com", "us-west-1": "guardduty.us-west-1.amazonaws.com", "us-gov-east-1": "guardduty.us-gov-east-1.amazonaws.com", "eu-west-3": "guardduty.eu-west-3.amazonaws.com", "cn-north-1": "guardduty.cn-north-1.amazonaws.com.cn", "sa-east-1": "guardduty.sa-east-1.amazonaws.com", "eu-west-1": "guardduty.eu-west-1.amazonaws.com", "us-gov-west-1": "guardduty.us-gov-west-1.amazonaws.com", "ap-southeast-2": "guardduty.ap-southeast-2.amazonaws.com", "ca-central-1": "guardduty.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "guardduty.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "guardduty.ap-southeast-1.amazonaws.com",
      "us-west-2": "guardduty.us-west-2.amazonaws.com",
      "eu-west-2": "guardduty.eu-west-2.amazonaws.com",
      "ap-northeast-3": "guardduty.ap-northeast-3.amazonaws.com",
      "eu-central-1": "guardduty.eu-central-1.amazonaws.com",
      "us-east-2": "guardduty.us-east-2.amazonaws.com",
      "us-east-1": "guardduty.us-east-1.amazonaws.com",
      "cn-northwest-1": "guardduty.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "guardduty.ap-south-1.amazonaws.com",
      "eu-north-1": "guardduty.eu-north-1.amazonaws.com",
      "ap-northeast-2": "guardduty.ap-northeast-2.amazonaws.com",
      "us-west-1": "guardduty.us-west-1.amazonaws.com",
      "us-gov-east-1": "guardduty.us-gov-east-1.amazonaws.com",
      "eu-west-3": "guardduty.eu-west-3.amazonaws.com",
      "cn-north-1": "guardduty.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "guardduty.sa-east-1.amazonaws.com",
      "eu-west-1": "guardduty.eu-west-1.amazonaws.com",
      "us-gov-west-1": "guardduty.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "guardduty.ap-southeast-2.amazonaws.com",
      "ca-central-1": "guardduty.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "guardduty"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AcceptInvitation_402656487 = ref object of OpenApiRestCall_402656044
proc url_AcceptInvitation_402656489(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/master")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AcceptInvitation_402656488(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Accepts the invitation to be monitored by a master GuardDuty account.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector of the GuardDuty member account.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656490 = path.getOrDefault("detectorId")
  valid_402656490 = validateParameter(valid_402656490, JString, required = true,
                                      default = nil)
  if valid_402656490 != nil:
    section.add "detectorId", valid_402656490
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656491 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Security-Token", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Signature")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Signature", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Algorithm", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Date")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Date", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Credential")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Credential", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656499: Call_AcceptInvitation_402656487;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Accepts the invitation to be monitored by a master GuardDuty account.
                                                                                         ## 
  let valid = call_402656499.validator(path, query, header, formData, body, _)
  let scheme = call_402656499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656499.makeUrl(scheme.get, call_402656499.host, call_402656499.base,
                                   call_402656499.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656499, uri, valid, _)

proc call*(call_402656500: Call_AcceptInvitation_402656487; body: JsonNode;
           detectorId: string): Recallable =
  ## acceptInvitation
  ## Accepts the invitation to be monitored by a master GuardDuty account.
  ##   body: 
                                                                          ## JObject (required)
  ##   
                                                                                               ## detectorId: string (required)
                                                                                               ##             
                                                                                               ## : 
                                                                                               ## The 
                                                                                               ## unique 
                                                                                               ## ID 
                                                                                               ## of 
                                                                                               ## the 
                                                                                               ## detector 
                                                                                               ## of 
                                                                                               ## the 
                                                                                               ## GuardDuty 
                                                                                               ## member 
                                                                                               ## account.
  var path_402656501 = newJObject()
  var body_402656502 = newJObject()
  if body != nil:
    body_402656502 = body
  add(path_402656501, "detectorId", newJString(detectorId))
  result = call_402656500.call(path_402656501, nil, nil, nil, body_402656502)

var acceptInvitation* = Call_AcceptInvitation_402656487(
    name: "acceptInvitation", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/master",
    validator: validate_AcceptInvitation_402656488, base: "/",
    makeUrl: url_AcceptInvitation_402656489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_402656294 = ref object of OpenApiRestCall_402656044
proc url_GetMasterAccount_402656296(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/master")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMasterAccount_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector of the GuardDuty member account.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656386 = path.getOrDefault("detectorId")
  valid_402656386 = validateParameter(valid_402656386, JString, required = true,
                                      default = nil)
  if valid_402656386 != nil:
    section.add "detectorId", valid_402656386
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656387 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Security-Token", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Signature")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Signature", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Algorithm", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Date")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Date", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Credential")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Credential", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656407: Call_GetMasterAccount_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
                                                                                         ## 
  let valid = call_402656407.validator(path, query, header, formData, body, _)
  let scheme = call_402656407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656407.makeUrl(scheme.get, call_402656407.host, call_402656407.base,
                                   call_402656407.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656407, uri, valid, _)

proc call*(call_402656456: Call_GetMasterAccount_402656294; detectorId: string): Recallable =
  ## getMasterAccount
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
  ##   
                                                                                                                ## detectorId: string (required)
                                                                                                                ##             
                                                                                                                ## : 
                                                                                                                ## The 
                                                                                                                ## unique 
                                                                                                                ## ID 
                                                                                                                ## of 
                                                                                                                ## the 
                                                                                                                ## detector 
                                                                                                                ## of 
                                                                                                                ## the 
                                                                                                                ## GuardDuty 
                                                                                                                ## member 
                                                                                                                ## account.
  var path_402656457 = newJObject()
  add(path_402656457, "detectorId", newJString(detectorId))
  result = call_402656456.call(path_402656457, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_402656294(
    name: "getMasterAccount", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/master",
    validator: validate_GetMasterAccount_402656295, base: "/",
    makeUrl: url_GetMasterAccount_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ArchiveFindings_402656503 = ref object of OpenApiRestCall_402656044
proc url_ArchiveFindings_402656505(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/findings/archive")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ArchiveFindings_402656504(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to archive.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656506 = path.getOrDefault("detectorId")
  valid_402656506 = validateParameter(valid_402656506, JString, required = true,
                                      default = nil)
  if valid_402656506 != nil:
    section.add "detectorId", valid_402656506
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Security-Token", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Signature")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Signature", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Algorithm", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Date")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Date", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Credential")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Credential", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656515: Call_ArchiveFindings_402656503; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
                                                                                         ## 
  let valid = call_402656515.validator(path, query, header, formData, body, _)
  let scheme = call_402656515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656515.makeUrl(scheme.get, call_402656515.host, call_402656515.base,
                                   call_402656515.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656515, uri, valid, _)

proc call*(call_402656516: Call_ArchiveFindings_402656503; body: JsonNode;
           detectorId: string): Recallable =
  ## archiveFindings
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
  ##   
                                                                                                                                                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                            ## detectorId: string (required)
                                                                                                                                                                                                                                                            ##             
                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                            ## ID 
                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                            ## detector 
                                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                                            ## specifies 
                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                            ## GuardDuty 
                                                                                                                                                                                                                                                            ## service 
                                                                                                                                                                                                                                                            ## whose 
                                                                                                                                                                                                                                                            ## findings 
                                                                                                                                                                                                                                                            ## you 
                                                                                                                                                                                                                                                            ## want 
                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                            ## archive.
  var path_402656517 = newJObject()
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  add(path_402656517, "detectorId", newJString(detectorId))
  result = call_402656516.call(path_402656517, nil, nil, nil, body_402656518)

var archiveFindings* = Call_ArchiveFindings_402656503(name: "archiveFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/archive",
    validator: validate_ArchiveFindings_402656504, base: "/",
    makeUrl: url_ArchiveFindings_402656505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDetector_402656536 = ref object of OpenApiRestCall_402656044
proc url_CreateDetector_402656538(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDetector_402656537(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656539 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Security-Token", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Signature")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Signature", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Algorithm", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Date")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Date", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Credential")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Credential", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656547: Call_CreateDetector_402656536; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
                                                                                         ## 
  let valid = call_402656547.validator(path, query, header, formData, body, _)
  let scheme = call_402656547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656547.makeUrl(scheme.get, call_402656547.host, call_402656547.base,
                                   call_402656547.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656547, uri, valid, _)

proc call*(call_402656548: Call_CreateDetector_402656536; body: JsonNode): Recallable =
  ## createDetector
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
  ##   
                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656549 = newJObject()
  if body != nil:
    body_402656549 = body
  result = call_402656548.call(nil, nil, nil, nil, body_402656549)

var createDetector* = Call_CreateDetector_402656536(name: "createDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector", validator: validate_CreateDetector_402656537, base: "/",
    makeUrl: url_CreateDetector_402656538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectors_402656519 = ref object of OpenApiRestCall_402656044
proc url_ListDetectors_402656521(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDetectors_402656520(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists detectorIds of all the existing Amazon GuardDuty detector resources.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   
                                                                                                                                                                                                 ## nextToken: JString
                                                                                                                                                                                                 ##            
                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                 ## You 
                                                                                                                                                                                                 ## can 
                                                                                                                                                                                                 ## use 
                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                 ## when 
                                                                                                                                                                                                 ## paginating 
                                                                                                                                                                                                 ## results. 
                                                                                                                                                                                                 ## Set 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## null 
                                                                                                                                                                                                 ## on 
                                                                                                                                                                                                 ## your 
                                                                                                                                                                                                 ## first 
                                                                                                                                                                                                 ## call 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## list 
                                                                                                                                                                                                 ## action. 
                                                                                                                                                                                                 ## For 
                                                                                                                                                                                                 ## subsequent 
                                                                                                                                                                                                 ## calls 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## action 
                                                                                                                                                                                                 ## fill 
                                                                                                                                                                                                 ## nextToken 
                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## request 
                                                                                                                                                                                                 ## with 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                 ## NextToken 
                                                                                                                                                                                                 ## from 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## previous 
                                                                                                                                                                                                 ## response 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## continue 
                                                                                                                                                                                                 ## listing 
                                                                                                                                                                                                 ## data.
  ##   
                                                                                                                                                                                                         ## MaxResults: JString
                                                                                                                                                                                                         ##             
                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                         ## limit
  ##   
                                                                                                                                                                                                                 ## NextToken: JString
                                                                                                                                                                                                                 ##            
                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                 ## token
  section = newJObject()
  var valid_402656522 = query.getOrDefault("maxResults")
  valid_402656522 = validateParameter(valid_402656522, JInt, required = false,
                                      default = nil)
  if valid_402656522 != nil:
    section.add "maxResults", valid_402656522
  var valid_402656523 = query.getOrDefault("nextToken")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "nextToken", valid_402656523
  var valid_402656524 = query.getOrDefault("MaxResults")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "MaxResults", valid_402656524
  var valid_402656525 = query.getOrDefault("NextToken")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "NextToken", valid_402656525
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656526 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Security-Token", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Signature")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Signature", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Algorithm", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Date")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Date", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Credential")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Credential", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656533: Call_ListDetectors_402656519; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists detectorIds of all the existing Amazon GuardDuty detector resources.
                                                                                         ## 
  let valid = call_402656533.validator(path, query, header, formData, body, _)
  let scheme = call_402656533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656533.makeUrl(scheme.get, call_402656533.host, call_402656533.base,
                                   call_402656533.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656533, uri, valid, _)

proc call*(call_402656534: Call_ListDetectors_402656519; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listDetectors
  ## Lists detectorIds of all the existing Amazon GuardDuty detector resources.
  ##   
                                                                               ## maxResults: int
                                                                               ##             
                                                                               ## : 
                                                                               ## You 
                                                                               ## can 
                                                                               ## use 
                                                                               ## this 
                                                                               ## parameter 
                                                                               ## to 
                                                                               ## indicate 
                                                                               ## the 
                                                                               ## maximum 
                                                                               ## number 
                                                                               ## of 
                                                                               ## items 
                                                                               ## you 
                                                                               ## want 
                                                                               ## in 
                                                                               ## the 
                                                                               ## response. 
                                                                               ## The 
                                                                               ## default 
                                                                               ## value 
                                                                               ## is 
                                                                               ## 50. 
                                                                               ## The 
                                                                               ## maximum 
                                                                               ## value 
                                                                               ## is 
                                                                               ## 50.
  ##   
                                                                                     ## nextToken: string
                                                                                     ##            
                                                                                     ## : 
                                                                                     ## You 
                                                                                     ## can 
                                                                                     ## use 
                                                                                     ## this 
                                                                                     ## parameter 
                                                                                     ## when 
                                                                                     ## paginating 
                                                                                     ## results. 
                                                                                     ## Set 
                                                                                     ## the 
                                                                                     ## value 
                                                                                     ## of 
                                                                                     ## this 
                                                                                     ## parameter 
                                                                                     ## to 
                                                                                     ## null 
                                                                                     ## on 
                                                                                     ## your 
                                                                                     ## first 
                                                                                     ## call 
                                                                                     ## to 
                                                                                     ## the 
                                                                                     ## list 
                                                                                     ## action. 
                                                                                     ## For 
                                                                                     ## subsequent 
                                                                                     ## calls 
                                                                                     ## to 
                                                                                     ## the 
                                                                                     ## action 
                                                                                     ## fill 
                                                                                     ## nextToken 
                                                                                     ## in 
                                                                                     ## the 
                                                                                     ## request 
                                                                                     ## with 
                                                                                     ## the 
                                                                                     ## value 
                                                                                     ## of 
                                                                                     ## NextToken 
                                                                                     ## from 
                                                                                     ## the 
                                                                                     ## previous 
                                                                                     ## response 
                                                                                     ## to 
                                                                                     ## continue 
                                                                                     ## listing 
                                                                                     ## data.
  ##   
                                                                                             ## MaxResults: string
                                                                                             ##             
                                                                                             ## : 
                                                                                             ## Pagination 
                                                                                             ## limit
  ##   
                                                                                                     ## NextToken: string
                                                                                                     ##            
                                                                                                     ## : 
                                                                                                     ## Pagination 
                                                                                                     ## token
  var query_402656535 = newJObject()
  add(query_402656535, "maxResults", newJInt(maxResults))
  add(query_402656535, "nextToken", newJString(nextToken))
  add(query_402656535, "MaxResults", newJString(MaxResults))
  add(query_402656535, "NextToken", newJString(NextToken))
  result = call_402656534.call(nil, query_402656535, nil, nil, nil)

var listDetectors* = Call_ListDetectors_402656519(name: "listDetectors",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector", validator: validate_ListDetectors_402656520, base: "/",
    makeUrl: url_ListDetectors_402656521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFilter_402656569 = ref object of OpenApiRestCall_402656044
proc url_CreateFilter_402656571(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/filter")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateFilter_402656570(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a filter using the specified finding criteria.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector of the GuardDuty account for which you want to create a filter.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656572 = path.getOrDefault("detectorId")
  valid_402656572 = validateParameter(valid_402656572, JString, required = true,
                                      default = nil)
  if valid_402656572 != nil:
    section.add "detectorId", valid_402656572
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656573 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Security-Token", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Signature")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Signature", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Algorithm", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Date")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Date", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Credential")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Credential", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656581: Call_CreateFilter_402656569; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a filter using the specified finding criteria.
                                                                                         ## 
  let valid = call_402656581.validator(path, query, header, formData, body, _)
  let scheme = call_402656581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656581.makeUrl(scheme.get, call_402656581.host, call_402656581.base,
                                   call_402656581.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656581, uri, valid, _)

proc call*(call_402656582: Call_CreateFilter_402656569; body: JsonNode;
           detectorId: string): Recallable =
  ## createFilter
  ## Creates a filter using the specified finding criteria.
  ##   body: JObject (required)
  ##   detectorId: string (required)
                               ##             : The unique ID of the detector of the GuardDuty account for which you want to create a filter.
  var path_402656583 = newJObject()
  var body_402656584 = newJObject()
  if body != nil:
    body_402656584 = body
  add(path_402656583, "detectorId", newJString(detectorId))
  result = call_402656582.call(path_402656583, nil, nil, nil, body_402656584)

var createFilter* = Call_CreateFilter_402656569(name: "createFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter", validator: validate_CreateFilter_402656570,
    base: "/", makeUrl: url_CreateFilter_402656571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFilters_402656550 = ref object of OpenApiRestCall_402656044
proc url_ListFilters_402656552(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/filter")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFilters_402656551(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a paginated list of the current filters.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector the filter is associated with.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656553 = path.getOrDefault("detectorId")
  valid_402656553 = validateParameter(valid_402656553, JString, required = true,
                                      default = nil)
  if valid_402656553 != nil:
    section.add "detectorId", valid_402656553
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   
                                                                                                                                                                                                 ## nextToken: JString
                                                                                                                                                                                                 ##            
                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                 ## You 
                                                                                                                                                                                                 ## can 
                                                                                                                                                                                                 ## use 
                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                 ## when 
                                                                                                                                                                                                 ## paginating 
                                                                                                                                                                                                 ## results. 
                                                                                                                                                                                                 ## Set 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## null 
                                                                                                                                                                                                 ## on 
                                                                                                                                                                                                 ## your 
                                                                                                                                                                                                 ## first 
                                                                                                                                                                                                 ## call 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## list 
                                                                                                                                                                                                 ## action. 
                                                                                                                                                                                                 ## For 
                                                                                                                                                                                                 ## subsequent 
                                                                                                                                                                                                 ## calls 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## action 
                                                                                                                                                                                                 ## fill 
                                                                                                                                                                                                 ## nextToken 
                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## request 
                                                                                                                                                                                                 ## with 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                 ## NextToken 
                                                                                                                                                                                                 ## from 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## previous 
                                                                                                                                                                                                 ## response 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## continue 
                                                                                                                                                                                                 ## listing 
                                                                                                                                                                                                 ## data.
  ##   
                                                                                                                                                                                                         ## MaxResults: JString
                                                                                                                                                                                                         ##             
                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                         ## limit
  ##   
                                                                                                                                                                                                                 ## NextToken: JString
                                                                                                                                                                                                                 ##            
                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                 ## token
  section = newJObject()
  var valid_402656554 = query.getOrDefault("maxResults")
  valid_402656554 = validateParameter(valid_402656554, JInt, required = false,
                                      default = nil)
  if valid_402656554 != nil:
    section.add "maxResults", valid_402656554
  var valid_402656555 = query.getOrDefault("nextToken")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "nextToken", valid_402656555
  var valid_402656556 = query.getOrDefault("MaxResults")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "MaxResults", valid_402656556
  var valid_402656557 = query.getOrDefault("NextToken")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "NextToken", valid_402656557
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656558 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Security-Token", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Signature")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Signature", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Algorithm", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Date")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Date", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Credential")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Credential", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656565: Call_ListFilters_402656550; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a paginated list of the current filters.
                                                                                         ## 
  let valid = call_402656565.validator(path, query, header, formData, body, _)
  let scheme = call_402656565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656565.makeUrl(scheme.get, call_402656565.host, call_402656565.base,
                                   call_402656565.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656565, uri, valid, _)

proc call*(call_402656566: Call_ListFilters_402656550; detectorId: string;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listFilters
  ## Returns a paginated list of the current filters.
  ##   maxResults: int
                                                     ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   
                                                                                                                                                                                                                    ## nextToken: string
                                                                                                                                                                                                                    ##            
                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                    ## You 
                                                                                                                                                                                                                    ## can 
                                                                                                                                                                                                                    ## use 
                                                                                                                                                                                                                    ## this 
                                                                                                                                                                                                                    ## parameter 
                                                                                                                                                                                                                    ## when 
                                                                                                                                                                                                                    ## paginating 
                                                                                                                                                                                                                    ## results. 
                                                                                                                                                                                                                    ## Set 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## value 
                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                    ## this 
                                                                                                                                                                                                                    ## parameter 
                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                    ## null 
                                                                                                                                                                                                                    ## on 
                                                                                                                                                                                                                    ## your 
                                                                                                                                                                                                                    ## first 
                                                                                                                                                                                                                    ## call 
                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## list 
                                                                                                                                                                                                                    ## action. 
                                                                                                                                                                                                                    ## For 
                                                                                                                                                                                                                    ## subsequent 
                                                                                                                                                                                                                    ## calls 
                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## action 
                                                                                                                                                                                                                    ## fill 
                                                                                                                                                                                                                    ## nextToken 
                                                                                                                                                                                                                    ## in 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## request 
                                                                                                                                                                                                                    ## with 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## value 
                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                    ## NextToken 
                                                                                                                                                                                                                    ## from 
                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                    ## previous 
                                                                                                                                                                                                                    ## response 
                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                    ## continue 
                                                                                                                                                                                                                    ## listing 
                                                                                                                                                                                                                    ## data.
  ##   
                                                                                                                                                                                                                            ## MaxResults: string
                                                                                                                                                                                                                            ##             
                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                                                            ## limit
  ##   
                                                                                                                                                                                                                                    ## detectorId: string (required)
                                                                                                                                                                                                                                    ##             
                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                    ## unique 
                                                                                                                                                                                                                                    ## ID 
                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                    ## detector 
                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                    ## filter 
                                                                                                                                                                                                                                    ## is 
                                                                                                                                                                                                                                    ## associated 
                                                                                                                                                                                                                                    ## with.
  ##   
                                                                                                                                                                                                                                            ## NextToken: string
                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                                                                            ## token
  var path_402656567 = newJObject()
  var query_402656568 = newJObject()
  add(query_402656568, "maxResults", newJInt(maxResults))
  add(query_402656568, "nextToken", newJString(nextToken))
  add(query_402656568, "MaxResults", newJString(MaxResults))
  add(path_402656567, "detectorId", newJString(detectorId))
  add(query_402656568, "NextToken", newJString(NextToken))
  result = call_402656566.call(path_402656567, query_402656568, nil, nil, nil)

var listFilters* = Call_ListFilters_402656550(name: "listFilters",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter", validator: validate_ListFilters_402656551,
    base: "/", makeUrl: url_ListFilters_402656552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIPSet_402656604 = ref object of OpenApiRestCall_402656044
proc url_CreateIPSet_402656606(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/ipset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIPSet_402656605(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new IPSet, called Trusted IP list in the consoler user interface. An IPSet is a list IP addresses trusted for secure communication with AWS infrastructure and applications. GuardDuty does not generate findings for IP addresses included in IPSets. Only users from the master account can use this operation.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector of the GuardDuty account for which you want to create an IPSet.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656607 = path.getOrDefault("detectorId")
  valid_402656607 = validateParameter(valid_402656607, JString, required = true,
                                      default = nil)
  if valid_402656607 != nil:
    section.add "detectorId", valid_402656607
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656608 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Security-Token", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Signature")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Signature", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Algorithm", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Date")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Date", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Credential")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Credential", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656616: Call_CreateIPSet_402656604; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new IPSet, called Trusted IP list in the consoler user interface. An IPSet is a list IP addresses trusted for secure communication with AWS infrastructure and applications. GuardDuty does not generate findings for IP addresses included in IPSets. Only users from the master account can use this operation.
                                                                                         ## 
  let valid = call_402656616.validator(path, query, header, formData, body, _)
  let scheme = call_402656616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656616.makeUrl(scheme.get, call_402656616.host, call_402656616.base,
                                   call_402656616.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656616, uri, valid, _)

proc call*(call_402656617: Call_CreateIPSet_402656604; body: JsonNode;
           detectorId: string): Recallable =
  ## createIPSet
  ## Creates a new IPSet, called Trusted IP list in the consoler user interface. An IPSet is a list IP addresses trusted for secure communication with AWS infrastructure and applications. GuardDuty does not generate findings for IP addresses included in IPSets. Only users from the master account can use this operation.
  ##   
                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                           ## detectorId: string (required)
                                                                                                                                                                                                                                                                                                                                                           ##             
                                                                                                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                                                                                                                                                           ## unique 
                                                                                                                                                                                                                                                                                                                                                           ## ID 
                                                                                                                                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                           ## detector 
                                                                                                                                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                           ## GuardDuty 
                                                                                                                                                                                                                                                                                                                                                           ## account 
                                                                                                                                                                                                                                                                                                                                                           ## for 
                                                                                                                                                                                                                                                                                                                                                           ## which 
                                                                                                                                                                                                                                                                                                                                                           ## you 
                                                                                                                                                                                                                                                                                                                                                           ## want 
                                                                                                                                                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                                                                                                                                                           ## create 
                                                                                                                                                                                                                                                                                                                                                           ## an 
                                                                                                                                                                                                                                                                                                                                                           ## IPSet.
  var path_402656618 = newJObject()
  var body_402656619 = newJObject()
  if body != nil:
    body_402656619 = body
  add(path_402656618, "detectorId", newJString(detectorId))
  result = call_402656617.call(path_402656618, nil, nil, nil, body_402656619)

var createIPSet* = Call_CreateIPSet_402656604(name: "createIPSet",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/ipset", validator: validate_CreateIPSet_402656605,
    base: "/", makeUrl: url_CreateIPSet_402656606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIPSets_402656585 = ref object of OpenApiRestCall_402656044
proc url_ListIPSets_402656587(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/ipset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIPSets_402656586(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the IPSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the IPSets returned are the IPSets from the associated master account.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector the ipSet is associated with.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656588 = path.getOrDefault("detectorId")
  valid_402656588 = validateParameter(valid_402656588, JString, required = true,
                                      default = nil)
  if valid_402656588 != nil:
    section.add "detectorId", valid_402656588
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   
                                                                                                                                                                                                 ## nextToken: JString
                                                                                                                                                                                                 ##            
                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                 ## You 
                                                                                                                                                                                                 ## can 
                                                                                                                                                                                                 ## use 
                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                 ## when 
                                                                                                                                                                                                 ## paginating 
                                                                                                                                                                                                 ## results. 
                                                                                                                                                                                                 ## Set 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## null 
                                                                                                                                                                                                 ## on 
                                                                                                                                                                                                 ## your 
                                                                                                                                                                                                 ## first 
                                                                                                                                                                                                 ## call 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## list 
                                                                                                                                                                                                 ## action. 
                                                                                                                                                                                                 ## For 
                                                                                                                                                                                                 ## subsequent 
                                                                                                                                                                                                 ## calls 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## action 
                                                                                                                                                                                                 ## fill 
                                                                                                                                                                                                 ## nextToken 
                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## request 
                                                                                                                                                                                                 ## with 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                 ## NextToken 
                                                                                                                                                                                                 ## from 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## previous 
                                                                                                                                                                                                 ## response 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## continue 
                                                                                                                                                                                                 ## listing 
                                                                                                                                                                                                 ## data.
  ##   
                                                                                                                                                                                                         ## MaxResults: JString
                                                                                                                                                                                                         ##             
                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                         ## limit
  ##   
                                                                                                                                                                                                                 ## NextToken: JString
                                                                                                                                                                                                                 ##            
                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                 ## token
  section = newJObject()
  var valid_402656589 = query.getOrDefault("maxResults")
  valid_402656589 = validateParameter(valid_402656589, JInt, required = false,
                                      default = nil)
  if valid_402656589 != nil:
    section.add "maxResults", valid_402656589
  var valid_402656590 = query.getOrDefault("nextToken")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "nextToken", valid_402656590
  var valid_402656591 = query.getOrDefault("MaxResults")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "MaxResults", valid_402656591
  var valid_402656592 = query.getOrDefault("NextToken")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "NextToken", valid_402656592
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656593 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Security-Token", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Signature")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Signature", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Algorithm", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Date")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Date", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Credential")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Credential", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656600: Call_ListIPSets_402656585; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the IPSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the IPSets returned are the IPSets from the associated master account.
                                                                                         ## 
  let valid = call_402656600.validator(path, query, header, formData, body, _)
  let scheme = call_402656600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656600.makeUrl(scheme.get, call_402656600.host, call_402656600.base,
                                   call_402656600.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656600, uri, valid, _)

proc call*(call_402656601: Call_ListIPSets_402656585; detectorId: string;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listIPSets
  ## Lists the IPSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the IPSets returned are the IPSets from the associated master account.
  ##   
                                                                                                                                                                                                    ## maxResults: int
                                                                                                                                                                                                    ##             
                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                    ## You 
                                                                                                                                                                                                    ## can 
                                                                                                                                                                                                    ## use 
                                                                                                                                                                                                    ## this 
                                                                                                                                                                                                    ## parameter 
                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                    ## indicate 
                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                    ## maximum 
                                                                                                                                                                                                    ## number 
                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                    ## items 
                                                                                                                                                                                                    ## you 
                                                                                                                                                                                                    ## want 
                                                                                                                                                                                                    ## in 
                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                    ## response. 
                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                    ## default 
                                                                                                                                                                                                    ## value 
                                                                                                                                                                                                    ## is 
                                                                                                                                                                                                    ## 50. 
                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                    ## maximum 
                                                                                                                                                                                                    ## value 
                                                                                                                                                                                                    ## is 
                                                                                                                                                                                                    ## 50.
  ##   
                                                                                                                                                                                                          ## nextToken: string
                                                                                                                                                                                                          ##            
                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                          ## You 
                                                                                                                                                                                                          ## can 
                                                                                                                                                                                                          ## use 
                                                                                                                                                                                                          ## this 
                                                                                                                                                                                                          ## parameter 
                                                                                                                                                                                                          ## when 
                                                                                                                                                                                                          ## paginating 
                                                                                                                                                                                                          ## results. 
                                                                                                                                                                                                          ## Set 
                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                          ## value 
                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                          ## this 
                                                                                                                                                                                                          ## parameter 
                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                          ## null 
                                                                                                                                                                                                          ## on 
                                                                                                                                                                                                          ## your 
                                                                                                                                                                                                          ## first 
                                                                                                                                                                                                          ## call 
                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                          ## list 
                                                                                                                                                                                                          ## action. 
                                                                                                                                                                                                          ## For 
                                                                                                                                                                                                          ## subsequent 
                                                                                                                                                                                                          ## calls 
                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                          ## action 
                                                                                                                                                                                                          ## fill 
                                                                                                                                                                                                          ## nextToken 
                                                                                                                                                                                                          ## in 
                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                          ## request 
                                                                                                                                                                                                          ## with 
                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                          ## value 
                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                          ## NextToken 
                                                                                                                                                                                                          ## from 
                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                          ## previous 
                                                                                                                                                                                                          ## response 
                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                          ## continue 
                                                                                                                                                                                                          ## listing 
                                                                                                                                                                                                          ## data.
  ##   
                                                                                                                                                                                                                  ## MaxResults: string
                                                                                                                                                                                                                  ##             
                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                  ## limit
  ##   
                                                                                                                                                                                                                          ## detectorId: string (required)
                                                                                                                                                                                                                          ##             
                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                          ## unique 
                                                                                                                                                                                                                          ## ID 
                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                          ## detector 
                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                          ## ipSet 
                                                                                                                                                                                                                          ## is 
                                                                                                                                                                                                                          ## associated 
                                                                                                                                                                                                                          ## with.
  ##   
                                                                                                                                                                                                                                  ## NextToken: string
                                                                                                                                                                                                                                  ##            
                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                  ## token
  var path_402656602 = newJObject()
  var query_402656603 = newJObject()
  add(query_402656603, "maxResults", newJInt(maxResults))
  add(query_402656603, "nextToken", newJString(nextToken))
  add(query_402656603, "MaxResults", newJString(MaxResults))
  add(path_402656602, "detectorId", newJString(detectorId))
  add(query_402656603, "NextToken", newJString(NextToken))
  result = call_402656601.call(path_402656602, query_402656603, nil, nil, nil)

var listIPSets* = Call_ListIPSets_402656585(name: "listIPSets",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/ipset", validator: validate_ListIPSets_402656586,
    base: "/", makeUrl: url_ListIPSets_402656587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_402656640 = ref object of OpenApiRestCall_402656044
proc url_CreateMembers_402656642(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/member")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateMembers_402656641(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector of the GuardDuty account with which you want to associate member accounts.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656643 = path.getOrDefault("detectorId")
  valid_402656643 = validateParameter(valid_402656643, JString, required = true,
                                      default = nil)
  if valid_402656643 != nil:
    section.add "detectorId", valid_402656643
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656644 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Security-Token", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Signature")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Signature", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Algorithm", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Date")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Date", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Credential")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Credential", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656652: Call_CreateMembers_402656640; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
                                                                                         ## 
  let valid = call_402656652.validator(path, query, header, formData, body, _)
  let scheme = call_402656652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656652.makeUrl(scheme.get, call_402656652.host, call_402656652.base,
                                   call_402656652.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656652, uri, valid, _)

proc call*(call_402656653: Call_CreateMembers_402656640; body: JsonNode;
           detectorId: string): Recallable =
  ## createMembers
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
  ##   
                                                                                                                                                                                             ## body: JObject (required)
  ##   
                                                                                                                                                                                                                        ## detectorId: string (required)
                                                                                                                                                                                                                        ##             
                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                        ## unique 
                                                                                                                                                                                                                        ## ID 
                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                        ## detector 
                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                        ## GuardDuty 
                                                                                                                                                                                                                        ## account 
                                                                                                                                                                                                                        ## with 
                                                                                                                                                                                                                        ## which 
                                                                                                                                                                                                                        ## you 
                                                                                                                                                                                                                        ## want 
                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                        ## associate 
                                                                                                                                                                                                                        ## member 
                                                                                                                                                                                                                        ## accounts.
  var path_402656654 = newJObject()
  var body_402656655 = newJObject()
  if body != nil:
    body_402656655 = body
  add(path_402656654, "detectorId", newJString(detectorId))
  result = call_402656653.call(path_402656654, nil, nil, nil, body_402656655)

var createMembers* = Call_CreateMembers_402656640(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member", validator: validate_CreateMembers_402656641,
    base: "/", makeUrl: url_CreateMembers_402656642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_402656620 = ref object of OpenApiRestCall_402656044
proc url_ListMembers_402656622(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/member")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListMembers_402656621(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists details about all member accounts for the current GuardDuty master account.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector the member is associated with.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656623 = path.getOrDefault("detectorId")
  valid_402656623 = validateParameter(valid_402656623, JString, required = true,
                                      default = nil)
  if valid_402656623 != nil:
    section.add "detectorId", valid_402656623
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   
                                                                                                                                                                                                 ## nextToken: JString
                                                                                                                                                                                                 ##            
                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                 ## You 
                                                                                                                                                                                                 ## can 
                                                                                                                                                                                                 ## use 
                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                 ## when 
                                                                                                                                                                                                 ## paginating 
                                                                                                                                                                                                 ## results. 
                                                                                                                                                                                                 ## Set 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## null 
                                                                                                                                                                                                 ## on 
                                                                                                                                                                                                 ## your 
                                                                                                                                                                                                 ## first 
                                                                                                                                                                                                 ## call 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## list 
                                                                                                                                                                                                 ## action. 
                                                                                                                                                                                                 ## For 
                                                                                                                                                                                                 ## subsequent 
                                                                                                                                                                                                 ## calls 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## action 
                                                                                                                                                                                                 ## fill 
                                                                                                                                                                                                 ## nextToken 
                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## request 
                                                                                                                                                                                                 ## with 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                 ## NextToken 
                                                                                                                                                                                                 ## from 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## previous 
                                                                                                                                                                                                 ## response 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## continue 
                                                                                                                                                                                                 ## listing 
                                                                                                                                                                                                 ## data.
  ##   
                                                                                                                                                                                                         ## MaxResults: JString
                                                                                                                                                                                                         ##             
                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                         ## limit
  ##   
                                                                                                                                                                                                                 ## NextToken: JString
                                                                                                                                                                                                                 ##            
                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                 ## token
  ##   
                                                                                                                                                                                                                         ## onlyAssociated: JString
                                                                                                                                                                                                                         ##                 
                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                         ## Specifies 
                                                                                                                                                                                                                         ## whether 
                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                         ## only 
                                                                                                                                                                                                                         ## return 
                                                                                                                                                                                                                         ## associated 
                                                                                                                                                                                                                         ## members 
                                                                                                                                                                                                                         ## or 
                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                         ## return 
                                                                                                                                                                                                                         ## all 
                                                                                                                                                                                                                         ## members 
                                                                                                                                                                                                                         ## (including 
                                                                                                                                                                                                                         ## members 
                                                                                                                                                                                                                         ## which 
                                                                                                                                                                                                                         ## haven't 
                                                                                                                                                                                                                         ## been 
                                                                                                                                                                                                                         ## invited 
                                                                                                                                                                                                                         ## yet 
                                                                                                                                                                                                                         ## or 
                                                                                                                                                                                                                         ## have 
                                                                                                                                                                                                                         ## been 
                                                                                                                                                                                                                         ## disassociated).
  section = newJObject()
  var valid_402656624 = query.getOrDefault("maxResults")
  valid_402656624 = validateParameter(valid_402656624, JInt, required = false,
                                      default = nil)
  if valid_402656624 != nil:
    section.add "maxResults", valid_402656624
  var valid_402656625 = query.getOrDefault("nextToken")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "nextToken", valid_402656625
  var valid_402656626 = query.getOrDefault("MaxResults")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "MaxResults", valid_402656626
  var valid_402656627 = query.getOrDefault("NextToken")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "NextToken", valid_402656627
  var valid_402656628 = query.getOrDefault("onlyAssociated")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "onlyAssociated", valid_402656628
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656629 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Security-Token", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Signature")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Signature", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Algorithm", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Date")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Date", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Credential")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Credential", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656636: Call_ListMembers_402656620; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists details about all member accounts for the current GuardDuty master account.
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_ListMembers_402656620; detectorId: string;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""; onlyAssociated: string = ""): Recallable =
  ## listMembers
  ## Lists details about all member accounts for the current GuardDuty master account.
  ##   
                                                                                      ## maxResults: int
                                                                                      ##             
                                                                                      ## : 
                                                                                      ## You 
                                                                                      ## can 
                                                                                      ## use 
                                                                                      ## this 
                                                                                      ## parameter 
                                                                                      ## to 
                                                                                      ## indicate 
                                                                                      ## the 
                                                                                      ## maximum 
                                                                                      ## number 
                                                                                      ## of 
                                                                                      ## items 
                                                                                      ## you 
                                                                                      ## want 
                                                                                      ## in 
                                                                                      ## the 
                                                                                      ## response. 
                                                                                      ## The 
                                                                                      ## default 
                                                                                      ## value 
                                                                                      ## is 
                                                                                      ## 50. 
                                                                                      ## The 
                                                                                      ## maximum 
                                                                                      ## value 
                                                                                      ## is 
                                                                                      ## 50.
  ##   
                                                                                            ## nextToken: string
                                                                                            ##            
                                                                                            ## : 
                                                                                            ## You 
                                                                                            ## can 
                                                                                            ## use 
                                                                                            ## this 
                                                                                            ## parameter 
                                                                                            ## when 
                                                                                            ## paginating 
                                                                                            ## results. 
                                                                                            ## Set 
                                                                                            ## the 
                                                                                            ## value 
                                                                                            ## of 
                                                                                            ## this 
                                                                                            ## parameter 
                                                                                            ## to 
                                                                                            ## null 
                                                                                            ## on 
                                                                                            ## your 
                                                                                            ## first 
                                                                                            ## call 
                                                                                            ## to 
                                                                                            ## the 
                                                                                            ## list 
                                                                                            ## action. 
                                                                                            ## For 
                                                                                            ## subsequent 
                                                                                            ## calls 
                                                                                            ## to 
                                                                                            ## the 
                                                                                            ## action 
                                                                                            ## fill 
                                                                                            ## nextToken 
                                                                                            ## in 
                                                                                            ## the 
                                                                                            ## request 
                                                                                            ## with 
                                                                                            ## the 
                                                                                            ## value 
                                                                                            ## of 
                                                                                            ## NextToken 
                                                                                            ## from 
                                                                                            ## the 
                                                                                            ## previous 
                                                                                            ## response 
                                                                                            ## to 
                                                                                            ## continue 
                                                                                            ## listing 
                                                                                            ## data.
  ##   
                                                                                                    ## MaxResults: string
                                                                                                    ##             
                                                                                                    ## : 
                                                                                                    ## Pagination 
                                                                                                    ## limit
  ##   
                                                                                                            ## detectorId: string (required)
                                                                                                            ##             
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## unique 
                                                                                                            ## ID 
                                                                                                            ## of 
                                                                                                            ## the 
                                                                                                            ## detector 
                                                                                                            ## the 
                                                                                                            ## member 
                                                                                                            ## is 
                                                                                                            ## associated 
                                                                                                            ## with.
  ##   
                                                                                                                    ## NextToken: string
                                                                                                                    ##            
                                                                                                                    ## : 
                                                                                                                    ## Pagination 
                                                                                                                    ## token
  ##   
                                                                                                                            ## onlyAssociated: string
                                                                                                                            ##                 
                                                                                                                            ## : 
                                                                                                                            ## Specifies 
                                                                                                                            ## whether 
                                                                                                                            ## to 
                                                                                                                            ## only 
                                                                                                                            ## return 
                                                                                                                            ## associated 
                                                                                                                            ## members 
                                                                                                                            ## or 
                                                                                                                            ## to 
                                                                                                                            ## return 
                                                                                                                            ## all 
                                                                                                                            ## members 
                                                                                                                            ## (including 
                                                                                                                            ## members 
                                                                                                                            ## which 
                                                                                                                            ## haven't 
                                                                                                                            ## been 
                                                                                                                            ## invited 
                                                                                                                            ## yet 
                                                                                                                            ## or 
                                                                                                                            ## have 
                                                                                                                            ## been 
                                                                                                                            ## disassociated).
  var path_402656638 = newJObject()
  var query_402656639 = newJObject()
  add(query_402656639, "maxResults", newJInt(maxResults))
  add(query_402656639, "nextToken", newJString(nextToken))
  add(query_402656639, "MaxResults", newJString(MaxResults))
  add(path_402656638, "detectorId", newJString(detectorId))
  add(query_402656639, "NextToken", newJString(NextToken))
  add(query_402656639, "onlyAssociated", newJString(onlyAssociated))
  result = call_402656637.call(path_402656638, query_402656639, nil, nil, nil)

var listMembers* = Call_ListMembers_402656620(name: "listMembers",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member", validator: validate_ListMembers_402656621,
    base: "/", makeUrl: url_ListMembers_402656622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublishingDestination_402656675 = ref object of OpenApiRestCall_402656044
proc url_CreatePublishingDestination_402656677(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/publishingDestination")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreatePublishingDestination_402656676(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a publishing destination to send findings to. The resource to send findings to must exist before you use this operation.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The ID of the GuardDuty detector associated with the publishing destination.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656678 = path.getOrDefault("detectorId")
  valid_402656678 = validateParameter(valid_402656678, JString, required = true,
                                      default = nil)
  if valid_402656678 != nil:
    section.add "detectorId", valid_402656678
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656679 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Security-Token", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Signature")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Signature", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Algorithm", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Date")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Date", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Credential")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Credential", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656687: Call_CreatePublishingDestination_402656675;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a publishing destination to send findings to. The resource to send findings to must exist before you use this operation.
                                                                                         ## 
  let valid = call_402656687.validator(path, query, header, formData, body, _)
  let scheme = call_402656687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656687.makeUrl(scheme.get, call_402656687.host, call_402656687.base,
                                   call_402656687.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656687, uri, valid, _)

proc call*(call_402656688: Call_CreatePublishingDestination_402656675;
           body: JsonNode; detectorId: string): Recallable =
  ## createPublishingDestination
  ## Creates a publishing destination to send findings to. The resource to send findings to must exist before you use this operation.
  ##   
                                                                                                                                     ## body: JObject (required)
  ##   
                                                                                                                                                                ## detectorId: string (required)
                                                                                                                                                                ##             
                                                                                                                                                                ## : 
                                                                                                                                                                ## The 
                                                                                                                                                                ## ID 
                                                                                                                                                                ## of 
                                                                                                                                                                ## the 
                                                                                                                                                                ## GuardDuty 
                                                                                                                                                                ## detector 
                                                                                                                                                                ## associated 
                                                                                                                                                                ## with 
                                                                                                                                                                ## the 
                                                                                                                                                                ## publishing 
                                                                                                                                                                ## destination.
  var path_402656689 = newJObject()
  var body_402656690 = newJObject()
  if body != nil:
    body_402656690 = body
  add(path_402656689, "detectorId", newJString(detectorId))
  result = call_402656688.call(path_402656689, nil, nil, nil, body_402656690)

var createPublishingDestination* = Call_CreatePublishingDestination_402656675(
    name: "createPublishingDestination", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination",
    validator: validate_CreatePublishingDestination_402656676, base: "/",
    makeUrl: url_CreatePublishingDestination_402656677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishingDestinations_402656656 = ref object of OpenApiRestCall_402656044
proc url_ListPublishingDestinations_402656658(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/publishingDestination")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListPublishingDestinations_402656657(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a list of publishing destinations associated with the specified <code>dectectorId</code>.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The ID of the detector to retrieve publishing destinations for.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656659 = path.getOrDefault("detectorId")
  valid_402656659 = validateParameter(valid_402656659, JString, required = true,
                                      default = nil)
  if valid_402656659 != nil:
    section.add "detectorId", valid_402656659
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return in the response.
  ##   
                                                                                                           ## nextToken: JString
                                                                                                           ##            
                                                                                                           ## : 
                                                                                                           ## A 
                                                                                                           ## token 
                                                                                                           ## to 
                                                                                                           ## use 
                                                                                                           ## for 
                                                                                                           ## paginating 
                                                                                                           ## results 
                                                                                                           ## returned 
                                                                                                           ## in 
                                                                                                           ## the 
                                                                                                           ## repsonse. 
                                                                                                           ## Set 
                                                                                                           ## the 
                                                                                                           ## value 
                                                                                                           ## of 
                                                                                                           ## this 
                                                                                                           ## parameter 
                                                                                                           ## to 
                                                                                                           ## null 
                                                                                                           ## for 
                                                                                                           ## the 
                                                                                                           ## first 
                                                                                                           ## request 
                                                                                                           ## to 
                                                                                                           ## a 
                                                                                                           ## list 
                                                                                                           ## action. 
                                                                                                           ## For 
                                                                                                           ## subsequent 
                                                                                                           ## calls, 
                                                                                                           ## use 
                                                                                                           ## the 
                                                                                                           ## <code>NextToken</code> 
                                                                                                           ## value 
                                                                                                           ## returned 
                                                                                                           ## from 
                                                                                                           ## the 
                                                                                                           ## previous 
                                                                                                           ## request 
                                                                                                           ## to 
                                                                                                           ## continue 
                                                                                                           ## listing 
                                                                                                           ## results 
                                                                                                           ## after 
                                                                                                           ## the 
                                                                                                           ## first 
                                                                                                           ## page.
  ##   
                                                                                                                   ## MaxResults: JString
                                                                                                                   ##             
                                                                                                                   ## : 
                                                                                                                   ## Pagination 
                                                                                                                   ## limit
  ##   
                                                                                                                           ## NextToken: JString
                                                                                                                           ##            
                                                                                                                           ## : 
                                                                                                                           ## Pagination 
                                                                                                                           ## token
  section = newJObject()
  var valid_402656660 = query.getOrDefault("maxResults")
  valid_402656660 = validateParameter(valid_402656660, JInt, required = false,
                                      default = nil)
  if valid_402656660 != nil:
    section.add "maxResults", valid_402656660
  var valid_402656661 = query.getOrDefault("nextToken")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "nextToken", valid_402656661
  var valid_402656662 = query.getOrDefault("MaxResults")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "MaxResults", valid_402656662
  var valid_402656663 = query.getOrDefault("NextToken")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "NextToken", valid_402656663
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656664 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Security-Token", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Signature")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Signature", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Algorithm", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Date")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Date", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Credential")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Credential", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656671: Call_ListPublishingDestinations_402656656;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of publishing destinations associated with the specified <code>dectectorId</code>.
                                                                                         ## 
  let valid = call_402656671.validator(path, query, header, formData, body, _)
  let scheme = call_402656671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656671.makeUrl(scheme.get, call_402656671.host, call_402656671.base,
                                   call_402656671.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656671, uri, valid, _)

proc call*(call_402656672: Call_ListPublishingDestinations_402656656;
           detectorId: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listPublishingDestinations
  ## Returns a list of publishing destinations associated with the specified <code>dectectorId</code>.
  ##   
                                                                                                      ## maxResults: int
                                                                                                      ##             
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## maximum 
                                                                                                      ## number 
                                                                                                      ## of 
                                                                                                      ## results 
                                                                                                      ## to 
                                                                                                      ## return 
                                                                                                      ## in 
                                                                                                      ## the 
                                                                                                      ## response.
  ##   
                                                                                                                  ## nextToken: string
                                                                                                                  ##            
                                                                                                                  ## : 
                                                                                                                  ## A 
                                                                                                                  ## token 
                                                                                                                  ## to 
                                                                                                                  ## use 
                                                                                                                  ## for 
                                                                                                                  ## paginating 
                                                                                                                  ## results 
                                                                                                                  ## returned 
                                                                                                                  ## in 
                                                                                                                  ## the 
                                                                                                                  ## repsonse. 
                                                                                                                  ## Set 
                                                                                                                  ## the 
                                                                                                                  ## value 
                                                                                                                  ## of 
                                                                                                                  ## this 
                                                                                                                  ## parameter 
                                                                                                                  ## to 
                                                                                                                  ## null 
                                                                                                                  ## for 
                                                                                                                  ## the 
                                                                                                                  ## first 
                                                                                                                  ## request 
                                                                                                                  ## to 
                                                                                                                  ## a 
                                                                                                                  ## list 
                                                                                                                  ## action. 
                                                                                                                  ## For 
                                                                                                                  ## subsequent 
                                                                                                                  ## calls, 
                                                                                                                  ## use 
                                                                                                                  ## the 
                                                                                                                  ## <code>NextToken</code> 
                                                                                                                  ## value 
                                                                                                                  ## returned 
                                                                                                                  ## from 
                                                                                                                  ## the 
                                                                                                                  ## previous 
                                                                                                                  ## request 
                                                                                                                  ## to 
                                                                                                                  ## continue 
                                                                                                                  ## listing 
                                                                                                                  ## results 
                                                                                                                  ## after 
                                                                                                                  ## the 
                                                                                                                  ## first 
                                                                                                                  ## page.
  ##   
                                                                                                                          ## MaxResults: string
                                                                                                                          ##             
                                                                                                                          ## : 
                                                                                                                          ## Pagination 
                                                                                                                          ## limit
  ##   
                                                                                                                                  ## detectorId: string (required)
                                                                                                                                  ##             
                                                                                                                                  ## : 
                                                                                                                                  ## The 
                                                                                                                                  ## ID 
                                                                                                                                  ## of 
                                                                                                                                  ## the 
                                                                                                                                  ## detector 
                                                                                                                                  ## to 
                                                                                                                                  ## retrieve 
                                                                                                                                  ## publishing 
                                                                                                                                  ## destinations 
                                                                                                                                  ## for.
  ##   
                                                                                                                                         ## NextToken: string
                                                                                                                                         ##            
                                                                                                                                         ## : 
                                                                                                                                         ## Pagination 
                                                                                                                                         ## token
  var path_402656673 = newJObject()
  var query_402656674 = newJObject()
  add(query_402656674, "maxResults", newJInt(maxResults))
  add(query_402656674, "nextToken", newJString(nextToken))
  add(query_402656674, "MaxResults", newJString(MaxResults))
  add(path_402656673, "detectorId", newJString(detectorId))
  add(query_402656674, "NextToken", newJString(NextToken))
  result = call_402656672.call(path_402656673, query_402656674, nil, nil, nil)

var listPublishingDestinations* = Call_ListPublishingDestinations_402656656(
    name: "listPublishingDestinations", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination",
    validator: validate_ListPublishingDestinations_402656657, base: "/",
    makeUrl: url_ListPublishingDestinations_402656658,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSampleFindings_402656691 = ref object of OpenApiRestCall_402656044
proc url_CreateSampleFindings_402656693(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/findings/create")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSampleFindings_402656692(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for <code>findingTypes</code>, the API generates example findings of all supported finding types.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The ID of the detector to create sample findings for.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656694 = path.getOrDefault("detectorId")
  valid_402656694 = validateParameter(valid_402656694, JString, required = true,
                                      default = nil)
  if valid_402656694 != nil:
    section.add "detectorId", valid_402656694
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656695 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Security-Token", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-Signature")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-Signature", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Algorithm", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Date")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Date", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Credential")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Credential", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656703: Call_CreateSampleFindings_402656691;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for <code>findingTypes</code>, the API generates example findings of all supported finding types.
                                                                                         ## 
  let valid = call_402656703.validator(path, query, header, formData, body, _)
  let scheme = call_402656703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656703.makeUrl(scheme.get, call_402656703.host, call_402656703.base,
                                   call_402656703.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656703, uri, valid, _)

proc call*(call_402656704: Call_CreateSampleFindings_402656691; body: JsonNode;
           detectorId: string): Recallable =
  ## createSampleFindings
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for <code>findingTypes</code>, the API generates example findings of all supported finding types.
  ##   
                                                                                                                                                                                                         ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                    ## detectorId: string (required)
                                                                                                                                                                                                                                    ##             
                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                    ## ID 
                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                    ## detector 
                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                    ## create 
                                                                                                                                                                                                                                    ## sample 
                                                                                                                                                                                                                                    ## findings 
                                                                                                                                                                                                                                    ## for.
  var path_402656705 = newJObject()
  var body_402656706 = newJObject()
  if body != nil:
    body_402656706 = body
  add(path_402656705, "detectorId", newJString(detectorId))
  result = call_402656704.call(path_402656705, nil, nil, nil, body_402656706)

var createSampleFindings* = Call_CreateSampleFindings_402656691(
    name: "createSampleFindings", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/create",
    validator: validate_CreateSampleFindings_402656692, base: "/",
    makeUrl: url_CreateSampleFindings_402656693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateThreatIntelSet_402656726 = ref object of OpenApiRestCall_402656044
proc url_CreateThreatIntelSet_402656728(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/threatintelset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateThreatIntelSet_402656727(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets. Only users of the master account can use this operation.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector of the GuardDuty account for which you want to create a threatIntelSet.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656729 = path.getOrDefault("detectorId")
  valid_402656729 = validateParameter(valid_402656729, JString, required = true,
                                      default = nil)
  if valid_402656729 != nil:
    section.add "detectorId", valid_402656729
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656730 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Security-Token", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Signature")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Signature", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Algorithm", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Date")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Date", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Credential")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Credential", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656738: Call_CreateThreatIntelSet_402656726;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets. Only users of the master account can use this operation.
                                                                                         ## 
  let valid = call_402656738.validator(path, query, header, formData, body, _)
  let scheme = call_402656738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656738.makeUrl(scheme.get, call_402656738.host, call_402656738.base,
                                   call_402656738.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656738, uri, valid, _)

proc call*(call_402656739: Call_CreateThreatIntelSet_402656726; body: JsonNode;
           detectorId: string): Recallable =
  ## createThreatIntelSet
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets. Only users of the master account can use this operation.
  ##   
                                                                                                                                                                                                          ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                     ## detectorId: string (required)
                                                                                                                                                                                                                                     ##             
                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                     ## unique 
                                                                                                                                                                                                                                     ## ID 
                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## detector 
                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                     ## GuardDuty 
                                                                                                                                                                                                                                     ## account 
                                                                                                                                                                                                                                     ## for 
                                                                                                                                                                                                                                     ## which 
                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                     ## want 
                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                     ## create 
                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                     ## threatIntelSet.
  var path_402656740 = newJObject()
  var body_402656741 = newJObject()
  if body != nil:
    body_402656741 = body
  add(path_402656740, "detectorId", newJString(detectorId))
  result = call_402656739.call(path_402656740, nil, nil, nil, body_402656741)

var createThreatIntelSet* = Call_CreateThreatIntelSet_402656726(
    name: "createThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_CreateThreatIntelSet_402656727, base: "/",
    makeUrl: url_CreateThreatIntelSet_402656728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListThreatIntelSets_402656707 = ref object of OpenApiRestCall_402656044
proc url_ListThreatIntelSets_402656709(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/threatintelset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListThreatIntelSets_402656708(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the ThreatIntelSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the ThreatIntelSets associated with the master account are returned.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector the threatIntelSet is associated with.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656710 = path.getOrDefault("detectorId")
  valid_402656710 = validateParameter(valid_402656710, JString, required = true,
                                      default = nil)
  if valid_402656710 != nil:
    section.add "detectorId", valid_402656710
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   
                                                                                                                                                                                                 ## nextToken: JString
                                                                                                                                                                                                 ##            
                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                 ## You 
                                                                                                                                                                                                 ## can 
                                                                                                                                                                                                 ## use 
                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## paginate 
                                                                                                                                                                                                 ## results 
                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## response. 
                                                                                                                                                                                                 ## Set 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## null 
                                                                                                                                                                                                 ## on 
                                                                                                                                                                                                 ## your 
                                                                                                                                                                                                 ## first 
                                                                                                                                                                                                 ## call 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## list 
                                                                                                                                                                                                 ## action. 
                                                                                                                                                                                                 ## For 
                                                                                                                                                                                                 ## subsequent 
                                                                                                                                                                                                 ## calls 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## action 
                                                                                                                                                                                                 ## fill 
                                                                                                                                                                                                 ## nextToken 
                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## request 
                                                                                                                                                                                                 ## with 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                 ## NextToken 
                                                                                                                                                                                                 ## from 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## previous 
                                                                                                                                                                                                 ## response 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## continue 
                                                                                                                                                                                                 ## listing 
                                                                                                                                                                                                 ## data.
  ##   
                                                                                                                                                                                                         ## MaxResults: JString
                                                                                                                                                                                                         ##             
                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                         ## limit
  ##   
                                                                                                                                                                                                                 ## NextToken: JString
                                                                                                                                                                                                                 ##            
                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                 ## token
  section = newJObject()
  var valid_402656711 = query.getOrDefault("maxResults")
  valid_402656711 = validateParameter(valid_402656711, JInt, required = false,
                                      default = nil)
  if valid_402656711 != nil:
    section.add "maxResults", valid_402656711
  var valid_402656712 = query.getOrDefault("nextToken")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "nextToken", valid_402656712
  var valid_402656713 = query.getOrDefault("MaxResults")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "MaxResults", valid_402656713
  var valid_402656714 = query.getOrDefault("NextToken")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "NextToken", valid_402656714
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656715 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Security-Token", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Signature")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Signature", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Algorithm", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Date")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Date", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Credential")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Credential", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656722: Call_ListThreatIntelSets_402656707;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the ThreatIntelSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the ThreatIntelSets associated with the master account are returned.
                                                                                         ## 
  let valid = call_402656722.validator(path, query, header, formData, body, _)
  let scheme = call_402656722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656722.makeUrl(scheme.get, call_402656722.host, call_402656722.base,
                                   call_402656722.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656722, uri, valid, _)

proc call*(call_402656723: Call_ListThreatIntelSets_402656707;
           detectorId: string; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listThreatIntelSets
  ## Lists the ThreatIntelSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the ThreatIntelSets associated with the master account are returned.
  ##   
                                                                                                                                                                                                           ## maxResults: int
                                                                                                                                                                                                           ##             
                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                           ## You 
                                                                                                                                                                                                           ## can 
                                                                                                                                                                                                           ## use 
                                                                                                                                                                                                           ## this 
                                                                                                                                                                                                           ## parameter 
                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                           ## indicate 
                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                           ## maximum 
                                                                                                                                                                                                           ## number 
                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                           ## items 
                                                                                                                                                                                                           ## you 
                                                                                                                                                                                                           ## want 
                                                                                                                                                                                                           ## in 
                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                           ## response. 
                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                           ## default 
                                                                                                                                                                                                           ## value 
                                                                                                                                                                                                           ## is 
                                                                                                                                                                                                           ## 50. 
                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                           ## maximum 
                                                                                                                                                                                                           ## value 
                                                                                                                                                                                                           ## is 
                                                                                                                                                                                                           ## 50.
  ##   
                                                                                                                                                                                                                 ## nextToken: string
                                                                                                                                                                                                                 ##            
                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                 ## You 
                                                                                                                                                                                                                 ## can 
                                                                                                                                                                                                                 ## use 
                                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                 ## paginate 
                                                                                                                                                                                                                 ## results 
                                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## response. 
                                                                                                                                                                                                                 ## Set 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                 ## null 
                                                                                                                                                                                                                 ## on 
                                                                                                                                                                                                                 ## your 
                                                                                                                                                                                                                 ## first 
                                                                                                                                                                                                                 ## call 
                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## list 
                                                                                                                                                                                                                 ## action. 
                                                                                                                                                                                                                 ## For 
                                                                                                                                                                                                                 ## subsequent 
                                                                                                                                                                                                                 ## calls 
                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## action 
                                                                                                                                                                                                                 ## fill 
                                                                                                                                                                                                                 ## nextToken 
                                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## request 
                                                                                                                                                                                                                 ## with 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                 ## NextToken 
                                                                                                                                                                                                                 ## from 
                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                 ## previous 
                                                                                                                                                                                                                 ## response 
                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                 ## continue 
                                                                                                                                                                                                                 ## listing 
                                                                                                                                                                                                                 ## data.
  ##   
                                                                                                                                                                                                                         ## MaxResults: string
                                                                                                                                                                                                                         ##             
                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                                         ## limit
  ##   
                                                                                                                                                                                                                                 ## detectorId: string (required)
                                                                                                                                                                                                                                 ##             
                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                                 ## unique 
                                                                                                                                                                                                                                 ## ID 
                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                 ## detector 
                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                 ## threatIntelSet 
                                                                                                                                                                                                                                 ## is 
                                                                                                                                                                                                                                 ## associated 
                                                                                                                                                                                                                                 ## with.
  ##   
                                                                                                                                                                                                                                         ## NextToken: string
                                                                                                                                                                                                                                         ##            
                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                                                         ## token
  var path_402656724 = newJObject()
  var query_402656725 = newJObject()
  add(query_402656725, "maxResults", newJInt(maxResults))
  add(query_402656725, "nextToken", newJString(nextToken))
  add(query_402656725, "MaxResults", newJString(MaxResults))
  add(path_402656724, "detectorId", newJString(detectorId))
  add(query_402656725, "NextToken", newJString(NextToken))
  result = call_402656723.call(path_402656724, query_402656725, nil, nil, nil)

var listThreatIntelSets* = Call_ListThreatIntelSets_402656707(
    name: "listThreatIntelSets", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_ListThreatIntelSets_402656708, base: "/",
    makeUrl: url_ListThreatIntelSets_402656709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_402656742 = ref object of OpenApiRestCall_402656044
proc url_DeclineInvitations_402656744(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeclineInvitations_402656743(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656745 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Security-Token", valid_402656745
  var valid_402656746 = header.getOrDefault("X-Amz-Signature")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-Signature", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Algorithm", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Date")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Date", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Credential")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Credential", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656753: Call_DeclineInvitations_402656742;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
                                                                                         ## 
  let valid = call_402656753.validator(path, query, header, formData, body, _)
  let scheme = call_402656753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656753.makeUrl(scheme.get, call_402656753.host, call_402656753.base,
                                   call_402656753.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656753, uri, valid, _)

proc call*(call_402656754: Call_DeclineInvitations_402656742; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
  ##   
                                                                                                           ## body: JObject (required)
  var body_402656755 = newJObject()
  if body != nil:
    body_402656755 = body
  result = call_402656754.call(nil, nil, nil, nil, body_402656755)

var declineInvitations* = Call_DeclineInvitations_402656742(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/invitation/decline",
    validator: validate_DeclineInvitations_402656743, base: "/",
    makeUrl: url_DeclineInvitations_402656744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetector_402656770 = ref object of OpenApiRestCall_402656044
proc url_UpdateDetector_402656772(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDetector_402656771(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the Amazon GuardDuty detector specified by the detectorId.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector to update.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656773 = path.getOrDefault("detectorId")
  valid_402656773 = validateParameter(valid_402656773, JString, required = true,
                                      default = nil)
  if valid_402656773 != nil:
    section.add "detectorId", valid_402656773
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656774 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Security-Token", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-Signature")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-Signature", valid_402656775
  var valid_402656776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656776
  var valid_402656777 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-Algorithm", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Date")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Date", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Credential")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Credential", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656782: Call_UpdateDetector_402656770; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the Amazon GuardDuty detector specified by the detectorId.
                                                                                         ## 
  let valid = call_402656782.validator(path, query, header, formData, body, _)
  let scheme = call_402656782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656782.makeUrl(scheme.get, call_402656782.host, call_402656782.base,
                                   call_402656782.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656782, uri, valid, _)

proc call*(call_402656783: Call_UpdateDetector_402656770; body: JsonNode;
           detectorId: string): Recallable =
  ## updateDetector
  ## Updates the Amazon GuardDuty detector specified by the detectorId.
  ##   body: JObject 
                                                                       ## (required)
  ##   
                                                                                    ## detectorId: string (required)
                                                                                    ##             
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## unique 
                                                                                    ## ID 
                                                                                    ## of 
                                                                                    ## the 
                                                                                    ## detector 
                                                                                    ## to 
                                                                                    ## update.
  var path_402656784 = newJObject()
  var body_402656785 = newJObject()
  if body != nil:
    body_402656785 = body
  add(path_402656784, "detectorId", newJString(detectorId))
  result = call_402656783.call(path_402656784, nil, nil, nil, body_402656785)

var updateDetector* = Call_UpdateDetector_402656770(name: "updateDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_UpdateDetector_402656771,
    base: "/", makeUrl: url_UpdateDetector_402656772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetector_402656756 = ref object of OpenApiRestCall_402656044
proc url_GetDetector_402656758(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDetector_402656757(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector that you want to get.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656759 = path.getOrDefault("detectorId")
  valid_402656759 = validateParameter(valid_402656759, JString, required = true,
                                      default = nil)
  if valid_402656759 != nil:
    section.add "detectorId", valid_402656759
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656760 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-Security-Token", valid_402656760
  var valid_402656761 = header.getOrDefault("X-Amz-Signature")
  valid_402656761 = validateParameter(valid_402656761, JString,
                                      required = false, default = nil)
  if valid_402656761 != nil:
    section.add "X-Amz-Signature", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Algorithm", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Date")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Date", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Credential")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Credential", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656767: Call_GetDetector_402656756; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
                                                                                         ## 
  let valid = call_402656767.validator(path, query, header, formData, body, _)
  let scheme = call_402656767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656767.makeUrl(scheme.get, call_402656767.host, call_402656767.base,
                                   call_402656767.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656767, uri, valid, _)

proc call*(call_402656768: Call_GetDetector_402656756; detectorId: string): Recallable =
  ## getDetector
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
  ##   
                                                                        ## detectorId: string (required)
                                                                        ##             
                                                                        ## : 
                                                                        ## The 
                                                                        ## unique 
                                                                        ## ID 
                                                                        ## of 
                                                                        ## the 
                                                                        ## detector 
                                                                        ## that 
                                                                        ## you 
                                                                        ## want 
                                                                        ## to 
                                                                        ## get.
  var path_402656769 = newJObject()
  add(path_402656769, "detectorId", newJString(detectorId))
  result = call_402656768.call(path_402656769, nil, nil, nil, nil)

var getDetector* = Call_GetDetector_402656756(name: "getDetector",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_GetDetector_402656757,
    base: "/", makeUrl: url_GetDetector_402656758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetector_402656786 = ref object of OpenApiRestCall_402656044
proc url_DeleteDetector_402656788(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDetector_402656787(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector that you want to delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656789 = path.getOrDefault("detectorId")
  valid_402656789 = validateParameter(valid_402656789, JString, required = true,
                                      default = nil)
  if valid_402656789 != nil:
    section.add "detectorId", valid_402656789
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656790 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Security-Token", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-Signature")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Signature", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Algorithm", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Date")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Date", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Credential")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Credential", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656797: Call_DeleteDetector_402656786; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
                                                                                         ## 
  let valid = call_402656797.validator(path, query, header, formData, body, _)
  let scheme = call_402656797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656797.makeUrl(scheme.get, call_402656797.host, call_402656797.base,
                                   call_402656797.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656797, uri, valid, _)

proc call*(call_402656798: Call_DeleteDetector_402656786; detectorId: string): Recallable =
  ## deleteDetector
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
  ##   
                                                                      ## detectorId: string (required)
                                                                      ##             
                                                                      ## : 
                                                                      ## The 
                                                                      ## unique ID of the 
                                                                      ## detector 
                                                                      ## that 
                                                                      ## you 
                                                                      ## want to 
                                                                      ## delete.
  var path_402656799 = newJObject()
  add(path_402656799, "detectorId", newJString(detectorId))
  result = call_402656798.call(path_402656799, nil, nil, nil, nil)

var deleteDetector* = Call_DeleteDetector_402656786(name: "deleteDetector",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_DeleteDetector_402656787,
    base: "/", makeUrl: url_DeleteDetector_402656788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFilter_402656815 = ref object of OpenApiRestCall_402656044
proc url_UpdateFilter_402656817(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  assert "filterName" in path, "`filterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/filter/"),
                 (kind: VariableSegment, value: "filterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFilter_402656816(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the filter specified by the filter name.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector that specifies the GuardDuty service where you want to update a filter.
  ##   
                                                                                                                                                       ## filterName: JString (required)
                                                                                                                                                       ##             
                                                                                                                                                       ## : 
                                                                                                                                                       ## The 
                                                                                                                                                       ## name 
                                                                                                                                                       ## of 
                                                                                                                                                       ## the 
                                                                                                                                                       ## filter.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656818 = path.getOrDefault("detectorId")
  valid_402656818 = validateParameter(valid_402656818, JString, required = true,
                                      default = nil)
  if valid_402656818 != nil:
    section.add "detectorId", valid_402656818
  var valid_402656819 = path.getOrDefault("filterName")
  valid_402656819 = validateParameter(valid_402656819, JString, required = true,
                                      default = nil)
  if valid_402656819 != nil:
    section.add "filterName", valid_402656819
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656820 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Security-Token", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-Signature")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Signature", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Algorithm", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Date")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Date", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Credential")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Credential", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656828: Call_UpdateFilter_402656815; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the filter specified by the filter name.
                                                                                         ## 
  let valid = call_402656828.validator(path, query, header, formData, body, _)
  let scheme = call_402656828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656828.makeUrl(scheme.get, call_402656828.host, call_402656828.base,
                                   call_402656828.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656828, uri, valid, _)

proc call*(call_402656829: Call_UpdateFilter_402656815; body: JsonNode;
           detectorId: string; filterName: string): Recallable =
  ## updateFilter
  ## Updates the filter specified by the filter name.
  ##   body: JObject (required)
  ##   detectorId: string (required)
                               ##             : The unique ID of the detector that specifies the GuardDuty service where you want to update a filter.
  ##   
                                                                                                                                                     ## filterName: string (required)
                                                                                                                                                     ##             
                                                                                                                                                     ## : 
                                                                                                                                                     ## The 
                                                                                                                                                     ## name 
                                                                                                                                                     ## of 
                                                                                                                                                     ## the 
                                                                                                                                                     ## filter.
  var path_402656830 = newJObject()
  var body_402656831 = newJObject()
  if body != nil:
    body_402656831 = body
  add(path_402656830, "detectorId", newJString(detectorId))
  add(path_402656830, "filterName", newJString(filterName))
  result = call_402656829.call(path_402656830, nil, nil, nil, body_402656831)

var updateFilter* = Call_UpdateFilter_402656815(name: "updateFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_UpdateFilter_402656816, base: "/",
    makeUrl: url_UpdateFilter_402656817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFilter_402656800 = ref object of OpenApiRestCall_402656044
proc url_GetFilter_402656802(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  assert "filterName" in path, "`filterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/filter/"),
                 (kind: VariableSegment, value: "filterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFilter_402656801(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the details of the filter specified by the filter name.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector the filter is associated with.
  ##   
                                                                                                              ## filterName: JString (required)
                                                                                                              ##             
                                                                                                              ## : 
                                                                                                              ## The 
                                                                                                              ## name 
                                                                                                              ## of 
                                                                                                              ## the 
                                                                                                              ## filter 
                                                                                                              ## you 
                                                                                                              ## want 
                                                                                                              ## to 
                                                                                                              ## get.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656803 = path.getOrDefault("detectorId")
  valid_402656803 = validateParameter(valid_402656803, JString, required = true,
                                      default = nil)
  if valid_402656803 != nil:
    section.add "detectorId", valid_402656803
  var valid_402656804 = path.getOrDefault("filterName")
  valid_402656804 = validateParameter(valid_402656804, JString, required = true,
                                      default = nil)
  if valid_402656804 != nil:
    section.add "filterName", valid_402656804
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656805 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-Security-Token", valid_402656805
  var valid_402656806 = header.getOrDefault("X-Amz-Signature")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Signature", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Algorithm", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Date")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Date", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Credential")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Credential", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656812: Call_GetFilter_402656800; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the details of the filter specified by the filter name.
                                                                                         ## 
  let valid = call_402656812.validator(path, query, header, formData, body, _)
  let scheme = call_402656812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656812.makeUrl(scheme.get, call_402656812.host, call_402656812.base,
                                   call_402656812.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656812, uri, valid, _)

proc call*(call_402656813: Call_GetFilter_402656800; detectorId: string;
           filterName: string): Recallable =
  ## getFilter
  ## Returns the details of the filter specified by the filter name.
  ##   detectorId: string (required)
                                                                    ##             : The unique ID of the detector the filter is associated with.
  ##   
                                                                                                                                                 ## filterName: string (required)
                                                                                                                                                 ##             
                                                                                                                                                 ## : 
                                                                                                                                                 ## The 
                                                                                                                                                 ## name 
                                                                                                                                                 ## of 
                                                                                                                                                 ## the 
                                                                                                                                                 ## filter 
                                                                                                                                                 ## you 
                                                                                                                                                 ## want 
                                                                                                                                                 ## to 
                                                                                                                                                 ## get.
  var path_402656814 = newJObject()
  add(path_402656814, "detectorId", newJString(detectorId))
  add(path_402656814, "filterName", newJString(filterName))
  result = call_402656813.call(path_402656814, nil, nil, nil, nil)

var getFilter* = Call_GetFilter_402656800(name: "getFilter",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_GetFilter_402656801, base: "/", makeUrl: url_GetFilter_402656802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFilter_402656832 = ref object of OpenApiRestCall_402656044
proc url_DeleteFilter_402656834(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  assert "filterName" in path, "`filterName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/filter/"),
                 (kind: VariableSegment, value: "filterName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFilter_402656833(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the filter specified by the filter name.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector the filter is associated with.
  ##   
                                                                                                              ## filterName: JString (required)
                                                                                                              ##             
                                                                                                              ## : 
                                                                                                              ## The 
                                                                                                              ## name 
                                                                                                              ## of 
                                                                                                              ## the 
                                                                                                              ## filter 
                                                                                                              ## you 
                                                                                                              ## want 
                                                                                                              ## to 
                                                                                                              ## delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656835 = path.getOrDefault("detectorId")
  valid_402656835 = validateParameter(valid_402656835, JString, required = true,
                                      default = nil)
  if valid_402656835 != nil:
    section.add "detectorId", valid_402656835
  var valid_402656836 = path.getOrDefault("filterName")
  valid_402656836 = validateParameter(valid_402656836, JString, required = true,
                                      default = nil)
  if valid_402656836 != nil:
    section.add "filterName", valid_402656836
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656837 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-Security-Token", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Signature")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Signature", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Algorithm", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Date")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Date", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Credential")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Credential", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656844: Call_DeleteFilter_402656832; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the filter specified by the filter name.
                                                                                         ## 
  let valid = call_402656844.validator(path, query, header, formData, body, _)
  let scheme = call_402656844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656844.makeUrl(scheme.get, call_402656844.host, call_402656844.base,
                                   call_402656844.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656844, uri, valid, _)

proc call*(call_402656845: Call_DeleteFilter_402656832; detectorId: string;
           filterName: string): Recallable =
  ## deleteFilter
  ## Deletes the filter specified by the filter name.
  ##   detectorId: string (required)
                                                     ##             : The unique ID of the detector the filter is associated with.
  ##   
                                                                                                                                  ## filterName: string (required)
                                                                                                                                  ##             
                                                                                                                                  ## : 
                                                                                                                                  ## The 
                                                                                                                                  ## name 
                                                                                                                                  ## of 
                                                                                                                                  ## the 
                                                                                                                                  ## filter 
                                                                                                                                  ## you 
                                                                                                                                  ## want 
                                                                                                                                  ## to 
                                                                                                                                  ## delete.
  var path_402656846 = newJObject()
  add(path_402656846, "detectorId", newJString(detectorId))
  add(path_402656846, "filterName", newJString(filterName))
  result = call_402656845.call(path_402656846, nil, nil, nil, nil)

var deleteFilter* = Call_DeleteFilter_402656832(name: "deleteFilter",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_DeleteFilter_402656833, base: "/",
    makeUrl: url_DeleteFilter_402656834, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIPSet_402656862 = ref object of OpenApiRestCall_402656044
proc url_UpdateIPSet_402656864(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  assert "ipSetId" in path, "`ipSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/ipset/"),
                 (kind: VariableSegment, value: "ipSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIPSet_402656863(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the IPSet specified by the IPSet ID.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ipSetId: JString (required)
                                 ##          : The unique ID that specifies the IPSet that you want to update.
  ##   
                                                                                                              ## detectorId: JString (required)
                                                                                                              ##             
                                                                                                              ## : 
                                                                                                              ## The 
                                                                                                              ## detectorID 
                                                                                                              ## that 
                                                                                                              ## specifies 
                                                                                                              ## the 
                                                                                                              ## GuardDuty 
                                                                                                              ## service 
                                                                                                              ## whose 
                                                                                                              ## IPSet 
                                                                                                              ## you 
                                                                                                              ## want 
                                                                                                              ## to 
                                                                                                              ## update.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ipSetId` field"
  var valid_402656865 = path.getOrDefault("ipSetId")
  valid_402656865 = validateParameter(valid_402656865, JString, required = true,
                                      default = nil)
  if valid_402656865 != nil:
    section.add "ipSetId", valid_402656865
  var valid_402656866 = path.getOrDefault("detectorId")
  valid_402656866 = validateParameter(valid_402656866, JString, required = true,
                                      default = nil)
  if valid_402656866 != nil:
    section.add "detectorId", valid_402656866
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656867 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656867 = validateParameter(valid_402656867, JString,
                                      required = false, default = nil)
  if valid_402656867 != nil:
    section.add "X-Amz-Security-Token", valid_402656867
  var valid_402656868 = header.getOrDefault("X-Amz-Signature")
  valid_402656868 = validateParameter(valid_402656868, JString,
                                      required = false, default = nil)
  if valid_402656868 != nil:
    section.add "X-Amz-Signature", valid_402656868
  var valid_402656869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656869
  var valid_402656870 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "X-Amz-Algorithm", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Date")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Date", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Credential")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Credential", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656875: Call_UpdateIPSet_402656862; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the IPSet specified by the IPSet ID.
                                                                                         ## 
  let valid = call_402656875.validator(path, query, header, formData, body, _)
  let scheme = call_402656875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656875.makeUrl(scheme.get, call_402656875.host, call_402656875.base,
                                   call_402656875.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656875, uri, valid, _)

proc call*(call_402656876: Call_UpdateIPSet_402656862; ipSetId: string;
           body: JsonNode; detectorId: string): Recallable =
  ## updateIPSet
  ## Updates the IPSet specified by the IPSet ID.
  ##   ipSetId: string (required)
                                                 ##          : The unique ID that specifies the IPSet that you want to update.
  ##   
                                                                                                                              ## body: JObject (required)
  ##   
                                                                                                                                                         ## detectorId: string (required)
                                                                                                                                                         ##             
                                                                                                                                                         ## : 
                                                                                                                                                         ## The 
                                                                                                                                                         ## detectorID 
                                                                                                                                                         ## that 
                                                                                                                                                         ## specifies 
                                                                                                                                                         ## the 
                                                                                                                                                         ## GuardDuty 
                                                                                                                                                         ## service 
                                                                                                                                                         ## whose 
                                                                                                                                                         ## IPSet 
                                                                                                                                                         ## you 
                                                                                                                                                         ## want 
                                                                                                                                                         ## to 
                                                                                                                                                         ## update.
  var path_402656877 = newJObject()
  var body_402656878 = newJObject()
  add(path_402656877, "ipSetId", newJString(ipSetId))
  if body != nil:
    body_402656878 = body
  add(path_402656877, "detectorId", newJString(detectorId))
  result = call_402656876.call(path_402656877, nil, nil, nil, body_402656878)

var updateIPSet* = Call_UpdateIPSet_402656862(name: "updateIPSet",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/ipset/{ipSetId}",
    validator: validate_UpdateIPSet_402656863, base: "/",
    makeUrl: url_UpdateIPSet_402656864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIPSet_402656847 = ref object of OpenApiRestCall_402656044
proc url_GetIPSet_402656849(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  assert "ipSetId" in path, "`ipSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/ipset/"),
                 (kind: VariableSegment, value: "ipSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIPSet_402656848(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ipSetId: JString (required)
                                 ##          : The unique ID of the IPSet to retrieve.
  ##   
                                                                                      ## detectorId: JString (required)
                                                                                      ##             
                                                                                      ## : 
                                                                                      ## The 
                                                                                      ## unique 
                                                                                      ## ID 
                                                                                      ## of 
                                                                                      ## the 
                                                                                      ## detector 
                                                                                      ## the 
                                                                                      ## ipSet 
                                                                                      ## is 
                                                                                      ## associated 
                                                                                      ## with.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ipSetId` field"
  var valid_402656850 = path.getOrDefault("ipSetId")
  valid_402656850 = validateParameter(valid_402656850, JString, required = true,
                                      default = nil)
  if valid_402656850 != nil:
    section.add "ipSetId", valid_402656850
  var valid_402656851 = path.getOrDefault("detectorId")
  valid_402656851 = validateParameter(valid_402656851, JString, required = true,
                                      default = nil)
  if valid_402656851 != nil:
    section.add "detectorId", valid_402656851
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656852 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "X-Amz-Security-Token", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-Signature")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-Signature", valid_402656853
  var valid_402656854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Algorithm", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Date")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Date", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Credential")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Credential", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656859: Call_GetIPSet_402656847; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
                                                                                         ## 
  let valid = call_402656859.validator(path, query, header, formData, body, _)
  let scheme = call_402656859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656859.makeUrl(scheme.get, call_402656859.host, call_402656859.base,
                                   call_402656859.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656859, uri, valid, _)

proc call*(call_402656860: Call_GetIPSet_402656847; ipSetId: string;
           detectorId: string): Recallable =
  ## getIPSet
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
  ##   ipSetId: string (required)
                                                               ##          : The unique ID of the IPSet to retrieve.
  ##   
                                                                                                                    ## detectorId: string (required)
                                                                                                                    ##             
                                                                                                                    ## : 
                                                                                                                    ## The 
                                                                                                                    ## unique 
                                                                                                                    ## ID 
                                                                                                                    ## of 
                                                                                                                    ## the 
                                                                                                                    ## detector 
                                                                                                                    ## the 
                                                                                                                    ## ipSet 
                                                                                                                    ## is 
                                                                                                                    ## associated 
                                                                                                                    ## with.
  var path_402656861 = newJObject()
  add(path_402656861, "ipSetId", newJString(ipSetId))
  add(path_402656861, "detectorId", newJString(detectorId))
  result = call_402656860.call(path_402656861, nil, nil, nil, nil)

var getIPSet* = Call_GetIPSet_402656847(name: "getIPSet",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                        validator: validate_GetIPSet_402656848,
                                        base: "/", makeUrl: url_GetIPSet_402656849,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIPSet_402656879 = ref object of OpenApiRestCall_402656044
proc url_DeleteIPSet_402656881(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  assert "ipSetId" in path, "`ipSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/ipset/"),
                 (kind: VariableSegment, value: "ipSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIPSet_402656880(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ipSetId: JString (required)
                                 ##          : The unique ID of the IPSet to delete.
  ##   
                                                                                    ## detectorId: JString (required)
                                                                                    ##             
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## unique 
                                                                                    ## ID 
                                                                                    ## of 
                                                                                    ## the 
                                                                                    ## detector 
                                                                                    ## associated 
                                                                                    ## with 
                                                                                    ## the 
                                                                                    ## IPSet.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ipSetId` field"
  var valid_402656882 = path.getOrDefault("ipSetId")
  valid_402656882 = validateParameter(valid_402656882, JString, required = true,
                                      default = nil)
  if valid_402656882 != nil:
    section.add "ipSetId", valid_402656882
  var valid_402656883 = path.getOrDefault("detectorId")
  valid_402656883 = validateParameter(valid_402656883, JString, required = true,
                                      default = nil)
  if valid_402656883 != nil:
    section.add "detectorId", valid_402656883
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656884 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Security-Token", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-Signature")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-Signature", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Algorithm", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Date")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Date", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Credential")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Credential", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656891: Call_DeleteIPSet_402656879; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
                                                                                         ## 
  let valid = call_402656891.validator(path, query, header, formData, body, _)
  let scheme = call_402656891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656891.makeUrl(scheme.get, call_402656891.host, call_402656891.base,
                                   call_402656891.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656891, uri, valid, _)

proc call*(call_402656892: Call_DeleteIPSet_402656879; ipSetId: string;
           detectorId: string): Recallable =
  ## deleteIPSet
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
  ##   
                                                                                                                               ## ipSetId: string (required)
                                                                                                                               ##          
                                                                                                                               ## : 
                                                                                                                               ## The 
                                                                                                                               ## unique 
                                                                                                                               ## ID 
                                                                                                                               ## of 
                                                                                                                               ## the 
                                                                                                                               ## IPSet 
                                                                                                                               ## to 
                                                                                                                               ## delete.
  ##   
                                                                                                                                         ## detectorId: string (required)
                                                                                                                                         ##             
                                                                                                                                         ## : 
                                                                                                                                         ## The 
                                                                                                                                         ## unique 
                                                                                                                                         ## ID 
                                                                                                                                         ## of 
                                                                                                                                         ## the 
                                                                                                                                         ## detector 
                                                                                                                                         ## associated 
                                                                                                                                         ## with 
                                                                                                                                         ## the 
                                                                                                                                         ## IPSet.
  var path_402656893 = newJObject()
  add(path_402656893, "ipSetId", newJString(ipSetId))
  add(path_402656893, "detectorId", newJString(detectorId))
  result = call_402656892.call(path_402656893, nil, nil, nil, nil)

var deleteIPSet* = Call_DeleteIPSet_402656879(name: "deleteIPSet",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/ipset/{ipSetId}",
    validator: validate_DeleteIPSet_402656880, base: "/",
    makeUrl: url_DeleteIPSet_402656881, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_402656894 = ref object of OpenApiRestCall_402656044
proc url_DeleteInvitations_402656896(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInvitations_402656895(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656897 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656897 = validateParameter(valid_402656897, JString,
                                      required = false, default = nil)
  if valid_402656897 != nil:
    section.add "X-Amz-Security-Token", valid_402656897
  var valid_402656898 = header.getOrDefault("X-Amz-Signature")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-Signature", valid_402656898
  var valid_402656899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Algorithm", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Date")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Date", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Credential")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Credential", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656905: Call_DeleteInvitations_402656894;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
                                                                                         ## 
  let valid = call_402656905.validator(path, query, header, formData, body, _)
  let scheme = call_402656905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656905.makeUrl(scheme.get, call_402656905.host, call_402656905.base,
                                   call_402656905.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656905, uri, valid, _)

proc call*(call_402656906: Call_DeleteInvitations_402656894; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
  ##   
                                                                                                           ## body: JObject (required)
  var body_402656907 = newJObject()
  if body != nil:
    body_402656907 = body
  result = call_402656906.call(nil, nil, nil, nil, body_402656907)

var deleteInvitations* = Call_DeleteInvitations_402656894(
    name: "deleteInvitations", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/invitation/delete",
    validator: validate_DeleteInvitations_402656895, base: "/",
    makeUrl: url_DeleteInvitations_402656896,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_402656908 = ref object of OpenApiRestCall_402656044
proc url_DeleteMembers_402656910(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/member/delete")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMembers_402656909(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector of the GuardDuty account whose members you want to delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402656911 = path.getOrDefault("detectorId")
  valid_402656911 = validateParameter(valid_402656911, JString, required = true,
                                      default = nil)
  if valid_402656911 != nil:
    section.add "detectorId", valid_402656911
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656912 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656912 = validateParameter(valid_402656912, JString,
                                      required = false, default = nil)
  if valid_402656912 != nil:
    section.add "X-Amz-Security-Token", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-Signature")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Signature", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-Algorithm", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Date")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Date", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-Credential")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Credential", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656920: Call_DeleteMembers_402656908; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
                                                                                         ## 
  let valid = call_402656920.validator(path, query, header, formData, body, _)
  let scheme = call_402656920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656920.makeUrl(scheme.get, call_402656920.host, call_402656920.base,
                                   call_402656920.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656920, uri, valid, _)

proc call*(call_402656921: Call_DeleteMembers_402656908; body: JsonNode;
           detectorId: string): Recallable =
  ## deleteMembers
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   
                                                                                                              ## body: JObject (required)
  ##   
                                                                                                                                         ## detectorId: string (required)
                                                                                                                                         ##             
                                                                                                                                         ## : 
                                                                                                                                         ## The 
                                                                                                                                         ## unique 
                                                                                                                                         ## ID 
                                                                                                                                         ## of 
                                                                                                                                         ## the 
                                                                                                                                         ## detector 
                                                                                                                                         ## of 
                                                                                                                                         ## the 
                                                                                                                                         ## GuardDuty 
                                                                                                                                         ## account 
                                                                                                                                         ## whose 
                                                                                                                                         ## members 
                                                                                                                                         ## you 
                                                                                                                                         ## want 
                                                                                                                                         ## to 
                                                                                                                                         ## delete.
  var path_402656922 = newJObject()
  var body_402656923 = newJObject()
  if body != nil:
    body_402656923 = body
  add(path_402656922, "detectorId", newJString(detectorId))
  result = call_402656921.call(path_402656922, nil, nil, nil, body_402656923)

var deleteMembers* = Call_DeleteMembers_402656908(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/delete",
    validator: validate_DeleteMembers_402656909, base: "/",
    makeUrl: url_DeleteMembers_402656910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePublishingDestination_402656939 = ref object of OpenApiRestCall_402656044
proc url_UpdatePublishingDestination_402656941(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  assert "destinationId" in path, "`destinationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/publishingDestination/"),
                 (kind: VariableSegment, value: "destinationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePublishingDestination_402656940(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   destinationId: JString (required)
                                 ##                : The ID of the detector associated with the publishing destinations to update.
  ##   
                                                                                                                                  ## detectorId: JString (required)
                                                                                                                                  ##             
                                                                                                                                  ## : 
                                                                                                                                  ## The 
                                                                                                                                  ## ID 
                                                                                                                                  ## of 
                                                                                                                                  ## the 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `destinationId` field"
  var valid_402656942 = path.getOrDefault("destinationId")
  valid_402656942 = validateParameter(valid_402656942, JString, required = true,
                                      default = nil)
  if valid_402656942 != nil:
    section.add "destinationId", valid_402656942
  var valid_402656943 = path.getOrDefault("detectorId")
  valid_402656943 = validateParameter(valid_402656943, JString, required = true,
                                      default = nil)
  if valid_402656943 != nil:
    section.add "detectorId", valid_402656943
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656944 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656944 = validateParameter(valid_402656944, JString,
                                      required = false, default = nil)
  if valid_402656944 != nil:
    section.add "X-Amz-Security-Token", valid_402656944
  var valid_402656945 = header.getOrDefault("X-Amz-Signature")
  valid_402656945 = validateParameter(valid_402656945, JString,
                                      required = false, default = nil)
  if valid_402656945 != nil:
    section.add "X-Amz-Signature", valid_402656945
  var valid_402656946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Algorithm", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-Date")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-Date", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-Credential")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-Credential", valid_402656949
  var valid_402656950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656950 = validateParameter(valid_402656950, JString,
                                      required = false, default = nil)
  if valid_402656950 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656952: Call_UpdatePublishingDestination_402656939;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
                                                                                         ## 
  let valid = call_402656952.validator(path, query, header, formData, body, _)
  let scheme = call_402656952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656952.makeUrl(scheme.get, call_402656952.host, call_402656952.base,
                                   call_402656952.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656952, uri, valid, _)

proc call*(call_402656953: Call_UpdatePublishingDestination_402656939;
           destinationId: string; body: JsonNode; detectorId: string): Recallable =
  ## updatePublishingDestination
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
  ##   
                                                                                                      ## destinationId: string (required)
                                                                                                      ##                
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## ID 
                                                                                                      ## of 
                                                                                                      ## the 
                                                                                                      ## detector 
                                                                                                      ## associated 
                                                                                                      ## with 
                                                                                                      ## the 
                                                                                                      ## publishing 
                                                                                                      ## destinations 
                                                                                                      ## to 
                                                                                                      ## update.
  ##   
                                                                                                                ## body: JObject (required)
  ##   
                                                                                                                                           ## detectorId: string (required)
                                                                                                                                           ##             
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## ID 
                                                                                                                                           ## of 
                                                                                                                                           ## the 
  var path_402656954 = newJObject()
  var body_402656955 = newJObject()
  add(path_402656954, "destinationId", newJString(destinationId))
  if body != nil:
    body_402656955 = body
  add(path_402656954, "detectorId", newJString(detectorId))
  result = call_402656953.call(path_402656954, nil, nil, nil, body_402656955)

var updatePublishingDestination* = Call_UpdatePublishingDestination_402656939(
    name: "updatePublishingDestination", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_UpdatePublishingDestination_402656940, base: "/",
    makeUrl: url_UpdatePublishingDestination_402656941,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePublishingDestination_402656924 = ref object of OpenApiRestCall_402656044
proc url_DescribePublishingDestination_402656926(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  assert "destinationId" in path, "`destinationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/publishingDestination/"),
                 (kind: VariableSegment, value: "destinationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribePublishingDestination_402656925(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   destinationId: JString (required)
                                 ##                : The ID of the publishing destination to retrieve.
  ##   
                                                                                                      ## detectorId: JString (required)
                                                                                                      ##             
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## unique 
                                                                                                      ## ID 
                                                                                                      ## of 
                                                                                                      ## the 
                                                                                                      ## detector 
                                                                                                      ## associated 
                                                                                                      ## with 
                                                                                                      ## the 
                                                                                                      ## publishing 
                                                                                                      ## destination 
                                                                                                      ## to 
                                                                                                      ## retrieve.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `destinationId` field"
  var valid_402656927 = path.getOrDefault("destinationId")
  valid_402656927 = validateParameter(valid_402656927, JString, required = true,
                                      default = nil)
  if valid_402656927 != nil:
    section.add "destinationId", valid_402656927
  var valid_402656928 = path.getOrDefault("detectorId")
  valid_402656928 = validateParameter(valid_402656928, JString, required = true,
                                      default = nil)
  if valid_402656928 != nil:
    section.add "detectorId", valid_402656928
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656929 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Security-Token", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Signature")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Signature", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Algorithm", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-Date")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-Date", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-Credential")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Credential", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656936: Call_DescribePublishingDestination_402656924;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
                                                                                         ## 
  let valid = call_402656936.validator(path, query, header, formData, body, _)
  let scheme = call_402656936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656936.makeUrl(scheme.get, call_402656936.host, call_402656936.base,
                                   call_402656936.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656936, uri, valid, _)

proc call*(call_402656937: Call_DescribePublishingDestination_402656924;
           destinationId: string; detectorId: string): Recallable =
  ## describePublishingDestination
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
  ##   
                                                                                                               ## destinationId: string (required)
                                                                                                               ##                
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## ID 
                                                                                                               ## of 
                                                                                                               ## the 
                                                                                                               ## publishing 
                                                                                                               ## destination 
                                                                                                               ## to 
                                                                                                               ## retrieve.
  ##   
                                                                                                                           ## detectorId: string (required)
                                                                                                                           ##             
                                                                                                                           ## : 
                                                                                                                           ## The 
                                                                                                                           ## unique 
                                                                                                                           ## ID 
                                                                                                                           ## of 
                                                                                                                           ## the 
                                                                                                                           ## detector 
                                                                                                                           ## associated 
                                                                                                                           ## with 
                                                                                                                           ## the 
                                                                                                                           ## publishing 
                                                                                                                           ## destination 
                                                                                                                           ## to 
                                                                                                                           ## retrieve.
  var path_402656938 = newJObject()
  add(path_402656938, "destinationId", newJString(destinationId))
  add(path_402656938, "detectorId", newJString(detectorId))
  result = call_402656937.call(path_402656938, nil, nil, nil, nil)

var describePublishingDestination* = Call_DescribePublishingDestination_402656924(
    name: "describePublishingDestination", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_DescribePublishingDestination_402656925, base: "/",
    makeUrl: url_DescribePublishingDestination_402656926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublishingDestination_402656956 = ref object of OpenApiRestCall_402656044
proc url_DeletePublishingDestination_402656958(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  assert "destinationId" in path, "`destinationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/publishingDestination/"),
                 (kind: VariableSegment, value: "destinationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePublishingDestination_402656957(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   destinationId: JString (required)
                                 ##                : The ID of the publishing destination to delete.
  ##   
                                                                                                    ## detectorId: JString (required)
                                                                                                    ##             
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## unique 
                                                                                                    ## ID 
                                                                                                    ## of 
                                                                                                    ## the 
                                                                                                    ## detector 
                                                                                                    ## associated 
                                                                                                    ## with 
                                                                                                    ## the 
                                                                                                    ## publishing 
                                                                                                    ## destination 
                                                                                                    ## to 
                                                                                                    ## delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `destinationId` field"
  var valid_402656959 = path.getOrDefault("destinationId")
  valid_402656959 = validateParameter(valid_402656959, JString, required = true,
                                      default = nil)
  if valid_402656959 != nil:
    section.add "destinationId", valid_402656959
  var valid_402656960 = path.getOrDefault("detectorId")
  valid_402656960 = validateParameter(valid_402656960, JString, required = true,
                                      default = nil)
  if valid_402656960 != nil:
    section.add "detectorId", valid_402656960
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656961 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Security-Token", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-Signature")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-Signature", valid_402656962
  var valid_402656963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656963
  var valid_402656964 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-Algorithm", valid_402656964
  var valid_402656965 = header.getOrDefault("X-Amz-Date")
  valid_402656965 = validateParameter(valid_402656965, JString,
                                      required = false, default = nil)
  if valid_402656965 != nil:
    section.add "X-Amz-Date", valid_402656965
  var valid_402656966 = header.getOrDefault("X-Amz-Credential")
  valid_402656966 = validateParameter(valid_402656966, JString,
                                      required = false, default = nil)
  if valid_402656966 != nil:
    section.add "X-Amz-Credential", valid_402656966
  var valid_402656967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656967 = validateParameter(valid_402656967, JString,
                                      required = false, default = nil)
  if valid_402656967 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656968: Call_DeletePublishingDestination_402656956;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
                                                                                         ## 
  let valid = call_402656968.validator(path, query, header, formData, body, _)
  let scheme = call_402656968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656968.makeUrl(scheme.get, call_402656968.host, call_402656968.base,
                                   call_402656968.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656968, uri, valid, _)

proc call*(call_402656969: Call_DeletePublishingDestination_402656956;
           destinationId: string; detectorId: string): Recallable =
  ## deletePublishingDestination
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
  ##   
                                                                                     ## destinationId: string (required)
                                                                                     ##                
                                                                                     ## : 
                                                                                     ## The 
                                                                                     ## ID 
                                                                                     ## of 
                                                                                     ## the 
                                                                                     ## publishing 
                                                                                     ## destination 
                                                                                     ## to 
                                                                                     ## delete.
  ##   
                                                                                               ## detectorId: string (required)
                                                                                               ##             
                                                                                               ## : 
                                                                                               ## The 
                                                                                               ## unique 
                                                                                               ## ID 
                                                                                               ## of 
                                                                                               ## the 
                                                                                               ## detector 
                                                                                               ## associated 
                                                                                               ## with 
                                                                                               ## the 
                                                                                               ## publishing 
                                                                                               ## destination 
                                                                                               ## to 
                                                                                               ## delete.
  var path_402656970 = newJObject()
  add(path_402656970, "destinationId", newJString(destinationId))
  add(path_402656970, "detectorId", newJString(detectorId))
  result = call_402656969.call(path_402656970, nil, nil, nil, nil)

var deletePublishingDestination* = Call_DeletePublishingDestination_402656956(
    name: "deletePublishingDestination", meth: HttpMethod.HttpDelete,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_DeletePublishingDestination_402656957, base: "/",
    makeUrl: url_DeletePublishingDestination_402656958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateThreatIntelSet_402656986 = ref object of OpenApiRestCall_402656044
proc url_UpdateThreatIntelSet_402656988(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  assert "threatIntelSetId" in path,
         "`threatIntelSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/threatintelset/"),
                 (kind: VariableSegment, value: "threatIntelSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateThreatIntelSet_402656987(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   threatIntelSetId: JString (required)
                                 ##                   : The unique ID that specifies the ThreatIntelSet that you want to update.
  ##   
                                                                                                                                ## detectorId: JString (required)
                                                                                                                                ##             
                                                                                                                                ## : 
                                                                                                                                ## The 
                                                                                                                                ## detectorID 
                                                                                                                                ## that 
                                                                                                                                ## specifies 
                                                                                                                                ## the 
                                                                                                                                ## GuardDuty 
                                                                                                                                ## service 
                                                                                                                                ## whose 
                                                                                                                                ## ThreatIntelSet 
                                                                                                                                ## you 
                                                                                                                                ## want 
                                                                                                                                ## to 
                                                                                                                                ## update.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `threatIntelSetId` field"
  var valid_402656989 = path.getOrDefault("threatIntelSetId")
  valid_402656989 = validateParameter(valid_402656989, JString, required = true,
                                      default = nil)
  if valid_402656989 != nil:
    section.add "threatIntelSetId", valid_402656989
  var valid_402656990 = path.getOrDefault("detectorId")
  valid_402656990 = validateParameter(valid_402656990, JString, required = true,
                                      default = nil)
  if valid_402656990 != nil:
    section.add "detectorId", valid_402656990
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656991 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-Security-Token", valid_402656991
  var valid_402656992 = header.getOrDefault("X-Amz-Signature")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "X-Amz-Signature", valid_402656992
  var valid_402656993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-Algorithm", valid_402656994
  var valid_402656995 = header.getOrDefault("X-Amz-Date")
  valid_402656995 = validateParameter(valid_402656995, JString,
                                      required = false, default = nil)
  if valid_402656995 != nil:
    section.add "X-Amz-Date", valid_402656995
  var valid_402656996 = header.getOrDefault("X-Amz-Credential")
  valid_402656996 = validateParameter(valid_402656996, JString,
                                      required = false, default = nil)
  if valid_402656996 != nil:
    section.add "X-Amz-Credential", valid_402656996
  var valid_402656997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656999: Call_UpdateThreatIntelSet_402656986;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
                                                                                         ## 
  let valid = call_402656999.validator(path, query, header, formData, body, _)
  let scheme = call_402656999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656999.makeUrl(scheme.get, call_402656999.host, call_402656999.base,
                                   call_402656999.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656999, uri, valid, _)

proc call*(call_402657000: Call_UpdateThreatIntelSet_402656986;
           threatIntelSetId: string; body: JsonNode; detectorId: string): Recallable =
  ## updateThreatIntelSet
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ##   threatIntelSetId: string (required)
                                                               ##                   : The unique ID that specifies the ThreatIntelSet that you want to update.
  ##   
                                                                                                                                                              ## body: JObject (required)
  ##   
                                                                                                                                                                                         ## detectorId: string (required)
                                                                                                                                                                                         ##             
                                                                                                                                                                                         ## : 
                                                                                                                                                                                         ## The 
                                                                                                                                                                                         ## detectorID 
                                                                                                                                                                                         ## that 
                                                                                                                                                                                         ## specifies 
                                                                                                                                                                                         ## the 
                                                                                                                                                                                         ## GuardDuty 
                                                                                                                                                                                         ## service 
                                                                                                                                                                                         ## whose 
                                                                                                                                                                                         ## ThreatIntelSet 
                                                                                                                                                                                         ## you 
                                                                                                                                                                                         ## want 
                                                                                                                                                                                         ## to 
                                                                                                                                                                                         ## update.
  var path_402657001 = newJObject()
  var body_402657002 = newJObject()
  add(path_402657001, "threatIntelSetId", newJString(threatIntelSetId))
  if body != nil:
    body_402657002 = body
  add(path_402657001, "detectorId", newJString(detectorId))
  result = call_402657000.call(path_402657001, nil, nil, nil, body_402657002)

var updateThreatIntelSet* = Call_UpdateThreatIntelSet_402656986(
    name: "updateThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_UpdateThreatIntelSet_402656987, base: "/",
    makeUrl: url_UpdateThreatIntelSet_402656988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThreatIntelSet_402656971 = ref object of OpenApiRestCall_402656044
proc url_GetThreatIntelSet_402656973(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  assert "threatIntelSetId" in path,
         "`threatIntelSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/threatintelset/"),
                 (kind: VariableSegment, value: "threatIntelSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetThreatIntelSet_402656972(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   threatIntelSetId: JString (required)
                                 ##                   : The unique ID of the threatIntelSet you want to get.
  ##   
                                                                                                            ## detectorId: JString (required)
                                                                                                            ##             
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## unique 
                                                                                                            ## ID 
                                                                                                            ## of 
                                                                                                            ## the 
                                                                                                            ## detector 
                                                                                                            ## the 
                                                                                                            ## threatIntelSet 
                                                                                                            ## is 
                                                                                                            ## associated 
                                                                                                            ## with.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `threatIntelSetId` field"
  var valid_402656974 = path.getOrDefault("threatIntelSetId")
  valid_402656974 = validateParameter(valid_402656974, JString, required = true,
                                      default = nil)
  if valid_402656974 != nil:
    section.add "threatIntelSetId", valid_402656974
  var valid_402656975 = path.getOrDefault("detectorId")
  valid_402656975 = validateParameter(valid_402656975, JString, required = true,
                                      default = nil)
  if valid_402656975 != nil:
    section.add "detectorId", valid_402656975
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656976 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Security-Token", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Signature")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Signature", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-Algorithm", valid_402656979
  var valid_402656980 = header.getOrDefault("X-Amz-Date")
  valid_402656980 = validateParameter(valid_402656980, JString,
                                      required = false, default = nil)
  if valid_402656980 != nil:
    section.add "X-Amz-Date", valid_402656980
  var valid_402656981 = header.getOrDefault("X-Amz-Credential")
  valid_402656981 = validateParameter(valid_402656981, JString,
                                      required = false, default = nil)
  if valid_402656981 != nil:
    section.add "X-Amz-Credential", valid_402656981
  var valid_402656982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656982 = validateParameter(valid_402656982, JString,
                                      required = false, default = nil)
  if valid_402656982 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656983: Call_GetThreatIntelSet_402656971;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
                                                                                         ## 
  let valid = call_402656983.validator(path, query, header, formData, body, _)
  let scheme = call_402656983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656983.makeUrl(scheme.get, call_402656983.host, call_402656983.base,
                                   call_402656983.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656983, uri, valid, _)

proc call*(call_402656984: Call_GetThreatIntelSet_402656971;
           threatIntelSetId: string; detectorId: string): Recallable =
  ## getThreatIntelSet
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ##   
                                                                             ## threatIntelSetId: string (required)
                                                                             ##                   
                                                                             ## : 
                                                                             ## The 
                                                                             ## unique 
                                                                             ## ID 
                                                                             ## of 
                                                                             ## the 
                                                                             ## threatIntelSet 
                                                                             ## you 
                                                                             ## want 
                                                                             ## to 
                                                                             ## get.
  ##   
                                                                                    ## detectorId: string (required)
                                                                                    ##             
                                                                                    ## : 
                                                                                    ## The 
                                                                                    ## unique 
                                                                                    ## ID 
                                                                                    ## of 
                                                                                    ## the 
                                                                                    ## detector 
                                                                                    ## the 
                                                                                    ## threatIntelSet 
                                                                                    ## is 
                                                                                    ## associated 
                                                                                    ## with.
  var path_402656985 = newJObject()
  add(path_402656985, "threatIntelSetId", newJString(threatIntelSetId))
  add(path_402656985, "detectorId", newJString(detectorId))
  result = call_402656984.call(path_402656985, nil, nil, nil, nil)

var getThreatIntelSet* = Call_GetThreatIntelSet_402656971(
    name: "getThreatIntelSet", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_GetThreatIntelSet_402656972, base: "/",
    makeUrl: url_GetThreatIntelSet_402656973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteThreatIntelSet_402657003 = ref object of OpenApiRestCall_402656044
proc url_DeleteThreatIntelSet_402657005(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  assert "threatIntelSetId" in path,
         "`threatIntelSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/threatintelset/"),
                 (kind: VariableSegment, value: "threatIntelSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteThreatIntelSet_402657004(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   threatIntelSetId: JString (required)
                                 ##                   : The unique ID of the threatIntelSet you want to delete.
  ##   
                                                                                                               ## detectorId: JString (required)
                                                                                                               ##             
                                                                                                               ## : 
                                                                                                               ## The 
                                                                                                               ## unique 
                                                                                                               ## ID 
                                                                                                               ## of 
                                                                                                               ## the 
                                                                                                               ## detector 
                                                                                                               ## the 
                                                                                                               ## threatIntelSet 
                                                                                                               ## is 
                                                                                                               ## associated 
                                                                                                               ## with.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `threatIntelSetId` field"
  var valid_402657006 = path.getOrDefault("threatIntelSetId")
  valid_402657006 = validateParameter(valid_402657006, JString, required = true,
                                      default = nil)
  if valid_402657006 != nil:
    section.add "threatIntelSetId", valid_402657006
  var valid_402657007 = path.getOrDefault("detectorId")
  valid_402657007 = validateParameter(valid_402657007, JString, required = true,
                                      default = nil)
  if valid_402657007 != nil:
    section.add "detectorId", valid_402657007
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657008 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657008 = validateParameter(valid_402657008, JString,
                                      required = false, default = nil)
  if valid_402657008 != nil:
    section.add "X-Amz-Security-Token", valid_402657008
  var valid_402657009 = header.getOrDefault("X-Amz-Signature")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-Signature", valid_402657009
  var valid_402657010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657010
  var valid_402657011 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "X-Amz-Algorithm", valid_402657011
  var valid_402657012 = header.getOrDefault("X-Amz-Date")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-Date", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Credential")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Credential", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657015: Call_DeleteThreatIntelSet_402657003;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
                                                                                         ## 
  let valid = call_402657015.validator(path, query, header, formData, body, _)
  let scheme = call_402657015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657015.makeUrl(scheme.get, call_402657015.host, call_402657015.base,
                                   call_402657015.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657015, uri, valid, _)

proc call*(call_402657016: Call_DeleteThreatIntelSet_402657003;
           threatIntelSetId: string; detectorId: string): Recallable =
  ## deleteThreatIntelSet
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ##   threatIntelSetId: string (required)
                                                               ##                   : The unique ID of the threatIntelSet you want to delete.
  ##   
                                                                                                                                             ## detectorId: string (required)
                                                                                                                                             ##             
                                                                                                                                             ## : 
                                                                                                                                             ## The 
                                                                                                                                             ## unique 
                                                                                                                                             ## ID 
                                                                                                                                             ## of 
                                                                                                                                             ## the 
                                                                                                                                             ## detector 
                                                                                                                                             ## the 
                                                                                                                                             ## threatIntelSet 
                                                                                                                                             ## is 
                                                                                                                                             ## associated 
                                                                                                                                             ## with.
  var path_402657017 = newJObject()
  add(path_402657017, "threatIntelSetId", newJString(threatIntelSetId))
  add(path_402657017, "detectorId", newJString(detectorId))
  result = call_402657016.call(path_402657017, nil, nil, nil, nil)

var deleteThreatIntelSet* = Call_DeleteThreatIntelSet_402657003(
    name: "deleteThreatIntelSet", meth: HttpMethod.HttpDelete,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_DeleteThreatIntelSet_402657004, base: "/",
    makeUrl: url_DeleteThreatIntelSet_402657005,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_402657018 = ref object of OpenApiRestCall_402656044
proc url_DisassociateFromMasterAccount_402657020(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/master/disassociate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateFromMasterAccount_402657019(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Disassociates the current GuardDuty member account from its master account.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector of the GuardDuty member account.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402657021 = path.getOrDefault("detectorId")
  valid_402657021 = validateParameter(valid_402657021, JString, required = true,
                                      default = nil)
  if valid_402657021 != nil:
    section.add "detectorId", valid_402657021
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657022 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657022 = validateParameter(valid_402657022, JString,
                                      required = false, default = nil)
  if valid_402657022 != nil:
    section.add "X-Amz-Security-Token", valid_402657022
  var valid_402657023 = header.getOrDefault("X-Amz-Signature")
  valid_402657023 = validateParameter(valid_402657023, JString,
                                      required = false, default = nil)
  if valid_402657023 != nil:
    section.add "X-Amz-Signature", valid_402657023
  var valid_402657024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657024 = validateParameter(valid_402657024, JString,
                                      required = false, default = nil)
  if valid_402657024 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657024
  var valid_402657025 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657025 = validateParameter(valid_402657025, JString,
                                      required = false, default = nil)
  if valid_402657025 != nil:
    section.add "X-Amz-Algorithm", valid_402657025
  var valid_402657026 = header.getOrDefault("X-Amz-Date")
  valid_402657026 = validateParameter(valid_402657026, JString,
                                      required = false, default = nil)
  if valid_402657026 != nil:
    section.add "X-Amz-Date", valid_402657026
  var valid_402657027 = header.getOrDefault("X-Amz-Credential")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "X-Amz-Credential", valid_402657027
  var valid_402657028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657029: Call_DisassociateFromMasterAccount_402657018;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates the current GuardDuty member account from its master account.
                                                                                         ## 
  let valid = call_402657029.validator(path, query, header, formData, body, _)
  let scheme = call_402657029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657029.makeUrl(scheme.get, call_402657029.host, call_402657029.base,
                                   call_402657029.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657029, uri, valid, _)

proc call*(call_402657030: Call_DisassociateFromMasterAccount_402657018;
           detectorId: string): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current GuardDuty member account from its master account.
  ##   
                                                                                ## detectorId: string (required)
                                                                                ##             
                                                                                ## : 
                                                                                ## The 
                                                                                ## unique 
                                                                                ## ID 
                                                                                ## of 
                                                                                ## the 
                                                                                ## detector 
                                                                                ## of 
                                                                                ## the 
                                                                                ## GuardDuty 
                                                                                ## member 
                                                                                ## account.
  var path_402657031 = newJObject()
  add(path_402657031, "detectorId", newJString(detectorId))
  result = call_402657030.call(path_402657031, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_402657018(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_402657019, base: "/",
    makeUrl: url_DisassociateFromMasterAccount_402657020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_402657032 = ref object of OpenApiRestCall_402656044
proc url_DisassociateMembers_402657034(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/member/disassociate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateMembers_402657033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector of the GuardDuty account whose members you want to disassociate from master.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402657035 = path.getOrDefault("detectorId")
  valid_402657035 = validateParameter(valid_402657035, JString, required = true,
                                      default = nil)
  if valid_402657035 != nil:
    section.add "detectorId", valid_402657035
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657036 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657036 = validateParameter(valid_402657036, JString,
                                      required = false, default = nil)
  if valid_402657036 != nil:
    section.add "X-Amz-Security-Token", valid_402657036
  var valid_402657037 = header.getOrDefault("X-Amz-Signature")
  valid_402657037 = validateParameter(valid_402657037, JString,
                                      required = false, default = nil)
  if valid_402657037 != nil:
    section.add "X-Amz-Signature", valid_402657037
  var valid_402657038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657038 = validateParameter(valid_402657038, JString,
                                      required = false, default = nil)
  if valid_402657038 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657038
  var valid_402657039 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657039 = validateParameter(valid_402657039, JString,
                                      required = false, default = nil)
  if valid_402657039 != nil:
    section.add "X-Amz-Algorithm", valid_402657039
  var valid_402657040 = header.getOrDefault("X-Amz-Date")
  valid_402657040 = validateParameter(valid_402657040, JString,
                                      required = false, default = nil)
  if valid_402657040 != nil:
    section.add "X-Amz-Date", valid_402657040
  var valid_402657041 = header.getOrDefault("X-Amz-Credential")
  valid_402657041 = validateParameter(valid_402657041, JString,
                                      required = false, default = nil)
  if valid_402657041 != nil:
    section.add "X-Amz-Credential", valid_402657041
  var valid_402657042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657042 = validateParameter(valid_402657042, JString,
                                      required = false, default = nil)
  if valid_402657042 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657044: Call_DisassociateMembers_402657032;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
                                                                                         ## 
  let valid = call_402657044.validator(path, query, header, formData, body, _)
  let scheme = call_402657044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657044.makeUrl(scheme.get, call_402657044.host, call_402657044.base,
                                   call_402657044.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657044, uri, valid, _)

proc call*(call_402657045: Call_DisassociateMembers_402657032; body: JsonNode;
           detectorId: string): Recallable =
  ## disassociateMembers
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   
                                                                                                                    ## body: JObject (required)
  ##   
                                                                                                                                               ## detectorId: string (required)
                                                                                                                                               ##             
                                                                                                                                               ## : 
                                                                                                                                               ## The 
                                                                                                                                               ## unique 
                                                                                                                                               ## ID 
                                                                                                                                               ## of 
                                                                                                                                               ## the 
                                                                                                                                               ## detector 
                                                                                                                                               ## of 
                                                                                                                                               ## the 
                                                                                                                                               ## GuardDuty 
                                                                                                                                               ## account 
                                                                                                                                               ## whose 
                                                                                                                                               ## members 
                                                                                                                                               ## you 
                                                                                                                                               ## want 
                                                                                                                                               ## to 
                                                                                                                                               ## disassociate 
                                                                                                                                               ## from 
                                                                                                                                               ## master.
  var path_402657046 = newJObject()
  var body_402657047 = newJObject()
  if body != nil:
    body_402657047 = body
  add(path_402657046, "detectorId", newJString(detectorId))
  result = call_402657045.call(path_402657046, nil, nil, nil, body_402657047)

var disassociateMembers* = Call_DisassociateMembers_402657032(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/disassociate",
    validator: validate_DisassociateMembers_402657033, base: "/",
    makeUrl: url_DisassociateMembers_402657034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_402657048 = ref object of OpenApiRestCall_402656044
proc url_GetFindings_402657050(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/findings/get")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFindings_402657049(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes Amazon GuardDuty findings specified by finding IDs.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to retrieve.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402657051 = path.getOrDefault("detectorId")
  valid_402657051 = validateParameter(valid_402657051, JString, required = true,
                                      default = nil)
  if valid_402657051 != nil:
    section.add "detectorId", valid_402657051
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657052 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657052 = validateParameter(valid_402657052, JString,
                                      required = false, default = nil)
  if valid_402657052 != nil:
    section.add "X-Amz-Security-Token", valid_402657052
  var valid_402657053 = header.getOrDefault("X-Amz-Signature")
  valid_402657053 = validateParameter(valid_402657053, JString,
                                      required = false, default = nil)
  if valid_402657053 != nil:
    section.add "X-Amz-Signature", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657054
  var valid_402657055 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657055 = validateParameter(valid_402657055, JString,
                                      required = false, default = nil)
  if valid_402657055 != nil:
    section.add "X-Amz-Algorithm", valid_402657055
  var valid_402657056 = header.getOrDefault("X-Amz-Date")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-Date", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-Credential")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-Credential", valid_402657057
  var valid_402657058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657060: Call_GetFindings_402657048; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes Amazon GuardDuty findings specified by finding IDs.
                                                                                         ## 
  let valid = call_402657060.validator(path, query, header, formData, body, _)
  let scheme = call_402657060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657060.makeUrl(scheme.get, call_402657060.host, call_402657060.base,
                                   call_402657060.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657060, uri, valid, _)

proc call*(call_402657061: Call_GetFindings_402657048; body: JsonNode;
           detectorId: string): Recallable =
  ## getFindings
  ## Describes Amazon GuardDuty findings specified by finding IDs.
  ##   body: JObject (required)
  ##   detectorId: string (required)
                               ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to retrieve.
  var path_402657062 = newJObject()
  var body_402657063 = newJObject()
  if body != nil:
    body_402657063 = body
  add(path_402657062, "detectorId", newJString(detectorId))
  result = call_402657061.call(path_402657062, nil, nil, nil, body_402657063)

var getFindings* = Call_GetFindings_402657048(name: "getFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/get",
    validator: validate_GetFindings_402657049, base: "/",
    makeUrl: url_GetFindings_402657050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindingsStatistics_402657064 = ref object of OpenApiRestCall_402656044
proc url_GetFindingsStatistics_402657066(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/findings/statistics")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFindingsStatistics_402657065(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The ID of the detector that specifies the GuardDuty service whose findings' statistics you want to retrieve.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402657067 = path.getOrDefault("detectorId")
  valid_402657067 = validateParameter(valid_402657067, JString, required = true,
                                      default = nil)
  if valid_402657067 != nil:
    section.add "detectorId", valid_402657067
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657068 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657068 = validateParameter(valid_402657068, JString,
                                      required = false, default = nil)
  if valid_402657068 != nil:
    section.add "X-Amz-Security-Token", valid_402657068
  var valid_402657069 = header.getOrDefault("X-Amz-Signature")
  valid_402657069 = validateParameter(valid_402657069, JString,
                                      required = false, default = nil)
  if valid_402657069 != nil:
    section.add "X-Amz-Signature", valid_402657069
  var valid_402657070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657070 = validateParameter(valid_402657070, JString,
                                      required = false, default = nil)
  if valid_402657070 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657070
  var valid_402657071 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657071 = validateParameter(valid_402657071, JString,
                                      required = false, default = nil)
  if valid_402657071 != nil:
    section.add "X-Amz-Algorithm", valid_402657071
  var valid_402657072 = header.getOrDefault("X-Amz-Date")
  valid_402657072 = validateParameter(valid_402657072, JString,
                                      required = false, default = nil)
  if valid_402657072 != nil:
    section.add "X-Amz-Date", valid_402657072
  var valid_402657073 = header.getOrDefault("X-Amz-Credential")
  valid_402657073 = validateParameter(valid_402657073, JString,
                                      required = false, default = nil)
  if valid_402657073 != nil:
    section.add "X-Amz-Credential", valid_402657073
  var valid_402657074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657074 = validateParameter(valid_402657074, JString,
                                      required = false, default = nil)
  if valid_402657074 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657076: Call_GetFindingsStatistics_402657064;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
                                                                                         ## 
  let valid = call_402657076.validator(path, query, header, formData, body, _)
  let scheme = call_402657076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657076.makeUrl(scheme.get, call_402657076.host, call_402657076.base,
                                   call_402657076.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657076, uri, valid, _)

proc call*(call_402657077: Call_GetFindingsStatistics_402657064; body: JsonNode;
           detectorId: string): Recallable =
  ## getFindingsStatistics
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
  ##   
                                                                               ## body: JObject (required)
  ##   
                                                                                                          ## detectorId: string (required)
                                                                                                          ##             
                                                                                                          ## : 
                                                                                                          ## The 
                                                                                                          ## ID 
                                                                                                          ## of 
                                                                                                          ## the 
                                                                                                          ## detector 
                                                                                                          ## that 
                                                                                                          ## specifies 
                                                                                                          ## the 
                                                                                                          ## GuardDuty 
                                                                                                          ## service 
                                                                                                          ## whose 
                                                                                                          ## findings' 
                                                                                                          ## statistics 
                                                                                                          ## you 
                                                                                                          ## want 
                                                                                                          ## to 
                                                                                                          ## retrieve.
  var path_402657078 = newJObject()
  var body_402657079 = newJObject()
  if body != nil:
    body_402657079 = body
  add(path_402657078, "detectorId", newJString(detectorId))
  result = call_402657077.call(path_402657078, nil, nil, nil, body_402657079)

var getFindingsStatistics* = Call_GetFindingsStatistics_402657064(
    name: "getFindingsStatistics", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/statistics",
    validator: validate_GetFindingsStatistics_402657065, base: "/",
    makeUrl: url_GetFindingsStatistics_402657066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_402657080 = ref object of OpenApiRestCall_402656044
proc url_GetInvitationsCount_402657082(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInvitationsCount_402657081(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657083 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657083 = validateParameter(valid_402657083, JString,
                                      required = false, default = nil)
  if valid_402657083 != nil:
    section.add "X-Amz-Security-Token", valid_402657083
  var valid_402657084 = header.getOrDefault("X-Amz-Signature")
  valid_402657084 = validateParameter(valid_402657084, JString,
                                      required = false, default = nil)
  if valid_402657084 != nil:
    section.add "X-Amz-Signature", valid_402657084
  var valid_402657085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657085 = validateParameter(valid_402657085, JString,
                                      required = false, default = nil)
  if valid_402657085 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657085
  var valid_402657086 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657086 = validateParameter(valid_402657086, JString,
                                      required = false, default = nil)
  if valid_402657086 != nil:
    section.add "X-Amz-Algorithm", valid_402657086
  var valid_402657087 = header.getOrDefault("X-Amz-Date")
  valid_402657087 = validateParameter(valid_402657087, JString,
                                      required = false, default = nil)
  if valid_402657087 != nil:
    section.add "X-Amz-Date", valid_402657087
  var valid_402657088 = header.getOrDefault("X-Amz-Credential")
  valid_402657088 = validateParameter(valid_402657088, JString,
                                      required = false, default = nil)
  if valid_402657088 != nil:
    section.add "X-Amz-Credential", valid_402657088
  var valid_402657089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657089 = validateParameter(valid_402657089, JString,
                                      required = false, default = nil)
  if valid_402657089 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657090: Call_GetInvitationsCount_402657080;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
                                                                                         ## 
  let valid = call_402657090.validator(path, query, header, formData, body, _)
  let scheme = call_402657090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657090.makeUrl(scheme.get, call_402657090.host, call_402657090.base,
                                   call_402657090.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657090, uri, valid, _)

proc call*(call_402657091: Call_GetInvitationsCount_402657080): Recallable =
  ## getInvitationsCount
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
  result = call_402657091.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_402657080(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/invitation/count",
    validator: validate_GetInvitationsCount_402657081, base: "/",
    makeUrl: url_GetInvitationsCount_402657082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_402657092 = ref object of OpenApiRestCall_402656044
proc url_GetMembers_402657094(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/member/get")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMembers_402657093(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector of the GuardDuty account whose members you want to retrieve.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402657095 = path.getOrDefault("detectorId")
  valid_402657095 = validateParameter(valid_402657095, JString, required = true,
                                      default = nil)
  if valid_402657095 != nil:
    section.add "detectorId", valid_402657095
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657096 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-Security-Token", valid_402657096
  var valid_402657097 = header.getOrDefault("X-Amz-Signature")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-Signature", valid_402657097
  var valid_402657098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657098 = validateParameter(valid_402657098, JString,
                                      required = false, default = nil)
  if valid_402657098 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-Algorithm", valid_402657099
  var valid_402657100 = header.getOrDefault("X-Amz-Date")
  valid_402657100 = validateParameter(valid_402657100, JString,
                                      required = false, default = nil)
  if valid_402657100 != nil:
    section.add "X-Amz-Date", valid_402657100
  var valid_402657101 = header.getOrDefault("X-Amz-Credential")
  valid_402657101 = validateParameter(valid_402657101, JString,
                                      required = false, default = nil)
  if valid_402657101 != nil:
    section.add "X-Amz-Credential", valid_402657101
  var valid_402657102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657102 = validateParameter(valid_402657102, JString,
                                      required = false, default = nil)
  if valid_402657102 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657104: Call_GetMembers_402657092; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
                                                                                         ## 
  let valid = call_402657104.validator(path, query, header, formData, body, _)
  let scheme = call_402657104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657104.makeUrl(scheme.get, call_402657104.host, call_402657104.base,
                                   call_402657104.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657104, uri, valid, _)

proc call*(call_402657105: Call_GetMembers_402657092; body: JsonNode;
           detectorId: string): Recallable =
  ## getMembers
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   
                                                                                                                ## body: JObject (required)
  ##   
                                                                                                                                           ## detectorId: string (required)
                                                                                                                                           ##             
                                                                                                                                           ## : 
                                                                                                                                           ## The 
                                                                                                                                           ## unique 
                                                                                                                                           ## ID 
                                                                                                                                           ## of 
                                                                                                                                           ## the 
                                                                                                                                           ## detector 
                                                                                                                                           ## of 
                                                                                                                                           ## the 
                                                                                                                                           ## GuardDuty 
                                                                                                                                           ## account 
                                                                                                                                           ## whose 
                                                                                                                                           ## members 
                                                                                                                                           ## you 
                                                                                                                                           ## want 
                                                                                                                                           ## to 
                                                                                                                                           ## retrieve.
  var path_402657106 = newJObject()
  var body_402657107 = newJObject()
  if body != nil:
    body_402657107 = body
  add(path_402657106, "detectorId", newJString(detectorId))
  result = call_402657105.call(path_402657106, nil, nil, nil, body_402657107)

var getMembers* = Call_GetMembers_402657092(name: "getMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/get", validator: validate_GetMembers_402657093,
    base: "/", makeUrl: url_GetMembers_402657094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_402657108 = ref object of OpenApiRestCall_402656044
proc url_InviteMembers_402657110(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/member/invite")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InviteMembers_402657109(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector of the GuardDuty account with which you want to invite members.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402657111 = path.getOrDefault("detectorId")
  valid_402657111 = validateParameter(valid_402657111, JString, required = true,
                                      default = nil)
  if valid_402657111 != nil:
    section.add "detectorId", valid_402657111
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657112 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657112 = validateParameter(valid_402657112, JString,
                                      required = false, default = nil)
  if valid_402657112 != nil:
    section.add "X-Amz-Security-Token", valid_402657112
  var valid_402657113 = header.getOrDefault("X-Amz-Signature")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "X-Amz-Signature", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657114
  var valid_402657115 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657115 = validateParameter(valid_402657115, JString,
                                      required = false, default = nil)
  if valid_402657115 != nil:
    section.add "X-Amz-Algorithm", valid_402657115
  var valid_402657116 = header.getOrDefault("X-Amz-Date")
  valid_402657116 = validateParameter(valid_402657116, JString,
                                      required = false, default = nil)
  if valid_402657116 != nil:
    section.add "X-Amz-Date", valid_402657116
  var valid_402657117 = header.getOrDefault("X-Amz-Credential")
  valid_402657117 = validateParameter(valid_402657117, JString,
                                      required = false, default = nil)
  if valid_402657117 != nil:
    section.add "X-Amz-Credential", valid_402657117
  var valid_402657118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657118 = validateParameter(valid_402657118, JString,
                                      required = false, default = nil)
  if valid_402657118 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657120: Call_InviteMembers_402657108; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
                                                                                         ## 
  let valid = call_402657120.validator(path, query, header, formData, body, _)
  let scheme = call_402657120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657120.makeUrl(scheme.get, call_402657120.host, call_402657120.base,
                                   call_402657120.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657120, uri, valid, _)

proc call*(call_402657121: Call_InviteMembers_402657108; body: JsonNode;
           detectorId: string): Recallable =
  ## inviteMembers
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
  ##   
                                                                                                                                                                                                                                                   ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                              ## detectorId: string (required)
                                                                                                                                                                                                                                                                              ##             
                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                              ## unique 
                                                                                                                                                                                                                                                                              ## ID 
                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                              ## detector 
                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                              ## GuardDuty 
                                                                                                                                                                                                                                                                              ## account 
                                                                                                                                                                                                                                                                              ## with 
                                                                                                                                                                                                                                                                              ## which 
                                                                                                                                                                                                                                                                              ## you 
                                                                                                                                                                                                                                                                              ## want 
                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                              ## invite 
                                                                                                                                                                                                                                                                              ## members.
  var path_402657122 = newJObject()
  var body_402657123 = newJObject()
  if body != nil:
    body_402657123 = body
  add(path_402657122, "detectorId", newJString(detectorId))
  result = call_402657121.call(path_402657122, nil, nil, nil, body_402657123)

var inviteMembers* = Call_InviteMembers_402657108(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/invite",
    validator: validate_InviteMembers_402657109, base: "/",
    makeUrl: url_InviteMembers_402657110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_402657124 = ref object of OpenApiRestCall_402656044
proc url_ListFindings_402657126(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/findings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFindings_402657125(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists Amazon GuardDuty findings for the specified detector ID.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to list.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402657127 = path.getOrDefault("detectorId")
  valid_402657127 = validateParameter(valid_402657127, JString, required = true,
                                      default = nil)
  if valid_402657127 != nil:
    section.add "detectorId", valid_402657127
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657128 = query.getOrDefault("MaxResults")
  valid_402657128 = validateParameter(valid_402657128, JString,
                                      required = false, default = nil)
  if valid_402657128 != nil:
    section.add "MaxResults", valid_402657128
  var valid_402657129 = query.getOrDefault("NextToken")
  valid_402657129 = validateParameter(valid_402657129, JString,
                                      required = false, default = nil)
  if valid_402657129 != nil:
    section.add "NextToken", valid_402657129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657130 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657130 = validateParameter(valid_402657130, JString,
                                      required = false, default = nil)
  if valid_402657130 != nil:
    section.add "X-Amz-Security-Token", valid_402657130
  var valid_402657131 = header.getOrDefault("X-Amz-Signature")
  valid_402657131 = validateParameter(valid_402657131, JString,
                                      required = false, default = nil)
  if valid_402657131 != nil:
    section.add "X-Amz-Signature", valid_402657131
  var valid_402657132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657132 = validateParameter(valid_402657132, JString,
                                      required = false, default = nil)
  if valid_402657132 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657132
  var valid_402657133 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657133 = validateParameter(valid_402657133, JString,
                                      required = false, default = nil)
  if valid_402657133 != nil:
    section.add "X-Amz-Algorithm", valid_402657133
  var valid_402657134 = header.getOrDefault("X-Amz-Date")
  valid_402657134 = validateParameter(valid_402657134, JString,
                                      required = false, default = nil)
  if valid_402657134 != nil:
    section.add "X-Amz-Date", valid_402657134
  var valid_402657135 = header.getOrDefault("X-Amz-Credential")
  valid_402657135 = validateParameter(valid_402657135, JString,
                                      required = false, default = nil)
  if valid_402657135 != nil:
    section.add "X-Amz-Credential", valid_402657135
  var valid_402657136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657136 = validateParameter(valid_402657136, JString,
                                      required = false, default = nil)
  if valid_402657136 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657138: Call_ListFindings_402657124; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists Amazon GuardDuty findings for the specified detector ID.
                                                                                         ## 
  let valid = call_402657138.validator(path, query, header, formData, body, _)
  let scheme = call_402657138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657138.makeUrl(scheme.get, call_402657138.host, call_402657138.base,
                                   call_402657138.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657138, uri, valid, _)

proc call*(call_402657139: Call_ListFindings_402657124; body: JsonNode;
           detectorId: string; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFindings
  ## Lists Amazon GuardDuty findings for the specified detector ID.
  ##   MaxResults: string
                                                                   ##             : Pagination limit
  ##   
                                                                                                    ## body: JObject (required)
  ##   
                                                                                                                               ## detectorId: string (required)
                                                                                                                               ##             
                                                                                                                               ## : 
                                                                                                                               ## The 
                                                                                                                               ## ID 
                                                                                                                               ## of 
                                                                                                                               ## the 
                                                                                                                               ## detector 
                                                                                                                               ## that 
                                                                                                                               ## specifies 
                                                                                                                               ## the 
                                                                                                                               ## GuardDuty 
                                                                                                                               ## service 
                                                                                                                               ## whose 
                                                                                                                               ## findings 
                                                                                                                               ## you 
                                                                                                                               ## want 
                                                                                                                               ## to 
                                                                                                                               ## list.
  ##   
                                                                                                                                       ## NextToken: string
                                                                                                                                       ##            
                                                                                                                                       ## : 
                                                                                                                                       ## Pagination 
                                                                                                                                       ## token
  var path_402657140 = newJObject()
  var query_402657141 = newJObject()
  var body_402657142 = newJObject()
  add(query_402657141, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657142 = body
  add(path_402657140, "detectorId", newJString(detectorId))
  add(query_402657141, "NextToken", newJString(NextToken))
  result = call_402657139.call(path_402657140, query_402657141, nil, nil, body_402657142)

var listFindings* = Call_ListFindings_402657124(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings", validator: validate_ListFindings_402657125,
    base: "/", makeUrl: url_ListFindings_402657126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_402657143 = ref object of OpenApiRestCall_402656044
proc url_ListInvitations_402657145(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInvitations_402657144(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all GuardDuty membership invitations that were sent to the current AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   
                                                                                                                                                                                                 ## nextToken: JString
                                                                                                                                                                                                 ##            
                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                 ## You 
                                                                                                                                                                                                 ## can 
                                                                                                                                                                                                 ## use 
                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                 ## when 
                                                                                                                                                                                                 ## paginating 
                                                                                                                                                                                                 ## results. 
                                                                                                                                                                                                 ## Set 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                 ## this 
                                                                                                                                                                                                 ## parameter 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## null 
                                                                                                                                                                                                 ## on 
                                                                                                                                                                                                 ## your 
                                                                                                                                                                                                 ## first 
                                                                                                                                                                                                 ## call 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## list 
                                                                                                                                                                                                 ## action. 
                                                                                                                                                                                                 ## For 
                                                                                                                                                                                                 ## subsequent 
                                                                                                                                                                                                 ## calls 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## action 
                                                                                                                                                                                                 ## fill 
                                                                                                                                                                                                 ## nextToken 
                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## request 
                                                                                                                                                                                                 ## with 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                 ## NextToken 
                                                                                                                                                                                                 ## from 
                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                 ## previous 
                                                                                                                                                                                                 ## response 
                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                 ## continue 
                                                                                                                                                                                                 ## listing 
                                                                                                                                                                                                 ## data.
  ##   
                                                                                                                                                                                                         ## MaxResults: JString
                                                                                                                                                                                                         ##             
                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                         ## limit
  ##   
                                                                                                                                                                                                                 ## NextToken: JString
                                                                                                                                                                                                                 ##            
                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                 ## token
  section = newJObject()
  var valid_402657146 = query.getOrDefault("maxResults")
  valid_402657146 = validateParameter(valid_402657146, JInt, required = false,
                                      default = nil)
  if valid_402657146 != nil:
    section.add "maxResults", valid_402657146
  var valid_402657147 = query.getOrDefault("nextToken")
  valid_402657147 = validateParameter(valid_402657147, JString,
                                      required = false, default = nil)
  if valid_402657147 != nil:
    section.add "nextToken", valid_402657147
  var valid_402657148 = query.getOrDefault("MaxResults")
  valid_402657148 = validateParameter(valid_402657148, JString,
                                      required = false, default = nil)
  if valid_402657148 != nil:
    section.add "MaxResults", valid_402657148
  var valid_402657149 = query.getOrDefault("NextToken")
  valid_402657149 = validateParameter(valid_402657149, JString,
                                      required = false, default = nil)
  if valid_402657149 != nil:
    section.add "NextToken", valid_402657149
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657150 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657150 = validateParameter(valid_402657150, JString,
                                      required = false, default = nil)
  if valid_402657150 != nil:
    section.add "X-Amz-Security-Token", valid_402657150
  var valid_402657151 = header.getOrDefault("X-Amz-Signature")
  valid_402657151 = validateParameter(valid_402657151, JString,
                                      required = false, default = nil)
  if valid_402657151 != nil:
    section.add "X-Amz-Signature", valid_402657151
  var valid_402657152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657152 = validateParameter(valid_402657152, JString,
                                      required = false, default = nil)
  if valid_402657152 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657152
  var valid_402657153 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657153 = validateParameter(valid_402657153, JString,
                                      required = false, default = nil)
  if valid_402657153 != nil:
    section.add "X-Amz-Algorithm", valid_402657153
  var valid_402657154 = header.getOrDefault("X-Amz-Date")
  valid_402657154 = validateParameter(valid_402657154, JString,
                                      required = false, default = nil)
  if valid_402657154 != nil:
    section.add "X-Amz-Date", valid_402657154
  var valid_402657155 = header.getOrDefault("X-Amz-Credential")
  valid_402657155 = validateParameter(valid_402657155, JString,
                                      required = false, default = nil)
  if valid_402657155 != nil:
    section.add "X-Amz-Credential", valid_402657155
  var valid_402657156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657156 = validateParameter(valid_402657156, JString,
                                      required = false, default = nil)
  if valid_402657156 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657157: Call_ListInvitations_402657143; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all GuardDuty membership invitations that were sent to the current AWS account.
                                                                                         ## 
  let valid = call_402657157.validator(path, query, header, formData, body, _)
  let scheme = call_402657157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657157.makeUrl(scheme.get, call_402657157.host, call_402657157.base,
                                   call_402657157.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657157, uri, valid, _)

proc call*(call_402657158: Call_ListInvitations_402657143; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listInvitations
  ## Lists all GuardDuty membership invitations that were sent to the current AWS account.
  ##   
                                                                                          ## maxResults: int
                                                                                          ##             
                                                                                          ## : 
                                                                                          ## You 
                                                                                          ## can 
                                                                                          ## use 
                                                                                          ## this 
                                                                                          ## parameter 
                                                                                          ## to 
                                                                                          ## indicate 
                                                                                          ## the 
                                                                                          ## maximum 
                                                                                          ## number 
                                                                                          ## of 
                                                                                          ## items 
                                                                                          ## you 
                                                                                          ## want 
                                                                                          ## in 
                                                                                          ## the 
                                                                                          ## response. 
                                                                                          ## The 
                                                                                          ## default 
                                                                                          ## value 
                                                                                          ## is 
                                                                                          ## 50. 
                                                                                          ## The 
                                                                                          ## maximum 
                                                                                          ## value 
                                                                                          ## is 
                                                                                          ## 50.
  ##   
                                                                                                ## nextToken: string
                                                                                                ##            
                                                                                                ## : 
                                                                                                ## You 
                                                                                                ## can 
                                                                                                ## use 
                                                                                                ## this 
                                                                                                ## parameter 
                                                                                                ## when 
                                                                                                ## paginating 
                                                                                                ## results. 
                                                                                                ## Set 
                                                                                                ## the 
                                                                                                ## value 
                                                                                                ## of 
                                                                                                ## this 
                                                                                                ## parameter 
                                                                                                ## to 
                                                                                                ## null 
                                                                                                ## on 
                                                                                                ## your 
                                                                                                ## first 
                                                                                                ## call 
                                                                                                ## to 
                                                                                                ## the 
                                                                                                ## list 
                                                                                                ## action. 
                                                                                                ## For 
                                                                                                ## subsequent 
                                                                                                ## calls 
                                                                                                ## to 
                                                                                                ## the 
                                                                                                ## action 
                                                                                                ## fill 
                                                                                                ## nextToken 
                                                                                                ## in 
                                                                                                ## the 
                                                                                                ## request 
                                                                                                ## with 
                                                                                                ## the 
                                                                                                ## value 
                                                                                                ## of 
                                                                                                ## NextToken 
                                                                                                ## from 
                                                                                                ## the 
                                                                                                ## previous 
                                                                                                ## response 
                                                                                                ## to 
                                                                                                ## continue 
                                                                                                ## listing 
                                                                                                ## data.
  ##   
                                                                                                        ## MaxResults: string
                                                                                                        ##             
                                                                                                        ## : 
                                                                                                        ## Pagination 
                                                                                                        ## limit
  ##   
                                                                                                                ## NextToken: string
                                                                                                                ##            
                                                                                                                ## : 
                                                                                                                ## Pagination 
                                                                                                                ## token
  var query_402657159 = newJObject()
  add(query_402657159, "maxResults", newJInt(maxResults))
  add(query_402657159, "nextToken", newJString(nextToken))
  add(query_402657159, "MaxResults", newJString(MaxResults))
  add(query_402657159, "NextToken", newJString(NextToken))
  result = call_402657158.call(nil, query_402657159, nil, nil, nil)

var listInvitations* = Call_ListInvitations_402657143(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/invitation", validator: validate_ListInvitations_402657144,
    base: "/", makeUrl: url_ListInvitations_402657145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657174 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402657176(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402657175(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds tags to a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) for the GuardDuty resource to apply a tag to.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402657177 = path.getOrDefault("resourceArn")
  valid_402657177 = validateParameter(valid_402657177, JString, required = true,
                                      default = nil)
  if valid_402657177 != nil:
    section.add "resourceArn", valid_402657177
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657178 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657178 = validateParameter(valid_402657178, JString,
                                      required = false, default = nil)
  if valid_402657178 != nil:
    section.add "X-Amz-Security-Token", valid_402657178
  var valid_402657179 = header.getOrDefault("X-Amz-Signature")
  valid_402657179 = validateParameter(valid_402657179, JString,
                                      required = false, default = nil)
  if valid_402657179 != nil:
    section.add "X-Amz-Signature", valid_402657179
  var valid_402657180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657180 = validateParameter(valid_402657180, JString,
                                      required = false, default = nil)
  if valid_402657180 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657180
  var valid_402657181 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657181 = validateParameter(valid_402657181, JString,
                                      required = false, default = nil)
  if valid_402657181 != nil:
    section.add "X-Amz-Algorithm", valid_402657181
  var valid_402657182 = header.getOrDefault("X-Amz-Date")
  valid_402657182 = validateParameter(valid_402657182, JString,
                                      required = false, default = nil)
  if valid_402657182 != nil:
    section.add "X-Amz-Date", valid_402657182
  var valid_402657183 = header.getOrDefault("X-Amz-Credential")
  valid_402657183 = validateParameter(valid_402657183, JString,
                                      required = false, default = nil)
  if valid_402657183 != nil:
    section.add "X-Amz-Credential", valid_402657183
  var valid_402657184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657184 = validateParameter(valid_402657184, JString,
                                      required = false, default = nil)
  if valid_402657184 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657186: Call_TagResource_402657174; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds tags to a resource.
                                                                                         ## 
  let valid = call_402657186.validator(path, query, header, formData, body, _)
  let scheme = call_402657186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657186.makeUrl(scheme.get, call_402657186.host, call_402657186.base,
                                   call_402657186.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657186, uri, valid, _)

proc call*(call_402657187: Call_TagResource_402657174; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Adds tags to a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
                               ##              : The Amazon Resource Name (ARN) for the GuardDuty resource to apply a tag to.
  var path_402657188 = newJObject()
  var body_402657189 = newJObject()
  if body != nil:
    body_402657189 = body
  add(path_402657188, "resourceArn", newJString(resourceArn))
  result = call_402657187.call(path_402657188, nil, nil, nil, body_402657189)

var tagResource* = Call_TagResource_402657174(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402657175,
    base: "/", makeUrl: url_TagResource_402657176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402657160 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402657162(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402657161(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) for the given GuardDuty resource 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402657163 = path.getOrDefault("resourceArn")
  valid_402657163 = validateParameter(valid_402657163, JString, required = true,
                                      default = nil)
  if valid_402657163 != nil:
    section.add "resourceArn", valid_402657163
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657164 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657164 = validateParameter(valid_402657164, JString,
                                      required = false, default = nil)
  if valid_402657164 != nil:
    section.add "X-Amz-Security-Token", valid_402657164
  var valid_402657165 = header.getOrDefault("X-Amz-Signature")
  valid_402657165 = validateParameter(valid_402657165, JString,
                                      required = false, default = nil)
  if valid_402657165 != nil:
    section.add "X-Amz-Signature", valid_402657165
  var valid_402657166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657166 = validateParameter(valid_402657166, JString,
                                      required = false, default = nil)
  if valid_402657166 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657166
  var valid_402657167 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657167 = validateParameter(valid_402657167, JString,
                                      required = false, default = nil)
  if valid_402657167 != nil:
    section.add "X-Amz-Algorithm", valid_402657167
  var valid_402657168 = header.getOrDefault("X-Amz-Date")
  valid_402657168 = validateParameter(valid_402657168, JString,
                                      required = false, default = nil)
  if valid_402657168 != nil:
    section.add "X-Amz-Date", valid_402657168
  var valid_402657169 = header.getOrDefault("X-Amz-Credential")
  valid_402657169 = validateParameter(valid_402657169, JString,
                                      required = false, default = nil)
  if valid_402657169 != nil:
    section.add "X-Amz-Credential", valid_402657169
  var valid_402657170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657170 = validateParameter(valid_402657170, JString,
                                      required = false, default = nil)
  if valid_402657170 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657171: Call_ListTagsForResource_402657160;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
                                                                                         ## 
  let valid = call_402657171.validator(path, query, header, formData, body, _)
  let scheme = call_402657171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657171.makeUrl(scheme.get, call_402657171.host, call_402657171.base,
                                   call_402657171.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657171, uri, valid, _)

proc call*(call_402657172: Call_ListTagsForResource_402657160;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
  ##   
                                                                                                                                                                                                                                                  ## resourceArn: string (required)
                                                                                                                                                                                                                                                  ##              
                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                  ## Amazon 
                                                                                                                                                                                                                                                  ## Resource 
                                                                                                                                                                                                                                                  ## Name 
                                                                                                                                                                                                                                                  ## (ARN) 
                                                                                                                                                                                                                                                  ## for 
                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                  ## given 
                                                                                                                                                                                                                                                  ## GuardDuty 
                                                                                                                                                                                                                                                  ## resource 
  var path_402657173 = newJObject()
  add(path_402657173, "resourceArn", newJString(resourceArn))
  result = call_402657172.call(path_402657173, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402657160(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402657161, base: "/",
    makeUrl: url_ListTagsForResource_402657162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringMembers_402657190 = ref object of OpenApiRestCall_402656044
proc url_StartMonitoringMembers_402657192(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/member/start")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartMonitoringMembers_402657191(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Turns on GuardDuty monitoring of the specified member accounts. Use this operation to restart monitoring of accounts that you stopped monitoring with the <code>StopMonitoringMembers</code> operation.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector of the GuardDuty master account associated with the member accounts to monitor.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402657193 = path.getOrDefault("detectorId")
  valid_402657193 = validateParameter(valid_402657193, JString, required = true,
                                      default = nil)
  if valid_402657193 != nil:
    section.add "detectorId", valid_402657193
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657194 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657194 = validateParameter(valid_402657194, JString,
                                      required = false, default = nil)
  if valid_402657194 != nil:
    section.add "X-Amz-Security-Token", valid_402657194
  var valid_402657195 = header.getOrDefault("X-Amz-Signature")
  valid_402657195 = validateParameter(valid_402657195, JString,
                                      required = false, default = nil)
  if valid_402657195 != nil:
    section.add "X-Amz-Signature", valid_402657195
  var valid_402657196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657196 = validateParameter(valid_402657196, JString,
                                      required = false, default = nil)
  if valid_402657196 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657196
  var valid_402657197 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657197 = validateParameter(valid_402657197, JString,
                                      required = false, default = nil)
  if valid_402657197 != nil:
    section.add "X-Amz-Algorithm", valid_402657197
  var valid_402657198 = header.getOrDefault("X-Amz-Date")
  valid_402657198 = validateParameter(valid_402657198, JString,
                                      required = false, default = nil)
  if valid_402657198 != nil:
    section.add "X-Amz-Date", valid_402657198
  var valid_402657199 = header.getOrDefault("X-Amz-Credential")
  valid_402657199 = validateParameter(valid_402657199, JString,
                                      required = false, default = nil)
  if valid_402657199 != nil:
    section.add "X-Amz-Credential", valid_402657199
  var valid_402657200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657200 = validateParameter(valid_402657200, JString,
                                      required = false, default = nil)
  if valid_402657200 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657202: Call_StartMonitoringMembers_402657190;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Turns on GuardDuty monitoring of the specified member accounts. Use this operation to restart monitoring of accounts that you stopped monitoring with the <code>StopMonitoringMembers</code> operation.
                                                                                         ## 
  let valid = call_402657202.validator(path, query, header, formData, body, _)
  let scheme = call_402657202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657202.makeUrl(scheme.get, call_402657202.host, call_402657202.base,
                                   call_402657202.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657202, uri, valid, _)

proc call*(call_402657203: Call_StartMonitoringMembers_402657190;
           body: JsonNode; detectorId: string): Recallable =
  ## startMonitoringMembers
  ## Turns on GuardDuty monitoring of the specified member accounts. Use this operation to restart monitoring of accounts that you stopped monitoring with the <code>StopMonitoringMembers</code> operation.
  ##   
                                                                                                                                                                                                            ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                       ## detectorId: string (required)
                                                                                                                                                                                                                                       ##             
                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                       ## unique 
                                                                                                                                                                                                                                       ## ID 
                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                       ## detector 
                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                       ## GuardDuty 
                                                                                                                                                                                                                                       ## master 
                                                                                                                                                                                                                                       ## account 
                                                                                                                                                                                                                                       ## associated 
                                                                                                                                                                                                                                       ## with 
                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                       ## member 
                                                                                                                                                                                                                                       ## accounts 
                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                       ## monitor.
  var path_402657204 = newJObject()
  var body_402657205 = newJObject()
  if body != nil:
    body_402657205 = body
  add(path_402657204, "detectorId", newJString(detectorId))
  result = call_402657203.call(path_402657204, nil, nil, nil, body_402657205)

var startMonitoringMembers* = Call_StartMonitoringMembers_402657190(
    name: "startMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/start",
    validator: validate_StartMonitoringMembers_402657191, base: "/",
    makeUrl: url_StartMonitoringMembers_402657192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringMembers_402657206 = ref object of OpenApiRestCall_402656044
proc url_StopMonitoringMembers_402657208(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/member/stop")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopMonitoringMembers_402657207(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops GuardDuty monitoring for the specified member accounnts. Use the <code>StartMonitoringMembers</code> to restart monitoring for those accounts.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The unique ID of the detector of the GuardDuty account that you want to stop from monitor members' findings.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402657209 = path.getOrDefault("detectorId")
  valid_402657209 = validateParameter(valid_402657209, JString, required = true,
                                      default = nil)
  if valid_402657209 != nil:
    section.add "detectorId", valid_402657209
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657210 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657210 = validateParameter(valid_402657210, JString,
                                      required = false, default = nil)
  if valid_402657210 != nil:
    section.add "X-Amz-Security-Token", valid_402657210
  var valid_402657211 = header.getOrDefault("X-Amz-Signature")
  valid_402657211 = validateParameter(valid_402657211, JString,
                                      required = false, default = nil)
  if valid_402657211 != nil:
    section.add "X-Amz-Signature", valid_402657211
  var valid_402657212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657212 = validateParameter(valid_402657212, JString,
                                      required = false, default = nil)
  if valid_402657212 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657212
  var valid_402657213 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657213 = validateParameter(valid_402657213, JString,
                                      required = false, default = nil)
  if valid_402657213 != nil:
    section.add "X-Amz-Algorithm", valid_402657213
  var valid_402657214 = header.getOrDefault("X-Amz-Date")
  valid_402657214 = validateParameter(valid_402657214, JString,
                                      required = false, default = nil)
  if valid_402657214 != nil:
    section.add "X-Amz-Date", valid_402657214
  var valid_402657215 = header.getOrDefault("X-Amz-Credential")
  valid_402657215 = validateParameter(valid_402657215, JString,
                                      required = false, default = nil)
  if valid_402657215 != nil:
    section.add "X-Amz-Credential", valid_402657215
  var valid_402657216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657216 = validateParameter(valid_402657216, JString,
                                      required = false, default = nil)
  if valid_402657216 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657218: Call_StopMonitoringMembers_402657206;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops GuardDuty monitoring for the specified member accounnts. Use the <code>StartMonitoringMembers</code> to restart monitoring for those accounts.
                                                                                         ## 
  let valid = call_402657218.validator(path, query, header, formData, body, _)
  let scheme = call_402657218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657218.makeUrl(scheme.get, call_402657218.host, call_402657218.base,
                                   call_402657218.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657218, uri, valid, _)

proc call*(call_402657219: Call_StopMonitoringMembers_402657206; body: JsonNode;
           detectorId: string): Recallable =
  ## stopMonitoringMembers
  ## Stops GuardDuty monitoring for the specified member accounnts. Use the <code>StartMonitoringMembers</code> to restart monitoring for those accounts.
  ##   
                                                                                                                                                         ## body: JObject (required)
  ##   
                                                                                                                                                                                    ## detectorId: string (required)
                                                                                                                                                                                    ##             
                                                                                                                                                                                    ## : 
                                                                                                                                                                                    ## The 
                                                                                                                                                                                    ## unique 
                                                                                                                                                                                    ## ID 
                                                                                                                                                                                    ## of 
                                                                                                                                                                                    ## the 
                                                                                                                                                                                    ## detector 
                                                                                                                                                                                    ## of 
                                                                                                                                                                                    ## the 
                                                                                                                                                                                    ## GuardDuty 
                                                                                                                                                                                    ## account 
                                                                                                                                                                                    ## that 
                                                                                                                                                                                    ## you 
                                                                                                                                                                                    ## want 
                                                                                                                                                                                    ## to 
                                                                                                                                                                                    ## stop 
                                                                                                                                                                                    ## from 
                                                                                                                                                                                    ## monitor 
                                                                                                                                                                                    ## members' 
                                                                                                                                                                                    ## findings.
  var path_402657220 = newJObject()
  var body_402657221 = newJObject()
  if body != nil:
    body_402657221 = body
  add(path_402657220, "detectorId", newJString(detectorId))
  result = call_402657219.call(path_402657220, nil, nil, nil, body_402657221)

var stopMonitoringMembers* = Call_StopMonitoringMembers_402657206(
    name: "stopMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/stop",
    validator: validate_StopMonitoringMembers_402657207, base: "/",
    makeUrl: url_StopMonitoringMembers_402657208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnarchiveFindings_402657222 = ref object of OpenApiRestCall_402656044
proc url_UnarchiveFindings_402657224(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/findings/unarchive")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UnarchiveFindings_402657223(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Unarchives GuardDuty findings specified by the <code>findingIds</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The ID of the detector associated with the findings to unarchive.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402657225 = path.getOrDefault("detectorId")
  valid_402657225 = validateParameter(valid_402657225, JString, required = true,
                                      default = nil)
  if valid_402657225 != nil:
    section.add "detectorId", valid_402657225
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657226 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657226 = validateParameter(valid_402657226, JString,
                                      required = false, default = nil)
  if valid_402657226 != nil:
    section.add "X-Amz-Security-Token", valid_402657226
  var valid_402657227 = header.getOrDefault("X-Amz-Signature")
  valid_402657227 = validateParameter(valid_402657227, JString,
                                      required = false, default = nil)
  if valid_402657227 != nil:
    section.add "X-Amz-Signature", valid_402657227
  var valid_402657228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657228 = validateParameter(valid_402657228, JString,
                                      required = false, default = nil)
  if valid_402657228 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657228
  var valid_402657229 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657229 = validateParameter(valid_402657229, JString,
                                      required = false, default = nil)
  if valid_402657229 != nil:
    section.add "X-Amz-Algorithm", valid_402657229
  var valid_402657230 = header.getOrDefault("X-Amz-Date")
  valid_402657230 = validateParameter(valid_402657230, JString,
                                      required = false, default = nil)
  if valid_402657230 != nil:
    section.add "X-Amz-Date", valid_402657230
  var valid_402657231 = header.getOrDefault("X-Amz-Credential")
  valid_402657231 = validateParameter(valid_402657231, JString,
                                      required = false, default = nil)
  if valid_402657231 != nil:
    section.add "X-Amz-Credential", valid_402657231
  var valid_402657232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657232 = validateParameter(valid_402657232, JString,
                                      required = false, default = nil)
  if valid_402657232 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657234: Call_UnarchiveFindings_402657222;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Unarchives GuardDuty findings specified by the <code>findingIds</code>.
                                                                                         ## 
  let valid = call_402657234.validator(path, query, header, formData, body, _)
  let scheme = call_402657234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657234.makeUrl(scheme.get, call_402657234.host, call_402657234.base,
                                   call_402657234.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657234, uri, valid, _)

proc call*(call_402657235: Call_UnarchiveFindings_402657222; body: JsonNode;
           detectorId: string): Recallable =
  ## unarchiveFindings
  ## Unarchives GuardDuty findings specified by the <code>findingIds</code>.
  ##   
                                                                            ## body: JObject (required)
  ##   
                                                                                                       ## detectorId: string (required)
                                                                                                       ##             
                                                                                                       ## : 
                                                                                                       ## The 
                                                                                                       ## ID 
                                                                                                       ## of 
                                                                                                       ## the 
                                                                                                       ## detector 
                                                                                                       ## associated 
                                                                                                       ## with 
                                                                                                       ## the 
                                                                                                       ## findings 
                                                                                                       ## to 
                                                                                                       ## unarchive.
  var path_402657236 = newJObject()
  var body_402657237 = newJObject()
  if body != nil:
    body_402657237 = body
  add(path_402657236, "detectorId", newJString(detectorId))
  result = call_402657235.call(path_402657236, nil, nil, nil, body_402657237)

var unarchiveFindings* = Call_UnarchiveFindings_402657222(
    name: "unarchiveFindings", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/unarchive",
    validator: validate_UnarchiveFindings_402657223, base: "/",
    makeUrl: url_UnarchiveFindings_402657224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657238 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657240(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402657239(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes tags from a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) for the resource to remove tags from.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402657241 = path.getOrDefault("resourceArn")
  valid_402657241 = validateParameter(valid_402657241, JString, required = true,
                                      default = nil)
  if valid_402657241 != nil:
    section.add "resourceArn", valid_402657241
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The tag keys to remove from the resource.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402657242 = query.getOrDefault("tagKeys")
  valid_402657242 = validateParameter(valid_402657242, JArray, required = true,
                                      default = nil)
  if valid_402657242 != nil:
    section.add "tagKeys", valid_402657242
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657243 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657243 = validateParameter(valid_402657243, JString,
                                      required = false, default = nil)
  if valid_402657243 != nil:
    section.add "X-Amz-Security-Token", valid_402657243
  var valid_402657244 = header.getOrDefault("X-Amz-Signature")
  valid_402657244 = validateParameter(valid_402657244, JString,
                                      required = false, default = nil)
  if valid_402657244 != nil:
    section.add "X-Amz-Signature", valid_402657244
  var valid_402657245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657245 = validateParameter(valid_402657245, JString,
                                      required = false, default = nil)
  if valid_402657245 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657245
  var valid_402657246 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657246 = validateParameter(valid_402657246, JString,
                                      required = false, default = nil)
  if valid_402657246 != nil:
    section.add "X-Amz-Algorithm", valid_402657246
  var valid_402657247 = header.getOrDefault("X-Amz-Date")
  valid_402657247 = validateParameter(valid_402657247, JString,
                                      required = false, default = nil)
  if valid_402657247 != nil:
    section.add "X-Amz-Date", valid_402657247
  var valid_402657248 = header.getOrDefault("X-Amz-Credential")
  valid_402657248 = validateParameter(valid_402657248, JString,
                                      required = false, default = nil)
  if valid_402657248 != nil:
    section.add "X-Amz-Credential", valid_402657248
  var valid_402657249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657249 = validateParameter(valid_402657249, JString,
                                      required = false, default = nil)
  if valid_402657249 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657250: Call_UntagResource_402657238; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags from a resource.
                                                                                         ## 
  let valid = call_402657250.validator(path, query, header, formData, body, _)
  let scheme = call_402657250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657250.makeUrl(scheme.get, call_402657250.host, call_402657250.base,
                                   call_402657250.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657250, uri, valid, _)

proc call*(call_402657251: Call_UntagResource_402657238; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   tagKeys: JArray (required)
                                  ##          : The tag keys to remove from the resource.
  ##   
                                                                                         ## resourceArn: string (required)
                                                                                         ##              
                                                                                         ## : 
                                                                                         ## The 
                                                                                         ## Amazon 
                                                                                         ## Resource 
                                                                                         ## Name 
                                                                                         ## (ARN) 
                                                                                         ## for 
                                                                                         ## the 
                                                                                         ## resource 
                                                                                         ## to 
                                                                                         ## remove 
                                                                                         ## tags 
                                                                                         ## from.
  var path_402657252 = newJObject()
  var query_402657253 = newJObject()
  if tagKeys != nil:
    query_402657253.add "tagKeys", tagKeys
  add(path_402657252, "resourceArn", newJString(resourceArn))
  result = call_402657251.call(path_402657252, query_402657253, nil, nil, nil)

var untagResource* = Call_UntagResource_402657238(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402657239,
    base: "/", makeUrl: url_UntagResource_402657240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindingsFeedback_402657254 = ref object of OpenApiRestCall_402656044
proc url_UpdateFindingsFeedback_402657256(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
                 (kind: VariableSegment, value: "detectorId"),
                 (kind: ConstantSegment, value: "/findings/feedback")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFindingsFeedback_402657255(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Marks the specified GuardDuty findings as useful or not useful.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
                                 ##             : The ID of the detector associated with the findings to update feedback for.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `detectorId` field"
  var valid_402657257 = path.getOrDefault("detectorId")
  valid_402657257 = validateParameter(valid_402657257, JString, required = true,
                                      default = nil)
  if valid_402657257 != nil:
    section.add "detectorId", valid_402657257
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657258 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657258 = validateParameter(valid_402657258, JString,
                                      required = false, default = nil)
  if valid_402657258 != nil:
    section.add "X-Amz-Security-Token", valid_402657258
  var valid_402657259 = header.getOrDefault("X-Amz-Signature")
  valid_402657259 = validateParameter(valid_402657259, JString,
                                      required = false, default = nil)
  if valid_402657259 != nil:
    section.add "X-Amz-Signature", valid_402657259
  var valid_402657260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657260 = validateParameter(valid_402657260, JString,
                                      required = false, default = nil)
  if valid_402657260 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657260
  var valid_402657261 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657261 = validateParameter(valid_402657261, JString,
                                      required = false, default = nil)
  if valid_402657261 != nil:
    section.add "X-Amz-Algorithm", valid_402657261
  var valid_402657262 = header.getOrDefault("X-Amz-Date")
  valid_402657262 = validateParameter(valid_402657262, JString,
                                      required = false, default = nil)
  if valid_402657262 != nil:
    section.add "X-Amz-Date", valid_402657262
  var valid_402657263 = header.getOrDefault("X-Amz-Credential")
  valid_402657263 = validateParameter(valid_402657263, JString,
                                      required = false, default = nil)
  if valid_402657263 != nil:
    section.add "X-Amz-Credential", valid_402657263
  var valid_402657264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657264 = validateParameter(valid_402657264, JString,
                                      required = false, default = nil)
  if valid_402657264 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657266: Call_UpdateFindingsFeedback_402657254;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Marks the specified GuardDuty findings as useful or not useful.
                                                                                         ## 
  let valid = call_402657266.validator(path, query, header, formData, body, _)
  let scheme = call_402657266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657266.makeUrl(scheme.get, call_402657266.host, call_402657266.base,
                                   call_402657266.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657266, uri, valid, _)

proc call*(call_402657267: Call_UpdateFindingsFeedback_402657254;
           body: JsonNode; detectorId: string): Recallable =
  ## updateFindingsFeedback
  ## Marks the specified GuardDuty findings as useful or not useful.
  ##   body: JObject (required)
  ##   detectorId: string (required)
                               ##             : The ID of the detector associated with the findings to update feedback for.
  var path_402657268 = newJObject()
  var body_402657269 = newJObject()
  if body != nil:
    body_402657269 = body
  add(path_402657268, "detectorId", newJString(detectorId))
  result = call_402657267.call(path_402657268, nil, nil, nil, body_402657269)

var updateFindingsFeedback* = Call_UpdateFindingsFeedback_402657254(
    name: "updateFindingsFeedback", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/feedback",
    validator: validate_UpdateFindingsFeedback_402657255, base: "/",
    makeUrl: url_UpdateFindingsFeedback_402657256,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}