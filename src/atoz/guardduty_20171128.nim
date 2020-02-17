
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  Call_AcceptInvitation_611266 = ref object of OpenApiRestCall_610658
proc url_AcceptInvitation_611268(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AcceptInvitation_611267(path: JsonNode; query: JsonNode;
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
  var valid_611269 = path.getOrDefault("detectorId")
  valid_611269 = validateParameter(valid_611269, JString, required = true,
                                 default = nil)
  if valid_611269 != nil:
    section.add "detectorId", valid_611269
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
  var valid_611270 = header.getOrDefault("X-Amz-Signature")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Signature", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Content-Sha256", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Date")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Date", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Credential")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Credential", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Security-Token")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Security-Token", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Algorithm")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Algorithm", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-SignedHeaders", valid_611276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611278: Call_AcceptInvitation_611266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts the invitation to be monitored by a master GuardDuty account.
  ## 
  let valid = call_611278.validator(path, query, header, formData, body)
  let scheme = call_611278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611278.url(scheme.get, call_611278.host, call_611278.base,
                         call_611278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611278, url, valid)

proc call*(call_611279: Call_AcceptInvitation_611266; detectorId: string;
          body: JsonNode): Recallable =
  ## acceptInvitation
  ## Accepts the invitation to be monitored by a master GuardDuty account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  ##   body: JObject (required)
  var path_611280 = newJObject()
  var body_611281 = newJObject()
  add(path_611280, "detectorId", newJString(detectorId))
  if body != nil:
    body_611281 = body
  result = call_611279.call(path_611280, nil, nil, nil, body_611281)

var acceptInvitation* = Call_AcceptInvitation_611266(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master", validator: validate_AcceptInvitation_611267,
    base: "/", url: url_AcceptInvitation_611268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_610996 = ref object of OpenApiRestCall_610658
proc url_GetMasterAccount_610998(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMasterAccount_610997(path: JsonNode; query: JsonNode;
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
  var valid_611124 = path.getOrDefault("detectorId")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "detectorId", valid_611124
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
  var valid_611125 = header.getOrDefault("X-Amz-Signature")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Signature", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Content-Sha256", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Date")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Date", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Credential")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Credential", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Security-Token")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Security-Token", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Algorithm")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Algorithm", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-SignedHeaders", valid_611131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_GetMasterAccount_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_GetMasterAccount_610996; detectorId: string): Recallable =
  ## getMasterAccount
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  var path_611226 = newJObject()
  add(path_611226, "detectorId", newJString(detectorId))
  result = call_611225.call(path_611226, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_610996(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master", validator: validate_GetMasterAccount_610997,
    base: "/", url: url_GetMasterAccount_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ArchiveFindings_611282 = ref object of OpenApiRestCall_610658
proc url_ArchiveFindings_611284(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ArchiveFindings_611283(path: JsonNode; query: JsonNode;
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
  var valid_611285 = path.getOrDefault("detectorId")
  valid_611285 = validateParameter(valid_611285, JString, required = true,
                                 default = nil)
  if valid_611285 != nil:
    section.add "detectorId", valid_611285
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
  var valid_611286 = header.getOrDefault("X-Amz-Signature")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Signature", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Content-Sha256", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Date")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Date", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Credential")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Credential", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Security-Token")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Security-Token", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Algorithm")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Algorithm", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-SignedHeaders", valid_611292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611294: Call_ArchiveFindings_611282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
  ## 
  let valid = call_611294.validator(path, query, header, formData, body)
  let scheme = call_611294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611294.url(scheme.get, call_611294.host, call_611294.base,
                         call_611294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611294, url, valid)

proc call*(call_611295: Call_ArchiveFindings_611282; detectorId: string;
          body: JsonNode): Recallable =
  ## archiveFindings
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to archive.
  ##   body: JObject (required)
  var path_611296 = newJObject()
  var body_611297 = newJObject()
  add(path_611296, "detectorId", newJString(detectorId))
  if body != nil:
    body_611297 = body
  result = call_611295.call(path_611296, nil, nil, nil, body_611297)

var archiveFindings* = Call_ArchiveFindings_611282(name: "archiveFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/archive",
    validator: validate_ArchiveFindings_611283, base: "/", url: url_ArchiveFindings_611284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDetector_611315 = ref object of OpenApiRestCall_610658
proc url_CreateDetector_611317(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDetector_611316(path: JsonNode; query: JsonNode;
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
  var valid_611318 = header.getOrDefault("X-Amz-Signature")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Signature", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Content-Sha256", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Date")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Date", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Credential")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Credential", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-Security-Token")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Security-Token", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-Algorithm")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Algorithm", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-SignedHeaders", valid_611324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611326: Call_CreateDetector_611315; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
  ## 
  let valid = call_611326.validator(path, query, header, formData, body)
  let scheme = call_611326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611326.url(scheme.get, call_611326.host, call_611326.base,
                         call_611326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611326, url, valid)

proc call*(call_611327: Call_CreateDetector_611315; body: JsonNode): Recallable =
  ## createDetector
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
  ##   body: JObject (required)
  var body_611328 = newJObject()
  if body != nil:
    body_611328 = body
  result = call_611327.call(nil, nil, nil, nil, body_611328)

var createDetector* = Call_CreateDetector_611315(name: "createDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com", route: "/detector",
    validator: validate_CreateDetector_611316, base: "/", url: url_CreateDetector_611317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectors_611298 = ref object of OpenApiRestCall_610658
proc url_ListDetectors_611300(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDetectors_611299(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611301 = query.getOrDefault("nextToken")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "nextToken", valid_611301
  var valid_611302 = query.getOrDefault("MaxResults")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "MaxResults", valid_611302
  var valid_611303 = query.getOrDefault("NextToken")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "NextToken", valid_611303
  var valid_611304 = query.getOrDefault("maxResults")
  valid_611304 = validateParameter(valid_611304, JInt, required = false, default = nil)
  if valid_611304 != nil:
    section.add "maxResults", valid_611304
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
  var valid_611305 = header.getOrDefault("X-Amz-Signature")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Signature", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Content-Sha256", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-Date")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Date", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Credential")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Credential", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Security-Token")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Security-Token", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Algorithm")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Algorithm", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-SignedHeaders", valid_611311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611312: Call_ListDetectors_611298; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists detectorIds of all the existing Amazon GuardDuty detector resources.
  ## 
  let valid = call_611312.validator(path, query, header, formData, body)
  let scheme = call_611312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611312.url(scheme.get, call_611312.host, call_611312.base,
                         call_611312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611312, url, valid)

proc call*(call_611313: Call_ListDetectors_611298; nextToken: string = "";
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
  var query_611314 = newJObject()
  add(query_611314, "nextToken", newJString(nextToken))
  add(query_611314, "MaxResults", newJString(MaxResults))
  add(query_611314, "NextToken", newJString(NextToken))
  add(query_611314, "maxResults", newJInt(maxResults))
  result = call_611313.call(nil, query_611314, nil, nil, nil)

var listDetectors* = Call_ListDetectors_611298(name: "listDetectors",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com", route: "/detector",
    validator: validate_ListDetectors_611299, base: "/", url: url_ListDetectors_611300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFilter_611348 = ref object of OpenApiRestCall_610658
proc url_CreateFilter_611350(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFilter_611349(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611351 = path.getOrDefault("detectorId")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = nil)
  if valid_611351 != nil:
    section.add "detectorId", valid_611351
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
  var valid_611352 = header.getOrDefault("X-Amz-Signature")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Signature", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Content-Sha256", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Date")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Date", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Credential")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Credential", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Security-Token")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Security-Token", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Algorithm")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Algorithm", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-SignedHeaders", valid_611358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611360: Call_CreateFilter_611348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a filter using the specified finding criteria.
  ## 
  let valid = call_611360.validator(path, query, header, formData, body)
  let scheme = call_611360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611360.url(scheme.get, call_611360.host, call_611360.base,
                         call_611360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611360, url, valid)

proc call*(call_611361: Call_CreateFilter_611348; detectorId: string; body: JsonNode): Recallable =
  ## createFilter
  ## Creates a filter using the specified finding criteria.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create a filter.
  ##   body: JObject (required)
  var path_611362 = newJObject()
  var body_611363 = newJObject()
  add(path_611362, "detectorId", newJString(detectorId))
  if body != nil:
    body_611363 = body
  result = call_611361.call(path_611362, nil, nil, nil, body_611363)

var createFilter* = Call_CreateFilter_611348(name: "createFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter", validator: validate_CreateFilter_611349,
    base: "/", url: url_CreateFilter_611350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFilters_611329 = ref object of OpenApiRestCall_610658
proc url_ListFilters_611331(protocol: Scheme; host: string; base: string;
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

proc validate_ListFilters_611330(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611332 = path.getOrDefault("detectorId")
  valid_611332 = validateParameter(valid_611332, JString, required = true,
                                 default = nil)
  if valid_611332 != nil:
    section.add "detectorId", valid_611332
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
  var valid_611333 = query.getOrDefault("nextToken")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "nextToken", valid_611333
  var valid_611334 = query.getOrDefault("MaxResults")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "MaxResults", valid_611334
  var valid_611335 = query.getOrDefault("NextToken")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "NextToken", valid_611335
  var valid_611336 = query.getOrDefault("maxResults")
  valid_611336 = validateParameter(valid_611336, JInt, required = false, default = nil)
  if valid_611336 != nil:
    section.add "maxResults", valid_611336
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
  var valid_611337 = header.getOrDefault("X-Amz-Signature")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Signature", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Content-Sha256", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Date")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Date", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Credential")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Credential", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Security-Token")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Security-Token", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Algorithm")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Algorithm", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-SignedHeaders", valid_611343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611344: Call_ListFilters_611329; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of the current filters.
  ## 
  let valid = call_611344.validator(path, query, header, formData, body)
  let scheme = call_611344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611344.url(scheme.get, call_611344.host, call_611344.base,
                         call_611344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611344, url, valid)

proc call*(call_611345: Call_ListFilters_611329; detectorId: string;
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
  var path_611346 = newJObject()
  var query_611347 = newJObject()
  add(query_611347, "nextToken", newJString(nextToken))
  add(query_611347, "MaxResults", newJString(MaxResults))
  add(path_611346, "detectorId", newJString(detectorId))
  add(query_611347, "NextToken", newJString(NextToken))
  add(query_611347, "maxResults", newJInt(maxResults))
  result = call_611345.call(path_611346, query_611347, nil, nil, nil)

var listFilters* = Call_ListFilters_611329(name: "listFilters",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/filter",
                                        validator: validate_ListFilters_611330,
                                        base: "/", url: url_ListFilters_611331,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIPSet_611383 = ref object of OpenApiRestCall_610658
proc url_CreateIPSet_611385(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIPSet_611384(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611386 = path.getOrDefault("detectorId")
  valid_611386 = validateParameter(valid_611386, JString, required = true,
                                 default = nil)
  if valid_611386 != nil:
    section.add "detectorId", valid_611386
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
  var valid_611387 = header.getOrDefault("X-Amz-Signature")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Signature", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Content-Sha256", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Date")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Date", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Credential")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Credential", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Security-Token")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Security-Token", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Algorithm")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Algorithm", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-SignedHeaders", valid_611393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611395: Call_CreateIPSet_611383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new IPSet, called Trusted IP list in the consoler user interface. An IPSet is a list IP addresses trusted for secure communication with AWS infrastructure and applications. GuardDuty does not generate findings for IP addresses included in IPSets. Only users from the master account can use this operation.
  ## 
  let valid = call_611395.validator(path, query, header, formData, body)
  let scheme = call_611395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611395.url(scheme.get, call_611395.host, call_611395.base,
                         call_611395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611395, url, valid)

proc call*(call_611396: Call_CreateIPSet_611383; detectorId: string; body: JsonNode): Recallable =
  ## createIPSet
  ## Creates a new IPSet, called Trusted IP list in the consoler user interface. An IPSet is a list IP addresses trusted for secure communication with AWS infrastructure and applications. GuardDuty does not generate findings for IP addresses included in IPSets. Only users from the master account can use this operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create an IPSet.
  ##   body: JObject (required)
  var path_611397 = newJObject()
  var body_611398 = newJObject()
  add(path_611397, "detectorId", newJString(detectorId))
  if body != nil:
    body_611398 = body
  result = call_611396.call(path_611397, nil, nil, nil, body_611398)

var createIPSet* = Call_CreateIPSet_611383(name: "createIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/ipset",
                                        validator: validate_CreateIPSet_611384,
                                        base: "/", url: url_CreateIPSet_611385,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIPSets_611364 = ref object of OpenApiRestCall_610658
proc url_ListIPSets_611366(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIPSets_611365(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611367 = path.getOrDefault("detectorId")
  valid_611367 = validateParameter(valid_611367, JString, required = true,
                                 default = nil)
  if valid_611367 != nil:
    section.add "detectorId", valid_611367
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
  var valid_611368 = query.getOrDefault("nextToken")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "nextToken", valid_611368
  var valid_611369 = query.getOrDefault("MaxResults")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "MaxResults", valid_611369
  var valid_611370 = query.getOrDefault("NextToken")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "NextToken", valid_611370
  var valid_611371 = query.getOrDefault("maxResults")
  valid_611371 = validateParameter(valid_611371, JInt, required = false, default = nil)
  if valid_611371 != nil:
    section.add "maxResults", valid_611371
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
  var valid_611372 = header.getOrDefault("X-Amz-Signature")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Signature", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Content-Sha256", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Date")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Date", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Credential")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Credential", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Security-Token")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Security-Token", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Algorithm")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Algorithm", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-SignedHeaders", valid_611378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611379: Call_ListIPSets_611364; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the IPSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the IPSets returned are the IPSets from the associated master account.
  ## 
  let valid = call_611379.validator(path, query, header, formData, body)
  let scheme = call_611379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611379.url(scheme.get, call_611379.host, call_611379.base,
                         call_611379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611379, url, valid)

proc call*(call_611380: Call_ListIPSets_611364; detectorId: string;
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
  var path_611381 = newJObject()
  var query_611382 = newJObject()
  add(query_611382, "nextToken", newJString(nextToken))
  add(query_611382, "MaxResults", newJString(MaxResults))
  add(path_611381, "detectorId", newJString(detectorId))
  add(query_611382, "NextToken", newJString(NextToken))
  add(query_611382, "maxResults", newJInt(maxResults))
  result = call_611380.call(path_611381, query_611382, nil, nil, nil)

var listIPSets* = Call_ListIPSets_611364(name: "listIPSets",
                                      meth: HttpMethod.HttpGet,
                                      host: "guardduty.amazonaws.com",
                                      route: "/detector/{detectorId}/ipset",
                                      validator: validate_ListIPSets_611365,
                                      base: "/", url: url_ListIPSets_611366,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_611419 = ref object of OpenApiRestCall_610658
proc url_CreateMembers_611421(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMembers_611420(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611422 = path.getOrDefault("detectorId")
  valid_611422 = validateParameter(valid_611422, JString, required = true,
                                 default = nil)
  if valid_611422 != nil:
    section.add "detectorId", valid_611422
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
  var valid_611423 = header.getOrDefault("X-Amz-Signature")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Signature", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Content-Sha256", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Date")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Date", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Credential")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Credential", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-Security-Token")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Security-Token", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Algorithm")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Algorithm", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-SignedHeaders", valid_611429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611431: Call_CreateMembers_611419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
  ## 
  let valid = call_611431.validator(path, query, header, formData, body)
  let scheme = call_611431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611431.url(scheme.get, call_611431.host, call_611431.base,
                         call_611431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611431, url, valid)

proc call*(call_611432: Call_CreateMembers_611419; detectorId: string; body: JsonNode): Recallable =
  ## createMembers
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account with which you want to associate member accounts.
  ##   body: JObject (required)
  var path_611433 = newJObject()
  var body_611434 = newJObject()
  add(path_611433, "detectorId", newJString(detectorId))
  if body != nil:
    body_611434 = body
  result = call_611432.call(path_611433, nil, nil, nil, body_611434)

var createMembers* = Call_CreateMembers_611419(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member", validator: validate_CreateMembers_611420,
    base: "/", url: url_CreateMembers_611421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_611399 = ref object of OpenApiRestCall_610658
proc url_ListMembers_611401(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_611400(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611402 = path.getOrDefault("detectorId")
  valid_611402 = validateParameter(valid_611402, JString, required = true,
                                 default = nil)
  if valid_611402 != nil:
    section.add "detectorId", valid_611402
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
  var valid_611403 = query.getOrDefault("nextToken")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "nextToken", valid_611403
  var valid_611404 = query.getOrDefault("MaxResults")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "MaxResults", valid_611404
  var valid_611405 = query.getOrDefault("NextToken")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "NextToken", valid_611405
  var valid_611406 = query.getOrDefault("onlyAssociated")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "onlyAssociated", valid_611406
  var valid_611407 = query.getOrDefault("maxResults")
  valid_611407 = validateParameter(valid_611407, JInt, required = false, default = nil)
  if valid_611407 != nil:
    section.add "maxResults", valid_611407
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
  var valid_611408 = header.getOrDefault("X-Amz-Signature")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Signature", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Content-Sha256", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Date")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Date", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Credential")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Credential", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Security-Token")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Security-Token", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Algorithm")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Algorithm", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-SignedHeaders", valid_611414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611415: Call_ListMembers_611399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current GuardDuty master account.
  ## 
  let valid = call_611415.validator(path, query, header, formData, body)
  let scheme = call_611415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611415.url(scheme.get, call_611415.host, call_611415.base,
                         call_611415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611415, url, valid)

proc call*(call_611416: Call_ListMembers_611399; detectorId: string;
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
  var path_611417 = newJObject()
  var query_611418 = newJObject()
  add(query_611418, "nextToken", newJString(nextToken))
  add(query_611418, "MaxResults", newJString(MaxResults))
  add(path_611417, "detectorId", newJString(detectorId))
  add(query_611418, "NextToken", newJString(NextToken))
  add(query_611418, "onlyAssociated", newJString(onlyAssociated))
  add(query_611418, "maxResults", newJInt(maxResults))
  result = call_611416.call(path_611417, query_611418, nil, nil, nil)

var listMembers* = Call_ListMembers_611399(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/member",
                                        validator: validate_ListMembers_611400,
                                        base: "/", url: url_ListMembers_611401,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublishingDestination_611454 = ref object of OpenApiRestCall_610658
proc url_CreatePublishingDestination_611456(protocol: Scheme; host: string;
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

proc validate_CreatePublishingDestination_611455(path: JsonNode; query: JsonNode;
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
  var valid_611457 = path.getOrDefault("detectorId")
  valid_611457 = validateParameter(valid_611457, JString, required = true,
                                 default = nil)
  if valid_611457 != nil:
    section.add "detectorId", valid_611457
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
  var valid_611458 = header.getOrDefault("X-Amz-Signature")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Signature", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Content-Sha256", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-Date")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Date", valid_611460
  var valid_611461 = header.getOrDefault("X-Amz-Credential")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Credential", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-Security-Token")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Security-Token", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-Algorithm")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Algorithm", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-SignedHeaders", valid_611464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611466: Call_CreatePublishingDestination_611454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a publishing destination to send findings to. The resource to send findings to must exist before you use this operation.
  ## 
  let valid = call_611466.validator(path, query, header, formData, body)
  let scheme = call_611466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611466.url(scheme.get, call_611466.host, call_611466.base,
                         call_611466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611466, url, valid)

proc call*(call_611467: Call_CreatePublishingDestination_611454;
          detectorId: string; body: JsonNode): Recallable =
  ## createPublishingDestination
  ## Creates a publishing destination to send findings to. The resource to send findings to must exist before you use this operation.
  ##   detectorId: string (required)
  ##             : The ID of the GuardDuty detector associated with the publishing destination.
  ##   body: JObject (required)
  var path_611468 = newJObject()
  var body_611469 = newJObject()
  add(path_611468, "detectorId", newJString(detectorId))
  if body != nil:
    body_611469 = body
  result = call_611467.call(path_611468, nil, nil, nil, body_611469)

var createPublishingDestination* = Call_CreatePublishingDestination_611454(
    name: "createPublishingDestination", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination",
    validator: validate_CreatePublishingDestination_611455, base: "/",
    url: url_CreatePublishingDestination_611456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishingDestinations_611435 = ref object of OpenApiRestCall_610658
proc url_ListPublishingDestinations_611437(protocol: Scheme; host: string;
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

proc validate_ListPublishingDestinations_611436(path: JsonNode; query: JsonNode;
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
  var valid_611438 = path.getOrDefault("detectorId")
  valid_611438 = validateParameter(valid_611438, JString, required = true,
                                 default = nil)
  if valid_611438 != nil:
    section.add "detectorId", valid_611438
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
  var valid_611439 = query.getOrDefault("nextToken")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "nextToken", valid_611439
  var valid_611440 = query.getOrDefault("MaxResults")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "MaxResults", valid_611440
  var valid_611441 = query.getOrDefault("NextToken")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "NextToken", valid_611441
  var valid_611442 = query.getOrDefault("maxResults")
  valid_611442 = validateParameter(valid_611442, JInt, required = false, default = nil)
  if valid_611442 != nil:
    section.add "maxResults", valid_611442
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
  var valid_611443 = header.getOrDefault("X-Amz-Signature")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-Signature", valid_611443
  var valid_611444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Content-Sha256", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Date")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Date", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Credential")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Credential", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Security-Token")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Security-Token", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Algorithm")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Algorithm", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-SignedHeaders", valid_611449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611450: Call_ListPublishingDestinations_611435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of publishing destinations associated with the specified <code>dectectorId</code>.
  ## 
  let valid = call_611450.validator(path, query, header, formData, body)
  let scheme = call_611450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611450.url(scheme.get, call_611450.host, call_611450.base,
                         call_611450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611450, url, valid)

proc call*(call_611451: Call_ListPublishingDestinations_611435; detectorId: string;
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
  var path_611452 = newJObject()
  var query_611453 = newJObject()
  add(query_611453, "nextToken", newJString(nextToken))
  add(query_611453, "MaxResults", newJString(MaxResults))
  add(path_611452, "detectorId", newJString(detectorId))
  add(query_611453, "NextToken", newJString(NextToken))
  add(query_611453, "maxResults", newJInt(maxResults))
  result = call_611451.call(path_611452, query_611453, nil, nil, nil)

var listPublishingDestinations* = Call_ListPublishingDestinations_611435(
    name: "listPublishingDestinations", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination",
    validator: validate_ListPublishingDestinations_611436, base: "/",
    url: url_ListPublishingDestinations_611437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSampleFindings_611470 = ref object of OpenApiRestCall_610658
proc url_CreateSampleFindings_611472(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSampleFindings_611471(path: JsonNode; query: JsonNode;
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
  var valid_611473 = path.getOrDefault("detectorId")
  valid_611473 = validateParameter(valid_611473, JString, required = true,
                                 default = nil)
  if valid_611473 != nil:
    section.add "detectorId", valid_611473
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
  var valid_611474 = header.getOrDefault("X-Amz-Signature")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Signature", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Content-Sha256", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Date")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Date", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Credential")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Credential", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Security-Token")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Security-Token", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Algorithm")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Algorithm", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-SignedHeaders", valid_611480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611482: Call_CreateSampleFindings_611470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for <code>findingTypes</code>, the API generates example findings of all supported finding types.
  ## 
  let valid = call_611482.validator(path, query, header, formData, body)
  let scheme = call_611482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611482.url(scheme.get, call_611482.host, call_611482.base,
                         call_611482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611482, url, valid)

proc call*(call_611483: Call_CreateSampleFindings_611470; detectorId: string;
          body: JsonNode): Recallable =
  ## createSampleFindings
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for <code>findingTypes</code>, the API generates example findings of all supported finding types.
  ##   detectorId: string (required)
  ##             : The ID of the detector to create sample findings for.
  ##   body: JObject (required)
  var path_611484 = newJObject()
  var body_611485 = newJObject()
  add(path_611484, "detectorId", newJString(detectorId))
  if body != nil:
    body_611485 = body
  result = call_611483.call(path_611484, nil, nil, nil, body_611485)

var createSampleFindings* = Call_CreateSampleFindings_611470(
    name: "createSampleFindings", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/create",
    validator: validate_CreateSampleFindings_611471, base: "/",
    url: url_CreateSampleFindings_611472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateThreatIntelSet_611505 = ref object of OpenApiRestCall_610658
proc url_CreateThreatIntelSet_611507(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateThreatIntelSet_611506(path: JsonNode; query: JsonNode;
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
  var valid_611508 = path.getOrDefault("detectorId")
  valid_611508 = validateParameter(valid_611508, JString, required = true,
                                 default = nil)
  if valid_611508 != nil:
    section.add "detectorId", valid_611508
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
  var valid_611509 = header.getOrDefault("X-Amz-Signature")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Signature", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Content-Sha256", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Date")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Date", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Credential")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Credential", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Security-Token")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Security-Token", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Algorithm")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Algorithm", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-SignedHeaders", valid_611515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611517: Call_CreateThreatIntelSet_611505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets. Only users of the master account can use this operation.
  ## 
  let valid = call_611517.validator(path, query, header, formData, body)
  let scheme = call_611517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611517.url(scheme.get, call_611517.host, call_611517.base,
                         call_611517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611517, url, valid)

proc call*(call_611518: Call_CreateThreatIntelSet_611505; detectorId: string;
          body: JsonNode): Recallable =
  ## createThreatIntelSet
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets. Only users of the master account can use this operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create a threatIntelSet.
  ##   body: JObject (required)
  var path_611519 = newJObject()
  var body_611520 = newJObject()
  add(path_611519, "detectorId", newJString(detectorId))
  if body != nil:
    body_611520 = body
  result = call_611518.call(path_611519, nil, nil, nil, body_611520)

var createThreatIntelSet* = Call_CreateThreatIntelSet_611505(
    name: "createThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_CreateThreatIntelSet_611506, base: "/",
    url: url_CreateThreatIntelSet_611507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListThreatIntelSets_611486 = ref object of OpenApiRestCall_610658
proc url_ListThreatIntelSets_611488(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListThreatIntelSets_611487(path: JsonNode; query: JsonNode;
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
  var valid_611489 = path.getOrDefault("detectorId")
  valid_611489 = validateParameter(valid_611489, JString, required = true,
                                 default = nil)
  if valid_611489 != nil:
    section.add "detectorId", valid_611489
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
  var valid_611490 = query.getOrDefault("nextToken")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "nextToken", valid_611490
  var valid_611491 = query.getOrDefault("MaxResults")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "MaxResults", valid_611491
  var valid_611492 = query.getOrDefault("NextToken")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "NextToken", valid_611492
  var valid_611493 = query.getOrDefault("maxResults")
  valid_611493 = validateParameter(valid_611493, JInt, required = false, default = nil)
  if valid_611493 != nil:
    section.add "maxResults", valid_611493
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
  var valid_611494 = header.getOrDefault("X-Amz-Signature")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Signature", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Content-Sha256", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Date")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Date", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Credential")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Credential", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Security-Token")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Security-Token", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Algorithm")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Algorithm", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-SignedHeaders", valid_611500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611501: Call_ListThreatIntelSets_611486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the ThreatIntelSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the ThreatIntelSets associated with the master account are returned.
  ## 
  let valid = call_611501.validator(path, query, header, formData, body)
  let scheme = call_611501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611501.url(scheme.get, call_611501.host, call_611501.base,
                         call_611501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611501, url, valid)

proc call*(call_611502: Call_ListThreatIntelSets_611486; detectorId: string;
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
  var path_611503 = newJObject()
  var query_611504 = newJObject()
  add(query_611504, "nextToken", newJString(nextToken))
  add(query_611504, "MaxResults", newJString(MaxResults))
  add(path_611503, "detectorId", newJString(detectorId))
  add(query_611504, "NextToken", newJString(NextToken))
  add(query_611504, "maxResults", newJInt(maxResults))
  result = call_611502.call(path_611503, query_611504, nil, nil, nil)

var listThreatIntelSets* = Call_ListThreatIntelSets_611486(
    name: "listThreatIntelSets", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_ListThreatIntelSets_611487, base: "/",
    url: url_ListThreatIntelSets_611488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_611521 = ref object of OpenApiRestCall_610658
proc url_DeclineInvitations_611523(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeclineInvitations_611522(path: JsonNode; query: JsonNode;
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
  var valid_611524 = header.getOrDefault("X-Amz-Signature")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Signature", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Content-Sha256", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Date")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Date", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Credential")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Credential", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Security-Token")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Security-Token", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Algorithm")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Algorithm", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-SignedHeaders", valid_611530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611532: Call_DeclineInvitations_611521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
  ## 
  let valid = call_611532.validator(path, query, header, formData, body)
  let scheme = call_611532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611532.url(scheme.get, call_611532.host, call_611532.base,
                         call_611532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611532, url, valid)

proc call*(call_611533: Call_DeclineInvitations_611521; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
  ##   body: JObject (required)
  var body_611534 = newJObject()
  if body != nil:
    body_611534 = body
  result = call_611533.call(nil, nil, nil, nil, body_611534)

var declineInvitations* = Call_DeclineInvitations_611521(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/invitation/decline",
    validator: validate_DeclineInvitations_611522, base: "/",
    url: url_DeclineInvitations_611523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetector_611549 = ref object of OpenApiRestCall_610658
proc url_UpdateDetector_611551(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDetector_611550(path: JsonNode; query: JsonNode;
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
  var valid_611552 = path.getOrDefault("detectorId")
  valid_611552 = validateParameter(valid_611552, JString, required = true,
                                 default = nil)
  if valid_611552 != nil:
    section.add "detectorId", valid_611552
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
  var valid_611553 = header.getOrDefault("X-Amz-Signature")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Signature", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Content-Sha256", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Date")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Date", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Credential")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Credential", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Security-Token")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Security-Token", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Algorithm")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Algorithm", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-SignedHeaders", valid_611559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611561: Call_UpdateDetector_611549; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Amazon GuardDuty detector specified by the detectorId.
  ## 
  let valid = call_611561.validator(path, query, header, formData, body)
  let scheme = call_611561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611561.url(scheme.get, call_611561.host, call_611561.base,
                         call_611561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611561, url, valid)

proc call*(call_611562: Call_UpdateDetector_611549; detectorId: string;
          body: JsonNode): Recallable =
  ## updateDetector
  ## Updates the Amazon GuardDuty detector specified by the detectorId.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector to update.
  ##   body: JObject (required)
  var path_611563 = newJObject()
  var body_611564 = newJObject()
  add(path_611563, "detectorId", newJString(detectorId))
  if body != nil:
    body_611564 = body
  result = call_611562.call(path_611563, nil, nil, nil, body_611564)

var updateDetector* = Call_UpdateDetector_611549(name: "updateDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_UpdateDetector_611550,
    base: "/", url: url_UpdateDetector_611551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetector_611535 = ref object of OpenApiRestCall_610658
proc url_GetDetector_611537(protocol: Scheme; host: string; base: string;
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

proc validate_GetDetector_611536(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611538 = path.getOrDefault("detectorId")
  valid_611538 = validateParameter(valid_611538, JString, required = true,
                                 default = nil)
  if valid_611538 != nil:
    section.add "detectorId", valid_611538
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
  var valid_611539 = header.getOrDefault("X-Amz-Signature")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Signature", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Content-Sha256", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Date")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Date", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Credential")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Credential", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-Security-Token")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Security-Token", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Algorithm")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Algorithm", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-SignedHeaders", valid_611545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611546: Call_GetDetector_611535; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
  ## 
  let valid = call_611546.validator(path, query, header, formData, body)
  let scheme = call_611546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611546.url(scheme.get, call_611546.host, call_611546.base,
                         call_611546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611546, url, valid)

proc call*(call_611547: Call_GetDetector_611535; detectorId: string): Recallable =
  ## getDetector
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that you want to get.
  var path_611548 = newJObject()
  add(path_611548, "detectorId", newJString(detectorId))
  result = call_611547.call(path_611548, nil, nil, nil, nil)

var getDetector* = Call_GetDetector_611535(name: "getDetector",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}",
                                        validator: validate_GetDetector_611536,
                                        base: "/", url: url_GetDetector_611537,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetector_611565 = ref object of OpenApiRestCall_610658
proc url_DeleteDetector_611567(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDetector_611566(path: JsonNode; query: JsonNode;
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
  var valid_611568 = path.getOrDefault("detectorId")
  valid_611568 = validateParameter(valid_611568, JString, required = true,
                                 default = nil)
  if valid_611568 != nil:
    section.add "detectorId", valid_611568
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
  var valid_611569 = header.getOrDefault("X-Amz-Signature")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Signature", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Content-Sha256", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Date")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Date", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Credential")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Credential", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Security-Token")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Security-Token", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Algorithm")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Algorithm", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-SignedHeaders", valid_611575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611576: Call_DeleteDetector_611565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
  ## 
  let valid = call_611576.validator(path, query, header, formData, body)
  let scheme = call_611576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611576.url(scheme.get, call_611576.host, call_611576.base,
                         call_611576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611576, url, valid)

proc call*(call_611577: Call_DeleteDetector_611565; detectorId: string): Recallable =
  ## deleteDetector
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that you want to delete.
  var path_611578 = newJObject()
  add(path_611578, "detectorId", newJString(detectorId))
  result = call_611577.call(path_611578, nil, nil, nil, nil)

var deleteDetector* = Call_DeleteDetector_611565(name: "deleteDetector",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_DeleteDetector_611566,
    base: "/", url: url_DeleteDetector_611567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFilter_611594 = ref object of OpenApiRestCall_610658
proc url_UpdateFilter_611596(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFilter_611595(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611597 = path.getOrDefault("detectorId")
  valid_611597 = validateParameter(valid_611597, JString, required = true,
                                 default = nil)
  if valid_611597 != nil:
    section.add "detectorId", valid_611597
  var valid_611598 = path.getOrDefault("filterName")
  valid_611598 = validateParameter(valid_611598, JString, required = true,
                                 default = nil)
  if valid_611598 != nil:
    section.add "filterName", valid_611598
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
  var valid_611599 = header.getOrDefault("X-Amz-Signature")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Signature", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Content-Sha256", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Date")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Date", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Credential")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Credential", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Security-Token")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Security-Token", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Algorithm")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Algorithm", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-SignedHeaders", valid_611605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611607: Call_UpdateFilter_611594; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the filter specified by the filter name.
  ## 
  let valid = call_611607.validator(path, query, header, formData, body)
  let scheme = call_611607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611607.url(scheme.get, call_611607.host, call_611607.base,
                         call_611607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611607, url, valid)

proc call*(call_611608: Call_UpdateFilter_611594; detectorId: string;
          filterName: string; body: JsonNode): Recallable =
  ## updateFilter
  ## Updates the filter specified by the filter name.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that specifies the GuardDuty service where you want to update a filter.
  ##   filterName: string (required)
  ##             : The name of the filter.
  ##   body: JObject (required)
  var path_611609 = newJObject()
  var body_611610 = newJObject()
  add(path_611609, "detectorId", newJString(detectorId))
  add(path_611609, "filterName", newJString(filterName))
  if body != nil:
    body_611610 = body
  result = call_611608.call(path_611609, nil, nil, nil, body_611610)

var updateFilter* = Call_UpdateFilter_611594(name: "updateFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_UpdateFilter_611595, base: "/", url: url_UpdateFilter_611596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFilter_611579 = ref object of OpenApiRestCall_610658
proc url_GetFilter_611581(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFilter_611580(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611582 = path.getOrDefault("detectorId")
  valid_611582 = validateParameter(valid_611582, JString, required = true,
                                 default = nil)
  if valid_611582 != nil:
    section.add "detectorId", valid_611582
  var valid_611583 = path.getOrDefault("filterName")
  valid_611583 = validateParameter(valid_611583, JString, required = true,
                                 default = nil)
  if valid_611583 != nil:
    section.add "filterName", valid_611583
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
  var valid_611584 = header.getOrDefault("X-Amz-Signature")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Signature", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Content-Sha256", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Date")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Date", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Credential")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Credential", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Security-Token")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Security-Token", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Algorithm")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Algorithm", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-SignedHeaders", valid_611590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611591: Call_GetFilter_611579; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of the filter specified by the filter name.
  ## 
  let valid = call_611591.validator(path, query, header, formData, body)
  let scheme = call_611591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611591.url(scheme.get, call_611591.host, call_611591.base,
                         call_611591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611591, url, valid)

proc call*(call_611592: Call_GetFilter_611579; detectorId: string; filterName: string): Recallable =
  ## getFilter
  ## Returns the details of the filter specified by the filter name.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  ##   filterName: string (required)
  ##             : The name of the filter you want to get.
  var path_611593 = newJObject()
  add(path_611593, "detectorId", newJString(detectorId))
  add(path_611593, "filterName", newJString(filterName))
  result = call_611592.call(path_611593, nil, nil, nil, nil)

var getFilter* = Call_GetFilter_611579(name: "getFilter", meth: HttpMethod.HttpGet,
                                    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/filter/{filterName}",
                                    validator: validate_GetFilter_611580,
                                    base: "/", url: url_GetFilter_611581,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFilter_611611 = ref object of OpenApiRestCall_610658
proc url_DeleteFilter_611613(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFilter_611612(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611614 = path.getOrDefault("detectorId")
  valid_611614 = validateParameter(valid_611614, JString, required = true,
                                 default = nil)
  if valid_611614 != nil:
    section.add "detectorId", valid_611614
  var valid_611615 = path.getOrDefault("filterName")
  valid_611615 = validateParameter(valid_611615, JString, required = true,
                                 default = nil)
  if valid_611615 != nil:
    section.add "filterName", valid_611615
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
  var valid_611616 = header.getOrDefault("X-Amz-Signature")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Signature", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Content-Sha256", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Date")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Date", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Credential")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Credential", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-Security-Token")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Security-Token", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Algorithm")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Algorithm", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-SignedHeaders", valid_611622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611623: Call_DeleteFilter_611611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the filter specified by the filter name.
  ## 
  let valid = call_611623.validator(path, query, header, formData, body)
  let scheme = call_611623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611623.url(scheme.get, call_611623.host, call_611623.base,
                         call_611623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611623, url, valid)

proc call*(call_611624: Call_DeleteFilter_611611; detectorId: string;
          filterName: string): Recallable =
  ## deleteFilter
  ## Deletes the filter specified by the filter name.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  ##   filterName: string (required)
  ##             : The name of the filter you want to delete.
  var path_611625 = newJObject()
  add(path_611625, "detectorId", newJString(detectorId))
  add(path_611625, "filterName", newJString(filterName))
  result = call_611624.call(path_611625, nil, nil, nil, nil)

var deleteFilter* = Call_DeleteFilter_611611(name: "deleteFilter",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_DeleteFilter_611612, base: "/", url: url_DeleteFilter_611613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIPSet_611641 = ref object of OpenApiRestCall_610658
proc url_UpdateIPSet_611643(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIPSet_611642(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611644 = path.getOrDefault("ipSetId")
  valid_611644 = validateParameter(valid_611644, JString, required = true,
                                 default = nil)
  if valid_611644 != nil:
    section.add "ipSetId", valid_611644
  var valid_611645 = path.getOrDefault("detectorId")
  valid_611645 = validateParameter(valid_611645, JString, required = true,
                                 default = nil)
  if valid_611645 != nil:
    section.add "detectorId", valid_611645
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
  var valid_611646 = header.getOrDefault("X-Amz-Signature")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-Signature", valid_611646
  var valid_611647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Content-Sha256", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-Date")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Date", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Credential")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Credential", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-Security-Token")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-Security-Token", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Algorithm")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Algorithm", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-SignedHeaders", valid_611652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611654: Call_UpdateIPSet_611641; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the IPSet specified by the IPSet ID.
  ## 
  let valid = call_611654.validator(path, query, header, formData, body)
  let scheme = call_611654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611654.url(scheme.get, call_611654.host, call_611654.base,
                         call_611654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611654, url, valid)

proc call*(call_611655: Call_UpdateIPSet_611641; ipSetId: string; detectorId: string;
          body: JsonNode): Recallable =
  ## updateIPSet
  ## Updates the IPSet specified by the IPSet ID.
  ##   ipSetId: string (required)
  ##          : The unique ID that specifies the IPSet that you want to update.
  ##   detectorId: string (required)
  ##             : The detectorID that specifies the GuardDuty service whose IPSet you want to update.
  ##   body: JObject (required)
  var path_611656 = newJObject()
  var body_611657 = newJObject()
  add(path_611656, "ipSetId", newJString(ipSetId))
  add(path_611656, "detectorId", newJString(detectorId))
  if body != nil:
    body_611657 = body
  result = call_611655.call(path_611656, nil, nil, nil, body_611657)

var updateIPSet* = Call_UpdateIPSet_611641(name: "updateIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                        validator: validate_UpdateIPSet_611642,
                                        base: "/", url: url_UpdateIPSet_611643,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIPSet_611626 = ref object of OpenApiRestCall_610658
proc url_GetIPSet_611628(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIPSet_611627(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611629 = path.getOrDefault("ipSetId")
  valid_611629 = validateParameter(valid_611629, JString, required = true,
                                 default = nil)
  if valid_611629 != nil:
    section.add "ipSetId", valid_611629
  var valid_611630 = path.getOrDefault("detectorId")
  valid_611630 = validateParameter(valid_611630, JString, required = true,
                                 default = nil)
  if valid_611630 != nil:
    section.add "detectorId", valid_611630
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
  var valid_611631 = header.getOrDefault("X-Amz-Signature")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Signature", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Content-Sha256", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Date")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Date", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Credential")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Credential", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Security-Token")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Security-Token", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Algorithm")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Algorithm", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-SignedHeaders", valid_611637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611638: Call_GetIPSet_611626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
  ## 
  let valid = call_611638.validator(path, query, header, formData, body)
  let scheme = call_611638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611638.url(scheme.get, call_611638.host, call_611638.base,
                         call_611638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611638, url, valid)

proc call*(call_611639: Call_GetIPSet_611626; ipSetId: string; detectorId: string): Recallable =
  ## getIPSet
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
  ##   ipSetId: string (required)
  ##          : The unique ID of the IPSet to retrieve.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the ipSet is associated with.
  var path_611640 = newJObject()
  add(path_611640, "ipSetId", newJString(ipSetId))
  add(path_611640, "detectorId", newJString(detectorId))
  result = call_611639.call(path_611640, nil, nil, nil, nil)

var getIPSet* = Call_GetIPSet_611626(name: "getIPSet", meth: HttpMethod.HttpGet,
                                  host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                  validator: validate_GetIPSet_611627, base: "/",
                                  url: url_GetIPSet_611628,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIPSet_611658 = ref object of OpenApiRestCall_610658
proc url_DeleteIPSet_611660(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIPSet_611659(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611661 = path.getOrDefault("ipSetId")
  valid_611661 = validateParameter(valid_611661, JString, required = true,
                                 default = nil)
  if valid_611661 != nil:
    section.add "ipSetId", valid_611661
  var valid_611662 = path.getOrDefault("detectorId")
  valid_611662 = validateParameter(valid_611662, JString, required = true,
                                 default = nil)
  if valid_611662 != nil:
    section.add "detectorId", valid_611662
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
  var valid_611663 = header.getOrDefault("X-Amz-Signature")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Signature", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Content-Sha256", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-Date")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Date", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Credential")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Credential", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Security-Token")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Security-Token", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Algorithm")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Algorithm", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-SignedHeaders", valid_611669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611670: Call_DeleteIPSet_611658; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
  ## 
  let valid = call_611670.validator(path, query, header, formData, body)
  let scheme = call_611670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611670.url(scheme.get, call_611670.host, call_611670.base,
                         call_611670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611670, url, valid)

proc call*(call_611671: Call_DeleteIPSet_611658; ipSetId: string; detectorId: string): Recallable =
  ## deleteIPSet
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
  ##   ipSetId: string (required)
  ##          : The unique ID of the IPSet to delete.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the IPSet.
  var path_611672 = newJObject()
  add(path_611672, "ipSetId", newJString(ipSetId))
  add(path_611672, "detectorId", newJString(detectorId))
  result = call_611671.call(path_611672, nil, nil, nil, nil)

var deleteIPSet* = Call_DeleteIPSet_611658(name: "deleteIPSet",
                                        meth: HttpMethod.HttpDelete,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                        validator: validate_DeleteIPSet_611659,
                                        base: "/", url: url_DeleteIPSet_611660,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_611673 = ref object of OpenApiRestCall_610658
proc url_DeleteInvitations_611675(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInvitations_611674(path: JsonNode; query: JsonNode;
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
  var valid_611676 = header.getOrDefault("X-Amz-Signature")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "X-Amz-Signature", valid_611676
  var valid_611677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-Content-Sha256", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Date")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Date", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Credential")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Credential", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-Security-Token")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-Security-Token", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Algorithm")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Algorithm", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-SignedHeaders", valid_611682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611684: Call_DeleteInvitations_611673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
  ## 
  let valid = call_611684.validator(path, query, header, formData, body)
  let scheme = call_611684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611684.url(scheme.get, call_611684.host, call_611684.base,
                         call_611684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611684, url, valid)

proc call*(call_611685: Call_DeleteInvitations_611673; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
  ##   body: JObject (required)
  var body_611686 = newJObject()
  if body != nil:
    body_611686 = body
  result = call_611685.call(nil, nil, nil, nil, body_611686)

var deleteInvitations* = Call_DeleteInvitations_611673(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/invitation/delete", validator: validate_DeleteInvitations_611674,
    base: "/", url: url_DeleteInvitations_611675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_611687 = ref object of OpenApiRestCall_610658
proc url_DeleteMembers_611689(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMembers_611688(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611690 = path.getOrDefault("detectorId")
  valid_611690 = validateParameter(valid_611690, JString, required = true,
                                 default = nil)
  if valid_611690 != nil:
    section.add "detectorId", valid_611690
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
  var valid_611691 = header.getOrDefault("X-Amz-Signature")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-Signature", valid_611691
  var valid_611692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-Content-Sha256", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Date")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Date", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Credential")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Credential", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-Security-Token")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-Security-Token", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-Algorithm")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Algorithm", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-SignedHeaders", valid_611697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611699: Call_DeleteMembers_611687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_611699.validator(path, query, header, formData, body)
  let scheme = call_611699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611699.url(scheme.get, call_611699.host, call_611699.base,
                         call_611699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611699, url, valid)

proc call*(call_611700: Call_DeleteMembers_611687; detectorId: string; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to delete.
  ##   body: JObject (required)
  var path_611701 = newJObject()
  var body_611702 = newJObject()
  add(path_611701, "detectorId", newJString(detectorId))
  if body != nil:
    body_611702 = body
  result = call_611700.call(path_611701, nil, nil, nil, body_611702)

var deleteMembers* = Call_DeleteMembers_611687(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/delete",
    validator: validate_DeleteMembers_611688, base: "/", url: url_DeleteMembers_611689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePublishingDestination_611718 = ref object of OpenApiRestCall_610658
proc url_UpdatePublishingDestination_611720(protocol: Scheme; host: string;
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

proc validate_UpdatePublishingDestination_611719(path: JsonNode; query: JsonNode;
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
  var valid_611721 = path.getOrDefault("detectorId")
  valid_611721 = validateParameter(valid_611721, JString, required = true,
                                 default = nil)
  if valid_611721 != nil:
    section.add "detectorId", valid_611721
  var valid_611722 = path.getOrDefault("destinationId")
  valid_611722 = validateParameter(valid_611722, JString, required = true,
                                 default = nil)
  if valid_611722 != nil:
    section.add "destinationId", valid_611722
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
  var valid_611723 = header.getOrDefault("X-Amz-Signature")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Signature", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Content-Sha256", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-Date")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Date", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Credential")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Credential", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Security-Token")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Security-Token", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Algorithm")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Algorithm", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-SignedHeaders", valid_611729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611731: Call_UpdatePublishingDestination_611718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
  ## 
  let valid = call_611731.validator(path, query, header, formData, body)
  let scheme = call_611731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611731.url(scheme.get, call_611731.host, call_611731.base,
                         call_611731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611731, url, valid)

proc call*(call_611732: Call_UpdatePublishingDestination_611718;
          detectorId: string; destinationId: string; body: JsonNode): Recallable =
  ## updatePublishingDestination
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
  ##   detectorId: string (required)
  ##             : The ID of the 
  ##   destinationId: string (required)
  ##                : The ID of the detector associated with the publishing destinations to update.
  ##   body: JObject (required)
  var path_611733 = newJObject()
  var body_611734 = newJObject()
  add(path_611733, "detectorId", newJString(detectorId))
  add(path_611733, "destinationId", newJString(destinationId))
  if body != nil:
    body_611734 = body
  result = call_611732.call(path_611733, nil, nil, nil, body_611734)

var updatePublishingDestination* = Call_UpdatePublishingDestination_611718(
    name: "updatePublishingDestination", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_UpdatePublishingDestination_611719, base: "/",
    url: url_UpdatePublishingDestination_611720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePublishingDestination_611703 = ref object of OpenApiRestCall_610658
proc url_DescribePublishingDestination_611705(protocol: Scheme; host: string;
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

proc validate_DescribePublishingDestination_611704(path: JsonNode; query: JsonNode;
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
  var valid_611706 = path.getOrDefault("detectorId")
  valid_611706 = validateParameter(valid_611706, JString, required = true,
                                 default = nil)
  if valid_611706 != nil:
    section.add "detectorId", valid_611706
  var valid_611707 = path.getOrDefault("destinationId")
  valid_611707 = validateParameter(valid_611707, JString, required = true,
                                 default = nil)
  if valid_611707 != nil:
    section.add "destinationId", valid_611707
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
  var valid_611708 = header.getOrDefault("X-Amz-Signature")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Signature", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Content-Sha256", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Date")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Date", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Credential")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Credential", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Security-Token")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Security-Token", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-Algorithm")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Algorithm", valid_611713
  var valid_611714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-SignedHeaders", valid_611714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611715: Call_DescribePublishingDestination_611703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
  ## 
  let valid = call_611715.validator(path, query, header, formData, body)
  let scheme = call_611715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611715.url(scheme.get, call_611715.host, call_611715.base,
                         call_611715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611715, url, valid)

proc call*(call_611716: Call_DescribePublishingDestination_611703;
          detectorId: string; destinationId: string): Recallable =
  ## describePublishingDestination
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the publishing destination to retrieve.
  ##   destinationId: string (required)
  ##                : The ID of the publishing destination to retrieve.
  var path_611717 = newJObject()
  add(path_611717, "detectorId", newJString(detectorId))
  add(path_611717, "destinationId", newJString(destinationId))
  result = call_611716.call(path_611717, nil, nil, nil, nil)

var describePublishingDestination* = Call_DescribePublishingDestination_611703(
    name: "describePublishingDestination", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_DescribePublishingDestination_611704, base: "/",
    url: url_DescribePublishingDestination_611705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublishingDestination_611735 = ref object of OpenApiRestCall_610658
proc url_DeletePublishingDestination_611737(protocol: Scheme; host: string;
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

proc validate_DeletePublishingDestination_611736(path: JsonNode; query: JsonNode;
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
  var valid_611738 = path.getOrDefault("detectorId")
  valid_611738 = validateParameter(valid_611738, JString, required = true,
                                 default = nil)
  if valid_611738 != nil:
    section.add "detectorId", valid_611738
  var valid_611739 = path.getOrDefault("destinationId")
  valid_611739 = validateParameter(valid_611739, JString, required = true,
                                 default = nil)
  if valid_611739 != nil:
    section.add "destinationId", valid_611739
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
  var valid_611740 = header.getOrDefault("X-Amz-Signature")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Signature", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Content-Sha256", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Date")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Date", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-Credential")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Credential", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Security-Token")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Security-Token", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Algorithm")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Algorithm", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-SignedHeaders", valid_611746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611747: Call_DeletePublishingDestination_611735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
  ## 
  let valid = call_611747.validator(path, query, header, formData, body)
  let scheme = call_611747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611747.url(scheme.get, call_611747.host, call_611747.base,
                         call_611747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611747, url, valid)

proc call*(call_611748: Call_DeletePublishingDestination_611735;
          detectorId: string; destinationId: string): Recallable =
  ## deletePublishingDestination
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the publishing destination to delete.
  ##   destinationId: string (required)
  ##                : The ID of the publishing destination to delete.
  var path_611749 = newJObject()
  add(path_611749, "detectorId", newJString(detectorId))
  add(path_611749, "destinationId", newJString(destinationId))
  result = call_611748.call(path_611749, nil, nil, nil, nil)

var deletePublishingDestination* = Call_DeletePublishingDestination_611735(
    name: "deletePublishingDestination", meth: HttpMethod.HttpDelete,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_DeletePublishingDestination_611736, base: "/",
    url: url_DeletePublishingDestination_611737,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateThreatIntelSet_611765 = ref object of OpenApiRestCall_610658
proc url_UpdateThreatIntelSet_611767(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateThreatIntelSet_611766(path: JsonNode; query: JsonNode;
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
  var valid_611768 = path.getOrDefault("detectorId")
  valid_611768 = validateParameter(valid_611768, JString, required = true,
                                 default = nil)
  if valid_611768 != nil:
    section.add "detectorId", valid_611768
  var valid_611769 = path.getOrDefault("threatIntelSetId")
  valid_611769 = validateParameter(valid_611769, JString, required = true,
                                 default = nil)
  if valid_611769 != nil:
    section.add "threatIntelSetId", valid_611769
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
  var valid_611770 = header.getOrDefault("X-Amz-Signature")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-Signature", valid_611770
  var valid_611771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611771 = validateParameter(valid_611771, JString, required = false,
                                 default = nil)
  if valid_611771 != nil:
    section.add "X-Amz-Content-Sha256", valid_611771
  var valid_611772 = header.getOrDefault("X-Amz-Date")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Date", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-Credential")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-Credential", valid_611773
  var valid_611774 = header.getOrDefault("X-Amz-Security-Token")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-Security-Token", valid_611774
  var valid_611775 = header.getOrDefault("X-Amz-Algorithm")
  valid_611775 = validateParameter(valid_611775, JString, required = false,
                                 default = nil)
  if valid_611775 != nil:
    section.add "X-Amz-Algorithm", valid_611775
  var valid_611776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-SignedHeaders", valid_611776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611778: Call_UpdateThreatIntelSet_611765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ## 
  let valid = call_611778.validator(path, query, header, formData, body)
  let scheme = call_611778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611778.url(scheme.get, call_611778.host, call_611778.base,
                         call_611778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611778, url, valid)

proc call*(call_611779: Call_UpdateThreatIntelSet_611765; detectorId: string;
          body: JsonNode; threatIntelSetId: string): Recallable =
  ## updateThreatIntelSet
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The detectorID that specifies the GuardDuty service whose ThreatIntelSet you want to update.
  ##   body: JObject (required)
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID that specifies the ThreatIntelSet that you want to update.
  var path_611780 = newJObject()
  var body_611781 = newJObject()
  add(path_611780, "detectorId", newJString(detectorId))
  if body != nil:
    body_611781 = body
  add(path_611780, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_611779.call(path_611780, nil, nil, nil, body_611781)

var updateThreatIntelSet* = Call_UpdateThreatIntelSet_611765(
    name: "updateThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_UpdateThreatIntelSet_611766, base: "/",
    url: url_UpdateThreatIntelSet_611767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThreatIntelSet_611750 = ref object of OpenApiRestCall_610658
proc url_GetThreatIntelSet_611752(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetThreatIntelSet_611751(path: JsonNode; query: JsonNode;
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
  var valid_611753 = path.getOrDefault("detectorId")
  valid_611753 = validateParameter(valid_611753, JString, required = true,
                                 default = nil)
  if valid_611753 != nil:
    section.add "detectorId", valid_611753
  var valid_611754 = path.getOrDefault("threatIntelSetId")
  valid_611754 = validateParameter(valid_611754, JString, required = true,
                                 default = nil)
  if valid_611754 != nil:
    section.add "threatIntelSetId", valid_611754
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
  var valid_611755 = header.getOrDefault("X-Amz-Signature")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-Signature", valid_611755
  var valid_611756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Content-Sha256", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Date")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Date", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Credential")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Credential", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-Security-Token")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-Security-Token", valid_611759
  var valid_611760 = header.getOrDefault("X-Amz-Algorithm")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-Algorithm", valid_611760
  var valid_611761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-SignedHeaders", valid_611761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611762: Call_GetThreatIntelSet_611750; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ## 
  let valid = call_611762.validator(path, query, header, formData, body)
  let scheme = call_611762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611762.url(scheme.get, call_611762.host, call_611762.base,
                         call_611762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611762, url, valid)

proc call*(call_611763: Call_GetThreatIntelSet_611750; detectorId: string;
          threatIntelSetId: string): Recallable =
  ## getThreatIntelSet
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID of the threatIntelSet you want to get.
  var path_611764 = newJObject()
  add(path_611764, "detectorId", newJString(detectorId))
  add(path_611764, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_611763.call(path_611764, nil, nil, nil, nil)

var getThreatIntelSet* = Call_GetThreatIntelSet_611750(name: "getThreatIntelSet",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_GetThreatIntelSet_611751, base: "/",
    url: url_GetThreatIntelSet_611752, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteThreatIntelSet_611782 = ref object of OpenApiRestCall_610658
proc url_DeleteThreatIntelSet_611784(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteThreatIntelSet_611783(path: JsonNode; query: JsonNode;
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
  var valid_611785 = path.getOrDefault("detectorId")
  valid_611785 = validateParameter(valid_611785, JString, required = true,
                                 default = nil)
  if valid_611785 != nil:
    section.add "detectorId", valid_611785
  var valid_611786 = path.getOrDefault("threatIntelSetId")
  valid_611786 = validateParameter(valid_611786, JString, required = true,
                                 default = nil)
  if valid_611786 != nil:
    section.add "threatIntelSetId", valid_611786
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
  var valid_611787 = header.getOrDefault("X-Amz-Signature")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "X-Amz-Signature", valid_611787
  var valid_611788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "X-Amz-Content-Sha256", valid_611788
  var valid_611789 = header.getOrDefault("X-Amz-Date")
  valid_611789 = validateParameter(valid_611789, JString, required = false,
                                 default = nil)
  if valid_611789 != nil:
    section.add "X-Amz-Date", valid_611789
  var valid_611790 = header.getOrDefault("X-Amz-Credential")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "X-Amz-Credential", valid_611790
  var valid_611791 = header.getOrDefault("X-Amz-Security-Token")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Security-Token", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-Algorithm")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-Algorithm", valid_611792
  var valid_611793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "X-Amz-SignedHeaders", valid_611793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611794: Call_DeleteThreatIntelSet_611782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ## 
  let valid = call_611794.validator(path, query, header, formData, body)
  let scheme = call_611794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611794.url(scheme.get, call_611794.host, call_611794.base,
                         call_611794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611794, url, valid)

proc call*(call_611795: Call_DeleteThreatIntelSet_611782; detectorId: string;
          threatIntelSetId: string): Recallable =
  ## deleteThreatIntelSet
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID of the threatIntelSet you want to delete.
  var path_611796 = newJObject()
  add(path_611796, "detectorId", newJString(detectorId))
  add(path_611796, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_611795.call(path_611796, nil, nil, nil, nil)

var deleteThreatIntelSet* = Call_DeleteThreatIntelSet_611782(
    name: "deleteThreatIntelSet", meth: HttpMethod.HttpDelete,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_DeleteThreatIntelSet_611783, base: "/",
    url: url_DeleteThreatIntelSet_611784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_611797 = ref object of OpenApiRestCall_610658
proc url_DisassociateFromMasterAccount_611799(protocol: Scheme; host: string;
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

proc validate_DisassociateFromMasterAccount_611798(path: JsonNode; query: JsonNode;
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
  var valid_611800 = path.getOrDefault("detectorId")
  valid_611800 = validateParameter(valid_611800, JString, required = true,
                                 default = nil)
  if valid_611800 != nil:
    section.add "detectorId", valid_611800
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
  var valid_611801 = header.getOrDefault("X-Amz-Signature")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-Signature", valid_611801
  var valid_611802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-Content-Sha256", valid_611802
  var valid_611803 = header.getOrDefault("X-Amz-Date")
  valid_611803 = validateParameter(valid_611803, JString, required = false,
                                 default = nil)
  if valid_611803 != nil:
    section.add "X-Amz-Date", valid_611803
  var valid_611804 = header.getOrDefault("X-Amz-Credential")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-Credential", valid_611804
  var valid_611805 = header.getOrDefault("X-Amz-Security-Token")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "X-Amz-Security-Token", valid_611805
  var valid_611806 = header.getOrDefault("X-Amz-Algorithm")
  valid_611806 = validateParameter(valid_611806, JString, required = false,
                                 default = nil)
  if valid_611806 != nil:
    section.add "X-Amz-Algorithm", valid_611806
  var valid_611807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611807 = validateParameter(valid_611807, JString, required = false,
                                 default = nil)
  if valid_611807 != nil:
    section.add "X-Amz-SignedHeaders", valid_611807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611808: Call_DisassociateFromMasterAccount_611797; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current GuardDuty member account from its master account.
  ## 
  let valid = call_611808.validator(path, query, header, formData, body)
  let scheme = call_611808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611808.url(scheme.get, call_611808.host, call_611808.base,
                         call_611808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611808, url, valid)

proc call*(call_611809: Call_DisassociateFromMasterAccount_611797;
          detectorId: string): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current GuardDuty member account from its master account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  var path_611810 = newJObject()
  add(path_611810, "detectorId", newJString(detectorId))
  result = call_611809.call(path_611810, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_611797(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_611798, base: "/",
    url: url_DisassociateFromMasterAccount_611799,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_611811 = ref object of OpenApiRestCall_610658
proc url_DisassociateMembers_611813(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateMembers_611812(path: JsonNode; query: JsonNode;
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
  var valid_611814 = path.getOrDefault("detectorId")
  valid_611814 = validateParameter(valid_611814, JString, required = true,
                                 default = nil)
  if valid_611814 != nil:
    section.add "detectorId", valid_611814
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
  var valid_611815 = header.getOrDefault("X-Amz-Signature")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-Signature", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Content-Sha256", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-Date")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-Date", valid_611817
  var valid_611818 = header.getOrDefault("X-Amz-Credential")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-Credential", valid_611818
  var valid_611819 = header.getOrDefault("X-Amz-Security-Token")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "X-Amz-Security-Token", valid_611819
  var valid_611820 = header.getOrDefault("X-Amz-Algorithm")
  valid_611820 = validateParameter(valid_611820, JString, required = false,
                                 default = nil)
  if valid_611820 != nil:
    section.add "X-Amz-Algorithm", valid_611820
  var valid_611821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611821 = validateParameter(valid_611821, JString, required = false,
                                 default = nil)
  if valid_611821 != nil:
    section.add "X-Amz-SignedHeaders", valid_611821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611823: Call_DisassociateMembers_611811; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_611823.validator(path, query, header, formData, body)
  let scheme = call_611823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611823.url(scheme.get, call_611823.host, call_611823.base,
                         call_611823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611823, url, valid)

proc call*(call_611824: Call_DisassociateMembers_611811; detectorId: string;
          body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to disassociate from master.
  ##   body: JObject (required)
  var path_611825 = newJObject()
  var body_611826 = newJObject()
  add(path_611825, "detectorId", newJString(detectorId))
  if body != nil:
    body_611826 = body
  result = call_611824.call(path_611825, nil, nil, nil, body_611826)

var disassociateMembers* = Call_DisassociateMembers_611811(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/disassociate",
    validator: validate_DisassociateMembers_611812, base: "/",
    url: url_DisassociateMembers_611813, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_611827 = ref object of OpenApiRestCall_610658
proc url_GetFindings_611829(protocol: Scheme; host: string; base: string;
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

proc validate_GetFindings_611828(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611830 = path.getOrDefault("detectorId")
  valid_611830 = validateParameter(valid_611830, JString, required = true,
                                 default = nil)
  if valid_611830 != nil:
    section.add "detectorId", valid_611830
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
  var valid_611831 = header.getOrDefault("X-Amz-Signature")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Signature", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-Content-Sha256", valid_611832
  var valid_611833 = header.getOrDefault("X-Amz-Date")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Date", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-Credential")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Credential", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-Security-Token")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-Security-Token", valid_611835
  var valid_611836 = header.getOrDefault("X-Amz-Algorithm")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "X-Amz-Algorithm", valid_611836
  var valid_611837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-SignedHeaders", valid_611837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611839: Call_GetFindings_611827; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes Amazon GuardDuty findings specified by finding IDs.
  ## 
  let valid = call_611839.validator(path, query, header, formData, body)
  let scheme = call_611839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611839.url(scheme.get, call_611839.host, call_611839.base,
                         call_611839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611839, url, valid)

proc call*(call_611840: Call_GetFindings_611827; detectorId: string; body: JsonNode): Recallable =
  ## getFindings
  ## Describes Amazon GuardDuty findings specified by finding IDs.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to retrieve.
  ##   body: JObject (required)
  var path_611841 = newJObject()
  var body_611842 = newJObject()
  add(path_611841, "detectorId", newJString(detectorId))
  if body != nil:
    body_611842 = body
  result = call_611840.call(path_611841, nil, nil, nil, body_611842)

var getFindings* = Call_GetFindings_611827(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/findings/get",
                                        validator: validate_GetFindings_611828,
                                        base: "/", url: url_GetFindings_611829,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindingsStatistics_611843 = ref object of OpenApiRestCall_610658
proc url_GetFindingsStatistics_611845(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFindingsStatistics_611844(path: JsonNode; query: JsonNode;
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
  var valid_611846 = path.getOrDefault("detectorId")
  valid_611846 = validateParameter(valid_611846, JString, required = true,
                                 default = nil)
  if valid_611846 != nil:
    section.add "detectorId", valid_611846
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
  var valid_611847 = header.getOrDefault("X-Amz-Signature")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-Signature", valid_611847
  var valid_611848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Content-Sha256", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Date")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Date", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-Credential")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Credential", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Security-Token")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Security-Token", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-Algorithm")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-Algorithm", valid_611852
  var valid_611853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611853 = validateParameter(valid_611853, JString, required = false,
                                 default = nil)
  if valid_611853 != nil:
    section.add "X-Amz-SignedHeaders", valid_611853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611855: Call_GetFindingsStatistics_611843; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
  ## 
  let valid = call_611855.validator(path, query, header, formData, body)
  let scheme = call_611855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611855.url(scheme.get, call_611855.host, call_611855.base,
                         call_611855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611855, url, valid)

proc call*(call_611856: Call_GetFindingsStatistics_611843; detectorId: string;
          body: JsonNode): Recallable =
  ## getFindingsStatistics
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings' statistics you want to retrieve.
  ##   body: JObject (required)
  var path_611857 = newJObject()
  var body_611858 = newJObject()
  add(path_611857, "detectorId", newJString(detectorId))
  if body != nil:
    body_611858 = body
  result = call_611856.call(path_611857, nil, nil, nil, body_611858)

var getFindingsStatistics* = Call_GetFindingsStatistics_611843(
    name: "getFindingsStatistics", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/statistics",
    validator: validate_GetFindingsStatistics_611844, base: "/",
    url: url_GetFindingsStatistics_611845, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_611859 = ref object of OpenApiRestCall_610658
proc url_GetInvitationsCount_611861(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInvitationsCount_611860(path: JsonNode; query: JsonNode;
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
  var valid_611862 = header.getOrDefault("X-Amz-Signature")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "X-Amz-Signature", valid_611862
  var valid_611863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "X-Amz-Content-Sha256", valid_611863
  var valid_611864 = header.getOrDefault("X-Amz-Date")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Date", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-Credential")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Credential", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-Security-Token")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Security-Token", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-Algorithm")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-Algorithm", valid_611867
  var valid_611868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-SignedHeaders", valid_611868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611869: Call_GetInvitationsCount_611859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
  ## 
  let valid = call_611869.validator(path, query, header, formData, body)
  let scheme = call_611869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611869.url(scheme.get, call_611869.host, call_611869.base,
                         call_611869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611869, url, valid)

proc call*(call_611870: Call_GetInvitationsCount_611859): Recallable =
  ## getInvitationsCount
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
  result = call_611870.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_611859(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/invitation/count",
    validator: validate_GetInvitationsCount_611860, base: "/",
    url: url_GetInvitationsCount_611861, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_611871 = ref object of OpenApiRestCall_610658
proc url_GetMembers_611873(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMembers_611872(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611874 = path.getOrDefault("detectorId")
  valid_611874 = validateParameter(valid_611874, JString, required = true,
                                 default = nil)
  if valid_611874 != nil:
    section.add "detectorId", valid_611874
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
  var valid_611875 = header.getOrDefault("X-Amz-Signature")
  valid_611875 = validateParameter(valid_611875, JString, required = false,
                                 default = nil)
  if valid_611875 != nil:
    section.add "X-Amz-Signature", valid_611875
  var valid_611876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611876 = validateParameter(valid_611876, JString, required = false,
                                 default = nil)
  if valid_611876 != nil:
    section.add "X-Amz-Content-Sha256", valid_611876
  var valid_611877 = header.getOrDefault("X-Amz-Date")
  valid_611877 = validateParameter(valid_611877, JString, required = false,
                                 default = nil)
  if valid_611877 != nil:
    section.add "X-Amz-Date", valid_611877
  var valid_611878 = header.getOrDefault("X-Amz-Credential")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Credential", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-Security-Token")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Security-Token", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-Algorithm")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Algorithm", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-SignedHeaders", valid_611881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611883: Call_GetMembers_611871; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_611883.validator(path, query, header, formData, body)
  let scheme = call_611883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611883.url(scheme.get, call_611883.host, call_611883.base,
                         call_611883.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611883, url, valid)

proc call*(call_611884: Call_GetMembers_611871; detectorId: string; body: JsonNode): Recallable =
  ## getMembers
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to retrieve.
  ##   body: JObject (required)
  var path_611885 = newJObject()
  var body_611886 = newJObject()
  add(path_611885, "detectorId", newJString(detectorId))
  if body != nil:
    body_611886 = body
  result = call_611884.call(path_611885, nil, nil, nil, body_611886)

var getMembers* = Call_GetMembers_611871(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/get",
                                      validator: validate_GetMembers_611872,
                                      base: "/", url: url_GetMembers_611873,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_611887 = ref object of OpenApiRestCall_610658
proc url_InviteMembers_611889(protocol: Scheme; host: string; base: string;
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

proc validate_InviteMembers_611888(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611890 = path.getOrDefault("detectorId")
  valid_611890 = validateParameter(valid_611890, JString, required = true,
                                 default = nil)
  if valid_611890 != nil:
    section.add "detectorId", valid_611890
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
  var valid_611891 = header.getOrDefault("X-Amz-Signature")
  valid_611891 = validateParameter(valid_611891, JString, required = false,
                                 default = nil)
  if valid_611891 != nil:
    section.add "X-Amz-Signature", valid_611891
  var valid_611892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Content-Sha256", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-Date")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-Date", valid_611893
  var valid_611894 = header.getOrDefault("X-Amz-Credential")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Credential", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-Security-Token")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Security-Token", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Algorithm")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Algorithm", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-SignedHeaders", valid_611897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611899: Call_InviteMembers_611887; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
  ## 
  let valid = call_611899.validator(path, query, header, formData, body)
  let scheme = call_611899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611899.url(scheme.get, call_611899.host, call_611899.base,
                         call_611899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611899, url, valid)

proc call*(call_611900: Call_InviteMembers_611887; detectorId: string; body: JsonNode): Recallable =
  ## inviteMembers
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account with which you want to invite members.
  ##   body: JObject (required)
  var path_611901 = newJObject()
  var body_611902 = newJObject()
  add(path_611901, "detectorId", newJString(detectorId))
  if body != nil:
    body_611902 = body
  result = call_611900.call(path_611901, nil, nil, nil, body_611902)

var inviteMembers* = Call_InviteMembers_611887(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/invite",
    validator: validate_InviteMembers_611888, base: "/", url: url_InviteMembers_611889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_611903 = ref object of OpenApiRestCall_610658
proc url_ListFindings_611905(protocol: Scheme; host: string; base: string;
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

proc validate_ListFindings_611904(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611906 = path.getOrDefault("detectorId")
  valid_611906 = validateParameter(valid_611906, JString, required = true,
                                 default = nil)
  if valid_611906 != nil:
    section.add "detectorId", valid_611906
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611907 = query.getOrDefault("MaxResults")
  valid_611907 = validateParameter(valid_611907, JString, required = false,
                                 default = nil)
  if valid_611907 != nil:
    section.add "MaxResults", valid_611907
  var valid_611908 = query.getOrDefault("NextToken")
  valid_611908 = validateParameter(valid_611908, JString, required = false,
                                 default = nil)
  if valid_611908 != nil:
    section.add "NextToken", valid_611908
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
  var valid_611909 = header.getOrDefault("X-Amz-Signature")
  valid_611909 = validateParameter(valid_611909, JString, required = false,
                                 default = nil)
  if valid_611909 != nil:
    section.add "X-Amz-Signature", valid_611909
  var valid_611910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-Content-Sha256", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Date")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Date", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-Credential")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-Credential", valid_611912
  var valid_611913 = header.getOrDefault("X-Amz-Security-Token")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "X-Amz-Security-Token", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-Algorithm")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Algorithm", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-SignedHeaders", valid_611915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611917: Call_ListFindings_611903; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists Amazon GuardDuty findings for the specified detector ID.
  ## 
  let valid = call_611917.validator(path, query, header, formData, body)
  let scheme = call_611917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611917.url(scheme.get, call_611917.host, call_611917.base,
                         call_611917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611917, url, valid)

proc call*(call_611918: Call_ListFindings_611903; detectorId: string; body: JsonNode;
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
  var path_611919 = newJObject()
  var query_611920 = newJObject()
  var body_611921 = newJObject()
  add(query_611920, "MaxResults", newJString(MaxResults))
  add(path_611919, "detectorId", newJString(detectorId))
  add(query_611920, "NextToken", newJString(NextToken))
  if body != nil:
    body_611921 = body
  result = call_611918.call(path_611919, query_611920, nil, nil, body_611921)

var listFindings* = Call_ListFindings_611903(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings", validator: validate_ListFindings_611904,
    base: "/", url: url_ListFindings_611905, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_611922 = ref object of OpenApiRestCall_610658
proc url_ListInvitations_611924(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInvitations_611923(path: JsonNode; query: JsonNode;
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
  var valid_611925 = query.getOrDefault("nextToken")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "nextToken", valid_611925
  var valid_611926 = query.getOrDefault("MaxResults")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "MaxResults", valid_611926
  var valid_611927 = query.getOrDefault("NextToken")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "NextToken", valid_611927
  var valid_611928 = query.getOrDefault("maxResults")
  valid_611928 = validateParameter(valid_611928, JInt, required = false, default = nil)
  if valid_611928 != nil:
    section.add "maxResults", valid_611928
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
  var valid_611929 = header.getOrDefault("X-Amz-Signature")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-Signature", valid_611929
  var valid_611930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-Content-Sha256", valid_611930
  var valid_611931 = header.getOrDefault("X-Amz-Date")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-Date", valid_611931
  var valid_611932 = header.getOrDefault("X-Amz-Credential")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "X-Amz-Credential", valid_611932
  var valid_611933 = header.getOrDefault("X-Amz-Security-Token")
  valid_611933 = validateParameter(valid_611933, JString, required = false,
                                 default = nil)
  if valid_611933 != nil:
    section.add "X-Amz-Security-Token", valid_611933
  var valid_611934 = header.getOrDefault("X-Amz-Algorithm")
  valid_611934 = validateParameter(valid_611934, JString, required = false,
                                 default = nil)
  if valid_611934 != nil:
    section.add "X-Amz-Algorithm", valid_611934
  var valid_611935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611935 = validateParameter(valid_611935, JString, required = false,
                                 default = nil)
  if valid_611935 != nil:
    section.add "X-Amz-SignedHeaders", valid_611935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611936: Call_ListInvitations_611922; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all GuardDuty membership invitations that were sent to the current AWS account.
  ## 
  let valid = call_611936.validator(path, query, header, formData, body)
  let scheme = call_611936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611936.url(scheme.get, call_611936.host, call_611936.base,
                         call_611936.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611936, url, valid)

proc call*(call_611937: Call_ListInvitations_611922; nextToken: string = "";
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
  var query_611938 = newJObject()
  add(query_611938, "nextToken", newJString(nextToken))
  add(query_611938, "MaxResults", newJString(MaxResults))
  add(query_611938, "NextToken", newJString(NextToken))
  add(query_611938, "maxResults", newJInt(maxResults))
  result = call_611937.call(nil, query_611938, nil, nil, nil)

var listInvitations* = Call_ListInvitations_611922(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com", route: "/invitation",
    validator: validate_ListInvitations_611923, base: "/", url: url_ListInvitations_611924,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611953 = ref object of OpenApiRestCall_610658
proc url_TagResource_611955(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_611954(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611956 = path.getOrDefault("resourceArn")
  valid_611956 = validateParameter(valid_611956, JString, required = true,
                                 default = nil)
  if valid_611956 != nil:
    section.add "resourceArn", valid_611956
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
  var valid_611957 = header.getOrDefault("X-Amz-Signature")
  valid_611957 = validateParameter(valid_611957, JString, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "X-Amz-Signature", valid_611957
  var valid_611958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611958 = validateParameter(valid_611958, JString, required = false,
                                 default = nil)
  if valid_611958 != nil:
    section.add "X-Amz-Content-Sha256", valid_611958
  var valid_611959 = header.getOrDefault("X-Amz-Date")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Date", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-Credential")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-Credential", valid_611960
  var valid_611961 = header.getOrDefault("X-Amz-Security-Token")
  valid_611961 = validateParameter(valid_611961, JString, required = false,
                                 default = nil)
  if valid_611961 != nil:
    section.add "X-Amz-Security-Token", valid_611961
  var valid_611962 = header.getOrDefault("X-Amz-Algorithm")
  valid_611962 = validateParameter(valid_611962, JString, required = false,
                                 default = nil)
  if valid_611962 != nil:
    section.add "X-Amz-Algorithm", valid_611962
  var valid_611963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611963 = validateParameter(valid_611963, JString, required = false,
                                 default = nil)
  if valid_611963 != nil:
    section.add "X-Amz-SignedHeaders", valid_611963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611965: Call_TagResource_611953; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource.
  ## 
  let valid = call_611965.validator(path, query, header, formData, body)
  let scheme = call_611965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611965.url(scheme.get, call_611965.host, call_611965.base,
                         call_611965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611965, url, valid)

proc call*(call_611966: Call_TagResource_611953; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the GuardDuty resource to apply a tag to.
  ##   body: JObject (required)
  var path_611967 = newJObject()
  var body_611968 = newJObject()
  add(path_611967, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_611968 = body
  result = call_611966.call(path_611967, nil, nil, nil, body_611968)

var tagResource* = Call_TagResource_611953(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_611954,
                                        base: "/", url: url_TagResource_611955,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611939 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611941(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_611940(path: JsonNode; query: JsonNode;
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
  var valid_611942 = path.getOrDefault("resourceArn")
  valid_611942 = validateParameter(valid_611942, JString, required = true,
                                 default = nil)
  if valid_611942 != nil:
    section.add "resourceArn", valid_611942
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
  var valid_611943 = header.getOrDefault("X-Amz-Signature")
  valid_611943 = validateParameter(valid_611943, JString, required = false,
                                 default = nil)
  if valid_611943 != nil:
    section.add "X-Amz-Signature", valid_611943
  var valid_611944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "X-Amz-Content-Sha256", valid_611944
  var valid_611945 = header.getOrDefault("X-Amz-Date")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Date", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-Credential")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-Credential", valid_611946
  var valid_611947 = header.getOrDefault("X-Amz-Security-Token")
  valid_611947 = validateParameter(valid_611947, JString, required = false,
                                 default = nil)
  if valid_611947 != nil:
    section.add "X-Amz-Security-Token", valid_611947
  var valid_611948 = header.getOrDefault("X-Amz-Algorithm")
  valid_611948 = validateParameter(valid_611948, JString, required = false,
                                 default = nil)
  if valid_611948 != nil:
    section.add "X-Amz-Algorithm", valid_611948
  var valid_611949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611949 = validateParameter(valid_611949, JString, required = false,
                                 default = nil)
  if valid_611949 != nil:
    section.add "X-Amz-SignedHeaders", valid_611949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611950: Call_ListTagsForResource_611939; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
  ## 
  let valid = call_611950.validator(path, query, header, formData, body)
  let scheme = call_611950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611950.url(scheme.get, call_611950.host, call_611950.base,
                         call_611950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611950, url, valid)

proc call*(call_611951: Call_ListTagsForResource_611939; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the given GuardDuty resource 
  var path_611952 = newJObject()
  add(path_611952, "resourceArn", newJString(resourceArn))
  result = call_611951.call(path_611952, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611939(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_611940, base: "/",
    url: url_ListTagsForResource_611941, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringMembers_611969 = ref object of OpenApiRestCall_610658
proc url_StartMonitoringMembers_611971(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartMonitoringMembers_611970(path: JsonNode; query: JsonNode;
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
  var valid_611972 = path.getOrDefault("detectorId")
  valid_611972 = validateParameter(valid_611972, JString, required = true,
                                 default = nil)
  if valid_611972 != nil:
    section.add "detectorId", valid_611972
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
  var valid_611973 = header.getOrDefault("X-Amz-Signature")
  valid_611973 = validateParameter(valid_611973, JString, required = false,
                                 default = nil)
  if valid_611973 != nil:
    section.add "X-Amz-Signature", valid_611973
  var valid_611974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "X-Amz-Content-Sha256", valid_611974
  var valid_611975 = header.getOrDefault("X-Amz-Date")
  valid_611975 = validateParameter(valid_611975, JString, required = false,
                                 default = nil)
  if valid_611975 != nil:
    section.add "X-Amz-Date", valid_611975
  var valid_611976 = header.getOrDefault("X-Amz-Credential")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "X-Amz-Credential", valid_611976
  var valid_611977 = header.getOrDefault("X-Amz-Security-Token")
  valid_611977 = validateParameter(valid_611977, JString, required = false,
                                 default = nil)
  if valid_611977 != nil:
    section.add "X-Amz-Security-Token", valid_611977
  var valid_611978 = header.getOrDefault("X-Amz-Algorithm")
  valid_611978 = validateParameter(valid_611978, JString, required = false,
                                 default = nil)
  if valid_611978 != nil:
    section.add "X-Amz-Algorithm", valid_611978
  var valid_611979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611979 = validateParameter(valid_611979, JString, required = false,
                                 default = nil)
  if valid_611979 != nil:
    section.add "X-Amz-SignedHeaders", valid_611979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611981: Call_StartMonitoringMembers_611969; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Turns on GuardDuty monitoring of the specified member accounts. Use this operation to restart monitoring of accounts that you stopped monitoring with the <code>StopMonitoringMembers</code> operation.
  ## 
  let valid = call_611981.validator(path, query, header, formData, body)
  let scheme = call_611981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611981.url(scheme.get, call_611981.host, call_611981.base,
                         call_611981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611981, url, valid)

proc call*(call_611982: Call_StartMonitoringMembers_611969; detectorId: string;
          body: JsonNode): Recallable =
  ## startMonitoringMembers
  ## Turns on GuardDuty monitoring of the specified member accounts. Use this operation to restart monitoring of accounts that you stopped monitoring with the <code>StopMonitoringMembers</code> operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty master account associated with the member accounts to monitor.
  ##   body: JObject (required)
  var path_611983 = newJObject()
  var body_611984 = newJObject()
  add(path_611983, "detectorId", newJString(detectorId))
  if body != nil:
    body_611984 = body
  result = call_611982.call(path_611983, nil, nil, nil, body_611984)

var startMonitoringMembers* = Call_StartMonitoringMembers_611969(
    name: "startMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/start",
    validator: validate_StartMonitoringMembers_611970, base: "/",
    url: url_StartMonitoringMembers_611971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringMembers_611985 = ref object of OpenApiRestCall_610658
proc url_StopMonitoringMembers_611987(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopMonitoringMembers_611986(path: JsonNode; query: JsonNode;
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
  var valid_611988 = path.getOrDefault("detectorId")
  valid_611988 = validateParameter(valid_611988, JString, required = true,
                                 default = nil)
  if valid_611988 != nil:
    section.add "detectorId", valid_611988
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
  var valid_611989 = header.getOrDefault("X-Amz-Signature")
  valid_611989 = validateParameter(valid_611989, JString, required = false,
                                 default = nil)
  if valid_611989 != nil:
    section.add "X-Amz-Signature", valid_611989
  var valid_611990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Content-Sha256", valid_611990
  var valid_611991 = header.getOrDefault("X-Amz-Date")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "X-Amz-Date", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-Credential")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Credential", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-Security-Token")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-Security-Token", valid_611993
  var valid_611994 = header.getOrDefault("X-Amz-Algorithm")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "X-Amz-Algorithm", valid_611994
  var valid_611995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "X-Amz-SignedHeaders", valid_611995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611997: Call_StopMonitoringMembers_611985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops GuardDuty monitoring for the specified member accounnts. Use the <code>StartMonitoringMembers</code> to restart monitoring for those accounts.
  ## 
  let valid = call_611997.validator(path, query, header, formData, body)
  let scheme = call_611997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611997.url(scheme.get, call_611997.host, call_611997.base,
                         call_611997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611997, url, valid)

proc call*(call_611998: Call_StopMonitoringMembers_611985; detectorId: string;
          body: JsonNode): Recallable =
  ## stopMonitoringMembers
  ## Stops GuardDuty monitoring for the specified member accounnts. Use the <code>StartMonitoringMembers</code> to restart monitoring for those accounts.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account that you want to stop from monitor members' findings.
  ##   body: JObject (required)
  var path_611999 = newJObject()
  var body_612000 = newJObject()
  add(path_611999, "detectorId", newJString(detectorId))
  if body != nil:
    body_612000 = body
  result = call_611998.call(path_611999, nil, nil, nil, body_612000)

var stopMonitoringMembers* = Call_StopMonitoringMembers_611985(
    name: "stopMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/stop",
    validator: validate_StopMonitoringMembers_611986, base: "/",
    url: url_StopMonitoringMembers_611987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnarchiveFindings_612001 = ref object of OpenApiRestCall_610658
proc url_UnarchiveFindings_612003(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UnarchiveFindings_612002(path: JsonNode; query: JsonNode;
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
  var valid_612004 = path.getOrDefault("detectorId")
  valid_612004 = validateParameter(valid_612004, JString, required = true,
                                 default = nil)
  if valid_612004 != nil:
    section.add "detectorId", valid_612004
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
  var valid_612005 = header.getOrDefault("X-Amz-Signature")
  valid_612005 = validateParameter(valid_612005, JString, required = false,
                                 default = nil)
  if valid_612005 != nil:
    section.add "X-Amz-Signature", valid_612005
  var valid_612006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "X-Amz-Content-Sha256", valid_612006
  var valid_612007 = header.getOrDefault("X-Amz-Date")
  valid_612007 = validateParameter(valid_612007, JString, required = false,
                                 default = nil)
  if valid_612007 != nil:
    section.add "X-Amz-Date", valid_612007
  var valid_612008 = header.getOrDefault("X-Amz-Credential")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "X-Amz-Credential", valid_612008
  var valid_612009 = header.getOrDefault("X-Amz-Security-Token")
  valid_612009 = validateParameter(valid_612009, JString, required = false,
                                 default = nil)
  if valid_612009 != nil:
    section.add "X-Amz-Security-Token", valid_612009
  var valid_612010 = header.getOrDefault("X-Amz-Algorithm")
  valid_612010 = validateParameter(valid_612010, JString, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "X-Amz-Algorithm", valid_612010
  var valid_612011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "X-Amz-SignedHeaders", valid_612011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612013: Call_UnarchiveFindings_612001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Unarchives GuardDuty findings specified by the <code>findingIds</code>.
  ## 
  let valid = call_612013.validator(path, query, header, formData, body)
  let scheme = call_612013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612013.url(scheme.get, call_612013.host, call_612013.base,
                         call_612013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612013, url, valid)

proc call*(call_612014: Call_UnarchiveFindings_612001; detectorId: string;
          body: JsonNode): Recallable =
  ## unarchiveFindings
  ## Unarchives GuardDuty findings specified by the <code>findingIds</code>.
  ##   detectorId: string (required)
  ##             : The ID of the detector associated with the findings to unarchive.
  ##   body: JObject (required)
  var path_612015 = newJObject()
  var body_612016 = newJObject()
  add(path_612015, "detectorId", newJString(detectorId))
  if body != nil:
    body_612016 = body
  result = call_612014.call(path_612015, nil, nil, nil, body_612016)

var unarchiveFindings* = Call_UnarchiveFindings_612001(name: "unarchiveFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/unarchive",
    validator: validate_UnarchiveFindings_612002, base: "/",
    url: url_UnarchiveFindings_612003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_612017 = ref object of OpenApiRestCall_610658
proc url_UntagResource_612019(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_612018(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612020 = path.getOrDefault("resourceArn")
  valid_612020 = validateParameter(valid_612020, JString, required = true,
                                 default = nil)
  if valid_612020 != nil:
    section.add "resourceArn", valid_612020
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_612021 = query.getOrDefault("tagKeys")
  valid_612021 = validateParameter(valid_612021, JArray, required = true, default = nil)
  if valid_612021 != nil:
    section.add "tagKeys", valid_612021
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
  var valid_612022 = header.getOrDefault("X-Amz-Signature")
  valid_612022 = validateParameter(valid_612022, JString, required = false,
                                 default = nil)
  if valid_612022 != nil:
    section.add "X-Amz-Signature", valid_612022
  var valid_612023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "X-Amz-Content-Sha256", valid_612023
  var valid_612024 = header.getOrDefault("X-Amz-Date")
  valid_612024 = validateParameter(valid_612024, JString, required = false,
                                 default = nil)
  if valid_612024 != nil:
    section.add "X-Amz-Date", valid_612024
  var valid_612025 = header.getOrDefault("X-Amz-Credential")
  valid_612025 = validateParameter(valid_612025, JString, required = false,
                                 default = nil)
  if valid_612025 != nil:
    section.add "X-Amz-Credential", valid_612025
  var valid_612026 = header.getOrDefault("X-Amz-Security-Token")
  valid_612026 = validateParameter(valid_612026, JString, required = false,
                                 default = nil)
  if valid_612026 != nil:
    section.add "X-Amz-Security-Token", valid_612026
  var valid_612027 = header.getOrDefault("X-Amz-Algorithm")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "X-Amz-Algorithm", valid_612027
  var valid_612028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-SignedHeaders", valid_612028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612029: Call_UntagResource_612017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_612029.validator(path, query, header, formData, body)
  let scheme = call_612029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612029.url(scheme.get, call_612029.host, call_612029.base,
                         call_612029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612029, url, valid)

proc call*(call_612030: Call_UntagResource_612017; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the resource to remove tags from.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the resource.
  var path_612031 = newJObject()
  var query_612032 = newJObject()
  add(path_612031, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_612032.add "tagKeys", tagKeys
  result = call_612030.call(path_612031, query_612032, nil, nil, nil)

var untagResource* = Call_UntagResource_612017(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_612018,
    base: "/", url: url_UntagResource_612019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindingsFeedback_612033 = ref object of OpenApiRestCall_610658
proc url_UpdateFindingsFeedback_612035(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFindingsFeedback_612034(path: JsonNode; query: JsonNode;
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
  var valid_612036 = path.getOrDefault("detectorId")
  valid_612036 = validateParameter(valid_612036, JString, required = true,
                                 default = nil)
  if valid_612036 != nil:
    section.add "detectorId", valid_612036
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
  var valid_612037 = header.getOrDefault("X-Amz-Signature")
  valid_612037 = validateParameter(valid_612037, JString, required = false,
                                 default = nil)
  if valid_612037 != nil:
    section.add "X-Amz-Signature", valid_612037
  var valid_612038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612038 = validateParameter(valid_612038, JString, required = false,
                                 default = nil)
  if valid_612038 != nil:
    section.add "X-Amz-Content-Sha256", valid_612038
  var valid_612039 = header.getOrDefault("X-Amz-Date")
  valid_612039 = validateParameter(valid_612039, JString, required = false,
                                 default = nil)
  if valid_612039 != nil:
    section.add "X-Amz-Date", valid_612039
  var valid_612040 = header.getOrDefault("X-Amz-Credential")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "X-Amz-Credential", valid_612040
  var valid_612041 = header.getOrDefault("X-Amz-Security-Token")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "X-Amz-Security-Token", valid_612041
  var valid_612042 = header.getOrDefault("X-Amz-Algorithm")
  valid_612042 = validateParameter(valid_612042, JString, required = false,
                                 default = nil)
  if valid_612042 != nil:
    section.add "X-Amz-Algorithm", valid_612042
  var valid_612043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "X-Amz-SignedHeaders", valid_612043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612045: Call_UpdateFindingsFeedback_612033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Marks the specified GuardDuty findings as useful or not useful.
  ## 
  let valid = call_612045.validator(path, query, header, formData, body)
  let scheme = call_612045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612045.url(scheme.get, call_612045.host, call_612045.base,
                         call_612045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612045, url, valid)

proc call*(call_612046: Call_UpdateFindingsFeedback_612033; detectorId: string;
          body: JsonNode): Recallable =
  ## updateFindingsFeedback
  ## Marks the specified GuardDuty findings as useful or not useful.
  ##   detectorId: string (required)
  ##             : The ID of the detector associated with the findings to update feedback for.
  ##   body: JObject (required)
  var path_612047 = newJObject()
  var body_612048 = newJObject()
  add(path_612047, "detectorId", newJString(detectorId))
  if body != nil:
    body_612048 = body
  result = call_612046.call(path_612047, nil, nil, nil, body_612048)

var updateFindingsFeedback* = Call_UpdateFindingsFeedback_612033(
    name: "updateFindingsFeedback", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/feedback",
    validator: validate_UpdateFindingsFeedback_612034, base: "/",
    url: url_UpdateFindingsFeedback_612035, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
