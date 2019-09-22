
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS SecurityHub
## version: 2018-10-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Security Hub provides you with a comprehensive view of the security state of your AWS environment and resources. It also provides you with the compliance status of your environment based on CIS AWS Foundations compliance checks. Security Hub collects security data from AWS accounts, services, and integrated third-party products and helps you analyze security trends in your environment to identify the highest priority security issues. For more information about Security Hub, see the <i> <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html">AWS Security Hub User Guide</a> </i>.</p> <p>When you use operations in the Security Hub API, the requests are executed only in the AWS Region that is currently active or in the specific AWS Region that you specify in your request. Any configuration or settings change that results from the operation is applied only to that Region. To make the same change in other Regions, execute the same command for each Region to apply the change to. For example, if your Region is set to <code>us-west-2</code>, when you use <code>CreateMembers</code> to add a member account to Security Hub, the association of the member account with the master account is created only in the us-west-2 Region. Security Hub must be enabled for the member account in the same Region that the invite was sent from.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/securityhub/
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "securityhub.ap-northeast-1.amazonaws.com", "ap-southeast-1": "securityhub.ap-southeast-1.amazonaws.com",
                           "us-west-2": "securityhub.us-west-2.amazonaws.com",
                           "eu-west-2": "securityhub.eu-west-2.amazonaws.com", "ap-northeast-3": "securityhub.ap-northeast-3.amazonaws.com", "eu-central-1": "securityhub.eu-central-1.amazonaws.com",
                           "us-east-2": "securityhub.us-east-2.amazonaws.com",
                           "us-east-1": "securityhub.us-east-1.amazonaws.com", "cn-northwest-1": "securityhub.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "securityhub.ap-south-1.amazonaws.com", "eu-north-1": "securityhub.eu-north-1.amazonaws.com", "ap-northeast-2": "securityhub.ap-northeast-2.amazonaws.com",
                           "us-west-1": "securityhub.us-west-1.amazonaws.com", "us-gov-east-1": "securityhub.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "securityhub.eu-west-3.amazonaws.com", "cn-north-1": "securityhub.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "securityhub.sa-east-1.amazonaws.com",
                           "eu-west-1": "securityhub.eu-west-1.amazonaws.com", "us-gov-west-1": "securityhub.us-gov-west-1.amazonaws.com", "ap-southeast-2": "securityhub.ap-southeast-2.amazonaws.com", "ca-central-1": "securityhub.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "securityhub.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "securityhub.ap-southeast-1.amazonaws.com",
      "us-west-2": "securityhub.us-west-2.amazonaws.com",
      "eu-west-2": "securityhub.eu-west-2.amazonaws.com",
      "ap-northeast-3": "securityhub.ap-northeast-3.amazonaws.com",
      "eu-central-1": "securityhub.eu-central-1.amazonaws.com",
      "us-east-2": "securityhub.us-east-2.amazonaws.com",
      "us-east-1": "securityhub.us-east-1.amazonaws.com",
      "cn-northwest-1": "securityhub.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "securityhub.ap-south-1.amazonaws.com",
      "eu-north-1": "securityhub.eu-north-1.amazonaws.com",
      "ap-northeast-2": "securityhub.ap-northeast-2.amazonaws.com",
      "us-west-1": "securityhub.us-west-1.amazonaws.com",
      "us-gov-east-1": "securityhub.us-gov-east-1.amazonaws.com",
      "eu-west-3": "securityhub.eu-west-3.amazonaws.com",
      "cn-north-1": "securityhub.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "securityhub.sa-east-1.amazonaws.com",
      "eu-west-1": "securityhub.eu-west-1.amazonaws.com",
      "us-gov-west-1": "securityhub.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "securityhub.ap-southeast-2.amazonaws.com",
      "ca-central-1": "securityhub.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "securityhub"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AcceptInvitation_603022 = ref object of OpenApiRestCall_602433
