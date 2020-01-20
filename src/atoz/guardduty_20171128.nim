
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
  awsServers = {Scheme.Http: {"ap-northeast-1": "guardduty.ap-northeast-1.amazonaws.com", "ap-southeast-1": "guardduty.ap-southeast-1.amazonaws.com",
                           "us-west-2": "guardduty.us-west-2.amazonaws.com",
                           "eu-west-2": "guardduty.eu-west-2.amazonaws.com", "ap-northeast-3": "guardduty.ap-northeast-3.amazonaws.com", "eu-central-1": "guardduty.eu-central-1.amazonaws.com",
                           "us-east-2": "guardduty.us-east-2.amazonaws.com",
                           "us-east-1": "guardduty.us-east-1.amazonaws.com", "cn-northwest-1": "guardduty.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "guardduty.ap-south-1.amazonaws.com",
                           "eu-north-1": "guardduty.eu-north-1.amazonaws.com", "ap-northeast-2": "guardduty.ap-northeast-2.amazonaws.com",
                           "us-west-1": "guardduty.us-west-1.amazonaws.com", "us-gov-east-1": "guardduty.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "guardduty.eu-west-3.amazonaws.com", "cn-north-1": "guardduty.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "guardduty.sa-east-1.amazonaws.com",
                           "eu-west-1": "guardduty.eu-west-1.amazonaws.com", "us-gov-west-1": "guardduty.us-gov-west-1.amazonaws.com", "ap-southeast-2": "guardduty.ap-southeast-2.amazonaws.com", "ca-central-1": "guardduty.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptInvitation_606197 = ref object of OpenApiRestCall_605589
proc url_AcceptInvitation_606199(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AcceptInvitation_606198(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_606200 = path.getOrDefault("detectorId")
  valid_606200 = validateParameter(valid_606200, JString, required = true,
                                 default = nil)
  if valid_606200 != nil:
    section.add "detectorId", valid_606200
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
  var valid_606201 = header.getOrDefault("X-Amz-Signature")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Signature", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Content-Sha256", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Date")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Date", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Credential")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Credential", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Security-Token")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Security-Token", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Algorithm")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Algorithm", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-SignedHeaders", valid_606207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606209: Call_AcceptInvitation_606197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts the invitation to be monitored by a master GuardDuty account.
  ## 
  let valid = call_606209.validator(path, query, header, formData, body)
  let scheme = call_606209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606209.url(scheme.get, call_606209.host, call_606209.base,
                         call_606209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606209, url, valid)

proc call*(call_606210: Call_AcceptInvitation_606197; detectorId: string;
          body: JsonNode): Recallable =
  ## acceptInvitation
  ## Accepts the invitation to be monitored by a master GuardDuty account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  ##   body: JObject (required)
  var path_606211 = newJObject()
  var body_606212 = newJObject()
  add(path_606211, "detectorId", newJString(detectorId))
  if body != nil:
    body_606212 = body
  result = call_606210.call(path_606211, nil, nil, nil, body_606212)

var acceptInvitation* = Call_AcceptInvitation_606197(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master", validator: validate_AcceptInvitation_606198,
    base: "/", url: url_AcceptInvitation_606199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_605927 = ref object of OpenApiRestCall_605589
proc url_GetMasterAccount_605929(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMasterAccount_605928(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_606055 = path.getOrDefault("detectorId")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "detectorId", valid_606055
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
  var valid_606056 = header.getOrDefault("X-Amz-Signature")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Signature", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Content-Sha256", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Date")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Date", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Credential")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Credential", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Security-Token")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Security-Token", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Algorithm")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Algorithm", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-SignedHeaders", valid_606062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_GetMasterAccount_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_GetMasterAccount_605927; detectorId: string): Recallable =
  ## getMasterAccount
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  var path_606157 = newJObject()
  add(path_606157, "detectorId", newJString(detectorId))
  result = call_606156.call(path_606157, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_605927(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master", validator: validate_GetMasterAccount_605928,
    base: "/", url: url_GetMasterAccount_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ArchiveFindings_606213 = ref object of OpenApiRestCall_605589
proc url_ArchiveFindings_606215(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ArchiveFindings_606214(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_606216 = path.getOrDefault("detectorId")
  valid_606216 = validateParameter(valid_606216, JString, required = true,
                                 default = nil)
  if valid_606216 != nil:
    section.add "detectorId", valid_606216
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
  var valid_606217 = header.getOrDefault("X-Amz-Signature")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Signature", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Content-Sha256", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Date")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Date", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Credential")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Credential", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Security-Token")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Security-Token", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Algorithm")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Algorithm", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-SignedHeaders", valid_606223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606225: Call_ArchiveFindings_606213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
  ## 
  let valid = call_606225.validator(path, query, header, formData, body)
  let scheme = call_606225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606225.url(scheme.get, call_606225.host, call_606225.base,
                         call_606225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606225, url, valid)

proc call*(call_606226: Call_ArchiveFindings_606213; detectorId: string;
          body: JsonNode): Recallable =
  ## archiveFindings
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to archive.
  ##   body: JObject (required)
  var path_606227 = newJObject()
  var body_606228 = newJObject()
  add(path_606227, "detectorId", newJString(detectorId))
  if body != nil:
    body_606228 = body
  result = call_606226.call(path_606227, nil, nil, nil, body_606228)

var archiveFindings* = Call_ArchiveFindings_606213(name: "archiveFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/archive",
    validator: validate_ArchiveFindings_606214, base: "/", url: url_ArchiveFindings_606215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDetector_606246 = ref object of OpenApiRestCall_605589
proc url_CreateDetector_606248(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDetector_606247(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
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
  var valid_606249 = header.getOrDefault("X-Amz-Signature")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Signature", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Content-Sha256", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Date")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Date", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-Credential")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Credential", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Security-Token")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Security-Token", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Algorithm")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Algorithm", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-SignedHeaders", valid_606255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606257: Call_CreateDetector_606246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
  ## 
  let valid = call_606257.validator(path, query, header, formData, body)
  let scheme = call_606257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606257.url(scheme.get, call_606257.host, call_606257.base,
                         call_606257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606257, url, valid)

proc call*(call_606258: Call_CreateDetector_606246; body: JsonNode): Recallable =
  ## createDetector
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
  ##   body: JObject (required)
  var body_606259 = newJObject()
  if body != nil:
    body_606259 = body
  result = call_606258.call(nil, nil, nil, nil, body_606259)

var createDetector* = Call_CreateDetector_606246(name: "createDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com", route: "/detector",
    validator: validate_CreateDetector_606247, base: "/", url: url_CreateDetector_606248,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectors_606229 = ref object of OpenApiRestCall_605589
proc url_ListDetectors_606231(protocol: Scheme; host: string; base: string;
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

proc validate_ListDetectors_606230(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists detectorIds of all the existing Amazon GuardDuty detector resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  section = newJObject()
  var valid_606232 = query.getOrDefault("nextToken")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "nextToken", valid_606232
  var valid_606233 = query.getOrDefault("MaxResults")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "MaxResults", valid_606233
  var valid_606234 = query.getOrDefault("NextToken")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "NextToken", valid_606234
  var valid_606235 = query.getOrDefault("maxResults")
  valid_606235 = validateParameter(valid_606235, JInt, required = false, default = nil)
  if valid_606235 != nil:
    section.add "maxResults", valid_606235
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
  var valid_606236 = header.getOrDefault("X-Amz-Signature")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Signature", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Content-Sha256", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Date")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Date", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Credential")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Credential", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Security-Token")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Security-Token", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Algorithm")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Algorithm", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-SignedHeaders", valid_606242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606243: Call_ListDetectors_606229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists detectorIds of all the existing Amazon GuardDuty detector resources.
  ## 
  let valid = call_606243.validator(path, query, header, formData, body)
  let scheme = call_606243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606243.url(scheme.get, call_606243.host, call_606243.base,
                         call_606243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606243, url, valid)

proc call*(call_606244: Call_ListDetectors_606229; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listDetectors
  ## Lists detectorIds of all the existing Amazon GuardDuty detector resources.
  ##   nextToken: string
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  var query_606245 = newJObject()
  add(query_606245, "nextToken", newJString(nextToken))
  add(query_606245, "MaxResults", newJString(MaxResults))
  add(query_606245, "NextToken", newJString(NextToken))
  add(query_606245, "maxResults", newJInt(maxResults))
  result = call_606244.call(nil, query_606245, nil, nil, nil)

var listDetectors* = Call_ListDetectors_606229(name: "listDetectors",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com", route: "/detector",
    validator: validate_ListDetectors_606230, base: "/", url: url_ListDetectors_606231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFilter_606279 = ref object of OpenApiRestCall_605589
proc url_CreateFilter_606281(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateFilter_606280(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606282 = path.getOrDefault("detectorId")
  valid_606282 = validateParameter(valid_606282, JString, required = true,
                                 default = nil)
  if valid_606282 != nil:
    section.add "detectorId", valid_606282
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
  var valid_606283 = header.getOrDefault("X-Amz-Signature")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Signature", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Content-Sha256", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Date")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Date", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Credential")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Credential", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Security-Token")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Security-Token", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Algorithm")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Algorithm", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-SignedHeaders", valid_606289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606291: Call_CreateFilter_606279; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a filter using the specified finding criteria.
  ## 
  let valid = call_606291.validator(path, query, header, formData, body)
  let scheme = call_606291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606291.url(scheme.get, call_606291.host, call_606291.base,
                         call_606291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606291, url, valid)

proc call*(call_606292: Call_CreateFilter_606279; detectorId: string; body: JsonNode): Recallable =
  ## createFilter
  ## Creates a filter using the specified finding criteria.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create a filter.
  ##   body: JObject (required)
  var path_606293 = newJObject()
  var body_606294 = newJObject()
  add(path_606293, "detectorId", newJString(detectorId))
  if body != nil:
    body_606294 = body
  result = call_606292.call(path_606293, nil, nil, nil, body_606294)

var createFilter* = Call_CreateFilter_606279(name: "createFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter", validator: validate_CreateFilter_606280,
    base: "/", url: url_CreateFilter_606281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFilters_606260 = ref object of OpenApiRestCall_605589
proc url_ListFilters_606262(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFilters_606261(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606263 = path.getOrDefault("detectorId")
  valid_606263 = validateParameter(valid_606263, JString, required = true,
                                 default = nil)
  if valid_606263 != nil:
    section.add "detectorId", valid_606263
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  section = newJObject()
  var valid_606264 = query.getOrDefault("nextToken")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "nextToken", valid_606264
  var valid_606265 = query.getOrDefault("MaxResults")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "MaxResults", valid_606265
  var valid_606266 = query.getOrDefault("NextToken")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "NextToken", valid_606266
  var valid_606267 = query.getOrDefault("maxResults")
  valid_606267 = validateParameter(valid_606267, JInt, required = false, default = nil)
  if valid_606267 != nil:
    section.add "maxResults", valid_606267
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
  var valid_606268 = header.getOrDefault("X-Amz-Signature")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Signature", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Content-Sha256", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Date")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Date", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Credential")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Credential", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Security-Token")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Security-Token", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Algorithm")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Algorithm", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-SignedHeaders", valid_606274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606275: Call_ListFilters_606260; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of the current filters.
  ## 
  let valid = call_606275.validator(path, query, header, formData, body)
  let scheme = call_606275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606275.url(scheme.get, call_606275.host, call_606275.base,
                         call_606275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606275, url, valid)

proc call*(call_606276: Call_ListFilters_606260; detectorId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listFilters
  ## Returns a paginated list of the current filters.
  ##   nextToken: string
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  var path_606277 = newJObject()
  var query_606278 = newJObject()
  add(query_606278, "nextToken", newJString(nextToken))
  add(query_606278, "MaxResults", newJString(MaxResults))
  add(path_606277, "detectorId", newJString(detectorId))
  add(query_606278, "NextToken", newJString(NextToken))
  add(query_606278, "maxResults", newJInt(maxResults))
  result = call_606276.call(path_606277, query_606278, nil, nil, nil)

var listFilters* = Call_ListFilters_606260(name: "listFilters",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/filter",
                                        validator: validate_ListFilters_606261,
                                        base: "/", url: url_ListFilters_606262,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIPSet_606314 = ref object of OpenApiRestCall_605589
proc url_CreateIPSet_606316(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIPSet_606315(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606317 = path.getOrDefault("detectorId")
  valid_606317 = validateParameter(valid_606317, JString, required = true,
                                 default = nil)
  if valid_606317 != nil:
    section.add "detectorId", valid_606317
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
  var valid_606318 = header.getOrDefault("X-Amz-Signature")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Signature", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Content-Sha256", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Date")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Date", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Credential")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Credential", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Security-Token")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Security-Token", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Algorithm")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Algorithm", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-SignedHeaders", valid_606324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606326: Call_CreateIPSet_606314; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new IPSet, called Trusted IP list in the consoler user interface. An IPSet is a list IP addresses trusted for secure communication with AWS infrastructure and applications. GuardDuty does not generate findings for IP addresses included in IPSets. Only users from the master account can use this operation.
  ## 
  let valid = call_606326.validator(path, query, header, formData, body)
  let scheme = call_606326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606326.url(scheme.get, call_606326.host, call_606326.base,
                         call_606326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606326, url, valid)

proc call*(call_606327: Call_CreateIPSet_606314; detectorId: string; body: JsonNode): Recallable =
  ## createIPSet
  ## Creates a new IPSet, called Trusted IP list in the consoler user interface. An IPSet is a list IP addresses trusted for secure communication with AWS infrastructure and applications. GuardDuty does not generate findings for IP addresses included in IPSets. Only users from the master account can use this operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create an IPSet.
  ##   body: JObject (required)
  var path_606328 = newJObject()
  var body_606329 = newJObject()
  add(path_606328, "detectorId", newJString(detectorId))
  if body != nil:
    body_606329 = body
  result = call_606327.call(path_606328, nil, nil, nil, body_606329)

var createIPSet* = Call_CreateIPSet_606314(name: "createIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/ipset",
                                        validator: validate_CreateIPSet_606315,
                                        base: "/", url: url_CreateIPSet_606316,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIPSets_606295 = ref object of OpenApiRestCall_605589
proc url_ListIPSets_606297(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIPSets_606296(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606298 = path.getOrDefault("detectorId")
  valid_606298 = validateParameter(valid_606298, JString, required = true,
                                 default = nil)
  if valid_606298 != nil:
    section.add "detectorId", valid_606298
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  section = newJObject()
  var valid_606299 = query.getOrDefault("nextToken")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "nextToken", valid_606299
  var valid_606300 = query.getOrDefault("MaxResults")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "MaxResults", valid_606300
  var valid_606301 = query.getOrDefault("NextToken")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "NextToken", valid_606301
  var valid_606302 = query.getOrDefault("maxResults")
  valid_606302 = validateParameter(valid_606302, JInt, required = false, default = nil)
  if valid_606302 != nil:
    section.add "maxResults", valid_606302
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
  var valid_606303 = header.getOrDefault("X-Amz-Signature")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Signature", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Content-Sha256", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Date")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Date", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Credential")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Credential", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Security-Token")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Security-Token", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Algorithm")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Algorithm", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-SignedHeaders", valid_606309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606310: Call_ListIPSets_606295; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the IPSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the IPSets returned are the IPSets from the associated master account.
  ## 
  let valid = call_606310.validator(path, query, header, formData, body)
  let scheme = call_606310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606310.url(scheme.get, call_606310.host, call_606310.base,
                         call_606310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606310, url, valid)

proc call*(call_606311: Call_ListIPSets_606295; detectorId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listIPSets
  ## Lists the IPSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the IPSets returned are the IPSets from the associated master account.
  ##   nextToken: string
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the ipSet is associated with.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  var path_606312 = newJObject()
  var query_606313 = newJObject()
  add(query_606313, "nextToken", newJString(nextToken))
  add(query_606313, "MaxResults", newJString(MaxResults))
  add(path_606312, "detectorId", newJString(detectorId))
  add(query_606313, "NextToken", newJString(NextToken))
  add(query_606313, "maxResults", newJInt(maxResults))
  result = call_606311.call(path_606312, query_606313, nil, nil, nil)

var listIPSets* = Call_ListIPSets_606295(name: "listIPSets",
                                      meth: HttpMethod.HttpGet,
                                      host: "guardduty.amazonaws.com",
                                      route: "/detector/{detectorId}/ipset",
                                      validator: validate_ListIPSets_606296,
                                      base: "/", url: url_ListIPSets_606297,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_606350 = ref object of OpenApiRestCall_605589
proc url_CreateMembers_606352(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateMembers_606351(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606353 = path.getOrDefault("detectorId")
  valid_606353 = validateParameter(valid_606353, JString, required = true,
                                 default = nil)
  if valid_606353 != nil:
    section.add "detectorId", valid_606353
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
  var valid_606354 = header.getOrDefault("X-Amz-Signature")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Signature", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Content-Sha256", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Date")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Date", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Credential")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Credential", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Security-Token")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Security-Token", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Algorithm")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Algorithm", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-SignedHeaders", valid_606360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606362: Call_CreateMembers_606350; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
  ## 
  let valid = call_606362.validator(path, query, header, formData, body)
  let scheme = call_606362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606362.url(scheme.get, call_606362.host, call_606362.base,
                         call_606362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606362, url, valid)

proc call*(call_606363: Call_CreateMembers_606350; detectorId: string; body: JsonNode): Recallable =
  ## createMembers
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account with which you want to associate member accounts.
  ##   body: JObject (required)
  var path_606364 = newJObject()
  var body_606365 = newJObject()
  add(path_606364, "detectorId", newJString(detectorId))
  if body != nil:
    body_606365 = body
  result = call_606363.call(path_606364, nil, nil, nil, body_606365)

var createMembers* = Call_CreateMembers_606350(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member", validator: validate_CreateMembers_606351,
    base: "/", url: url_CreateMembers_606352, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_606330 = ref object of OpenApiRestCall_605589
proc url_ListMembers_606332(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListMembers_606331(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606333 = path.getOrDefault("detectorId")
  valid_606333 = validateParameter(valid_606333, JString, required = true,
                                 default = nil)
  if valid_606333 != nil:
    section.add "detectorId", valid_606333
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   onlyAssociated: JString
  ##                 : Specifies whether to only return associated members or to return all members (including members which haven't been invited yet or have been disassociated).
  ##   maxResults: JInt
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  section = newJObject()
  var valid_606334 = query.getOrDefault("nextToken")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "nextToken", valid_606334
  var valid_606335 = query.getOrDefault("MaxResults")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "MaxResults", valid_606335
  var valid_606336 = query.getOrDefault("NextToken")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "NextToken", valid_606336
  var valid_606337 = query.getOrDefault("onlyAssociated")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "onlyAssociated", valid_606337
  var valid_606338 = query.getOrDefault("maxResults")
  valid_606338 = validateParameter(valid_606338, JInt, required = false, default = nil)
  if valid_606338 != nil:
    section.add "maxResults", valid_606338
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
  var valid_606339 = header.getOrDefault("X-Amz-Signature")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Signature", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Content-Sha256", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Date")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Date", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Credential")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Credential", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Security-Token")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Security-Token", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Algorithm")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Algorithm", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-SignedHeaders", valid_606345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606346: Call_ListMembers_606330; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current GuardDuty master account.
  ## 
  let valid = call_606346.validator(path, query, header, formData, body)
  let scheme = call_606346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606346.url(scheme.get, call_606346.host, call_606346.base,
                         call_606346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606346, url, valid)

proc call*(call_606347: Call_ListMembers_606330; detectorId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          onlyAssociated: string = ""; maxResults: int = 0): Recallable =
  ## listMembers
  ## Lists details about all member accounts for the current GuardDuty master account.
  ##   nextToken: string
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the member is associated with.
  ##   NextToken: string
  ##            : Pagination token
  ##   onlyAssociated: string
  ##                 : Specifies whether to only return associated members or to return all members (including members which haven't been invited yet or have been disassociated).
  ##   maxResults: int
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  var path_606348 = newJObject()
  var query_606349 = newJObject()
  add(query_606349, "nextToken", newJString(nextToken))
  add(query_606349, "MaxResults", newJString(MaxResults))
  add(path_606348, "detectorId", newJString(detectorId))
  add(query_606349, "NextToken", newJString(NextToken))
  add(query_606349, "onlyAssociated", newJString(onlyAssociated))
  add(query_606349, "maxResults", newJInt(maxResults))
  result = call_606347.call(path_606348, query_606349, nil, nil, nil)

var listMembers* = Call_ListMembers_606330(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/member",
                                        validator: validate_ListMembers_606331,
                                        base: "/", url: url_ListMembers_606332,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublishingDestination_606385 = ref object of OpenApiRestCall_605589
proc url_CreatePublishingDestination_606387(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreatePublishingDestination_606386(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606388 = path.getOrDefault("detectorId")
  valid_606388 = validateParameter(valid_606388, JString, required = true,
                                 default = nil)
  if valid_606388 != nil:
    section.add "detectorId", valid_606388
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
  var valid_606389 = header.getOrDefault("X-Amz-Signature")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Signature", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Content-Sha256", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Date")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Date", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Credential")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Credential", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Security-Token")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Security-Token", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Algorithm")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Algorithm", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-SignedHeaders", valid_606395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606397: Call_CreatePublishingDestination_606385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a publishing destination to send findings to. The resource to send findings to must exist before you use this operation.
  ## 
  let valid = call_606397.validator(path, query, header, formData, body)
  let scheme = call_606397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606397.url(scheme.get, call_606397.host, call_606397.base,
                         call_606397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606397, url, valid)

proc call*(call_606398: Call_CreatePublishingDestination_606385;
          detectorId: string; body: JsonNode): Recallable =
  ## createPublishingDestination
  ## Creates a publishing destination to send findings to. The resource to send findings to must exist before you use this operation.
  ##   detectorId: string (required)
  ##             : The ID of the GuardDuty detector associated with the publishing destination.
  ##   body: JObject (required)
  var path_606399 = newJObject()
  var body_606400 = newJObject()
  add(path_606399, "detectorId", newJString(detectorId))
  if body != nil:
    body_606400 = body
  result = call_606398.call(path_606399, nil, nil, nil, body_606400)

var createPublishingDestination* = Call_CreatePublishingDestination_606385(
    name: "createPublishingDestination", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination",
    validator: validate_CreatePublishingDestination_606386, base: "/",
    url: url_CreatePublishingDestination_606387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishingDestinations_606366 = ref object of OpenApiRestCall_605589
proc url_ListPublishingDestinations_606368(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListPublishingDestinations_606367(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606369 = path.getOrDefault("detectorId")
  valid_606369 = validateParameter(valid_606369, JString, required = true,
                                 default = nil)
  if valid_606369 != nil:
    section.add "detectorId", valid_606369
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token to use for paginating results returned in the repsonse. Set the value of this parameter to null for the first request to a list action. For subsequent calls, use the <code>NextToken</code> value returned from the previous request to continue listing results after the first page.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results to return in the response.
  section = newJObject()
  var valid_606370 = query.getOrDefault("nextToken")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "nextToken", valid_606370
  var valid_606371 = query.getOrDefault("MaxResults")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "MaxResults", valid_606371
  var valid_606372 = query.getOrDefault("NextToken")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "NextToken", valid_606372
  var valid_606373 = query.getOrDefault("maxResults")
  valid_606373 = validateParameter(valid_606373, JInt, required = false, default = nil)
  if valid_606373 != nil:
    section.add "maxResults", valid_606373
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
  var valid_606374 = header.getOrDefault("X-Amz-Signature")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Signature", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Content-Sha256", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Date")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Date", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Credential")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Credential", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Security-Token")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Security-Token", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Algorithm")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Algorithm", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-SignedHeaders", valid_606380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606381: Call_ListPublishingDestinations_606366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of publishing destinations associated with the specified <code>dectectorId</code>.
  ## 
  let valid = call_606381.validator(path, query, header, formData, body)
  let scheme = call_606381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606381.url(scheme.get, call_606381.host, call_606381.base,
                         call_606381.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606381, url, valid)

proc call*(call_606382: Call_ListPublishingDestinations_606366; detectorId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listPublishingDestinations
  ## Returns a list of publishing destinations associated with the specified <code>dectectorId</code>.
  ##   nextToken: string
  ##            : A token to use for paginating results returned in the repsonse. Set the value of this parameter to null for the first request to a list action. For subsequent calls, use the <code>NextToken</code> value returned from the previous request to continue listing results after the first page.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   detectorId: string (required)
  ##             : The ID of the detector to retrieve publishing destinations for.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in the response.
  var path_606383 = newJObject()
  var query_606384 = newJObject()
  add(query_606384, "nextToken", newJString(nextToken))
  add(query_606384, "MaxResults", newJString(MaxResults))
  add(path_606383, "detectorId", newJString(detectorId))
  add(query_606384, "NextToken", newJString(NextToken))
  add(query_606384, "maxResults", newJInt(maxResults))
  result = call_606382.call(path_606383, query_606384, nil, nil, nil)

var listPublishingDestinations* = Call_ListPublishingDestinations_606366(
    name: "listPublishingDestinations", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination",
    validator: validate_ListPublishingDestinations_606367, base: "/",
    url: url_ListPublishingDestinations_606368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSampleFindings_606401 = ref object of OpenApiRestCall_605589
proc url_CreateSampleFindings_606403(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSampleFindings_606402(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606404 = path.getOrDefault("detectorId")
  valid_606404 = validateParameter(valid_606404, JString, required = true,
                                 default = nil)
  if valid_606404 != nil:
    section.add "detectorId", valid_606404
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
  var valid_606405 = header.getOrDefault("X-Amz-Signature")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Signature", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Content-Sha256", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Date")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Date", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Credential")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Credential", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Security-Token")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Security-Token", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Algorithm")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Algorithm", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-SignedHeaders", valid_606411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606413: Call_CreateSampleFindings_606401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for <code>findingTypes</code>, the API generates example findings of all supported finding types.
  ## 
  let valid = call_606413.validator(path, query, header, formData, body)
  let scheme = call_606413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606413.url(scheme.get, call_606413.host, call_606413.base,
                         call_606413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606413, url, valid)

proc call*(call_606414: Call_CreateSampleFindings_606401; detectorId: string;
          body: JsonNode): Recallable =
  ## createSampleFindings
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for <code>findingTypes</code>, the API generates example findings of all supported finding types.
  ##   detectorId: string (required)
  ##             : The ID of the detector to create sample findings for.
  ##   body: JObject (required)
  var path_606415 = newJObject()
  var body_606416 = newJObject()
  add(path_606415, "detectorId", newJString(detectorId))
  if body != nil:
    body_606416 = body
  result = call_606414.call(path_606415, nil, nil, nil, body_606416)

var createSampleFindings* = Call_CreateSampleFindings_606401(
    name: "createSampleFindings", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/create",
    validator: validate_CreateSampleFindings_606402, base: "/",
    url: url_CreateSampleFindings_606403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateThreatIntelSet_606436 = ref object of OpenApiRestCall_605589
proc url_CreateThreatIntelSet_606438(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateThreatIntelSet_606437(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606439 = path.getOrDefault("detectorId")
  valid_606439 = validateParameter(valid_606439, JString, required = true,
                                 default = nil)
  if valid_606439 != nil:
    section.add "detectorId", valid_606439
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

proc call*(call_606448: Call_CreateThreatIntelSet_606436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets. Only users of the master account can use this operation.
  ## 
  let valid = call_606448.validator(path, query, header, formData, body)
  let scheme = call_606448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606448.url(scheme.get, call_606448.host, call_606448.base,
                         call_606448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606448, url, valid)

proc call*(call_606449: Call_CreateThreatIntelSet_606436; detectorId: string;
          body: JsonNode): Recallable =
  ## createThreatIntelSet
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets. Only users of the master account can use this operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create a threatIntelSet.
  ##   body: JObject (required)
  var path_606450 = newJObject()
  var body_606451 = newJObject()
  add(path_606450, "detectorId", newJString(detectorId))
  if body != nil:
    body_606451 = body
  result = call_606449.call(path_606450, nil, nil, nil, body_606451)

var createThreatIntelSet* = Call_CreateThreatIntelSet_606436(
    name: "createThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_CreateThreatIntelSet_606437, base: "/",
    url: url_CreateThreatIntelSet_606438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListThreatIntelSets_606417 = ref object of OpenApiRestCall_605589
proc url_ListThreatIntelSets_606419(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListThreatIntelSets_606418(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_606420 = path.getOrDefault("detectorId")
  valid_606420 = validateParameter(valid_606420, JString, required = true,
                                 default = nil)
  if valid_606420 != nil:
    section.add "detectorId", valid_606420
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : You can use this parameter to paginate results in the response. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  section = newJObject()
  var valid_606421 = query.getOrDefault("nextToken")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "nextToken", valid_606421
  var valid_606422 = query.getOrDefault("MaxResults")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "MaxResults", valid_606422
  var valid_606423 = query.getOrDefault("NextToken")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "NextToken", valid_606423
  var valid_606424 = query.getOrDefault("maxResults")
  valid_606424 = validateParameter(valid_606424, JInt, required = false, default = nil)
  if valid_606424 != nil:
    section.add "maxResults", valid_606424
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
  if body != nil:
    result.add "body", body

proc call*(call_606432: Call_ListThreatIntelSets_606417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the ThreatIntelSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the ThreatIntelSets associated with the master account are returned.
  ## 
  let valid = call_606432.validator(path, query, header, formData, body)
  let scheme = call_606432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606432.url(scheme.get, call_606432.host, call_606432.base,
                         call_606432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606432, url, valid)

proc call*(call_606433: Call_ListThreatIntelSets_606417; detectorId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listThreatIntelSets
  ## Lists the ThreatIntelSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the ThreatIntelSets associated with the master account are returned.
  ##   nextToken: string
  ##            : You can use this parameter to paginate results in the response. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  var path_606434 = newJObject()
  var query_606435 = newJObject()
  add(query_606435, "nextToken", newJString(nextToken))
  add(query_606435, "MaxResults", newJString(MaxResults))
  add(path_606434, "detectorId", newJString(detectorId))
  add(query_606435, "NextToken", newJString(NextToken))
  add(query_606435, "maxResults", newJInt(maxResults))
  result = call_606433.call(path_606434, query_606435, nil, nil, nil)

var listThreatIntelSets* = Call_ListThreatIntelSets_606417(
    name: "listThreatIntelSets", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_ListThreatIntelSets_606418, base: "/",
    url: url_ListThreatIntelSets_606419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_606452 = ref object of OpenApiRestCall_605589
proc url_DeclineInvitations_606454(protocol: Scheme; host: string; base: string;
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

proc validate_DeclineInvitations_606453(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
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

proc call*(call_606463: Call_DeclineInvitations_606452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_DeclineInvitations_606452; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
  ##   body: JObject (required)
  var body_606465 = newJObject()
  if body != nil:
    body_606465 = body
  result = call_606464.call(nil, nil, nil, nil, body_606465)

var declineInvitations* = Call_DeclineInvitations_606452(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/invitation/decline",
    validator: validate_DeclineInvitations_606453, base: "/",
    url: url_DeclineInvitations_606454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetector_606480 = ref object of OpenApiRestCall_605589
proc url_UpdateDetector_606482(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDetector_606481(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_606483 = path.getOrDefault("detectorId")
  valid_606483 = validateParameter(valid_606483, JString, required = true,
                                 default = nil)
  if valid_606483 != nil:
    section.add "detectorId", valid_606483
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
  var valid_606484 = header.getOrDefault("X-Amz-Signature")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Signature", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Content-Sha256", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Date")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Date", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Credential")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Credential", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Security-Token")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Security-Token", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Algorithm")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Algorithm", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-SignedHeaders", valid_606490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606492: Call_UpdateDetector_606480; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Amazon GuardDuty detector specified by the detectorId.
  ## 
  let valid = call_606492.validator(path, query, header, formData, body)
  let scheme = call_606492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606492.url(scheme.get, call_606492.host, call_606492.base,
                         call_606492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606492, url, valid)

proc call*(call_606493: Call_UpdateDetector_606480; detectorId: string;
          body: JsonNode): Recallable =
  ## updateDetector
  ## Updates the Amazon GuardDuty detector specified by the detectorId.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector to update.
  ##   body: JObject (required)
  var path_606494 = newJObject()
  var body_606495 = newJObject()
  add(path_606494, "detectorId", newJString(detectorId))
  if body != nil:
    body_606495 = body
  result = call_606493.call(path_606494, nil, nil, nil, body_606495)

var updateDetector* = Call_UpdateDetector_606480(name: "updateDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_UpdateDetector_606481,
    base: "/", url: url_UpdateDetector_606482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetector_606466 = ref object of OpenApiRestCall_605589
proc url_GetDetector_606468(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDetector_606467(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606469 = path.getOrDefault("detectorId")
  valid_606469 = validateParameter(valid_606469, JString, required = true,
                                 default = nil)
  if valid_606469 != nil:
    section.add "detectorId", valid_606469
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
  if body != nil:
    result.add "body", body

proc call*(call_606477: Call_GetDetector_606466; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
  ## 
  let valid = call_606477.validator(path, query, header, formData, body)
  let scheme = call_606477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606477.url(scheme.get, call_606477.host, call_606477.base,
                         call_606477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606477, url, valid)

proc call*(call_606478: Call_GetDetector_606466; detectorId: string): Recallable =
  ## getDetector
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that you want to get.
  var path_606479 = newJObject()
  add(path_606479, "detectorId", newJString(detectorId))
  result = call_606478.call(path_606479, nil, nil, nil, nil)

var getDetector* = Call_GetDetector_606466(name: "getDetector",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}",
                                        validator: validate_GetDetector_606467,
                                        base: "/", url: url_GetDetector_606468,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetector_606496 = ref object of OpenApiRestCall_605589
proc url_DeleteDetector_606498(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDetector_606497(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_606499 = path.getOrDefault("detectorId")
  valid_606499 = validateParameter(valid_606499, JString, required = true,
                                 default = nil)
  if valid_606499 != nil:
    section.add "detectorId", valid_606499
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
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606507: Call_DeleteDetector_606496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
  ## 
  let valid = call_606507.validator(path, query, header, formData, body)
  let scheme = call_606507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606507.url(scheme.get, call_606507.host, call_606507.base,
                         call_606507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606507, url, valid)

proc call*(call_606508: Call_DeleteDetector_606496; detectorId: string): Recallable =
  ## deleteDetector
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that you want to delete.
  var path_606509 = newJObject()
  add(path_606509, "detectorId", newJString(detectorId))
  result = call_606508.call(path_606509, nil, nil, nil, nil)

var deleteDetector* = Call_DeleteDetector_606496(name: "deleteDetector",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_DeleteDetector_606497,
    base: "/", url: url_DeleteDetector_606498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFilter_606525 = ref object of OpenApiRestCall_605589
proc url_UpdateFilter_606527(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFilter_606526(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the filter specified by the filter name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector that specifies the GuardDuty service where you want to update a filter.
  ##   filterName: JString (required)
  ##             : The name of the filter.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_606528 = path.getOrDefault("detectorId")
  valid_606528 = validateParameter(valid_606528, JString, required = true,
                                 default = nil)
  if valid_606528 != nil:
    section.add "detectorId", valid_606528
  var valid_606529 = path.getOrDefault("filterName")
  valid_606529 = validateParameter(valid_606529, JString, required = true,
                                 default = nil)
  if valid_606529 != nil:
    section.add "filterName", valid_606529
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
  var valid_606530 = header.getOrDefault("X-Amz-Signature")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Signature", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Content-Sha256", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Date")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Date", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Credential")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Credential", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Security-Token")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Security-Token", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Algorithm")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Algorithm", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-SignedHeaders", valid_606536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606538: Call_UpdateFilter_606525; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the filter specified by the filter name.
  ## 
  let valid = call_606538.validator(path, query, header, formData, body)
  let scheme = call_606538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606538.url(scheme.get, call_606538.host, call_606538.base,
                         call_606538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606538, url, valid)

proc call*(call_606539: Call_UpdateFilter_606525; detectorId: string;
          filterName: string; body: JsonNode): Recallable =
  ## updateFilter
  ## Updates the filter specified by the filter name.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that specifies the GuardDuty service where you want to update a filter.
  ##   filterName: string (required)
  ##             : The name of the filter.
  ##   body: JObject (required)
  var path_606540 = newJObject()
  var body_606541 = newJObject()
  add(path_606540, "detectorId", newJString(detectorId))
  add(path_606540, "filterName", newJString(filterName))
  if body != nil:
    body_606541 = body
  result = call_606539.call(path_606540, nil, nil, nil, body_606541)

var updateFilter* = Call_UpdateFilter_606525(name: "updateFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_UpdateFilter_606526, base: "/", url: url_UpdateFilter_606527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFilter_606510 = ref object of OpenApiRestCall_605589
proc url_GetFilter_606512(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFilter_606511(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the details of the filter specified by the filter name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector the filter is associated with.
  ##   filterName: JString (required)
  ##             : The name of the filter you want to get.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_606513 = path.getOrDefault("detectorId")
  valid_606513 = validateParameter(valid_606513, JString, required = true,
                                 default = nil)
  if valid_606513 != nil:
    section.add "detectorId", valid_606513
  var valid_606514 = path.getOrDefault("filterName")
  valid_606514 = validateParameter(valid_606514, JString, required = true,
                                 default = nil)
  if valid_606514 != nil:
    section.add "filterName", valid_606514
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
  var valid_606515 = header.getOrDefault("X-Amz-Signature")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Signature", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Content-Sha256", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Date")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Date", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Credential")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Credential", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Security-Token")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Security-Token", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Algorithm")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Algorithm", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-SignedHeaders", valid_606521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606522: Call_GetFilter_606510; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of the filter specified by the filter name.
  ## 
  let valid = call_606522.validator(path, query, header, formData, body)
  let scheme = call_606522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606522.url(scheme.get, call_606522.host, call_606522.base,
                         call_606522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606522, url, valid)

proc call*(call_606523: Call_GetFilter_606510; detectorId: string; filterName: string): Recallable =
  ## getFilter
  ## Returns the details of the filter specified by the filter name.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  ##   filterName: string (required)
  ##             : The name of the filter you want to get.
  var path_606524 = newJObject()
  add(path_606524, "detectorId", newJString(detectorId))
  add(path_606524, "filterName", newJString(filterName))
  result = call_606523.call(path_606524, nil, nil, nil, nil)

var getFilter* = Call_GetFilter_606510(name: "getFilter", meth: HttpMethod.HttpGet,
                                    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/filter/{filterName}",
                                    validator: validate_GetFilter_606511,
                                    base: "/", url: url_GetFilter_606512,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFilter_606542 = ref object of OpenApiRestCall_605589
proc url_DeleteFilter_606544(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFilter_606543(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the filter specified by the filter name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector the filter is associated with.
  ##   filterName: JString (required)
  ##             : The name of the filter you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_606545 = path.getOrDefault("detectorId")
  valid_606545 = validateParameter(valid_606545, JString, required = true,
                                 default = nil)
  if valid_606545 != nil:
    section.add "detectorId", valid_606545
  var valid_606546 = path.getOrDefault("filterName")
  valid_606546 = validateParameter(valid_606546, JString, required = true,
                                 default = nil)
  if valid_606546 != nil:
    section.add "filterName", valid_606546
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
  var valid_606547 = header.getOrDefault("X-Amz-Signature")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Signature", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Content-Sha256", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Date")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Date", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Credential")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Credential", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Security-Token")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Security-Token", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Algorithm")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Algorithm", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-SignedHeaders", valid_606553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606554: Call_DeleteFilter_606542; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the filter specified by the filter name.
  ## 
  let valid = call_606554.validator(path, query, header, formData, body)
  let scheme = call_606554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606554.url(scheme.get, call_606554.host, call_606554.base,
                         call_606554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606554, url, valid)

proc call*(call_606555: Call_DeleteFilter_606542; detectorId: string;
          filterName: string): Recallable =
  ## deleteFilter
  ## Deletes the filter specified by the filter name.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  ##   filterName: string (required)
  ##             : The name of the filter you want to delete.
  var path_606556 = newJObject()
  add(path_606556, "detectorId", newJString(detectorId))
  add(path_606556, "filterName", newJString(filterName))
  result = call_606555.call(path_606556, nil, nil, nil, nil)

var deleteFilter* = Call_DeleteFilter_606542(name: "deleteFilter",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_DeleteFilter_606543, base: "/", url: url_DeleteFilter_606544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIPSet_606572 = ref object of OpenApiRestCall_605589
proc url_UpdateIPSet_606574(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIPSet_606573(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the IPSet specified by the IPSet ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ipSetId: JString (required)
  ##          : The unique ID that specifies the IPSet that you want to update.
  ##   detectorId: JString (required)
  ##             : The detectorID that specifies the GuardDuty service whose IPSet you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ipSetId` field"
  var valid_606575 = path.getOrDefault("ipSetId")
  valid_606575 = validateParameter(valid_606575, JString, required = true,
                                 default = nil)
  if valid_606575 != nil:
    section.add "ipSetId", valid_606575
  var valid_606576 = path.getOrDefault("detectorId")
  valid_606576 = validateParameter(valid_606576, JString, required = true,
                                 default = nil)
  if valid_606576 != nil:
    section.add "detectorId", valid_606576
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
  var valid_606577 = header.getOrDefault("X-Amz-Signature")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Signature", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Content-Sha256", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Date")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Date", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Credential")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Credential", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Security-Token")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Security-Token", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-Algorithm")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-Algorithm", valid_606582
  var valid_606583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-SignedHeaders", valid_606583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606585: Call_UpdateIPSet_606572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the IPSet specified by the IPSet ID.
  ## 
  let valid = call_606585.validator(path, query, header, formData, body)
  let scheme = call_606585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606585.url(scheme.get, call_606585.host, call_606585.base,
                         call_606585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606585, url, valid)

proc call*(call_606586: Call_UpdateIPSet_606572; ipSetId: string; detectorId: string;
          body: JsonNode): Recallable =
  ## updateIPSet
  ## Updates the IPSet specified by the IPSet ID.
  ##   ipSetId: string (required)
  ##          : The unique ID that specifies the IPSet that you want to update.
  ##   detectorId: string (required)
  ##             : The detectorID that specifies the GuardDuty service whose IPSet you want to update.
  ##   body: JObject (required)
  var path_606587 = newJObject()
  var body_606588 = newJObject()
  add(path_606587, "ipSetId", newJString(ipSetId))
  add(path_606587, "detectorId", newJString(detectorId))
  if body != nil:
    body_606588 = body
  result = call_606586.call(path_606587, nil, nil, nil, body_606588)

var updateIPSet* = Call_UpdateIPSet_606572(name: "updateIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                        validator: validate_UpdateIPSet_606573,
                                        base: "/", url: url_UpdateIPSet_606574,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIPSet_606557 = ref object of OpenApiRestCall_605589
proc url_GetIPSet_606559(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIPSet_606558(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ipSetId: JString (required)
  ##          : The unique ID of the IPSet to retrieve.
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector the ipSet is associated with.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ipSetId` field"
  var valid_606560 = path.getOrDefault("ipSetId")
  valid_606560 = validateParameter(valid_606560, JString, required = true,
                                 default = nil)
  if valid_606560 != nil:
    section.add "ipSetId", valid_606560
  var valid_606561 = path.getOrDefault("detectorId")
  valid_606561 = validateParameter(valid_606561, JString, required = true,
                                 default = nil)
  if valid_606561 != nil:
    section.add "detectorId", valid_606561
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
  var valid_606562 = header.getOrDefault("X-Amz-Signature")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Signature", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Content-Sha256", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Date")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Date", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Credential")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Credential", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Security-Token")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Security-Token", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Algorithm")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Algorithm", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-SignedHeaders", valid_606568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606569: Call_GetIPSet_606557; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
  ## 
  let valid = call_606569.validator(path, query, header, formData, body)
  let scheme = call_606569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606569.url(scheme.get, call_606569.host, call_606569.base,
                         call_606569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606569, url, valid)

proc call*(call_606570: Call_GetIPSet_606557; ipSetId: string; detectorId: string): Recallable =
  ## getIPSet
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
  ##   ipSetId: string (required)
  ##          : The unique ID of the IPSet to retrieve.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the ipSet is associated with.
  var path_606571 = newJObject()
  add(path_606571, "ipSetId", newJString(ipSetId))
  add(path_606571, "detectorId", newJString(detectorId))
  result = call_606570.call(path_606571, nil, nil, nil, nil)

var getIPSet* = Call_GetIPSet_606557(name: "getIPSet", meth: HttpMethod.HttpGet,
                                  host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                  validator: validate_GetIPSet_606558, base: "/",
                                  url: url_GetIPSet_606559,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIPSet_606589 = ref object of OpenApiRestCall_605589
proc url_DeleteIPSet_606591(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIPSet_606590(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ipSetId: JString (required)
  ##          : The unique ID of the IPSet to delete.
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector associated with the IPSet.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ipSetId` field"
  var valid_606592 = path.getOrDefault("ipSetId")
  valid_606592 = validateParameter(valid_606592, JString, required = true,
                                 default = nil)
  if valid_606592 != nil:
    section.add "ipSetId", valid_606592
  var valid_606593 = path.getOrDefault("detectorId")
  valid_606593 = validateParameter(valid_606593, JString, required = true,
                                 default = nil)
  if valid_606593 != nil:
    section.add "detectorId", valid_606593
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
  var valid_606594 = header.getOrDefault("X-Amz-Signature")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Signature", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Content-Sha256", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Date")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Date", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Credential")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Credential", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Security-Token")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Security-Token", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Algorithm")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Algorithm", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-SignedHeaders", valid_606600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606601: Call_DeleteIPSet_606589; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
  ## 
  let valid = call_606601.validator(path, query, header, formData, body)
  let scheme = call_606601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606601.url(scheme.get, call_606601.host, call_606601.base,
                         call_606601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606601, url, valid)

proc call*(call_606602: Call_DeleteIPSet_606589; ipSetId: string; detectorId: string): Recallable =
  ## deleteIPSet
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
  ##   ipSetId: string (required)
  ##          : The unique ID of the IPSet to delete.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the IPSet.
  var path_606603 = newJObject()
  add(path_606603, "ipSetId", newJString(ipSetId))
  add(path_606603, "detectorId", newJString(detectorId))
  result = call_606602.call(path_606603, nil, nil, nil, nil)

var deleteIPSet* = Call_DeleteIPSet_606589(name: "deleteIPSet",
                                        meth: HttpMethod.HttpDelete,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                        validator: validate_DeleteIPSet_606590,
                                        base: "/", url: url_DeleteIPSet_606591,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_606604 = ref object of OpenApiRestCall_605589
proc url_DeleteInvitations_606606(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInvitations_606605(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
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
  var valid_606607 = header.getOrDefault("X-Amz-Signature")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Signature", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Content-Sha256", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Date")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Date", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Credential")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Credential", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Security-Token")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Security-Token", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Algorithm")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Algorithm", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-SignedHeaders", valid_606613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606615: Call_DeleteInvitations_606604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
  ## 
  let valid = call_606615.validator(path, query, header, formData, body)
  let scheme = call_606615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606615.url(scheme.get, call_606615.host, call_606615.base,
                         call_606615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606615, url, valid)

proc call*(call_606616: Call_DeleteInvitations_606604; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
  ##   body: JObject (required)
  var body_606617 = newJObject()
  if body != nil:
    body_606617 = body
  result = call_606616.call(nil, nil, nil, nil, body_606617)

var deleteInvitations* = Call_DeleteInvitations_606604(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/invitation/delete", validator: validate_DeleteInvitations_606605,
    base: "/", url: url_DeleteInvitations_606606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_606618 = ref object of OpenApiRestCall_605589
proc url_DeleteMembers_606620(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMembers_606619(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606621 = path.getOrDefault("detectorId")
  valid_606621 = validateParameter(valid_606621, JString, required = true,
                                 default = nil)
  if valid_606621 != nil:
    section.add "detectorId", valid_606621
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
  var valid_606622 = header.getOrDefault("X-Amz-Signature")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Signature", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Content-Sha256", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Date")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Date", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Credential")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Credential", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Security-Token")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Security-Token", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Algorithm")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Algorithm", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-SignedHeaders", valid_606628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606630: Call_DeleteMembers_606618; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_606630.validator(path, query, header, formData, body)
  let scheme = call_606630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606630.url(scheme.get, call_606630.host, call_606630.base,
                         call_606630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606630, url, valid)

proc call*(call_606631: Call_DeleteMembers_606618; detectorId: string; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to delete.
  ##   body: JObject (required)
  var path_606632 = newJObject()
  var body_606633 = newJObject()
  add(path_606632, "detectorId", newJString(detectorId))
  if body != nil:
    body_606633 = body
  result = call_606631.call(path_606632, nil, nil, nil, body_606633)

var deleteMembers* = Call_DeleteMembers_606618(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/delete",
    validator: validate_DeleteMembers_606619, base: "/", url: url_DeleteMembers_606620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePublishingDestination_606649 = ref object of OpenApiRestCall_605589
proc url_UpdatePublishingDestination_606651(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePublishingDestination_606650(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The ID of the 
  ##   destinationId: JString (required)
  ##                : The ID of the detector associated with the publishing destinations to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_606652 = path.getOrDefault("detectorId")
  valid_606652 = validateParameter(valid_606652, JString, required = true,
                                 default = nil)
  if valid_606652 != nil:
    section.add "detectorId", valid_606652
  var valid_606653 = path.getOrDefault("destinationId")
  valid_606653 = validateParameter(valid_606653, JString, required = true,
                                 default = nil)
  if valid_606653 != nil:
    section.add "destinationId", valid_606653
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
  var valid_606654 = header.getOrDefault("X-Amz-Signature")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Signature", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Content-Sha256", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Date")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Date", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Credential")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Credential", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Security-Token")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Security-Token", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Algorithm")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Algorithm", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-SignedHeaders", valid_606660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606662: Call_UpdatePublishingDestination_606649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
  ## 
  let valid = call_606662.validator(path, query, header, formData, body)
  let scheme = call_606662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606662.url(scheme.get, call_606662.host, call_606662.base,
                         call_606662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606662, url, valid)

proc call*(call_606663: Call_UpdatePublishingDestination_606649;
          detectorId: string; destinationId: string; body: JsonNode): Recallable =
  ## updatePublishingDestination
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
  ##   detectorId: string (required)
  ##             : The ID of the 
  ##   destinationId: string (required)
  ##                : The ID of the detector associated with the publishing destinations to update.
  ##   body: JObject (required)
  var path_606664 = newJObject()
  var body_606665 = newJObject()
  add(path_606664, "detectorId", newJString(detectorId))
  add(path_606664, "destinationId", newJString(destinationId))
  if body != nil:
    body_606665 = body
  result = call_606663.call(path_606664, nil, nil, nil, body_606665)

var updatePublishingDestination* = Call_UpdatePublishingDestination_606649(
    name: "updatePublishingDestination", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_UpdatePublishingDestination_606650, base: "/",
    url: url_UpdatePublishingDestination_606651,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePublishingDestination_606634 = ref object of OpenApiRestCall_605589
proc url_DescribePublishingDestination_606636(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribePublishingDestination_606635(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector associated with the publishing destination to retrieve.
  ##   destinationId: JString (required)
  ##                : The ID of the publishing destination to retrieve.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_606637 = path.getOrDefault("detectorId")
  valid_606637 = validateParameter(valid_606637, JString, required = true,
                                 default = nil)
  if valid_606637 != nil:
    section.add "detectorId", valid_606637
  var valid_606638 = path.getOrDefault("destinationId")
  valid_606638 = validateParameter(valid_606638, JString, required = true,
                                 default = nil)
  if valid_606638 != nil:
    section.add "destinationId", valid_606638
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
  var valid_606639 = header.getOrDefault("X-Amz-Signature")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Signature", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Content-Sha256", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Date")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Date", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Credential")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Credential", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Security-Token")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Security-Token", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Algorithm")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Algorithm", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-SignedHeaders", valid_606645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606646: Call_DescribePublishingDestination_606634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
  ## 
  let valid = call_606646.validator(path, query, header, formData, body)
  let scheme = call_606646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606646.url(scheme.get, call_606646.host, call_606646.base,
                         call_606646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606646, url, valid)

proc call*(call_606647: Call_DescribePublishingDestination_606634;
          detectorId: string; destinationId: string): Recallable =
  ## describePublishingDestination
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the publishing destination to retrieve.
  ##   destinationId: string (required)
  ##                : The ID of the publishing destination to retrieve.
  var path_606648 = newJObject()
  add(path_606648, "detectorId", newJString(detectorId))
  add(path_606648, "destinationId", newJString(destinationId))
  result = call_606647.call(path_606648, nil, nil, nil, nil)

var describePublishingDestination* = Call_DescribePublishingDestination_606634(
    name: "describePublishingDestination", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_DescribePublishingDestination_606635, base: "/",
    url: url_DescribePublishingDestination_606636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublishingDestination_606666 = ref object of OpenApiRestCall_605589
proc url_DeletePublishingDestination_606668(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePublishingDestination_606667(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector associated with the publishing destination to delete.
  ##   destinationId: JString (required)
  ##                : The ID of the publishing destination to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_606669 = path.getOrDefault("detectorId")
  valid_606669 = validateParameter(valid_606669, JString, required = true,
                                 default = nil)
  if valid_606669 != nil:
    section.add "detectorId", valid_606669
  var valid_606670 = path.getOrDefault("destinationId")
  valid_606670 = validateParameter(valid_606670, JString, required = true,
                                 default = nil)
  if valid_606670 != nil:
    section.add "destinationId", valid_606670
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
  var valid_606671 = header.getOrDefault("X-Amz-Signature")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Signature", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Content-Sha256", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Date")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Date", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Credential")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Credential", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Security-Token")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Security-Token", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Algorithm")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Algorithm", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-SignedHeaders", valid_606677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606678: Call_DeletePublishingDestination_606666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
  ## 
  let valid = call_606678.validator(path, query, header, formData, body)
  let scheme = call_606678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606678.url(scheme.get, call_606678.host, call_606678.base,
                         call_606678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606678, url, valid)

proc call*(call_606679: Call_DeletePublishingDestination_606666;
          detectorId: string; destinationId: string): Recallable =
  ## deletePublishingDestination
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the publishing destination to delete.
  ##   destinationId: string (required)
  ##                : The ID of the publishing destination to delete.
  var path_606680 = newJObject()
  add(path_606680, "detectorId", newJString(detectorId))
  add(path_606680, "destinationId", newJString(destinationId))
  result = call_606679.call(path_606680, nil, nil, nil, nil)

var deletePublishingDestination* = Call_DeletePublishingDestination_606666(
    name: "deletePublishingDestination", meth: HttpMethod.HttpDelete,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_DeletePublishingDestination_606667, base: "/",
    url: url_DeletePublishingDestination_606668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateThreatIntelSet_606696 = ref object of OpenApiRestCall_605589
proc url_UpdateThreatIntelSet_606698(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateThreatIntelSet_606697(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The detectorID that specifies the GuardDuty service whose ThreatIntelSet you want to update.
  ##   threatIntelSetId: JString (required)
  ##                   : The unique ID that specifies the ThreatIntelSet that you want to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_606699 = path.getOrDefault("detectorId")
  valid_606699 = validateParameter(valid_606699, JString, required = true,
                                 default = nil)
  if valid_606699 != nil:
    section.add "detectorId", valid_606699
  var valid_606700 = path.getOrDefault("threatIntelSetId")
  valid_606700 = validateParameter(valid_606700, JString, required = true,
                                 default = nil)
  if valid_606700 != nil:
    section.add "threatIntelSetId", valid_606700
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
  var valid_606701 = header.getOrDefault("X-Amz-Signature")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-Signature", valid_606701
  var valid_606702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606702 = validateParameter(valid_606702, JString, required = false,
                                 default = nil)
  if valid_606702 != nil:
    section.add "X-Amz-Content-Sha256", valid_606702
  var valid_606703 = header.getOrDefault("X-Amz-Date")
  valid_606703 = validateParameter(valid_606703, JString, required = false,
                                 default = nil)
  if valid_606703 != nil:
    section.add "X-Amz-Date", valid_606703
  var valid_606704 = header.getOrDefault("X-Amz-Credential")
  valid_606704 = validateParameter(valid_606704, JString, required = false,
                                 default = nil)
  if valid_606704 != nil:
    section.add "X-Amz-Credential", valid_606704
  var valid_606705 = header.getOrDefault("X-Amz-Security-Token")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Security-Token", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Algorithm")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Algorithm", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-SignedHeaders", valid_606707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606709: Call_UpdateThreatIntelSet_606696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ## 
  let valid = call_606709.validator(path, query, header, formData, body)
  let scheme = call_606709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606709.url(scheme.get, call_606709.host, call_606709.base,
                         call_606709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606709, url, valid)

proc call*(call_606710: Call_UpdateThreatIntelSet_606696; detectorId: string;
          body: JsonNode; threatIntelSetId: string): Recallable =
  ## updateThreatIntelSet
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The detectorID that specifies the GuardDuty service whose ThreatIntelSet you want to update.
  ##   body: JObject (required)
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID that specifies the ThreatIntelSet that you want to update.
  var path_606711 = newJObject()
  var body_606712 = newJObject()
  add(path_606711, "detectorId", newJString(detectorId))
  if body != nil:
    body_606712 = body
  add(path_606711, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_606710.call(path_606711, nil, nil, nil, body_606712)

var updateThreatIntelSet* = Call_UpdateThreatIntelSet_606696(
    name: "updateThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_UpdateThreatIntelSet_606697, base: "/",
    url: url_UpdateThreatIntelSet_606698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThreatIntelSet_606681 = ref object of OpenApiRestCall_605589
proc url_GetThreatIntelSet_606683(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetThreatIntelSet_606682(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: JString (required)
  ##                   : The unique ID of the threatIntelSet you want to get.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_606684 = path.getOrDefault("detectorId")
  valid_606684 = validateParameter(valid_606684, JString, required = true,
                                 default = nil)
  if valid_606684 != nil:
    section.add "detectorId", valid_606684
  var valid_606685 = path.getOrDefault("threatIntelSetId")
  valid_606685 = validateParameter(valid_606685, JString, required = true,
                                 default = nil)
  if valid_606685 != nil:
    section.add "threatIntelSetId", valid_606685
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
  var valid_606686 = header.getOrDefault("X-Amz-Signature")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-Signature", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Content-Sha256", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Date")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Date", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Credential")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Credential", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Security-Token")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Security-Token", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Algorithm")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Algorithm", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-SignedHeaders", valid_606692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606693: Call_GetThreatIntelSet_606681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ## 
  let valid = call_606693.validator(path, query, header, formData, body)
  let scheme = call_606693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606693.url(scheme.get, call_606693.host, call_606693.base,
                         call_606693.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606693, url, valid)

proc call*(call_606694: Call_GetThreatIntelSet_606681; detectorId: string;
          threatIntelSetId: string): Recallable =
  ## getThreatIntelSet
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID of the threatIntelSet you want to get.
  var path_606695 = newJObject()
  add(path_606695, "detectorId", newJString(detectorId))
  add(path_606695, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_606694.call(path_606695, nil, nil, nil, nil)

var getThreatIntelSet* = Call_GetThreatIntelSet_606681(name: "getThreatIntelSet",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_GetThreatIntelSet_606682, base: "/",
    url: url_GetThreatIntelSet_606683, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteThreatIntelSet_606713 = ref object of OpenApiRestCall_605589
proc url_DeleteThreatIntelSet_606715(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteThreatIntelSet_606714(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: JString (required)
  ##                   : The unique ID of the threatIntelSet you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_606716 = path.getOrDefault("detectorId")
  valid_606716 = validateParameter(valid_606716, JString, required = true,
                                 default = nil)
  if valid_606716 != nil:
    section.add "detectorId", valid_606716
  var valid_606717 = path.getOrDefault("threatIntelSetId")
  valid_606717 = validateParameter(valid_606717, JString, required = true,
                                 default = nil)
  if valid_606717 != nil:
    section.add "threatIntelSetId", valid_606717
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
  var valid_606718 = header.getOrDefault("X-Amz-Signature")
  valid_606718 = validateParameter(valid_606718, JString, required = false,
                                 default = nil)
  if valid_606718 != nil:
    section.add "X-Amz-Signature", valid_606718
  var valid_606719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606719 = validateParameter(valid_606719, JString, required = false,
                                 default = nil)
  if valid_606719 != nil:
    section.add "X-Amz-Content-Sha256", valid_606719
  var valid_606720 = header.getOrDefault("X-Amz-Date")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Date", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Credential")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Credential", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Security-Token")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Security-Token", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Algorithm")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Algorithm", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-SignedHeaders", valid_606724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606725: Call_DeleteThreatIntelSet_606713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ## 
  let valid = call_606725.validator(path, query, header, formData, body)
  let scheme = call_606725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606725.url(scheme.get, call_606725.host, call_606725.base,
                         call_606725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606725, url, valid)

proc call*(call_606726: Call_DeleteThreatIntelSet_606713; detectorId: string;
          threatIntelSetId: string): Recallable =
  ## deleteThreatIntelSet
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID of the threatIntelSet you want to delete.
  var path_606727 = newJObject()
  add(path_606727, "detectorId", newJString(detectorId))
  add(path_606727, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_606726.call(path_606727, nil, nil, nil, nil)

var deleteThreatIntelSet* = Call_DeleteThreatIntelSet_606713(
    name: "deleteThreatIntelSet", meth: HttpMethod.HttpDelete,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_DeleteThreatIntelSet_606714, base: "/",
    url: url_DeleteThreatIntelSet_606715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_606728 = ref object of OpenApiRestCall_605589
proc url_DisassociateFromMasterAccount_606730(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateFromMasterAccount_606729(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606731 = path.getOrDefault("detectorId")
  valid_606731 = validateParameter(valid_606731, JString, required = true,
                                 default = nil)
  if valid_606731 != nil:
    section.add "detectorId", valid_606731
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
  if body != nil:
    result.add "body", body

proc call*(call_606739: Call_DisassociateFromMasterAccount_606728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current GuardDuty member account from its master account.
  ## 
  let valid = call_606739.validator(path, query, header, formData, body)
  let scheme = call_606739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606739.url(scheme.get, call_606739.host, call_606739.base,
                         call_606739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606739, url, valid)

proc call*(call_606740: Call_DisassociateFromMasterAccount_606728;
          detectorId: string): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current GuardDuty member account from its master account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  var path_606741 = newJObject()
  add(path_606741, "detectorId", newJString(detectorId))
  result = call_606740.call(path_606741, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_606728(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_606729, base: "/",
    url: url_DisassociateFromMasterAccount_606730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_606742 = ref object of OpenApiRestCall_605589
proc url_DisassociateMembers_606744(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateMembers_606743(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_606745 = path.getOrDefault("detectorId")
  valid_606745 = validateParameter(valid_606745, JString, required = true,
                                 default = nil)
  if valid_606745 != nil:
    section.add "detectorId", valid_606745
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
  var valid_606746 = header.getOrDefault("X-Amz-Signature")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Signature", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Content-Sha256", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Date")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Date", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Credential")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Credential", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Security-Token")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Security-Token", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-Algorithm")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-Algorithm", valid_606751
  var valid_606752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "X-Amz-SignedHeaders", valid_606752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606754: Call_DisassociateMembers_606742; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_606754.validator(path, query, header, formData, body)
  let scheme = call_606754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606754.url(scheme.get, call_606754.host, call_606754.base,
                         call_606754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606754, url, valid)

proc call*(call_606755: Call_DisassociateMembers_606742; detectorId: string;
          body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to disassociate from master.
  ##   body: JObject (required)
  var path_606756 = newJObject()
  var body_606757 = newJObject()
  add(path_606756, "detectorId", newJString(detectorId))
  if body != nil:
    body_606757 = body
  result = call_606755.call(path_606756, nil, nil, nil, body_606757)

var disassociateMembers* = Call_DisassociateMembers_606742(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/disassociate",
    validator: validate_DisassociateMembers_606743, base: "/",
    url: url_DisassociateMembers_606744, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_606758 = ref object of OpenApiRestCall_605589
proc url_GetFindings_606760(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFindings_606759(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606761 = path.getOrDefault("detectorId")
  valid_606761 = validateParameter(valid_606761, JString, required = true,
                                 default = nil)
  if valid_606761 != nil:
    section.add "detectorId", valid_606761
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

proc call*(call_606770: Call_GetFindings_606758; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes Amazon GuardDuty findings specified by finding IDs.
  ## 
  let valid = call_606770.validator(path, query, header, formData, body)
  let scheme = call_606770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606770.url(scheme.get, call_606770.host, call_606770.base,
                         call_606770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606770, url, valid)

proc call*(call_606771: Call_GetFindings_606758; detectorId: string; body: JsonNode): Recallable =
  ## getFindings
  ## Describes Amazon GuardDuty findings specified by finding IDs.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to retrieve.
  ##   body: JObject (required)
  var path_606772 = newJObject()
  var body_606773 = newJObject()
  add(path_606772, "detectorId", newJString(detectorId))
  if body != nil:
    body_606773 = body
  result = call_606771.call(path_606772, nil, nil, nil, body_606773)

var getFindings* = Call_GetFindings_606758(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/findings/get",
                                        validator: validate_GetFindings_606759,
                                        base: "/", url: url_GetFindings_606760,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindingsStatistics_606774 = ref object of OpenApiRestCall_605589
proc url_GetFindingsStatistics_606776(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFindingsStatistics_606775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606777 = path.getOrDefault("detectorId")
  valid_606777 = validateParameter(valid_606777, JString, required = true,
                                 default = nil)
  if valid_606777 != nil:
    section.add "detectorId", valid_606777
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
  var valid_606778 = header.getOrDefault("X-Amz-Signature")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Signature", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Content-Sha256", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Date")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Date", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Credential")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Credential", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Security-Token")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Security-Token", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-Algorithm")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Algorithm", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-SignedHeaders", valid_606784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606786: Call_GetFindingsStatistics_606774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
  ## 
  let valid = call_606786.validator(path, query, header, formData, body)
  let scheme = call_606786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606786.url(scheme.get, call_606786.host, call_606786.base,
                         call_606786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606786, url, valid)

proc call*(call_606787: Call_GetFindingsStatistics_606774; detectorId: string;
          body: JsonNode): Recallable =
  ## getFindingsStatistics
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings' statistics you want to retrieve.
  ##   body: JObject (required)
  var path_606788 = newJObject()
  var body_606789 = newJObject()
  add(path_606788, "detectorId", newJString(detectorId))
  if body != nil:
    body_606789 = body
  result = call_606787.call(path_606788, nil, nil, nil, body_606789)

var getFindingsStatistics* = Call_GetFindingsStatistics_606774(
    name: "getFindingsStatistics", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/statistics",
    validator: validate_GetFindingsStatistics_606775, base: "/",
    url: url_GetFindingsStatistics_606776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_606790 = ref object of OpenApiRestCall_605589
proc url_GetInvitationsCount_606792(protocol: Scheme; host: string; base: string;
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

proc validate_GetInvitationsCount_606791(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
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
  var valid_606793 = header.getOrDefault("X-Amz-Signature")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-Signature", valid_606793
  var valid_606794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Content-Sha256", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Date")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Date", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Credential")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Credential", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Security-Token")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Security-Token", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Algorithm")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Algorithm", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-SignedHeaders", valid_606799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606800: Call_GetInvitationsCount_606790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
  ## 
  let valid = call_606800.validator(path, query, header, formData, body)
  let scheme = call_606800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606800.url(scheme.get, call_606800.host, call_606800.base,
                         call_606800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606800, url, valid)

proc call*(call_606801: Call_GetInvitationsCount_606790): Recallable =
  ## getInvitationsCount
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
  result = call_606801.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_606790(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/invitation/count",
    validator: validate_GetInvitationsCount_606791, base: "/",
    url: url_GetInvitationsCount_606792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_606802 = ref object of OpenApiRestCall_605589
proc url_GetMembers_606804(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMembers_606803(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606805 = path.getOrDefault("detectorId")
  valid_606805 = validateParameter(valid_606805, JString, required = true,
                                 default = nil)
  if valid_606805 != nil:
    section.add "detectorId", valid_606805
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
  var valid_606806 = header.getOrDefault("X-Amz-Signature")
  valid_606806 = validateParameter(valid_606806, JString, required = false,
                                 default = nil)
  if valid_606806 != nil:
    section.add "X-Amz-Signature", valid_606806
  var valid_606807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606807 = validateParameter(valid_606807, JString, required = false,
                                 default = nil)
  if valid_606807 != nil:
    section.add "X-Amz-Content-Sha256", valid_606807
  var valid_606808 = header.getOrDefault("X-Amz-Date")
  valid_606808 = validateParameter(valid_606808, JString, required = false,
                                 default = nil)
  if valid_606808 != nil:
    section.add "X-Amz-Date", valid_606808
  var valid_606809 = header.getOrDefault("X-Amz-Credential")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Credential", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Security-Token")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Security-Token", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Algorithm")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Algorithm", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-SignedHeaders", valid_606812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606814: Call_GetMembers_606802; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_606814.validator(path, query, header, formData, body)
  let scheme = call_606814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606814.url(scheme.get, call_606814.host, call_606814.base,
                         call_606814.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606814, url, valid)

proc call*(call_606815: Call_GetMembers_606802; detectorId: string; body: JsonNode): Recallable =
  ## getMembers
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to retrieve.
  ##   body: JObject (required)
  var path_606816 = newJObject()
  var body_606817 = newJObject()
  add(path_606816, "detectorId", newJString(detectorId))
  if body != nil:
    body_606817 = body
  result = call_606815.call(path_606816, nil, nil, nil, body_606817)

var getMembers* = Call_GetMembers_606802(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/get",
                                      validator: validate_GetMembers_606803,
                                      base: "/", url: url_GetMembers_606804,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_606818 = ref object of OpenApiRestCall_605589
proc url_InviteMembers_606820(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InviteMembers_606819(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606821 = path.getOrDefault("detectorId")
  valid_606821 = validateParameter(valid_606821, JString, required = true,
                                 default = nil)
  if valid_606821 != nil:
    section.add "detectorId", valid_606821
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

proc call*(call_606830: Call_InviteMembers_606818; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
  ## 
  let valid = call_606830.validator(path, query, header, formData, body)
  let scheme = call_606830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606830.url(scheme.get, call_606830.host, call_606830.base,
                         call_606830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606830, url, valid)

proc call*(call_606831: Call_InviteMembers_606818; detectorId: string; body: JsonNode): Recallable =
  ## inviteMembers
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account with which you want to invite members.
  ##   body: JObject (required)
  var path_606832 = newJObject()
  var body_606833 = newJObject()
  add(path_606832, "detectorId", newJString(detectorId))
  if body != nil:
    body_606833 = body
  result = call_606831.call(path_606832, nil, nil, nil, body_606833)

var inviteMembers* = Call_InviteMembers_606818(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/invite",
    validator: validate_InviteMembers_606819, base: "/", url: url_InviteMembers_606820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_606834 = ref object of OpenApiRestCall_605589
proc url_ListFindings_606836(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFindings_606835(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606837 = path.getOrDefault("detectorId")
  valid_606837 = validateParameter(valid_606837, JString, required = true,
                                 default = nil)
  if valid_606837 != nil:
    section.add "detectorId", valid_606837
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606838 = query.getOrDefault("MaxResults")
  valid_606838 = validateParameter(valid_606838, JString, required = false,
                                 default = nil)
  if valid_606838 != nil:
    section.add "MaxResults", valid_606838
  var valid_606839 = query.getOrDefault("NextToken")
  valid_606839 = validateParameter(valid_606839, JString, required = false,
                                 default = nil)
  if valid_606839 != nil:
    section.add "NextToken", valid_606839
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
  var valid_606840 = header.getOrDefault("X-Amz-Signature")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "X-Amz-Signature", valid_606840
  var valid_606841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Content-Sha256", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Date")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Date", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Credential")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Credential", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Security-Token")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Security-Token", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Algorithm")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Algorithm", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-SignedHeaders", valid_606846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606848: Call_ListFindings_606834; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists Amazon GuardDuty findings for the specified detector ID.
  ## 
  let valid = call_606848.validator(path, query, header, formData, body)
  let scheme = call_606848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606848.url(scheme.get, call_606848.host, call_606848.base,
                         call_606848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606848, url, valid)

proc call*(call_606849: Call_ListFindings_606834; detectorId: string; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listFindings
  ## Lists Amazon GuardDuty findings for the specified detector ID.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to list.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var path_606850 = newJObject()
  var query_606851 = newJObject()
  var body_606852 = newJObject()
  add(query_606851, "MaxResults", newJString(MaxResults))
  add(path_606850, "detectorId", newJString(detectorId))
  add(query_606851, "NextToken", newJString(NextToken))
  if body != nil:
    body_606852 = body
  result = call_606849.call(path_606850, query_606851, nil, nil, body_606852)

var listFindings* = Call_ListFindings_606834(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings", validator: validate_ListFindings_606835,
    base: "/", url: url_ListFindings_606836, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_606853 = ref object of OpenApiRestCall_605589
proc url_ListInvitations_606855(protocol: Scheme; host: string; base: string;
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

proc validate_ListInvitations_606854(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists all GuardDuty membership invitations that were sent to the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  section = newJObject()
  var valid_606856 = query.getOrDefault("nextToken")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "nextToken", valid_606856
  var valid_606857 = query.getOrDefault("MaxResults")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "MaxResults", valid_606857
  var valid_606858 = query.getOrDefault("NextToken")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "NextToken", valid_606858
  var valid_606859 = query.getOrDefault("maxResults")
  valid_606859 = validateParameter(valid_606859, JInt, required = false, default = nil)
  if valid_606859 != nil:
    section.add "maxResults", valid_606859
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
  var valid_606860 = header.getOrDefault("X-Amz-Signature")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Signature", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Content-Sha256", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-Date")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-Date", valid_606862
  var valid_606863 = header.getOrDefault("X-Amz-Credential")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-Credential", valid_606863
  var valid_606864 = header.getOrDefault("X-Amz-Security-Token")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = nil)
  if valid_606864 != nil:
    section.add "X-Amz-Security-Token", valid_606864
  var valid_606865 = header.getOrDefault("X-Amz-Algorithm")
  valid_606865 = validateParameter(valid_606865, JString, required = false,
                                 default = nil)
  if valid_606865 != nil:
    section.add "X-Amz-Algorithm", valid_606865
  var valid_606866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606866 = validateParameter(valid_606866, JString, required = false,
                                 default = nil)
  if valid_606866 != nil:
    section.add "X-Amz-SignedHeaders", valid_606866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606867: Call_ListInvitations_606853; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all GuardDuty membership invitations that were sent to the current AWS account.
  ## 
  let valid = call_606867.validator(path, query, header, formData, body)
  let scheme = call_606867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606867.url(scheme.get, call_606867.host, call_606867.base,
                         call_606867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606867, url, valid)

proc call*(call_606868: Call_ListInvitations_606853; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listInvitations
  ## Lists all GuardDuty membership invitations that were sent to the current AWS account.
  ##   nextToken: string
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  var query_606869 = newJObject()
  add(query_606869, "nextToken", newJString(nextToken))
  add(query_606869, "MaxResults", newJString(MaxResults))
  add(query_606869, "NextToken", newJString(NextToken))
  add(query_606869, "maxResults", newJInt(maxResults))
  result = call_606868.call(nil, query_606869, nil, nil, nil)

var listInvitations* = Call_ListInvitations_606853(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com", route: "/invitation",
    validator: validate_ListInvitations_606854, base: "/", url: url_ListInvitations_606855,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606884 = ref object of OpenApiRestCall_605589
proc url_TagResource_606886(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_606885(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606887 = path.getOrDefault("resourceArn")
  valid_606887 = validateParameter(valid_606887, JString, required = true,
                                 default = nil)
  if valid_606887 != nil:
    section.add "resourceArn", valid_606887
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
  var valid_606888 = header.getOrDefault("X-Amz-Signature")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-Signature", valid_606888
  var valid_606889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606889 = validateParameter(valid_606889, JString, required = false,
                                 default = nil)
  if valid_606889 != nil:
    section.add "X-Amz-Content-Sha256", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Date")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Date", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Credential")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Credential", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-Security-Token")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-Security-Token", valid_606892
  var valid_606893 = header.getOrDefault("X-Amz-Algorithm")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "X-Amz-Algorithm", valid_606893
  var valid_606894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606894 = validateParameter(valid_606894, JString, required = false,
                                 default = nil)
  if valid_606894 != nil:
    section.add "X-Amz-SignedHeaders", valid_606894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606896: Call_TagResource_606884; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource.
  ## 
  let valid = call_606896.validator(path, query, header, formData, body)
  let scheme = call_606896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606896.url(scheme.get, call_606896.host, call_606896.base,
                         call_606896.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606896, url, valid)

proc call*(call_606897: Call_TagResource_606884; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the GuardDuty resource to apply a tag to.
  ##   body: JObject (required)
  var path_606898 = newJObject()
  var body_606899 = newJObject()
  add(path_606898, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_606899 = body
  result = call_606897.call(path_606898, nil, nil, nil, body_606899)

var tagResource* = Call_TagResource_606884(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_606885,
                                        base: "/", url: url_TagResource_606886,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606870 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606872(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_606871(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_606873 = path.getOrDefault("resourceArn")
  valid_606873 = validateParameter(valid_606873, JString, required = true,
                                 default = nil)
  if valid_606873 != nil:
    section.add "resourceArn", valid_606873
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
  var valid_606874 = header.getOrDefault("X-Amz-Signature")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Signature", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Content-Sha256", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Date")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Date", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Credential")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Credential", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-Security-Token")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-Security-Token", valid_606878
  var valid_606879 = header.getOrDefault("X-Amz-Algorithm")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-Algorithm", valid_606879
  var valid_606880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606880 = validateParameter(valid_606880, JString, required = false,
                                 default = nil)
  if valid_606880 != nil:
    section.add "X-Amz-SignedHeaders", valid_606880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606881: Call_ListTagsForResource_606870; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
  ## 
  let valid = call_606881.validator(path, query, header, formData, body)
  let scheme = call_606881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606881.url(scheme.get, call_606881.host, call_606881.base,
                         call_606881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606881, url, valid)

proc call*(call_606882: Call_ListTagsForResource_606870; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the given GuardDuty resource 
  var path_606883 = newJObject()
  add(path_606883, "resourceArn", newJString(resourceArn))
  result = call_606882.call(path_606883, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606870(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_606871, base: "/",
    url: url_ListTagsForResource_606872, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringMembers_606900 = ref object of OpenApiRestCall_605589
proc url_StartMonitoringMembers_606902(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartMonitoringMembers_606901(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606903 = path.getOrDefault("detectorId")
  valid_606903 = validateParameter(valid_606903, JString, required = true,
                                 default = nil)
  if valid_606903 != nil:
    section.add "detectorId", valid_606903
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
  var valid_606904 = header.getOrDefault("X-Amz-Signature")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-Signature", valid_606904
  var valid_606905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-Content-Sha256", valid_606905
  var valid_606906 = header.getOrDefault("X-Amz-Date")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "X-Amz-Date", valid_606906
  var valid_606907 = header.getOrDefault("X-Amz-Credential")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "X-Amz-Credential", valid_606907
  var valid_606908 = header.getOrDefault("X-Amz-Security-Token")
  valid_606908 = validateParameter(valid_606908, JString, required = false,
                                 default = nil)
  if valid_606908 != nil:
    section.add "X-Amz-Security-Token", valid_606908
  var valid_606909 = header.getOrDefault("X-Amz-Algorithm")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-Algorithm", valid_606909
  var valid_606910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "X-Amz-SignedHeaders", valid_606910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606912: Call_StartMonitoringMembers_606900; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Turns on GuardDuty monitoring of the specified member accounts. Use this operation to restart monitoring of accounts that you stopped monitoring with the <code>StopMonitoringMembers</code> operation.
  ## 
  let valid = call_606912.validator(path, query, header, formData, body)
  let scheme = call_606912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606912.url(scheme.get, call_606912.host, call_606912.base,
                         call_606912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606912, url, valid)

proc call*(call_606913: Call_StartMonitoringMembers_606900; detectorId: string;
          body: JsonNode): Recallable =
  ## startMonitoringMembers
  ## Turns on GuardDuty monitoring of the specified member accounts. Use this operation to restart monitoring of accounts that you stopped monitoring with the <code>StopMonitoringMembers</code> operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty master account associated with the member accounts to monitor.
  ##   body: JObject (required)
  var path_606914 = newJObject()
  var body_606915 = newJObject()
  add(path_606914, "detectorId", newJString(detectorId))
  if body != nil:
    body_606915 = body
  result = call_606913.call(path_606914, nil, nil, nil, body_606915)

var startMonitoringMembers* = Call_StartMonitoringMembers_606900(
    name: "startMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/start",
    validator: validate_StartMonitoringMembers_606901, base: "/",
    url: url_StartMonitoringMembers_606902, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringMembers_606916 = ref object of OpenApiRestCall_605589
proc url_StopMonitoringMembers_606918(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopMonitoringMembers_606917(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606919 = path.getOrDefault("detectorId")
  valid_606919 = validateParameter(valid_606919, JString, required = true,
                                 default = nil)
  if valid_606919 != nil:
    section.add "detectorId", valid_606919
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
  var valid_606920 = header.getOrDefault("X-Amz-Signature")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-Signature", valid_606920
  var valid_606921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Content-Sha256", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-Date")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-Date", valid_606922
  var valid_606923 = header.getOrDefault("X-Amz-Credential")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Credential", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-Security-Token")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-Security-Token", valid_606924
  var valid_606925 = header.getOrDefault("X-Amz-Algorithm")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "X-Amz-Algorithm", valid_606925
  var valid_606926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-SignedHeaders", valid_606926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606928: Call_StopMonitoringMembers_606916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops GuardDuty monitoring for the specified member accounnts. Use the <code>StartMonitoringMembers</code> to restart monitoring for those accounts.
  ## 
  let valid = call_606928.validator(path, query, header, formData, body)
  let scheme = call_606928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606928.url(scheme.get, call_606928.host, call_606928.base,
                         call_606928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606928, url, valid)

proc call*(call_606929: Call_StopMonitoringMembers_606916; detectorId: string;
          body: JsonNode): Recallable =
  ## stopMonitoringMembers
  ## Stops GuardDuty monitoring for the specified member accounnts. Use the <code>StartMonitoringMembers</code> to restart monitoring for those accounts.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account that you want to stop from monitor members' findings.
  ##   body: JObject (required)
  var path_606930 = newJObject()
  var body_606931 = newJObject()
  add(path_606930, "detectorId", newJString(detectorId))
  if body != nil:
    body_606931 = body
  result = call_606929.call(path_606930, nil, nil, nil, body_606931)

var stopMonitoringMembers* = Call_StopMonitoringMembers_606916(
    name: "stopMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/stop",
    validator: validate_StopMonitoringMembers_606917, base: "/",
    url: url_StopMonitoringMembers_606918, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnarchiveFindings_606932 = ref object of OpenApiRestCall_605589
proc url_UnarchiveFindings_606934(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UnarchiveFindings_606933(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_606935 = path.getOrDefault("detectorId")
  valid_606935 = validateParameter(valid_606935, JString, required = true,
                                 default = nil)
  if valid_606935 != nil:
    section.add "detectorId", valid_606935
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
  var valid_606936 = header.getOrDefault("X-Amz-Signature")
  valid_606936 = validateParameter(valid_606936, JString, required = false,
                                 default = nil)
  if valid_606936 != nil:
    section.add "X-Amz-Signature", valid_606936
  var valid_606937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "X-Amz-Content-Sha256", valid_606937
  var valid_606938 = header.getOrDefault("X-Amz-Date")
  valid_606938 = validateParameter(valid_606938, JString, required = false,
                                 default = nil)
  if valid_606938 != nil:
    section.add "X-Amz-Date", valid_606938
  var valid_606939 = header.getOrDefault("X-Amz-Credential")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "X-Amz-Credential", valid_606939
  var valid_606940 = header.getOrDefault("X-Amz-Security-Token")
  valid_606940 = validateParameter(valid_606940, JString, required = false,
                                 default = nil)
  if valid_606940 != nil:
    section.add "X-Amz-Security-Token", valid_606940
  var valid_606941 = header.getOrDefault("X-Amz-Algorithm")
  valid_606941 = validateParameter(valid_606941, JString, required = false,
                                 default = nil)
  if valid_606941 != nil:
    section.add "X-Amz-Algorithm", valid_606941
  var valid_606942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "X-Amz-SignedHeaders", valid_606942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606944: Call_UnarchiveFindings_606932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Unarchives GuardDuty findings specified by the <code>findingIds</code>.
  ## 
  let valid = call_606944.validator(path, query, header, formData, body)
  let scheme = call_606944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606944.url(scheme.get, call_606944.host, call_606944.base,
                         call_606944.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606944, url, valid)

proc call*(call_606945: Call_UnarchiveFindings_606932; detectorId: string;
          body: JsonNode): Recallable =
  ## unarchiveFindings
  ## Unarchives GuardDuty findings specified by the <code>findingIds</code>.
  ##   detectorId: string (required)
  ##             : The ID of the detector associated with the findings to unarchive.
  ##   body: JObject (required)
  var path_606946 = newJObject()
  var body_606947 = newJObject()
  add(path_606946, "detectorId", newJString(detectorId))
  if body != nil:
    body_606947 = body
  result = call_606945.call(path_606946, nil, nil, nil, body_606947)

var unarchiveFindings* = Call_UnarchiveFindings_606932(name: "unarchiveFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/unarchive",
    validator: validate_UnarchiveFindings_606933, base: "/",
    url: url_UnarchiveFindings_606934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606948 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606950(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_606949(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606951 = path.getOrDefault("resourceArn")
  valid_606951 = validateParameter(valid_606951, JString, required = true,
                                 default = nil)
  if valid_606951 != nil:
    section.add "resourceArn", valid_606951
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606952 = query.getOrDefault("tagKeys")
  valid_606952 = validateParameter(valid_606952, JArray, required = true, default = nil)
  if valid_606952 != nil:
    section.add "tagKeys", valid_606952
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
  var valid_606953 = header.getOrDefault("X-Amz-Signature")
  valid_606953 = validateParameter(valid_606953, JString, required = false,
                                 default = nil)
  if valid_606953 != nil:
    section.add "X-Amz-Signature", valid_606953
  var valid_606954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "X-Amz-Content-Sha256", valid_606954
  var valid_606955 = header.getOrDefault("X-Amz-Date")
  valid_606955 = validateParameter(valid_606955, JString, required = false,
                                 default = nil)
  if valid_606955 != nil:
    section.add "X-Amz-Date", valid_606955
  var valid_606956 = header.getOrDefault("X-Amz-Credential")
  valid_606956 = validateParameter(valid_606956, JString, required = false,
                                 default = nil)
  if valid_606956 != nil:
    section.add "X-Amz-Credential", valid_606956
  var valid_606957 = header.getOrDefault("X-Amz-Security-Token")
  valid_606957 = validateParameter(valid_606957, JString, required = false,
                                 default = nil)
  if valid_606957 != nil:
    section.add "X-Amz-Security-Token", valid_606957
  var valid_606958 = header.getOrDefault("X-Amz-Algorithm")
  valid_606958 = validateParameter(valid_606958, JString, required = false,
                                 default = nil)
  if valid_606958 != nil:
    section.add "X-Amz-Algorithm", valid_606958
  var valid_606959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-SignedHeaders", valid_606959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606960: Call_UntagResource_606948; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_606960.validator(path, query, header, formData, body)
  let scheme = call_606960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606960.url(scheme.get, call_606960.host, call_606960.base,
                         call_606960.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606960, url, valid)

proc call*(call_606961: Call_UntagResource_606948; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the resource to remove tags from.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the resource.
  var path_606962 = newJObject()
  var query_606963 = newJObject()
  add(path_606962, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_606963.add "tagKeys", tagKeys
  result = call_606961.call(path_606962, query_606963, nil, nil, nil)

var untagResource* = Call_UntagResource_606948(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_606949,
    base: "/", url: url_UntagResource_606950, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindingsFeedback_606964 = ref object of OpenApiRestCall_605589
proc url_UpdateFindingsFeedback_606966(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFindingsFeedback_606965(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606967 = path.getOrDefault("detectorId")
  valid_606967 = validateParameter(valid_606967, JString, required = true,
                                 default = nil)
  if valid_606967 != nil:
    section.add "detectorId", valid_606967
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
  var valid_606968 = header.getOrDefault("X-Amz-Signature")
  valid_606968 = validateParameter(valid_606968, JString, required = false,
                                 default = nil)
  if valid_606968 != nil:
    section.add "X-Amz-Signature", valid_606968
  var valid_606969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606969 = validateParameter(valid_606969, JString, required = false,
                                 default = nil)
  if valid_606969 != nil:
    section.add "X-Amz-Content-Sha256", valid_606969
  var valid_606970 = header.getOrDefault("X-Amz-Date")
  valid_606970 = validateParameter(valid_606970, JString, required = false,
                                 default = nil)
  if valid_606970 != nil:
    section.add "X-Amz-Date", valid_606970
  var valid_606971 = header.getOrDefault("X-Amz-Credential")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "X-Amz-Credential", valid_606971
  var valid_606972 = header.getOrDefault("X-Amz-Security-Token")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "X-Amz-Security-Token", valid_606972
  var valid_606973 = header.getOrDefault("X-Amz-Algorithm")
  valid_606973 = validateParameter(valid_606973, JString, required = false,
                                 default = nil)
  if valid_606973 != nil:
    section.add "X-Amz-Algorithm", valid_606973
  var valid_606974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "X-Amz-SignedHeaders", valid_606974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606976: Call_UpdateFindingsFeedback_606964; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Marks the specified GuardDuty findings as useful or not useful.
  ## 
  let valid = call_606976.validator(path, query, header, formData, body)
  let scheme = call_606976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606976.url(scheme.get, call_606976.host, call_606976.base,
                         call_606976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606976, url, valid)

proc call*(call_606977: Call_UpdateFindingsFeedback_606964; detectorId: string;
          body: JsonNode): Recallable =
  ## updateFindingsFeedback
  ## Marks the specified GuardDuty findings as useful or not useful.
  ##   detectorId: string (required)
  ##             : The ID of the detector associated with the findings to update feedback for.
  ##   body: JObject (required)
  var path_606978 = newJObject()
  var body_606979 = newJObject()
  add(path_606978, "detectorId", newJString(detectorId))
  if body != nil:
    body_606979 = body
  result = call_606977.call(path_606978, nil, nil, nil, body_606979)

var updateFindingsFeedback* = Call_UpdateFindingsFeedback_606964(
    name: "updateFindingsFeedback", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/feedback",
    validator: validate_UpdateFindingsFeedback_606965, base: "/",
    url: url_UpdateFindingsFeedback_606966, schemes: {Scheme.Https, Scheme.Http})
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
