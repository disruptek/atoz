
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
  Call_AcceptInvitation_599957 = ref object of OpenApiRestCall_599368
proc url_AcceptInvitation_599959(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AcceptInvitation_599958(path: JsonNode; query: JsonNode;
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
  var valid_599960 = header.getOrDefault("X-Amz-Date")
  valid_599960 = validateParameter(valid_599960, JString, required = false,
                                 default = nil)
  if valid_599960 != nil:
    section.add "X-Amz-Date", valid_599960
  var valid_599961 = header.getOrDefault("X-Amz-Security-Token")
  valid_599961 = validateParameter(valid_599961, JString, required = false,
                                 default = nil)
  if valid_599961 != nil:
    section.add "X-Amz-Security-Token", valid_599961
  var valid_599962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599962 = validateParameter(valid_599962, JString, required = false,
                                 default = nil)
  if valid_599962 != nil:
    section.add "X-Amz-Content-Sha256", valid_599962
  var valid_599963 = header.getOrDefault("X-Amz-Algorithm")
  valid_599963 = validateParameter(valid_599963, JString, required = false,
                                 default = nil)
  if valid_599963 != nil:
    section.add "X-Amz-Algorithm", valid_599963
  var valid_599964 = header.getOrDefault("X-Amz-Signature")
  valid_599964 = validateParameter(valid_599964, JString, required = false,
                                 default = nil)
  if valid_599964 != nil:
    section.add "X-Amz-Signature", valid_599964
  var valid_599965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599965 = validateParameter(valid_599965, JString, required = false,
                                 default = nil)
  if valid_599965 != nil:
    section.add "X-Amz-SignedHeaders", valid_599965
  var valid_599966 = header.getOrDefault("X-Amz-Credential")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Credential", valid_599966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599968: Call_AcceptInvitation_599957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from. When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.
  ## 
  let valid = call_599968.validator(path, query, header, formData, body)
  let scheme = call_599968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599968.url(scheme.get, call_599968.host, call_599968.base,
                         call_599968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599968, url, valid)

proc call*(call_599969: Call_AcceptInvitation_599957; body: JsonNode): Recallable =
  ## acceptInvitation
  ## Accepts the invitation to be a member account and be monitored by the Security Hub master account that the invitation was sent from. When the member account accepts the invitation, permission is granted to the master account to view findings generated in the member account.
  ##   body: JObject (required)
  var body_599970 = newJObject()
  if body != nil:
    body_599970 = body
  result = call_599969.call(nil, nil, nil, nil, body_599970)

var acceptInvitation* = Call_AcceptInvitation_599957(name: "acceptInvitation",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_AcceptInvitation_599958, base: "/",
    url: url_AcceptInvitation_599959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMasterAccount_599705 = ref object of OpenApiRestCall_599368
proc url_GetMasterAccount_599707(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMasterAccount_599706(path: JsonNode; query: JsonNode;
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
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  var valid_599821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Content-Sha256", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Algorithm")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Algorithm", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Signature")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Signature", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-SignedHeaders", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Credential")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Credential", valid_599825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599848: Call_GetMasterAccount_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details for the Security Hub master account to the current member account. 
  ## 
  let valid = call_599848.validator(path, query, header, formData, body)
  let scheme = call_599848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599848.url(scheme.get, call_599848.host, call_599848.base,
                         call_599848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599848, url, valid)

proc call*(call_599919: Call_GetMasterAccount_599705): Recallable =
  ## getMasterAccount
  ## Provides the details for the Security Hub master account to the current member account. 
  result = call_599919.call(nil, nil, nil, nil, nil)

var getMasterAccount* = Call_GetMasterAccount_599705(name: "getMasterAccount",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/master",
    validator: validate_GetMasterAccount_599706, base: "/",
    url: url_GetMasterAccount_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisableStandards_599972 = ref object of OpenApiRestCall_599368
proc url_BatchDisableStandards_599974(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDisableStandards_599973(path: JsonNode; query: JsonNode;
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
  var valid_599975 = header.getOrDefault("X-Amz-Date")
  valid_599975 = validateParameter(valid_599975, JString, required = false,
                                 default = nil)
  if valid_599975 != nil:
    section.add "X-Amz-Date", valid_599975
  var valid_599976 = header.getOrDefault("X-Amz-Security-Token")
  valid_599976 = validateParameter(valid_599976, JString, required = false,
                                 default = nil)
  if valid_599976 != nil:
    section.add "X-Amz-Security-Token", valid_599976
  var valid_599977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Content-Sha256", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Algorithm")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Algorithm", valid_599978
  var valid_599979 = header.getOrDefault("X-Amz-Signature")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Signature", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-SignedHeaders", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Credential")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Credential", valid_599981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599983: Call_BatchDisableStandards_599972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ## 
  let valid = call_599983.validator(path, query, header, formData, body)
  let scheme = call_599983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599983.url(scheme.get, call_599983.host, call_599983.base,
                         call_599983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599983, url, valid)

proc call*(call_599984: Call_BatchDisableStandards_599972; body: JsonNode): Recallable =
  ## batchDisableStandards
  ## Disables the standards specified by the provided <code>StandardsSubscriptionArns</code>. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_599985 = newJObject()
  if body != nil:
    body_599985 = body
  result = call_599984.call(nil, nil, nil, nil, body_599985)

var batchDisableStandards* = Call_BatchDisableStandards_599972(
    name: "batchDisableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/deregister",
    validator: validate_BatchDisableStandards_599973, base: "/",
    url: url_BatchDisableStandards_599974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchEnableStandards_599986 = ref object of OpenApiRestCall_599368
proc url_BatchEnableStandards_599988(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchEnableStandards_599987(path: JsonNode; query: JsonNode;
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
  var valid_599989 = header.getOrDefault("X-Amz-Date")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Date", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Security-Token")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Security-Token", valid_599990
  var valid_599991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-Content-Sha256", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-Algorithm")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Algorithm", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Signature")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Signature", valid_599993
  var valid_599994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599994 = validateParameter(valid_599994, JString, required = false,
                                 default = nil)
  if valid_599994 != nil:
    section.add "X-Amz-SignedHeaders", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Credential")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Credential", valid_599995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599997: Call_BatchEnableStandards_599986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the standards specified by the provided <code>standardsArn</code>. In this release, only CIS AWS Foundations standards are supported. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ## 
  let valid = call_599997.validator(path, query, header, formData, body)
  let scheme = call_599997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599997.url(scheme.get, call_599997.host, call_599997.base,
                         call_599997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599997, url, valid)

proc call*(call_599998: Call_BatchEnableStandards_599986; body: JsonNode): Recallable =
  ## batchEnableStandards
  ## Enables the standards specified by the provided <code>standardsArn</code>. In this release, only CIS AWS Foundations standards are supported. For more information, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html">Standards Supported in AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_599999 = newJObject()
  if body != nil:
    body_599999 = body
  result = call_599998.call(nil, nil, nil, nil, body_599999)

var batchEnableStandards* = Call_BatchEnableStandards_599986(
    name: "batchEnableStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/register",
    validator: validate_BatchEnableStandards_599987, base: "/",
    url: url_BatchEnableStandards_599988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchImportFindings_600000 = ref object of OpenApiRestCall_599368
proc url_BatchImportFindings_600002(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchImportFindings_600001(path: JsonNode; query: JsonNode;
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
  var valid_600003 = header.getOrDefault("X-Amz-Date")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Date", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Security-Token")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Security-Token", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Content-Sha256", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Algorithm")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Algorithm", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Signature")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Signature", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-SignedHeaders", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Credential")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Credential", valid_600009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600011: Call_BatchImportFindings_600000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub. The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.
  ## 
  let valid = call_600011.validator(path, query, header, formData, body)
  let scheme = call_600011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600011.url(scheme.get, call_600011.host, call_600011.base,
                         call_600011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600011, url, valid)

proc call*(call_600012: Call_BatchImportFindings_600000; body: JsonNode): Recallable =
  ## batchImportFindings
  ## Imports security findings generated from an integrated third-party product into Security Hub. This action is requested by the integrated product to import its findings into Security Hub. The maximum allowed size for a finding is 240 Kb. An error is returned for any finding larger than 240 Kb.
  ##   body: JObject (required)
  var body_600013 = newJObject()
  if body != nil:
    body_600013 = body
  result = call_600012.call(nil, nil, nil, nil, body_600013)

var batchImportFindings* = Call_BatchImportFindings_600000(
    name: "batchImportFindings", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/findings/import",
    validator: validate_BatchImportFindings_600001, base: "/",
    url: url_BatchImportFindings_600002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActionTarget_600014 = ref object of OpenApiRestCall_599368
proc url_CreateActionTarget_600016(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateActionTarget_600015(path: JsonNode; query: JsonNode;
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
  var valid_600017 = header.getOrDefault("X-Amz-Date")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Date", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Security-Token")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Security-Token", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Content-Sha256", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Algorithm")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Algorithm", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Signature")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Signature", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-SignedHeaders", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Credential")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Credential", valid_600023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600025: Call_CreateActionTarget_600014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom action target in Security Hub. You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.
  ## 
  let valid = call_600025.validator(path, query, header, formData, body)
  let scheme = call_600025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600025.url(scheme.get, call_600025.host, call_600025.base,
                         call_600025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600025, url, valid)

proc call*(call_600026: Call_CreateActionTarget_600014; body: JsonNode): Recallable =
  ## createActionTarget
  ## Creates a custom action target in Security Hub. You can use custom actions on findings and insights in Security Hub to trigger target actions in Amazon CloudWatch Events.
  ##   body: JObject (required)
  var body_600027 = newJObject()
  if body != nil:
    body_600027 = body
  result = call_600026.call(nil, nil, nil, nil, body_600027)

var createActionTarget* = Call_CreateActionTarget_600014(
    name: "createActionTarget", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets",
    validator: validate_CreateActionTarget_600015, base: "/",
    url: url_CreateActionTarget_600016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInsight_600028 = ref object of OpenApiRestCall_599368
proc url_CreateInsight_600030(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInsight_600029(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600031 = header.getOrDefault("X-Amz-Date")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Date", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-Security-Token")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Security-Token", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Content-Sha256", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Algorithm")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Algorithm", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Signature")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Signature", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-SignedHeaders", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Credential")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Credential", valid_600037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600039: Call_CreateInsight_600028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation. Use the <code>GroupByAttribute</code> to group the related findings in the insight.
  ## 
  let valid = call_600039.validator(path, query, header, formData, body)
  let scheme = call_600039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600039.url(scheme.get, call_600039.host, call_600039.base,
                         call_600039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600039, url, valid)

proc call*(call_600040: Call_CreateInsight_600028; body: JsonNode): Recallable =
  ## createInsight
  ## Creates a custom insight in Security Hub. An insight is a consolidation of findings that relate to a security issue that requires attention or remediation. Use the <code>GroupByAttribute</code> to group the related findings in the insight.
  ##   body: JObject (required)
  var body_600041 = newJObject()
  if body != nil:
    body_600041 = body
  result = call_600040.call(nil, nil, nil, nil, body_600041)

var createInsight* = Call_CreateInsight_600028(name: "createInsight",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/insights", validator: validate_CreateInsight_600029, base: "/",
    url: url_CreateInsight_600030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMembers_600059 = ref object of OpenApiRestCall_599368
proc url_CreateMembers_600061(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMembers_600060(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600062 = header.getOrDefault("X-Amz-Date")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Date", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Security-Token")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Security-Token", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Content-Sha256", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Algorithm")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Algorithm", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Signature")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Signature", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-SignedHeaders", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Credential")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Credential", valid_600068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600070: Call_CreateMembers_600059; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. You can use the <a>EnableSecurityHub</a> to enable Security Hub.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you need to use the <a>InviteMembers</a> action, which invites the accounts to enable Security Hub and become member accounts in Security Hub. If the invitation is accepted by the account owner, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start being sent to both the member and master accounts.</p> <p>You can remove the association between the master and member accounts by using the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ## 
  let valid = call_600070.validator(path, query, header, formData, body)
  let scheme = call_600070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600070.url(scheme.get, call_600070.host, call_600070.base,
                         call_600070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600070, url, valid)

proc call*(call_600071: Call_CreateMembers_600059; body: JsonNode): Recallable =
  ## createMembers
  ## <p>Creates a member association in Security Hub between the specified accounts and the account used to make the request, which is the master account. To successfully create a member, you must use this action from an account that already has Security Hub enabled. You can use the <a>EnableSecurityHub</a> to enable Security Hub.</p> <p>After you use <code>CreateMembers</code> to create member account associations in Security Hub, you need to use the <a>InviteMembers</a> action, which invites the accounts to enable Security Hub and become member accounts in Security Hub. If the invitation is accepted by the account owner, the account becomes a member account in Security Hub, and a permission policy is added that permits the master account to view the findings generated in the member account. When Security Hub is enabled in the invited account, findings start being sent to both the member and master accounts.</p> <p>You can remove the association between the master and member accounts by using the <a>DisassociateFromMasterAccount</a> or <a>DisassociateMembers</a> operation.</p>
  ##   body: JObject (required)
  var body_600072 = newJObject()
  if body != nil:
    body_600072 = body
  result = call_600071.call(nil, nil, nil, nil, body_600072)

var createMembers* = Call_CreateMembers_600059(name: "createMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com", route: "/members",
    validator: validate_CreateMembers_600060, base: "/", url: url_CreateMembers_600061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMembers_600042 = ref object of OpenApiRestCall_599368
proc url_ListMembers_600044(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMembers_600043(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600045 = query.getOrDefault("OnlyAssociated")
  valid_600045 = validateParameter(valid_600045, JBool, required = false, default = nil)
  if valid_600045 != nil:
    section.add "OnlyAssociated", valid_600045
  var valid_600046 = query.getOrDefault("NextToken")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "NextToken", valid_600046
  var valid_600047 = query.getOrDefault("MaxResults")
  valid_600047 = validateParameter(valid_600047, JInt, required = false, default = nil)
  if valid_600047 != nil:
    section.add "MaxResults", valid_600047
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
  var valid_600048 = header.getOrDefault("X-Amz-Date")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Date", valid_600048
  var valid_600049 = header.getOrDefault("X-Amz-Security-Token")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Security-Token", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Content-Sha256", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-Algorithm")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-Algorithm", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Signature")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Signature", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-SignedHeaders", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Credential")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Credential", valid_600054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600055: Call_ListMembers_600042; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists details about all member accounts for the current Security Hub master account.
  ## 
  let valid = call_600055.validator(path, query, header, formData, body)
  let scheme = call_600055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600055.url(scheme.get, call_600055.host, call_600055.base,
                         call_600055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600055, url, valid)

proc call*(call_600056: Call_ListMembers_600042; OnlyAssociated: bool = false;
          NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listMembers
  ## Lists details about all member accounts for the current Security Hub master account.
  ##   OnlyAssociated: bool
  ##                 : Specifies which member accounts the response includes based on their relationship status with the master account. The default value is <code>TRUE</code>. If <code>onlyAssociated</code> is set to <code>TRUE</code>, the response includes member accounts whose relationship status with the master is set to <code>ENABLED</code> or <code>DISABLED</code>. If <code>onlyAssociated</code> is set to <code>FALSE</code>, the response includes all existing member accounts. 
  ##   NextToken: string
  ##            : Paginates results. Set the value of this parameter to <code>NULL</code> on your first call to the <code>ListMembers</code> operation. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>nextToken</code> from the previous response to continue listing data. 
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response. 
  var query_600057 = newJObject()
  add(query_600057, "OnlyAssociated", newJBool(OnlyAssociated))
  add(query_600057, "NextToken", newJString(NextToken))
  add(query_600057, "MaxResults", newJInt(MaxResults))
  result = call_600056.call(nil, query_600057, nil, nil, nil)

var listMembers* = Call_ListMembers_600042(name: "listMembers",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/members",
                                        validator: validate_ListMembers_600043,
                                        base: "/", url: url_ListMembers_600044,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeclineInvitations_600073 = ref object of OpenApiRestCall_599368
proc url_DeclineInvitations_600075(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeclineInvitations_600074(path: JsonNode; query: JsonNode;
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
  var valid_600076 = header.getOrDefault("X-Amz-Date")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Date", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Security-Token")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Security-Token", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Content-Sha256", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Algorithm")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Algorithm", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Signature")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Signature", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-SignedHeaders", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Credential")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Credential", valid_600082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600084: Call_DeclineInvitations_600073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Declines invitations to become a member account.
  ## 
  let valid = call_600084.validator(path, query, header, formData, body)
  let scheme = call_600084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600084.url(scheme.get, call_600084.host, call_600084.base,
                         call_600084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600084, url, valid)

proc call*(call_600085: Call_DeclineInvitations_600073; body: JsonNode): Recallable =
  ## declineInvitations
  ## Declines invitations to become a member account.
  ##   body: JObject (required)
  var body_600086 = newJObject()
  if body != nil:
    body_600086 = body
  result = call_600085.call(nil, nil, nil, nil, body_600086)

var declineInvitations* = Call_DeclineInvitations_600073(
    name: "declineInvitations", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/invitations/decline",
    validator: validate_DeclineInvitations_600074, base: "/",
    url: url_DeclineInvitations_600075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateActionTarget_600115 = ref object of OpenApiRestCall_599368
proc url_UpdateActionTarget_600117(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateActionTarget_600116(path: JsonNode; query: JsonNode;
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
  var valid_600118 = path.getOrDefault("ActionTargetArn")
  valid_600118 = validateParameter(valid_600118, JString, required = true,
                                 default = nil)
  if valid_600118 != nil:
    section.add "ActionTargetArn", valid_600118
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
  var valid_600119 = header.getOrDefault("X-Amz-Date")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Date", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Security-Token")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Security-Token", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Content-Sha256", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Algorithm")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Algorithm", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Signature")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Signature", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-SignedHeaders", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Credential")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Credential", valid_600125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600127: Call_UpdateActionTarget_600115; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name and description of a custom action target in Security Hub.
  ## 
  let valid = call_600127.validator(path, query, header, formData, body)
  let scheme = call_600127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600127.url(scheme.get, call_600127.host, call_600127.base,
                         call_600127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600127, url, valid)

proc call*(call_600128: Call_UpdateActionTarget_600115; body: JsonNode;
          ActionTargetArn: string): Recallable =
  ## updateActionTarget
  ## Updates the name and description of a custom action target in Security Hub.
  ##   body: JObject (required)
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to update.
  var path_600129 = newJObject()
  var body_600130 = newJObject()
  if body != nil:
    body_600130 = body
  add(path_600129, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_600128.call(path_600129, nil, nil, nil, body_600130)

var updateActionTarget* = Call_UpdateActionTarget_600115(
    name: "updateActionTarget", meth: HttpMethod.HttpPatch,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_UpdateActionTarget_600116, base: "/",
    url: url_UpdateActionTarget_600117, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActionTarget_600087 = ref object of OpenApiRestCall_599368
proc url_DeleteActionTarget_600089(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteActionTarget_600088(path: JsonNode; query: JsonNode;
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
  var valid_600104 = path.getOrDefault("ActionTargetArn")
  valid_600104 = validateParameter(valid_600104, JString, required = true,
                                 default = nil)
  if valid_600104 != nil:
    section.add "ActionTargetArn", valid_600104
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
  var valid_600105 = header.getOrDefault("X-Amz-Date")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Date", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Security-Token")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Security-Token", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Content-Sha256", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-Algorithm")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Algorithm", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Signature")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Signature", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-SignedHeaders", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-Credential")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Credential", valid_600111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600112: Call_DeleteActionTarget_600087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a custom action target from Security Hub. Deleting a custom action target doesn't affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.
  ## 
  let valid = call_600112.validator(path, query, header, formData, body)
  let scheme = call_600112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600112.url(scheme.get, call_600112.host, call_600112.base,
                         call_600112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600112, url, valid)

proc call*(call_600113: Call_DeleteActionTarget_600087; ActionTargetArn: string): Recallable =
  ## deleteActionTarget
  ## Deletes a custom action target from Security Hub. Deleting a custom action target doesn't affect any findings or insights that were already sent to Amazon CloudWatch Events using the custom action.
  ##   ActionTargetArn: string (required)
  ##                  : The ARN of the custom action target to delete.
  var path_600114 = newJObject()
  add(path_600114, "ActionTargetArn", newJString(ActionTargetArn))
  result = call_600113.call(path_600114, nil, nil, nil, nil)

var deleteActionTarget* = Call_DeleteActionTarget_600087(
    name: "deleteActionTarget", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/actionTargets/{ActionTargetArn}",
    validator: validate_DeleteActionTarget_600088, base: "/",
    url: url_DeleteActionTarget_600089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInsight_600145 = ref object of OpenApiRestCall_599368
proc url_UpdateInsight_600147(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateInsight_600146(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600148 = path.getOrDefault("InsightArn")
  valid_600148 = validateParameter(valid_600148, JString, required = true,
                                 default = nil)
  if valid_600148 != nil:
    section.add "InsightArn", valid_600148
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
  var valid_600149 = header.getOrDefault("X-Amz-Date")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Date", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-Security-Token")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-Security-Token", valid_600150
  var valid_600151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Content-Sha256", valid_600151
  var valid_600152 = header.getOrDefault("X-Amz-Algorithm")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Algorithm", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Signature")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Signature", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-SignedHeaders", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Credential")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Credential", valid_600155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600157: Call_UpdateInsight_600145; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the Security Hub insight that the insight ARN specifies.
  ## 
  let valid = call_600157.validator(path, query, header, formData, body)
  let scheme = call_600157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600157.url(scheme.get, call_600157.host, call_600157.base,
                         call_600157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600157, url, valid)

proc call*(call_600158: Call_UpdateInsight_600145; InsightArn: string; body: JsonNode): Recallable =
  ## updateInsight
  ## Updates the Security Hub insight that the insight ARN specifies.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight that you want to update.
  ##   body: JObject (required)
  var path_600159 = newJObject()
  var body_600160 = newJObject()
  add(path_600159, "InsightArn", newJString(InsightArn))
  if body != nil:
    body_600160 = body
  result = call_600158.call(path_600159, nil, nil, nil, body_600160)

var updateInsight* = Call_UpdateInsight_600145(name: "updateInsight",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_UpdateInsight_600146,
    base: "/", url: url_UpdateInsight_600147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInsight_600131 = ref object of OpenApiRestCall_599368
proc url_DeleteInsight_600133(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInsight_600132(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600134 = path.getOrDefault("InsightArn")
  valid_600134 = validateParameter(valid_600134, JString, required = true,
                                 default = nil)
  if valid_600134 != nil:
    section.add "InsightArn", valid_600134
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
  var valid_600135 = header.getOrDefault("X-Amz-Date")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Date", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-Security-Token")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Security-Token", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Content-Sha256", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-Algorithm")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-Algorithm", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Signature")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Signature", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-SignedHeaders", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Credential")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Credential", valid_600141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600142: Call_DeleteInsight_600131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ## 
  let valid = call_600142.validator(path, query, header, formData, body)
  let scheme = call_600142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600142.url(scheme.get, call_600142.host, call_600142.base,
                         call_600142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600142, url, valid)

proc call*(call_600143: Call_DeleteInsight_600131; InsightArn: string): Recallable =
  ## deleteInsight
  ## Deletes the insight specified by the <code>InsightArn</code>.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight to delete.
  var path_600144 = newJObject()
  add(path_600144, "InsightArn", newJString(InsightArn))
  result = call_600143.call(path_600144, nil, nil, nil, nil)

var deleteInsight* = Call_DeleteInsight_600131(name: "deleteInsight",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/insights/{InsightArn}", validator: validate_DeleteInsight_600132,
    base: "/", url: url_DeleteInsight_600133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInvitations_600161 = ref object of OpenApiRestCall_599368
proc url_DeleteInvitations_600163(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInvitations_600162(path: JsonNode; query: JsonNode;
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
  var valid_600164 = header.getOrDefault("X-Amz-Date")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Date", valid_600164
  var valid_600165 = header.getOrDefault("X-Amz-Security-Token")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "X-Amz-Security-Token", valid_600165
  var valid_600166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = nil)
  if valid_600166 != nil:
    section.add "X-Amz-Content-Sha256", valid_600166
  var valid_600167 = header.getOrDefault("X-Amz-Algorithm")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Algorithm", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Signature")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Signature", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-SignedHeaders", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Credential")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Credential", valid_600170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600172: Call_DeleteInvitations_600161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes invitations received by the AWS account to become a member account.
  ## 
  let valid = call_600172.validator(path, query, header, formData, body)
  let scheme = call_600172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600172.url(scheme.get, call_600172.host, call_600172.base,
                         call_600172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600172, url, valid)

proc call*(call_600173: Call_DeleteInvitations_600161; body: JsonNode): Recallable =
  ## deleteInvitations
  ## Deletes invitations received by the AWS account to become a member account.
  ##   body: JObject (required)
  var body_600174 = newJObject()
  if body != nil:
    body_600174 = body
  result = call_600173.call(nil, nil, nil, nil, body_600174)

var deleteInvitations* = Call_DeleteInvitations_600161(name: "deleteInvitations",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/invitations/delete", validator: validate_DeleteInvitations_600162,
    base: "/", url: url_DeleteInvitations_600163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMembers_600175 = ref object of OpenApiRestCall_599368
proc url_DeleteMembers_600177(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMembers_600176(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600178 = header.getOrDefault("X-Amz-Date")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Date", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Security-Token")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Security-Token", valid_600179
  var valid_600180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-Content-Sha256", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Algorithm")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Algorithm", valid_600181
  var valid_600182 = header.getOrDefault("X-Amz-Signature")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "X-Amz-Signature", valid_600182
  var valid_600183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-SignedHeaders", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Credential")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Credential", valid_600184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600186: Call_DeleteMembers_600175; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified member accounts from Security Hub.
  ## 
  let valid = call_600186.validator(path, query, header, formData, body)
  let scheme = call_600186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600186.url(scheme.get, call_600186.host, call_600186.base,
                         call_600186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600186, url, valid)

proc call*(call_600187: Call_DeleteMembers_600175; body: JsonNode): Recallable =
  ## deleteMembers
  ## Deletes the specified member accounts from Security Hub.
  ##   body: JObject (required)
  var body_600188 = newJObject()
  if body != nil:
    body_600188 = body
  result = call_600187.call(nil, nil, nil, nil, body_600188)

var deleteMembers* = Call_DeleteMembers_600175(name: "deleteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/delete", validator: validate_DeleteMembers_600176, base: "/",
    url: url_DeleteMembers_600177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActionTargets_600189 = ref object of OpenApiRestCall_599368
proc url_DescribeActionTargets_600191(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeActionTargets_600190(path: JsonNode; query: JsonNode;
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
  var valid_600192 = query.getOrDefault("NextToken")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "NextToken", valid_600192
  var valid_600193 = query.getOrDefault("MaxResults")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "MaxResults", valid_600193
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
  var valid_600194 = header.getOrDefault("X-Amz-Date")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Date", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Security-Token")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Security-Token", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Content-Sha256", valid_600196
  var valid_600197 = header.getOrDefault("X-Amz-Algorithm")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Algorithm", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-Signature")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Signature", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-SignedHeaders", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Credential")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Credential", valid_600200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600202: Call_DescribeActionTargets_600189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the custom action targets in Security Hub in your account.
  ## 
  let valid = call_600202.validator(path, query, header, formData, body)
  let scheme = call_600202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600202.url(scheme.get, call_600202.host, call_600202.base,
                         call_600202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600202, url, valid)

proc call*(call_600203: Call_DescribeActionTargets_600189; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeActionTargets
  ## Returns a list of the custom action targets in Security Hub in your account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600204 = newJObject()
  var body_600205 = newJObject()
  add(query_600204, "NextToken", newJString(NextToken))
  if body != nil:
    body_600205 = body
  add(query_600204, "MaxResults", newJString(MaxResults))
  result = call_600203.call(nil, query_600204, nil, nil, body_600205)

var describeActionTargets* = Call_DescribeActionTargets_600189(
    name: "describeActionTargets", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/actionTargets/get",
    validator: validate_DescribeActionTargets_600190, base: "/",
    url: url_DescribeActionTargets_600191, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableSecurityHub_600220 = ref object of OpenApiRestCall_599368
proc url_EnableSecurityHub_600222(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableSecurityHub_600221(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600223 = header.getOrDefault("X-Amz-Date")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Date", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Security-Token")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Security-Token", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Content-Sha256", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Algorithm")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Algorithm", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Signature")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Signature", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-SignedHeaders", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Credential")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Credential", valid_600229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600231: Call_EnableSecurityHub_600220; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. Enabling Security Hub also enables the CIS AWS Foundations standard. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
  ## 
  let valid = call_600231.validator(path, query, header, formData, body)
  let scheme = call_600231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600231.url(scheme.get, call_600231.host, call_600231.base,
                         call_600231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600231, url, valid)

proc call*(call_600232: Call_EnableSecurityHub_600220; body: JsonNode): Recallable =
  ## enableSecurityHub
  ## Enables Security Hub for your account in the current Region or the Region you specify in the request. Enabling Security Hub also enables the CIS AWS Foundations standard. When you enable Security Hub, you grant to Security Hub the permissions necessary to gather findings from AWS Config, Amazon GuardDuty, Amazon Inspector, and Amazon Macie. To learn more, see <a href="https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html">Setting Up AWS Security Hub</a>.
  ##   body: JObject (required)
  var body_600233 = newJObject()
  if body != nil:
    body_600233 = body
  result = call_600232.call(nil, nil, nil, nil, body_600233)

var enableSecurityHub* = Call_EnableSecurityHub_600220(name: "enableSecurityHub",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/accounts", validator: validate_EnableSecurityHub_600221, base: "/",
    url: url_EnableSecurityHub_600222, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHub_600206 = ref object of OpenApiRestCall_599368
proc url_DescribeHub_600208(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeHub_600207(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600209 = query.getOrDefault("HubArn")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "HubArn", valid_600209
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
  var valid_600210 = header.getOrDefault("X-Amz-Date")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Date", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Security-Token")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Security-Token", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Content-Sha256", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Algorithm")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Algorithm", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Signature")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Signature", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-SignedHeaders", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Credential")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Credential", valid_600216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600217: Call_DescribeHub_600206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ## 
  let valid = call_600217.validator(path, query, header, formData, body)
  let scheme = call_600217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600217.url(scheme.get, call_600217.host, call_600217.base,
                         call_600217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600217, url, valid)

proc call*(call_600218: Call_DescribeHub_600206; HubArn: string = ""): Recallable =
  ## describeHub
  ## Returns details about the Hub resource in your account, including the <code>HubArn</code> and the time when you enabled Security Hub.
  ##   HubArn: string
  ##         : The ARN of the Hub resource to retrieve.
  var query_600219 = newJObject()
  add(query_600219, "HubArn", newJString(HubArn))
  result = call_600218.call(nil, query_600219, nil, nil, nil)

var describeHub* = Call_DescribeHub_600206(name: "describeHub",
                                        meth: HttpMethod.HttpGet,
                                        host: "securityhub.amazonaws.com",
                                        route: "/accounts",
                                        validator: validate_DescribeHub_600207,
                                        base: "/", url: url_DescribeHub_600208,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableSecurityHub_600234 = ref object of OpenApiRestCall_599368
proc url_DisableSecurityHub_600236(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisableSecurityHub_600235(path: JsonNode; query: JsonNode;
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
  var valid_600237 = header.getOrDefault("X-Amz-Date")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Date", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-Security-Token")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-Security-Token", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Content-Sha256", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Algorithm")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Algorithm", valid_600240
  var valid_600241 = header.getOrDefault("X-Amz-Signature")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Signature", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-SignedHeaders", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Credential")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Credential", valid_600243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600244: Call_DisableSecurityHub_600234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub. When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and can't be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed. If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  ## 
  let valid = call_600244.validator(path, query, header, formData, body)
  let scheme = call_600244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600244.url(scheme.get, call_600244.host, call_600244.base,
                         call_600244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600244, url, valid)

proc call*(call_600245: Call_DisableSecurityHub_600234): Recallable =
  ## disableSecurityHub
  ## <p>Disables Security Hub in your account only in the current Region. To disable Security Hub in all Regions, you must submit one request per Region where you have enabled Security Hub. When you disable Security Hub for a master account, it doesn't disable Security Hub for any associated member accounts.</p> <p>When you disable Security Hub, your existing findings and insights and any Security Hub configuration settings are deleted after 90 days and can't be recovered. Any standards that were enabled are disabled, and your master and member account associations are removed. If you want to save your existing findings, you must export them before you disable Security Hub.</p>
  result = call_600245.call(nil, nil, nil, nil, nil)

var disableSecurityHub* = Call_DisableSecurityHub_600234(
    name: "disableSecurityHub", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com", route: "/accounts",
    validator: validate_DisableSecurityHub_600235, base: "/",
    url: url_DisableSecurityHub_600236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProducts_600246 = ref object of OpenApiRestCall_599368
proc url_DescribeProducts_600248(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProducts_600247(path: JsonNode; query: JsonNode;
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
  var valid_600249 = query.getOrDefault("NextToken")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "NextToken", valid_600249
  var valid_600250 = query.getOrDefault("MaxResults")
  valid_600250 = validateParameter(valid_600250, JInt, required = false, default = nil)
  if valid_600250 != nil:
    section.add "MaxResults", valid_600250
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
  var valid_600251 = header.getOrDefault("X-Amz-Date")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Date", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Security-Token")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Security-Token", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Content-Sha256", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Algorithm")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Algorithm", valid_600254
  var valid_600255 = header.getOrDefault("X-Amz-Signature")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-Signature", valid_600255
  var valid_600256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600256 = validateParameter(valid_600256, JString, required = false,
                                 default = nil)
  if valid_600256 != nil:
    section.add "X-Amz-SignedHeaders", valid_600256
  var valid_600257 = header.getOrDefault("X-Amz-Credential")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Credential", valid_600257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600258: Call_DescribeProducts_600246; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
  ## 
  let valid = call_600258.validator(path, query, header, formData, body)
  let scheme = call_600258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600258.url(scheme.get, call_600258.host, call_600258.base,
                         call_600258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600258, url, valid)

proc call*(call_600259: Call_DescribeProducts_600246; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## describeProducts
  ## Returns information about the products available that you can subscribe to and integrate with Security Hub to consolidate findings.
  ##   NextToken: string
  ##            : The token that is required for pagination.
  ##   MaxResults: int
  ##             : The maximum number of results to return.
  var query_600260 = newJObject()
  add(query_600260, "NextToken", newJString(NextToken))
  add(query_600260, "MaxResults", newJInt(MaxResults))
  result = call_600259.call(nil, query_600260, nil, nil, nil)

var describeProducts* = Call_DescribeProducts_600246(name: "describeProducts",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com", route: "/products",
    validator: validate_DescribeProducts_600247, base: "/",
    url: url_DescribeProducts_600248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisableImportFindingsForProduct_600261 = ref object of OpenApiRestCall_599368
proc url_DisableImportFindingsForProduct_600263(protocol: Scheme; host: string;
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

proc validate_DisableImportFindingsForProduct_600262(path: JsonNode;
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
  var valid_600264 = path.getOrDefault("ProductSubscriptionArn")
  valid_600264 = validateParameter(valid_600264, JString, required = true,
                                 default = nil)
  if valid_600264 != nil:
    section.add "ProductSubscriptionArn", valid_600264
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
  var valid_600265 = header.getOrDefault("X-Amz-Date")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Date", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Security-Token")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Security-Token", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Content-Sha256", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-Algorithm")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-Algorithm", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-Signature")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Signature", valid_600269
  var valid_600270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "X-Amz-SignedHeaders", valid_600270
  var valid_600271 = header.getOrDefault("X-Amz-Credential")
  valid_600271 = validateParameter(valid_600271, JString, required = false,
                                 default = nil)
  if valid_600271 != nil:
    section.add "X-Amz-Credential", valid_600271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600272: Call_DisableImportFindingsForProduct_600261;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Disables the integration of the specified product with Security Hub. Findings from that product are no longer sent to Security Hub after the integration is disabled.
  ## 
  let valid = call_600272.validator(path, query, header, formData, body)
  let scheme = call_600272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600272.url(scheme.get, call_600272.host, call_600272.base,
                         call_600272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600272, url, valid)

proc call*(call_600273: Call_DisableImportFindingsForProduct_600261;
          ProductSubscriptionArn: string): Recallable =
  ## disableImportFindingsForProduct
  ## Disables the integration of the specified product with Security Hub. Findings from that product are no longer sent to Security Hub after the integration is disabled.
  ##   ProductSubscriptionArn: string (required)
  ##                         : The ARN of the integrated product to disable the integration for.
  var path_600274 = newJObject()
  add(path_600274, "ProductSubscriptionArn", newJString(ProductSubscriptionArn))
  result = call_600273.call(path_600274, nil, nil, nil, nil)

var disableImportFindingsForProduct* = Call_DisableImportFindingsForProduct_600261(
    name: "disableImportFindingsForProduct", meth: HttpMethod.HttpDelete,
    host: "securityhub.amazonaws.com",
    route: "/productSubscriptions/{ProductSubscriptionArn}",
    validator: validate_DisableImportFindingsForProduct_600262, base: "/",
    url: url_DisableImportFindingsForProduct_600263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateFromMasterAccount_600275 = ref object of OpenApiRestCall_599368
proc url_DisassociateFromMasterAccount_600277(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateFromMasterAccount_600276(path: JsonNode; query: JsonNode;
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

proc call*(call_600285: Call_DisassociateFromMasterAccount_600275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the current Security Hub member account from the associated master account.
  ## 
  let valid = call_600285.validator(path, query, header, formData, body)
  let scheme = call_600285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600285.url(scheme.get, call_600285.host, call_600285.base,
                         call_600285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600285, url, valid)

proc call*(call_600286: Call_DisassociateFromMasterAccount_600275): Recallable =
  ## disassociateFromMasterAccount
  ## Disassociates the current Security Hub member account from the associated master account.
  result = call_600286.call(nil, nil, nil, nil, nil)

var disassociateFromMasterAccount* = Call_DisassociateFromMasterAccount_600275(
    name: "disassociateFromMasterAccount", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/master/disassociate",
    validator: validate_DisassociateFromMasterAccount_600276, base: "/",
    url: url_DisassociateFromMasterAccount_600277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateMembers_600287 = ref object of OpenApiRestCall_599368
proc url_DisassociateMembers_600289(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateMembers_600288(path: JsonNode; query: JsonNode;
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
  var valid_600290 = header.getOrDefault("X-Amz-Date")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Date", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Security-Token")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Security-Token", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Content-Sha256", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Algorithm")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Algorithm", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Signature")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Signature", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-SignedHeaders", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Credential")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Credential", valid_600296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600298: Call_DisassociateMembers_600287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Disassociates the specified member accounts from the associated master account.
  ## 
  let valid = call_600298.validator(path, query, header, formData, body)
  let scheme = call_600298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600298.url(scheme.get, call_600298.host, call_600298.base,
                         call_600298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600298, url, valid)

proc call*(call_600299: Call_DisassociateMembers_600287; body: JsonNode): Recallable =
  ## disassociateMembers
  ## Disassociates the specified member accounts from the associated master account.
  ##   body: JObject (required)
  var body_600300 = newJObject()
  if body != nil:
    body_600300 = body
  result = call_600299.call(nil, nil, nil, nil, body_600300)

var disassociateMembers* = Call_DisassociateMembers_600287(
    name: "disassociateMembers", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/members/disassociate",
    validator: validate_DisassociateMembers_600288, base: "/",
    url: url_DisassociateMembers_600289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_EnableImportFindingsForProduct_600316 = ref object of OpenApiRestCall_599368
proc url_EnableImportFindingsForProduct_600318(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EnableImportFindingsForProduct_600317(path: JsonNode;
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
  var valid_600319 = header.getOrDefault("X-Amz-Date")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-Date", valid_600319
  var valid_600320 = header.getOrDefault("X-Amz-Security-Token")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-Security-Token", valid_600320
  var valid_600321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "X-Amz-Content-Sha256", valid_600321
  var valid_600322 = header.getOrDefault("X-Amz-Algorithm")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Algorithm", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Signature")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Signature", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-SignedHeaders", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Credential")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Credential", valid_600325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600327: Call_EnableImportFindingsForProduct_600316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub. When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.
  ## 
  let valid = call_600327.validator(path, query, header, formData, body)
  let scheme = call_600327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600327.url(scheme.get, call_600327.host, call_600327.base,
                         call_600327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600327, url, valid)

proc call*(call_600328: Call_EnableImportFindingsForProduct_600316; body: JsonNode): Recallable =
  ## enableImportFindingsForProduct
  ## Enables the integration of a partner product with Security Hub. Integrated products send findings to Security Hub. When you enable a product integration, a permission policy that grants permission for the product to send findings to Security Hub is applied.
  ##   body: JObject (required)
  var body_600329 = newJObject()
  if body != nil:
    body_600329 = body
  result = call_600328.call(nil, nil, nil, nil, body_600329)

var enableImportFindingsForProduct* = Call_EnableImportFindingsForProduct_600316(
    name: "enableImportFindingsForProduct", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_EnableImportFindingsForProduct_600317, base: "/",
    url: url_EnableImportFindingsForProduct_600318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEnabledProductsForImport_600301 = ref object of OpenApiRestCall_599368
proc url_ListEnabledProductsForImport_600303(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEnabledProductsForImport_600302(path: JsonNode; query: JsonNode;
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
  var valid_600304 = query.getOrDefault("NextToken")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "NextToken", valid_600304
  var valid_600305 = query.getOrDefault("MaxResults")
  valid_600305 = validateParameter(valid_600305, JInt, required = false, default = nil)
  if valid_600305 != nil:
    section.add "MaxResults", valid_600305
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
  var valid_600306 = header.getOrDefault("X-Amz-Date")
  valid_600306 = validateParameter(valid_600306, JString, required = false,
                                 default = nil)
  if valid_600306 != nil:
    section.add "X-Amz-Date", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-Security-Token")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Security-Token", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Content-Sha256", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Algorithm")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Algorithm", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Signature")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Signature", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-SignedHeaders", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Credential")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Credential", valid_600312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600313: Call_ListEnabledProductsForImport_600301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ## 
  let valid = call_600313.validator(path, query, header, formData, body)
  let scheme = call_600313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600313.url(scheme.get, call_600313.host, call_600313.base,
                         call_600313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600313, url, valid)

proc call*(call_600314: Call_ListEnabledProductsForImport_600301;
          NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listEnabledProductsForImport
  ## Lists all findings-generating solutions (products) whose findings you have subscribed to receive in Security Hub.
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListEnabledProductsForImport</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data.
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response.
  var query_600315 = newJObject()
  add(query_600315, "NextToken", newJString(NextToken))
  add(query_600315, "MaxResults", newJInt(MaxResults))
  result = call_600314.call(nil, query_600315, nil, nil, nil)

var listEnabledProductsForImport* = Call_ListEnabledProductsForImport_600301(
    name: "listEnabledProductsForImport", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/productSubscriptions",
    validator: validate_ListEnabledProductsForImport_600302, base: "/",
    url: url_ListEnabledProductsForImport_600303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEnabledStandards_600330 = ref object of OpenApiRestCall_599368
proc url_GetEnabledStandards_600332(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEnabledStandards_600331(path: JsonNode; query: JsonNode;
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
  var valid_600333 = header.getOrDefault("X-Amz-Date")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Date", valid_600333
  var valid_600334 = header.getOrDefault("X-Amz-Security-Token")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Security-Token", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Content-Sha256", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-Algorithm")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Algorithm", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-Signature")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Signature", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-SignedHeaders", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Credential")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Credential", valid_600339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600341: Call_GetEnabledStandards_600330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the standards that are currently enabled.
  ## 
  let valid = call_600341.validator(path, query, header, formData, body)
  let scheme = call_600341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600341.url(scheme.get, call_600341.host, call_600341.base,
                         call_600341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600341, url, valid)

proc call*(call_600342: Call_GetEnabledStandards_600330; body: JsonNode): Recallable =
  ## getEnabledStandards
  ## Returns a list of the standards that are currently enabled.
  ##   body: JObject (required)
  var body_600343 = newJObject()
  if body != nil:
    body_600343 = body
  result = call_600342.call(nil, nil, nil, nil, body_600343)

var getEnabledStandards* = Call_GetEnabledStandards_600330(
    name: "getEnabledStandards", meth: HttpMethod.HttpPost,
    host: "securityhub.amazonaws.com", route: "/standards/get",
    validator: validate_GetEnabledStandards_600331, base: "/",
    url: url_GetEnabledStandards_600332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFindings_600344 = ref object of OpenApiRestCall_599368
proc url_GetFindings_600346(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFindings_600345(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600347 = query.getOrDefault("NextToken")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "NextToken", valid_600347
  var valid_600348 = query.getOrDefault("MaxResults")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "MaxResults", valid_600348
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
  var valid_600349 = header.getOrDefault("X-Amz-Date")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Date", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-Security-Token")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Security-Token", valid_600350
  var valid_600351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-Content-Sha256", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-Algorithm")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Algorithm", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Signature")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Signature", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-SignedHeaders", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Credential")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Credential", valid_600355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600357: Call_GetFindings_600344; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of findings that match the specified criteria.
  ## 
  let valid = call_600357.validator(path, query, header, formData, body)
  let scheme = call_600357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600357.url(scheme.get, call_600357.host, call_600357.base,
                         call_600357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600357, url, valid)

proc call*(call_600358: Call_GetFindings_600344; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getFindings
  ## Returns a list of findings that match the specified criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600359 = newJObject()
  var body_600360 = newJObject()
  add(query_600359, "NextToken", newJString(NextToken))
  if body != nil:
    body_600360 = body
  add(query_600359, "MaxResults", newJString(MaxResults))
  result = call_600358.call(nil, query_600359, nil, nil, body_600360)

var getFindings* = Call_GetFindings_600344(name: "getFindings",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/findings",
                                        validator: validate_GetFindings_600345,
                                        base: "/", url: url_GetFindings_600346,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFindings_600361 = ref object of OpenApiRestCall_599368
proc url_UpdateFindings_600363(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateFindings_600362(path: JsonNode; query: JsonNode;
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
  var valid_600364 = header.getOrDefault("X-Amz-Date")
  valid_600364 = validateParameter(valid_600364, JString, required = false,
                                 default = nil)
  if valid_600364 != nil:
    section.add "X-Amz-Date", valid_600364
  var valid_600365 = header.getOrDefault("X-Amz-Security-Token")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Security-Token", valid_600365
  var valid_600366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600366 = validateParameter(valid_600366, JString, required = false,
                                 default = nil)
  if valid_600366 != nil:
    section.add "X-Amz-Content-Sha256", valid_600366
  var valid_600367 = header.getOrDefault("X-Amz-Algorithm")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Algorithm", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-Signature")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Signature", valid_600368
  var valid_600369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-SignedHeaders", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-Credential")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Credential", valid_600370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600372: Call_UpdateFindings_600361; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ## 
  let valid = call_600372.validator(path, query, header, formData, body)
  let scheme = call_600372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600372.url(scheme.get, call_600372.host, call_600372.base,
                         call_600372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600372, url, valid)

proc call*(call_600373: Call_UpdateFindings_600361; body: JsonNode): Recallable =
  ## updateFindings
  ## Updates the <code>Note</code> and <code>RecordState</code> of the Security Hub-aggregated findings that the filter attributes specify. Any member account that can view the finding also sees the update to the finding.
  ##   body: JObject (required)
  var body_600374 = newJObject()
  if body != nil:
    body_600374 = body
  result = call_600373.call(nil, nil, nil, nil, body_600374)

var updateFindings* = Call_UpdateFindings_600361(name: "updateFindings",
    meth: HttpMethod.HttpPatch, host: "securityhub.amazonaws.com",
    route: "/findings", validator: validate_UpdateFindings_600362, base: "/",
    url: url_UpdateFindings_600363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsightResults_600375 = ref object of OpenApiRestCall_599368
proc url_GetInsightResults_600377(protocol: Scheme; host: string; base: string;
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

proc validate_GetInsightResults_600376(path: JsonNode; query: JsonNode;
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
  var valid_600378 = path.getOrDefault("InsightArn")
  valid_600378 = validateParameter(valid_600378, JString, required = true,
                                 default = nil)
  if valid_600378 != nil:
    section.add "InsightArn", valid_600378
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
  var valid_600379 = header.getOrDefault("X-Amz-Date")
  valid_600379 = validateParameter(valid_600379, JString, required = false,
                                 default = nil)
  if valid_600379 != nil:
    section.add "X-Amz-Date", valid_600379
  var valid_600380 = header.getOrDefault("X-Amz-Security-Token")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "X-Amz-Security-Token", valid_600380
  var valid_600381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "X-Amz-Content-Sha256", valid_600381
  var valid_600382 = header.getOrDefault("X-Amz-Algorithm")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Algorithm", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Signature")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Signature", valid_600383
  var valid_600384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-SignedHeaders", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Credential")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Credential", valid_600385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600386: Call_GetInsightResults_600375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the results of the Security Hub insight that the insight ARN specifies.
  ## 
  let valid = call_600386.validator(path, query, header, formData, body)
  let scheme = call_600386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600386.url(scheme.get, call_600386.host, call_600386.base,
                         call_600386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600386, url, valid)

proc call*(call_600387: Call_GetInsightResults_600375; InsightArn: string): Recallable =
  ## getInsightResults
  ## Lists the results of the Security Hub insight that the insight ARN specifies.
  ##   InsightArn: string (required)
  ##             : The ARN of the insight whose results you want to see.
  var path_600388 = newJObject()
  add(path_600388, "InsightArn", newJString(InsightArn))
  result = call_600387.call(path_600388, nil, nil, nil, nil)

var getInsightResults* = Call_GetInsightResults_600375(name: "getInsightResults",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/insights/results/{InsightArn}",
    validator: validate_GetInsightResults_600376, base: "/",
    url: url_GetInsightResults_600377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsights_600389 = ref object of OpenApiRestCall_599368
proc url_GetInsights_600391(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInsights_600390(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600392 = query.getOrDefault("NextToken")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "NextToken", valid_600392
  var valid_600393 = query.getOrDefault("MaxResults")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "MaxResults", valid_600393
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
  var valid_600394 = header.getOrDefault("X-Amz-Date")
  valid_600394 = validateParameter(valid_600394, JString, required = false,
                                 default = nil)
  if valid_600394 != nil:
    section.add "X-Amz-Date", valid_600394
  var valid_600395 = header.getOrDefault("X-Amz-Security-Token")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-Security-Token", valid_600395
  var valid_600396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600396 = validateParameter(valid_600396, JString, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "X-Amz-Content-Sha256", valid_600396
  var valid_600397 = header.getOrDefault("X-Amz-Algorithm")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Algorithm", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Signature")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Signature", valid_600398
  var valid_600399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-SignedHeaders", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-Credential")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Credential", valid_600400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600402: Call_GetInsights_600389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists and describes insights that insight ARNs specify.
  ## 
  let valid = call_600402.validator(path, query, header, formData, body)
  let scheme = call_600402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600402.url(scheme.get, call_600402.host, call_600402.base,
                         call_600402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600402, url, valid)

proc call*(call_600403: Call_GetInsights_600389; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getInsights
  ## Lists and describes insights that insight ARNs specify.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600404 = newJObject()
  var body_600405 = newJObject()
  add(query_600404, "NextToken", newJString(NextToken))
  if body != nil:
    body_600405 = body
  add(query_600404, "MaxResults", newJString(MaxResults))
  result = call_600403.call(nil, query_600404, nil, nil, body_600405)

var getInsights* = Call_GetInsights_600389(name: "getInsights",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/insights/get",
                                        validator: validate_GetInsights_600390,
                                        base: "/", url: url_GetInsights_600391,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvitationsCount_600406 = ref object of OpenApiRestCall_599368
proc url_GetInvitationsCount_600408(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInvitationsCount_600407(path: JsonNode; query: JsonNode;
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
  var valid_600409 = header.getOrDefault("X-Amz-Date")
  valid_600409 = validateParameter(valid_600409, JString, required = false,
                                 default = nil)
  if valid_600409 != nil:
    section.add "X-Amz-Date", valid_600409
  var valid_600410 = header.getOrDefault("X-Amz-Security-Token")
  valid_600410 = validateParameter(valid_600410, JString, required = false,
                                 default = nil)
  if valid_600410 != nil:
    section.add "X-Amz-Security-Token", valid_600410
  var valid_600411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "X-Amz-Content-Sha256", valid_600411
  var valid_600412 = header.getOrDefault("X-Amz-Algorithm")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-Algorithm", valid_600412
  var valid_600413 = header.getOrDefault("X-Amz-Signature")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Signature", valid_600413
  var valid_600414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "X-Amz-SignedHeaders", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-Credential")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Credential", valid_600415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600416: Call_GetInvitationsCount_600406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  ## 
  let valid = call_600416.validator(path, query, header, formData, body)
  let scheme = call_600416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600416.url(scheme.get, call_600416.host, call_600416.base,
                         call_600416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600416, url, valid)

proc call*(call_600417: Call_GetInvitationsCount_600406): Recallable =
  ## getInvitationsCount
  ## Returns the count of all Security Hub membership invitations that were sent to the current member account, not including the currently accepted invitation. 
  result = call_600417.call(nil, nil, nil, nil, nil)

var getInvitationsCount* = Call_GetInvitationsCount_600406(
    name: "getInvitationsCount", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/invitations/count",
    validator: validate_GetInvitationsCount_600407, base: "/",
    url: url_GetInvitationsCount_600408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMembers_600418 = ref object of OpenApiRestCall_599368
proc url_GetMembers_600420(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMembers_600419(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600421 = header.getOrDefault("X-Amz-Date")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Date", valid_600421
  var valid_600422 = header.getOrDefault("X-Amz-Security-Token")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-Security-Token", valid_600422
  var valid_600423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Content-Sha256", valid_600423
  var valid_600424 = header.getOrDefault("X-Amz-Algorithm")
  valid_600424 = validateParameter(valid_600424, JString, required = false,
                                 default = nil)
  if valid_600424 != nil:
    section.add "X-Amz-Algorithm", valid_600424
  var valid_600425 = header.getOrDefault("X-Amz-Signature")
  valid_600425 = validateParameter(valid_600425, JString, required = false,
                                 default = nil)
  if valid_600425 != nil:
    section.add "X-Amz-Signature", valid_600425
  var valid_600426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600426 = validateParameter(valid_600426, JString, required = false,
                                 default = nil)
  if valid_600426 != nil:
    section.add "X-Amz-SignedHeaders", valid_600426
  var valid_600427 = header.getOrDefault("X-Amz-Credential")
  valid_600427 = validateParameter(valid_600427, JString, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "X-Amz-Credential", valid_600427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600429: Call_GetMembers_600418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the details on the Security Hub member accounts that the account IDs specify.
  ## 
  let valid = call_600429.validator(path, query, header, formData, body)
  let scheme = call_600429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600429.url(scheme.get, call_600429.host, call_600429.base,
                         call_600429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600429, url, valid)

proc call*(call_600430: Call_GetMembers_600418; body: JsonNode): Recallable =
  ## getMembers
  ## Returns the details on the Security Hub member accounts that the account IDs specify.
  ##   body: JObject (required)
  var body_600431 = newJObject()
  if body != nil:
    body_600431 = body
  result = call_600430.call(nil, nil, nil, nil, body_600431)

var getMembers* = Call_GetMembers_600418(name: "getMembers",
                                      meth: HttpMethod.HttpPost,
                                      host: "securityhub.amazonaws.com",
                                      route: "/members/get",
                                      validator: validate_GetMembers_600419,
                                      base: "/", url: url_GetMembers_600420,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_InviteMembers_600432 = ref object of OpenApiRestCall_599368
proc url_InviteMembers_600434(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_InviteMembers_600433(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600435 = header.getOrDefault("X-Amz-Date")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Date", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-Security-Token")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Security-Token", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-Content-Sha256", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-Algorithm")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Algorithm", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-Signature")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-Signature", valid_600439
  var valid_600440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "X-Amz-SignedHeaders", valid_600440
  var valid_600441 = header.getOrDefault("X-Amz-Credential")
  valid_600441 = validateParameter(valid_600441, JString, required = false,
                                 default = nil)
  if valid_600441 != nil:
    section.add "X-Amz-Credential", valid_600441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600443: Call_InviteMembers_600432; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from. Before you can use this action to invite a member, you must first create the member account in Security Hub by using the <a>CreateMembers</a> action. When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from member account.
  ## 
  let valid = call_600443.validator(path, query, header, formData, body)
  let scheme = call_600443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600443.url(scheme.get, call_600443.host, call_600443.base,
                         call_600443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600443, url, valid)

proc call*(call_600444: Call_InviteMembers_600432; body: JsonNode): Recallable =
  ## inviteMembers
  ## Invites other AWS accounts to become member accounts for the Security Hub master account that the invitation is sent from. Before you can use this action to invite a member, you must first create the member account in Security Hub by using the <a>CreateMembers</a> action. When the account owner accepts the invitation to become a member account and enables Security Hub, the master account can view the findings generated from member account.
  ##   body: JObject (required)
  var body_600445 = newJObject()
  if body != nil:
    body_600445 = body
  result = call_600444.call(nil, nil, nil, nil, body_600445)

var inviteMembers* = Call_InviteMembers_600432(name: "inviteMembers",
    meth: HttpMethod.HttpPost, host: "securityhub.amazonaws.com",
    route: "/members/invite", validator: validate_InviteMembers_600433, base: "/",
    url: url_InviteMembers_600434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvitations_600446 = ref object of OpenApiRestCall_599368
proc url_ListInvitations_600448(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInvitations_600447(path: JsonNode; query: JsonNode;
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
  var valid_600449 = query.getOrDefault("NextToken")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "NextToken", valid_600449
  var valid_600450 = query.getOrDefault("MaxResults")
  valid_600450 = validateParameter(valid_600450, JInt, required = false, default = nil)
  if valid_600450 != nil:
    section.add "MaxResults", valid_600450
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
  var valid_600451 = header.getOrDefault("X-Amz-Date")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-Date", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Security-Token")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Security-Token", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-Content-Sha256", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-Algorithm")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-Algorithm", valid_600454
  var valid_600455 = header.getOrDefault("X-Amz-Signature")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-Signature", valid_600455
  var valid_600456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600456 = validateParameter(valid_600456, JString, required = false,
                                 default = nil)
  if valid_600456 != nil:
    section.add "X-Amz-SignedHeaders", valid_600456
  var valid_600457 = header.getOrDefault("X-Amz-Credential")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Credential", valid_600457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600458: Call_ListInvitations_600446; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ## 
  let valid = call_600458.validator(path, query, header, formData, body)
  let scheme = call_600458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600458.url(scheme.get, call_600458.host, call_600458.base,
                         call_600458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600458, url, valid)

proc call*(call_600459: Call_ListInvitations_600446; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## listInvitations
  ## Lists all Security Hub membership invitations that were sent to the current AWS account. 
  ##   NextToken: string
  ##            : Paginates results. On your first call to the <code>ListInvitations</code> operation, set the value of this parameter to <code>NULL</code>. For subsequent calls to the operation, fill <code>nextToken</code> in the request with the value of <code>NextToken</code> from the previous response to continue listing data. 
  ##   MaxResults: int
  ##             : The maximum number of items that you want in the response. 
  var query_600460 = newJObject()
  add(query_600460, "NextToken", newJString(NextToken))
  add(query_600460, "MaxResults", newJInt(MaxResults))
  result = call_600459.call(nil, query_600460, nil, nil, nil)

var listInvitations* = Call_ListInvitations_600446(name: "listInvitations",
    meth: HttpMethod.HttpGet, host: "securityhub.amazonaws.com",
    route: "/invitations", validator: validate_ListInvitations_600447, base: "/",
    url: url_ListInvitations_600448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600475 = ref object of OpenApiRestCall_599368
proc url_TagResource_600477(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_600476(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600478 = path.getOrDefault("ResourceArn")
  valid_600478 = validateParameter(valid_600478, JString, required = true,
                                 default = nil)
  if valid_600478 != nil:
    section.add "ResourceArn", valid_600478
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

proc call*(call_600487: Call_TagResource_600475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a resource.
  ## 
  let valid = call_600487.validator(path, query, header, formData, body)
  let scheme = call_600487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600487.url(scheme.get, call_600487.host, call_600487.base,
                         call_600487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600487, url, valid)

proc call*(call_600488: Call_TagResource_600475; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds one or more tags to a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to apply the tags to.
  ##   body: JObject (required)
  var path_600489 = newJObject()
  var body_600490 = newJObject()
  add(path_600489, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_600490 = body
  result = call_600488.call(path_600489, nil, nil, nil, body_600490)

var tagResource* = Call_TagResource_600475(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "securityhub.amazonaws.com",
                                        route: "/tags/{ResourceArn}",
                                        validator: validate_TagResource_600476,
                                        base: "/", url: url_TagResource_600477,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600461 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600463(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_600462(path: JsonNode; query: JsonNode;
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
  var valid_600464 = path.getOrDefault("ResourceArn")
  valid_600464 = validateParameter(valid_600464, JString, required = true,
                                 default = nil)
  if valid_600464 != nil:
    section.add "ResourceArn", valid_600464
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
  var valid_600465 = header.getOrDefault("X-Amz-Date")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amz-Date", valid_600465
  var valid_600466 = header.getOrDefault("X-Amz-Security-Token")
  valid_600466 = validateParameter(valid_600466, JString, required = false,
                                 default = nil)
  if valid_600466 != nil:
    section.add "X-Amz-Security-Token", valid_600466
  var valid_600467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-Content-Sha256", valid_600467
  var valid_600468 = header.getOrDefault("X-Amz-Algorithm")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "X-Amz-Algorithm", valid_600468
  var valid_600469 = header.getOrDefault("X-Amz-Signature")
  valid_600469 = validateParameter(valid_600469, JString, required = false,
                                 default = nil)
  if valid_600469 != nil:
    section.add "X-Amz-Signature", valid_600469
  var valid_600470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600470 = validateParameter(valid_600470, JString, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "X-Amz-SignedHeaders", valid_600470
  var valid_600471 = header.getOrDefault("X-Amz-Credential")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "X-Amz-Credential", valid_600471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600472: Call_ListTagsForResource_600461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of tags associated with a resource.
  ## 
  let valid = call_600472.validator(path, query, header, formData, body)
  let scheme = call_600472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600472.url(scheme.get, call_600472.host, call_600472.base,
                         call_600472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600472, url, valid)

proc call*(call_600473: Call_ListTagsForResource_600461; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags associated with a resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to retrieve tags for.
  var path_600474 = newJObject()
  add(path_600474, "ResourceArn", newJString(ResourceArn))
  result = call_600473.call(path_600474, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600461(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "securityhub.amazonaws.com", route: "/tags/{ResourceArn}",
    validator: validate_ListTagsForResource_600462, base: "/",
    url: url_ListTagsForResource_600463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600491 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600493(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_600492(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600494 = path.getOrDefault("ResourceArn")
  valid_600494 = validateParameter(valid_600494, JString, required = true,
                                 default = nil)
  if valid_600494 != nil:
    section.add "ResourceArn", valid_600494
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_600495 = query.getOrDefault("tagKeys")
  valid_600495 = validateParameter(valid_600495, JArray, required = true, default = nil)
  if valid_600495 != nil:
    section.add "tagKeys", valid_600495
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

proc call*(call_600503: Call_UntagResource_600491; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a resource.
  ## 
  let valid = call_600503.validator(path, query, header, formData, body)
  let scheme = call_600503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600503.url(scheme.get, call_600503.host, call_600503.base,
                         call_600503.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600503, url, valid)

proc call*(call_600504: Call_UntagResource_600491; tagKeys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags from a resource.
  ##   tagKeys: JArray (required)
  ##          : The tag keys associated with the tags to remove from the resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource to remove the tags from.
  var path_600505 = newJObject()
  var query_600506 = newJObject()
  if tagKeys != nil:
    query_600506.add "tagKeys", tagKeys
  add(path_600505, "ResourceArn", newJString(ResourceArn))
  result = call_600504.call(path_600505, query_600506, nil, nil, nil)

var untagResource* = Call_UntagResource_600491(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "securityhub.amazonaws.com",
    route: "/tags/{ResourceArn}#tagKeys", validator: validate_UntagResource_600492,
    base: "/", url: url_UntagResource_600493, schemes: {Scheme.Https, Scheme.Http})
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
