
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS SecurityHub
## version: 2018-10-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Security Hub provides you with a comprehensive view of the security state of your AWS environment and resources. It also provides you with the compliance status of your environment based on controls from supported standards. Security Hub collects security data from AWS accounts, services, and integrated third-party products and helps you analyze security trends in your environment to identify the highest priority security issues. For more information about Security Hub, see the <i> <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html">AWS Security Hub User Guide</a> </i>.</p> <p>When you use operations in the Security Hub API, the requests are executed only in the AWS Region that is currently active or in the specific AWS Region that you specify in your request. Any configuration or settings change that results from the operation is applied only to that Region. To make the same change in other Regions, execute the same command for each Region to apply the change to.</p> <p>For example, if your Region is set to <code>us-west-2</code>, when you use <code> <a>CreateMembers</a> </code> to add a member account to Security Hub, the association of the member account with the master account is created only in the <code>us-west-2</code> Region. Security Hub must be enabled for the member account in the same Region that the invitation was sent from.</p> <p>The following throttling limits apply to using Security Hub API operations.</p> <ul> <li> <p> <code> <a>GetFindings</a> </code> - <code>RateLimit</code> of 3 requests per second. <code>BurstLimit</code> of 6 requests per second.</p> </li> <li> <p> <code> <a>UpdateFindings</a> </code> - <code>RateLimit</code> of 1 request per second. <code>BurstLimit</code> of 5 requests per second.</p> </li> <li> <p>All other operations - <code>RateLimit</code> of 10 requests per second. <code>BurstLimit</code> of 30 requests per second.</p> </li> </ul>
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AcceptInvitation_611248 = ref object of OpenApiRestCall_610658
proc url_AcceptInvitation_611250(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptInvitation_611249(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from.</p> <p>When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.</p>
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
  var valid_611251 = header.getOrDefault("X-Amz-Signature")
  valid_611251 = validateParameter(valid_611251, JString, required = false,
                                 default = nil)
  if valid_611251 != nil:
    section.add "X-Amz-Signature", valid_611251
  var valid_611252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611252 = validateParameter(valid_611252, JString, required = false,
                                 default = nil)
  if valid_611252 != nil:
    section.add "X-Amz-Content-Sha256", valid_611252
  var valid_611253 = header.getOrDefault("X-Amz-Date")
  valid_611253 = validateParameter(valid_611253, JString, required = false,
                                 default = nil)
  if valid_611253 != nil:
    section.add "X-Amz-Date", valid_611253
  var valid_611254 = header.getOrDefault("X-Amz-Credential")
  valid_611254 = validateParameter(valid_611254, JString, required = false,
                                 default = nil)
  if valid_611254 != nil:
    section.add "X-Amz-Credential", valid_611254
  var valid_611255 = header.getOrDefault("X-Amz-Security-Token")
  valid_611255 = validateParameter(valid_611255, JString, required = false,
                                 default = nil)
  if valid_611255 != nil:
    section.add "X-Amz-Security-Token", valid_611255
  var valid_611256 = header.getOrDefault("X-Amz-Algorithm")
  valid_611256 = validateParameter(valid_611256, JString, required = false,
                                 default = nil)
  if valid_611256 != nil:
    section.add "X-Amz-Algorithm", valid_611256
  var valid_611257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-SignedHeaders", valid_611257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611259: Call_AcceptInvitation_611248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from.</p> <p>When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.</p>
  ## 
  let valid = call_611259.validator(path, query, header, formData, body)
  let scheme = call_611259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611259.url(scheme.get, call_611259.host, call_611259.base,
                         call_611259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611259, url, valid)

proc call*(call_611260: Call_AcceptInvitation_611248; body: JsonNode): Recallable =
  ## acceptInvitation
  ## <p>Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from.</p> <p>When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.</p>
  ##   body: JObject (required)
  var body_611261 = newJObject()
  if body != nil:
    body_611261 = body
  result = call_611260.call(nil, nil, nil, nil, body_611261)

var acceptInvitation* = Call_AcceptInvitation_611248(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_AcceptInvitation_611249, base: "/",
    url: url_AcceptInvitation_611250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_610996 = ref object of OpenApiRestCall_610658
proc url_GetMasterAccount_610998(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMasterAccount_610997(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Provides the details for the Security Hub master account for the current member account. 
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
  var valid_611110 = header.getOrDefault("X-Amz-Signature")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "X-Amz-Signature", valid_611110
  var valid_611111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "X-Amz-Content-Sha256", valid_611111
  var valid_611112 = header.getOrDefault("X-Amz-Date")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Date", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Credential")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Credential", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Security-Token")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Security-Token", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Algorithm")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Algorithm", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-SignedHeaders", valid_611116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611139: Call_GetMasterAccount_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the Security Hub master account for the current member account. 
  ## 
  let valid = call_611139.validator(path, query, header, formData, body)
  let scheme = call_611139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611139.url(scheme.get, call_611139.host, call_611139.base,
                         call_611139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611139, url, valid)

proc call*(call_611210: Call_GetMasterAccount_610996): Recallable =
  ## getMasterAccount
  ## Provides the details for the Security Hub master account for the current member account. 
  result = call_611210.call(nil, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_610996(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_GetMasterAccount_610997, base: "/",
    url: url_GetMasterAccount_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisableStandards_611263 = ref object of OpenApiRestCall_610658
proc url_BatchDisableStandards_611265(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDisableStandards_611264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Compliance Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
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
  var valid_611266 = header.getOrDefault("X-Amz-Signature")
  valid_611266 = validateParameter(valid_611266, JString, required = false,
                                 default = nil)
  if valid_611266 != nil:
    section.add "X-Amz-Signature", valid_611266
  var valid_611267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611267 = validateParameter(valid_611267, JString, required = false,
                                 default = nil)
  if valid_611267 != nil:
    section.add "X-Amz-Content-Sha256", valid_611267
  var valid_611268 = header.getOrDefault("X-Amz-Date")
  valid_611268 = validateParameter(valid_611268, JString, required = false,
                                 default = nil)
  if valid_611268 != nil:
    section.add "X-Amz-Date", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Credential")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Credential", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Security-Token")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Security-Token", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Algorithm")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Algorithm", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-SignedHeaders", valid_611272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611274: Call_BatchDisableStandards_611263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Compliance Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
  ## 
  let valid = call_611274.validator(path, query, header, formData, body)
  let scheme = call_611274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611274.url(scheme.get, call_611274.host, call_611274.base,
                         call_611274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611274, url, valid)

proc call*(call_611275: Call_BatchDisableStandards_611263; body: JsonNode): Recallable =
  ## batchDisableStandards
  ## <p>Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Compliance Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
  ##   body: JObject (required)
  var body_611276 = newJObject()
  if body != nil:
    body_611276 = body
  result = call_611275.call(nil, nil, nil, nil, body_611276)

var batchDisableStandards* = Call_BatchDisableStandards_611263(
    name: "batchDisableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/deregister",
    validator: validate_BatchDisableStandards_611264, base: "/",
    url: url_BatchDisableStandards_611265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchEnableStandards_611277 = ref object of OpenApiRestCall_610658
proc url_BatchEnableStandards_611279(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchEnableStandards_611278(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables the standards specified by the provided <code>StandardsArn</code>. To obtain the ARN for a standard, use the <code> <a>DescribeStandards</a> </code> operation.</p> <p>For more information, see the <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Compliance Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
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
  var valid_611280 = header.getOrDefault("X-Amz-Signature")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-Signature", valid_611280
  var valid_611281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "X-Amz-Content-Sha256", valid_611281
  var valid_611282 = header.getOrDefault("X-Amz-Date")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "X-Amz-Date", valid_611282
  var valid_611283 = header.getOrDefault("X-Amz-Credential")
  valid_611283 = validateParameter(valid_611283, JString, required = false,
                                 default = nil)
  if valid_611283 != nil:
    section.add "X-Amz-Credential", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Security-Token")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Security-Token", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Algorithm")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Algorithm", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-SignedHeaders", valid_611286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611288: Call_BatchEnableStandards_611277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the standards specified by the provided <code>StandardsArn</code>. To obtain the ARN for a standard, use the <code> <a>DescribeStandards</a> </code> operation.</p> <p>For more information, see the <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Compliance Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
  ## 
  let valid = call_611288.validator(path, query, header, formData, body)
  let scheme = call_611288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611288.url(scheme.get, call_611288.host, call_611288.base,
                         call_611288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611288, url, valid)

proc call*(call_611289: Call_BatchEnableStandards_611277; body: JsonNode): Recallable =
  ## batchEnableStandards
  ## <p>Enables the standards specified by the provided <code>StandardsArn</code>. To obtain the ARN for a standard, use the <code> <a>DescribeStandards</a> </code> operation.</p> <p>For more information, see the <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Compliance Standards</a> section of the <i>AWS Security Hub User Guide</i>.</p>
  ##   body: JObject (required)
  var body_611290 = newJObject()
  if body != nil:
    body_611290 = body
  result = call_611289.call(nil, nil, nil, nil, body_611290)

var batchEnableStandards* = Call_BatchEnableStandards_611277(
    name: "batchEnableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/register",
    validator: validate_BatchEnableStandards_611278, base: "/",
    url: url_BatchEnableStandards_611279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchImportFindings_611291 = ref object of OpenApiRestCall_610658
proc url_BatchImportFindings_611293(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchImportFindings_611292(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub.</p> <p>The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.</p>
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
  var valid_611294 = header.getOrDefault("X-Amz-Signature")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Signature", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Content-Sha256", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-Date")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Date", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Credential")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Credential", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Security-Token")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Security-Token", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Algorithm")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Algorithm", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-SignedHeaders", valid_611300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611302: Call_BatchImportFindings_611291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub.</p> <p>The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.</p>
  ## 
  let valid = call_611302.validator(path, query, header, formData, body)
  let scheme = call_611302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611302.url(scheme.get, call_611302.host, call_611302.base,
                         call_611302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611302, url, valid)

proc call*(call_611303: Call_BatchImportFindings_611291; body: JsonNode): Recallable =
  ## batchImportFindings
  ## <p>Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub.</p> <p>The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.</p>
  ##   body: JObject (required)
  var body_611304 = newJObject()
  if body != nil:
    body_611304 = body
  result = call_611303.call(nil, nil, nil, nil, body_611304)

var batchImportFindings* = Call_BatchImportFindings_611291(
    name: "batchImportFindings", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/findings/import",
    validator: validate_BatchImportFindings_611292, base: "/",
    url: url_BatchImportFindings_611293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActionTarget_611305 = ref object of OpenApiRestCall_610658
proc url_CreateActionTarget_611307(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateActionTarget_611306(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates a custom action target in Security Hub.</p> <p>You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.</p>
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
  var valid_611308 = header.getOrDefault("X-Amz-Signature")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Signature", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Content-Sha256", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Date")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Date", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Credential")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Credential", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Security-Token")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Security-Token", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Algorithm")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Algorithm", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-SignedHeaders", valid_611314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611316: Call_CreateActionTarget_611305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a custom action target in Security Hub.</p> <p>You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.</p>
  ## 
  let valid = call_611316.validator(path, query, header, formData, body)
  let scheme = call_611316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611316.url(scheme.get, call_611316.host, call_611316.base,
                         call_611316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611316, url, valid)

proc call*(call_611317: Call_CreateActionTarget_611305; body: JsonNode): Recallable =
  ## createActionTarget
  ## <p>Creates a custom action target in Security Hub.</p> <p>You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.</p>
  ##   body: JObject (required)
  var body_611318 = newJObject()
  if body != nil:
    body_611318 = body
  result = call_611317.call(nil, nil, nil, nil, body_611318)

var createActionTarget* = Call_CreateActionTarget_611305(
    name: "createActionTarget", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets",
    validator: validate_CreateActionTarget_611306, base: "/",
    url: url_CreateActionTarget_611307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInsight_611319 = ref object of OpenApiRestCall_610658
proc url_CreateInsight_611321(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInsight_611320(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation.</p> <p>To group the related findings in the insight, use the <code>GroupByAttribute</code>.</p>
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
  var valid_611322 = header.getOrDefault("X-Amz-Signature")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Signature", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Content-Sha256", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Date")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Date", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Credential")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Credential", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Security-Token")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Security-Token", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Algorithm")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Algorithm", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-SignedHeaders", valid_611328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611330: Call_CreateInsight_611319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation.</p> <p>To group the related findings in the insight, use the <code>GroupByAttribute</code>.</p>
  ## 
  let valid = call_611330.validator(path, query, header, formData, body)
  let scheme = call_611330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611330.url(scheme.get, call_611330.host, call_611330.base,
                         call_611330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611330, url, valid)

proc call*(call_611331: Call_CreateInsight_611319; body: JsonNode): Recallable =
  ## createInsight
  ## <p>Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation.</p> <p>To group the related findings in the insight, use the <code>GroupByAttribute</code>.</p>
  ##   body: JObject (required)
  var body_611332 = newJObject()
  if body != nil:
    body_611332 = body
  result = call_611331.call(nil, nil, nil, nil, body_611332)

var createInsight* = Call_CreateInsight_611319(name: "createInsight",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/insights", validator: validate_CreateInsight_611320, base: "/",
    url: url_CreateInsight_611321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_611350 = ref object of OpenApiRestCall_610658
proc url_CreateMembers_611352(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMembers_611351(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. To enable Security Hub, you can use the <code> <a>EnableSecurityHub</a> </code> operation.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you must use the <code> <a>InviteMembers</a> </code> operation to invite the accounts to enable Security Hub and become member accounts in Security Hub.</p> <p>If the account owner accepts the invitation, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start to be sent to both the member and master accounts.</p> <p>To remove the association between the master and member accounts, use the <code> <a>DisassociateFromMasterAccount</a> </code> or <code> <a>DisassociateMembers</a> </code> operation.</p>
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
  var valid_611353 = header.getOrDefault("X-Amz-Signature")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Signature", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Content-Sha256", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Date")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Date", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Credential")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Credential", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Security-Token")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Security-Token", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-Algorithm")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Algorithm", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-SignedHeaders", valid_611359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611361: Call_CreateMembers_611350; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. To enable Security Hub, you can use the <code> <a>EnableSecurityHub</a> </code> operation.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you must use the <code> <a>InviteMembers</a> </code> operation to invite the accounts to enable Security Hub and become member accounts in Security Hub.</p> <p>If the account owner accepts the invitation, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start to be sent to both the member and master accounts.</p> <p>To remove the association between the master and member accounts, use the <code> <a>DisassociateFromMasterAccount</a> </code> or <code> <a>DisassociateMembers</a> </code> operation.</p>
  ## 
  let valid = call_611361.validator(path, query, header, formData, body)
  let scheme = call_611361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611361.url(scheme.get, call_611361.host, call_611361.base,
                         call_611361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611361, url, valid)

proc call*(call_611362: Call_CreateMembers_611350; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. To enable Security Hub, you can use the <code> <a>EnableSecurityHub</a> </code> operation.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you must use the <code> <a>InviteMembers</a> </code> operation to invite the accounts to enable Security Hub and become member accounts in Security Hub.</p> <p>If the account owner accepts the invitation, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start to be sent to both the member and master accounts.</p> <p>To remove the association between the master and member accounts, use the <code> <a>DisassociateFromMasterAccount</a> </code> or <code> <a>DisassociateMembers</a> </code> operation.</p>
  ##   body: JObject (required)
  var body_611363 = newJObject()
  if body != nil:
    body_611363 = body
  result = call_611362.call(nil, nil, nil, nil, body_611363)

var createMembers* = Call_CreateMembers_611350(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/members",
    validator: validate_CreateMembers_611351, base: "/", url: url_CreateMembers_611352,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_611333 = ref object of OpenApiRestCall_610658
proc url_ListMembers_611335(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMembers_611334(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists details about all member accounts for the current Security Hub master account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum number of items to return in the response. 
  ##   NextToken: JString
  ##            : <p>The token that is required for pagination. On your first call to the <code>ListMembers</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   OnlyAssociated: JBool
  ##                 : <p>Specifies which member accounts to include in the response based on their relationship status with the master account. The default value is <code>TRUE</code>.</p> <p>If <code>OnlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>.</p> <p>If <code>OnlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. </p>
  section = newJObject()
  var valid_611336 = query.getOrDefault("MaxResults")
  valid_611336 = validateParameter(valid_611336, JInt, required = false, default = nil)
  if valid_611336 != nil:
    section.add "MaxResults", valid_611336
  var valid_611337 = query.getOrDefault("NextToken")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "NextToken", valid_611337
  var valid_611338 = query.getOrDefault("OnlyAssociated")
  valid_611338 = validateParameter(valid_611338, JBool, required = false, default = nil)
  if valid_611338 != nil:
    section.add "OnlyAssociated", valid_611338
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
  var valid_611339 = header.getOrDefault("X-Amz-Signature")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Signature", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Content-Sha256", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Date")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Date", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Credential")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Credential", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-Security-Token")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Security-Token", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Algorithm")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Algorithm", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-SignedHeaders", valid_611345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611346: Call_ListMembers_611333; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current Security Hub master account.
  ## 
  let valid = call_611346.validator(path, query, header, formData, body)
  let scheme = call_611346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611346.url(scheme.get, call_611346.host, call_611346.base,
                         call_611346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611346, url, valid)

proc call*(call_611347: Call_ListMembers_611333; MaxResults: int = 0;
          NextToken: string = ""; OnlyAssociated: bool = false): Recallable =
  ## listMembers
  ## Lists details about all member accounts for the current Security Hub master account.
  ##   MaxResults: int
  ##             : The maximum number of items to return in the response. 
  ##   NextToken: string
  ##            : <p>The token that is required for pagination. On your first call to the <code>ListMembers</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  ##   OnlyAssociated: bool
  ##                 : <p>Specifies which member accounts to include in the response based on their relationship status with the master account. The default value is <code>TRUE</code>.</p> <p>If <code>OnlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>.</p> <p>If <code>OnlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. </p>
  var query_611348 = newJObject()
  add(query_611348, "MaxResults", newJInt(MaxResults))
  add(query_611348, "NextToken", newJString(NextToken))
  add(query_611348, "OnlyAssociated", newJBool(OnlyAssociated))
  result = call_611347.call(nil, query_611348, nil, nil, nil)

var listMembers* = Call_ListMembers_611333(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/members",
                                        validator: validate_ListMembers_611334,
                                        base: "/", url: url_ListMembers_611335,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_611364 = ref object of OpenApiRestCall_610658
proc url_DeclineInvitations_611366(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeclineInvitations_611365(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611367 = header.getOrDefault("X-Amz-Signature")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Signature", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Content-Sha256", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Date")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Date", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Credential")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Credential", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Security-Token")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Security-Token", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Algorithm")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Algorithm", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-SignedHeaders", valid_611373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611375: Call_DeclineInvitations_611364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations to become a member account.
  ## 
  let valid = call_611375.validator(path, query, header, formData, body)
  let scheme = call_611375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611375.url(scheme.get, call_611375.host, call_611375.base,
                         call_611375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611375, url, valid)

proc call*(call_611376: Call_DeclineInvitations_611364; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations to become a member account.
  ##   body: JObject (required)
  var body_611377 = newJObject()
  if body != nil:
    body_611377 = body
  result = call_611376.call(nil, nil, nil, nil, body_611377)

var declineInvitations* = Call_DeclineInvitations_611364(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/invitations/decline",
    validator: validate_DeclineInvitations_611365, base: "/",
    url: url_DeclineInvitations_611366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateActionTarget_611406 = ref object of OpenApiRestCall_610658
proc url_UpdateActionTarget_611408(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ActionTargetArn" in path, "`ActionTargetArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/actionTargets/"),
               (kind: VariableSegment, value: "ActionTargetArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateActionTarget_611407(path: JsonNode; query: JsonNode;
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
  var valid_611409 = path.getOrDefault("ActionTargetArn")
  valid_611409 = validateParameter(valid_611409, JString, required = true,
                                 default = nil)
  if valid_611409 != nil:
    section.add "ActionTargetArn", valid_611409
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
  var valid_611410 = header.getOrDefault("X-Amz-Signature")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Signature", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Content-Sha256", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Date")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Date", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Credential")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Credential", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Security-Token")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Security-Token", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Algorithm")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Algorithm", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-SignedHeaders", valid_611416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611418: Call_UpdateActionTarget_611406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name and description of a custom action target in Security Hub.
  ## 
  let valid = call_611418.validator(path, query, header, formData, body)
  let scheme = call_611418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611418.url(scheme.get, call_611418.host, call_611418.base,
                         call_611418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611418, url, valid)

proc call*(call_611419: Call_UpdateActionTarget_611406; ActionTargetArn: string;
          body: JsonNode): Recallable =
  ## updateActionTarget
  ## Updates the name and description of a custom action target in Security Hub.
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to update.
  ##   body: JObject (required)
  var path_611420 = newJObject()
  var body_611421 = newJObject()
  add(path_611420, "ActionTargetArn", newJString(ActionTargetArn))
  if body != nil:
    body_611421 = body
  result = call_611419.call(path_611420, nil, nil, nil, body_611421)

var updateActionTarget* = Call_UpdateActionTarget_611406(
    name: "updateActionTarget", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_UpdateActionTarget_611407, base: "/",
    url: url_UpdateActionTarget_611408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActionTarget_611378 = ref object of OpenApiRestCall_610658
proc url_DeleteActionTarget_611380(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ActionTargetArn" in path, "`ActionTargetArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/actionTargets/"),
               (kind: VariableSegment, value: "ActionTargetArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteActionTarget_611379(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes a custom action target from Security Hub.</p> <p>Deleting a custom action target does not affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ActionTargetArn: JString (required)
  ##                  : The ARN of the custom action target to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ActionTargetArn` field"
  var valid_611395 = path.getOrDefault("ActionTargetArn")
  valid_611395 = validateParameter(valid_611395, JString, required = true,
                                 default = nil)
  if valid_611395 != nil:
    section.add "ActionTargetArn", valid_611395
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
  var valid_611396 = header.getOrDefault("X-Amz-Signature")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Signature", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Content-Sha256", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Date")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Date", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Credential")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Credential", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-Security-Token")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Security-Token", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Algorithm")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Algorithm", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-SignedHeaders", valid_611402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611403: Call_DeleteActionTarget_611378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a custom action target from Security Hub.</p> <p>Deleting a custom action target does not affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.</p>
  ## 
  let valid = call_611403.validator(path, query, header, formData, body)
  let scheme = call_611403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611403.url(scheme.get, call_611403.host, call_611403.base,
                         call_611403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611403, url, valid)

proc call*(call_611404: Call_DeleteActionTarget_611378; ActionTargetArn: string): Recallable =
  ## deleteActionTarget
  ## <p>Deletes a custom action target from Security Hub.</p> <p>Deleting a custom action target does not affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.</p>
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to delete.
  var path_611405 = newJObject()
  add(path_611405, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_611404.call(path_611405, nil, nil, nil, nil)

var deleteActionTarget* = Call_DeleteActionTarget_611378(
    name: "deleteActionTarget", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_DeleteActionTarget_611379, base: "/",
    url: url_DeleteActionTarget_611380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInsight_611436 = ref object of OpenApiRestCall_610658
proc url_UpdateInsight_611438(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InsightArn" in path, "`InsightArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/insights/"),
               (kind: VariableSegment, value: "InsightArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateInsight_611437(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the Security Hub insight identified by the specified insight ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InsightArn: JString (required)
  ##             : The ARN of the insight that you want to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InsightArn` field"
  var valid_611439 = path.getOrDefault("InsightArn")
  valid_611439 = validateParameter(valid_611439, JString, required = true,
                                 default = nil)
  if valid_611439 != nil:
    section.add "InsightArn", valid_611439
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
  var valid_611440 = header.getOrDefault("X-Amz-Signature")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Signature", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Content-Sha256", valid_611441
  var valid_611442 = header.getOrDefault("X-Amz-Date")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-Date", valid_611442
  var valid_611443 = header.getOrDefault("X-Amz-Credential")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-Credential", valid_611443
  var valid_611444 = header.getOrDefault("X-Amz-Security-Token")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Security-Token", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Algorithm")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Algorithm", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-SignedHeaders", valid_611446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611448: Call_UpdateInsight_611436; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Security Hub insight identified by the specified insight ARN.
  ## 
  let valid = call_611448.validator(path, query, header, formData, body)
  let scheme = call_611448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611448.url(scheme.get, call_611448.host, call_611448.base,
                         call_611448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611448, url, valid)

proc call*(call_611449: Call_UpdateInsight_611436; InsightArn: string; body: JsonNode): Recallable =
  ## updateInsight
  ## Updates the Security Hub insight identified by the specified insight ARN.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight that you want to update.
  ##   body: JObject (required)
  var path_611450 = newJObject()
  var body_611451 = newJObject()
  add(path_611450, "InsightArn", newJString(InsightArn))
  if body != nil:
    body_611451 = body
  result = call_611449.call(path_611450, nil, nil, nil, body_611451)

var updateInsight* = Call_UpdateInsight_611436(name: "updateInsight",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_UpdateInsight_611437,
    base: "/", url: url_UpdateInsight_611438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInsight_611422 = ref object of OpenApiRestCall_610658
proc url_DeleteInsight_611424(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InsightArn" in path, "`InsightArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/insights/"),
               (kind: VariableSegment, value: "InsightArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteInsight_611423(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611425 = path.getOrDefault("InsightArn")
  valid_611425 = validateParameter(valid_611425, JString, required = true,
                                 default = nil)
  if valid_611425 != nil:
    section.add "InsightArn", valid_611425
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
  var valid_611426 = header.getOrDefault("X-Amz-Signature")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Signature", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Content-Sha256", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Date")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Date", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Credential")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Credential", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Security-Token")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Security-Token", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Algorithm")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Algorithm", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-SignedHeaders", valid_611432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611433: Call_DeleteInsight_611422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ## 
  let valid = call_611433.validator(path, query, header, formData, body)
  let scheme = call_611433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611433.url(scheme.get, call_611433.host, call_611433.base,
                         call_611433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611433, url, valid)

proc call*(call_611434: Call_DeleteInsight_611422; InsightArn: string): Recallable =
  ## deleteInsight
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight to delete.
  var path_611435 = newJObject()
  add(path_611435, "InsightArn", newJString(InsightArn))
  result = call_611434.call(path_611435, nil, nil, nil, nil)

var deleteInsight* = Call_DeleteInsight_611422(name: "deleteInsight",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_DeleteInsight_611423,
    base: "/", url: url_DeleteInsight_611424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_611452 = ref object of OpenApiRestCall_610658
proc url_DeleteInvitations_611454(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInvitations_611453(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611455 = header.getOrDefault("X-Amz-Signature")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Signature", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Content-Sha256", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-Date")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Date", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-Credential")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Credential", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Security-Token")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Security-Token", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-Algorithm")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Algorithm", valid_611460
  var valid_611461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-SignedHeaders", valid_611461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611463: Call_DeleteInvitations_611452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations received by the AWS account to become a member account.
  ## 
  let valid = call_611463.validator(path, query, header, formData, body)
  let scheme = call_611463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611463.url(scheme.get, call_611463.host, call_611463.base,
                         call_611463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611463, url, valid)

proc call*(call_611464: Call_DeleteInvitations_611452; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations received by the AWS account to become a member account.
  ##   body: JObject (required)
  var body_611465 = newJObject()
  if body != nil:
    body_611465 = body
  result = call_611464.call(nil, nil, nil, nil, body_611465)

var deleteInvitations* = Call_DeleteInvitations_611452(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/invitations/delete", validator: validate_DeleteInvitations_611453,
    base: "/", url: url_DeleteInvitations_611454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_611466 = ref object of OpenApiRestCall_610658
proc url_DeleteMembers_611468(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMembers_611467(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611469 = header.getOrDefault("X-Amz-Signature")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Signature", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Content-Sha256", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-Date")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Date", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-Credential")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-Credential", valid_611472
  var valid_611473 = header.getOrDefault("X-Amz-Security-Token")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Security-Token", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-Algorithm")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Algorithm", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-SignedHeaders", valid_611475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611477: Call_DeleteMembers_611466; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified member accounts from Security Hub.
  ## 
  let valid = call_611477.validator(path, query, header, formData, body)
  let scheme = call_611477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611477.url(scheme.get, call_611477.host, call_611477.base,
                         call_611477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611477, url, valid)

proc call*(call_611478: Call_DeleteMembers_611466; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes the specified member accounts from Security Hub.
  ##   body: JObject (required)
  var body_611479 = newJObject()
  if body != nil:
    body_611479 = body
  result = call_611478.call(nil, nil, nil, nil, body_611479)

var deleteMembers* = Call_DeleteMembers_611466(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/delete", validator: validate_DeleteMembers_611467, base: "/",
    url: url_DeleteMembers_611468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActionTargets_611480 = ref object of OpenApiRestCall_610658
proc url_DescribeActionTargets_611482(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeActionTargets_611481(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the custom action targets in Security Hub in your account.
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
  var valid_611483 = query.getOrDefault("MaxResults")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "MaxResults", valid_611483
  var valid_611484 = query.getOrDefault("NextToken")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "NextToken", valid_611484
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
  var valid_611485 = header.getOrDefault("X-Amz-Signature")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Signature", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Content-Sha256", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-Date")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Date", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-Credential")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-Credential", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-Security-Token")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Security-Token", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-Algorithm")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Algorithm", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-SignedHeaders", valid_611491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611493: Call_DescribeActionTargets_611480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the custom action targets in Security Hub in your account.
  ## 
  let valid = call_611493.validator(path, query, header, formData, body)
  let scheme = call_611493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611493.url(scheme.get, call_611493.host, call_611493.base,
                         call_611493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611493, url, valid)

proc call*(call_611494: Call_DescribeActionTargets_611480; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeActionTargets
  ## Returns a list of the custom action targets in Security Hub in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611495 = newJObject()
  var body_611496 = newJObject()
  add(query_611495, "MaxResults", newJString(MaxResults))
  add(query_611495, "NextToken", newJString(NextToken))
  if body != nil:
    body_611496 = body
  result = call_611494.call(nil, query_611495, nil, nil, body_611496)

var describeActionTargets* = Call_DescribeActionTargets_611480(
    name: "describeActionTargets", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets/get",
    validator: validate_DescribeActionTargets_611481, base: "/",
    url: url_DescribeActionTargets_611482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSecurityHub_611511 = ref object of OpenApiRestCall_610658
proc url_EnableSecurityHub_611513(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableSecurityHub_611512(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Enables Security Hub for your account in the current Region or the Region you specify in the request.</p> <p>When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie.</p> <p>When you use the <code>EnableSecurityHub</code> operation to enable Security Hub, you also automatically enable the CIS AWS Foundations standard. You do not enable the Payment Card Industry Data Security Standard (PCI DSS) standard. To enable a standard, use the <code> <a>BatchEnableStandards</a> </code> operation. To disable a standard, use the <code> <a>BatchDisableStandards</a> </code> operation.</p> <p>To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a> in the <i>AWS Security Hub User Guide</i>.</p>
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
  var valid_611514 = header.getOrDefault("X-Amz-Signature")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Signature", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Content-Sha256", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Date")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Date", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Credential")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Credential", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Security-Token")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Security-Token", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Algorithm")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Algorithm", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-SignedHeaders", valid_611520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611522: Call_EnableSecurityHub_611511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables Security Hub for your account in the current Region or the Region you specify in the request.</p> <p>When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie.</p> <p>When you use the <code>EnableSecurityHub</code> operation to enable Security Hub, you also automatically enable the CIS AWS Foundations standard. You do not enable the Payment Card Industry Data Security Standard (PCI DSS) standard. To enable a standard, use the <code> <a>BatchEnableStandards</a> </code> operation. To disable a standard, use the <code> <a>BatchDisableStandards</a> </code> operation.</p> <p>To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a> in the <i>AWS Security Hub User Guide</i>.</p>
  ## 
  let valid = call_611522.validator(path, query, header, formData, body)
  let scheme = call_611522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611522.url(scheme.get, call_611522.host, call_611522.base,
                         call_611522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611522, url, valid)

proc call*(call_611523: Call_EnableSecurityHub_611511; body: JsonNode): Recallable =
  ## enableSecurityHub
  ## <p>Enables Security Hub for your account in the current Region or the Region you specify in the request.</p> <p>When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie.</p> <p>When you use the <code>EnableSecurityHub</code> operation to enable Security Hub, you also automatically enable the CIS AWS Foundations standard. You do not enable the Payment Card Industry Data Security Standard (PCI DSS) standard. To enable a standard, use the <code> <a>BatchEnableStandards</a> </code> operation. To disable a standard, use the <code> <a>BatchDisableStandards</a> </code> operation.</p> <p>To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a> in the <i>AWS Security Hub User Guide</i>.</p>
  ##   body: JObject (required)
  var body_611524 = newJObject()
  if body != nil:
    body_611524 = body
  result = call_611523.call(nil, nil, nil, nil, body_611524)

var enableSecurityHub* = Call_EnableSecurityHub_611511(name: "enableSecurityHub",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/accounts", validator: validate_EnableSecurityHub_611512, base: "/",
    url: url_EnableSecurityHub_611513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHub_611497 = ref object of OpenApiRestCall_610658
proc url_DescribeHub_611499(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHub_611498(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611500 = query.getOrDefault("HubArn")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "HubArn", valid_611500
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
  var valid_611501 = header.getOrDefault("X-Amz-Signature")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Signature", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Content-Sha256", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Date")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Date", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Credential")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Credential", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-Security-Token")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-Security-Token", valid_611505
  var valid_611506 = header.getOrDefault("X-Amz-Algorithm")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Algorithm", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-SignedHeaders", valid_611507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611508: Call_DescribeHub_611497; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ## 
  let valid = call_611508.validator(path, query, header, formData, body)
  let scheme = call_611508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611508.url(scheme.get, call_611508.host, call_611508.base,
                         call_611508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611508, url, valid)

proc call*(call_611509: Call_DescribeHub_611497; HubArn: string = ""): Recallable =
  ## describeHub
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ##   HubArn: string
  ##         : The ARN of the Hub resource to retrieve.
  var query_611510 = newJObject()
  add(query_611510, "HubArn", newJString(HubArn))
  result = call_611509.call(nil, query_611510, nil, nil, nil)

var describeHub* = Call_DescribeHub_611497(name: "describeHub",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/accounts",
                                        validator: validate_DescribeHub_611498,
                                        base: "/", url: url_DescribeHub_611499,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSecurityHub_611525 = ref object of OpenApiRestCall_610658
proc url_DisableSecurityHub_611527(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableSecurityHub_611526(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub.</p> <p>When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and cannot be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed.</p> <p>If you want to save your existing findings, you must export them before you disable Security Hub.</p>
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
  var valid_611528 = header.getOrDefault("X-Amz-Signature")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Signature", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Content-Sha256", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-Date")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Date", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-Credential")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Credential", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-Security-Token")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Security-Token", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-Algorithm")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Algorithm", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-SignedHeaders", valid_611534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611535: Call_DisableSecurityHub_611525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub.</p> <p>When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and cannot be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed.</p> <p>If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  ## 
  let valid = call_611535.validator(path, query, header, formData, body)
  let scheme = call_611535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611535.url(scheme.get, call_611535.host, call_611535.base,
                         call_611535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611535, url, valid)

proc call*(call_611536: Call_DisableSecurityHub_611525): Recallable =
  ## disableSecurityHub
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub.</p> <p>When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and cannot be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed.</p> <p>If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  result = call_611536.call(nil, nil, nil, nil, nil)

var disableSecurityHub* = Call_DisableSecurityHub_611525(
    name: "disableSecurityHub", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/accounts",
    validator: validate_DisableSecurityHub_611526, base: "/",
    url: url_DisableSecurityHub_611527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProducts_611537 = ref object of OpenApiRestCall_610658
proc url_DescribeProducts_611539(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProducts_611538(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns information about the available products that you can subscribe to and integrate with Security Hub in order to consolidate findings.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum number of results to return.
  ##   NextToken: JString
  ##            : <p>The token that is required for pagination. On your first call to the <code>DescribeProducts</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  section = newJObject()
  var valid_611540 = query.getOrDefault("MaxResults")
  valid_611540 = validateParameter(valid_611540, JInt, required = false, default = nil)
  if valid_611540 != nil:
    section.add "MaxResults", valid_611540
  var valid_611541 = query.getOrDefault("NextToken")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "NextToken", valid_611541
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
  var valid_611542 = header.getOrDefault("X-Amz-Signature")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Signature", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Content-Sha256", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Date")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Date", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Credential")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Credential", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Security-Token")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Security-Token", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Algorithm")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Algorithm", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-SignedHeaders", valid_611548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611549: Call_DescribeProducts_611537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the available products that you can subscribe to and integrate with Security Hub in order to consolidate findings.
  ## 
  let valid = call_611549.validator(path, query, header, formData, body)
  let scheme = call_611549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611549.url(scheme.get, call_611549.host, call_611549.base,
                         call_611549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611549, url, valid)

proc call*(call_611550: Call_DescribeProducts_611537; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## describeProducts
  ## Returns information about the available products that you can subscribe to and integrate with Security Hub in order to consolidate findings.
  ##   MaxResults: int
  ##             : The maximum number of results to return.
  ##   NextToken: string
  ##            : <p>The token that is required for pagination. On your first call to the <code>DescribeProducts</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  var query_611551 = newJObject()
  add(query_611551, "MaxResults", newJInt(MaxResults))
  add(query_611551, "NextToken", newJString(NextToken))
  result = call_611550.call(nil, query_611551, nil, nil, nil)

var describeProducts* = Call_DescribeProducts_611537(name: "describeProducts",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/products",
    validator: validate_DescribeProducts_611538, base: "/",
    url: url_DescribeProducts_611539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStandards_611552 = ref object of OpenApiRestCall_610658
proc url_DescribeStandards_611554(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeStandards_611553(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Returns a list of the available standards in Security Hub.</p> <p>For each standard, the results include the standard ARN, the name, and a description. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum number of standards to return.
  ##   NextToken: JString
  ##            : <p>The token that is required for pagination. On your first call to the <code>DescribeStandards</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  section = newJObject()
  var valid_611555 = query.getOrDefault("MaxResults")
  valid_611555 = validateParameter(valid_611555, JInt, required = false, default = nil)
  if valid_611555 != nil:
    section.add "MaxResults", valid_611555
  var valid_611556 = query.getOrDefault("NextToken")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "NextToken", valid_611556
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
  var valid_611557 = header.getOrDefault("X-Amz-Signature")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Signature", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Content-Sha256", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-Date")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Date", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-Credential")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-Credential", valid_611560
  var valid_611561 = header.getOrDefault("X-Amz-Security-Token")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-Security-Token", valid_611561
  var valid_611562 = header.getOrDefault("X-Amz-Algorithm")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Algorithm", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-SignedHeaders", valid_611563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611564: Call_DescribeStandards_611552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the available standards in Security Hub.</p> <p>For each standard, the results include the standard ARN, the name, and a description. </p>
  ## 
  let valid = call_611564.validator(path, query, header, formData, body)
  let scheme = call_611564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611564.url(scheme.get, call_611564.host, call_611564.base,
                         call_611564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611564, url, valid)

proc call*(call_611565: Call_DescribeStandards_611552; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## describeStandards
  ## <p>Returns a list of the available standards in Security Hub.</p> <p>For each standard, the results include the standard ARN, the name, and a description. </p>
  ##   MaxResults: int
  ##             : The maximum number of standards to return.
  ##   NextToken: string
  ##            : <p>The token that is required for pagination. On your first call to the <code>DescribeStandards</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  var query_611566 = newJObject()
  add(query_611566, "MaxResults", newJInt(MaxResults))
  add(query_611566, "NextToken", newJString(NextToken))
  result = call_611565.call(nil, query_611566, nil, nil, nil)

var describeStandards* = Call_DescribeStandards_611552(name: "describeStandards",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/standards", validator: validate_DescribeStandards_611553, base: "/",
    url: url_DescribeStandards_611554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStandardsControls_611567 = ref object of OpenApiRestCall_610658
proc url_DescribeStandardsControls_611569(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "StandardsSubscriptionArn" in path,
        "`StandardsSubscriptionArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/standards/controls/"),
               (kind: VariableSegment, value: "StandardsSubscriptionArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeStandardsControls_611568(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of compliance standards controls.</p> <p>For each control, the results include information about whether it is currently enabled, the severity, and a link to remediation information.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   StandardsSubscriptionArn: JString (required)
  ##                           : The ARN of a resource that represents your subscription to a supported standard.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `StandardsSubscriptionArn` field"
  var valid_611570 = path.getOrDefault("StandardsSubscriptionArn")
  valid_611570 = validateParameter(valid_611570, JString, required = true,
                                 default = nil)
  if valid_611570 != nil:
    section.add "StandardsSubscriptionArn", valid_611570
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum number of compliance standard controls to return.
  ##   NextToken: JString
  ##            : <p>The token that is required for pagination. On your first call to the <code>DescribeStandardsControls</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  section = newJObject()
  var valid_611571 = query.getOrDefault("MaxResults")
  valid_611571 = validateParameter(valid_611571, JInt, required = false, default = nil)
  if valid_611571 != nil:
    section.add "MaxResults", valid_611571
  var valid_611572 = query.getOrDefault("NextToken")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "NextToken", valid_611572
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
  var valid_611573 = header.getOrDefault("X-Amz-Signature")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Signature", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Content-Sha256", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-Date")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-Date", valid_611575
  var valid_611576 = header.getOrDefault("X-Amz-Credential")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "X-Amz-Credential", valid_611576
  var valid_611577 = header.getOrDefault("X-Amz-Security-Token")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "X-Amz-Security-Token", valid_611577
  var valid_611578 = header.getOrDefault("X-Amz-Algorithm")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "X-Amz-Algorithm", valid_611578
  var valid_611579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-SignedHeaders", valid_611579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611580: Call_DescribeStandardsControls_611567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of compliance standards controls.</p> <p>For each control, the results include information about whether it is currently enabled, the severity, and a link to remediation information.</p>
  ## 
  let valid = call_611580.validator(path, query, header, formData, body)
  let scheme = call_611580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611580.url(scheme.get, call_611580.host, call_611580.base,
                         call_611580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611580, url, valid)

proc call*(call_611581: Call_DescribeStandardsControls_611567;
          StandardsSubscriptionArn: string; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## describeStandardsControls
  ## <p>Returns a list of compliance standards controls.</p> <p>For each control, the results include information about whether it is currently enabled, the severity, and a link to remediation information.</p>
  ##   MaxResults: int
  ##             : The maximum number of compliance standard controls to return.
  ##   StandardsSubscriptionArn: string (required)
  ##                           : The ARN of a resource that represents your subscription to a supported standard.
  ##   NextToken: string
  ##            : <p>The token that is required for pagination. On your first call to the <code>DescribeStandardsControls</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  var path_611582 = newJObject()
  var query_611583 = newJObject()
  add(query_611583, "MaxResults", newJInt(MaxResults))
  add(path_611582, "StandardsSubscriptionArn",
      newJString(StandardsSubscriptionArn))
  add(query_611583, "NextToken", newJString(NextToken))
  result = call_611581.call(path_611582, query_611583, nil, nil, nil)

var describeStandardsControls* = Call_DescribeStandardsControls_611567(
    name: "describeStandardsControls", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com",
    route: "/standards/controls/{StandardsSubscriptionArn}",
    validator: validate_DescribeStandardsControls_611568, base: "/",
    url: url_DescribeStandardsControls_611569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableImportFindingsForProduct_611584 = ref object of OpenApiRestCall_610658
proc url_DisableImportFindingsForProduct_611586(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ProductSubscriptionArn" in path,
        "`ProductSubscriptionArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/productSubscriptions/"),
               (kind: VariableSegment, value: "ProductSubscriptionArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisableImportFindingsForProduct_611585(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Disables the integration of the specified product with Security Hub. After the integration is disabled, findings from that product are no longer sent to Security Hub.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ProductSubscriptionArn: JString (required)
  ##                         : The ARN of the integrated product to disable the integration for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ProductSubscriptionArn` field"
  var valid_611587 = path.getOrDefault("ProductSubscriptionArn")
  valid_611587 = validateParameter(valid_611587, JString, required = true,
                                 default = nil)
  if valid_611587 != nil:
    section.add "ProductSubscriptionArn", valid_611587
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
  var valid_611588 = header.getOrDefault("X-Amz-Signature")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Signature", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Content-Sha256", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-Date")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Date", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Credential")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Credential", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Security-Token")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Security-Token", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Algorithm")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Algorithm", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-SignedHeaders", valid_611594
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611595: Call_DisableImportFindingsForProduct_611584;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disables the integration of the specified product with Security Hub. After the integration is disabled, findings from that product are no longer sent to Security Hub.
  ## 
  let valid = call_611595.validator(path, query, header, formData, body)
  let scheme = call_611595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611595.url(scheme.get, call_611595.host, call_611595.base,
                         call_611595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611595, url, valid)

proc call*(call_611596: Call_DisableImportFindingsForProduct_611584;
          ProductSubscriptionArn: string): Recallable =
  ## disableImportFindingsForProduct
  ## Disables the integration of the specified product with Security Hub. After the integration is disabled, findings from that product are no longer sent to Security Hub.
  ##   ProductSubscriptionArn: string (required)
  ##                         : The ARN of the integrated product to disable the integration for.
  var path_611597 = newJObject()
  add(path_611597, "ProductSubscriptionArn", newJString(ProductSubscriptionArn))
  result = call_611596.call(path_611597, nil, nil, nil, nil)

var disableImportFindingsForProduct* = Call_DisableImportFindingsForProduct_611584(
    name: "disableImportFindingsForProduct", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com",
    route: "/productSubscriptions/{ProductSubscriptionArn}",
    validator: validate_DisableImportFindingsForProduct_611585, base: "/",
    url: url_DisableImportFindingsForProduct_611586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_611598 = ref object of OpenApiRestCall_610658
proc url_DisassociateFromMasterAccount_611600(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateFromMasterAccount_611599(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611601 = header.getOrDefault("X-Amz-Signature")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Signature", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Content-Sha256", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Date")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Date", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Credential")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Credential", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-Security-Token")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Security-Token", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-Algorithm")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-Algorithm", valid_611606
  var valid_611607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611607 = validateParameter(valid_611607, JString, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "X-Amz-SignedHeaders", valid_611607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611608: Call_DisassociateFromMasterAccount_611598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current Security Hub member account from the associated master account.
  ## 
  let valid = call_611608.validator(path, query, header, formData, body)
  let scheme = call_611608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611608.url(scheme.get, call_611608.host, call_611608.base,
                         call_611608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611608, url, valid)

proc call*(call_611609: Call_DisassociateFromMasterAccount_611598): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current Security Hub member account from the associated master account.
  result = call_611609.call(nil, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_611598(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_611599, base: "/",
    url: url_DisassociateFromMasterAccount_611600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_611610 = ref object of OpenApiRestCall_610658
proc url_DisassociateMembers_611612(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateMembers_611611(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611613 = header.getOrDefault("X-Amz-Signature")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "X-Amz-Signature", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Content-Sha256", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Date")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Date", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Credential")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Credential", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Security-Token")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Security-Token", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Algorithm")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Algorithm", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-SignedHeaders", valid_611619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611621: Call_DisassociateMembers_611610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified member accounts from the associated master account.
  ## 
  let valid = call_611621.validator(path, query, header, formData, body)
  let scheme = call_611621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611621.url(scheme.get, call_611621.host, call_611621.base,
                         call_611621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611621, url, valid)

proc call*(call_611622: Call_DisassociateMembers_611610; body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates the specified member accounts from the associated master account.
  ##   body: JObject (required)
  var body_611623 = newJObject()
  if body != nil:
    body_611623 = body
  result = call_611622.call(nil, nil, nil, nil, body_611623)

var disassociateMembers* = Call_DisassociateMembers_611610(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/members/disassociate",
    validator: validate_DisassociateMembers_611611, base: "/",
    url: url_DisassociateMembers_611612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableImportFindingsForProduct_611639 = ref object of OpenApiRestCall_610658
proc url_EnableImportFindingsForProduct_611641(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableImportFindingsForProduct_611640(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub.</p> <p>When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.</p>
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
  var valid_611642 = header.getOrDefault("X-Amz-Signature")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-Signature", valid_611642
  var valid_611643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611643 = validateParameter(valid_611643, JString, required = false,
                                 default = nil)
  if valid_611643 != nil:
    section.add "X-Amz-Content-Sha256", valid_611643
  var valid_611644 = header.getOrDefault("X-Amz-Date")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Date", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-Credential")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-Credential", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-Security-Token")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-Security-Token", valid_611646
  var valid_611647 = header.getOrDefault("X-Amz-Algorithm")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Algorithm", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-SignedHeaders", valid_611648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611650: Call_EnableImportFindingsForProduct_611639; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub.</p> <p>When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.</p>
  ## 
  let valid = call_611650.validator(path, query, header, formData, body)
  let scheme = call_611650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611650.url(scheme.get, call_611650.host, call_611650.base,
                         call_611650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611650, url, valid)

proc call*(call_611651: Call_EnableImportFindingsForProduct_611639; body: JsonNode): Recallable =
  ## enableImportFindingsForProduct
  ## <p>Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub.</p> <p>When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.</p>
  ##   body: JObject (required)
  var body_611652 = newJObject()
  if body != nil:
    body_611652 = body
  result = call_611651.call(nil, nil, nil, nil, body_611652)

var enableImportFindingsForProduct* = Call_EnableImportFindingsForProduct_611639(
    name: "enableImportFindingsForProduct", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_EnableImportFindingsForProduct_611640, base: "/",
    url: url_EnableImportFindingsForProduct_611641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnabledProductsForImport_611624 = ref object of OpenApiRestCall_610658
proc url_ListEnabledProductsForImport_611626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEnabledProductsForImport_611625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all findings-generating solutions (products) that you are subscribed to receive findings from in Security Hub.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum number of items to return in the response.
  ##   NextToken: JString
  ##            : <p>The token that is required for pagination. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  section = newJObject()
  var valid_611627 = query.getOrDefault("MaxResults")
  valid_611627 = validateParameter(valid_611627, JInt, required = false, default = nil)
  if valid_611627 != nil:
    section.add "MaxResults", valid_611627
  var valid_611628 = query.getOrDefault("NextToken")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "NextToken", valid_611628
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
  var valid_611629 = header.getOrDefault("X-Amz-Signature")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Signature", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Content-Sha256", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Date")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Date", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Credential")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Credential", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Security-Token")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Security-Token", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Algorithm")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Algorithm", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-SignedHeaders", valid_611635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611636: Call_ListEnabledProductsForImport_611624; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all findings-generating solutions (products) that you are subscribed to receive findings from in Security Hub.
  ## 
  let valid = call_611636.validator(path, query, header, formData, body)
  let scheme = call_611636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611636.url(scheme.get, call_611636.host, call_611636.base,
                         call_611636.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611636, url, valid)

proc call*(call_611637: Call_ListEnabledProductsForImport_611624;
          MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## listEnabledProductsForImport
  ## Lists all findings-generating solutions (products) that you are subscribed to receive findings from in Security Hub.
  ##   MaxResults: int
  ##             : The maximum number of items to return in the response.
  ##   NextToken: string
  ##            : <p>The token that is required for pagination. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  var query_611638 = newJObject()
  add(query_611638, "MaxResults", newJInt(MaxResults))
  add(query_611638, "NextToken", newJString(NextToken))
  result = call_611637.call(nil, query_611638, nil, nil, nil)

var listEnabledProductsForImport* = Call_ListEnabledProductsForImport_611624(
    name: "listEnabledProductsForImport", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_ListEnabledProductsForImport_611625, base: "/",
    url: url_ListEnabledProductsForImport_611626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnabledStandards_611653 = ref object of OpenApiRestCall_610658
proc url_GetEnabledStandards_611655(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEnabledStandards_611654(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of the standards that are currently enabled.
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
  var valid_611656 = query.getOrDefault("MaxResults")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "MaxResults", valid_611656
  var valid_611657 = query.getOrDefault("NextToken")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "NextToken", valid_611657
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
  var valid_611658 = header.getOrDefault("X-Amz-Signature")
  valid_611658 = validateParameter(valid_611658, JString, required = false,
                                 default = nil)
  if valid_611658 != nil:
    section.add "X-Amz-Signature", valid_611658
  var valid_611659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-Content-Sha256", valid_611659
  var valid_611660 = header.getOrDefault("X-Amz-Date")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-Date", valid_611660
  var valid_611661 = header.getOrDefault("X-Amz-Credential")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-Credential", valid_611661
  var valid_611662 = header.getOrDefault("X-Amz-Security-Token")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-Security-Token", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-Algorithm")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Algorithm", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-SignedHeaders", valid_611664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611666: Call_GetEnabledStandards_611653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the standards that are currently enabled.
  ## 
  let valid = call_611666.validator(path, query, header, formData, body)
  let scheme = call_611666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611666.url(scheme.get, call_611666.host, call_611666.base,
                         call_611666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611666, url, valid)

proc call*(call_611667: Call_GetEnabledStandards_611653; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getEnabledStandards
  ## Returns a list of the standards that are currently enabled.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611668 = newJObject()
  var body_611669 = newJObject()
  add(query_611668, "MaxResults", newJString(MaxResults))
  add(query_611668, "NextToken", newJString(NextToken))
  if body != nil:
    body_611669 = body
  result = call_611667.call(nil, query_611668, nil, nil, body_611669)

var getEnabledStandards* = Call_GetEnabledStandards_611653(
    name: "getEnabledStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/get",
    validator: validate_GetEnabledStandards_611654, base: "/",
    url: url_GetEnabledStandards_611655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_611670 = ref object of OpenApiRestCall_610658
proc url_GetFindings_611672(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFindings_611671(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of findings that match the specified criteria.
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
  var valid_611673 = query.getOrDefault("MaxResults")
  valid_611673 = validateParameter(valid_611673, JString, required = false,
                                 default = nil)
  if valid_611673 != nil:
    section.add "MaxResults", valid_611673
  var valid_611674 = query.getOrDefault("NextToken")
  valid_611674 = validateParameter(valid_611674, JString, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "NextToken", valid_611674
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
  var valid_611675 = header.getOrDefault("X-Amz-Signature")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-Signature", valid_611675
  var valid_611676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "X-Amz-Content-Sha256", valid_611676
  var valid_611677 = header.getOrDefault("X-Amz-Date")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-Date", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Credential")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Credential", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Security-Token")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Security-Token", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-Algorithm")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-Algorithm", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-SignedHeaders", valid_611681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611683: Call_GetFindings_611670; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of findings that match the specified criteria.
  ## 
  let valid = call_611683.validator(path, query, header, formData, body)
  let scheme = call_611683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611683.url(scheme.get, call_611683.host, call_611683.base,
                         call_611683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611683, url, valid)

proc call*(call_611684: Call_GetFindings_611670; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getFindings
  ## Returns a list of findings that match the specified criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611685 = newJObject()
  var body_611686 = newJObject()
  add(query_611685, "MaxResults", newJString(MaxResults))
  add(query_611685, "NextToken", newJString(NextToken))
  if body != nil:
    body_611686 = body
  result = call_611684.call(nil, query_611685, nil, nil, body_611686)

var getFindings* = Call_GetFindings_611670(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/findings",
                                        validator: validate_GetFindings_611671,
                                        base: "/", url: url_GetFindings_611672,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_611687 = ref object of OpenApiRestCall_610658
proc url_UpdateFindings_611689(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFindings_611688(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611690 = header.getOrDefault("X-Amz-Signature")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-Signature", valid_611690
  var valid_611691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-Content-Sha256", valid_611691
  var valid_611692 = header.getOrDefault("X-Amz-Date")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-Date", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Credential")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Credential", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Security-Token")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Security-Token", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-Algorithm")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-Algorithm", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-SignedHeaders", valid_611696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611698: Call_UpdateFindings_611687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ## 
  let valid = call_611698.validator(path, query, header, formData, body)
  let scheme = call_611698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611698.url(scheme.get, call_611698.host, call_611698.base,
                         call_611698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611698, url, valid)

proc call*(call_611699: Call_UpdateFindings_611687; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ##   body: JObject (required)
  var body_611700 = newJObject()
  if body != nil:
    body_611700 = body
  result = call_611699.call(nil, nil, nil, nil, body_611700)

var updateFindings* = Call_UpdateFindings_611687(name: "updateFindings",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/findings", validator: validate_UpdateFindings_611688, base: "/",
    url: url_UpdateFindings_611689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsightResults_611701 = ref object of OpenApiRestCall_610658
proc url_GetInsightResults_611703(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "InsightArn" in path, "`InsightArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/insights/results/"),
               (kind: VariableSegment, value: "InsightArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetInsightResults_611702(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists the results of the Security Hub insight specified by the insight ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InsightArn: JString (required)
  ##             : The ARN of the insight for which to return results.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InsightArn` field"
  var valid_611704 = path.getOrDefault("InsightArn")
  valid_611704 = validateParameter(valid_611704, JString, required = true,
                                 default = nil)
  if valid_611704 != nil:
    section.add "InsightArn", valid_611704
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
  var valid_611705 = header.getOrDefault("X-Amz-Signature")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-Signature", valid_611705
  var valid_611706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Content-Sha256", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Date")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Date", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Credential")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Credential", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Security-Token")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Security-Token", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Algorithm")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Algorithm", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-SignedHeaders", valid_611711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611712: Call_GetInsightResults_611701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the results of the Security Hub insight specified by the insight ARN.
  ## 
  let valid = call_611712.validator(path, query, header, formData, body)
  let scheme = call_611712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611712.url(scheme.get, call_611712.host, call_611712.base,
                         call_611712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611712, url, valid)

proc call*(call_611713: Call_GetInsightResults_611701; InsightArn: string): Recallable =
  ## getInsightResults
  ## Lists the results of the Security Hub insight specified by the insight ARN.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight for which to return results.
  var path_611714 = newJObject()
  add(path_611714, "InsightArn", newJString(InsightArn))
  result = call_611713.call(path_611714, nil, nil, nil, nil)

var getInsightResults* = Call_GetInsightResults_611701(name: "getInsightResults",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/insights/results/{InsightArn}",
    validator: validate_GetInsightResults_611702, base: "/",
    url: url_GetInsightResults_611703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsights_611715 = ref object of OpenApiRestCall_610658
proc url_GetInsights_611717(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInsights_611716(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists and describes insights for the specified insight ARNs.
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
  var valid_611718 = query.getOrDefault("MaxResults")
  valid_611718 = validateParameter(valid_611718, JString, required = false,
                                 default = nil)
  if valid_611718 != nil:
    section.add "MaxResults", valid_611718
  var valid_611719 = query.getOrDefault("NextToken")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "NextToken", valid_611719
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
  var valid_611720 = header.getOrDefault("X-Amz-Signature")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-Signature", valid_611720
  var valid_611721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Content-Sha256", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-Date")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Date", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-Credential")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-Credential", valid_611723
  var valid_611724 = header.getOrDefault("X-Amz-Security-Token")
  valid_611724 = validateParameter(valid_611724, JString, required = false,
                                 default = nil)
  if valid_611724 != nil:
    section.add "X-Amz-Security-Token", valid_611724
  var valid_611725 = header.getOrDefault("X-Amz-Algorithm")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Algorithm", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-SignedHeaders", valid_611726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611728: Call_GetInsights_611715; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists and describes insights for the specified insight ARNs.
  ## 
  let valid = call_611728.validator(path, query, header, formData, body)
  let scheme = call_611728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611728.url(scheme.get, call_611728.host, call_611728.base,
                         call_611728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611728, url, valid)

proc call*(call_611729: Call_GetInsights_611715; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getInsights
  ## Lists and describes insights for the specified insight ARNs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611730 = newJObject()
  var body_611731 = newJObject()
  add(query_611730, "MaxResults", newJString(MaxResults))
  add(query_611730, "NextToken", newJString(NextToken))
  if body != nil:
    body_611731 = body
  result = call_611729.call(nil, query_611730, nil, nil, body_611731)

var getInsights* = Call_GetInsights_611715(name: "getInsights",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/insights/get",
                                        validator: validate_GetInsights_611716,
                                        base: "/", url: url_GetInsights_611717,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_611732 = ref object of OpenApiRestCall_610658
proc url_GetInvitationsCount_611734(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInvitationsCount_611733(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611735 = header.getOrDefault("X-Amz-Signature")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "X-Amz-Signature", valid_611735
  var valid_611736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611736 = validateParameter(valid_611736, JString, required = false,
                                 default = nil)
  if valid_611736 != nil:
    section.add "X-Amz-Content-Sha256", valid_611736
  var valid_611737 = header.getOrDefault("X-Amz-Date")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-Date", valid_611737
  var valid_611738 = header.getOrDefault("X-Amz-Credential")
  valid_611738 = validateParameter(valid_611738, JString, required = false,
                                 default = nil)
  if valid_611738 != nil:
    section.add "X-Amz-Credential", valid_611738
  var valid_611739 = header.getOrDefault("X-Amz-Security-Token")
  valid_611739 = validateParameter(valid_611739, JString, required = false,
                                 default = nil)
  if valid_611739 != nil:
    section.add "X-Amz-Security-Token", valid_611739
  var valid_611740 = header.getOrDefault("X-Amz-Algorithm")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Algorithm", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-SignedHeaders", valid_611741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611742: Call_GetInvitationsCount_611732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  ## 
  let valid = call_611742.validator(path, query, header, formData, body)
  let scheme = call_611742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611742.url(scheme.get, call_611742.host, call_611742.base,
                         call_611742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611742, url, valid)

proc call*(call_611743: Call_GetInvitationsCount_611732): Recallable =
  ## getInvitationsCount
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  result = call_611743.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_611732(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/invitations/count",
    validator: validate_GetInvitationsCount_611733, base: "/",
    url: url_GetInvitationsCount_611734, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_611744 = ref object of OpenApiRestCall_610658
proc url_GetMembers_611746(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMembers_611745(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the details for the Security Hub member accounts for the specified account IDs.
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
  var valid_611747 = header.getOrDefault("X-Amz-Signature")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-Signature", valid_611747
  var valid_611748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611748 = validateParameter(valid_611748, JString, required = false,
                                 default = nil)
  if valid_611748 != nil:
    section.add "X-Amz-Content-Sha256", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-Date")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-Date", valid_611749
  var valid_611750 = header.getOrDefault("X-Amz-Credential")
  valid_611750 = validateParameter(valid_611750, JString, required = false,
                                 default = nil)
  if valid_611750 != nil:
    section.add "X-Amz-Credential", valid_611750
  var valid_611751 = header.getOrDefault("X-Amz-Security-Token")
  valid_611751 = validateParameter(valid_611751, JString, required = false,
                                 default = nil)
  if valid_611751 != nil:
    section.add "X-Amz-Security-Token", valid_611751
  var valid_611752 = header.getOrDefault("X-Amz-Algorithm")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-Algorithm", valid_611752
  var valid_611753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-SignedHeaders", valid_611753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611755: Call_GetMembers_611744; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details for the Security Hub member accounts for the specified account IDs.
  ## 
  let valid = call_611755.validator(path, query, header, formData, body)
  let scheme = call_611755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611755.url(scheme.get, call_611755.host, call_611755.base,
                         call_611755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611755, url, valid)

proc call*(call_611756: Call_GetMembers_611744; body: JsonNode): Recallable =
  ## getMembers
  ## Returns the details for the Security Hub member accounts for the specified account IDs.
  ##   body: JObject (required)
  var body_611757 = newJObject()
  if body != nil:
    body_611757 = body
  result = call_611756.call(nil, nil, nil, nil, body_611757)

var getMembers* = Call_GetMembers_611744(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "securityhub.amazonaws.com",
                                      route: "/members/get",
                                      validator: validate_GetMembers_611745,
                                      base: "/", url: url_GetMembers_611746,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_611758 = ref object of OpenApiRestCall_610658
proc url_InviteMembers_611760(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InviteMembers_611759(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from.</p> <p>Before you can use this action to invite a member, you must first use the <code> <a>CreateMembers</a> </code> action to create the member account in Security Hub.</p> <p>When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from the member account.</p>
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
  var valid_611761 = header.getOrDefault("X-Amz-Signature")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-Signature", valid_611761
  var valid_611762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-Content-Sha256", valid_611762
  var valid_611763 = header.getOrDefault("X-Amz-Date")
  valid_611763 = validateParameter(valid_611763, JString, required = false,
                                 default = nil)
  if valid_611763 != nil:
    section.add "X-Amz-Date", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-Credential")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Credential", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Security-Token")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Security-Token", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-Algorithm")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-Algorithm", valid_611766
  var valid_611767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-SignedHeaders", valid_611767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611769: Call_InviteMembers_611758; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from.</p> <p>Before you can use this action to invite a member, you must first use the <code> <a>CreateMembers</a> </code> action to create the member account in Security Hub.</p> <p>When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from the member account.</p>
  ## 
  let valid = call_611769.validator(path, query, header, formData, body)
  let scheme = call_611769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611769.url(scheme.get, call_611769.host, call_611769.base,
                         call_611769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611769, url, valid)

proc call*(call_611770: Call_InviteMembers_611758; body: JsonNode): Recallable =
  ## inviteMembers
  ## <p>Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from.</p> <p>Before you can use this action to invite a member, you must first use the <code> <a>CreateMembers</a> </code> action to create the member account in Security Hub.</p> <p>When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from the member account.</p>
  ##   body: JObject (required)
  var body_611771 = newJObject()
  if body != nil:
    body_611771 = body
  result = call_611770.call(nil, nil, nil, nil, body_611771)

var inviteMembers* = Call_InviteMembers_611758(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/invite", validator: validate_InviteMembers_611759, base: "/",
    url: url_InviteMembers_611760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_611772 = ref object of OpenApiRestCall_610658
proc url_ListInvitations_611774(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInvitations_611773(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum number of items to return in the response. 
  ##   NextToken: JString
  ##            : <p>The token that is required for pagination. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  section = newJObject()
  var valid_611775 = query.getOrDefault("MaxResults")
  valid_611775 = validateParameter(valid_611775, JInt, required = false, default = nil)
  if valid_611775 != nil:
    section.add "MaxResults", valid_611775
  var valid_611776 = query.getOrDefault("NextToken")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "NextToken", valid_611776
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
  var valid_611777 = header.getOrDefault("X-Amz-Signature")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-Signature", valid_611777
  var valid_611778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-Content-Sha256", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Date")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Date", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Credential")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Credential", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-Security-Token")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-Security-Token", valid_611781
  var valid_611782 = header.getOrDefault("X-Amz-Algorithm")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-Algorithm", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-SignedHeaders", valid_611783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611784: Call_ListInvitations_611772; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ## 
  let valid = call_611784.validator(path, query, header, formData, body)
  let scheme = call_611784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611784.url(scheme.get, call_611784.host, call_611784.base,
                         call_611784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611784, url, valid)

proc call*(call_611785: Call_ListInvitations_611772; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## listInvitations
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ##   MaxResults: int
  ##             : The maximum number of items to return in the response. 
  ##   NextToken: string
  ##            : <p>The token that is required for pagination. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>.</p> <p>For subsequent calls to the operation, to continue listing data, set the value of this parameter to the value returned from the previous response.</p>
  var query_611786 = newJObject()
  add(query_611786, "MaxResults", newJInt(MaxResults))
  add(query_611786, "NextToken", newJString(NextToken))
  result = call_611785.call(nil, query_611786, nil, nil, nil)

var listInvitations* = Call_ListInvitations_611772(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_611773, base: "/",
    url: url_ListInvitations_611774, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611801 = ref object of OpenApiRestCall_610658
proc url_TagResource_611803(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "ResourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_611802(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611804 = path.getOrDefault("ResourceArn")
  valid_611804 = validateParameter(valid_611804, JString, required = true,
                                 default = nil)
  if valid_611804 != nil:
    section.add "ResourceArn", valid_611804
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
  var valid_611805 = header.getOrDefault("X-Amz-Signature")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "X-Amz-Signature", valid_611805
  var valid_611806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611806 = validateParameter(valid_611806, JString, required = false,
                                 default = nil)
  if valid_611806 != nil:
    section.add "X-Amz-Content-Sha256", valid_611806
  var valid_611807 = header.getOrDefault("X-Amz-Date")
  valid_611807 = validateParameter(valid_611807, JString, required = false,
                                 default = nil)
  if valid_611807 != nil:
    section.add "X-Amz-Date", valid_611807
  var valid_611808 = header.getOrDefault("X-Amz-Credential")
  valid_611808 = validateParameter(valid_611808, JString, required = false,
                                 default = nil)
  if valid_611808 != nil:
    section.add "X-Amz-Credential", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Security-Token")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Security-Token", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-Algorithm")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Algorithm", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-SignedHeaders", valid_611811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611813: Call_TagResource_611801; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a resource.
  ## 
  let valid = call_611813.validator(path, query, header, formData, body)
  let scheme = call_611813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611813.url(scheme.get, call_611813.host, call_611813.base,
                         call_611813.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611813, url, valid)

proc call*(call_611814: Call_TagResource_611801; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to apply the tags to.
  ##   body: JObject (required)
  var path_611815 = newJObject()
  var body_611816 = newJObject()
  add(path_611815, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_611816 = body
  result = call_611814.call(path_611815, nil, nil, nil, body_611816)

var tagResource* = Call_TagResource_611801(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_611802,
                                        base: "/", url: url_TagResource_611803,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611787 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611789(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "ResourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_611788(path: JsonNode; query: JsonNode;
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
  var valid_611790 = path.getOrDefault("ResourceArn")
  valid_611790 = validateParameter(valid_611790, JString, required = true,
                                 default = nil)
  if valid_611790 != nil:
    section.add "ResourceArn", valid_611790
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
  var valid_611791 = header.getOrDefault("X-Amz-Signature")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Signature", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-Content-Sha256", valid_611792
  var valid_611793 = header.getOrDefault("X-Amz-Date")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "X-Amz-Date", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Credential")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Credential", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-Security-Token")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-Security-Token", valid_611795
  var valid_611796 = header.getOrDefault("X-Amz-Algorithm")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-Algorithm", valid_611796
  var valid_611797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "X-Amz-SignedHeaders", valid_611797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611798: Call_ListTagsForResource_611787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags associated with a resource.
  ## 
  let valid = call_611798.validator(path, query, header, formData, body)
  let scheme = call_611798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611798.url(scheme.get, call_611798.host, call_611798.base,
                         call_611798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611798, url, valid)

proc call*(call_611799: Call_ListTagsForResource_611787; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags associated with a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to retrieve tags for.
  var path_611800 = newJObject()
  add(path_611800, "ResourceArn", newJString(ResourceArn))
  result = call_611799.call(path_611800, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611787(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_611788, base: "/",
    url: url_ListTagsForResource_611789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611817 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611819(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "ResourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_611818(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611820 = path.getOrDefault("ResourceArn")
  valid_611820 = validateParameter(valid_611820, JString, required = true,
                                 default = nil)
  if valid_611820 != nil:
    section.add "ResourceArn", valid_611820
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_611821 = query.getOrDefault("tagKeys")
  valid_611821 = validateParameter(valid_611821, JArray, required = true, default = nil)
  if valid_611821 != nil:
    section.add "tagKeys", valid_611821
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
  var valid_611822 = header.getOrDefault("X-Amz-Signature")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "X-Amz-Signature", valid_611822
  var valid_611823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611823 = validateParameter(valid_611823, JString, required = false,
                                 default = nil)
  if valid_611823 != nil:
    section.add "X-Amz-Content-Sha256", valid_611823
  var valid_611824 = header.getOrDefault("X-Amz-Date")
  valid_611824 = validateParameter(valid_611824, JString, required = false,
                                 default = nil)
  if valid_611824 != nil:
    section.add "X-Amz-Date", valid_611824
  var valid_611825 = header.getOrDefault("X-Amz-Credential")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-Credential", valid_611825
  var valid_611826 = header.getOrDefault("X-Amz-Security-Token")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Security-Token", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-Algorithm")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-Algorithm", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-SignedHeaders", valid_611828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611829: Call_UntagResource_611817; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a resource.
  ## 
  let valid = call_611829.validator(path, query, header, formData, body)
  let scheme = call_611829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611829.url(scheme.get, call_611829.host, call_611829.base,
                         call_611829.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611829, url, valid)

proc call*(call_611830: Call_UntagResource_611817; ResourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to remove the tags from.
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  var path_611831 = newJObject()
  var query_611832 = newJObject()
  add(path_611831, "ResourceArn", newJString(ResourceArn))
  if tagKeys != nil:
    query_611832.add "tagKeys", tagKeys
  result = call_611830.call(path_611831, query_611832, nil, nil, nil)

var untagResource* = Call_UntagResource_611817(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_611818,
    base: "/", url: url_UntagResource_611819, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStandardsControl_611833 = ref object of OpenApiRestCall_610658
proc url_UpdateStandardsControl_611835(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "StandardsControlArn" in path,
        "`StandardsControlArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/standards/control/"),
               (kind: VariableSegment, value: "StandardsControlArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStandardsControl_611834(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Used to control whether an individual compliance standard control is enabled or disabled.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   StandardsControlArn: JString (required)
  ##                      : The ARN of the compliance standard control to enable or disable.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `StandardsControlArn` field"
  var valid_611836 = path.getOrDefault("StandardsControlArn")
  valid_611836 = validateParameter(valid_611836, JString, required = true,
                                 default = nil)
  if valid_611836 != nil:
    section.add "StandardsControlArn", valid_611836
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
  var valid_611837 = header.getOrDefault("X-Amz-Signature")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-Signature", valid_611837
  var valid_611838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611838 = validateParameter(valid_611838, JString, required = false,
                                 default = nil)
  if valid_611838 != nil:
    section.add "X-Amz-Content-Sha256", valid_611838
  var valid_611839 = header.getOrDefault("X-Amz-Date")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "X-Amz-Date", valid_611839
  var valid_611840 = header.getOrDefault("X-Amz-Credential")
  valid_611840 = validateParameter(valid_611840, JString, required = false,
                                 default = nil)
  if valid_611840 != nil:
    section.add "X-Amz-Credential", valid_611840
  var valid_611841 = header.getOrDefault("X-Amz-Security-Token")
  valid_611841 = validateParameter(valid_611841, JString, required = false,
                                 default = nil)
  if valid_611841 != nil:
    section.add "X-Amz-Security-Token", valid_611841
  var valid_611842 = header.getOrDefault("X-Amz-Algorithm")
  valid_611842 = validateParameter(valid_611842, JString, required = false,
                                 default = nil)
  if valid_611842 != nil:
    section.add "X-Amz-Algorithm", valid_611842
  var valid_611843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611843 = validateParameter(valid_611843, JString, required = false,
                                 default = nil)
  if valid_611843 != nil:
    section.add "X-Amz-SignedHeaders", valid_611843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611845: Call_UpdateStandardsControl_611833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to control whether an individual compliance standard control is enabled or disabled.
  ## 
  let valid = call_611845.validator(path, query, header, formData, body)
  let scheme = call_611845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611845.url(scheme.get, call_611845.host, call_611845.base,
                         call_611845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611845, url, valid)

proc call*(call_611846: Call_UpdateStandardsControl_611833;
          StandardsControlArn: string; body: JsonNode): Recallable =
  ## updateStandardsControl
  ## Used to control whether an individual compliance standard control is enabled or disabled.
  ##   StandardsControlArn: string (required)
  ##                      : The ARN of the compliance standard control to enable or disable.
  ##   body: JObject (required)
  var path_611847 = newJObject()
  var body_611848 = newJObject()
  add(path_611847, "StandardsControlArn", newJString(StandardsControlArn))
  if body != nil:
    body_611848 = body
  result = call_611846.call(path_611847, nil, nil, nil, body_611848)

var updateStandardsControl* = Call_UpdateStandardsControl_611833(
    name: "updateStandardsControl", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com",
    route: "/standards/control/{StandardsControlArn}",
    validator: validate_UpdateStandardsControl_611834, base: "/",
    url: url_UpdateStandardsControl_611835, schemes: {Scheme.Https, Scheme.Http})
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
