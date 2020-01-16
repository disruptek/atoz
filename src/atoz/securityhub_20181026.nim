
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
## <p>Security Hub provides you with a comprehensive view of the security state of your AWS environment and resources. It also provides you with the compliance status of your environment based on CIS AWS Foundations compliance checks. Security Hub collects security data from AWS accounts, services, and integrated third-party products and helps you analyze security trends in your environment to identify the highest priority security issues. For more information about Security Hub, see the <i> <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html">AWS Security Hub User Guide</a> </i>.</p> <p>When you use operations in the Security Hub API, the requests are executed only in the AWS Region that is currently active or in the specific AWS Region that you specify in your request. Any configuration or settings change that results from the operation is applied only to that Region. To make the same change in other Regions, execute the same command for each Region to apply the change to. For example, if your Region is set to <code>us-west-2</code>, when you use <code>CreateMembers</code> to add a member account to Security Hub, the association of the member account with the master account is created only in the us-west-2 Region. Security Hub must be enabled for the member account in the same Region that the invite was sent from.</p> <p>The following throttling limits apply to using Security Hub API operations:</p> <ul> <li> <p> <code>GetFindings</code> - RateLimit of 3 requests per second, and a BurstLimit of 6 requests per second.</p> </li> <li> <p> <code>UpdateFindings</code> - RateLimit of 1 request per second, and a BurstLimit of 5 requests per second.</p> </li> <li> <p>All other operations - RateLimit of 10 request per second, and a BurstLimit of 30 requests per second.</p> </li> </ul>
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
  Call_AcceptInvitation_606179 = ref object of OpenApiRestCall_605589
