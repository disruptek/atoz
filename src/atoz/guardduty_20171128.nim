
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_AcceptInvitation_613266 = ref object of OpenApiRestCall_612658
proc url_AcceptInvitation_613268(protocol: Scheme; host: string; base: string;
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

proc validate_AcceptInvitation_613267(path: JsonNode; query: JsonNode;
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
  var valid_613269 = path.getOrDefault("detectorId")
  valid_613269 = validateParameter(valid_613269, JString, required = true,
                                 default = nil)
  if valid_613269 != nil:
    section.add "detectorId", valid_613269
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
  var valid_613270 = header.getOrDefault("X-Amz-Signature")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Signature", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Content-Sha256", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Date")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Date", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Credential")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Credential", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Security-Token")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Security-Token", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Algorithm")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Algorithm", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-SignedHeaders", valid_613276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613278: Call_AcceptInvitation_613266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts the invitation to be monitored by a master GuardDuty account.
  ## 
  let valid = call_613278.validator(path, query, header, formData, body)
  let scheme = call_613278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613278.url(scheme.get, call_613278.host, call_613278.base,
                         call_613278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613278, url, valid)

proc call*(call_613279: Call_AcceptInvitation_613266; detectorId: string;
          body: JsonNode): Recallable =
  ## acceptInvitation
  ## Accepts the invitation to be monitored by a master GuardDuty account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  ##   body: JObject (required)
  var path_613280 = newJObject()
  var body_613281 = newJObject()
  add(path_613280, "detectorId", newJString(detectorId))
  if body != nil:
    body_613281 = body
  result = call_613279.call(path_613280, nil, nil, nil, body_613281)

var acceptInvitation* = Call_AcceptInvitation_613266(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master", validator: validate_AcceptInvitation_613267,
    base: "/", url: url_AcceptInvitation_613268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_612996 = ref object of OpenApiRestCall_612658
proc url_GetMasterAccount_612998(protocol: Scheme; host: string; base: string;
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

proc validate_GetMasterAccount_612997(path: JsonNode; query: JsonNode;
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
  var valid_613124 = path.getOrDefault("detectorId")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "detectorId", valid_613124
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
  var valid_613125 = header.getOrDefault("X-Amz-Signature")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "X-Amz-Signature", valid_613125
  var valid_613126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Content-Sha256", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Date")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Date", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Credential")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Credential", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Security-Token")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Security-Token", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Algorithm")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Algorithm", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-SignedHeaders", valid_613131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613154: Call_GetMasterAccount_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
  ## 
  let valid = call_613154.validator(path, query, header, formData, body)
  let scheme = call_613154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613154.url(scheme.get, call_613154.host, call_613154.base,
                         call_613154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613154, url, valid)

proc call*(call_613225: Call_GetMasterAccount_612996; detectorId: string): Recallable =
  ## getMasterAccount
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  var path_613226 = newJObject()
  add(path_613226, "detectorId", newJString(detectorId))
  result = call_613225.call(path_613226, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_612996(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master", validator: validate_GetMasterAccount_612997,
    base: "/", url: url_GetMasterAccount_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ArchiveFindings_613282 = ref object of OpenApiRestCall_612658
proc url_ArchiveFindings_613284(protocol: Scheme; host: string; base: string;
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

proc validate_ArchiveFindings_613283(path: JsonNode; query: JsonNode;
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
  var valid_613285 = path.getOrDefault("detectorId")
  valid_613285 = validateParameter(valid_613285, JString, required = true,
                                 default = nil)
  if valid_613285 != nil:
    section.add "detectorId", valid_613285
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
  var valid_613286 = header.getOrDefault("X-Amz-Signature")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Signature", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Content-Sha256", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Date")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Date", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Credential")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Credential", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Security-Token")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Security-Token", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Algorithm")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Algorithm", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-SignedHeaders", valid_613292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613294: Call_ArchiveFindings_613282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
  ## 
  let valid = call_613294.validator(path, query, header, formData, body)
  let scheme = call_613294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613294.url(scheme.get, call_613294.host, call_613294.base,
                         call_613294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613294, url, valid)

proc call*(call_613295: Call_ArchiveFindings_613282; detectorId: string;
          body: JsonNode): Recallable =
  ## archiveFindings
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to archive.
  ##   body: JObject (required)
  var path_613296 = newJObject()
  var body_613297 = newJObject()
  add(path_613296, "detectorId", newJString(detectorId))
  if body != nil:
    body_613297 = body
  result = call_613295.call(path_613296, nil, nil, nil, body_613297)

var archiveFindings* = Call_ArchiveFindings_613282(name: "archiveFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/archive",
    validator: validate_ArchiveFindings_613283, base: "/", url: url_ArchiveFindings_613284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDetector_613315 = ref object of OpenApiRestCall_612658
proc url_CreateDetector_613317(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDetector_613316(path: JsonNode; query: JsonNode;
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
  var valid_613318 = header.getOrDefault("X-Amz-Signature")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Signature", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-Content-Sha256", valid_613319
  var valid_613320 = header.getOrDefault("X-Amz-Date")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Date", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Credential")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Credential", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Security-Token")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Security-Token", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Algorithm")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Algorithm", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-SignedHeaders", valid_613324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613326: Call_CreateDetector_613315; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
  ## 
  let valid = call_613326.validator(path, query, header, formData, body)
  let scheme = call_613326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613326.url(scheme.get, call_613326.host, call_613326.base,
                         call_613326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613326, url, valid)

proc call*(call_613327: Call_CreateDetector_613315; body: JsonNode): Recallable =
  ## createDetector
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
  ##   body: JObject (required)
  var body_613328 = newJObject()
  if body != nil:
    body_613328 = body
  result = call_613327.call(nil, nil, nil, nil, body_613328)

var createDetector* = Call_CreateDetector_613315(name: "createDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com", route: "/detector",
    validator: validate_CreateDetector_613316, base: "/", url: url_CreateDetector_613317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectors_613298 = ref object of OpenApiRestCall_612658
proc url_ListDetectors_613300(protocol: Scheme; host: string; base: string;
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

proc validate_ListDetectors_613299(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613301 = query.getOrDefault("nextToken")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "nextToken", valid_613301
  var valid_613302 = query.getOrDefault("MaxResults")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "MaxResults", valid_613302
  var valid_613303 = query.getOrDefault("NextToken")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "NextToken", valid_613303
  var valid_613304 = query.getOrDefault("maxResults")
  valid_613304 = validateParameter(valid_613304, JInt, required = false, default = nil)
  if valid_613304 != nil:
    section.add "maxResults", valid_613304
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
  var valid_613305 = header.getOrDefault("X-Amz-Signature")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Signature", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Content-Sha256", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Date")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Date", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Credential")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Credential", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Security-Token")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Security-Token", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Algorithm")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Algorithm", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-SignedHeaders", valid_613311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613312: Call_ListDetectors_613298; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists detectorIds of all the existing Amazon GuardDuty detector resources.
  ## 
  let valid = call_613312.validator(path, query, header, formData, body)
  let scheme = call_613312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613312.url(scheme.get, call_613312.host, call_613312.base,
                         call_613312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613312, url, valid)

proc call*(call_613313: Call_ListDetectors_613298; nextToken: string = "";
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
  var query_613314 = newJObject()
  add(query_613314, "nextToken", newJString(nextToken))
  add(query_613314, "MaxResults", newJString(MaxResults))
  add(query_613314, "NextToken", newJString(NextToken))
  add(query_613314, "maxResults", newJInt(maxResults))
  result = call_613313.call(nil, query_613314, nil, nil, nil)

var listDetectors* = Call_ListDetectors_613298(name: "listDetectors",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com", route: "/detector",
    validator: validate_ListDetectors_613299, base: "/", url: url_ListDetectors_613300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFilter_613348 = ref object of OpenApiRestCall_612658
proc url_CreateFilter_613350(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFilter_613349(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613351 = path.getOrDefault("detectorId")
  valid_613351 = validateParameter(valid_613351, JString, required = true,
                                 default = nil)
  if valid_613351 != nil:
    section.add "detectorId", valid_613351
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
  var valid_613352 = header.getOrDefault("X-Amz-Signature")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Signature", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Content-Sha256", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Date")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Date", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Credential")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Credential", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Security-Token")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Security-Token", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Algorithm")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Algorithm", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-SignedHeaders", valid_613358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613360: Call_CreateFilter_613348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a filter using the specified finding criteria.
  ## 
  let valid = call_613360.validator(path, query, header, formData, body)
  let scheme = call_613360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613360.url(scheme.get, call_613360.host, call_613360.base,
                         call_613360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613360, url, valid)

proc call*(call_613361: Call_CreateFilter_613348; detectorId: string; body: JsonNode): Recallable =
  ## createFilter
  ## Creates a filter using the specified finding criteria.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create a filter.
  ##   body: JObject (required)
  var path_613362 = newJObject()
  var body_613363 = newJObject()
  add(path_613362, "detectorId", newJString(detectorId))
  if body != nil:
    body_613363 = body
  result = call_613361.call(path_613362, nil, nil, nil, body_613363)

var createFilter* = Call_CreateFilter_613348(name: "createFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter", validator: validate_CreateFilter_613349,
    base: "/", url: url_CreateFilter_613350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFilters_613329 = ref object of OpenApiRestCall_612658
proc url_ListFilters_613331(protocol: Scheme; host: string; base: string;
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

proc validate_ListFilters_613330(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613332 = path.getOrDefault("detectorId")
  valid_613332 = validateParameter(valid_613332, JString, required = true,
                                 default = nil)
  if valid_613332 != nil:
    section.add "detectorId", valid_613332
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
  var valid_613333 = query.getOrDefault("nextToken")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "nextToken", valid_613333
  var valid_613334 = query.getOrDefault("MaxResults")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "MaxResults", valid_613334
  var valid_613335 = query.getOrDefault("NextToken")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "NextToken", valid_613335
  var valid_613336 = query.getOrDefault("maxResults")
  valid_613336 = validateParameter(valid_613336, JInt, required = false, default = nil)
  if valid_613336 != nil:
    section.add "maxResults", valid_613336
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
  var valid_613337 = header.getOrDefault("X-Amz-Signature")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Signature", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Content-Sha256", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Date")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Date", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Credential")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Credential", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Security-Token")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Security-Token", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Algorithm")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Algorithm", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-SignedHeaders", valid_613343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613344: Call_ListFilters_613329; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of the current filters.
  ## 
  let valid = call_613344.validator(path, query, header, formData, body)
  let scheme = call_613344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613344.url(scheme.get, call_613344.host, call_613344.base,
                         call_613344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613344, url, valid)

proc call*(call_613345: Call_ListFilters_613329; detectorId: string;
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
  var path_613346 = newJObject()
  var query_613347 = newJObject()
  add(query_613347, "nextToken", newJString(nextToken))
  add(query_613347, "MaxResults", newJString(MaxResults))
  add(path_613346, "detectorId", newJString(detectorId))
  add(query_613347, "NextToken", newJString(NextToken))
  add(query_613347, "maxResults", newJInt(maxResults))
  result = call_613345.call(path_613346, query_613347, nil, nil, nil)

var listFilters* = Call_ListFilters_613329(name: "listFilters",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/filter",
                                        validator: validate_ListFilters_613330,
                                        base: "/", url: url_ListFilters_613331,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIPSet_613383 = ref object of OpenApiRestCall_612658
proc url_CreateIPSet_613385(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIPSet_613384(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613386 = path.getOrDefault("detectorId")
  valid_613386 = validateParameter(valid_613386, JString, required = true,
                                 default = nil)
  if valid_613386 != nil:
    section.add "detectorId", valid_613386
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
  var valid_613387 = header.getOrDefault("X-Amz-Signature")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Signature", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Content-Sha256", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Date")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Date", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Credential")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Credential", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Security-Token")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Security-Token", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Algorithm")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Algorithm", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-SignedHeaders", valid_613393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613395: Call_CreateIPSet_613383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new IPSet, called Trusted IP list in the consoler user interface. An IPSet is a list IP addresses trusted for secure communication with AWS infrastructure and applications. GuardDuty does not generate findings for IP addresses included in IPSets. Only users from the master account can use this operation.
  ## 
  let valid = call_613395.validator(path, query, header, formData, body)
  let scheme = call_613395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613395.url(scheme.get, call_613395.host, call_613395.base,
                         call_613395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613395, url, valid)

proc call*(call_613396: Call_CreateIPSet_613383; detectorId: string; body: JsonNode): Recallable =
  ## createIPSet
  ## Creates a new IPSet, called Trusted IP list in the consoler user interface. An IPSet is a list IP addresses trusted for secure communication with AWS infrastructure and applications. GuardDuty does not generate findings for IP addresses included in IPSets. Only users from the master account can use this operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create an IPSet.
  ##   body: JObject (required)
  var path_613397 = newJObject()
  var body_613398 = newJObject()
  add(path_613397, "detectorId", newJString(detectorId))
  if body != nil:
    body_613398 = body
  result = call_613396.call(path_613397, nil, nil, nil, body_613398)

var createIPSet* = Call_CreateIPSet_613383(name: "createIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/ipset",
                                        validator: validate_CreateIPSet_613384,
                                        base: "/", url: url_CreateIPSet_613385,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIPSets_613364 = ref object of OpenApiRestCall_612658
proc url_ListIPSets_613366(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListIPSets_613365(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613367 = path.getOrDefault("detectorId")
  valid_613367 = validateParameter(valid_613367, JString, required = true,
                                 default = nil)
  if valid_613367 != nil:
    section.add "detectorId", valid_613367
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
  var valid_613368 = query.getOrDefault("nextToken")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "nextToken", valid_613368
  var valid_613369 = query.getOrDefault("MaxResults")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "MaxResults", valid_613369
  var valid_613370 = query.getOrDefault("NextToken")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "NextToken", valid_613370
  var valid_613371 = query.getOrDefault("maxResults")
  valid_613371 = validateParameter(valid_613371, JInt, required = false, default = nil)
  if valid_613371 != nil:
    section.add "maxResults", valid_613371
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
  var valid_613372 = header.getOrDefault("X-Amz-Signature")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Signature", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Content-Sha256", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Date")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Date", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Credential")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Credential", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Security-Token")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Security-Token", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Algorithm")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Algorithm", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-SignedHeaders", valid_613378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613379: Call_ListIPSets_613364; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the IPSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the IPSets returned are the IPSets from the associated master account.
  ## 
  let valid = call_613379.validator(path, query, header, formData, body)
  let scheme = call_613379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613379.url(scheme.get, call_613379.host, call_613379.base,
                         call_613379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613379, url, valid)

proc call*(call_613380: Call_ListIPSets_613364; detectorId: string;
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
  var path_613381 = newJObject()
  var query_613382 = newJObject()
  add(query_613382, "nextToken", newJString(nextToken))
  add(query_613382, "MaxResults", newJString(MaxResults))
  add(path_613381, "detectorId", newJString(detectorId))
  add(query_613382, "NextToken", newJString(NextToken))
  add(query_613382, "maxResults", newJInt(maxResults))
  result = call_613380.call(path_613381, query_613382, nil, nil, nil)

var listIPSets* = Call_ListIPSets_613364(name: "listIPSets",
                                      meth: HttpMethod.HttpGet,
                                      host: "guardduty.amazonaws.com",
                                      route: "/detector/{detectorId}/ipset",
                                      validator: validate_ListIPSets_613365,
                                      base: "/", url: url_ListIPSets_613366,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_613419 = ref object of OpenApiRestCall_612658
proc url_CreateMembers_613421(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMembers_613420(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613422 = path.getOrDefault("detectorId")
  valid_613422 = validateParameter(valid_613422, JString, required = true,
                                 default = nil)
  if valid_613422 != nil:
    section.add "detectorId", valid_613422
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
  var valid_613423 = header.getOrDefault("X-Amz-Signature")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Signature", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Content-Sha256", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Date")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Date", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-Credential")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Credential", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-Security-Token")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Security-Token", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Algorithm")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Algorithm", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-SignedHeaders", valid_613429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613431: Call_CreateMembers_613419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
  ## 
  let valid = call_613431.validator(path, query, header, formData, body)
  let scheme = call_613431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613431.url(scheme.get, call_613431.host, call_613431.base,
                         call_613431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613431, url, valid)

proc call*(call_613432: Call_CreateMembers_613419; detectorId: string; body: JsonNode): Recallable =
  ## createMembers
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account with which you want to associate member accounts.
  ##   body: JObject (required)
  var path_613433 = newJObject()
  var body_613434 = newJObject()
  add(path_613433, "detectorId", newJString(detectorId))
  if body != nil:
    body_613434 = body
  result = call_613432.call(path_613433, nil, nil, nil, body_613434)

var createMembers* = Call_CreateMembers_613419(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member", validator: validate_CreateMembers_613420,
    base: "/", url: url_CreateMembers_613421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_613399 = ref object of OpenApiRestCall_612658
proc url_ListMembers_613401(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_613400(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613402 = path.getOrDefault("detectorId")
  valid_613402 = validateParameter(valid_613402, JString, required = true,
                                 default = nil)
  if valid_613402 != nil:
    section.add "detectorId", valid_613402
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
  var valid_613403 = query.getOrDefault("nextToken")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "nextToken", valid_613403
  var valid_613404 = query.getOrDefault("MaxResults")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "MaxResults", valid_613404
  var valid_613405 = query.getOrDefault("NextToken")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "NextToken", valid_613405
  var valid_613406 = query.getOrDefault("onlyAssociated")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "onlyAssociated", valid_613406
  var valid_613407 = query.getOrDefault("maxResults")
  valid_613407 = validateParameter(valid_613407, JInt, required = false, default = nil)
  if valid_613407 != nil:
    section.add "maxResults", valid_613407
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
  var valid_613408 = header.getOrDefault("X-Amz-Signature")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Signature", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Content-Sha256", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-Date")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Date", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Credential")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Credential", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Security-Token")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Security-Token", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Algorithm")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Algorithm", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-SignedHeaders", valid_613414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613415: Call_ListMembers_613399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current GuardDuty master account.
  ## 
  let valid = call_613415.validator(path, query, header, formData, body)
  let scheme = call_613415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613415.url(scheme.get, call_613415.host, call_613415.base,
                         call_613415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613415, url, valid)

proc call*(call_613416: Call_ListMembers_613399; detectorId: string;
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
  var path_613417 = newJObject()
  var query_613418 = newJObject()
  add(query_613418, "nextToken", newJString(nextToken))
  add(query_613418, "MaxResults", newJString(MaxResults))
  add(path_613417, "detectorId", newJString(detectorId))
  add(query_613418, "NextToken", newJString(NextToken))
  add(query_613418, "onlyAssociated", newJString(onlyAssociated))
  add(query_613418, "maxResults", newJInt(maxResults))
  result = call_613416.call(path_613417, query_613418, nil, nil, nil)

var listMembers* = Call_ListMembers_613399(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/member",
                                        validator: validate_ListMembers_613400,
                                        base: "/", url: url_ListMembers_613401,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublishingDestination_613454 = ref object of OpenApiRestCall_612658
proc url_CreatePublishingDestination_613456(protocol: Scheme; host: string;
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

proc validate_CreatePublishingDestination_613455(path: JsonNode; query: JsonNode;
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
  var valid_613457 = path.getOrDefault("detectorId")
  valid_613457 = validateParameter(valid_613457, JString, required = true,
                                 default = nil)
  if valid_613457 != nil:
    section.add "detectorId", valid_613457
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
  var valid_613458 = header.getOrDefault("X-Amz-Signature")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Signature", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Content-Sha256", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Date")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Date", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Credential")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Credential", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Security-Token")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Security-Token", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Algorithm")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Algorithm", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-SignedHeaders", valid_613464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613466: Call_CreatePublishingDestination_613454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a publishing destination to send findings to. The resource to send findings to must exist before you use this operation.
  ## 
  let valid = call_613466.validator(path, query, header, formData, body)
  let scheme = call_613466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613466.url(scheme.get, call_613466.host, call_613466.base,
                         call_613466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613466, url, valid)

proc call*(call_613467: Call_CreatePublishingDestination_613454;
          detectorId: string; body: JsonNode): Recallable =
  ## createPublishingDestination
  ## Creates a publishing destination to send findings to. The resource to send findings to must exist before you use this operation.
  ##   detectorId: string (required)
  ##             : The ID of the GuardDuty detector associated with the publishing destination.
  ##   body: JObject (required)
  var path_613468 = newJObject()
  var body_613469 = newJObject()
  add(path_613468, "detectorId", newJString(detectorId))
  if body != nil:
    body_613469 = body
  result = call_613467.call(path_613468, nil, nil, nil, body_613469)

var createPublishingDestination* = Call_CreatePublishingDestination_613454(
    name: "createPublishingDestination", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination",
    validator: validate_CreatePublishingDestination_613455, base: "/",
    url: url_CreatePublishingDestination_613456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishingDestinations_613435 = ref object of OpenApiRestCall_612658
proc url_ListPublishingDestinations_613437(protocol: Scheme; host: string;
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

proc validate_ListPublishingDestinations_613436(path: JsonNode; query: JsonNode;
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
  var valid_613438 = path.getOrDefault("detectorId")
  valid_613438 = validateParameter(valid_613438, JString, required = true,
                                 default = nil)
  if valid_613438 != nil:
    section.add "detectorId", valid_613438
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
  var valid_613439 = query.getOrDefault("nextToken")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "nextToken", valid_613439
  var valid_613440 = query.getOrDefault("MaxResults")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "MaxResults", valid_613440
  var valid_613441 = query.getOrDefault("NextToken")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "NextToken", valid_613441
  var valid_613442 = query.getOrDefault("maxResults")
  valid_613442 = validateParameter(valid_613442, JInt, required = false, default = nil)
  if valid_613442 != nil:
    section.add "maxResults", valid_613442
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
  var valid_613443 = header.getOrDefault("X-Amz-Signature")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Signature", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Content-Sha256", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Date")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Date", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Credential")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Credential", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Security-Token")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Security-Token", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Algorithm")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Algorithm", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-SignedHeaders", valid_613449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613450: Call_ListPublishingDestinations_613435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of publishing destinations associated with the specified <code>dectectorId</code>.
  ## 
  let valid = call_613450.validator(path, query, header, formData, body)
  let scheme = call_613450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613450.url(scheme.get, call_613450.host, call_613450.base,
                         call_613450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613450, url, valid)

proc call*(call_613451: Call_ListPublishingDestinations_613435; detectorId: string;
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
  var path_613452 = newJObject()
  var query_613453 = newJObject()
  add(query_613453, "nextToken", newJString(nextToken))
  add(query_613453, "MaxResults", newJString(MaxResults))
  add(path_613452, "detectorId", newJString(detectorId))
  add(query_613453, "NextToken", newJString(NextToken))
  add(query_613453, "maxResults", newJInt(maxResults))
  result = call_613451.call(path_613452, query_613453, nil, nil, nil)

var listPublishingDestinations* = Call_ListPublishingDestinations_613435(
    name: "listPublishingDestinations", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination",
    validator: validate_ListPublishingDestinations_613436, base: "/",
    url: url_ListPublishingDestinations_613437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSampleFindings_613470 = ref object of OpenApiRestCall_612658
proc url_CreateSampleFindings_613472(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSampleFindings_613471(path: JsonNode; query: JsonNode;
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
  var valid_613473 = path.getOrDefault("detectorId")
  valid_613473 = validateParameter(valid_613473, JString, required = true,
                                 default = nil)
  if valid_613473 != nil:
    section.add "detectorId", valid_613473
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
  var valid_613474 = header.getOrDefault("X-Amz-Signature")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Signature", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Content-Sha256", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Date")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Date", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Credential")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Credential", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-Security-Token")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Security-Token", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Algorithm")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Algorithm", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-SignedHeaders", valid_613480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613482: Call_CreateSampleFindings_613470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for <code>findingTypes</code>, the API generates example findings of all supported finding types.
  ## 
  let valid = call_613482.validator(path, query, header, formData, body)
  let scheme = call_613482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613482.url(scheme.get, call_613482.host, call_613482.base,
                         call_613482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613482, url, valid)

proc call*(call_613483: Call_CreateSampleFindings_613470; detectorId: string;
          body: JsonNode): Recallable =
  ## createSampleFindings
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for <code>findingTypes</code>, the API generates example findings of all supported finding types.
  ##   detectorId: string (required)
  ##             : The ID of the detector to create sample findings for.
  ##   body: JObject (required)
  var path_613484 = newJObject()
  var body_613485 = newJObject()
  add(path_613484, "detectorId", newJString(detectorId))
  if body != nil:
    body_613485 = body
  result = call_613483.call(path_613484, nil, nil, nil, body_613485)

var createSampleFindings* = Call_CreateSampleFindings_613470(
    name: "createSampleFindings", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/create",
    validator: validate_CreateSampleFindings_613471, base: "/",
    url: url_CreateSampleFindings_613472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateThreatIntelSet_613505 = ref object of OpenApiRestCall_612658
proc url_CreateThreatIntelSet_613507(protocol: Scheme; host: string; base: string;
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

proc validate_CreateThreatIntelSet_613506(path: JsonNode; query: JsonNode;
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
  var valid_613508 = path.getOrDefault("detectorId")
  valid_613508 = validateParameter(valid_613508, JString, required = true,
                                 default = nil)
  if valid_613508 != nil:
    section.add "detectorId", valid_613508
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
  var valid_613509 = header.getOrDefault("X-Amz-Signature")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Signature", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Content-Sha256", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Date")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Date", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Credential")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Credential", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Security-Token")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Security-Token", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Algorithm")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Algorithm", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-SignedHeaders", valid_613515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613517: Call_CreateThreatIntelSet_613505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets. Only users of the master account can use this operation.
  ## 
  let valid = call_613517.validator(path, query, header, formData, body)
  let scheme = call_613517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613517.url(scheme.get, call_613517.host, call_613517.base,
                         call_613517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613517, url, valid)

proc call*(call_613518: Call_CreateThreatIntelSet_613505; detectorId: string;
          body: JsonNode): Recallable =
  ## createThreatIntelSet
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets. Only users of the master account can use this operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create a threatIntelSet.
  ##   body: JObject (required)
  var path_613519 = newJObject()
  var body_613520 = newJObject()
  add(path_613519, "detectorId", newJString(detectorId))
  if body != nil:
    body_613520 = body
  result = call_613518.call(path_613519, nil, nil, nil, body_613520)

var createThreatIntelSet* = Call_CreateThreatIntelSet_613505(
    name: "createThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_CreateThreatIntelSet_613506, base: "/",
    url: url_CreateThreatIntelSet_613507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListThreatIntelSets_613486 = ref object of OpenApiRestCall_612658
proc url_ListThreatIntelSets_613488(protocol: Scheme; host: string; base: string;
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

proc validate_ListThreatIntelSets_613487(path: JsonNode; query: JsonNode;
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
  var valid_613489 = path.getOrDefault("detectorId")
  valid_613489 = validateParameter(valid_613489, JString, required = true,
                                 default = nil)
  if valid_613489 != nil:
    section.add "detectorId", valid_613489
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
  var valid_613490 = query.getOrDefault("nextToken")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "nextToken", valid_613490
  var valid_613491 = query.getOrDefault("MaxResults")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "MaxResults", valid_613491
  var valid_613492 = query.getOrDefault("NextToken")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "NextToken", valid_613492
  var valid_613493 = query.getOrDefault("maxResults")
  valid_613493 = validateParameter(valid_613493, JInt, required = false, default = nil)
  if valid_613493 != nil:
    section.add "maxResults", valid_613493
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
  var valid_613494 = header.getOrDefault("X-Amz-Signature")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Signature", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Content-Sha256", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Date")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Date", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Credential")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Credential", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Security-Token")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Security-Token", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Algorithm")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Algorithm", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-SignedHeaders", valid_613500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613501: Call_ListThreatIntelSets_613486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the ThreatIntelSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the ThreatIntelSets associated with the master account are returned.
  ## 
  let valid = call_613501.validator(path, query, header, formData, body)
  let scheme = call_613501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613501.url(scheme.get, call_613501.host, call_613501.base,
                         call_613501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613501, url, valid)

proc call*(call_613502: Call_ListThreatIntelSets_613486; detectorId: string;
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
  var path_613503 = newJObject()
  var query_613504 = newJObject()
  add(query_613504, "nextToken", newJString(nextToken))
  add(query_613504, "MaxResults", newJString(MaxResults))
  add(path_613503, "detectorId", newJString(detectorId))
  add(query_613504, "NextToken", newJString(NextToken))
  add(query_613504, "maxResults", newJInt(maxResults))
  result = call_613502.call(path_613503, query_613504, nil, nil, nil)

var listThreatIntelSets* = Call_ListThreatIntelSets_613486(
    name: "listThreatIntelSets", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_ListThreatIntelSets_613487, base: "/",
    url: url_ListThreatIntelSets_613488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_613521 = ref object of OpenApiRestCall_612658
proc url_DeclineInvitations_613523(protocol: Scheme; host: string; base: string;
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

proc validate_DeclineInvitations_613522(path: JsonNode; query: JsonNode;
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
  var valid_613524 = header.getOrDefault("X-Amz-Signature")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Signature", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Content-Sha256", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Date")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Date", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Credential")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Credential", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Security-Token")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Security-Token", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Algorithm")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Algorithm", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-SignedHeaders", valid_613530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613532: Call_DeclineInvitations_613521; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
  ## 
  let valid = call_613532.validator(path, query, header, formData, body)
  let scheme = call_613532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613532.url(scheme.get, call_613532.host, call_613532.base,
                         call_613532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613532, url, valid)

proc call*(call_613533: Call_DeclineInvitations_613521; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
  ##   body: JObject (required)
  var body_613534 = newJObject()
  if body != nil:
    body_613534 = body
  result = call_613533.call(nil, nil, nil, nil, body_613534)

var declineInvitations* = Call_DeclineInvitations_613521(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/invitation/decline",
    validator: validate_DeclineInvitations_613522, base: "/",
    url: url_DeclineInvitations_613523, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetector_613549 = ref object of OpenApiRestCall_612658
proc url_UpdateDetector_613551(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDetector_613550(path: JsonNode; query: JsonNode;
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
  var valid_613552 = path.getOrDefault("detectorId")
  valid_613552 = validateParameter(valid_613552, JString, required = true,
                                 default = nil)
  if valid_613552 != nil:
    section.add "detectorId", valid_613552
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
  var valid_613553 = header.getOrDefault("X-Amz-Signature")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Signature", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Content-Sha256", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Date")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Date", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Credential")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Credential", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Security-Token")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Security-Token", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Algorithm")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Algorithm", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-SignedHeaders", valid_613559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613561: Call_UpdateDetector_613549; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Amazon GuardDuty detector specified by the detectorId.
  ## 
  let valid = call_613561.validator(path, query, header, formData, body)
  let scheme = call_613561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613561.url(scheme.get, call_613561.host, call_613561.base,
                         call_613561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613561, url, valid)

proc call*(call_613562: Call_UpdateDetector_613549; detectorId: string;
          body: JsonNode): Recallable =
  ## updateDetector
  ## Updates the Amazon GuardDuty detector specified by the detectorId.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector to update.
  ##   body: JObject (required)
  var path_613563 = newJObject()
  var body_613564 = newJObject()
  add(path_613563, "detectorId", newJString(detectorId))
  if body != nil:
    body_613564 = body
  result = call_613562.call(path_613563, nil, nil, nil, body_613564)

var updateDetector* = Call_UpdateDetector_613549(name: "updateDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_UpdateDetector_613550,
    base: "/", url: url_UpdateDetector_613551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetector_613535 = ref object of OpenApiRestCall_612658
proc url_GetDetector_613537(protocol: Scheme; host: string; base: string;
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

proc validate_GetDetector_613536(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613538 = path.getOrDefault("detectorId")
  valid_613538 = validateParameter(valid_613538, JString, required = true,
                                 default = nil)
  if valid_613538 != nil:
    section.add "detectorId", valid_613538
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
  var valid_613539 = header.getOrDefault("X-Amz-Signature")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Signature", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Content-Sha256", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Date")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Date", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Credential")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Credential", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Security-Token")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Security-Token", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Algorithm")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Algorithm", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-SignedHeaders", valid_613545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613546: Call_GetDetector_613535; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
  ## 
  let valid = call_613546.validator(path, query, header, formData, body)
  let scheme = call_613546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613546.url(scheme.get, call_613546.host, call_613546.base,
                         call_613546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613546, url, valid)

proc call*(call_613547: Call_GetDetector_613535; detectorId: string): Recallable =
  ## getDetector
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that you want to get.
  var path_613548 = newJObject()
  add(path_613548, "detectorId", newJString(detectorId))
  result = call_613547.call(path_613548, nil, nil, nil, nil)

var getDetector* = Call_GetDetector_613535(name: "getDetector",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}",
                                        validator: validate_GetDetector_613536,
                                        base: "/", url: url_GetDetector_613537,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetector_613565 = ref object of OpenApiRestCall_612658
proc url_DeleteDetector_613567(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDetector_613566(path: JsonNode; query: JsonNode;
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
  var valid_613568 = path.getOrDefault("detectorId")
  valid_613568 = validateParameter(valid_613568, JString, required = true,
                                 default = nil)
  if valid_613568 != nil:
    section.add "detectorId", valid_613568
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
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613576: Call_DeleteDetector_613565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
  ## 
  let valid = call_613576.validator(path, query, header, formData, body)
  let scheme = call_613576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613576.url(scheme.get, call_613576.host, call_613576.base,
                         call_613576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613576, url, valid)

proc call*(call_613577: Call_DeleteDetector_613565; detectorId: string): Recallable =
  ## deleteDetector
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that you want to delete.
  var path_613578 = newJObject()
  add(path_613578, "detectorId", newJString(detectorId))
  result = call_613577.call(path_613578, nil, nil, nil, nil)

var deleteDetector* = Call_DeleteDetector_613565(name: "deleteDetector",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_DeleteDetector_613566,
    base: "/", url: url_DeleteDetector_613567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFilter_613594 = ref object of OpenApiRestCall_612658
proc url_UpdateFilter_613596(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFilter_613595(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613597 = path.getOrDefault("detectorId")
  valid_613597 = validateParameter(valid_613597, JString, required = true,
                                 default = nil)
  if valid_613597 != nil:
    section.add "detectorId", valid_613597
  var valid_613598 = path.getOrDefault("filterName")
  valid_613598 = validateParameter(valid_613598, JString, required = true,
                                 default = nil)
  if valid_613598 != nil:
    section.add "filterName", valid_613598
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
  var valid_613599 = header.getOrDefault("X-Amz-Signature")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Signature", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Content-Sha256", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Date")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Date", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Credential")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Credential", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Security-Token")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Security-Token", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Algorithm")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Algorithm", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-SignedHeaders", valid_613605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613607: Call_UpdateFilter_613594; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the filter specified by the filter name.
  ## 
  let valid = call_613607.validator(path, query, header, formData, body)
  let scheme = call_613607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613607.url(scheme.get, call_613607.host, call_613607.base,
                         call_613607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613607, url, valid)

proc call*(call_613608: Call_UpdateFilter_613594; detectorId: string;
          filterName: string; body: JsonNode): Recallable =
  ## updateFilter
  ## Updates the filter specified by the filter name.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that specifies the GuardDuty service where you want to update a filter.
  ##   filterName: string (required)
  ##             : The name of the filter.
  ##   body: JObject (required)
  var path_613609 = newJObject()
  var body_613610 = newJObject()
  add(path_613609, "detectorId", newJString(detectorId))
  add(path_613609, "filterName", newJString(filterName))
  if body != nil:
    body_613610 = body
  result = call_613608.call(path_613609, nil, nil, nil, body_613610)

var updateFilter* = Call_UpdateFilter_613594(name: "updateFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_UpdateFilter_613595, base: "/", url: url_UpdateFilter_613596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFilter_613579 = ref object of OpenApiRestCall_612658
proc url_GetFilter_613581(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetFilter_613580(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613582 = path.getOrDefault("detectorId")
  valid_613582 = validateParameter(valid_613582, JString, required = true,
                                 default = nil)
  if valid_613582 != nil:
    section.add "detectorId", valid_613582
  var valid_613583 = path.getOrDefault("filterName")
  valid_613583 = validateParameter(valid_613583, JString, required = true,
                                 default = nil)
  if valid_613583 != nil:
    section.add "filterName", valid_613583
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
  var valid_613584 = header.getOrDefault("X-Amz-Signature")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Signature", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Content-Sha256", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Date")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Date", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Credential")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Credential", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Security-Token")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Security-Token", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Algorithm")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Algorithm", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-SignedHeaders", valid_613590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613591: Call_GetFilter_613579; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of the filter specified by the filter name.
  ## 
  let valid = call_613591.validator(path, query, header, formData, body)
  let scheme = call_613591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613591.url(scheme.get, call_613591.host, call_613591.base,
                         call_613591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613591, url, valid)

proc call*(call_613592: Call_GetFilter_613579; detectorId: string; filterName: string): Recallable =
  ## getFilter
  ## Returns the details of the filter specified by the filter name.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  ##   filterName: string (required)
  ##             : The name of the filter you want to get.
  var path_613593 = newJObject()
  add(path_613593, "detectorId", newJString(detectorId))
  add(path_613593, "filterName", newJString(filterName))
  result = call_613592.call(path_613593, nil, nil, nil, nil)

var getFilter* = Call_GetFilter_613579(name: "getFilter", meth: HttpMethod.HttpGet,
                                    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/filter/{filterName}",
                                    validator: validate_GetFilter_613580,
                                    base: "/", url: url_GetFilter_613581,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFilter_613611 = ref object of OpenApiRestCall_612658
proc url_DeleteFilter_613613(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFilter_613612(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613614 = path.getOrDefault("detectorId")
  valid_613614 = validateParameter(valid_613614, JString, required = true,
                                 default = nil)
  if valid_613614 != nil:
    section.add "detectorId", valid_613614
  var valid_613615 = path.getOrDefault("filterName")
  valid_613615 = validateParameter(valid_613615, JString, required = true,
                                 default = nil)
  if valid_613615 != nil:
    section.add "filterName", valid_613615
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
  var valid_613616 = header.getOrDefault("X-Amz-Signature")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Signature", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Content-Sha256", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Date")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Date", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Credential")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Credential", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Security-Token")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Security-Token", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Algorithm")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Algorithm", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-SignedHeaders", valid_613622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613623: Call_DeleteFilter_613611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the filter specified by the filter name.
  ## 
  let valid = call_613623.validator(path, query, header, formData, body)
  let scheme = call_613623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613623.url(scheme.get, call_613623.host, call_613623.base,
                         call_613623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613623, url, valid)

proc call*(call_613624: Call_DeleteFilter_613611; detectorId: string;
          filterName: string): Recallable =
  ## deleteFilter
  ## Deletes the filter specified by the filter name.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  ##   filterName: string (required)
  ##             : The name of the filter you want to delete.
  var path_613625 = newJObject()
  add(path_613625, "detectorId", newJString(detectorId))
  add(path_613625, "filterName", newJString(filterName))
  result = call_613624.call(path_613625, nil, nil, nil, nil)

var deleteFilter* = Call_DeleteFilter_613611(name: "deleteFilter",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_DeleteFilter_613612, base: "/", url: url_DeleteFilter_613613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIPSet_613641 = ref object of OpenApiRestCall_612658
proc url_UpdateIPSet_613643(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIPSet_613642(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613644 = path.getOrDefault("ipSetId")
  valid_613644 = validateParameter(valid_613644, JString, required = true,
                                 default = nil)
  if valid_613644 != nil:
    section.add "ipSetId", valid_613644
  var valid_613645 = path.getOrDefault("detectorId")
  valid_613645 = validateParameter(valid_613645, JString, required = true,
                                 default = nil)
  if valid_613645 != nil:
    section.add "detectorId", valid_613645
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
  var valid_613646 = header.getOrDefault("X-Amz-Signature")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Signature", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-Content-Sha256", valid_613647
  var valid_613648 = header.getOrDefault("X-Amz-Date")
  valid_613648 = validateParameter(valid_613648, JString, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "X-Amz-Date", valid_613648
  var valid_613649 = header.getOrDefault("X-Amz-Credential")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "X-Amz-Credential", valid_613649
  var valid_613650 = header.getOrDefault("X-Amz-Security-Token")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Security-Token", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Algorithm")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Algorithm", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-SignedHeaders", valid_613652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613654: Call_UpdateIPSet_613641; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the IPSet specified by the IPSet ID.
  ## 
  let valid = call_613654.validator(path, query, header, formData, body)
  let scheme = call_613654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613654.url(scheme.get, call_613654.host, call_613654.base,
                         call_613654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613654, url, valid)

proc call*(call_613655: Call_UpdateIPSet_613641; ipSetId: string; detectorId: string;
          body: JsonNode): Recallable =
  ## updateIPSet
  ## Updates the IPSet specified by the IPSet ID.
  ##   ipSetId: string (required)
  ##          : The unique ID that specifies the IPSet that you want to update.
  ##   detectorId: string (required)
  ##             : The detectorID that specifies the GuardDuty service whose IPSet you want to update.
  ##   body: JObject (required)
  var path_613656 = newJObject()
  var body_613657 = newJObject()
  add(path_613656, "ipSetId", newJString(ipSetId))
  add(path_613656, "detectorId", newJString(detectorId))
  if body != nil:
    body_613657 = body
  result = call_613655.call(path_613656, nil, nil, nil, body_613657)

var updateIPSet* = Call_UpdateIPSet_613641(name: "updateIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                        validator: validate_UpdateIPSet_613642,
                                        base: "/", url: url_UpdateIPSet_613643,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIPSet_613626 = ref object of OpenApiRestCall_612658
proc url_GetIPSet_613628(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetIPSet_613627(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613629 = path.getOrDefault("ipSetId")
  valid_613629 = validateParameter(valid_613629, JString, required = true,
                                 default = nil)
  if valid_613629 != nil:
    section.add "ipSetId", valid_613629
  var valid_613630 = path.getOrDefault("detectorId")
  valid_613630 = validateParameter(valid_613630, JString, required = true,
                                 default = nil)
  if valid_613630 != nil:
    section.add "detectorId", valid_613630
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
  var valid_613631 = header.getOrDefault("X-Amz-Signature")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Signature", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Content-Sha256", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-Date")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Date", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Credential")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Credential", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Security-Token")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Security-Token", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Algorithm")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Algorithm", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-SignedHeaders", valid_613637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613638: Call_GetIPSet_613626; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
  ## 
  let valid = call_613638.validator(path, query, header, formData, body)
  let scheme = call_613638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613638.url(scheme.get, call_613638.host, call_613638.base,
                         call_613638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613638, url, valid)

proc call*(call_613639: Call_GetIPSet_613626; ipSetId: string; detectorId: string): Recallable =
  ## getIPSet
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
  ##   ipSetId: string (required)
  ##          : The unique ID of the IPSet to retrieve.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the ipSet is associated with.
  var path_613640 = newJObject()
  add(path_613640, "ipSetId", newJString(ipSetId))
  add(path_613640, "detectorId", newJString(detectorId))
  result = call_613639.call(path_613640, nil, nil, nil, nil)

var getIPSet* = Call_GetIPSet_613626(name: "getIPSet", meth: HttpMethod.HttpGet,
                                  host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                  validator: validate_GetIPSet_613627, base: "/",
                                  url: url_GetIPSet_613628,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIPSet_613658 = ref object of OpenApiRestCall_612658
proc url_DeleteIPSet_613660(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIPSet_613659(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613661 = path.getOrDefault("ipSetId")
  valid_613661 = validateParameter(valid_613661, JString, required = true,
                                 default = nil)
  if valid_613661 != nil:
    section.add "ipSetId", valid_613661
  var valid_613662 = path.getOrDefault("detectorId")
  valid_613662 = validateParameter(valid_613662, JString, required = true,
                                 default = nil)
  if valid_613662 != nil:
    section.add "detectorId", valid_613662
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
  var valid_613663 = header.getOrDefault("X-Amz-Signature")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Signature", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Content-Sha256", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Date")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Date", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Credential")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Credential", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Security-Token")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Security-Token", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Algorithm")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Algorithm", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-SignedHeaders", valid_613669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613670: Call_DeleteIPSet_613658; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
  ## 
  let valid = call_613670.validator(path, query, header, formData, body)
  let scheme = call_613670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613670.url(scheme.get, call_613670.host, call_613670.base,
                         call_613670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613670, url, valid)

proc call*(call_613671: Call_DeleteIPSet_613658; ipSetId: string; detectorId: string): Recallable =
  ## deleteIPSet
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
  ##   ipSetId: string (required)
  ##          : The unique ID of the IPSet to delete.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the IPSet.
  var path_613672 = newJObject()
  add(path_613672, "ipSetId", newJString(ipSetId))
  add(path_613672, "detectorId", newJString(detectorId))
  result = call_613671.call(path_613672, nil, nil, nil, nil)

var deleteIPSet* = Call_DeleteIPSet_613658(name: "deleteIPSet",
                                        meth: HttpMethod.HttpDelete,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                        validator: validate_DeleteIPSet_613659,
                                        base: "/", url: url_DeleteIPSet_613660,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_613673 = ref object of OpenApiRestCall_612658
proc url_DeleteInvitations_613675(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInvitations_613674(path: JsonNode; query: JsonNode;
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
  var valid_613676 = header.getOrDefault("X-Amz-Signature")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Signature", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Content-Sha256", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Date")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Date", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Credential")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Credential", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-Security-Token")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Security-Token", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Algorithm")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Algorithm", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-SignedHeaders", valid_613682
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613684: Call_DeleteInvitations_613673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
  ## 
  let valid = call_613684.validator(path, query, header, formData, body)
  let scheme = call_613684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613684.url(scheme.get, call_613684.host, call_613684.base,
                         call_613684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613684, url, valid)

proc call*(call_613685: Call_DeleteInvitations_613673; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
  ##   body: JObject (required)
  var body_613686 = newJObject()
  if body != nil:
    body_613686 = body
  result = call_613685.call(nil, nil, nil, nil, body_613686)

var deleteInvitations* = Call_DeleteInvitations_613673(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/invitation/delete", validator: validate_DeleteInvitations_613674,
    base: "/", url: url_DeleteInvitations_613675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_613687 = ref object of OpenApiRestCall_612658
proc url_DeleteMembers_613689(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMembers_613688(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613690 = path.getOrDefault("detectorId")
  valid_613690 = validateParameter(valid_613690, JString, required = true,
                                 default = nil)
  if valid_613690 != nil:
    section.add "detectorId", valid_613690
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
  var valid_613691 = header.getOrDefault("X-Amz-Signature")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Signature", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Content-Sha256", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Date")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Date", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Credential")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Credential", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Security-Token")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Security-Token", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Algorithm")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Algorithm", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-SignedHeaders", valid_613697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613699: Call_DeleteMembers_613687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_613699.validator(path, query, header, formData, body)
  let scheme = call_613699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613699.url(scheme.get, call_613699.host, call_613699.base,
                         call_613699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613699, url, valid)

proc call*(call_613700: Call_DeleteMembers_613687; detectorId: string; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to delete.
  ##   body: JObject (required)
  var path_613701 = newJObject()
  var body_613702 = newJObject()
  add(path_613701, "detectorId", newJString(detectorId))
  if body != nil:
    body_613702 = body
  result = call_613700.call(path_613701, nil, nil, nil, body_613702)

var deleteMembers* = Call_DeleteMembers_613687(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/delete",
    validator: validate_DeleteMembers_613688, base: "/", url: url_DeleteMembers_613689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePublishingDestination_613718 = ref object of OpenApiRestCall_612658
proc url_UpdatePublishingDestination_613720(protocol: Scheme; host: string;
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

proc validate_UpdatePublishingDestination_613719(path: JsonNode; query: JsonNode;
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
  var valid_613721 = path.getOrDefault("detectorId")
  valid_613721 = validateParameter(valid_613721, JString, required = true,
                                 default = nil)
  if valid_613721 != nil:
    section.add "detectorId", valid_613721
  var valid_613722 = path.getOrDefault("destinationId")
  valid_613722 = validateParameter(valid_613722, JString, required = true,
                                 default = nil)
  if valid_613722 != nil:
    section.add "destinationId", valid_613722
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
  var valid_613723 = header.getOrDefault("X-Amz-Signature")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Signature", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Content-Sha256", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Date")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Date", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Credential")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Credential", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Security-Token")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Security-Token", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-Algorithm")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Algorithm", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-SignedHeaders", valid_613729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613731: Call_UpdatePublishingDestination_613718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
  ## 
  let valid = call_613731.validator(path, query, header, formData, body)
  let scheme = call_613731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613731.url(scheme.get, call_613731.host, call_613731.base,
                         call_613731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613731, url, valid)

proc call*(call_613732: Call_UpdatePublishingDestination_613718;
          detectorId: string; destinationId: string; body: JsonNode): Recallable =
  ## updatePublishingDestination
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
  ##   detectorId: string (required)
  ##             : The ID of the 
  ##   destinationId: string (required)
  ##                : The ID of the detector associated with the publishing destinations to update.
  ##   body: JObject (required)
  var path_613733 = newJObject()
  var body_613734 = newJObject()
  add(path_613733, "detectorId", newJString(detectorId))
  add(path_613733, "destinationId", newJString(destinationId))
  if body != nil:
    body_613734 = body
  result = call_613732.call(path_613733, nil, nil, nil, body_613734)

var updatePublishingDestination* = Call_UpdatePublishingDestination_613718(
    name: "updatePublishingDestination", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_UpdatePublishingDestination_613719, base: "/",
    url: url_UpdatePublishingDestination_613720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePublishingDestination_613703 = ref object of OpenApiRestCall_612658
proc url_DescribePublishingDestination_613705(protocol: Scheme; host: string;
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

proc validate_DescribePublishingDestination_613704(path: JsonNode; query: JsonNode;
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
  var valid_613706 = path.getOrDefault("detectorId")
  valid_613706 = validateParameter(valid_613706, JString, required = true,
                                 default = nil)
  if valid_613706 != nil:
    section.add "detectorId", valid_613706
  var valid_613707 = path.getOrDefault("destinationId")
  valid_613707 = validateParameter(valid_613707, JString, required = true,
                                 default = nil)
  if valid_613707 != nil:
    section.add "destinationId", valid_613707
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
  var valid_613708 = header.getOrDefault("X-Amz-Signature")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Signature", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Content-Sha256", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Date")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Date", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Credential")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Credential", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Security-Token")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Security-Token", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Algorithm")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Algorithm", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-SignedHeaders", valid_613714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613715: Call_DescribePublishingDestination_613703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
  ## 
  let valid = call_613715.validator(path, query, header, formData, body)
  let scheme = call_613715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613715.url(scheme.get, call_613715.host, call_613715.base,
                         call_613715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613715, url, valid)

proc call*(call_613716: Call_DescribePublishingDestination_613703;
          detectorId: string; destinationId: string): Recallable =
  ## describePublishingDestination
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the publishing destination to retrieve.
  ##   destinationId: string (required)
  ##                : The ID of the publishing destination to retrieve.
  var path_613717 = newJObject()
  add(path_613717, "detectorId", newJString(detectorId))
  add(path_613717, "destinationId", newJString(destinationId))
  result = call_613716.call(path_613717, nil, nil, nil, nil)

var describePublishingDestination* = Call_DescribePublishingDestination_613703(
    name: "describePublishingDestination", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_DescribePublishingDestination_613704, base: "/",
    url: url_DescribePublishingDestination_613705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublishingDestination_613735 = ref object of OpenApiRestCall_612658
proc url_DeletePublishingDestination_613737(protocol: Scheme; host: string;
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

proc validate_DeletePublishingDestination_613736(path: JsonNode; query: JsonNode;
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
  var valid_613738 = path.getOrDefault("detectorId")
  valid_613738 = validateParameter(valid_613738, JString, required = true,
                                 default = nil)
  if valid_613738 != nil:
    section.add "detectorId", valid_613738
  var valid_613739 = path.getOrDefault("destinationId")
  valid_613739 = validateParameter(valid_613739, JString, required = true,
                                 default = nil)
  if valid_613739 != nil:
    section.add "destinationId", valid_613739
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
  var valid_613740 = header.getOrDefault("X-Amz-Signature")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Signature", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Content-Sha256", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Date")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Date", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-Credential")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Credential", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Security-Token")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Security-Token", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Algorithm")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Algorithm", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-SignedHeaders", valid_613746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613747: Call_DeletePublishingDestination_613735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
  ## 
  let valid = call_613747.validator(path, query, header, formData, body)
  let scheme = call_613747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613747.url(scheme.get, call_613747.host, call_613747.base,
                         call_613747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613747, url, valid)

proc call*(call_613748: Call_DeletePublishingDestination_613735;
          detectorId: string; destinationId: string): Recallable =
  ## deletePublishingDestination
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the publishing destination to delete.
  ##   destinationId: string (required)
  ##                : The ID of the publishing destination to delete.
  var path_613749 = newJObject()
  add(path_613749, "detectorId", newJString(detectorId))
  add(path_613749, "destinationId", newJString(destinationId))
  result = call_613748.call(path_613749, nil, nil, nil, nil)

var deletePublishingDestination* = Call_DeletePublishingDestination_613735(
    name: "deletePublishingDestination", meth: HttpMethod.HttpDelete,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_DeletePublishingDestination_613736, base: "/",
    url: url_DeletePublishingDestination_613737,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateThreatIntelSet_613765 = ref object of OpenApiRestCall_612658
proc url_UpdateThreatIntelSet_613767(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateThreatIntelSet_613766(path: JsonNode; query: JsonNode;
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
  var valid_613768 = path.getOrDefault("detectorId")
  valid_613768 = validateParameter(valid_613768, JString, required = true,
                                 default = nil)
  if valid_613768 != nil:
    section.add "detectorId", valid_613768
  var valid_613769 = path.getOrDefault("threatIntelSetId")
  valid_613769 = validateParameter(valid_613769, JString, required = true,
                                 default = nil)
  if valid_613769 != nil:
    section.add "threatIntelSetId", valid_613769
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
  var valid_613770 = header.getOrDefault("X-Amz-Signature")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-Signature", valid_613770
  var valid_613771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613771 = validateParameter(valid_613771, JString, required = false,
                                 default = nil)
  if valid_613771 != nil:
    section.add "X-Amz-Content-Sha256", valid_613771
  var valid_613772 = header.getOrDefault("X-Amz-Date")
  valid_613772 = validateParameter(valid_613772, JString, required = false,
                                 default = nil)
  if valid_613772 != nil:
    section.add "X-Amz-Date", valid_613772
  var valid_613773 = header.getOrDefault("X-Amz-Credential")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Credential", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-Security-Token")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Security-Token", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-Algorithm")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Algorithm", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-SignedHeaders", valid_613776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613778: Call_UpdateThreatIntelSet_613765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ## 
  let valid = call_613778.validator(path, query, header, formData, body)
  let scheme = call_613778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613778.url(scheme.get, call_613778.host, call_613778.base,
                         call_613778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613778, url, valid)

proc call*(call_613779: Call_UpdateThreatIntelSet_613765; detectorId: string;
          body: JsonNode; threatIntelSetId: string): Recallable =
  ## updateThreatIntelSet
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The detectorID that specifies the GuardDuty service whose ThreatIntelSet you want to update.
  ##   body: JObject (required)
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID that specifies the ThreatIntelSet that you want to update.
  var path_613780 = newJObject()
  var body_613781 = newJObject()
  add(path_613780, "detectorId", newJString(detectorId))
  if body != nil:
    body_613781 = body
  add(path_613780, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_613779.call(path_613780, nil, nil, nil, body_613781)

var updateThreatIntelSet* = Call_UpdateThreatIntelSet_613765(
    name: "updateThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_UpdateThreatIntelSet_613766, base: "/",
    url: url_UpdateThreatIntelSet_613767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThreatIntelSet_613750 = ref object of OpenApiRestCall_612658
proc url_GetThreatIntelSet_613752(protocol: Scheme; host: string; base: string;
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

proc validate_GetThreatIntelSet_613751(path: JsonNode; query: JsonNode;
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
  var valid_613753 = path.getOrDefault("detectorId")
  valid_613753 = validateParameter(valid_613753, JString, required = true,
                                 default = nil)
  if valid_613753 != nil:
    section.add "detectorId", valid_613753
  var valid_613754 = path.getOrDefault("threatIntelSetId")
  valid_613754 = validateParameter(valid_613754, JString, required = true,
                                 default = nil)
  if valid_613754 != nil:
    section.add "threatIntelSetId", valid_613754
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
  var valid_613755 = header.getOrDefault("X-Amz-Signature")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-Signature", valid_613755
  var valid_613756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Content-Sha256", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Date")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Date", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Credential")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Credential", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-Security-Token")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Security-Token", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-Algorithm")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Algorithm", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-SignedHeaders", valid_613761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613762: Call_GetThreatIntelSet_613750; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ## 
  let valid = call_613762.validator(path, query, header, formData, body)
  let scheme = call_613762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613762.url(scheme.get, call_613762.host, call_613762.base,
                         call_613762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613762, url, valid)

proc call*(call_613763: Call_GetThreatIntelSet_613750; detectorId: string;
          threatIntelSetId: string): Recallable =
  ## getThreatIntelSet
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID of the threatIntelSet you want to get.
  var path_613764 = newJObject()
  add(path_613764, "detectorId", newJString(detectorId))
  add(path_613764, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_613763.call(path_613764, nil, nil, nil, nil)

var getThreatIntelSet* = Call_GetThreatIntelSet_613750(name: "getThreatIntelSet",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_GetThreatIntelSet_613751, base: "/",
    url: url_GetThreatIntelSet_613752, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteThreatIntelSet_613782 = ref object of OpenApiRestCall_612658
proc url_DeleteThreatIntelSet_613784(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteThreatIntelSet_613783(path: JsonNode; query: JsonNode;
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
  var valid_613785 = path.getOrDefault("detectorId")
  valid_613785 = validateParameter(valid_613785, JString, required = true,
                                 default = nil)
  if valid_613785 != nil:
    section.add "detectorId", valid_613785
  var valid_613786 = path.getOrDefault("threatIntelSetId")
  valid_613786 = validateParameter(valid_613786, JString, required = true,
                                 default = nil)
  if valid_613786 != nil:
    section.add "threatIntelSetId", valid_613786
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
  var valid_613787 = header.getOrDefault("X-Amz-Signature")
  valid_613787 = validateParameter(valid_613787, JString, required = false,
                                 default = nil)
  if valid_613787 != nil:
    section.add "X-Amz-Signature", valid_613787
  var valid_613788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613788 = validateParameter(valid_613788, JString, required = false,
                                 default = nil)
  if valid_613788 != nil:
    section.add "X-Amz-Content-Sha256", valid_613788
  var valid_613789 = header.getOrDefault("X-Amz-Date")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-Date", valid_613789
  var valid_613790 = header.getOrDefault("X-Amz-Credential")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-Credential", valid_613790
  var valid_613791 = header.getOrDefault("X-Amz-Security-Token")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Security-Token", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Algorithm")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Algorithm", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-SignedHeaders", valid_613793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613794: Call_DeleteThreatIntelSet_613782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ## 
  let valid = call_613794.validator(path, query, header, formData, body)
  let scheme = call_613794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613794.url(scheme.get, call_613794.host, call_613794.base,
                         call_613794.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613794, url, valid)

proc call*(call_613795: Call_DeleteThreatIntelSet_613782; detectorId: string;
          threatIntelSetId: string): Recallable =
  ## deleteThreatIntelSet
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID of the threatIntelSet you want to delete.
  var path_613796 = newJObject()
  add(path_613796, "detectorId", newJString(detectorId))
  add(path_613796, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_613795.call(path_613796, nil, nil, nil, nil)

var deleteThreatIntelSet* = Call_DeleteThreatIntelSet_613782(
    name: "deleteThreatIntelSet", meth: HttpMethod.HttpDelete,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_DeleteThreatIntelSet_613783, base: "/",
    url: url_DeleteThreatIntelSet_613784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_613797 = ref object of OpenApiRestCall_612658
proc url_DisassociateFromMasterAccount_613799(protocol: Scheme; host: string;
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

proc validate_DisassociateFromMasterAccount_613798(path: JsonNode; query: JsonNode;
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
  var valid_613800 = path.getOrDefault("detectorId")
  valid_613800 = validateParameter(valid_613800, JString, required = true,
                                 default = nil)
  if valid_613800 != nil:
    section.add "detectorId", valid_613800
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
  var valid_613801 = header.getOrDefault("X-Amz-Signature")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Signature", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Content-Sha256", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Date")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Date", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-Credential")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Credential", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-Security-Token")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-Security-Token", valid_613805
  var valid_613806 = header.getOrDefault("X-Amz-Algorithm")
  valid_613806 = validateParameter(valid_613806, JString, required = false,
                                 default = nil)
  if valid_613806 != nil:
    section.add "X-Amz-Algorithm", valid_613806
  var valid_613807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613807 = validateParameter(valid_613807, JString, required = false,
                                 default = nil)
  if valid_613807 != nil:
    section.add "X-Amz-SignedHeaders", valid_613807
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613808: Call_DisassociateFromMasterAccount_613797; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current GuardDuty member account from its master account.
  ## 
  let valid = call_613808.validator(path, query, header, formData, body)
  let scheme = call_613808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613808.url(scheme.get, call_613808.host, call_613808.base,
                         call_613808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613808, url, valid)

proc call*(call_613809: Call_DisassociateFromMasterAccount_613797;
          detectorId: string): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current GuardDuty member account from its master account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  var path_613810 = newJObject()
  add(path_613810, "detectorId", newJString(detectorId))
  result = call_613809.call(path_613810, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_613797(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_613798, base: "/",
    url: url_DisassociateFromMasterAccount_613799,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_613811 = ref object of OpenApiRestCall_612658
proc url_DisassociateMembers_613813(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateMembers_613812(path: JsonNode; query: JsonNode;
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
  var valid_613814 = path.getOrDefault("detectorId")
  valid_613814 = validateParameter(valid_613814, JString, required = true,
                                 default = nil)
  if valid_613814 != nil:
    section.add "detectorId", valid_613814
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
  var valid_613815 = header.getOrDefault("X-Amz-Signature")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Signature", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Content-Sha256", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Date")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Date", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Credential")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Credential", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-Security-Token")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-Security-Token", valid_613819
  var valid_613820 = header.getOrDefault("X-Amz-Algorithm")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-Algorithm", valid_613820
  var valid_613821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "X-Amz-SignedHeaders", valid_613821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613823: Call_DisassociateMembers_613811; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_613823.validator(path, query, header, formData, body)
  let scheme = call_613823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613823.url(scheme.get, call_613823.host, call_613823.base,
                         call_613823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613823, url, valid)

proc call*(call_613824: Call_DisassociateMembers_613811; detectorId: string;
          body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to disassociate from master.
  ##   body: JObject (required)
  var path_613825 = newJObject()
  var body_613826 = newJObject()
  add(path_613825, "detectorId", newJString(detectorId))
  if body != nil:
    body_613826 = body
  result = call_613824.call(path_613825, nil, nil, nil, body_613826)

var disassociateMembers* = Call_DisassociateMembers_613811(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/disassociate",
    validator: validate_DisassociateMembers_613812, base: "/",
    url: url_DisassociateMembers_613813, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_613827 = ref object of OpenApiRestCall_612658
proc url_GetFindings_613829(protocol: Scheme; host: string; base: string;
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

proc validate_GetFindings_613828(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613830 = path.getOrDefault("detectorId")
  valid_613830 = validateParameter(valid_613830, JString, required = true,
                                 default = nil)
  if valid_613830 != nil:
    section.add "detectorId", valid_613830
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
  var valid_613831 = header.getOrDefault("X-Amz-Signature")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Signature", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Content-Sha256", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Date")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Date", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Credential")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Credential", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-Security-Token")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-Security-Token", valid_613835
  var valid_613836 = header.getOrDefault("X-Amz-Algorithm")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-Algorithm", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-SignedHeaders", valid_613837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613839: Call_GetFindings_613827; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes Amazon GuardDuty findings specified by finding IDs.
  ## 
  let valid = call_613839.validator(path, query, header, formData, body)
  let scheme = call_613839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613839.url(scheme.get, call_613839.host, call_613839.base,
                         call_613839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613839, url, valid)

proc call*(call_613840: Call_GetFindings_613827; detectorId: string; body: JsonNode): Recallable =
  ## getFindings
  ## Describes Amazon GuardDuty findings specified by finding IDs.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to retrieve.
  ##   body: JObject (required)
  var path_613841 = newJObject()
  var body_613842 = newJObject()
  add(path_613841, "detectorId", newJString(detectorId))
  if body != nil:
    body_613842 = body
  result = call_613840.call(path_613841, nil, nil, nil, body_613842)

var getFindings* = Call_GetFindings_613827(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/findings/get",
                                        validator: validate_GetFindings_613828,
                                        base: "/", url: url_GetFindings_613829,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindingsStatistics_613843 = ref object of OpenApiRestCall_612658
proc url_GetFindingsStatistics_613845(protocol: Scheme; host: string; base: string;
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

proc validate_GetFindingsStatistics_613844(path: JsonNode; query: JsonNode;
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
  var valid_613846 = path.getOrDefault("detectorId")
  valid_613846 = validateParameter(valid_613846, JString, required = true,
                                 default = nil)
  if valid_613846 != nil:
    section.add "detectorId", valid_613846
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
  var valid_613847 = header.getOrDefault("X-Amz-Signature")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Signature", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Content-Sha256", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Date")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Date", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Credential")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Credential", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Security-Token")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Security-Token", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-Algorithm")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-Algorithm", valid_613852
  var valid_613853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-SignedHeaders", valid_613853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613855: Call_GetFindingsStatistics_613843; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
  ## 
  let valid = call_613855.validator(path, query, header, formData, body)
  let scheme = call_613855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613855.url(scheme.get, call_613855.host, call_613855.base,
                         call_613855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613855, url, valid)

proc call*(call_613856: Call_GetFindingsStatistics_613843; detectorId: string;
          body: JsonNode): Recallable =
  ## getFindingsStatistics
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings' statistics you want to retrieve.
  ##   body: JObject (required)
  var path_613857 = newJObject()
  var body_613858 = newJObject()
  add(path_613857, "detectorId", newJString(detectorId))
  if body != nil:
    body_613858 = body
  result = call_613856.call(path_613857, nil, nil, nil, body_613858)

var getFindingsStatistics* = Call_GetFindingsStatistics_613843(
    name: "getFindingsStatistics", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/statistics",
    validator: validate_GetFindingsStatistics_613844, base: "/",
    url: url_GetFindingsStatistics_613845, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_613859 = ref object of OpenApiRestCall_612658
proc url_GetInvitationsCount_613861(protocol: Scheme; host: string; base: string;
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

proc validate_GetInvitationsCount_613860(path: JsonNode; query: JsonNode;
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
  var valid_613862 = header.getOrDefault("X-Amz-Signature")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "X-Amz-Signature", valid_613862
  var valid_613863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Content-Sha256", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-Date")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Date", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-Credential")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Credential", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Security-Token")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Security-Token", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Algorithm")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Algorithm", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-SignedHeaders", valid_613868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613869: Call_GetInvitationsCount_613859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
  ## 
  let valid = call_613869.validator(path, query, header, formData, body)
  let scheme = call_613869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613869.url(scheme.get, call_613869.host, call_613869.base,
                         call_613869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613869, url, valid)

proc call*(call_613870: Call_GetInvitationsCount_613859): Recallable =
  ## getInvitationsCount
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
  result = call_613870.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_613859(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/invitation/count",
    validator: validate_GetInvitationsCount_613860, base: "/",
    url: url_GetInvitationsCount_613861, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_613871 = ref object of OpenApiRestCall_612658
proc url_GetMembers_613873(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMembers_613872(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613874 = path.getOrDefault("detectorId")
  valid_613874 = validateParameter(valid_613874, JString, required = true,
                                 default = nil)
  if valid_613874 != nil:
    section.add "detectorId", valid_613874
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
  var valid_613875 = header.getOrDefault("X-Amz-Signature")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-Signature", valid_613875
  var valid_613876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613876 = validateParameter(valid_613876, JString, required = false,
                                 default = nil)
  if valid_613876 != nil:
    section.add "X-Amz-Content-Sha256", valid_613876
  var valid_613877 = header.getOrDefault("X-Amz-Date")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Date", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-Credential")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Credential", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Security-Token")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Security-Token", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-Algorithm")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Algorithm", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-SignedHeaders", valid_613881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613883: Call_GetMembers_613871; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_613883.validator(path, query, header, formData, body)
  let scheme = call_613883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613883.url(scheme.get, call_613883.host, call_613883.base,
                         call_613883.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613883, url, valid)

proc call*(call_613884: Call_GetMembers_613871; detectorId: string; body: JsonNode): Recallable =
  ## getMembers
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to retrieve.
  ##   body: JObject (required)
  var path_613885 = newJObject()
  var body_613886 = newJObject()
  add(path_613885, "detectorId", newJString(detectorId))
  if body != nil:
    body_613886 = body
  result = call_613884.call(path_613885, nil, nil, nil, body_613886)

var getMembers* = Call_GetMembers_613871(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/get",
                                      validator: validate_GetMembers_613872,
                                      base: "/", url: url_GetMembers_613873,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_613887 = ref object of OpenApiRestCall_612658
proc url_InviteMembers_613889(protocol: Scheme; host: string; base: string;
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

proc validate_InviteMembers_613888(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613890 = path.getOrDefault("detectorId")
  valid_613890 = validateParameter(valid_613890, JString, required = true,
                                 default = nil)
  if valid_613890 != nil:
    section.add "detectorId", valid_613890
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
  var valid_613891 = header.getOrDefault("X-Amz-Signature")
  valid_613891 = validateParameter(valid_613891, JString, required = false,
                                 default = nil)
  if valid_613891 != nil:
    section.add "X-Amz-Signature", valid_613891
  var valid_613892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Content-Sha256", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-Date")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Date", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-Credential")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Credential", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-Security-Token")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Security-Token", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-Algorithm")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Algorithm", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-SignedHeaders", valid_613897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613899: Call_InviteMembers_613887; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
  ## 
  let valid = call_613899.validator(path, query, header, formData, body)
  let scheme = call_613899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613899.url(scheme.get, call_613899.host, call_613899.base,
                         call_613899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613899, url, valid)

proc call*(call_613900: Call_InviteMembers_613887; detectorId: string; body: JsonNode): Recallable =
  ## inviteMembers
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account with which you want to invite members.
  ##   body: JObject (required)
  var path_613901 = newJObject()
  var body_613902 = newJObject()
  add(path_613901, "detectorId", newJString(detectorId))
  if body != nil:
    body_613902 = body
  result = call_613900.call(path_613901, nil, nil, nil, body_613902)

var inviteMembers* = Call_InviteMembers_613887(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/invite",
    validator: validate_InviteMembers_613888, base: "/", url: url_InviteMembers_613889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_613903 = ref object of OpenApiRestCall_612658
proc url_ListFindings_613905(protocol: Scheme; host: string; base: string;
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

proc validate_ListFindings_613904(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613906 = path.getOrDefault("detectorId")
  valid_613906 = validateParameter(valid_613906, JString, required = true,
                                 default = nil)
  if valid_613906 != nil:
    section.add "detectorId", valid_613906
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613907 = query.getOrDefault("MaxResults")
  valid_613907 = validateParameter(valid_613907, JString, required = false,
                                 default = nil)
  if valid_613907 != nil:
    section.add "MaxResults", valid_613907
  var valid_613908 = query.getOrDefault("NextToken")
  valid_613908 = validateParameter(valid_613908, JString, required = false,
                                 default = nil)
  if valid_613908 != nil:
    section.add "NextToken", valid_613908
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
  var valid_613909 = header.getOrDefault("X-Amz-Signature")
  valid_613909 = validateParameter(valid_613909, JString, required = false,
                                 default = nil)
  if valid_613909 != nil:
    section.add "X-Amz-Signature", valid_613909
  var valid_613910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Content-Sha256", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Date")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Date", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-Credential")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Credential", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Security-Token")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Security-Token", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-Algorithm")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Algorithm", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-SignedHeaders", valid_613915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613917: Call_ListFindings_613903; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists Amazon GuardDuty findings for the specified detector ID.
  ## 
  let valid = call_613917.validator(path, query, header, formData, body)
  let scheme = call_613917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613917.url(scheme.get, call_613917.host, call_613917.base,
                         call_613917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613917, url, valid)

proc call*(call_613918: Call_ListFindings_613903; detectorId: string; body: JsonNode;
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
  var path_613919 = newJObject()
  var query_613920 = newJObject()
  var body_613921 = newJObject()
  add(query_613920, "MaxResults", newJString(MaxResults))
  add(path_613919, "detectorId", newJString(detectorId))
  add(query_613920, "NextToken", newJString(NextToken))
  if body != nil:
    body_613921 = body
  result = call_613918.call(path_613919, query_613920, nil, nil, body_613921)

var listFindings* = Call_ListFindings_613903(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings", validator: validate_ListFindings_613904,
    base: "/", url: url_ListFindings_613905, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_613922 = ref object of OpenApiRestCall_612658
proc url_ListInvitations_613924(protocol: Scheme; host: string; base: string;
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

proc validate_ListInvitations_613923(path: JsonNode; query: JsonNode;
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
  var valid_613925 = query.getOrDefault("nextToken")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "nextToken", valid_613925
  var valid_613926 = query.getOrDefault("MaxResults")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "MaxResults", valid_613926
  var valid_613927 = query.getOrDefault("NextToken")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "NextToken", valid_613927
  var valid_613928 = query.getOrDefault("maxResults")
  valid_613928 = validateParameter(valid_613928, JInt, required = false, default = nil)
  if valid_613928 != nil:
    section.add "maxResults", valid_613928
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
  var valid_613929 = header.getOrDefault("X-Amz-Signature")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Signature", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Content-Sha256", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-Date")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-Date", valid_613931
  var valid_613932 = header.getOrDefault("X-Amz-Credential")
  valid_613932 = validateParameter(valid_613932, JString, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "X-Amz-Credential", valid_613932
  var valid_613933 = header.getOrDefault("X-Amz-Security-Token")
  valid_613933 = validateParameter(valid_613933, JString, required = false,
                                 default = nil)
  if valid_613933 != nil:
    section.add "X-Amz-Security-Token", valid_613933
  var valid_613934 = header.getOrDefault("X-Amz-Algorithm")
  valid_613934 = validateParameter(valid_613934, JString, required = false,
                                 default = nil)
  if valid_613934 != nil:
    section.add "X-Amz-Algorithm", valid_613934
  var valid_613935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-SignedHeaders", valid_613935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613936: Call_ListInvitations_613922; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all GuardDuty membership invitations that were sent to the current AWS account.
  ## 
  let valid = call_613936.validator(path, query, header, formData, body)
  let scheme = call_613936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613936.url(scheme.get, call_613936.host, call_613936.base,
                         call_613936.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613936, url, valid)

proc call*(call_613937: Call_ListInvitations_613922; nextToken: string = "";
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
  var query_613938 = newJObject()
  add(query_613938, "nextToken", newJString(nextToken))
  add(query_613938, "MaxResults", newJString(MaxResults))
  add(query_613938, "NextToken", newJString(NextToken))
  add(query_613938, "maxResults", newJInt(maxResults))
  result = call_613937.call(nil, query_613938, nil, nil, nil)

var listInvitations* = Call_ListInvitations_613922(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com", route: "/invitation",
    validator: validate_ListInvitations_613923, base: "/", url: url_ListInvitations_613924,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613953 = ref object of OpenApiRestCall_612658
proc url_TagResource_613955(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_613954(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613956 = path.getOrDefault("resourceArn")
  valid_613956 = validateParameter(valid_613956, JString, required = true,
                                 default = nil)
  if valid_613956 != nil:
    section.add "resourceArn", valid_613956
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
  var valid_613957 = header.getOrDefault("X-Amz-Signature")
  valid_613957 = validateParameter(valid_613957, JString, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "X-Amz-Signature", valid_613957
  var valid_613958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613958 = validateParameter(valid_613958, JString, required = false,
                                 default = nil)
  if valid_613958 != nil:
    section.add "X-Amz-Content-Sha256", valid_613958
  var valid_613959 = header.getOrDefault("X-Amz-Date")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Date", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Credential")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Credential", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Security-Token")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Security-Token", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Algorithm")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Algorithm", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-SignedHeaders", valid_613963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613965: Call_TagResource_613953; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource.
  ## 
  let valid = call_613965.validator(path, query, header, formData, body)
  let scheme = call_613965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613965.url(scheme.get, call_613965.host, call_613965.base,
                         call_613965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613965, url, valid)

proc call*(call_613966: Call_TagResource_613953; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the GuardDuty resource to apply a tag to.
  ##   body: JObject (required)
  var path_613967 = newJObject()
  var body_613968 = newJObject()
  add(path_613967, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_613968 = body
  result = call_613966.call(path_613967, nil, nil, nil, body_613968)

var tagResource* = Call_TagResource_613953(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_613954,
                                        base: "/", url: url_TagResource_613955,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613939 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613941(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613940(path: JsonNode; query: JsonNode;
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
  var valid_613942 = path.getOrDefault("resourceArn")
  valid_613942 = validateParameter(valid_613942, JString, required = true,
                                 default = nil)
  if valid_613942 != nil:
    section.add "resourceArn", valid_613942
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
  var valid_613943 = header.getOrDefault("X-Amz-Signature")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-Signature", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Content-Sha256", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Date")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Date", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Credential")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Credential", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Security-Token")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Security-Token", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-Algorithm")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-Algorithm", valid_613948
  var valid_613949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613949 = validateParameter(valid_613949, JString, required = false,
                                 default = nil)
  if valid_613949 != nil:
    section.add "X-Amz-SignedHeaders", valid_613949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613950: Call_ListTagsForResource_613939; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
  ## 
  let valid = call_613950.validator(path, query, header, formData, body)
  let scheme = call_613950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613950.url(scheme.get, call_613950.host, call_613950.base,
                         call_613950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613950, url, valid)

proc call*(call_613951: Call_ListTagsForResource_613939; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the given GuardDuty resource 
  var path_613952 = newJObject()
  add(path_613952, "resourceArn", newJString(resourceArn))
  result = call_613951.call(path_613952, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613939(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_613940, base: "/",
    url: url_ListTagsForResource_613941, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringMembers_613969 = ref object of OpenApiRestCall_612658
proc url_StartMonitoringMembers_613971(protocol: Scheme; host: string; base: string;
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

proc validate_StartMonitoringMembers_613970(path: JsonNode; query: JsonNode;
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
  var valid_613972 = path.getOrDefault("detectorId")
  valid_613972 = validateParameter(valid_613972, JString, required = true,
                                 default = nil)
  if valid_613972 != nil:
    section.add "detectorId", valid_613972
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
  var valid_613973 = header.getOrDefault("X-Amz-Signature")
  valid_613973 = validateParameter(valid_613973, JString, required = false,
                                 default = nil)
  if valid_613973 != nil:
    section.add "X-Amz-Signature", valid_613973
  var valid_613974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "X-Amz-Content-Sha256", valid_613974
  var valid_613975 = header.getOrDefault("X-Amz-Date")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "X-Amz-Date", valid_613975
  var valid_613976 = header.getOrDefault("X-Amz-Credential")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-Credential", valid_613976
  var valid_613977 = header.getOrDefault("X-Amz-Security-Token")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Security-Token", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Algorithm")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Algorithm", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-SignedHeaders", valid_613979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613981: Call_StartMonitoringMembers_613969; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Turns on GuardDuty monitoring of the specified member accounts. Use this operation to restart monitoring of accounts that you stopped monitoring with the <code>StopMonitoringMembers</code> operation.
  ## 
  let valid = call_613981.validator(path, query, header, formData, body)
  let scheme = call_613981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613981.url(scheme.get, call_613981.host, call_613981.base,
                         call_613981.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613981, url, valid)

proc call*(call_613982: Call_StartMonitoringMembers_613969; detectorId: string;
          body: JsonNode): Recallable =
  ## startMonitoringMembers
  ## Turns on GuardDuty monitoring of the specified member accounts. Use this operation to restart monitoring of accounts that you stopped monitoring with the <code>StopMonitoringMembers</code> operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty master account associated with the member accounts to monitor.
  ##   body: JObject (required)
  var path_613983 = newJObject()
  var body_613984 = newJObject()
  add(path_613983, "detectorId", newJString(detectorId))
  if body != nil:
    body_613984 = body
  result = call_613982.call(path_613983, nil, nil, nil, body_613984)

var startMonitoringMembers* = Call_StartMonitoringMembers_613969(
    name: "startMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/start",
    validator: validate_StartMonitoringMembers_613970, base: "/",
    url: url_StartMonitoringMembers_613971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringMembers_613985 = ref object of OpenApiRestCall_612658
proc url_StopMonitoringMembers_613987(protocol: Scheme; host: string; base: string;
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

proc validate_StopMonitoringMembers_613986(path: JsonNode; query: JsonNode;
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
  var valid_613988 = path.getOrDefault("detectorId")
  valid_613988 = validateParameter(valid_613988, JString, required = true,
                                 default = nil)
  if valid_613988 != nil:
    section.add "detectorId", valid_613988
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
  var valid_613989 = header.getOrDefault("X-Amz-Signature")
  valid_613989 = validateParameter(valid_613989, JString, required = false,
                                 default = nil)
  if valid_613989 != nil:
    section.add "X-Amz-Signature", valid_613989
  var valid_613990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Content-Sha256", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-Date")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-Date", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-Credential")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Credential", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Security-Token")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Security-Token", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Algorithm")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Algorithm", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-SignedHeaders", valid_613995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613997: Call_StopMonitoringMembers_613985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops GuardDuty monitoring for the specified member accounnts. Use the <code>StartMonitoringMembers</code> to restart monitoring for those accounts.
  ## 
  let valid = call_613997.validator(path, query, header, formData, body)
  let scheme = call_613997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613997.url(scheme.get, call_613997.host, call_613997.base,
                         call_613997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613997, url, valid)

proc call*(call_613998: Call_StopMonitoringMembers_613985; detectorId: string;
          body: JsonNode): Recallable =
  ## stopMonitoringMembers
  ## Stops GuardDuty monitoring for the specified member accounnts. Use the <code>StartMonitoringMembers</code> to restart monitoring for those accounts.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account that you want to stop from monitor members' findings.
  ##   body: JObject (required)
  var path_613999 = newJObject()
  var body_614000 = newJObject()
  add(path_613999, "detectorId", newJString(detectorId))
  if body != nil:
    body_614000 = body
  result = call_613998.call(path_613999, nil, nil, nil, body_614000)

var stopMonitoringMembers* = Call_StopMonitoringMembers_613985(
    name: "stopMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/stop",
    validator: validate_StopMonitoringMembers_613986, base: "/",
    url: url_StopMonitoringMembers_613987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnarchiveFindings_614001 = ref object of OpenApiRestCall_612658
proc url_UnarchiveFindings_614003(protocol: Scheme; host: string; base: string;
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

proc validate_UnarchiveFindings_614002(path: JsonNode; query: JsonNode;
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
  var valid_614004 = path.getOrDefault("detectorId")
  valid_614004 = validateParameter(valid_614004, JString, required = true,
                                 default = nil)
  if valid_614004 != nil:
    section.add "detectorId", valid_614004
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
  var valid_614005 = header.getOrDefault("X-Amz-Signature")
  valid_614005 = validateParameter(valid_614005, JString, required = false,
                                 default = nil)
  if valid_614005 != nil:
    section.add "X-Amz-Signature", valid_614005
  var valid_614006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "X-Amz-Content-Sha256", valid_614006
  var valid_614007 = header.getOrDefault("X-Amz-Date")
  valid_614007 = validateParameter(valid_614007, JString, required = false,
                                 default = nil)
  if valid_614007 != nil:
    section.add "X-Amz-Date", valid_614007
  var valid_614008 = header.getOrDefault("X-Amz-Credential")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "X-Amz-Credential", valid_614008
  var valid_614009 = header.getOrDefault("X-Amz-Security-Token")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "X-Amz-Security-Token", valid_614009
  var valid_614010 = header.getOrDefault("X-Amz-Algorithm")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "X-Amz-Algorithm", valid_614010
  var valid_614011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "X-Amz-SignedHeaders", valid_614011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614013: Call_UnarchiveFindings_614001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Unarchives GuardDuty findings specified by the <code>findingIds</code>.
  ## 
  let valid = call_614013.validator(path, query, header, formData, body)
  let scheme = call_614013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614013.url(scheme.get, call_614013.host, call_614013.base,
                         call_614013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614013, url, valid)

proc call*(call_614014: Call_UnarchiveFindings_614001; detectorId: string;
          body: JsonNode): Recallable =
  ## unarchiveFindings
  ## Unarchives GuardDuty findings specified by the <code>findingIds</code>.
  ##   detectorId: string (required)
  ##             : The ID of the detector associated with the findings to unarchive.
  ##   body: JObject (required)
  var path_614015 = newJObject()
  var body_614016 = newJObject()
  add(path_614015, "detectorId", newJString(detectorId))
  if body != nil:
    body_614016 = body
  result = call_614014.call(path_614015, nil, nil, nil, body_614016)

var unarchiveFindings* = Call_UnarchiveFindings_614001(name: "unarchiveFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/unarchive",
    validator: validate_UnarchiveFindings_614002, base: "/",
    url: url_UnarchiveFindings_614003, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_614017 = ref object of OpenApiRestCall_612658
proc url_UntagResource_614019(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_614018(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614020 = path.getOrDefault("resourceArn")
  valid_614020 = validateParameter(valid_614020, JString, required = true,
                                 default = nil)
  if valid_614020 != nil:
    section.add "resourceArn", valid_614020
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_614021 = query.getOrDefault("tagKeys")
  valid_614021 = validateParameter(valid_614021, JArray, required = true, default = nil)
  if valid_614021 != nil:
    section.add "tagKeys", valid_614021
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
  var valid_614022 = header.getOrDefault("X-Amz-Signature")
  valid_614022 = validateParameter(valid_614022, JString, required = false,
                                 default = nil)
  if valid_614022 != nil:
    section.add "X-Amz-Signature", valid_614022
  var valid_614023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "X-Amz-Content-Sha256", valid_614023
  var valid_614024 = header.getOrDefault("X-Amz-Date")
  valid_614024 = validateParameter(valid_614024, JString, required = false,
                                 default = nil)
  if valid_614024 != nil:
    section.add "X-Amz-Date", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-Credential")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-Credential", valid_614025
  var valid_614026 = header.getOrDefault("X-Amz-Security-Token")
  valid_614026 = validateParameter(valid_614026, JString, required = false,
                                 default = nil)
  if valid_614026 != nil:
    section.add "X-Amz-Security-Token", valid_614026
  var valid_614027 = header.getOrDefault("X-Amz-Algorithm")
  valid_614027 = validateParameter(valid_614027, JString, required = false,
                                 default = nil)
  if valid_614027 != nil:
    section.add "X-Amz-Algorithm", valid_614027
  var valid_614028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-SignedHeaders", valid_614028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614029: Call_UntagResource_614017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_614029.validator(path, query, header, formData, body)
  let scheme = call_614029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614029.url(scheme.get, call_614029.host, call_614029.base,
                         call_614029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614029, url, valid)

proc call*(call_614030: Call_UntagResource_614017; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the resource to remove tags from.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the resource.
  var path_614031 = newJObject()
  var query_614032 = newJObject()
  add(path_614031, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_614032.add "tagKeys", tagKeys
  result = call_614030.call(path_614031, query_614032, nil, nil, nil)

var untagResource* = Call_UntagResource_614017(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_614018,
    base: "/", url: url_UntagResource_614019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindingsFeedback_614033 = ref object of OpenApiRestCall_612658
proc url_UpdateFindingsFeedback_614035(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFindingsFeedback_614034(path: JsonNode; query: JsonNode;
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
  var valid_614036 = path.getOrDefault("detectorId")
  valid_614036 = validateParameter(valid_614036, JString, required = true,
                                 default = nil)
  if valid_614036 != nil:
    section.add "detectorId", valid_614036
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
  var valid_614037 = header.getOrDefault("X-Amz-Signature")
  valid_614037 = validateParameter(valid_614037, JString, required = false,
                                 default = nil)
  if valid_614037 != nil:
    section.add "X-Amz-Signature", valid_614037
  var valid_614038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614038 = validateParameter(valid_614038, JString, required = false,
                                 default = nil)
  if valid_614038 != nil:
    section.add "X-Amz-Content-Sha256", valid_614038
  var valid_614039 = header.getOrDefault("X-Amz-Date")
  valid_614039 = validateParameter(valid_614039, JString, required = false,
                                 default = nil)
  if valid_614039 != nil:
    section.add "X-Amz-Date", valid_614039
  var valid_614040 = header.getOrDefault("X-Amz-Credential")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "X-Amz-Credential", valid_614040
  var valid_614041 = header.getOrDefault("X-Amz-Security-Token")
  valid_614041 = validateParameter(valid_614041, JString, required = false,
                                 default = nil)
  if valid_614041 != nil:
    section.add "X-Amz-Security-Token", valid_614041
  var valid_614042 = header.getOrDefault("X-Amz-Algorithm")
  valid_614042 = validateParameter(valid_614042, JString, required = false,
                                 default = nil)
  if valid_614042 != nil:
    section.add "X-Amz-Algorithm", valid_614042
  var valid_614043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614043 = validateParameter(valid_614043, JString, required = false,
                                 default = nil)
  if valid_614043 != nil:
    section.add "X-Amz-SignedHeaders", valid_614043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614045: Call_UpdateFindingsFeedback_614033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Marks the specified GuardDuty findings as useful or not useful.
  ## 
  let valid = call_614045.validator(path, query, header, formData, body)
  let scheme = call_614045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614045.url(scheme.get, call_614045.host, call_614045.base,
                         call_614045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614045, url, valid)

proc call*(call_614046: Call_UpdateFindingsFeedback_614033; detectorId: string;
          body: JsonNode): Recallable =
  ## updateFindingsFeedback
  ## Marks the specified GuardDuty findings as useful or not useful.
  ##   detectorId: string (required)
  ##             : The ID of the detector associated with the findings to update feedback for.
  ##   body: JObject (required)
  var path_614047 = newJObject()
  var body_614048 = newJObject()
  add(path_614047, "detectorId", newJString(detectorId))
  if body != nil:
    body_614048 = body
  result = call_614046.call(path_614047, nil, nil, nil, body_614048)

var updateFindingsFeedback* = Call_UpdateFindingsFeedback_614033(
    name: "updateFindingsFeedback", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/feedback",
    validator: validate_UpdateFindingsFeedback_614034, base: "/",
    url: url_UpdateFindingsFeedback_614035, schemes: {Scheme.Https, Scheme.Http})
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
