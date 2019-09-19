
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  Call_AcceptInvitation_773185 = ref object of OpenApiRestCall_772597
proc url_AcceptInvitation_773187(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AcceptInvitation_773186(path: JsonNode; query: JsonNode;
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
  var valid_773188 = header.getOrDefault("X-Amz-Date")
  valid_773188 = validateParameter(valid_773188, JString, required = false,
                                 default = nil)
  if valid_773188 != nil:
    section.add "X-Amz-Date", valid_773188
  var valid_773189 = header.getOrDefault("X-Amz-Security-Token")
  valid_773189 = validateParameter(valid_773189, JString, required = false,
                                 default = nil)
  if valid_773189 != nil:
    section.add "X-Amz-Security-Token", valid_773189
  var valid_773190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773190 = validateParameter(valid_773190, JString, required = false,
                                 default = nil)
  if valid_773190 != nil:
    section.add "X-Amz-Content-Sha256", valid_773190
  var valid_773191 = header.getOrDefault("X-Amz-Algorithm")
  valid_773191 = validateParameter(valid_773191, JString, required = false,
                                 default = nil)
  if valid_773191 != nil:
    section.add "X-Amz-Algorithm", valid_773191
  var valid_773192 = header.getOrDefault("X-Amz-Signature")
  valid_773192 = validateParameter(valid_773192, JString, required = false,
                                 default = nil)
  if valid_773192 != nil:
    section.add "X-Amz-Signature", valid_773192
  var valid_773193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773193 = validateParameter(valid_773193, JString, required = false,
                                 default = nil)
  if valid_773193 != nil:
    section.add "X-Amz-SignedHeaders", valid_773193
  var valid_773194 = header.getOrDefault("X-Amz-Credential")
  valid_773194 = validateParameter(valid_773194, JString, required = false,
                                 default = nil)
  if valid_773194 != nil:
    section.add "X-Amz-Credential", valid_773194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773196: Call_AcceptInvitation_773185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from. When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.
  ## 
  let valid = call_773196.validator(path, query, header, formData, body)
  let scheme = call_773196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773196.url(scheme.get, call_773196.host, call_773196.base,
                         call_773196.route, valid.getOrDefault("path"))
  result = hook(call_773196, url, valid)

proc call*(call_773197: Call_AcceptInvitation_773185; body: JsonNode): Recallable =
  ## acceptInvitation
  ## Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from. When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.
  ##   body: JObject (required)
  var body_773198 = newJObject()
  if body != nil:
    body_773198 = body
  result = call_773197.call(nil, nil, nil, nil, body_773198)

var acceptInvitation* = Call_AcceptInvitation_773185(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_AcceptInvitation_773186, base: "/",
    url: url_AcceptInvitation_773187, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_772933 = ref object of OpenApiRestCall_772597
proc url_GetMasterAccount_772935(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMasterAccount_772934(path: JsonNode; query: JsonNode;
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  var valid_773049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Content-Sha256", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-Algorithm")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-Algorithm", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-Signature")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Signature", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-SignedHeaders", valid_773052
  var valid_773053 = header.getOrDefault("X-Amz-Credential")
  valid_773053 = validateParameter(valid_773053, JString, required = false,
                                 default = nil)
  if valid_773053 != nil:
    section.add "X-Amz-Credential", valid_773053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773076: Call_GetMasterAccount_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the Security Hub master account to the current member account. 
  ## 
  let valid = call_773076.validator(path, query, header, formData, body)
  let scheme = call_773076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773076.url(scheme.get, call_773076.host, call_773076.base,
                         call_773076.route, valid.getOrDefault("path"))
  result = hook(call_773076, url, valid)

proc call*(call_773147: Call_GetMasterAccount_772933): Recallable =
  ## getMasterAccount
  ## Provides the details for the Security Hub master account to the current member account. 
  result = call_773147.call(nil, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_772933(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_GetMasterAccount_772934, base: "/",
    url: url_GetMasterAccount_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisableStandards_773200 = ref object of OpenApiRestCall_772597
proc url_BatchDisableStandards_773202(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDisableStandards_773201(path: JsonNode; query: JsonNode;
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
  var valid_773203 = header.getOrDefault("X-Amz-Date")
  valid_773203 = validateParameter(valid_773203, JString, required = false,
                                 default = nil)
  if valid_773203 != nil:
    section.add "X-Amz-Date", valid_773203
  var valid_773204 = header.getOrDefault("X-Amz-Security-Token")
  valid_773204 = validateParameter(valid_773204, JString, required = false,
                                 default = nil)
  if valid_773204 != nil:
    section.add "X-Amz-Security-Token", valid_773204
  var valid_773205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Content-Sha256", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Algorithm")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Algorithm", valid_773206
  var valid_773207 = header.getOrDefault("X-Amz-Signature")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-Signature", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-SignedHeaders", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Credential")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Credential", valid_773209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773211: Call_BatchDisableStandards_773200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ## 
  let valid = call_773211.validator(path, query, header, formData, body)
  let scheme = call_773211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773211.url(scheme.get, call_773211.host, call_773211.base,
                         call_773211.route, valid.getOrDefault("path"))
  result = hook(call_773211, url, valid)

proc call*(call_773212: Call_BatchDisableStandards_773200; body: JsonNode): Recallable =
  ## batchDisableStandards
  ## Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_773213 = newJObject()
  if body != nil:
    body_773213 = body
  result = call_773212.call(nil, nil, nil, nil, body_773213)

var batchDisableStandards* = Call_BatchDisableStandards_773200(
    name: "batchDisableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/deregister",
    validator: validate_BatchDisableStandards_773201, base: "/",
    url: url_BatchDisableStandards_773202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchEnableStandards_773214 = ref object of OpenApiRestCall_772597
proc url_BatchEnableStandards_773216(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchEnableStandards_773215(path: JsonNode; query: JsonNode;
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
  var valid_773217 = header.getOrDefault("X-Amz-Date")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "X-Amz-Date", valid_773217
  var valid_773218 = header.getOrDefault("X-Amz-Security-Token")
  valid_773218 = validateParameter(valid_773218, JString, required = false,
                                 default = nil)
  if valid_773218 != nil:
    section.add "X-Amz-Security-Token", valid_773218
  var valid_773219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773219 = validateParameter(valid_773219, JString, required = false,
                                 default = nil)
  if valid_773219 != nil:
    section.add "X-Amz-Content-Sha256", valid_773219
  var valid_773220 = header.getOrDefault("X-Amz-Algorithm")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Algorithm", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Signature")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Signature", valid_773221
  var valid_773222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-SignedHeaders", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Credential")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Credential", valid_773223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773225: Call_BatchEnableStandards_773214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the standards specified by the provided <code>standardsArn</code>. In this release, only CIS AWS Foundations standards are supported. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ## 
  let valid = call_773225.validator(path, query, header, formData, body)
  let scheme = call_773225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773225.url(scheme.get, call_773225.host, call_773225.base,
                         call_773225.route, valid.getOrDefault("path"))
  result = hook(call_773225, url, valid)

proc call*(call_773226: Call_BatchEnableStandards_773214; body: JsonNode): Recallable =
  ## batchEnableStandards
  ## Enables the standards specified by the provided <code>standardsArn</code>. In this release, only CIS AWS Foundations standards are supported. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_773227 = newJObject()
  if body != nil:
    body_773227 = body
  result = call_773226.call(nil, nil, nil, nil, body_773227)

var batchEnableStandards* = Call_BatchEnableStandards_773214(
    name: "batchEnableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/register",
    validator: validate_BatchEnableStandards_773215, base: "/",
    url: url_BatchEnableStandards_773216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchImportFindings_773228 = ref object of OpenApiRestCall_772597
proc url_BatchImportFindings_773230(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchImportFindings_773229(path: JsonNode; query: JsonNode;
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
  var valid_773231 = header.getOrDefault("X-Amz-Date")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Date", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-Security-Token")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-Security-Token", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Content-Sha256", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Algorithm")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Algorithm", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-Signature")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Signature", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-SignedHeaders", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-Credential")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Credential", valid_773237
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773239: Call_BatchImportFindings_773228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub. The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.
  ## 
  let valid = call_773239.validator(path, query, header, formData, body)
  let scheme = call_773239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773239.url(scheme.get, call_773239.host, call_773239.base,
                         call_773239.route, valid.getOrDefault("path"))
  result = hook(call_773239, url, valid)

proc call*(call_773240: Call_BatchImportFindings_773228; body: JsonNode): Recallable =
  ## batchImportFindings
  ## Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub. The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.
  ##   body: JObject (required)
  var body_773241 = newJObject()
  if body != nil:
    body_773241 = body
  result = call_773240.call(nil, nil, nil, nil, body_773241)

var batchImportFindings* = Call_BatchImportFindings_773228(
    name: "batchImportFindings", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/findings/import",
    validator: validate_BatchImportFindings_773229, base: "/",
    url: url_BatchImportFindings_773230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActionTarget_773242 = ref object of OpenApiRestCall_772597
proc url_CreateActionTarget_773244(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateActionTarget_773243(path: JsonNode; query: JsonNode;
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
  var valid_773245 = header.getOrDefault("X-Amz-Date")
  valid_773245 = validateParameter(valid_773245, JString, required = false,
                                 default = nil)
  if valid_773245 != nil:
    section.add "X-Amz-Date", valid_773245
  var valid_773246 = header.getOrDefault("X-Amz-Security-Token")
  valid_773246 = validateParameter(valid_773246, JString, required = false,
                                 default = nil)
  if valid_773246 != nil:
    section.add "X-Amz-Security-Token", valid_773246
  var valid_773247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Content-Sha256", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-Algorithm")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Algorithm", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-Signature")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Signature", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-SignedHeaders", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Credential")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Credential", valid_773251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773253: Call_CreateActionTarget_773242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom action target in Security Hub. You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.
  ## 
  let valid = call_773253.validator(path, query, header, formData, body)
  let scheme = call_773253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773253.url(scheme.get, call_773253.host, call_773253.base,
                         call_773253.route, valid.getOrDefault("path"))
  result = hook(call_773253, url, valid)

proc call*(call_773254: Call_CreateActionTarget_773242; body: JsonNode): Recallable =
  ## createActionTarget
  ## Creates a custom action target in Security Hub. You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.
  ##   body: JObject (required)
  var body_773255 = newJObject()
  if body != nil:
    body_773255 = body
  result = call_773254.call(nil, nil, nil, nil, body_773255)

var createActionTarget* = Call_CreateActionTarget_773242(
    name: "createActionTarget", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets",
    validator: validate_CreateActionTarget_773243, base: "/",
    url: url_CreateActionTarget_773244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInsight_773256 = ref object of OpenApiRestCall_772597
proc url_CreateInsight_773258(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateInsight_773257(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773259 = header.getOrDefault("X-Amz-Date")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-Date", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Security-Token")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Security-Token", valid_773260
  var valid_773261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773261 = validateParameter(valid_773261, JString, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "X-Amz-Content-Sha256", valid_773261
  var valid_773262 = header.getOrDefault("X-Amz-Algorithm")
  valid_773262 = validateParameter(valid_773262, JString, required = false,
                                 default = nil)
  if valid_773262 != nil:
    section.add "X-Amz-Algorithm", valid_773262
  var valid_773263 = header.getOrDefault("X-Amz-Signature")
  valid_773263 = validateParameter(valid_773263, JString, required = false,
                                 default = nil)
  if valid_773263 != nil:
    section.add "X-Amz-Signature", valid_773263
  var valid_773264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773264 = validateParameter(valid_773264, JString, required = false,
                                 default = nil)
  if valid_773264 != nil:
    section.add "X-Amz-SignedHeaders", valid_773264
  var valid_773265 = header.getOrDefault("X-Amz-Credential")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Credential", valid_773265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773267: Call_CreateInsight_773256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation. Use the <code>GroupByAttribute</code> to group the related findings in the insight.
  ## 
  let valid = call_773267.validator(path, query, header, formData, body)
  let scheme = call_773267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773267.url(scheme.get, call_773267.host, call_773267.base,
                         call_773267.route, valid.getOrDefault("path"))
  result = hook(call_773267, url, valid)

proc call*(call_773268: Call_CreateInsight_773256; body: JsonNode): Recallable =
  ## createInsight
  ## Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation. Use the <code>GroupByAttribute</code> to group the related findings in the insight.
  ##   body: JObject (required)
  var body_773269 = newJObject()
  if body != nil:
    body_773269 = body
  result = call_773268.call(nil, nil, nil, nil, body_773269)

var createInsight* = Call_CreateInsight_773256(name: "createInsight",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/insights", validator: validate_CreateInsight_773257, base: "/",
    url: url_CreateInsight_773258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_773287 = ref object of OpenApiRestCall_772597
proc url_CreateMembers_773289(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateMembers_773288(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773290 = header.getOrDefault("X-Amz-Date")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Date", valid_773290
  var valid_773291 = header.getOrDefault("X-Amz-Security-Token")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Security-Token", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Content-Sha256", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Algorithm")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Algorithm", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-Signature")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-Signature", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-SignedHeaders", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Credential")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Credential", valid_773296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773298: Call_CreateMembers_773287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. You can use the <a>EnableSecurityHub</a> to enable Security Hub.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you need to use the <a>InviteMembers</a> action, which invites the accounts to enable Security Hub and become member accounts in Security Hub. If the invitation is accepted by the account owner, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start being sent to both the member and master accounts.</p> <p>You can remove the association between the master and member accounts by using the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ## 
  let valid = call_773298.validator(path, query, header, formData, body)
  let scheme = call_773298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773298.url(scheme.get, call_773298.host, call_773298.base,
                         call_773298.route, valid.getOrDefault("path"))
  result = hook(call_773298, url, valid)

proc call*(call_773299: Call_CreateMembers_773287; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. You can use the <a>EnableSecurityHub</a> to enable Security Hub.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you need to use the <a>InviteMembers</a> action, which invites the accounts to enable Security Hub and become member accounts in Security Hub. If the invitation is accepted by the account owner, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start being sent to both the member and master accounts.</p> <p>You can remove the association between the master and member accounts by using the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ##   body: JObject (required)
  var body_773300 = newJObject()
  if body != nil:
    body_773300 = body
  result = call_773299.call(nil, nil, nil, nil, body_773300)

var createMembers* = Call_CreateMembers_773287(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/members",
    validator: validate_CreateMembers_773288, base: "/", url: url_CreateMembers_773289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_773270 = ref object of OpenApiRestCall_772597
proc url_ListMembers_773272(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListMembers_773271(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773273 = query.getOrDefault("OnlyAssociated")
  valid_773273 = validateParameter(valid_773273, JBool, required = false, default = nil)
  if valid_773273 != nil:
    section.add "OnlyAssociated", valid_773273
  var valid_773274 = query.getOrDefault("NextToken")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "NextToken", valid_773274
  var valid_773275 = query.getOrDefault("MaxResults")
  valid_773275 = validateParameter(valid_773275, JInt, required = false, default = nil)
  if valid_773275 != nil:
    section.add "MaxResults", valid_773275
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
  var valid_773276 = header.getOrDefault("X-Amz-Date")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "X-Amz-Date", valid_773276
  var valid_773277 = header.getOrDefault("X-Amz-Security-Token")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "X-Amz-Security-Token", valid_773277
  var valid_773278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Content-Sha256", valid_773278
  var valid_773279 = header.getOrDefault("X-Amz-Algorithm")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-Algorithm", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Signature")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Signature", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-SignedHeaders", valid_773281
  var valid_773282 = header.getOrDefault("X-Amz-Credential")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Credential", valid_773282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773283: Call_ListMembers_773270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current Security Hub master account.
  ## 
  let valid = call_773283.validator(path, query, header, formData, body)
  let scheme = call_773283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773283.url(scheme.get, call_773283.host, call_773283.base,
                         call_773283.route, valid.getOrDefault("path"))
  result = hook(call_773283, url, valid)

proc call*(call_773284: Call_ListMembers_773270; OnlyAssociated: bool = false;
          NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listMembers
  ## Lists details about all member accounts for the current Security Hub master account.
  ##   OnlyAssociated: bool
  ##                 : Specifies which member accounts the response includes based on their relationship status with the master account. The default value is <code>TRUE</code>. If <code>onlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>. If <code>onlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. 
  ##   NextToken: string
  ##            : Paginates results. Set the value of this parameter to <code>NULL</code> on your first call to the <code>ListMembers</code> operation. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>nextToken</code> from the previous response to continue listing data. 
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response. 
  var query_773285 = newJObject()
  add(query_773285, "OnlyAssociated", newJBool(OnlyAssociated))
  add(query_773285, "NextToken", newJString(NextToken))
  add(query_773285, "MaxResults", newJInt(MaxResults))
  result = call_773284.call(nil, query_773285, nil, nil, nil)

var listMembers* = Call_ListMembers_773270(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/members",
                                        validator: validate_ListMembers_773271,
                                        base: "/", url: url_ListMembers_773272,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_773301 = ref object of OpenApiRestCall_772597
proc url_DeclineInvitations_773303(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeclineInvitations_773302(path: JsonNode; query: JsonNode;
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
  var valid_773304 = header.getOrDefault("X-Amz-Date")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-Date", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-Security-Token")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Security-Token", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Content-Sha256", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-Algorithm")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-Algorithm", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-Signature")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Signature", valid_773308
  var valid_773309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-SignedHeaders", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-Credential")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Credential", valid_773310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773312: Call_DeclineInvitations_773301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations to become a member account.
  ## 
  let valid = call_773312.validator(path, query, header, formData, body)
  let scheme = call_773312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773312.url(scheme.get, call_773312.host, call_773312.base,
                         call_773312.route, valid.getOrDefault("path"))
  result = hook(call_773312, url, valid)

proc call*(call_773313: Call_DeclineInvitations_773301; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations to become a member account.
  ##   body: JObject (required)
  var body_773314 = newJObject()
  if body != nil:
    body_773314 = body
  result = call_773313.call(nil, nil, nil, nil, body_773314)

var declineInvitations* = Call_DeclineInvitations_773301(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/invitations/decline",
    validator: validate_DeclineInvitations_773302, base: "/",
    url: url_DeclineInvitations_773303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateActionTarget_773343 = ref object of OpenApiRestCall_772597
proc url_UpdateActionTarget_773345(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ActionTargetArn" in path, "`ActionTargetArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/actionTargets/"),
               (kind: VariableSegment, value: "ActionTargetArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateActionTarget_773344(path: JsonNode; query: JsonNode;
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
  var valid_773346 = path.getOrDefault("ActionTargetArn")
  valid_773346 = validateParameter(valid_773346, JString, required = true,
                                 default = nil)
  if valid_773346 != nil:
    section.add "ActionTargetArn", valid_773346
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
  var valid_773347 = header.getOrDefault("X-Amz-Date")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Date", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-Security-Token")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Security-Token", valid_773348
  var valid_773349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-Content-Sha256", valid_773349
  var valid_773350 = header.getOrDefault("X-Amz-Algorithm")
  valid_773350 = validateParameter(valid_773350, JString, required = false,
                                 default = nil)
  if valid_773350 != nil:
    section.add "X-Amz-Algorithm", valid_773350
  var valid_773351 = header.getOrDefault("X-Amz-Signature")
  valid_773351 = validateParameter(valid_773351, JString, required = false,
                                 default = nil)
  if valid_773351 != nil:
    section.add "X-Amz-Signature", valid_773351
  var valid_773352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773352 = validateParameter(valid_773352, JString, required = false,
                                 default = nil)
  if valid_773352 != nil:
    section.add "X-Amz-SignedHeaders", valid_773352
  var valid_773353 = header.getOrDefault("X-Amz-Credential")
  valid_773353 = validateParameter(valid_773353, JString, required = false,
                                 default = nil)
  if valid_773353 != nil:
    section.add "X-Amz-Credential", valid_773353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773355: Call_UpdateActionTarget_773343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name and description of a custom action target in Security Hub.
  ## 
  let valid = call_773355.validator(path, query, header, formData, body)
  let scheme = call_773355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773355.url(scheme.get, call_773355.host, call_773355.base,
                         call_773355.route, valid.getOrDefault("path"))
  result = hook(call_773355, url, valid)

proc call*(call_773356: Call_UpdateActionTarget_773343; body: JsonNode;
          ActionTargetArn: string): Recallable =
  ## updateActionTarget
  ## Updates the name and description of a custom action target in Security Hub.
  ##   body: JObject (required)
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to update.
  var path_773357 = newJObject()
  var body_773358 = newJObject()
  if body != nil:
    body_773358 = body
  add(path_773357, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_773356.call(path_773357, nil, nil, nil, body_773358)

var updateActionTarget* = Call_UpdateActionTarget_773343(
    name: "updateActionTarget", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_UpdateActionTarget_773344, base: "/",
    url: url_UpdateActionTarget_773345, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActionTarget_773315 = ref object of OpenApiRestCall_772597
proc url_DeleteActionTarget_773317(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ActionTargetArn" in path, "`ActionTargetArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/actionTargets/"),
               (kind: VariableSegment, value: "ActionTargetArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteActionTarget_773316(path: JsonNode; query: JsonNode;
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
  var valid_773332 = path.getOrDefault("ActionTargetArn")
  valid_773332 = validateParameter(valid_773332, JString, required = true,
                                 default = nil)
  if valid_773332 != nil:
    section.add "ActionTargetArn", valid_773332
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
  var valid_773333 = header.getOrDefault("X-Amz-Date")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Date", valid_773333
  var valid_773334 = header.getOrDefault("X-Amz-Security-Token")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "X-Amz-Security-Token", valid_773334
  var valid_773335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773335 = validateParameter(valid_773335, JString, required = false,
                                 default = nil)
  if valid_773335 != nil:
    section.add "X-Amz-Content-Sha256", valid_773335
  var valid_773336 = header.getOrDefault("X-Amz-Algorithm")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "X-Amz-Algorithm", valid_773336
  var valid_773337 = header.getOrDefault("X-Amz-Signature")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "X-Amz-Signature", valid_773337
  var valid_773338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773338 = validateParameter(valid_773338, JString, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "X-Amz-SignedHeaders", valid_773338
  var valid_773339 = header.getOrDefault("X-Amz-Credential")
  valid_773339 = validateParameter(valid_773339, JString, required = false,
                                 default = nil)
  if valid_773339 != nil:
    section.add "X-Amz-Credential", valid_773339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773340: Call_DeleteActionTarget_773315; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a custom action target from Security Hub. Deleting a custom action target doesn't affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.
  ## 
  let valid = call_773340.validator(path, query, header, formData, body)
  let scheme = call_773340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773340.url(scheme.get, call_773340.host, call_773340.base,
                         call_773340.route, valid.getOrDefault("path"))
  result = hook(call_773340, url, valid)

proc call*(call_773341: Call_DeleteActionTarget_773315; ActionTargetArn: string): Recallable =
  ## deleteActionTarget
  ## Deletes a custom action target from Security Hub. Deleting a custom action target doesn't affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to delete.
  var path_773342 = newJObject()
  add(path_773342, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_773341.call(path_773342, nil, nil, nil, nil)

var deleteActionTarget* = Call_DeleteActionTarget_773315(
    name: "deleteActionTarget", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_DeleteActionTarget_773316, base: "/",
    url: url_DeleteActionTarget_773317, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInsight_773373 = ref object of OpenApiRestCall_772597
proc url_UpdateInsight_773375(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InsightArn" in path, "`InsightArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/insights/"),
               (kind: VariableSegment, value: "InsightArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateInsight_773374(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773376 = path.getOrDefault("InsightArn")
  valid_773376 = validateParameter(valid_773376, JString, required = true,
                                 default = nil)
  if valid_773376 != nil:
    section.add "InsightArn", valid_773376
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
  var valid_773377 = header.getOrDefault("X-Amz-Date")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Date", valid_773377
  var valid_773378 = header.getOrDefault("X-Amz-Security-Token")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-Security-Token", valid_773378
  var valid_773379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "X-Amz-Content-Sha256", valid_773379
  var valid_773380 = header.getOrDefault("X-Amz-Algorithm")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "X-Amz-Algorithm", valid_773380
  var valid_773381 = header.getOrDefault("X-Amz-Signature")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "X-Amz-Signature", valid_773381
  var valid_773382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "X-Amz-SignedHeaders", valid_773382
  var valid_773383 = header.getOrDefault("X-Amz-Credential")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Credential", valid_773383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773385: Call_UpdateInsight_773373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Security Hub insight that the insight ARN specifies.
  ## 
  let valid = call_773385.validator(path, query, header, formData, body)
  let scheme = call_773385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773385.url(scheme.get, call_773385.host, call_773385.base,
                         call_773385.route, valid.getOrDefault("path"))
  result = hook(call_773385, url, valid)

proc call*(call_773386: Call_UpdateInsight_773373; InsightArn: string; body: JsonNode): Recallable =
  ## updateInsight
  ## Updates the Security Hub insight that the insight ARN specifies.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight that you want to update.
  ##   body: JObject (required)
  var path_773387 = newJObject()
  var body_773388 = newJObject()
  add(path_773387, "InsightArn", newJString(InsightArn))
  if body != nil:
    body_773388 = body
  result = call_773386.call(path_773387, nil, nil, nil, body_773388)

var updateInsight* = Call_UpdateInsight_773373(name: "updateInsight",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_UpdateInsight_773374,
    base: "/", url: url_UpdateInsight_773375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInsight_773359 = ref object of OpenApiRestCall_772597
proc url_DeleteInsight_773361(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InsightArn" in path, "`InsightArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/insights/"),
               (kind: VariableSegment, value: "InsightArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteInsight_773360(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773362 = path.getOrDefault("InsightArn")
  valid_773362 = validateParameter(valid_773362, JString, required = true,
                                 default = nil)
  if valid_773362 != nil:
    section.add "InsightArn", valid_773362
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
  var valid_773363 = header.getOrDefault("X-Amz-Date")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-Date", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-Security-Token")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Security-Token", valid_773364
  var valid_773365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Content-Sha256", valid_773365
  var valid_773366 = header.getOrDefault("X-Amz-Algorithm")
  valid_773366 = validateParameter(valid_773366, JString, required = false,
                                 default = nil)
  if valid_773366 != nil:
    section.add "X-Amz-Algorithm", valid_773366
  var valid_773367 = header.getOrDefault("X-Amz-Signature")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "X-Amz-Signature", valid_773367
  var valid_773368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773368 = validateParameter(valid_773368, JString, required = false,
                                 default = nil)
  if valid_773368 != nil:
    section.add "X-Amz-SignedHeaders", valid_773368
  var valid_773369 = header.getOrDefault("X-Amz-Credential")
  valid_773369 = validateParameter(valid_773369, JString, required = false,
                                 default = nil)
  if valid_773369 != nil:
    section.add "X-Amz-Credential", valid_773369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773370: Call_DeleteInsight_773359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ## 
  let valid = call_773370.validator(path, query, header, formData, body)
  let scheme = call_773370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773370.url(scheme.get, call_773370.host, call_773370.base,
                         call_773370.route, valid.getOrDefault("path"))
  result = hook(call_773370, url, valid)

proc call*(call_773371: Call_DeleteInsight_773359; InsightArn: string): Recallable =
  ## deleteInsight
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight to delete.
  var path_773372 = newJObject()
  add(path_773372, "InsightArn", newJString(InsightArn))
  result = call_773371.call(path_773372, nil, nil, nil, nil)

var deleteInsight* = Call_DeleteInsight_773359(name: "deleteInsight",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_DeleteInsight_773360,
    base: "/", url: url_DeleteInsight_773361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_773389 = ref object of OpenApiRestCall_772597
proc url_DeleteInvitations_773391(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteInvitations_773390(path: JsonNode; query: JsonNode;
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
  var valid_773392 = header.getOrDefault("X-Amz-Date")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Date", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-Security-Token")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Security-Token", valid_773393
  var valid_773394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-Content-Sha256", valid_773394
  var valid_773395 = header.getOrDefault("X-Amz-Algorithm")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-Algorithm", valid_773395
  var valid_773396 = header.getOrDefault("X-Amz-Signature")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-Signature", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-SignedHeaders", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-Credential")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-Credential", valid_773398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773400: Call_DeleteInvitations_773389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations received by the AWS account to become a member account.
  ## 
  let valid = call_773400.validator(path, query, header, formData, body)
  let scheme = call_773400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773400.url(scheme.get, call_773400.host, call_773400.base,
                         call_773400.route, valid.getOrDefault("path"))
  result = hook(call_773400, url, valid)

proc call*(call_773401: Call_DeleteInvitations_773389; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations received by the AWS account to become a member account.
  ##   body: JObject (required)
  var body_773402 = newJObject()
  if body != nil:
    body_773402 = body
  result = call_773401.call(nil, nil, nil, nil, body_773402)

var deleteInvitations* = Call_DeleteInvitations_773389(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/invitations/delete", validator: validate_DeleteInvitations_773390,
    base: "/", url: url_DeleteInvitations_773391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_773403 = ref object of OpenApiRestCall_772597
proc url_DeleteMembers_773405(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteMembers_773404(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773406 = header.getOrDefault("X-Amz-Date")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-Date", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Security-Token")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Security-Token", valid_773407
  var valid_773408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Content-Sha256", valid_773408
  var valid_773409 = header.getOrDefault("X-Amz-Algorithm")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Algorithm", valid_773409
  var valid_773410 = header.getOrDefault("X-Amz-Signature")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-Signature", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-SignedHeaders", valid_773411
  var valid_773412 = header.getOrDefault("X-Amz-Credential")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Credential", valid_773412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773414: Call_DeleteMembers_773403; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified member accounts from Security Hub.
  ## 
  let valid = call_773414.validator(path, query, header, formData, body)
  let scheme = call_773414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773414.url(scheme.get, call_773414.host, call_773414.base,
                         call_773414.route, valid.getOrDefault("path"))
  result = hook(call_773414, url, valid)

proc call*(call_773415: Call_DeleteMembers_773403; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes the specified member accounts from Security Hub.
  ##   body: JObject (required)
  var body_773416 = newJObject()
  if body != nil:
    body_773416 = body
  result = call_773415.call(nil, nil, nil, nil, body_773416)

var deleteMembers* = Call_DeleteMembers_773403(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/delete", validator: validate_DeleteMembers_773404, base: "/",
    url: url_DeleteMembers_773405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActionTargets_773417 = ref object of OpenApiRestCall_772597
proc url_DescribeActionTargets_773419(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeActionTargets_773418(path: JsonNode; query: JsonNode;
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
  var valid_773420 = query.getOrDefault("NextToken")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "NextToken", valid_773420
  var valid_773421 = query.getOrDefault("MaxResults")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "MaxResults", valid_773421
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
  var valid_773422 = header.getOrDefault("X-Amz-Date")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Date", valid_773422
  var valid_773423 = header.getOrDefault("X-Amz-Security-Token")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "X-Amz-Security-Token", valid_773423
  var valid_773424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773424 = validateParameter(valid_773424, JString, required = false,
                                 default = nil)
  if valid_773424 != nil:
    section.add "X-Amz-Content-Sha256", valid_773424
  var valid_773425 = header.getOrDefault("X-Amz-Algorithm")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Algorithm", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-Signature")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Signature", valid_773426
  var valid_773427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-SignedHeaders", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-Credential")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Credential", valid_773428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773430: Call_DescribeActionTargets_773417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the custom action targets in Security Hub in your account.
  ## 
  let valid = call_773430.validator(path, query, header, formData, body)
  let scheme = call_773430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773430.url(scheme.get, call_773430.host, call_773430.base,
                         call_773430.route, valid.getOrDefault("path"))
  result = hook(call_773430, url, valid)

proc call*(call_773431: Call_DescribeActionTargets_773417; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeActionTargets
  ## Returns a list of the custom action targets in Security Hub in your account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773432 = newJObject()
  var body_773433 = newJObject()
  add(query_773432, "NextToken", newJString(NextToken))
  if body != nil:
    body_773433 = body
  add(query_773432, "MaxResults", newJString(MaxResults))
  result = call_773431.call(nil, query_773432, nil, nil, body_773433)

var describeActionTargets* = Call_DescribeActionTargets_773417(
    name: "describeActionTargets", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets/get",
    validator: validate_DescribeActionTargets_773418, base: "/",
    url: url_DescribeActionTargets_773419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSecurityHub_773448 = ref object of OpenApiRestCall_772597
proc url_EnableSecurityHub_773450(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableSecurityHub_773449(path: JsonNode; query: JsonNode;
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
  var valid_773451 = header.getOrDefault("X-Amz-Date")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-Date", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Security-Token")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Security-Token", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Content-Sha256", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-Algorithm")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-Algorithm", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-Signature")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-Signature", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-SignedHeaders", valid_773456
  var valid_773457 = header.getOrDefault("X-Amz-Credential")
  valid_773457 = validateParameter(valid_773457, JString, required = false,
                                 default = nil)
  if valid_773457 != nil:
    section.add "X-Amz-Credential", valid_773457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773459: Call_EnableSecurityHub_773448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
  ## 
  let valid = call_773459.validator(path, query, header, formData, body)
  let scheme = call_773459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773459.url(scheme.get, call_773459.host, call_773459.base,
                         call_773459.route, valid.getOrDefault("path"))
  result = hook(call_773459, url, valid)

proc call*(call_773460: Call_EnableSecurityHub_773448; body: JsonNode): Recallable =
  ## enableSecurityHub
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_773461 = newJObject()
  if body != nil:
    body_773461 = body
  result = call_773460.call(nil, nil, nil, nil, body_773461)

var enableSecurityHub* = Call_EnableSecurityHub_773448(name: "enableSecurityHub",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/accounts", validator: validate_EnableSecurityHub_773449, base: "/",
    url: url_EnableSecurityHub_773450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHub_773434 = ref object of OpenApiRestCall_772597
proc url_DescribeHub_773436(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeHub_773435(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773437 = query.getOrDefault("HubArn")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "HubArn", valid_773437
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
  var valid_773438 = header.getOrDefault("X-Amz-Date")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Date", valid_773438
  var valid_773439 = header.getOrDefault("X-Amz-Security-Token")
  valid_773439 = validateParameter(valid_773439, JString, required = false,
                                 default = nil)
  if valid_773439 != nil:
    section.add "X-Amz-Security-Token", valid_773439
  var valid_773440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Content-Sha256", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Algorithm")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Algorithm", valid_773441
  var valid_773442 = header.getOrDefault("X-Amz-Signature")
  valid_773442 = validateParameter(valid_773442, JString, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "X-Amz-Signature", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-SignedHeaders", valid_773443
  var valid_773444 = header.getOrDefault("X-Amz-Credential")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-Credential", valid_773444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773445: Call_DescribeHub_773434; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ## 
  let valid = call_773445.validator(path, query, header, formData, body)
  let scheme = call_773445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773445.url(scheme.get, call_773445.host, call_773445.base,
                         call_773445.route, valid.getOrDefault("path"))
  result = hook(call_773445, url, valid)

proc call*(call_773446: Call_DescribeHub_773434; HubArn: string = ""): Recallable =
  ## describeHub
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ##   HubArn: string
  ##         : The ARN of the Hub resource to retrieve.
  var query_773447 = newJObject()
  add(query_773447, "HubArn", newJString(HubArn))
  result = call_773446.call(nil, query_773447, nil, nil, nil)

var describeHub* = Call_DescribeHub_773434(name: "describeHub",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/accounts",
                                        validator: validate_DescribeHub_773435,
                                        base: "/", url: url_DescribeHub_773436,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSecurityHub_773462 = ref object of OpenApiRestCall_772597
proc url_DisableSecurityHub_773464(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisableSecurityHub_773463(path: JsonNode; query: JsonNode;
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
  var valid_773465 = header.getOrDefault("X-Amz-Date")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Date", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-Security-Token")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Security-Token", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Content-Sha256", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Algorithm")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Algorithm", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Signature")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Signature", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-SignedHeaders", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Credential")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Credential", valid_773471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773472: Call_DisableSecurityHub_773462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub. When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and can't be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed. If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  ## 
  let valid = call_773472.validator(path, query, header, formData, body)
  let scheme = call_773472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773472.url(scheme.get, call_773472.host, call_773472.base,
                         call_773472.route, valid.getOrDefault("path"))
  result = hook(call_773472, url, valid)

proc call*(call_773473: Call_DisableSecurityHub_773462): Recallable =
  ## disableSecurityHub
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub. When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and can't be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed. If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  result = call_773473.call(nil, nil, nil, nil, nil)

var disableSecurityHub* = Call_DisableSecurityHub_773462(
    name: "disableSecurityHub", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/accounts",
    validator: validate_DisableSecurityHub_773463, base: "/",
    url: url_DisableSecurityHub_773464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProducts_773474 = ref object of OpenApiRestCall_772597
proc url_DescribeProducts_773476(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeProducts_773475(path: JsonNode; query: JsonNode;
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
  var valid_773477 = query.getOrDefault("NextToken")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "NextToken", valid_773477
  var valid_773478 = query.getOrDefault("MaxResults")
  valid_773478 = validateParameter(valid_773478, JInt, required = false, default = nil)
  if valid_773478 != nil:
    section.add "MaxResults", valid_773478
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
  var valid_773479 = header.getOrDefault("X-Amz-Date")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Date", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Security-Token")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Security-Token", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-Content-Sha256", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-Algorithm")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Algorithm", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-Signature")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-Signature", valid_773483
  var valid_773484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-SignedHeaders", valid_773484
  var valid_773485 = header.getOrDefault("X-Amz-Credential")
  valid_773485 = validateParameter(valid_773485, JString, required = false,
                                 default = nil)
  if valid_773485 != nil:
    section.add "X-Amz-Credential", valid_773485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773486: Call_DescribeProducts_773474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
  ## 
  let valid = call_773486.validator(path, query, header, formData, body)
  let scheme = call_773486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773486.url(scheme.get, call_773486.host, call_773486.base,
                         call_773486.route, valid.getOrDefault("path"))
  result = hook(call_773486, url, valid)

proc call*(call_773487: Call_DescribeProducts_773474; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## describeProducts
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
  ##   NextToken: string
  ##            : The token that is required for pagination.
  ##   MaxResults: int
  ##             : The maximum number of results to return.
  var query_773488 = newJObject()
  add(query_773488, "NextToken", newJString(NextToken))
  add(query_773488, "MaxResults", newJInt(MaxResults))
  result = call_773487.call(nil, query_773488, nil, nil, nil)

var describeProducts* = Call_DescribeProducts_773474(name: "describeProducts",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/products",
    validator: validate_DescribeProducts_773475, base: "/",
    url: url_DescribeProducts_773476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableImportFindingsForProduct_773489 = ref object of OpenApiRestCall_772597
proc url_DisableImportFindingsForProduct_773491(protocol: Scheme; host: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DisableImportFindingsForProduct_773490(path: JsonNode;
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
  var valid_773492 = path.getOrDefault("ProductSubscriptionArn")
  valid_773492 = validateParameter(valid_773492, JString, required = true,
                                 default = nil)
  if valid_773492 != nil:
    section.add "ProductSubscriptionArn", valid_773492
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
  var valid_773493 = header.getOrDefault("X-Amz-Date")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Date", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Security-Token")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Security-Token", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-Content-Sha256", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-Algorithm")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-Algorithm", valid_773496
  var valid_773497 = header.getOrDefault("X-Amz-Signature")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Signature", valid_773497
  var valid_773498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-SignedHeaders", valid_773498
  var valid_773499 = header.getOrDefault("X-Amz-Credential")
  valid_773499 = validateParameter(valid_773499, JString, required = false,
                                 default = nil)
  if valid_773499 != nil:
    section.add "X-Amz-Credential", valid_773499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773500: Call_DisableImportFindingsForProduct_773489;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disables the integration of the specified product with Security Hub. Findings from that product are no longer sent to Security Hub after the integration is disabled.
  ## 
  let valid = call_773500.validator(path, query, header, formData, body)
  let scheme = call_773500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773500.url(scheme.get, call_773500.host, call_773500.base,
                         call_773500.route, valid.getOrDefault("path"))
  result = hook(call_773500, url, valid)

proc call*(call_773501: Call_DisableImportFindingsForProduct_773489;
          ProductSubscriptionArn: string): Recallable =
  ## disableImportFindingsForProduct
  ## Disables the integration of the specified product with Security Hub. Findings from that product are no longer sent to Security Hub after the integration is disabled.
  ##   ProductSubscriptionArn: string (required)
  ##                         : The ARN of the integrated product to disable the integration for.
  var path_773502 = newJObject()
  add(path_773502, "ProductSubscriptionArn", newJString(ProductSubscriptionArn))
  result = call_773501.call(path_773502, nil, nil, nil, nil)

var disableImportFindingsForProduct* = Call_DisableImportFindingsForProduct_773489(
    name: "disableImportFindingsForProduct", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com",
    route: "/productSubscriptions/{ProductSubscriptionArn}",
    validator: validate_DisableImportFindingsForProduct_773490, base: "/",
    url: url_DisableImportFindingsForProduct_773491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_773503 = ref object of OpenApiRestCall_772597
proc url_DisassociateFromMasterAccount_773505(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateFromMasterAccount_773504(path: JsonNode; query: JsonNode;
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
  var valid_773506 = header.getOrDefault("X-Amz-Date")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Date", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Security-Token")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Security-Token", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Content-Sha256", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Algorithm")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Algorithm", valid_773509
  var valid_773510 = header.getOrDefault("X-Amz-Signature")
  valid_773510 = validateParameter(valid_773510, JString, required = false,
                                 default = nil)
  if valid_773510 != nil:
    section.add "X-Amz-Signature", valid_773510
  var valid_773511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-SignedHeaders", valid_773511
  var valid_773512 = header.getOrDefault("X-Amz-Credential")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Credential", valid_773512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773513: Call_DisassociateFromMasterAccount_773503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current Security Hub member account from the associated master account.
  ## 
  let valid = call_773513.validator(path, query, header, formData, body)
  let scheme = call_773513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773513.url(scheme.get, call_773513.host, call_773513.base,
                         call_773513.route, valid.getOrDefault("path"))
  result = hook(call_773513, url, valid)

proc call*(call_773514: Call_DisassociateFromMasterAccount_773503): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current Security Hub member account from the associated master account.
  result = call_773514.call(nil, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_773503(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_773504, base: "/",
    url: url_DisassociateFromMasterAccount_773505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_773515 = ref object of OpenApiRestCall_772597
proc url_DisassociateMembers_773517(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DisassociateMembers_773516(path: JsonNode; query: JsonNode;
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
  var valid_773518 = header.getOrDefault("X-Amz-Date")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Date", valid_773518
  var valid_773519 = header.getOrDefault("X-Amz-Security-Token")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Security-Token", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Content-Sha256", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-Algorithm")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Algorithm", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Signature")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Signature", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-SignedHeaders", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-Credential")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-Credential", valid_773524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773526: Call_DisassociateMembers_773515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified member accounts from the associated master account.
  ## 
  let valid = call_773526.validator(path, query, header, formData, body)
  let scheme = call_773526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773526.url(scheme.get, call_773526.host, call_773526.base,
                         call_773526.route, valid.getOrDefault("path"))
  result = hook(call_773526, url, valid)

proc call*(call_773527: Call_DisassociateMembers_773515; body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates the specified member accounts from the associated master account.
  ##   body: JObject (required)
  var body_773528 = newJObject()
  if body != nil:
    body_773528 = body
  result = call_773527.call(nil, nil, nil, nil, body_773528)

var disassociateMembers* = Call_DisassociateMembers_773515(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/members/disassociate",
    validator: validate_DisassociateMembers_773516, base: "/",
    url: url_DisassociateMembers_773517, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableImportFindingsForProduct_773544 = ref object of OpenApiRestCall_772597
proc url_EnableImportFindingsForProduct_773546(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_EnableImportFindingsForProduct_773545(path: JsonNode;
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
  var valid_773547 = header.getOrDefault("X-Amz-Date")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Date", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-Security-Token")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Security-Token", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-Content-Sha256", valid_773549
  var valid_773550 = header.getOrDefault("X-Amz-Algorithm")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Algorithm", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Signature")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Signature", valid_773551
  var valid_773552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-SignedHeaders", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Credential")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Credential", valid_773553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773555: Call_EnableImportFindingsForProduct_773544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub. When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.
  ## 
  let valid = call_773555.validator(path, query, header, formData, body)
  let scheme = call_773555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773555.url(scheme.get, call_773555.host, call_773555.base,
                         call_773555.route, valid.getOrDefault("path"))
  result = hook(call_773555, url, valid)

proc call*(call_773556: Call_EnableImportFindingsForProduct_773544; body: JsonNode): Recallable =
  ## enableImportFindingsForProduct
  ## Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub. When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.
  ##   body: JObject (required)
  var body_773557 = newJObject()
  if body != nil:
    body_773557 = body
  result = call_773556.call(nil, nil, nil, nil, body_773557)

var enableImportFindingsForProduct* = Call_EnableImportFindingsForProduct_773544(
    name: "enableImportFindingsForProduct", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_EnableImportFindingsForProduct_773545, base: "/",
    url: url_EnableImportFindingsForProduct_773546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnabledProductsForImport_773529 = ref object of OpenApiRestCall_772597
proc url_ListEnabledProductsForImport_773531(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListEnabledProductsForImport_773530(path: JsonNode; query: JsonNode;
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
  var valid_773532 = query.getOrDefault("NextToken")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "NextToken", valid_773532
  var valid_773533 = query.getOrDefault("MaxResults")
  valid_773533 = validateParameter(valid_773533, JInt, required = false, default = nil)
  if valid_773533 != nil:
    section.add "MaxResults", valid_773533
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
  var valid_773534 = header.getOrDefault("X-Amz-Date")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-Date", valid_773534
  var valid_773535 = header.getOrDefault("X-Amz-Security-Token")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "X-Amz-Security-Token", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Content-Sha256", valid_773536
  var valid_773537 = header.getOrDefault("X-Amz-Algorithm")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Algorithm", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Signature")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Signature", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-SignedHeaders", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Credential")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Credential", valid_773540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773541: Call_ListEnabledProductsForImport_773529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ## 
  let valid = call_773541.validator(path, query, header, formData, body)
  let scheme = call_773541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773541.url(scheme.get, call_773541.host, call_773541.base,
                         call_773541.route, valid.getOrDefault("path"))
  result = hook(call_773541, url, valid)

proc call*(call_773542: Call_ListEnabledProductsForImport_773529;
          NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listEnabledProductsForImport
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data.
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response.
  var query_773543 = newJObject()
  add(query_773543, "NextToken", newJString(NextToken))
  add(query_773543, "MaxResults", newJInt(MaxResults))
  result = call_773542.call(nil, query_773543, nil, nil, nil)

var listEnabledProductsForImport* = Call_ListEnabledProductsForImport_773529(
    name: "listEnabledProductsForImport", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_ListEnabledProductsForImport_773530, base: "/",
    url: url_ListEnabledProductsForImport_773531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnabledStandards_773558 = ref object of OpenApiRestCall_772597
proc url_GetEnabledStandards_773560(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetEnabledStandards_773559(path: JsonNode; query: JsonNode;
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
  var valid_773561 = header.getOrDefault("X-Amz-Date")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Date", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-Security-Token")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Security-Token", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Content-Sha256", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-Algorithm")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Algorithm", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-Signature")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Signature", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-SignedHeaders", valid_773566
  var valid_773567 = header.getOrDefault("X-Amz-Credential")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "X-Amz-Credential", valid_773567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773569: Call_GetEnabledStandards_773558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the standards that are currently enabled.
  ## 
  let valid = call_773569.validator(path, query, header, formData, body)
  let scheme = call_773569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773569.url(scheme.get, call_773569.host, call_773569.base,
                         call_773569.route, valid.getOrDefault("path"))
  result = hook(call_773569, url, valid)

proc call*(call_773570: Call_GetEnabledStandards_773558; body: JsonNode): Recallable =
  ## getEnabledStandards
  ## Returns a list of the standards that are currently enabled.
  ##   body: JObject (required)
  var body_773571 = newJObject()
  if body != nil:
    body_773571 = body
  result = call_773570.call(nil, nil, nil, nil, body_773571)

var getEnabledStandards* = Call_GetEnabledStandards_773558(
    name: "getEnabledStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/get",
    validator: validate_GetEnabledStandards_773559, base: "/",
    url: url_GetEnabledStandards_773560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_773572 = ref object of OpenApiRestCall_772597
proc url_GetFindings_773574(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetFindings_773573(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773575 = query.getOrDefault("NextToken")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "NextToken", valid_773575
  var valid_773576 = query.getOrDefault("MaxResults")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "MaxResults", valid_773576
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
  var valid_773577 = header.getOrDefault("X-Amz-Date")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Date", valid_773577
  var valid_773578 = header.getOrDefault("X-Amz-Security-Token")
  valid_773578 = validateParameter(valid_773578, JString, required = false,
                                 default = nil)
  if valid_773578 != nil:
    section.add "X-Amz-Security-Token", valid_773578
  var valid_773579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773579 = validateParameter(valid_773579, JString, required = false,
                                 default = nil)
  if valid_773579 != nil:
    section.add "X-Amz-Content-Sha256", valid_773579
  var valid_773580 = header.getOrDefault("X-Amz-Algorithm")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Algorithm", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Signature")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Signature", valid_773581
  var valid_773582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "X-Amz-SignedHeaders", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-Credential")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-Credential", valid_773583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773585: Call_GetFindings_773572; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of findings that match the specified criteria.
  ## 
  let valid = call_773585.validator(path, query, header, formData, body)
  let scheme = call_773585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773585.url(scheme.get, call_773585.host, call_773585.base,
                         call_773585.route, valid.getOrDefault("path"))
  result = hook(call_773585, url, valid)

proc call*(call_773586: Call_GetFindings_773572; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getFindings
  ## Returns a list of findings that match the specified criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773587 = newJObject()
  var body_773588 = newJObject()
  add(query_773587, "NextToken", newJString(NextToken))
  if body != nil:
    body_773588 = body
  add(query_773587, "MaxResults", newJString(MaxResults))
  result = call_773586.call(nil, query_773587, nil, nil, body_773588)

var getFindings* = Call_GetFindings_773572(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/findings",
                                        validator: validate_GetFindings_773573,
                                        base: "/", url: url_GetFindings_773574,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_773589 = ref object of OpenApiRestCall_772597
proc url_UpdateFindings_773591(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateFindings_773590(path: JsonNode; query: JsonNode;
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
  var valid_773592 = header.getOrDefault("X-Amz-Date")
  valid_773592 = validateParameter(valid_773592, JString, required = false,
                                 default = nil)
  if valid_773592 != nil:
    section.add "X-Amz-Date", valid_773592
  var valid_773593 = header.getOrDefault("X-Amz-Security-Token")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "X-Amz-Security-Token", valid_773593
  var valid_773594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773594 = validateParameter(valid_773594, JString, required = false,
                                 default = nil)
  if valid_773594 != nil:
    section.add "X-Amz-Content-Sha256", valid_773594
  var valid_773595 = header.getOrDefault("X-Amz-Algorithm")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Algorithm", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-Signature")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Signature", valid_773596
  var valid_773597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "X-Amz-SignedHeaders", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-Credential")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-Credential", valid_773598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773600: Call_UpdateFindings_773589; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ## 
  let valid = call_773600.validator(path, query, header, formData, body)
  let scheme = call_773600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773600.url(scheme.get, call_773600.host, call_773600.base,
                         call_773600.route, valid.getOrDefault("path"))
  result = hook(call_773600, url, valid)

proc call*(call_773601: Call_UpdateFindings_773589; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ##   body: JObject (required)
  var body_773602 = newJObject()
  if body != nil:
    body_773602 = body
  result = call_773601.call(nil, nil, nil, nil, body_773602)

var updateFindings* = Call_UpdateFindings_773589(name: "updateFindings",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/findings", validator: validate_UpdateFindings_773590, base: "/",
    url: url_UpdateFindings_773591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsightResults_773603 = ref object of OpenApiRestCall_772597
proc url_GetInsightResults_773605(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "InsightArn" in path, "`InsightArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/insights/results/"),
               (kind: VariableSegment, value: "InsightArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetInsightResults_773604(path: JsonNode; query: JsonNode;
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
  var valid_773606 = path.getOrDefault("InsightArn")
  valid_773606 = validateParameter(valid_773606, JString, required = true,
                                 default = nil)
  if valid_773606 != nil:
    section.add "InsightArn", valid_773606
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
  var valid_773607 = header.getOrDefault("X-Amz-Date")
  valid_773607 = validateParameter(valid_773607, JString, required = false,
                                 default = nil)
  if valid_773607 != nil:
    section.add "X-Amz-Date", valid_773607
  var valid_773608 = header.getOrDefault("X-Amz-Security-Token")
  valid_773608 = validateParameter(valid_773608, JString, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "X-Amz-Security-Token", valid_773608
  var valid_773609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773609 = validateParameter(valid_773609, JString, required = false,
                                 default = nil)
  if valid_773609 != nil:
    section.add "X-Amz-Content-Sha256", valid_773609
  var valid_773610 = header.getOrDefault("X-Amz-Algorithm")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Algorithm", valid_773610
  var valid_773611 = header.getOrDefault("X-Amz-Signature")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-Signature", valid_773611
  var valid_773612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "X-Amz-SignedHeaders", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-Credential")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Credential", valid_773613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773614: Call_GetInsightResults_773603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the results of the Security Hub insight that the insight ARN specifies.
  ## 
  let valid = call_773614.validator(path, query, header, formData, body)
  let scheme = call_773614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773614.url(scheme.get, call_773614.host, call_773614.base,
                         call_773614.route, valid.getOrDefault("path"))
  result = hook(call_773614, url, valid)

proc call*(call_773615: Call_GetInsightResults_773603; InsightArn: string): Recallable =
  ## getInsightResults
  ## Lists the results of the Security Hub insight that the insight ARN specifies.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight whose results you want to see.
  var path_773616 = newJObject()
  add(path_773616, "InsightArn", newJString(InsightArn))
  result = call_773615.call(path_773616, nil, nil, nil, nil)

var getInsightResults* = Call_GetInsightResults_773603(name: "getInsightResults",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/insights/results/{InsightArn}",
    validator: validate_GetInsightResults_773604, base: "/",
    url: url_GetInsightResults_773605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsights_773617 = ref object of OpenApiRestCall_772597
proc url_GetInsights_773619(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetInsights_773618(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773620 = query.getOrDefault("NextToken")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "NextToken", valid_773620
  var valid_773621 = query.getOrDefault("MaxResults")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "MaxResults", valid_773621
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
  var valid_773622 = header.getOrDefault("X-Amz-Date")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "X-Amz-Date", valid_773622
  var valid_773623 = header.getOrDefault("X-Amz-Security-Token")
  valid_773623 = validateParameter(valid_773623, JString, required = false,
                                 default = nil)
  if valid_773623 != nil:
    section.add "X-Amz-Security-Token", valid_773623
  var valid_773624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773624 = validateParameter(valid_773624, JString, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "X-Amz-Content-Sha256", valid_773624
  var valid_773625 = header.getOrDefault("X-Amz-Algorithm")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Algorithm", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-Signature")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-Signature", valid_773626
  var valid_773627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773627 = validateParameter(valid_773627, JString, required = false,
                                 default = nil)
  if valid_773627 != nil:
    section.add "X-Amz-SignedHeaders", valid_773627
  var valid_773628 = header.getOrDefault("X-Amz-Credential")
  valid_773628 = validateParameter(valid_773628, JString, required = false,
                                 default = nil)
  if valid_773628 != nil:
    section.add "X-Amz-Credential", valid_773628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773630: Call_GetInsights_773617; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists and describes insights that insight ARNs specify.
  ## 
  let valid = call_773630.validator(path, query, header, formData, body)
  let scheme = call_773630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773630.url(scheme.get, call_773630.host, call_773630.base,
                         call_773630.route, valid.getOrDefault("path"))
  result = hook(call_773630, url, valid)

proc call*(call_773631: Call_GetInsights_773617; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getInsights
  ## Lists and describes insights that insight ARNs specify.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773632 = newJObject()
  var body_773633 = newJObject()
  add(query_773632, "NextToken", newJString(NextToken))
  if body != nil:
    body_773633 = body
  add(query_773632, "MaxResults", newJString(MaxResults))
  result = call_773631.call(nil, query_773632, nil, nil, body_773633)

var getInsights* = Call_GetInsights_773617(name: "getInsights",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/insights/get",
                                        validator: validate_GetInsights_773618,
                                        base: "/", url: url_GetInsights_773619,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_773634 = ref object of OpenApiRestCall_772597
proc url_GetInvitationsCount_773636(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetInvitationsCount_773635(path: JsonNode; query: JsonNode;
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
  var valid_773637 = header.getOrDefault("X-Amz-Date")
  valid_773637 = validateParameter(valid_773637, JString, required = false,
                                 default = nil)
  if valid_773637 != nil:
    section.add "X-Amz-Date", valid_773637
  var valid_773638 = header.getOrDefault("X-Amz-Security-Token")
  valid_773638 = validateParameter(valid_773638, JString, required = false,
                                 default = nil)
  if valid_773638 != nil:
    section.add "X-Amz-Security-Token", valid_773638
  var valid_773639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773639 = validateParameter(valid_773639, JString, required = false,
                                 default = nil)
  if valid_773639 != nil:
    section.add "X-Amz-Content-Sha256", valid_773639
  var valid_773640 = header.getOrDefault("X-Amz-Algorithm")
  valid_773640 = validateParameter(valid_773640, JString, required = false,
                                 default = nil)
  if valid_773640 != nil:
    section.add "X-Amz-Algorithm", valid_773640
  var valid_773641 = header.getOrDefault("X-Amz-Signature")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "X-Amz-Signature", valid_773641
  var valid_773642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "X-Amz-SignedHeaders", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-Credential")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-Credential", valid_773643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773644: Call_GetInvitationsCount_773634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  ## 
  let valid = call_773644.validator(path, query, header, formData, body)
  let scheme = call_773644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773644.url(scheme.get, call_773644.host, call_773644.base,
                         call_773644.route, valid.getOrDefault("path"))
  result = hook(call_773644, url, valid)

proc call*(call_773645: Call_GetInvitationsCount_773634): Recallable =
  ## getInvitationsCount
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  result = call_773645.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_773634(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/invitations/count",
    validator: validate_GetInvitationsCount_773635, base: "/",
    url: url_GetInvitationsCount_773636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_773646 = ref object of OpenApiRestCall_772597
proc url_GetMembers_773648(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMembers_773647(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773649 = header.getOrDefault("X-Amz-Date")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-Date", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-Security-Token")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-Security-Token", valid_773650
  var valid_773651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773651 = validateParameter(valid_773651, JString, required = false,
                                 default = nil)
  if valid_773651 != nil:
    section.add "X-Amz-Content-Sha256", valid_773651
  var valid_773652 = header.getOrDefault("X-Amz-Algorithm")
  valid_773652 = validateParameter(valid_773652, JString, required = false,
                                 default = nil)
  if valid_773652 != nil:
    section.add "X-Amz-Algorithm", valid_773652
  var valid_773653 = header.getOrDefault("X-Amz-Signature")
  valid_773653 = validateParameter(valid_773653, JString, required = false,
                                 default = nil)
  if valid_773653 != nil:
    section.add "X-Amz-Signature", valid_773653
  var valid_773654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773654 = validateParameter(valid_773654, JString, required = false,
                                 default = nil)
  if valid_773654 != nil:
    section.add "X-Amz-SignedHeaders", valid_773654
  var valid_773655 = header.getOrDefault("X-Amz-Credential")
  valid_773655 = validateParameter(valid_773655, JString, required = false,
                                 default = nil)
  if valid_773655 != nil:
    section.add "X-Amz-Credential", valid_773655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773657: Call_GetMembers_773646; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details on the Security Hub member accounts that the account IDs specify.
  ## 
  let valid = call_773657.validator(path, query, header, formData, body)
  let scheme = call_773657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773657.url(scheme.get, call_773657.host, call_773657.base,
                         call_773657.route, valid.getOrDefault("path"))
  result = hook(call_773657, url, valid)

proc call*(call_773658: Call_GetMembers_773646; body: JsonNode): Recallable =
  ## getMembers
  ## Returns the details on the Security Hub member accounts that the account IDs specify.
  ##   body: JObject (required)
  var body_773659 = newJObject()
  if body != nil:
    body_773659 = body
  result = call_773658.call(nil, nil, nil, nil, body_773659)

var getMembers* = Call_GetMembers_773646(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "securityhub.amazonaws.com",
                                      route: "/members/get",
                                      validator: validate_GetMembers_773647,
                                      base: "/", url: url_GetMembers_773648,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_773660 = ref object of OpenApiRestCall_772597
proc url_InviteMembers_773662(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_InviteMembers_773661(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773663 = header.getOrDefault("X-Amz-Date")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Date", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-Security-Token")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-Security-Token", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-Content-Sha256", valid_773665
  var valid_773666 = header.getOrDefault("X-Amz-Algorithm")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-Algorithm", valid_773666
  var valid_773667 = header.getOrDefault("X-Amz-Signature")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-Signature", valid_773667
  var valid_773668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773668 = validateParameter(valid_773668, JString, required = false,
                                 default = nil)
  if valid_773668 != nil:
    section.add "X-Amz-SignedHeaders", valid_773668
  var valid_773669 = header.getOrDefault("X-Amz-Credential")
  valid_773669 = validateParameter(valid_773669, JString, required = false,
                                 default = nil)
  if valid_773669 != nil:
    section.add "X-Amz-Credential", valid_773669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773671: Call_InviteMembers_773660; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from. Before you can use this action to invite a member, you must first create the member account in Security Hub by using the <a>CreateMembers</a> action. When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from member account.
  ## 
  let valid = call_773671.validator(path, query, header, formData, body)
  let scheme = call_773671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773671.url(scheme.get, call_773671.host, call_773671.base,
                         call_773671.route, valid.getOrDefault("path"))
  result = hook(call_773671, url, valid)

proc call*(call_773672: Call_InviteMembers_773660; body: JsonNode): Recallable =
  ## inviteMembers
  ## Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from. Before you can use this action to invite a member, you must first create the member account in Security Hub by using the <a>CreateMembers</a> action. When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from member account.
  ##   body: JObject (required)
  var body_773673 = newJObject()
  if body != nil:
    body_773673 = body
  result = call_773672.call(nil, nil, nil, nil, body_773673)

var inviteMembers* = Call_InviteMembers_773660(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/invite", validator: validate_InviteMembers_773661, base: "/",
    url: url_InviteMembers_773662, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_773674 = ref object of OpenApiRestCall_772597
proc url_ListInvitations_773676(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInvitations_773675(path: JsonNode; query: JsonNode;
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
  var valid_773677 = query.getOrDefault("NextToken")
  valid_773677 = validateParameter(valid_773677, JString, required = false,
                                 default = nil)
  if valid_773677 != nil:
    section.add "NextToken", valid_773677
  var valid_773678 = query.getOrDefault("MaxResults")
  valid_773678 = validateParameter(valid_773678, JInt, required = false, default = nil)
  if valid_773678 != nil:
    section.add "MaxResults", valid_773678
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
  var valid_773679 = header.getOrDefault("X-Amz-Date")
  valid_773679 = validateParameter(valid_773679, JString, required = false,
                                 default = nil)
  if valid_773679 != nil:
    section.add "X-Amz-Date", valid_773679
  var valid_773680 = header.getOrDefault("X-Amz-Security-Token")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Security-Token", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-Content-Sha256", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-Algorithm")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-Algorithm", valid_773682
  var valid_773683 = header.getOrDefault("X-Amz-Signature")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "X-Amz-Signature", valid_773683
  var valid_773684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773684 = validateParameter(valid_773684, JString, required = false,
                                 default = nil)
  if valid_773684 != nil:
    section.add "X-Amz-SignedHeaders", valid_773684
  var valid_773685 = header.getOrDefault("X-Amz-Credential")
  valid_773685 = validateParameter(valid_773685, JString, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "X-Amz-Credential", valid_773685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773686: Call_ListInvitations_773674; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ## 
  let valid = call_773686.validator(path, query, header, formData, body)
  let scheme = call_773686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773686.url(scheme.get, call_773686.host, call_773686.base,
                         call_773686.route, valid.getOrDefault("path"))
  result = hook(call_773686, url, valid)

proc call*(call_773687: Call_ListInvitations_773674; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## listInvitations
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data. 
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response. 
  var query_773688 = newJObject()
  add(query_773688, "NextToken", newJString(NextToken))
  add(query_773688, "MaxResults", newJInt(MaxResults))
  result = call_773687.call(nil, query_773688, nil, nil, nil)

var listInvitations* = Call_ListInvitations_773674(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_773675, base: "/",
    url: url_ListInvitations_773676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_773703 = ref object of OpenApiRestCall_772597
proc url_TagResource_773705(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "ResourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TagResource_773704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773706 = path.getOrDefault("ResourceArn")
  valid_773706 = validateParameter(valid_773706, JString, required = true,
                                 default = nil)
  if valid_773706 != nil:
    section.add "ResourceArn", valid_773706
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
  var valid_773707 = header.getOrDefault("X-Amz-Date")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Date", valid_773707
  var valid_773708 = header.getOrDefault("X-Amz-Security-Token")
  valid_773708 = validateParameter(valid_773708, JString, required = false,
                                 default = nil)
  if valid_773708 != nil:
    section.add "X-Amz-Security-Token", valid_773708
  var valid_773709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773709 = validateParameter(valid_773709, JString, required = false,
                                 default = nil)
  if valid_773709 != nil:
    section.add "X-Amz-Content-Sha256", valid_773709
  var valid_773710 = header.getOrDefault("X-Amz-Algorithm")
  valid_773710 = validateParameter(valid_773710, JString, required = false,
                                 default = nil)
  if valid_773710 != nil:
    section.add "X-Amz-Algorithm", valid_773710
  var valid_773711 = header.getOrDefault("X-Amz-Signature")
  valid_773711 = validateParameter(valid_773711, JString, required = false,
                                 default = nil)
  if valid_773711 != nil:
    section.add "X-Amz-Signature", valid_773711
  var valid_773712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773712 = validateParameter(valid_773712, JString, required = false,
                                 default = nil)
  if valid_773712 != nil:
    section.add "X-Amz-SignedHeaders", valid_773712
  var valid_773713 = header.getOrDefault("X-Amz-Credential")
  valid_773713 = validateParameter(valid_773713, JString, required = false,
                                 default = nil)
  if valid_773713 != nil:
    section.add "X-Amz-Credential", valid_773713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773715: Call_TagResource_773703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a resource.
  ## 
  let valid = call_773715.validator(path, query, header, formData, body)
  let scheme = call_773715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773715.url(scheme.get, call_773715.host, call_773715.base,
                         call_773715.route, valid.getOrDefault("path"))
  result = hook(call_773715, url, valid)

proc call*(call_773716: Call_TagResource_773703; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to apply the tags to.
  ##   body: JObject (required)
  var path_773717 = newJObject()
  var body_773718 = newJObject()
  add(path_773717, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_773718 = body
  result = call_773716.call(path_773717, nil, nil, nil, body_773718)

var tagResource* = Call_TagResource_773703(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_773704,
                                        base: "/", url: url_TagResource_773705,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_773689 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource_773691(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "ResourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTagsForResource_773690(path: JsonNode; query: JsonNode;
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
  var valid_773692 = path.getOrDefault("ResourceArn")
  valid_773692 = validateParameter(valid_773692, JString, required = true,
                                 default = nil)
  if valid_773692 != nil:
    section.add "ResourceArn", valid_773692
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
  var valid_773693 = header.getOrDefault("X-Amz-Date")
  valid_773693 = validateParameter(valid_773693, JString, required = false,
                                 default = nil)
  if valid_773693 != nil:
    section.add "X-Amz-Date", valid_773693
  var valid_773694 = header.getOrDefault("X-Amz-Security-Token")
  valid_773694 = validateParameter(valid_773694, JString, required = false,
                                 default = nil)
  if valid_773694 != nil:
    section.add "X-Amz-Security-Token", valid_773694
  var valid_773695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Content-Sha256", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-Algorithm")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-Algorithm", valid_773696
  var valid_773697 = header.getOrDefault("X-Amz-Signature")
  valid_773697 = validateParameter(valid_773697, JString, required = false,
                                 default = nil)
  if valid_773697 != nil:
    section.add "X-Amz-Signature", valid_773697
  var valid_773698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773698 = validateParameter(valid_773698, JString, required = false,
                                 default = nil)
  if valid_773698 != nil:
    section.add "X-Amz-SignedHeaders", valid_773698
  var valid_773699 = header.getOrDefault("X-Amz-Credential")
  valid_773699 = validateParameter(valid_773699, JString, required = false,
                                 default = nil)
  if valid_773699 != nil:
    section.add "X-Amz-Credential", valid_773699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773700: Call_ListTagsForResource_773689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags associated with a resource.
  ## 
  let valid = call_773700.validator(path, query, header, formData, body)
  let scheme = call_773700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773700.url(scheme.get, call_773700.host, call_773700.base,
                         call_773700.route, valid.getOrDefault("path"))
  result = hook(call_773700, url, valid)

proc call*(call_773701: Call_ListTagsForResource_773689; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags associated with a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to retrieve tags for.
  var path_773702 = newJObject()
  add(path_773702, "ResourceArn", newJString(ResourceArn))
  result = call_773701.call(path_773702, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_773689(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_773690, base: "/",
    url: url_ListTagsForResource_773691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_773719 = ref object of OpenApiRestCall_772597
proc url_UntagResource_773721(protocol: Scheme; host: string; base: string;
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UntagResource_773720(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773722 = path.getOrDefault("ResourceArn")
  valid_773722 = validateParameter(valid_773722, JString, required = true,
                                 default = nil)
  if valid_773722 != nil:
    section.add "ResourceArn", valid_773722
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_773723 = query.getOrDefault("tagKeys")
  valid_773723 = validateParameter(valid_773723, JArray, required = true, default = nil)
  if valid_773723 != nil:
    section.add "tagKeys", valid_773723
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
  var valid_773724 = header.getOrDefault("X-Amz-Date")
  valid_773724 = validateParameter(valid_773724, JString, required = false,
                                 default = nil)
  if valid_773724 != nil:
    section.add "X-Amz-Date", valid_773724
  var valid_773725 = header.getOrDefault("X-Amz-Security-Token")
  valid_773725 = validateParameter(valid_773725, JString, required = false,
                                 default = nil)
  if valid_773725 != nil:
    section.add "X-Amz-Security-Token", valid_773725
  var valid_773726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773726 = validateParameter(valid_773726, JString, required = false,
                                 default = nil)
  if valid_773726 != nil:
    section.add "X-Amz-Content-Sha256", valid_773726
  var valid_773727 = header.getOrDefault("X-Amz-Algorithm")
  valid_773727 = validateParameter(valid_773727, JString, required = false,
                                 default = nil)
  if valid_773727 != nil:
    section.add "X-Amz-Algorithm", valid_773727
  var valid_773728 = header.getOrDefault("X-Amz-Signature")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "X-Amz-Signature", valid_773728
  var valid_773729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773729 = validateParameter(valid_773729, JString, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "X-Amz-SignedHeaders", valid_773729
  var valid_773730 = header.getOrDefault("X-Amz-Credential")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-Credential", valid_773730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773731: Call_UntagResource_773719; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a resource.
  ## 
  let valid = call_773731.validator(path, query, header, formData, body)
  let scheme = call_773731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773731.url(scheme.get, call_773731.host, call_773731.base,
                         call_773731.route, valid.getOrDefault("path"))
  result = hook(call_773731, url, valid)

proc call*(call_773732: Call_UntagResource_773719; tagKeys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags from a resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to remove the tags from.
  var path_773733 = newJObject()
  var query_773734 = newJObject()
  if tagKeys != nil:
    query_773734.add "tagKeys", tagKeys
  add(path_773733, "ResourceArn", newJString(ResourceArn))
  result = call_773732.call(path_773733, query_773734, nil, nil, nil)

var untagResource* = Call_UntagResource_773719(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_773720,
    base: "/", url: url_UntagResource_773721, schemes: {Scheme.Https, Scheme.Http})
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
