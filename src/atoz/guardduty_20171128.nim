
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_AcceptInvitation_601997 = ref object of OpenApiRestCall_601389
proc url_AcceptInvitation_601999(protocol: Scheme; host: string; base: string;
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

proc validate_AcceptInvitation_601998(path: JsonNode; query: JsonNode;
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
  var valid_602000 = path.getOrDefault("detectorId")
  valid_602000 = validateParameter(valid_602000, JString, required = true,
                                 default = nil)
  if valid_602000 != nil:
    section.add "detectorId", valid_602000
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
  var valid_602001 = header.getOrDefault("X-Amz-Signature")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Signature", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Content-Sha256", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Security-Token")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Security-Token", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Algorithm")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Algorithm", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-SignedHeaders", valid_602007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602009: Call_AcceptInvitation_601997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts the invitation to be monitored by a master GuardDuty account.
  ## 
  let valid = call_602009.validator(path, query, header, formData, body)
  let scheme = call_602009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602009.url(scheme.get, call_602009.host, call_602009.base,
                         call_602009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602009, url, valid)

proc call*(call_602010: Call_AcceptInvitation_601997; detectorId: string;
          body: JsonNode): Recallable =
  ## acceptInvitation
  ## Accepts the invitation to be monitored by a master GuardDuty account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  ##   body: JObject (required)
  var path_602011 = newJObject()
  var body_602012 = newJObject()
  add(path_602011, "detectorId", newJString(detectorId))
  if body != nil:
    body_602012 = body
  result = call_602010.call(path_602011, nil, nil, nil, body_602012)

var acceptInvitation* = Call_AcceptInvitation_601997(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master", validator: validate_AcceptInvitation_601998,
    base: "/", url: url_AcceptInvitation_601999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_601727 = ref object of OpenApiRestCall_601389
proc url_GetMasterAccount_601729(protocol: Scheme; host: string; base: string;
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

proc validate_GetMasterAccount_601728(path: JsonNode; query: JsonNode;
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
  var valid_601855 = path.getOrDefault("detectorId")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = nil)
  if valid_601855 != nil:
    section.add "detectorId", valid_601855
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
  var valid_601856 = header.getOrDefault("X-Amz-Signature")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Signature", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Content-Sha256", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Date")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Date", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Credential")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Credential", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Security-Token")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Security-Token", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Algorithm")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Algorithm", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-SignedHeaders", valid_601862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_GetMasterAccount_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_GetMasterAccount_601727; detectorId: string): Recallable =
  ## getMasterAccount
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  var path_601957 = newJObject()
  add(path_601957, "detectorId", newJString(detectorId))
  result = call_601956.call(path_601957, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_601727(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master", validator: validate_GetMasterAccount_601728,
    base: "/", url: url_GetMasterAccount_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ArchiveFindings_602013 = ref object of OpenApiRestCall_601389
proc url_ArchiveFindings_602015(protocol: Scheme; host: string; base: string;
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

proc validate_ArchiveFindings_602014(path: JsonNode; query: JsonNode;
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
  var valid_602016 = path.getOrDefault("detectorId")
  valid_602016 = validateParameter(valid_602016, JString, required = true,
                                 default = nil)
  if valid_602016 != nil:
    section.add "detectorId", valid_602016
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
  var valid_602017 = header.getOrDefault("X-Amz-Signature")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Signature", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Content-Sha256", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Date")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Date", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Credential")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Credential", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Security-Token")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Security-Token", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Algorithm")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Algorithm", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-SignedHeaders", valid_602023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602025: Call_ArchiveFindings_602013; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
  ## 
  let valid = call_602025.validator(path, query, header, formData, body)
  let scheme = call_602025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602025.url(scheme.get, call_602025.host, call_602025.base,
                         call_602025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602025, url, valid)

proc call*(call_602026: Call_ArchiveFindings_602013; detectorId: string;
          body: JsonNode): Recallable =
  ## archiveFindings
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to archive.
  ##   body: JObject (required)
  var path_602027 = newJObject()
  var body_602028 = newJObject()
  add(path_602027, "detectorId", newJString(detectorId))
  if body != nil:
    body_602028 = body
  result = call_602026.call(path_602027, nil, nil, nil, body_602028)

var archiveFindings* = Call_ArchiveFindings_602013(name: "archiveFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/archive",
    validator: validate_ArchiveFindings_602014, base: "/", url: url_ArchiveFindings_602015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDetector_602046 = ref object of OpenApiRestCall_601389
proc url_CreateDetector_602048(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDetector_602047(path: JsonNode; query: JsonNode;
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
  var valid_602049 = header.getOrDefault("X-Amz-Signature")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Signature", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Content-Sha256", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Date")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Date", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Credential")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Credential", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Security-Token")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Security-Token", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Algorithm")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Algorithm", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-SignedHeaders", valid_602055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602057: Call_CreateDetector_602046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
  ## 
  let valid = call_602057.validator(path, query, header, formData, body)
  let scheme = call_602057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602057.url(scheme.get, call_602057.host, call_602057.base,
                         call_602057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602057, url, valid)

proc call*(call_602058: Call_CreateDetector_602046; body: JsonNode): Recallable =
  ## createDetector
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
  ##   body: JObject (required)
  var body_602059 = newJObject()
  if body != nil:
    body_602059 = body
  result = call_602058.call(nil, nil, nil, nil, body_602059)

var createDetector* = Call_CreateDetector_602046(name: "createDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com", route: "/detector",
    validator: validate_CreateDetector_602047, base: "/", url: url_CreateDetector_602048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectors_602029 = ref object of OpenApiRestCall_601389
proc url_ListDetectors_602031(protocol: Scheme; host: string; base: string;
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

proc validate_ListDetectors_602030(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602032 = query.getOrDefault("nextToken")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "nextToken", valid_602032
  var valid_602033 = query.getOrDefault("MaxResults")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "MaxResults", valid_602033
  var valid_602034 = query.getOrDefault("NextToken")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "NextToken", valid_602034
  var valid_602035 = query.getOrDefault("maxResults")
  valid_602035 = validateParameter(valid_602035, JInt, required = false, default = nil)
  if valid_602035 != nil:
    section.add "maxResults", valid_602035
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
  var valid_602036 = header.getOrDefault("X-Amz-Signature")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Signature", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Content-Sha256", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Date")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Date", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Credential")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Credential", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Security-Token")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Security-Token", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Algorithm")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Algorithm", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-SignedHeaders", valid_602042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602043: Call_ListDetectors_602029; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists detectorIds of all the existing Amazon GuardDuty detector resources.
  ## 
  let valid = call_602043.validator(path, query, header, formData, body)
  let scheme = call_602043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602043.url(scheme.get, call_602043.host, call_602043.base,
                         call_602043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602043, url, valid)

proc call*(call_602044: Call_ListDetectors_602029; nextToken: string = "";
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
  var query_602045 = newJObject()
  add(query_602045, "nextToken", newJString(nextToken))
  add(query_602045, "MaxResults", newJString(MaxResults))
  add(query_602045, "NextToken", newJString(NextToken))
  add(query_602045, "maxResults", newJInt(maxResults))
  result = call_602044.call(nil, query_602045, nil, nil, nil)

var listDetectors* = Call_ListDetectors_602029(name: "listDetectors",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com", route: "/detector",
    validator: validate_ListDetectors_602030, base: "/", url: url_ListDetectors_602031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFilter_602079 = ref object of OpenApiRestCall_601389
proc url_CreateFilter_602081(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFilter_602080(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602082 = path.getOrDefault("detectorId")
  valid_602082 = validateParameter(valid_602082, JString, required = true,
                                 default = nil)
  if valid_602082 != nil:
    section.add "detectorId", valid_602082
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
  var valid_602083 = header.getOrDefault("X-Amz-Signature")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Signature", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Content-Sha256", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Date")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Date", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Credential")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Credential", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Security-Token")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Security-Token", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Algorithm")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Algorithm", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-SignedHeaders", valid_602089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602091: Call_CreateFilter_602079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a filter using the specified finding criteria.
  ## 
  let valid = call_602091.validator(path, query, header, formData, body)
  let scheme = call_602091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602091.url(scheme.get, call_602091.host, call_602091.base,
                         call_602091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602091, url, valid)

proc call*(call_602092: Call_CreateFilter_602079; detectorId: string; body: JsonNode): Recallable =
  ## createFilter
  ## Creates a filter using the specified finding criteria.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create a filter.
  ##   body: JObject (required)
  var path_602093 = newJObject()
  var body_602094 = newJObject()
  add(path_602093, "detectorId", newJString(detectorId))
  if body != nil:
    body_602094 = body
  result = call_602092.call(path_602093, nil, nil, nil, body_602094)

var createFilter* = Call_CreateFilter_602079(name: "createFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter", validator: validate_CreateFilter_602080,
    base: "/", url: url_CreateFilter_602081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFilters_602060 = ref object of OpenApiRestCall_601389
proc url_ListFilters_602062(protocol: Scheme; host: string; base: string;
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

proc validate_ListFilters_602061(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602063 = path.getOrDefault("detectorId")
  valid_602063 = validateParameter(valid_602063, JString, required = true,
                                 default = nil)
  if valid_602063 != nil:
    section.add "detectorId", valid_602063
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
  var valid_602064 = query.getOrDefault("nextToken")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "nextToken", valid_602064
  var valid_602065 = query.getOrDefault("MaxResults")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "MaxResults", valid_602065
  var valid_602066 = query.getOrDefault("NextToken")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "NextToken", valid_602066
  var valid_602067 = query.getOrDefault("maxResults")
  valid_602067 = validateParameter(valid_602067, JInt, required = false, default = nil)
  if valid_602067 != nil:
    section.add "maxResults", valid_602067
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
  var valid_602068 = header.getOrDefault("X-Amz-Signature")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Signature", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Content-Sha256", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Date")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Date", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Credential")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Credential", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Security-Token")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Security-Token", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Algorithm")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Algorithm", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-SignedHeaders", valid_602074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602075: Call_ListFilters_602060; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of the current filters.
  ## 
  let valid = call_602075.validator(path, query, header, formData, body)
  let scheme = call_602075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602075.url(scheme.get, call_602075.host, call_602075.base,
                         call_602075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602075, url, valid)

proc call*(call_602076: Call_ListFilters_602060; detectorId: string;
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
  var path_602077 = newJObject()
  var query_602078 = newJObject()
  add(query_602078, "nextToken", newJString(nextToken))
  add(query_602078, "MaxResults", newJString(MaxResults))
  add(path_602077, "detectorId", newJString(detectorId))
  add(query_602078, "NextToken", newJString(NextToken))
  add(query_602078, "maxResults", newJInt(maxResults))
  result = call_602076.call(path_602077, query_602078, nil, nil, nil)

var listFilters* = Call_ListFilters_602060(name: "listFilters",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/filter",
                                        validator: validate_ListFilters_602061,
                                        base: "/", url: url_ListFilters_602062,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIPSet_602114 = ref object of OpenApiRestCall_601389
proc url_CreateIPSet_602116(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIPSet_602115(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602117 = path.getOrDefault("detectorId")
  valid_602117 = validateParameter(valid_602117, JString, required = true,
                                 default = nil)
  if valid_602117 != nil:
    section.add "detectorId", valid_602117
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
  var valid_602118 = header.getOrDefault("X-Amz-Signature")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Signature", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Content-Sha256", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Date")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Date", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Credential")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Credential", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Security-Token")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Security-Token", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Algorithm")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Algorithm", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-SignedHeaders", valid_602124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602126: Call_CreateIPSet_602114; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new IPSet, called Trusted IP list in the consoler user interface. An IPSet is a list IP addresses trusted for secure communication with AWS infrastructure and applications. GuardDuty does not generate findings for IP addresses included in IPSets. Only users from the master account can use this operation.
  ## 
  let valid = call_602126.validator(path, query, header, formData, body)
  let scheme = call_602126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602126.url(scheme.get, call_602126.host, call_602126.base,
                         call_602126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602126, url, valid)

proc call*(call_602127: Call_CreateIPSet_602114; detectorId: string; body: JsonNode): Recallable =
  ## createIPSet
  ## Creates a new IPSet, called Trusted IP list in the consoler user interface. An IPSet is a list IP addresses trusted for secure communication with AWS infrastructure and applications. GuardDuty does not generate findings for IP addresses included in IPSets. Only users from the master account can use this operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create an IPSet.
  ##   body: JObject (required)
  var path_602128 = newJObject()
  var body_602129 = newJObject()
  add(path_602128, "detectorId", newJString(detectorId))
  if body != nil:
    body_602129 = body
  result = call_602127.call(path_602128, nil, nil, nil, body_602129)

var createIPSet* = Call_CreateIPSet_602114(name: "createIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/ipset",
                                        validator: validate_CreateIPSet_602115,
                                        base: "/", url: url_CreateIPSet_602116,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIPSets_602095 = ref object of OpenApiRestCall_601389
proc url_ListIPSets_602097(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListIPSets_602096(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602098 = path.getOrDefault("detectorId")
  valid_602098 = validateParameter(valid_602098, JString, required = true,
                                 default = nil)
  if valid_602098 != nil:
    section.add "detectorId", valid_602098
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
  var valid_602099 = query.getOrDefault("nextToken")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "nextToken", valid_602099
  var valid_602100 = query.getOrDefault("MaxResults")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "MaxResults", valid_602100
  var valid_602101 = query.getOrDefault("NextToken")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "NextToken", valid_602101
  var valid_602102 = query.getOrDefault("maxResults")
  valid_602102 = validateParameter(valid_602102, JInt, required = false, default = nil)
  if valid_602102 != nil:
    section.add "maxResults", valid_602102
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
  var valid_602103 = header.getOrDefault("X-Amz-Signature")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Signature", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Content-Sha256", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Date")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Date", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Credential")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Credential", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Security-Token")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Security-Token", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Algorithm")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Algorithm", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-SignedHeaders", valid_602109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602110: Call_ListIPSets_602095; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the IPSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the IPSets returned are the IPSets from the associated master account.
  ## 
  let valid = call_602110.validator(path, query, header, formData, body)
  let scheme = call_602110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602110.url(scheme.get, call_602110.host, call_602110.base,
                         call_602110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602110, url, valid)

proc call*(call_602111: Call_ListIPSets_602095; detectorId: string;
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
  var path_602112 = newJObject()
  var query_602113 = newJObject()
  add(query_602113, "nextToken", newJString(nextToken))
  add(query_602113, "MaxResults", newJString(MaxResults))
  add(path_602112, "detectorId", newJString(detectorId))
  add(query_602113, "NextToken", newJString(NextToken))
  add(query_602113, "maxResults", newJInt(maxResults))
  result = call_602111.call(path_602112, query_602113, nil, nil, nil)

var listIPSets* = Call_ListIPSets_602095(name: "listIPSets",
                                      meth: HttpMethod.HttpGet,
                                      host: "guardduty.amazonaws.com",
                                      route: "/detector/{detectorId}/ipset",
                                      validator: validate_ListIPSets_602096,
                                      base: "/", url: url_ListIPSets_602097,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_602150 = ref object of OpenApiRestCall_601389
proc url_CreateMembers_602152(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMembers_602151(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602153 = path.getOrDefault("detectorId")
  valid_602153 = validateParameter(valid_602153, JString, required = true,
                                 default = nil)
  if valid_602153 != nil:
    section.add "detectorId", valid_602153
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
  var valid_602154 = header.getOrDefault("X-Amz-Signature")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Signature", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Content-Sha256", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Date")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Date", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Credential")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Credential", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Security-Token")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Security-Token", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Algorithm")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Algorithm", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-SignedHeaders", valid_602160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602162: Call_CreateMembers_602150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
  ## 
  let valid = call_602162.validator(path, query, header, formData, body)
  let scheme = call_602162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602162.url(scheme.get, call_602162.host, call_602162.base,
                         call_602162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602162, url, valid)

proc call*(call_602163: Call_CreateMembers_602150; detectorId: string; body: JsonNode): Recallable =
  ## createMembers
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account with which you want to associate member accounts.
  ##   body: JObject (required)
  var path_602164 = newJObject()
  var body_602165 = newJObject()
  add(path_602164, "detectorId", newJString(detectorId))
  if body != nil:
    body_602165 = body
  result = call_602163.call(path_602164, nil, nil, nil, body_602165)

var createMembers* = Call_CreateMembers_602150(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member", validator: validate_CreateMembers_602151,
    base: "/", url: url_CreateMembers_602152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_602130 = ref object of OpenApiRestCall_601389
proc url_ListMembers_602132(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_602131(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602133 = path.getOrDefault("detectorId")
  valid_602133 = validateParameter(valid_602133, JString, required = true,
                                 default = nil)
  if valid_602133 != nil:
    section.add "detectorId", valid_602133
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
  var valid_602134 = query.getOrDefault("nextToken")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "nextToken", valid_602134
  var valid_602135 = query.getOrDefault("MaxResults")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "MaxResults", valid_602135
  var valid_602136 = query.getOrDefault("NextToken")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "NextToken", valid_602136
  var valid_602137 = query.getOrDefault("onlyAssociated")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "onlyAssociated", valid_602137
  var valid_602138 = query.getOrDefault("maxResults")
  valid_602138 = validateParameter(valid_602138, JInt, required = false, default = nil)
  if valid_602138 != nil:
    section.add "maxResults", valid_602138
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
  var valid_602139 = header.getOrDefault("X-Amz-Signature")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Signature", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Content-Sha256", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Date")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Date", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Credential")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Credential", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Security-Token")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Security-Token", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Algorithm")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Algorithm", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-SignedHeaders", valid_602145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602146: Call_ListMembers_602130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current GuardDuty master account.
  ## 
  let valid = call_602146.validator(path, query, header, formData, body)
  let scheme = call_602146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602146.url(scheme.get, call_602146.host, call_602146.base,
                         call_602146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602146, url, valid)

proc call*(call_602147: Call_ListMembers_602130; detectorId: string;
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
  var path_602148 = newJObject()
  var query_602149 = newJObject()
  add(query_602149, "nextToken", newJString(nextToken))
  add(query_602149, "MaxResults", newJString(MaxResults))
  add(path_602148, "detectorId", newJString(detectorId))
  add(query_602149, "NextToken", newJString(NextToken))
  add(query_602149, "onlyAssociated", newJString(onlyAssociated))
  add(query_602149, "maxResults", newJInt(maxResults))
  result = call_602147.call(path_602148, query_602149, nil, nil, nil)

var listMembers* = Call_ListMembers_602130(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/member",
                                        validator: validate_ListMembers_602131,
                                        base: "/", url: url_ListMembers_602132,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublishingDestination_602185 = ref object of OpenApiRestCall_601389
proc url_CreatePublishingDestination_602187(protocol: Scheme; host: string;
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

proc validate_CreatePublishingDestination_602186(path: JsonNode; query: JsonNode;
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
  var valid_602188 = path.getOrDefault("detectorId")
  valid_602188 = validateParameter(valid_602188, JString, required = true,
                                 default = nil)
  if valid_602188 != nil:
    section.add "detectorId", valid_602188
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
  var valid_602189 = header.getOrDefault("X-Amz-Signature")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Signature", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Content-Sha256", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Date")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Date", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Credential")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Credential", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Security-Token")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Security-Token", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Algorithm")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Algorithm", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-SignedHeaders", valid_602195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602197: Call_CreatePublishingDestination_602185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a publishing destination to send findings to. The resource to send findings to must exist before you use this operation.
  ## 
  let valid = call_602197.validator(path, query, header, formData, body)
  let scheme = call_602197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602197.url(scheme.get, call_602197.host, call_602197.base,
                         call_602197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602197, url, valid)

proc call*(call_602198: Call_CreatePublishingDestination_602185;
          detectorId: string; body: JsonNode): Recallable =
  ## createPublishingDestination
  ## Creates a publishing destination to send findings to. The resource to send findings to must exist before you use this operation.
  ##   detectorId: string (required)
  ##             : The ID of the GuardDuty detector associated with the publishing destination.
  ##   body: JObject (required)
  var path_602199 = newJObject()
  var body_602200 = newJObject()
  add(path_602199, "detectorId", newJString(detectorId))
  if body != nil:
    body_602200 = body
  result = call_602198.call(path_602199, nil, nil, nil, body_602200)

var createPublishingDestination* = Call_CreatePublishingDestination_602185(
    name: "createPublishingDestination", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination",
    validator: validate_CreatePublishingDestination_602186, base: "/",
    url: url_CreatePublishingDestination_602187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishingDestinations_602166 = ref object of OpenApiRestCall_601389
proc url_ListPublishingDestinations_602168(protocol: Scheme; host: string;
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

proc validate_ListPublishingDestinations_602167(path: JsonNode; query: JsonNode;
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
  var valid_602169 = path.getOrDefault("detectorId")
  valid_602169 = validateParameter(valid_602169, JString, required = true,
                                 default = nil)
  if valid_602169 != nil:
    section.add "detectorId", valid_602169
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
  var valid_602170 = query.getOrDefault("nextToken")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "nextToken", valid_602170
  var valid_602171 = query.getOrDefault("MaxResults")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "MaxResults", valid_602171
  var valid_602172 = query.getOrDefault("NextToken")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "NextToken", valid_602172
  var valid_602173 = query.getOrDefault("maxResults")
  valid_602173 = validateParameter(valid_602173, JInt, required = false, default = nil)
  if valid_602173 != nil:
    section.add "maxResults", valid_602173
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
  var valid_602174 = header.getOrDefault("X-Amz-Signature")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Signature", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Content-Sha256", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Date")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Date", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Credential")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Credential", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Security-Token")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Security-Token", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Algorithm")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Algorithm", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-SignedHeaders", valid_602180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602181: Call_ListPublishingDestinations_602166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of publishing destinations associated with the specified <code>dectectorId</code>.
  ## 
  let valid = call_602181.validator(path, query, header, formData, body)
  let scheme = call_602181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602181.url(scheme.get, call_602181.host, call_602181.base,
                         call_602181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602181, url, valid)

proc call*(call_602182: Call_ListPublishingDestinations_602166; detectorId: string;
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
  var path_602183 = newJObject()
  var query_602184 = newJObject()
  add(query_602184, "nextToken", newJString(nextToken))
  add(query_602184, "MaxResults", newJString(MaxResults))
  add(path_602183, "detectorId", newJString(detectorId))
  add(query_602184, "NextToken", newJString(NextToken))
  add(query_602184, "maxResults", newJInt(maxResults))
  result = call_602182.call(path_602183, query_602184, nil, nil, nil)

var listPublishingDestinations* = Call_ListPublishingDestinations_602166(
    name: "listPublishingDestinations", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination",
    validator: validate_ListPublishingDestinations_602167, base: "/",
    url: url_ListPublishingDestinations_602168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSampleFindings_602201 = ref object of OpenApiRestCall_601389
proc url_CreateSampleFindings_602203(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSampleFindings_602202(path: JsonNode; query: JsonNode;
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
  var valid_602204 = path.getOrDefault("detectorId")
  valid_602204 = validateParameter(valid_602204, JString, required = true,
                                 default = nil)
  if valid_602204 != nil:
    section.add "detectorId", valid_602204
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
  var valid_602205 = header.getOrDefault("X-Amz-Signature")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Signature", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Content-Sha256", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Date")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Date", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Credential")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Credential", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Security-Token")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Security-Token", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Algorithm")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Algorithm", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-SignedHeaders", valid_602211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602213: Call_CreateSampleFindings_602201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for <code>findingTypes</code>, the API generates example findings of all supported finding types.
  ## 
  let valid = call_602213.validator(path, query, header, formData, body)
  let scheme = call_602213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602213.url(scheme.get, call_602213.host, call_602213.base,
                         call_602213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602213, url, valid)

proc call*(call_602214: Call_CreateSampleFindings_602201; detectorId: string;
          body: JsonNode): Recallable =
  ## createSampleFindings
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for <code>findingTypes</code>, the API generates example findings of all supported finding types.
  ##   detectorId: string (required)
  ##             : The ID of the detector to create sample findings for.
  ##   body: JObject (required)
  var path_602215 = newJObject()
  var body_602216 = newJObject()
  add(path_602215, "detectorId", newJString(detectorId))
  if body != nil:
    body_602216 = body
  result = call_602214.call(path_602215, nil, nil, nil, body_602216)

var createSampleFindings* = Call_CreateSampleFindings_602201(
    name: "createSampleFindings", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/create",
    validator: validate_CreateSampleFindings_602202, base: "/",
    url: url_CreateSampleFindings_602203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateThreatIntelSet_602236 = ref object of OpenApiRestCall_601389
proc url_CreateThreatIntelSet_602238(protocol: Scheme; host: string; base: string;
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

proc validate_CreateThreatIntelSet_602237(path: JsonNode; query: JsonNode;
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
  var valid_602239 = path.getOrDefault("detectorId")
  valid_602239 = validateParameter(valid_602239, JString, required = true,
                                 default = nil)
  if valid_602239 != nil:
    section.add "detectorId", valid_602239
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
  var valid_602240 = header.getOrDefault("X-Amz-Signature")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Signature", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Content-Sha256", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Date")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Date", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Credential")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Credential", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Security-Token")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Security-Token", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Algorithm")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Algorithm", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-SignedHeaders", valid_602246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602248: Call_CreateThreatIntelSet_602236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets. Only users of the master account can use this operation.
  ## 
  let valid = call_602248.validator(path, query, header, formData, body)
  let scheme = call_602248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602248.url(scheme.get, call_602248.host, call_602248.base,
                         call_602248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602248, url, valid)

proc call*(call_602249: Call_CreateThreatIntelSet_602236; detectorId: string;
          body: JsonNode): Recallable =
  ## createThreatIntelSet
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets. Only users of the master account can use this operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create a threatIntelSet.
  ##   body: JObject (required)
  var path_602250 = newJObject()
  var body_602251 = newJObject()
  add(path_602250, "detectorId", newJString(detectorId))
  if body != nil:
    body_602251 = body
  result = call_602249.call(path_602250, nil, nil, nil, body_602251)

var createThreatIntelSet* = Call_CreateThreatIntelSet_602236(
    name: "createThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_CreateThreatIntelSet_602237, base: "/",
    url: url_CreateThreatIntelSet_602238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListThreatIntelSets_602217 = ref object of OpenApiRestCall_601389
proc url_ListThreatIntelSets_602219(protocol: Scheme; host: string; base: string;
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

proc validate_ListThreatIntelSets_602218(path: JsonNode; query: JsonNode;
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
  var valid_602220 = path.getOrDefault("detectorId")
  valid_602220 = validateParameter(valid_602220, JString, required = true,
                                 default = nil)
  if valid_602220 != nil:
    section.add "detectorId", valid_602220
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
  var valid_602221 = query.getOrDefault("nextToken")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "nextToken", valid_602221
  var valid_602222 = query.getOrDefault("MaxResults")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "MaxResults", valid_602222
  var valid_602223 = query.getOrDefault("NextToken")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "NextToken", valid_602223
  var valid_602224 = query.getOrDefault("maxResults")
  valid_602224 = validateParameter(valid_602224, JInt, required = false, default = nil)
  if valid_602224 != nil:
    section.add "maxResults", valid_602224
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
  var valid_602225 = header.getOrDefault("X-Amz-Signature")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Signature", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Content-Sha256", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Date")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Date", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Credential")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Credential", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Security-Token")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Security-Token", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Algorithm")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Algorithm", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-SignedHeaders", valid_602231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602232: Call_ListThreatIntelSets_602217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the ThreatIntelSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the ThreatIntelSets associated with the master account are returned.
  ## 
  let valid = call_602232.validator(path, query, header, formData, body)
  let scheme = call_602232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602232.url(scheme.get, call_602232.host, call_602232.base,
                         call_602232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602232, url, valid)

proc call*(call_602233: Call_ListThreatIntelSets_602217; detectorId: string;
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
  var path_602234 = newJObject()
  var query_602235 = newJObject()
  add(query_602235, "nextToken", newJString(nextToken))
  add(query_602235, "MaxResults", newJString(MaxResults))
  add(path_602234, "detectorId", newJString(detectorId))
  add(query_602235, "NextToken", newJString(NextToken))
  add(query_602235, "maxResults", newJInt(maxResults))
  result = call_602233.call(path_602234, query_602235, nil, nil, nil)

var listThreatIntelSets* = Call_ListThreatIntelSets_602217(
    name: "listThreatIntelSets", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_ListThreatIntelSets_602218, base: "/",
    url: url_ListThreatIntelSets_602219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_602252 = ref object of OpenApiRestCall_601389
proc url_DeclineInvitations_602254(protocol: Scheme; host: string; base: string;
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

proc validate_DeclineInvitations_602253(path: JsonNode; query: JsonNode;
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
  var valid_602255 = header.getOrDefault("X-Amz-Signature")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Signature", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Content-Sha256", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Date")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Date", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Credential")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Credential", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Security-Token")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Security-Token", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Algorithm")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Algorithm", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-SignedHeaders", valid_602261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602263: Call_DeclineInvitations_602252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
  ## 
  let valid = call_602263.validator(path, query, header, formData, body)
  let scheme = call_602263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602263.url(scheme.get, call_602263.host, call_602263.base,
                         call_602263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602263, url, valid)

proc call*(call_602264: Call_DeclineInvitations_602252; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
  ##   body: JObject (required)
  var body_602265 = newJObject()
  if body != nil:
    body_602265 = body
  result = call_602264.call(nil, nil, nil, nil, body_602265)

var declineInvitations* = Call_DeclineInvitations_602252(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/invitation/decline",
    validator: validate_DeclineInvitations_602253, base: "/",
    url: url_DeclineInvitations_602254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetector_602280 = ref object of OpenApiRestCall_601389
proc url_UpdateDetector_602282(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDetector_602281(path: JsonNode; query: JsonNode;
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
  var valid_602283 = path.getOrDefault("detectorId")
  valid_602283 = validateParameter(valid_602283, JString, required = true,
                                 default = nil)
  if valid_602283 != nil:
    section.add "detectorId", valid_602283
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
  var valid_602284 = header.getOrDefault("X-Amz-Signature")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Signature", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Content-Sha256", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Date")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Date", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Credential")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Credential", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Security-Token")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Security-Token", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Algorithm")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Algorithm", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-SignedHeaders", valid_602290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602292: Call_UpdateDetector_602280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Amazon GuardDuty detector specified by the detectorId.
  ## 
  let valid = call_602292.validator(path, query, header, formData, body)
  let scheme = call_602292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602292.url(scheme.get, call_602292.host, call_602292.base,
                         call_602292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602292, url, valid)

proc call*(call_602293: Call_UpdateDetector_602280; detectorId: string;
          body: JsonNode): Recallable =
  ## updateDetector
  ## Updates the Amazon GuardDuty detector specified by the detectorId.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector to update.
  ##   body: JObject (required)
  var path_602294 = newJObject()
  var body_602295 = newJObject()
  add(path_602294, "detectorId", newJString(detectorId))
  if body != nil:
    body_602295 = body
  result = call_602293.call(path_602294, nil, nil, nil, body_602295)

var updateDetector* = Call_UpdateDetector_602280(name: "updateDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_UpdateDetector_602281,
    base: "/", url: url_UpdateDetector_602282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetector_602266 = ref object of OpenApiRestCall_601389
proc url_GetDetector_602268(protocol: Scheme; host: string; base: string;
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

proc validate_GetDetector_602267(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602269 = path.getOrDefault("detectorId")
  valid_602269 = validateParameter(valid_602269, JString, required = true,
                                 default = nil)
  if valid_602269 != nil:
    section.add "detectorId", valid_602269
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
  var valid_602270 = header.getOrDefault("X-Amz-Signature")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Signature", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Content-Sha256", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Date")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Date", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Credential")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Credential", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Security-Token")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Security-Token", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Algorithm")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Algorithm", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-SignedHeaders", valid_602276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602277: Call_GetDetector_602266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
  ## 
  let valid = call_602277.validator(path, query, header, formData, body)
  let scheme = call_602277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602277.url(scheme.get, call_602277.host, call_602277.base,
                         call_602277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602277, url, valid)

proc call*(call_602278: Call_GetDetector_602266; detectorId: string): Recallable =
  ## getDetector
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that you want to get.
  var path_602279 = newJObject()
  add(path_602279, "detectorId", newJString(detectorId))
  result = call_602278.call(path_602279, nil, nil, nil, nil)

var getDetector* = Call_GetDetector_602266(name: "getDetector",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}",
                                        validator: validate_GetDetector_602267,
                                        base: "/", url: url_GetDetector_602268,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetector_602296 = ref object of OpenApiRestCall_601389
proc url_DeleteDetector_602298(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDetector_602297(path: JsonNode; query: JsonNode;
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
  var valid_602299 = path.getOrDefault("detectorId")
  valid_602299 = validateParameter(valid_602299, JString, required = true,
                                 default = nil)
  if valid_602299 != nil:
    section.add "detectorId", valid_602299
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
  var valid_602300 = header.getOrDefault("X-Amz-Signature")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Signature", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Content-Sha256", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Date")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Date", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Credential")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Credential", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Security-Token")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Security-Token", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Algorithm")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Algorithm", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-SignedHeaders", valid_602306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602307: Call_DeleteDetector_602296; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
  ## 
  let valid = call_602307.validator(path, query, header, formData, body)
  let scheme = call_602307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602307.url(scheme.get, call_602307.host, call_602307.base,
                         call_602307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602307, url, valid)

proc call*(call_602308: Call_DeleteDetector_602296; detectorId: string): Recallable =
  ## deleteDetector
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that you want to delete.
  var path_602309 = newJObject()
  add(path_602309, "detectorId", newJString(detectorId))
  result = call_602308.call(path_602309, nil, nil, nil, nil)

var deleteDetector* = Call_DeleteDetector_602296(name: "deleteDetector",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_DeleteDetector_602297,
    base: "/", url: url_DeleteDetector_602298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFilter_602325 = ref object of OpenApiRestCall_601389
proc url_UpdateFilter_602327(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFilter_602326(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602328 = path.getOrDefault("detectorId")
  valid_602328 = validateParameter(valid_602328, JString, required = true,
                                 default = nil)
  if valid_602328 != nil:
    section.add "detectorId", valid_602328
  var valid_602329 = path.getOrDefault("filterName")
  valid_602329 = validateParameter(valid_602329, JString, required = true,
                                 default = nil)
  if valid_602329 != nil:
    section.add "filterName", valid_602329
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
  var valid_602330 = header.getOrDefault("X-Amz-Signature")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Signature", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Content-Sha256", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Date")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Date", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Credential")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Credential", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Security-Token")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Security-Token", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Algorithm")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Algorithm", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-SignedHeaders", valid_602336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602338: Call_UpdateFilter_602325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the filter specified by the filter name.
  ## 
  let valid = call_602338.validator(path, query, header, formData, body)
  let scheme = call_602338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602338.url(scheme.get, call_602338.host, call_602338.base,
                         call_602338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602338, url, valid)

proc call*(call_602339: Call_UpdateFilter_602325; detectorId: string;
          filterName: string; body: JsonNode): Recallable =
  ## updateFilter
  ## Updates the filter specified by the filter name.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that specifies the GuardDuty service where you want to update a filter.
  ##   filterName: string (required)
  ##             : The name of the filter.
  ##   body: JObject (required)
  var path_602340 = newJObject()
  var body_602341 = newJObject()
  add(path_602340, "detectorId", newJString(detectorId))
  add(path_602340, "filterName", newJString(filterName))
  if body != nil:
    body_602341 = body
  result = call_602339.call(path_602340, nil, nil, nil, body_602341)

var updateFilter* = Call_UpdateFilter_602325(name: "updateFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_UpdateFilter_602326, base: "/", url: url_UpdateFilter_602327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFilter_602310 = ref object of OpenApiRestCall_601389
proc url_GetFilter_602312(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetFilter_602311(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602313 = path.getOrDefault("detectorId")
  valid_602313 = validateParameter(valid_602313, JString, required = true,
                                 default = nil)
  if valid_602313 != nil:
    section.add "detectorId", valid_602313
  var valid_602314 = path.getOrDefault("filterName")
  valid_602314 = validateParameter(valid_602314, JString, required = true,
                                 default = nil)
  if valid_602314 != nil:
    section.add "filterName", valid_602314
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
  var valid_602315 = header.getOrDefault("X-Amz-Signature")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Signature", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Content-Sha256", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Date")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Date", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Credential")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Credential", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Security-Token")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Security-Token", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Algorithm")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Algorithm", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-SignedHeaders", valid_602321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602322: Call_GetFilter_602310; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of the filter specified by the filter name.
  ## 
  let valid = call_602322.validator(path, query, header, formData, body)
  let scheme = call_602322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602322.url(scheme.get, call_602322.host, call_602322.base,
                         call_602322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602322, url, valid)

proc call*(call_602323: Call_GetFilter_602310; detectorId: string; filterName: string): Recallable =
  ## getFilter
  ## Returns the details of the filter specified by the filter name.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  ##   filterName: string (required)
  ##             : The name of the filter you want to get.
  var path_602324 = newJObject()
  add(path_602324, "detectorId", newJString(detectorId))
  add(path_602324, "filterName", newJString(filterName))
  result = call_602323.call(path_602324, nil, nil, nil, nil)

var getFilter* = Call_GetFilter_602310(name: "getFilter", meth: HttpMethod.HttpGet,
                                    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/filter/{filterName}",
                                    validator: validate_GetFilter_602311,
                                    base: "/", url: url_GetFilter_602312,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFilter_602342 = ref object of OpenApiRestCall_601389
proc url_DeleteFilter_602344(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFilter_602343(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602345 = path.getOrDefault("detectorId")
  valid_602345 = validateParameter(valid_602345, JString, required = true,
                                 default = nil)
  if valid_602345 != nil:
    section.add "detectorId", valid_602345
  var valid_602346 = path.getOrDefault("filterName")
  valid_602346 = validateParameter(valid_602346, JString, required = true,
                                 default = nil)
  if valid_602346 != nil:
    section.add "filterName", valid_602346
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
  var valid_602347 = header.getOrDefault("X-Amz-Signature")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Signature", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Content-Sha256", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Date")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Date", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Credential")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Credential", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Security-Token")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Security-Token", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Algorithm")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Algorithm", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-SignedHeaders", valid_602353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602354: Call_DeleteFilter_602342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the filter specified by the filter name.
  ## 
  let valid = call_602354.validator(path, query, header, formData, body)
  let scheme = call_602354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602354.url(scheme.get, call_602354.host, call_602354.base,
                         call_602354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602354, url, valid)

proc call*(call_602355: Call_DeleteFilter_602342; detectorId: string;
          filterName: string): Recallable =
  ## deleteFilter
  ## Deletes the filter specified by the filter name.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  ##   filterName: string (required)
  ##             : The name of the filter you want to delete.
  var path_602356 = newJObject()
  add(path_602356, "detectorId", newJString(detectorId))
  add(path_602356, "filterName", newJString(filterName))
  result = call_602355.call(path_602356, nil, nil, nil, nil)

var deleteFilter* = Call_DeleteFilter_602342(name: "deleteFilter",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_DeleteFilter_602343, base: "/", url: url_DeleteFilter_602344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIPSet_602372 = ref object of OpenApiRestCall_601389
proc url_UpdateIPSet_602374(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIPSet_602373(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602375 = path.getOrDefault("ipSetId")
  valid_602375 = validateParameter(valid_602375, JString, required = true,
                                 default = nil)
  if valid_602375 != nil:
    section.add "ipSetId", valid_602375
  var valid_602376 = path.getOrDefault("detectorId")
  valid_602376 = validateParameter(valid_602376, JString, required = true,
                                 default = nil)
  if valid_602376 != nil:
    section.add "detectorId", valid_602376
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
  var valid_602377 = header.getOrDefault("X-Amz-Signature")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Signature", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Content-Sha256", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Date")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Date", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Credential")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Credential", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Security-Token")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Security-Token", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Algorithm")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Algorithm", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-SignedHeaders", valid_602383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602385: Call_UpdateIPSet_602372; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the IPSet specified by the IPSet ID.
  ## 
  let valid = call_602385.validator(path, query, header, formData, body)
  let scheme = call_602385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602385.url(scheme.get, call_602385.host, call_602385.base,
                         call_602385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602385, url, valid)

proc call*(call_602386: Call_UpdateIPSet_602372; ipSetId: string; detectorId: string;
          body: JsonNode): Recallable =
  ## updateIPSet
  ## Updates the IPSet specified by the IPSet ID.
  ##   ipSetId: string (required)
  ##          : The unique ID that specifies the IPSet that you want to update.
  ##   detectorId: string (required)
  ##             : The detectorID that specifies the GuardDuty service whose IPSet you want to update.
  ##   body: JObject (required)
  var path_602387 = newJObject()
  var body_602388 = newJObject()
  add(path_602387, "ipSetId", newJString(ipSetId))
  add(path_602387, "detectorId", newJString(detectorId))
  if body != nil:
    body_602388 = body
  result = call_602386.call(path_602387, nil, nil, nil, body_602388)

var updateIPSet* = Call_UpdateIPSet_602372(name: "updateIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                        validator: validate_UpdateIPSet_602373,
                                        base: "/", url: url_UpdateIPSet_602374,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIPSet_602357 = ref object of OpenApiRestCall_601389
proc url_GetIPSet_602359(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetIPSet_602358(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602360 = path.getOrDefault("ipSetId")
  valid_602360 = validateParameter(valid_602360, JString, required = true,
                                 default = nil)
  if valid_602360 != nil:
    section.add "ipSetId", valid_602360
  var valid_602361 = path.getOrDefault("detectorId")
  valid_602361 = validateParameter(valid_602361, JString, required = true,
                                 default = nil)
  if valid_602361 != nil:
    section.add "detectorId", valid_602361
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
  var valid_602362 = header.getOrDefault("X-Amz-Signature")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Signature", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Content-Sha256", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Date")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Date", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Credential")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Credential", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Security-Token")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Security-Token", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Algorithm")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Algorithm", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-SignedHeaders", valid_602368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602369: Call_GetIPSet_602357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
  ## 
  let valid = call_602369.validator(path, query, header, formData, body)
  let scheme = call_602369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602369.url(scheme.get, call_602369.host, call_602369.base,
                         call_602369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602369, url, valid)

proc call*(call_602370: Call_GetIPSet_602357; ipSetId: string; detectorId: string): Recallable =
  ## getIPSet
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
  ##   ipSetId: string (required)
  ##          : The unique ID of the IPSet to retrieve.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the ipSet is associated with.
  var path_602371 = newJObject()
  add(path_602371, "ipSetId", newJString(ipSetId))
  add(path_602371, "detectorId", newJString(detectorId))
  result = call_602370.call(path_602371, nil, nil, nil, nil)

var getIPSet* = Call_GetIPSet_602357(name: "getIPSet", meth: HttpMethod.HttpGet,
                                  host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                  validator: validate_GetIPSet_602358, base: "/",
                                  url: url_GetIPSet_602359,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIPSet_602389 = ref object of OpenApiRestCall_601389
proc url_DeleteIPSet_602391(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIPSet_602390(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602392 = path.getOrDefault("ipSetId")
  valid_602392 = validateParameter(valid_602392, JString, required = true,
                                 default = nil)
  if valid_602392 != nil:
    section.add "ipSetId", valid_602392
  var valid_602393 = path.getOrDefault("detectorId")
  valid_602393 = validateParameter(valid_602393, JString, required = true,
                                 default = nil)
  if valid_602393 != nil:
    section.add "detectorId", valid_602393
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
  var valid_602394 = header.getOrDefault("X-Amz-Signature")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Signature", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Content-Sha256", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Date")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Date", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Credential")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Credential", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Security-Token")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Security-Token", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Algorithm")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Algorithm", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-SignedHeaders", valid_602400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602401: Call_DeleteIPSet_602389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
  ## 
  let valid = call_602401.validator(path, query, header, formData, body)
  let scheme = call_602401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602401.url(scheme.get, call_602401.host, call_602401.base,
                         call_602401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602401, url, valid)

proc call*(call_602402: Call_DeleteIPSet_602389; ipSetId: string; detectorId: string): Recallable =
  ## deleteIPSet
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
  ##   ipSetId: string (required)
  ##          : The unique ID of the IPSet to delete.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the IPSet.
  var path_602403 = newJObject()
  add(path_602403, "ipSetId", newJString(ipSetId))
  add(path_602403, "detectorId", newJString(detectorId))
  result = call_602402.call(path_602403, nil, nil, nil, nil)

var deleteIPSet* = Call_DeleteIPSet_602389(name: "deleteIPSet",
                                        meth: HttpMethod.HttpDelete,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                        validator: validate_DeleteIPSet_602390,
                                        base: "/", url: url_DeleteIPSet_602391,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_602404 = ref object of OpenApiRestCall_601389
proc url_DeleteInvitations_602406(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInvitations_602405(path: JsonNode; query: JsonNode;
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
  var valid_602407 = header.getOrDefault("X-Amz-Signature")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Signature", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Content-Sha256", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Date")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Date", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Credential")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Credential", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Security-Token")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Security-Token", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Algorithm")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Algorithm", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-SignedHeaders", valid_602413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602415: Call_DeleteInvitations_602404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
  ## 
  let valid = call_602415.validator(path, query, header, formData, body)
  let scheme = call_602415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602415.url(scheme.get, call_602415.host, call_602415.base,
                         call_602415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602415, url, valid)

proc call*(call_602416: Call_DeleteInvitations_602404; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
  ##   body: JObject (required)
  var body_602417 = newJObject()
  if body != nil:
    body_602417 = body
  result = call_602416.call(nil, nil, nil, nil, body_602417)

var deleteInvitations* = Call_DeleteInvitations_602404(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/invitation/delete", validator: validate_DeleteInvitations_602405,
    base: "/", url: url_DeleteInvitations_602406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_602418 = ref object of OpenApiRestCall_601389
proc url_DeleteMembers_602420(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMembers_602419(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602421 = path.getOrDefault("detectorId")
  valid_602421 = validateParameter(valid_602421, JString, required = true,
                                 default = nil)
  if valid_602421 != nil:
    section.add "detectorId", valid_602421
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
  var valid_602422 = header.getOrDefault("X-Amz-Signature")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Signature", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Content-Sha256", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Date")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Date", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Credential")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Credential", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-Security-Token")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Security-Token", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Algorithm")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Algorithm", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-SignedHeaders", valid_602428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602430: Call_DeleteMembers_602418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_602430.validator(path, query, header, formData, body)
  let scheme = call_602430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602430.url(scheme.get, call_602430.host, call_602430.base,
                         call_602430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602430, url, valid)

proc call*(call_602431: Call_DeleteMembers_602418; detectorId: string; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to delete.
  ##   body: JObject (required)
  var path_602432 = newJObject()
  var body_602433 = newJObject()
  add(path_602432, "detectorId", newJString(detectorId))
  if body != nil:
    body_602433 = body
  result = call_602431.call(path_602432, nil, nil, nil, body_602433)

var deleteMembers* = Call_DeleteMembers_602418(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/delete",
    validator: validate_DeleteMembers_602419, base: "/", url: url_DeleteMembers_602420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePublishingDestination_602449 = ref object of OpenApiRestCall_601389
proc url_UpdatePublishingDestination_602451(protocol: Scheme; host: string;
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

proc validate_UpdatePublishingDestination_602450(path: JsonNode; query: JsonNode;
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
  var valid_602452 = path.getOrDefault("detectorId")
  valid_602452 = validateParameter(valid_602452, JString, required = true,
                                 default = nil)
  if valid_602452 != nil:
    section.add "detectorId", valid_602452
  var valid_602453 = path.getOrDefault("destinationId")
  valid_602453 = validateParameter(valid_602453, JString, required = true,
                                 default = nil)
  if valid_602453 != nil:
    section.add "destinationId", valid_602453
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
  var valid_602454 = header.getOrDefault("X-Amz-Signature")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Signature", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Content-Sha256", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-Date")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Date", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Credential")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Credential", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Security-Token")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Security-Token", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Algorithm")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Algorithm", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-SignedHeaders", valid_602460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602462: Call_UpdatePublishingDestination_602449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
  ## 
  let valid = call_602462.validator(path, query, header, formData, body)
  let scheme = call_602462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602462.url(scheme.get, call_602462.host, call_602462.base,
                         call_602462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602462, url, valid)

proc call*(call_602463: Call_UpdatePublishingDestination_602449;
          detectorId: string; destinationId: string; body: JsonNode): Recallable =
  ## updatePublishingDestination
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
  ##   detectorId: string (required)
  ##             : The ID of the 
  ##   destinationId: string (required)
  ##                : The ID of the detector associated with the publishing destinations to update.
  ##   body: JObject (required)
  var path_602464 = newJObject()
  var body_602465 = newJObject()
  add(path_602464, "detectorId", newJString(detectorId))
  add(path_602464, "destinationId", newJString(destinationId))
  if body != nil:
    body_602465 = body
  result = call_602463.call(path_602464, nil, nil, nil, body_602465)

var updatePublishingDestination* = Call_UpdatePublishingDestination_602449(
    name: "updatePublishingDestination", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_UpdatePublishingDestination_602450, base: "/",
    url: url_UpdatePublishingDestination_602451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePublishingDestination_602434 = ref object of OpenApiRestCall_601389
proc url_DescribePublishingDestination_602436(protocol: Scheme; host: string;
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

proc validate_DescribePublishingDestination_602435(path: JsonNode; query: JsonNode;
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
  var valid_602437 = path.getOrDefault("detectorId")
  valid_602437 = validateParameter(valid_602437, JString, required = true,
                                 default = nil)
  if valid_602437 != nil:
    section.add "detectorId", valid_602437
  var valid_602438 = path.getOrDefault("destinationId")
  valid_602438 = validateParameter(valid_602438, JString, required = true,
                                 default = nil)
  if valid_602438 != nil:
    section.add "destinationId", valid_602438
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
  var valid_602439 = header.getOrDefault("X-Amz-Signature")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Signature", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Content-Sha256", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Date")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Date", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Credential")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Credential", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Security-Token")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Security-Token", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Algorithm")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Algorithm", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-SignedHeaders", valid_602445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602446: Call_DescribePublishingDestination_602434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
  ## 
  let valid = call_602446.validator(path, query, header, formData, body)
  let scheme = call_602446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602446.url(scheme.get, call_602446.host, call_602446.base,
                         call_602446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602446, url, valid)

proc call*(call_602447: Call_DescribePublishingDestination_602434;
          detectorId: string; destinationId: string): Recallable =
  ## describePublishingDestination
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the publishing destination to retrieve.
  ##   destinationId: string (required)
  ##                : The ID of the publishing destination to retrieve.
  var path_602448 = newJObject()
  add(path_602448, "detectorId", newJString(detectorId))
  add(path_602448, "destinationId", newJString(destinationId))
  result = call_602447.call(path_602448, nil, nil, nil, nil)

var describePublishingDestination* = Call_DescribePublishingDestination_602434(
    name: "describePublishingDestination", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_DescribePublishingDestination_602435, base: "/",
    url: url_DescribePublishingDestination_602436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublishingDestination_602466 = ref object of OpenApiRestCall_601389
proc url_DeletePublishingDestination_602468(protocol: Scheme; host: string;
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

proc validate_DeletePublishingDestination_602467(path: JsonNode; query: JsonNode;
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
  var valid_602469 = path.getOrDefault("detectorId")
  valid_602469 = validateParameter(valid_602469, JString, required = true,
                                 default = nil)
  if valid_602469 != nil:
    section.add "detectorId", valid_602469
  var valid_602470 = path.getOrDefault("destinationId")
  valid_602470 = validateParameter(valid_602470, JString, required = true,
                                 default = nil)
  if valid_602470 != nil:
    section.add "destinationId", valid_602470
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
  var valid_602471 = header.getOrDefault("X-Amz-Signature")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Signature", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Content-Sha256", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Date")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Date", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-Credential")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Credential", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Security-Token")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Security-Token", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Algorithm")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Algorithm", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-SignedHeaders", valid_602477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602478: Call_DeletePublishingDestination_602466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
  ## 
  let valid = call_602478.validator(path, query, header, formData, body)
  let scheme = call_602478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602478.url(scheme.get, call_602478.host, call_602478.base,
                         call_602478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602478, url, valid)

proc call*(call_602479: Call_DeletePublishingDestination_602466;
          detectorId: string; destinationId: string): Recallable =
  ## deletePublishingDestination
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the publishing destination to delete.
  ##   destinationId: string (required)
  ##                : The ID of the publishing destination to delete.
  var path_602480 = newJObject()
  add(path_602480, "detectorId", newJString(detectorId))
  add(path_602480, "destinationId", newJString(destinationId))
  result = call_602479.call(path_602480, nil, nil, nil, nil)

var deletePublishingDestination* = Call_DeletePublishingDestination_602466(
    name: "deletePublishingDestination", meth: HttpMethod.HttpDelete,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_DeletePublishingDestination_602467, base: "/",
    url: url_DeletePublishingDestination_602468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateThreatIntelSet_602496 = ref object of OpenApiRestCall_601389
proc url_UpdateThreatIntelSet_602498(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateThreatIntelSet_602497(path: JsonNode; query: JsonNode;
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
  var valid_602499 = path.getOrDefault("detectorId")
  valid_602499 = validateParameter(valid_602499, JString, required = true,
                                 default = nil)
  if valid_602499 != nil:
    section.add "detectorId", valid_602499
  var valid_602500 = path.getOrDefault("threatIntelSetId")
  valid_602500 = validateParameter(valid_602500, JString, required = true,
                                 default = nil)
  if valid_602500 != nil:
    section.add "threatIntelSetId", valid_602500
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
  var valid_602501 = header.getOrDefault("X-Amz-Signature")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-Signature", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-Content-Sha256", valid_602502
  var valid_602503 = header.getOrDefault("X-Amz-Date")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Date", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-Credential")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-Credential", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-Security-Token")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Security-Token", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-Algorithm")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Algorithm", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-SignedHeaders", valid_602507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602509: Call_UpdateThreatIntelSet_602496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ## 
  let valid = call_602509.validator(path, query, header, formData, body)
  let scheme = call_602509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602509.url(scheme.get, call_602509.host, call_602509.base,
                         call_602509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602509, url, valid)

proc call*(call_602510: Call_UpdateThreatIntelSet_602496; detectorId: string;
          body: JsonNode; threatIntelSetId: string): Recallable =
  ## updateThreatIntelSet
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The detectorID that specifies the GuardDuty service whose ThreatIntelSet you want to update.
  ##   body: JObject (required)
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID that specifies the ThreatIntelSet that you want to update.
  var path_602511 = newJObject()
  var body_602512 = newJObject()
  add(path_602511, "detectorId", newJString(detectorId))
  if body != nil:
    body_602512 = body
  add(path_602511, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_602510.call(path_602511, nil, nil, nil, body_602512)

var updateThreatIntelSet* = Call_UpdateThreatIntelSet_602496(
    name: "updateThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_UpdateThreatIntelSet_602497, base: "/",
    url: url_UpdateThreatIntelSet_602498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThreatIntelSet_602481 = ref object of OpenApiRestCall_601389
proc url_GetThreatIntelSet_602483(protocol: Scheme; host: string; base: string;
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

proc validate_GetThreatIntelSet_602482(path: JsonNode; query: JsonNode;
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
  var valid_602484 = path.getOrDefault("detectorId")
  valid_602484 = validateParameter(valid_602484, JString, required = true,
                                 default = nil)
  if valid_602484 != nil:
    section.add "detectorId", valid_602484
  var valid_602485 = path.getOrDefault("threatIntelSetId")
  valid_602485 = validateParameter(valid_602485, JString, required = true,
                                 default = nil)
  if valid_602485 != nil:
    section.add "threatIntelSetId", valid_602485
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
  var valid_602486 = header.getOrDefault("X-Amz-Signature")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-Signature", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Content-Sha256", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-Date")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Date", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-Credential")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Credential", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Security-Token")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Security-Token", valid_602490
  var valid_602491 = header.getOrDefault("X-Amz-Algorithm")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Algorithm", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-SignedHeaders", valid_602492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602493: Call_GetThreatIntelSet_602481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ## 
  let valid = call_602493.validator(path, query, header, formData, body)
  let scheme = call_602493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602493.url(scheme.get, call_602493.host, call_602493.base,
                         call_602493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602493, url, valid)

proc call*(call_602494: Call_GetThreatIntelSet_602481; detectorId: string;
          threatIntelSetId: string): Recallable =
  ## getThreatIntelSet
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID of the threatIntelSet you want to get.
  var path_602495 = newJObject()
  add(path_602495, "detectorId", newJString(detectorId))
  add(path_602495, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_602494.call(path_602495, nil, nil, nil, nil)

var getThreatIntelSet* = Call_GetThreatIntelSet_602481(name: "getThreatIntelSet",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_GetThreatIntelSet_602482, base: "/",
    url: url_GetThreatIntelSet_602483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteThreatIntelSet_602513 = ref object of OpenApiRestCall_601389
proc url_DeleteThreatIntelSet_602515(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteThreatIntelSet_602514(path: JsonNode; query: JsonNode;
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
  var valid_602516 = path.getOrDefault("detectorId")
  valid_602516 = validateParameter(valid_602516, JString, required = true,
                                 default = nil)
  if valid_602516 != nil:
    section.add "detectorId", valid_602516
  var valid_602517 = path.getOrDefault("threatIntelSetId")
  valid_602517 = validateParameter(valid_602517, JString, required = true,
                                 default = nil)
  if valid_602517 != nil:
    section.add "threatIntelSetId", valid_602517
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
  var valid_602518 = header.getOrDefault("X-Amz-Signature")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "X-Amz-Signature", valid_602518
  var valid_602519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-Content-Sha256", valid_602519
  var valid_602520 = header.getOrDefault("X-Amz-Date")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Date", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-Credential")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Credential", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Security-Token")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Security-Token", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Algorithm")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Algorithm", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-SignedHeaders", valid_602524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602525: Call_DeleteThreatIntelSet_602513; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ## 
  let valid = call_602525.validator(path, query, header, formData, body)
  let scheme = call_602525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602525.url(scheme.get, call_602525.host, call_602525.base,
                         call_602525.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602525, url, valid)

proc call*(call_602526: Call_DeleteThreatIntelSet_602513; detectorId: string;
          threatIntelSetId: string): Recallable =
  ## deleteThreatIntelSet
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID of the threatIntelSet you want to delete.
  var path_602527 = newJObject()
  add(path_602527, "detectorId", newJString(detectorId))
  add(path_602527, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_602526.call(path_602527, nil, nil, nil, nil)

var deleteThreatIntelSet* = Call_DeleteThreatIntelSet_602513(
    name: "deleteThreatIntelSet", meth: HttpMethod.HttpDelete,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_DeleteThreatIntelSet_602514, base: "/",
    url: url_DeleteThreatIntelSet_602515, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_602528 = ref object of OpenApiRestCall_601389
proc url_DisassociateFromMasterAccount_602530(protocol: Scheme; host: string;
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

proc validate_DisassociateFromMasterAccount_602529(path: JsonNode; query: JsonNode;
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
  var valid_602531 = path.getOrDefault("detectorId")
  valid_602531 = validateParameter(valid_602531, JString, required = true,
                                 default = nil)
  if valid_602531 != nil:
    section.add "detectorId", valid_602531
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
  var valid_602532 = header.getOrDefault("X-Amz-Signature")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "X-Amz-Signature", valid_602532
  var valid_602533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-Content-Sha256", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Date")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Date", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-Credential")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-Credential", valid_602535
  var valid_602536 = header.getOrDefault("X-Amz-Security-Token")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "X-Amz-Security-Token", valid_602536
  var valid_602537 = header.getOrDefault("X-Amz-Algorithm")
  valid_602537 = validateParameter(valid_602537, JString, required = false,
                                 default = nil)
  if valid_602537 != nil:
    section.add "X-Amz-Algorithm", valid_602537
  var valid_602538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-SignedHeaders", valid_602538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602539: Call_DisassociateFromMasterAccount_602528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current GuardDuty member account from its master account.
  ## 
  let valid = call_602539.validator(path, query, header, formData, body)
  let scheme = call_602539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602539.url(scheme.get, call_602539.host, call_602539.base,
                         call_602539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602539, url, valid)

proc call*(call_602540: Call_DisassociateFromMasterAccount_602528;
          detectorId: string): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current GuardDuty member account from its master account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  var path_602541 = newJObject()
  add(path_602541, "detectorId", newJString(detectorId))
  result = call_602540.call(path_602541, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_602528(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_602529, base: "/",
    url: url_DisassociateFromMasterAccount_602530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_602542 = ref object of OpenApiRestCall_601389
proc url_DisassociateMembers_602544(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateMembers_602543(path: JsonNode; query: JsonNode;
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
  var valid_602545 = path.getOrDefault("detectorId")
  valid_602545 = validateParameter(valid_602545, JString, required = true,
                                 default = nil)
  if valid_602545 != nil:
    section.add "detectorId", valid_602545
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
  var valid_602546 = header.getOrDefault("X-Amz-Signature")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Signature", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Content-Sha256", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-Date")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-Date", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-Credential")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Credential", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-Security-Token")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Security-Token", valid_602550
  var valid_602551 = header.getOrDefault("X-Amz-Algorithm")
  valid_602551 = validateParameter(valid_602551, JString, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "X-Amz-Algorithm", valid_602551
  var valid_602552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "X-Amz-SignedHeaders", valid_602552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602554: Call_DisassociateMembers_602542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_602554.validator(path, query, header, formData, body)
  let scheme = call_602554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602554.url(scheme.get, call_602554.host, call_602554.base,
                         call_602554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602554, url, valid)

proc call*(call_602555: Call_DisassociateMembers_602542; detectorId: string;
          body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to disassociate from master.
  ##   body: JObject (required)
  var path_602556 = newJObject()
  var body_602557 = newJObject()
  add(path_602556, "detectorId", newJString(detectorId))
  if body != nil:
    body_602557 = body
  result = call_602555.call(path_602556, nil, nil, nil, body_602557)

var disassociateMembers* = Call_DisassociateMembers_602542(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/disassociate",
    validator: validate_DisassociateMembers_602543, base: "/",
    url: url_DisassociateMembers_602544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_602558 = ref object of OpenApiRestCall_601389
proc url_GetFindings_602560(protocol: Scheme; host: string; base: string;
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

proc validate_GetFindings_602559(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602561 = path.getOrDefault("detectorId")
  valid_602561 = validateParameter(valid_602561, JString, required = true,
                                 default = nil)
  if valid_602561 != nil:
    section.add "detectorId", valid_602561
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
  var valid_602562 = header.getOrDefault("X-Amz-Signature")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Signature", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Content-Sha256", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-Date")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Date", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Credential")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Credential", valid_602565
  var valid_602566 = header.getOrDefault("X-Amz-Security-Token")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "X-Amz-Security-Token", valid_602566
  var valid_602567 = header.getOrDefault("X-Amz-Algorithm")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "X-Amz-Algorithm", valid_602567
  var valid_602568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-SignedHeaders", valid_602568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602570: Call_GetFindings_602558; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes Amazon GuardDuty findings specified by finding IDs.
  ## 
  let valid = call_602570.validator(path, query, header, formData, body)
  let scheme = call_602570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602570.url(scheme.get, call_602570.host, call_602570.base,
                         call_602570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602570, url, valid)

proc call*(call_602571: Call_GetFindings_602558; detectorId: string; body: JsonNode): Recallable =
  ## getFindings
  ## Describes Amazon GuardDuty findings specified by finding IDs.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to retrieve.
  ##   body: JObject (required)
  var path_602572 = newJObject()
  var body_602573 = newJObject()
  add(path_602572, "detectorId", newJString(detectorId))
  if body != nil:
    body_602573 = body
  result = call_602571.call(path_602572, nil, nil, nil, body_602573)

var getFindings* = Call_GetFindings_602558(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/findings/get",
                                        validator: validate_GetFindings_602559,
                                        base: "/", url: url_GetFindings_602560,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindingsStatistics_602574 = ref object of OpenApiRestCall_601389
proc url_GetFindingsStatistics_602576(protocol: Scheme; host: string; base: string;
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

proc validate_GetFindingsStatistics_602575(path: JsonNode; query: JsonNode;
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
  var valid_602577 = path.getOrDefault("detectorId")
  valid_602577 = validateParameter(valid_602577, JString, required = true,
                                 default = nil)
  if valid_602577 != nil:
    section.add "detectorId", valid_602577
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
  var valid_602578 = header.getOrDefault("X-Amz-Signature")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Signature", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Content-Sha256", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Date")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Date", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Credential")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Credential", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Security-Token")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Security-Token", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-Algorithm")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Algorithm", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-SignedHeaders", valid_602584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602586: Call_GetFindingsStatistics_602574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
  ## 
  let valid = call_602586.validator(path, query, header, formData, body)
  let scheme = call_602586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602586.url(scheme.get, call_602586.host, call_602586.base,
                         call_602586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602586, url, valid)

proc call*(call_602587: Call_GetFindingsStatistics_602574; detectorId: string;
          body: JsonNode): Recallable =
  ## getFindingsStatistics
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings' statistics you want to retrieve.
  ##   body: JObject (required)
  var path_602588 = newJObject()
  var body_602589 = newJObject()
  add(path_602588, "detectorId", newJString(detectorId))
  if body != nil:
    body_602589 = body
  result = call_602587.call(path_602588, nil, nil, nil, body_602589)

var getFindingsStatistics* = Call_GetFindingsStatistics_602574(
    name: "getFindingsStatistics", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/statistics",
    validator: validate_GetFindingsStatistics_602575, base: "/",
    url: url_GetFindingsStatistics_602576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_602590 = ref object of OpenApiRestCall_601389
proc url_GetInvitationsCount_602592(protocol: Scheme; host: string; base: string;
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

proc validate_GetInvitationsCount_602591(path: JsonNode; query: JsonNode;
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
  var valid_602593 = header.getOrDefault("X-Amz-Signature")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Signature", valid_602593
  var valid_602594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Content-Sha256", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-Date")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Date", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Credential")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Credential", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Security-Token")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Security-Token", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Algorithm")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Algorithm", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-SignedHeaders", valid_602599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602600: Call_GetInvitationsCount_602590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
  ## 
  let valid = call_602600.validator(path, query, header, formData, body)
  let scheme = call_602600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602600.url(scheme.get, call_602600.host, call_602600.base,
                         call_602600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602600, url, valid)

proc call*(call_602601: Call_GetInvitationsCount_602590): Recallable =
  ## getInvitationsCount
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
  result = call_602601.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_602590(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/invitation/count",
    validator: validate_GetInvitationsCount_602591, base: "/",
    url: url_GetInvitationsCount_602592, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_602602 = ref object of OpenApiRestCall_601389
proc url_GetMembers_602604(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMembers_602603(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602605 = path.getOrDefault("detectorId")
  valid_602605 = validateParameter(valid_602605, JString, required = true,
                                 default = nil)
  if valid_602605 != nil:
    section.add "detectorId", valid_602605
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
  var valid_602606 = header.getOrDefault("X-Amz-Signature")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-Signature", valid_602606
  var valid_602607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602607 = validateParameter(valid_602607, JString, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "X-Amz-Content-Sha256", valid_602607
  var valid_602608 = header.getOrDefault("X-Amz-Date")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Date", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-Credential")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Credential", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-Security-Token")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Security-Token", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Algorithm")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Algorithm", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-SignedHeaders", valid_602612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602614: Call_GetMembers_602602; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_602614.validator(path, query, header, formData, body)
  let scheme = call_602614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602614.url(scheme.get, call_602614.host, call_602614.base,
                         call_602614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602614, url, valid)

proc call*(call_602615: Call_GetMembers_602602; detectorId: string; body: JsonNode): Recallable =
  ## getMembers
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to retrieve.
  ##   body: JObject (required)
  var path_602616 = newJObject()
  var body_602617 = newJObject()
  add(path_602616, "detectorId", newJString(detectorId))
  if body != nil:
    body_602617 = body
  result = call_602615.call(path_602616, nil, nil, nil, body_602617)

var getMembers* = Call_GetMembers_602602(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/get",
                                      validator: validate_GetMembers_602603,
                                      base: "/", url: url_GetMembers_602604,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_602618 = ref object of OpenApiRestCall_601389
proc url_InviteMembers_602620(protocol: Scheme; host: string; base: string;
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

proc validate_InviteMembers_602619(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602621 = path.getOrDefault("detectorId")
  valid_602621 = validateParameter(valid_602621, JString, required = true,
                                 default = nil)
  if valid_602621 != nil:
    section.add "detectorId", valid_602621
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
  var valid_602622 = header.getOrDefault("X-Amz-Signature")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "X-Amz-Signature", valid_602622
  var valid_602623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Content-Sha256", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-Date")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Date", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Credential")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Credential", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-Security-Token")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Security-Token", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-Algorithm")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Algorithm", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-SignedHeaders", valid_602628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602630: Call_InviteMembers_602618; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
  ## 
  let valid = call_602630.validator(path, query, header, formData, body)
  let scheme = call_602630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602630.url(scheme.get, call_602630.host, call_602630.base,
                         call_602630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602630, url, valid)

proc call*(call_602631: Call_InviteMembers_602618; detectorId: string; body: JsonNode): Recallable =
  ## inviteMembers
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account with which you want to invite members.
  ##   body: JObject (required)
  var path_602632 = newJObject()
  var body_602633 = newJObject()
  add(path_602632, "detectorId", newJString(detectorId))
  if body != nil:
    body_602633 = body
  result = call_602631.call(path_602632, nil, nil, nil, body_602633)

var inviteMembers* = Call_InviteMembers_602618(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/invite",
    validator: validate_InviteMembers_602619, base: "/", url: url_InviteMembers_602620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_602634 = ref object of OpenApiRestCall_601389
proc url_ListFindings_602636(protocol: Scheme; host: string; base: string;
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

proc validate_ListFindings_602635(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602637 = path.getOrDefault("detectorId")
  valid_602637 = validateParameter(valid_602637, JString, required = true,
                                 default = nil)
  if valid_602637 != nil:
    section.add "detectorId", valid_602637
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602638 = query.getOrDefault("MaxResults")
  valid_602638 = validateParameter(valid_602638, JString, required = false,
                                 default = nil)
  if valid_602638 != nil:
    section.add "MaxResults", valid_602638
  var valid_602639 = query.getOrDefault("NextToken")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "NextToken", valid_602639
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
  var valid_602640 = header.getOrDefault("X-Amz-Signature")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Signature", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Content-Sha256", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Date")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Date", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Credential")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Credential", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Security-Token")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Security-Token", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-Algorithm")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Algorithm", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-SignedHeaders", valid_602646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602648: Call_ListFindings_602634; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists Amazon GuardDuty findings for the specified detector ID.
  ## 
  let valid = call_602648.validator(path, query, header, formData, body)
  let scheme = call_602648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602648.url(scheme.get, call_602648.host, call_602648.base,
                         call_602648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602648, url, valid)

proc call*(call_602649: Call_ListFindings_602634; detectorId: string; body: JsonNode;
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
  var path_602650 = newJObject()
  var query_602651 = newJObject()
  var body_602652 = newJObject()
  add(query_602651, "MaxResults", newJString(MaxResults))
  add(path_602650, "detectorId", newJString(detectorId))
  add(query_602651, "NextToken", newJString(NextToken))
  if body != nil:
    body_602652 = body
  result = call_602649.call(path_602650, query_602651, nil, nil, body_602652)

var listFindings* = Call_ListFindings_602634(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings", validator: validate_ListFindings_602635,
    base: "/", url: url_ListFindings_602636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_602653 = ref object of OpenApiRestCall_601389
proc url_ListInvitations_602655(protocol: Scheme; host: string; base: string;
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

proc validate_ListInvitations_602654(path: JsonNode; query: JsonNode;
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
  var valid_602656 = query.getOrDefault("nextToken")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "nextToken", valid_602656
  var valid_602657 = query.getOrDefault("MaxResults")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "MaxResults", valid_602657
  var valid_602658 = query.getOrDefault("NextToken")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "NextToken", valid_602658
  var valid_602659 = query.getOrDefault("maxResults")
  valid_602659 = validateParameter(valid_602659, JInt, required = false, default = nil)
  if valid_602659 != nil:
    section.add "maxResults", valid_602659
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
  var valid_602660 = header.getOrDefault("X-Amz-Signature")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Signature", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-Content-Sha256", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-Date")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-Date", valid_602662
  var valid_602663 = header.getOrDefault("X-Amz-Credential")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "X-Amz-Credential", valid_602663
  var valid_602664 = header.getOrDefault("X-Amz-Security-Token")
  valid_602664 = validateParameter(valid_602664, JString, required = false,
                                 default = nil)
  if valid_602664 != nil:
    section.add "X-Amz-Security-Token", valid_602664
  var valid_602665 = header.getOrDefault("X-Amz-Algorithm")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "X-Amz-Algorithm", valid_602665
  var valid_602666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-SignedHeaders", valid_602666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602667: Call_ListInvitations_602653; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all GuardDuty membership invitations that were sent to the current AWS account.
  ## 
  let valid = call_602667.validator(path, query, header, formData, body)
  let scheme = call_602667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602667.url(scheme.get, call_602667.host, call_602667.base,
                         call_602667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602667, url, valid)

proc call*(call_602668: Call_ListInvitations_602653; nextToken: string = "";
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
  var query_602669 = newJObject()
  add(query_602669, "nextToken", newJString(nextToken))
  add(query_602669, "MaxResults", newJString(MaxResults))
  add(query_602669, "NextToken", newJString(NextToken))
  add(query_602669, "maxResults", newJInt(maxResults))
  result = call_602668.call(nil, query_602669, nil, nil, nil)

var listInvitations* = Call_ListInvitations_602653(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com", route: "/invitation",
    validator: validate_ListInvitations_602654, base: "/", url: url_ListInvitations_602655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602684 = ref object of OpenApiRestCall_601389
proc url_TagResource_602686(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602685(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602687 = path.getOrDefault("resourceArn")
  valid_602687 = validateParameter(valid_602687, JString, required = true,
                                 default = nil)
  if valid_602687 != nil:
    section.add "resourceArn", valid_602687
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
  var valid_602688 = header.getOrDefault("X-Amz-Signature")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-Signature", valid_602688
  var valid_602689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-Content-Sha256", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Date")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Date", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Credential")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Credential", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-Security-Token")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Security-Token", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-Algorithm")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-Algorithm", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-SignedHeaders", valid_602694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602696: Call_TagResource_602684; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource.
  ## 
  let valid = call_602696.validator(path, query, header, formData, body)
  let scheme = call_602696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602696.url(scheme.get, call_602696.host, call_602696.base,
                         call_602696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602696, url, valid)

proc call*(call_602697: Call_TagResource_602684; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds tags to a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the GuardDuty resource to apply a tag to.
  ##   body: JObject (required)
  var path_602698 = newJObject()
  var body_602699 = newJObject()
  add(path_602698, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_602699 = body
  result = call_602697.call(path_602698, nil, nil, nil, body_602699)

var tagResource* = Call_TagResource_602684(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_602685,
                                        base: "/", url: url_TagResource_602686,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602670 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602672(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602671(path: JsonNode; query: JsonNode;
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
  var valid_602673 = path.getOrDefault("resourceArn")
  valid_602673 = validateParameter(valid_602673, JString, required = true,
                                 default = nil)
  if valid_602673 != nil:
    section.add "resourceArn", valid_602673
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
  var valid_602674 = header.getOrDefault("X-Amz-Signature")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Signature", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Content-Sha256", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Date")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Date", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Credential")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Credential", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Security-Token")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Security-Token", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Algorithm")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Algorithm", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-SignedHeaders", valid_602680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602681: Call_ListTagsForResource_602670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
  ## 
  let valid = call_602681.validator(path, query, header, formData, body)
  let scheme = call_602681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602681.url(scheme.get, call_602681.host, call_602681.base,
                         call_602681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602681, url, valid)

proc call*(call_602682: Call_ListTagsForResource_602670; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the given GuardDuty resource 
  var path_602683 = newJObject()
  add(path_602683, "resourceArn", newJString(resourceArn))
  result = call_602682.call(path_602683, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602670(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_602671, base: "/",
    url: url_ListTagsForResource_602672, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringMembers_602700 = ref object of OpenApiRestCall_601389
proc url_StartMonitoringMembers_602702(protocol: Scheme; host: string; base: string;
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

proc validate_StartMonitoringMembers_602701(path: JsonNode; query: JsonNode;
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
  var valid_602703 = path.getOrDefault("detectorId")
  valid_602703 = validateParameter(valid_602703, JString, required = true,
                                 default = nil)
  if valid_602703 != nil:
    section.add "detectorId", valid_602703
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
  var valid_602704 = header.getOrDefault("X-Amz-Signature")
  valid_602704 = validateParameter(valid_602704, JString, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "X-Amz-Signature", valid_602704
  var valid_602705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602705 = validateParameter(valid_602705, JString, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "X-Amz-Content-Sha256", valid_602705
  var valid_602706 = header.getOrDefault("X-Amz-Date")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "X-Amz-Date", valid_602706
  var valid_602707 = header.getOrDefault("X-Amz-Credential")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "X-Amz-Credential", valid_602707
  var valid_602708 = header.getOrDefault("X-Amz-Security-Token")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "X-Amz-Security-Token", valid_602708
  var valid_602709 = header.getOrDefault("X-Amz-Algorithm")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Algorithm", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-SignedHeaders", valid_602710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602712: Call_StartMonitoringMembers_602700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Turns on GuardDuty monitoring of the specified member accounts. Use this operation to restart monitoring of accounts that you stopped monitoring with the <code>StopMonitoringMembers</code> operation.
  ## 
  let valid = call_602712.validator(path, query, header, formData, body)
  let scheme = call_602712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602712.url(scheme.get, call_602712.host, call_602712.base,
                         call_602712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602712, url, valid)

proc call*(call_602713: Call_StartMonitoringMembers_602700; detectorId: string;
          body: JsonNode): Recallable =
  ## startMonitoringMembers
  ## Turns on GuardDuty monitoring of the specified member accounts. Use this operation to restart monitoring of accounts that you stopped monitoring with the <code>StopMonitoringMembers</code> operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty master account associated with the member accounts to monitor.
  ##   body: JObject (required)
  var path_602714 = newJObject()
  var body_602715 = newJObject()
  add(path_602714, "detectorId", newJString(detectorId))
  if body != nil:
    body_602715 = body
  result = call_602713.call(path_602714, nil, nil, nil, body_602715)

var startMonitoringMembers* = Call_StartMonitoringMembers_602700(
    name: "startMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/start",
    validator: validate_StartMonitoringMembers_602701, base: "/",
    url: url_StartMonitoringMembers_602702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringMembers_602716 = ref object of OpenApiRestCall_601389
proc url_StopMonitoringMembers_602718(protocol: Scheme; host: string; base: string;
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

proc validate_StopMonitoringMembers_602717(path: JsonNode; query: JsonNode;
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
  var valid_602719 = path.getOrDefault("detectorId")
  valid_602719 = validateParameter(valid_602719, JString, required = true,
                                 default = nil)
  if valid_602719 != nil:
    section.add "detectorId", valid_602719
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
  var valid_602720 = header.getOrDefault("X-Amz-Signature")
  valid_602720 = validateParameter(valid_602720, JString, required = false,
                                 default = nil)
  if valid_602720 != nil:
    section.add "X-Amz-Signature", valid_602720
  var valid_602721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602721 = validateParameter(valid_602721, JString, required = false,
                                 default = nil)
  if valid_602721 != nil:
    section.add "X-Amz-Content-Sha256", valid_602721
  var valid_602722 = header.getOrDefault("X-Amz-Date")
  valid_602722 = validateParameter(valid_602722, JString, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "X-Amz-Date", valid_602722
  var valid_602723 = header.getOrDefault("X-Amz-Credential")
  valid_602723 = validateParameter(valid_602723, JString, required = false,
                                 default = nil)
  if valid_602723 != nil:
    section.add "X-Amz-Credential", valid_602723
  var valid_602724 = header.getOrDefault("X-Amz-Security-Token")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-Security-Token", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-Algorithm")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Algorithm", valid_602725
  var valid_602726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-SignedHeaders", valid_602726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602728: Call_StopMonitoringMembers_602716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops GuardDuty monitoring for the specified member accounnts. Use the <code>StartMonitoringMembers</code> to restart monitoring for those accounts.
  ## 
  let valid = call_602728.validator(path, query, header, formData, body)
  let scheme = call_602728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602728.url(scheme.get, call_602728.host, call_602728.base,
                         call_602728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602728, url, valid)

proc call*(call_602729: Call_StopMonitoringMembers_602716; detectorId: string;
          body: JsonNode): Recallable =
  ## stopMonitoringMembers
  ## Stops GuardDuty monitoring for the specified member accounnts. Use the <code>StartMonitoringMembers</code> to restart monitoring for those accounts.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account that you want to stop from monitor members' findings.
  ##   body: JObject (required)
  var path_602730 = newJObject()
  var body_602731 = newJObject()
  add(path_602730, "detectorId", newJString(detectorId))
  if body != nil:
    body_602731 = body
  result = call_602729.call(path_602730, nil, nil, nil, body_602731)

var stopMonitoringMembers* = Call_StopMonitoringMembers_602716(
    name: "stopMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/stop",
    validator: validate_StopMonitoringMembers_602717, base: "/",
    url: url_StopMonitoringMembers_602718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnarchiveFindings_602732 = ref object of OpenApiRestCall_601389
proc url_UnarchiveFindings_602734(protocol: Scheme; host: string; base: string;
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

proc validate_UnarchiveFindings_602733(path: JsonNode; query: JsonNode;
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
  var valid_602735 = path.getOrDefault("detectorId")
  valid_602735 = validateParameter(valid_602735, JString, required = true,
                                 default = nil)
  if valid_602735 != nil:
    section.add "detectorId", valid_602735
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
  var valid_602736 = header.getOrDefault("X-Amz-Signature")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "X-Amz-Signature", valid_602736
  var valid_602737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-Content-Sha256", valid_602737
  var valid_602738 = header.getOrDefault("X-Amz-Date")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-Date", valid_602738
  var valid_602739 = header.getOrDefault("X-Amz-Credential")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "X-Amz-Credential", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-Security-Token")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-Security-Token", valid_602740
  var valid_602741 = header.getOrDefault("X-Amz-Algorithm")
  valid_602741 = validateParameter(valid_602741, JString, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "X-Amz-Algorithm", valid_602741
  var valid_602742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "X-Amz-SignedHeaders", valid_602742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602744: Call_UnarchiveFindings_602732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Unarchives GuardDuty findings specified by the <code>findingIds</code>.
  ## 
  let valid = call_602744.validator(path, query, header, formData, body)
  let scheme = call_602744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602744.url(scheme.get, call_602744.host, call_602744.base,
                         call_602744.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602744, url, valid)

proc call*(call_602745: Call_UnarchiveFindings_602732; detectorId: string;
          body: JsonNode): Recallable =
  ## unarchiveFindings
  ## Unarchives GuardDuty findings specified by the <code>findingIds</code>.
  ##   detectorId: string (required)
  ##             : The ID of the detector associated with the findings to unarchive.
  ##   body: JObject (required)
  var path_602746 = newJObject()
  var body_602747 = newJObject()
  add(path_602746, "detectorId", newJString(detectorId))
  if body != nil:
    body_602747 = body
  result = call_602745.call(path_602746, nil, nil, nil, body_602747)

var unarchiveFindings* = Call_UnarchiveFindings_602732(name: "unarchiveFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/unarchive",
    validator: validate_UnarchiveFindings_602733, base: "/",
    url: url_UnarchiveFindings_602734, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602748 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602750(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602749(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602751 = path.getOrDefault("resourceArn")
  valid_602751 = validateParameter(valid_602751, JString, required = true,
                                 default = nil)
  if valid_602751 != nil:
    section.add "resourceArn", valid_602751
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602752 = query.getOrDefault("tagKeys")
  valid_602752 = validateParameter(valid_602752, JArray, required = true, default = nil)
  if valid_602752 != nil:
    section.add "tagKeys", valid_602752
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
  var valid_602753 = header.getOrDefault("X-Amz-Signature")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-Signature", valid_602753
  var valid_602754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Content-Sha256", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-Date")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-Date", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-Credential")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-Credential", valid_602756
  var valid_602757 = header.getOrDefault("X-Amz-Security-Token")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-Security-Token", valid_602757
  var valid_602758 = header.getOrDefault("X-Amz-Algorithm")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "X-Amz-Algorithm", valid_602758
  var valid_602759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-SignedHeaders", valid_602759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602760: Call_UntagResource_602748; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_602760.validator(path, query, header, formData, body)
  let scheme = call_602760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602760.url(scheme.get, call_602760.host, call_602760.base,
                         call_602760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602760, url, valid)

proc call*(call_602761: Call_UntagResource_602748; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the resource to remove tags from.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the resource.
  var path_602762 = newJObject()
  var query_602763 = newJObject()
  add(path_602762, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_602763.add "tagKeys", tagKeys
  result = call_602761.call(path_602762, query_602763, nil, nil, nil)

var untagResource* = Call_UntagResource_602748(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_602749,
    base: "/", url: url_UntagResource_602750, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindingsFeedback_602764 = ref object of OpenApiRestCall_601389
proc url_UpdateFindingsFeedback_602766(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFindingsFeedback_602765(path: JsonNode; query: JsonNode;
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
  var valid_602767 = path.getOrDefault("detectorId")
  valid_602767 = validateParameter(valid_602767, JString, required = true,
                                 default = nil)
  if valid_602767 != nil:
    section.add "detectorId", valid_602767
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
  var valid_602768 = header.getOrDefault("X-Amz-Signature")
  valid_602768 = validateParameter(valid_602768, JString, required = false,
                                 default = nil)
  if valid_602768 != nil:
    section.add "X-Amz-Signature", valid_602768
  var valid_602769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-Content-Sha256", valid_602769
  var valid_602770 = header.getOrDefault("X-Amz-Date")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-Date", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-Credential")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-Credential", valid_602771
  var valid_602772 = header.getOrDefault("X-Amz-Security-Token")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Security-Token", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Algorithm")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Algorithm", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-SignedHeaders", valid_602774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602776: Call_UpdateFindingsFeedback_602764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Marks the specified GuardDuty findings as useful or not useful.
  ## 
  let valid = call_602776.validator(path, query, header, formData, body)
  let scheme = call_602776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602776.url(scheme.get, call_602776.host, call_602776.base,
                         call_602776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602776, url, valid)

proc call*(call_602777: Call_UpdateFindingsFeedback_602764; detectorId: string;
          body: JsonNode): Recallable =
  ## updateFindingsFeedback
  ## Marks the specified GuardDuty findings as useful or not useful.
  ##   detectorId: string (required)
  ##             : The ID of the detector associated with the findings to update feedback for.
  ##   body: JObject (required)
  var path_602778 = newJObject()
  var body_602779 = newJObject()
  add(path_602778, "detectorId", newJString(detectorId))
  if body != nil:
    body_602779 = body
  result = call_602777.call(path_602778, nil, nil, nil, body_602779)

var updateFindingsFeedback* = Call_UpdateFindingsFeedback_602764(
    name: "updateFindingsFeedback", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/feedback",
    validator: validate_UpdateFindingsFeedback_602765, base: "/",
    url: url_UpdateFindingsFeedback_602766, schemes: {Scheme.Https, Scheme.Http})
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