proc url_AcceptInvitation_603024(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AcceptInvitation_603023(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from. When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.
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
  var valid_603025 = header.getOrDefault("X-Amz-Date")
  valid_603025 = validateParameter(valid_603025, JString, required = false,
                                 default = nil)
  if valid_603025 != nil:
    section.add "X-Amz-Date", valid_603025
  var valid_603026 = header.getOrDefault("X-Amz-Security-Token")
  valid_603026 = validateParameter(valid_603026, JString, required = false,
                                 default = nil)
  if valid_603026 != nil:
    section.add "X-Amz-Security-Token", valid_603026
  var valid_603027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603027 = validateParameter(valid_603027, JString, required = false,
                                 default = nil)
  if valid_603027 != nil:
    section.add "X-Amz-Content-Sha256", valid_603027
  var valid_603028 = header.getOrDefault("X-Amz-Algorithm")
  valid_603028 = validateParameter(valid_603028, JString, required = false,
                                 default = nil)
  if valid_603028 != nil:
    section.add "X-Amz-Algorithm", valid_603028
  var valid_603029 = header.getOrDefault("X-Amz-Signature")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-Signature", valid_603029
  var valid_603030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "X-Amz-SignedHeaders", valid_603030
  var valid_603031 = header.getOrDefault("X-Amz-Credential")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Credential", valid_603031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603033: Call_AcceptInvitation_603022; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from. When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.
  ## 
  let valid = call_603033.validator(path, query, header, formData, body)
  let scheme = call_603033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603033.url(scheme.get, call_603033.host, call_603033.base,
                         call_603033.route, valid.getOrDefault("path"))
  result = hook(call_603033, url, valid)

proc call*(call_603034: Call_AcceptInvitation_603022; body: JsonNode): Recallable =
  ## acceptInvitation
  ## Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from. When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.
  ##   body: JObject (required)
  var body_603035 = newJObject()
  if body != nil:
    body_603035 = body
  result = call_603034.call(nil, nil, nil, nil, body_603035)

var acceptInvitation* = Call_AcceptInvitation_603022(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_AcceptInvitation_603023, base: "/",
    url: url_AcceptInvitation_603024, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_602770 = ref object of OpenApiRestCall_602433
proc url_GetMasterAccount_602772(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMasterAccount_602771(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Provides the details for the Security Hub master account to the current member account. 
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
  var valid_602884 = header.getOrDefault("X-Amz-Date")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Date", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Security-Token")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Security-Token", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Content-Sha256", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Algorithm")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Algorithm", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Signature")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Signature", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-SignedHeaders", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Credential")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Credential", valid_602890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602913: Call_GetMasterAccount_602770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the Security Hub master account to the current member account. 
  ## 
  let valid = call_602913.validator(path, query, header, formData, body)
  let scheme = call_602913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602913.url(scheme.get, call_602913.host, call_602913.base,
                         call_602913.route, valid.getOrDefault("path"))
  result = hook(call_602913, url, valid)

proc call*(call_602984: Call_GetMasterAccount_602770): Recallable =
  ## getMasterAccount
  ## Provides the details for the Security Hub master account to the current member account. 
  result = call_602984.call(nil, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_602770(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_GetMasterAccount_602771, base: "/",
    url: url_GetMasterAccount_602772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisableStandards_603037 = ref object of OpenApiRestCall_602433
proc url_BatchDisableStandards_603039(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDisableStandards_603038(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
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
  var valid_603040 = header.getOrDefault("X-Amz-Date")
  valid_603040 = validateParameter(valid_603040, JString, required = false,
                                 default = nil)
  if valid_603040 != nil:
    section.add "X-Amz-Date", valid_603040
  var valid_603041 = header.getOrDefault("X-Amz-Security-Token")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "X-Amz-Security-Token", valid_603041
  var valid_603042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Content-Sha256", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Algorithm")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Algorithm", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-Signature")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Signature", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-SignedHeaders", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Credential")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Credential", valid_603046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603048: Call_BatchDisableStandards_603037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ## 
  let valid = call_603048.validator(path, query, header, formData, body)
  let scheme = call_603048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603048.url(scheme.get, call_603048.host, call_603048.base,
                         call_603048.route, valid.getOrDefault("path"))
  result = hook(call_603048, url, valid)

proc call*(call_603049: Call_BatchDisableStandards_603037; body: JsonNode): Recallable =
  ## batchDisableStandards
  ## Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_603050 = newJObject()
  if body != nil:
    body_603050 = body
  result = call_603049.call(nil, nil, nil, nil, body_603050)

var batchDisableStandards* = Call_BatchDisableStandards_603037(
    name: "batchDisableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/deregister",
    validator: validate_BatchDisableStandards_603038, base: "/",
    url: url_BatchDisableStandards_603039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchEnableStandards_603051 = ref object of OpenApiRestCall_602433
proc url_BatchEnableStandards_603053(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchEnableStandards_603052(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enables the standards specified by the provided <code>standardsArn</code>. In this release, only CIS AWS Foundations standards are supported. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
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
  var valid_603054 = header.getOrDefault("X-Amz-Date")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Date", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-Security-Token")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-Security-Token", valid_603055
  var valid_603056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-Content-Sha256", valid_603056
  var valid_603057 = header.getOrDefault("X-Amz-Algorithm")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Algorithm", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Signature")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Signature", valid_603058
  var valid_603059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-SignedHeaders", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Credential")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Credential", valid_603060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603062: Call_BatchEnableStandards_603051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the standards specified by the provided <code>standardsArn</code>. In this release, only CIS AWS Foundations standards are supported. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ## 
  let valid = call_603062.validator(path, query, header, formData, body)
  let scheme = call_603062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603062.url(scheme.get, call_603062.host, call_603062.base,
                         call_603062.route, valid.getOrDefault("path"))
  result = hook(call_603062, url, valid)

proc call*(call_603063: Call_BatchEnableStandards_603051; body: JsonNode): Recallable =
  ## batchEnableStandards
  ## Enables the standards specified by the provided <code>standardsArn</code>. In this release, only CIS AWS Foundations standards are supported. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_603064 = newJObject()
  if body != nil:
    body_603064 = body
  result = call_603063.call(nil, nil, nil, nil, body_603064)

var batchEnableStandards* = Call_BatchEnableStandards_603051(
    name: "batchEnableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/register",
    validator: validate_BatchEnableStandards_603052, base: "/",
    url: url_BatchEnableStandards_603053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchImportFindings_603065 = ref object of OpenApiRestCall_602433
proc url_BatchImportFindings_603067(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchImportFindings_603066(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub. The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.
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
  var valid_603068 = header.getOrDefault("X-Amz-Date")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Date", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Security-Token")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Security-Token", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Content-Sha256", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Algorithm")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Algorithm", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Signature")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Signature", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-SignedHeaders", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Credential")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Credential", valid_603074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603076: Call_BatchImportFindings_603065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub. The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.
  ## 
  let valid = call_603076.validator(path, query, header, formData, body)
  let scheme = call_603076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603076.url(scheme.get, call_603076.host, call_603076.base,
                         call_603076.route, valid.getOrDefault("path"))
  result = hook(call_603076, url, valid)

proc call*(call_603077: Call_BatchImportFindings_603065; body: JsonNode): Recallable =
  ## batchImportFindings
  ## Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub. The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.
  ##   body: JObject (required)
  var body_603078 = newJObject()
  if body != nil:
    body_603078 = body
  result = call_603077.call(nil, nil, nil, nil, body_603078)

var batchImportFindings* = Call_BatchImportFindings_603065(
    name: "batchImportFindings", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/findings/import",
    validator: validate_BatchImportFindings_603066, base: "/",
    url: url_BatchImportFindings_603067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActionTarget_603079 = ref object of OpenApiRestCall_602433
proc url_CreateActionTarget_603081(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateActionTarget_603080(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a custom action target in Security Hub. You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.
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
  var valid_603082 = header.getOrDefault("X-Amz-Date")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Date", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Security-Token")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Security-Token", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Content-Sha256", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Algorithm")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Algorithm", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Signature")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Signature", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-SignedHeaders", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Credential")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Credential", valid_603088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603090: Call_CreateActionTarget_603079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom action target in Security Hub. You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.
  ## 
  let valid = call_603090.validator(path, query, header, formData, body)
  let scheme = call_603090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603090.url(scheme.get, call_603090.host, call_603090.base,
                         call_603090.route, valid.getOrDefault("path"))
  result = hook(call_603090, url, valid)

proc call*(call_603091: Call_CreateActionTarget_603079; body: JsonNode): Recallable =
  ## createActionTarget
  ## Creates a custom action target in Security Hub. You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.
  ##   body: JObject (required)
  var body_603092 = newJObject()
  if body != nil:
    body_603092 = body
  result = call_603091.call(nil, nil, nil, nil, body_603092)

var createActionTarget* = Call_CreateActionTarget_603079(
    name: "createActionTarget", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets",
    validator: validate_CreateActionTarget_603080, base: "/",
    url: url_CreateActionTarget_603081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInsight_603093 = ref object of OpenApiRestCall_602433
proc url_CreateInsight_603095(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateInsight_603094(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation. Use the <code>GroupByAttribute</code> to group the related findings in the insight.
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
  var valid_603096 = header.getOrDefault("X-Amz-Date")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Date", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Security-Token")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Security-Token", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Content-Sha256", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Algorithm")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Algorithm", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Signature")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Signature", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-SignedHeaders", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Credential")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Credential", valid_603102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603104: Call_CreateInsight_603093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation. Use the <code>GroupByAttribute</code> to group the related findings in the insight.
  ## 
  let valid = call_603104.validator(path, query, header, formData, body)
  let scheme = call_603104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603104.url(scheme.get, call_603104.host, call_603104.base,
                         call_603104.route, valid.getOrDefault("path"))
  result = hook(call_603104, url, valid)

proc call*(call_603105: Call_CreateInsight_603093; body: JsonNode): Recallable =
  ## createInsight
  ## Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation. Use the <code>GroupByAttribute</code> to group the related findings in the insight.
  ##   body: JObject (required)
  var body_603106 = newJObject()
  if body != nil:
    body_603106 = body
  result = call_603105.call(nil, nil, nil, nil, body_603106)

var createInsight* = Call_CreateInsight_603093(name: "createInsight",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/insights", validator: validate_CreateInsight_603094, base: "/",
    url: url_CreateInsight_603095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_603124 = ref object of OpenApiRestCall_602433
proc url_CreateMembers_603126(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateMembers_603125(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. You can use the <a>EnableSecurityHub</a> to enable Security Hub.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you need to use the <a>InviteMembers</a> action, which invites the accounts to enable Security Hub and become member accounts in Security Hub. If the invitation is accepted by the account owner, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start being sent to both the member and master accounts.</p> <p>You can remove the association between the master and member accounts by using the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
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
  var valid_603127 = header.getOrDefault("X-Amz-Date")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Date", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Security-Token")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Security-Token", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Content-Sha256", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Algorithm")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Algorithm", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Signature")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Signature", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-SignedHeaders", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Credential")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Credential", valid_603133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603135: Call_CreateMembers_603124; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. You can use the <a>EnableSecurityHub</a> to enable Security Hub.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you need to use the <a>InviteMembers</a> action, which invites the accounts to enable Security Hub and become member accounts in Security Hub. If the invitation is accepted by the account owner, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start being sent to both the member and master accounts.</p> <p>You can remove the association between the master and member accounts by using the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ## 
  let valid = call_603135.validator(path, query, header, formData, body)
  let scheme = call_603135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603135.url(scheme.get, call_603135.host, call_603135.base,
                         call_603135.route, valid.getOrDefault("path"))
  result = hook(call_603135, url, valid)

proc call*(call_603136: Call_CreateMembers_603124; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. You can use the <a>EnableSecurityHub</a> to enable Security Hub.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you need to use the <a>InviteMembers</a> action, which invites the accounts to enable Security Hub and become member accounts in Security Hub. If the invitation is accepted by the account owner, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start being sent to both the member and master accounts.</p> <p>You can remove the association between the master and member accounts by using the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ##   body: JObject (required)
  var body_603137 = newJObject()
  if body != nil:
    body_603137 = body
  result = call_603136.call(nil, nil, nil, nil, body_603137)

var createMembers* = Call_CreateMembers_603124(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/members",
    validator: validate_CreateMembers_603125, base: "/", url: url_CreateMembers_603126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_603107 = ref object of OpenApiRestCall_602433
proc url_ListMembers_603109(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListMembers_603108(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists details about all member accounts for the current Security Hub master account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OnlyAssociated: JBool
  ##                 : Specifies which member accounts the response includes based on their relationship status with the master account. The default value is <code>TRUE</code>. If <code>onlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>. If <code>onlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. 
  ##   NextToken: JString
  ##            : Paginates results. Set the value of this parameter to <code>NULL</code> on your first call to the <code>ListMembers</code> operation. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>nextToken</code> from the previous response to continue listing data. 
  ##   MaxResults: JInt
  ##             : The maximum number of items that you want in the response. 
  section = newJObject()
  var valid_603110 = query.getOrDefault("OnlyAssociated")
  valid_603110 = validateParameter(valid_603110, JBool, required = false, default = nil)
  if valid_603110 != nil:
    section.add "OnlyAssociated", valid_603110
  var valid_603111 = query.getOrDefault("NextToken")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "NextToken", valid_603111
  var valid_603112 = query.getOrDefault("MaxResults")
  valid_603112 = validateParameter(valid_603112, JInt, required = false, default = nil)
  if valid_603112 != nil:
    section.add "MaxResults", valid_603112
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
  var valid_603113 = header.getOrDefault("X-Amz-Date")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Date", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Security-Token")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Security-Token", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Content-Sha256", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Algorithm")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Algorithm", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Signature")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Signature", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-SignedHeaders", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Credential")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Credential", valid_603119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603120: Call_ListMembers_603107; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current Security Hub master account.
  ## 
  let valid = call_603120.validator(path, query, header, formData, body)
  let scheme = call_603120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603120.url(scheme.get, call_603120.host, call_603120.base,
                         call_603120.route, valid.getOrDefault("path"))
  result = hook(call_603120, url, valid)

proc call*(call_603121: Call_ListMembers_603107; OnlyAssociated: bool = false;
          NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listMembers
  ## Lists details about all member accounts for the current Security Hub master account.
  ##   OnlyAssociated: bool
  ##                 : Specifies which member accounts the response includes based on their relationship status with the master account. The default value is <code>TRUE</code>. If <code>onlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>. If <code>onlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. 
  ##   NextToken: string
  ##            : Paginates results. Set the value of this parameter to <code>NULL</code> on your first call to the <code>ListMembers</code> operation. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>nextToken</code> from the previous response to continue listing data. 
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response. 
  var query_603122 = newJObject()
  add(query_603122, "OnlyAssociated", newJBool(OnlyAssociated))
  add(query_603122, "NextToken", newJString(NextToken))
  add(query_603122, "MaxResults", newJInt(MaxResults))
  result = call_603121.call(nil, query_603122, nil, nil, nil)

var listMembers* = Call_ListMembers_603107(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/members",
                                        validator: validate_ListMembers_603108,
                                        base: "/", url: url_ListMembers_603109,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_603138 = ref object of OpenApiRestCall_602433
proc url_DeclineInvitations_603140(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeclineInvitations_603139(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Declines invitations to become a member account.
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
  var valid_603141 = header.getOrDefault("X-Amz-Date")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Date", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Security-Token")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Security-Token", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Content-Sha256", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Algorithm")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Algorithm", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Signature")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Signature", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-SignedHeaders", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Credential")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Credential", valid_603147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603149: Call_DeclineInvitations_603138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations to become a member account.
  ## 
  let valid = call_603149.validator(path, query, header, formData, body)
  let scheme = call_603149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603149.url(scheme.get, call_603149.host, call_603149.base,
                         call_603149.route, valid.getOrDefault("path"))
  result = hook(call_603149, url, valid)

proc call*(call_603150: Call_DeclineInvitations_603138; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations to become a member account.
  ##   body: JObject (required)
  var body_603151 = newJObject()
  if body != nil:
    body_603151 = body
  result = call_603150.call(nil, nil, nil, nil, body_603151)

var declineInvitations* = Call_DeclineInvitations_603138(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/invitations/decline",
    validator: validate_DeclineInvitations_603139, base: "/",
    url: url_DeclineInvitations_603140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateActionTarget_603180 = ref object of OpenApiRestCall_602433
proc url_UpdateActionTarget_603182(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ActionTargetArn" in path, "`ActionTargetArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/actionTargets/"),
               (kind: VariableSegment, value: "ActionTargetArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateActionTarget_603181(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Updates the name and description of a custom action target in Security Hub.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ActionTargetArn: JString (required)
  ##                  : The ARN of the custom action target to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ActionTargetArn` field"
  var valid_603183 = path.getOrDefault("ActionTargetArn")
  valid_603183 = validateParameter(valid_603183, JString, required = true,
                                 default = nil)
  if valid_603183 != nil:
    section.add "ActionTargetArn", valid_603183
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
  var valid_603184 = header.getOrDefault("X-Amz-Date")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Date", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Security-Token")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Security-Token", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Content-Sha256", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Algorithm")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Algorithm", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Signature")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Signature", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-SignedHeaders", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Credential")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Credential", valid_603190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603192: Call_UpdateActionTarget_603180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name and description of a custom action target in Security Hub.
  ## 
  let valid = call_603192.validator(path, query, header, formData, body)
  let scheme = call_603192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603192.url(scheme.get, call_603192.host, call_603192.base,
                         call_603192.route, valid.getOrDefault("path"))
  result = hook(call_603192, url, valid)

proc call*(call_603193: Call_UpdateActionTarget_603180; body: JsonNode;
          ActionTargetArn: string): Recallable =
  ## updateActionTarget
  ## Updates the name and description of a custom action target in Security Hub.
  ##   body: JObject (required)
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to update.
  var path_603194 = newJObject()
  var body_603195 = newJObject()
  if body != nil:
    body_603195 = body
  add(path_603194, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_603193.call(path_603194, nil, nil, nil, body_603195)

var updateActionTarget* = Call_UpdateActionTarget_603180(
    name: "updateActionTarget", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_UpdateActionTarget_603181, base: "/",
    url: url_UpdateActionTarget_603182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActionTarget_603152 = ref object of OpenApiRestCall_602433
proc url_DeleteActionTarget_603154(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ActionTargetArn" in path, "`ActionTargetArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/actionTargets/"),
               (kind: VariableSegment, value: "ActionTargetArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteActionTarget_603153(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a custom action target from Security Hub. Deleting a custom action target doesn't affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ActionTargetArn: JString (required)
  ##                  : The ARN of the custom action target to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ActionTargetArn` field"
  var valid_603169 = path.getOrDefault("ActionTargetArn")
  valid_603169 = validateParameter(valid_603169, JString, required = true,
                                 default = nil)
  if valid_603169 != nil:
    section.add "ActionTargetArn", valid_603169
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
  var valid_603170 = header.getOrDefault("X-Amz-Date")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Date", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Security-Token")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Security-Token", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Content-Sha256", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Algorithm")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Algorithm", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Signature")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Signature", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-SignedHeaders", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Credential")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Credential", valid_603176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603177: Call_DeleteActionTarget_603152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a custom action target from Security Hub. Deleting a custom action target doesn't affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.
  ## 
  let valid = call_603177.validator(path, query, header, formData, body)
  let scheme = call_603177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603177.url(scheme.get, call_603177.host, call_603177.base,
                         call_603177.route, valid.getOrDefault("path"))
  result = hook(call_603177, url, valid)

proc call*(call_603178: Call_DeleteActionTarget_603152; ActionTargetArn: string): Recallable =
  ## deleteActionTarget
  ## Deletes a custom action target from Security Hub. Deleting a custom action target doesn't affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to delete.
  var path_603179 = newJObject()
  add(path_603179, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_603178.call(path_603179, nil, nil, nil, nil)

var deleteActionTarget* = Call_DeleteActionTarget_603152(
    name: "deleteActionTarget", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_DeleteActionTarget_603153, base: "/",
    url: url_DeleteActionTarget_603154, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInsight_603210 = ref object of OpenApiRestCall_602433
proc url_UpdateInsight_603212(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InsightArn" in path, "`InsightArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/insights/"),
               (kind: VariableSegment, value: "InsightArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UpdateInsight_603211(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the Security Hub insight that the insight ARN specifies.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InsightArn: JString (required)
  ##             : The ARN of the insight that you want to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InsightArn` field"
  var valid_603213 = path.getOrDefault("InsightArn")
  valid_603213 = validateParameter(valid_603213, JString, required = true,
                                 default = nil)
  if valid_603213 != nil:
    section.add "InsightArn", valid_603213
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
  var valid_603214 = header.getOrDefault("X-Amz-Date")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Date", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Security-Token")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Security-Token", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Content-Sha256", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Algorithm")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Algorithm", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Signature")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Signature", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-SignedHeaders", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Credential")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Credential", valid_603220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603222: Call_UpdateInsight_603210; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Security Hub insight that the insight ARN specifies.
  ## 
  let valid = call_603222.validator(path, query, header, formData, body)
  let scheme = call_603222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603222.url(scheme.get, call_603222.host, call_603222.base,
                         call_603222.route, valid.getOrDefault("path"))
  result = hook(call_603222, url, valid)

proc call*(call_603223: Call_UpdateInsight_603210; InsightArn: string; body: JsonNode): Recallable =
  ## updateInsight
  ## Updates the Security Hub insight that the insight ARN specifies.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight that you want to update.
  ##   body: JObject (required)
  var path_603224 = newJObject()
  var body_603225 = newJObject()
  add(path_603224, "InsightArn", newJString(InsightArn))
  if body != nil:
    body_603225 = body
  result = call_603223.call(path_603224, nil, nil, nil, body_603225)

var updateInsight* = Call_UpdateInsight_603210(name: "updateInsight",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_UpdateInsight_603211,
    base: "/", url: url_UpdateInsight_603212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInsight_603196 = ref object of OpenApiRestCall_602433
proc url_DeleteInsight_603198(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InsightArn" in path, "`InsightArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/insights/"),
               (kind: VariableSegment, value: "InsightArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DeleteInsight_603197(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InsightArn: JString (required)
  ##             : The ARN of the insight to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InsightArn` field"
  var valid_603199 = path.getOrDefault("InsightArn")
  valid_603199 = validateParameter(valid_603199, JString, required = true,
                                 default = nil)
  if valid_603199 != nil:
    section.add "InsightArn", valid_603199
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
  var valid_603200 = header.getOrDefault("X-Amz-Date")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Date", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Security-Token")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Security-Token", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Content-Sha256", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Algorithm")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Algorithm", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Signature")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Signature", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-SignedHeaders", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Credential")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Credential", valid_603206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603207: Call_DeleteInsight_603196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ## 
  let valid = call_603207.validator(path, query, header, formData, body)
  let scheme = call_603207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603207.url(scheme.get, call_603207.host, call_603207.base,
                         call_603207.route, valid.getOrDefault("path"))
  result = hook(call_603207, url, valid)

proc call*(call_603208: Call_DeleteInsight_603196; InsightArn: string): Recallable =
  ## deleteInsight
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight to delete.
  var path_603209 = newJObject()
  add(path_603209, "InsightArn", newJString(InsightArn))
  result = call_603208.call(path_603209, nil, nil, nil, nil)

var deleteInsight* = Call_DeleteInsight_603196(name: "deleteInsight",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_DeleteInsight_603197,
    base: "/", url: url_DeleteInsight_603198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_603226 = ref object of OpenApiRestCall_602433
proc url_DeleteInvitations_603228(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteInvitations_603227(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes invitations received by the AWS account to become a member account.
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
  var valid_603229 = header.getOrDefault("X-Amz-Date")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Date", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Security-Token")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Security-Token", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Content-Sha256", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Algorithm")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Algorithm", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Signature")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Signature", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-SignedHeaders", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Credential")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Credential", valid_603235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603237: Call_DeleteInvitations_603226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations received by the AWS account to become a member account.
  ## 
  let valid = call_603237.validator(path, query, header, formData, body)
  let scheme = call_603237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603237.url(scheme.get, call_603237.host, call_603237.base,
                         call_603237.route, valid.getOrDefault("path"))
  result = hook(call_603237, url, valid)

proc call*(call_603238: Call_DeleteInvitations_603226; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations received by the AWS account to become a member account.
  ##   body: JObject (required)
  var body_603239 = newJObject()
  if body != nil:
    body_603239 = body
  result = call_603238.call(nil, nil, nil, nil, body_603239)

var deleteInvitations* = Call_DeleteInvitations_603226(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/invitations/delete", validator: validate_DeleteInvitations_603227,
    base: "/", url: url_DeleteInvitations_603228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_603240 = ref object of OpenApiRestCall_602433
proc url_DeleteMembers_603242(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteMembers_603241(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified member accounts from Security Hub.
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
  var valid_603243 = header.getOrDefault("X-Amz-Date")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Date", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Security-Token")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Security-Token", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Content-Sha256", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Algorithm")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Algorithm", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Signature")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Signature", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-SignedHeaders", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Credential")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Credential", valid_603249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603251: Call_DeleteMembers_603240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified member accounts from Security Hub.
  ## 
  let valid = call_603251.validator(path, query, header, formData, body)
  let scheme = call_603251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603251.url(scheme.get, call_603251.host, call_603251.base,
                         call_603251.route, valid.getOrDefault("path"))
  result = hook(call_603251, url, valid)

proc call*(call_603252: Call_DeleteMembers_603240; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes the specified member accounts from Security Hub.
  ##   body: JObject (required)
  var body_603253 = newJObject()
  if body != nil:
    body_603253 = body
  result = call_603252.call(nil, nil, nil, nil, body_603253)

var deleteMembers* = Call_DeleteMembers_603240(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/delete", validator: validate_DeleteMembers_603241, base: "/",
    url: url_DeleteMembers_603242, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActionTargets_603254 = ref object of OpenApiRestCall_602433
proc url_DescribeActionTargets_603256(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeActionTargets_603255(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the custom action targets in Security Hub in your account.
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
  var valid_603257 = query.getOrDefault("NextToken")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "NextToken", valid_603257
  var valid_603258 = query.getOrDefault("MaxResults")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "MaxResults", valid_603258
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
  var valid_603259 = header.getOrDefault("X-Amz-Date")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Date", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Security-Token")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Security-Token", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Content-Sha256", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Algorithm")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Algorithm", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Signature")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Signature", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-SignedHeaders", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Credential")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Credential", valid_603265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603267: Call_DescribeActionTargets_603254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the custom action targets in Security Hub in your account.
  ## 
  let valid = call_603267.validator(path, query, header, formData, body)
  let scheme = call_603267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603267.url(scheme.get, call_603267.host, call_603267.base,
                         call_603267.route, valid.getOrDefault("path"))
  result = hook(call_603267, url, valid)

proc call*(call_603268: Call_DescribeActionTargets_603254; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeActionTargets
  ## Returns a list of the custom action targets in Security Hub in your account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603269 = newJObject()
  var body_603270 = newJObject()
  add(query_603269, "NextToken", newJString(NextToken))
  if body != nil:
    body_603270 = body
  add(query_603269, "MaxResults", newJString(MaxResults))
  result = call_603268.call(nil, query_603269, nil, nil, body_603270)

var describeActionTargets* = Call_DescribeActionTargets_603254(
    name: "describeActionTargets", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets/get",
    validator: validate_DescribeActionTargets_603255, base: "/",
    url: url_DescribeActionTargets_603256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSecurityHub_603285 = ref object of OpenApiRestCall_602433
proc url_EnableSecurityHub_603287(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableSecurityHub_603286(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
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
  var valid_603288 = header.getOrDefault("X-Amz-Date")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Date", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Security-Token")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Security-Token", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Content-Sha256", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Algorithm")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Algorithm", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Signature")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Signature", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-SignedHeaders", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Credential")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Credential", valid_603294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603296: Call_EnableSecurityHub_603285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
  ## 
  let valid = call_603296.validator(path, query, header, formData, body)
  let scheme = call_603296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603296.url(scheme.get, call_603296.host, call_603296.base,
                         call_603296.route, valid.getOrDefault("path"))
  result = hook(call_603296, url, valid)

proc call*(call_603297: Call_EnableSecurityHub_603285; body: JsonNode): Recallable =
  ## enableSecurityHub
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_603298 = newJObject()
  if body != nil:
    body_603298 = body
  result = call_603297.call(nil, nil, nil, nil, body_603298)

var enableSecurityHub* = Call_EnableSecurityHub_603285(name: "enableSecurityHub",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/accounts", validator: validate_EnableSecurityHub_603286, base: "/",
    url: url_EnableSecurityHub_603287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHub_603271 = ref object of OpenApiRestCall_602433
proc url_DescribeHub_603273(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeHub_603272(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   HubArn: JString
  ##         : The ARN of the Hub resource to retrieve.
  section = newJObject()
  var valid_603274 = query.getOrDefault("HubArn")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "HubArn", valid_603274
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
  var valid_603275 = header.getOrDefault("X-Amz-Date")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Date", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Security-Token")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Security-Token", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Content-Sha256", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Algorithm")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Algorithm", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Signature")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Signature", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-SignedHeaders", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Credential")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Credential", valid_603281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603282: Call_DescribeHub_603271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ## 
  let valid = call_603282.validator(path, query, header, formData, body)
  let scheme = call_603282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603282.url(scheme.get, call_603282.host, call_603282.base,
                         call_603282.route, valid.getOrDefault("path"))
  result = hook(call_603282, url, valid)

proc call*(call_603283: Call_DescribeHub_603271; HubArn: string = ""): Recallable =
  ## describeHub
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ##   HubArn: string
  ##         : The ARN of the Hub resource to retrieve.
  var query_603284 = newJObject()
  add(query_603284, "HubArn", newJString(HubArn))
  result = call_603283.call(nil, query_603284, nil, nil, nil)

var describeHub* = Call_DescribeHub_603271(name: "describeHub",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/accounts",
                                        validator: validate_DescribeHub_603272,
                                        base: "/", url: url_DescribeHub_603273,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSecurityHub_603299 = ref object of OpenApiRestCall_602433
proc url_DisableSecurityHub_603301(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableSecurityHub_603300(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub. When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and can't be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed. If you want to save your existing findings, you must export them before you disable Security Hub.</p>
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
  var valid_603302 = header.getOrDefault("X-Amz-Date")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Date", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Security-Token")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Security-Token", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Content-Sha256", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Algorithm")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Algorithm", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Signature")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Signature", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-SignedHeaders", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Credential")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Credential", valid_603308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_DisableSecurityHub_603299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub. When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and can't be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed. If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_DisableSecurityHub_603299): Recallable =
  ## disableSecurityHub
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub. When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and can't be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed. If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  result = call_603310.call(nil, nil, nil, nil, nil)

var disableSecurityHub* = Call_DisableSecurityHub_603299(
    name: "disableSecurityHub", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/accounts",
    validator: validate_DisableSecurityHub_603300, base: "/",
    url: url_DisableSecurityHub_603301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProducts_603311 = ref object of OpenApiRestCall_602433
proc url_DescribeProducts_603313(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeProducts_603312(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The token that is required for pagination.
  ##   MaxResults: JInt
  ##             : The maximum number of results to return.
  section = newJObject()
  var valid_603314 = query.getOrDefault("NextToken")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "NextToken", valid_603314
  var valid_603315 = query.getOrDefault("MaxResults")
  valid_603315 = validateParameter(valid_603315, JInt, required = false, default = nil)
  if valid_603315 != nil:
    section.add "MaxResults", valid_603315
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
  var valid_603316 = header.getOrDefault("X-Amz-Date")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Date", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Security-Token")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Security-Token", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603323: Call_DescribeProducts_603311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
  ## 
  let valid = call_603323.validator(path, query, header, formData, body)
  let scheme = call_603323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603323.url(scheme.get, call_603323.host, call_603323.base,
                         call_603323.route, valid.getOrDefault("path"))
  result = hook(call_603323, url, valid)

proc call*(call_603324: Call_DescribeProducts_603311; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## describeProducts
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
  ##   NextToken: string
  ##            : The token that is required for pagination.
  ##   MaxResults: int
  ##             : The maximum number of results to return.
  var query_603325 = newJObject()
  add(query_603325, "NextToken", newJString(NextToken))
  add(query_603325, "MaxResults", newJInt(MaxResults))
  result = call_603324.call(nil, query_603325, nil, nil, nil)

var describeProducts* = Call_DescribeProducts_603311(name: "describeProducts",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/products",
    validator: validate_DescribeProducts_603312, base: "/",
    url: url_DescribeProducts_603313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableImportFindingsForProduct_603326 = ref object of OpenApiRestCall_602433
proc url_DisableImportFindingsForProduct_603328(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ProductSubscriptionArn" in path,
        "`ProductSubscriptionArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/productSubscriptions/"),
               (kind: VariableSegment, value: "ProductSubscriptionArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_DisableImportFindingsForProduct_603327(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables the integration of the specified product with Security Hub. Findings from that product are no longer sent to Security Hub after the integration is disabled.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ProductSubscriptionArn: JString (required)
  ##                         : The ARN of the integrated product to disable the integration for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ProductSubscriptionArn` field"
  var valid_603329 = path.getOrDefault("ProductSubscriptionArn")
  valid_603329 = validateParameter(valid_603329, JString, required = true,
                                 default = nil)
  if valid_603329 != nil:
    section.add "ProductSubscriptionArn", valid_603329
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
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Content-Sha256", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Algorithm")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Algorithm", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Signature")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Signature", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-SignedHeaders", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Credential")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Credential", valid_603336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603337: Call_DisableImportFindingsForProduct_603326;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disables the integration of the specified product with Security Hub. Findings from that product are no longer sent to Security Hub after the integration is disabled.
  ## 
  let valid = call_603337.validator(path, query, header, formData, body)
  let scheme = call_603337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603337.url(scheme.get, call_603337.host, call_603337.base,
                         call_603337.route, valid.getOrDefault("path"))
  result = hook(call_603337, url, valid)

proc call*(call_603338: Call_DisableImportFindingsForProduct_603326;
          ProductSubscriptionArn: string): Recallable =
  ## disableImportFindingsForProduct
  ## Disables the integration of the specified product with Security Hub. Findings from that product are no longer sent to Security Hub after the integration is disabled.
  ##   ProductSubscriptionArn: string (required)
  ##                         : The ARN of the integrated product to disable the integration for.
  var path_603339 = newJObject()
  add(path_603339, "ProductSubscriptionArn", newJString(ProductSubscriptionArn))
  result = call_603338.call(path_603339, nil, nil, nil, nil)

var disableImportFindingsForProduct* = Call_DisableImportFindingsForProduct_603326(
    name: "disableImportFindingsForProduct", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com",
    route: "/productSubscriptions/{ProductSubscriptionArn}",
    validator: validate_DisableImportFindingsForProduct_603327, base: "/",
    url: url_DisableImportFindingsForProduct_603328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_603340 = ref object of OpenApiRestCall_602433
proc url_DisassociateFromMasterAccount_603342(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateFromMasterAccount_603341(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disassociates the current Security Hub member account from the associated master account.
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
  var valid_603343 = header.getOrDefault("X-Amz-Date")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Date", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Security-Token")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Security-Token", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Content-Sha256", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Algorithm")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Algorithm", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Signature")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Signature", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-SignedHeaders", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Credential")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Credential", valid_603349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603350: Call_DisassociateFromMasterAccount_603340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current Security Hub member account from the associated master account.
  ## 
  let valid = call_603350.validator(path, query, header, formData, body)
  let scheme = call_603350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603350.url(scheme.get, call_603350.host, call_603350.base,
                         call_603350.route, valid.getOrDefault("path"))
  result = hook(call_603350, url, valid)

proc call*(call_603351: Call_DisassociateFromMasterAccount_603340): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current Security Hub member account from the associated master account.
  result = call_603351.call(nil, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_603340(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_603341, base: "/",
    url: url_DisassociateFromMasterAccount_603342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_603352 = ref object of OpenApiRestCall_602433
proc url_DisassociateMembers_603354(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateMembers_603353(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Disassociates the specified member accounts from the associated master account.
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
  var valid_603355 = header.getOrDefault("X-Amz-Date")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Date", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Security-Token")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Security-Token", valid_603356
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

proc call*(call_603363: Call_DisassociateMembers_603352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified member accounts from the associated master account.
  ## 
  let valid = call_603363.validator(path, query, header, formData, body)
  let scheme = call_603363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603363.url(scheme.get, call_603363.host, call_603363.base,
                         call_603363.route, valid.getOrDefault("path"))
  result = hook(call_603363, url, valid)

proc call*(call_603364: Call_DisassociateMembers_603352; body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates the specified member accounts from the associated master account.
  ##   body: JObject (required)
  var body_603365 = newJObject()
  if body != nil:
    body_603365 = body
  result = call_603364.call(nil, nil, nil, nil, body_603365)

var disassociateMembers* = Call_DisassociateMembers_603352(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/members/disassociate",
    validator: validate_DisassociateMembers_603353, base: "/",
    url: url_DisassociateMembers_603354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableImportFindingsForProduct_603381 = ref object of OpenApiRestCall_602433
proc url_EnableImportFindingsForProduct_603383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableImportFindingsForProduct_603382(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub. When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.
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
  var valid_603384 = header.getOrDefault("X-Amz-Date")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Date", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Security-Token")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Security-Token", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Content-Sha256", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-Algorithm")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Algorithm", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Signature")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Signature", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-SignedHeaders", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Credential")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Credential", valid_603390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603392: Call_EnableImportFindingsForProduct_603381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub. When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.
  ## 
  let valid = call_603392.validator(path, query, header, formData, body)
  let scheme = call_603392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603392.url(scheme.get, call_603392.host, call_603392.base,
                         call_603392.route, valid.getOrDefault("path"))
  result = hook(call_603392, url, valid)

proc call*(call_603393: Call_EnableImportFindingsForProduct_603381; body: JsonNode): Recallable =
  ## enableImportFindingsForProduct
  ## Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub. When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.
  ##   body: JObject (required)
  var body_603394 = newJObject()
  if body != nil:
    body_603394 = body
  result = call_603393.call(nil, nil, nil, nil, body_603394)

var enableImportFindingsForProduct* = Call_EnableImportFindingsForProduct_603381(
    name: "enableImportFindingsForProduct", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_EnableImportFindingsForProduct_603382, base: "/",
    url: url_EnableImportFindingsForProduct_603383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnabledProductsForImport_603366 = ref object of OpenApiRestCall_602433
proc url_ListEnabledProductsForImport_603368(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListEnabledProductsForImport_603367(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Paginates results. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data.
  ##   MaxResults: JInt
  ##             : The maximum number of items that you want in the response.
  section = newJObject()
  var valid_603369 = query.getOrDefault("NextToken")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "NextToken", valid_603369
  var valid_603370 = query.getOrDefault("MaxResults")
  valid_603370 = validateParameter(valid_603370, JInt, required = false, default = nil)
  if valid_603370 != nil:
    section.add "MaxResults", valid_603370
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
  var valid_603371 = header.getOrDefault("X-Amz-Date")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "X-Amz-Date", valid_603371
  var valid_603372 = header.getOrDefault("X-Amz-Security-Token")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "X-Amz-Security-Token", valid_603372
  var valid_603373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "X-Amz-Content-Sha256", valid_603373
  var valid_603374 = header.getOrDefault("X-Amz-Algorithm")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "X-Amz-Algorithm", valid_603374
  var valid_603375 = header.getOrDefault("X-Amz-Signature")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Signature", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-SignedHeaders", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Credential")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Credential", valid_603377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603378: Call_ListEnabledProductsForImport_603366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ## 
  let valid = call_603378.validator(path, query, header, formData, body)
  let scheme = call_603378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603378.url(scheme.get, call_603378.host, call_603378.base,
                         call_603378.route, valid.getOrDefault("path"))
  result = hook(call_603378, url, valid)

proc call*(call_603379: Call_ListEnabledProductsForImport_603366;
          NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listEnabledProductsForImport
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data.
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response.
  var query_603380 = newJObject()
  add(query_603380, "NextToken", newJString(NextToken))
  add(query_603380, "MaxResults", newJInt(MaxResults))
  result = call_603379.call(nil, query_603380, nil, nil, nil)

var listEnabledProductsForImport* = Call_ListEnabledProductsForImport_603366(
    name: "listEnabledProductsForImport", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_ListEnabledProductsForImport_603367, base: "/",
    url: url_ListEnabledProductsForImport_603368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnabledStandards_603395 = ref object of OpenApiRestCall_602433
proc url_GetEnabledStandards_603397(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetEnabledStandards_603396(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of the standards that are currently enabled.
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
  var valid_603398 = header.getOrDefault("X-Amz-Date")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Date", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Security-Token")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Security-Token", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Content-Sha256", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Algorithm")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Algorithm", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-Signature")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Signature", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-SignedHeaders", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Credential")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Credential", valid_603404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603406: Call_GetEnabledStandards_603395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the standards that are currently enabled.
  ## 
  let valid = call_603406.validator(path, query, header, formData, body)
  let scheme = call_603406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603406.url(scheme.get, call_603406.host, call_603406.base,
                         call_603406.route, valid.getOrDefault("path"))
  result = hook(call_603406, url, valid)

proc call*(call_603407: Call_GetEnabledStandards_603395; body: JsonNode): Recallable =
  ## getEnabledStandards
  ## Returns a list of the standards that are currently enabled.
  ##   body: JObject (required)
  var body_603408 = newJObject()
  if body != nil:
    body_603408 = body
  result = call_603407.call(nil, nil, nil, nil, body_603408)

var getEnabledStandards* = Call_GetEnabledStandards_603395(
    name: "getEnabledStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/get",
    validator: validate_GetEnabledStandards_603396, base: "/",
    url: url_GetEnabledStandards_603397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_603409 = ref object of OpenApiRestCall_602433
proc url_GetFindings_603411(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetFindings_603410(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of findings that match the specified criteria.
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
  var valid_603412 = query.getOrDefault("NextToken")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "NextToken", valid_603412
  var valid_603413 = query.getOrDefault("MaxResults")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "MaxResults", valid_603413
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
  var valid_603414 = header.getOrDefault("X-Amz-Date")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Date", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Security-Token")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Security-Token", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Content-Sha256", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Algorithm")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Algorithm", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-Signature")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Signature", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-SignedHeaders", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-Credential")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Credential", valid_603420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603422: Call_GetFindings_603409; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of findings that match the specified criteria.
  ## 
  let valid = call_603422.validator(path, query, header, formData, body)
  let scheme = call_603422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603422.url(scheme.get, call_603422.host, call_603422.base,
                         call_603422.route, valid.getOrDefault("path"))
  result = hook(call_603422, url, valid)

proc call*(call_603423: Call_GetFindings_603409; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getFindings
  ## Returns a list of findings that match the specified criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603424 = newJObject()
  var body_603425 = newJObject()
  add(query_603424, "NextToken", newJString(NextToken))
  if body != nil:
    body_603425 = body
  add(query_603424, "MaxResults", newJString(MaxResults))
  result = call_603423.call(nil, query_603424, nil, nil, body_603425)

var getFindings* = Call_GetFindings_603409(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/findings",
                                        validator: validate_GetFindings_603410,
                                        base: "/", url: url_GetFindings_603411,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_603426 = ref object of OpenApiRestCall_602433
proc url_UpdateFindings_603428(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateFindings_603427(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
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
  var valid_603429 = header.getOrDefault("X-Amz-Date")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Date", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Security-Token")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Security-Token", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Content-Sha256", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-Algorithm")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Algorithm", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Signature")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Signature", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-SignedHeaders", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Credential")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Credential", valid_603435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603437: Call_UpdateFindings_603426; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ## 
  let valid = call_603437.validator(path, query, header, formData, body)
  let scheme = call_603437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603437.url(scheme.get, call_603437.host, call_603437.base,
                         call_603437.route, valid.getOrDefault("path"))
  result = hook(call_603437, url, valid)

proc call*(call_603438: Call_UpdateFindings_603426; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ##   body: JObject (required)
  var body_603439 = newJObject()
  if body != nil:
    body_603439 = body
  result = call_603438.call(nil, nil, nil, nil, body_603439)

var updateFindings* = Call_UpdateFindings_603426(name: "updateFindings",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/findings", validator: validate_UpdateFindings_603427, base: "/",
    url: url_UpdateFindings_603428, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsightResults_603440 = ref object of OpenApiRestCall_602433
proc url_GetInsightResults_603442(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InsightArn" in path, "`InsightArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/insights/results/"),
               (kind: VariableSegment, value: "InsightArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_GetInsightResults_603441(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists the results of the Security Hub insight that the insight ARN specifies.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InsightArn: JString (required)
  ##             : The ARN of the insight whose results you want to see.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InsightArn` field"
  var valid_603443 = path.getOrDefault("InsightArn")
  valid_603443 = validateParameter(valid_603443, JString, required = true,
                                 default = nil)
  if valid_603443 != nil:
    section.add "InsightArn", valid_603443
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
  var valid_603444 = header.getOrDefault("X-Amz-Date")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Date", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Security-Token")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Security-Token", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Content-Sha256", valid_603446
  var valid_603447 = header.getOrDefault("X-Amz-Algorithm")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Algorithm", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Signature")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Signature", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-SignedHeaders", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Credential")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Credential", valid_603450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603451: Call_GetInsightResults_603440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the results of the Security Hub insight that the insight ARN specifies.
  ## 
  let valid = call_603451.validator(path, query, header, formData, body)
  let scheme = call_603451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603451.url(scheme.get, call_603451.host, call_603451.base,
                         call_603451.route, valid.getOrDefault("path"))
  result = hook(call_603451, url, valid)

proc call*(call_603452: Call_GetInsightResults_603440; InsightArn: string): Recallable =
  ## getInsightResults
  ## Lists the results of the Security Hub insight that the insight ARN specifies.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight whose results you want to see.
  var path_603453 = newJObject()
  add(path_603453, "InsightArn", newJString(InsightArn))
  result = call_603452.call(path_603453, nil, nil, nil, nil)

var getInsightResults* = Call_GetInsightResults_603440(name: "getInsightResults",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/insights/results/{InsightArn}",
    validator: validate_GetInsightResults_603441, base: "/",
    url: url_GetInsightResults_603442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsights_603454 = ref object of OpenApiRestCall_602433
proc url_GetInsights_603456(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetInsights_603455(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists and describes insights that insight ARNs specify.
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
  var valid_603457 = query.getOrDefault("NextToken")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "NextToken", valid_603457
  var valid_603458 = query.getOrDefault("MaxResults")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "MaxResults", valid_603458
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
  var valid_603459 = header.getOrDefault("X-Amz-Date")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Date", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Security-Token")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Security-Token", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Content-Sha256", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Algorithm")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Algorithm", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Signature")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Signature", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-SignedHeaders", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-Credential")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Credential", valid_603465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603467: Call_GetInsights_603454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists and describes insights that insight ARNs specify.
  ## 
  let valid = call_603467.validator(path, query, header, formData, body)
  let scheme = call_603467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603467.url(scheme.get, call_603467.host, call_603467.base,
                         call_603467.route, valid.getOrDefault("path"))
  result = hook(call_603467, url, valid)

proc call*(call_603468: Call_GetInsights_603454; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getInsights
  ## Lists and describes insights that insight ARNs specify.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603469 = newJObject()
  var body_603470 = newJObject()
  add(query_603469, "NextToken", newJString(NextToken))
  if body != nil:
    body_603470 = body
  add(query_603469, "MaxResults", newJString(MaxResults))
  result = call_603468.call(nil, query_603469, nil, nil, body_603470)

var getInsights* = Call_GetInsights_603454(name: "getInsights",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/insights/get",
                                        validator: validate_GetInsights_603455,
                                        base: "/", url: url_GetInsights_603456,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_603471 = ref object of OpenApiRestCall_602433
proc url_GetInvitationsCount_603473(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetInvitationsCount_603472(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
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
  var valid_603474 = header.getOrDefault("X-Amz-Date")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Date", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Security-Token")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Security-Token", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Content-Sha256", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-Algorithm")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Algorithm", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Signature")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Signature", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-SignedHeaders", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Credential")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Credential", valid_603480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603481: Call_GetInvitationsCount_603471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  ## 
  let valid = call_603481.validator(path, query, header, formData, body)
  let scheme = call_603481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603481.url(scheme.get, call_603481.host, call_603481.base,
                         call_603481.route, valid.getOrDefault("path"))
  result = hook(call_603481, url, valid)

proc call*(call_603482: Call_GetInvitationsCount_603471): Recallable =
  ## getInvitationsCount
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  result = call_603482.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_603471(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/invitations/count",
    validator: validate_GetInvitationsCount_603472, base: "/",
    url: url_GetInvitationsCount_603473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_603483 = ref object of OpenApiRestCall_602433
proc url_GetMembers_603485(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMembers_603484(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the details on the Security Hub member accounts that the account IDs specify.
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
  var valid_603486 = header.getOrDefault("X-Amz-Date")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Date", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Security-Token")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Security-Token", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Content-Sha256", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Algorithm")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Algorithm", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Signature")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Signature", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-SignedHeaders", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Credential")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Credential", valid_603492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603494: Call_GetMembers_603483; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details on the Security Hub member accounts that the account IDs specify.
  ## 
  let valid = call_603494.validator(path, query, header, formData, body)
  let scheme = call_603494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603494.url(scheme.get, call_603494.host, call_603494.base,
                         call_603494.route, valid.getOrDefault("path"))
  result = hook(call_603494, url, valid)

proc call*(call_603495: Call_GetMembers_603483; body: JsonNode): Recallable =
  ## getMembers
  ## Returns the details on the Security Hub member accounts that the account IDs specify.
  ##   body: JObject (required)
  var body_603496 = newJObject()
  if body != nil:
    body_603496 = body
  result = call_603495.call(nil, nil, nil, nil, body_603496)

var getMembers* = Call_GetMembers_603483(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "securityhub.amazonaws.com",
                                      route: "/members/get",
                                      validator: validate_GetMembers_603484,
                                      base: "/", url: url_GetMembers_603485,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_603497 = ref object of OpenApiRestCall_602433
proc url_InviteMembers_603499(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_InviteMembers_603498(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from. Before you can use this action to invite a member, you must first create the member account in Security Hub by using the <a>CreateMembers</a> action. When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from member account.
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
  var valid_603500 = header.getOrDefault("X-Amz-Date")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Date", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Security-Token")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Security-Token", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Content-Sha256", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Algorithm")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Algorithm", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Signature")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Signature", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-SignedHeaders", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Credential")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Credential", valid_603506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603508: Call_InviteMembers_603497; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from. Before you can use this action to invite a member, you must first create the member account in Security Hub by using the <a>CreateMembers</a> action. When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from member account.
  ## 
  let valid = call_603508.validator(path, query, header, formData, body)
  let scheme = call_603508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603508.url(scheme.get, call_603508.host, call_603508.base,
                         call_603508.route, valid.getOrDefault("path"))
  result = hook(call_603508, url, valid)

proc call*(call_603509: Call_InviteMembers_603497; body: JsonNode): Recallable =
  ## inviteMembers
  ## Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from. Before you can use this action to invite a member, you must first create the member account in Security Hub by using the <a>CreateMembers</a> action. When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from member account.
  ##   body: JObject (required)
  var body_603510 = newJObject()
  if body != nil:
    body_603510 = body
  result = call_603509.call(nil, nil, nil, nil, body_603510)

var inviteMembers* = Call_InviteMembers_603497(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/invite", validator: validate_InviteMembers_603498, base: "/",
    url: url_InviteMembers_603499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_603511 = ref object of OpenApiRestCall_602433
proc url_ListInvitations_603513(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInvitations_603512(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Paginates results. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data. 
  ##   MaxResults: JInt
  ##             : The maximum number of items that you want in the response. 
  section = newJObject()
  var valid_603514 = query.getOrDefault("NextToken")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "NextToken", valid_603514
  var valid_603515 = query.getOrDefault("MaxResults")
  valid_603515 = validateParameter(valid_603515, JInt, required = false, default = nil)
  if valid_603515 != nil:
    section.add "MaxResults", valid_603515
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
  var valid_603516 = header.getOrDefault("X-Amz-Date")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Date", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Security-Token")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Security-Token", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Content-Sha256", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Algorithm")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Algorithm", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Signature")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Signature", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-SignedHeaders", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Credential")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Credential", valid_603522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603523: Call_ListInvitations_603511; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ## 
  let valid = call_603523.validator(path, query, header, formData, body)
  let scheme = call_603523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603523.url(scheme.get, call_603523.host, call_603523.base,
                         call_603523.route, valid.getOrDefault("path"))
  result = hook(call_603523, url, valid)

proc call*(call_603524: Call_ListInvitations_603511; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## listInvitations
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data. 
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response. 
  var query_603525 = newJObject()
  add(query_603525, "NextToken", newJString(NextToken))
  add(query_603525, "MaxResults", newJInt(MaxResults))
  result = call_603524.call(nil, query_603525, nil, nil, nil)

var listInvitations* = Call_ListInvitations_603511(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_603512, base: "/",
    url: url_ListInvitations_603513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603540 = ref object of OpenApiRestCall_602433
proc url_TagResource_603542(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "ResourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_TagResource_603541(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds one or more tags to a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the resource to apply the tags to.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceArn` field"
  var valid_603543 = path.getOrDefault("ResourceArn")
  valid_603543 = validateParameter(valid_603543, JString, required = true,
                                 default = nil)
  if valid_603543 != nil:
    section.add "ResourceArn", valid_603543
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
  var valid_603544 = header.getOrDefault("X-Amz-Date")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Date", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Security-Token")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Security-Token", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-Content-Sha256", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Algorithm")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Algorithm", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Signature")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Signature", valid_603548
  var valid_603549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "X-Amz-SignedHeaders", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Credential")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Credential", valid_603550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603552: Call_TagResource_603540; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a resource.
  ## 
  let valid = call_603552.validator(path, query, header, formData, body)
  let scheme = call_603552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603552.url(scheme.get, call_603552.host, call_603552.base,
                         call_603552.route, valid.getOrDefault("path"))
  result = hook(call_603552, url, valid)

proc call*(call_603553: Call_TagResource_603540; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to apply the tags to.
  ##   body: JObject (required)
  var path_603554 = newJObject()
  var body_603555 = newJObject()
  add(path_603554, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_603555 = body
  result = call_603553.call(path_603554, nil, nil, nil, body_603555)

var tagResource* = Call_TagResource_603540(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_603541,
                                        base: "/", url: url_TagResource_603542,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603526 = ref object of OpenApiRestCall_602433
proc url_ListTagsForResource_603528(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "ResourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_ListTagsForResource_603527(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of tags associated with a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the resource to retrieve tags for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceArn` field"
  var valid_603529 = path.getOrDefault("ResourceArn")
  valid_603529 = validateParameter(valid_603529, JString, required = true,
                                 default = nil)
  if valid_603529 != nil:
    section.add "ResourceArn", valid_603529
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
  var valid_603530 = header.getOrDefault("X-Amz-Date")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Date", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Security-Token")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Security-Token", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Content-Sha256", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Algorithm")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Algorithm", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Signature")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Signature", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-SignedHeaders", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Credential")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Credential", valid_603536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603537: Call_ListTagsForResource_603526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags associated with a resource.
  ## 
  let valid = call_603537.validator(path, query, header, formData, body)
  let scheme = call_603537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603537.url(scheme.get, call_603537.host, call_603537.base,
                         call_603537.route, valid.getOrDefault("path"))
  result = hook(call_603537, url, valid)

proc call*(call_603538: Call_ListTagsForResource_603526; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags associated with a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to retrieve tags for.
  var path_603539 = newJObject()
  add(path_603539, "ResourceArn", newJString(ResourceArn))
  result = call_603538.call(path_603539, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_603526(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_603527, base: "/",
    url: url_ListTagsForResource_603528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603556 = ref object of OpenApiRestCall_602433
proc url_UntagResource_603558(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "ResourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get

proc validate_UntagResource_603557(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the resource to remove the tags from.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceArn` field"
  var valid_603559 = path.getOrDefault("ResourceArn")
  valid_603559 = validateParameter(valid_603559, JString, required = true,
                                 default = nil)
  if valid_603559 != nil:
    section.add "ResourceArn", valid_603559
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_603560 = query.getOrDefault("tagKeys")
  valid_603560 = validateParameter(valid_603560, JArray, required = true, default = nil)
  if valid_603560 != nil:
    section.add "tagKeys", valid_603560
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
  var valid_603561 = header.getOrDefault("X-Amz-Date")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-Date", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Security-Token")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Security-Token", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Content-Sha256", valid_603563
  var valid_603564 = header.getOrDefault("X-Amz-Algorithm")
  valid_603564 = validateParameter(valid_603564, JString, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "X-Amz-Algorithm", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-Signature")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Signature", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-SignedHeaders", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Credential")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Credential", valid_603567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603568: Call_UntagResource_603556; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a resource.
  ## 
  let valid = call_603568.validator(path, query, header, formData, body)
  let scheme = call_603568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603568.url(scheme.get, call_603568.host, call_603568.base,
                         call_603568.route, valid.getOrDefault("path"))
  result = hook(call_603568, url, valid)

proc call*(call_603569: Call_UntagResource_603556; tagKeys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags from a resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to remove the tags from.
  var path_603570 = newJObject()
  var query_603571 = newJObject()
  if tagKeys != nil:
    query_603571.add "tagKeys", tagKeys
  add(path_603570, "ResourceArn", newJString(ResourceArn))
  result = call_603569.call(path_603570, query_603571, nil, nil, nil)

var untagResource* = Call_UntagResource_603556(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_603557,
    base: "/", url: url_UntagResource_603558, schemes: {Scheme.Https, Scheme.Http})
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

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
