
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
## <p>Security Hub provides you with a comprehensive view of the security state of your AWS environment and resources. It also provides you with the compliance status of your environment based on CIS AWS Foundations compliance checks. Security Hub collects security data from AWS accounts, services, and integrated third-party products and helps you analyze security trends in your environment to identify the highest priority security issues. For more information about Security Hub, see the <i> <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html">AWS Security Hub User Guide</a> </i>.</p> <p>When you use operations in the Security Hub API, the requests are executed only in the AWS Region that is currently active or in the specific AWS Region that you specify in your request. Any configuration or settings change that results from the operation is applied only to that Region. To make the same change in other Regions, execute the same command for each Region to apply the change to.</p> <p>For example, if your Region is set to <code>us-west-2</code>, when you use <code>CreateMembers</code> to add a member account to Security Hub, the association of the member account with the master account is created only in the <code>us-west-2</code> Region. Security Hub must be enabled for the member account in the same Region that the invitation was sent from.</p> <p>The following throttling limits apply to using Security Hub API operations.</p> <ul> <li> <p> <code>GetFindings</code> - <code>RateLimit</code> of 3 requests per second. <code>BurstLimit</code> of 6 requests per second.</p> </li> <li> <p> <code>UpdateFindings</code> - <code>RateLimit</code> of 1 request per second. <code>BurstLimit</code> of 5 requests per second.</p> </li> <li> <p>All other operations - <code>RateLimit</code> of 10 request per second. <code>BurstLimit</code> of 30 requests per second.</p> </li> </ul>
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
  Call_AcceptInvitation_613248 = ref object of OpenApiRestCall_612658
