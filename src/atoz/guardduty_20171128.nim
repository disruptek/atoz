
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_AcceptInvitation_599975 = ref object of OpenApiRestCall_599368
proc url_AcceptInvitation_599977(protocol: Scheme; host: string; base: string;
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

proc validate_AcceptInvitation_599976(path: JsonNode; query: JsonNode;
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
  var valid_599978 = path.getOrDefault("detectorId")
  valid_599978 = validateParameter(valid_599978, JString, required = true,
                                 default = nil)
  if valid_599978 != nil:
    section.add "detectorId", valid_599978
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599979 = header.getOrDefault("X-Amz-Date")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Date", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Security-Token")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Security-Token", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Content-Sha256", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Algorithm")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Algorithm", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Signature")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Signature", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-SignedHeaders", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Credential")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Credential", valid_599985
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599987: Call_AcceptInvitation_599975; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts the invitation to be monitored by a master GuardDuty account.
  ## 
  let valid = call_599987.validator(path, query, header, formData, body)
  let scheme = call_599987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599987.url(scheme.get, call_599987.host, call_599987.base,
                         call_599987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599987, url, valid)

proc call*(call_599988: Call_AcceptInvitation_599975; detectorId: string;
          body: JsonNode): Recallable =
  ## acceptInvitation
  ## Accepts the invitation to be monitored by a master GuardDuty account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  ##   body: JObject (required)
  var path_599989 = newJObject()
  var body_599990 = newJObject()
  add(path_599989, "detectorId", newJString(detectorId))
  if body != nil:
    body_599990 = body
  result = call_599988.call(path_599989, nil, nil, nil, body_599990)