proc url_AcceptInvitation_606181(protocol: Scheme; host: string; base: string;
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

proc validate_AcceptInvitation_606180(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606182 = header.getOrDefault("X-Amz-Signature")
  valid_606182 = validateParameter(valid_606182, JString, required = false,
                                 default = nil)
  if valid_606182 != nil:
    section.add "X-Amz-Signature", valid_606182
  var valid_606183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606183 = validateParameter(valid_606183, JString, required = false,
                                 default = nil)
  if valid_606183 != nil:
    section.add "X-Amz-Content-Sha256", valid_606183
  var valid_606184 = header.getOrDefault("X-Amz-Date")
  valid_606184 = validateParameter(valid_606184, JString, required = false,
                                 default = nil)
  if valid_606184 != nil:
    section.add "X-Amz-Date", valid_606184
  var valid_606185 = header.getOrDefault("X-Amz-Credential")
  valid_606185 = validateParameter(valid_606185, JString, required = false,
                                 default = nil)
  if valid_606185 != nil:
    section.add "X-Amz-Credential", valid_606185
  var valid_606186 = header.getOrDefault("X-Amz-Security-Token")
  valid_606186 = validateParameter(valid_606186, JString, required = false,
                                 default = nil)
  if valid_606186 != nil:
    section.add "X-Amz-Security-Token", valid_606186
  var valid_606187 = header.getOrDefault("X-Amz-Algorithm")
  valid_606187 = validateParameter(valid_606187, JString, required = false,
                                 default = nil)
  if valid_606187 != nil:
    section.add "X-Amz-Algorithm", valid_606187
  var valid_606188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-SignedHeaders", valid_606188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606190: Call_AcceptInvitation_606179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from. When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.
  ## 
  let valid = call_606190.validator(path, query, header, formData, body)
  let scheme = call_606190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606190.url(scheme.get, call_606190.host, call_606190.base,
                         call_606190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606190, url, valid)

proc call*(call_606191: Call_AcceptInvitation_606179; body: JsonNode): Recallable =
  ## acceptInvitation
  ## Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from. When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.
  ##   body: JObject (required)
  var body_606192 = newJObject()
  if body != nil:
    body_606192 = body
  result = call_606191.call(nil, nil, nil, nil, body_606192)

var acceptInvitation* = Call_AcceptInvitation_606179(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_AcceptInvitation_606180, base: "/",
    url: url_AcceptInvitation_606181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_605927 = ref object of OpenApiRestCall_605589
proc url_GetMasterAccount_605929(protocol: Scheme; host: string; base: string;
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

proc validate_GetMasterAccount_605928(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606041 = header.getOrDefault("X-Amz-Signature")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "X-Amz-Signature", valid_606041
  var valid_606042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "X-Amz-Content-Sha256", valid_606042
  var valid_606043 = header.getOrDefault("X-Amz-Date")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Date", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-Credential")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Credential", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Security-Token")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Security-Token", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Algorithm")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Algorithm", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-SignedHeaders", valid_606047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606070: Call_GetMasterAccount_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the Security Hub master account to the current member account. 
  ## 
  let valid = call_606070.validator(path, query, header, formData, body)
  let scheme = call_606070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606070.url(scheme.get, call_606070.host, call_606070.base,
                         call_606070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606070, url, valid)

proc call*(call_606141: Call_GetMasterAccount_605927): Recallable =
  ## getMasterAccount
  ## Provides the details for the Security Hub master account to the current member account. 
  result = call_606141.call(nil, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_605927(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_GetMasterAccount_605928, base: "/",
    url: url_GetMasterAccount_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisableStandards_606194 = ref object of OpenApiRestCall_605589
proc url_BatchDisableStandards_606196(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDisableStandards_606195(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606197 = header.getOrDefault("X-Amz-Signature")
  valid_606197 = validateParameter(valid_606197, JString, required = false,
                                 default = nil)
  if valid_606197 != nil:
    section.add "X-Amz-Signature", valid_606197
  var valid_606198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606198 = validateParameter(valid_606198, JString, required = false,
                                 default = nil)
  if valid_606198 != nil:
    section.add "X-Amz-Content-Sha256", valid_606198
  var valid_606199 = header.getOrDefault("X-Amz-Date")
  valid_606199 = validateParameter(valid_606199, JString, required = false,
                                 default = nil)
  if valid_606199 != nil:
    section.add "X-Amz-Date", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Credential")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Credential", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Security-Token")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Security-Token", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Algorithm")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Algorithm", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-SignedHeaders", valid_606203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606205: Call_BatchDisableStandards_606194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ## 
  let valid = call_606205.validator(path, query, header, formData, body)
  let scheme = call_606205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606205.url(scheme.get, call_606205.host, call_606205.base,
                         call_606205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606205, url, valid)

proc call*(call_606206: Call_BatchDisableStandards_606194; body: JsonNode): Recallable =
  ## batchDisableStandards
  ## Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_606207 = newJObject()
  if body != nil:
    body_606207 = body
  result = call_606206.call(nil, nil, nil, nil, body_606207)

var batchDisableStandards* = Call_BatchDisableStandards_606194(
    name: "batchDisableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/deregister",
    validator: validate_BatchDisableStandards_606195, base: "/",
    url: url_BatchDisableStandards_606196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchEnableStandards_606208 = ref object of OpenApiRestCall_605589
proc url_BatchEnableStandards_606210(protocol: Scheme; host: string; base: string;
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

proc validate_BatchEnableStandards_606209(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606211 = header.getOrDefault("X-Amz-Signature")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Signature", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Content-Sha256", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-Date")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Date", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-Credential")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-Credential", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Security-Token")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Security-Token", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Algorithm")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Algorithm", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-SignedHeaders", valid_606217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606219: Call_BatchEnableStandards_606208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the standards specified by the provided <code>standardsArn</code>. In this release, only CIS AWS Foundations standards are supported. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ## 
  let valid = call_606219.validator(path, query, header, formData, body)
  let scheme = call_606219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606219.url(scheme.get, call_606219.host, call_606219.base,
                         call_606219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606219, url, valid)

proc call*(call_606220: Call_BatchEnableStandards_606208; body: JsonNode): Recallable =
  ## batchEnableStandards
  ## Enables the standards specified by the provided <code>standardsArn</code>. In this release, only CIS AWS Foundations standards are supported. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_606221 = newJObject()
  if body != nil:
    body_606221 = body
  result = call_606220.call(nil, nil, nil, nil, body_606221)

var batchEnableStandards* = Call_BatchEnableStandards_606208(
    name: "batchEnableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/register",
    validator: validate_BatchEnableStandards_606209, base: "/",
    url: url_BatchEnableStandards_606210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchImportFindings_606222 = ref object of OpenApiRestCall_605589
proc url_BatchImportFindings_606224(protocol: Scheme; host: string; base: string;
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

proc validate_BatchImportFindings_606223(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606225 = header.getOrDefault("X-Amz-Signature")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Signature", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Content-Sha256", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Date")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Date", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Credential")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Credential", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Security-Token")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Security-Token", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Algorithm")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Algorithm", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-SignedHeaders", valid_606231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606233: Call_BatchImportFindings_606222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub. The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.
  ## 
  let valid = call_606233.validator(path, query, header, formData, body)
  let scheme = call_606233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606233.url(scheme.get, call_606233.host, call_606233.base,
                         call_606233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606233, url, valid)

proc call*(call_606234: Call_BatchImportFindings_606222; body: JsonNode): Recallable =
  ## batchImportFindings
  ## Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub. The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.
  ##   body: JObject (required)
  var body_606235 = newJObject()
  if body != nil:
    body_606235 = body
  result = call_606234.call(nil, nil, nil, nil, body_606235)

var batchImportFindings* = Call_BatchImportFindings_606222(
    name: "batchImportFindings", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/findings/import",
    validator: validate_BatchImportFindings_606223, base: "/",
    url: url_BatchImportFindings_606224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActionTarget_606236 = ref object of OpenApiRestCall_605589
proc url_CreateActionTarget_606238(protocol: Scheme; host: string; base: string;
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

proc validate_CreateActionTarget_606237(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606239 = header.getOrDefault("X-Amz-Signature")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Signature", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Content-Sha256", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Date")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Date", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Credential")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Credential", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Security-Token")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Security-Token", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Algorithm")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Algorithm", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-SignedHeaders", valid_606245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606247: Call_CreateActionTarget_606236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom action target in Security Hub. You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.
  ## 
  let valid = call_606247.validator(path, query, header, formData, body)
  let scheme = call_606247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606247.url(scheme.get, call_606247.host, call_606247.base,
                         call_606247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606247, url, valid)

proc call*(call_606248: Call_CreateActionTarget_606236; body: JsonNode): Recallable =
  ## createActionTarget
  ## Creates a custom action target in Security Hub. You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.
  ##   body: JObject (required)
  var body_606249 = newJObject()
  if body != nil:
    body_606249 = body
  result = call_606248.call(nil, nil, nil, nil, body_606249)

var createActionTarget* = Call_CreateActionTarget_606236(
    name: "createActionTarget", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets",
    validator: validate_CreateActionTarget_606237, base: "/",
    url: url_CreateActionTarget_606238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInsight_606250 = ref object of OpenApiRestCall_605589
proc url_CreateInsight_606252(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInsight_606251(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606253 = header.getOrDefault("X-Amz-Signature")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Signature", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Content-Sha256", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Date")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Date", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Credential")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Credential", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Security-Token")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Security-Token", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Algorithm")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Algorithm", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-SignedHeaders", valid_606259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606261: Call_CreateInsight_606250; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation. Use the <code>GroupByAttribute</code> to group the related findings in the insight.
  ## 
  let valid = call_606261.validator(path, query, header, formData, body)
  let scheme = call_606261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606261.url(scheme.get, call_606261.host, call_606261.base,
                         call_606261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606261, url, valid)

proc call*(call_606262: Call_CreateInsight_606250; body: JsonNode): Recallable =
  ## createInsight
  ## Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation. Use the <code>GroupByAttribute</code> to group the related findings in the insight.
  ##   body: JObject (required)
  var body_606263 = newJObject()
  if body != nil:
    body_606263 = body
  result = call_606262.call(nil, nil, nil, nil, body_606263)

var createInsight* = Call_CreateInsight_606250(name: "createInsight",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/insights", validator: validate_CreateInsight_606251, base: "/",
    url: url_CreateInsight_606252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_606281 = ref object of OpenApiRestCall_605589
proc url_CreateMembers_606283(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMembers_606282(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606284 = header.getOrDefault("X-Amz-Signature")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Signature", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Content-Sha256", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Date")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Date", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Credential")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Credential", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Security-Token")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Security-Token", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-Algorithm")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Algorithm", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-SignedHeaders", valid_606290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606292: Call_CreateMembers_606281; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. You can use the <a>EnableSecurityHub</a> to enable Security Hub.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you need to use the <a>InviteMembers</a> action, which invites the accounts to enable Security Hub and become member accounts in Security Hub. If the invitation is accepted by the account owner, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start being sent to both the member and master accounts.</p> <p>You can remove the association between the master and member accounts by using the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ## 
  let valid = call_606292.validator(path, query, header, formData, body)
  let scheme = call_606292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606292.url(scheme.get, call_606292.host, call_606292.base,
                         call_606292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606292, url, valid)

proc call*(call_606293: Call_CreateMembers_606281; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. You can use the <a>EnableSecurityHub</a> to enable Security Hub.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you need to use the <a>InviteMembers</a> action, which invites the accounts to enable Security Hub and become member accounts in Security Hub. If the invitation is accepted by the account owner, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start being sent to both the member and master accounts.</p> <p>You can remove the association between the master and member accounts by using the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ##   body: JObject (required)
  var body_606294 = newJObject()
  if body != nil:
    body_606294 = body
  result = call_606293.call(nil, nil, nil, nil, body_606294)

var createMembers* = Call_CreateMembers_606281(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/members",
    validator: validate_CreateMembers_606282, base: "/", url: url_CreateMembers_606283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_606264 = ref object of OpenApiRestCall_605589
proc url_ListMembers_606266(protocol: Scheme; host: string; base: string;
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

proc validate_ListMembers_606265(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists details about all member accounts for the current Security Hub master account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum number of items that you want in the response. 
  ##   NextToken: JString
  ##            : Paginates results. Set the value of this parameter to <code>NULL</code> on your first call to the <code>ListMembers</code> operation. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>nextToken</code> from the previous response to continue listing data. 
  ##   OnlyAssociated: JBool
  ##                 : Specifies which member accounts the response includes based on their relationship status with the master account. The default value is <code>TRUE</code>. If <code>onlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>. If <code>onlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. 
  section = newJObject()
  var valid_606267 = query.getOrDefault("MaxResults")
  valid_606267 = validateParameter(valid_606267, JInt, required = false, default = nil)
  if valid_606267 != nil:
    section.add "MaxResults", valid_606267
  var valid_606268 = query.getOrDefault("NextToken")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "NextToken", valid_606268
  var valid_606269 = query.getOrDefault("OnlyAssociated")
  valid_606269 = validateParameter(valid_606269, JBool, required = false, default = nil)
  if valid_606269 != nil:
    section.add "OnlyAssociated", valid_606269
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606270 = header.getOrDefault("X-Amz-Signature")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Signature", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Content-Sha256", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Date")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Date", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Credential")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Credential", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Security-Token")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Security-Token", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Algorithm")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Algorithm", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-SignedHeaders", valid_606276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606277: Call_ListMembers_606264; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current Security Hub master account.
  ## 
  let valid = call_606277.validator(path, query, header, formData, body)
  let scheme = call_606277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606277.url(scheme.get, call_606277.host, call_606277.base,
                         call_606277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606277, url, valid)

proc call*(call_606278: Call_ListMembers_606264; MaxResults: int = 0;
          NextToken: string = ""; OnlyAssociated: bool = false): Recallable =
  ## listMembers
  ## Lists details about all member accounts for the current Security Hub master account.
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response. 
  ##   NextToken: string
  ##            : Paginates results. Set the value of this parameter to <code>NULL</code> on your first call to the <code>ListMembers</code> operation. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>nextToken</code> from the previous response to continue listing data. 
  ##   OnlyAssociated: bool
  ##                 : Specifies which member accounts the response includes based on their relationship status with the master account. The default value is <code>TRUE</code>. If <code>onlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>. If <code>onlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. 
  var query_606279 = newJObject()
  add(query_606279, "MaxResults", newJInt(MaxResults))
  add(query_606279, "NextToken", newJString(NextToken))
  add(query_606279, "OnlyAssociated", newJBool(OnlyAssociated))
  result = call_606278.call(nil, query_606279, nil, nil, nil)

var listMembers* = Call_ListMembers_606264(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/members",
                                        validator: validate_ListMembers_606265,
                                        base: "/", url: url_ListMembers_606266,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_606295 = ref object of OpenApiRestCall_605589
proc url_DeclineInvitations_606297(protocol: Scheme; host: string; base: string;
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

proc validate_DeclineInvitations_606296(path: JsonNode; query: JsonNode;
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
  var valid_606298 = header.getOrDefault("X-Amz-Signature")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Signature", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Content-Sha256", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Date")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Date", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Credential")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Credential", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Security-Token")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Security-Token", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Algorithm")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Algorithm", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-SignedHeaders", valid_606304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606306: Call_DeclineInvitations_606295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations to become a member account.
  ## 
  let valid = call_606306.validator(path, query, header, formData, body)
  let scheme = call_606306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606306.url(scheme.get, call_606306.host, call_606306.base,
                         call_606306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606306, url, valid)

proc call*(call_606307: Call_DeclineInvitations_606295; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations to become a member account.
  ##   body: JObject (required)
  var body_606308 = newJObject()
  if body != nil:
    body_606308 = body
  result = call_606307.call(nil, nil, nil, nil, body_606308)

var declineInvitations* = Call_DeclineInvitations_606295(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/invitations/decline",
    validator: validate_DeclineInvitations_606296, base: "/",
    url: url_DeclineInvitations_606297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateActionTarget_606337 = ref object of OpenApiRestCall_605589
proc url_UpdateActionTarget_606339(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateActionTarget_606338(path: JsonNode; query: JsonNode;
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
  var valid_606340 = path.getOrDefault("ActionTargetArn")
  valid_606340 = validateParameter(valid_606340, JString, required = true,
                                 default = nil)
  if valid_606340 != nil:
    section.add "ActionTargetArn", valid_606340
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
  var valid_606341 = header.getOrDefault("X-Amz-Signature")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Signature", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Content-Sha256", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Date")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Date", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Credential")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Credential", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Security-Token")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Security-Token", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Algorithm")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Algorithm", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-SignedHeaders", valid_606347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606349: Call_UpdateActionTarget_606337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name and description of a custom action target in Security Hub.
  ## 
  let valid = call_606349.validator(path, query, header, formData, body)
  let scheme = call_606349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606349.url(scheme.get, call_606349.host, call_606349.base,
                         call_606349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606349, url, valid)

proc call*(call_606350: Call_UpdateActionTarget_606337; ActionTargetArn: string;
          body: JsonNode): Recallable =
  ## updateActionTarget
  ## Updates the name and description of a custom action target in Security Hub.
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to update.
  ##   body: JObject (required)
  var path_606351 = newJObject()
  var body_606352 = newJObject()
  add(path_606351, "ActionTargetArn", newJString(ActionTargetArn))
  if body != nil:
    body_606352 = body
  result = call_606350.call(path_606351, nil, nil, nil, body_606352)

var updateActionTarget* = Call_UpdateActionTarget_606337(
    name: "updateActionTarget", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_UpdateActionTarget_606338, base: "/",
    url: url_UpdateActionTarget_606339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActionTarget_606309 = ref object of OpenApiRestCall_605589
proc url_DeleteActionTarget_606311(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteActionTarget_606310(path: JsonNode; query: JsonNode;
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
  var valid_606326 = path.getOrDefault("ActionTargetArn")
  valid_606326 = validateParameter(valid_606326, JString, required = true,
                                 default = nil)
  if valid_606326 != nil:
    section.add "ActionTargetArn", valid_606326
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
  var valid_606327 = header.getOrDefault("X-Amz-Signature")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Signature", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Content-Sha256", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Date")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Date", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Credential")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Credential", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Security-Token")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Security-Token", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Algorithm")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Algorithm", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-SignedHeaders", valid_606333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606334: Call_DeleteActionTarget_606309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a custom action target from Security Hub. Deleting a custom action target doesn't affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.
  ## 
  let valid = call_606334.validator(path, query, header, formData, body)
  let scheme = call_606334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606334.url(scheme.get, call_606334.host, call_606334.base,
                         call_606334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606334, url, valid)

proc call*(call_606335: Call_DeleteActionTarget_606309; ActionTargetArn: string): Recallable =
  ## deleteActionTarget
  ## Deletes a custom action target from Security Hub. Deleting a custom action target doesn't affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to delete.
  var path_606336 = newJObject()
  add(path_606336, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_606335.call(path_606336, nil, nil, nil, nil)

var deleteActionTarget* = Call_DeleteActionTarget_606309(
    name: "deleteActionTarget", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_DeleteActionTarget_606310, base: "/",
    url: url_DeleteActionTarget_606311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInsight_606367 = ref object of OpenApiRestCall_605589
proc url_UpdateInsight_606369(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateInsight_606368(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606370 = path.getOrDefault("InsightArn")
  valid_606370 = validateParameter(valid_606370, JString, required = true,
                                 default = nil)
  if valid_606370 != nil:
    section.add "InsightArn", valid_606370
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
  var valid_606371 = header.getOrDefault("X-Amz-Signature")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Signature", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Content-Sha256", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Date")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Date", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Credential")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Credential", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Security-Token")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Security-Token", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Algorithm")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Algorithm", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-SignedHeaders", valid_606377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606379: Call_UpdateInsight_606367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Security Hub insight that the insight ARN specifies.
  ## 
  let valid = call_606379.validator(path, query, header, formData, body)
  let scheme = call_606379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606379.url(scheme.get, call_606379.host, call_606379.base,
                         call_606379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606379, url, valid)

proc call*(call_606380: Call_UpdateInsight_606367; InsightArn: string; body: JsonNode): Recallable =
  ## updateInsight
  ## Updates the Security Hub insight that the insight ARN specifies.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight that you want to update.
  ##   body: JObject (required)
  var path_606381 = newJObject()
  var body_606382 = newJObject()
  add(path_606381, "InsightArn", newJString(InsightArn))
  if body != nil:
    body_606382 = body
  result = call_606380.call(path_606381, nil, nil, nil, body_606382)

var updateInsight* = Call_UpdateInsight_606367(name: "updateInsight",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_UpdateInsight_606368,
    base: "/", url: url_UpdateInsight_606369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInsight_606353 = ref object of OpenApiRestCall_605589
proc url_DeleteInsight_606355(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInsight_606354(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606356 = path.getOrDefault("InsightArn")
  valid_606356 = validateParameter(valid_606356, JString, required = true,
                                 default = nil)
  if valid_606356 != nil:
    section.add "InsightArn", valid_606356
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
  var valid_606357 = header.getOrDefault("X-Amz-Signature")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Signature", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Content-Sha256", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Date")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Date", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Credential")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Credential", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Security-Token")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Security-Token", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Algorithm")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Algorithm", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-SignedHeaders", valid_606363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606364: Call_DeleteInsight_606353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ## 
  let valid = call_606364.validator(path, query, header, formData, body)
  let scheme = call_606364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606364.url(scheme.get, call_606364.host, call_606364.base,
                         call_606364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606364, url, valid)

proc call*(call_606365: Call_DeleteInsight_606353; InsightArn: string): Recallable =
  ## deleteInsight
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight to delete.
  var path_606366 = newJObject()
  add(path_606366, "InsightArn", newJString(InsightArn))
  result = call_606365.call(path_606366, nil, nil, nil, nil)

var deleteInsight* = Call_DeleteInsight_606353(name: "deleteInsight",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_DeleteInsight_606354,
    base: "/", url: url_DeleteInsight_606355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_606383 = ref object of OpenApiRestCall_605589
proc url_DeleteInvitations_606385(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInvitations_606384(path: JsonNode; query: JsonNode;
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
  var valid_606386 = header.getOrDefault("X-Amz-Signature")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Signature", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Content-Sha256", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Date")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Date", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Credential")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Credential", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Security-Token")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Security-Token", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Algorithm")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Algorithm", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-SignedHeaders", valid_606392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606394: Call_DeleteInvitations_606383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations received by the AWS account to become a member account.
  ## 
  let valid = call_606394.validator(path, query, header, formData, body)
  let scheme = call_606394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606394.url(scheme.get, call_606394.host, call_606394.base,
                         call_606394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606394, url, valid)

proc call*(call_606395: Call_DeleteInvitations_606383; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations received by the AWS account to become a member account.
  ##   body: JObject (required)
  var body_606396 = newJObject()
  if body != nil:
    body_606396 = body
  result = call_606395.call(nil, nil, nil, nil, body_606396)

var deleteInvitations* = Call_DeleteInvitations_606383(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/invitations/delete", validator: validate_DeleteInvitations_606384,
    base: "/", url: url_DeleteInvitations_606385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_606397 = ref object of OpenApiRestCall_605589
proc url_DeleteMembers_606399(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMembers_606398(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606400 = header.getOrDefault("X-Amz-Signature")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Signature", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Content-Sha256", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Date")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Date", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Credential")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Credential", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Security-Token")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Security-Token", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Algorithm")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Algorithm", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-SignedHeaders", valid_606406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606408: Call_DeleteMembers_606397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified member accounts from Security Hub.
  ## 
  let valid = call_606408.validator(path, query, header, formData, body)
  let scheme = call_606408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606408.url(scheme.get, call_606408.host, call_606408.base,
                         call_606408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606408, url, valid)

proc call*(call_606409: Call_DeleteMembers_606397; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes the specified member accounts from Security Hub.
  ##   body: JObject (required)
  var body_606410 = newJObject()
  if body != nil:
    body_606410 = body
  result = call_606409.call(nil, nil, nil, nil, body_606410)

var deleteMembers* = Call_DeleteMembers_606397(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/delete", validator: validate_DeleteMembers_606398, base: "/",
    url: url_DeleteMembers_606399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActionTargets_606411 = ref object of OpenApiRestCall_605589
proc url_DescribeActionTargets_606413(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeActionTargets_606412(path: JsonNode; query: JsonNode;
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
  var valid_606414 = query.getOrDefault("MaxResults")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "MaxResults", valid_606414
  var valid_606415 = query.getOrDefault("NextToken")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "NextToken", valid_606415
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606416 = header.getOrDefault("X-Amz-Signature")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Signature", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Content-Sha256", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Date")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Date", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Credential")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Credential", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Security-Token")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Security-Token", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-Algorithm")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Algorithm", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-SignedHeaders", valid_606422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606424: Call_DescribeActionTargets_606411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the custom action targets in Security Hub in your account.
  ## 
  let valid = call_606424.validator(path, query, header, formData, body)
  let scheme = call_606424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606424.url(scheme.get, call_606424.host, call_606424.base,
                         call_606424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606424, url, valid)

proc call*(call_606425: Call_DescribeActionTargets_606411; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeActionTargets
  ## Returns a list of the custom action targets in Security Hub in your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606426 = newJObject()
  var body_606427 = newJObject()
  add(query_606426, "MaxResults", newJString(MaxResults))
  add(query_606426, "NextToken", newJString(NextToken))
  if body != nil:
    body_606427 = body
  result = call_606425.call(nil, query_606426, nil, nil, body_606427)

var describeActionTargets* = Call_DescribeActionTargets_606411(
    name: "describeActionTargets", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets/get",
    validator: validate_DescribeActionTargets_606412, base: "/",
    url: url_DescribeActionTargets_606413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSecurityHub_606442 = ref object of OpenApiRestCall_605589
proc url_EnableSecurityHub_606444(protocol: Scheme; host: string; base: string;
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

proc validate_EnableSecurityHub_606443(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. Enabling Security Hub also enables the CIS AWS Foundations standard. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
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
  var valid_606445 = header.getOrDefault("X-Amz-Signature")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Signature", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Content-Sha256", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Date")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Date", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Credential")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Credential", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Security-Token")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Security-Token", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Algorithm")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Algorithm", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-SignedHeaders", valid_606451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606453: Call_EnableSecurityHub_606442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. Enabling Security Hub also enables the CIS AWS Foundations standard. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
  ## 
  let valid = call_606453.validator(path, query, header, formData, body)
  let scheme = call_606453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606453.url(scheme.get, call_606453.host, call_606453.base,
                         call_606453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606453, url, valid)

proc call*(call_606454: Call_EnableSecurityHub_606442; body: JsonNode): Recallable =
  ## enableSecurityHub
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. Enabling Security Hub also enables the CIS AWS Foundations standard. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_606455 = newJObject()
  if body != nil:
    body_606455 = body
  result = call_606454.call(nil, nil, nil, nil, body_606455)

var enableSecurityHub* = Call_EnableSecurityHub_606442(name: "enableSecurityHub",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/accounts", validator: validate_EnableSecurityHub_606443, base: "/",
    url: url_EnableSecurityHub_606444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHub_606428 = ref object of OpenApiRestCall_605589
proc url_DescribeHub_606430(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeHub_606429(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606431 = query.getOrDefault("HubArn")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "HubArn", valid_606431
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606432 = header.getOrDefault("X-Amz-Signature")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Signature", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Content-Sha256", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Date")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Date", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Credential")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Credential", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-Security-Token")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Security-Token", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Algorithm")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Algorithm", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-SignedHeaders", valid_606438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606439: Call_DescribeHub_606428; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ## 
  let valid = call_606439.validator(path, query, header, formData, body)
  let scheme = call_606439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606439.url(scheme.get, call_606439.host, call_606439.base,
                         call_606439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606439, url, valid)

proc call*(call_606440: Call_DescribeHub_606428; HubArn: string = ""): Recallable =
  ## describeHub
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ##   HubArn: string
  ##         : The ARN of the Hub resource to retrieve.
  var query_606441 = newJObject()
  add(query_606441, "HubArn", newJString(HubArn))
  result = call_606440.call(nil, query_606441, nil, nil, nil)

var describeHub* = Call_DescribeHub_606428(name: "describeHub",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/accounts",
                                        validator: validate_DescribeHub_606429,
                                        base: "/", url: url_DescribeHub_606430,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSecurityHub_606456 = ref object of OpenApiRestCall_605589
proc url_DisableSecurityHub_606458(protocol: Scheme; host: string; base: string;
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

proc validate_DisableSecurityHub_606457(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606459 = header.getOrDefault("X-Amz-Signature")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Signature", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Content-Sha256", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Date")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Date", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Credential")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Credential", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Security-Token")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Security-Token", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Algorithm")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Algorithm", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-SignedHeaders", valid_606465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606466: Call_DisableSecurityHub_606456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub. When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and can't be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed. If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  ## 
  let valid = call_606466.validator(path, query, header, formData, body)
  let scheme = call_606466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606466.url(scheme.get, call_606466.host, call_606466.base,
                         call_606466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606466, url, valid)

proc call*(call_606467: Call_DisableSecurityHub_606456): Recallable =
  ## disableSecurityHub
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub. When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and can't be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed. If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  result = call_606467.call(nil, nil, nil, nil, nil)

var disableSecurityHub* = Call_DisableSecurityHub_606456(
    name: "disableSecurityHub", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/accounts",
    validator: validate_DisableSecurityHub_606457, base: "/",
    url: url_DisableSecurityHub_606458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProducts_606468 = ref object of OpenApiRestCall_605589
proc url_DescribeProducts_606470(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeProducts_606469(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
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
  var valid_606471 = query.getOrDefault("MaxResults")
  valid_606471 = validateParameter(valid_606471, JInt, required = false, default = nil)
  if valid_606471 != nil:
    section.add "MaxResults", valid_606471
  var valid_606472 = query.getOrDefault("NextToken")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "NextToken", valid_606472
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606473 = header.getOrDefault("X-Amz-Signature")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Signature", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Content-Sha256", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Date")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Date", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Credential")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Credential", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Security-Token")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Security-Token", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Algorithm")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Algorithm", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-SignedHeaders", valid_606479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606480: Call_DescribeProducts_606468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
  ## 
  let valid = call_606480.validator(path, query, header, formData, body)
  let scheme = call_606480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606480.url(scheme.get, call_606480.host, call_606480.base,
                         call_606480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606480, url, valid)

proc call*(call_606481: Call_DescribeProducts_606468; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## describeProducts
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
  ##   MaxResults: int
  ##             : The maximum number of results to return.
  ##   NextToken: string
  ##            : The token that is required for pagination.
  var query_606482 = newJObject()
  add(query_606482, "MaxResults", newJInt(MaxResults))
  add(query_606482, "NextToken", newJString(NextToken))
  result = call_606481.call(nil, query_606482, nil, nil, nil)

var describeProducts* = Call_DescribeProducts_606468(name: "describeProducts",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/products",
    validator: validate_DescribeProducts_606469, base: "/",
    url: url_DescribeProducts_606470, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableImportFindingsForProduct_606483 = ref object of OpenApiRestCall_605589
proc url_DisableImportFindingsForProduct_606485(protocol: Scheme; host: string;
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

proc validate_DisableImportFindingsForProduct_606484(path: JsonNode;
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
  var valid_606486 = path.getOrDefault("ProductSubscriptionArn")
  valid_606486 = validateParameter(valid_606486, JString, required = true,
                                 default = nil)
  if valid_606486 != nil:
    section.add "ProductSubscriptionArn", valid_606486
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
  var valid_606487 = header.getOrDefault("X-Amz-Signature")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Signature", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Content-Sha256", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Date")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Date", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Credential")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Credential", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Security-Token")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Security-Token", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Algorithm")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Algorithm", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-SignedHeaders", valid_606493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606494: Call_DisableImportFindingsForProduct_606483;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disables the integration of the specified product with Security Hub. Findings from that product are no longer sent to Security Hub after the integration is disabled.
  ## 
  let valid = call_606494.validator(path, query, header, formData, body)
  let scheme = call_606494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606494.url(scheme.get, call_606494.host, call_606494.base,
                         call_606494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606494, url, valid)

proc call*(call_606495: Call_DisableImportFindingsForProduct_606483;
          ProductSubscriptionArn: string): Recallable =
  ## disableImportFindingsForProduct
  ## Disables the integration of the specified product with Security Hub. Findings from that product are no longer sent to Security Hub after the integration is disabled.
  ##   ProductSubscriptionArn: string (required)
  ##                         : The ARN of the integrated product to disable the integration for.
  var path_606496 = newJObject()
  add(path_606496, "ProductSubscriptionArn", newJString(ProductSubscriptionArn))
  result = call_606495.call(path_606496, nil, nil, nil, nil)

var disableImportFindingsForProduct* = Call_DisableImportFindingsForProduct_606483(
    name: "disableImportFindingsForProduct", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com",
    route: "/productSubscriptions/{ProductSubscriptionArn}",
    validator: validate_DisableImportFindingsForProduct_606484, base: "/",
    url: url_DisableImportFindingsForProduct_606485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_606497 = ref object of OpenApiRestCall_605589
proc url_DisassociateFromMasterAccount_606499(protocol: Scheme; host: string;
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

proc validate_DisassociateFromMasterAccount_606498(path: JsonNode; query: JsonNode;
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

proc call*(call_606507: Call_DisassociateFromMasterAccount_606497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current Security Hub member account from the associated master account.
  ## 
  let valid = call_606507.validator(path, query, header, formData, body)
  let scheme = call_606507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606507.url(scheme.get, call_606507.host, call_606507.base,
                         call_606507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606507, url, valid)

proc call*(call_606508: Call_DisassociateFromMasterAccount_606497): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current Security Hub member account from the associated master account.
  result = call_606508.call(nil, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_606497(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_606498, base: "/",
    url: url_DisassociateFromMasterAccount_606499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_606509 = ref object of OpenApiRestCall_605589
proc url_DisassociateMembers_606511(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateMembers_606510(path: JsonNode; query: JsonNode;
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
  var valid_606512 = header.getOrDefault("X-Amz-Signature")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-Signature", valid_606512
  var valid_606513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Content-Sha256", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Date")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Date", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Credential")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Credential", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Security-Token")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Security-Token", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Algorithm")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Algorithm", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-SignedHeaders", valid_606518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606520: Call_DisassociateMembers_606509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified member accounts from the associated master account.
  ## 
  let valid = call_606520.validator(path, query, header, formData, body)
  let scheme = call_606520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606520.url(scheme.get, call_606520.host, call_606520.base,
                         call_606520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606520, url, valid)

proc call*(call_606521: Call_DisassociateMembers_606509; body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates the specified member accounts from the associated master account.
  ##   body: JObject (required)
  var body_606522 = newJObject()
  if body != nil:
    body_606522 = body
  result = call_606521.call(nil, nil, nil, nil, body_606522)

var disassociateMembers* = Call_DisassociateMembers_606509(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/members/disassociate",
    validator: validate_DisassociateMembers_606510, base: "/",
    url: url_DisassociateMembers_606511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableImportFindingsForProduct_606538 = ref object of OpenApiRestCall_605589
proc url_EnableImportFindingsForProduct_606540(protocol: Scheme; host: string;
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

proc validate_EnableImportFindingsForProduct_606539(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606541 = header.getOrDefault("X-Amz-Signature")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-Signature", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Content-Sha256", valid_606542
  var valid_606543 = header.getOrDefault("X-Amz-Date")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-Date", valid_606543
  var valid_606544 = header.getOrDefault("X-Amz-Credential")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Credential", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Security-Token")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Security-Token", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Algorithm")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Algorithm", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-SignedHeaders", valid_606547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606549: Call_EnableImportFindingsForProduct_606538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub. When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.
  ## 
  let valid = call_606549.validator(path, query, header, formData, body)
  let scheme = call_606549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606549.url(scheme.get, call_606549.host, call_606549.base,
                         call_606549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606549, url, valid)

proc call*(call_606550: Call_EnableImportFindingsForProduct_606538; body: JsonNode): Recallable =
  ## enableImportFindingsForProduct
  ## Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub. When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.
  ##   body: JObject (required)
  var body_606551 = newJObject()
  if body != nil:
    body_606551 = body
  result = call_606550.call(nil, nil, nil, nil, body_606551)

var enableImportFindingsForProduct* = Call_EnableImportFindingsForProduct_606538(
    name: "enableImportFindingsForProduct", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_EnableImportFindingsForProduct_606539, base: "/",
    url: url_EnableImportFindingsForProduct_606540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnabledProductsForImport_606523 = ref object of OpenApiRestCall_605589
proc url_ListEnabledProductsForImport_606525(protocol: Scheme; host: string;
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

proc validate_ListEnabledProductsForImport_606524(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum number of items that you want in the response.
  ##   NextToken: JString
  ##            : Paginates results. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data.
  section = newJObject()
  var valid_606526 = query.getOrDefault("MaxResults")
  valid_606526 = validateParameter(valid_606526, JInt, required = false, default = nil)
  if valid_606526 != nil:
    section.add "MaxResults", valid_606526
  var valid_606527 = query.getOrDefault("NextToken")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "NextToken", valid_606527
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606528 = header.getOrDefault("X-Amz-Signature")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-Signature", valid_606528
  var valid_606529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Content-Sha256", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Date")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Date", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Credential")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Credential", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Security-Token")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Security-Token", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Algorithm")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Algorithm", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-SignedHeaders", valid_606534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606535: Call_ListEnabledProductsForImport_606523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ## 
  let valid = call_606535.validator(path, query, header, formData, body)
  let scheme = call_606535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606535.url(scheme.get, call_606535.host, call_606535.base,
                         call_606535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606535, url, valid)

proc call*(call_606536: Call_ListEnabledProductsForImport_606523;
          MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## listEnabledProductsForImport
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response.
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data.
  var query_606537 = newJObject()
  add(query_606537, "MaxResults", newJInt(MaxResults))
  add(query_606537, "NextToken", newJString(NextToken))
  result = call_606536.call(nil, query_606537, nil, nil, nil)

var listEnabledProductsForImport* = Call_ListEnabledProductsForImport_606523(
    name: "listEnabledProductsForImport", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_ListEnabledProductsForImport_606524, base: "/",
    url: url_ListEnabledProductsForImport_606525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnabledStandards_606552 = ref object of OpenApiRestCall_605589
proc url_GetEnabledStandards_606554(protocol: Scheme; host: string; base: string;
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

proc validate_GetEnabledStandards_606553(path: JsonNode; query: JsonNode;
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
  var valid_606555 = header.getOrDefault("X-Amz-Signature")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Signature", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Content-Sha256", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-Date")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Date", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Credential")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Credential", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Security-Token")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Security-Token", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Algorithm")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Algorithm", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-SignedHeaders", valid_606561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606563: Call_GetEnabledStandards_606552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the standards that are currently enabled.
  ## 
  let valid = call_606563.validator(path, query, header, formData, body)
  let scheme = call_606563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606563.url(scheme.get, call_606563.host, call_606563.base,
                         call_606563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606563, url, valid)

proc call*(call_606564: Call_GetEnabledStandards_606552; body: JsonNode): Recallable =
  ## getEnabledStandards
  ## Returns a list of the standards that are currently enabled.
  ##   body: JObject (required)
  var body_606565 = newJObject()
  if body != nil:
    body_606565 = body
  result = call_606564.call(nil, nil, nil, nil, body_606565)

var getEnabledStandards* = Call_GetEnabledStandards_606552(
    name: "getEnabledStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/get",
    validator: validate_GetEnabledStandards_606553, base: "/",
    url: url_GetEnabledStandards_606554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_606566 = ref object of OpenApiRestCall_605589
proc url_GetFindings_606568(protocol: Scheme; host: string; base: string;
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

proc validate_GetFindings_606567(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606569 = query.getOrDefault("MaxResults")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "MaxResults", valid_606569
  var valid_606570 = query.getOrDefault("NextToken")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "NextToken", valid_606570
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606571 = header.getOrDefault("X-Amz-Signature")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Signature", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Content-Sha256", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-Date")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Date", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Credential")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Credential", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Security-Token")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Security-Token", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Algorithm")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Algorithm", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-SignedHeaders", valid_606577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606579: Call_GetFindings_606566; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of findings that match the specified criteria.
  ## 
  let valid = call_606579.validator(path, query, header, formData, body)
  let scheme = call_606579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606579.url(scheme.get, call_606579.host, call_606579.base,
                         call_606579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606579, url, valid)

proc call*(call_606580: Call_GetFindings_606566; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getFindings
  ## Returns a list of findings that match the specified criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606581 = newJObject()
  var body_606582 = newJObject()
  add(query_606581, "MaxResults", newJString(MaxResults))
  add(query_606581, "NextToken", newJString(NextToken))
  if body != nil:
    body_606582 = body
  result = call_606580.call(nil, query_606581, nil, nil, body_606582)

var getFindings* = Call_GetFindings_606566(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/findings",
                                        validator: validate_GetFindings_606567,
                                        base: "/", url: url_GetFindings_606568,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_606583 = ref object of OpenApiRestCall_605589
proc url_UpdateFindings_606585(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFindings_606584(path: JsonNode; query: JsonNode;
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
  var valid_606586 = header.getOrDefault("X-Amz-Signature")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Signature", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Content-Sha256", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-Date")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Date", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-Credential")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Credential", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Security-Token")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Security-Token", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Algorithm")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Algorithm", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-SignedHeaders", valid_606592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606594: Call_UpdateFindings_606583; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ## 
  let valid = call_606594.validator(path, query, header, formData, body)
  let scheme = call_606594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606594.url(scheme.get, call_606594.host, call_606594.base,
                         call_606594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606594, url, valid)

proc call*(call_606595: Call_UpdateFindings_606583; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ##   body: JObject (required)
  var body_606596 = newJObject()
  if body != nil:
    body_606596 = body
  result = call_606595.call(nil, nil, nil, nil, body_606596)

var updateFindings* = Call_UpdateFindings_606583(name: "updateFindings",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/findings", validator: validate_UpdateFindings_606584, base: "/",
    url: url_UpdateFindings_606585, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsightResults_606597 = ref object of OpenApiRestCall_605589
proc url_GetInsightResults_606599(protocol: Scheme; host: string; base: string;
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

proc validate_GetInsightResults_606598(path: JsonNode; query: JsonNode;
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
  var valid_606600 = path.getOrDefault("InsightArn")
  valid_606600 = validateParameter(valid_606600, JString, required = true,
                                 default = nil)
  if valid_606600 != nil:
    section.add "InsightArn", valid_606600
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
  var valid_606601 = header.getOrDefault("X-Amz-Signature")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Signature", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Content-Sha256", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Date")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Date", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-Credential")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-Credential", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Security-Token")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Security-Token", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Algorithm")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Algorithm", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-SignedHeaders", valid_606607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606608: Call_GetInsightResults_606597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the results of the Security Hub insight that the insight ARN specifies.
  ## 
  let valid = call_606608.validator(path, query, header, formData, body)
  let scheme = call_606608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606608.url(scheme.get, call_606608.host, call_606608.base,
                         call_606608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606608, url, valid)

proc call*(call_606609: Call_GetInsightResults_606597; InsightArn: string): Recallable =
  ## getInsightResults
  ## Lists the results of the Security Hub insight that the insight ARN specifies.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight whose results you want to see.
  var path_606610 = newJObject()
  add(path_606610, "InsightArn", newJString(InsightArn))
  result = call_606609.call(path_606610, nil, nil, nil, nil)

var getInsightResults* = Call_GetInsightResults_606597(name: "getInsightResults",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/insights/results/{InsightArn}",
    validator: validate_GetInsightResults_606598, base: "/",
    url: url_GetInsightResults_606599, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsights_606611 = ref object of OpenApiRestCall_605589
proc url_GetInsights_606613(protocol: Scheme; host: string; base: string;
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

proc validate_GetInsights_606612(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists and describes insights that insight ARNs specify.
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
  var valid_606614 = query.getOrDefault("MaxResults")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "MaxResults", valid_606614
  var valid_606615 = query.getOrDefault("NextToken")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "NextToken", valid_606615
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606616 = header.getOrDefault("X-Amz-Signature")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Signature", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Content-Sha256", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-Date")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Date", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-Credential")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Credential", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Security-Token")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Security-Token", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Algorithm")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Algorithm", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-SignedHeaders", valid_606622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606624: Call_GetInsights_606611; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists and describes insights that insight ARNs specify.
  ## 
  let valid = call_606624.validator(path, query, header, formData, body)
  let scheme = call_606624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606624.url(scheme.get, call_606624.host, call_606624.base,
                         call_606624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606624, url, valid)

proc call*(call_606625: Call_GetInsights_606611; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getInsights
  ## Lists and describes insights that insight ARNs specify.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606626 = newJObject()
  var body_606627 = newJObject()
  add(query_606626, "MaxResults", newJString(MaxResults))
  add(query_606626, "NextToken", newJString(NextToken))
  if body != nil:
    body_606627 = body
  result = call_606625.call(nil, query_606626, nil, nil, body_606627)

var getInsights* = Call_GetInsights_606611(name: "getInsights",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/insights/get",
                                        validator: validate_GetInsights_606612,
                                        base: "/", url: url_GetInsights_606613,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_606628 = ref object of OpenApiRestCall_605589
proc url_GetInvitationsCount_606630(protocol: Scheme; host: string; base: string;
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

proc validate_GetInvitationsCount_606629(path: JsonNode; query: JsonNode;
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
  var valid_606631 = header.getOrDefault("X-Amz-Signature")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-Signature", valid_606631
  var valid_606632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-Content-Sha256", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-Date")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-Date", valid_606633
  var valid_606634 = header.getOrDefault("X-Amz-Credential")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "X-Amz-Credential", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Security-Token")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Security-Token", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Algorithm")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Algorithm", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-SignedHeaders", valid_606637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606638: Call_GetInvitationsCount_606628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  ## 
  let valid = call_606638.validator(path, query, header, formData, body)
  let scheme = call_606638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606638.url(scheme.get, call_606638.host, call_606638.base,
                         call_606638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606638, url, valid)

proc call*(call_606639: Call_GetInvitationsCount_606628): Recallable =
  ## getInvitationsCount
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  result = call_606639.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_606628(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/invitations/count",
    validator: validate_GetInvitationsCount_606629, base: "/",
    url: url_GetInvitationsCount_606630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_606640 = ref object of OpenApiRestCall_605589
proc url_GetMembers_606642(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetMembers_606641(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606643 = header.getOrDefault("X-Amz-Signature")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Signature", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Content-Sha256", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-Date")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Date", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-Credential")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-Credential", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-Security-Token")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Security-Token", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-Algorithm")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-Algorithm", valid_606648
  var valid_606649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "X-Amz-SignedHeaders", valid_606649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606651: Call_GetMembers_606640; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details on the Security Hub member accounts that the account IDs specify.
  ## 
  let valid = call_606651.validator(path, query, header, formData, body)
  let scheme = call_606651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606651.url(scheme.get, call_606651.host, call_606651.base,
                         call_606651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606651, url, valid)

proc call*(call_606652: Call_GetMembers_606640; body: JsonNode): Recallable =
  ## getMembers
  ## Returns the details on the Security Hub member accounts that the account IDs specify.
  ##   body: JObject (required)
  var body_606653 = newJObject()
  if body != nil:
    body_606653 = body
  result = call_606652.call(nil, nil, nil, nil, body_606653)

var getMembers* = Call_GetMembers_606640(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "securityhub.amazonaws.com",
                                      route: "/members/get",
                                      validator: validate_GetMembers_606641,
                                      base: "/", url: url_GetMembers_606642,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_606654 = ref object of OpenApiRestCall_605589
proc url_InviteMembers_606656(protocol: Scheme; host: string; base: string;
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

proc validate_InviteMembers_606655(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606657 = header.getOrDefault("X-Amz-Signature")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Signature", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Content-Sha256", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Date")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Date", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-Credential")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Credential", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-Security-Token")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-Security-Token", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-Algorithm")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-Algorithm", valid_606662
  var valid_606663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-SignedHeaders", valid_606663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606665: Call_InviteMembers_606654; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from. Before you can use this action to invite a member, you must first create the member account in Security Hub by using the <a>CreateMembers</a> action. When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from member account.
  ## 
  let valid = call_606665.validator(path, query, header, formData, body)
  let scheme = call_606665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606665.url(scheme.get, call_606665.host, call_606665.base,
                         call_606665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606665, url, valid)

proc call*(call_606666: Call_InviteMembers_606654; body: JsonNode): Recallable =
  ## inviteMembers
  ## Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from. Before you can use this action to invite a member, you must first create the member account in Security Hub by using the <a>CreateMembers</a> action. When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from member account.
  ##   body: JObject (required)
  var body_606667 = newJObject()
  if body != nil:
    body_606667 = body
  result = call_606666.call(nil, nil, nil, nil, body_606667)

var inviteMembers* = Call_InviteMembers_606654(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/invite", validator: validate_InviteMembers_606655, base: "/",
    url: url_InviteMembers_606656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_606668 = ref object of OpenApiRestCall_605589
proc url_ListInvitations_606670(protocol: Scheme; host: string; base: string;
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

proc validate_ListInvitations_606669(path: JsonNode; query: JsonNode;
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
  ##             : The maximum number of items that you want in the response. 
  ##   NextToken: JString
  ##            : Paginates results. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data. 
  section = newJObject()
  var valid_606671 = query.getOrDefault("MaxResults")
  valid_606671 = validateParameter(valid_606671, JInt, required = false, default = nil)
  if valid_606671 != nil:
    section.add "MaxResults", valid_606671
  var valid_606672 = query.getOrDefault("NextToken")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "NextToken", valid_606672
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606673 = header.getOrDefault("X-Amz-Signature")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Signature", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Content-Sha256", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Date")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Date", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Credential")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Credential", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-Security-Token")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Security-Token", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-Algorithm")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-Algorithm", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-SignedHeaders", valid_606679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606680: Call_ListInvitations_606668; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ## 
  let valid = call_606680.validator(path, query, header, formData, body)
  let scheme = call_606680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606680.url(scheme.get, call_606680.host, call_606680.base,
                         call_606680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606680, url, valid)

proc call*(call_606681: Call_ListInvitations_606668; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## listInvitations
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response. 
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data. 
  var query_606682 = newJObject()
  add(query_606682, "MaxResults", newJInt(MaxResults))
  add(query_606682, "NextToken", newJString(NextToken))
  result = call_606681.call(nil, query_606682, nil, nil, nil)

var listInvitations* = Call_ListInvitations_606668(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_606669, base: "/",
    url: url_ListInvitations_606670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606697 = ref object of OpenApiRestCall_605589
proc url_TagResource_606699(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606698(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606700 = path.getOrDefault("ResourceArn")
  valid_606700 = validateParameter(valid_606700, JString, required = true,
                                 default = nil)
  if valid_606700 != nil:
    section.add "ResourceArn", valid_606700
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

proc call*(call_606709: Call_TagResource_606697; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a resource.
  ## 
  let valid = call_606709.validator(path, query, header, formData, body)
  let scheme = call_606709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606709.url(scheme.get, call_606709.host, call_606709.base,
                         call_606709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606709, url, valid)

proc call*(call_606710: Call_TagResource_606697; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to apply the tags to.
  ##   body: JObject (required)
  var path_606711 = newJObject()
  var body_606712 = newJObject()
  add(path_606711, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_606712 = body
  result = call_606710.call(path_606711, nil, nil, nil, body_606712)

var tagResource* = Call_TagResource_606697(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_606698,
                                        base: "/", url: url_TagResource_606699,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606683 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606685(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606684(path: JsonNode; query: JsonNode;
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
  var valid_606686 = path.getOrDefault("ResourceArn")
  valid_606686 = validateParameter(valid_606686, JString, required = true,
                                 default = nil)
  if valid_606686 != nil:
    section.add "ResourceArn", valid_606686
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
  var valid_606687 = header.getOrDefault("X-Amz-Signature")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Signature", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Content-Sha256", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Date")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Date", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Credential")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Credential", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Security-Token")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Security-Token", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-Algorithm")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-Algorithm", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-SignedHeaders", valid_606693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606694: Call_ListTagsForResource_606683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags associated with a resource.
  ## 
  let valid = call_606694.validator(path, query, header, formData, body)
  let scheme = call_606694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606694.url(scheme.get, call_606694.host, call_606694.base,
                         call_606694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606694, url, valid)

proc call*(call_606695: Call_ListTagsForResource_606683; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags associated with a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to retrieve tags for.
  var path_606696 = newJObject()
  add(path_606696, "ResourceArn", newJString(ResourceArn))
  result = call_606695.call(path_606696, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606683(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_606684, base: "/",
    url: url_ListTagsForResource_606685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606713 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606715(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606714(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606716 = path.getOrDefault("ResourceArn")
  valid_606716 = validateParameter(valid_606716, JString, required = true,
                                 default = nil)
  if valid_606716 != nil:
    section.add "ResourceArn", valid_606716
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606717 = query.getOrDefault("tagKeys")
  valid_606717 = validateParameter(valid_606717, JArray, required = true, default = nil)
  if valid_606717 != nil:
    section.add "tagKeys", valid_606717
  result.add "query", section
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

proc call*(call_606725: Call_UntagResource_606713; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a resource.
  ## 
  let valid = call_606725.validator(path, query, header, formData, body)
  let scheme = call_606725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606725.url(scheme.get, call_606725.host, call_606725.base,
                         call_606725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606725, url, valid)

proc call*(call_606726: Call_UntagResource_606713; ResourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to remove the tags from.
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  var path_606727 = newJObject()
  var query_606728 = newJObject()
  add(path_606727, "ResourceArn", newJString(ResourceArn))
  if tagKeys != nil:
    query_606728.add "tagKeys", tagKeys
  result = call_606726.call(path_606727, query_606728, nil, nil, nil)

var untagResource* = Call_UntagResource_606713(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_606714,
    base: "/", url: url_UntagResource_606715, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