proc url_AcceptInvitation_613250(protocol: Scheme; host: string; base: string;
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

proc validate_AcceptInvitation_613249(path: JsonNode; query: JsonNode;
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
  var valid_613251 = header.getOrDefault("X-Amz-Signature")
  valid_613251 = validateParameter(valid_613251, JString, required = false,
                                 default = nil)
  if valid_613251 != nil:
    section.add "X-Amz-Signature", valid_613251
  var valid_613252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613252 = validateParameter(valid_613252, JString, required = false,
                                 default = nil)
  if valid_613252 != nil:
    section.add "X-Amz-Content-Sha256", valid_613252
  var valid_613253 = header.getOrDefault("X-Amz-Date")
  valid_613253 = validateParameter(valid_613253, JString, required = false,
                                 default = nil)
  if valid_613253 != nil:
    section.add "X-Amz-Date", valid_613253
  var valid_613254 = header.getOrDefault("X-Amz-Credential")
  valid_613254 = validateParameter(valid_613254, JString, required = false,
                                 default = nil)
  if valid_613254 != nil:
    section.add "X-Amz-Credential", valid_613254
  var valid_613255 = header.getOrDefault("X-Amz-Security-Token")
  valid_613255 = validateParameter(valid_613255, JString, required = false,
                                 default = nil)
  if valid_613255 != nil:
    section.add "X-Amz-Security-Token", valid_613255
  var valid_613256 = header.getOrDefault("X-Amz-Algorithm")
  valid_613256 = validateParameter(valid_613256, JString, required = false,
                                 default = nil)
  if valid_613256 != nil:
    section.add "X-Amz-Algorithm", valid_613256
  var valid_613257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-SignedHeaders", valid_613257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613259: Call_AcceptInvitation_613248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from.</p> <p>When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.</p>
  ## 
  let valid = call_613259.validator(path, query, header, formData, body)
  let scheme = call_613259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613259.url(scheme.get, call_613259.host, call_613259.base,
                         call_613259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613259, url, valid)

proc call*(call_613260: Call_AcceptInvitation_613248; body: JsonNode): Recallable =
  ## acceptInvitation
  ## <p>Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from.</p> <p>When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.</p>
  ##   body: JObject (required)
  var body_613261 = newJObject()
  if body != nil:
    body_613261 = body
  result = call_613260.call(nil, nil, nil, nil, body_613261)

var acceptInvitation* = Call_AcceptInvitation_613248(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_AcceptInvitation_613249, base: "/",
    url: url_AcceptInvitation_613250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_612996 = ref object of OpenApiRestCall_612658
proc url_GetMasterAccount_612998(protocol: Scheme; host: string; base: string;
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

proc validate_GetMasterAccount_612997(path: JsonNode; query: JsonNode;
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
  var valid_613110 = header.getOrDefault("X-Amz-Signature")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "X-Amz-Signature", valid_613110
  var valid_613111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Content-Sha256", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Date")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Date", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Credential")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Credential", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Security-Token")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Security-Token", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Algorithm")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Algorithm", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-SignedHeaders", valid_613116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613139: Call_GetMasterAccount_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the Security Hub master account for the current member account. 
  ## 
  let valid = call_613139.validator(path, query, header, formData, body)
  let scheme = call_613139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613139.url(scheme.get, call_613139.host, call_613139.base,
                         call_613139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613139, url, valid)

proc call*(call_613210: Call_GetMasterAccount_612996): Recallable =
  ## getMasterAccount
  ## Provides the details for the Security Hub master account for the current member account. 
  result = call_613210.call(nil, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_612996(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_GetMasterAccount_612997, base: "/",
    url: url_GetMasterAccount_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisableStandards_613263 = ref object of OpenApiRestCall_612658
proc url_BatchDisableStandards_613265(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDisableStandards_613264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.</p>
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
  var valid_613266 = header.getOrDefault("X-Amz-Signature")
  valid_613266 = validateParameter(valid_613266, JString, required = false,
                                 default = nil)
  if valid_613266 != nil:
    section.add "X-Amz-Signature", valid_613266
  var valid_613267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613267 = validateParameter(valid_613267, JString, required = false,
                                 default = nil)
  if valid_613267 != nil:
    section.add "X-Amz-Content-Sha256", valid_613267
  var valid_613268 = header.getOrDefault("X-Amz-Date")
  valid_613268 = validateParameter(valid_613268, JString, required = false,
                                 default = nil)
  if valid_613268 != nil:
    section.add "X-Amz-Date", valid_613268
  var valid_613269 = header.getOrDefault("X-Amz-Credential")
  valid_613269 = validateParameter(valid_613269, JString, required = false,
                                 default = nil)
  if valid_613269 != nil:
    section.add "X-Amz-Credential", valid_613269
  var valid_613270 = header.getOrDefault("X-Amz-Security-Token")
  valid_613270 = validateParameter(valid_613270, JString, required = false,
                                 default = nil)
  if valid_613270 != nil:
    section.add "X-Amz-Security-Token", valid_613270
  var valid_613271 = header.getOrDefault("X-Amz-Algorithm")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Algorithm", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-SignedHeaders", valid_613272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613274: Call_BatchDisableStandards_613263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.</p>
  ## 
  let valid = call_613274.validator(path, query, header, formData, body)
  let scheme = call_613274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613274.url(scheme.get, call_613274.host, call_613274.base,
                         call_613274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613274, url, valid)

proc call*(call_613275: Call_BatchDisableStandards_613263; body: JsonNode): Recallable =
  ## batchDisableStandards
  ## <p>Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.</p>
  ##   body: JObject (required)
  var body_613276 = newJObject()
  if body != nil:
    body_613276 = body
  result = call_613275.call(nil, nil, nil, nil, body_613276)

var batchDisableStandards* = Call_BatchDisableStandards_613263(
    name: "batchDisableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/deregister",
    validator: validate_BatchDisableStandards_613264, base: "/",
    url: url_BatchDisableStandards_613265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchEnableStandards_613277 = ref object of OpenApiRestCall_612658
proc url_BatchEnableStandards_613279(protocol: Scheme; host: string; base: string;
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

proc validate_BatchEnableStandards_613278(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enables the standards specified by the provided <code>standardsArn</code>.</p> <p>In this release, only CIS AWS Foundations standards are supported.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.</p>
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
  var valid_613280 = header.getOrDefault("X-Amz-Signature")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Signature", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-Content-Sha256", valid_613281
  var valid_613282 = header.getOrDefault("X-Amz-Date")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Date", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-Credential")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Credential", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-Security-Token")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-Security-Token", valid_613284
  var valid_613285 = header.getOrDefault("X-Amz-Algorithm")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Algorithm", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-SignedHeaders", valid_613286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613288: Call_BatchEnableStandards_613277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the standards specified by the provided <code>standardsArn</code>.</p> <p>In this release, only CIS AWS Foundations standards are supported.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.</p>
  ## 
  let valid = call_613288.validator(path, query, header, formData, body)
  let scheme = call_613288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613288.url(scheme.get, call_613288.host, call_613288.base,
                         call_613288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613288, url, valid)

proc call*(call_613289: Call_BatchEnableStandards_613277; body: JsonNode): Recallable =
  ## batchEnableStandards
  ## <p>Enables the standards specified by the provided <code>standardsArn</code>.</p> <p>In this release, only CIS AWS Foundations standards are supported.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.</p>
  ##   body: JObject (required)
  var body_613290 = newJObject()
  if body != nil:
    body_613290 = body
  result = call_613289.call(nil, nil, nil, nil, body_613290)

var batchEnableStandards* = Call_BatchEnableStandards_613277(
    name: "batchEnableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/register",
    validator: validate_BatchEnableStandards_613278, base: "/",
    url: url_BatchEnableStandards_613279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchImportFindings_613291 = ref object of OpenApiRestCall_612658
proc url_BatchImportFindings_613293(protocol: Scheme; host: string; base: string;
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

proc validate_BatchImportFindings_613292(path: JsonNode; query: JsonNode;
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
  var valid_613294 = header.getOrDefault("X-Amz-Signature")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Signature", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Content-Sha256", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Date")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Date", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Credential")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Credential", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Security-Token")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Security-Token", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Algorithm")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Algorithm", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-SignedHeaders", valid_613300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613302: Call_BatchImportFindings_613291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub.</p> <p>The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.</p>
  ## 
  let valid = call_613302.validator(path, query, header, formData, body)
  let scheme = call_613302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613302.url(scheme.get, call_613302.host, call_613302.base,
                         call_613302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613302, url, valid)

proc call*(call_613303: Call_BatchImportFindings_613291; body: JsonNode): Recallable =
  ## batchImportFindings
  ## <p>Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub.</p> <p>The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.</p>
  ##   body: JObject (required)
  var body_613304 = newJObject()
  if body != nil:
    body_613304 = body
  result = call_613303.call(nil, nil, nil, nil, body_613304)

var batchImportFindings* = Call_BatchImportFindings_613291(
    name: "batchImportFindings", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/findings/import",
    validator: validate_BatchImportFindings_613292, base: "/",
    url: url_BatchImportFindings_613293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActionTarget_613305 = ref object of OpenApiRestCall_612658
proc url_CreateActionTarget_613307(protocol: Scheme; host: string; base: string;
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

proc validate_CreateActionTarget_613306(path: JsonNode; query: JsonNode;
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
  var valid_613308 = header.getOrDefault("X-Amz-Signature")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Signature", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Content-Sha256", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Date")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Date", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Credential")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Credential", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Security-Token")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Security-Token", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Algorithm")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Algorithm", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-SignedHeaders", valid_613314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613316: Call_CreateActionTarget_613305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a custom action target in Security Hub.</p> <p>You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.</p>
  ## 
  let valid = call_613316.validator(path, query, header, formData, body)
  let scheme = call_613316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613316.url(scheme.get, call_613316.host, call_613316.base,
                         call_613316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613316, url, valid)

proc call*(call_613317: Call_CreateActionTarget_613305; body: JsonNode): Recallable =
  ## createActionTarget
  ## <p>Creates a custom action target in Security Hub.</p> <p>You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.</p>
  ##   body: JObject (required)
  var body_613318 = newJObject()
  if body != nil:
    body_613318 = body
  result = call_613317.call(nil, nil, nil, nil, body_613318)

var createActionTarget* = Call_CreateActionTarget_613305(
    name: "createActionTarget", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets",
    validator: validate_CreateActionTarget_613306, base: "/",
    url: url_CreateActionTarget_613307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInsight_613319 = ref object of OpenApiRestCall_612658
proc url_CreateInsight_613321(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInsight_613320(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613322 = header.getOrDefault("X-Amz-Signature")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Signature", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Content-Sha256", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Date")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Date", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Credential")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Credential", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Security-Token")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Security-Token", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Algorithm")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Algorithm", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-SignedHeaders", valid_613328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613330: Call_CreateInsight_613319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation.</p> <p>To group the related findings in the insight, use the <code>GroupByAttribute</code>.</p>
  ## 
  let valid = call_613330.validator(path, query, header, formData, body)
  let scheme = call_613330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613330.url(scheme.get, call_613330.host, call_613330.base,
                         call_613330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613330, url, valid)

proc call*(call_613331: Call_CreateInsight_613319; body: JsonNode): Recallable =
  ## createInsight
  ## <p>Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation.</p> <p>To group the related findings in the insight, use the <code>GroupByAttribute</code>.</p>
  ##   body: JObject (required)
  var body_613332 = newJObject()
  if body != nil:
    body_613332 = body
  result = call_613331.call(nil, nil, nil, nil, body_613332)

var createInsight* = Call_CreateInsight_613319(name: "createInsight",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/insights", validator: validate_CreateInsight_613320, base: "/",
    url: url_CreateInsight_613321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_613350 = ref object of OpenApiRestCall_612658
proc url_CreateMembers_613352(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMembers_613351(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. To enable Security Hub, you can use the <a>EnableSecurityHub</a> operation.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you must use the <a>InviteMembers</a> operation to invite the accounts to enable Security Hub and become member accounts in Security Hub.</p> <p>If the account owner accepts the invitation, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start to be sent to both the member and master accounts.</p> <p>To remove the association between the master and member accounts, use the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
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
  var valid_613353 = header.getOrDefault("X-Amz-Signature")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Signature", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Content-Sha256", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Date")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Date", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Credential")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Credential", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Security-Token")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Security-Token", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Algorithm")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Algorithm", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-SignedHeaders", valid_613359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613361: Call_CreateMembers_613350; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. To enable Security Hub, you can use the <a>EnableSecurityHub</a> operation.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you must use the <a>InviteMembers</a> operation to invite the accounts to enable Security Hub and become member accounts in Security Hub.</p> <p>If the account owner accepts the invitation, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start to be sent to both the member and master accounts.</p> <p>To remove the association between the master and member accounts, use the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ## 
  let valid = call_613361.validator(path, query, header, formData, body)
  let scheme = call_613361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613361.url(scheme.get, call_613361.host, call_613361.base,
                         call_613361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613361, url, valid)

proc call*(call_613362: Call_CreateMembers_613350; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. To enable Security Hub, you can use the <a>EnableSecurityHub</a> operation.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you must use the <a>InviteMembers</a> operation to invite the accounts to enable Security Hub and become member accounts in Security Hub.</p> <p>If the account owner accepts the invitation, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start to be sent to both the member and master accounts.</p> <p>To remove the association between the master and member accounts, use the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ##   body: JObject (required)
  var body_613363 = newJObject()
  if body != nil:
    body_613363 = body
  result = call_613362.call(nil, nil, nil, nil, body_613363)

var createMembers* = Call_CreateMembers_613350(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/members",
    validator: validate_CreateMembers_613351, base: "/", url: url_CreateMembers_613352,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_613333 = ref object of OpenApiRestCall_612658
proc url_ListMembers_613335(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_613334(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##            : Paginates results. On your first call to the <code>ListMembers</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, to continue listing data, set <code>nextToken</code> in the request to the value of <code>nextToken</code> from the previous response.
  ##   OnlyAssociated: JBool
  ##                 : <p>Specifies which member accounts to include in the response based on their relationship status with the master account. The default value is <code>TRUE</code>.</p> <p>If <code>onlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>.</p> <p>If <code>onlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. </p>
  section = newJObject()
  var valid_613336 = query.getOrDefault("MaxResults")
  valid_613336 = validateParameter(valid_613336, JInt, required = false, default = nil)
  if valid_613336 != nil:
    section.add "MaxResults", valid_613336
  var valid_613337 = query.getOrDefault("NextToken")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "NextToken", valid_613337
  var valid_613338 = query.getOrDefault("OnlyAssociated")
  valid_613338 = validateParameter(valid_613338, JBool, required = false, default = nil)
  if valid_613338 != nil:
    section.add "OnlyAssociated", valid_613338
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
  var valid_613339 = header.getOrDefault("X-Amz-Signature")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Signature", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Content-Sha256", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Date")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Date", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Credential")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Credential", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Security-Token")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Security-Token", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Algorithm")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Algorithm", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-SignedHeaders", valid_613345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613346: Call_ListMembers_613333; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current Security Hub master account.
  ## 
  let valid = call_613346.validator(path, query, header, formData, body)
  let scheme = call_613346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613346.url(scheme.get, call_613346.host, call_613346.base,
                         call_613346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613346, url, valid)

proc call*(call_613347: Call_ListMembers_613333; MaxResults: int = 0;
          NextToken: string = ""; OnlyAssociated: bool = false): Recallable =
  ## listMembers
  ## Lists details about all member accounts for the current Security Hub master account.
  ##   MaxResults: int
  ##             : The maximum number of items to return in the response. 
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListMembers</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, to continue listing data, set <code>nextToken</code> in the request to the value of <code>nextToken</code> from the previous response.
  ##   OnlyAssociated: bool
  ##                 : <p>Specifies which member accounts to include in the response based on their relationship status with the master account. The default value is <code>TRUE</code>.</p> <p>If <code>onlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>.</p> <p>If <code>onlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. </p>
  var query_613348 = newJObject()
  add(query_613348, "MaxResults", newJInt(MaxResults))
  add(query_613348, "NextToken", newJString(NextToken))
  add(query_613348, "OnlyAssociated", newJBool(OnlyAssociated))
  result = call_613347.call(nil, query_613348, nil, nil, nil)

var listMembers* = Call_ListMembers_613333(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/members",
                                        validator: validate_ListMembers_613334,
                                        base: "/", url: url_ListMembers_613335,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_613364 = ref object of OpenApiRestCall_612658
proc url_DeclineInvitations_613366(protocol: Scheme; host: string; base: string;
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

proc validate_DeclineInvitations_613365(path: JsonNode; query: JsonNode;
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
  var valid_613367 = header.getOrDefault("X-Amz-Signature")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Signature", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Content-Sha256", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Date")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Date", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Credential")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Credential", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Security-Token")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Security-Token", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Algorithm")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Algorithm", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-SignedHeaders", valid_613373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613375: Call_DeclineInvitations_613364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations to become a member account.
  ## 
  let valid = call_613375.validator(path, query, header, formData, body)
  let scheme = call_613375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613375.url(scheme.get, call_613375.host, call_613375.base,
                         call_613375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613375, url, valid)

proc call*(call_613376: Call_DeclineInvitations_613364; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations to become a member account.
  ##   body: JObject (required)
  var body_613377 = newJObject()
  if body != nil:
    body_613377 = body
  result = call_613376.call(nil, nil, nil, nil, body_613377)

var declineInvitations* = Call_DeclineInvitations_613364(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/invitations/decline",
    validator: validate_DeclineInvitations_613365, base: "/",
    url: url_DeclineInvitations_613366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateActionTarget_613406 = ref object of OpenApiRestCall_612658
proc url_UpdateActionTarget_613408(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateActionTarget_613407(path: JsonNode; query: JsonNode;
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
  var valid_613409 = path.getOrDefault("ActionTargetArn")
  valid_613409 = validateParameter(valid_613409, JString, required = true,
                                 default = nil)
  if valid_613409 != nil:
    section.add "ActionTargetArn", valid_613409
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
  var valid_613410 = header.getOrDefault("X-Amz-Signature")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-Signature", valid_613410
  var valid_613411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "X-Amz-Content-Sha256", valid_613411
  var valid_613412 = header.getOrDefault("X-Amz-Date")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Date", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Credential")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Credential", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Security-Token")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Security-Token", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Algorithm")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Algorithm", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-SignedHeaders", valid_613416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613418: Call_UpdateActionTarget_613406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name and description of a custom action target in Security Hub.
  ## 
  let valid = call_613418.validator(path, query, header, formData, body)
  let scheme = call_613418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613418.url(scheme.get, call_613418.host, call_613418.base,
                         call_613418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613418, url, valid)

proc call*(call_613419: Call_UpdateActionTarget_613406; ActionTargetArn: string;
          body: JsonNode): Recallable =
  ## updateActionTarget
  ## Updates the name and description of a custom action target in Security Hub.
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to update.
  ##   body: JObject (required)
  var path_613420 = newJObject()
  var body_613421 = newJObject()
  add(path_613420, "ActionTargetArn", newJString(ActionTargetArn))
  if body != nil:
    body_613421 = body
  result = call_613419.call(path_613420, nil, nil, nil, body_613421)

var updateActionTarget* = Call_UpdateActionTarget_613406(
    name: "updateActionTarget", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_UpdateActionTarget_613407, base: "/",
    url: url_UpdateActionTarget_613408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActionTarget_613378 = ref object of OpenApiRestCall_612658
proc url_DeleteActionTarget_613380(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteActionTarget_613379(path: JsonNode; query: JsonNode;
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
  var valid_613395 = path.getOrDefault("ActionTargetArn")
  valid_613395 = validateParameter(valid_613395, JString, required = true,
                                 default = nil)
  if valid_613395 != nil:
    section.add "ActionTargetArn", valid_613395
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
  var valid_613396 = header.getOrDefault("X-Amz-Signature")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Signature", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Content-Sha256", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-Date")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-Date", valid_613398
  var valid_613399 = header.getOrDefault("X-Amz-Credential")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-Credential", valid_613399
  var valid_613400 = header.getOrDefault("X-Amz-Security-Token")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-Security-Token", valid_613400
  var valid_613401 = header.getOrDefault("X-Amz-Algorithm")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Algorithm", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-SignedHeaders", valid_613402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613403: Call_DeleteActionTarget_613378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a custom action target from Security Hub.</p> <p>Deleting a custom action target does not affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.</p>
  ## 
  let valid = call_613403.validator(path, query, header, formData, body)
  let scheme = call_613403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613403.url(scheme.get, call_613403.host, call_613403.base,
                         call_613403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613403, url, valid)

proc call*(call_613404: Call_DeleteActionTarget_613378; ActionTargetArn: string): Recallable =
  ## deleteActionTarget
  ## <p>Deletes a custom action target from Security Hub.</p> <p>Deleting a custom action target does not affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.</p>
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to delete.
  var path_613405 = newJObject()
  add(path_613405, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_613404.call(path_613405, nil, nil, nil, nil)

var deleteActionTarget* = Call_DeleteActionTarget_613378(
    name: "deleteActionTarget", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_DeleteActionTarget_613379, base: "/",
    url: url_DeleteActionTarget_613380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInsight_613436 = ref object of OpenApiRestCall_612658
proc url_UpdateInsight_613438(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateInsight_613437(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613439 = path.getOrDefault("InsightArn")
  valid_613439 = validateParameter(valid_613439, JString, required = true,
                                 default = nil)
  if valid_613439 != nil:
    section.add "InsightArn", valid_613439
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
  var valid_613440 = header.getOrDefault("X-Amz-Signature")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Signature", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-Content-Sha256", valid_613441
  var valid_613442 = header.getOrDefault("X-Amz-Date")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-Date", valid_613442
  var valid_613443 = header.getOrDefault("X-Amz-Credential")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Credential", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Security-Token")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Security-Token", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Algorithm")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Algorithm", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-SignedHeaders", valid_613446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613448: Call_UpdateInsight_613436; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Security Hub insight identified by the specified insight ARN.
  ## 
  let valid = call_613448.validator(path, query, header, formData, body)
  let scheme = call_613448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613448.url(scheme.get, call_613448.host, call_613448.base,
                         call_613448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613448, url, valid)

proc call*(call_613449: Call_UpdateInsight_613436; InsightArn: string; body: JsonNode): Recallable =
  ## updateInsight
  ## Updates the Security Hub insight identified by the specified insight ARN.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight that you want to update.
  ##   body: JObject (required)
  var path_613450 = newJObject()
  var body_613451 = newJObject()
  add(path_613450, "InsightArn", newJString(InsightArn))
  if body != nil:
    body_613451 = body
  result = call_613449.call(path_613450, nil, nil, nil, body_613451)

var updateInsight* = Call_UpdateInsight_613436(name: "updateInsight",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_UpdateInsight_613437,
    base: "/", url: url_UpdateInsight_613438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInsight_613422 = ref object of OpenApiRestCall_612658
proc url_DeleteInsight_613424(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteInsight_613423(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613425 = path.getOrDefault("InsightArn")
  valid_613425 = validateParameter(valid_613425, JString, required = true,
                                 default = nil)
  if valid_613425 != nil:
    section.add "InsightArn", valid_613425
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
  var valid_613426 = header.getOrDefault("X-Amz-Signature")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Signature", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Content-Sha256", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Date")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Date", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Credential")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Credential", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Security-Token")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Security-Token", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Algorithm")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Algorithm", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-SignedHeaders", valid_613432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613433: Call_DeleteInsight_613422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ## 
  let valid = call_613433.validator(path, query, header, formData, body)
  let scheme = call_613433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613433.url(scheme.get, call_613433.host, call_613433.base,
                         call_613433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613433, url, valid)

proc call*(call_613434: Call_DeleteInsight_613422; InsightArn: string): Recallable =
  ## deleteInsight
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight to delete.
  var path_613435 = newJObject()
  add(path_613435, "InsightArn", newJString(InsightArn))
  result = call_613434.call(path_613435, nil, nil, nil, nil)

var deleteInsight* = Call_DeleteInsight_613422(name: "deleteInsight",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_DeleteInsight_613423,
    base: "/", url: url_DeleteInsight_613424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_613452 = ref object of OpenApiRestCall_612658
proc url_DeleteInvitations_613454(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInvitations_613453(path: JsonNode; query: JsonNode;
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
  var valid_613455 = header.getOrDefault("X-Amz-Signature")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Signature", valid_613455
  var valid_613456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-Content-Sha256", valid_613456
  var valid_613457 = header.getOrDefault("X-Amz-Date")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Date", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-Credential")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Credential", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Security-Token")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Security-Token", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Algorithm")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Algorithm", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-SignedHeaders", valid_613461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613463: Call_DeleteInvitations_613452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations received by the AWS account to become a member account.
  ## 
  let valid = call_613463.validator(path, query, header, formData, body)
  let scheme = call_613463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613463.url(scheme.get, call_613463.host, call_613463.base,
                         call_613463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613463, url, valid)

proc call*(call_613464: Call_DeleteInvitations_613452; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations received by the AWS account to become a member account.
  ##   body: JObject (required)
  var body_613465 = newJObject()
  if body != nil:
    body_613465 = body
  result = call_613464.call(nil, nil, nil, nil, body_613465)

var deleteInvitations* = Call_DeleteInvitations_613452(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/invitations/delete", validator: validate_DeleteInvitations_613453,
    base: "/", url: url_DeleteInvitations_613454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_613466 = ref object of OpenApiRestCall_612658
proc url_DeleteMembers_613468(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMembers_613467(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613469 = header.getOrDefault("X-Amz-Signature")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Signature", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Content-Sha256", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-Date")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Date", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-Credential")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Credential", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Security-Token")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Security-Token", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Algorithm")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Algorithm", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-SignedHeaders", valid_613475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613477: Call_DeleteMembers_613466; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified member accounts from Security Hub.
  ## 
  let valid = call_613477.validator(path, query, header, formData, body)
  let scheme = call_613477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613477.url(scheme.get, call_613477.host, call_613477.base,
                         call_613477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613477, url, valid)

proc call*(call_613478: Call_DeleteMembers_613466; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes the specified member accounts from Security Hub.
  ##   body: JObject (required)
  var body_613479 = newJObject()
  if body != nil:
    body_613479 = body
  result = call_613478.call(nil, nil, nil, nil, body_613479)

var deleteMembers* = Call_DeleteMembers_613466(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/delete", validator: validate_DeleteMembers_613467, base: "/",
    url: url_DeleteMembers_613468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActionTargets_613480 = ref object of OpenApiRestCall_612658
proc url_DescribeActionTargets_613482(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeActionTargets_613481(path: JsonNode; query: JsonNode;
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
  var valid_613483 = query.getOrDefault("MaxResults")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "MaxResults", valid_613483
  var valid_613484 = query.getOrDefault("NextToken")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "NextToken", valid_613484
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
  var valid_613485 = header.getOrDefault("X-Amz-Signature")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Signature", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Content-Sha256", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-Date")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Date", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Credential")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Credential", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Security-Token")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Security-Token", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Algorithm")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Algorithm", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-SignedHeaders", valid_613491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613493: Call_DescribeActionTargets_613480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the custom action targets in Security Hub in your account.
  ## 
  let valid = call_613493.validator(path, query, header, formData, body)
  let scheme = call_613493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613493.url(scheme.get, call_613493.host, call_613493.base,
                         call_613493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613493, url, valid)

proc call*(call_613494: Call_DescribeActionTargets_613480; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeActionTargets
  ## Returns a list of the custom action targets in Security Hub in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613495 = newJObject()
  var body_613496 = newJObject()
  add(query_613495, "MaxResults", newJString(MaxResults))
  add(query_613495, "NextToken", newJString(NextToken))
  if body != nil:
    body_613496 = body
  result = call_613494.call(nil, query_613495, nil, nil, body_613496)

var describeActionTargets* = Call_DescribeActionTargets_613480(
    name: "describeActionTargets", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets/get",
    validator: validate_DescribeActionTargets_613481, base: "/",
    url: url_DescribeActionTargets_613482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSecurityHub_613511 = ref object of OpenApiRestCall_612658
proc url_EnableSecurityHub_613513(protocol: Scheme; host: string; base: string;
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

proc validate_EnableSecurityHub_613512(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Enables Security Hub for your account in the current Region or the Region you specify in the request.</p> <p>Enabling Security Hub also enables the CIS AWS Foundations standard.</p> <p>When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie.</p> <p>To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.</p>
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
  var valid_613514 = header.getOrDefault("X-Amz-Signature")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Signature", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Content-Sha256", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Date")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Date", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Credential")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Credential", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Security-Token")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Security-Token", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-Algorithm")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Algorithm", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-SignedHeaders", valid_613520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613522: Call_EnableSecurityHub_613511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables Security Hub for your account in the current Region or the Region you specify in the request.</p> <p>Enabling Security Hub also enables the CIS AWS Foundations standard.</p> <p>When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie.</p> <p>To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.</p>
  ## 
  let valid = call_613522.validator(path, query, header, formData, body)
  let scheme = call_613522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613522.url(scheme.get, call_613522.host, call_613522.base,
                         call_613522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613522, url, valid)

proc call*(call_613523: Call_EnableSecurityHub_613511; body: JsonNode): Recallable =
  ## enableSecurityHub
  ## <p>Enables Security Hub for your account in the current Region or the Region you specify in the request.</p> <p>Enabling Security Hub also enables the CIS AWS Foundations standard.</p> <p>When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie.</p> <p>To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.</p>
  ##   body: JObject (required)
  var body_613524 = newJObject()
  if body != nil:
    body_613524 = body
  result = call_613523.call(nil, nil, nil, nil, body_613524)

var enableSecurityHub* = Call_EnableSecurityHub_613511(name: "enableSecurityHub",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/accounts", validator: validate_EnableSecurityHub_613512, base: "/",
    url: url_EnableSecurityHub_613513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHub_613497 = ref object of OpenApiRestCall_612658
proc url_DescribeHub_613499(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeHub_613498(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613500 = query.getOrDefault("HubArn")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "HubArn", valid_613500
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
  var valid_613501 = header.getOrDefault("X-Amz-Signature")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Signature", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Content-Sha256", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Date")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Date", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Credential")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Credential", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Security-Token")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Security-Token", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Algorithm")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Algorithm", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-SignedHeaders", valid_613507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613508: Call_DescribeHub_613497; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ## 
  let valid = call_613508.validator(path, query, header, formData, body)
  let scheme = call_613508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613508.url(scheme.get, call_613508.host, call_613508.base,
                         call_613508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613508, url, valid)

proc call*(call_613509: Call_DescribeHub_613497; HubArn: string = ""): Recallable =
  ## describeHub
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ##   HubArn: string
  ##         : The ARN of the Hub resource to retrieve.
  var query_613510 = newJObject()
  add(query_613510, "HubArn", newJString(HubArn))
  result = call_613509.call(nil, query_613510, nil, nil, nil)

var describeHub* = Call_DescribeHub_613497(name: "describeHub",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/accounts",
                                        validator: validate_DescribeHub_613498,
                                        base: "/", url: url_DescribeHub_613499,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSecurityHub_613525 = ref object of OpenApiRestCall_612658
proc url_DisableSecurityHub_613527(protocol: Scheme; host: string; base: string;
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

proc validate_DisableSecurityHub_613526(path: JsonNode; query: JsonNode;
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
  var valid_613528 = header.getOrDefault("X-Amz-Signature")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Signature", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Content-Sha256", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Date")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Date", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Credential")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Credential", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Security-Token")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Security-Token", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Algorithm")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Algorithm", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-SignedHeaders", valid_613534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613535: Call_DisableSecurityHub_613525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub.</p> <p>When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and cannot be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed.</p> <p>If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  ## 
  let valid = call_613535.validator(path, query, header, formData, body)
  let scheme = call_613535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613535.url(scheme.get, call_613535.host, call_613535.base,
                         call_613535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613535, url, valid)

proc call*(call_613536: Call_DisableSecurityHub_613525): Recallable =
  ## disableSecurityHub
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub.</p> <p>When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and cannot be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed.</p> <p>If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  result = call_613536.call(nil, nil, nil, nil, nil)

var disableSecurityHub* = Call_DisableSecurityHub_613525(
    name: "disableSecurityHub", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/accounts",
    validator: validate_DisableSecurityHub_613526, base: "/",
    url: url_DisableSecurityHub_613527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProducts_613537 = ref object of OpenApiRestCall_612658
proc url_DescribeProducts_613539(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProducts_613538(path: JsonNode; query: JsonNode;
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
  ##            : The token that is required for pagination.
  section = newJObject()
  var valid_613540 = query.getOrDefault("MaxResults")
  valid_613540 = validateParameter(valid_613540, JInt, required = false, default = nil)
  if valid_613540 != nil:
    section.add "MaxResults", valid_613540
  var valid_613541 = query.getOrDefault("NextToken")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "NextToken", valid_613541
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
  var valid_613542 = header.getOrDefault("X-Amz-Signature")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Signature", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Content-Sha256", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Date")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Date", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Credential")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Credential", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Security-Token")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Security-Token", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Algorithm")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Algorithm", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-SignedHeaders", valid_613548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613549: Call_DescribeProducts_613537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the available products that you can subscribe to and integrate with Security Hub in order to consolidate findings.
  ## 
  let valid = call_613549.validator(path, query, header, formData, body)
  let scheme = call_613549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613549.url(scheme.get, call_613549.host, call_613549.base,
                         call_613549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613549, url, valid)

proc call*(call_613550: Call_DescribeProducts_613537; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## describeProducts
  ## Returns information about the available products that you can subscribe to and integrate with Security Hub in order to consolidate findings.
  ##   MaxResults: int
  ##             : The maximum number of results to return.
  ##   NextToken: string
  ##            : The token that is required for pagination.
  var query_613551 = newJObject()
  add(query_613551, "MaxResults", newJInt(MaxResults))
  add(query_613551, "NextToken", newJString(NextToken))
  result = call_613550.call(nil, query_613551, nil, nil, nil)

var describeProducts* = Call_DescribeProducts_613537(name: "describeProducts",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/products",
    validator: validate_DescribeProducts_613538, base: "/",
    url: url_DescribeProducts_613539, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStandardsControls_613552 = ref object of OpenApiRestCall_612658
proc url_DescribeStandardsControls_613554(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeStandardsControls_613553(path: JsonNode; query: JsonNode;
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
  var valid_613555 = path.getOrDefault("StandardsSubscriptionArn")
  valid_613555 = validateParameter(valid_613555, JString, required = true,
                                 default = nil)
  if valid_613555 != nil:
    section.add "StandardsSubscriptionArn", valid_613555
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum number of compliance standard controls to return.
  ##   NextToken: JString
  ##            : For requests to get the next page of results, the pagination token that was returned with the previous set of results. The initial request does not include a pagination token.
  section = newJObject()
  var valid_613556 = query.getOrDefault("MaxResults")
  valid_613556 = validateParameter(valid_613556, JInt, required = false, default = nil)
  if valid_613556 != nil:
    section.add "MaxResults", valid_613556
  var valid_613557 = query.getOrDefault("NextToken")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "NextToken", valid_613557
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
  var valid_613558 = header.getOrDefault("X-Amz-Signature")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Signature", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Content-Sha256", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Date")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Date", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Credential")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Credential", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-Security-Token")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Security-Token", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-Algorithm")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-Algorithm", valid_613563
  var valid_613564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613564 = validateParameter(valid_613564, JString, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "X-Amz-SignedHeaders", valid_613564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613565: Call_DescribeStandardsControls_613552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of compliance standards controls.</p> <p>For each control, the results include information about whether it is currently enabled, the severity, and a link to remediation information.</p>
  ## 
  let valid = call_613565.validator(path, query, header, formData, body)
  let scheme = call_613565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613565.url(scheme.get, call_613565.host, call_613565.base,
                         call_613565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613565, url, valid)

proc call*(call_613566: Call_DescribeStandardsControls_613552;
          StandardsSubscriptionArn: string; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## describeStandardsControls
  ## <p>Returns a list of compliance standards controls.</p> <p>For each control, the results include information about whether it is currently enabled, the severity, and a link to remediation information.</p>
  ##   MaxResults: int
  ##             : The maximum number of compliance standard controls to return.
  ##   StandardsSubscriptionArn: string (required)
  ##                           : The ARN of a resource that represents your subscription to a supported standard.
  ##   NextToken: string
  ##            : For requests to get the next page of results, the pagination token that was returned with the previous set of results. The initial request does not include a pagination token.
  var path_613567 = newJObject()
  var query_613568 = newJObject()
  add(query_613568, "MaxResults", newJInt(MaxResults))
  add(path_613567, "StandardsSubscriptionArn",
      newJString(StandardsSubscriptionArn))
  add(query_613568, "NextToken", newJString(NextToken))
  result = call_613566.call(path_613567, query_613568, nil, nil, nil)

var describeStandardsControls* = Call_DescribeStandardsControls_613552(
    name: "describeStandardsControls", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com",
    route: "/standards/controls/{StandardsSubscriptionArn}",
    validator: validate_DescribeStandardsControls_613553, base: "/",
    url: url_DescribeStandardsControls_613554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableImportFindingsForProduct_613569 = ref object of OpenApiRestCall_612658
proc url_DisableImportFindingsForProduct_613571(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisableImportFindingsForProduct_613570(path: JsonNode;
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
  var valid_613572 = path.getOrDefault("ProductSubscriptionArn")
  valid_613572 = validateParameter(valid_613572, JString, required = true,
                                 default = nil)
  if valid_613572 != nil:
    section.add "ProductSubscriptionArn", valid_613572
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
  var valid_613573 = header.getOrDefault("X-Amz-Signature")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Signature", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Content-Sha256", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-Date")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Date", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-Credential")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Credential", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Security-Token")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Security-Token", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Algorithm")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Algorithm", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-SignedHeaders", valid_613579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613580: Call_DisableImportFindingsForProduct_613569;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disables the integration of the specified product with Security Hub. After the integration is disabled, findings from that product are no longer sent to Security Hub.
  ## 
  let valid = call_613580.validator(path, query, header, formData, body)
  let scheme = call_613580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613580.url(scheme.get, call_613580.host, call_613580.base,
                         call_613580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613580, url, valid)

proc call*(call_613581: Call_DisableImportFindingsForProduct_613569;
          ProductSubscriptionArn: string): Recallable =
  ## disableImportFindingsForProduct
  ## Disables the integration of the specified product with Security Hub. After the integration is disabled, findings from that product are no longer sent to Security Hub.
  ##   ProductSubscriptionArn: string (required)
  ##                         : The ARN of the integrated product to disable the integration for.
  var path_613582 = newJObject()
  add(path_613582, "ProductSubscriptionArn", newJString(ProductSubscriptionArn))
  result = call_613581.call(path_613582, nil, nil, nil, nil)

var disableImportFindingsForProduct* = Call_DisableImportFindingsForProduct_613569(
    name: "disableImportFindingsForProduct", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com",
    route: "/productSubscriptions/{ProductSubscriptionArn}",
    validator: validate_DisableImportFindingsForProduct_613570, base: "/",
    url: url_DisableImportFindingsForProduct_613571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_613583 = ref object of OpenApiRestCall_612658
proc url_DisassociateFromMasterAccount_613585(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateFromMasterAccount_613584(path: JsonNode; query: JsonNode;
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
  var valid_613586 = header.getOrDefault("X-Amz-Signature")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Signature", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Content-Sha256", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Date")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Date", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Credential")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Credential", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-Security-Token")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Security-Token", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Algorithm")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Algorithm", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-SignedHeaders", valid_613592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613593: Call_DisassociateFromMasterAccount_613583; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current Security Hub member account from the associated master account.
  ## 
  let valid = call_613593.validator(path, query, header, formData, body)
  let scheme = call_613593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613593.url(scheme.get, call_613593.host, call_613593.base,
                         call_613593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613593, url, valid)

proc call*(call_613594: Call_DisassociateFromMasterAccount_613583): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current Security Hub member account from the associated master account.
  result = call_613594.call(nil, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_613583(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_613584, base: "/",
    url: url_DisassociateFromMasterAccount_613585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_613595 = ref object of OpenApiRestCall_612658
proc url_DisassociateMembers_613597(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateMembers_613596(path: JsonNode; query: JsonNode;
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
  var valid_613598 = header.getOrDefault("X-Amz-Signature")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "X-Amz-Signature", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Content-Sha256", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Date")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Date", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Credential")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Credential", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Security-Token")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Security-Token", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Algorithm")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Algorithm", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-SignedHeaders", valid_613604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613606: Call_DisassociateMembers_613595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified member accounts from the associated master account.
  ## 
  let valid = call_613606.validator(path, query, header, formData, body)
  let scheme = call_613606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613606.url(scheme.get, call_613606.host, call_613606.base,
                         call_613606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613606, url, valid)

proc call*(call_613607: Call_DisassociateMembers_613595; body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates the specified member accounts from the associated master account.
  ##   body: JObject (required)
  var body_613608 = newJObject()
  if body != nil:
    body_613608 = body
  result = call_613607.call(nil, nil, nil, nil, body_613608)

var disassociateMembers* = Call_DisassociateMembers_613595(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/members/disassociate",
    validator: validate_DisassociateMembers_613596, base: "/",
    url: url_DisassociateMembers_613597, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableImportFindingsForProduct_613624 = ref object of OpenApiRestCall_612658
proc url_EnableImportFindingsForProduct_613626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableImportFindingsForProduct_613625(path: JsonNode;
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
  var valid_613627 = header.getOrDefault("X-Amz-Signature")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Signature", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Content-Sha256", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Date")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Date", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Credential")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Credential", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Security-Token")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Security-Token", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-Algorithm")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-Algorithm", valid_613632
  var valid_613633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-SignedHeaders", valid_613633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613635: Call_EnableImportFindingsForProduct_613624; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub.</p> <p>When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.</p>
  ## 
  let valid = call_613635.validator(path, query, header, formData, body)
  let scheme = call_613635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613635.url(scheme.get, call_613635.host, call_613635.base,
                         call_613635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613635, url, valid)

proc call*(call_613636: Call_EnableImportFindingsForProduct_613624; body: JsonNode): Recallable =
  ## enableImportFindingsForProduct
  ## <p>Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub.</p> <p>When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.</p>
  ##   body: JObject (required)
  var body_613637 = newJObject()
  if body != nil:
    body_613637 = body
  result = call_613636.call(nil, nil, nil, nil, body_613637)

var enableImportFindingsForProduct* = Call_EnableImportFindingsForProduct_613624(
    name: "enableImportFindingsForProduct", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_EnableImportFindingsForProduct_613625, base: "/",
    url: url_EnableImportFindingsForProduct_613626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnabledProductsForImport_613609 = ref object of OpenApiRestCall_612658
proc url_ListEnabledProductsForImport_613611(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEnabledProductsForImport_613610(path: JsonNode; query: JsonNode;
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
  ##            : Paginates results. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, to continue listing data, set <code>nextToken</code> in the request to the value of <code>NextToken</code> from the previous response.
  section = newJObject()
  var valid_613612 = query.getOrDefault("MaxResults")
  valid_613612 = validateParameter(valid_613612, JInt, required = false, default = nil)
  if valid_613612 != nil:
    section.add "MaxResults", valid_613612
  var valid_613613 = query.getOrDefault("NextToken")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "NextToken", valid_613613
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
  var valid_613614 = header.getOrDefault("X-Amz-Signature")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Signature", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Content-Sha256", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Date")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Date", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Credential")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Credential", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Security-Token")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Security-Token", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Algorithm")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Algorithm", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-SignedHeaders", valid_613620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613621: Call_ListEnabledProductsForImport_613609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all findings-generating solutions (products) that you are subscribed to receive findings from in Security Hub.
  ## 
  let valid = call_613621.validator(path, query, header, formData, body)
  let scheme = call_613621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613621.url(scheme.get, call_613621.host, call_613621.base,
                         call_613621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613621, url, valid)

proc call*(call_613622: Call_ListEnabledProductsForImport_613609;
          MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## listEnabledProductsForImport
  ## Lists all findings-generating solutions (products) that you are subscribed to receive findings from in Security Hub.
  ##   MaxResults: int
  ##             : The maximum number of items to return in the response.
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, to continue listing data, set <code>nextToken</code> in the request to the value of <code>NextToken</code> from the previous response.
  var query_613623 = newJObject()
  add(query_613623, "MaxResults", newJInt(MaxResults))
  add(query_613623, "NextToken", newJString(NextToken))
  result = call_613622.call(nil, query_613623, nil, nil, nil)

var listEnabledProductsForImport* = Call_ListEnabledProductsForImport_613609(
    name: "listEnabledProductsForImport", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_ListEnabledProductsForImport_613610, base: "/",
    url: url_ListEnabledProductsForImport_613611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnabledStandards_613638 = ref object of OpenApiRestCall_612658
proc url_GetEnabledStandards_613640(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnabledStandards_613639(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613641 = header.getOrDefault("X-Amz-Signature")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Signature", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Content-Sha256", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-Date")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Date", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Credential")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Credential", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Security-Token")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Security-Token", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Algorithm")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Algorithm", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-SignedHeaders", valid_613647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613649: Call_GetEnabledStandards_613638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the standards that are currently enabled.
  ## 
  let valid = call_613649.validator(path, query, header, formData, body)
  let scheme = call_613649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613649.url(scheme.get, call_613649.host, call_613649.base,
                         call_613649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613649, url, valid)

proc call*(call_613650: Call_GetEnabledStandards_613638; body: JsonNode): Recallable =
  ## getEnabledStandards
  ## Returns a list of the standards that are currently enabled.
  ##   body: JObject (required)
  var body_613651 = newJObject()
  if body != nil:
    body_613651 = body
  result = call_613650.call(nil, nil, nil, nil, body_613651)

var getEnabledStandards* = Call_GetEnabledStandards_613638(
    name: "getEnabledStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/get",
    validator: validate_GetEnabledStandards_613639, base: "/",
    url: url_GetEnabledStandards_613640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_613652 = ref object of OpenApiRestCall_612658
proc url_GetFindings_613654(protocol: Scheme; host: string; base: string;
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

proc validate_GetFindings_613653(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613655 = query.getOrDefault("MaxResults")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "MaxResults", valid_613655
  var valid_613656 = query.getOrDefault("NextToken")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "NextToken", valid_613656
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
  var valid_613657 = header.getOrDefault("X-Amz-Signature")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Signature", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Content-Sha256", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Date")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Date", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Credential")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Credential", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Security-Token")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Security-Token", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Algorithm")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Algorithm", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-SignedHeaders", valid_613663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613665: Call_GetFindings_613652; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of findings that match the specified criteria.
  ## 
  let valid = call_613665.validator(path, query, header, formData, body)
  let scheme = call_613665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613665.url(scheme.get, call_613665.host, call_613665.base,
                         call_613665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613665, url, valid)

proc call*(call_613666: Call_GetFindings_613652; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getFindings
  ## Returns a list of findings that match the specified criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613667 = newJObject()
  var body_613668 = newJObject()
  add(query_613667, "MaxResults", newJString(MaxResults))
  add(query_613667, "NextToken", newJString(NextToken))
  if body != nil:
    body_613668 = body
  result = call_613666.call(nil, query_613667, nil, nil, body_613668)

var getFindings* = Call_GetFindings_613652(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/findings",
                                        validator: validate_GetFindings_613653,
                                        base: "/", url: url_GetFindings_613654,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_613669 = ref object of OpenApiRestCall_612658
proc url_UpdateFindings_613671(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFindings_613670(path: JsonNode; query: JsonNode;
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
  var valid_613672 = header.getOrDefault("X-Amz-Signature")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Signature", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-Content-Sha256", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Date")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Date", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Credential")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Credential", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Security-Token")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Security-Token", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Algorithm")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Algorithm", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-SignedHeaders", valid_613678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613680: Call_UpdateFindings_613669; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ## 
  let valid = call_613680.validator(path, query, header, formData, body)
  let scheme = call_613680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613680.url(scheme.get, call_613680.host, call_613680.base,
                         call_613680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613680, url, valid)

proc call*(call_613681: Call_UpdateFindings_613669; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ##   body: JObject (required)
  var body_613682 = newJObject()
  if body != nil:
    body_613682 = body
  result = call_613681.call(nil, nil, nil, nil, body_613682)

var updateFindings* = Call_UpdateFindings_613669(name: "updateFindings",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/findings", validator: validate_UpdateFindings_613670, base: "/",
    url: url_UpdateFindings_613671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsightResults_613683 = ref object of OpenApiRestCall_612658
proc url_GetInsightResults_613685(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetInsightResults_613684(path: JsonNode; query: JsonNode;
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
  var valid_613686 = path.getOrDefault("InsightArn")
  valid_613686 = validateParameter(valid_613686, JString, required = true,
                                 default = nil)
  if valid_613686 != nil:
    section.add "InsightArn", valid_613686
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
  var valid_613687 = header.getOrDefault("X-Amz-Signature")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Signature", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-Content-Sha256", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Date")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Date", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Credential")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Credential", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Security-Token")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Security-Token", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Algorithm")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Algorithm", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-SignedHeaders", valid_613693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613694: Call_GetInsightResults_613683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the results of the Security Hub insight specified by the insight ARN.
  ## 
  let valid = call_613694.validator(path, query, header, formData, body)
  let scheme = call_613694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613694.url(scheme.get, call_613694.host, call_613694.base,
                         call_613694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613694, url, valid)

proc call*(call_613695: Call_GetInsightResults_613683; InsightArn: string): Recallable =
  ## getInsightResults
  ## Lists the results of the Security Hub insight specified by the insight ARN.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight for which to return results.
  var path_613696 = newJObject()
  add(path_613696, "InsightArn", newJString(InsightArn))
  result = call_613695.call(path_613696, nil, nil, nil, nil)

var getInsightResults* = Call_GetInsightResults_613683(name: "getInsightResults",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/insights/results/{InsightArn}",
    validator: validate_GetInsightResults_613684, base: "/",
    url: url_GetInsightResults_613685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsights_613697 = ref object of OpenApiRestCall_612658
proc url_GetInsights_613699(protocol: Scheme; host: string; base: string;
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

proc validate_GetInsights_613698(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613700 = query.getOrDefault("MaxResults")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "MaxResults", valid_613700
  var valid_613701 = query.getOrDefault("NextToken")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "NextToken", valid_613701
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
  var valid_613702 = header.getOrDefault("X-Amz-Signature")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Signature", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Content-Sha256", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Date")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Date", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Credential")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Credential", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Security-Token")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Security-Token", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Algorithm")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Algorithm", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-SignedHeaders", valid_613708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613710: Call_GetInsights_613697; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists and describes insights for the specified insight ARNs.
  ## 
  let valid = call_613710.validator(path, query, header, formData, body)
  let scheme = call_613710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613710.url(scheme.get, call_613710.host, call_613710.base,
                         call_613710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613710, url, valid)

proc call*(call_613711: Call_GetInsights_613697; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getInsights
  ## Lists and describes insights for the specified insight ARNs.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613712 = newJObject()
  var body_613713 = newJObject()
  add(query_613712, "MaxResults", newJString(MaxResults))
  add(query_613712, "NextToken", newJString(NextToken))
  if body != nil:
    body_613713 = body
  result = call_613711.call(nil, query_613712, nil, nil, body_613713)

var getInsights* = Call_GetInsights_613697(name: "getInsights",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/insights/get",
                                        validator: validate_GetInsights_613698,
                                        base: "/", url: url_GetInsights_613699,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_613714 = ref object of OpenApiRestCall_612658
proc url_GetInvitationsCount_613716(protocol: Scheme; host: string; base: string;
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

proc validate_GetInvitationsCount_613715(path: JsonNode; query: JsonNode;
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
  var valid_613717 = header.getOrDefault("X-Amz-Signature")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-Signature", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-Content-Sha256", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Date")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Date", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Credential")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Credential", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Security-Token")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Security-Token", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Algorithm")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Algorithm", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-SignedHeaders", valid_613723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613724: Call_GetInvitationsCount_613714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  ## 
  let valid = call_613724.validator(path, query, header, formData, body)
  let scheme = call_613724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613724.url(scheme.get, call_613724.host, call_613724.base,
                         call_613724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613724, url, valid)

proc call*(call_613725: Call_GetInvitationsCount_613714): Recallable =
  ## getInvitationsCount
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  result = call_613725.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_613714(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/invitations/count",
    validator: validate_GetInvitationsCount_613715, base: "/",
    url: url_GetInvitationsCount_613716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_613726 = ref object of OpenApiRestCall_612658
proc url_GetMembers_613728(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMembers_613727(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613729 = header.getOrDefault("X-Amz-Signature")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Signature", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-Content-Sha256", valid_613730
  var valid_613731 = header.getOrDefault("X-Amz-Date")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-Date", valid_613731
  var valid_613732 = header.getOrDefault("X-Amz-Credential")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = nil)
  if valid_613732 != nil:
    section.add "X-Amz-Credential", valid_613732
  var valid_613733 = header.getOrDefault("X-Amz-Security-Token")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "X-Amz-Security-Token", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-Algorithm")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Algorithm", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-SignedHeaders", valid_613735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613737: Call_GetMembers_613726; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details for the Security Hub member accounts for the specified account IDs.
  ## 
  let valid = call_613737.validator(path, query, header, formData, body)
  let scheme = call_613737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613737.url(scheme.get, call_613737.host, call_613737.base,
                         call_613737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613737, url, valid)

proc call*(call_613738: Call_GetMembers_613726; body: JsonNode): Recallable =
  ## getMembers
  ## Returns the details for the Security Hub member accounts for the specified account IDs.
  ##   body: JObject (required)
  var body_613739 = newJObject()
  if body != nil:
    body_613739 = body
  result = call_613738.call(nil, nil, nil, nil, body_613739)

var getMembers* = Call_GetMembers_613726(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "securityhub.amazonaws.com",
                                      route: "/members/get",
                                      validator: validate_GetMembers_613727,
                                      base: "/", url: url_GetMembers_613728,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_613740 = ref object of OpenApiRestCall_612658
proc url_InviteMembers_613742(protocol: Scheme; host: string; base: string;
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

proc validate_InviteMembers_613741(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from.</p> <p>Before you can use this action to invite a member, you must first use the <a>CreateMembers</a> action to create the member account in Security Hub.</p> <p>When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from the member account.</p>
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
  var valid_613743 = header.getOrDefault("X-Amz-Signature")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Signature", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Content-Sha256", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Date")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Date", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-Credential")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Credential", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Security-Token")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Security-Token", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Algorithm")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Algorithm", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-SignedHeaders", valid_613749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613751: Call_InviteMembers_613740; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from.</p> <p>Before you can use this action to invite a member, you must first use the <a>CreateMembers</a> action to create the member account in Security Hub.</p> <p>When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from the member account.</p>
  ## 
  let valid = call_613751.validator(path, query, header, formData, body)
  let scheme = call_613751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613751.url(scheme.get, call_613751.host, call_613751.base,
                         call_613751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613751, url, valid)

proc call*(call_613752: Call_InviteMembers_613740; body: JsonNode): Recallable =
  ## inviteMembers
  ## <p>Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from.</p> <p>Before you can use this action to invite a member, you must first use the <a>CreateMembers</a> action to create the member account in Security Hub.</p> <p>When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from the member account.</p>
  ##   body: JObject (required)
  var body_613753 = newJObject()
  if body != nil:
    body_613753 = body
  result = call_613752.call(nil, nil, nil, nil, body_613753)

var inviteMembers* = Call_InviteMembers_613740(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/invite", validator: validate_InviteMembers_613741, base: "/",
    url: url_InviteMembers_613742, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_613754 = ref object of OpenApiRestCall_612658
proc url_ListInvitations_613756(protocol: Scheme; host: string; base: string;
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

proc validate_ListInvitations_613755(path: JsonNode; query: JsonNode;
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
  ##            : Paginates results. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, to continue listing data, set <code>nextToken</code> in the request to the value of <code>NextToken</code> from the previous response. 
  section = newJObject()
  var valid_613757 = query.getOrDefault("MaxResults")
  valid_613757 = validateParameter(valid_613757, JInt, required = false, default = nil)
  if valid_613757 != nil:
    section.add "MaxResults", valid_613757
  var valid_613758 = query.getOrDefault("NextToken")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "NextToken", valid_613758
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
  var valid_613759 = header.getOrDefault("X-Amz-Signature")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Signature", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Content-Sha256", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-Date")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-Date", valid_613761
  var valid_613762 = header.getOrDefault("X-Amz-Credential")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-Credential", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-Security-Token")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-Security-Token", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Algorithm")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Algorithm", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-SignedHeaders", valid_613765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613766: Call_ListInvitations_613754; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ## 
  let valid = call_613766.validator(path, query, header, formData, body)
  let scheme = call_613766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613766.url(scheme.get, call_613766.host, call_613766.base,
                         call_613766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613766, url, valid)

proc call*(call_613767: Call_ListInvitations_613754; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## listInvitations
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ##   MaxResults: int
  ##             : The maximum number of items to return in the response. 
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, to continue listing data, set <code>nextToken</code> in the request to the value of <code>NextToken</code> from the previous response. 
  var query_613768 = newJObject()
  add(query_613768, "MaxResults", newJInt(MaxResults))
  add(query_613768, "NextToken", newJString(NextToken))
  result = call_613767.call(nil, query_613768, nil, nil, nil)

var listInvitations* = Call_ListInvitations_613754(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_613755, base: "/",
    url: url_ListInvitations_613756, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_613783 = ref object of OpenApiRestCall_612658
proc url_TagResource_613785(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_613784(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613786 = path.getOrDefault("ResourceArn")
  valid_613786 = validateParameter(valid_613786, JString, required = true,
                                 default = nil)
  if valid_613786 != nil:
    section.add "ResourceArn", valid_613786
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613795: Call_TagResource_613783; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a resource.
  ## 
  let valid = call_613795.validator(path, query, header, formData, body)
  let scheme = call_613795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613795.url(scheme.get, call_613795.host, call_613795.base,
                         call_613795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613795, url, valid)

proc call*(call_613796: Call_TagResource_613783; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to apply the tags to.
  ##   body: JObject (required)
  var path_613797 = newJObject()
  var body_613798 = newJObject()
  add(path_613797, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_613798 = body
  result = call_613796.call(path_613797, nil, nil, nil, body_613798)

var tagResource* = Call_TagResource_613783(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_613784,
                                        base: "/", url: url_TagResource_613785,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613769 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613771(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_613770(path: JsonNode; query: JsonNode;
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
  var valid_613772 = path.getOrDefault("ResourceArn")
  valid_613772 = validateParameter(valid_613772, JString, required = true,
                                 default = nil)
  if valid_613772 != nil:
    section.add "ResourceArn", valid_613772
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
  var valid_613773 = header.getOrDefault("X-Amz-Signature")
  valid_613773 = validateParameter(valid_613773, JString, required = false,
                                 default = nil)
  if valid_613773 != nil:
    section.add "X-Amz-Signature", valid_613773
  var valid_613774 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Content-Sha256", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-Date")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Date", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-Credential")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Credential", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Security-Token")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Security-Token", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Algorithm")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Algorithm", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-SignedHeaders", valid_613779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613780: Call_ListTagsForResource_613769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags associated with a resource.
  ## 
  let valid = call_613780.validator(path, query, header, formData, body)
  let scheme = call_613780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613780.url(scheme.get, call_613780.host, call_613780.base,
                         call_613780.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613780, url, valid)

proc call*(call_613781: Call_ListTagsForResource_613769; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags associated with a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to retrieve tags for.
  var path_613782 = newJObject()
  add(path_613782, "ResourceArn", newJString(ResourceArn))
  result = call_613781.call(path_613782, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613769(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_613770, base: "/",
    url: url_ListTagsForResource_613771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613799 = ref object of OpenApiRestCall_612658
proc url_UntagResource_613801(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_613800(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613802 = path.getOrDefault("ResourceArn")
  valid_613802 = validateParameter(valid_613802, JString, required = true,
                                 default = nil)
  if valid_613802 != nil:
    section.add "ResourceArn", valid_613802
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613803 = query.getOrDefault("tagKeys")
  valid_613803 = validateParameter(valid_613803, JArray, required = true, default = nil)
  if valid_613803 != nil:
    section.add "tagKeys", valid_613803
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
  var valid_613804 = header.getOrDefault("X-Amz-Signature")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Signature", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-Content-Sha256", valid_613805
  var valid_613806 = header.getOrDefault("X-Amz-Date")
  valid_613806 = validateParameter(valid_613806, JString, required = false,
                                 default = nil)
  if valid_613806 != nil:
    section.add "X-Amz-Date", valid_613806
  var valid_613807 = header.getOrDefault("X-Amz-Credential")
  valid_613807 = validateParameter(valid_613807, JString, required = false,
                                 default = nil)
  if valid_613807 != nil:
    section.add "X-Amz-Credential", valid_613807
  var valid_613808 = header.getOrDefault("X-Amz-Security-Token")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "X-Amz-Security-Token", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Algorithm")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Algorithm", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-SignedHeaders", valid_613810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613811: Call_UntagResource_613799; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a resource.
  ## 
  let valid = call_613811.validator(path, query, header, formData, body)
  let scheme = call_613811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613811.url(scheme.get, call_613811.host, call_613811.base,
                         call_613811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613811, url, valid)

proc call*(call_613812: Call_UntagResource_613799; ResourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to remove the tags from.
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  var path_613813 = newJObject()
  var query_613814 = newJObject()
  add(path_613813, "ResourceArn", newJString(ResourceArn))
  if tagKeys != nil:
    query_613814.add "tagKeys", tagKeys
  result = call_613812.call(path_613813, query_613814, nil, nil, nil)

var untagResource* = Call_UntagResource_613799(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_613800,
    base: "/", url: url_UntagResource_613801, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStandardsControl_613815 = ref object of OpenApiRestCall_612658
proc url_UpdateStandardsControl_613817(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStandardsControl_613816(path: JsonNode; query: JsonNode;
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
  var valid_613818 = path.getOrDefault("StandardsControlArn")
  valid_613818 = validateParameter(valid_613818, JString, required = true,
                                 default = nil)
  if valid_613818 != nil:
    section.add "StandardsControlArn", valid_613818
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
  var valid_613819 = header.getOrDefault("X-Amz-Signature")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-Signature", valid_613819
  var valid_613820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-Content-Sha256", valid_613820
  var valid_613821 = header.getOrDefault("X-Amz-Date")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "X-Amz-Date", valid_613821
  var valid_613822 = header.getOrDefault("X-Amz-Credential")
  valid_613822 = validateParameter(valid_613822, JString, required = false,
                                 default = nil)
  if valid_613822 != nil:
    section.add "X-Amz-Credential", valid_613822
  var valid_613823 = header.getOrDefault("X-Amz-Security-Token")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "X-Amz-Security-Token", valid_613823
  var valid_613824 = header.getOrDefault("X-Amz-Algorithm")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-Algorithm", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-SignedHeaders", valid_613825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613827: Call_UpdateStandardsControl_613815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to control whether an individual compliance standard control is enabled or disabled.
  ## 
  let valid = call_613827.validator(path, query, header, formData, body)
  let scheme = call_613827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613827.url(scheme.get, call_613827.host, call_613827.base,
                         call_613827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613827, url, valid)

proc call*(call_613828: Call_UpdateStandardsControl_613815;
          StandardsControlArn: string; body: JsonNode): Recallable =
  ## updateStandardsControl
  ## Used to control whether an individual compliance standard control is enabled or disabled.
  ##   StandardsControlArn: string (required)
  ##                      : The ARN of the compliance standard control to enable or disable.
  ##   body: JObject (required)
  var path_613829 = newJObject()
  var body_613830 = newJObject()
  add(path_613829, "StandardsControlArn", newJString(StandardsControlArn))
  if body != nil:
    body_613830 = body
  result = call_613828.call(path_613829, nil, nil, nil, body_613830)

var updateStandardsControl* = Call_UpdateStandardsControl_613815(
    name: "updateStandardsControl", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com",
    route: "/standards/control/{StandardsControlArn}",
    validator: validate_UpdateStandardsControl_613816, base: "/",
    url: url_UpdateStandardsControl_613817, schemes: {Scheme.Https, Scheme.Http})
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
