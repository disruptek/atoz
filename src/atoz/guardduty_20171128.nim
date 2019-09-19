
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon GuardDuty
## version: 2017-11-28
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon GuardDuty is a continuous security monitoring service that analyzes and processes the following data sources: VPC Flow Logs, AWS CloudTrail event logs, and DNS logs. It uses threat intelligence feeds, such as lists of malicious IPs and domains, and machine learning to identify unexpected and potentially unauthorized and malicious activity within your AWS environment. This can include issues like escalations of privileges, uses of exposed credentials, or communication with malicious IPs, URLs, or domains. For example, GuardDuty can detect compromised EC2 instances serving malware or mining bitcoin. It also monitors AWS account access behavior for signs of compromise, such as unauthorized infrastructure deployments, like instances deployed in a region that has never been used, or unusual API calls, like a password policy change to reduce password strength. GuardDuty informs you of the status of your AWS environment by producing security findings that you can view in the GuardDuty console or through Amazon CloudWatch events. For more information, see <a href="https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html"> Amazon GuardDuty User Guide</a>. 
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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AcceptInvitation_601038 = ref object of OpenApiRestCall_600426
proc url_AcceptInvitation_601040(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/master")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_AcceptInvitation_601039(path: JsonNode; query: JsonNode;
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
  var valid_601041 = path.getOrDefault("detectorId")
  valid_601041 = validateParameter(valid_601041, JString, required = true,
                                 default = nil)
  if valid_601041 != nil:
    section.add "detectorId", valid_601041
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
  var valid_601042 = header.getOrDefault("X-Amz-Date")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Date", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Security-Token")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Security-Token", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Content-Sha256", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Algorithm")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Algorithm", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Signature")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Signature", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-SignedHeaders", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Credential")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Credential", valid_601048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601050: Call_AcceptInvitation_601038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts the invitation to be monitored by a master GuardDuty account.
  ## 
  let valid = call_601050.validator(path, query, header, formData, body)
  let scheme = call_601050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601050.url(scheme.get, call_601050.host, call_601050.base,
                         call_601050.route, valid.getOrDefault("path"))
  result = hook(call_601050, url, valid)

proc call*(call_601051: Call_AcceptInvitation_601038; detectorId: string;
          body: JsonNode): Recallable =
  ## acceptInvitation
  ## Accepts the invitation to be monitored by a master GuardDuty account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  ##   body: JObject (required)
  var path_601052 = newJObject()
  var body_601053 = newJObject()
  add(path_601052, "detectorId", newJString(detectorId))
  if body != nil:
    body_601053 = body
  result = call_601051.call(path_601052, nil, nil, nil, body_601053)