var acceptInvitation* = Call_AcceptInvitation_599975(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master", validator: validate_AcceptInvitation_599976,
    base: "/", url: url_AcceptInvitation_599977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_599705 = ref object of OpenApiRestCall_599368
proc url_GetMasterAccount_599707(protocol: Scheme; host: string; base: string;
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

proc validate_GetMasterAccount_599706(path: JsonNode; query: JsonNode;
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
  var valid_599833 = path.getOrDefault("detectorId")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = nil)
  if valid_599833 != nil:
    section.add "detectorId", valid_599833
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599834 = header.getOrDefault("X-Amz-Date")
  valid_599834 = validateParameter(valid_599834, JString, required = false,
                                 default = nil)
  if valid_599834 != nil:
    section.add "X-Amz-Date", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Security-Token")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Security-Token", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Content-Sha256", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Algorithm")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Algorithm", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Signature")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Signature", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-SignedHeaders", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Credential")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Credential", valid_599840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_GetMasterAccount_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_GetMasterAccount_599705; detectorId: string): Recallable =
  ## getMasterAccount
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  var path_599935 = newJObject()
  add(path_599935, "detectorId", newJString(detectorId))
  result = call_599934.call(path_599935, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_599705(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master", validator: validate_GetMasterAccount_599706,
    base: "/", url: url_GetMasterAccount_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ArchiveFindings_599991 = ref object of OpenApiRestCall_599368
proc url_ArchiveFindings_599993(protocol: Scheme; host: string; base: string;
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

proc validate_ArchiveFindings_599992(path: JsonNode; query: JsonNode;
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
  var valid_599994 = path.getOrDefault("detectorId")
  valid_599994 = validateParameter(valid_599994, JString, required = true,
                                 default = nil)
  if valid_599994 != nil:
    section.add "detectorId", valid_599994
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599995 = header.getOrDefault("X-Amz-Date")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Date", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Security-Token")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Security-Token", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Content-Sha256", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Algorithm")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Algorithm", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Signature")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Signature", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-SignedHeaders", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Credential")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Credential", valid_600001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600003: Call_ArchiveFindings_599991; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
  ## 
  let valid = call_600003.validator(path, query, header, formData, body)
  let scheme = call_600003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600003.url(scheme.get, call_600003.host, call_600003.base,
                         call_600003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600003, url, valid)

proc call*(call_600004: Call_ArchiveFindings_599991; detectorId: string;
          body: JsonNode): Recallable =
  ## archiveFindings
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to archive.
  ##   body: JObject (required)
  var path_600005 = newJObject()
  var body_600006 = newJObject()
  add(path_600005, "detectorId", newJString(detectorId))
  if body != nil:
    body_600006 = body
  result = call_600004.call(path_600005, nil, nil, nil, body_600006)

var archiveFindings* = Call_ArchiveFindings_599991(name: "archiveFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/archive",
    validator: validate_ArchiveFindings_599992, base: "/", url: url_ArchiveFindings_599993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDetector_600024 = ref object of OpenApiRestCall_599368
proc url_CreateDetector_600026(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDetector_600025(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600027 = header.getOrDefault("X-Amz-Date")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Date", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Security-Token")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Security-Token", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Content-Sha256", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Algorithm")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Algorithm", valid_600030
  var valid_600031 = header.getOrDefault("X-Amz-Signature")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Signature", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-SignedHeaders", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-Credential")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Credential", valid_600033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600035: Call_CreateDetector_600024; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
  ## 
  let valid = call_600035.validator(path, query, header, formData, body)
  let scheme = call_600035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600035.url(scheme.get, call_600035.host, call_600035.base,
                         call_600035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600035, url, valid)

proc call*(call_600036: Call_CreateDetector_600024; body: JsonNode): Recallable =
  ## createDetector
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
  ##   body: JObject (required)
  var body_600037 = newJObject()
  if body != nil:
    body_600037 = body
  result = call_600036.call(nil, nil, nil, nil, body_600037)

var createDetector* = Call_CreateDetector_600024(name: "createDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com", route: "/detector",
    validator: validate_CreateDetector_600025, base: "/", url: url_CreateDetector_600026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectors_600007 = ref object of OpenApiRestCall_599368
proc url_ListDetectors_600009(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDetectors_600008(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists detectorIds of all the existing Amazon GuardDuty detector resources.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   nextToken: JString
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600010 = query.getOrDefault("NextToken")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "NextToken", valid_600010
  var valid_600011 = query.getOrDefault("maxResults")
  valid_600011 = validateParameter(valid_600011, JInt, required = false, default = nil)
  if valid_600011 != nil:
    section.add "maxResults", valid_600011
  var valid_600012 = query.getOrDefault("nextToken")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "nextToken", valid_600012
  var valid_600013 = query.getOrDefault("MaxResults")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "MaxResults", valid_600013
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600014 = header.getOrDefault("X-Amz-Date")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Date", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Security-Token")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Security-Token", valid_600015
  var valid_600016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Content-Sha256", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Algorithm")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Algorithm", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Signature")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Signature", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-SignedHeaders", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Credential")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Credential", valid_600020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600021: Call_ListDetectors_600007; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists detectorIds of all the existing Amazon GuardDuty detector resources.
  ## 
  let valid = call_600021.validator(path, query, header, formData, body)
  let scheme = call_600021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600021.url(scheme.get, call_600021.host, call_600021.base,
                         call_600021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600021, url, valid)

proc call*(call_600022: Call_ListDetectors_600007; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDetectors
  ## Lists detectorIds of all the existing Amazon GuardDuty detector resources.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   nextToken: string
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600023 = newJObject()
  add(query_600023, "NextToken", newJString(NextToken))
  add(query_600023, "maxResults", newJInt(maxResults))
  add(query_600023, "nextToken", newJString(nextToken))
  add(query_600023, "MaxResults", newJString(MaxResults))
  result = call_600022.call(nil, query_600023, nil, nil, nil)

var listDetectors* = Call_ListDetectors_600007(name: "listDetectors",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com", route: "/detector",
    validator: validate_ListDetectors_600008, base: "/", url: url_ListDetectors_600009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFilter_600057 = ref object of OpenApiRestCall_599368
proc url_CreateFilter_600059(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFilter_600058(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600060 = path.getOrDefault("detectorId")
  valid_600060 = validateParameter(valid_600060, JString, required = true,
                                 default = nil)
  if valid_600060 != nil:
    section.add "detectorId", valid_600060
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600061 = header.getOrDefault("X-Amz-Date")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Date", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-Security-Token")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Security-Token", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Content-Sha256", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Algorithm")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Algorithm", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Signature")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Signature", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-SignedHeaders", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Credential")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Credential", valid_600067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600069: Call_CreateFilter_600057; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a filter using the specified finding criteria.
  ## 
  let valid = call_600069.validator(path, query, header, formData, body)
  let scheme = call_600069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600069.url(scheme.get, call_600069.host, call_600069.base,
                         call_600069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600069, url, valid)

proc call*(call_600070: Call_CreateFilter_600057; detectorId: string; body: JsonNode): Recallable =
  ## createFilter
  ## Creates a filter using the specified finding criteria.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create a filter.
  ##   body: JObject (required)
  var path_600071 = newJObject()
  var body_600072 = newJObject()
  add(path_600071, "detectorId", newJString(detectorId))
  if body != nil:
    body_600072 = body
  result = call_600070.call(path_600071, nil, nil, nil, body_600072)

var createFilter* = Call_CreateFilter_600057(name: "createFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter", validator: validate_CreateFilter_600058,
    base: "/", url: url_CreateFilter_600059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFilters_600038 = ref object of OpenApiRestCall_599368
proc url_ListFilters_600040(protocol: Scheme; host: string; base: string;
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

proc validate_ListFilters_600039(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600041 = path.getOrDefault("detectorId")
  valid_600041 = validateParameter(valid_600041, JString, required = true,
                                 default = nil)
  if valid_600041 != nil:
    section.add "detectorId", valid_600041
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   nextToken: JString
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600042 = query.getOrDefault("NextToken")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "NextToken", valid_600042
  var valid_600043 = query.getOrDefault("maxResults")
  valid_600043 = validateParameter(valid_600043, JInt, required = false, default = nil)
  if valid_600043 != nil:
    section.add "maxResults", valid_600043
  var valid_600044 = query.getOrDefault("nextToken")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "nextToken", valid_600044
  var valid_600045 = query.getOrDefault("MaxResults")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "MaxResults", valid_600045
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600046 = header.getOrDefault("X-Amz-Date")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Date", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Security-Token")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Security-Token", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Content-Sha256", valid_600048
  var valid_600049 = header.getOrDefault("X-Amz-Algorithm")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Algorithm", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Signature")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Signature", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-SignedHeaders", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Credential")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Credential", valid_600052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600053: Call_ListFilters_600038; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of the current filters.
  ## 
  let valid = call_600053.validator(path, query, header, formData, body)
  let scheme = call_600053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600053.url(scheme.get, call_600053.host, call_600053.base,
                         call_600053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600053, url, valid)

proc call*(call_600054: Call_ListFilters_600038; detectorId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listFilters
  ## Returns a paginated list of the current filters.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   nextToken: string
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600055 = newJObject()
  var query_600056 = newJObject()
  add(query_600056, "NextToken", newJString(NextToken))
  add(query_600056, "maxResults", newJInt(maxResults))
  add(query_600056, "nextToken", newJString(nextToken))
  add(path_600055, "detectorId", newJString(detectorId))
  add(query_600056, "MaxResults", newJString(MaxResults))
  result = call_600054.call(path_600055, query_600056, nil, nil, nil)

var listFilters* = Call_ListFilters_600038(name: "listFilters",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/filter",
                                        validator: validate_ListFilters_600039,
                                        base: "/", url: url_ListFilters_600040,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIPSet_600092 = ref object of OpenApiRestCall_599368
proc url_CreateIPSet_600094(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIPSet_600093(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600095 = path.getOrDefault("detectorId")
  valid_600095 = validateParameter(valid_600095, JString, required = true,
                                 default = nil)
  if valid_600095 != nil:
    section.add "detectorId", valid_600095
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600096 = header.getOrDefault("X-Amz-Date")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-Date", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-Security-Token")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Security-Token", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Content-Sha256", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-Algorithm")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Algorithm", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Signature")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Signature", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-SignedHeaders", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Credential")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Credential", valid_600102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600104: Call_CreateIPSet_600092; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new IPSet, called Trusted IP list in the consoler user interface. An IPSet is a list IP addresses trusted for secure communication with AWS infrastructure and applications. GuardDuty does not generate findings for IP addresses included in IPSets. Only users from the master account can use this operation.
  ## 
  let valid = call_600104.validator(path, query, header, formData, body)
  let scheme = call_600104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600104.url(scheme.get, call_600104.host, call_600104.base,
                         call_600104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600104, url, valid)

proc call*(call_600105: Call_CreateIPSet_600092; detectorId: string; body: JsonNode): Recallable =
  ## createIPSet
  ## Creates a new IPSet, called Trusted IP list in the consoler user interface. An IPSet is a list IP addresses trusted for secure communication with AWS infrastructure and applications. GuardDuty does not generate findings for IP addresses included in IPSets. Only users from the master account can use this operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create an IPSet.
  ##   body: JObject (required)
  var path_600106 = newJObject()
  var body_600107 = newJObject()
  add(path_600106, "detectorId", newJString(detectorId))
  if body != nil:
    body_600107 = body
  result = call_600105.call(path_600106, nil, nil, nil, body_600107)

var createIPSet* = Call_CreateIPSet_600092(name: "createIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/ipset",
                                        validator: validate_CreateIPSet_600093,
                                        base: "/", url: url_CreateIPSet_600094,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIPSets_600073 = ref object of OpenApiRestCall_599368
proc url_ListIPSets_600075(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListIPSets_600074(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600076 = path.getOrDefault("detectorId")
  valid_600076 = validateParameter(valid_600076, JString, required = true,
                                 default = nil)
  if valid_600076 != nil:
    section.add "detectorId", valid_600076
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   nextToken: JString
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600077 = query.getOrDefault("NextToken")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "NextToken", valid_600077
  var valid_600078 = query.getOrDefault("maxResults")
  valid_600078 = validateParameter(valid_600078, JInt, required = false, default = nil)
  if valid_600078 != nil:
    section.add "maxResults", valid_600078
  var valid_600079 = query.getOrDefault("nextToken")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "nextToken", valid_600079
  var valid_600080 = query.getOrDefault("MaxResults")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "MaxResults", valid_600080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600081 = header.getOrDefault("X-Amz-Date")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Date", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Security-Token")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Security-Token", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Content-Sha256", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Algorithm")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Algorithm", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Signature")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Signature", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-SignedHeaders", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Credential")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Credential", valid_600087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600088: Call_ListIPSets_600073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the IPSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the IPSets returned are the IPSets from the associated master account.
  ## 
  let valid = call_600088.validator(path, query, header, formData, body)
  let scheme = call_600088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600088.url(scheme.get, call_600088.host, call_600088.base,
                         call_600088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600088, url, valid)

proc call*(call_600089: Call_ListIPSets_600073; detectorId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listIPSets
  ## Lists the IPSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the IPSets returned are the IPSets from the associated master account.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   nextToken: string
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the ipSet is associated with.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600090 = newJObject()
  var query_600091 = newJObject()
  add(query_600091, "NextToken", newJString(NextToken))
  add(query_600091, "maxResults", newJInt(maxResults))
  add(query_600091, "nextToken", newJString(nextToken))
  add(path_600090, "detectorId", newJString(detectorId))
  add(query_600091, "MaxResults", newJString(MaxResults))
  result = call_600089.call(path_600090, query_600091, nil, nil, nil)

var listIPSets* = Call_ListIPSets_600073(name: "listIPSets",
                                      meth: HttpMethod.HttpGet,
                                      host: "guardduty.amazonaws.com",
                                      route: "/detector/{detectorId}/ipset",
                                      validator: validate_ListIPSets_600074,
                                      base: "/", url: url_ListIPSets_600075,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_600128 = ref object of OpenApiRestCall_599368
proc url_CreateMembers_600130(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMembers_600129(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600131 = path.getOrDefault("detectorId")
  valid_600131 = validateParameter(valid_600131, JString, required = true,
                                 default = nil)
  if valid_600131 != nil:
    section.add "detectorId", valid_600131
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600132 = header.getOrDefault("X-Amz-Date")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Date", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Security-Token")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Security-Token", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Content-Sha256", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Algorithm")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Algorithm", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-Signature")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Signature", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-SignedHeaders", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-Credential")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-Credential", valid_600138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600140: Call_CreateMembers_600128; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
  ## 
  let valid = call_600140.validator(path, query, header, formData, body)
  let scheme = call_600140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600140.url(scheme.get, call_600140.host, call_600140.base,
                         call_600140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600140, url, valid)

proc call*(call_600141: Call_CreateMembers_600128; detectorId: string; body: JsonNode): Recallable =
  ## createMembers
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account with which you want to associate member accounts.
  ##   body: JObject (required)
  var path_600142 = newJObject()
  var body_600143 = newJObject()
  add(path_600142, "detectorId", newJString(detectorId))
  if body != nil:
    body_600143 = body
  result = call_600141.call(path_600142, nil, nil, nil, body_600143)

var createMembers* = Call_CreateMembers_600128(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member", validator: validate_CreateMembers_600129,
    base: "/", url: url_CreateMembers_600130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_600108 = ref object of OpenApiRestCall_599368
proc url_ListMembers_600110(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_600109(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600111 = path.getOrDefault("detectorId")
  valid_600111 = validateParameter(valid_600111, JString, required = true,
                                 default = nil)
  if valid_600111 != nil:
    section.add "detectorId", valid_600111
  result.add "path", section
  ## parameters in `query` object:
  ##   onlyAssociated: JString
  ##                 : Specifies whether to only return associated members or to return all members (including members which haven't been invited yet or have been disassociated).
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   nextToken: JString
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600112 = query.getOrDefault("onlyAssociated")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "onlyAssociated", valid_600112
  var valid_600113 = query.getOrDefault("NextToken")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "NextToken", valid_600113
  var valid_600114 = query.getOrDefault("maxResults")
  valid_600114 = validateParameter(valid_600114, JInt, required = false, default = nil)
  if valid_600114 != nil:
    section.add "maxResults", valid_600114
  var valid_600115 = query.getOrDefault("nextToken")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "nextToken", valid_600115
  var valid_600116 = query.getOrDefault("MaxResults")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "MaxResults", valid_600116
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600117 = header.getOrDefault("X-Amz-Date")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Date", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Security-Token")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Security-Token", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Content-Sha256", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Algorithm")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Algorithm", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Signature")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Signature", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-SignedHeaders", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Credential")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Credential", valid_600123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600124: Call_ListMembers_600108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current GuardDuty master account.
  ## 
  let valid = call_600124.validator(path, query, header, formData, body)
  let scheme = call_600124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600124.url(scheme.get, call_600124.host, call_600124.base,
                         call_600124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600124, url, valid)

proc call*(call_600125: Call_ListMembers_600108; detectorId: string;
          onlyAssociated: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listMembers
  ## Lists details about all member accounts for the current GuardDuty master account.
  ##   onlyAssociated: string
  ##                 : Specifies whether to only return associated members or to return all members (including members which haven't been invited yet or have been disassociated).
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   nextToken: string
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the member is associated with.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600126 = newJObject()
  var query_600127 = newJObject()
  add(query_600127, "onlyAssociated", newJString(onlyAssociated))
  add(query_600127, "NextToken", newJString(NextToken))
  add(query_600127, "maxResults", newJInt(maxResults))
  add(query_600127, "nextToken", newJString(nextToken))
  add(path_600126, "detectorId", newJString(detectorId))
  add(query_600127, "MaxResults", newJString(MaxResults))
  result = call_600125.call(path_600126, query_600127, nil, nil, nil)

var listMembers* = Call_ListMembers_600108(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/member",
                                        validator: validate_ListMembers_600109,
                                        base: "/", url: url_ListMembers_600110,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublishingDestination_600163 = ref object of OpenApiRestCall_599368
proc url_CreatePublishingDestination_600165(protocol: Scheme; host: string;
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

proc validate_CreatePublishingDestination_600164(path: JsonNode; query: JsonNode;
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
  var valid_600166 = path.getOrDefault("detectorId")
  valid_600166 = validateParameter(valid_600166, JString, required = true,
                                 default = nil)
  if valid_600166 != nil:
    section.add "detectorId", valid_600166
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600167 = header.getOrDefault("X-Amz-Date")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Date", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Security-Token")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Security-Token", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Content-Sha256", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Algorithm")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Algorithm", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Signature")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Signature", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-SignedHeaders", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Credential")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Credential", valid_600173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600175: Call_CreatePublishingDestination_600163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a publishing destination to send findings to. The resource to send findings to must exist before you use this operation.
  ## 
  let valid = call_600175.validator(path, query, header, formData, body)
  let scheme = call_600175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600175.url(scheme.get, call_600175.host, call_600175.base,
                         call_600175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600175, url, valid)

proc call*(call_600176: Call_CreatePublishingDestination_600163;
          detectorId: string; body: JsonNode): Recallable =
  ## createPublishingDestination
  ## Creates a publishing destination to send findings to. The resource to send findings to must exist before you use this operation.
  ##   detectorId: string (required)
  ##             : The ID of the GuardDuty detector associated with the publishing destination.
  ##   body: JObject (required)
  var path_600177 = newJObject()
  var body_600178 = newJObject()
  add(path_600177, "detectorId", newJString(detectorId))
  if body != nil:
    body_600178 = body
  result = call_600176.call(path_600177, nil, nil, nil, body_600178)

var createPublishingDestination* = Call_CreatePublishingDestination_600163(
    name: "createPublishingDestination", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination",
    validator: validate_CreatePublishingDestination_600164, base: "/",
    url: url_CreatePublishingDestination_600165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublishingDestinations_600144 = ref object of OpenApiRestCall_599368
proc url_ListPublishingDestinations_600146(protocol: Scheme; host: string;
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

proc validate_ListPublishingDestinations_600145(path: JsonNode; query: JsonNode;
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
  var valid_600147 = path.getOrDefault("detectorId")
  valid_600147 = validateParameter(valid_600147, JString, required = true,
                                 default = nil)
  if valid_600147 != nil:
    section.add "detectorId", valid_600147
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results to return in the response.
  ##   nextToken: JString
  ##            : A token to use for paginating results returned in the repsonse. Set the value of this parameter to null for the first request to a list action. For subsequent calls, use the <code>NextToken</code> value returned from the previous request to continue listing results after the first page.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600148 = query.getOrDefault("NextToken")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "NextToken", valid_600148
  var valid_600149 = query.getOrDefault("maxResults")
  valid_600149 = validateParameter(valid_600149, JInt, required = false, default = nil)
  if valid_600149 != nil:
    section.add "maxResults", valid_600149
  var valid_600150 = query.getOrDefault("nextToken")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "nextToken", valid_600150
  var valid_600151 = query.getOrDefault("MaxResults")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "MaxResults", valid_600151
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600152 = header.getOrDefault("X-Amz-Date")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Date", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Security-Token")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Security-Token", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Content-Sha256", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Algorithm")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Algorithm", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Signature")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Signature", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-SignedHeaders", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Credential")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Credential", valid_600158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600159: Call_ListPublishingDestinations_600144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of publishing destinations associated with the specified <code>dectectorId</code>.
  ## 
  let valid = call_600159.validator(path, query, header, formData, body)
  let scheme = call_600159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600159.url(scheme.get, call_600159.host, call_600159.base,
                         call_600159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600159, url, valid)

proc call*(call_600160: Call_ListPublishingDestinations_600144; detectorId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listPublishingDestinations
  ## Returns a list of publishing destinations associated with the specified <code>dectectorId</code>.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to return in the response.
  ##   nextToken: string
  ##            : A token to use for paginating results returned in the repsonse. Set the value of this parameter to null for the first request to a list action. For subsequent calls, use the <code>NextToken</code> value returned from the previous request to continue listing results after the first page.
  ##   detectorId: string (required)
  ##             : The ID of the detector to retrieve publishing destinations for.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600161 = newJObject()
  var query_600162 = newJObject()
  add(query_600162, "NextToken", newJString(NextToken))
  add(query_600162, "maxResults", newJInt(maxResults))
  add(query_600162, "nextToken", newJString(nextToken))
  add(path_600161, "detectorId", newJString(detectorId))
  add(query_600162, "MaxResults", newJString(MaxResults))
  result = call_600160.call(path_600161, query_600162, nil, nil, nil)

var listPublishingDestinations* = Call_ListPublishingDestinations_600144(
    name: "listPublishingDestinations", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination",
    validator: validate_ListPublishingDestinations_600145, base: "/",
    url: url_ListPublishingDestinations_600146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSampleFindings_600179 = ref object of OpenApiRestCall_599368
proc url_CreateSampleFindings_600181(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSampleFindings_600180(path: JsonNode; query: JsonNode;
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
  var valid_600182 = path.getOrDefault("detectorId")
  valid_600182 = validateParameter(valid_600182, JString, required = true,
                                 default = nil)
  if valid_600182 != nil:
    section.add "detectorId", valid_600182
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600183 = header.getOrDefault("X-Amz-Date")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Date", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Security-Token")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Security-Token", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Content-Sha256", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Algorithm")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Algorithm", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Signature")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Signature", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-SignedHeaders", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Credential")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Credential", valid_600189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600191: Call_CreateSampleFindings_600179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for <code>findingTypes</code>, the API generates example findings of all supported finding types.
  ## 
  let valid = call_600191.validator(path, query, header, formData, body)
  let scheme = call_600191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600191.url(scheme.get, call_600191.host, call_600191.base,
                         call_600191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600191, url, valid)

proc call*(call_600192: Call_CreateSampleFindings_600179; detectorId: string;
          body: JsonNode): Recallable =
  ## createSampleFindings
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for <code>findingTypes</code>, the API generates example findings of all supported finding types.
  ##   detectorId: string (required)
  ##             : The ID of the detector to create sample findings for.
  ##   body: JObject (required)
  var path_600193 = newJObject()
  var body_600194 = newJObject()
  add(path_600193, "detectorId", newJString(detectorId))
  if body != nil:
    body_600194 = body
  result = call_600192.call(path_600193, nil, nil, nil, body_600194)

var createSampleFindings* = Call_CreateSampleFindings_600179(
    name: "createSampleFindings", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/create",
    validator: validate_CreateSampleFindings_600180, base: "/",
    url: url_CreateSampleFindings_600181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateThreatIntelSet_600214 = ref object of OpenApiRestCall_599368
proc url_CreateThreatIntelSet_600216(protocol: Scheme; host: string; base: string;
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

proc validate_CreateThreatIntelSet_600215(path: JsonNode; query: JsonNode;
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
  var valid_600217 = path.getOrDefault("detectorId")
  valid_600217 = validateParameter(valid_600217, JString, required = true,
                                 default = nil)
  if valid_600217 != nil:
    section.add "detectorId", valid_600217
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600218 = header.getOrDefault("X-Amz-Date")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Date", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Security-Token")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Security-Token", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Content-Sha256", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Algorithm")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Algorithm", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Signature")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Signature", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-SignedHeaders", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Credential")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Credential", valid_600224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600226: Call_CreateThreatIntelSet_600214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets. Only users of the master account can use this operation.
  ## 
  let valid = call_600226.validator(path, query, header, formData, body)
  let scheme = call_600226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600226.url(scheme.get, call_600226.host, call_600226.base,
                         call_600226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600226, url, valid)

proc call*(call_600227: Call_CreateThreatIntelSet_600214; detectorId: string;
          body: JsonNode): Recallable =
  ## createThreatIntelSet
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets. Only users of the master account can use this operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create a threatIntelSet.
  ##   body: JObject (required)
  var path_600228 = newJObject()
  var body_600229 = newJObject()
  add(path_600228, "detectorId", newJString(detectorId))
  if body != nil:
    body_600229 = body
  result = call_600227.call(path_600228, nil, nil, nil, body_600229)

var createThreatIntelSet* = Call_CreateThreatIntelSet_600214(
    name: "createThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_CreateThreatIntelSet_600215, base: "/",
    url: url_CreateThreatIntelSet_600216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListThreatIntelSets_600195 = ref object of OpenApiRestCall_599368
proc url_ListThreatIntelSets_600197(protocol: Scheme; host: string; base: string;
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

proc validate_ListThreatIntelSets_600196(path: JsonNode; query: JsonNode;
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
  var valid_600198 = path.getOrDefault("detectorId")
  valid_600198 = validateParameter(valid_600198, JString, required = true,
                                 default = nil)
  if valid_600198 != nil:
    section.add "detectorId", valid_600198
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   nextToken: JString
  ##            : You can use this parameter to paginate results in the response. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600199 = query.getOrDefault("NextToken")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "NextToken", valid_600199
  var valid_600200 = query.getOrDefault("maxResults")
  valid_600200 = validateParameter(valid_600200, JInt, required = false, default = nil)
  if valid_600200 != nil:
    section.add "maxResults", valid_600200
  var valid_600201 = query.getOrDefault("nextToken")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "nextToken", valid_600201
  var valid_600202 = query.getOrDefault("MaxResults")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "MaxResults", valid_600202
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600203 = header.getOrDefault("X-Amz-Date")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Date", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Security-Token")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Security-Token", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Content-Sha256", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Algorithm")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Algorithm", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Signature")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Signature", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-SignedHeaders", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Credential")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Credential", valid_600209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600210: Call_ListThreatIntelSets_600195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the ThreatIntelSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the ThreatIntelSets associated with the master account are returned.
  ## 
  let valid = call_600210.validator(path, query, header, formData, body)
  let scheme = call_600210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600210.url(scheme.get, call_600210.host, call_600210.base,
                         call_600210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600210, url, valid)

proc call*(call_600211: Call_ListThreatIntelSets_600195; detectorId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listThreatIntelSets
  ## Lists the ThreatIntelSets of the GuardDuty service specified by the detector ID. If you use this operation from a member account, the ThreatIntelSets associated with the master account are returned.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   nextToken: string
  ##            : You can use this parameter to paginate results in the response. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600212 = newJObject()
  var query_600213 = newJObject()
  add(query_600213, "NextToken", newJString(NextToken))
  add(query_600213, "maxResults", newJInt(maxResults))
  add(query_600213, "nextToken", newJString(nextToken))
  add(path_600212, "detectorId", newJString(detectorId))
  add(query_600213, "MaxResults", newJString(MaxResults))
  result = call_600211.call(path_600212, query_600213, nil, nil, nil)

var listThreatIntelSets* = Call_ListThreatIntelSets_600195(
    name: "listThreatIntelSets", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_ListThreatIntelSets_600196, base: "/",
    url: url_ListThreatIntelSets_600197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_600230 = ref object of OpenApiRestCall_599368
proc url_DeclineInvitations_600232(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeclineInvitations_600231(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600233 = header.getOrDefault("X-Amz-Date")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Date", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Security-Token")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Security-Token", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Content-Sha256", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Algorithm")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Algorithm", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Signature")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Signature", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-SignedHeaders", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Credential")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Credential", valid_600239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600241: Call_DeclineInvitations_600230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
  ## 
  let valid = call_600241.validator(path, query, header, formData, body)
  let scheme = call_600241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600241.url(scheme.get, call_600241.host, call_600241.base,
                         call_600241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600241, url, valid)

proc call*(call_600242: Call_DeclineInvitations_600230; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
  ##   body: JObject (required)
  var body_600243 = newJObject()
  if body != nil:
    body_600243 = body
  result = call_600242.call(nil, nil, nil, nil, body_600243)

var declineInvitations* = Call_DeclineInvitations_600230(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/invitation/decline",
    validator: validate_DeclineInvitations_600231, base: "/",
    url: url_DeclineInvitations_600232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetector_600258 = ref object of OpenApiRestCall_599368
proc url_UpdateDetector_600260(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDetector_600259(path: JsonNode; query: JsonNode;
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
  var valid_600261 = path.getOrDefault("detectorId")
  valid_600261 = validateParameter(valid_600261, JString, required = true,
                                 default = nil)
  if valid_600261 != nil:
    section.add "detectorId", valid_600261
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600262 = header.getOrDefault("X-Amz-Date")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Date", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Security-Token")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Security-Token", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Content-Sha256", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Algorithm")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Algorithm", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Signature")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Signature", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-SignedHeaders", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-Credential")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-Credential", valid_600268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600270: Call_UpdateDetector_600258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Amazon GuardDuty detector specified by the detectorId.
  ## 
  let valid = call_600270.validator(path, query, header, formData, body)
  let scheme = call_600270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600270.url(scheme.get, call_600270.host, call_600270.base,
                         call_600270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600270, url, valid)

proc call*(call_600271: Call_UpdateDetector_600258; detectorId: string;
          body: JsonNode): Recallable =
  ## updateDetector
  ## Updates the Amazon GuardDuty detector specified by the detectorId.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector to update.
  ##   body: JObject (required)
  var path_600272 = newJObject()
  var body_600273 = newJObject()
  add(path_600272, "detectorId", newJString(detectorId))
  if body != nil:
    body_600273 = body
  result = call_600271.call(path_600272, nil, nil, nil, body_600273)

var updateDetector* = Call_UpdateDetector_600258(name: "updateDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_UpdateDetector_600259,
    base: "/", url: url_UpdateDetector_600260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetector_600244 = ref object of OpenApiRestCall_599368
proc url_GetDetector_600246(protocol: Scheme; host: string; base: string;
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

proc validate_GetDetector_600245(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600247 = path.getOrDefault("detectorId")
  valid_600247 = validateParameter(valid_600247, JString, required = true,
                                 default = nil)
  if valid_600247 != nil:
    section.add "detectorId", valid_600247
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600248 = header.getOrDefault("X-Amz-Date")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Date", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Security-Token")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Security-Token", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Content-Sha256", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Algorithm")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Algorithm", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Signature")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Signature", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-SignedHeaders", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Credential")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Credential", valid_600254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600255: Call_GetDetector_600244; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
  ## 
  let valid = call_600255.validator(path, query, header, formData, body)
  let scheme = call_600255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600255.url(scheme.get, call_600255.host, call_600255.base,
                         call_600255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600255, url, valid)

proc call*(call_600256: Call_GetDetector_600244; detectorId: string): Recallable =
  ## getDetector
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that you want to get.
  var path_600257 = newJObject()
  add(path_600257, "detectorId", newJString(detectorId))
  result = call_600256.call(path_600257, nil, nil, nil, nil)

var getDetector* = Call_GetDetector_600244(name: "getDetector",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}",
                                        validator: validate_GetDetector_600245,
                                        base: "/", url: url_GetDetector_600246,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetector_600274 = ref object of OpenApiRestCall_599368
proc url_DeleteDetector_600276(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDetector_600275(path: JsonNode; query: JsonNode;
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
  var valid_600277 = path.getOrDefault("detectorId")
  valid_600277 = validateParameter(valid_600277, JString, required = true,
                                 default = nil)
  if valid_600277 != nil:
    section.add "detectorId", valid_600277
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600278 = header.getOrDefault("X-Amz-Date")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Date", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Security-Token")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Security-Token", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Content-Sha256", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Algorithm")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Algorithm", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Signature")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Signature", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-SignedHeaders", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Credential")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Credential", valid_600284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600285: Call_DeleteDetector_600274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
  ## 
  let valid = call_600285.validator(path, query, header, formData, body)
  let scheme = call_600285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600285.url(scheme.get, call_600285.host, call_600285.base,
                         call_600285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600285, url, valid)

proc call*(call_600286: Call_DeleteDetector_600274; detectorId: string): Recallable =
  ## deleteDetector
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that you want to delete.
  var path_600287 = newJObject()
  add(path_600287, "detectorId", newJString(detectorId))
  result = call_600286.call(path_600287, nil, nil, nil, nil)

var deleteDetector* = Call_DeleteDetector_600274(name: "deleteDetector",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_DeleteDetector_600275,
    base: "/", url: url_DeleteDetector_600276, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFilter_600303 = ref object of OpenApiRestCall_599368
proc url_UpdateFilter_600305(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFilter_600304(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the filter specified by the filter name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   filterName: JString (required)
  ##             : The name of the filter.
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector that specifies the GuardDuty service where you want to update a filter.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `filterName` field"
  var valid_600306 = path.getOrDefault("filterName")
  valid_600306 = validateParameter(valid_600306, JString, required = true,
                                 default = nil)
  if valid_600306 != nil:
    section.add "filterName", valid_600306
  var valid_600307 = path.getOrDefault("detectorId")
  valid_600307 = validateParameter(valid_600307, JString, required = true,
                                 default = nil)
  if valid_600307 != nil:
    section.add "detectorId", valid_600307
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600308 = header.getOrDefault("X-Amz-Date")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Date", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Security-Token")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Security-Token", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Content-Sha256", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Algorithm")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Algorithm", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Signature")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Signature", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-SignedHeaders", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Credential")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Credential", valid_600314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600316: Call_UpdateFilter_600303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the filter specified by the filter name.
  ## 
  let valid = call_600316.validator(path, query, header, formData, body)
  let scheme = call_600316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600316.url(scheme.get, call_600316.host, call_600316.base,
                         call_600316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600316, url, valid)

proc call*(call_600317: Call_UpdateFilter_600303; filterName: string;
          detectorId: string; body: JsonNode): Recallable =
  ## updateFilter
  ## Updates the filter specified by the filter name.
  ##   filterName: string (required)
  ##             : The name of the filter.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that specifies the GuardDuty service where you want to update a filter.
  ##   body: JObject (required)
  var path_600318 = newJObject()
  var body_600319 = newJObject()
  add(path_600318, "filterName", newJString(filterName))
  add(path_600318, "detectorId", newJString(detectorId))
  if body != nil:
    body_600319 = body
  result = call_600317.call(path_600318, nil, nil, nil, body_600319)

var updateFilter* = Call_UpdateFilter_600303(name: "updateFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_UpdateFilter_600304, base: "/", url: url_UpdateFilter_600305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFilter_600288 = ref object of OpenApiRestCall_599368
proc url_GetFilter_600290(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetFilter_600289(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the details of the filter specified by the filter name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   filterName: JString (required)
  ##             : The name of the filter you want to get.
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector the filter is associated with.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `filterName` field"
  var valid_600291 = path.getOrDefault("filterName")
  valid_600291 = validateParameter(valid_600291, JString, required = true,
                                 default = nil)
  if valid_600291 != nil:
    section.add "filterName", valid_600291
  var valid_600292 = path.getOrDefault("detectorId")
  valid_600292 = validateParameter(valid_600292, JString, required = true,
                                 default = nil)
  if valid_600292 != nil:
    section.add "detectorId", valid_600292
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600293 = header.getOrDefault("X-Amz-Date")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Date", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Security-Token")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Security-Token", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Content-Sha256", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Algorithm")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Algorithm", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Signature")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Signature", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-SignedHeaders", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Credential")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Credential", valid_600299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600300: Call_GetFilter_600288; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of the filter specified by the filter name.
  ## 
  let valid = call_600300.validator(path, query, header, formData, body)
  let scheme = call_600300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600300.url(scheme.get, call_600300.host, call_600300.base,
                         call_600300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600300, url, valid)

proc call*(call_600301: Call_GetFilter_600288; filterName: string; detectorId: string): Recallable =
  ## getFilter
  ## Returns the details of the filter specified by the filter name.
  ##   filterName: string (required)
  ##             : The name of the filter you want to get.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  var path_600302 = newJObject()
  add(path_600302, "filterName", newJString(filterName))
  add(path_600302, "detectorId", newJString(detectorId))
  result = call_600301.call(path_600302, nil, nil, nil, nil)

var getFilter* = Call_GetFilter_600288(name: "getFilter", meth: HttpMethod.HttpGet,
                                    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/filter/{filterName}",
                                    validator: validate_GetFilter_600289,
                                    base: "/", url: url_GetFilter_600290,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFilter_600320 = ref object of OpenApiRestCall_599368
proc url_DeleteFilter_600322(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFilter_600321(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the filter specified by the filter name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   filterName: JString (required)
  ##             : The name of the filter you want to delete.
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector the filter is associated with.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `filterName` field"
  var valid_600323 = path.getOrDefault("filterName")
  valid_600323 = validateParameter(valid_600323, JString, required = true,
                                 default = nil)
  if valid_600323 != nil:
    section.add "filterName", valid_600323
  var valid_600324 = path.getOrDefault("detectorId")
  valid_600324 = validateParameter(valid_600324, JString, required = true,
                                 default = nil)
  if valid_600324 != nil:
    section.add "detectorId", valid_600324
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600325 = header.getOrDefault("X-Amz-Date")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Date", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Security-Token")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Security-Token", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Content-Sha256", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Algorithm")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Algorithm", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Signature")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Signature", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-SignedHeaders", valid_600330
  var valid_600331 = header.getOrDefault("X-Amz-Credential")
  valid_600331 = validateParameter(valid_600331, JString, required = false,
                                 default = nil)
  if valid_600331 != nil:
    section.add "X-Amz-Credential", valid_600331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600332: Call_DeleteFilter_600320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the filter specified by the filter name.
  ## 
  let valid = call_600332.validator(path, query, header, formData, body)
  let scheme = call_600332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600332.url(scheme.get, call_600332.host, call_600332.base,
                         call_600332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600332, url, valid)

proc call*(call_600333: Call_DeleteFilter_600320; filterName: string;
          detectorId: string): Recallable =
  ## deleteFilter
  ## Deletes the filter specified by the filter name.
  ##   filterName: string (required)
  ##             : The name of the filter you want to delete.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  var path_600334 = newJObject()
  add(path_600334, "filterName", newJString(filterName))
  add(path_600334, "detectorId", newJString(detectorId))
  result = call_600333.call(path_600334, nil, nil, nil, nil)

var deleteFilter* = Call_DeleteFilter_600320(name: "deleteFilter",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_DeleteFilter_600321, base: "/", url: url_DeleteFilter_600322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIPSet_600350 = ref object of OpenApiRestCall_599368
proc url_UpdateIPSet_600352(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateIPSet_600351(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600353 = path.getOrDefault("ipSetId")
  valid_600353 = validateParameter(valid_600353, JString, required = true,
                                 default = nil)
  if valid_600353 != nil:
    section.add "ipSetId", valid_600353
  var valid_600354 = path.getOrDefault("detectorId")
  valid_600354 = validateParameter(valid_600354, JString, required = true,
                                 default = nil)
  if valid_600354 != nil:
    section.add "detectorId", valid_600354
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600355 = header.getOrDefault("X-Amz-Date")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Date", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Security-Token")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Security-Token", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Content-Sha256", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-Algorithm")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Algorithm", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Signature")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Signature", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-SignedHeaders", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Credential")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Credential", valid_600361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600363: Call_UpdateIPSet_600350; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the IPSet specified by the IPSet ID.
  ## 
  let valid = call_600363.validator(path, query, header, formData, body)
  let scheme = call_600363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600363.url(scheme.get, call_600363.host, call_600363.base,
                         call_600363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600363, url, valid)

proc call*(call_600364: Call_UpdateIPSet_600350; ipSetId: string; detectorId: string;
          body: JsonNode): Recallable =
  ## updateIPSet
  ## Updates the IPSet specified by the IPSet ID.
  ##   ipSetId: string (required)
  ##          : The unique ID that specifies the IPSet that you want to update.
  ##   detectorId: string (required)
  ##             : The detectorID that specifies the GuardDuty service whose IPSet you want to update.
  ##   body: JObject (required)
  var path_600365 = newJObject()
  var body_600366 = newJObject()
  add(path_600365, "ipSetId", newJString(ipSetId))
  add(path_600365, "detectorId", newJString(detectorId))
  if body != nil:
    body_600366 = body
  result = call_600364.call(path_600365, nil, nil, nil, body_600366)

var updateIPSet* = Call_UpdateIPSet_600350(name: "updateIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                        validator: validate_UpdateIPSet_600351,
                                        base: "/", url: url_UpdateIPSet_600352,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIPSet_600335 = ref object of OpenApiRestCall_599368
proc url_GetIPSet_600337(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetIPSet_600336(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600338 = path.getOrDefault("ipSetId")
  valid_600338 = validateParameter(valid_600338, JString, required = true,
                                 default = nil)
  if valid_600338 != nil:
    section.add "ipSetId", valid_600338
  var valid_600339 = path.getOrDefault("detectorId")
  valid_600339 = validateParameter(valid_600339, JString, required = true,
                                 default = nil)
  if valid_600339 != nil:
    section.add "detectorId", valid_600339
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600340 = header.getOrDefault("X-Amz-Date")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Date", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Security-Token")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Security-Token", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Content-Sha256", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-Algorithm")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Algorithm", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Signature")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Signature", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-SignedHeaders", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-Credential")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-Credential", valid_600346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600347: Call_GetIPSet_600335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
  ## 
  let valid = call_600347.validator(path, query, header, formData, body)
  let scheme = call_600347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600347.url(scheme.get, call_600347.host, call_600347.base,
                         call_600347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600347, url, valid)

proc call*(call_600348: Call_GetIPSet_600335; ipSetId: string; detectorId: string): Recallable =
  ## getIPSet
  ## Retrieves the IPSet specified by the <code>ipSetId</code>.
  ##   ipSetId: string (required)
  ##          : The unique ID of the IPSet to retrieve.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the ipSet is associated with.
  var path_600349 = newJObject()
  add(path_600349, "ipSetId", newJString(ipSetId))
  add(path_600349, "detectorId", newJString(detectorId))
  result = call_600348.call(path_600349, nil, nil, nil, nil)

var getIPSet* = Call_GetIPSet_600335(name: "getIPSet", meth: HttpMethod.HttpGet,
                                  host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                  validator: validate_GetIPSet_600336, base: "/",
                                  url: url_GetIPSet_600337,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIPSet_600367 = ref object of OpenApiRestCall_599368
proc url_DeleteIPSet_600369(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIPSet_600368(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600370 = path.getOrDefault("ipSetId")
  valid_600370 = validateParameter(valid_600370, JString, required = true,
                                 default = nil)
  if valid_600370 != nil:
    section.add "ipSetId", valid_600370
  var valid_600371 = path.getOrDefault("detectorId")
  valid_600371 = validateParameter(valid_600371, JString, required = true,
                                 default = nil)
  if valid_600371 != nil:
    section.add "detectorId", valid_600371
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600372 = header.getOrDefault("X-Amz-Date")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Date", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-Security-Token")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-Security-Token", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Content-Sha256", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Algorithm")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Algorithm", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-Signature")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Signature", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-SignedHeaders", valid_600377
  var valid_600378 = header.getOrDefault("X-Amz-Credential")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "X-Amz-Credential", valid_600378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600379: Call_DeleteIPSet_600367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
  ## 
  let valid = call_600379.validator(path, query, header, formData, body)
  let scheme = call_600379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600379.url(scheme.get, call_600379.host, call_600379.base,
                         call_600379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600379, url, valid)

proc call*(call_600380: Call_DeleteIPSet_600367; ipSetId: string; detectorId: string): Recallable =
  ## deleteIPSet
  ## Deletes the IPSet specified by the <code>ipSetId</code>. IPSets are called Trusted IP lists in the console user interface.
  ##   ipSetId: string (required)
  ##          : The unique ID of the IPSet to delete.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the IPSet.
  var path_600381 = newJObject()
  add(path_600381, "ipSetId", newJString(ipSetId))
  add(path_600381, "detectorId", newJString(detectorId))
  result = call_600380.call(path_600381, nil, nil, nil, nil)

var deleteIPSet* = Call_DeleteIPSet_600367(name: "deleteIPSet",
                                        meth: HttpMethod.HttpDelete,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                        validator: validate_DeleteIPSet_600368,
                                        base: "/", url: url_DeleteIPSet_600369,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_600382 = ref object of OpenApiRestCall_599368
proc url_DeleteInvitations_600384(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInvitations_600383(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600385 = header.getOrDefault("X-Amz-Date")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Date", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Security-Token")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Security-Token", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Content-Sha256", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-Algorithm")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Algorithm", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Signature")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Signature", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-SignedHeaders", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-Credential")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-Credential", valid_600391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600393: Call_DeleteInvitations_600382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
  ## 
  let valid = call_600393.validator(path, query, header, formData, body)
  let scheme = call_600393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600393.url(scheme.get, call_600393.host, call_600393.base,
                         call_600393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600393, url, valid)

proc call*(call_600394: Call_DeleteInvitations_600382; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
  ##   body: JObject (required)
  var body_600395 = newJObject()
  if body != nil:
    body_600395 = body
  result = call_600394.call(nil, nil, nil, nil, body_600395)

var deleteInvitations* = Call_DeleteInvitations_600382(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/invitation/delete", validator: validate_DeleteInvitations_600383,
    base: "/", url: url_DeleteInvitations_600384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_600396 = ref object of OpenApiRestCall_599368
proc url_DeleteMembers_600398(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMembers_600397(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600399 = path.getOrDefault("detectorId")
  valid_600399 = validateParameter(valid_600399, JString, required = true,
                                 default = nil)
  if valid_600399 != nil:
    section.add "detectorId", valid_600399
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600400 = header.getOrDefault("X-Amz-Date")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Date", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Security-Token")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Security-Token", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Content-Sha256", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-Algorithm")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-Algorithm", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Signature")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Signature", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-SignedHeaders", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-Credential")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-Credential", valid_600406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600408: Call_DeleteMembers_600396; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_600408.validator(path, query, header, formData, body)
  let scheme = call_600408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600408.url(scheme.get, call_600408.host, call_600408.base,
                         call_600408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600408, url, valid)

proc call*(call_600409: Call_DeleteMembers_600396; detectorId: string; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to delete.
  ##   body: JObject (required)
  var path_600410 = newJObject()
  var body_600411 = newJObject()
  add(path_600410, "detectorId", newJString(detectorId))
  if body != nil:
    body_600411 = body
  result = call_600409.call(path_600410, nil, nil, nil, body_600411)

var deleteMembers* = Call_DeleteMembers_600396(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/delete",
    validator: validate_DeleteMembers_600397, base: "/", url: url_DeleteMembers_600398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePublishingDestination_600427 = ref object of OpenApiRestCall_599368
proc url_UpdatePublishingDestination_600429(protocol: Scheme; host: string;
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

proc validate_UpdatePublishingDestination_600428(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   destinationId: JString (required)
  ##                : The ID of the detector associated with the publishing destinations to update.
  ##   detectorId: JString (required)
  ##             : The ID of the 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `destinationId` field"
  var valid_600430 = path.getOrDefault("destinationId")
  valid_600430 = validateParameter(valid_600430, JString, required = true,
                                 default = nil)
  if valid_600430 != nil:
    section.add "destinationId", valid_600430
  var valid_600431 = path.getOrDefault("detectorId")
  valid_600431 = validateParameter(valid_600431, JString, required = true,
                                 default = nil)
  if valid_600431 != nil:
    section.add "detectorId", valid_600431
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600432 = header.getOrDefault("X-Amz-Date")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Date", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-Security-Token")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-Security-Token", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Content-Sha256", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Algorithm")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Algorithm", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-Signature")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Signature", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-SignedHeaders", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-Credential")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Credential", valid_600438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600440: Call_UpdatePublishingDestination_600427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
  ## 
  let valid = call_600440.validator(path, query, header, formData, body)
  let scheme = call_600440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600440.url(scheme.get, call_600440.host, call_600440.base,
                         call_600440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600440, url, valid)

proc call*(call_600441: Call_UpdatePublishingDestination_600427;
          destinationId: string; detectorId: string; body: JsonNode): Recallable =
  ## updatePublishingDestination
  ## Updates information about the publishing destination specified by the <code>destinationId</code>.
  ##   destinationId: string (required)
  ##                : The ID of the detector associated with the publishing destinations to update.
  ##   detectorId: string (required)
  ##             : The ID of the 
  ##   body: JObject (required)
  var path_600442 = newJObject()
  var body_600443 = newJObject()
  add(path_600442, "destinationId", newJString(destinationId))
  add(path_600442, "detectorId", newJString(detectorId))
  if body != nil:
    body_600443 = body
  result = call_600441.call(path_600442, nil, nil, nil, body_600443)

var updatePublishingDestination* = Call_UpdatePublishingDestination_600427(
    name: "updatePublishingDestination", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_UpdatePublishingDestination_600428, base: "/",
    url: url_UpdatePublishingDestination_600429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePublishingDestination_600412 = ref object of OpenApiRestCall_599368
proc url_DescribePublishingDestination_600414(protocol: Scheme; host: string;
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

proc validate_DescribePublishingDestination_600413(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   destinationId: JString (required)
  ##                : The ID of the publishing destination to retrieve.
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector associated with the publishing destination to retrieve.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `destinationId` field"
  var valid_600415 = path.getOrDefault("destinationId")
  valid_600415 = validateParameter(valid_600415, JString, required = true,
                                 default = nil)
  if valid_600415 != nil:
    section.add "destinationId", valid_600415
  var valid_600416 = path.getOrDefault("detectorId")
  valid_600416 = validateParameter(valid_600416, JString, required = true,
                                 default = nil)
  if valid_600416 != nil:
    section.add "detectorId", valid_600416
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600417 = header.getOrDefault("X-Amz-Date")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Date", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-Security-Token")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-Security-Token", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Content-Sha256", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-Algorithm")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-Algorithm", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-Signature")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Signature", valid_600421
  var valid_600422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-SignedHeaders", valid_600422
  var valid_600423 = header.getOrDefault("X-Amz-Credential")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Credential", valid_600423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600424: Call_DescribePublishingDestination_600412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
  ## 
  let valid = call_600424.validator(path, query, header, formData, body)
  let scheme = call_600424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600424.url(scheme.get, call_600424.host, call_600424.base,
                         call_600424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600424, url, valid)

proc call*(call_600425: Call_DescribePublishingDestination_600412;
          destinationId: string; detectorId: string): Recallable =
  ## describePublishingDestination
  ## Returns information about the publishing destination specified by the provided <code>destinationId</code>.
  ##   destinationId: string (required)
  ##                : The ID of the publishing destination to retrieve.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the publishing destination to retrieve.
  var path_600426 = newJObject()
  add(path_600426, "destinationId", newJString(destinationId))
  add(path_600426, "detectorId", newJString(detectorId))
  result = call_600425.call(path_600426, nil, nil, nil, nil)

var describePublishingDestination* = Call_DescribePublishingDestination_600412(
    name: "describePublishingDestination", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_DescribePublishingDestination_600413, base: "/",
    url: url_DescribePublishingDestination_600414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublishingDestination_600444 = ref object of OpenApiRestCall_599368
proc url_DeletePublishingDestination_600446(protocol: Scheme; host: string;
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

proc validate_DeletePublishingDestination_600445(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   destinationId: JString (required)
  ##                : The ID of the publishing destination to delete.
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector associated with the publishing destination to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `destinationId` field"
  var valid_600447 = path.getOrDefault("destinationId")
  valid_600447 = validateParameter(valid_600447, JString, required = true,
                                 default = nil)
  if valid_600447 != nil:
    section.add "destinationId", valid_600447
  var valid_600448 = path.getOrDefault("detectorId")
  valid_600448 = validateParameter(valid_600448, JString, required = true,
                                 default = nil)
  if valid_600448 != nil:
    section.add "detectorId", valid_600448
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600449 = header.getOrDefault("X-Amz-Date")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Date", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Security-Token")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Security-Token", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-Content-Sha256", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Algorithm")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Algorithm", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-Signature")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-Signature", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-SignedHeaders", valid_600454
  var valid_600455 = header.getOrDefault("X-Amz-Credential")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-Credential", valid_600455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600456: Call_DeletePublishingDestination_600444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
  ## 
  let valid = call_600456.validator(path, query, header, formData, body)
  let scheme = call_600456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600456.url(scheme.get, call_600456.host, call_600456.base,
                         call_600456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600456, url, valid)

proc call*(call_600457: Call_DeletePublishingDestination_600444;
          destinationId: string; detectorId: string): Recallable =
  ## deletePublishingDestination
  ## Deletes the publishing definition with the specified <code>destinationId</code>.
  ##   destinationId: string (required)
  ##                : The ID of the publishing destination to delete.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector associated with the publishing destination to delete.
  var path_600458 = newJObject()
  add(path_600458, "destinationId", newJString(destinationId))
  add(path_600458, "detectorId", newJString(detectorId))
  result = call_600457.call(path_600458, nil, nil, nil, nil)

var deletePublishingDestination* = Call_DeletePublishingDestination_600444(
    name: "deletePublishingDestination", meth: HttpMethod.HttpDelete,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/publishingDestination/{destinationId}",
    validator: validate_DeletePublishingDestination_600445, base: "/",
    url: url_DeletePublishingDestination_600446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateThreatIntelSet_600474 = ref object of OpenApiRestCall_599368
proc url_UpdateThreatIntelSet_600476(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateThreatIntelSet_600475(path: JsonNode; query: JsonNode;
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
  var valid_600477 = path.getOrDefault("detectorId")
  valid_600477 = validateParameter(valid_600477, JString, required = true,
                                 default = nil)
  if valid_600477 != nil:
    section.add "detectorId", valid_600477
  var valid_600478 = path.getOrDefault("threatIntelSetId")
  valid_600478 = validateParameter(valid_600478, JString, required = true,
                                 default = nil)
  if valid_600478 != nil:
    section.add "threatIntelSetId", valid_600478
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600479 = header.getOrDefault("X-Amz-Date")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Date", valid_600479
  var valid_600480 = header.getOrDefault("X-Amz-Security-Token")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-Security-Token", valid_600480
  var valid_600481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600481 = validateParameter(valid_600481, JString, required = false,
                                 default = nil)
  if valid_600481 != nil:
    section.add "X-Amz-Content-Sha256", valid_600481
  var valid_600482 = header.getOrDefault("X-Amz-Algorithm")
  valid_600482 = validateParameter(valid_600482, JString, required = false,
                                 default = nil)
  if valid_600482 != nil:
    section.add "X-Amz-Algorithm", valid_600482
  var valid_600483 = header.getOrDefault("X-Amz-Signature")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "X-Amz-Signature", valid_600483
  var valid_600484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600484 = validateParameter(valid_600484, JString, required = false,
                                 default = nil)
  if valid_600484 != nil:
    section.add "X-Amz-SignedHeaders", valid_600484
  var valid_600485 = header.getOrDefault("X-Amz-Credential")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "X-Amz-Credential", valid_600485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600487: Call_UpdateThreatIntelSet_600474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ## 
  let valid = call_600487.validator(path, query, header, formData, body)
  let scheme = call_600487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600487.url(scheme.get, call_600487.host, call_600487.base,
                         call_600487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600487, url, valid)

proc call*(call_600488: Call_UpdateThreatIntelSet_600474; detectorId: string;
          threatIntelSetId: string; body: JsonNode): Recallable =
  ## updateThreatIntelSet
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The detectorID that specifies the GuardDuty service whose ThreatIntelSet you want to update.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID that specifies the ThreatIntelSet that you want to update.
  ##   body: JObject (required)
  var path_600489 = newJObject()
  var body_600490 = newJObject()
  add(path_600489, "detectorId", newJString(detectorId))
  add(path_600489, "threatIntelSetId", newJString(threatIntelSetId))
  if body != nil:
    body_600490 = body
  result = call_600488.call(path_600489, nil, nil, nil, body_600490)

var updateThreatIntelSet* = Call_UpdateThreatIntelSet_600474(
    name: "updateThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_UpdateThreatIntelSet_600475, base: "/",
    url: url_UpdateThreatIntelSet_600476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThreatIntelSet_600459 = ref object of OpenApiRestCall_599368
proc url_GetThreatIntelSet_600461(protocol: Scheme; host: string; base: string;
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

proc validate_GetThreatIntelSet_600460(path: JsonNode; query: JsonNode;
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
  var valid_600462 = path.getOrDefault("detectorId")
  valid_600462 = validateParameter(valid_600462, JString, required = true,
                                 default = nil)
  if valid_600462 != nil:
    section.add "detectorId", valid_600462
  var valid_600463 = path.getOrDefault("threatIntelSetId")
  valid_600463 = validateParameter(valid_600463, JString, required = true,
                                 default = nil)
  if valid_600463 != nil:
    section.add "threatIntelSetId", valid_600463
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600464 = header.getOrDefault("X-Amz-Date")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Date", valid_600464
  var valid_600465 = header.getOrDefault("X-Amz-Security-Token")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amz-Security-Token", valid_600465
  var valid_600466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600466 = validateParameter(valid_600466, JString, required = false,
                                 default = nil)
  if valid_600466 != nil:
    section.add "X-Amz-Content-Sha256", valid_600466
  var valid_600467 = header.getOrDefault("X-Amz-Algorithm")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-Algorithm", valid_600467
  var valid_600468 = header.getOrDefault("X-Amz-Signature")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "X-Amz-Signature", valid_600468
  var valid_600469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600469 = validateParameter(valid_600469, JString, required = false,
                                 default = nil)
  if valid_600469 != nil:
    section.add "X-Amz-SignedHeaders", valid_600469
  var valid_600470 = header.getOrDefault("X-Amz-Credential")
  valid_600470 = validateParameter(valid_600470, JString, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "X-Amz-Credential", valid_600470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600471: Call_GetThreatIntelSet_600459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ## 
  let valid = call_600471.validator(path, query, header, formData, body)
  let scheme = call_600471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600471.url(scheme.get, call_600471.host, call_600471.base,
                         call_600471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600471, url, valid)

proc call*(call_600472: Call_GetThreatIntelSet_600459; detectorId: string;
          threatIntelSetId: string): Recallable =
  ## getThreatIntelSet
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID of the threatIntelSet you want to get.
  var path_600473 = newJObject()
  add(path_600473, "detectorId", newJString(detectorId))
  add(path_600473, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_600472.call(path_600473, nil, nil, nil, nil)

var getThreatIntelSet* = Call_GetThreatIntelSet_600459(name: "getThreatIntelSet",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_GetThreatIntelSet_600460, base: "/",
    url: url_GetThreatIntelSet_600461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteThreatIntelSet_600491 = ref object of OpenApiRestCall_599368
proc url_DeleteThreatIntelSet_600493(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteThreatIntelSet_600492(path: JsonNode; query: JsonNode;
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
  var valid_600494 = path.getOrDefault("detectorId")
  valid_600494 = validateParameter(valid_600494, JString, required = true,
                                 default = nil)
  if valid_600494 != nil:
    section.add "detectorId", valid_600494
  var valid_600495 = path.getOrDefault("threatIntelSetId")
  valid_600495 = validateParameter(valid_600495, JString, required = true,
                                 default = nil)
  if valid_600495 != nil:
    section.add "threatIntelSetId", valid_600495
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600496 = header.getOrDefault("X-Amz-Date")
  valid_600496 = validateParameter(valid_600496, JString, required = false,
                                 default = nil)
  if valid_600496 != nil:
    section.add "X-Amz-Date", valid_600496
  var valid_600497 = header.getOrDefault("X-Amz-Security-Token")
  valid_600497 = validateParameter(valid_600497, JString, required = false,
                                 default = nil)
  if valid_600497 != nil:
    section.add "X-Amz-Security-Token", valid_600497
  var valid_600498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600498 = validateParameter(valid_600498, JString, required = false,
                                 default = nil)
  if valid_600498 != nil:
    section.add "X-Amz-Content-Sha256", valid_600498
  var valid_600499 = header.getOrDefault("X-Amz-Algorithm")
  valid_600499 = validateParameter(valid_600499, JString, required = false,
                                 default = nil)
  if valid_600499 != nil:
    section.add "X-Amz-Algorithm", valid_600499
  var valid_600500 = header.getOrDefault("X-Amz-Signature")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "X-Amz-Signature", valid_600500
  var valid_600501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "X-Amz-SignedHeaders", valid_600501
  var valid_600502 = header.getOrDefault("X-Amz-Credential")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-Credential", valid_600502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600503: Call_DeleteThreatIntelSet_600491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ## 
  let valid = call_600503.validator(path, query, header, formData, body)
  let scheme = call_600503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600503.url(scheme.get, call_600503.host, call_600503.base,
                         call_600503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600503, url, valid)

proc call*(call_600504: Call_DeleteThreatIntelSet_600491; detectorId: string;
          threatIntelSetId: string): Recallable =
  ## deleteThreatIntelSet
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID of the threatIntelSet you want to delete.
  var path_600505 = newJObject()
  add(path_600505, "detectorId", newJString(detectorId))
  add(path_600505, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_600504.call(path_600505, nil, nil, nil, nil)

var deleteThreatIntelSet* = Call_DeleteThreatIntelSet_600491(
    name: "deleteThreatIntelSet", meth: HttpMethod.HttpDelete,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_DeleteThreatIntelSet_600492, base: "/",
    url: url_DeleteThreatIntelSet_600493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_600506 = ref object of OpenApiRestCall_599368
proc url_DisassociateFromMasterAccount_600508(protocol: Scheme; host: string;
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

proc validate_DisassociateFromMasterAccount_600507(path: JsonNode; query: JsonNode;
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
  var valid_600509 = path.getOrDefault("detectorId")
  valid_600509 = validateParameter(valid_600509, JString, required = true,
                                 default = nil)
  if valid_600509 != nil:
    section.add "detectorId", valid_600509
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600510 = header.getOrDefault("X-Amz-Date")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Date", valid_600510
  var valid_600511 = header.getOrDefault("X-Amz-Security-Token")
  valid_600511 = validateParameter(valid_600511, JString, required = false,
                                 default = nil)
  if valid_600511 != nil:
    section.add "X-Amz-Security-Token", valid_600511
  var valid_600512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600512 = validateParameter(valid_600512, JString, required = false,
                                 default = nil)
  if valid_600512 != nil:
    section.add "X-Amz-Content-Sha256", valid_600512
  var valid_600513 = header.getOrDefault("X-Amz-Algorithm")
  valid_600513 = validateParameter(valid_600513, JString, required = false,
                                 default = nil)
  if valid_600513 != nil:
    section.add "X-Amz-Algorithm", valid_600513
  var valid_600514 = header.getOrDefault("X-Amz-Signature")
  valid_600514 = validateParameter(valid_600514, JString, required = false,
                                 default = nil)
  if valid_600514 != nil:
    section.add "X-Amz-Signature", valid_600514
  var valid_600515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600515 = validateParameter(valid_600515, JString, required = false,
                                 default = nil)
  if valid_600515 != nil:
    section.add "X-Amz-SignedHeaders", valid_600515
  var valid_600516 = header.getOrDefault("X-Amz-Credential")
  valid_600516 = validateParameter(valid_600516, JString, required = false,
                                 default = nil)
  if valid_600516 != nil:
    section.add "X-Amz-Credential", valid_600516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600517: Call_DisassociateFromMasterAccount_600506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current GuardDuty member account from its master account.
  ## 
  let valid = call_600517.validator(path, query, header, formData, body)
  let scheme = call_600517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600517.url(scheme.get, call_600517.host, call_600517.base,
                         call_600517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600517, url, valid)

proc call*(call_600518: Call_DisassociateFromMasterAccount_600506;
          detectorId: string): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current GuardDuty member account from its master account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  var path_600519 = newJObject()
  add(path_600519, "detectorId", newJString(detectorId))
  result = call_600518.call(path_600519, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_600506(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_600507, base: "/",
    url: url_DisassociateFromMasterAccount_600508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_600520 = ref object of OpenApiRestCall_599368
proc url_DisassociateMembers_600522(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateMembers_600521(path: JsonNode; query: JsonNode;
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
  var valid_600523 = path.getOrDefault("detectorId")
  valid_600523 = validateParameter(valid_600523, JString, required = true,
                                 default = nil)
  if valid_600523 != nil:
    section.add "detectorId", valid_600523
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600524 = header.getOrDefault("X-Amz-Date")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Date", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Security-Token")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Security-Token", valid_600525
  var valid_600526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "X-Amz-Content-Sha256", valid_600526
  var valid_600527 = header.getOrDefault("X-Amz-Algorithm")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-Algorithm", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-Signature")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-Signature", valid_600528
  var valid_600529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600529 = validateParameter(valid_600529, JString, required = false,
                                 default = nil)
  if valid_600529 != nil:
    section.add "X-Amz-SignedHeaders", valid_600529
  var valid_600530 = header.getOrDefault("X-Amz-Credential")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "X-Amz-Credential", valid_600530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600532: Call_DisassociateMembers_600520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_600532.validator(path, query, header, formData, body)
  let scheme = call_600532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600532.url(scheme.get, call_600532.host, call_600532.base,
                         call_600532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600532, url, valid)

proc call*(call_600533: Call_DisassociateMembers_600520; detectorId: string;
          body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to disassociate from master.
  ##   body: JObject (required)
  var path_600534 = newJObject()
  var body_600535 = newJObject()
  add(path_600534, "detectorId", newJString(detectorId))
  if body != nil:
    body_600535 = body
  result = call_600533.call(path_600534, nil, nil, nil, body_600535)

var disassociateMembers* = Call_DisassociateMembers_600520(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/disassociate",
    validator: validate_DisassociateMembers_600521, base: "/",
    url: url_DisassociateMembers_600522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_600536 = ref object of OpenApiRestCall_599368
proc url_GetFindings_600538(protocol: Scheme; host: string; base: string;
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

proc validate_GetFindings_600537(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600539 = path.getOrDefault("detectorId")
  valid_600539 = validateParameter(valid_600539, JString, required = true,
                                 default = nil)
  if valid_600539 != nil:
    section.add "detectorId", valid_600539
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600540 = header.getOrDefault("X-Amz-Date")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Date", valid_600540
  var valid_600541 = header.getOrDefault("X-Amz-Security-Token")
  valid_600541 = validateParameter(valid_600541, JString, required = false,
                                 default = nil)
  if valid_600541 != nil:
    section.add "X-Amz-Security-Token", valid_600541
  var valid_600542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-Content-Sha256", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-Algorithm")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-Algorithm", valid_600543
  var valid_600544 = header.getOrDefault("X-Amz-Signature")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "X-Amz-Signature", valid_600544
  var valid_600545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "X-Amz-SignedHeaders", valid_600545
  var valid_600546 = header.getOrDefault("X-Amz-Credential")
  valid_600546 = validateParameter(valid_600546, JString, required = false,
                                 default = nil)
  if valid_600546 != nil:
    section.add "X-Amz-Credential", valid_600546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600548: Call_GetFindings_600536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes Amazon GuardDuty findings specified by finding IDs.
  ## 
  let valid = call_600548.validator(path, query, header, formData, body)
  let scheme = call_600548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600548.url(scheme.get, call_600548.host, call_600548.base,
                         call_600548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600548, url, valid)

proc call*(call_600549: Call_GetFindings_600536; detectorId: string; body: JsonNode): Recallable =
  ## getFindings
  ## Describes Amazon GuardDuty findings specified by finding IDs.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to retrieve.
  ##   body: JObject (required)
  var path_600550 = newJObject()
  var body_600551 = newJObject()
  add(path_600550, "detectorId", newJString(detectorId))
  if body != nil:
    body_600551 = body
  result = call_600549.call(path_600550, nil, nil, nil, body_600551)

var getFindings* = Call_GetFindings_600536(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/findings/get",
                                        validator: validate_GetFindings_600537,
                                        base: "/", url: url_GetFindings_600538,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindingsStatistics_600552 = ref object of OpenApiRestCall_599368
proc url_GetFindingsStatistics_600554(protocol: Scheme; host: string; base: string;
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

proc validate_GetFindingsStatistics_600553(path: JsonNode; query: JsonNode;
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
  var valid_600555 = path.getOrDefault("detectorId")
  valid_600555 = validateParameter(valid_600555, JString, required = true,
                                 default = nil)
  if valid_600555 != nil:
    section.add "detectorId", valid_600555
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600556 = header.getOrDefault("X-Amz-Date")
  valid_600556 = validateParameter(valid_600556, JString, required = false,
                                 default = nil)
  if valid_600556 != nil:
    section.add "X-Amz-Date", valid_600556
  var valid_600557 = header.getOrDefault("X-Amz-Security-Token")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-Security-Token", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-Content-Sha256", valid_600558
  var valid_600559 = header.getOrDefault("X-Amz-Algorithm")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Algorithm", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-Signature")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-Signature", valid_600560
  var valid_600561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "X-Amz-SignedHeaders", valid_600561
  var valid_600562 = header.getOrDefault("X-Amz-Credential")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "X-Amz-Credential", valid_600562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600564: Call_GetFindingsStatistics_600552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
  ## 
  let valid = call_600564.validator(path, query, header, formData, body)
  let scheme = call_600564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600564.url(scheme.get, call_600564.host, call_600564.base,
                         call_600564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600564, url, valid)

proc call*(call_600565: Call_GetFindingsStatistics_600552; detectorId: string;
          body: JsonNode): Recallable =
  ## getFindingsStatistics
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings' statistics you want to retrieve.
  ##   body: JObject (required)
  var path_600566 = newJObject()
  var body_600567 = newJObject()
  add(path_600566, "detectorId", newJString(detectorId))
  if body != nil:
    body_600567 = body
  result = call_600565.call(path_600566, nil, nil, nil, body_600567)

var getFindingsStatistics* = Call_GetFindingsStatistics_600552(
    name: "getFindingsStatistics", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/statistics",
    validator: validate_GetFindingsStatistics_600553, base: "/",
    url: url_GetFindingsStatistics_600554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_600568 = ref object of OpenApiRestCall_599368
proc url_GetInvitationsCount_600570(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInvitationsCount_600569(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600571 = header.getOrDefault("X-Amz-Date")
  valid_600571 = validateParameter(valid_600571, JString, required = false,
                                 default = nil)
  if valid_600571 != nil:
    section.add "X-Amz-Date", valid_600571
  var valid_600572 = header.getOrDefault("X-Amz-Security-Token")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "X-Amz-Security-Token", valid_600572
  var valid_600573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-Content-Sha256", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-Algorithm")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Algorithm", valid_600574
  var valid_600575 = header.getOrDefault("X-Amz-Signature")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-Signature", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-SignedHeaders", valid_600576
  var valid_600577 = header.getOrDefault("X-Amz-Credential")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-Credential", valid_600577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600578: Call_GetInvitationsCount_600568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
  ## 
  let valid = call_600578.validator(path, query, header, formData, body)
  let scheme = call_600578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600578.url(scheme.get, call_600578.host, call_600578.base,
                         call_600578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600578, url, valid)

proc call*(call_600579: Call_GetInvitationsCount_600568): Recallable =
  ## getInvitationsCount
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
  result = call_600579.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_600568(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/invitation/count",
    validator: validate_GetInvitationsCount_600569, base: "/",
    url: url_GetInvitationsCount_600570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_600580 = ref object of OpenApiRestCall_599368
proc url_GetMembers_600582(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMembers_600581(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600583 = path.getOrDefault("detectorId")
  valid_600583 = validateParameter(valid_600583, JString, required = true,
                                 default = nil)
  if valid_600583 != nil:
    section.add "detectorId", valid_600583
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600584 = header.getOrDefault("X-Amz-Date")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Date", valid_600584
  var valid_600585 = header.getOrDefault("X-Amz-Security-Token")
  valid_600585 = validateParameter(valid_600585, JString, required = false,
                                 default = nil)
  if valid_600585 != nil:
    section.add "X-Amz-Security-Token", valid_600585
  var valid_600586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600586 = validateParameter(valid_600586, JString, required = false,
                                 default = nil)
  if valid_600586 != nil:
    section.add "X-Amz-Content-Sha256", valid_600586
  var valid_600587 = header.getOrDefault("X-Amz-Algorithm")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-Algorithm", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-Signature")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-Signature", valid_600588
  var valid_600589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-SignedHeaders", valid_600589
  var valid_600590 = header.getOrDefault("X-Amz-Credential")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-Credential", valid_600590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600592: Call_GetMembers_600580; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_600592.validator(path, query, header, formData, body)
  let scheme = call_600592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600592.url(scheme.get, call_600592.host, call_600592.base,
                         call_600592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600592, url, valid)

proc call*(call_600593: Call_GetMembers_600580; detectorId: string; body: JsonNode): Recallable =
  ## getMembers
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to retrieve.
  ##   body: JObject (required)
  var path_600594 = newJObject()
  var body_600595 = newJObject()
  add(path_600594, "detectorId", newJString(detectorId))
  if body != nil:
    body_600595 = body
  result = call_600593.call(path_600594, nil, nil, nil, body_600595)

var getMembers* = Call_GetMembers_600580(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/get",
                                      validator: validate_GetMembers_600581,
                                      base: "/", url: url_GetMembers_600582,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_600596 = ref object of OpenApiRestCall_599368
proc url_InviteMembers_600598(protocol: Scheme; host: string; base: string;
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

proc validate_InviteMembers_600597(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600599 = path.getOrDefault("detectorId")
  valid_600599 = validateParameter(valid_600599, JString, required = true,
                                 default = nil)
  if valid_600599 != nil:
    section.add "detectorId", valid_600599
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600600 = header.getOrDefault("X-Amz-Date")
  valid_600600 = validateParameter(valid_600600, JString, required = false,
                                 default = nil)
  if valid_600600 != nil:
    section.add "X-Amz-Date", valid_600600
  var valid_600601 = header.getOrDefault("X-Amz-Security-Token")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = nil)
  if valid_600601 != nil:
    section.add "X-Amz-Security-Token", valid_600601
  var valid_600602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-Content-Sha256", valid_600602
  var valid_600603 = header.getOrDefault("X-Amz-Algorithm")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "X-Amz-Algorithm", valid_600603
  var valid_600604 = header.getOrDefault("X-Amz-Signature")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-Signature", valid_600604
  var valid_600605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "X-Amz-SignedHeaders", valid_600605
  var valid_600606 = header.getOrDefault("X-Amz-Credential")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-Credential", valid_600606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600608: Call_InviteMembers_600596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
  ## 
  let valid = call_600608.validator(path, query, header, formData, body)
  let scheme = call_600608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600608.url(scheme.get, call_600608.host, call_600608.base,
                         call_600608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600608, url, valid)

proc call*(call_600609: Call_InviteMembers_600596; detectorId: string; body: JsonNode): Recallable =
  ## inviteMembers
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account with which you want to invite members.
  ##   body: JObject (required)
  var path_600610 = newJObject()
  var body_600611 = newJObject()
  add(path_600610, "detectorId", newJString(detectorId))
  if body != nil:
    body_600611 = body
  result = call_600609.call(path_600610, nil, nil, nil, body_600611)

var inviteMembers* = Call_InviteMembers_600596(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/invite",
    validator: validate_InviteMembers_600597, base: "/", url: url_InviteMembers_600598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_600612 = ref object of OpenApiRestCall_599368
proc url_ListFindings_600614(protocol: Scheme; host: string; base: string;
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

proc validate_ListFindings_600613(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600615 = path.getOrDefault("detectorId")
  valid_600615 = validateParameter(valid_600615, JString, required = true,
                                 default = nil)
  if valid_600615 != nil:
    section.add "detectorId", valid_600615
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600616 = query.getOrDefault("NextToken")
  valid_600616 = validateParameter(valid_600616, JString, required = false,
                                 default = nil)
  if valid_600616 != nil:
    section.add "NextToken", valid_600616
  var valid_600617 = query.getOrDefault("MaxResults")
  valid_600617 = validateParameter(valid_600617, JString, required = false,
                                 default = nil)
  if valid_600617 != nil:
    section.add "MaxResults", valid_600617
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600618 = header.getOrDefault("X-Amz-Date")
  valid_600618 = validateParameter(valid_600618, JString, required = false,
                                 default = nil)
  if valid_600618 != nil:
    section.add "X-Amz-Date", valid_600618
  var valid_600619 = header.getOrDefault("X-Amz-Security-Token")
  valid_600619 = validateParameter(valid_600619, JString, required = false,
                                 default = nil)
  if valid_600619 != nil:
    section.add "X-Amz-Security-Token", valid_600619
  var valid_600620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-Content-Sha256", valid_600620
  var valid_600621 = header.getOrDefault("X-Amz-Algorithm")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Algorithm", valid_600621
  var valid_600622 = header.getOrDefault("X-Amz-Signature")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-Signature", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-SignedHeaders", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-Credential")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Credential", valid_600624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600626: Call_ListFindings_600612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists Amazon GuardDuty findings for the specified detector ID.
  ## 
  let valid = call_600626.validator(path, query, header, formData, body)
  let scheme = call_600626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600626.url(scheme.get, call_600626.host, call_600626.base,
                         call_600626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600626, url, valid)

proc call*(call_600627: Call_ListFindings_600612; detectorId: string; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listFindings
  ## Lists Amazon GuardDuty findings for the specified detector ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to list.
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600628 = newJObject()
  var query_600629 = newJObject()
  var body_600630 = newJObject()
  add(query_600629, "NextToken", newJString(NextToken))
  add(path_600628, "detectorId", newJString(detectorId))
  if body != nil:
    body_600630 = body
  add(query_600629, "MaxResults", newJString(MaxResults))
  result = call_600627.call(path_600628, query_600629, nil, nil, body_600630)

var listFindings* = Call_ListFindings_600612(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings", validator: validate_ListFindings_600613,
    base: "/", url: url_ListFindings_600614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_600631 = ref object of OpenApiRestCall_599368
proc url_ListInvitations_600633(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInvitations_600632(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists all GuardDuty membership invitations that were sent to the current AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   nextToken: JString
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600634 = query.getOrDefault("NextToken")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "NextToken", valid_600634
  var valid_600635 = query.getOrDefault("maxResults")
  valid_600635 = validateParameter(valid_600635, JInt, required = false, default = nil)
  if valid_600635 != nil:
    section.add "maxResults", valid_600635
  var valid_600636 = query.getOrDefault("nextToken")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "nextToken", valid_600636
  var valid_600637 = query.getOrDefault("MaxResults")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "MaxResults", valid_600637
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600638 = header.getOrDefault("X-Amz-Date")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Date", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-Security-Token")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Security-Token", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Content-Sha256", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-Algorithm")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Algorithm", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Signature")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Signature", valid_600642
  var valid_600643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600643 = validateParameter(valid_600643, JString, required = false,
                                 default = nil)
  if valid_600643 != nil:
    section.add "X-Amz-SignedHeaders", valid_600643
  var valid_600644 = header.getOrDefault("X-Amz-Credential")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-Credential", valid_600644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600645: Call_ListInvitations_600631; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all GuardDuty membership invitations that were sent to the current AWS account.
  ## 
  let valid = call_600645.validator(path, query, header, formData, body)
  let scheme = call_600645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600645.url(scheme.get, call_600645.host, call_600645.base,
                         call_600645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600645, url, valid)

proc call*(call_600646: Call_ListInvitations_600631; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listInvitations
  ## Lists all GuardDuty membership invitations that were sent to the current AWS account.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   nextToken: string
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600647 = newJObject()
  add(query_600647, "NextToken", newJString(NextToken))
  add(query_600647, "maxResults", newJInt(maxResults))
  add(query_600647, "nextToken", newJString(nextToken))
  add(query_600647, "MaxResults", newJString(MaxResults))
  result = call_600646.call(nil, query_600647, nil, nil, nil)

var listInvitations* = Call_ListInvitations_600631(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com", route: "/invitation",
    validator: validate_ListInvitations_600632, base: "/", url: url_ListInvitations_600633,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600662 = ref object of OpenApiRestCall_599368
proc url_TagResource_600664(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_600663(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600665 = path.getOrDefault("resourceArn")
  valid_600665 = validateParameter(valid_600665, JString, required = true,
                                 default = nil)
  if valid_600665 != nil:
    section.add "resourceArn", valid_600665
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600666 = header.getOrDefault("X-Amz-Date")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "X-Amz-Date", valid_600666
  var valid_600667 = header.getOrDefault("X-Amz-Security-Token")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Security-Token", valid_600667
  var valid_600668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Content-Sha256", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-Algorithm")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-Algorithm", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-Signature")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-Signature", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-SignedHeaders", valid_600671
  var valid_600672 = header.getOrDefault("X-Amz-Credential")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-Credential", valid_600672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600674: Call_TagResource_600662; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource.
  ## 
  let valid = call_600674.validator(path, query, header, formData, body)
  let scheme = call_600674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600674.url(scheme.get, call_600674.host, call_600674.base,
                         call_600674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600674, url, valid)

proc call*(call_600675: Call_TagResource_600662; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Adds tags to a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the GuardDuty resource to apply a tag to.
  var path_600676 = newJObject()
  var body_600677 = newJObject()
  if body != nil:
    body_600677 = body
  add(path_600676, "resourceArn", newJString(resourceArn))
  result = call_600675.call(path_600676, nil, nil, nil, body_600677)

var tagResource* = Call_TagResource_600662(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_600663,
                                        base: "/", url: url_TagResource_600664,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600648 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600650(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_600649(path: JsonNode; query: JsonNode;
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
  var valid_600651 = path.getOrDefault("resourceArn")
  valid_600651 = validateParameter(valid_600651, JString, required = true,
                                 default = nil)
  if valid_600651 != nil:
    section.add "resourceArn", valid_600651
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600652 = header.getOrDefault("X-Amz-Date")
  valid_600652 = validateParameter(valid_600652, JString, required = false,
                                 default = nil)
  if valid_600652 != nil:
    section.add "X-Amz-Date", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Security-Token")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Security-Token", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Content-Sha256", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Algorithm")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Algorithm", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-Signature")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-Signature", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-SignedHeaders", valid_600657
  var valid_600658 = header.getOrDefault("X-Amz-Credential")
  valid_600658 = validateParameter(valid_600658, JString, required = false,
                                 default = nil)
  if valid_600658 != nil:
    section.add "X-Amz-Credential", valid_600658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600659: Call_ListTagsForResource_600648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
  ## 
  let valid = call_600659.validator(path, query, header, formData, body)
  let scheme = call_600659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600659.url(scheme.get, call_600659.host, call_600659.base,
                         call_600659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600659, url, valid)

proc call*(call_600660: Call_ListTagsForResource_600648; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the given GuardDuty resource 
  var path_600661 = newJObject()
  add(path_600661, "resourceArn", newJString(resourceArn))
  result = call_600660.call(path_600661, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600648(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_600649, base: "/",
    url: url_ListTagsForResource_600650, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringMembers_600678 = ref object of OpenApiRestCall_599368
proc url_StartMonitoringMembers_600680(protocol: Scheme; host: string; base: string;
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

proc validate_StartMonitoringMembers_600679(path: JsonNode; query: JsonNode;
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
  var valid_600681 = path.getOrDefault("detectorId")
  valid_600681 = validateParameter(valid_600681, JString, required = true,
                                 default = nil)
  if valid_600681 != nil:
    section.add "detectorId", valid_600681
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600682 = header.getOrDefault("X-Amz-Date")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "X-Amz-Date", valid_600682
  var valid_600683 = header.getOrDefault("X-Amz-Security-Token")
  valid_600683 = validateParameter(valid_600683, JString, required = false,
                                 default = nil)
  if valid_600683 != nil:
    section.add "X-Amz-Security-Token", valid_600683
  var valid_600684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600684 = validateParameter(valid_600684, JString, required = false,
                                 default = nil)
  if valid_600684 != nil:
    section.add "X-Amz-Content-Sha256", valid_600684
  var valid_600685 = header.getOrDefault("X-Amz-Algorithm")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "X-Amz-Algorithm", valid_600685
  var valid_600686 = header.getOrDefault("X-Amz-Signature")
  valid_600686 = validateParameter(valid_600686, JString, required = false,
                                 default = nil)
  if valid_600686 != nil:
    section.add "X-Amz-Signature", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-SignedHeaders", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-Credential")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-Credential", valid_600688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600690: Call_StartMonitoringMembers_600678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Turns on GuardDuty monitoring of the specified member accounts. Use this operation to restart monitoring of accounts that you stopped monitoring with the <code>StopMonitoringMembers</code> operation.
  ## 
  let valid = call_600690.validator(path, query, header, formData, body)
  let scheme = call_600690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600690.url(scheme.get, call_600690.host, call_600690.base,
                         call_600690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600690, url, valid)

proc call*(call_600691: Call_StartMonitoringMembers_600678; detectorId: string;
          body: JsonNode): Recallable =
  ## startMonitoringMembers
  ## Turns on GuardDuty monitoring of the specified member accounts. Use this operation to restart monitoring of accounts that you stopped monitoring with the <code>StopMonitoringMembers</code> operation.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty master account associated with the member accounts to monitor.
  ##   body: JObject (required)
  var path_600692 = newJObject()
  var body_600693 = newJObject()
  add(path_600692, "detectorId", newJString(detectorId))
  if body != nil:
    body_600693 = body
  result = call_600691.call(path_600692, nil, nil, nil, body_600693)

var startMonitoringMembers* = Call_StartMonitoringMembers_600678(
    name: "startMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/start",
    validator: validate_StartMonitoringMembers_600679, base: "/",
    url: url_StartMonitoringMembers_600680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringMembers_600694 = ref object of OpenApiRestCall_599368
proc url_StopMonitoringMembers_600696(protocol: Scheme; host: string; base: string;
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

proc validate_StopMonitoringMembers_600695(path: JsonNode; query: JsonNode;
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
  var valid_600697 = path.getOrDefault("detectorId")
  valid_600697 = validateParameter(valid_600697, JString, required = true,
                                 default = nil)
  if valid_600697 != nil:
    section.add "detectorId", valid_600697
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600698 = header.getOrDefault("X-Amz-Date")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = nil)
  if valid_600698 != nil:
    section.add "X-Amz-Date", valid_600698
  var valid_600699 = header.getOrDefault("X-Amz-Security-Token")
  valid_600699 = validateParameter(valid_600699, JString, required = false,
                                 default = nil)
  if valid_600699 != nil:
    section.add "X-Amz-Security-Token", valid_600699
  var valid_600700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Content-Sha256", valid_600700
  var valid_600701 = header.getOrDefault("X-Amz-Algorithm")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Algorithm", valid_600701
  var valid_600702 = header.getOrDefault("X-Amz-Signature")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Signature", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-SignedHeaders", valid_600703
  var valid_600704 = header.getOrDefault("X-Amz-Credential")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-Credential", valid_600704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600706: Call_StopMonitoringMembers_600694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops GuardDuty monitoring for the specified member accounnts. Use the <code>StartMonitoringMembers</code> to restart monitoring for those accounts.
  ## 
  let valid = call_600706.validator(path, query, header, formData, body)
  let scheme = call_600706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600706.url(scheme.get, call_600706.host, call_600706.base,
                         call_600706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600706, url, valid)

proc call*(call_600707: Call_StopMonitoringMembers_600694; detectorId: string;
          body: JsonNode): Recallable =
  ## stopMonitoringMembers
  ## Stops GuardDuty monitoring for the specified member accounnts. Use the <code>StartMonitoringMembers</code> to restart monitoring for those accounts.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account that you want to stop from monitor members' findings.
  ##   body: JObject (required)
  var path_600708 = newJObject()
  var body_600709 = newJObject()
  add(path_600708, "detectorId", newJString(detectorId))
  if body != nil:
    body_600709 = body
  result = call_600707.call(path_600708, nil, nil, nil, body_600709)

var stopMonitoringMembers* = Call_StopMonitoringMembers_600694(
    name: "stopMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/stop",
    validator: validate_StopMonitoringMembers_600695, base: "/",
    url: url_StopMonitoringMembers_600696, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnarchiveFindings_600710 = ref object of OpenApiRestCall_599368
proc url_UnarchiveFindings_600712(protocol: Scheme; host: string; base: string;
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

proc validate_UnarchiveFindings_600711(path: JsonNode; query: JsonNode;
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
  var valid_600713 = path.getOrDefault("detectorId")
  valid_600713 = validateParameter(valid_600713, JString, required = true,
                                 default = nil)
  if valid_600713 != nil:
    section.add "detectorId", valid_600713
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600714 = header.getOrDefault("X-Amz-Date")
  valid_600714 = validateParameter(valid_600714, JString, required = false,
                                 default = nil)
  if valid_600714 != nil:
    section.add "X-Amz-Date", valid_600714
  var valid_600715 = header.getOrDefault("X-Amz-Security-Token")
  valid_600715 = validateParameter(valid_600715, JString, required = false,
                                 default = nil)
  if valid_600715 != nil:
    section.add "X-Amz-Security-Token", valid_600715
  var valid_600716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600716 = validateParameter(valid_600716, JString, required = false,
                                 default = nil)
  if valid_600716 != nil:
    section.add "X-Amz-Content-Sha256", valid_600716
  var valid_600717 = header.getOrDefault("X-Amz-Algorithm")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "X-Amz-Algorithm", valid_600717
  var valid_600718 = header.getOrDefault("X-Amz-Signature")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "X-Amz-Signature", valid_600718
  var valid_600719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600719 = validateParameter(valid_600719, JString, required = false,
                                 default = nil)
  if valid_600719 != nil:
    section.add "X-Amz-SignedHeaders", valid_600719
  var valid_600720 = header.getOrDefault("X-Amz-Credential")
  valid_600720 = validateParameter(valid_600720, JString, required = false,
                                 default = nil)
  if valid_600720 != nil:
    section.add "X-Amz-Credential", valid_600720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600722: Call_UnarchiveFindings_600710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Unarchives GuardDuty findings specified by the <code>findingIds</code>.
  ## 
  let valid = call_600722.validator(path, query, header, formData, body)
  let scheme = call_600722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600722.url(scheme.get, call_600722.host, call_600722.base,
                         call_600722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600722, url, valid)

proc call*(call_600723: Call_UnarchiveFindings_600710; detectorId: string;
          body: JsonNode): Recallable =
  ## unarchiveFindings
  ## Unarchives GuardDuty findings specified by the <code>findingIds</code>.
  ##   detectorId: string (required)
  ##             : The ID of the detector associated with the findings to unarchive.
  ##   body: JObject (required)
  var path_600724 = newJObject()
  var body_600725 = newJObject()
  add(path_600724, "detectorId", newJString(detectorId))
  if body != nil:
    body_600725 = body
  result = call_600723.call(path_600724, nil, nil, nil, body_600725)

var unarchiveFindings* = Call_UnarchiveFindings_600710(name: "unarchiveFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/unarchive",
    validator: validate_UnarchiveFindings_600711, base: "/",
    url: url_UnarchiveFindings_600712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600726 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600728(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_600727(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600729 = path.getOrDefault("resourceArn")
  valid_600729 = validateParameter(valid_600729, JString, required = true,
                                 default = nil)
  if valid_600729 != nil:
    section.add "resourceArn", valid_600729
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_600730 = query.getOrDefault("tagKeys")
  valid_600730 = validateParameter(valid_600730, JArray, required = true, default = nil)
  if valid_600730 != nil:
    section.add "tagKeys", valid_600730
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600731 = header.getOrDefault("X-Amz-Date")
  valid_600731 = validateParameter(valid_600731, JString, required = false,
                                 default = nil)
  if valid_600731 != nil:
    section.add "X-Amz-Date", valid_600731
  var valid_600732 = header.getOrDefault("X-Amz-Security-Token")
  valid_600732 = validateParameter(valid_600732, JString, required = false,
                                 default = nil)
  if valid_600732 != nil:
    section.add "X-Amz-Security-Token", valid_600732
  var valid_600733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600733 = validateParameter(valid_600733, JString, required = false,
                                 default = nil)
  if valid_600733 != nil:
    section.add "X-Amz-Content-Sha256", valid_600733
  var valid_600734 = header.getOrDefault("X-Amz-Algorithm")
  valid_600734 = validateParameter(valid_600734, JString, required = false,
                                 default = nil)
  if valid_600734 != nil:
    section.add "X-Amz-Algorithm", valid_600734
  var valid_600735 = header.getOrDefault("X-Amz-Signature")
  valid_600735 = validateParameter(valid_600735, JString, required = false,
                                 default = nil)
  if valid_600735 != nil:
    section.add "X-Amz-Signature", valid_600735
  var valid_600736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600736 = validateParameter(valid_600736, JString, required = false,
                                 default = nil)
  if valid_600736 != nil:
    section.add "X-Amz-SignedHeaders", valid_600736
  var valid_600737 = header.getOrDefault("X-Amz-Credential")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-Credential", valid_600737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600738: Call_UntagResource_600726; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_600738.validator(path, query, header, formData, body)
  let scheme = call_600738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600738.url(scheme.get, call_600738.host, call_600738.base,
                         call_600738.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600738, url, valid)

proc call*(call_600739: Call_UntagResource_600726; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from the resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the resource to remove tags from.
  var path_600740 = newJObject()
  var query_600741 = newJObject()
  if tagKeys != nil:
    query_600741.add "tagKeys", tagKeys
  add(path_600740, "resourceArn", newJString(resourceArn))
  result = call_600739.call(path_600740, query_600741, nil, nil, nil)

var untagResource* = Call_UntagResource_600726(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_600727,
    base: "/", url: url_UntagResource_600728, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindingsFeedback_600742 = ref object of OpenApiRestCall_599368
proc url_UpdateFindingsFeedback_600744(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFindingsFeedback_600743(path: JsonNode; query: JsonNode;
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
  var valid_600745 = path.getOrDefault("detectorId")
  valid_600745 = validateParameter(valid_600745, JString, required = true,
                                 default = nil)
  if valid_600745 != nil:
    section.add "detectorId", valid_600745
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600746 = header.getOrDefault("X-Amz-Date")
  valid_600746 = validateParameter(valid_600746, JString, required = false,
                                 default = nil)
  if valid_600746 != nil:
    section.add "X-Amz-Date", valid_600746
  var valid_600747 = header.getOrDefault("X-Amz-Security-Token")
  valid_600747 = validateParameter(valid_600747, JString, required = false,
                                 default = nil)
  if valid_600747 != nil:
    section.add "X-Amz-Security-Token", valid_600747
  var valid_600748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600748 = validateParameter(valid_600748, JString, required = false,
                                 default = nil)
  if valid_600748 != nil:
    section.add "X-Amz-Content-Sha256", valid_600748
  var valid_600749 = header.getOrDefault("X-Amz-Algorithm")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "X-Amz-Algorithm", valid_600749
  var valid_600750 = header.getOrDefault("X-Amz-Signature")
  valid_600750 = validateParameter(valid_600750, JString, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "X-Amz-Signature", valid_600750
  var valid_600751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600751 = validateParameter(valid_600751, JString, required = false,
                                 default = nil)
  if valid_600751 != nil:
    section.add "X-Amz-SignedHeaders", valid_600751
  var valid_600752 = header.getOrDefault("X-Amz-Credential")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "X-Amz-Credential", valid_600752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600754: Call_UpdateFindingsFeedback_600742; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Marks the specified GuardDuty findings as useful or not useful.
  ## 
  let valid = call_600754.validator(path, query, header, formData, body)
  let scheme = call_600754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600754.url(scheme.get, call_600754.host, call_600754.base,
                         call_600754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600754, url, valid)

proc call*(call_600755: Call_UpdateFindingsFeedback_600742; detectorId: string;
          body: JsonNode): Recallable =
  ## updateFindingsFeedback
  ## Marks the specified GuardDuty findings as useful or not useful.
  ##   detectorId: string (required)
  ##             : The ID of the detector associated with the findings to update feedback for.
  ##   body: JObject (required)
  var path_600756 = newJObject()
  var body_600757 = newJObject()
  add(path_600756, "detectorId", newJString(detectorId))
  if body != nil:
    body_600757 = body
  result = call_600755.call(path_600756, nil, nil, nil, body_600757)

var updateFindingsFeedback* = Call_UpdateFindingsFeedback_600742(
    name: "updateFindingsFeedback", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/feedback",
    validator: validate_UpdateFindingsFeedback_600743, base: "/",
    url: url_UpdateFindingsFeedback_600744, schemes: {Scheme.Https, Scheme.Http})
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