var acceptInvitation* = Call_AcceptInvitation_601038(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master", validator: validate_AcceptInvitation_601039,
    base: "/", url: url_AcceptInvitation_601040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_600768 = ref object of OpenApiRestCall_600426
proc url_GetMasterAccount_600770(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/master")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetMasterAccount_600769(path: JsonNode; query: JsonNode;
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
  var valid_600896 = path.getOrDefault("detectorId")
  valid_600896 = validateParameter(valid_600896, JString, required = true,
                                 default = nil)
  if valid_600896 != nil:
    section.add "detectorId", valid_600896
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
  var valid_600897 = header.getOrDefault("X-Amz-Date")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "X-Amz-Date", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Security-Token")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Security-Token", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Content-Sha256", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Algorithm")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Algorithm", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Signature")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Signature", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-SignedHeaders", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Credential")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Credential", valid_600903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_GetMasterAccount_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_GetMasterAccount_600768; detectorId: string): Recallable =
  ## getMasterAccount
  ## Provides the details for the GuardDuty master account associated with the current GuardDuty member account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  var path_600998 = newJObject()
  add(path_600998, "detectorId", newJString(detectorId))
  result = call_600997.call(path_600998, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_600768(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master", validator: validate_GetMasterAccount_600769,
    base: "/", url: url_GetMasterAccount_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ArchiveFindings_601054 = ref object of OpenApiRestCall_600426
proc url_ArchiveFindings_601056(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/findings/archive")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ArchiveFindings_601055(path: JsonNode; query: JsonNode;
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
  var valid_601057 = path.getOrDefault("detectorId")
  valid_601057 = validateParameter(valid_601057, JString, required = true,
                                 default = nil)
  if valid_601057 != nil:
    section.add "detectorId", valid_601057
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
  var valid_601058 = header.getOrDefault("X-Amz-Date")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Date", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Security-Token")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Security-Token", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Content-Sha256", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Algorithm")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Algorithm", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Signature")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Signature", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-SignedHeaders", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Credential")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Credential", valid_601064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601066: Call_ArchiveFindings_601054; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
  ## 
  let valid = call_601066.validator(path, query, header, formData, body)
  let scheme = call_601066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601066.url(scheme.get, call_601066.host, call_601066.base,
                         call_601066.route, valid.getOrDefault("path"))
  result = hook(call_601066, url, valid)

proc call*(call_601067: Call_ArchiveFindings_601054; detectorId: string;
          body: JsonNode): Recallable =
  ## archiveFindings
  ## <p>Archives GuardDuty findings specified by the list of finding IDs.</p> <note> <p>Only the master account can archive findings. Member accounts do not have permission to archive findings from their accounts.</p> </note>
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to archive.
  ##   body: JObject (required)
  var path_601068 = newJObject()
  var body_601069 = newJObject()
  add(path_601068, "detectorId", newJString(detectorId))
  if body != nil:
    body_601069 = body
  result = call_601067.call(path_601068, nil, nil, nil, body_601069)

var archiveFindings* = Call_ArchiveFindings_601054(name: "archiveFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/archive",
    validator: validate_ArchiveFindings_601055, base: "/", url: url_ArchiveFindings_601056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDetector_601087 = ref object of OpenApiRestCall_600426
proc url_CreateDetector_601089(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDetector_601088(path: JsonNode; query: JsonNode;
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
  var valid_601090 = header.getOrDefault("X-Amz-Date")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Date", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Security-Token")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Security-Token", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Content-Sha256", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Algorithm")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Algorithm", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Signature")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Signature", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-SignedHeaders", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Credential")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Credential", valid_601096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601098: Call_CreateDetector_601087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
  ## 
  let valid = call_601098.validator(path, query, header, formData, body)
  let scheme = call_601098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601098.url(scheme.get, call_601098.host, call_601098.base,
                         call_601098.route, valid.getOrDefault("path"))
  result = hook(call_601098, url, valid)

proc call*(call_601099: Call_CreateDetector_601087; body: JsonNode): Recallable =
  ## createDetector
  ## Creates a single Amazon GuardDuty detector. A detector is a resource that represents the GuardDuty service. To start using GuardDuty, you must create a detector in each region that you enable the service. You can have only one detector per account per region.
  ##   body: JObject (required)
  var body_601100 = newJObject()
  if body != nil:
    body_601100 = body
  result = call_601099.call(nil, nil, nil, nil, body_601100)

var createDetector* = Call_CreateDetector_601087(name: "createDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com", route: "/detector",
    validator: validate_CreateDetector_601088, base: "/", url: url_CreateDetector_601089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDetectors_601070 = ref object of OpenApiRestCall_600426
proc url_ListDetectors_601072(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDetectors_601071(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601073 = query.getOrDefault("NextToken")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "NextToken", valid_601073
  var valid_601074 = query.getOrDefault("maxResults")
  valid_601074 = validateParameter(valid_601074, JInt, required = false, default = nil)
  if valid_601074 != nil:
    section.add "maxResults", valid_601074
  var valid_601075 = query.getOrDefault("nextToken")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "nextToken", valid_601075
  var valid_601076 = query.getOrDefault("MaxResults")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "MaxResults", valid_601076
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
  var valid_601077 = header.getOrDefault("X-Amz-Date")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Date", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Security-Token")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Security-Token", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Content-Sha256", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Algorithm")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Algorithm", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Signature")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Signature", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-SignedHeaders", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Credential")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Credential", valid_601083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601084: Call_ListDetectors_601070; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists detectorIds of all the existing Amazon GuardDuty detector resources.
  ## 
  let valid = call_601084.validator(path, query, header, formData, body)
  let scheme = call_601084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601084.url(scheme.get, call_601084.host, call_601084.base,
                         call_601084.route, valid.getOrDefault("path"))
  result = hook(call_601084, url, valid)

proc call*(call_601085: Call_ListDetectors_601070; NextToken: string = "";
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
  var query_601086 = newJObject()
  add(query_601086, "NextToken", newJString(NextToken))
  add(query_601086, "maxResults", newJInt(maxResults))
  add(query_601086, "nextToken", newJString(nextToken))
  add(query_601086, "MaxResults", newJString(MaxResults))
  result = call_601085.call(nil, query_601086, nil, nil, nil)

var listDetectors* = Call_ListDetectors_601070(name: "listDetectors",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com", route: "/detector",
    validator: validate_ListDetectors_601071, base: "/", url: url_ListDetectors_601072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFilter_601120 = ref object of OpenApiRestCall_600426
proc url_CreateFilter_601122(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/filter")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateFilter_601121(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601123 = path.getOrDefault("detectorId")
  valid_601123 = validateParameter(valid_601123, JString, required = true,
                                 default = nil)
  if valid_601123 != nil:
    section.add "detectorId", valid_601123
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
  var valid_601124 = header.getOrDefault("X-Amz-Date")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Date", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Security-Token")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Security-Token", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Content-Sha256", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Algorithm")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Algorithm", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Signature")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Signature", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-SignedHeaders", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Credential")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Credential", valid_601130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601132: Call_CreateFilter_601120; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a filter using the specified finding criteria.
  ## 
  let valid = call_601132.validator(path, query, header, formData, body)
  let scheme = call_601132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601132.url(scheme.get, call_601132.host, call_601132.base,
                         call_601132.route, valid.getOrDefault("path"))
  result = hook(call_601132, url, valid)

proc call*(call_601133: Call_CreateFilter_601120; detectorId: string; body: JsonNode): Recallable =
  ## createFilter
  ## Creates a filter using the specified finding criteria.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create a filter.
  ##   body: JObject (required)
  var path_601134 = newJObject()
  var body_601135 = newJObject()
  add(path_601134, "detectorId", newJString(detectorId))
  if body != nil:
    body_601135 = body
  result = call_601133.call(path_601134, nil, nil, nil, body_601135)

var createFilter* = Call_CreateFilter_601120(name: "createFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter", validator: validate_CreateFilter_601121,
    base: "/", url: url_CreateFilter_601122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFilters_601101 = ref object of OpenApiRestCall_600426
proc url_ListFilters_601103(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/filter")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListFilters_601102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601104 = path.getOrDefault("detectorId")
  valid_601104 = validateParameter(valid_601104, JString, required = true,
                                 default = nil)
  if valid_601104 != nil:
    section.add "detectorId", valid_601104
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
  var valid_601105 = query.getOrDefault("NextToken")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "NextToken", valid_601105
  var valid_601106 = query.getOrDefault("maxResults")
  valid_601106 = validateParameter(valid_601106, JInt, required = false, default = nil)
  if valid_601106 != nil:
    section.add "maxResults", valid_601106
  var valid_601107 = query.getOrDefault("nextToken")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "nextToken", valid_601107
  var valid_601108 = query.getOrDefault("MaxResults")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "MaxResults", valid_601108
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
  var valid_601109 = header.getOrDefault("X-Amz-Date")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Date", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Security-Token")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Security-Token", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Content-Sha256", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Algorithm")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Algorithm", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Signature")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Signature", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-SignedHeaders", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Credential")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Credential", valid_601115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601116: Call_ListFilters_601101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a paginated list of the current filters.
  ## 
  let valid = call_601116.validator(path, query, header, formData, body)
  let scheme = call_601116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601116.url(scheme.get, call_601116.host, call_601116.base,
                         call_601116.route, valid.getOrDefault("path"))
  result = hook(call_601116, url, valid)

proc call*(call_601117: Call_ListFilters_601101; detectorId: string;
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
  var path_601118 = newJObject()
  var query_601119 = newJObject()
  add(query_601119, "NextToken", newJString(NextToken))
  add(query_601119, "maxResults", newJInt(maxResults))
  add(query_601119, "nextToken", newJString(nextToken))
  add(path_601118, "detectorId", newJString(detectorId))
  add(query_601119, "MaxResults", newJString(MaxResults))
  result = call_601117.call(path_601118, query_601119, nil, nil, nil)

var listFilters* = Call_ListFilters_601101(name: "listFilters",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/filter",
                                        validator: validate_ListFilters_601102,
                                        base: "/", url: url_ListFilters_601103,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIPSet_601155 = ref object of OpenApiRestCall_600426
proc url_CreateIPSet_601157(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/ipset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateIPSet_601156(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new IPSet - a list of trusted IP addresses that have been whitelisted for secure communication with AWS infrastructure and applications.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create an IPSet.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_601158 = path.getOrDefault("detectorId")
  valid_601158 = validateParameter(valid_601158, JString, required = true,
                                 default = nil)
  if valid_601158 != nil:
    section.add "detectorId", valid_601158
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
  var valid_601159 = header.getOrDefault("X-Amz-Date")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Date", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-Security-Token")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Security-Token", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Content-Sha256", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Algorithm")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Algorithm", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Signature")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Signature", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-SignedHeaders", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Credential")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Credential", valid_601165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601167: Call_CreateIPSet_601155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new IPSet - a list of trusted IP addresses that have been whitelisted for secure communication with AWS infrastructure and applications.
  ## 
  let valid = call_601167.validator(path, query, header, formData, body)
  let scheme = call_601167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601167.url(scheme.get, call_601167.host, call_601167.base,
                         call_601167.route, valid.getOrDefault("path"))
  result = hook(call_601167, url, valid)

proc call*(call_601168: Call_CreateIPSet_601155; detectorId: string; body: JsonNode): Recallable =
  ## createIPSet
  ## Creates a new IPSet - a list of trusted IP addresses that have been whitelisted for secure communication with AWS infrastructure and applications.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create an IPSet.
  ##   body: JObject (required)
  var path_601169 = newJObject()
  var body_601170 = newJObject()
  add(path_601169, "detectorId", newJString(detectorId))
  if body != nil:
    body_601170 = body
  result = call_601168.call(path_601169, nil, nil, nil, body_601170)

var createIPSet* = Call_CreateIPSet_601155(name: "createIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/ipset",
                                        validator: validate_CreateIPSet_601156,
                                        base: "/", url: url_CreateIPSet_601157,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIPSets_601136 = ref object of OpenApiRestCall_600426
proc url_ListIPSets_601138(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/ipset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListIPSets_601137(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the IPSets of the GuardDuty service specified by the detector ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector the ipSet is associated with.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_601139 = path.getOrDefault("detectorId")
  valid_601139 = validateParameter(valid_601139, JString, required = true,
                                 default = nil)
  if valid_601139 != nil:
    section.add "detectorId", valid_601139
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
  var valid_601140 = query.getOrDefault("NextToken")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "NextToken", valid_601140
  var valid_601141 = query.getOrDefault("maxResults")
  valid_601141 = validateParameter(valid_601141, JInt, required = false, default = nil)
  if valid_601141 != nil:
    section.add "maxResults", valid_601141
  var valid_601142 = query.getOrDefault("nextToken")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "nextToken", valid_601142
  var valid_601143 = query.getOrDefault("MaxResults")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "MaxResults", valid_601143
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
  var valid_601144 = header.getOrDefault("X-Amz-Date")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Date", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Security-Token")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Security-Token", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Content-Sha256", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Algorithm")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Algorithm", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Signature")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Signature", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-SignedHeaders", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Credential")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Credential", valid_601150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601151: Call_ListIPSets_601136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the IPSets of the GuardDuty service specified by the detector ID.
  ## 
  let valid = call_601151.validator(path, query, header, formData, body)
  let scheme = call_601151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601151.url(scheme.get, call_601151.host, call_601151.base,
                         call_601151.route, valid.getOrDefault("path"))
  result = hook(call_601151, url, valid)

proc call*(call_601152: Call_ListIPSets_601136; detectorId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listIPSets
  ## Lists the IPSets of the GuardDuty service specified by the detector ID.
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
  var path_601153 = newJObject()
  var query_601154 = newJObject()
  add(query_601154, "NextToken", newJString(NextToken))
  add(query_601154, "maxResults", newJInt(maxResults))
  add(query_601154, "nextToken", newJString(nextToken))
  add(path_601153, "detectorId", newJString(detectorId))
  add(query_601154, "MaxResults", newJString(MaxResults))
  result = call_601152.call(path_601153, query_601154, nil, nil, nil)

var listIPSets* = Call_ListIPSets_601136(name: "listIPSets",
                                      meth: HttpMethod.HttpGet,
                                      host: "guardduty.amazonaws.com",
                                      route: "/detector/{detectorId}/ipset",
                                      validator: validate_ListIPSets_601137,
                                      base: "/", url: url_ListIPSets_601138,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_601191 = ref object of OpenApiRestCall_600426
proc url_CreateMembers_601193(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/member")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateMembers_601192(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601194 = path.getOrDefault("detectorId")
  valid_601194 = validateParameter(valid_601194, JString, required = true,
                                 default = nil)
  if valid_601194 != nil:
    section.add "detectorId", valid_601194
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
  var valid_601195 = header.getOrDefault("X-Amz-Date")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Date", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Security-Token")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Security-Token", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Content-Sha256", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Algorithm")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Algorithm", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Signature")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Signature", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-SignedHeaders", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Credential")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Credential", valid_601201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601203: Call_CreateMembers_601191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
  ## 
  let valid = call_601203.validator(path, query, header, formData, body)
  let scheme = call_601203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601203.url(scheme.get, call_601203.host, call_601203.base,
                         call_601203.route, valid.getOrDefault("path"))
  result = hook(call_601203, url, valid)

proc call*(call_601204: Call_CreateMembers_601191; detectorId: string; body: JsonNode): Recallable =
  ## createMembers
  ## Creates member accounts of the current AWS account by specifying a list of AWS account IDs. The current AWS account can then invite these members to manage GuardDuty in their accounts.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account with which you want to associate member accounts.
  ##   body: JObject (required)
  var path_601205 = newJObject()
  var body_601206 = newJObject()
  add(path_601205, "detectorId", newJString(detectorId))
  if body != nil:
    body_601206 = body
  result = call_601204.call(path_601205, nil, nil, nil, body_601206)

var createMembers* = Call_CreateMembers_601191(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member", validator: validate_CreateMembers_601192,
    base: "/", url: url_CreateMembers_601193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_601171 = ref object of OpenApiRestCall_600426
proc url_ListMembers_601173(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/member")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListMembers_601172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601174 = path.getOrDefault("detectorId")
  valid_601174 = validateParameter(valid_601174, JString, required = true,
                                 default = nil)
  if valid_601174 != nil:
    section.add "detectorId", valid_601174
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
  var valid_601175 = query.getOrDefault("onlyAssociated")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "onlyAssociated", valid_601175
  var valid_601176 = query.getOrDefault("NextToken")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "NextToken", valid_601176
  var valid_601177 = query.getOrDefault("maxResults")
  valid_601177 = validateParameter(valid_601177, JInt, required = false, default = nil)
  if valid_601177 != nil:
    section.add "maxResults", valid_601177
  var valid_601178 = query.getOrDefault("nextToken")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "nextToken", valid_601178
  var valid_601179 = query.getOrDefault("MaxResults")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "MaxResults", valid_601179
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
  var valid_601180 = header.getOrDefault("X-Amz-Date")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Date", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Security-Token")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Security-Token", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Content-Sha256", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Algorithm")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Algorithm", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Signature")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Signature", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-SignedHeaders", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Credential")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Credential", valid_601186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601187: Call_ListMembers_601171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current GuardDuty master account.
  ## 
  let valid = call_601187.validator(path, query, header, formData, body)
  let scheme = call_601187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601187.url(scheme.get, call_601187.host, call_601187.base,
                         call_601187.route, valid.getOrDefault("path"))
  result = hook(call_601187, url, valid)

proc call*(call_601188: Call_ListMembers_601171; detectorId: string;
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
  var path_601189 = newJObject()
  var query_601190 = newJObject()
  add(query_601190, "onlyAssociated", newJString(onlyAssociated))
  add(query_601190, "NextToken", newJString(NextToken))
  add(query_601190, "maxResults", newJInt(maxResults))
  add(query_601190, "nextToken", newJString(nextToken))
  add(path_601189, "detectorId", newJString(detectorId))
  add(query_601190, "MaxResults", newJString(MaxResults))
  result = call_601188.call(path_601189, query_601190, nil, nil, nil)

var listMembers* = Call_ListMembers_601171(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}/member",
                                        validator: validate_ListMembers_601172,
                                        base: "/", url: url_ListMembers_601173,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSampleFindings_601207 = ref object of OpenApiRestCall_600426
proc url_CreateSampleFindings_601209(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/findings/create")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateSampleFindings_601208(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for findingTypes, the API generates example findings of all supported finding types.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The ID of the detector to create sample findings for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_601210 = path.getOrDefault("detectorId")
  valid_601210 = validateParameter(valid_601210, JString, required = true,
                                 default = nil)
  if valid_601210 != nil:
    section.add "detectorId", valid_601210
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
  var valid_601211 = header.getOrDefault("X-Amz-Date")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Date", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Security-Token")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Security-Token", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Content-Sha256", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Algorithm")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Algorithm", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Signature")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Signature", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-SignedHeaders", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Credential")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Credential", valid_601217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601219: Call_CreateSampleFindings_601207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for findingTypes, the API generates example findings of all supported finding types.
  ## 
  let valid = call_601219.validator(path, query, header, formData, body)
  let scheme = call_601219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601219.url(scheme.get, call_601219.host, call_601219.base,
                         call_601219.route, valid.getOrDefault("path"))
  result = hook(call_601219, url, valid)

proc call*(call_601220: Call_CreateSampleFindings_601207; detectorId: string;
          body: JsonNode): Recallable =
  ## createSampleFindings
  ## Generates example findings of types specified by the list of finding types. If 'NULL' is specified for findingTypes, the API generates example findings of all supported finding types.
  ##   detectorId: string (required)
  ##             : The ID of the detector to create sample findings for.
  ##   body: JObject (required)
  var path_601221 = newJObject()
  var body_601222 = newJObject()
  add(path_601221, "detectorId", newJString(detectorId))
  if body != nil:
    body_601222 = body
  result = call_601220.call(path_601221, nil, nil, nil, body_601222)

var createSampleFindings* = Call_CreateSampleFindings_601207(
    name: "createSampleFindings", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/create",
    validator: validate_CreateSampleFindings_601208, base: "/",
    url: url_CreateSampleFindings_601209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateThreatIntelSet_601242 = ref object of OpenApiRestCall_600426
proc url_CreateThreatIntelSet_601244(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/threatintelset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateThreatIntelSet_601243(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create a threatIntelSet.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_601245 = path.getOrDefault("detectorId")
  valid_601245 = validateParameter(valid_601245, JString, required = true,
                                 default = nil)
  if valid_601245 != nil:
    section.add "detectorId", valid_601245
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
  var valid_601246 = header.getOrDefault("X-Amz-Date")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Date", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Security-Token")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Security-Token", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Content-Sha256", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Algorithm")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Algorithm", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Signature")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Signature", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-SignedHeaders", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Credential")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Credential", valid_601252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601254: Call_CreateThreatIntelSet_601242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets.
  ## 
  let valid = call_601254.validator(path, query, header, formData, body)
  let scheme = call_601254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601254.url(scheme.get, call_601254.host, call_601254.base,
                         call_601254.route, valid.getOrDefault("path"))
  result = hook(call_601254, url, valid)

proc call*(call_601255: Call_CreateThreatIntelSet_601242; detectorId: string;
          body: JsonNode): Recallable =
  ## createThreatIntelSet
  ## Create a new ThreatIntelSet. ThreatIntelSets consist of known malicious IP addresses. GuardDuty generates findings based on ThreatIntelSets.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account for which you want to create a threatIntelSet.
  ##   body: JObject (required)
  var path_601256 = newJObject()
  var body_601257 = newJObject()
  add(path_601256, "detectorId", newJString(detectorId))
  if body != nil:
    body_601257 = body
  result = call_601255.call(path_601256, nil, nil, nil, body_601257)

var createThreatIntelSet* = Call_CreateThreatIntelSet_601242(
    name: "createThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_CreateThreatIntelSet_601243, base: "/",
    url: url_CreateThreatIntelSet_601244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListThreatIntelSets_601223 = ref object of OpenApiRestCall_600426
proc url_ListThreatIntelSets_601225(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/threatintelset")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListThreatIntelSets_601224(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the ThreatIntelSets of the GuardDuty service specified by the detector ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_601226 = path.getOrDefault("detectorId")
  valid_601226 = validateParameter(valid_601226, JString, required = true,
                                 default = nil)
  if valid_601226 != nil:
    section.add "detectorId", valid_601226
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
  var valid_601227 = query.getOrDefault("NextToken")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "NextToken", valid_601227
  var valid_601228 = query.getOrDefault("maxResults")
  valid_601228 = validateParameter(valid_601228, JInt, required = false, default = nil)
  if valid_601228 != nil:
    section.add "maxResults", valid_601228
  var valid_601229 = query.getOrDefault("nextToken")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "nextToken", valid_601229
  var valid_601230 = query.getOrDefault("MaxResults")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "MaxResults", valid_601230
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
  var valid_601231 = header.getOrDefault("X-Amz-Date")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Date", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Security-Token")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Security-Token", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Content-Sha256", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Algorithm")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Algorithm", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Signature")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Signature", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-SignedHeaders", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Credential")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Credential", valid_601237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601238: Call_ListThreatIntelSets_601223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the ThreatIntelSets of the GuardDuty service specified by the detector ID.
  ## 
  let valid = call_601238.validator(path, query, header, formData, body)
  let scheme = call_601238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601238.url(scheme.get, call_601238.host, call_601238.base,
                         call_601238.route, valid.getOrDefault("path"))
  result = hook(call_601238, url, valid)

proc call*(call_601239: Call_ListThreatIntelSets_601223; detectorId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listThreatIntelSets
  ## Lists the ThreatIntelSets of the GuardDuty service specified by the detector ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : You can use this parameter to indicate the maximum number of items you want in the response. The default value is 50. The maximum value is 50.
  ##   nextToken: string
  ##            : You can use this parameter when paginating results. Set the value of this parameter to null on your first call to the list action. For subsequent calls to the action fill nextToken in the request with the value of NextToken from the previous response to continue listing data.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_601240 = newJObject()
  var query_601241 = newJObject()
  add(query_601241, "NextToken", newJString(NextToken))
  add(query_601241, "maxResults", newJInt(maxResults))
  add(query_601241, "nextToken", newJString(nextToken))
  add(path_601240, "detectorId", newJString(detectorId))
  add(query_601241, "MaxResults", newJString(MaxResults))
  result = call_601239.call(path_601240, query_601241, nil, nil, nil)

var listThreatIntelSets* = Call_ListThreatIntelSets_601223(
    name: "listThreatIntelSets", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset",
    validator: validate_ListThreatIntelSets_601224, base: "/",
    url: url_ListThreatIntelSets_601225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_601258 = ref object of OpenApiRestCall_600426
proc url_DeclineInvitations_601260(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeclineInvitations_601259(path: JsonNode; query: JsonNode;
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
  var valid_601261 = header.getOrDefault("X-Amz-Date")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Date", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Security-Token")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Security-Token", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Content-Sha256", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Algorithm")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Algorithm", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Signature")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Signature", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-SignedHeaders", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Credential")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Credential", valid_601267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601269: Call_DeclineInvitations_601258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
  ## 
  let valid = call_601269.validator(path, query, header, formData, body)
  let scheme = call_601269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601269.url(scheme.get, call_601269.host, call_601269.base,
                         call_601269.route, valid.getOrDefault("path"))
  result = hook(call_601269, url, valid)

proc call*(call_601270: Call_DeclineInvitations_601258; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations sent to the current member account by AWS account specified by their account IDs.
  ##   body: JObject (required)
  var body_601271 = newJObject()
  if body != nil:
    body_601271 = body
  result = call_601270.call(nil, nil, nil, nil, body_601271)

var declineInvitations* = Call_DeclineInvitations_601258(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/invitation/decline",
    validator: validate_DeclineInvitations_601259, base: "/",
    url: url_DeclineInvitations_601260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDetector_601286 = ref object of OpenApiRestCall_600426
proc url_UpdateDetector_601288(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDetector_601287(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates an Amazon GuardDuty detector specified by the detectorId.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector that you want to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_601289 = path.getOrDefault("detectorId")
  valid_601289 = validateParameter(valid_601289, JString, required = true,
                                 default = nil)
  if valid_601289 != nil:
    section.add "detectorId", valid_601289
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
  var valid_601290 = header.getOrDefault("X-Amz-Date")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Date", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Security-Token")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Security-Token", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Content-Sha256", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Algorithm")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Algorithm", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Signature")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Signature", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-SignedHeaders", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Credential")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Credential", valid_601296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601298: Call_UpdateDetector_601286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Amazon GuardDuty detector specified by the detectorId.
  ## 
  let valid = call_601298.validator(path, query, header, formData, body)
  let scheme = call_601298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601298.url(scheme.get, call_601298.host, call_601298.base,
                         call_601298.route, valid.getOrDefault("path"))
  result = hook(call_601298, url, valid)

proc call*(call_601299: Call_UpdateDetector_601286; detectorId: string;
          body: JsonNode): Recallable =
  ## updateDetector
  ## Updates an Amazon GuardDuty detector specified by the detectorId.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that you want to update.
  ##   body: JObject (required)
  var path_601300 = newJObject()
  var body_601301 = newJObject()
  add(path_601300, "detectorId", newJString(detectorId))
  if body != nil:
    body_601301 = body
  result = call_601299.call(path_601300, nil, nil, nil, body_601301)

var updateDetector* = Call_UpdateDetector_601286(name: "updateDetector",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_UpdateDetector_601287,
    base: "/", url: url_UpdateDetector_601288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDetector_601272 = ref object of OpenApiRestCall_600426
proc url_GetDetector_601274(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDetector_601273(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601275 = path.getOrDefault("detectorId")
  valid_601275 = validateParameter(valid_601275, JString, required = true,
                                 default = nil)
  if valid_601275 != nil:
    section.add "detectorId", valid_601275
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
  var valid_601276 = header.getOrDefault("X-Amz-Date")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Date", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Security-Token")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Security-Token", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Content-Sha256", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Algorithm")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Algorithm", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Signature")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Signature", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-SignedHeaders", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Credential")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Credential", valid_601282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601283: Call_GetDetector_601272; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
  ## 
  let valid = call_601283.validator(path, query, header, formData, body)
  let scheme = call_601283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601283.url(scheme.get, call_601283.host, call_601283.base,
                         call_601283.route, valid.getOrDefault("path"))
  result = hook(call_601283, url, valid)

proc call*(call_601284: Call_GetDetector_601272; detectorId: string): Recallable =
  ## getDetector
  ## Retrieves an Amazon GuardDuty detector specified by the detectorId.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that you want to get.
  var path_601285 = newJObject()
  add(path_601285, "detectorId", newJString(detectorId))
  result = call_601284.call(path_601285, nil, nil, nil, nil)

var getDetector* = Call_GetDetector_601272(name: "getDetector",
                                        meth: HttpMethod.HttpGet,
                                        host: "guardduty.amazonaws.com",
                                        route: "/detector/{detectorId}",
                                        validator: validate_GetDetector_601273,
                                        base: "/", url: url_GetDetector_601274,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDetector_601302 = ref object of OpenApiRestCall_600426
proc url_DeleteDetector_601304(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDetector_601303(path: JsonNode; query: JsonNode;
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
  var valid_601305 = path.getOrDefault("detectorId")
  valid_601305 = validateParameter(valid_601305, JString, required = true,
                                 default = nil)
  if valid_601305 != nil:
    section.add "detectorId", valid_601305
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
  var valid_601306 = header.getOrDefault("X-Amz-Date")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Date", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Security-Token")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Security-Token", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Content-Sha256", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Algorithm")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Algorithm", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Signature")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Signature", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-SignedHeaders", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Credential")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Credential", valid_601312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601313: Call_DeleteDetector_601302; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
  ## 
  let valid = call_601313.validator(path, query, header, formData, body)
  let scheme = call_601313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601313.url(scheme.get, call_601313.host, call_601313.base,
                         call_601313.route, valid.getOrDefault("path"))
  result = hook(call_601313, url, valid)

proc call*(call_601314: Call_DeleteDetector_601302; detectorId: string): Recallable =
  ## deleteDetector
  ## Deletes a Amazon GuardDuty detector specified by the detector ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that you want to delete.
  var path_601315 = newJObject()
  add(path_601315, "detectorId", newJString(detectorId))
  result = call_601314.call(path_601315, nil, nil, nil, nil)

var deleteDetector* = Call_DeleteDetector_601302(name: "deleteDetector",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}", validator: validate_DeleteDetector_601303,
    base: "/", url: url_DeleteDetector_601304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFilter_601331 = ref object of OpenApiRestCall_600426
proc url_UpdateFilter_601333(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateFilter_601332(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601334 = path.getOrDefault("filterName")
  valid_601334 = validateParameter(valid_601334, JString, required = true,
                                 default = nil)
  if valid_601334 != nil:
    section.add "filterName", valid_601334
  var valid_601335 = path.getOrDefault("detectorId")
  valid_601335 = validateParameter(valid_601335, JString, required = true,
                                 default = nil)
  if valid_601335 != nil:
    section.add "detectorId", valid_601335
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
  var valid_601336 = header.getOrDefault("X-Amz-Date")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Date", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Security-Token")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Security-Token", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Content-Sha256", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Algorithm")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Algorithm", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Signature")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Signature", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-SignedHeaders", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Credential")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Credential", valid_601342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601344: Call_UpdateFilter_601331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the filter specified by the filter name.
  ## 
  let valid = call_601344.validator(path, query, header, formData, body)
  let scheme = call_601344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601344.url(scheme.get, call_601344.host, call_601344.base,
                         call_601344.route, valid.getOrDefault("path"))
  result = hook(call_601344, url, valid)

proc call*(call_601345: Call_UpdateFilter_601331; filterName: string;
          detectorId: string; body: JsonNode): Recallable =
  ## updateFilter
  ## Updates the filter specified by the filter name.
  ##   filterName: string (required)
  ##             : The name of the filter.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector that specifies the GuardDuty service where you want to update a filter.
  ##   body: JObject (required)
  var path_601346 = newJObject()
  var body_601347 = newJObject()
  add(path_601346, "filterName", newJString(filterName))
  add(path_601346, "detectorId", newJString(detectorId))
  if body != nil:
    body_601347 = body
  result = call_601345.call(path_601346, nil, nil, nil, body_601347)

var updateFilter* = Call_UpdateFilter_601331(name: "updateFilter",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_UpdateFilter_601332, base: "/", url: url_UpdateFilter_601333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFilter_601316 = ref object of OpenApiRestCall_600426
proc url_GetFilter_601318(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetFilter_601317(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601319 = path.getOrDefault("filterName")
  valid_601319 = validateParameter(valid_601319, JString, required = true,
                                 default = nil)
  if valid_601319 != nil:
    section.add "filterName", valid_601319
  var valid_601320 = path.getOrDefault("detectorId")
  valid_601320 = validateParameter(valid_601320, JString, required = true,
                                 default = nil)
  if valid_601320 != nil:
    section.add "detectorId", valid_601320
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
  var valid_601321 = header.getOrDefault("X-Amz-Date")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-Date", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Security-Token")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Security-Token", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Content-Sha256", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Algorithm")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Algorithm", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Signature")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Signature", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-SignedHeaders", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Credential")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Credential", valid_601327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601328: Call_GetFilter_601316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details of the filter specified by the filter name.
  ## 
  let valid = call_601328.validator(path, query, header, formData, body)
  let scheme = call_601328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601328.url(scheme.get, call_601328.host, call_601328.base,
                         call_601328.route, valid.getOrDefault("path"))
  result = hook(call_601328, url, valid)

proc call*(call_601329: Call_GetFilter_601316; filterName: string; detectorId: string): Recallable =
  ## getFilter
  ## Returns the details of the filter specified by the filter name.
  ##   filterName: string (required)
  ##             : The name of the filter you want to get.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  var path_601330 = newJObject()
  add(path_601330, "filterName", newJString(filterName))
  add(path_601330, "detectorId", newJString(detectorId))
  result = call_601329.call(path_601330, nil, nil, nil, nil)

var getFilter* = Call_GetFilter_601316(name: "getFilter", meth: HttpMethod.HttpGet,
                                    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/filter/{filterName}",
                                    validator: validate_GetFilter_601317,
                                    base: "/", url: url_GetFilter_601318,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFilter_601348 = ref object of OpenApiRestCall_600426
proc url_DeleteFilter_601350(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteFilter_601349(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601351 = path.getOrDefault("filterName")
  valid_601351 = validateParameter(valid_601351, JString, required = true,
                                 default = nil)
  if valid_601351 != nil:
    section.add "filterName", valid_601351
  var valid_601352 = path.getOrDefault("detectorId")
  valid_601352 = validateParameter(valid_601352, JString, required = true,
                                 default = nil)
  if valid_601352 != nil:
    section.add "detectorId", valid_601352
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
  var valid_601353 = header.getOrDefault("X-Amz-Date")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Date", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Security-Token")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Security-Token", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Content-Sha256", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Algorithm")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Algorithm", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Signature")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Signature", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-SignedHeaders", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Credential")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Credential", valid_601359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601360: Call_DeleteFilter_601348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the filter specified by the filter name.
  ## 
  let valid = call_601360.validator(path, query, header, formData, body)
  let scheme = call_601360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601360.url(scheme.get, call_601360.host, call_601360.base,
                         call_601360.route, valid.getOrDefault("path"))
  result = hook(call_601360, url, valid)

proc call*(call_601361: Call_DeleteFilter_601348; filterName: string;
          detectorId: string): Recallable =
  ## deleteFilter
  ## Deletes the filter specified by the filter name.
  ##   filterName: string (required)
  ##             : The name of the filter you want to delete.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the filter is associated with.
  var path_601362 = newJObject()
  add(path_601362, "filterName", newJString(filterName))
  add(path_601362, "detectorId", newJString(detectorId))
  result = call_601361.call(path_601362, nil, nil, nil, nil)

var deleteFilter* = Call_DeleteFilter_601348(name: "deleteFilter",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/filter/{filterName}",
    validator: validate_DeleteFilter_601349, base: "/", url: url_DeleteFilter_601350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIPSet_601378 = ref object of OpenApiRestCall_600426
proc url_UpdateIPSet_601380(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateIPSet_601379(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601381 = path.getOrDefault("ipSetId")
  valid_601381 = validateParameter(valid_601381, JString, required = true,
                                 default = nil)
  if valid_601381 != nil:
    section.add "ipSetId", valid_601381
  var valid_601382 = path.getOrDefault("detectorId")
  valid_601382 = validateParameter(valid_601382, JString, required = true,
                                 default = nil)
  if valid_601382 != nil:
    section.add "detectorId", valid_601382
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
  var valid_601383 = header.getOrDefault("X-Amz-Date")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Date", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-Security-Token")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Security-Token", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Content-Sha256", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Algorithm")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Algorithm", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Signature")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Signature", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-SignedHeaders", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Credential")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Credential", valid_601389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601391: Call_UpdateIPSet_601378; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the IPSet specified by the IPSet ID.
  ## 
  let valid = call_601391.validator(path, query, header, formData, body)
  let scheme = call_601391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601391.url(scheme.get, call_601391.host, call_601391.base,
                         call_601391.route, valid.getOrDefault("path"))
  result = hook(call_601391, url, valid)

proc call*(call_601392: Call_UpdateIPSet_601378; ipSetId: string; detectorId: string;
          body: JsonNode): Recallable =
  ## updateIPSet
  ## Updates the IPSet specified by the IPSet ID.
  ##   ipSetId: string (required)
  ##          : The unique ID that specifies the IPSet that you want to update.
  ##   detectorId: string (required)
  ##             : The detectorID that specifies the GuardDuty service whose IPSet you want to update.
  ##   body: JObject (required)
  var path_601393 = newJObject()
  var body_601394 = newJObject()
  add(path_601393, "ipSetId", newJString(ipSetId))
  add(path_601393, "detectorId", newJString(detectorId))
  if body != nil:
    body_601394 = body
  result = call_601392.call(path_601393, nil, nil, nil, body_601394)

var updateIPSet* = Call_UpdateIPSet_601378(name: "updateIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                        validator: validate_UpdateIPSet_601379,
                                        base: "/", url: url_UpdateIPSet_601380,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIPSet_601363 = ref object of OpenApiRestCall_600426
proc url_GetIPSet_601365(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetIPSet_601364(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the IPSet specified by the IPSet ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ipSetId: JString (required)
  ##          : The unique ID of the ipSet you want to get.
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector the ipSet is associated with.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ipSetId` field"
  var valid_601366 = path.getOrDefault("ipSetId")
  valid_601366 = validateParameter(valid_601366, JString, required = true,
                                 default = nil)
  if valid_601366 != nil:
    section.add "ipSetId", valid_601366
  var valid_601367 = path.getOrDefault("detectorId")
  valid_601367 = validateParameter(valid_601367, JString, required = true,
                                 default = nil)
  if valid_601367 != nil:
    section.add "detectorId", valid_601367
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
  var valid_601368 = header.getOrDefault("X-Amz-Date")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Date", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Security-Token")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Security-Token", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Content-Sha256", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Algorithm")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Algorithm", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Signature")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Signature", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-SignedHeaders", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Credential")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Credential", valid_601374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601375: Call_GetIPSet_601363; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the IPSet specified by the IPSet ID.
  ## 
  let valid = call_601375.validator(path, query, header, formData, body)
  let scheme = call_601375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601375.url(scheme.get, call_601375.host, call_601375.base,
                         call_601375.route, valid.getOrDefault("path"))
  result = hook(call_601375, url, valid)

proc call*(call_601376: Call_GetIPSet_601363; ipSetId: string; detectorId: string): Recallable =
  ## getIPSet
  ## Retrieves the IPSet specified by the IPSet ID.
  ##   ipSetId: string (required)
  ##          : The unique ID of the ipSet you want to get.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the ipSet is associated with.
  var path_601377 = newJObject()
  add(path_601377, "ipSetId", newJString(ipSetId))
  add(path_601377, "detectorId", newJString(detectorId))
  result = call_601376.call(path_601377, nil, nil, nil, nil)

var getIPSet* = Call_GetIPSet_601363(name: "getIPSet", meth: HttpMethod.HttpGet,
                                  host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                  validator: validate_GetIPSet_601364, base: "/",
                                  url: url_GetIPSet_601365,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIPSet_601395 = ref object of OpenApiRestCall_600426
proc url_DeleteIPSet_601397(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteIPSet_601396(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the IPSet specified by the IPSet ID.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ipSetId: JString (required)
  ##          : The unique ID of the ipSet you want to delete.
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector the ipSet is associated with.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ipSetId` field"
  var valid_601398 = path.getOrDefault("ipSetId")
  valid_601398 = validateParameter(valid_601398, JString, required = true,
                                 default = nil)
  if valid_601398 != nil:
    section.add "ipSetId", valid_601398
  var valid_601399 = path.getOrDefault("detectorId")
  valid_601399 = validateParameter(valid_601399, JString, required = true,
                                 default = nil)
  if valid_601399 != nil:
    section.add "detectorId", valid_601399
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
  var valid_601400 = header.getOrDefault("X-Amz-Date")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Date", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Security-Token")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Security-Token", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Content-Sha256", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Algorithm")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Algorithm", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Signature")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Signature", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-SignedHeaders", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Credential")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Credential", valid_601406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601407: Call_DeleteIPSet_601395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the IPSet specified by the IPSet ID.
  ## 
  let valid = call_601407.validator(path, query, header, formData, body)
  let scheme = call_601407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601407.url(scheme.get, call_601407.host, call_601407.base,
                         call_601407.route, valid.getOrDefault("path"))
  result = hook(call_601407, url, valid)

proc call*(call_601408: Call_DeleteIPSet_601395; ipSetId: string; detectorId: string): Recallable =
  ## deleteIPSet
  ## Deletes the IPSet specified by the IPSet ID.
  ##   ipSetId: string (required)
  ##          : The unique ID of the ipSet you want to delete.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the ipSet is associated with.
  var path_601409 = newJObject()
  add(path_601409, "ipSetId", newJString(ipSetId))
  add(path_601409, "detectorId", newJString(detectorId))
  result = call_601408.call(path_601409, nil, nil, nil, nil)

var deleteIPSet* = Call_DeleteIPSet_601395(name: "deleteIPSet",
                                        meth: HttpMethod.HttpDelete,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/ipset/{ipSetId}",
                                        validator: validate_DeleteIPSet_601396,
                                        base: "/", url: url_DeleteIPSet_601397,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_601410 = ref object of OpenApiRestCall_600426
proc url_DeleteInvitations_601412(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteInvitations_601411(path: JsonNode; query: JsonNode;
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
  var valid_601413 = header.getOrDefault("X-Amz-Date")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Date", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Security-Token")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Security-Token", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Content-Sha256", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Algorithm")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Algorithm", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Signature")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Signature", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-SignedHeaders", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Credential")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Credential", valid_601419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601421: Call_DeleteInvitations_601410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
  ## 
  let valid = call_601421.validator(path, query, header, formData, body)
  let scheme = call_601421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601421.url(scheme.get, call_601421.host, call_601421.base,
                         call_601421.route, valid.getOrDefault("path"))
  result = hook(call_601421, url, valid)

proc call*(call_601422: Call_DeleteInvitations_601410; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations sent to the current member account by AWS accounts specified by their account IDs.
  ##   body: JObject (required)
  var body_601423 = newJObject()
  if body != nil:
    body_601423 = body
  result = call_601422.call(nil, nil, nil, nil, body_601423)

var deleteInvitations* = Call_DeleteInvitations_601410(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/invitation/delete", validator: validate_DeleteInvitations_601411,
    base: "/", url: url_DeleteInvitations_601412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_601424 = ref object of OpenApiRestCall_600426
proc url_DeleteMembers_601426(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/member/delete")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteMembers_601425(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601427 = path.getOrDefault("detectorId")
  valid_601427 = validateParameter(valid_601427, JString, required = true,
                                 default = nil)
  if valid_601427 != nil:
    section.add "detectorId", valid_601427
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
  var valid_601428 = header.getOrDefault("X-Amz-Date")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Date", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Security-Token")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Security-Token", valid_601429
  var valid_601430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Content-Sha256", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-Algorithm")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Algorithm", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-Signature")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Signature", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-SignedHeaders", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Credential")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Credential", valid_601434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601436: Call_DeleteMembers_601424; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_601436.validator(path, query, header, formData, body)
  let scheme = call_601436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601436.url(scheme.get, call_601436.host, call_601436.base,
                         call_601436.route, valid.getOrDefault("path"))
  result = hook(call_601436, url, valid)

proc call*(call_601437: Call_DeleteMembers_601424; detectorId: string; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to delete.
  ##   body: JObject (required)
  var path_601438 = newJObject()
  var body_601439 = newJObject()
  add(path_601438, "detectorId", newJString(detectorId))
  if body != nil:
    body_601439 = body
  result = call_601437.call(path_601438, nil, nil, nil, body_601439)

var deleteMembers* = Call_DeleteMembers_601424(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/delete",
    validator: validate_DeleteMembers_601425, base: "/", url: url_DeleteMembers_601426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateThreatIntelSet_601455 = ref object of OpenApiRestCall_600426
proc url_UpdateThreatIntelSet_601457(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateThreatIntelSet_601456(path: JsonNode; query: JsonNode;
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
  var valid_601458 = path.getOrDefault("detectorId")
  valid_601458 = validateParameter(valid_601458, JString, required = true,
                                 default = nil)
  if valid_601458 != nil:
    section.add "detectorId", valid_601458
  var valid_601459 = path.getOrDefault("threatIntelSetId")
  valid_601459 = validateParameter(valid_601459, JString, required = true,
                                 default = nil)
  if valid_601459 != nil:
    section.add "threatIntelSetId", valid_601459
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
  var valid_601460 = header.getOrDefault("X-Amz-Date")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Date", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Security-Token")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Security-Token", valid_601461
  var valid_601462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-Content-Sha256", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Algorithm")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Algorithm", valid_601463
  var valid_601464 = header.getOrDefault("X-Amz-Signature")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-Signature", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-SignedHeaders", valid_601465
  var valid_601466 = header.getOrDefault("X-Amz-Credential")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Credential", valid_601466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601468: Call_UpdateThreatIntelSet_601455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ## 
  let valid = call_601468.validator(path, query, header, formData, body)
  let scheme = call_601468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601468.url(scheme.get, call_601468.host, call_601468.base,
                         call_601468.route, valid.getOrDefault("path"))
  result = hook(call_601468, url, valid)

proc call*(call_601469: Call_UpdateThreatIntelSet_601455; detectorId: string;
          threatIntelSetId: string; body: JsonNode): Recallable =
  ## updateThreatIntelSet
  ## Updates the ThreatIntelSet specified by ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The detectorID that specifies the GuardDuty service whose ThreatIntelSet you want to update.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID that specifies the ThreatIntelSet that you want to update.
  ##   body: JObject (required)
  var path_601470 = newJObject()
  var body_601471 = newJObject()
  add(path_601470, "detectorId", newJString(detectorId))
  add(path_601470, "threatIntelSetId", newJString(threatIntelSetId))
  if body != nil:
    body_601471 = body
  result = call_601469.call(path_601470, nil, nil, nil, body_601471)

var updateThreatIntelSet* = Call_UpdateThreatIntelSet_601455(
    name: "updateThreatIntelSet", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_UpdateThreatIntelSet_601456, base: "/",
    url: url_UpdateThreatIntelSet_601457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetThreatIntelSet_601440 = ref object of OpenApiRestCall_600426
proc url_GetThreatIntelSet_601442(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetThreatIntelSet_601441(path: JsonNode; query: JsonNode;
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
  var valid_601443 = path.getOrDefault("detectorId")
  valid_601443 = validateParameter(valid_601443, JString, required = true,
                                 default = nil)
  if valid_601443 != nil:
    section.add "detectorId", valid_601443
  var valid_601444 = path.getOrDefault("threatIntelSetId")
  valid_601444 = validateParameter(valid_601444, JString, required = true,
                                 default = nil)
  if valid_601444 != nil:
    section.add "threatIntelSetId", valid_601444
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
  var valid_601445 = header.getOrDefault("X-Amz-Date")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-Date", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-Security-Token")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-Security-Token", valid_601446
  var valid_601447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "X-Amz-Content-Sha256", valid_601447
  var valid_601448 = header.getOrDefault("X-Amz-Algorithm")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Algorithm", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-Signature")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Signature", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-SignedHeaders", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-Credential")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Credential", valid_601451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601452: Call_GetThreatIntelSet_601440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ## 
  let valid = call_601452.validator(path, query, header, formData, body)
  let scheme = call_601452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601452.url(scheme.get, call_601452.host, call_601452.base,
                         call_601452.route, valid.getOrDefault("path"))
  result = hook(call_601452, url, valid)

proc call*(call_601453: Call_GetThreatIntelSet_601440; detectorId: string;
          threatIntelSetId: string): Recallable =
  ## getThreatIntelSet
  ## Retrieves the ThreatIntelSet that is specified by the ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID of the threatIntelSet you want to get.
  var path_601454 = newJObject()
  add(path_601454, "detectorId", newJString(detectorId))
  add(path_601454, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_601453.call(path_601454, nil, nil, nil, nil)

var getThreatIntelSet* = Call_GetThreatIntelSet_601440(name: "getThreatIntelSet",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_GetThreatIntelSet_601441, base: "/",
    url: url_GetThreatIntelSet_601442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteThreatIntelSet_601472 = ref object of OpenApiRestCall_600426
proc url_DeleteThreatIntelSet_601474(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteThreatIntelSet_601473(path: JsonNode; query: JsonNode;
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
  var valid_601475 = path.getOrDefault("detectorId")
  valid_601475 = validateParameter(valid_601475, JString, required = true,
                                 default = nil)
  if valid_601475 != nil:
    section.add "detectorId", valid_601475
  var valid_601476 = path.getOrDefault("threatIntelSetId")
  valid_601476 = validateParameter(valid_601476, JString, required = true,
                                 default = nil)
  if valid_601476 != nil:
    section.add "threatIntelSetId", valid_601476
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
  var valid_601477 = header.getOrDefault("X-Amz-Date")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Date", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Security-Token")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Security-Token", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Content-Sha256", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Algorithm")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Algorithm", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Signature")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Signature", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-SignedHeaders", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Credential")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Credential", valid_601483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601484: Call_DeleteThreatIntelSet_601472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ## 
  let valid = call_601484.validator(path, query, header, formData, body)
  let scheme = call_601484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601484.url(scheme.get, call_601484.host, call_601484.base,
                         call_601484.route, valid.getOrDefault("path"))
  result = hook(call_601484, url, valid)

proc call*(call_601485: Call_DeleteThreatIntelSet_601472; detectorId: string;
          threatIntelSetId: string): Recallable =
  ## deleteThreatIntelSet
  ## Deletes ThreatIntelSet specified by the ThreatIntelSet ID.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector the threatIntelSet is associated with.
  ##   threatIntelSetId: string (required)
  ##                   : The unique ID of the threatIntelSet you want to delete.
  var path_601486 = newJObject()
  add(path_601486, "detectorId", newJString(detectorId))
  add(path_601486, "threatIntelSetId", newJString(threatIntelSetId))
  result = call_601485.call(path_601486, nil, nil, nil, nil)

var deleteThreatIntelSet* = Call_DeleteThreatIntelSet_601472(
    name: "deleteThreatIntelSet", meth: HttpMethod.HttpDelete,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/threatintelset/{threatIntelSetId}",
    validator: validate_DeleteThreatIntelSet_601473, base: "/",
    url: url_DeleteThreatIntelSet_601474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_601487 = ref object of OpenApiRestCall_600426
proc url_DisassociateFromMasterAccount_601489(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/master/disassociate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DisassociateFromMasterAccount_601488(path: JsonNode; query: JsonNode;
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
  var valid_601490 = path.getOrDefault("detectorId")
  valid_601490 = validateParameter(valid_601490, JString, required = true,
                                 default = nil)
  if valid_601490 != nil:
    section.add "detectorId", valid_601490
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
  var valid_601491 = header.getOrDefault("X-Amz-Date")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-Date", valid_601491
  var valid_601492 = header.getOrDefault("X-Amz-Security-Token")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Security-Token", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Content-Sha256", valid_601493
  var valid_601494 = header.getOrDefault("X-Amz-Algorithm")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-Algorithm", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Signature")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Signature", valid_601495
  var valid_601496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-SignedHeaders", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Credential")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Credential", valid_601497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601498: Call_DisassociateFromMasterAccount_601487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current GuardDuty member account from its master account.
  ## 
  let valid = call_601498.validator(path, query, header, formData, body)
  let scheme = call_601498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601498.url(scheme.get, call_601498.host, call_601498.base,
                         call_601498.route, valid.getOrDefault("path"))
  result = hook(call_601498, url, valid)

proc call*(call_601499: Call_DisassociateFromMasterAccount_601487;
          detectorId: string): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current GuardDuty member account from its master account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty member account.
  var path_601500 = newJObject()
  add(path_601500, "detectorId", newJString(detectorId))
  result = call_601499.call(path_601500, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_601487(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_601488, base: "/",
    url: url_DisassociateFromMasterAccount_601489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_601501 = ref object of OpenApiRestCall_600426
proc url_DisassociateMembers_601503(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/member/disassociate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DisassociateMembers_601502(path: JsonNode; query: JsonNode;
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
  var valid_601504 = path.getOrDefault("detectorId")
  valid_601504 = validateParameter(valid_601504, JString, required = true,
                                 default = nil)
  if valid_601504 != nil:
    section.add "detectorId", valid_601504
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
  var valid_601505 = header.getOrDefault("X-Amz-Date")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-Date", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-Security-Token")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Security-Token", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-Content-Sha256", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-Algorithm")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Algorithm", valid_601508
  var valid_601509 = header.getOrDefault("X-Amz-Signature")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-Signature", valid_601509
  var valid_601510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "X-Amz-SignedHeaders", valid_601510
  var valid_601511 = header.getOrDefault("X-Amz-Credential")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-Credential", valid_601511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601513: Call_DisassociateMembers_601501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_601513.validator(path, query, header, formData, body)
  let scheme = call_601513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601513.url(scheme.get, call_601513.host, call_601513.base,
                         call_601513.route, valid.getOrDefault("path"))
  result = hook(call_601513, url, valid)

proc call*(call_601514: Call_DisassociateMembers_601501; detectorId: string;
          body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to disassociate from master.
  ##   body: JObject (required)
  var path_601515 = newJObject()
  var body_601516 = newJObject()
  add(path_601515, "detectorId", newJString(detectorId))
  if body != nil:
    body_601516 = body
  result = call_601514.call(path_601515, nil, nil, nil, body_601516)

var disassociateMembers* = Call_DisassociateMembers_601501(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/disassociate",
    validator: validate_DisassociateMembers_601502, base: "/",
    url: url_DisassociateMembers_601503, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_601517 = ref object of OpenApiRestCall_600426
proc url_GetFindings_601519(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/findings/get")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetFindings_601518(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601520 = path.getOrDefault("detectorId")
  valid_601520 = validateParameter(valid_601520, JString, required = true,
                                 default = nil)
  if valid_601520 != nil:
    section.add "detectorId", valid_601520
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
  var valid_601521 = header.getOrDefault("X-Amz-Date")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Date", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Security-Token")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Security-Token", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Content-Sha256", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-Algorithm")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-Algorithm", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Signature")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Signature", valid_601525
  var valid_601526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-SignedHeaders", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Credential")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Credential", valid_601527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601529: Call_GetFindings_601517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes Amazon GuardDuty findings specified by finding IDs.
  ## 
  let valid = call_601529.validator(path, query, header, formData, body)
  let scheme = call_601529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601529.url(scheme.get, call_601529.host, call_601529.base,
                         call_601529.route, valid.getOrDefault("path"))
  result = hook(call_601529, url, valid)

proc call*(call_601530: Call_GetFindings_601517; detectorId: string; body: JsonNode): Recallable =
  ## getFindings
  ## Describes Amazon GuardDuty findings specified by finding IDs.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to retrieve.
  ##   body: JObject (required)
  var path_601531 = newJObject()
  var body_601532 = newJObject()
  add(path_601531, "detectorId", newJString(detectorId))
  if body != nil:
    body_601532 = body
  result = call_601530.call(path_601531, nil, nil, nil, body_601532)

var getFindings* = Call_GetFindings_601517(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/findings/get",
                                        validator: validate_GetFindings_601518,
                                        base: "/", url: url_GetFindings_601519,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindingsStatistics_601533 = ref object of OpenApiRestCall_600426
proc url_GetFindingsStatistics_601535(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/findings/statistics")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetFindingsStatistics_601534(path: JsonNode; query: JsonNode;
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
  var valid_601536 = path.getOrDefault("detectorId")
  valid_601536 = validateParameter(valid_601536, JString, required = true,
                                 default = nil)
  if valid_601536 != nil:
    section.add "detectorId", valid_601536
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
  var valid_601537 = header.getOrDefault("X-Amz-Date")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Date", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Security-Token")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Security-Token", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Content-Sha256", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Algorithm")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Algorithm", valid_601540
  var valid_601541 = header.getOrDefault("X-Amz-Signature")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Signature", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-SignedHeaders", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Credential")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Credential", valid_601543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601545: Call_GetFindingsStatistics_601533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
  ## 
  let valid = call_601545.validator(path, query, header, formData, body)
  let scheme = call_601545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601545.url(scheme.get, call_601545.host, call_601545.base,
                         call_601545.route, valid.getOrDefault("path"))
  result = hook(call_601545, url, valid)

proc call*(call_601546: Call_GetFindingsStatistics_601533; detectorId: string;
          body: JsonNode): Recallable =
  ## getFindingsStatistics
  ## Lists Amazon GuardDuty findings' statistics for the specified detector ID.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings' statistics you want to retrieve.
  ##   body: JObject (required)
  var path_601547 = newJObject()
  var body_601548 = newJObject()
  add(path_601547, "detectorId", newJString(detectorId))
  if body != nil:
    body_601548 = body
  result = call_601546.call(path_601547, nil, nil, nil, body_601548)

var getFindingsStatistics* = Call_GetFindingsStatistics_601533(
    name: "getFindingsStatistics", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/statistics",
    validator: validate_GetFindingsStatistics_601534, base: "/",
    url: url_GetFindingsStatistics_601535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_601549 = ref object of OpenApiRestCall_600426
proc url_GetInvitationsCount_601551(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetInvitationsCount_601550(path: JsonNode; query: JsonNode;
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
  var valid_601552 = header.getOrDefault("X-Amz-Date")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Date", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Security-Token")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Security-Token", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-Content-Sha256", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Algorithm")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Algorithm", valid_601555
  var valid_601556 = header.getOrDefault("X-Amz-Signature")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Signature", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-SignedHeaders", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Credential")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Credential", valid_601558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601559: Call_GetInvitationsCount_601549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
  ## 
  let valid = call_601559.validator(path, query, header, formData, body)
  let scheme = call_601559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601559.url(scheme.get, call_601559.host, call_601559.base,
                         call_601559.route, valid.getOrDefault("path"))
  result = hook(call_601559, url, valid)

proc call*(call_601560: Call_GetInvitationsCount_601549): Recallable =
  ## getInvitationsCount
  ## Returns the count of all GuardDuty membership invitations that were sent to the current member account except the currently accepted invitation.
  result = call_601560.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_601549(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/invitation/count",
    validator: validate_GetInvitationsCount_601550, base: "/",
    url: url_GetInvitationsCount_601551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_601561 = ref object of OpenApiRestCall_600426
proc url_GetMembers_601563(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/member/get")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetMembers_601562(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601564 = path.getOrDefault("detectorId")
  valid_601564 = validateParameter(valid_601564, JString, required = true,
                                 default = nil)
  if valid_601564 != nil:
    section.add "detectorId", valid_601564
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
  var valid_601565 = header.getOrDefault("X-Amz-Date")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Date", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Security-Token")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Security-Token", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Content-Sha256", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-Algorithm")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Algorithm", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-Signature")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-Signature", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-SignedHeaders", valid_601570
  var valid_601571 = header.getOrDefault("X-Amz-Credential")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-Credential", valid_601571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601573: Call_GetMembers_601561; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ## 
  let valid = call_601573.validator(path, query, header, formData, body)
  let scheme = call_601573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601573.url(scheme.get, call_601573.host, call_601573.base,
                         call_601573.route, valid.getOrDefault("path"))
  result = hook(call_601573, url, valid)

proc call*(call_601574: Call_GetMembers_601561; detectorId: string; body: JsonNode): Recallable =
  ## getMembers
  ## Retrieves GuardDuty member accounts (to the current GuardDuty master account) specified by the account IDs.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whose members you want to retrieve.
  ##   body: JObject (required)
  var path_601575 = newJObject()
  var body_601576 = newJObject()
  add(path_601575, "detectorId", newJString(detectorId))
  if body != nil:
    body_601576 = body
  result = call_601574.call(path_601575, nil, nil, nil, body_601576)

var getMembers* = Call_GetMembers_601561(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/get",
                                      validator: validate_GetMembers_601562,
                                      base: "/", url: url_GetMembers_601563,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_601577 = ref object of OpenApiRestCall_600426
proc url_InviteMembers_601579(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/member/invite")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_InviteMembers_601578(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601580 = path.getOrDefault("detectorId")
  valid_601580 = validateParameter(valid_601580, JString, required = true,
                                 default = nil)
  if valid_601580 != nil:
    section.add "detectorId", valid_601580
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
  var valid_601581 = header.getOrDefault("X-Amz-Date")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Date", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Security-Token")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Security-Token", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Content-Sha256", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-Algorithm")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Algorithm", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-Signature")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Signature", valid_601585
  var valid_601586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-SignedHeaders", valid_601586
  var valid_601587 = header.getOrDefault("X-Amz-Credential")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Credential", valid_601587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601589: Call_InviteMembers_601577; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
  ## 
  let valid = call_601589.validator(path, query, header, formData, body)
  let scheme = call_601589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601589.url(scheme.get, call_601589.host, call_601589.base,
                         call_601589.route, valid.getOrDefault("path"))
  result = hook(call_601589, url, valid)

proc call*(call_601590: Call_InviteMembers_601577; detectorId: string; body: JsonNode): Recallable =
  ## inviteMembers
  ## Invites other AWS accounts (created as members of the current AWS account by CreateMembers) to enable GuardDuty and allow the current AWS account to view and manage these accounts' GuardDuty findings on their behalf as the master account.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account with which you want to invite members.
  ##   body: JObject (required)
  var path_601591 = newJObject()
  var body_601592 = newJObject()
  add(path_601591, "detectorId", newJString(detectorId))
  if body != nil:
    body_601592 = body
  result = call_601590.call(path_601591, nil, nil, nil, body_601592)

var inviteMembers* = Call_InviteMembers_601577(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/member/invite",
    validator: validate_InviteMembers_601578, base: "/", url: url_InviteMembers_601579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFindings_601593 = ref object of OpenApiRestCall_600426
proc url_ListFindings_601595(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/findings")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListFindings_601594(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601596 = path.getOrDefault("detectorId")
  valid_601596 = validateParameter(valid_601596, JString, required = true,
                                 default = nil)
  if valid_601596 != nil:
    section.add "detectorId", valid_601596
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601597 = query.getOrDefault("NextToken")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "NextToken", valid_601597
  var valid_601598 = query.getOrDefault("MaxResults")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "MaxResults", valid_601598
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
  var valid_601599 = header.getOrDefault("X-Amz-Date")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-Date", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-Security-Token")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-Security-Token", valid_601600
  var valid_601601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "X-Amz-Content-Sha256", valid_601601
  var valid_601602 = header.getOrDefault("X-Amz-Algorithm")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-Algorithm", valid_601602
  var valid_601603 = header.getOrDefault("X-Amz-Signature")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Signature", valid_601603
  var valid_601604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = nil)
  if valid_601604 != nil:
    section.add "X-Amz-SignedHeaders", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-Credential")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Credential", valid_601605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601607: Call_ListFindings_601593; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists Amazon GuardDuty findings for the specified detector ID.
  ## 
  let valid = call_601607.validator(path, query, header, formData, body)
  let scheme = call_601607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601607.url(scheme.get, call_601607.host, call_601607.base,
                         call_601607.route, valid.getOrDefault("path"))
  result = hook(call_601607, url, valid)

proc call*(call_601608: Call_ListFindings_601593; detectorId: string; body: JsonNode;
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
  var path_601609 = newJObject()
  var query_601610 = newJObject()
  var body_601611 = newJObject()
  add(query_601610, "NextToken", newJString(NextToken))
  add(path_601609, "detectorId", newJString(detectorId))
  if body != nil:
    body_601611 = body
  add(query_601610, "MaxResults", newJString(MaxResults))
  result = call_601608.call(path_601609, query_601610, nil, nil, body_601611)

var listFindings* = Call_ListFindings_601593(name: "listFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings", validator: validate_ListFindings_601594,
    base: "/", url: url_ListFindings_601595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_601612 = ref object of OpenApiRestCall_600426
proc url_ListInvitations_601614(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInvitations_601613(path: JsonNode; query: JsonNode;
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
  var valid_601615 = query.getOrDefault("NextToken")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "NextToken", valid_601615
  var valid_601616 = query.getOrDefault("maxResults")
  valid_601616 = validateParameter(valid_601616, JInt, required = false, default = nil)
  if valid_601616 != nil:
    section.add "maxResults", valid_601616
  var valid_601617 = query.getOrDefault("nextToken")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "nextToken", valid_601617
  var valid_601618 = query.getOrDefault("MaxResults")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "MaxResults", valid_601618
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
  var valid_601619 = header.getOrDefault("X-Amz-Date")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "X-Amz-Date", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-Security-Token")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Security-Token", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Content-Sha256", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-Algorithm")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Algorithm", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-Signature")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Signature", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-SignedHeaders", valid_601624
  var valid_601625 = header.getOrDefault("X-Amz-Credential")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-Credential", valid_601625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601626: Call_ListInvitations_601612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all GuardDuty membership invitations that were sent to the current AWS account.
  ## 
  let valid = call_601626.validator(path, query, header, formData, body)
  let scheme = call_601626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601626.url(scheme.get, call_601626.host, call_601626.base,
                         call_601626.route, valid.getOrDefault("path"))
  result = hook(call_601626, url, valid)

proc call*(call_601627: Call_ListInvitations_601612; NextToken: string = "";
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
  var query_601628 = newJObject()
  add(query_601628, "NextToken", newJString(NextToken))
  add(query_601628, "maxResults", newJInt(maxResults))
  add(query_601628, "nextToken", newJString(nextToken))
  add(query_601628, "MaxResults", newJString(MaxResults))
  result = call_601627.call(nil, query_601628, nil, nil, nil)

var listInvitations* = Call_ListInvitations_601612(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "guardduty.amazonaws.com", route: "/invitation",
    validator: validate_ListInvitations_601613, base: "/", url: url_ListInvitations_601614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601643 = ref object of OpenApiRestCall_600426
proc url_TagResource_601645(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TagResource_601644(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds tags to a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) for the given GuardDuty resource 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_601646 = path.getOrDefault("resourceArn")
  valid_601646 = validateParameter(valid_601646, JString, required = true,
                                 default = nil)
  if valid_601646 != nil:
    section.add "resourceArn", valid_601646
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
  var valid_601647 = header.getOrDefault("X-Amz-Date")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Date", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Security-Token")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Security-Token", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Content-Sha256", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Algorithm")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Algorithm", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Signature")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Signature", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-SignedHeaders", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Credential")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Credential", valid_601653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601655: Call_TagResource_601643; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to a resource.
  ## 
  let valid = call_601655.validator(path, query, header, formData, body)
  let scheme = call_601655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601655.url(scheme.get, call_601655.host, call_601655.base,
                         call_601655.route, valid.getOrDefault("path"))
  result = hook(call_601655, url, valid)

proc call*(call_601656: Call_TagResource_601643; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Adds tags to a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the given GuardDuty resource 
  var path_601657 = newJObject()
  var body_601658 = newJObject()
  if body != nil:
    body_601658 = body
  add(path_601657, "resourceArn", newJString(resourceArn))
  result = call_601656.call(path_601657, nil, nil, nil, body_601658)

var tagResource* = Call_TagResource_601643(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "guardduty.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_601644,
                                        base: "/", url: url_TagResource_601645,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601629 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601631(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTagsForResource_601630(path: JsonNode; query: JsonNode;
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
  var valid_601632 = path.getOrDefault("resourceArn")
  valid_601632 = validateParameter(valid_601632, JString, required = true,
                                 default = nil)
  if valid_601632 != nil:
    section.add "resourceArn", valid_601632
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
  var valid_601633 = header.getOrDefault("X-Amz-Date")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Date", valid_601633
  var valid_601634 = header.getOrDefault("X-Amz-Security-Token")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "X-Amz-Security-Token", valid_601634
  var valid_601635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-Content-Sha256", valid_601635
  var valid_601636 = header.getOrDefault("X-Amz-Algorithm")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Algorithm", valid_601636
  var valid_601637 = header.getOrDefault("X-Amz-Signature")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-Signature", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-SignedHeaders", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Credential")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Credential", valid_601639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601640: Call_ListTagsForResource_601629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
  ## 
  let valid = call_601640.validator(path, query, header, formData, body)
  let scheme = call_601640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601640.url(scheme.get, call_601640.host, call_601640.base,
                         call_601640.route, valid.getOrDefault("path"))
  result = hook(call_601640, url, valid)

proc call*(call_601641: Call_ListTagsForResource_601629; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists tags for a resource. Tagging is currently supported for detectors, finding filters, IP sets, and Threat Intel sets, with a limit of 50 tags per resource. When invoked, this operation returns all assigned tags for a given resource..
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the given GuardDuty resource 
  var path_601642 = newJObject()
  add(path_601642, "resourceArn", newJString(resourceArn))
  result = call_601641.call(path_601642, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_601629(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "guardduty.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_601630, base: "/",
    url: url_ListTagsForResource_601631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMonitoringMembers_601659 = ref object of OpenApiRestCall_600426
proc url_StartMonitoringMembers_601661(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/member/start")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_StartMonitoringMembers_601660(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Re-enables GuardDuty to monitor findings of the member accounts specified by the account IDs. A master GuardDuty account can run this command after disabling GuardDuty from monitoring these members' findings by running StopMonitoringMembers.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector of the GuardDuty account whom you want to re-enable to monitor members' findings.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_601662 = path.getOrDefault("detectorId")
  valid_601662 = validateParameter(valid_601662, JString, required = true,
                                 default = nil)
  if valid_601662 != nil:
    section.add "detectorId", valid_601662
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
  var valid_601663 = header.getOrDefault("X-Amz-Date")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Date", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-Security-Token")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Security-Token", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Content-Sha256", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Algorithm")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Algorithm", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-Signature")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-Signature", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-SignedHeaders", valid_601668
  var valid_601669 = header.getOrDefault("X-Amz-Credential")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-Credential", valid_601669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601671: Call_StartMonitoringMembers_601659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Re-enables GuardDuty to monitor findings of the member accounts specified by the account IDs. A master GuardDuty account can run this command after disabling GuardDuty from monitoring these members' findings by running StopMonitoringMembers.
  ## 
  let valid = call_601671.validator(path, query, header, formData, body)
  let scheme = call_601671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601671.url(scheme.get, call_601671.host, call_601671.base,
                         call_601671.route, valid.getOrDefault("path"))
  result = hook(call_601671, url, valid)

proc call*(call_601672: Call_StartMonitoringMembers_601659; detectorId: string;
          body: JsonNode): Recallable =
  ## startMonitoringMembers
  ## Re-enables GuardDuty to monitor findings of the member accounts specified by the account IDs. A master GuardDuty account can run this command after disabling GuardDuty from monitoring these members' findings by running StopMonitoringMembers.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account whom you want to re-enable to monitor members' findings.
  ##   body: JObject (required)
  var path_601673 = newJObject()
  var body_601674 = newJObject()
  add(path_601673, "detectorId", newJString(detectorId))
  if body != nil:
    body_601674 = body
  result = call_601672.call(path_601673, nil, nil, nil, body_601674)

var startMonitoringMembers* = Call_StartMonitoringMembers_601659(
    name: "startMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/start",
    validator: validate_StartMonitoringMembers_601660, base: "/",
    url: url_StartMonitoringMembers_601661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMonitoringMembers_601675 = ref object of OpenApiRestCall_600426
proc url_StopMonitoringMembers_601677(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/member/stop")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_StopMonitoringMembers_601676(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables GuardDuty from monitoring findings of the member accounts specified by the account IDs. After running this command, a master GuardDuty account can run StartMonitoringMembers to re-enable GuardDuty to monitor these members’ findings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The unique ID of the detector of the GuardDuty account that you want to stop from monitor members' findings.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_601678 = path.getOrDefault("detectorId")
  valid_601678 = validateParameter(valid_601678, JString, required = true,
                                 default = nil)
  if valid_601678 != nil:
    section.add "detectorId", valid_601678
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
  var valid_601679 = header.getOrDefault("X-Amz-Date")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "X-Amz-Date", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-Security-Token")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Security-Token", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Content-Sha256", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-Algorithm")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Algorithm", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Signature")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Signature", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-SignedHeaders", valid_601684
  var valid_601685 = header.getOrDefault("X-Amz-Credential")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "X-Amz-Credential", valid_601685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601687: Call_StopMonitoringMembers_601675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables GuardDuty from monitoring findings of the member accounts specified by the account IDs. After running this command, a master GuardDuty account can run StartMonitoringMembers to re-enable GuardDuty to monitor these members’ findings.
  ## 
  let valid = call_601687.validator(path, query, header, formData, body)
  let scheme = call_601687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601687.url(scheme.get, call_601687.host, call_601687.base,
                         call_601687.route, valid.getOrDefault("path"))
  result = hook(call_601687, url, valid)

proc call*(call_601688: Call_StopMonitoringMembers_601675; detectorId: string;
          body: JsonNode): Recallable =
  ## stopMonitoringMembers
  ## Disables GuardDuty from monitoring findings of the member accounts specified by the account IDs. After running this command, a master GuardDuty account can run StartMonitoringMembers to re-enable GuardDuty to monitor these members’ findings.
  ##   detectorId: string (required)
  ##             : The unique ID of the detector of the GuardDuty account that you want to stop from monitor members' findings.
  ##   body: JObject (required)
  var path_601689 = newJObject()
  var body_601690 = newJObject()
  add(path_601689, "detectorId", newJString(detectorId))
  if body != nil:
    body_601690 = body
  result = call_601688.call(path_601689, nil, nil, nil, body_601690)

var stopMonitoringMembers* = Call_StopMonitoringMembers_601675(
    name: "stopMonitoringMembers", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com", route: "/detector/{detectorId}/member/stop",
    validator: validate_StopMonitoringMembers_601676, base: "/",
    url: url_StopMonitoringMembers_601677, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UnarchiveFindings_601691 = ref object of OpenApiRestCall_600426
proc url_UnarchiveFindings_601693(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/findings/unarchive")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UnarchiveFindings_601692(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Unarchives Amazon GuardDuty findings specified by the list of finding IDs.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to unarchive.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_601694 = path.getOrDefault("detectorId")
  valid_601694 = validateParameter(valid_601694, JString, required = true,
                                 default = nil)
  if valid_601694 != nil:
    section.add "detectorId", valid_601694
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
  var valid_601695 = header.getOrDefault("X-Amz-Date")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Date", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-Security-Token")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Security-Token", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Content-Sha256", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-Algorithm")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Algorithm", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Signature")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Signature", valid_601699
  var valid_601700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "X-Amz-SignedHeaders", valid_601700
  var valid_601701 = header.getOrDefault("X-Amz-Credential")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-Credential", valid_601701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601703: Call_UnarchiveFindings_601691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Unarchives Amazon GuardDuty findings specified by the list of finding IDs.
  ## 
  let valid = call_601703.validator(path, query, header, formData, body)
  let scheme = call_601703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601703.url(scheme.get, call_601703.host, call_601703.base,
                         call_601703.route, valid.getOrDefault("path"))
  result = hook(call_601703, url, valid)

proc call*(call_601704: Call_UnarchiveFindings_601691; detectorId: string;
          body: JsonNode): Recallable =
  ## unarchiveFindings
  ## Unarchives Amazon GuardDuty findings specified by the list of finding IDs.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to unarchive.
  ##   body: JObject (required)
  var path_601705 = newJObject()
  var body_601706 = newJObject()
  add(path_601705, "detectorId", newJString(detectorId))
  if body != nil:
    body_601706 = body
  result = call_601704.call(path_601705, nil, nil, nil, body_601706)

var unarchiveFindings* = Call_UnarchiveFindings_601691(name: "unarchiveFindings",
    meth: HttpMethod.HttpPost, host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/unarchive",
    validator: validate_UnarchiveFindings_601692, base: "/",
    url: url_UnarchiveFindings_601693, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601707 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601709(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UntagResource_601708(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) for the given GuardDuty resource 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_601710 = path.getOrDefault("resourceArn")
  valid_601710 = validateParameter(valid_601710, JString, required = true,
                                 default = nil)
  if valid_601710 != nil:
    section.add "resourceArn", valid_601710
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from a resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_601711 = query.getOrDefault("tagKeys")
  valid_601711 = validateParameter(valid_601711, JArray, required = true, default = nil)
  if valid_601711 != nil:
    section.add "tagKeys", valid_601711
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
  var valid_601712 = header.getOrDefault("X-Amz-Date")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-Date", valid_601712
  var valid_601713 = header.getOrDefault("X-Amz-Security-Token")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-Security-Token", valid_601713
  var valid_601714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Content-Sha256", valid_601714
  var valid_601715 = header.getOrDefault("X-Amz-Algorithm")
  valid_601715 = validateParameter(valid_601715, JString, required = false,
                                 default = nil)
  if valid_601715 != nil:
    section.add "X-Amz-Algorithm", valid_601715
  var valid_601716 = header.getOrDefault("X-Amz-Signature")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-Signature", valid_601716
  var valid_601717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "X-Amz-SignedHeaders", valid_601717
  var valid_601718 = header.getOrDefault("X-Amz-Credential")
  valid_601718 = validateParameter(valid_601718, JString, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "X-Amz-Credential", valid_601718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601719: Call_UntagResource_601707; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags from a resource.
  ## 
  let valid = call_601719.validator(path, query, header, formData, body)
  let scheme = call_601719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601719.url(scheme.get, call_601719.host, call_601719.base,
                         call_601719.route, valid.getOrDefault("path"))
  result = hook(call_601719, url, valid)

proc call*(call_601720: Call_UntagResource_601707; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes tags from a resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys to remove from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) for the given GuardDuty resource 
  var path_601721 = newJObject()
  var query_601722 = newJObject()
  if tagKeys != nil:
    query_601722.add "tagKeys", tagKeys
  add(path_601721, "resourceArn", newJString(resourceArn))
  result = call_601720.call(path_601721, query_601722, nil, nil, nil)

var untagResource* = Call_UntagResource_601707(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "guardduty.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_601708,
    base: "/", url: url_UntagResource_601709, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindingsFeedback_601723 = ref object of OpenApiRestCall_600426
proc url_UpdateFindingsFeedback_601725(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "detectorId" in path, "`detectorId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/detector/"),
               (kind: VariableSegment, value: "detectorId"),
               (kind: ConstantSegment, value: "/findings/feedback")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateFindingsFeedback_601724(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Marks specified Amazon GuardDuty findings as useful or not useful.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   detectorId: JString (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to mark as useful or not useful.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `detectorId` field"
  var valid_601726 = path.getOrDefault("detectorId")
  valid_601726 = validateParameter(valid_601726, JString, required = true,
                                 default = nil)
  if valid_601726 != nil:
    section.add "detectorId", valid_601726
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
  var valid_601727 = header.getOrDefault("X-Amz-Date")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-Date", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-Security-Token")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-Security-Token", valid_601728
  var valid_601729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-Content-Sha256", valid_601729
  var valid_601730 = header.getOrDefault("X-Amz-Algorithm")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-Algorithm", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Signature")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Signature", valid_601731
  var valid_601732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "X-Amz-SignedHeaders", valid_601732
  var valid_601733 = header.getOrDefault("X-Amz-Credential")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-Credential", valid_601733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601735: Call_UpdateFindingsFeedback_601723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Marks specified Amazon GuardDuty findings as useful or not useful.
  ## 
  let valid = call_601735.validator(path, query, header, formData, body)
  let scheme = call_601735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601735.url(scheme.get, call_601735.host, call_601735.base,
                         call_601735.route, valid.getOrDefault("path"))
  result = hook(call_601735, url, valid)

proc call*(call_601736: Call_UpdateFindingsFeedback_601723; detectorId: string;
          body: JsonNode): Recallable =
  ## updateFindingsFeedback
  ## Marks specified Amazon GuardDuty findings as useful or not useful.
  ##   detectorId: string (required)
  ##             : The ID of the detector that specifies the GuardDuty service whose findings you want to mark as useful or not useful.
  ##   body: JObject (required)
  var path_601737 = newJObject()
  var body_601738 = newJObject()
  add(path_601737, "detectorId", newJString(detectorId))
  if body != nil:
    body_601738 = body
  result = call_601736.call(path_601737, nil, nil, nil, body_601738)

var updateFindingsFeedback* = Call_UpdateFindingsFeedback_601723(
    name: "updateFindingsFeedback", meth: HttpMethod.HttpPost,
    host: "guardduty.amazonaws.com",
    route: "/detector/{detectorId}/findings/feedback",
    validator: validate_UpdateFindingsFeedback_601724, base: "/",
    url: url_UpdateFindingsFeedback_601725, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
